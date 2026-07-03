import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../providers/weather_provider.dart';
import '../../services/weather/weather_service.dart';
import '../../utils/weather_icons.dart';

/// Port weatherCard iz ResultView.swift (WeatherKit) preko Open-Meteo.
///
/// ItineraryResponse NEMA eksplicitan datum početka putovanja (nema date
/// picker-a nigdje na Plan ekranu) — PRETPOSTAVKA: Day 1 = danas, datum za
/// [dayNumber] je `DateTime.now().add(Duration(days: dayNumber - 1))`. Ako
/// se ispostavi netačna (npr. postoji trip start date koji nije viđen),
/// treba dodatno polje u modelu — javi ako zatreba.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({
    super.key,
    required this.lat,
    required this.lon,
    required this.city,
    required this.dayNumber,
  });

  final double lat;
  final double lon;
  final String city;
  final int dayNumber;

  DateTime get _targetDate =>
      DateUtils.dateOnly(DateTime.now().add(Duration(days: dayNumber - 1)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(weatherForecastProvider((lat: lat, lon: lon)));

    return forecastAsync.when(
      loading: () => const _WeatherCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (forecast) {
        final targetDate = _targetDate;
        DayWeather? day;
        for (final entry in forecast) {
          if (DateUtils.isSameDay(entry.date, targetDate)) {
            day = entry;
            break;
          }
        }
        if (day == null) return const SizedBox.shrink();
        return _WeatherCardContent(city: city, date: targetDate, day: day);
      },
    );
  }
}

class _WeatherCardSkeleton extends StatelessWidget {
  const _WeatherCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: context.accent.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

class _WeatherCardContent extends StatelessWidget {
  const _WeatherCardContent({required this.city, required this.date, required this.day});

  final String city;
  final DateTime date;
  final DayWeather day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(WeatherIcons.iconFor(day.weatherCode), size: 40, color: Colors.orange),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${day.tempMaxC.round()}°',
                style: AppTypography.heroTitle.copyWith(color: context.textPrimary),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(city, style: AppTypography.cardTitle.copyWith(color: context.textPrimary)),
                  Text(
                    DateFormat.MMMd().format(date),
                    style: AppTypography.bodySecondary.copyWith(color: context.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            WeatherIcons.descriptionFor(day.weatherCode),
            style: AppTypography.body.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _statChip(context, Icons.arrow_upward, '${day.tempMaxC.round()}°'),
              const SizedBox(width: AppSpacing.md),
              _statChip(context, Icons.arrow_downward, '${day.tempMinC.round()}°'),
              const SizedBox(width: AppSpacing.md),
              _statChip(context, Icons.water_drop_outlined, '${day.precipitationProbability}%'),
              const SizedBox(width: AppSpacing.md),
              _statChip(context, Icons.air, '${day.windSpeedKmh.round()} km/h'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Weather data by Open-Meteo',
            style: AppTypography.fieldLabel.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 2),
        Text(label, style: AppTypography.bodySecondary.copyWith(color: context.textSecondary)),
      ],
    );
  }
}
