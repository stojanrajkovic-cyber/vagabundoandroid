import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../models/itinerary.dart';
import '../../providers/plan_config_provider.dart';
import '../../utils/haptics.dart';

/// Port tripPaceSection iz MainView.swift — 3 dugmeta (TripPace.values),
/// horizontalno, isti stil selekcije kao _TabItem u app_tab_shell.dart.
class TripPaceSelector extends ConsumerWidget {
  const TripPaceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(planConfigProvider).tripPace;
    final notifier = ref.read(planConfigProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Row(
        children: [
          for (final pace in TripPace.values)
            Expanded(
              child: _PaceButton(
                pace: pace,
                isSelected: pace == selected,
                onTap: () {
                  Haptics.selection();
                  notifier.setTripPace(pace);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PaceButton extends StatelessWidget {
  const _PaceButton({required this.pace, required this.isSelected, required this.onTap});

  final TripPace pace;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label {
    switch (pace) {
      case TripPace.relaxed:
        return 'Relaxed';
      case TripPace.balanced:
        return 'Balanced';
      case TripPace.packed:
        return 'Packed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.accent : context.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? context.accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
        child: Text(
          _label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
