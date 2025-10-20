import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result =
        await ref.read(authProvider.notifier).resetPassword(_emailController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      onSuccess: (_) {
        setState(() => _emailSent = true);
        context.showSuccessSnackBar(
          'Password reset link sent! Check your email.',
        );
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_emailSent) {
      return _buildEmailSentView();
    }
    return _buildResetPasswordView();
  }

  Widget _buildResetPasswordView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(
  
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.lightPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Enter your email to receive a password reset link',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _handleResetPassword(),
                ),
                const SizedBox(height: 32),

                // Send Reset Link Button
                CustomButton(
                  text: 'Send Reset Link',
                  onPressed: _handleResetPassword,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Back to Login Link
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Remember your password? ",
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.lightPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSentView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(

      appBar: AppBar(
  
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    size: 50,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Center(
                child: Text(
                  'Check Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Center(
                child: Text(
                  'We\'ve sent a password reset link to your email',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Instructions
              Text(
                'Please check your inbox and follow the instructions to reset your password.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Back to Login Button
              CustomButton(
                text: 'Back to Login',
                onPressed: () => Navigator.of(context).pop(),
                isLoading: false,
              ),
              const SizedBox(height: 16),

              // Resend Link
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _emailSent = false);
                  },
                  child: Text(
                    'Didn\'t receive the email? Try again',
                    style: TextStyle(
                      color: AppColors.lightPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
