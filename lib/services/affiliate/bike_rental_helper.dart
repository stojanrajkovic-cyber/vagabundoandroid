import 'package:url_launcher/url_launcher.dart';

/// Ekvivalent openBikeRentalGoogle(for:) iz ResultView.swift — nema WebView,
/// samo otvara Google Maps pretragu u spoljnoj app/browseru.
class BikeRentalHelper {
  BikeRentalHelper._();

  static Future<void> openGoogleMapsSearch(String city) async {
    final query = Uri.encodeComponent('bike rental in $city');
    final url = Uri.parse('https://www.google.com/maps/search/$query');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
