import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/screens/profile_management_screen.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/presentation/screens/account_management_screen.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../transactions/presentation/providers/emi_provider.dart';
import '../../../transactions/presentation/screens/emi_list_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isEnablingBiometric = false;

  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile != null) {
        // Load accounts
        ref.read(accountProvider.notifier).loadAccounts(activeProfile.id);
        // Load categories
        ref.read(categoryProvider.notifier).loadCategories(activeProfile.id);
        // Load EMIs
        ref.read(emiProvider.notifier).loadEmis(activeProfile.id);
      }
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _isEnablingBiometric = true);

    final result = value
        ? await ref.read(authProvider.notifier).enableBiometric()
        : await ref.read(authProvider.notifier).disableBiometric();

    setState(() => _isEnablingBiometric = false);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        context.showSuccessSnackBar(
          value ? 'Biometric enabled successfully' : 'Biometric disabled',
        );
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
      },
    );
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _handleForceSignOut() async {
    // Show confirmation dialog explaining the issue
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your session has expired and needs to be refreshed. '
          'You will need to sign in again to continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Sign Out & Re-login'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).forceSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = themeNotifier.isDarkMode;
    final isBiometricAvailableFuture = ref.watch(isBiometricAvailableProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lightPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.lightPrimary,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Security Section
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Biometric Toggle
                  isBiometricAvailableFuture.when(
                    data: (isAvailable) {
                      if (!isAvailable) {
                        return _SettingsTile(
                          icon: Icons.fingerprint,
                          title: 'Biometric Authentication',
                          subtitle: 'Not available on this device',
                          trailing: const Icon(
                            Icons.info_outline,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }

                      return _SettingsTile(
                        icon: Icons.fingerprint,
                        title: 'Biometric Authentication',
                        subtitle: user.biometricEnabled
                            ? 'Enabled'
                            : 'Tap to enable',
                        trailing: _isEnablingBiometric
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: user.biometricEnabled,
                                onChanged: _toggleBiometric,
                                activeColor: AppColors.lightPrimary,
                              ),
                      );
                    },
                    loading: () => _SettingsTile(
                      icon: Icons.fingerprint,
                      title: 'Biometric Authentication',
                      subtitle: 'Checking availability...',
                      trailing: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => _SettingsTile(
                      icon: Icons.fingerprint,
                      title: 'Biometric Authentication',
                      subtitle: 'Error checking availability',
                      trailing: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Appearance Section
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Theme Toggle
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: isDarkMode ? 'Enabled' : 'Disabled',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).setThemeMode(
                              value ? AppThemeMode.dark : AppThemeMode.light,
                            );
                      },
                      activeColor: AppColors.lightPrimary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Profiles Section
                  const Text(
                    'Profiles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Manage Profiles Tile
                  Builder(
                    builder: (context) {
                      final profileState = ref.watch(profileProvider);
                      final profileCount = profileState.profiles.length;
                      final activeProfile = profileState.activeProfile;

                      return _SettingsTile(
                        icon: Icons.switch_account_outlined,
                        title: 'Manage Profiles',
                        subtitle: '$profileCount ${profileCount == 1 ? 'profile' : 'profiles'} • Active: ${activeProfile?.name ?? 'None'}',
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileManagementScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Manage Accounts Tile
                  Builder(
                    builder: (context) {
                      final accountState = ref.watch(accountProvider);
                      final accountCount = accountState.accounts.length;

                      return _SettingsTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Manage Accounts',
                        subtitle: '$accountCount ${accountCount == 1 ? 'account' : 'accounts'}',
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountManagementScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Manage Categories Tile
                  Builder(
                    builder: (context) {
                      final categoryState = ref.watch(categoryProvider);
                      final categoryCount = categoryState.categories.length;

                      return _SettingsTile(
                        icon: Icons.category_outlined,
                        title: 'Manage Categories',
                        subtitle: '$categoryCount ${categoryCount == 1 ? 'category' : 'categories'}',
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryManagementScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Manage EMIs Tile
                  Builder(
                    builder: (context) {
                      final emiState = ref.watch(emiProvider);
                      final emiCount = emiState.activeEmis.length;
                      final totalMonthly = emiState.totalMonthlyPayment;

                      return _SettingsTile(
                        icon: Icons.payments_outlined,
                        title: 'Manage EMIs',
                        subtitle: '$emiCount active ${emiCount == 1 ? 'EMI' : 'EMIs'}${totalMonthly > 0 ? ' • ₹${totalMonthly.toStringAsFixed(0)}/month' : ''}',
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmiListScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Account Section
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Out Button
                  _SettingsTile(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red,
                    ),
                    onTap: _handleSignOut,
                    titleColor: Colors.red,
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (titleColor ?? AppColors.lightPrimary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppColors.lightPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}
