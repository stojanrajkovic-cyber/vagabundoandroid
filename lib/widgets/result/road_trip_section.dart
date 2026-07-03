import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';

/// Ekvivalent RoadTripSection iz ResultView.swift — POJEDNOSTAVLJENA verzija
/// za v1 (vidi Fase 4 obim): prosta lista segmenata (ikona + label + minuti +
/// adresa), BEZ mape/rute i BEZ MiniRoadMap-a.
class RoadTripSection extends StatelessWidget {
  const RoadTripSection({super.key, required this.trip});

  final RoadTripPlan trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: context.cardBackground, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: context.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text('Road trip', style: AppTypography.sectionTitle.copyWith(color: context.textPrimary)),
            ],
          ),
          if (trip.origin != null && trip.destination != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${trip.origin} → ${trip.destination}', style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
          ],
          if (trip.totalDistanceKm != null && trip.totalDurationMin != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${trip.totalDistanceKm!.toStringAsFixed(1)} km · ${(trip.totalDurationMin! / 60).toStringAsFixed(1)} h total',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final day in trip.days) _dayCard(context, day),
        ],
      ),
    );
  }

  Widget _dayCard(BuildContext context, RoadTripDay day) {
    final title = day.title?.trim() ?? '';
    final subtitle = day.subtitle?.trim() ?? '';
    final segments = day.segments ?? const <DriveLeg>[];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day ${day.dayNumber}', style: AppTypography.cardTitle.copyWith(color: context.textPrimary)),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(title, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
            ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (segments.isNotEmpty)
            for (final seg in segments) _segmentRow(context, seg)
          else
            Text('No segments available.', style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }

  Widget _segmentRow(BuildContext context, DriveLeg seg) {
    final IconData icon;
    switch (seg.kind) {
      case DriveLegKind.drive:
        icon = Icons.directions_car_filled;
        break;
      case DriveLegKind.stop:
        icon = Icons.local_cafe_outlined;
        break;
      case DriveLegKind.overnight:
        icon = Icons.bed_outlined;
        break;
    }

    final label = seg.placeName ?? seg.label ?? '';
    final address = seg.address?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ${_minutesToText(seg.minutes)}'.trim(),
                  style: AppTypography.body.copyWith(color: context.textPrimary),
                ),
                if (address.isNotEmpty)
                  Text(address, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _minutesToText(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    return h > 0 ? '${h}h${mm == 0 ? '' : ' ${mm}m'}' : '${mm}m';
  }
}
