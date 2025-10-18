import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';
import '../screens/profile_management_screen.dart';

class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.activeProfile;
    final profiles = profileState.profiles;

    if (activeProfile == null || profiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showProfileSwitcher(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          border: Border.all(
            color: context.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Icon
            Icon(
              Icons.account_circle_outlined,
              size: 20,
              color: context.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),

            // Profile Name
            Text(
              activeProfile.name,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),

            // Dropdown Icon
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSwitcher(BuildContext context, WidgetRef ref) {
    final profileState = ref.read(profileProvider);
    final profiles = profileState.profiles;
    final activeProfile = profileState.activeProfile;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeRadius),
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Title
            Text(
              'Switch Profile',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),

            // Profile List
            ...profiles.map((profile) {
              final isActive = profile.id == activeProfile?.id;

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? context.colorScheme.primaryContainer
                        : context.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 24,
                      color: isActive
                          ? context.colorScheme.onPrimaryContainer
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(
                  profile.name,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isActive
                    ? Icon(
                        Icons.check_circle,
                        color: context.colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  if (!isActive) {
                    await ref
                        .read(profileProvider.notifier)
                        .switchProfile(profile.id);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }),

            const SizedBox(height: AppConstants.spacingMd),

            // Manage Profiles Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Manage Profiles'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lightPrimary,
                  side: BorderSide(color: AppColors.lightPrimary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacingMd),
          ],
        ),
      ),
    );
  }
}
