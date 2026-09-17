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
- Backend: Supabase in an EU region (account not created yet).
- Payments: prepare for Stripe Connect (payments, platform fee, payouts,
  refunds, status, history); no live payments yet.
- AI (later) must never invent prices; estimates for large projects are
  clearly marked as non-binding.
- Development happens on Windows; iOS builds and releases happen later on a Mac.

## Architecture rules

- Feature-first: `lib/features/<feature>/{data,domain,presentation}`.
  Shared infrastructure in `lib/core/`, visual tokens and theme in
  `lib/design_system/`.
- State management: Riverpod. Navigation: go_router, paths in `AppRoutes`.
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
- Never commit secrets (`.env*`, `env/*.json`, keystores).

## Before every commit

```bash
dart format lib test
flutter analyze
flutter test
```
