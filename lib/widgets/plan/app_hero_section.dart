import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Port AppHeroSection.swift — parallax hero na vrhu MainScreen-a.
///
/// [scrollOffset] računa roditelj (main_screen.dart) preko ScrollController
/// i prosljeđuje ovdje; matematika (progress/eased/scale/blur) je 1:1
/// prevedena sa SwiftUI-a, samo koristeći Flutter Curves umjesto .easeOut.
class AppHeroSection extends StatelessWidget {
  const AppHeroSection({
    super.key,
    required this.scrollOffset,
    required this.title,
    this.imageAssetPath,
  });

  final double scrollOffset;
  final String title;
  final String? imageAssetPath;

  static const double height = 280;
  static const double _parallaxRange = 80;
  static const double _titleFadeRange = 120;
  static const double _titleBlurRange = 40;

  @override
  Widget build(BuildContext context) {
    final clampedOffset = scrollOffset < 0 ? 0.0 : scrollOffset;

    final progress = (clampedOffset / _parallaxRange).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(progress);
    final scale = 1.05 - (0.05 * eased);
    final blurSigma = eased * 6;

    final titleOpacity =
        (1 - (clampedOffset / _titleFadeRange)).clamp(0.0, 1.0);
    final titleBlur = (clampedOffset / _titleBlurRange).clamp(0.0, 6.0);

    return ClipRect(
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: scale,
              child: ImageFiltered(
                imageFilter:
                    ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: imageAssetPath != null
                    ? Image.asset(imageAssetPath!, fit: BoxFit.cover)
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [context.accent, AppColors.accentDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.05),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Opacity(
                opacity: titleOpacity,
                child: ImageFiltered(
                  imageFilter:
                      ui.ImageFilter.blur(sigmaX: titleBlur, sigmaY: titleBlur),
                  child: Text(
                    title,
                    style:
                        AppTypography.heroTitle.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
