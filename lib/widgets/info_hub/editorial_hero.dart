import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Ekvivalent EditorialHero.swift — brend uvod na vrhu InfoHubView-a.
class EditorialHero extends StatelessWidget {
  const EditorialHero({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 48, AppSpacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VAGABUNDO',
                style: AppTypography.fieldLabel.copyWith(
                  color: context.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Designed for curious travelers.',
                style: AppTypography.heroTitle.copyWith(color: context.textPrimary, fontSize: 32),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Intelligent itineraries. Thoughtfully crafted. Built with care.',
                style: AppTypography.body.copyWith(color: context.textSecondary),
              ),
              if (version.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Version $version', style: AppTypography.fieldLabel.copyWith(color: context.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.lg),
              Divider(color: context.cardStroke),
            ],
          ),
        );
      },
    );
  }
}
