import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';
import '../../widgets/info_hub/ai_transparency_section.dart';
import '../../widgets/info_hub/editorial_hero.dart';
import '../../widgets/info_hub/feedback_cta_section.dart';
import '../../widgets/info_hub/how_vagabundo_works.dart';
import '../../widgets/info_hub/legal_footer_section.dart';
import '../../widgets/info_hub/mission_manifesto.dart';
import '../../widgets/info_hub/monetization_section.dart';
import '../../widgets/info_hub/privacy_security_section.dart';
import '../../widgets/info_hub/roadmap_section.dart';

/// Ekvivalent InfoHubView.swift (About/Transparency) — 9 pod-sekcija.
class InfoHubScreen extends StatelessWidget {
  const InfoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Vagabundo')),
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditorialHero(),
            SizedBox(height: AppSpacing.xl),
            MissionManifesto(),
            SizedBox(height: AppSpacing.lg),
            HowVagabundoWorks(),
            SizedBox(height: AppSpacing.lg),
            AiTransparencySection(),
            SizedBox(height: AppSpacing.lg),
            MonetizationSection(),
            SizedBox(height: AppSpacing.lg),
            PrivacySecuritySection(),
            SizedBox(height: AppSpacing.lg),
            RoadmapSection(),
            SizedBox(height: AppSpacing.lg),
            FeedbackCtaSection(),
            LegalFooterSection(),
          ],
        ),
      ),
    );
  }
}
