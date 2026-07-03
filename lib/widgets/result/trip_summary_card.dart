import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';

/// Ekvivalent tripSummaryCard iz ResultView.swift.
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({super.key, required this.itinerary});

  final ItineraryResponse itinerary;

  @override
  Widget build(BuildContext context) {
    final summary = itinerary.summary?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
        boxShadow: [
          BoxShadow(color: AppColors.cerulean.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      itinerary.country,
                      style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                    ),
                    Text('•', style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
                    Text('${itinerary.days.length} days', style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
                    if (itinerary.pace != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: context.chipSelectedBackground,
                          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                        ),
                        child: Text(
                          _paceLabel(itinerary.pace!),
                          style: AppTypography.chip.copyWith(color: context.chipSelectedText),
                        ),
                      ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySecondary.copyWith(color: context.textPrimary),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            // TODO: plan tools meni (Stay22, rent-a-car, packing guide) — van
            // obima za Fazu 4, samo placeholder ikona za sada.
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: context.accent.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(Icons.handyman_outlined, size: 18, color: context.accent.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  String _paceLabel(TripPace pace) {
    switch (pace) {
      case TripPace.relaxed:
        return 'Relaxed';
      case TripPace.balanced:
        return 'Balanced';
      case TripPace.packed:
        return 'Packed';
    }
  }
}
