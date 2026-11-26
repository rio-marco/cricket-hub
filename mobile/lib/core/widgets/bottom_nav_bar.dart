import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Navigation item definition for CricketBottomNavBar.
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? badge;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badge,
  });
}

/// Beautiful Material 3 Bottom Navigation Bar for Cricket Hub with 5 primary destinations:
/// Home, Matches, Tournaments, Teams, and Profile.
class CricketBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const CricketBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    BottomNavItem(
      label: 'Matches',
      icon: Icons.sports_cricket_outlined,
      selectedIcon: Icons.sports_cricket_rounded,
    ),
    BottomNavItem(
      label: 'Tournaments',
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
    ),
    BottomNavItem(
      label: 'Teams',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
    BottomNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  static const BottomNavItem adminItem = BottomNavItem(
    label: 'Admin',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings_rounded,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navItems = <BottomNavItem>[...items, if (isAdmin) adminItem];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 0.8,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withOpacity(isDark ? 0.22 : 0.12),
        destinations: navItems.map((item) {
          Widget iconWidget = Icon(
            item.icon,
            size: 24,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          );

          Widget selectedIconWidget = Icon(
            item.selectedIcon,
            size: 24,
            color: AppColors.primary,
          );

          if (item.badge != null) {
            iconWidget = Badge(
              label: Text(item.badge!),
              backgroundColor: AppColors.primary,
              child: iconWidget,
            );
            selectedIconWidget = Badge(
              label: Text(item.badge!),
              backgroundColor: AppColors.primary,
              child: selectedIconWidget,
            );
          }

          return NavigationDestination(
            icon: iconWidget,
            selectedIcon: selectedIconWidget,
            label: item.label,
            tooltip: item.label,
          );
        }).toList(),
      ),
    );
  }
}
