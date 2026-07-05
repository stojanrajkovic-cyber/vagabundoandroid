import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/google_link_service.dart';
import '../../services/settings/app_settings_store.dart';
import '../../widgets/settings/feedback_sheet.dart';

/// Ekvivalent Settings.swift (port sa dogovorenim promjenama obima).
///
/// REDIZAJN: svaka sekcija je sad kartica (context.cardBackground +
/// AppSpacing.cardRadius + border + sjena) — isti vizuelni jezik kao
/// TripSummaryCard/PlanOptionsView na Main/Result ekranima, umjesto
/// plosnate ListView/Divider strukture od ranije.
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

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final settings = ref.watch(appSettingsProvider);
    final settingsController = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          if (isAuthenticated) ...[
            const _SectionHeader(title: 'Linked accounts'),
            _SettingsCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.accent.withValues(alpha: 0.10),
                    child: Text(
                      'G',
                      style: AppTypography.cardTitle
                          .copyWith(color: context.accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Google',
                      style: AppTypography.body
                          .copyWith(color: context.textPrimary),
                    ),
                  ),
                  _isGoogleBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _toggleGoogleLink,
                          child: Text(
                            _isGoogleLinked ? 'Unlink' : 'Link',
                            style: AppTypography.body.copyWith(
                              color: context.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          const _SectionHeader(title: 'Feedback & feel'),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsSwitchRow(
                  label: 'Haptics',
                  value: settings.hapticsEnabled,
                  onChanged: settingsController.setHapticsEnabled,
                ),
                const _CardDivider(),
                _SettingsSwitchRow(
                  label: 'Sound',
                  value: settings.soundEnabled,
                  onChanged: settingsController.setSoundEnabled,
                ),
                if (settings.soundEnabled) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.volume_down,
                          size: 18, color: context.textSecondary),
                      Expanded(
                        child: Slider(
                          value: settings.soundVolume,
                          activeColor: context.accent,
                          onChanged: settingsController.setSoundVolume,
                        ),
                      ),
                      Icon(Icons.volume_up,
                          size: 18, color: context.textSecondary),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader(title: 'Appearance'),
          _SettingsCard(
            padding: const EdgeInsets.all(AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.lg),
          _SettingsCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsActionRow(
                  icon: Icons.info_outline,
                  label: 'About & transparency',
                  onTap: () => context.push('/about'),
                ),
                const _CardDivider(indent: true),
                _SettingsActionRow(
                  icon: Icons.feedback_outlined,
                  label: 'Send feedback',
                  onTap: () => showFeedbackSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Zajednički card container — isti stil kao TripSummaryCard/PlanOptionsView.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.cerulean.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
          AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.fieldLabel.copyWith(color: context.textSecondary),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider({this.indent = false});

  final bool indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: indent ? AppSpacing.lg : 0,
        right: indent ? AppSpacing.lg : 0,
      ),
      child: Divider(height: AppSpacing.md, color: context.cardStroke),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: AppTypography.body.copyWith(color: context.textPrimary)),
        ),
        Switch(value: value, activeThumbColor: context.accent, onChanged: onChanged),
      ],
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Text(label, style: AppTypography.body.copyWith(color: color)),
            ],
          ),
        ),
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
          color: isSelected
              ? context.accent.withValues(alpha: 0.10)
              : Colors.transparent,
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
