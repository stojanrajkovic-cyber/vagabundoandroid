import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import '../../models/itinerary.dart';
import '../analytics/analytics_service.dart';
import '../roadtrip/road_trip_planner_service.dart';
import 'itinerary_json_parser.dart';
import 'prompt_builder.dart';

/// Ekvivalent ItineraryGenerator protokola.
abstract class ItineraryGenerator {
  Future<ItineraryResponse> generate(ItineraryRequest req);
  Future<DayVariant> generateAlternativeVariant({
    required ItineraryResponse plan,
    required int dayNumber,
  });
}

/// Generator koji poziva sopstvenu Firebase Cloud Function ("generateItinerary")
/// umjesto AIProxy-ja direktno. Zamjenjuje raniji `AIProxyItineraryGenerator`
/// (AIProxy je zahtijevao `aiproxy-devicecheck` header koji Android/Flutter
/// nije mogao proizvesti — vidi PATCH_itinerary_generator_cloud_function.md).
///
/// Prompt building (PromptBuilder), retry/backoff i tolerantni JSON parsing
/// su nepromijenjeni — samo je transport sloj (`_callAIProxy`) zamijenjen
/// pozivom na `FirebaseFunctions.instance.httpsCallable('generateItinerary')`.
/// Region/projekat se automatski uzima iz `Firebase.initializeApp()` (main.dart),
/// nema potrebe za service URL-om ili partial key-om kao kod AIProxy-ja.
class CloudItineraryGenerator implements ItineraryGenerator {
  CloudItineraryGenerator();

  static const int _maxVariantsPerDay = 3;

  bool _isRetryable(Object error) {
    if (error is FirebaseFunctionsException) {
      // 'resource-exhausted' = rate limit (naš server), 'internal'/'deadline-exceeded' = privremeno.
      // NAPOMENA: 'resource-exhausted' (rate limit) NIJE retryable u istom pozivu —
      // korisnik treba sačekati, ne odmah pokušati ponovo.
      return error.code == 'internal' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'unavailable';
    }
    return false;
  }

  Duration _backoffDelay(int attempt) {
    // 0.6s, 1.3s, 2.1s — identično Swift verziji.
    final secs = 0.6 + (attempt - 1) * 0.7;
    return Duration(milliseconds: (secs * 1000).round());
  }

  @override
  Future<ItineraryResponse> generate(ItineraryRequest req) async {
    final sys = PromptBuilder.system(languageCode: req.languageCode);
    final user =
        '${PromptBuilder.user(req)}\n\nReturn only JSON matching the schema.';

    final text = await _callAIProxyWithRetry(
      systemPrompt: sys,
      userPrompt: user,
      model: req.model,
    );

    var result = ItineraryJsonParser.decodeItinerary(
      text,
      defaultCountry: req.country,
      defaultCity: req.city,
    );

    // Zakači prompt snapshot (isto kao Swift — treba za generateAlternativeVariant kasnije).
    result = ItineraryResponse(
      country: result.country,
      city: result.city,
      days: result.days,
      // Fallback na req.cityLat/cityLon (poznati iz CountryCityPicker-a) ako ih
      // LLM izostavi iz JSON odgovora — isti pattern kao country/city fallback
      // u ItineraryJsonParser, samo primijenjen ovdje jer parser ima 3 različite
      // decode putanje i req nije dostupan u sve tri. Bez ovoga WeatherCard
      // (Faza 5.5) skoro nikad ne bi imao koordinate za prikaz.
      cityLat: result.cityLat ?? req.cityLat,
      cityLon: result.cityLon ?? req.cityLon,
      roadTrip: result.roadTrip,
      generatorModel: req.model,
      promptSnapshot: PromptSnapshot(
        schemaVersion: 1,
        model: req.model,
        createdAt: DateTime.now(),
        languageCode: req.languageCode,
        systemPrompt: sys,
        userPrompt: user,
        requestFingerprint: null,
      ),
      status: result.status,
      completedAt: result.completedAt,
      summary: result.summary,
      pace: result.pace,
      interests: req.interests,
      withKids: req.withKids,
    );

    result = _normalizeInitial(result);

    if (req.byCar) {
      result = await _attachRealRoadTrip(result, req);
    }

    return result;
  }

  /// Zamjenjuje AI-izmišljenu rutu (koju AI od Zadatka B3 uopšte više ne
  /// vraća — roadTripAddon() je uklonjen iz prompta) stvarnim planom iz
  /// RoadTripPlannerService (Google Routes/Places, vidi functions/src/planRoadTrip.ts).
  /// Ako Cloud Function pukne (npr. mreža), `result` se vraća nepromijenjen
  /// (roadTrip ostaje null) — generisanje CIJELOG plana se NE prekida.
  Future<ItineraryResponse> _attachRealRoadTrip(
    ItineraryResponse result,
    ItineraryRequest req,
  ) async {
    final realRoadTrip = await RoadTripPlannerService.instance.plan(
      originLat: req.originLat,
      originLon: req.originLon,
      originName: req.originName,
      destLat: result.cityLat ?? req.cityLat ?? 0,
      destLon: result.cityLon ?? req.cityLon ?? 0,
      destName: '${result.city}, ${result.country}',
      maxDrivingHoursPerDay: req.maxDrivingHoursPerDay,
      breakEveryMinutes: req.breakEveryMinutes,
      languageCode: req.languageCode,
    );

    if (realRoadTrip == null) return result;

    AnalyticsService.instance.logRoadTripGenerated(
      origin: realRoadTrip.origin ?? '',
      destination: realRoadTrip.destination ?? '',
      totalDistanceKm: realRoadTrip.totalDistanceKm ?? 0,
    );

    return ItineraryResponse(
      country: result.country,
      city: result.city,
      days: result.days,
      cityLat: result.cityLat,
      cityLon: result.cityLon,
      roadTrip: realRoadTrip,
      generatorModel: result.generatorModel,
      promptSnapshot: result.promptSnapshot,
      status: result.status,
      completedAt: result.completedAt,
      summary: result.summary,
      pace: result.pace,
      interests: result.interests,
      withKids: result.withKids,
    );
  }

  @override
  Future<DayVariant> generateAlternativeVariant({
    required ItineraryResponse plan,
    required int dayNumber,
  }) async {
    final snap = plan.promptSnapshot;
    if (snap == null) {
      throw StateError('error_missing_prompt_snapshot');
    }

    ItineraryDay? day;
    for (final d in plan.days) {
      if (d.dayNumber == dayNumber) {
        day = d;
        break;
      }
    }
    if (day == null) {
      throw StateError('error_day_not_found: $dayNumber');
    }

    if (day.variants.length >= _maxVariantsPerDay) {
      throw StateError('error_no_more_alternatives');
    }

    final current = day.activeVariant;
    final avoid = '''
Current Day $dayNumber (avoid repeating these exact places/structure):
- Morning: ${current.morning.title}
- Afternoon: ${current.afternoon.title}
- Evening: ${current.evening.title}''';

    final task = '''
TASK: Generate ONE NEW alternative variant for Day $dayNumber ONLY.
$avoid

Return JSON ONLY in this exact shape:
{
  "dayNumber": $dayNumber,
  "variant": {
    "morning":   { "title": "...", "description": "...", "locationName": "...", "lat": <num|null>, "lon": <num|null> },
    "afternoon": { "title": "...", "description": "...", "locationName": "...", "lat": <num|null>, "lon": <num|null> },
    "evening":   { "title": "...", "description": "...", "locationName": "...", "lat": <num|null>, "lon": <num|null> },
    "dayStructure": {
      "morning":   [ { "title": "...", "steps": ["..."] } ],
      "afternoon": [ { "title": "...", "steps": ["..."] } ],
      "evening":   [ { "title": "...", "steps": ["..."] } ]
    }
  }
}

STRICT RULES:
- Output MUST be in languageCode ${snap.languageCode}.
- The 'variant' must be a complete alternative day.
- Do NOT return the full itinerary; only the object above.
- No emojis. JSON only.''';

    final userPrompt = '${snap.userPrompt}\n\n---\n$task';

    final text = await _callAIProxyWithRetry(
      systemPrompt: snap.systemPrompt,
      userPrompt: userPrompt,
      model: snap.model,
    );

    return ItineraryJsonParser.decodeAlternativeVariant(text,
        expectedDay: dayNumber);
  }

  /// Ekvivalent normalizeInitial — enforce tačno 1 varijantu po danu za
  /// inicijalni plan (sprječava crash na `variants.first!` kasnije u UI-u).
  ItineraryResponse _normalizeInitial(ItineraryResponse res) {
    final normalizedDays =
        res.days.where((d) => d.variants.isNotEmpty).map((d) {
      final variants = d.variants.length > 1 ? [d.variants.first] : d.variants;
      return ItineraryDay(
        dayNumber: d.dayNumber,
        title: d.title,
        variants: variants,
        activeVariantIndex: 0,
      );
    }).toList();

    return ItineraryResponse(
      country: res.country,
      city: res.city,
      days: normalizedDays,
      cityLat: res.cityLat,
      cityLon: res.cityLon,
      roadTrip: res.roadTrip,
      generatorModel: res.generatorModel,
      promptSnapshot: res.promptSnapshot,
      status: res.status,
      completedAt: res.completedAt,
      summary: res.summary,
      pace: res.pace,
      interests: res.interests,
      withKids: res.withKids,
    );
  }

  Future<String> _callAIProxyWithRetry({
    required String systemPrompt,
    required String userPrompt,
    required String model,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await _callAIProxy(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          model: model,
        );
      } catch (e) {
        if (_isRetryable(e) && attempt < 3) {
          lastError = e;
          await Future.delayed(_backoffDelay(attempt));
          continue;
        }
        rethrow;
      }
    }
    throw lastError ?? StateError('error_unknown');
  }

  /// Poziva sopstvenu "generateItinerary" Cloud Function umjesto AIProxy-ja
  /// direktno — schema/response_format enforcement je sada server-side.
  Future<String> _callAIProxy({
    required String systemPrompt,
    required String userPrompt,
    required String model,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'generateItinerary',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 115)),
    );

    // NAPOMENA: NE hvatati FirebaseFunctionsException ovdje — mora propagirati
    // nepromijenjena do _callAIProxyWithRetry(), jer _isRetryable() provjerava
    // `error is FirebaseFunctionsException`. Hvatanje i rethrow kao generički
    // Exception (kako je ranije pisalo ovdje) tiho gasi retry logiku za
    // 'internal'/'deadline-exceeded'/'unavailable' greške.
    final result = await callable.call<Map<String, dynamic>>({
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'model': model,
    });

    final content = result.data['content'] as String?;
    if (content == null || content.isEmpty) {
      throw StateError('Prazan odgovor od generateItinerary funkcije.');
    }
    return content;
  }
}
