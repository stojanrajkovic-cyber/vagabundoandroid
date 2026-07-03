import '../../models/itinerary.dart';

/// Formatira ItineraryResponse kao plain-text pogodan za "Share as text"
/// (native share sheet preko share_plus).
class ItineraryTextFormatter {
  ItineraryTextFormatter._();

  static String format(ItineraryResponse itinerary) {
    final buffer = StringBuffer();
    buffer.writeln('${itinerary.city}, ${itinerary.country} — ${itinerary.days.length} days');
    if (itinerary.summary != null) buffer.writeln(itinerary.summary);
    buffer.writeln();

    for (final day in itinerary.days) {
      buffer.writeln('Day ${day.dayNumber}${day.title != null ? ': ${day.title}' : ''}');
      buffer.writeln('  Morning: ${day.morningItem.title}');
      buffer.writeln('  Afternoon: ${day.afternoonItem.title}');
      buffer.writeln('  Evening: ${day.eveningItem.title}');
      buffer.writeln();
    }

    buffer.writeln('Planned with Vagabundo');
    return buffer.toString();
  }
}
