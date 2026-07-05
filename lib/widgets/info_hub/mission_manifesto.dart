import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'info_section_card.dart';

/// Ekvivalent MissionManifesto.swift.
class MissionManifesto extends StatelessWidget {
  const MissionManifesto({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InfoSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoSectionHeader(
              title: 'Our Mission',
              subtitle: 'Travel should feel personal. Not automated.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vagabundo was created with a simple idea: technology should inspire exploration — not replace it.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Planning a journey should feel structured and exciting, not overwhelming or generic. Every itinerary is designed to provide clarity while leaving space for personal discovery.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vagabundo is not a booking engine. It is a companion for thoughtful travelers.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
