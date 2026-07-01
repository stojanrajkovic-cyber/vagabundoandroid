import 'dart:async';

import '../../models/itinerary.dart';
import 'itinerary_json_parser.dart';

/// Ekvivalent ItineraryRequest tipa — NIJE bio dostupan ni u jednom
/// uploadanom fajlu, samo korišten kao parametar u
/// AIProxyItineraryGenerator.swift. Ovo je MINIMALNA pretpostavljena
/// verzija — dopuni kad uploadaš pravi ItineraryRequest.swift.
class ItineraryRequest {
  const ItineraryRequest({
    required this.country,
    required this.city,
    required this.languageCode,
    required this.model,
    this.days = 3,
  });

  final String country;
  final String city;
  final String languageCode;
  final String model;
  final int days;
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
/// ⚠️ BLOKIRANO — `_buildPrompt()` i `_callAIProxy()` su placeholderi.
/// Da bi ovo stvarno radilo, trebaju mi:
///   1. PromptBuilder.swift — gradi system/user prompt tekst i JSON schema
///      (PromptBuilder.system, .user, .jsonSchema, .variantSchema)
///   2. Kako je AIProxyClient konfigurisan (base URL / partial key) — obično
///      u app-startup kodu koji nisam vidio
///   3. Pravi ItineraryRequest.swift (gore je pretpostavljena verzija)
///
/// Sve ostalo (retry, backoff, tolerantni JSON parsing) je već portovano
/// i spremno za upotrebu čim se poveže stvarni HTTP poziv.
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
    // TODO: zamijeni sa stvarnim pozivom kad PromptBuilder bude portovan.
    final text = await _callAIProxyWithRetry(
      systemPrompt: _buildSystemPromptPlaceholder(req),
      userPrompt: _buildUserPromptPlaceholder(req),
      model: req.model,
    );

    var result = ItineraryJsonParser.decodeItinerary(
      text,
      defaultCountry: req.country,
      defaultCity: req.city,
    );

    result = _normalizeInitial(result);
    return result;
  }

  @override
  Future<DayVariant> generateAlternativeVariant({
    required ItineraryResponse plan,
    required int dayNumber,
  }) async {
    if (plan.promptSnapshot == null) {
      throw StateError('error_missing_prompt_snapshot');
    }

    final day = plan.days.where((d) => d.dayNumber == dayNumber).firstOrNull;
    if (day == null) {
      throw StateError('error_day_not_found: $dayNumber');
    }

    if (day.variants.length >= _maxVariantsPerDay) {
      throw StateError('error_no_more_alternatives');
    }

    // TODO: sastavi task prompt (avoid-repeat blok + strict JSON shape
    // instrukcija) — logika je identična Swift verziji, samo treba
    // PromptBuilder da se poveže sa stvarnim snap.userPrompt/systemPrompt.
    final text = await _callAIProxyWithRetry(
      systemPrompt: plan.promptSnapshot!.systemPrompt,
      userPrompt: _buildAlternativeTaskPromptPlaceholder(plan, dayNumber),
      model: plan.promptSnapshot!.model,
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

  // --- Placeholderi koji čekaju PromptBuilder.swift ---

  String _buildSystemPromptPlaceholder(ItineraryRequest req) {
    throw UnimplementedError(
      'PromptBuilder.system() nije portovan — uploaduj PromptBuilder.swift.',
    );
  }

  String _buildUserPromptPlaceholder(ItineraryRequest req) {
    throw UnimplementedError(
      'PromptBuilder.user() nije portovan — uploaduj PromptBuilder.swift.',
    );
  }

  String _buildAlternativeTaskPromptPlaceholder(ItineraryResponse plan, int dayNumber) {
    throw UnimplementedError(
      'Task prompt za alternativnu varijantu čeka PromptBuilder.swift.',
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

  Future<String> _callAIProxy({
    required String systemPrompt,
    required String userPrompt,
    required String model,
  }) async {
    // TODO: pravi HTTP POST na aiProxyBaseUrl sa {model, messages, ...}
    // payload-om, čim znamo tačan ugovor AIProxy servera.
    throw UnimplementedError(
      'AIProxy HTTP poziv nije portovan — treba mi konfiguracija endpoint-a.',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
