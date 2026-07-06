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
///
/// DODANO: animirana fade+slide tranzicija pri promjeni taba (tap na bottom
/// bar), smjer slide-a zavisi od toga ide li se "lijevo" ili "desno" kroz
/// redoslijed tabova — daje osjećaj swipe-a bez stvarnog drag gesture-a
/// (korisnikova odluka — samo animacija na tap, ne prevlačenje prstom).
class AppTabShell extends ConsumerStatefulWidget {
  const AppTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppTabShell> createState() => _AppTabShellState();
}

/// NAPOMENA (fix): prvobitna implementacija je koristila AnimatedSwitcher +
/// KeyedSubtree oko navigationShell-a — pucalo je sa "Duplicate GlobalKey"
/// jer AnimatedSwitcher tokom tranzicije drži staru I novu verziju child-a
/// ISTOVREMENO u stablu (da bi mogao da ih ukrsti), a navigationShell nosi
/// svoj interni GlobalKey (go_router-ova implementacija) — dvije kopije iste
/// instance sa istim GlobalKey-em u stablu odjednom = crash. Fix: JEDNA,
/// stalna instanca navigationShell-a u stablu, samo se njena providnost/
/// pozicija animira preko AnimationController-a koji se resetuje pri svakoj
/// promjeni taba — bez ikakvog dupliranja.
class _AppTabShellState extends ConsumerState<AppTabShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..value = 1.0;

  late Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late Animation<Offset> _slide = Tween<Offset>(
    begin: Offset.zero,
    end: Offset.zero,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.navigationShell),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: _FloatingTabBar(
          currentIndex: widget.navigationShell.currentIndex,
          isAuthenticated: isAuthenticated,
          onTap: _onTap,
        ),
      ),
    );
  }

  void _onTap(int index) {
    Haptics.light();
    final current = widget.navigationShell.currentIndex;

    if (index != current) {
      final movingForward = index >= current;
      _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
      _slide = Tween<Offset>(
        begin: Offset(movingForward ? 0.06 : -0.06, 0),
        end: Offset.zero,
      ).animate(_fade);
      _controller.forward(from: 0);
    }

    // initialLocation: true -> ako je tab već aktivan, vrati ga na root te grane
    // (ekvivalent guard selectedTab != index na iOS-u, samo dopušta i "pop to root")
    widget.navigationShell.goBranch(index, initialLocation: index == current);
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
    _TabDefinition(
        icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Plan'),
    _TabDefinition(
      icon: Icons.location_searching,
      activeIcon: Icons.location_searching,
      label: 'Explore',
    ),
    _TabDefinition(
        icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: 'Saved'),
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
        color: context.cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: context.cardStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
          color: isActive
              ? context.accent.withValues(alpha: 0.10)
              : Colors.transparent,
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
