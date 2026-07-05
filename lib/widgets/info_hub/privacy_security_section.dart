import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'info_section_card.dart';

/// Ekvivalent PrivacySecuritySection.swift.
class PrivacySecuritySection extends StatelessWidget {
  const PrivacySecuritySection({super.key});

  static const _bullets = [
    'Encrypted communication between app and server',
    'Secure authentication via trusted providers',
    'Account deletion available at any time',
    'Clear and transparent privacy policies',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: InfoSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoSectionHeader(
              title: 'Privacy & Security',
              subtitle: 'Your data stays yours.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Vagabundo uses secure authentication systems and encrypted connections to protect your account.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We do not track your real-time location without explicit permission.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We do not sell personal data or share identifiable information with third parties.',
              style: AppTypography.body.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final bullet in _bullets) InfoBulletRow(text: bullet),
          ],
        ),
      ),
    );
  }
}
