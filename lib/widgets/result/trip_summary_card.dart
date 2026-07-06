import 'package:flutter/material.dart';

import '../../app/language.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';
import '../../services/affiliate/bike_rental_helper.dart';
import '../../services/affiliate/discover_cars_service.dart';
import '../../services/affiliate/stay22_service.dart';
import '../webview/in_app_webview_screen.dart';

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

  /// TODO: rent-a-car i rent-a-bike integracije — van obima za sada, ostaju
  /// disabled dok ne stignu odgovarajući affiliate fajlovi.
  void _showPlanToolsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanToolsSheet(itinerary: widget.itinerary),
    );
  }
}

class _PlanToolsSheet extends StatelessWidget {
  const _PlanToolsSheet({required this.itinerary});

  final ItineraryResponse itinerary;

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
              ListTile(
                leading: const Icon(Icons.bed_outlined),
                title: const Text('Find accommodation'),
                onTap: itinerary.cityLat == null || itinerary.cityLon == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        final url = Stay22Service.buildUrl(
                          lat: itinerary.cityLat!,
                          lon: itinerary.cityLon!,
                          languageCode: kAppLanguageCode,
                        );
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => InAppWebViewScreen(
                              url: url,
                              title: 'Accommodation in ${itinerary.city}',
                            ),
                          ),
                        );
                      },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: const Text('Rent a car'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => InAppWebViewScreen.html(
                        html: DiscoverCarsService.buildHtml(),
                        title: 'Rent a car',
                        baseUrl: 'https://www.discovercars.com',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.pedal_bike_outlined),
                title: const Text('Rent a bike'),
                onTap: () {
                  Navigator.pop(context);
                  BikeRentalHelper.openGoogleMapsSearch(itinerary.city);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
