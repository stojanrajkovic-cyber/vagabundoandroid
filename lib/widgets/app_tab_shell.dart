import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/spacing.dart';
import '../providers/auth_provider.dart';
import '../utils/haptics.dart';

/// Direktan ekvivalent AppTabShell.swift:
/// - ZStack(alignment: .bottom)          -> Scaffold(extendBody: true) + bottomNavigationBar
/// - safeAreaInset(edge: .bottom)        -> extendBody + SafeArea u tab baru
/// - Capsule + .regularMaterial + stroke -> DecoratedBox s blur/opacity + border
/// - selectedTab @State                  -> navigationShell.currentIndex (GoRouter)
/// - session.isAuthenticated             -> isAuthenticatedProvider (Riverpod)
class AppTabShell extends ConsumerWidget {
  const AppTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: _FloatingTabBar(
          currentIndex: navigationShell.currentIndex,
          isAuthenticated: isAuthenticated,
          onTap: (index) => _onTap(index),
        ),
      ),
    );
  }

  void _onTap(int index) {
    Haptics.light();
    // initialLocation: true -> ako je tab već aktivan, vrati ga na root te grane
    // (ekvivalent guard selectedTab != index na iOS-u, samo dopušta i "pop to root")
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _TabDefinition {
  const _TabDefinition({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.currentIndex,
    required this.isAuthenticated,
    required this.onTap,
  });

  final int currentIndex;
  final bool isAuthenticated;
  final ValueChanged<int> onTap;

  static const _staticItems = [
    _TabDefinition(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Plan'),
    _TabDefinition(
      icon: Icons.location_searching,
      activeIcon: Icons.location_searching,
      label: 'Explore',
    ),
    _TabDefinition(icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: 'Saved'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      ..._staticItems,
      _TabDefinition(
        icon: Icons.account_circle_outlined,
        activeIcon: Icons.account_circle,
        label: isAuthenticated ? 'Account' : 'Sign in',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardBackground.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: context.cardStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            return Expanded(
              child: _TabItem(
                icon: isActive ? item.activeIcon : item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.accent : context.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? context.accent.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
