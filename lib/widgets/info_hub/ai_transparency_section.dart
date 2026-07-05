import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'info_section_card.dart';

/// Ekvivalent AITransparencySection.swift.
class AiTransparencySection extends StatelessWidget {
  const AiTransparencySection({super.key});

  static const _warnings = [
    'Verify opening hours before visiting.',
    'Confirm ticket availability in advance.',
    'Check seasonal closures and local regulations.',
    'Consult official sources when making critical decisions.',
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
              title: 'AI Transparency',
              subtitle: 'AI is powerful — but not infallible.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vagabundo uses advanced language models to generate travel itineraries tailored to your preferences.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'While these systems are highly capable, they may occasionally produce outdated, incomplete, or imprecise information.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vagabundo does not access real-time booking systems and does not guarantee availability or operational accuracy.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final warning in _warnings) InfoWarningRow(text: warning),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Think of Vagabundo as a structured guide — not a final authority. Your judgment always comes first.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
