import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/feedback_item.dart';
import '../primary_button.dart';
import '../settings/feedback_sheet.dart';
import 'info_section_card.dart';

/// Ekvivalent FeedbackCTASection.swift.
class FeedbackCtaSection extends StatelessWidget {
  const FeedbackCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InfoSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoSectionHeader(
              title: 'Help Shape Vagabundo',
              subtitle: 'Thoughtful feedback builds better journeys.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'If you encounter an issue, have an idea, or want to suggest an improvement, we would love to hear from you.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Report a Bug',
              onPressed: () => showFeedbackSheet(context, initialType: FeedbackType.bug),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => showFeedbackSheet(context, initialType: FeedbackType.idea),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.cardStroke),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                ),
                child: Text(
                  'Suggest a Feature',
                  style: AppTypography.button.copyWith(color: context.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
