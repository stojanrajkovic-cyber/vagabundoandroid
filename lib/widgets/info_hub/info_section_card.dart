import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Zajednički card container za InfoHub sekcije — isti vizuelni jezik kao
/// ostatak app-a (context.cardBackground + AppSpacing.cardRadius + border).
class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: child,
    );
  }
}

/// Naslov + podnaslov korišten na vrhu skoro svake InfoHub kartice.
class InfoSectionHeader extends StatelessWidget {
  const InfoSectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.sectionTitle.copyWith(color: context.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTypography.cardTitle.copyWith(color: context.textSecondary)),
      ],
    );
  }
}

/// Bullet red sa kružnom tačkom u accent boji (Zadatak 3/6/7).
class InfoBulletRow extends StatelessWidget {
  const InfoBulletRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: context.accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.body.copyWith(color: context.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// "Warning" red sa uskom vertikalnom trakom u accent boji — vizuelno
/// različito od InfoBulletRow (Zadatak 4).
class InfoWarningRow extends StatelessWidget {
  const InfoWarningRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: context.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.body.copyWith(color: context.textPrimary)),
          ),
        ],
      ),
    );
  }
}
