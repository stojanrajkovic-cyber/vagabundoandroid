import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/typography.dart';
import '../../models/itinerary.dart';
import '../../utils/haptics.dart';

/// Ekvivalent SegmentTimelineSelector.swift — ISTA ikona za sva tri segmenta
/// ("arrow.forward.circle.fill" sa palette rendering: bijela strelica na
/// ochre/gray4 pozadini kad je (ne)selektovano), NE tri različite ikone.
/// Divider (Rectangle height 1, maxWidth infinity) razvlači se IZMEĐU
/// dugmadi fiksne širine — isto ponašanje kao Swift HStack.
class SegmentTimelineSelector extends StatelessWidget {
  const SegmentTimelineSelector({super.key, required this.selected, required this.onSelect});

  final DayPart selected;
  final ValueChanged<DayPart> onSelect;

  static const Map<DayPart, String> _labels = {
    DayPart.morning: 'Morning',
    DayPart.afternoon: 'Afternoon',
    DayPart.evening: 'Evening',
  };

  // Ekvivalent Color(.systemGray4).
  static const Color _unselectedBadge = Color(0xFFD1D1D6);

  @override
  Widget build(BuildContext context) {
    const parts = DayPart.values;
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      children.add(_segmentButton(context, parts[i]));
      if (parts[i] != DayPart.evening) {
        children.add(
          Expanded(
            child: Container(height: 1, color: context.textSecondary.withValues(alpha: 0.3)),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _segmentButton(BuildContext context, DayPart part) {
    final isSelected = part == selected;
    final badgeColor = isSelected ? context.accent : _unselectedBadge;

    return InkWell(
      onTap: () {
        Haptics.light();
        onSelect(part);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _labels[part]!,
            style: AppTypography.fieldLabel.copyWith(
              color: isSelected ? context.textPrimary : context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
