import 'package:flutter/material.dart';

/// Mapiranje Apple SF Symbols naziva (kolona `interests.icon` u Supabase,
/// isti podaci koje iOS app koristi preko `Image(systemName:)`) na najbliži
/// Flutter Material ikon ekvivalent.
///
/// Ovih 40 pokriva CIJELU trenutnu `interests` tabelu (potvrđeno iz stvarnog
/// exporta, 2026-07-02). Ako se doda novi red u Supabase sa novim icon
/// nazivom, `iconFor()` ispod vraća fallback i ispisuje upozorenje u konzoli
/// — tad treba dodati novi red ovdje.
class SfSymbolIcons {
  SfSymbolIcons._();

  static const Map<String, IconData> _map = {
    'archivebox': Icons.archive,
    'arrow.triangle.branch': Icons.alt_route,
    'basketball': Icons.sports_basketball,
    'bicycle': Icons.directions_bike,
    'binoculars': Icons.visibility,
    'building.2': Icons.location_city,
    'building.columns': Icons.account_balance,
    'camera': Icons.camera_alt,
    'cart': Icons.shopping_cart,
    'cpu': Icons.memory,
    'cup.and.saucer': Icons.local_cafe,
    'drop': Icons.water_drop,
    'ferriswheel': Icons.attractions,
    'figure.2.and.child.holdinghands': Icons.family_restroom,
    'figure.hiking': Icons.hiking,
    'figure.pool.swim': Icons.pool,
    'figure.run': Icons.directions_run,
    'flask': Icons.science,
    'fork.knife': Icons.restaurant,
    'fossil.shell': Icons.museum,
    'leaf': Icons.eco,
    'mappin.and.ellipse': Icons.location_on,
    'moon.stars': Icons.nightlife,
    'mountain.2': Icons.terrain,
    'mountain.2.fill': Icons.terrain,
    'music.mic': Icons.mic,
    'music.note': Icons.music_note,
    'paintbrush': Icons.brush,
    'paintpalette': Icons.palette,
    'party.popper': Icons.celebration,
    'pawprint': Icons.pets,
    'shield': Icons.shield,
    'soccerball': Icons.sports_soccer,
    'sparkles': Icons.auto_awesome,
    'sportscourt': Icons.sports_tennis,
    'star.circle': Icons.stars,
    'sun.horizon': Icons.wb_twilight,
    'ticket': Icons.confirmation_number,
    'tram': Icons.tram,
    'wineglass': Icons.wine_bar,
  };

  static const IconData _fallback = Icons.local_offer;

  /// Vraća Flutter IconData za dati SF Symbol naziv, ili fallback ikonicu
  /// (uz debug print upozorenje) ako naziv nije u mapi (npr. novi red u
  /// Supabase tabeli koji još nije dodat ovdje).
  static IconData iconFor(String sfSymbolName) {
    final match = _map[sfSymbolName];
    if (match != null) return match;

    // ignore: avoid_print
    print('⚠️ SfSymbolIcons: nema mapiranja za "$sfSymbolName" — koristi fallback ikonicu. '
        'Dodaj ga u lib/utils/sf_symbol_icons.dart.');
    return _fallback;
  }
}
