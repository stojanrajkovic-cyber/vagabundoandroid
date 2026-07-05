import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/distance_unit.dart';
import '../../models/nearby_poi.dart';
import '../../models/poi_category.dart';

/// Port ExplorePOIRow.swift — ikonica kategorije, naziv, kategorija,
/// distanca, open/closed badge.
class PoiRow extends StatelessWidget {
  const PoiRow({super.key, required this.poi, required this.onTap});

  final NearbyPOI poi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.cardStroke),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(PoiCategoryIcons.iconFor(poi.category),
                    color: context.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: AppTypography.cardTitle
                          .copyWith(color: context.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${poi.category} · ${DistanceFormatter.formatDistance(poi.distanceMeters, kDefaultDistanceUnit)}',
                      style: AppTypography.bodySecondary
                          .copyWith(color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              if (poi.isOpenNow != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _OpenBadge(isOpen: poi.isOpenNow!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.green : Colors.red;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: AppTypography.fieldLabel
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
