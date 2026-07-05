import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/nearby_poi.dart';
import '../../providers/explore_provider.dart';
import '../../utils/haptics.dart';
import '../../widgets/explore/explore_map_view.dart';
import '../../widgets/explore/poi_detail_sheet.dart';
import '../../widgets/explore/poi_row.dart';
import '../../widgets/primary_button.dart';

/// Port ExploreResultsView.swift — segmented list/map toggle + "Explore
/// again" dugme na dnu koje restartuje cijeli flow preko controller.start().
///
/// NAPOMENA (fix): raniji layout je ugrađivao mapu FIKSNE visine (420px)
/// unutar scrollable roditelja (SingleChildScrollView u explore_screen.dart)
/// — mapa nije mogla zauzeti preostali prostor ekrana, a dugme je ostajalo
/// odmah ispod nje umjesto na dnu ekrana. Sad ovaj widget SAM upravlja
/// svojim prostorom preko Expanded (parent MORA dati bounded height, vidi
/// izmjenu u explore_screen.dart — SingleChildScrollView je uklonjen za
/// ExploreLoaded case).
class ExploreResultsScreen extends ConsumerStatefulWidget {
  const ExploreResultsScreen({super.key, required this.pois});

  final List<NearbyPOI> pois;

  @override
  ConsumerState<ExploreResultsScreen> createState() =>
      _ExploreResultsScreenState();
}

class _ExploreResultsScreenState extends ConsumerState<ExploreResultsScreen> {
  ExploreDisplayMode _mode = ExploreDisplayMode.list;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentedToggle(
          mode: _mode,
          onChanged: (mode) {
            Haptics.selection();
            setState(() => _mode = mode);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _mode == ExploreDisplayMode.list
              ? ListView.builder(
                  itemCount: widget.pois.length,
                  itemBuilder: (context, index) {
                    final poi = widget.pois[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: PoiRow(
                          poi: poi,
                          onTap: () => showPoiDetailSheet(context, poi)),
                    );
                  },
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: ExploreMapView(pois: widget.pois),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Explore again',
          onPressed: () {
            Haptics.light();
            ref.read(exploreControllerProvider.notifier).start();
          },
        ),
      ],
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.mode, required this.onChanged});

  final ExploreDisplayMode mode;
  final ValueChanged<ExploreDisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Row(
        children: [
          for (final option in ExploreDisplayMode.values)
            Expanded(
              child: _SegmentButton(
                label: option == ExploreDisplayMode.list ? 'List' : 'Map',
                isSelected: option == mode,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton(
      {required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? context.accent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.chip.copyWith(
            color: isSelected ? context.accent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
