import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/pin_verification_provider.dart';

/// Custom formatter that adds spaces between PIN digits
class PinInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all spaces from the input
    final digitsOnly = newValue.text.replaceAll(' ', '');

    // Limit to 4 digits
    if (digitsOnly.length > 4) {
      return oldValue;
    }

    // Add spaces between digits
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmPinFocusNode = FocusNode();
  bool _isConfirming = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    if (_isLoading) return;

    // Trigger rebuild to show filled circles
    setState(() {});

    // Remove spaces to get actual digit count
    final digitsOnly = value.replaceAll(' ', '');
    if (digitsOnly.length == 4) {
      setState(() {
        _isConfirming = true;
      });
      // Auto-focus the confirm field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_confirmPinFocusNode);
        }
      });
    }
  }

  void _onConfirmPinChanged(String value) {
    if (_isLoading) return;

    // Trigger rebuild to show filled circles
    setState(() {});

    // Remove spaces to get actual digit count
    final digitsOnly = value.replaceAll(' ', '');
    if (digitsOnly.length == 4) {
      _handlePinSetup();
    }
  }

  Future<void> _handlePinSetup() async {
    // Remove spaces to get actual PINs
    final pin = _pinController.text.replaceAll(' ', '');
    final confirmPin = _confirmPinController.text.replaceAll(' ', '');

    if (pin.length != 4 || confirmPin.length != 4) return;

    if (pin != confirmPin) {
      context.showErrorSnackBar('PINs do not match. Please try again.');
      setState(() {
        _confirmPinController.clear();
        _isConfirming = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(authProvider.notifier).setupPin(pin);

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        context.showSuccessSnackBar('PIN set up successfully!');
        ref.read(pinVerificationProvider.notifier).setPinVerified(true);
        setState(() {
          _pinController.clear();
          _confirmPinController.clear();
          _isConfirming = false;
        });
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
        _clearPins();
      },
    );
  }

  void _clearPins() {
    setState(() {
      _isConfirming = false;
      _pinController.clear();
      _confirmPinController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isConfirming ? 'Confirm Your PIN' : 'Set Up Your PIN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                _isConfirming
                    ? 'Enter your PIN again to confirm'
                    : 'Create a 4-digit PIN for quick access',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // PIN Input Boxes
              GestureDetector(
                onTap: () {
                  if (!_isConfirming) {
                    FocusScope.of(context).requestFocus(_pinFocusNode);
                  } else {
                    FocusScope.of(context).requestFocus(_confirmPinFocusNode);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final pin = _isConfirming
                        ? _confirmPinController.text.replaceAll(' ', '')
                        : _pinController.text.replaceAll(' ', '');
                    final isFilled = index < pin.length;
                    final isActive = index == pin.length;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 60,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.lightPrimary
                              : Colors.grey[300]!,
                          width: isActive ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isFilled
                            ? const Icon(
                                Icons.circle,
                                size: 16,
                                color: AppColors.lightPrimary,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              // Hidden TextFields for keyboard input
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 0.1,
                  height: 0.1,
                  child: Column(
                    children: [
                      if (!_isConfirming)
                        TextField(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          maxLength: 7,
                          autofocus: true,
                          showCursor: false,
                          cursorWidth: 0,
                          cursorHeight: 0,
                          cursorColor: Colors.transparent,
                          style: const TextStyle(
                            color: Colors.transparent,
                            fontSize: 0.1,
                            height: 0.1,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onPinChanged,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            PinInputFormatter(),
                          ],
                        ),
                      if (_isConfirming)
                        TextField(
                          controller: _confirmPinController,
                          focusNode: _confirmPinFocusNode,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          maxLength: 7,
                          autofocus: true,
                          showCursor: false,
                          cursorWidth: 0,
                          cursorHeight: 0,
                          cursorColor: Colors.transparent,
                          style: const TextStyle(
                            color: Colors.transparent,
                            fontSize: 0.1,
                            height: 0.1,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onConfirmPinChanged,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            PinInputFormatter(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Push button to bottom
              const Spacer(flex: 2),

              // Loading Indicator or Change PIN button
              SizedBox(
                height: 40,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isConfirming
                        ? TextButton.icon(
                            onPressed: _clearPins,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Change PIN'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.lightPrimary,
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

