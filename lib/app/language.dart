/// App je engleski-only (nema l10n sistema za UI) — SVE što se čita iz
/// Interest.nameTranslations (fetch/display/selectedLabels/displayName) mora
/// koristiti ovu konstantu, NIKAD `Localizations.localeOf(context).languageCode`
/// (jezik UREĐAJA). Miješanje ta dva je uzrokovalo bug: na uređaju podešenom
/// na bs/hr/sr, `ItineraryResponse.interests` je snimao prevedene labele
/// (npr. "Planinarenje") umjesto engleskih ("Hiking"), pa je
/// PackingRecommendationEngine-ov keyword matching (koji traži engleske
/// riječi) uvijek promašivao.
///
/// NAPOMENA: ovo NIJE isto što i `ItineraryRequest.languageCode` — taj i
/// dalje ide sa device locale-om jer kontroliše jezik SADRŽAJA itinerara koji
/// generiše LLM (odvojena, namjerna funkcionalnost).
const String kAppLanguageCode = 'en';
