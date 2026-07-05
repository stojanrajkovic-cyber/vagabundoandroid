import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'info_section_card.dart';

/// Ekvivalent RoadmapSection.swift — SA IZMJENOM: "Offline access to saved
/// itineraries" i "Sharing and export capabilities" IZOSTAVLJENE (već
/// isporučene na Androidu u Fazi 4/5, pa ne idu u buduće stavke).
class RoadmapSection extends StatelessWidget {
  const RoadmapSection({super.key});

  static const _items = [
    'Light itinerary editing tools',
    'Expanded discovery features',
    'Continuous performance and AI improvements',
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
              title: 'Roadmap',
              subtitle: 'This is just the beginning.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vagabundo continues to evolve with careful improvements designed to enhance clarity, flexibility, and discovery.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in _items) InfoBulletRow(text: item),
          ],
        ),
      ),
    );
  }
}
