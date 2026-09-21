# Roadmap

Each step ends with something testable on a phone. The owner confirms before
the next step starts.

Legend: ✅ done · 🔄 in progress · ⏳ open

## MVP

| # | Step | Status | Result |
|---|---|---|---|
| 0 | **Project setup:** clean Flutter project (Android + iOS), Git, packages, languages, design tokens, navigation base, brand/market config, docs | ✅ | Welcome screen builds for Android; tests pass |
| 1 | **Onboarding & app shells:** role selection (customer / provider), role-based navigation, customer and provider menus with placeholder screens | ✅ | Clickable app skeleton for both roles; role remembered on the device; mode switch in profile |
| 2 | **Backend setup:** Supabase connected (dev project), environment config, login with email code, profiles, roles, security rules | ✅ | Verified end to end on a device: code email, sign-in, role, and profile read from Supabase |
| 2b | **Customer request flow:** home with free-text request field, example requests, category cards; request screen with optional category, location/photo UI prepared, timing | ✅ | Customer describes a job in their own words and finds it again under "Deine Anfragen" |
| 2c | **Requests in the backend:** `service_requests` table with RLS, column grants that keep AI fields out of reach of clients, Supabase repository | ✅ | Requests survive reinstalling the app and are readable only by their own customer |
| 3 | **Service catalog:** categories, services, price options, sample data for Vienna; category and service screens | ✅ | The app shows whatever the backend holds — adding a category needs no release |
| 4 | **Provider onboarding:** guided profile (personal, business, services from the catalog, service area), resumable, provider home, verification status prepared | ✅ | A provider signs up, picks services and reaches their own area — still unverified until the team checks |
| 4b | **Verification & documents:** upload, category-specific requirements, admin review | ⏳ | Provider submits documents; the team approves in Supabase |
| 5 | **Discovery & fixed-price booking:** location, nearby verified providers, option → price → time → request | ⏳ | Customer books a cleaner in Vienna |
| 6 | **Job flow:** accept/decline, on the way, in progress, done, customer confirms, navigation button | ⏳ | Full job lifecycle between two test accounts |
| 7 | **Chat:** live messages and photos per job | ⏳ | |
| 8 | **Reviews & book again** | ⏳ | |
| 9 | **Projects & offers:** project with photos/measurements/budget, offers, compare, accept | ⏳ | Paving project receives offers |
| 10 | **Push notifications** | ⏳ | |
| 11 | **Payments:** Stripe Connect in test mode (only when instructed) | ⏳ | Test payment, platform fee, payout, refund |
| 12 | **Launch prep:** separate prod Supabase project, own email service (SMTP), icon, splash, legal pages + consent at sign-up, account deletion, sign-in tokens in secure storage, crash reporting, store listings, release signing, iOS build on a Mac, TestFlight + Play internal testing | ⏳ | Beta testers install the app |
| 13 | **Closed beta in Vienna**, fixes, public launch | ⏳ | |

## After the MVP

Admin panel for the team · site visits and final quotes · disputes ·
cancellation rules · invoices · Germany as second market · AI request
understanding · automatic matching · live map tracking · automated identity
checks · insurance expiry reminders · milestone payments · more languages ·
analytics.

## Open to-dos for the owner

- [x] Supabase: SQL migration run and verified (tables, RLS, policies, functions, triggers all present)
- [x] Supabase: region confirmed EU (`eu-central-1`, Frankfurt)
- [x] Own email sending: Gmail app password (`docs/supabase-setup.md`, section 3, Variante A)
- [x] Supabase: SMTP settings entered (Gmail), template editing unlocked
- [x] Supabase: email templates switched to codes — verified, a real code email arrived
- [x] First real sign-in on a device — confirmed in the running app
- [x] Supabase: `20260920120000_service_requests.sql` run — verified by creating a real request that survived an app restart
- [x] Supabase: `20260920140000_service_catalog.sql` run — verified against the live catalog on a device
- [ ] **Supabase: run `supabase/migrations/20260921120000_providers.sql`** (`docs/supabase-setup.md`, section 2). Until this is done, provider onboarding cannot save anything

- [x] Android SDK Command-line Tools installed
- [x] Android licences: Google replaced `sdkmanager --licenses`; `flutter doctor` still reports "unknown", which is a tooling mismatch, not a blocker — builds work
- [x] Pixel 7 emulator created and running (Windows Hypervisor Platform enabled)
- [ ] Free up disk space on C: (98% full)
