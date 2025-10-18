import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthGradientBackground extends StatelessWidget {
  final Widget child;

  const AuthGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lightPrimary,
            AppColors.primaryVariant1,
          ],
        ),
      ),
      child: child,
    );
  }
}
