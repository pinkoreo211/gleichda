# Roadmap

Each step ends with something testable on a phone. The owner confirms before
the next step starts.

Legend: ✅ done · 🔄 in progress · ⏳ open

## MVP

| # | Step | Status | Result |
|---|---|---|---|
| 0 | **Project setup:** clean Flutter project (Android + iOS), Git, packages, languages, design tokens, navigation base, brand/market config, docs | ✅ | Welcome screen builds for Android; tests pass |
| 1 | **Onboarding & app shells:** role selection (customer / provider), role-based navigation, customer and provider menus with placeholder screens | ⏳ | Clickable app skeleton for both roles |
| 2 | **Backend setup:** Supabase account (EU region), dev + prod projects, environment config, login with email code, profiles, roles, security rules | ⏳ | Real sign-up and login; role stored on the server |
| 3 | **Service catalog:** categories, services, price options, sample data for Vienna | ⏳ | Real categories loaded from Supabase |
| 4 | **Provider onboarding & verification:** profile, services, prices, service area, availability, document upload, category-specific requirements | ⏳ | Provider submits documents; admin approves in Supabase |
| 5 | **Discovery & fixed-price booking:** location, nearby verified providers, option → price → time → request | ⏳ | Customer books a cleaner in Vienna |
| 6 | **Job flow:** accept/decline, on the way, in progress, done, customer confirms, navigation button | ⏳ | Full job lifecycle between two test accounts |
| 7 | **Chat:** live messages and photos per job | ⏳ | |
| 8 | **Reviews & book again** | ⏳ | |
| 9 | **Projects & offers:** project with photos/measurements/budget, offers, compare, accept | ⏳ | Paving project receives offers |
| 10 | **Push notifications** | ⏳ | |
| 11 | **Payments:** Stripe Connect in test mode (only when instructed) | ⏳ | Test payment, platform fee, payout, refund |
| 12 | **Launch prep:** icon, splash, legal pages, account deletion, crash reporting, store listings, release signing, iOS build on a Mac, TestFlight + Play internal testing | ⏳ | Beta testers install the app |
| 13 | **Closed beta in Vienna**, fixes, public launch | ⏳ | |

## After the MVP

Admin panel for the team · site visits and final quotes · disputes ·
cancellation rules · invoices · Germany as second market · AI request
understanding · automatic matching · live map tracking · automated identity
checks · insurance expiry reminders · milestone payments · more languages ·
analytics.

## Open to-dos for the owner

- [ ] Android Studio → SDK Manager → SDK Tools → install **Android SDK Command-line Tools**
- [ ] Run `flutter doctor --android-licenses` and accept the licenses
- [ ] Android Studio → Device Manager → create an emulator (or connect a phone)
- [ ] Free up disk space on C: (98% full)
