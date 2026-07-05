import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Ekvivalent LegalFooterSection.swift — BEZ card pozadine, samo divider +
/// linkovi (kao u Swift originalu).
class LegalFooterSection extends StatelessWidget {
  const LegalFooterSection({super.key});

  static const _links = [
    ('Terms of Service', 'https://vagabundo.app/terms-of-service-tos/'),
    ('Privacy Policy', 'https://vagabundo.app/privacy-policy/'),
    ('AI Content Disclaimer', 'https://vagabundo.app/ai-content-disclaimer/'),
    ('Contact Support', 'mailto:support@vagabundo.app'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: context.cardStroke),
          for (final (label, url) in _links) _LegalLinkRow(label: label, url: url),
          const SizedBox(height: AppSpacing.md),
          Text(
            '© ${DateTime.now().year} Vagabundo',
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LegalLinkRow extends StatelessWidget {
  const _LegalLinkRow({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: AppTypography.body.copyWith(color: context.textPrimary)),
              ),
              Icon(Icons.arrow_outward, size: 18, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
