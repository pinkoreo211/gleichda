# GleichDa – mobile app

On-demand marketplace for local services: customers say what they need, find
verified providers nearby, book, pay and track the job. Providers receive
jobs, send offers and get paid.

One Flutter codebase for **Android and iOS**. Progress: see
[docs/ROADMAP.md](docs/ROADMAP.md).

## Key facts

| | |
|---|---|
| App ID (Android + iOS) | `com.gleichda.app`. This is permanent once published. Users never see it, so it can stay after a rebrand. |
| Dart package name | `app` (brand-neutral, so imports look like `package:app/...`) |
| Platforms | Android 7.0+ · iOS 15+ (iPhone only for now) |
| Launch market | Austria (Vienna) |
| Languages | German (source language), English |
| Backend | Supabase (planned, EU region) |

## Requirements

- Flutter (stable channel, 3.47 or newer)
- Android Studio with Android SDK, SDK Command-line Tools and an emulator
- iOS builds need a Mac with Xcode. This is not possible on Windows.

## Everyday commands

```bash
flutter pub get          # download packages, regenerate translations
flutter run              # start the app on the emulator / connected phone
flutter analyze          # check code quality
flutter test             # run automated tests
flutter build apk --debug
```

## Project structure

```
lib/
├─ main.dart                 start-up
├─ app.dart                  root widget: theme, languages, navigation
├─ core/
│  ├─ config/                brand name, market settings (Austria)
│  └─ routing/               all screens and navigation rules
├─ design_system/            colors, spacing, theme
├─ features/                 one folder per feature
│  └─ onboarding/presentation/welcome_screen.dart
└─ l10n/                     translations (.arb) + generated code
test/                        automated tests
docs/                        roadmap and project documentation
```

Each feature grows into three layers:
`data/` (talks to the backend), `domain/` (models and business rules),
`presentation/` (screens and widgets).

## Texts and languages

- **New text:** add a key to `lib/l10n/app_de.arb` (with a `description`) and
  its translation to `app_en.arb`. The Dart code regenerates on
  `flutter pub get` / `flutter run`.
- **New language:** add `lib/l10n/app_<code>.arb` and add the code to
  `CFBundleLocalizations` in `ios/Runner/Info.plist`.
- Unsupported device languages fall back to German.

## Markets

`lib/core/config/market_config.dart` holds country settings (currency, time
zone, formatting locale, default city). Dates and prices are formatted for
the market (Austria: "Jänner", "€ 89,00"), independent of the UI language.
Adding Germany = adding one `MarketConfig` constant.

## Rebranding checklist

1. `lib/core/config/brand_config.dart` – brand name
2. `lib/design_system/app_colors.dart` – brand color
3. `lib/l10n/*.arb` – slogan and texts mentioning the brand
4. `android/app/src/main/AndroidManifest.xml` – `android:label`
5. `ios/Runner/Info.plist` – `CFBundleDisplayName`, `CFBundleName`
6. App icons and splash screen (once created)

## Note on the UI library

Flutter's Material widgets are now published as the separate package
`material_ui`. Always import `package:material_ui/material_ui.dart`, never
`package:flutter/material.dart`, because mixing both breaks themes and
translations.
