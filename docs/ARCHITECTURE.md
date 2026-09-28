# Architecture — FlutterFlow + Firebase + RevenueCat

| | |
|---|---|
| Status | Draft v0.2 — planning phase. No Firebase project, FlutterFlow project, RevenueCat project, or repository branch exists yet. v0.2 adds the subscription and hybrid-audio architecture confirmed on 2026-09-21. |
| Last updated | 2026-09-21 |
| Related docs | [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels:** **[CONFIRMED]** decided by the owner · **[ASSUMPTION]** unconfirmed working assumption · **[DECISION NEEDED]** must be resolved before the affected work starts · **[VERIFY]** a claim about a third-party tool that must be checked against its current documentation or behaviour before relying on it.

---

## 1. System overview

```
┌────────────────────────────── Mobile app (iOS / Android) ───────────────────────────────┐
│  FlutterFlow-generated Flutter UI + FlutterFlow custom code (Dart actions / widgets)      │
│  ┌────────────┐ ┌────────────┐ ┌────────────────────┐ ┌────────────┐ ┌────────────────┐ │
│  │ Parent auth│ │ Child area │ │ Reader / Listener  │ │ Gate +     │ │ Local state    │ │
│  │ screens    │ │ (library,  │ │ StoryNarrator      │ │ Paywall +  │ │ activeChild,   │ │
│  │            │ │ lock badge)│ │ (audio file ⇄ TTS) │ │ Parent area│ │ gate, speed…   │ │
│  └─────┬──────┘ └─────┬──────┘ └──────┬──────┬──────┘ └─────┬──────┘ └────────────────┘ │
│        │              │               │      │              │  RevenueCat SDK (FlutterFlow │
│        │              │               │      │ device TTS   │  integration): purchase,     │
│        │              │               │      │ (on-device)  │  restore, customer info      │
└────────┼──────────────┼───────────────┼──────┴──────────────┼──────────────┬──────────────┘
         │              │               │  every request carries an App Check token         │
         ▼              ▼               ▼                     ▼              ▼
┌──────────────┐ ┌──────────────────┐ ┌────────────────┐ ┌─────────────────┐ ┌───────────────┐
│ Firebase Auth│ │ Cloud Firestore  │ │ Firebase       │ │ Cloud Functions │ │ RevenueCat    │
│ parents only │ │ users/…/children │ │ Storage        │ │ deleteAccount   │ │ (subscription │
│ email+pw     │ │ stories/…/pages  │ │ stories/free/… │ │ syncEntitlement │ │ source of     │
│ (+ D-01)     │ │ entitlements ◄───┼─┼────────────────┼─┤ revenuecatWebhk │◄┤ truth)        │
│              │ │ categories       │ │ stories/       │ │ onChildDeleted  │ │ Apple IAP /   │
│              │ │ appConfig        │ │   premium/…    │ │ auditPremium    │ │ Play Billing  │
└──────────────┘ └────────▲─────────┘ └───────▲────────┘ └─────────────────┘ └───────────────┘
                          │ Admin SDK          │ Admin SDK
                ┌─────────┴────────────────────┴──────────┐
                │ Content tooling (Node.js, git)           │  run by an admin on a workstation
                │ validate → (generate audio) → upload →   │  or CI; never from the mobile app
                │ write stories/pages → publish            │
                └──────────────────────────────────────────┘
```

Security boundaries: Firestore and Storage **security rules** are the primary authorisation mechanism (including premium access, via a server-written entitlement mirror); **App Check** limits access to genuine app builds; **Cloud Functions** perform the operations that must not be trusted to the client (entitlement synchronisation, account deletion, cascading cleanup); **RevenueCat** is the source of truth for subscription state and the only path by which premium is granted. Details in [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) and [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md).

---

## 2. Responsibilities of each service

| Component | Responsible for | Explicitly *not* responsible for |
|---|---|---|
| **FlutterFlow** | All pages, components, navigation, theming, localisation strings, Firestore collection schema binding, standard Firebase Auth flows, standard CRUD actions, app state, the RevenueCat integration (initialisation, purchase, restore, entitlement checks in UI conditions), generated code export to the `flutterflow` git branch. | Security rules (authored in git), Cloud Functions, content tooling, any file that lives only in `develop`, granting premium (only RevenueCat + server do). |
| **Flutter / Dart custom code** (authored through FlutterFlow) | Logic FlutterFlow cannot express cleanly: the hybrid narrator widget (audio file ⇄ TTS, speed, auto-advance), Arabic TTS voice check, secure media loading for premium stories, parental-gate question generation, deterministic-ID writes (favorites/progress), progress bookkeeping, Arabic-Indic digits, bidi helpers, RevenueCat user identification if the integration does not do it, App Check bootstrapping if needed. | UI layout (stays in FlutterFlow), server-side trust decisions, entitlement decisions. |
| **Firebase Authentication** | Parent identity only: email + password (D-01 may add providers), password reset, email verification, re-authentication before destructive actions, custom claim `admin`. The Firebase UID is also the RevenueCat app user ID. **[CONFIRMED]** | Any child identity. Children are documents, never users. |
| **Cloud Firestore** | Application data: parent documents, child profiles, favorites, progress, story catalog (with `accessLevel`), story pages (display text, TTS text, media references), categories, app configuration, the **entitlement mirror** written only by trusted server code. Offline persistence on mobile. | Binary media (Storage), secrets, analytics, being the source of truth for subscriptions (RevenueCat is). |
| **Firebase Storage** | Story cover images, page illustrations, prepared narration audio, category icons. Free-story media may be served by tokened download URLs; **premium page media is never exposed by unrestricted URLs** and is fetched through the SDK under rules. **[CONFIRMED]** | Avatars (bundled in the app), user uploads (none exist). |
| **Cloud Functions** | Trusted operations: RevenueCat webhook receiver, on-demand entitlement synchronisation (callable), account deletion (incl. RevenueCat subscriber deletion), cascading cleanup on child-profile deletion, scheduled audit that no premium object carries a download token, optional content validation hooks. | Serving content, business logic the client can do safely under rules. |
| **RevenueCat** | Subscription source of truth: products/offerings, purchase and receipt validation with Apple/Google, entitlement `premium_library`, customer info on device, webhooks to the backend, REST API for server-side verification. | Storing any child data (it never receives any), unlocking content on its own (rules use the mirror). |
| **Apple In-App Purchase / Google Play Billing** | The only payment rails for digital content. Subscription management, cancellation, refunds, grace periods, family sharing (if enabled) happen in the stores. **[CONFIRMED]** | — |
| **Device text-to-speech engine** | Fallback narration from `ttsTextAr` using an Arabic voice present on the device; on-device processing (some Android engines may use cloud synthesis **[VERIFY per engine]** — input is story text only, never child data). | Being the primary narration source when prepared audio exists. |
| **Firebase App Check** | Attesting that Firestore / Storage / Functions requests come from the genuine app (Play Integrity, App Attest / DeviceCheck). | Replacing security rules; protecting the RevenueCat webhook (which is server-to-server and uses a shared secret). |
| **Firebase Emulator Suite** | Local development and automated tests of rules and Functions without cloud resources or billing. | Production data; store or RevenueCat sandboxes. |
| **GitHub** | Source of truth for everything that is *not* FlutterFlow UI: docs, rules, indexes, Functions, content tooling, CI workflows. Receives FlutterFlow exports on the `flutterflow` branch. | Being the source of truth for FlutterFlow UI (FlutterFlow is). |
| **Firebase CLI** | Deploying rules, indexes, and Functions from git (`develop` → dev/staging, `main` → prod). | Deploying the mobile app. |
| **Content tooling** (`backend/tools/content`) | Validating a story manifest, optionally generating audio (D-23), uploading media to versioned, access-level-encoded Storage paths, writing story + page documents, flipping `status` / `accessLevel`. | Anything that runs inside the app. |

---

## 3. Data flow

### 3.1 Sign-in and bootstrap
1. App starts → FlutterFlow auth listener resolves the parent session.
2. App reads `appConfig/public` (min build, maintenance, featured IDs, playback options, subscription display config). If blocked → blocking screen.
3. RevenueCat is identified with the Firebase UID (FlutterFlow integration, or custom action `identifyRevenueCatUser()` **[VERIFY which]**); customer info is fetched and cached by the SDK.
4. If the entitlement mirror is older than 24 h **[ASSUMPTION]** or the SDK state disagrees with the mirror, the app calls `syncEntitlement` (callable) in the background.
5. App lists `users/{uid}/children` → `ProfilePickerPage`. Selecting a profile stores `activeChild*` in persisted app state. No Firestore write is needed.

### 3.2 Library
1. `HomePage` queries `stories` with `status == "published"` (plus `ageGroups array-contains` the active child's group, ordered by `sortOrder`). Both free and premium stories are returned; the UI shows a lock badge when `accessLevel == "premium"` and the user is not entitled (client-side display decision only — enforcement is in rules).
2. "Continue reading" queries `…/progress` where `completed == false`, ordered by `updatedAt desc`, limited to 10, then joins with the loaded catalog in memory.
3. "Favorites" lists `…/favorites` and joins the same way. "Free stories" queries `accessLevel == "free"`.
4. Covers load from `coverImageUrl` — covers are always accessible, including for premium stories, so the lock badge can sit on a real cover.

### 3.3 Opening a story
1. `StoryDetailsPage` shows metadata from the catalog document and reads `progress/{storyId}` to offer "continue".
2. If `accessLevel == "premium"` and the user is not entitled → `LockedStoryPage` (child-facing, no prices) → "للأهل" → gate → `PaywallPage` (§3.8).
3. Otherwise the parent/child chooses "اقرأ بنفسي" or "استمع إلى القصة" → `ReaderPage` in that mode.
4. `ReaderPage` queries `stories/{storyId}/pages` ordered by `pageNumber` (one query; a story has ≤ ~30 pages **[ASSUMPTION]**). For premium stories the rules verify the entitlement mirror before returning pages.

### 3.4 Narration (hybrid) — see [MONETIZATION_AND_TTS.md §10–13](MONETIZATION_AND_TTS.md)
1. For the current page the `StoryNarrator` widget decides the source: prepared audio (`audioPath`/`audioUrl`) if present and loadable → else on-device Arabic TTS of `ttsTextAr` → else "unavailable" state.
2. Before any TTS utterance the widget confirms an Arabic voice is installed; it never falls back to another language.
3. Controls: play, pause, resume, stop, speed; when narration ends and auto-advance applies, the widget invokes the FlutterFlow callback that moves to the next page.
4. Media is fetched through the cache layer: free assets by URL, premium assets by Storage SDK path (rules-enforced); files are cached on disk keyed by Storage path.

### 3.5 Progress and favorites
- Page change → custom action `saveProgress(childId, storyId, pageNumber, pageCount, mode)` merge-writes `progress/{storyId}`. On the last page it sets `completed = true`, `completedAt`, and increments the counter for the mode.
- `toggleFavorite(childId, storyId)` creates or deletes `…/favorites/{storyId}` (deterministic ID → idempotent).

### 3.6 Media access strategy **[CONFIRMED direction; details D-09 revised]**

| Asset class | Storage path prefix | How the app loads it | Why |
|---|---|---|---|
| Covers (all stories) | `stories/{free\|premium}/{storyId}/v{n}/cover.*` | Tokened download URL stored in `coverImageUrl` | Must be visible to everyone for the lock badge; low value if leaked. |
| Free story page media | `stories/free/{storyId}/v{n}/pages/…` | Tokened download URL stored in `imageUrl` / `audioUrl` (FlutterFlow-native widgets can bind directly) | Free by definition; leakage is acceptable. |
| Premium story page media | `stories/premium/{storyId}/v{n}/pages/…` | **Storage SDK by path only** (`imagePath` / `audioPath`); `imageUrl` / `audioUrl` are absent; **no download tokens are ever created** for these objects | Storage rules check the entitlement mirror on every fetch; nothing shareable exists. **[CONFIRMED: no unrestricted URLs for premium media]** |

Alternative kept in reserve: a callable Function that returns short-lived signed URLs for a story's premium media after verifying the mirror server-side. Use it only if cross-service Storage rules are unavailable in the chosen region or the SDK-path approach proves impractical in FlutterFlow **[VERIFY in Phase 3]**. Both alternatives satisfy the "no unrestricted URLs" requirement; the SDK-path approach is preferred because it needs no extra Function and caches naturally by path.

### 3.7 Content publishing (admin, outside the app)
1. Author prepares a story folder: `manifest.json` (metadata incl. `accessLevel`, ordered pages with `displayTextAr` and `ttsTextAr`) + `cover.*` + `pages/NN.image.*` + optional `pages/NN.audio.*`.
2. `validate` checks required fields, page ordering, media presence, text lengths, age groups, that free stories are complete, and that `ttsTextAr` is non-empty for every page.
3. Optional `generate-audio` step (D-23) produces reviewed audio files for pages lacking human narration; generated files are still uploaded as prepared audio with `audioSource: "generated"`.
4. `import` uploads media to `stories/{accessLevel}/{storyId}/v{contentVersion}/…`, creating download tokens **only** for covers and free-story page media, then writes `stories/{storyId}` (status `draft`) and its `pages` in a batch.
5. `publish` sets `status = "published"` and `publishedAt`. `set-access-level` moves a story between free and premium by re-importing under the new prefix with a bumped `contentVersion` (paths change, tokens are created or withheld accordingly).
6. Clients see the change on their next catalog query. Old media versions are pruned by a cleanup script after a grace period.

### 3.8 Purchase (parent) — see [MONETIZATION_AND_TTS.md §2–6](MONETIZATION_AND_TTS.md)
1. `PaywallPage` (reachable only via the gate) loads the current RevenueCat offering (monthly + annual packages) with store-localised prices.
2. Parent taps a package → FlutterFlow RevenueCat purchase action → platform purchase sheet → RevenueCat validates the receipt with Apple/Google → SDK returns customer info with `premium_library` active.
3. App immediately calls `syncEntitlement` (callable); the Function fetches the subscriber from the RevenueCat REST API and writes `entitlements/{uid}`. Independently, RevenueCat sends a webhook (`INITIAL_PURCHASE`) to `revenuecatWebhook`, which performs the same write (idempotent).
4. UI unlocks (the SDK state is used for display; the mirror is used by rules); the child's locked story opens.

### 3.9 Entitlement synchronisation (server) — see [MONETIZATION_AND_TTS.md §8](MONETIZATION_AND_TTS.md)
- **Push:** RevenueCat → `revenuecatWebhook` (HTTPS Function, shared-secret header) for every subscription event → verify → re-fetch subscriber from RevenueCat → compute mirror → write `entitlements/{uid}` + append `events/{eventId}`.
- **Pull:** app → `syncEntitlement` (callable; auth + App Check; acts only on the caller's UID; rate-limited) after purchase, restore, sign-in, and when stale.
- **Rules:** premium reads require `entitlements/{uid}.premiumActive == true && accessExpiresAt > request.time`.
- The client can never write the mirror; the mirror is derived only from RevenueCat data fetched server-side.

### 3.10 Account deletion
Parent → gate → re-authentication → callable `deleteAccount` → Function verifies recent sign-in, recursively deletes `users/{uid}`, deletes `entitlements/{uid}` (with events), deletes the RevenueCat subscriber via REST API, deletes the Auth user → client signs out. The active store subscription is **not** cancelled by this (stores do not allow it); the UI tells the parent to cancel it in the store. Details in [SECURITY_AND_PRIVACY.md §9](SECURITY_AND_PRIVACY.md).

### 3.11 Child-profile deletion
Client deletes `users/{uid}/children/{childId}` (allowed by rules) → Firestore trigger `onChildProfileDeleted` recursively deletes its `favorites` and `progress` subcollections.

---

## 4. Application structure (FlutterFlow)

### 4.1 Pages (proposed)
| Area | Pages |
|---|---|
| Bootstrap | `SplashPage`, `BlockedPage` (maintenance / update) |
| Parent auth | `WelcomePage`, `SignInPage`, `SignUpPage`, `ResetPasswordPage` |
| Child area | `ProfilePickerPage`, `HomePage`, `StoryDetailsPage`, `LockedStoryPage`, `ReaderPage` (read + listen modes), `StoryCompletePage` (or an overlay state of the reader) |
| Gate | `ParentalGatePage` (or a modal component reused everywhere) |
| Parent area | `ParentAreaPage`, `ChildrenListPage`, `CreateChildPage` / `EditChildPage`, `SettingsPage`, `SubscriptionPage`, `PaywallPage`, `AccountPage`, `DeleteAccountPage` |

### 4.2 Components
`StoryCoverCard` (with lock badge + progress ring), `ShelfRow`, `AvatarGrid`, `AgeGroupChips`, `ModeSelector` (اقرأ بنفسي / استمع), `NarrationControls`, `SpeedSelector`, `PageProgress`, `ParentalGateDialog`, `ExternalLinkConfirmDialog`, `PaywallPackageCard`, `SubscriptionStatusCard`, `BillingIssueBanner`, `TtsUnavailableNotice`, `EmptyState`, `ErrorState`.

### 4.3 App state (FlutterFlow)
| Name | Persisted | Purpose |
|---|---|---|
| `activeChildId` | yes | Current child profile document ID |
| `activeChildNickname`, `activeChildAgeGroup`, `activeChildAvatarId`, `activeChildPreferredMode` | yes | Avoids re-reading the profile on every screen |
| `narrationAutoplay`, `autoAdvance`, `playbackSpeed`, `defaultMode` | yes | Mirror of parent settings for fast access |
| `gateUnlockedUntil` | no | Session-only timestamp; gate re-locks when leaving the parent area or after **[ASSUMPTION]** 5 minutes |
| `isPremiumUi` | no | Display-only flag derived from the RevenueCat SDK's active entitlements; never used for enforcement |
| `arabicTtsAvailable` | no | Result of the last voice check (re-checked on resume) |
| `catalogCache` | no | Optional in-memory list of published stories for shelf joins |

### 4.4 Custom code inventory (Dart, authored through FlutterFlow custom code — see §8)
| Kind | Name | Purpose |
|---|---|---|
| Custom widget | `StoryNarrator` | Hybrid narration engine: source selection (prepared audio ⇄ TTS), Arabic voice check, play/pause/resume/stop, speed, auto-advance callback, error states. The largest piece of custom code. |
| Custom widget | `StoryMediaImage` | Displays a page illustration from `imageUrl` (free) or from a Storage path via the SDK + disk cache (premium). |
| Custom action | `checkArabicTtsVoice()` | Returns whether an Arabic voice is installed; updates `arabicTtsAvailable`. |
| Custom action | `prefetchPageMedia(...)` | Warms the cache for the next page (image + audio). |
| Custom action | `saveProgress(...)` | Merge-write to `progress/{storyId}` with deterministic ID and mode counters. |
| Custom action | `toggleFavorite(...)` | Create/delete `favorites/{storyId}`. |
| Custom action | `syncEntitlement()` | Calls the callable Function after purchase/restore/sign-in; returns the mirror state. |
| Custom action | `identifyRevenueCatUser()` / `logOutRevenueCat()` | Only if FlutterFlow's integration does not already log in with the Firebase UID **[VERIFY]**. |
| Custom action | `callDeleteAccount()` | Invokes the callable Function and signs out. |
| Custom action | `purgePremiumCache()` | Clears cached premium media on sign-out and on entitlement loss. |
| Custom function | `numberToArabicWords(int)` | Parental-gate question text. |
| Custom function | `generateGateChallenge()` | Random two-operand problem with an Arabic-words prompt and numeric answer. |
| Custom function | `toArabicIndicDigits(String)` | Digit formatting (D-05). |
| Custom function | `formatSubscriptionDate(...)` | Arabic date/price formatting with bidi isolates. |
| Custom action | `initAppCheck()` | Only if FlutterFlow's App Check setting cannot configure the required providers **[VERIFY]**. |

Candidate pub packages (none selected or installed): `flutter_tts` for TTS, `just_audio` or `audioplayers` for prepared audio, `flutter_cache_manager` for the disk cache, `purchases_flutter` (pulled in by FlutterFlow's RevenueCat integration). Each must be verified for FlutterFlow custom-code compatibility **[VERIFY]**.

---

## 5. Environments

| | Development | Staging | Production |
|---|---|---|---|
| Firebase project | one project, suggested name `storyapp-dev` **(placeholder — no project exists)** | `storyapp-staging` **(placeholder)** | `storyapp-prod` **(placeholder)** |
| RevenueCat project | `storyapp-dev` RevenueCat project (sandbox purchases only) **[ASSUMPTION: one RevenueCat project per Firebase environment]** | shared with dev or its own **[DECISION NEEDED — D-25]** | dedicated; webhook secret and REST key distinct from non-prod |
| Store products | Sandbox / test products with placeholder IDs | same | Real products (IDs decided by the owner — D-20) |
| Purpose | Daily development, emulator fallback, FlutterFlow test mode, sandbox purchase testing | Release candidates, store review builds, rules/App Check enforcement rehearsal | Real users |
| Who has access | Developers (Editor) | Developers (Viewer), release manager (Editor) | Owner + release manager only; developers Viewer at most |
| Data | Synthetic; may be wiped | Copy of production content, synthetic users | Real |
| App Check | Debug provider tokens allowed | Enforced (Play Integrity / App Attest) | Enforced |
| Rules / indexes / Functions deployed from | `develop` (manual `firebase deploy` or CI) | `develop` tag / `release/*` | `main` (CI, protected) |
| Function secrets (RevenueCat webhook secret, REST key) | Secret Manager, dev values | Secret Manager | Secret Manager, prod values; never in git or FlutterFlow **[CONFIRMED: no keys in docs or code]** |
| App bundle ID | `<base>.dev` **[ASSUMPTION]** | `<base>.staging` | `<base>` |
| FlutterFlow connection | FlutterFlow project points here for test mode and dev builds | Via FlutterFlow "Dev Environments" if available on the plan **[VERIFY]**; otherwise via local builds from git with the staging Firebase config | Same mechanism as staging |

**[DECISION NEEDED — D-10]** Start with all three projects, or start with `dev` + `prod` and add `staging` before the first store submission? Recommendation: create `dev` now and `prod` when Phase 5 starts; add `staging` only if FlutterFlow environment switching is available on the chosen plan, otherwise treat a TestFlight/internal-track build against `prod` as staging.

**Billing note:** Cloud Functions (mandatory now — the RevenueCat webhook and entitlement sync run there) and, for projects created after October 2024, the default Storage bucket require the Blaze pay-as-you-go plan **[VERIFY against current Firebase pricing]**. Enabling billing is an owner action and is *not* part of this planning phase. Budget alerts should be configured on day one.

**Region [DECISION NEEDED — D-11]:** Firestore location is permanent. Choose one region for Firestore, Storage, and Functions. Cross-service Storage rules (Storage rules reading Firestore) must be available there **[VERIFY]**. Candidates: a Middle-East region if all services are available, otherwise a European region.

---

## 6. Repository layout (proposed)

```
StoryApp/
├── docs/                          # this planning set (git-only)
├── backend/                       # git-only; never touched by FlutterFlow
│   ├── firebase.json              # rules/indexes/functions/emulator config
│   ├── .firebaserc                # project aliases: dev / staging / prod
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   ├── functions/                 # Cloud Functions (TypeScript): revenuecatWebhook, syncEntitlement,
│   │                              #   deleteAccount, onChildProfileDeleted, auditPremiumTokens
│   ├── tools/
│   │   ├── content/               # validate / generate-audio / import / publish / set-access-level / prune
│   │   └── admin/                 # set-admin-claim, delete-user, grant-manual-entitlement (support)
│   └── tests/                     # rules unit tests + Functions tests (Emulator Suite)
├── content/                       # story sources: manifests only in git; media via Git LFS or
│                                  # outside git [DECISION NEEDED — D-12]
├── .github/
│   ├── workflows/                 # CI: rules tests, functions build, flutter analyze
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
├── lib/                           # FlutterFlow-generated (arrives via flutterflow branch)
│   ├── custom_code/               # FlutterFlow custom actions/widgets — source of truth is FlutterFlow
│   ├── flutter_flow/              # generated helpers, incl. custom_functions.dart, revenue_cat_util
│   ├── backend/                   # generated Firestore record classes, Firebase init
│   └── ...                        # generated pages/components
├── android/  ios/  assets/        # FlutterFlow-generated
├── pubspec.yaml                   # FlutterFlow-generated (dependencies are declared in FlutterFlow)
└── README.md
```

Everything under `backend/`, `docs/`, `content/`, `.github/` is **git-only**. Everything else is **FlutterFlow-owned** and must only change via the `flutterflow` branch. On the first FlutterFlow push, the exact set of generated files must be recorded (see Phase 0 in the implementation plan) and this table adjusted if FlutterFlow emits files under a path listed here as git-only **[VERIFY]**.

Secrets (RevenueCat public SDK keys live in FlutterFlow settings; the webhook secret and REST API key live in Secret Manager) are never committed. `.gitignore` covers service-account keys and `.env` files from the first commit.

---

## 7. Git branching and FlutterFlow synchronisation

### 7.1 Branches
| Branch | Written by | Contains | Protection |
|---|---|---|---|
| `flutterflow` | FlutterFlow GitHub integration only | Exact FlutterFlow export | No manual commits, ever. Not protected against force-push by FlutterFlow. |
| `develop` | Developers via PRs; merges from `flutterflow` | Integration: FlutterFlow export + git-only work | Require PR + CI green |
| `main` | Release manager via PR from `develop` | Production-ready | Require PR, CI green, one review; tags `v1.0.0` |
| `feature/*`, `fix/*` | Developers | Git-only work in progress | Short-lived |
| `hotfix/*` | Release manager | Urgent prod fixes branched from `main`, merged back to `main` and `develop` | — |

### 7.2 Synchronisation loop
```
FlutterFlow editor ──push──▶ flutterflow ──merge (PR "Sync FlutterFlow <date>")──▶ develop ──PR──▶ main
                                                   ▲
                    feature/* (git-only work) ─────┘
```
1. A developer finishes UI work in FlutterFlow and pushes to `flutterflow`.
2. Open a PR `flutterflow → develop` titled `Sync FlutterFlow YYYY-MM-DD`. Conflicts should be rare because git-only work lives in paths FlutterFlow never writes; if a conflict appears inside a FlutterFlow-owned file, **the FlutterFlow side always wins** and the intended change is redone inside FlutterFlow.
3. CI runs on the PR: `flutter analyze` (when a Flutter SDK is configured in CI), rules tests, Functions build.
4. Merge. `develop` is now the integration state.
5. Release: PR `develop → main`, tag, deploy backend from `main`, build the app (see §8.3).

### 7.3 Rules that keep the model safe
- Never commit to `flutterflow`. Never cherry-pick *into* it. Never rebase it.
- Never edit FlutterFlow-owned files on `develop`; edit in FlutterFlow and re-sync.
- FlutterFlow custom code (`lib/custom_code/**`, `lib/flutter_flow/custom_functions.dart`) is authored *through FlutterFlow* (its editor or its VS Code extension / CLI **[VERIFY]**), so the exported copy in git is a mirror, not an editing surface.
- FlutterFlow can also deploy Firestore rules and Functions from its UI. **Disable / do not use that**; rules and Functions come from `backend/` only, otherwise the two sources will overwrite each other.
- Every merge from `flutterflow` is reviewed for: unexpected new dependencies, changes to Firebase init files, RevenueCat configuration changes, and any generated rules files (which must be deleted or ignored so they never get deployed).

---

## 8. Separation between FlutterFlow work and custom-code work

### 8.1 Ownership table
| Concern | Owner | Where it lives | How it changes |
|---|---|---|---|
| Pages, components, navigation, theme, strings, widget tree | FlutterFlow | FlutterFlow project → `lib/**` | FlutterFlow editor only |
| Firestore collection schema *binding* (record classes) | FlutterFlow | `lib/backend/schema/**` | FlutterFlow "Firestore" settings, must match [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) |
| RevenueCat integration (keys, purchase/restore actions, entitlement checks in conditions) | FlutterFlow | FlutterFlow settings + generated `revenue_cat_util` **[VERIFY file name]** | FlutterFlow settings; public SDK keys entered there, never in git |
| Firestore *rules*, indexes, Storage rules | Custom code (git) | `backend/` | PR to `develop`; deployed with Firebase CLI |
| Cloud Functions (webhook, sync, deletion, audit) | Custom code (git) | `backend/functions/` | PR to `develop` |
| Content tooling, admin scripts | Custom code (git) | `backend/tools/` | PR to `develop` |
| Dart custom actions / functions / widgets | Custom code, authored in FlutterFlow | `lib/custom_code/**`, `lib/flutter_flow/custom_functions.dart` | FlutterFlow custom-code editor (or its VS Code extension). Reviewed in git after sync. |
| pub dependencies | FlutterFlow | `pubspec.yaml` (generated) | Declared inside FlutterFlow custom-code settings; never edited in git |
| CI, docs, PR templates | Custom code (git) | `.github/`, `docs/` | PR to `develop` |

### 8.2 Design rule for Dart custom code
Custom Dart must be **small, pure, and self-contained**: it may depend on pub packages declared in FlutterFlow and on FlutterFlow's generated record classes, but it must not depend on git-only files. Reason: FlutterFlow compiles custom code in its own workspace, and a dependency on a git-only file would break FlutterFlow test mode and FlutterFlow builds. The `StoryNarrator` widget is the exception in size, not in principle: it depends only on pub packages and receives everything else as parameters and callbacks.

### 8.3 Build and release pipeline **[DECISION NEEDED — D-13]**
| Option | Description | Consequence |
|---|---|---|
| **A. FlutterFlow builds the app** (proposed default) | Releases are produced by FlutterFlow's deploy to App Store / Play. Git `main` is the source for backend + docs and holds a mirror of the released app code (the synced export). | All Dart that ships must live in FlutterFlow (as in §8.1). No Flutter SDK is needed on developer machines for releases. Simplest for a FlutterFlow-first team. |
| B. Git builds the app | Releases are built from `main` locally or in CI (`flutter build`). | Allows git-only Dart (e.g., `lib/custom/`) and per-flavor Firebase configs, at the cost of maintaining a Flutter toolchain, signing, and CI, and of FlutterFlow test mode not seeing git-only code. |

Recommendation: **Option A** until a concrete need for git-only Dart appears. The repository layout above works for both; switching to B later only adds a build workflow.

---

## 9. Content management workflow (no app release required)

1. **Author** writes the story in a `manifest.json` (see [FIREBASE_SCHEMA.md §10](FIREBASE_SCHEMA.md) for the shape) with `displayTextAr` and `ttsTextAr` per page, `accessLevel`, target age groups, plus illustrations and optional narration files in the agreed formats (§10).
2. **Validate** locally: `backend/tools/content validate <folder>` — schema, page ordering, media presence, text length, forbidden characters, age-group values, free-story completeness, non-empty `ttsTextAr`.
3. **Generate audio** (optional, D-23): produce narration for pages without human audio using a cloud TTS chosen by the owner; files are reviewed by a native speaker before import.
4. **Import** to `dev`: uploads media to the access-level-encoded, versioned Storage paths and writes the story as `draft`. Download tokens are created only where allowed (§3.6).
5. **Review** in the dev app (drafts are visible only to admins — rules allow admins to read drafts and premium content).
6. **Promote**: run the same import against `staging` / `prod` (idempotent for a given `contentVersion`), then `publish`.
7. **Correct / re-tier**: fix the manifest or change `accessLevel`, bump `contentVersion`, re-import, re-publish. Old media versions can be pruned by a cleanup script.

**[DECISION NEEDED — D-14]** Longer-term, is a small admin web app (FlutterFlow web project gated by the `admin` claim) wanted? Not in MVP.

---

## 10. Media and content formats (proposed)

| Asset | Format | Constraints |
|---|---|---|
| Cover | WebP (JPEG fallback) | 1200 × 1600 px (3:4) **[ASSUMPTION]**, ≤ 300 KB |
| Page illustration | WebP (JPEG fallback) | 1600 × 1200 px (4:3) **[ASSUMPTION]**; image-dominant layout for `1-2` may use 1:1 **[ASSUMPTION]**; ≤ 400 KB |
| Prepared narration | AAC in `.m4a` | mono or stereo, 64–96 kbps, loudness-normalised (e.g., −16 LUFS integrated **[ASSUMPTION]**), ≤ 60 s per page |
| Category icon | PNG / SVG-rendered PNG | 256 × 256 px, or bundled in the app |
| Avatars | Bundled app assets | 12 predefined avatars **[ASSUMPTION]**, IDs `avatar_01` … `avatar_12` |
| Display text | UTF-8 Arabic, simple MSA, tashkeel where the author supplies it | `1-2`: ≤ 2 short sentences; others ≤ 300 characters per page **[ASSUMPTION]** |
| TTS text | UTF-8 Arabic optimised for engines: numbers written as words, punctuation for pauses, diacritics where they improve pronunciation | Same length limits |

---

## 11. Local development and testing

- **Firebase Emulator Suite** (Auth, Firestore, Storage, Functions) runs from `backend/` for rules unit tests and Functions tests, including replaying recorded RevenueCat webhook payloads. No cloud resources or billing are required for this.
- **Rules unit tests** live in `backend/tests/` and run in CI on every PR that touches `backend/`.
- **FlutterFlow test mode** runs against the `dev` Firebase project (FlutterFlow cannot target the emulator **[VERIFY]**). Purchases in test mode use the store sandboxes through RevenueCat.
- **Device matrix** for TTS and purchases is defined in [MONETIZATION_AND_TTS.md §16](MONETIZATION_AND_TTS.md).
- **Local Flutter runs** (optional) require the Flutter SDK, which is currently not installed on the planning machine.

---

## 12. Assumptions and open decisions (architecture)

| ID | Item | Status / default |
|---|---|---|
| D-09 | Media URLs vs. paths | **Revised & confirmed direction**: URLs for covers and free page media; Storage-SDK paths only (no tokens) for premium page media |
| D-10 | Environment count at start | `dev` now, `prod` at Phase 5, `staging` if the FlutterFlow plan supports environment switching |
| D-11 | Firebase region | Verify Middle-East availability incl. cross-service rules; otherwise a European region |
| D-12 | Where story media sources live | Manifests in git; media in Git LFS or a shared drive — not plain git |
| D-13 | Build & release pipeline | FlutterFlow builds the app (Option A) |
| D-14 | Admin web panel | Not in MVP |
| D-25 | RevenueCat project per environment | One non-prod project (dev + staging) and one prod project |
| — | FlutterFlow plan tier supports GitHub integration, the RevenueCat integration, and (optionally) Dev Environments | **[VERIFY]** |
| — | FlutterFlow's RevenueCat integration logs in with the Firebase UID | **[VERIFY]** — otherwise custom action |
| — | FlutterFlow custom-code directories and generated file list | **[VERIFY]** on first export |
| — | Candidate packages (`flutter_tts`, `just_audio`/`audioplayers`, `flutter_cache_manager`) compile in FlutterFlow custom code | **[VERIFY]** in Phase 3 |
| — | Cross-service Storage rules available in the chosen region | **[VERIFY]** before Phase 2 |
| — | FlutterFlow App Check setting supports Play Integrity and App Attest | **[VERIFY]** in Phase 5 |
