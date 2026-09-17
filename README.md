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
| Backend | Supabase (Auth + Postgres), sign-in with email code |

## Requirements

- Flutter (stable channel, 3.47 or newer)
- Android Studio with Android SDK, SDK Command-line Tools and an emulator
- iOS builds need a Mac with Xcode. This is not possible on Windows.

## Backend configuration

The app reads the Supabase **Project URL** and **publishable key** at build
time from `env/dev.json`. This file is ignored by Git, so the values never
end up in the code or the repository.

1. Copy `env/dev.example.json` to `env/dev.json` and fill in both values
   (Supabase Dashboard → Project Settings → API Keys).
2. Always start or build the app with `--dart-define-from-file=env/dev.json`
   (VS Code: use the "App (dev backend)" launch configuration; Android Studio:
   Run → Edit Configurations → *Additional run args*).
3. Set up the Supabase project once: see
   [docs/supabase-setup.md](docs/supabase-setup.md).

Only public client values belong in `env/*.json`. The publishable key is
compiled into the app by design; data is protected by row level security.
**Never** put `service_role` or `sb_secret_…` keys into the app.

Database changes live in `supabase/migrations/` (applied in order).

## Everyday commands

```bash
flutter pub get          # download packages, regenerate translations
flutter run --dart-define-from-file=env/dev.json
flutter analyze          # check code quality
flutter test             # run automated tests (no backend needed)
flutter build apk --debug --dart-define-from-file=env/dev.json
```

## Project structure

```
lib/
├─ main.dart                 start-up (loads saved session, starts the app)
├─ app.dart                  root widget: theme, languages, navigation
├─ core/
│  ├─ backend/               Supabase client
│  ├─ config/                brand, market (Austria), build-time env values
│  ├─ errors/                user-facing error types and messages
│  └─ routing/               screen addresses, router, route guard
├─ design_system/            colors, spacing, theme, shared widgets
├─ features/                 one folder per feature
│  ├─ auth/                  sign-in with email code, sign-out
│  ├─ session/               server roles + last used mode per account
│  ├─ onboarding/            welcome and mode selection
│  ├─ shell/                 bottom navigation per role
│  ├─ discovery/             customer home (placeholder)
│  ├─ jobs/                  customer bookings, provider jobs (placeholders)
│  ├─ chat/                  chats (placeholder)
│  ├─ availability/          provider calendar (placeholder)
│  ├─ earnings/              provider finances (placeholder)
│  └─ profile/               profile and mode switch
└─ l10n/                     translations (.arb) + generated code
test/                        automated tests (helpers/ has fake backend services)
supabase/migrations/         database structure and security rules (SQL)
env/                         local build config (only *.example.json in Git)
docs/                        roadmap, Supabase setup, documentation
```

Each feature is split into up to four layers:
`data/` (storage and backend access), `domain/` (models and business rules),
`application/` (app-wide state shared by several screens),
`presentation/` (screens and widgets).

## Roles and navigation

- Flow: welcome → sign in with email code → choose mode → customer or provider
  area. Returning users open directly in their last mode.
- **Roles live on the server** (`public.user_roles`). The app can only add
  `customer` or `provider` through the database function `add_my_role`;
  `admin` can never be granted from the app. Having the provider role does
  not mean verified (roadmap step 4).
- The **last used mode** is remembered on the device per account, so another
  account on the same phone does not inherit it. It can be switched in the
  profile.
- Every screen lives in exactly one area: `/welcome/...`, `/customer/...` or
  `/provider/...` (`core/routing/app_routes.dart`).
- `core/routing/route_guard.dart` decides where the user may go (signed out →
  welcome/login, no mode → mode selection, otherwise only their own area).
  This only controls navigation in the app. Data access is enforced by the
  database's row level security.
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
