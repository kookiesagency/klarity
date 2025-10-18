import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/profile_model.dart';

/// Repository for profile operations
class ProfileRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all profiles for current user
  Future<Result<List<ProfileModel>>> getProfiles(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.profilesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final profiles = (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();

      return Success(profiles);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get profile by ID
  Future<Result<ProfileModel>> getProfileById(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.profilesTable)
          .select()
          .eq('id', profileId)
          .single();

      final profile = ProfileModel.fromJson(response);
      return Success(profile);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new profile
  Future<Result<ProfileModel>> createProfile({
    required String userId,
    required String name,
    bool isDefault = false,
    double lowBalanceThreshold = 1000.00,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.profilesTable)
          .insert({
            'user_id': userId,
            'name': name,
            'is_default': isDefault,
            'low_balance_threshold': lowBalanceThreshold,
          })
          .select()
          .single();

      final profile = ProfileModel.fromJson(response);
      return Success(profile);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Update profile
  Future<Result<ProfileModel>> updateProfile({
    required String profileId,
    String? name,
    double? lowBalanceThreshold,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (lowBalanceThreshold != null) updates['low_balance_threshold'] = lowBalanceThreshold;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(ApiConstants.profilesTable)
          .update(updates)
          .eq('id', profileId)
          .select()
          .single();

      final profile = ProfileModel.fromJson(response);
      return Success(profile);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete profile (hard delete)
  Future<Result<void>> deleteProfile(String profileId) async {
    try {
      await _supabase
          .from(ApiConstants.profilesTable)
          .delete()
          .eq('id', profileId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Check if user has any profiles
  Future<Result<bool>> hasProfiles(String userId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.profilesTable)
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return Success((response as List).isNotEmpty);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create default profile for new user (Personal only)
  Future<Result<List<ProfileModel>>> createDefaultProfiles(String userId) async {
    try {
      // Create only Personal profile (other profiles can be added manually later)
      final response = await _supabase
          .from(ApiConstants.profilesTable)
          .insert({
            'user_id': userId,
            'name': 'Personal',
            'is_default': true,
          })
          .select();

      final profiles = (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();

      return Success(profiles);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
