import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../models/itinerary.dart';

/// Generiše jednostavan (crno-bijeli, bez brand stiliziranja) PDF export
/// itinerary-ja za "Share as PDF" — v1, poboljšaj kasnije ako zatreba.
class ItineraryPdfGenerator {
  ItineraryPdfGenerator._();

  static Future<Uint8List> generate(ItineraryResponse itinerary) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('${itinerary.city}, ${itinerary.country}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('${itinerary.days.length} days'
              '${itinerary.pace != null ? " • ${itinerary.pace!.toJson()}" : ""}'),
          if (itinerary.summary != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(itinerary.summary!),
          ],
          pw.SizedBox(height: 16),
          for (final day in itinerary.days) ...[
            pw.Header(
              level: 1,
              text: 'Day ${day.dayNumber}${day.title != null ? ": ${day.title}" : ""}',
            ),
            _daySegment('Morning', day.morningItem),
            _daySegment('Afternoon', day.afternoonItem),
            _daySegment('Evening', day.eveningItem),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _daySegment(String label, ItineraryItem item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(item.title),
          pw.Text(item.description, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
