# CLAUDE.md

Guidance for AI coding assistants working in this repository.

## Working with the owner

- The owner is not an experienced programmer. Explain important technical
  decisions in plain language (what, why, what the alternative would cost).
- Work step by step along `docs/ROADMAP.md`. **Wait for the owner's
  confirmation before starting a new feature step.** Update the roadmap when
  a step is finished.
- Do not implement Stripe or any live payments until explicitly instructed.

## Confirmed product decisions (2026-09-17)

- ONE mobile app (Flutter, Android + iOS) with **Customer** and **Provider**
  modes. The role is chosen during onboarding; navigation and permissions are
  role-based. Admin functionality is never shipped inside the mobile app.
- App ID `com.gleichda.app`. The brand may change, so code stays brand-neutral
  (Dart package `app`, brand name only via `BrandConfig`).
- Launch in Austria (Vienna), German first. Architecture must support Germany
  and additional languages.
- Backend: Supabase (one dev project connected; a separate prod project comes
  before launch). Sign-in is passwordless with a one-time email code.
- The owner never shares secret keys. Use only the Project URL and the
  publishable key, read from `env/*.json` via `--dart-define-from-file`
  (`Env`). Never hard-code them or commit them. Dashboard changes (SQL,
  email templates) are done by the owner following `docs/supabase-setup.md`.
- Payments: prepare for Stripe Connect (payments, platform fee, payouts,
  refunds, status, history); no live payments yet.
- AI (later) must never invent prices; estimates for large projects are
  clearly marked as non-binding.
- Development happens on Windows; iOS builds and releases happen later on a Mac.

## Architecture rules

- Feature-first: `lib/features/<feature>/{data,domain,application,presentation}`
  (`application/` = Riverpod state shared by several screens). Shared
  infrastructure in `lib/core/`, visual tokens, theme and shared widgets in
  `lib/design_system/`.
- State management: Riverpod. Navigation: go_router, paths in `AppRoutes`.
- Every route lives in exactly one area (`/welcome`, `/customer`, `/provider`).
  `route_guard.dart` is deny-by-default; keep its unit tests in sync. It is a
  navigation guard, not a security boundary.
- Bottom navigation tabs come from `ShellTab`. Keep tab labels short enough for
  five tabs on a 320-point-wide screen.
- Placeholder screens live in the feature folder that will own the real screen;
  replace them there.
- Import `package:material_ui/material_ui.dart`, never
  `package:flutter/material.dart`. Localization delegates come from
  `material_ui` (`GlobalMaterialLocalizations.delegates`).
- Package imports only (`package:app/...`).
- No user-visible strings in code: add them to `lib/l10n/app_de.arb`
  (template, with description) and `app_en.arb`.
- No hard-coded brand name, colors or spacing: use `BrandConfig`,
  `Theme.of(context)`, `AppSpacing` / `AppRadius`.
- Format dates, numbers and currency with
  `MarketConfig.launchMarket.formattingLocale`, not the UI language.
- Store money as integer cents.
- **The server decides.** Anything involving money, job status, verification
  or permissions must be enforced in the backend (Supabase RLS / server
  functions), never only in the app.
- Database changes are new files in `supabase/migrations/` (never edit an
  applied migration). Every table: RLS enabled, explicit grants, policies for
  each allowed action. `security definer` functions set `search_path = ''`
  and revoke execute from `public`/`anon`.
- Roles live in `public.user_roles` and are only added via `add_my_role`
  (customer/provider). The provider role alone never means verified.
- Screens never use Supabase types. Repositories (`data/`) wrap Supabase and
  throw `AppFailure`; tests override repository providers with fakes from
  `test/helpers/pump_app.dart` and never call the real backend.
- Never commit secrets (`.env*`, `env/*.json`, keystores).

## Before every commit

```bash
dart format lib test
flutter analyze
flutter test
```
