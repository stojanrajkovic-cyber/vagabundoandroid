class Stay22Service {
  Stay22Service._();

  /// Ekvivalent Stay22ReserveButton.swift stay22URL computed property.
  /// aid=stojanrajkovic je affiliate ID — ISTI na Android i iOS (jedan
  /// affiliate nalog za oba platforma, ne treba poseban Android aid).
  static Uri buildUrl({
    required double lat,
    required double lon,
    String languageCode = 'en',
    String currency = 'EUR',
  }) {
    return Uri.parse(
      'https://www.stay22.com/embed/gm'
      '?aid=stojanrajkovic'
      '&lat=$lat'
      '&lng=$lon'
      '&lang=$languageCode'
      '&currency=$currency'
      '&utm_source=vagabundo'
      '&utm_medium=app'
      '&utm_campaign=city_picker',
    );
  }
}
