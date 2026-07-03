import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';

/// Ekvivalent EntryBlock (private struct u ResultView.swift) — legacy
/// fallback prikaz kad `day.dayStructure == null`.
class EntryBlock extends StatelessWidget {
  const EntryBlock({super.key, required this.label, required this.item});

  /// "Morning"/"Afternoon"/"Evening" iz poziva — app je engleski-only,
  /// nema l10n sistema (namjerna odluka).
  final String label;
  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final locationName = item.locationName ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: context.cardBackground, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTypography.cardTitle.copyWith(color: context.textPrimary)),
              const Spacer(),
              if (locationName.isNotEmpty)
                Flexible(
                  child: Text(
                    locationName,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(item.title, style: AppTypography.body.copyWith(color: context.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          _renderDescription(context, item.description),
        ],
      ),
    );
  }

  /// Ekvivalent renderDescription() iz ResultView.swift — prepoznaje linije
  /// koje počinju sa `[CAR]` i prikazuje ih sa auto ikonom u posebnom "chip"-u.
  Widget _renderDescription(BuildContext context, String text) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rawLine in lines) _renderLine(context, rawLine),
      ],
    );
  }

  Widget _renderLine(BuildContext context, String rawLine) {
    final trimmed = rawLine.trim();
    if (trimmed.startsWith('[CAR]')) {
      final carText = trimmed.substring('[CAR]'.length).trim();
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(color: context.chipBackground, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, size: 14, color: context.textPrimary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                carText,
                style: AppTypography.chip.copyWith(color: context.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Text(rawLine, style: AppTypography.body.copyWith(color: context.textPrimary));
  }
}
