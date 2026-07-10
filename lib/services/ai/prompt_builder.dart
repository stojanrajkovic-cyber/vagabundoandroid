import 'dart:convert';

import '../../models/itinerary.dart';

/// Ekvivalent PromptBuilder.swift (enum sa static metodama → Dart klasa
/// sa static metodama, isti obrazac koristimo i za AppTheme).
class PromptBuilder {
  PromptBuilder._();

  static String system({required String languageCode}) {
    return '''
You are Vagabundo, a precise itinerary planner.

IMPORTANT:
Write ALL output strictly in the language with code "$languageCode".
Do NOT mix languages.
Do NOT translate into any other language.

Produce clear, practical text. Avoid emojis and icons.''';
  }

  static String user(ItineraryRequest req) {
    final cityHint = (req.cityLat != null && req.cityLon != null)
        ? 'Known city center (approx): ${req.cityLat}, ${req.cityLon}'
        : 'Known city center (approx): unknown';

    var text = '''
Language: ${req.languageCode}
Trip pace preference: ${req.tripPace.name}.
${req.tripPace.promptDescription}
Create a ${req.days}-day itinerary for ${req.city}, ${req.country}.

$cityHint
REQUIREMENTS:
1) At the TOP LEVEL include:
   "cityLat": <Double>, "cityLon": <Double>
   If unknown, estimate city hall / main square.
   Do NOT use 0 or strings.
   ALSO include:
   "summary": a 1–2 sentence overview of the whole trip (string)
   "pace": one of ["relaxed", "balanced", "packed"]
2) For EACH day include:
   - "variants": array of EXACTLY 1 full-day variants.
Each variant MUST contain:
{
  "morning": itineraryItem,
  "afternoon": itineraryItem,
  "evening": itineraryItem,
  "dayStructure": structured object
}
Each itineraryItem MUST include:
- "title"
- "description"
- "locationName"
- "lat"
- "lon"
Each variant must represent a COMPLETE alternative day.
Do NOT reuse the same morning with different afternoon.
Each variant must feel like a different version of the whole day.
3) "dayStructure" MUST exist inside EACH variant.
It must contain:
- "morning"
- "afternoon"
- "evening"
Each of those is an array (2–5 blocks).
Each block:
- "title": short label
- "steps": 3–6 short steps (strings)
4) Walking realistic.
5) No emojis.
6) JSON only.
7) If structure is missing, output is INVALID.
Output shape example (schema, not content):
{
  "country": "...",
  "city": "...",
  "summary": "...",
  "pace": "balanced",
  "cityLat": 43.856,
  "cityLon": 18.413,
  "days": [
    {
      "dayNumber": 1,
      "title": "...",
      "variants": [
        {
          "morning": { "title":"...", "description":"...", "locationName":"...", "lat":43.86, "lon":18.41 },
          "afternoon": { ... },
          "evening": { ... },
          "dayStructure": {
            "morning": [ { "title":"...", "steps":["..."] } ],
            "afternoon": [ { ... } ],
            "evening": [ { ... } ]
          }
        }
      ]
    }
  ]
}
Steps must be non-empty strings. Do not output empty steps.''';

    // 🔗 Dodaj postojeće add-one da model vidi car zahtjeve. NAPOMENA: AI više
    // NE generiše stvarnu rutu/segmente (roadTripAddon je uklonjen) — to sada
    // radi RoadTripPlannerService (Google Routes/Places, Dio A), pozvan
    // odvojeno u CloudItineraryGenerator nakon ovog poziva. carAddon() ostaje
    // jer i dalje daje AI-ju kontekst za sadržaj dana (biraj POI-jeve "usput",
    // parking, kratke pauze u Morning/Afternoon/Evening napomenama).
    text += originAddon(req);
    text += carAddon(req);

    return text;
  }

  // MARK: - JSON scheme (parsirane jednom, koriste se kao response_format).

  static Map<String, dynamic>? get jsonSchema => _tryParse(_itinerarySchemaJson);
  static Map<String, dynamic>? get variantSchema => _tryParse(_variantSchemaJson);

  static Map<String, dynamic>? _tryParse(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static const String _itinerarySchemaJson = '''
{
  "type": "object",
  "properties": {
    "summary": {"type": ["string","null"]},
    "pace": {
      "type": ["string","null"],
      "enum": ["relaxed","balanced","packed", null]
    },
    "country": {"type": "string"},
    "city": {"type": "string"},
    "cityLat": {"type": "number"},
    "cityLon": {"type": "number"},
    "days": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "dayNumber": {"type": "integer"},
          "title": {"type": ["string","null"]},
          "variants": {
            "type": "array",
            "minItems": 1,
            "maxItems": 1,
            "items": {
              "type": "object",
              "properties": {
                "morning": { "\$ref": "#/\$defs/item" },
                "afternoon": { "\$ref": "#/\$defs/item" },
                "evening": { "\$ref": "#/\$defs/item" },
                "dayStructure": { "\$ref": "#/\$defs/dayStructure" }
              },
              "required": ["morning","afternoon","evening","dayStructure"]
            }
          }
        },
        "required": ["dayNumber","variants"]
      }
    }
  },
  "required": ["country","city","cityLat","cityLon","days"],
  "\$defs": {
    "item": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "description": {"type": "string"},
        "locationName": {"type": ["string","null"]},
        "lat": {"type": ["number","null"]},
        "lon": {"type": ["number","null"]}
      },
      "required": ["title","description"]
    },
    "dayStructure": {
      "type": "object",
      "properties": {
        "morning": {
          "type": ["array","null"],
          "items": { "\$ref": "#/\$defs/day_block" }
        },
        "afternoon": {
          "type": ["array","null"],
          "items": { "\$ref": "#/\$defs/day_block" }
        },
        "evening": {
          "type": ["array","null"],
          "items": { "\$ref": "#/\$defs/day_block" }
        }
      }
    },
    "day_block": {
      "type": "object",
      "properties": {
        "title": { "type": "string" },
        "steps": { "type": "array", "items": { "type": "string" } }
      },
      "required": ["title","steps"]
    }
  }
}
''';

  static const String _variantSchemaJson = '''
{
  "type": "object",
  "properties": {
    "dayNumber": {"type": "integer"},
    "variant": {
      "type": "object",
      "properties": {
        "morning": { "\$ref": "#/\$defs/item" },
        "afternoon": { "\$ref": "#/\$defs/item" },
        "evening": { "\$ref": "#/\$defs/item" },
        "dayStructure": { "\$ref": "#/\$defs/dayStructure" }
      },
      "required": ["morning","afternoon","evening","dayStructure"]
    }
  },
  "required": ["dayNumber","variant"],
  "\$defs": {
    "item": {
      "type": "object",
      "properties": {
        "title": {"type": "string"},
        "description": {"type": "string"},
        "locationName": {"type": ["string","null"]},
        "lat": {"type": ["number","null"]},
        "lon": {"type": ["number","null"]}
      },
      "required": ["title","description"]
    },
    "dayStructure": {
      "type": "object",
      "properties": {
        "morning": {
          "type": ["array","null"],
          "items": { "\$ref": "#/\$defs/day_block" }
        },
        "afternoon": {
          "type": ["array","null"],
          "items": { "\$ref": "#/\$defs/day_block" }
        },
        "evening": {
          "type": ["array","null"],
          "items": { "\$ref": "#/\$defs/day_block" }
        }
      }
    },
    "day_block": {
      "type": "object",
      "properties": {
        "title": { "type": "string" },
        "steps": { "type": "array", "items": { "type": "string" } }
      },
      "required": ["title","steps"]
    }
  }
}
''';

  // MARK: - Add-oni

  static String carAddon(ItineraryRequest req) {
    if (!req.byCar) return '';
    return '''
###
ROAD TRIP RULES:
- The user is driving a car.
- Prefer POIs with easy parking and quick on/off access from main roads.
- Insert short DRIVING BREAK suggestions between time blocks (fuel/coffee/playground/restrooms) INSIDE the existing Morning/Afternoon/Evening notes.
- Avoid large detours; keep stops broadly along the way between main POIs.
- If a day is long, you may suggest an OVERNIGHT midway (optional) in the Evening note.
- IMPORTANT: Keep the output schema EXACTLY the same as specified. Do NOT add extra fields.
- To mark any driving tip line, prefix the line with the literal token "[CAR]" (no emoji). Example: "[CAR] Quick break near A1 rest area…"
###''';
  }

  static String originAddon(ItineraryRequest req) {
    if (!req.byCar) return '';
    if (req.originName != null && req.originName!.isNotEmpty) {
      return '\nORIGIN: ${req.originName}\nDESTINATION: ${req.city}, ${req.country}\n';
    }
    if (req.originLat != null && req.originLon != null) {
      final lat = req.originLat!.toStringAsFixed(5);
      final lon = req.originLon!.toStringAsFixed(5);
      return '\nORIGIN_COORDS: $lat, $lon\nDESTINATION: ${req.city}, ${req.country}\n';
    }
    return '';
  }
}
