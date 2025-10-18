import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the PIN has been verified in the current session
class PinVerificationNotifier extends StateNotifier<bool> {
  PinVerificationNotifier() : super(false);

  void setPinVerified(bool verified) {
    state = verified;
  }

  void reset() {
    state = false;
  }
}

/// Provider for PIN verification state
final pinVerificationProvider =
    StateNotifierProvider<PinVerificationNotifier, bool>((ref) {
  return PinVerificationNotifier();
});
