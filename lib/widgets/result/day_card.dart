import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../models/itinerary.dart';
import '../../utils/haptics.dart';
import 'day_map_view.dart';
import 'day_structured_section.dart';
import 'entry_block.dart';

/// Ekvivalent DayCard (private struct u ResultView.swift) — DayMapView +
/// "Expand map" dugme + uslovno DayStructuredSection ili EntryBlock fallback.
class DayCard extends StatefulWidget {
  const DayCard({
    super.key,
    required this.day,
    required this.fallbackCenter,
    required this.onSelectPart,
    required this.isReadOnly,
    required this.isSavedPlan,
    required this.isGeneratingAltVariant,
    required this.generatingAltDayNumber,
    required this.onRequestAlternative,
    this.onPersistPlan,
  });

  final ItineraryDay day;
  final LatLng? fallbackCenter;
  final ValueChanged<DayPart> onSelectPart;
  final bool isReadOnly;
  final bool isSavedPlan;
  final bool isGeneratingAltVariant;
  final int? generatingAltDayNumber;
  final Future<DayVariant> Function(int dayNumber) onRequestAlternative;
  final VoidCallback? onPersistPlan;

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  DayPart? _selectedPart;

  void _handleSelectPart(DayPart part) {
    setState(() => _selectedPart = part);
    widget.onSelectPart(part);
  }

  void _openFullScreenMap() {
    Haptics.light();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenMapPage(
          day: widget.day,
          fallbackCenter: widget.fallbackCenter,
          highlightedPart: _selectedPart,
          dayNumber: widget.day.dayNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DayMapView(
            // Forsira novi State (novi onMapCreated fit) kad se activeVariantIndex
            // promijeni — vidi napomenu u day_map_view.dart.
            key: ValueKey(widget.day.activeVariantIndex),
            day: widget.day,
            fallbackCenter: widget.fallbackCenter,
            highlightedPart: _selectedPart,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openFullScreenMap,
            icon: const Icon(Icons.open_in_full, size: 14),
            label: const Text('Expand map', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 10),
          if (widget.day.dayStructure != null)
            DayStructuredSection(
              day: widget.day,
              onSelectPart: _handleSelectPart,
              isReadOnly: widget.isReadOnly,
              isSavedPlan: widget.isSavedPlan,
              onRequestAlternative: widget.onRequestAlternative,
              isGeneratingAltVariant: widget.isGeneratingAltVariant,
              generatingAltDayNumber: widget.generatingAltDayNumber,
              onPersistPlan: widget.onPersistPlan,
            )
          else ...[
            GestureDetector(
              onTap: () => _handleSelectPart(DayPart.morning),
              child: EntryBlock(label: 'Morning', item: widget.day.morningItem),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _handleSelectPart(DayPart.afternoon),
              child: EntryBlock(label: 'Afternoon', item: widget.day.afternoonItem),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _handleSelectPart(DayPart.evening),
              child: EntryBlock(label: 'Evening', item: widget.day.eveningItem),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ekvivalent `.sheet(item: $fullMapDay)` iz ResultView.swift — full-screen
/// ruta sa `DayMapView(isExpanded: true)`.
class _FullScreenMapPage extends StatelessWidget {
  const _FullScreenMapPage({
    required this.day,
    required this.fallbackCenter,
    required this.highlightedPart,
    required this.dayNumber,
  });

  final ItineraryDay day;
  final LatLng? fallbackCenter;
  final DayPart? highlightedPart;
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Day $dayNumber'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
      body: DayMapView(day: day, fallbackCenter: fallbackCenter, highlightedPart: highlightedPart, isExpanded: true),
    );
  }
}
