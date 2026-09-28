# Security and Privacy

| | |
|---|---|
| Status | Draft v0.2 — planning phase. No rules, claims, App Check registration, secrets, or policies exist yet. v0.2 adds the subscription/entitlement security model and the TTS/third-party-SDK privacy analysis. |
| Last updated | 2026-09-21 |
| Related docs | [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels:** **[CONFIRMED]** · **[ASSUMPTION]** · **[DECISION NEEDED]** · **[VERIFY]** · **[LEGAL]** = requires review by a qualified privacy/legal adviser; this document is engineering guidance, not legal advice.

---

## 1. Principles

1. **Children are never principals.** No child credentials, tokens, or identifiers exist outside the parent's own data tree.
2. **Ownership by path.** Everything a parent owns lives under `users/{uid}`. Authorisation is `request.auth.uid == uid`; nothing else needs to be checked for parent data.
3. **Clients cannot write content or entitlements.** `stories`, `pages`, `categories`, `appConfig`, and `entitlements` are read-only (or invisible) for the app; content changes go through admin tooling, entitlement changes only through server code fed by RevenueCat. **[CONFIRMED: the mobile client can never grant itself premium access]**
4. **RevenueCat is the source of truth for subscriptions; Firestore holds a server-written mirror; rules enforce on the mirror.** UI state from the RevenueCat SDK is for display only.
5. **Premium media is never reachable by an unrestricted URL.** **[CONFIRMED]**
6. **Defence in depth.** Security rules are the authorisation layer; App Check is an abuse-reduction layer; Cloud Functions handle the few operations the client must not be trusted with.
7. **Minimise, then minimise again.** If a field is not needed to render a screen or to meet a legal obligation, do not collect it. Only an age-group identifier is stored for a child. **[CONFIRMED]**
8. **Rules are code.** They live in git (`backend/`), have unit tests, and are deployed from git only — never edited in the console or in FlutterFlow.
9. **Secrets never live in git, docs, or FlutterFlow custom code.** RevenueCat public SDK keys are entered in FlutterFlow settings; the webhook secret and REST API key live in Secret Manager. **[CONFIRMED: no API keys in this planning set]**

---

## 2. Threat model

### 2.1 Assets
| Asset | Sensitivity | Why it matters |
|---|---|---|
| Parent account (email, password hash in Firebase Auth) | High | Account takeover exposes child profiles, enables deletion, and can consume the subscription. |
| Child profiles (nickname, age group, avatar) | Medium-High | Minimal by design, but still data about a child; regulated **[LEGAL]**. |
| Reading/listening history (favorites, progress) | Medium | Behavioural data about a child. |
| Free story content | Low-Medium | Licensed / commissioned IP; leakage tolerated. |
| Premium story content (pages, illustrations, audio) | High (business) | The product's revenue; must not be obtainable without an entitlement. |
| Entitlement mirror (`entitlements/{uid}`) | High | If forgeable, premium is free; if wrong, paying parents are locked out. |
| RevenueCat webhook secret and REST API key | High | Forged webhooks could grant premium; the REST key can read/delete subscriber data. |
| Admin capability (custom claim) | High | Can alter what every child sees. |
| App integrity (genuine builds only) | Medium | Modified clients could scrape content or abuse Functions. |

### 2.2 Threats and controls
| # | Threat | Likelihood | Impact | Controls |
|---|---|---|---|---|
| T1 | Parent A reads or edits parent B's data by guessing IDs | Medium | High | Rules: path ownership; rules unit tests (AC-35); opaque auto-IDs for children. |
| T2 | Client writes to content collections | Medium | High | Rules deny all client writes; admin writes only via Admin SDK (AC-36). |
| T3 | Child accidentally reaches purchases, prices, external links, settings, or deletes data | High | Medium | Parental gate (§7) in front of every such surface; child-facing lock screen has no prices; confirmations; deletion requires re-auth (AC-66, AC-67). |
| T4 | Scripted / modified client abuses Firestore, Storage, or Functions (scraping, quota burn) | Medium | Medium | App Check enforced on all three; query limits in rules (§4.4); budget alerts. |
| T5 | Leaked tokened download URLs expose content | Medium | Low for free content / **High for premium** | Free content: accepted (D-09). Premium page media: **no tokens are ever created**; SDK access under rules only; scheduled audit asserts the absence of tokens (T15). |
| T6 | Account takeover (weak password, phishing) | Medium | High | Firebase Auth password policy, email verification prompt, re-auth for destructive actions. |
| T7 | Admin credential compromise | Low | High | Admin claim only on dedicated accounts with 2-step verification; claim granted by an owner-run script, not by a Function; separate admin accounts per environment. |
| T8 | Rules drift (console or FlutterFlow overwrites rules) | Medium | High | Rules deployed only from git via CI; FlutterFlow rule deployment disabled; periodic diff of deployed vs. git rules. |
| T9 | Sensitive data in logs / crash reports | Medium | Medium | No nickname / email / child ID in custom log keys; Functions log UIDs only where necessary; raw webhook payloads only in Cloud Logging with limited retention. |
| T10 | Excessive data collection by SDKs (advertising ID, analytics, attribution) | Medium | High (policy) | No ad SDKs; analytics off or with ad-ID collection disabled (D-04); RevenueCat attribution/device-identifier collection **not** enabled (§8, P-15); SDK inventory reviewed each release **[LEGAL]**. |
| T11 | Lost / shared device with the parent still signed in | High | Low-Medium | Child area is safe by design; parent area and paywall behind the gate; destructive actions behind re-auth. |
| T12 | Dependency / supply-chain compromise | Low | High | Dependencies pinned in FlutterFlow and `backend/`; CI dependency audit; review of new packages in every `flutterflow → develop` PR. |
| T13 | Cloud Functions abuse (mass calls, cost) | Low | Medium | Callables require auth + App Check; act only on the caller's own UID; per-UID rate limit on `syncEntitlement`; bounded retries. |
| T14 | Content that is inappropriate or incorrect reaches children | Low | High (trust) | Content review in `dev` before `publish`; `status` gate; instant unpublish path; generated audio reviewed by a native speaker (D-23). |
| T15 | Premium media leaks via an accidentally created download token (console upload, tooling bug) | Medium | High | Import script never creates tokens under `stories/premium/**/pages/**`; scheduled `auditPremiumTokens` Function lists those objects and alerts/strips tokens; console uploads to premium paths are a documented prohibition. |
| T16 | Client forges premium state (modified app, jailbroken device spoofing the RevenueCat SDK's customer info) | Medium | High | Enforcement is on the server-written mirror, not on SDK state; the mirror is built only from server-side calls to RevenueCat; App Check reduces modified clients. UI may show "unlocked" briefly, but pages and media are denied by rules. |
| T17 | Forged or replayed RevenueCat webhook | Low-Medium | High | Shared-secret `Authorization` header checked with constant-time comparison; event ID idempotency; the Function **re-fetches the subscriber from the RevenueCat REST API** and never trusts the payload alone; sandbox events cannot affect production entitlements (D-26). |
| T18 | Stale mirror keeps premium alive after expiry (missed webhook) | Medium | Medium | Rules require `accessExpiresAt > request.time`; scheduled re-sync of entitlements expiring within 48 h **[ASSUMPTION]**; client-triggered `syncEntitlement` on launch when stale. |
| T19 | Race after purchase: SDK says entitled, mirror not yet written → rules deny | High (seconds) | Low | Client calls `syncEntitlement` immediately after purchase/restore and shows a brief "جارٍ التفعيل" state; webhook arrives independently. |
| T20 | Restore/transfer moves the entitlement between Firebase accounts (same store account, different app users) | Medium | Medium | RevenueCat transfer behaviour configured deliberately (D-21); `TRANSFER` events update **both** mirrors; parent is warned before restoring on a different account; support script for disputes. |
| T21 | Third-party SDK in a children's app violates store policies (Kids Category / Families) | Medium | High (rejection) | RevenueCat is purchase infrastructure, not ads/analytics; disable device-identifier and attribution collection; TTS is on-device and receives only story text; review Play Families SDK requirements and Apple Kids guidelines before submission **[VERIFY]** **[LEGAL]**. |
| T22 | Compromised RevenueCat REST API key | Low | High | Stored only in Secret Manager; least-privilege key type **[VERIFY RevenueCat key scopes]**; rotation procedure documented; never used from the client. |
| T23 | Cached premium media remains on device after expiry or sign-out | High | Low-Medium | Premium cache stored in app-private storage, excluded from backups, purged on sign-out and on entitlement loss; offline grace bounded (see [MONETIZATION_AND_TTS.md §7.3](MONETIZATION_AND_TTS.md)). |
| T24 | Child triggers a purchase through OS-level prompts (e.g., store re-authentication sheets) | Low | Medium | Purchase sheets are invoked only from `PaywallPage` behind the gate; store parental controls ("Ask to Buy") are supported implicitly through the platform; no one-tap purchase anywhere else. |

---

## 3. Authentication and authorisation model

### 3.1 Identities
| Identity | Mechanism | Notes |
|---|---|---|
| Parent | Firebase Auth user (email + password; D-01 may add Google / Apple) | The only client identity. Its UID is the RevenueCat app user ID. **[CONFIRMED]** |
| Child | Firestore document under the parent | No credentials. Selected client-side. |
| Admin | Firebase Auth user with custom claim `admin: true` | Used by tooling and (later) an admin web app. Never used on a child device. |
| System | Admin SDK inside Cloud Functions / scripts | Bypasses rules; must validate inputs itself. Only writer of `entitlements/**`. |
| RevenueCat (webhook caller) | Shared secret in `Authorization` header | Server-to-server; not a Firebase identity. |

### 3.2 Session rules
- Firebase Auth persistence keeps the parent signed in on the device; this is intended (the child uses the parent's device).
- Actions that change or remove data outside the child's normal flow (delete child, delete account, sign out, change email/password) require the gate; account deletion additionally requires a **recent re-authentication** (Firebase `reauthenticate`), and the Function checks `auth_time` is within 5 minutes **[ASSUMPTION]**.
- Purchases, restore, and subscription management require the gate; the platform purchase sheet adds the store's own authentication.
- Email verification is prompted but **[DECISION NEEDED — D-17]** whether unverified parents are blocked from creating child profiles. Default: not blocked in MVP.
- Password policy: Firebase Auth's configurable password policy enabled with minimum length 8 **[ASSUMPTION]**.
- On sign-out: RevenueCat SDK is logged out (or reset to anonymous **[VERIFY FlutterFlow behaviour]**), persisted app state is cleared, premium cache purged.

### 3.3 Authorisation summary
| Resource | Read | Create | Update | Delete |
|---|---|---|---|---|
| `users/{uid}` | owner | owner (on sign-up, schema-validated) | owner (allowed fields only) | **denied** (Function only) |
| `users/{uid}/children/{id}` | owner | owner (schema-validated) | owner (schema-validated) | owner (cascade by Function) |
| `…/favorites/{storyId}` | owner | owner (schema-validated) | owner | owner |
| `…/progress/{storyId}` | owner | owner (schema-validated) | owner (schema-validated) | owner |
| `stories/{id}` | signed-in if `published` (free and premium metadata); admin: any | denied | denied | denied |
| `stories/{id}/pages/{p}` | signed-in if parent story `published` **and** (`accessLevel == "free"` **or** entitled); admin: any | denied | denied | denied |
| `categories/{id}` | signed-in | denied | denied | denied |
| `appConfig/public` | signed-in | denied | denied | denied |
| `entitlements/{uid}` | owner; admin | **denied** | **denied** | **denied** |
| `entitlements/{uid}/events/**` | **denied** (admin via Admin SDK only) | denied | denied | denied |
| everything else | denied | denied | denied | denied |

"Signed-in" always means a Firebase Auth user; anonymous auth is not enabled in MVP. "Entitled" = `entitlements/{uid}` exists ∧ `premiumActive == true` ∧ `accessExpiresAt > request.time` (∧ `isSandbox == false` in production if D-26 keeps the default).

---

## 4. Firestore and Storage rule requirements

These are requirements for the rules that will be written in Phases 1–4 (`backend/firestore.rules`, `backend/storage.rules`). They are deliberately expressed as requirements, not final code.

### 4.1 Helper predicates
- `isSignedIn()` — `request.auth != null`.
- `isOwner(uid)` — `isSignedIn() && request.auth.uid == uid`.
- `isAdmin()` — `isSignedIn() && request.auth.token.admin == true`.
- `hasOnlyKeys(list)` — the written document has no keys outside `list`.
- `isValidNickname(s)` — string, 1–20 characters; reject leading/trailing whitespace with a regex **[VERIFY: rules cannot trim]**.
- `isValidAgeGroup(s)` — `s in ["1-2", "3-4", "5-6"]`.
- `isValidAvatar(s)` — `s.matches("^avatar_(0[1-9]|1[0-2])$")`.
- `isValidMode(s)` — `s in ["read", "listen"]`.
- `isServerTime(field)` — `request.resource.data[field] == request.time`.
- `entitlement(uid)` — `get(/databases/$(db)/documents/entitlements/$(uid)).data`.
- `isEntitled(uid)` — `exists(entitlement doc) && entitlement(uid).premiumActive == true && entitlement(uid).accessExpiresAt > request.time` (and `isSandbox == false` in prod per D-26; implemented by deploying a different constant per environment).
- `storyIsPublished(storyId)` / `storyIsFree(storyId)` — from `get(/stories/$(storyId)).data`.

### 4.2 `users/{uid}`
- Read: owner.
- Create: owner; `uid` field equals path; `email` equals `request.auth.token.email`; `locale`, `settings`, `consent` present and well-formed; no other keys except FlutterFlow's `display_name`, `created_time`.
- Update: owner; may change only `display_name`, `settings`, `consent`, `childrenCount`, `updatedAt`; `uid`, `email`, `created_time` immutable; **no subscription/premium key may ever appear** (covered by `hasOnlyKeys`).
- Delete: denied.

### 4.3 `users/{uid}/children/{childId}` and below
- All operations: owner.
- Child create/update: only the allowed keys (`nickname`, `ageGroup`, `avatarId`, `preferredMode`, `createdAt`, `updatedAt`); validators; `createdAt` immutable on update; timestamps are server time.
- Favorites create: keys `storyId`, `createdAt`; `storyId == storyId` path segment. Favouriting a premium story is allowed without entitlement.
- Progress create/update: keys as in the schema; `lastPageNumber >= 1`; `pageCount >= 1`; `lastPageNumber <= pageCount`; counters `>= 0`; `completed` bool; `isValidMode(lastMode)`; `storyId == storyId`. Progress on a premium story may be written only if entitled **[DECISION NEEDED — D-27]**; default: allowed (the page data itself is protected; progress is the parent's own data).
- Optional: on child create, require `get(/users/{uid}).data.childrenCount < get(/appConfig/public).data.maxChildrenPerParent` **[ASSUMPTION: adds two reads per create; acceptable]**.

### 4.4 Content collections
- `stories/{storyId}` read: `isAdmin() || (isSignedIn() && resource.data.status == "published")`. Client list queries must include `where("status", "==", "published")`. Both free and premium metadata are readable — required for the lock badge.
- `stories/{storyId}/pages/{pageId}` read: `isAdmin() || (isSignedIn() && storyIsPublished(storyId) && (storyIsFree(storyId) || isEntitled(request.auth.uid)))`. Up to two `get()` calls per query (evaluated once per list query).
- `categories`, `appConfig/public` read: `isSignedIn()`.
- All writes: denied (`allow write: if false`) — admin tooling uses the Admin SDK. If an admin web app is ever built (D-14), writes become `isAdmin()` with schema validation.
- List-size guard: consider `request.query.limit <= 50` on `stories` **[ASSUMPTION]** to bound scraping cost.

### 4.5 `entitlements/{uid}`
- Read: `isOwner(uid) || isAdmin()`.
- Create / update / delete: **denied for every client**, including admins from the client (admin scripts use the Admin SDK). This is the single most important rule for the business model; it gets its own test cases (owner, other user, admin, unauthenticated × create/update/delete).
- `entitlements/{uid}/events/**`: no client access at all.

### 4.6 Storage
- `stories/free/{storyId}/{rest=**}`: read `isSignedIn()`; write denied.
- `stories/{level}/{storyId}/{version}/cover.{ext}`: read `isSignedIn()`; write denied.
- `stories/premium/{storyId}/{version}/pages/{rest=**}`: read `isAdmin() || (isSignedIn() && firestore-based isEntitled(uid))` using cross-service rules (`firestore.get(/databases/(default)/documents/entitlements/$(request.auth.uid))`) **[VERIFY availability in the chosen region and read cost]**; write denied.
- Everything else: denied.
- No client may create or read object metadata tokens; the import script sets `firebaseStorageDownloadTokens` only on free/cover objects; premium page objects are uploaded without tokens and the `auditPremiumTokens` Function verifies this on a schedule **[ASSUMPTION: daily]**.
- App Check enforcement at the Storage service level (§6) applies on top.
- Note: tokened download URLs for free content and covers are served without evaluating these rules. This is an accepted trade-off limited to non-premium assets (D-09).
- Fallback if cross-service rules are unavailable: premium page reads are denied to all clients and a callable Function returns short-lived signed URLs after checking the mirror server-side ([ARCHITECTURE.md §3.6](ARCHITECTURE.md)).

### 4.7 Testing requirements
- Rules unit tests run against the Emulator Suite in CI for every change in `backend/`.
- Minimum test matrix: each row of §3.3 with (a) unauthenticated, (b) other parent, (c) owner, (d) admin; schema-violation cases for children / favorites / progress; "draft story not readable by parent"; **premium pages: not entitled / entitled / expired mirror (`accessExpiresAt` in the past) / sandbox mirror in prod mode / missing mirror**; **`entitlements` write denied in every case**; Storage: premium page object denied without entitlement and allowed with it; free object allowed; cover allowed.

---

## 5. Admin role strategy (custom claims)

| Aspect | Decision |
|---|---|
| Claim | `admin: true` on the Firebase Auth user. No other roles in MVP. |
| Who gets it | Named content administrators only, on **dedicated** accounts (not the same email used as a test parent), with 2-step verification enabled on the underlying Google account where applicable. Separate admin accounts per environment. |
| How it is granted | A script in `backend/tools/admin/` run **locally by a Firebase project owner** using Application Default Credentials or a service-account key that is never committed. It sets or removes the claim for an email and prints the result. No Cloud Function grants admin — that removes a remotely exploitable path (T7). |
| Where it is used | Firestore / Storage rules (`isAdmin()`): reading drafts and premium content for review; content tooling (which uses the Admin SDK and therefore does not need the claim, but logs the operator's identity); any future admin web app. |
| What it does **not** do | Grant premium to anyone from the client. Manual entitlement grants (support cases) go through `backend/tools/admin/grant-manual-entitlement`, which writes `entitlements/{uid}.manualGrant` with a reason and an expiry via the Admin SDK and is logged. |
| Propagation | Claims are embedded in the ID token; the admin must sign out/in or force a token refresh after the claim changes. |
| Review | Quarterly listing of accounts with the claim and of manual entitlement grants (script output kept in the ops log). |
| Revocation | Same script with `--remove`; revoke refresh tokens for immediate effect. |

---

## 6. Firebase App Check plan

| Step | Action | Environment |
|---|---|---|
| 1 | Register the Android app with **Play Integrity** and the iOS app with **App Attest** (DeviceCheck as fallback for devices that do not support App Attest). | dev first |
| 2 | Enable App Check in the app. Prefer FlutterFlow's built-in App Check setting **[VERIFY it supports Play Integrity + App Attest]**; otherwise a custom action `initAppCheck()` runs at startup. | dev |
| 3 | Use **debug provider tokens** for FlutterFlow test mode, emulators, and CI; register each debug token in the console and rotate them when developers leave. | dev / staging |
| 4 | Turn on **monitoring (unenforced)** for Firestore, Storage, and Functions; watch the verified / unverified request ratio for at least one week of real testing. | staging, then prod |
| 5 | **Enforce** on Firestore, Storage, and Functions (`syncEntitlement`, `deleteAccount`) once unverified traffic from legitimate builds is ~0. The RevenueCat webhook Function is **excluded** from App Check (server-to-server) and protected by its shared secret instead. | staging, then prod |
| 6 | Set token TTL to the default (1 hour) **[ASSUMPTION]**; shorten only if abuse is observed. | all |
| 7 | Document a rollback: disable enforcement per service from the console if a store build starts failing attestation (e.g., new device class). | prod |

Limits: App Check reduces abuse from non-genuine clients; it does not authenticate users, does not replace rules, and does not make the SDK's entitlement state trustworthy (T16). Debug tokens must never be embedded in a release build.

---

## 7. Parental gate requirements

The gate is a **child-resistant, not parent-secure**, barrier. It is required by Apple's Kids Category guidance and Google Play's Families policy before purchases, external links, and parental settings **[VERIFY current store policy wording before submission]**.

| # | Requirement |
|---|---|
| G-01 | Triggers: entering the parent area; opening the paywall or any screen that shows prices; purchase; restore purchases; subscription management links; opening any external link (privacy policy, terms, support, store update link, store billing/subscription pages, device TTS settings); sign-out; deleting a child profile or the account. **[CONFIRMED]** |
| G-02 | Mechanism (MVP): a randomly generated arithmetic problem with two-digit operands, presented **in Arabic words** (e.g., "ما ناتج ثلاثةَ عشرَ زائدَ تسعة؟"), answered by typing digits on a numeric keyboard. Words rather than digits so pre-readers cannot pattern-match. |
| G-03 | A new problem is generated on every attempt; the answer is never shown. |
| G-04 | After 3 wrong answers the gate locks for 30 seconds (client-side timer, session state only). |
| G-05 | A successful gate unlocks the parent area for the current session only; leaving the parent area or backgrounding the app for more than 5 minutes **[ASSUMPTION]** re-locks it. Unlock state is never persisted to disk or Firestore. |
| G-06 | The gate UI is clearly addressed to adults ("للأهل فقط") and uses standard-size (not oversized child) controls. |
| G-07 | External links additionally show a confirmation "سيتم فتح المتصفح" after the gate. |
| G-08 | The gate must be a single reusable FlutterFlow component + one custom function (`generateGateChallenge`) so that every trigger uses the same logic. |
| G-09 | The child-facing `LockedStoryPage` shows **no prices, no product names, no store branding, and no purchase button** — only an explanation and "للأهل". The paywall exists only behind the gate. **[CONFIRMED]** |
| G-10 | Post-MVP option: parent PIN as an alternative gate (still not a security control). |

---

## 8. Child privacy and data-minimisation checklist

Legal frameworks that may apply depending on launch markets — COPPA (US), GDPR / UK GDPR with parental-consent thresholds for children, and regional laws in Arabic-speaking markets (e.g., Saudi PDPL, UAE PDPL) — **[LEGAL]** determine which apply and whether verifiable parental consent mechanisms beyond account creation are required.

| # | Item | Status / owner |
|---|---|---|
| P-01 | Child data collected is exactly: nickname, age group, avatar ID, optional preferred mode, favorites, progress, timestamps. | Enforced by rules (AC-06). |
| P-02 | Not collected about children: full name, date of birth, email, phone, photo, voice, location, contacts, device identifiers for advertising, free-text input. **[CONFIRMED]** | Design + rules. |
| P-03 | Nickname guidance in the UI: "اسم الدلع فقط، لا داعي للاسم الكامل". | FlutterFlow copy. |
| P-04 | No advertising SDKs, no social SDKs, no third-party analytics SDKs. Third-party SDKs in the binary: Firebase (Auth, Firestore, Storage, App Check, Functions, optional Crashlytics), RevenueCat, TTS/audio plugins (on-device). | SDK inventory reviewed at each release. |
| P-05 | Crash reporting (if enabled) contains no custom keys with nickname/email; user identifier is the parent UID at most **[DECISION NEEDED — D-18]**. | Phase 5. |
| P-06 | Firebase Analytics: off by default (D-04). If enabled: disable advertising-ID collection and personalised advertising features; no child identifiers in events. | D-04. |
| P-07 | Parent consent record (`consent` map) stores versions and time of acceptance. | Schema. |
| P-08 | Privacy policy and terms exist in Arabic, hosted at stable URLs stored in `appConfig.legalUrls`, reachable only behind the gate; subscription terms (price, period, auto-renewal, cancellation) are also shown in-app on the paywall as the stores require **[VERIFY]**. **[LEGAL]** content. | Owner. |
| P-09 | App-store declarations: Apple privacy nutrition labels (include purchase data via RevenueCat); Google Play Data safety form including the account-deletion web URL requirement **[VERIFY current requirements]**. | Phase 6. |
| P-10 | Data retention: user data lives until the parent deletes it; entitlement events purged after 90 days **[ASSUMPTION]**; Functions logs retained ≤ 30 days **[ASSUMPTION]**; deleted accounts leave no data in Firestore, Storage caches, or RevenueCat (verified by a test). | Phase 5. |
| P-11 | Data location: the Firebase region decision (D-11) and RevenueCat's processing locations are recorded in the privacy policy **[LEGAL]**. | Owner. |
| P-12 | Access to production data is limited to owner + release manager; developers use `dev`. | Env policy. |
| P-13 | No screenshots or exports of production child data in tickets, docs, or chats. | Team rule. |
| P-14 | Store category: Apple **Kids** category (appropriate age band) and Google Play **Designed for Families** — both restrict SDKs and require the gate; subscriptions are permitted with the gate **[VERIFY]**. | Phase 6. |
| P-15 | RevenueCat configuration for a children's app: app user ID = Firebase UID only (no email or names passed as attributes); **do not** enable device-identifier collection (IDFA/IDFV/GAID) or ad-network attribution features; no RevenueCat attributes containing child data; review RevenueCat's data-processing terms **[LEGAL]** **[VERIFY SDK option names]**. | Phase 4. |
| P-16 | TTS: the engine receives only `ttsTextAr` (story content), never a nickname or any child data (AC-72). Note in the privacy policy that some device TTS engines may process text off-device **[VERIFY per platform]**. | Phase 3. |
| P-17 | Purchases: the child never sees prices or purchase UI; all purchase data is the parent's; refunds and cancellations are handled by the stores. | Design (G-09). |
| P-18 | Cached premium media is stored in app-private storage, excluded from device backups, and purged on sign-out / entitlement loss (T23). | Phase 4. |

---

## 9. Account and child-profile deletion flows

### 9.1 Child profile deletion (client-initiated)
1. Parent passes the gate → `ChildrenListPage` → delete → confirmation explaining that favorites and progress will be removed.
2. Client deletes `users/{uid}/children/{childId}` (rules allow).
3. Cloud Function `onChildProfileDeleted` (Firestore `onDelete` trigger) recursively deletes `favorites` and `progress` under that path. Idempotent; safe to retry.
4. If the deleted child was the active profile, the client clears `activeChild*` app state and returns to `ProfilePickerPage`.
5. Verification: after ≤ 1 minute, no documents remain under the deleted path (AC-10).

### 9.2 Account deletion (server-executed)
1. Parent passes the gate → `AccountPage` → "حذف الحساب" → explanation of what is deleted, that it cannot be undone, and that **an active subscription must be cancelled in the App Store / Google Play separately** (the app cannot cancel it).
2. Client re-authenticates the parent (password; provider re-auth if D-01 adds providers).
3. Client calls callable Function `deleteAccount` (App Check + auth required; no parameters — it acts only on `context.auth.uid`).
4. Function:
   1. Verifies `auth_time` is recent (≤ 5 minutes **[ASSUMPTION]**).
   2. Recursively deletes `users/{uid}` (all children, favorites, progress).
   3. Deletes `entitlements/{uid}` and its `events` subcollection.
   4. Deletes the RevenueCat subscriber for this app user ID via the REST API **[VERIFY endpoint and consequences: this removes purchase history from RevenueCat; the store subscription itself continues until cancelled by the parent]**.
   5. Deletes the Firebase Auth user (this also invalidates tokens).
   6. Writes a minimal audit record without personal data (uid hash, timestamp, outcome) to Cloud Logging **[ASSUMPTION: no separate audit collection]**.
5. Client logs out of RevenueCat, signs out locally, purges caches, clears persisted app state, returns to `WelcomePage`.
6. Failure handling: if steps 4.2–4.4 partially fail, the Function returns an error and the client offers retry; the Auth user is deleted only after data deletion succeeds, so a retry is always possible.
7. Alternative considered: Firebase's "Delete User Data" extension. Not chosen for MVP because the custom Function must also call RevenueCat and control ordering. Revisit if maintenance cost matters more than control.

### 9.3 Web deletion request path
Google Play requires a web-accessible way to request account deletion **[VERIFY current requirement]**. Plan: a static page at the support URL explaining in-app deletion and providing a contact email; requests received by email are processed by an owner using the same admin script logic (delete by email). No self-service web deletion in MVP.

### 9.4 Deletion by admin (support)
`backend/tools/admin/` includes a `delete-user --email` script that runs the same logic as the Function (including RevenueCat subscriber deletion) using the Admin SDK, for support cases. Requires an owner to run it; logs the operator.

---

## 10. Secrets and operational security

- **Secrets inventory:** RevenueCat public SDK keys (per platform; entered in FlutterFlow settings — treated as public but not committed to docs), RevenueCat webhook `Authorization` secret, RevenueCat secret/REST API key, Firebase service-account credentials for tooling (ADC preferred), App Check debug tokens. None appear in git, docs, FlutterFlow custom code, or Firestore. **[CONFIRMED: none inserted in this planning set]**
- Cloud Functions read secrets from Secret Manager; separate values per environment; rotation procedure: rotate in RevenueCat/Secret Manager → redeploy → verify webhook test event.
- Firebase project IAM: Owner = 1–2 people; developers get Editor on `dev` only; production uses least-privilege roles.
- Service-account keys are never committed; prefer Application Default Credentials for scripts; add `*.json` key patterns and `.env*` to `.gitignore` from day one.
- Budget alerts on every Blaze project; Firestore, Storage egress (audio), and Functions invocations reviewed weekly during the first month.
- Backups: scheduled Firestore exports for production **[ASSUMPTION: daily, 30-day retention]** — an owner action after billing is enabled. The entitlement mirror is reconstructible from RevenueCat, so it needs no special backup.
- Incident checklist (to be expanded before launch): revoke tokens, rotate debug App Check tokens, rotate RevenueCat secrets, disable a compromised admin claim, unpublish content, strip any leaked premium token (re-import with a new version), communicate.

---

## 11. Open decisions (security & privacy)

| ID | Decision | Status / default |
|---|---|---|
| D-01 | Sign-in providers | Open — email + password only |
| D-04 | Analytics | Open — crash reporting only |
| D-09 | Tokened download URLs for free content and covers only | **Confirmed direction** |
| D-17 | Block unverified emails from creating child profiles | Open — no |
| D-18 | Include parent UID in crash reports | Open — default no |
| D-21 | RevenueCat restore/transfer behaviour across Firebase accounts | Open — default transfer with warning |
| D-26 | Honour sandbox entitlements in production rules | Open — default no |
| D-27 | Allow writing progress for premium stories without entitlement | Open — default allowed |
| — | Applicable privacy laws and consent mechanism | **[LEGAL]** |
| — | Store categories and age bands for listings; subscription disclosure wording | **[VERIFY]** at Phase 6 |
| — | RevenueCat SDK options for disabling identifier/attribution collection | **[VERIFY]** at Phase 4 |
