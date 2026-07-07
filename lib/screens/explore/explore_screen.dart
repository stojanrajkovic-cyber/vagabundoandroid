import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../providers/explore_provider.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../widgets/explore/explore_controls.dart';
import '../../widgets/plan/app_hero_section.dart';
import 'explore_results_screen.dart';

/// Port ExploreView.swift — state-driven Explore ekran (Faza 6).
///
/// Explore je BESPLATAN na Androidu za sada (RevenueCat nalog nije otvoren,
/// monetizacija dolazi u Fazi 8) — na iOS-u je plaćena feature preko
/// PurchaseManager.exploreProduct(), ovdje se preskače direktno u loading.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  static const int _heroImageCount = 4;
  late final String _heroImageAssetPath = _pickRandomHeroImage();

  static String _pickRandomHeroImage() {
    final index = Random().nextInt(_heroImageCount) + 1; // 1..4
    return 'assets/images/explore_bg_$index.jpg';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(exploreControllerProvider);
      if (state is ExploreIdle) {
        ref.read(exploreControllerProvider.notifier).start();
      }
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      body: Stack(
        children: [
          _buildContent(context, state),
          if (isOffline) const _OfflineOverlay(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExploreState state) {
    switch (state) {
      case ExploreIdle():
      case ExploreRequestingLocation():
        return const _CenteredMessage(
          icon: null,
          isLoading: true,
          message: 'Finding your location...',
        );

      case ExploreLocationDenied():
        return _CenteredMessage(
          icon: Icons.location_off,
          message: 'Location access denied',
          actionLabel: 'Open Settings',
          onAction: () => Geolocator.openAppSettings(),
        );

      case ExploreReady():
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: AppHeroSection(
                scrollOffset: _scrollOffset,
                title: 'Explore nearby',
                imageAssetPath: _heroImageAssetPath,
              ),
            ),
            SliverPadding(
              // Isti fix kao main_screen.dart — AppTabShell renderuje floating
              // tab bar preko Scaffold(extendBody: true), sadržaj mora imati
              // dovoljno donjeg razmaka da zadnja stavka (Explore nearby
              // dugme) može potpuno da se skroluje iznad njega. Bez ovoga,
              // scroll extent je skoro nula (sadržaj skoro stane u ekran) pa
              // scroll djeluje "zaglavljeno", a dugme ostaje zaklonjeno.
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + 96,
              ),
              sliver: SliverToBoxAdapter(child: ExploreControls()),
            ),
          ],
        );

      case ExplorePurchasing():
      case ExploreLoading():
        return const _CenteredMessage(
          icon: null,
          isLoading: true,
          message: 'Searching nearby...',
        );

      case ExploreLoaded(:final pois):
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ExploreResultsScreen(pois: pois),
          ),
        );

      case ExploreEmpty():
        return const _CenteredMessage(
          icon: Icons.search_off,
          message: 'No places found',
          subtitle: 'Try a larger radius',
        );

      case ExploreError(:final message):
        return _CenteredMessage(
          icon: Icons.error_outline,
          message: message,
          actionLabel: 'Retry',
          onAction: () => ref.read(exploreControllerProvider.notifier).start(),
        );
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.subtitle,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData? icon;
  final String message;
  final String? subtitle;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: context.accent)
              else if (icon != null)
                Icon(icon, size: 48, color: context.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: context.textPrimary),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary
                      .copyWith(color: context.textSecondary),
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: AppTypography.body.copyWith(
                      color: context.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineOverlay extends StatelessWidget {
  const _OfflineOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.96),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 48, color: context.textSecondary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'You are offline',
                    style:
                        AppTypography.body.copyWith(color: context.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Explore needs an internet connection to find nearby places.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary
                        .copyWith(color: context.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
