import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../providers/share_link_provider.dart';
import '../../services/share/share_link_service.dart';

/// Port ManageShareLinkView.swift — prikazan kao bottom sheet iz ResultScreen-a
/// (share dugme u AppBar-u), umjesto posebne rute (jednostavnije za Fazu 5).
class ManageShareLinkSheet extends ConsumerStatefulWidget {
  const ManageShareLinkSheet({super.key, required this.initialShare});

  final ShareInfo initialShare;

  @override
  ConsumerState<ManageShareLinkSheet> createState() => _ManageShareLinkSheetState();
}

class _ManageShareLinkSheetState extends ConsumerState<ManageShareLinkSheet> {
  late ShareInfo _share = widget.initialShare;
  bool _isUpdating = false;
  bool _isDeleting = false;

  Future<void> _handleToggle(bool enabled) async {
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(shareLinkServiceProvider)
          .setRevoked(token: _share.id, revoked: !enabled);
      if (!mounted) return;
      setState(() => _share = _share.copyWith(revoked: !enabled));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update link: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      await ref.read(shareLinkServiceProvider).deleteShare(token: _share.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
          border: Border.all(color: context.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.cardStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Share plan', style: AppTypography.sectionTitle.copyWith(color: context.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Anyone with this link can view a read-only copy of your plan.',
              style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: !_share.revoked,
              onChanged: _isUpdating ? null : _handleToggle,
              activeThumbColor: context.accent,
              title: Text(
                'Public link enabled',
                style: AppTypography.body.copyWith(color: context.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _handleDelete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.delete_outline, color: Colors.red),
                label: Text('Delete link', style: AppTypography.button.copyWith(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
