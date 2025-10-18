import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../core/utils/result.dart';

/// Service for biometric authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<Result<bool>> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return Success(isAvailable && isDeviceSupported);
    } catch (e) {
      return Failure(AuthException('Failed to check biometric availability'));
    }
  }

  /// Get available biometric types
  Future<Result<List<BiometricType>>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      return Success(biometrics);
    } catch (e) {
      return Failure(AuthException('Failed to get available biometrics'));
    }
  }

  /// Authenticate with biometrics
  Future<Result<bool>> authenticate({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      // Check if biometrics are available
      final availabilityResult = await isBiometricAvailable();
      if (availabilityResult.isFailure || availabilityResult.data == false) {
        return Failure(AuthException.biometricNotAvailable());
      }

      // Attempt authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      return Success(authenticated);
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        return Failure(AuthException.biometricNotAvailable());
      } else if (e.code == 'NotEnrolled') {
        return Failure(AuthException(
          'No biometric credentials enrolled. Please set up biometrics in your device settings.',
          code: 'BIOMETRIC_NOT_ENROLLED',
        ));
      } else if (e.code == 'LockedOut') {
        return Failure(AuthException(
          'Too many failed attempts. Please try again later.',
          code: 'BIOMETRIC_LOCKED_OUT',
        ));
      } else if (e.code == 'PermanentlyLockedOut') {
        return Failure(AuthException(
          'Biometric authentication is permanently locked. Please use PIN.',
          code: 'BIOMETRIC_PERMANENTLY_LOCKED',
        ));
      }
      return Failure(AuthException.biometricFailed());
    } catch (e) {
      return Failure(AuthException.biometricFailed());
    }
  }

  /// Stop authentication (cancel)
  Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  /// Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}
