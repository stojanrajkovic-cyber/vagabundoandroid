import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/nearby_poi.dart';
import '../../services/functions/functions_service.dart';
import '../../utils/haptics.dart';
import '../primary_button.dart';

/// Port POIDetailSheet.swift — poziva `getPlaceDetails` na otvaranju.
/// Response shape NIJE poznat unaprijed, pa se SVAKO polje čita
/// defenzivno (provjera tipa/null) prije prikaza.
Future<void> showPoiDetailSheet(BuildContext context, NearbyPOI poi) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PoiDetailSheet(poi: poi),
  );
}

class PoiDetailSheet extends StatefulWidget {
  const PoiDetailSheet({super.key, required this.poi});

  final NearbyPOI poi;

  @override
  State<PoiDetailSheet> createState() => _PoiDetailSheetState();
}

class _PoiDetailSheetState extends State<PoiDetailSheet> {
  late final Future<Map<String, dynamic>> _detailsFuture =
      FunctionsService.instance.fetchPlaceDetails(widget.poi.placeId);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.poi.name,
                style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.poi.category,
                style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              FutureBuilder<Map<String, dynamic>>(
                future: _detailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(
                      'Could not load more details for this place.',
                      style: AppTypography.body.copyWith(color: context.textSecondary),
                    );
                  }
                  return _DetailsBody(data: snapshot.data!);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Open in Maps',
                onPressed: () {
                  Haptics.light();
                  widget.poi.openInMaps();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] as num?;
    final address = data['formattedAddress'] as String?;
    final phone = data['phoneNumber'] as String?;
    final openingHours = data['openingHours'];
    final photoReference = data['photoReference'] as String?;

    final hoursLines = <String>[];
    if (openingHours is List) {
      for (final line in openingHours) {
        if (line is String) hoursLines.add(line);
      }
    } else if (openingHours is Map) {
      final weekdayText = openingHours['weekdayText'];
      if (weekdayText is List) {
        for (final line in weekdayText) {
          if (line is String) hoursLines.add(line);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photoReference != null && photoReference.isNotEmpty) ...[
          _PoiPhoto(photoReference: photoReference),
          const SizedBox(height: AppSpacing.md),
        ],
        if (rating != null) ...[
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: AppSpacing.xs),
              Text(
                rating.toStringAsFixed(1),
                style: AppTypography.body.copyWith(color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (address != null && address.isNotEmpty) ...[
          Text(
            address,
            style: AppTypography.body.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          Text(
            phone,
            style: AppTypography.body.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (hoursLines.isNotEmpty)
          Text(
            hoursLines.join('\n'),
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
      ],
    );
  }
}

class _PoiPhoto extends StatelessWidget {
  const _PoiPhoto({required this.photoReference});

  final String photoReference;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: FunctionsService.instance.fetchPlacePhoto(photoReference),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Image.memory(
            snapshot.data!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
