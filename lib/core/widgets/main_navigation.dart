import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';

/// Main navigation scaffold with modern bottom navigation bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Navigation screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const TransactionListScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  // Navigation items data
  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
    _NavItem(icon: Icons.analytics_rounded, label: 'Analytics'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if device has bottom system UI (home indicator or navigation bar)
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasSystemNavigation = bottomPadding > 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _navItems.length,
                  (index) => _NavBarItem(
                    icon: _navItems[index].icon,
                    label: _navItems[index].label,
                    isSelected: _currentIndex == index,
                    isDarkMode: isDarkMode,
                    onTap: () => setState(() => _currentIndex = index),
                  ),
                ),
              ),
            ),
            // Add smart bottom padding
            // For iPhone home indicator: use half padding (looks cleaner)
            // For Android nav buttons: use full padding (needs more space)
            if (hasSystemNavigation)
              SizedBox(height: bottomPadding * 0.5) // 50% of system padding
            else
              const SizedBox(height: 4), // Minimal padding for devices without system nav
          ],
        ),
      ),
    );
  }
}

/// Navigation item data class
class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}

/// Modern navigation bar item widget with label
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : (isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600]),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
