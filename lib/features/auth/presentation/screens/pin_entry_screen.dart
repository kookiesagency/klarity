import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart' as app_exceptions;
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/local_pin_service.dart';
import '../../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';
import '../providers/pin_verification_provider.dart';
import '../widgets/custom_button.dart';

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

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  bool _isLoading = false;
  bool _hasError = false;
  bool _isPinVerified = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    // Get userId from either Authenticated or SessionExpired state
    final authState = ref.read(authProvider);
    final String? userId;
    if (authState is Authenticated) {
      userId = authState.user.id;
    } else if (authState is SessionExpired) {
      userId = authState.userId;
    } else {
      return;
    }

    if (userId == null) return;

    // Check if biometric is available on device
    final biometricService = ref.read(biometricServiceProvider);
    final availableResult = await biometricService.isBiometricAvailable();

    // Load biometric enabled flag from local storage
    final localPinService = ref.read(localPinServiceProvider);
    final biometricEnabled = await localPinService.getBiometricEnabled(userId);

    if (mounted) {
      setState(() {
        _isBiometricAvailable = availableResult.data ?? false;
        _isBiometricEnabled = biometricEnabled;
      });

      // Auto-attempt biometric if enabled
      if (_isBiometricEnabled && _isBiometricAvailable) {
        _authenticateWithBiometric();
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isLoading || _isPinVerified) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authProvider.notifier).authenticateWithBiometric(
          reason: 'Unlock your account',
        );

    if (!mounted) return;

    result.fold(
      onSuccess: (isAuthenticated) {
        if (isAuthenticated) {
          setState(() {
            _isPinVerified = true;
            _isLoading = false;
          });
          ref.read(pinVerificationProvider.notifier).setPinVerified(true);
        } else {
          setState(() => _isLoading = false);
          // Biometric failed, user can use PIN
        }
      },
      onFailure: (exception) {
        setState(() => _isLoading = false);
        // Biometric failed, user can use PIN
        // Don't show error if user cancelled
        if (!exception.message.contains('cancel')) {
          context.showErrorSnackBar('Biometric authentication failed. Please use PIN.');
        }
      },
    );
  }

  void _onPinChanged(String value) {
    if (_isLoading || _isPinVerified) return;

    setState(() {
      _hasError = false;
    });

    // Remove spaces to get actual digit count
    final digitsOnly = value.replaceAll(' ', '');
    if (digitsOnly.length == 4) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    // Remove spaces to get actual PIN
    final pin = _pinController.text.replaceAll(' ', '');
    if (pin.length != 4) return;

    setState(() => _isLoading = true);

    try {
      // Add timeout to prevent infinite loading
      final result = await ref
          .read(authProvider.notifier)
          .verifyPin(pin)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              return Failure(app_exceptions.AuthException('Verification timed out. Please try again.'));
            },
          );

      if (!mounted) return;

      setState(() => _isLoading = false);

      result.fold(
        onSuccess: (isValid) {
          if (isValid) {
            setState(() => _isPinVerified = true);
            ref.read(pinVerificationProvider.notifier).setPinVerified(true);
          } else {
            setState(() => _hasError = true);
            _showErrorAndClear();
          }
        },
        onFailure: (exception) {
          // Check if it's a session error
          final isSessionError = exception.message.contains('oauth_client_id') ||
              exception.message.contains('Session') ||
              exception.message.contains('expired') ||
              exception.message.contains('unexpected_failure');

          if (isSessionError) {
            // Session expired - automatically sign out
            context.showErrorSnackBar('Your session has expired. Please sign in again.');
            // Delay to show message, then sign out
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                _handleSignOut();
              }
            });
          } else {
            setState(() => _hasError = true);
            // Show user-friendly error message instead of raw error
            final errorMessage = _getReadableErrorMessage(exception.message);
            context.showErrorSnackBar(errorMessage);
            _clearPin();
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      context.showErrorSnackBar('Unable to verify PIN. Please try again.');
      _clearPin();
    }
  }

  String _getReadableErrorMessage(String rawError) {
    // Convert technical errors to user-friendly messages
    if (rawError.contains('oauth_client_id') ||
        rawError.contains('Session') ||
        rawError.contains('unexpected_failure')) {
      return 'Session expired. Please sign in again.';
    }
    if (rawError.contains('network') || rawError.contains('timeout')) {
      return 'Network error. Please check your connection.';
    }
    if (rawError.contains('PIN not set')) {
      return 'PIN not found. Please set up your PIN.';
    }
    return 'Unable to verify PIN. Please try again.';
  }

  void _showErrorAndClear() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _clearPin();
      }
    });
  }

  void _clearPin() {
    setState(() {
      _hasError = false;
      _pinController.clear();
      _isPinVerified = false;
    });
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).signOut();
    // Navigation will be handled by the auth state listener in main.dart
  }

  Future<void> _handleForgotPin() async {
    final user = ref.read(authProvider.notifier).currentUser;
    if (user == null) {
      context.showErrorSnackBar('Unable to reset PIN right now.');
      return;
    }

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ForgotPinSheet(email: user.email),
    );

    if (updated == true && mounted) {
      setState(() {
        _hasError = false;
        _isPinVerified = true;
      });
      ref.read(pinVerificationProvider.notifier).setPinVerified(true);
      context.showSuccessSnackBar('PIN updated successfully');
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.notifier).currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                  color: _isPinVerified
                      ? Colors.green
                      : AppColors.lightPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isPinVerified
                      ? Icons.check_circle_outline
                      : Icons.lock_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // User greeting
              if (user != null) ...[
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Title
              Text(
                _isPinVerified ? 'PIN Verified!' : 'Enter Your PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                _hasError
                    ? 'Incorrect PIN. Please try again.'
                    : 'Enter your 4-digit PIN to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: _hasError
                      ? Colors.red
                      : (isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // PIN Input Boxes
              GestureDetector(
                onTap: () {
                  // Focus the hidden text field when boxes are tapped
                  FocusScope.of(context).requestFocus(_pinFocusNode);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final pin = _pinController.text.replaceAll(' ', '');
                    final isFilled = index < pin.length;
                    final isActive = index == pin.length;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 60,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.darkSurfaceVariant
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasError
                              ? Colors.red
                              : isActive
                                  ? AppColors.lightPrimary
                                  : (isDarkMode
                                      ? AppColors.darkOnSurface.withOpacity(0.3)
                                      : Colors.grey[300]!),
                          width: isActive ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isFilled
                            ? Icon(
                                Icons.circle,
                                size: 16,
                                color: isDarkMode
                                    ? AppColors.darkPrimary.withOpacity(0.8)
                                    : AppColors.lightPrimary,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              // Hidden TextField for keyboard input
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 0.1,
                  height: 0.1,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    enabled: !_isLoading && !_isPinVerified,
                    keyboardType: TextInputType.number,
                    maxLength: 7, // 4 digits + 3 spaces
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
                ),
              ),

              const SizedBox(height: 24),

              // Biometric button
              if (_isBiometricAvailable && _isBiometricEnabled && !_isPinVerified)
                Center(
                  child: IconButton(
                    onPressed: _authenticateWithBiometric,
                    icon: const Icon(
                      Icons.fingerprint,
                      size: 48,
                      color: AppColors.lightPrimary,
                    ),
                    tooltip: 'Use biometric authentication',
                  ),
                ),

              // Push button to bottom
              const Spacer(flex: 2),

              // Loading indicator or Forgot PIN button
              SizedBox(
                height: 40,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !_isPinVerified
                        ? TextButton(
                            onPressed: _handleForgotPin,
                            child: const Text(
                              'Forgot PIN?',
                              style: TextStyle(
                                color: AppColors.lightPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),

              // Sign Out button
              if (!_isPinVerified && !_isLoading)
                TextButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgotPinSheet extends ConsumerStatefulWidget{
  final String email;
  const _ForgotPinSheet({required this.email});

  @override
  ConsumerState<_ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends ConsumerState<_ForgotPinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseConfig.client;

      AuthResponse response;
      try {
        response = await supabase.auth.signInWithPassword(
          email: widget.email,
          password: _passwordController.text.trim(),
        );
      } catch (authError) {
        // Handle authentication errors specifically
        if (mounted) {
          final errorStr = authError.toString().toLowerCase();
          String errorMessage = 'Incorrect password';

          if (errorStr.contains('network') || errorStr.contains('connection')) {
            errorMessage = 'Network error. Please check your connection.';
          } else if (errorStr.contains('email')) {
            errorMessage = 'Email not found. Please try again.';
          }

          setState(() {
            _errorMessage = errorMessage;
            _isLoading = false;
          });
        }
        return;
      }

      if (response.user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Incorrect password';
            _isLoading = false;
          });
        }
        return;
      }

      final authNotifier = ref.read(authProvider.notifier);
      final setupResult = await authNotifier.setupPin(_pinController.text);
      if (setupResult.isFailure) {
        if (mounted) {
          context.showErrorSnackBar(
            setupResult.exception?.message ?? 'Failed to update PIN.',
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      await authNotifier.refreshUser();
      ref.read(pinVerificationProvider.notifier).setPinVerified(true);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('Unable to reset PIN. Please try again.');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reset PIN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'To create a new PIN, confirm your password and choose a new 4-digit PIN.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: widget.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _errorMessage,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: Validators.password,
                onChanged: (_) {
                  // Clear error message when user starts typing
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLength,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.length != AppConstants.pinLength) {
                    return 'PIN must be ${AppConstants.pinLength} digits';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'PIN must contain only numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.pinLength,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.length != AppConstants.pinLength) {
                    return 'Confirm PIN must be ${AppConstants.pinLength} digits';
                  }
                  if (value != _pinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Create New PIN',
                onPressed: _handleReset,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
