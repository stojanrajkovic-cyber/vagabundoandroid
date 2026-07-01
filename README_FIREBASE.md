# Firebase setup (Android)

Vagabundo Android koristi isti Firebase projekt kao iOS app
(`com.stojanrajkovic.Vagabundo` po `AppState.swift`).

## 1. Dodaj Android app u postojeći Firebase projekt

1. Firebase Console → Project settings → Add app → Android
2. Package name: npr. `com.stojanrajkovic.vagabundo` (mora se poklapati s
   `applicationId` u `android/app/build.gradle`)
3. Preuzmi `google-services.json` i stavi ga u `android/app/google-services.json`
   (nije uključen u ovaj export — sadrži tajne ključeve, ne generira se automatski)

## 2. FlutterFire CLI (preporučeno)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Ovo generira `lib/firebase_options.dart` i automatski povezuje
Android/iOS/Web konfiguraciju s istim Firebase projektom. Nakon toga
otkomentiraj u `lib/main.dart`:

```dart
import 'firebase_options.dart';
...
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 3. Android-specifično

`android/app/build.gradle` treba:

```gradle
apply plugin: 'com.google.gms.google-services'
```

i u `android/build.gradle`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.1'
}
```

## 4. Supabase

`InterestsService` (Faza 2) koristi Supabase kao i iOS. Trebat će ti
`SUPABASE_URL` i `SUPABASE_ANON_KEY` — isti kao u iOS `Info.plist` / config.
