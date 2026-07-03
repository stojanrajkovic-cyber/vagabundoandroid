import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/spacing.dart';
import '../app/theme/typography.dart';
import '../utils/haptics.dart';
import '../utils/sf_symbol_icons.dart';

/// Ekvivalent capsule chip-a korištenog za interese/trip pace (spomenut u
/// Fazi 1 arhitekturi kao lib/widgets/pill_chip.dart, sada implementiran).
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  final String label;

  /// SF Symbol naziv iz Interest.icon (npr. "fork.knife", "sparkles") —
  /// mapira se preko SfSymbolIcons.iconFor() na Flutter Material ikonicu.
  /// NIJE emoji/literal tekst za direktan prikaz.
  final String? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? context.accent.withValues(alpha: 0.10)
        : context.cardBackground;
    final foreground = isSelected ? context.accent : context.textPrimary;
    final border =
        isSelected ? context.accent.withValues(alpha: 0.4) : context.cardStroke;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        onTap: onTap == null
            ? null
            : () {
                Haptics.selection();
                onTap!();
              },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && icon!.isNotEmpty) ...[
                Icon(SfSymbolIcons.iconFor(icon!), size: 15, color: foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTypography.chip.copyWith(color: foreground),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: () {
                    Haptics.light();
                    onDelete!();
                  },
                  child: Icon(Icons.close, size: 14, color: foreground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
