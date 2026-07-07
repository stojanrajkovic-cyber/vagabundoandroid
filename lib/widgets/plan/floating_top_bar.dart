import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Ekvivalent TopBarView.swift (iOS) — floating traka sa logom/brendingom,
/// review dugmetom i settings dugmetom, koja se skuplja pri scroll-u.
/// Ista scroll-driven shrink matematika kao AppHeroSection (parallax).
class FloatingTopBar extends StatelessWidget {
  const FloatingTopBar({
    super.key,
    required this.scrollOffset,
    this.onReviewTap,
    this.onSettingsTap,
  });

  final double scrollOffset;
  final VoidCallback? onReviewTap;
  final VoidCallback? onSettingsTap;

  static const double _shrinkRange = 80;
  static const double _maxHeight = 56;
  static const double _minHeight = 44;

  @override
  Widget build(BuildContext context) {
    final clamped = scrollOffset < 0 ? 0.0 : scrollOffset;
    final progress = (clamped / _shrinkRange).clamp(0.0, 1.0);
    final height = _maxHeight - ((_maxHeight - _minHeight) * progress);
    final logoSize = 26.0 - (6.0 * progress);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.accent,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset('assets/images/logo.png',
                  width: logoSize, height: logoSize),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Vagabundo',
                  style: AppTypography.cardTitle.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onReviewTap,
                icon: const Icon(Icons.star_outline, color: Colors.white),
                tooltip: 'Rate Vagabundo',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Settings',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
