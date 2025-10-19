import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '../../data/repositories/auth_repository.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/local_pin_service.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/login_request.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../core/config/supabase_config.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for BiometricService
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider for LocalPinService
final localPinServiceProvider = Provider<LocalPinService>((ref) {
  return LocalPinService();
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final BiometricService _biometricService;
  final LocalPinService _localPinService;

  AuthNotifier(this._authRepository, this._biometricService, this._localPinService)
      : super(const AuthInitial()) {
    _initializeAuth();
  }

  /// Initialize auth state and listen to auth changes
  Future<void> _initializeAuth() async {
    // Listen to auth state changes (for automatic token refresh)
    SupabaseConfig.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (session?.user != null) {
          print('🔄 Auth state changed: ${event.name}');
          // Refresh user data when token is refreshed
          await _checkAuthStatus();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print('👋 User signed out');
        state = const Unauthenticated();
      } else if (event == AuthChangeEvent.userUpdated) {
        print('🔄 User data updated');
        await _checkAuthStatus();
      }
    });

    // Check current session
    await _checkAuthStatus();
  }

  /// Check current authentication status
  /// ⭐ PlasticMart-style: Simple and clean!
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();

    final result = await _authRepository.getCurrentUser();
    result.fold(
      onSuccess: (user) {
        if (user != null) {
          print('✅ User authenticated: ${user.email}');
          state = Authenticated(user);
        } else {
          print('ℹ️ No active session - showing login screen');
          state = const Unauthenticated();
        }
      },
      onFailure: (exception) {
        print('⚠️ Session check failed: ${exception.message}');
        // On any error, go to unauthenticated (login screen)
        state = const Unauthenticated();
      },
    );
  }

  /// Sign in with email and password
  Future<Result<UserModel>> signIn(String email, String password) async {
    state = const AuthLoading();

    final request = LoginRequest(email: email, password: password);
    final result = await _authRepository.signIn(request);

    result.fold(
      onSuccess: (user) {
        state = Authenticated(user);
        // Store user ID for PIN unlock persistence
        _localPinService.storeLastUserId(user.id);
      },
      onFailure: (exception) {
        state = AuthError(exception.message);
      },
    );

    return result;
  }

  /// Sign up with email and password
  Future<Result<UserModel>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = const AuthLoading();

    final request = SignupRequest(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    final result = await _authRepository.signUp(request);

    result.fold(
      onSuccess: (user) {
        state = Authenticated(user);
        // Store user ID for PIN unlock persistence
        _localPinService.storeLastUserId(user.id);
      },
      onFailure: (exception) {
        state = AuthError(exception.message);
      },
    );

    return result;
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    // Clear local PIN, user ID, and biometric flag before signing out
    if (state is Authenticated) {
      final user = (state as Authenticated).user;
      await _localPinService.clearLocalPin(user.id);
      await _localPinService.clearBiometricEnabled(user.id);
    }
    await _localPinService.clearLastUserId();

    final result = await _authRepository.signOut();

    result.fold(
      onSuccess: (_) {
        state = const Unauthenticated();
      },
      onFailure: (exception) {
        // Even if sign out fails, set to unauthenticated
        state = const Unauthenticated();
      },
    );

    return result;
  }

  /// Set up PIN
  Future<Result<void>> setupPin(String pin) async {
    if (state is! Authenticated) {
      return Failure(AuthException('User not authenticated'));
    }

    final user = (state as Authenticated).user;

    // Store PIN locally first (primary storage)
    final localResult = await _localPinService.storePinLocally(user.id, pin);
    if (localResult.isFailure) {
      return localResult;
    }

    // Also store in database for backup/sync (best effort, don't fail if this fails)
    try {
      await _authRepository.setupPin(user.id, pin);
    } catch (e) {
      print('⚠️ Failed to store PIN in database (not critical): $e');
    }

    // Update user state
    final updatedUser = user.copyWith(hasPin: true);
    state = Authenticated(updatedUser);

    // Update cached user data to reflect PIN setup
    await _authRepository.getCurrentUser();

    return const Success(null);
  }

  /// Verify PIN (uses local storage, works offline)
  Future<Result<bool>> verifyPin(String pin) async {
    // Get user ID from either Authenticated or SessionExpired state
    final String? userId;
    if (state is Authenticated) {
      userId = (state as Authenticated).user.id;
    } else if (state is SessionExpired) {
      userId = (state as SessionExpired).userId;
    } else {
      return Failure(AuthException('User not authenticated'));
    }

    if (userId == null) {
      return Failure(AuthException('User ID not found'));
    }

    // Try to verify PIN locally first (works offline and when session expired)
    final localResult = await _localPinService.verifyPinLocally(userId, pin);

    // If local verification succeeds, return immediately (don't refresh to avoid backend errors)
    if (localResult.isSuccess && localResult.data == true) {
      return localResult;
    }

    // If local PIN doesn't exist, try database as fallback (for migration)
    // This handles users who have a database PIN but no local PIN yet
    if (localResult.isFailure && localResult.exception?.message.contains('No PIN set locally') == true) {
      print('📱 No local PIN found, attempting database verification as fallback...');

      try {
        final dbResult = await _authRepository.verifyPin(userId, pin);

        // If database verification succeeds, migrate PIN to local storage
        if (dbResult.isSuccess && dbResult.data == true) {
          print('✅ Database PIN verified, migrating to local storage...');
          await _localPinService.storePinLocally(userId, pin);

          return Success(true);
        }

        return dbResult;
      } catch (e) {
        print('⚠️ Database fallback failed: $e');
        // If database fallback fails, return the original local result
        return localResult;
      }
    }

    return localResult;
  }

  /// Enable biometric authentication
  Future<Result<void>> enableBiometric() async {
    if (state is! Authenticated) {
      return Failure(AuthException('User not authenticated'));
    }

    // Check if biometric is available
    final availabilityResult = await _biometricService.isBiometricAvailable();
    if (availabilityResult.isFailure || availabilityResult.data == false) {
      return availabilityResult as Result<void>;
    }

    final user = (state as Authenticated).user;
    final result = await _authRepository.enableBiometric(user.id);

    if (result.isSuccess) {
      state = Authenticated(user.copyWith(biometricEnabled: true));
      // Store biometric enabled flag locally
      await _localPinService.storeBiometricEnabled(user.id, true);
    }

    return result;
  }

  /// Disable biometric authentication
  Future<Result<void>> disableBiometric() async {
    if (state is! Authenticated) {
      return Failure(AuthException('User not authenticated'));
    }

    final user = (state as Authenticated).user;
    final result = await _authRepository.disableBiometric(user.id);

    if (result.isSuccess) {
      state = Authenticated(user.copyWith(biometricEnabled: false));
      // Store biometric disabled flag locally
      await _localPinService.storeBiometricEnabled(user.id, false);
    }

    return result;
  }

  /// Authenticate with biometrics
  Future<Result<bool>> authenticateWithBiometric({String? reason}) async {
    return await _biometricService.authenticate(
      reason: reason ?? 'Please authenticate to access your account',
    );
  }

  /// Send password reset email
  Future<Result<void>> resetPassword(String email) async {
    return await _authRepository.resetPassword(email);
  }

  /// Update user profile
  Future<Result<UserModel>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    if (state is! Authenticated) {
      return Failure(AuthException('User not authenticated'));
    }

    final user = (state as Authenticated).user;
    final result = await _authRepository.updateProfile(
      userId: user.id,
      fullName: fullName,
      phone: phone,
    );

    if (result.isSuccess) {
      state = Authenticated(result.data!);
    }

    return result;
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    await _checkAuthStatus();
  }

  /// Force sign out and clear all cached data (useful for auth errors)
  Future<Result<void>> forceSignOut() async {
    print('🔄 Force sign out - clearing all local data...');

    // Clear all local data first
    if (state is Authenticated) {
      final user = (state as Authenticated).user;
      await _localPinService.clearLocalPin(user.id);
      await _localPinService.clearBiometricEnabled(user.id);
    }
    await _localPinService.clearLastUserId();

    // Try to sign out from Supabase (best effort, ignore errors)
    try {
      await _authRepository.signOut();
    } catch (e) {
      print('⚠️ Supabase sign out failed (continuing anyway): $e');
    }

    // Always set to unauthenticated state
    state = const Unauthenticated();

    print('✅ Force sign out completed');
    return const Success(null);
  }

  /// Get current user
  UserModel? get currentUser {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }
    return null;
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  final localPinService = ref.watch(localPinServiceProvider);
  return AuthNotifier(authRepository, biometricService, localPinService);
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is Authenticated) {
    return authState.user;
  }
  return null;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is Authenticated;
});

/// Check if biometric is available provider
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  final result = await biometricService.isBiometricAvailable();
  return result.data ?? false;
});
