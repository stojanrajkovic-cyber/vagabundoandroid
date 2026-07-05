import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'info_section_card.dart';

/// Ekvivalent HowVagabundoWorks.swift.
class HowVagabundoWorks extends StatelessWidget {
  const HowVagabundoWorks({super.key});

  static const _bullets = [
    'Organized clearly by day',
    'Structured by morning, afternoon, and evening',
    'Geographically aligned for practical movement',
    'Visualized on an interactive map',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InfoSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoSectionHeader(
              title: 'How Vagabundo Works',
              subtitle: 'From preference to plan — in seconds.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'You choose a destination, duration, and travel interests. Vagabundo processes your input through a specialized AI model built for structured itinerary generation.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final bullet in _bullets) InfoBulletRow(text: bullet),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Paid plans use a more advanced AI model for deeper refinement. Free plans use a lightweight model for quick inspiration. You remain in control at every step.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
