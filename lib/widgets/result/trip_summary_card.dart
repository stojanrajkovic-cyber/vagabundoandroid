import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';

/// Ekvivalent tripSummaryCard iz ResultView.swift.
///
/// StatefulWidget (bilo StatelessWidget) — dodano tap-to-expand za summary
/// tekst koji je znao biti presječen na 3 linije bez načina da se pročita
/// ostatak.
class TripSummaryCard extends StatefulWidget {
  const TripSummaryCard({super.key, required this.itinerary});

  final ItineraryResponse itinerary;

  @override
  State<TripSummaryCard> createState() => _TripSummaryCardState();
}

class _TripSummaryCardState extends State<TripSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;
    final summary = itinerary.summary?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
        boxShadow: [
          BoxShadow(
              color: AppColors.cerulean.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6)),
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
                      style: AppTypography.bodySecondary
                          .copyWith(color: context.textSecondary),
                    ),
                    Text('•',
                        style: AppTypography.bodySecondary
                            .copyWith(color: context.textSecondary)),
                    Text('${itinerary.days.length} days',
                        style: AppTypography.bodySecondary
                            .copyWith(color: context.textSecondary)),
                    if (itinerary.pace != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: context.chipSelectedBackground,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.pillRadius),
                        ),
                        child: Text(
                          _paceLabel(itinerary.pace!),
                          style: AppTypography.chip
                              .copyWith(color: context.chipSelectedText),
                        ),
                      ),
                  ],
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          alignment: Alignment.topLeft,
                          child: Text(
                            summary,
                            maxLines: _isExpanded ? null : 3,
                            overflow: _isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: AppTypography.bodySecondary
                                .copyWith(color: context.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isExpanded ? 'Show less' : 'Show more',
                          style: AppTypography.bodySecondary.copyWith(
                            color: context.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showPlanToolsSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: context.accent.withValues(alpha: 0.10),
                      shape: BoxShape.circle),
                  child: Icon(Icons.handyman_outlined,
                      size: 18, color: context.accent),
                ),
              ),
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

  /// TODO: prava Plan Tools funkcionalnost (Stay22 smještaj, rent-a-car,
  /// rent-a-bike integracije) — van obima za sada, ovo je samo UI
  /// acknowledgment da dugme "radi" umjesto da izgleda mrtvo/pokvareno.
  void _showPlanToolsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PlanToolsSheet(),
    );
  }
}

class _PlanToolsSheet extends StatelessWidget {
  const _PlanToolsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadius)),
          border: Border.all(color: context.cardStroke),
        ),
        // ListTile crta ink splash-eve na najbližem Material predaku — bez ovoga
        // Flutter baca "background color or ink splashes may be invisible" (jer
        // je Container iznad DecoratedBox sa bojom).
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.cardStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Plan tools',
                    style: AppTypography.sectionTitle
                        .copyWith(color: context.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const ListTile(
                leading: Icon(Icons.bed_outlined),
                title: Text('Find accommodation'),
                trailing: Text('Coming soon', style: TextStyle(fontSize: 11)),
                enabled: false,
              ),
              const ListTile(
                leading: Icon(Icons.directions_car_outlined),
                title: Text('Rent a car'),
                trailing: Text('Coming soon', style: TextStyle(fontSize: 11)),
                enabled: false,
              ),
              const ListTile(
                leading: Icon(Icons.pedal_bike_outlined),
                title: Text('Rent a bike'),
                trailing: Text('Coming soon', style: TextStyle(fontSize: 11)),
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
