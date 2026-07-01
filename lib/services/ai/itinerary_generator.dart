import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/itinerary.dart';
import 'itinerary_json_parser.dart';
import 'prompt_builder.dart';

/// Ekvivalent ItineraryRequest tipa — sastavljen iz upotrebe u
/// PromptBuilder.swift (nije postojao kao poseban uploadan fajl).
/// Polja su sad usklađena sa onim što PromptBuilder stvarno čita
/// (req.interests, req.tripPace, req.byCar, req.originName/Lat/Lon).
class ItineraryRequest {
  const ItineraryRequest({
    required this.country,
    required this.city,
    required this.languageCode,
    required this.model,
    this.days = 3,
    this.cityLat,
    this.cityLon,
    this.tripPace = TripPace.balanced,
    this.interests = const [],
    this.byCar = false,
    this.originName,
    this.originLat,
    this.originLon,
  });

  final String country;
  final String city;
  final String languageCode;
  final String model;
  final int days;
  final double? cityLat;
  final double? cityLon;
  final TripPace tripPace;
  final List<String> interests;

  /// Road trip način — kad je true, PromptBuilder dodaje car/roadTrip/origin addone.
  final bool byCar;
  final String? originName;
  final double? originLat;
  final double? originLon;
}

/// Ekvivalent ItineraryGenerator protokola.
abstract class ItineraryGenerator {
  Future<ItineraryResponse> generate(ItineraryRequest req);
  Future<DayVariant> generateAlternativeVariant({
    required ItineraryResponse plan,
    required int dayNumber,
  });
}

/// Ekvivalent AIProxyItineraryGenerator.swift.
///
/// Prompt building (PromptBuilder), retry/backoff i tolerantni JSON parsing
/// su svi portovani i povezani. Jedino što ostaje NEPROVJERENO je tačan
/// HTTP ugovor tvog AIProxy servera (vidi napomenu iznad _callAIProxy) —
/// nisam imao pristup app-startup kodu koji konfiguriše AIProxyClient, pa
/// sam pretpostavio standardni OpenAI chat-completions oblik. Testiraj sa
/// stvarnim pozivom i javi ako AIProxy očekuje drugačije header-e/putanju.
class AIProxyItineraryGenerator implements ItineraryGenerator {
  AIProxyItineraryGenerator({required this.aiProxyBaseUrl});

  /// Endpoint tvog AIProxy servera. AIProxy je proxy koji krije OpenAI
  /// API ključ i prosljeđuje zahtjeve — isto na iOS i Flutter strani
  /// (čist HTTP poziv, nema native SDK-a ni na jednoj platformi).
  final Uri aiProxyBaseUrl;

  static const int _maxVariantsPerDay = 3;

  bool _isRetryable(Object error) {
    // TODO: uskladi sa stvarnim tipom greške koji baca http/AIProxy poziv
    // (Swift verzija provjerava URLError kodove i AIProxyError.unsuccessfulRequest
    // status 429 ili 500-504).
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
    final user = '${PromptBuilder.user(req)}\n\nReturn only JSON matching the schema.';

    final text = await _callAIProxyWithRetry(
      systemPrompt: sys,
      userPrompt: user,
      model: req.model,
      responseSchema: PromptBuilder.jsonSchema,
      schemaName: 'itinerary_response',
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
      cityLat: result.cityLat,
      cityLon: result.cityLon,
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
      interests: result.interests,
    );

    result = _normalizeInitial(result);
    return result;
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
      responseSchema: PromptBuilder.variantSchema,
      schemaName: 'day_variant',
    );

    return ItineraryJsonParser.decodeAlternativeVariant(text, expectedDay: dayNumber);
  }

  /// Ekvivalent normalizeInitial — enforce tačno 1 varijantu po danu za
  /// inicijalni plan (sprječava crash na `variants.first!` kasnije u UI-u).
  ItineraryResponse _normalizeInitial(ItineraryResponse res) {
    final normalizedDays = res.days
        .where((d) => d.variants.isNotEmpty)
        .map((d) {
          final variants = d.variants.length > 1 ? [d.variants.first] : d.variants;
          return ItineraryDay(
            dayNumber: d.dayNumber,
            title: d.title,
            variants: variants,
            activeVariantIndex: 0,
          );
        })
        .toList();

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
    );
  }

  Future<String> _callAIProxyWithRetry({
    required String systemPrompt,
    required String userPrompt,
    required String model,
    required Map<String, dynamic>? responseSchema,
    required String schemaName,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await _callAIProxy(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          model: model,
          responseSchema: responseSchema,
          schemaName: schemaName,
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

  /// ⚠️ NAJBOLJI-MOGUĆI-POKUŠAJ implementacija — nisam imao pristup
  /// stvarnoj AIProxy konfiguraciji (base URL / auth header / partial key),
  /// pa ovo šalje standardni OpenAI-kompatibilan chat-completions payload
  /// (model, messages, response_format, temperature) na [aiProxyBaseUrl].
  ///
  /// PRIJE PRVOG POKRETANJA PROVJERI:
  /// - Da li AIProxy zahtijeva poseban header (npr. `aiproxy-partial-key`,
  ///   `aiproxy-service-url`) umjesto/pored `Authorization: Bearer`.
  /// - Tačnu putanju (npr. `/v1/chat/completions` vs. neki AIProxy-specifičan
  ///   route) — Swift SDK (`AIProxyClient.openAIService`) ovo krije od nas,
  ///   pa sam pretpostavio OpenAI-standardni oblik jer je model ionako
  ///   OpenAI-ov (gpt-5-mini).
  /// - Da li treba API key kao query param ili poseban auth flow.
  Future<String> _callAIProxy({
    required String systemPrompt,
    required String userPrompt,
    required String model,
    required Map<String, dynamic>? responseSchema,
    required String schemaName,
  }) async {
    final responseFormat = responseSchema != null
        ? {
            'type': 'json_schema',
            'json_schema': {
              'name': schemaName,
              'schema': responseSchema,
              'strict': false,
            },
          }
        : {'type': 'json_object'};

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'response_format': responseFormat,
      'temperature': 1.0, // GPT-5 zahtijeva 1.0 (isto kao Swift original)
    });

    final response = await http
        .post(
          aiProxyBaseUrl,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'AIProxy/OpenAI error (${response.statusCode}) via $model: ${response.body}',
        aiProxyBaseUrl,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    final content = choices?.isNotEmpty == true
        ? (choices!.first as Map<String, dynamic>)['message']?['content'] as String?
        : null;

    if (content == null || content.isEmpty) {
      throw StateError('No content from $model');
    }

    return content;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
