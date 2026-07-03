import 'dart:math';

/// Motivacione rečenice za AppHeroSection naslov — identične iOS listi.
/// Jedna se bira NASUMIČNO pri pokretanju ekrana (isti pattern kao
/// _pickRandomHeroImage u main_screen.dart), i ostaje ista dok korisnik
/// ne izabere grad — tad se prikazuje "Plan your trip to {city}, {country}."
/// umjesto nje.
class HeroTaglines {
  HeroTaglines._();

  static const List<String> all = [
    'Where will your story begin?',
    'Your next destination is calling.',
    'Plan less. Experience more.',
    'Craft your perfect escape.',
    'Where is your next great adventure?',
    'Where do you want to relax this weekend?',
  ];

  static String pickRandom() => all[Random().nextInt(all.length)];
}
