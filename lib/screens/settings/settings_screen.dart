import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/google_link_service.dart';
import '../../services/settings/app_settings_store.dart';
import '../../widgets/settings/feedback_sheet.dart';

/// Ekvivalent Settings.swift (port sa dogovorenim promjenama obima —
/// vidi zadatak). Linked accounts (Google-only), haptic/sound feedback,
/// appearance, feedback sheet i sign out.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isGoogleLinked = false;
  bool _isGoogleBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshGoogleLinkStatus();
  }

  void _refreshGoogleLinkStatus() {
    final service = ref.read(googleLinkServiceProvider);
    setState(() => _isGoogleLinked = service.isGoogleLinked());
  }

  Future<void> _toggleGoogleLink() async {
    final service = ref.read(googleLinkServiceProvider);
    setState(() => _isGoogleBusy = true);
    try {
      if (_isGoogleLinked) {
        await service.unlinkGoogle();
      } else {
        await service.linkGoogle();
      }
      _refreshGoogleLinkStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isGoogleBusy = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/plan');
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final settings = ref.watch(appSettingsProvider);
    final settingsController = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          if (isAuthenticated) ...[
            const _SectionHeader(title: 'Linked accounts'),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.cardBackground,
                child: Text(
                  'G',
                  style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
                ),
              ),
              title: Text('Google', style: AppTypography.body.copyWith(color: context.textPrimary)),
              trailing: _isGoogleBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _toggleGoogleLink,
                      child: Text(_isGoogleLinked ? 'Unlink' : 'Link'),
                    ),
            ),
            const Divider(height: AppSpacing.xl),
          ],
          const _SectionHeader(title: 'Feedback & feel'),
          SwitchListTile(
            title: Text('Haptics', style: AppTypography.body.copyWith(color: context.textPrimary)),
            value: settings.hapticsEnabled,
            onChanged: settingsController.setHapticsEnabled,
          ),
          SwitchListTile(
            title: Text('Sound', style: AppTypography.body.copyWith(color: context.textPrimary)),
            value: settings.soundEnabled,
            onChanged: settingsController.setSoundEnabled,
          ),
          if (settings.soundEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.volume_down, color: context.textSecondary),
                  Expanded(
                    child: Slider(
                      value: settings.soundVolume,
                      onChanged: settingsController.setSoundVolume,
                    ),
                  ),
                  Icon(Icons.volume_up, color: context.textSecondary),
                ],
              ),
            ),
          const Divider(height: AppSpacing.xl),
          const _SectionHeader(title: 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: Border.all(color: context.cardStroke),
              ),
              child: Row(
                children: [
                  for (final mode in AppThemeMode.values)
                    Expanded(
                      child: _ThemeModeButton(
                        mode: mode,
                        isSelected: mode == settings.themeMode,
                        onTap: () => settingsController.setThemeMode(mode),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text('Send feedback', style: AppTypography.body.copyWith(color: context.textPrimary)),
            onTap: () => showFeedbackSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.fieldLabel.copyWith(color: context.textSecondary),
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
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
          style: AppTypography.chip.copyWith(color: color),
        ),
      ),
    );
  }
}
