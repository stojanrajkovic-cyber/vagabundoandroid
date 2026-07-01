# Vagabundo — Flutter (Android)

Faza 1 — Foundation. Vidi `VagabundoAndroidPlan.md` iz projekta za cijeli plan.

## Što je gotovo u Fazi 1

- [x] Struktura projekta (`lib/app`, `lib/services`, `lib/providers`, `lib/screens`, `lib/widgets`)
- [x] `pubspec.yaml` sa svim dependency-ima iz plana
- [x] `AppTheme` — boje, spacing (placeholder paleta, vidi napomenu ispod)
- [x] Floating tab bar — direktan port `AppTabShell.swift` → `app_tab_shell.dart`
- [x] GoRouter navigacija (`StatefulShellRoute.indexedStack`, 4 taba)
- [x] Auth flow — Sign in / Sign up ekran spojen na Firebase Auth
- [x] Riverpod providers za auth stanje (ekvivalent `@EnvironmentObject var session`)

## Pokretanje

```bash
flutter create --org com.stojanrajkovic --platforms=android . --overwrite
flutter pub get
```

Zatim slijedi Firebase setup — vidi `README_FIREBASE.md`.

```bash
flutter run
```

## Napomena o bojama

`lib/app/theme/colors.dart` trenutno ima placeholder hex vrijednosti
(narančasti accent kao pretpostavka iz naziva "Vagabundo"). Kad uploadaš
pravi `AppTheme.swift` u chat, zamijenit ćemo vrijednosti da izgled bude
identičan iOS verziji.

## Sljedeći koraci (Faza 2)

- Port modela: `Itinerary`, `Interest`, `NearbyPOI`, `PlanDocument`
- `FirestoreService`
- `InterestsService` (Supabase)
- AIProxy itinerary generator
- `LocationService`

Uploadaj `Itinerary.swift`, `InterestsService.swift`, `FirestoreService.swift`
kao referencu za Fazu 2.
