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
├─ main.dart                 start-up (loads saved session, starts the app)
├─ app.dart                  root widget: theme, languages, navigation
├─ core/
│  ├─ config/                brand name, market settings (Austria)
│  └─ routing/               screen addresses, router, route guard
├─ design_system/            colors, spacing, theme, shared widgets
├─ features/                 one folder per feature
│  ├─ session/               active role (customer / provider), saved on device
│  ├─ onboarding/            welcome and role selection
│  ├─ shell/                 bottom navigation per role
│  ├─ discovery/             customer home (placeholder)
│  ├─ jobs/                  customer bookings, provider jobs (placeholders)
│  ├─ chat/                  chats (placeholder)
│  ├─ availability/          provider calendar (placeholder)
│  ├─ earnings/              provider finances (placeholder)
│  └─ profile/               profile and mode switch
└─ l10n/                     translations (.arb) + generated code
test/                        automated tests (helpers/ has test utilities)
docs/                        roadmap and project documentation
```

Each feature is split into up to four layers:
`data/` (storage and backend access), `domain/` (models and business rules),
`application/` (app-wide state shared by several screens),
`presentation/` (screens and widgets).

## Roles and navigation

- After onboarding the user is either in **customer** or **provider** mode
  (`features/session`). The choice is saved on the device and can be switched
  in the profile.
- Every screen lives in exactly one area: `/welcome/...`, `/customer/...` or
  `/provider/...` (`core/routing/app_routes.dart`).
- `core/routing/route_guard.dart` keeps each role inside its own area
  (deny by default). This only controls navigation in the app. Access to
  real data will be enforced by the backend's security rules.
- Bottom navigation tabs are defined once in
  `features/shell/presentation/shell_tab.dart`. Tab labels must stay short:
  the provider bar has five tabs and must fit a 320-point-wide iPhone SE.

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
