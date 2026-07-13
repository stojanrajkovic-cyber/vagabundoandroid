import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/distance_unit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/haptics.dart';
import '../ads/ad_banner_widget.dart';
import '../primary_button.dart';
import 'explore_category_chips.dart';

/// Port ExploreControlsView.swift — lokacija, interesi, radius, CTA.
class ExploreControls extends ConsumerStatefulWidget {
  const ExploreControls({super.key});

  @override
  ConsumerState<ExploreControls> createState() => _ExploreControlsState();
}

class _ExploreControlsState extends ConsumerState<ExploreControls> {
  final Set<String> _selectedCategoryKeys = {};
  late int _radiusMeters = DistanceFormatter.radiusOptions(kDefaultDistanceUnit)[1].meters;

  void _toggleCategory(String key) {
    setState(() {
      if (_selectedCategoryKeys.contains(key)) {
        _selectedCategoryKeys.remove(key);
      } else {
        _selectedCategoryKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final placemarkName = ref.watch(deviceLocationManagerProvider).placemarkName;
    // watch (ne read) na state-u — isCtaDisabled zavisi od ExploreState-a
    // (ExploreReady), pa dugme mora rebuild-ovati kad se to promijeni.
    ref.watch(exploreControllerProvider);
    ref.watch(isAuthenticatedProvider);
    final controller = ref.read(exploreControllerProvider.notifier);
    final radiusOptions = DistanceFormatter.radiusOptions(kDefaultDistanceUnit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.my_location, size: 18, color: context.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                placemarkName ?? 'Current location',
                style: AppTypography.body.copyWith(color: context.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Card(
          title: 'Interests',
          child: ExploreCategoryChips(
            selectedKeys: _selectedCategoryKeys,
            onToggle: _toggleCategory,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(
          title: 'Search radius',
          child: Row(
            children: [
              for (final option in radiusOptions)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: option == radiusOptions.last ? 0 : AppSpacing.sm,
                    ),
                    child: _RadiusButton(
                      option: option,
                      isSelected: option.meters == _radiusMeters,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _radiusMeters = option.meters);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Explore nearby',
          onPressed: controller.isCtaDisabled
              ? null
              : () {
                  Haptics.light();
                  controller.explore(
                    radiusMeters: _radiusMeters,
                    categoryKeys: _selectedCategoryKeys,
                  );
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        const Center(child: AdBannerWidget()),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _RadiusButton extends StatelessWidget {
  const _RadiusButton({required this.option, required this.isSelected, required this.onTap});

  final RadiusOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? context.accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: isSelected ? context.accent : context.cardStroke),
        ),
        child: Text(
          option.label,
          textAlign: TextAlign.center,
          style: AppTypography.chip.copyWith(
            color: isSelected ? context.accent : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
