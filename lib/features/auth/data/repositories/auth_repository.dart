import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/exceptions.dart' as app_exceptions;
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/login_request.dart';

/// Repository for authentication operations
class AuthRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _userDataKey = 'cached_user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Sign up with email and password
  Future<Result<UserModel>> signUp(SignupRequest request) async {
    try {
      // Sign up with Supabase Auth
      final normalizedEmail = request.email.trim().toLowerCase();
      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: request.password,
        data: request.toMetadata(),
      );

      if (response.user == null) {
        return Failure(app_exceptions.AuthException('Failed to create account'));
      }

      // Wait a moment for trigger to create user record
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch user data from users table with retry
      try {
        var userData = await _supabase
            .from(ApiConstants.usersTable)
            .select()
            .eq('id', response.user!.id)
            .single();

        final trimmedFullName = request.fullName.trim();
        final requestPhone = request.phone?.trim();
        final existingFullName = (userData['full_name'] as String?)?.trim();
        final existingPhone = (userData['phone'] as String?)?.trim();

        final updates = <String, dynamic>{};
        if (trimmedFullName.isNotEmpty &&
            (existingFullName == null || existingFullName.isEmpty)) {
          updates['full_name'] = trimmedFullName;
        }
        if (requestPhone != null &&
            requestPhone.isNotEmpty &&
            (existingPhone == null || existingPhone.isEmpty)) {
          updates['phone'] = requestPhone;
        }

        if (updates.isNotEmpty) {
          userData = await _supabase
              .from(ApiConstants.usersTable)
              .update(updates)
              .eq('id', response.user!.id)
              .select()
              .single();
        }

        final user = UserModel.fromJson(userData);

        // Cache user data locally
        await _cacheUserData(user);

        return Success(user);
      } catch (e) {
        // If user record not found, create it manually
        await _supabase.from(ApiConstants.usersTable).insert({
          'id': response.user!.id,
          'email': normalizedEmail,
          'full_name': request.fullName.trim(),
          'phone': request.phone?.trim(),
        });

        // Fetch the newly created user
        final userData = await _supabase
            .from(ApiConstants.usersTable)
            .select()
            .eq('id', response.user!.id)
            .single();

        final user = UserModel.fromJson(userData);

        // Cache user data locally
        await _cacheUserData(user);

        return Success(user);
      }
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Sign in with email and password
  Future<Result<UserModel>> signIn(LoginRequest request) async {
    try {
      // Sign in with Supabase Auth
      final normalizedEmail = request.email.trim().toLowerCase();
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: request.password,
      );

      if (response.user == null) {
        return Failure(app_exceptions.AuthException.invalidCredentials());
      }

      // Fetch user data from users table
      final userData = await _supabase
          .from(ApiConstants.usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();

      final user = UserModel.fromJson(userData);

      // Check if account is locked
      if (user.isAccountLocked) {
        return Failure(app_exceptions.AuthException.accountLocked());
      }

      // Update last login time
      await _updateLastLogin(user.id);

      // Cache user data locally
      await _cacheUserData(user);

      return Success(user);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await _supabase.auth.signOut();

      // Clear cached user data
      await _clearCachedUserData();

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get current user
  /// ⭐ PlasticMart-style: Trust Supabase session completely!
  Future<Result<UserModel?>> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;

      // ⭐ KEY FIX: If no Supabase session, DON'T use cache - force fresh login!
      if (authUser == null) {
        print('ℹ️ No Supabase session - clearing cache and requiring login');
        await _clearCachedUserData();
        return const Success(null);
      }

      // ✅ Supabase session is valid - fetch fresh user data
      try {
        final userData = await _supabase
            .from(ApiConstants.usersTable)
            .select()
            .eq('id', authUser.id)
            .single();

        final user = UserModel.fromJson(userData);

        // Update cache with fresh data (for offline fallback only)
        await _cacheUserData(user);

        return Success(user);
      } catch (e) {
        final errorMessage = e.toString();

        // Check if this is auth/token error - force logout
        if (errorMessage.contains('oauth_client_id') ||
            errorMessage.contains('unexpected_failure') ||
            errorMessage.contains('JWT') ||
            errorMessage.contains('expired')) {
          print('🔥 Auth error detected - forcing fresh login: $errorMessage');
          // Clear everything and force login
          try {
            await _supabase.auth.signOut();
            await _clearCachedUserData();
          } catch (signOutError) {
            print('⚠️ Error during forced sign out: $signOutError');
          }
          return const Success(null);
        }

        // ⭐ For network/database errors ONLY (and session is valid), use cache as fallback
        print('⚠️ Database fetch failed, using cache as fallback: $e');
        final cachedUser = await _getCachedUserData();
        if (cachedUser != null && cachedUser.id == authUser.id) {
          print('📱 Returning cached user data (Supabase session is still valid)');
          return Success(cachedUser);
        }

        // No cache available, return error
        return Failure(ErrorHandler.handle(e));
      }
    } catch (e, stackTrace) {
      print('❌ Unexpected error in getCurrentUser: $e');
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Set up PIN
  Future<Result<void>> setupPin(String userId, String pin) async {
    try {
      // Hash the PIN
      final pinHash = _hashPin(pin);

      // Update user with PIN hash
      await _supabase
          .from(ApiConstants.usersTable)
          .update({'pin_hash': pinHash})
          .eq('id', userId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Verify PIN
  /// ⭐ Only works if Supabase session is valid!
  Future<Result<bool>> verifyPin(String userId, String pin) async {
    try {
      // ⭐ CRITICAL: Check if we have a valid Supabase session FIRST
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('🔒 No Supabase session - cannot verify PIN, forcing login');
        await _clearCachedUserData();
        return Failure(app_exceptions.AuthException('Session expired. Please sign in again.'));
      }

      // ✅ Session valid - verify PIN from database
      final userData = await _supabase
          .from(ApiConstants.usersTable)
          .select('pin_hash')
          .eq('id', userId)
          .single();

      final storedPinHash = userData['pin_hash'] as String?;
      if (storedPinHash == null) {
        return Failure(app_exceptions.AuthException('PIN not set'));
      }

      // Hash the entered PIN and compare
      final pinHash = _hashPin(pin);
      final isValid = pinHash == storedPinHash;

      if (!isValid) {
        // Increment failed attempts
        await _incrementFailedAttempts(userId);
      } else {
        // Reset failed attempts
        await _resetFailedAttempts(userId);
      }

      return Success(isValid);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Enable biometric authentication
  Future<Result<void>> enableBiometric(String userId) async {
    try {
      await _supabase
          .from(ApiConstants.usersTable)
          .update({'biometric_enabled': true})
          .eq('id', userId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Disable biometric authentication
  Future<Result<void>> disableBiometric(String userId) async {
    try {
      await _supabase
          .from(ApiConstants.usersTable)
          .update({'biometric_enabled': false})
          .eq('id', userId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Send password reset email
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Update user profile
  Future<Result<UserModel>> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;

      final userData = await _supabase
          .from(ApiConstants.usersTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      final user = UserModel.fromJson(userData);
      return Success(user);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  // Private helper methods

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Update last login time
  Future<void> _updateLastLogin(String userId) async {
    await _supabase
        .from(ApiConstants.usersTable)
        .update({
          'last_login_at': DateTime.now().toIso8601String(),
          'failed_login_attempts': 0,
        })
        .eq('id', userId);
  }

  /// Increment failed login attempts
  Future<void> _incrementFailedAttempts(String userId) async {
    await _supabase.rpc('increment_failed_attempts', params: {'user_id': userId});
  }

  /// Reset failed login attempts
  Future<void> _resetFailedAttempts(String userId) async {
    await _supabase
        .from(ApiConstants.usersTable)
        .update({'failed_login_attempts': 0})
        .eq('id', userId);
  }

  /// Cache user data locally
  Future<void> _cacheUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userDataKey, userJson);
      await prefs.setBool(_isLoggedInKey, true);
      print('💾 Cached user data locally');
    } catch (e) {
      print('⚠️ Failed to cache user data: $e');
      // Don't throw, caching is optional
    }
  }

  /// Get cached user data
  Future<UserModel?> _getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) {
        return null;
      }

      final userJson = prefs.getString(_userDataKey);
      if (userJson == null) {
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      print('⚠️ Failed to get cached user data: $e');
      return null;
    }
  }

  /// Clear cached user data
  Future<void> _clearCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);
      print('🗑️ Cleared cached user data');
    } catch (e) {
      print('⚠️ Failed to clear cached user data: $e');
      // Don't throw, clearing cache is best-effort
    }
  }
}
