import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'info_section_card.dart';

/// Ekvivalent MonetizationSection.swift — tekst identičan iOS-u iako
/// RevenueCat/Token Protection JOŠ NISU live na Androidu (Faza 8).
/// Namjerno — opisuje dogovoreni/budući sistem.
class MonetizationSection extends StatelessWidget {
  const MonetizationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InfoSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoSectionHeader(
              title: 'Monetization & Fairness',
              subtitle: 'Built to be sustainable — never intrusive.',
            ),
            SizedBox(height: AppSpacing.md),
            _MonetizationSubBlock(
              title: 'Free Plans',
              body:
                  'Free generations allow you to explore Vagabundo using a lightweight AI model for quick inspiration.',
            ),
            _MonetizationSubBlock(
              title: 'Pro AI Plans',
              body:
                  'Paid plans unlock a more advanced AI model, delivering deeper structure, refinement, and more detailed itineraries.',
            ),
            _MonetizationSubBlock(
              title: 'Token Protection System',
              body:
                  'If a generation fails due to a network interruption or unexpected issue, your credit is automatically preserved. Credits are deducted only after a successful itinerary is created. No double charges. No lost tokens.',
              isHighlighted: true,
            ),
            _MonetizationSubBlock(
              title: 'Affiliate Transparency',
              body:
                  'Some external booking links may generate a commission. These links never influence itinerary suggestions. Revenue supports infrastructure, AI usage, and continued development.',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonetizationSubBlock extends StatelessWidget {
  const _MonetizationSubBlock({
    required this.title,
    required this.body,
    this.isHighlighted = false,
    this.isLast = false,
  });

  final String title;
  final String body;
  final bool isHighlighted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(
              color: isHighlighted ? context.accent : context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTypography.body.copyWith(color: context.textPrimary)),
        ],
      ),
    );
  }
}
