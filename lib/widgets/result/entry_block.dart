import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../models/itinerary.dart';

/// Ekvivalent EntryBlock (private struct u ResultView.swift) — legacy
/// fallback prikaz kad `day.dayStructure == null`.
class EntryBlock extends StatelessWidget {
  const EntryBlock({super.key, required this.label, required this.item});

  /// Hardkodirano "Morning"/"Afternoon"/"Evening" iz poziva (l10n dolazi kasnije).
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
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: context.textPrimary)),
              const Spacer(),
              if (locationName.isNotEmpty)
                Flexible(
                  child: Text(
                    locationName,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary)),
          const SizedBox(height: 4),
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
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: context.chipBackground, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, size: 14, color: context.textPrimary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                carText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Text(rawLine, style: TextStyle(fontSize: 14, color: context.textPrimary));
  }
}
