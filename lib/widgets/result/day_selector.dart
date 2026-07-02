import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../models/itinerary.dart';
import '../../utils/haptics.dart';

/// Ekvivalent daySelector + circleLabel iz ResultView.swift.
class DaySelector extends StatelessWidget {
  const DaySelector({super.key, required this.itinerary, required this.selectedPageIndex, required this.onSelect});

  final ItineraryResponse itinerary;
  final int selectedPageIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final hasRoadTrip = itinerary.roadTrip != null;
    final baseIndex = hasRoadTrip ? 1 : 0;
    final itemCount = itinerary.days.length + (hasRoadTrip ? 1 : 0);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (hasRoadTrip && i == 0) {
            return _CirclePill(
              isSelected: selectedPageIndex == 0,
              onTap: () => onSelect(0),
              child: const Icon(Icons.directions_car, size: 15),
            );
          }

          final dayIndex = i - baseIndex;
          final pageIndex = dayIndex + baseIndex;
          return _CirclePill(
            isSelected: selectedPageIndex == pageIndex,
            onTap: () => onSelect(pageIndex),
            child: Text(selectedPageIndex == pageIndex ? 'Day ${dayIndex + 1}' : '${dayIndex + 1}'),
          );
        },
      ),
    );
  }
}

class _CirclePill extends StatelessWidget {
  const _CirclePill({required this.isSelected, required this.onTap, required this.child});

  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fill = isSelected ? context.daySelectorSelectedFill : context.daySelectorUnselectedFill;
    final stroke = isSelected ? context.daySelectorSelectedStroke : context.daySelectorUnselectedStroke;
    final textColor = isSelected ? context.daySelectorSelectedText : context.daySelectorUnselectedText;

    return GestureDetector(
      onTap: () {
        Haptics.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: 36,
        constraints: const BoxConstraints(minWidth: 38),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: stroke, width: 1.5),
        ),
        child: DefaultTextStyle(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
          child: IconTheme(data: IconThemeData(color: textColor, size: 15), child: child),
        ),
      ),
    );
  }
}
