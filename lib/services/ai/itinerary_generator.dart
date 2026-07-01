import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/itinerary.dart';
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

/// Ekvivalent AIProxyItineraryGenerator.swift.
///
/// Prompt building (PromptBuilder), retry/backoff i tolerantni JSON parsing
/// su svi portovani i povezani. HTTP ugovor je potvrđen iz AIProxySwift SDK
/// izvornog koda (lzell/AIProxySwift, AIProxyProxiedRequestBuilder +
/// AIProxyURLRequest.create): POST na `<serviceURL>/v1/chat/completions`,
/// sa `aiproxy-partial-key` header-om (ekvivalent onome što iOS SDK radi
/// interno preko partialKey/serviceURL iz AIProxyClient.swift).
///
/// ⚠️ POZNATO OGRANIČENJE (TODO Fase 8/9): AIProxy server zahtijeva i
/// `aiproxy-devicecheck` header — token iz Apple DeviceCheck/App Attest API-ja,
/// generisan native iOS/macOS SDK-om. Android/Flutter nema direktan ekvivalent
/// (trebao bi Play Integrity API + eksplicitna AIProxy podrška za taj tok).
/// Bez tog header-a, stvarni pozivi sa uređaja će vjerovatno dobiti 401 sa
/// AIProxy servera — to je OČEKIVANO za sada i hvata se kao greška
/// (SnackBar u MainScreen), ne crash. Za lokalno testiranje bez tog problema,
/// AIProxy dashboard nudi "device check bypass" token (isto što iOS SDK šalje
/// kao `aiproxy-devicecheck-bypass` u simulator build-ovima) — ako ga imaš,
/// dodaj ga kao dodatni header ovdje.
class AIProxyItineraryGenerator implements ItineraryGenerator {
  AIProxyItineraryGenerator({required this.aiProxyServiceUrl, required this.partialKey});

  /// AIProxy "service URL" (npr. https://api.aiproxy.com/8c264efa/7b8576a3) —
  /// ekvivalent AIPROXY_SERVICE_URL iz iOS Info.plist/Secrets.xcconfig.
  final Uri aiProxyServiceUrl;

  /// AIProxy "partial key" — ekvivalent AIPROXY_PARTIAL_KEY. Po AIProxy
  /// dizajnu ovo je BEZBJEDNO za bundlovanje u klijentu (server drži drugu
  /// polovinu ključa) — isto kao što je već bilo bundlovano u iOS Info.plist.
  final String partialKey;

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

  /// Šalje standardni OpenAI-kompatibilan chat-completions payload
  /// (model, messages, response_format, temperature) na
  /// `<aiProxyServiceUrl>/v1/chat/completions`, sa AIProxy auth header-ima.
  /// Vidi napomenu o `aiproxy-devicecheck` ograničenju iznad klase.
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

    final endpoint = aiProxyServiceUrl.replace(
      path: '${aiProxyServiceUrl.path}/v1/chat/completions',
    );

    final response = await http
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
            'aiproxy-partial-key': partialKey,
            // TODO Fase 8/9: 'aiproxy-devicecheck' (vidi napomenu iznad klase).
          },
          body: body,
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'AIProxy/OpenAI error (${response.statusCode}) via $model: ${response.body}',
        endpoint,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;

    String? content;
    if (choices != null && choices.isNotEmpty) {
      final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      content = message?['content'] as String?;
    }

    if (content == null || content.isEmpty) {
      throw StateError('No content from $model');
    }

    return content;
  }
}
