import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';

/// Service for local PIN storage and verification
/// PINs are stored locally and don't require database access
class LocalPinService {
  static const String _pinHashKey = 'local_pin_hash';
  static const String _pinSetKey = 'local_pin_set';
  static const String _lastUserIdKey = 'last_user_id';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Store PIN hash locally
  Future<Result<void>> storePinLocally(String userId, String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinHash = _hashPin(pin);

      await prefs.setString('${_pinHashKey}_$userId', pinHash);
      await prefs.setBool('${_pinSetKey}_$userId', true);

      print('✅ PIN stored locally for user: $userId');
      return const Success(null);
    } catch (e) {
      print('❌ Failed to store PIN locally: $e');
      return Failure(AuthException('Failed to store PIN locally'));
    }
  }

  /// Verify PIN against local storage
  Future<Result<bool>> verifyPinLocally(String userId, String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('${_pinHashKey}_$userId');

      if (storedHash == null) {
        print('⚠️ No local PIN found for user: $userId');
        return Failure(AuthException('No PIN set locally'));
      }

      final enteredHash = _hashPin(pin);
      final isValid = storedHash == enteredHash;

      print(isValid ? '✅ PIN verified locally' : '❌ PIN verification failed');
      return Success(isValid);
    } catch (e) {
      print('❌ PIN verification error: $e');
      return Failure(AuthException('Failed to verify PIN'));
    }
  }

  /// Check if user has a local PIN set
  Future<bool> hasLocalPin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${_pinSetKey}_$userId') ?? false;
    } catch (e) {
      print('⚠️ Failed to check local PIN: $e');
      return false;
    }
  }

  /// Clear local PIN (when user signs out or changes PIN)
  Future<void> clearLocalPin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_pinHashKey}_$userId');
      await prefs.remove('${_pinSetKey}_$userId');
      print('🗑️ Local PIN cleared for user: $userId');
    } catch (e) {
      print('⚠️ Failed to clear local PIN: $e');
    }
  }

  /// Store last logged-in user ID (for PIN unlock persistence)
  Future<void> storeLastUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, userId);
      print('💾 Last user ID stored: $userId');
    } catch (e) {
      print('⚠️ Failed to store last user ID: $e');
    }
  }

  /// Get last logged-in user ID
  Future<String?> getLastUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUserIdKey);
    } catch (e) {
      print('⚠️ Failed to get last user ID: $e');
      return null;
    }
  }

  /// Clear last user ID (on logout)
  Future<void> clearLastUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUserIdKey);
      print('🗑️ Last user ID cleared');
    } catch (e) {
      print('⚠️ Failed to clear last user ID: $e');
    }
  }

  /// Store biometric enabled flag
  Future<void> storeBiometricEnabled(String userId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_biometricEnabledKey}_$userId', enabled);
      print('💾 Biometric enabled flag stored: $enabled');
    } catch (e) {
      print('⚠️ Failed to store biometric flag: $e');
    }
  }

  /// Get biometric enabled flag
  Future<bool> getBiometricEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${_biometricEnabledKey}_$userId') ?? false;
    } catch (e) {
      print('⚠️ Failed to get biometric flag: $e');
      return false;
    }
  }

  /// Clear biometric enabled flag (on logout)
  Future<void> clearBiometricEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_biometricEnabledKey}_$userId');
      print('🗑️ Biometric enabled flag cleared');
    } catch (e) {
      print('⚠️ Failed to clear biometric flag: $e');
    }
  }

  /// Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
