import 'dart:convert';

import '../../models/itinerary.dart';

/// Ekvivalent tolerantnog JSON parsera iz AIProxyItineraryGenerator.swift
/// (decodeItinerary / decodeAlternativeVariant / stripCodeFences).
///
/// Ovo je namjerno IZDVOJENO od stvarnog AI poziva (vidi itinerary_generator.dart)
/// jer je potpuno samostalno — ne zavisi od PromptBuilder-a ni AIProxy SDK-a,
/// samo parsira tekst koji AI vrati (koji ponekad nije čist JSON: markdown code
/// fence-ovi, wrapper objekti poput {"itinerary": {...}}, itd.)
class ItineraryJsonParser {
  ItineraryJsonParser._();

  /// Skida ```json ... ``` ili ``` ... ``` omotač ako postoji.
  static String stripCodeFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return t;
  }

  /// Ekvivalent decodeItinerary(from:defaults:).
  ///
  /// Redoslijed pokušaja (isti kao Swift):
  /// 1. Direktan strict decode (ItineraryResponse.fromJson)
  /// 2. Isto, ali nakon skidanja code fence-ova
  /// 3. Tolerantni fallback: raspakuje wrapper-e (itinerary/data/result) i
  ///    ručno gradi ItineraryDay listu iz "days" niza (samo novi variants[] format).
  static ItineraryResponse decodeItinerary(
    String text, {
    required String defaultCountry,
    required String defaultCity,
  }) {
    // 1️⃣ Direktan pokušaj
    final direct = _tryStrictDecode(text);
    if (direct != null) return direct;

    // 2️⃣ Nakon skidanja code fence-ova
    final stripped = stripCodeFences(text);
    if (stripped != text) {
      final afterStrip = _tryStrictDecode(stripped);
      if (afterStrip != null) return afterStrip;
    }

    // 3️⃣ Tolerantni fallback
    dynamic rootAny;
    try {
      rootAny = jsonDecode(stripped);
    } catch (_) {
      throw const FormatException('Invalid JSON');
    }
    if (rootAny is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON');
    }
    var root = rootAny;

    // odmotaj poznate wrapper-e
    if (root['itinerary'] is Map<String, dynamic>) {
      root = root['itinerary'] as Map<String, dynamic>;
    }
    if (root['data'] is Map<String, dynamic>) {
      root = root['data'] as Map<String, dynamic>;
    }
    if (root['result'] is Map<String, dynamic>) {
      root = root['result'] as Map<String, dynamic>;
    }

    final rawDays = root['days'] as List<dynamic>?;
    if (rawDays == null) {
      throw const FormatException('Missing days array');
    }

    final days = <ItineraryDay>[];
    for (var idx = 0; idx < rawDays.length; idx++) {
      final dict = rawDays[idx] as Map<String, dynamic>;
      final dayNumber = dict['dayNumber'] as int? ?? (idx + 1);
      final title = dict['title'] as String?;

      final rawVariants = dict['variants'] as List<dynamic>?;
      if (rawVariants == null) continue;

      final parsedVariants = <DayVariant>[];
      for (final v in rawVariants) {
        final vMap = v as Map<String, dynamic>;
        final m = vMap['morning'] as Map<String, dynamic>?;
        final a = vMap['afternoon'] as Map<String, dynamic>?;
        final e = vMap['evening'] as Map<String, dynamic>?;
        if (m == null || a == null || e == null) continue;

        parsedVariants.add(DayVariant(
          morning: ItineraryItem.fromJson(m),
          afternoon: ItineraryItem.fromJson(a),
          evening: ItineraryItem.fromJson(e),
          dayStructure: vMap['dayStructure'] != null
              ? DayStructure.fromJson(vMap['dayStructure'] as Map<String, dynamic>)
              : null,
        ));
      }

      if (parsedVariants.isNotEmpty) {
        days.add(ItineraryDay(dayNumber: dayNumber, title: title, variants: parsedVariants));
      }
    }

    return ItineraryResponse(
      country: root['country'] as String? ?? defaultCountry,
      city: root['city'] as String? ?? defaultCity,
      days: days,
    );
  }

  static ItineraryResponse? _tryStrictDecode(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      return ItineraryResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Ekvivalent decodeAlternativeVariant(from:expectedDay:).
  /// Vraća DayVariant za "generiraj jednu alternativu za dan X" odgovor.
  static DayVariant decodeAlternativeVariant(String text, {required int expectedDay}) {
    DayVariant? tryDecode(String s) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map<String, dynamic>) return null;
        final variant = decoded['variant'] as Map<String, dynamic>?;
        if (variant == null) return null;
        return DayVariant.fromJson(variant);
      } catch (_) {
        return null;
      }
    }

    final direct = tryDecode(text);
    if (direct != null) return direct;

    final stripped = stripCodeFences(text);
    final afterStrip = tryDecode(stripped);
    if (afterStrip != null) return afterStrip;

    throw const FormatException('Invalid alternative variant JSON');
  }
}
