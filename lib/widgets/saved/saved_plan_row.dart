import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

enum SavedPlanRowStatus { planned, completed }

/// Red za jedan sačuvan plan (Saved Plans ekran, Faza 5) — koristi se i za
/// online (Firestore) i offline (LocalPlanMirror) redove.
///
/// Kad su [onComplete] i/ili [onDelete] proslijeđeni, red je uvijen u
/// [Dismissible] za swipe akcije; ako je [onDelete] null (offline redovi
/// nemaju swipe akcije), prikazuje se obična kartica.
class SavedPlanRow extends StatelessWidget {
  const SavedPlanRow({
    super.key,
    required this.id,
    required this.status,
    required this.city,
    required this.days,
    required this.trailingLabel,
    required this.onTap,
    this.distanceKm,
    this.onComplete,
    this.onDelete,
  });

  final String id;
  final SavedPlanRowStatus status;
  final String city;
  final int days;
  final double? distanceKm;
  final String trailingLabel;
  final VoidCallback onTap;
  final Future<void> Function()? onComplete;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final row = _RowCard(
      status: status,
      city: city,
      days: days,
      distanceKm: distanceKm,
      trailingLabel: trailingLabel,
      onTap: onTap,
    );

    if (onDelete == null) return row;

    final canComplete = onComplete != null && status == SavedPlanRowStatus.planned;

    return Dismissible(
      key: ValueKey('dismiss_$id'),
      direction: canComplete ? DismissDirection.horizontal : DismissDirection.endToStart,
      background: canComplete
          ? const _SwipeBackground(
              alignment: Alignment.centerLeft,
              color: Colors.green,
              icon: Icons.check_circle_outline,
              label: 'Complete',
            )
          : const SizedBox.shrink(),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete_outline,
        label: 'Delete',
      ),
      confirmDismiss: (direction) => _confirmDismiss(context, direction, canComplete),
      child: row,
    );
  }

  Future<bool> _confirmDismiss(
    BuildContext context,
    DismissDirection direction,
    bool canComplete,
  ) async {
    if (direction == DismissDirection.startToEnd && canComplete) {
      try {
        await onComplete!();
        return true;
      } catch (_) {
        return false;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete plan?'),
        content: const Text(
          'This removes the plan from your saved list. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      await onDelete!();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.body.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.status,
    required this.city,
    required this.days,
    required this.trailingLabel,
    required this.onTap,
    this.distanceKm,
  });

  final SavedPlanRowStatus status;
  final String city;
  final int days;
  final double? distanceKm;
  final String trailingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == SavedPlanRowStatus.completed;
    final statusColor = isCompleted ? Colors.green : context.accent;
    final statusIcon = isCompleted ? Icons.check : Icons.map_outlined;

    final subtitleParts = <String>['$days days'];
    if (distanceKm != null) {
      subtitleParts.add('${distanceKm!.toStringAsFixed(0)} km');
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.cardStroke),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city, style: AppTypography.cardTitle.copyWith(color: context.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(trailingLabel, style: AppTypography.fieldLabel.copyWith(color: context.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
