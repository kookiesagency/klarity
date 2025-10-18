import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile_model.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Profile state
class ProfileState {
  final List<ProfileModel> profiles;
  final ProfileModel? activeProfile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profiles = const [],
    this.activeProfile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    List<ProfileModel>? profiles,
    ProfileModel? activeProfile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile: activeProfile ?? this.activeProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;
  static const String _activeProfileKey = 'active_profile_id';
  static const String _cachedProfilesKey = 'cached_profiles_data';

  ProfileNotifier(this._repository, this._ref) : super(const ProfileState()) {
    _initialize();
  }

  /// Initialize profiles
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      await loadProfiles(user.id);
    });
  }

  /// Load all profiles for user
  Future<void> loadProfiles(String userId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getProfiles(userId);

    result.fold(
      onSuccess: (profiles) async {
        state = state.copyWith(
          profiles: profiles,
          isLoading: false,
          error: null,
        );

        // Cache profiles for offline access
        await _cacheProfilesData(profiles);

        // If no profiles exist, create defaults
        if (profiles.isEmpty) {
          await _createDefaultProfiles(userId);
          return;
        }

        // Load active profile from storage
        await _loadActiveProfile();
      },
      onFailure: (exception) async {
        print('⚠️ Failed to load profiles from database: ${exception.message}');

        // Try to load from cache (for offline/expired session scenarios)
        final cachedProfiles = await _getCachedProfilesData();

        if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
          print('✅ Loaded profiles from cache');
          state = state.copyWith(
            profiles: cachedProfiles,
            isLoading: false,
            error: null,
          );

          // Load active profile from storage
          await _loadActiveProfile();
        } else {
          print('❌ No cached profiles available');
          state = state.copyWith(
            isLoading: false,
            error: exception.message,
          );
        }
      },
    );
  }

  /// Create default profiles (Personal and Company)
  Future<void> _createDefaultProfiles(String userId) async {
    final result = await _repository.createDefaultProfiles(userId);

    result.fold(
      onSuccess: (profiles) async {
        state = state.copyWith(
          profiles: profiles,
          activeProfile: profiles.isNotEmpty ? profiles.first : null,
        );

        // Cache profiles
        await _cacheProfilesData(profiles);

        // Save first profile as active
        if (profiles.isNotEmpty) {
          await _saveActiveProfile(profiles.first.id);
        }
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );
  }

  /// Cache profiles data locally
  Future<void> _cacheProfilesData(List<ProfileModel> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = jsonEncode(profiles.map((p) => p.toJson()).toList());
      await prefs.setString(_cachedProfilesKey, profilesJson);
      print('💾 Cached profiles data locally');
    } catch (e) {
      print('⚠️ Failed to cache profiles: $e');
    }
  }

  /// Get cached profiles data
  Future<List<ProfileModel>?> _getCachedProfilesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString(_cachedProfilesKey);
      if (profilesJson == null) return null;

      final List<dynamic> profilesList = jsonDecode(profilesJson);
      return profilesList.map((json) => ProfileModel.fromJson(json)).toList();
    } catch (e) {
      print('⚠️ Failed to get cached profiles: $e');
      return null;
    }
  }

  /// Load active profile from storage
  Future<void> _loadActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final activeProfileId = prefs.getString(_activeProfileKey);

    if (activeProfileId != null) {
      final profile = state.profiles.firstWhere(
        (p) => p.id == activeProfileId,
        orElse: () => state.profiles.first,
      );
      state = state.copyWith(activeProfile: profile);
    } else if (state.profiles.isNotEmpty) {
      // Default to first profile
      state = state.copyWith(activeProfile: state.profiles.first);
      await _saveActiveProfile(state.profiles.first.id);
    }
  }

  /// Save active profile to storage
  Future<void> _saveActiveProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileKey, profileId);
  }

  /// Switch active profile
  Future<void> switchProfile(String profileId) async {
    final profile = state.profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => throw DatabaseException.notFound(),
    );

    state = state.copyWith(activeProfile: profile);
    await _saveActiveProfile(profileId);
  }

  /// Create new profile
  Future<Result<ProfileModel>> createProfile({
    required String name,
    double lowBalanceThreshold = 1000.00,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      return Failure(AuthException('User not authenticated'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createProfile(
      userId: user.id,
      name: name,
      lowBalanceThreshold: lowBalanceThreshold,
    );

    result.fold(
      onSuccess: (profile) async {
        final updatedProfiles = [...state.profiles, profile];
        state = state.copyWith(
          profiles: updatedProfiles,
          isLoading: false,
          error: null,
        );

        // Cache updated profiles
        await _cacheProfilesData(updatedProfiles);
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Update profile
  Future<Result<ProfileModel>> updateProfile({
    required String profileId,
    required String name,
    double? lowBalanceThreshold,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateProfile(
      profileId: profileId,
      name: name,
      lowBalanceThreshold: lowBalanceThreshold,
    );

    result.fold(
      onSuccess: (updatedProfile) async {
        final updatedProfiles = state.profiles.map((p) {
          return p.id == profileId ? updatedProfile : p;
        }).toList();

        state = state.copyWith(
          profiles: updatedProfiles,
          activeProfile: state.activeProfile?.id == profileId
              ? updatedProfile
              : state.activeProfile,
          isLoading: false,
          error: null,
        );

        // Cache updated profiles
        await _cacheProfilesData(updatedProfiles);
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Delete profile
  Future<Result<void>> deleteProfile(String profileId) async {
    // Prevent deleting the last profile
    if (state.profiles.length <= 1) {
      return Failure(ValidationException('Cannot delete the last profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteProfile(profileId);

    result.fold(
      onSuccess: (_) async {
        final updatedProfiles =
            state.profiles.where((p) => p.id != profileId).toList();

        // If deleted profile was active, switch to first available
        ProfileModel? newActiveProfile = state.activeProfile;
        if (state.activeProfile?.id == profileId) {
          newActiveProfile = updatedProfiles.isNotEmpty ? updatedProfiles.first : null;
          if (newActiveProfile != null) {
            await _saveActiveProfile(newActiveProfile.id);
          }
        }

        state = state.copyWith(
          profiles: updatedProfiles,
          activeProfile: newActiveProfile,
          isLoading: false,
          error: null,
        );

        // Cache updated profiles
        await _cacheProfilesData(updatedProfiles);
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Refresh profiles
  Future<void> refresh() async {
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      await loadProfiles(user.id);
    }
  }
}

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository, ref);
});

/// Active profile provider
final activeProfileProvider = Provider<ProfileModel?>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.activeProfile;
});

/// Profiles list provider
final profilesListProvider = Provider<List<ProfileModel>>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.profiles;
});
