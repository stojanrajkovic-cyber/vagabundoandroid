import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Prikazuje se SAMO kad NIJE offline i ima planiranih (planned) planova
/// koji nemaju lokalnu kopiju (vidi SavedPlansProvider.missingOfflineIds).
class OfflineSyncBanner extends StatelessWidget {
  const OfflineSyncBanner({
    super.key,
    required this.count,
    required this.isSyncing,
    required this.onSyncTap,
  });

  final int count;
  final bool isSyncing;
  final VoidCallback onSyncTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: context.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'plan' : 'plans'} not available offline',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
          ),
          TextButton(
            onPressed: isSyncing ? null : onSyncTap,
            child: isSyncing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.accent),
                  )
                : Text(
                    'Sync now',
                    style: AppTypography.body.copyWith(color: context.accent, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
