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
| 4a | **Provider prices:** own price options per offered service, activate, deactivate, delete; catalog stays untouched | ✅ | A provider sets their own price and the list shows it instead of the catalog example |
| 4c | **Matching foundation:** requests carry a `service_id`; one security-definer function returns only public provider data; results list with verified badge and own price | ✅ | A customer opens a service and sees who offers it, verified first then cheapest |
| 4d | **Request reaches a provider:** the request stores its town, matching runs on the saved request, the customer sends it to a provider, the provider sees it in their area | ✅ | A customer writes a request in Vienna and a provider finds it on their home screen |
| 4e | **Accept or decline:** the provider answers a received request once; the customer sees the answer on the request and on the provider | ✅ | A provider accepts, and the customer's booking list says so |
| 4f | **Chat:** one private conversation per accepted job; text messages, opened from either side | ✅ | Customer and provider agree a time in the app |
| 4g | **Chat list:** the Chats tab shows every conversation with the other person's name, the job and the last message | ✅ | A provider with ten jobs reaches any chat in one tap |
| 4b | **Verification & documents:** upload to a private bucket, per-service requirements, team review in the dashboard | ✅ | Provider submits documents; the team approves in Supabase |
| 5 | **Discovery & fixed-price booking:** location, nearby verified providers, option → price → time → request | ⏳ | Customer books a cleaner in Vienna |
| 6 | **Job flow:** accepted, time agreed, on the way, in progress, done, customer confirms — each side offered only its own steps | ✅ | Both sides move one job through to the end; skipping a step is refused by the database |
| 7 | **Chat:** live messages and photos per job | ⏳ | |
| 8 | **Reviews:** the customer rates a confirmed job once; the provider's average comes from real reviews | ✅ | An unrated provider reads "no reviews yet", never five stars |
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
- [x] Supabase: providers migration run — provider onboarding verified end to end on a device
- [x] Supabase: provider prices migration run — verified by saving a real price on a device
- [x] Supabase: matching migration run — verified on a device: the price a provider saved appeared for a customer as "ab € 39,99", with no verified badge, because that profile is not verified
- [x] Supabase: request contacts migration run — verified on a device: a request from Wien reached the provider, who sees it under "Requests for you"
- [x] Supabase: request responses migration run — verified on a device: accepted and declined both reached the customer's side
- [x] Supabase: chat migration run — verified on a device with two real accounts: customer and provider reach the same conversation, and neither sees the other pair's
- [x] Supabase: conversation list migration run — verified on a device: the customer sees one chat, the provider both, each with its own last message
- [x] Supabase: no-self-hire migration run — verified on a device: the provider no longer appears in their own results
- [x] Supabase: both job status migrations run — verified on a device with two accounts: the whole lifecycle from agreeing a time to the customer's confirmation
- [x] Supabase: reviews migration run — verified on a device: the customer rated a confirmed job five stars with a comment, the button turned into the given rating, and the provider went from no rating at all to "5,0 · 1 review" in the search
- [x] Supabase: verification migration run — bucket `provider-documents` exists, is not public, and carries all three storage policies
- [ ] **Supabase: run `20260926140000_document_upload_limits.sql`** — the bucket still accepts 50 MB of any file type; the app's 10 MB / PDF-and-photo rule should hold on the server too

- [x] Android SDK Command-line Tools installed
- [x] Android licences: Google replaced `sdkmanager --licenses`; `flutter doctor` still reports "unknown", which is a tooling mismatch, not a blocker — builds work
- [x] Pixel 7 emulator created and running (Windows Hypervisor Platform enabled)
- [ ] Free up disk space on C: (98% full)
