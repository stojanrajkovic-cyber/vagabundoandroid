import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../models/distance_unit.dart';
import '../../models/nearby_poi.dart';
import '../../services/functions/functions_service.dart';
import '../../utils/haptics.dart';
import '../primary_button.dart';

/// Port POIDetailSheet.swift — poziva `getPlaceDetails` na otvaranju.
///
/// Response shape JE poznat (potvrđen iz placeDetails.ts), ali SVAKO polje
/// osim `photos`/`reviews` (uvijek liste, mogu biti prazne) MOŽE biti null,
/// pa se svako čita defenzivno (provjera tipa/null) prije prikaza.
Future<void> showPoiDetailSheet(BuildContext context, NearbyPOI poi) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.cardStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: _detailsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    // Defenzivno: na grešku i dalje renderuj sa praznim
                    // podacima (naziv/kategorija/Open in Maps ostaju vidljivi).
                    final data = (!snapshot.hasError && snapshot.hasData)
                        ? snapshot.data!
                        : const <String, dynamic>{};
                    return _PoiDetailsContent(poi: widget.poi, data: data);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PoiPhoto {
  const _PoiPhoto({required this.url, this.attribution});
  final String url;
  final String? attribution;
}

class _PoiReview {
  const _PoiReview({required this.authorName, this.rating, required this.text});
  final String authorName;
  final double? rating;
  final String text;
}

/// Nested liste (`photos`/`reviews`) iz platform channel odgovora dolaze kao
/// `List<Object?>` sa elementima `Map<Object?, Object?>` — direktan cast na
/// `Map<String, dynamic>` puca, otud `Map<String, dynamic>.from(...)` fix
/// (ista klasa buga kao nearbyPlaces ranije).
List<_PoiPhoto> _parsePhotos(dynamic raw) {
  if (raw is! List) return [];
  final result = <_PoiPhoto>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final map = Map<String, dynamic>.from(e);
    final url = map['url'] as String?;
    if (url == null || url.isEmpty) continue;
    result.add(_PoiPhoto(url: url, attribution: map['attribution'] as String?));
  }
  return result;
}

List<_PoiReview> _parseReviews(dynamic raw) {
  if (raw is! List) return [];
  final result = <_PoiReview>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final map = Map<String, dynamic>.from(e);
    final authorName = map['authorName'] as String?;
    final text = map['text'] as String?;
    if (authorName == null || text == null) continue;
    result.add(_PoiReview(
      authorName: authorName,
      rating: (map['rating'] as num?)?.toDouble(),
      text: text,
    ));
  }
  return result;
}

List<String> _parseWeekdayDescriptions(dynamic raw) {
  if (raw is! List) return [];
  return raw.whereType<String>().toList();
}

String _priceLevelLabel(String raw) {
  switch (raw) {
    case 'PRICE_LEVEL_FREE':
      return 'Free';
    case 'PRICE_LEVEL_INEXPENSIVE':
      return '\$';
    case 'PRICE_LEVEL_MODERATE':
      return '\$\$';
    case 'PRICE_LEVEL_EXPENSIVE':
      return '\$\$\$';
    case 'PRICE_LEVEL_VERY_EXPENSIVE':
      return '\$\$\$\$';
    default:
      return raw;
  }
}

class _PoiDetailsContent extends StatelessWidget {
  const _PoiDetailsContent({required this.poi, required this.data});

  final NearbyPOI poi;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rating = (data['rating'] as num?)?.toDouble();
    final userRatingCount = (data['userRatingCount'] as num?)?.toInt();
    final priceLevel = data['priceLevel'] as String?;
    final websiteUri = data['websiteUri'] as String?;
    final primaryTypeDisplayName = data['primaryTypeDisplayName'] as String?;
    final goodForChildren = data['goodForChildren'] as bool?;
    final summary = data['summary'] as String?;
    final photos = _parsePhotos(data['photos']);
    final reviews = _parseReviews(data['reviews']);
    final hours = _parseWeekdayDescriptions(data['weekdayDescriptions']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty) ...[
          _PhotoCarousel(photos: photos),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          poi.name,
          style: AppTypography.sectionTitle.copyWith(color: context.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '${primaryTypeDisplayName ?? poi.category} · '
                '${DistanceFormatter.formatDistance(poi.distanceMeters, kDefaultDistanceUnit)}',
                style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
              ),
            ),
            if (poi.isOpenNow != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _OpenBadge(isOpen: poi.isOpenNow!),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (rating != null) ...[
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: AppSpacing.xs),
              Text(
                userRatingCount != null
                    ? '${rating.toStringAsFixed(1)} ($userRatingCount)'
                    : rating.toStringAsFixed(1),
                style: AppTypography.body.copyWith(color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (priceLevel != null || goodForChildren == true) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (priceLevel != null)
                _Pill(label: _priceLevelLabel(priceLevel), color: context.accent),
              if (goodForChildren == true)
                const _Pill(
                  icon: Icons.child_care,
                  label: 'Good for kids',
                  color: Colors.green,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (summary != null && summary.isNotEmpty) ...[
          Text(
            summary,
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (hours.isNotEmpty) ...[
          Text(
            'Hours',
            style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hours.join('\n'),
            style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (reviews.isNotEmpty) ...[
          Text(
            'Reviews',
            style: AppTypography.cardTitle.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final review in reviews) _ReviewCard(review: review),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (websiteUri != null && websiteUri.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () {
                Haptics.light();
                launchUrl(Uri.parse(websiteUri), mode: LaunchMode.externalApplication);
              },
              icon: Icon(Icons.language, color: context.accent),
              label: Text(
                'Visit website',
                style: AppTypography.body.copyWith(color: context.accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: 'Open in Maps',
          onPressed: () {
            Haptics.light();
            poi.openInMaps();
          },
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({this.icon, required this.label, required this.color});

  final IconData? icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.fieldLabel.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: AppTypography.fieldLabel.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photos});

  final List<_PoiPhoto> photos;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final attribution = photos[_currentIndex].attribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => Image.network(
                photos[index].url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: context.cardStroke,
                  child: Icon(Icons.image_not_supported, color: context.textSecondary),
                ),
              ),
            ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentIndex ? context.accent : context.cardStroke,
                  ),
                ),
            ],
          ),
        ],
        if (attribution != null && attribution.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            attribution,
            style: AppTypography.fieldLabel.copyWith(color: context.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Ekvivalent expand-on-tap mehanizma iz TripSummaryCard (Faza 4/polish) —
/// identičan pattern, samo po review-u (svaki ima svoj `_isExpanded`).
class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review});

  final _PoiReview review;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,
                  style: AppTypography.body.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (review.rating != null) ...[
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  review.rating!.toStringAsFixed(1),
                  style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topLeft,
                  child: Text(
                    review.text,
                    maxLines: _isExpanded ? null : 4,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: AppTypography.bodySecondary.copyWith(color: context.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isExpanded ? 'Read less' : 'Read more',
                  style: AppTypography.bodySecondary.copyWith(
                    color: context.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
