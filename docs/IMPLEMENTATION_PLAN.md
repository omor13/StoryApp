# Implementation Plan

| | |
|---|---|
| Status | Draft v0.2 — planning phase. Nothing below has started. v0.2 adds the monetisation phase, the hybrid narrator, and the ages 1–6 content model confirmed on 2026-09-21. |
| Last updated | 2026-09-21 |
| Related docs | [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) |

**Labels:** **[CONFIRMED]** · **[ASSUMPTION]** · **[DECISION NEEDED]** · **[VERIFY]** · **[OWNER]** = an action only the product/project owner can take (accounts, billing, store consoles, RevenueCat, credentials). Claude Code never performs **[OWNER]** actions.

**Roles used below**
- **FlutterFlow tasks** — done in the FlutterFlow editor by a FlutterFlow developer (UI, schema binding, standard actions, RevenueCat integration settings, custom code entered through FlutterFlow).
- **Claude Code tasks** — done in the git repository on the `develop` branch: docs, rules, indexes, Functions, tooling, tests, CI, and drafting the Dart custom code that a developer then pastes into FlutterFlow (see [ARCHITECTURE.md §8](ARCHITECTURE.md)).
- **Owner tasks** — accounts, billing, consoles, store products, RevenueCat, credentials, legal texts.

Each phase is sized to be reviewable in one pull request set and demonstrable at the end. Phases are sequential unless noted.

---

## Current state (2026-09-21)

- Repository folder `StoryApp/` contains only `docs/`; it is **not yet a git repository**.
- No FlutterFlow project, Firebase project, RevenueCat project, GitHub repository, store developer account status, or store listing is known to exist.
- Toolchain on the planning machine: git, Node.js, Firebase CLI, GitHub CLI present; Flutter SDK and FlutterFlow CLI **not** installed.
- Confirmed: ages 1–6 in three groups; two reading modes with hybrid audio; freemium monthly/annual subscription via RevenueCat/FlutterFlow with entitlement `premium_library`; RevenueCat as source of truth; server-side entitlement mirror; no unrestricted URLs for premium media.
- Open decisions: D-01, D-04 … D-08, D-10 … D-15, D-17 … D-28 (tables in the other documents).

---

## Phase 0 — Foundations: repository, projects, conventions

**Goal:** a repository with the agreed branch model, a FlutterFlow project connected to it, and a `dev` Firebase project — with nothing product-specific built yet. Store and RevenueCat account setup starts now because it has long lead times.

**Deliverables**
- Git repository initialised with branches `main`, `develop`; first commit contains `docs/`, `README.md`, `.gitignore` (Flutter, Node, Firebase, service-account keys, `.env*`), `.github/PULL_REQUEST_TEMPLATE.md` (with the RTL/accessibility and "no prices outside gated screens" checklists), `CODEOWNERS`.
- GitHub repository created; branch protection on `main` and `develop`.
- FlutterFlow project created (Arabic default language, RTL) and connected to GitHub, pushing to `flutterflow`.
- First `flutterflow → develop` sync PR merged; a recorded inventory of FlutterFlow-generated paths (`docs/FLUTTERFLOW_GENERATED_PATHS.md`).
- `dev` Firebase project created and linked to FlutterFlow; Blaze billing decision recorded (**mandatory** for Functions — the webhook and entitlement sync — and for Storage on new projects **[VERIFY]**).
- `backend/` skeleton: `firebase.json`, `.firebaserc` (dev alias only), deny-all rules, emulator config, empty `functions/` project, CI workflow running trivial emulator tests.
- Owner checklist started: Apple Developer Program and Google Play Console accounts, paid-apps agreements / tax and banking forms, RevenueCat account.

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Create the project; set default locale `ar` and enable RTL; set app name; create an empty theme with a placeholder Arabic font. | `git init`, branch setup, `.gitignore`, PR template, `CODEOWNERS`, `README.md`. | **[OWNER]** Create the GitHub repo (or grant access). |
| Connect GitHub integration; push once. | After the first push: diff `flutterflow` against the layout in [ARCHITECTURE.md §6](ARCHITECTURE.md); write `docs/FLUTTERFLOW_GENERATED_PATHS.md`; adjust the layout doc if needed. | **[OWNER]** Create the `dev` Firebase project in the chosen region (D-11, verifying cross-service Storage rules availability); enable Auth (email/password), Firestore, Storage; approve Blaze billing with budget alerts. |
| Link the `dev` Firebase project in FlutterFlow; **do not** enable FlutterFlow's rules/Functions deployment. | `backend/` skeleton with deny-all rules, emulator config, Functions project scaffold (no business logic), CI workflow. | **[OWNER]** Confirm the FlutterFlow plan supports GitHub integration and the RevenueCat integration **[VERIFY]**. |
| | | **[OWNER]** Start store developer accounts and agreements; create a RevenueCat account (no products yet). |

**Dependencies:** answers to the blocking questions (end of this document): billing approval, release-pipeline choice (D-13), repository location, store/RevenueCat account ownership.

**Risks**
- FlutterFlow emits files under a path planned as git-only → mitigated by the generated-paths inventory and renaming git-only folders if needed.
- Billing not approved → Functions and Storage blocked; Phase 1 can still proceed with Auth + Firestore and the emulator, but Phases 2 and 4 cannot complete.
- Store agreements (tax/banking) often take weeks → start in Phase 0 so Phase 4 sandbox testing is not blocked.

**Verification**
- `git log` shows docs on `develop`; `flutterflow` branch exists with only FlutterFlow commits.
- FlutterFlow test mode signs in against `dev` Auth.
- CI passes on an empty PR.

---

## Phase 1 — Parent auth, child profiles, app shell, parental gate

**Goal:** a parent can sign up, create child profiles (three age groups), pick one, and reach an empty child home; the parent area is reachable only through the gate. Rules for the `users` tree are live and tested.

**Deliverables**
- Pages: `SplashPage`, `WelcomePage`, `SignInPage`, `SignUpPage`, `ResetPasswordPage`, `CreateChildPage`, `EditChildPage`, `ProfilePickerPage`, `HomePage` (empty state), `ParentalGatePage`/component, `ParentAreaPage`, `ChildrenListPage`, `SettingsPage` (narration autoplay, auto-advance, default speed, default mode), `AccountPage` (sign-out only for now).
- FlutterFlow Firestore schema for `users`, `children` bound exactly as in [FIREBASE_SCHEMA.md §3–4](FIREBASE_SCHEMA.md) (camelCase; `ageGroup` ∈ `1-2`, `3-4`, `5-6`).
- App state: `activeChild*`, `narrationAutoplay`, `autoAdvance`, `playbackSpeed`, `defaultMode`, `gateUnlockedUntil`, `isPremiumUi` (unused yet), `arabicTtsAvailable` (unused yet).
- Theme: Arabic font decision (D-06) applied and evaluated with diacritised sample text; digit style decision (D-05) applied via `toArabicIndicDigits`.
- Custom functions: `numberToArabicWords`, `generateGateChallenge`, `toArabicIndicDigits`.
- `backend/firestore.rules` v1 covering `users/**` with schema validation; `entitlements/**` **deny-all for clients** already in place (so no later phase can forget it); rules unit tests; deployed to `dev` from git.
- Bundled avatar assets (12 placeholders **[ASSUMPTION]**) and the `appConfig/public` seed document in `dev` (including `playback` and `subscription` display config with the `premium_library` placeholder).

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Build the pages/components above with RTL layout, Arabic strings in the localisation table, 48/64 dp targets; age-group chips with Arabic labels from `appConfig`. | Draft the three custom functions as Dart snippets (with unit-test cases) for pasting into FlutterFlow custom code. | **[OWNER]** Provide or approve the avatar set and the Arabic font licence. |
| Configure Auth (email/password), users collection with only the allowed auto-fields. | Write `firestore.rules` for `users/**`, `appConfig`, and the `entitlements` deny-all; emulator tests for the §4.7 matrix rows that exist so far. | Decide D-01, D-05, D-06, D-07. |
| Standard actions: sign-up creates `users/{uid}` with `locale`, `settings`, `consent`; create/edit/delete child; set app state on profile tap. | Seed script for `appConfig/public` in `dev` (Admin SDK, run locally). | |
| Gate component: question from `generateGateChallenge`, numeric keyboard, 3-strike cooldown, session-only unlock. | Review the `flutterflow → develop` sync PR for new dependencies and generated rule files. | |

**Dependencies:** Phase 0; D-01, D-05, D-06 decided.

**Risks**
- Diacritics render poorly in the chosen font → evaluate with real story text before finalising D-06.
- FlutterFlow's "Create Document" cannot set custom IDs → confirms the need for custom actions in Phase 3.
- Rules and FlutterFlow schema drift → the schema doc is the single source; PR checklist item.

**Verification**
- AC-01 … AC-11, AC-27 … AC-30, AC-37 … AC-40 pass on the `dev` project.
- Rules tests: owner can CRUD own child; other parent cannot; unknown field rejected; invalid age group / avatar rejected; any client write to `entitlements` rejected.

---

## Phase 2 — Content model, tooling, and first stories (free and premium)

**Goal:** stories exist in `dev` with pages (display + TTS text), images, and optional prepared audio, imported by a repeatable script that encodes `accessLevel` in Storage paths and creates download tokens only where allowed; content rules and indexes are live.

**Deliverables**
- `backend/tools/content/`: `validate`, `import`, `publish`, `unpublish`, `set-access-level`, `prune-versions`, optional `generate-audio` (D-23) — Node.js, Admin SDK, sample story folders (one free, one premium), README.
- `backend/tools/admin/set-admin-claim` script; first admin claim set on `dev` by the owner.
- `firestore.rules` v2 covering `stories`, `pages` (free-vs-premium logic with the entitlement `get()`), `categories`; `storage.rules` v1 with the `stories/free/**`, cover, and `stories/premium/**/pages/**` rules (cross-service entitlement check **[VERIFY]**); `firestore.indexes.json` with I-1 … I-7; deployed to `dev` from git.
- 3–5 free and 2–3 premium stories (real or placeholder) imported and published in `dev`, across the three age groups; categories seeded.
- `docs/CONTENT_GUIDE.md` for authors: formats, sizes, loudness, diacritics, `displayTextAr` vs `ttsTextAr` rules, per-age-group length limits, alt text, free-story completeness, `pageKind: "question"` usage.

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Add Firestore schema bindings for `stories`, `pages`, `categories`, `appConfig`, `entitlements` (read-only binding) — fields exactly as documented. | Build and document the content tooling; make `import` idempotent per `contentVersion`; write `*Url` fields only for covers and free pages; never create tokens under premium page paths. | **[OWNER]** Supply story text (display + TTS variants), illustrations, and narration (or approve placeholders and the generated-audio approach, D-23); confirm licensing. |
| No UI in this phase beyond verifying bindings compile. | Rules v2 + Storage rules + indexes + tests ("draft not readable", "no client writes", "admin reads drafts", "premium pages denied without mirror", "premium pages allowed with valid mirror", "expired mirror denied", "premium Storage object denied/allowed", "free Storage object allowed"). Fixture mirror documents are written with the Admin SDK in tests. | **[OWNER]** Run the admin-claim script for the designated admin account on `dev`. |
| | `auditPremiumTokens` scheduled Function (list premium page objects, assert no tokens) + test. | Decide D-12, D-15, D-23, D-27. |
| | `docs/CONTENT_GUIDE.md`; sample manifests. | |

**Dependencies:** Phase 0 (Storage and Functions require billing); cross-service Storage rules availability verified; at least placeholder content.

**Risks**
- Content not ready → proceed with placeholder stories clearly marked; do not block Phase 3.
- Cross-service Storage rules unavailable in the chosen region → switch premium media to the signed-URL fallback ([MONETIZATION_AND_TTS.md §9](MONETIZATION_AND_TTS.md)); document.
- Index build time on first deploy → deploy indexes early in the phase.

**Verification**
- `validate` rejects: missing page audio for a page that declares one, out-of-order pages, empty `ttsTextAr`, unknown `accessLevel`, a free story flagged partial.
- Import twice with the same version is a no-op; with a bumped version produces new Storage paths; `set-access-level` moves media between prefixes and tokens appear/disappear accordingly.
- Rules tests for §4.4–4.6 pass; the token audit passes on the imported premium stories.
- Console shows I-1 … I-7 built.

---

## Phase 3 — Library, reader, hybrid narrator, favorites, progress (free stories; premium locked)

**Goal:** the full child loop works end to end on `dev` with real content in both modes; premium stories show the lock badge and the child-facing lock screen leading to the gate (paywall is a placeholder page until Phase 4).

**Deliverables**
- Pages: `HomePage` (shelves: featured, continue reading, favorites, free stories, categories, by age group), `StoryDetailsPage` (mode selector), `LockedStoryPage`, `ReaderPage` (read + listen), completion state.
- Components: `StoryCoverCard` (lock badge, progress ring), `ShelfRow`, `ModeSelector`, `NarrationControls`, `SpeedSelector`, `PageProgress`, `TtsUnavailableNotice`, `EmptyState`, `ErrorState`.
- Custom widgets: `StoryNarrator` (hybrid engine per [MONETIZATION_AND_TTS.md §10–12](MONETIZATION_AND_TTS.md)), `StoryMediaImage` (URL or SDK path via cache).
- Custom actions: `checkArabicTtsVoice`, `openTtsSettings` (gated), `prefetchPageMedia`, `saveProgress` (with mode counters), `toggleFavorite`, `purgePremiumCache` (no-op until Phase 4 caches premium).
- Media cache layer keyed by Storage path with the two fetchers.
- Splash handling of `appConfig`: min build, maintenance mode, featured IDs.

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Build shelves with queries Q2–Q9, Q11–Q14 exactly as documented; lock badge bound to `accessLevel` + `isPremiumUi`. | Evaluate candidate packages (`flutter_tts`, `just_audio`/`audioplayers`, `flutter_cache_manager`) for FlutterFlow custom-code compatibility; record findings. | Review the listening experience with parents of children in each age group (**[ASSUMPTION]** informal sessions); confirm speeds (D-22) and auto-advance defaults (D-24). |
| Reader: RTL page view, image + display text + narrator widget, mode-specific behaviour, autoplay per setting, stop on exit, completion state; `LockedStoryPage` → gate → placeholder paywall. | Draft `StoryNarrator`, `StoryMediaImage`, and the custom actions as Dart for FlutterFlow custom code, including the voice check and fallback matrix; unit tests for sentence chunking, speed mapping, and auto-advance timing logic. | |
| Favorites toggle on details + reader; progress ring on covers; "continue" button logic with last mode/speed. | Rules tests for `favorites` / `progress` validators (`lastPageNumber <= pageCount`, mode enum, counters). | |
| Splash checks against `appConfig/public`; blocking screens. | Sync-PR review; update docs where behaviour deviated from the plan (especially the Android voice-installed detection **[UNRESOLVED]**). | |

**Dependencies:** Phases 1–2; content in `dev`; package compatibility verified.

**Risks**
- TTS plugin limitations (pause on Android, rate scales, voice-installed detection) → sentence-level pause fallback is the design floor; record platform specifics in the doc.
- Audio latency / autoplay restrictions on iOS → pre-buffer the next page's audio; document observed behaviour.
- `StoryNarrator` grows large → keep it parameter-driven and free of Firestore access (data comes in as parameters) so it remains testable.
- RTL `PageView` swipe direction confusion → verify with families; make arrows explicit.

**Verification**
- AC-12 … AC-26, AC-41 … AC-45 (lock screen without paywall), AC-59 … AC-62, AC-64, AC-65, AC-68 … AC-72 pass on `dev`.
- Airplane-mode test: a free story opened earlier still renders pages and images; prepared audio from cache plays; TTS works; progress writes queue and sync when online.
- Device without an Arabic voice: no non-Arabic speech in any scenario (A6, A8).

---

## Phase 4 — Monetisation: RevenueCat, paywall, entitlement sync, premium access

**Goal:** a parent can subscribe (sandbox) monthly or annually, restore, and unlock premium stories; the server-side mirror is written by webhook and callable; Firestore and Storage rules enforce premium; premium media is fetched by SDK path only.

**Deliverables**
- RevenueCat non-prod project configured **[OWNER]**: entitlement `premium_library`, offering `default` with monthly and annual packages, placeholder store products in App Store Connect / Play Console sandbox, webhook URL pointing at `dev`.
- FlutterFlow RevenueCat integration enabled (public keys in FlutterFlow settings only); verified whether it performs `logIn(uid)` / `logOut()` **[VERIFY]**; custom actions `identifyRevenueCatUser` / `logOutRevenueCat` only if needed.
- Pages: `PaywallPage` (packages, prices, disclosures, restore, legal links), `SubscriptionPage` (status, dates, billing-issue banner, gated store links); `LockedStoryPage` wired to the real paywall via the gate.
- Cloud Functions: `revenuecatWebhook`, `syncEntitlement`, `resyncExpiringEntitlements`; tests with recorded payload fixtures and a stubbed RevenueCat REST client; secrets read from Secret Manager (values set by **[OWNER]**).
- Custom actions: `syncEntitlement`, `purgePremiumCache` (real), `isAccessAllowedOffline`, `formatSubscriptionDate` / `formatPriceAr`.
- Premium media path: `StoryMediaImage` and `StoryNarrator` fetch premium assets via the Storage SDK under rules; cache purge on entitlement loss/sign-out.
- Admin scripts: `resync-entitlement`, `grant-manual-entitlement` (bounded, logged).

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Enable the RevenueCat integration; build `PaywallPage` and `SubscriptionPage`; wire purchase and restore actions; `isPremiumUi` from active entitlements; post-purchase `syncEntitlement` + return to story; billing-issue banner. | Implement and test the three Functions and the mirror computation; idempotency; `TRANSFER` handling for both UIDs; sandbox handling per D-26; rate limiting; structured logs without personal data. | **[OWNER]** Create sandbox products with placeholder IDs in both store consoles; configure grace periods; create sandbox testers / license testers; create the RevenueCat non-prod project, entitlement, offering; set webhook secret and REST key in Secret Manager. |
| Ensure no price or purchase affordance exists outside gated screens (navigation audit). | Draft the monetisation custom actions; rules tests for the full premium matrix (entitled / not / expired / sandbox-in-prod / missing); Storage rules tests for premium objects. | Decide D-19, D-20 (final IDs later), D-21, D-25, D-26, D-28. |
| | Support scripts; CI job for Functions; docs updates with observed RevenueCat field names (replace **[VERIFY]** tags). | **[OWNER]** Configure RevenueCat restore behaviour per D-21; disable any device-identifier/attribution collection options **[VERIFY]**. |

**Dependencies:** Phases 1–3; Blaze billing; store developer accounts with agreements accepted; RevenueCat account; region supports cross-service rules (or fallback chosen).

**Risks**
- Store agreements or product approval delays block sandbox purchases → keep Functions and rules testable with fixtures; use RevenueCat test events.
- FlutterFlow's RevenueCat integration lacks a needed hook (user identification, offerings details) → custom actions via the RevenueCat Flutter SDK, still authored in FlutterFlow.
- Race after purchase (T19) → immediate `syncEntitlement` with a visible "جارٍ التفعيل" state; verify ≤ 10 s.
- Sandbox renewals are fast and noisy → dedicated test accounts; mirror `isSandbox` visible in `SubscriptionPage` debug info (dev builds only).

**Verification**
- AC-46 … AC-58, AC-63, AC-66, AC-67 pass on `dev` with sandbox purchases on both platforms (scenarios S1–S20 in [MONETIZATION_AND_TTS.md §16](MONETIZATION_AND_TTS.md)).
- Webhook test event from RevenueCat is accepted; a forged request without the secret is rejected (401); a replayed event is a no-op.
- After expiry in sandbox, the premium story locks without an app restart and the cache purge removes premium files.
- Token audit still passes after all imports.

---

## Phase 5 — Parent area completion, deletion, App Check, production project

**Goal:** all account and privacy features are complete (including RevenueCat subscriber deletion); the production project and RevenueCat prod project exist; App Check is monitored (not yet enforced).

**Deliverables**
- Cloud Functions: `deleteAccount` (callable; deletes Firestore tree, mirror, RevenueCat subscriber, Auth user), `onChildProfileDeleted` (trigger), `purgeEntitlementEvents` (scheduled); tests on the emulator; deployed to `dev` from git.
- Pages: `AccountPage` (sign out, delete account with re-auth and the "cancel your subscription in the store" notice), `DeleteAccountPage`, legal links with external-link confirmation.
- App Check enabled in the app (FlutterFlow setting or `initAppCheck()`), debug tokens registered for dev; the webhook Function excluded from App Check.
- `prod` Firebase project (and `staging` if D-10 says so) created; rules, indexes, Functions deployed from `main` via CI; App Check registered and set to monitor; RevenueCat prod project with real product IDs (D-20) and prod webhook/secrets **[OWNER]**.
- Crash reporting decision (D-04 / D-18) implemented; SDK inventory documented (Firebase, RevenueCat, TTS/audio plugins).
- Backups schedule, IAM matrix, budget alerts checklist applied.

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Account page, re-auth flow, delete confirmation copy; `callDeleteAccount` wiring; sign-out resets state, logs out RevenueCat, purges caches. | Write and test `deleteAccount` (with stubbed RevenueCat deletion), `onChildProfileDeleted`, `purgeEntitlementEvents`; `backend/tools/admin/delete-user`; CI job deploying backend from `main` with a manual approval step. | **[OWNER]** Create `prod` (and `staging`) Firebase projects; enable billing; register apps for App Check (Play Integrity / App Attest); create the RevenueCat prod project; publish Arabic privacy policy, terms, and subscription terms at stable URLs **[LEGAL]**; set `appConfig.legalUrls` and `subscription.manageUrls`. |
| Enable App Check in FlutterFlow settings **[VERIFY]**; otherwise add `initAppCheck()` at startup. | Draft `initAppCheck()` if needed; document debug-token handling; secrets rotation procedure. | Decide D-04, D-17, D-18. |
| External-link confirmation component reused for privacy/terms/support/store/billing/TTS settings. | Backups schedule doc; IAM matrix; budget alerts checklist; privacy-label inventory of data collected by each SDK. | |

**Dependencies:** Phases 1–4; billing on `dev`; owner accounts for App Check registration; legal texts.

**Risks**
- App Check attestation failures on some devices → stay in monitor mode until data is clean; keep the rollback documented.
- RevenueCat subscriber deletion semantics (what happens to an active subscription's future webhooks) **[VERIFY]** → document behaviour; the UI already tells the parent to cancel in the store.
- Store account creation delays → started in Phase 0.

**Verification**
- AC-31, AC-32, AC-10 pass; after deletion no document remains under `users/{uid}` or `entitlements/{uid}`, the RevenueCat subscriber is gone (or documented equivalent), and the Auth user is gone.
- Function tests pass in CI; deploy to `prod` succeeds from `main`.
- App Check dashboard shows ≥ 99 % verified requests from test builds after one week.

---

## Phase 6 — Hardening, compliance, release candidate

**Goal:** a store-submittable build with enforced App Check, reviewed rules, accessibility QA, complete subscription QA on both platforms, and complete store metadata.

**Deliverables**
- App Check enforced on Firestore, Storage, and callable Functions in `prod` (and `staging`).
- Rules review sign-off: deployed rules diffed against git; full §4.7 test matrix green, including every premium and `entitlements` case.
- Full purchase/entitlement and audio/TTS test matrices ([MONETIZATION_AND_TTS.md §16](MONETIZATION_AND_TTS.md)) executed on the device matrix; results recorded.
- Accessibility & RTL QA report across every screen (AC-37 … AC-40, AC-63), TalkBack/VoiceOver pass, "no prices outside gated screens" audit (AC-66, AC-67).
- Performance pass: cold start, first catalog paint, reader page switch, narration start latency, memory with audio, premium media fetch latency.
- Store assets and listings: Kids/Families category selection, privacy labels (incl. purchases via RevenueCat), Data safety form, subscription metadata, screenshots (Arabic), age rating questionnaires, review notes explaining the parental gate, the lock screen, and the absence of ads **[OWNER]** **[LEGAL]**.
- Release process doc (`docs/RELEASE.md`): tagging, backend deploy, FlutterFlow deploy (D-13), RevenueCat/product checklist, rollback.
- Internal testing / TestFlight build distributed to testers with real (prod) products in sandbox mode.

| FlutterFlow tasks | Claude Code tasks | Owner tasks |
|---|---|---|
| Fix QA findings; final copy review of all Arabic strings including paywall disclosures; empty/error states complete. | Rules diff tooling; QA checklists as PR templates; `docs/RELEASE.md`; CI gate for `main`. | **[OWNER]** Store listings, privacy labels, Data safety, age ratings, subscription setup review; **[LEGAL]** review of policy and paywall texts. |
| Build the release candidate via FlutterFlow deploy (Option A) with production Firebase and RevenueCat prod keys. | Verify `minSupportedBuild` handling with a deliberately low build number; run the token audit against prod content. | **[OWNER]** Enforce App Check in the console after monitoring confirms. |

**Dependencies:** Phase 5; store accounts; legal texts; final product IDs and prices (D-20).

**Risks**
- Store review rejection over the gate, the lock screen, or subscription disclosures → pre-empt with review notes and a demo video; keep the gate visibly adult-oriented; follow disclosure requirements exactly **[VERIFY current wording]**.
- Enforcing App Check breaks a device class → rollback plan from the security doc §6.

**Verification**
- Full acceptance-criteria pass (AC-01 … AC-72) on the release candidate against `prod`.
- A fresh install on a clean device completes J1 → J2 → J12 (sandbox) → J14 → J8 without developer help.

---

## Post-MVP backlog (not scheduled)

| Item | Depends on | Notes |
|---|---|---|
| In-app plan change (monthly ↔ annual) | RevenueCat upgrade/downgrade APIs | Currently done in the store. |
| Free trial / intro offers (D-19) | Store product setup, paywall copy | Adds trial states to the mirror/UI. |
| Family sharing / multiple parents (D-28) | Apple Family Sharing, RevenueCat support | — |
| Offline downloads per story | Cache layer already keyed by path | Download-state UI; premium purge rules already exist. |
| Word highlighting synchronised with audio | Per-word timestamps in manifests | Content-pipeline change first. |
| Interactive question pages beyond `pageKind` | Content decision after the first batch | **[UNRESOLVED]** |
| Parent PIN gate | Gate component | Alternative to arithmetic. |
| Admin web app (D-14) | Admin claim, FlutterFlow web project, write rules with validation | Replaces scripts for non-technical admins. |
| English UI | Localisation table already in FlutterFlow | Content remains Arabic. |
| Analytics (D-04) | Privacy policy update | Only with ad-ID collection disabled. |
| Cached TTS output / iOS synthesizer-to-file | Platform APIs | Reduces dependence on prepared audio. |

---

## Cross-phase risks

| Risk | Impact | Mitigation |
|---|---|---|
| FlutterFlow regeneration overwrites custom work | High | Ownership table in [ARCHITECTURE.md §8](ARCHITECTURE.md); never edit generated files on `develop`; custom Dart authored through FlutterFlow only. |
| Rules edited in console or by FlutterFlow deploy | High | Git-only deploys; CI diff check; FlutterFlow rule deploy disabled. |
| Premium content leaks (tokens, cache, stale mirror) | High | No tokens for premium page objects + scheduled audit; private purgeable cache; time-checked mirror; rules tests for every premium case. |
| Client-side entitlement trusted by mistake | High | `isPremiumUi` is display-only by convention and code review; enforcement only in rules; test S15/S16 in every release. |
| Billing surprise (Functions, Storage egress from audio, RevenueCat plan) | Medium | Budget alerts; audio bitrate ≤ 96 kbps; monitor egress weekly; RevenueCat pricing reviewed **[OWNER]**. |
| Region choice wrong (latency, missing cross-service rules) | High (irreversible for Firestore) | Verify availability before creating `dev`; use the same region for all environments. |
| Content pipeline becomes the bottleneck (three age groups, TTS text variants, audio) | Medium | Placeholders unblock engineering; the content guide sets expectations early; generated audio (D-23) fills gaps. |
| Arabic typography and TTS quality | Medium | Decide D-06 with real diacritised text on device in Phase 1; evaluate device voices in Phase 3; prefer prepared audio for premium. |
| Store policy changes (Kids/Families, subscriptions) | Medium | Re-verify requirements at Phase 6 start. |

---

## Definition of done (per phase)

1. All deliverables listed are merged to `develop` (backend, docs) and synced from FlutterFlow (UI).
2. Acceptance criteria named in the phase's verification section pass on the target environment.
3. Rules and Functions tests are green in CI, including the `entitlements` deny-all and premium cases from Phase 1 onward.
4. Docs updated for any deviation from the plan; new decisions added to the decision tables; **[VERIFY]** tags replaced with observed facts.
5. A short demo (screen recording or live) of the phase goal is shown to the owner.

---

## Blocking questions before Phase 0

These are the questions whose answers change what Phase 0 does. Full context lives in the decision tables of the other documents.

1. **Billing and project ownership** — Is Blaze (pay-as-you-go) billing approved for the Firebase projects, and which Google account / organisation will own them? Cloud Functions (now mandatory for the RevenueCat webhook and entitlement sync) and, for new projects, Storage require it **[VERIFY]**.
2. **Store and RevenueCat accounts** — Do Apple Developer Program and Google Play Console accounts exist with paid-apps agreements (tax/banking) accepted, and who owns the RevenueCat account? Sandbox purchase testing in Phase 4 is impossible without them, and agreements can take weeks.
3. **FlutterFlow account and plan** — Does a FlutterFlow project already exist, and does the plan include GitHub integration and the RevenueCat integration (and, optionally, Dev Environments)?
4. **Release pipeline (D-13)** — Will releases be built by FlutterFlow's deploy or from git? This determines where Flutter custom Dart is allowed to live.
5. **Sign-in providers (D-01)** — Email + password only, or also Google / Apple? Affects Phase 1 scope, iOS requirements, and re-authentication before deletion.

Not blocking Phase 0 but needed before Phase 4: final product IDs and prices (D-20), trial policy (D-19), restore/transfer policy (D-21), and the source of prepared audio (D-23).
