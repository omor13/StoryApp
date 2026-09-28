# Kids Stories — FlutterFlow Screen Specification

| | |
|---|---|
| Status | Draft v0.1 — planning phase. Exact page-by-page build spec for FlutterFlow. No page, component, or custom code exists yet. |
| Last updated | 2026-09-21 |
| Related docs | [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) · [design/design_tokens.json](../design/design_tokens.json) · [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels:** **[CONFIRMED]** · **[ASSUMPTION]** · **[DECISION NEEDED]** · **[VERIFY]** · **[ASSET NEEDED]**.

---

## 1. Conventions and global setup

### 1.1 Work-split legend (used in every page's table)
| Tag | Who / where | What belongs here |
|---|---|---|
| **[FF-UI]** | FlutterFlow visual work | Widget tree, components, theme bindings, responsive settings, localisation strings |
| **[FF-ACT]** | FlutterFlow action-flow work | On-load actions, button actions, conditional navigation, app-state updates, standard Firestore/Auth/RevenueCat actions |
| **[FB]** | Firebase work (git, `backend/`) | Rules, indexes, seed data, Functions that the page depends on |
| **[DART]** | Custom Dart (authored through FlutterFlow custom code) | Custom widgets / actions / functions listed in [ARCHITECTURE.md §4.4](ARCHITECTURE.md) and [MONETIZATION_AND_TTS.md §15](MONETIZATION_AND_TTS.md) |
| **[CC]** | Claude Code after code export (git `develop`) | Safe tasks only: reviewing the exported page for RTL/semantics/token misuse, writing unit tests for custom functions, rules tests, seed scripts, docs, CI. **Never** edits FlutterFlow-generated widget files. |

### 1.2 FlutterFlow project settings checklist **[FF-UI]**
| Setting | Value |
|---|---|
| Default language / locale | Arabic (`ar`) only in MVP; all strings in the localisation table with English keys as in [DESIGN_SYSTEM.md §13](DESIGN_SYSTEM.md) |
| Text direction | RTL (set at app level; never override per widget) |
| Theme colours | Map slots per [DESIGN_SYSTEM.md §3.3](DESIGN_SYSTEM.md); add custom colours (`errorText`, `outline`, `outlineStrong`, `disabledSurface`, `disabledText`, `scrim`, `white`) |
| Typography | Baloo Bhaijaan 2 + Tajawal per [DESIGN_SYSTEM.md §4.2](DESIGN_SYSTEM.md); bundle font files **[VERIFY FlutterFlow custom-font upload vs. Google Fonts option]** |
| Breakpoints | Compact < 600, Medium 600–839, Expanded ≥ 840 **[VERIFY against FlutterFlow's editor breakpoints; adopt FlutterFlow's if different]** |
| Orientation | Portrait locked on phones; tablets portrait (landscape per D-08) |
| Firebase | `dev` project; Auth email/password; users collection with only allowed auto-fields |
| Firestore schema bindings | Exactly [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) (camelCase) |
| RevenueCat | Enabled in Phase 4 only; keys in FlutterFlow settings, never in docs/git |
| App Check | Phase 5 |
| Splash / launch | Static `storyBlueDark` background + logo **[ASSET NEEDED]** |

### 1.3 Page-name mapping (earlier docs → this spec)
| Earlier name (v0.2 docs) | This spec (canonical from now on) |
|---|---|
| `WelcomePage` | `ParentWelcomePage` |
| `SignInPage`, `SignUpPage` | `ParentSignInPage` (sign-in / sign-up modes) + `ParentPasswordResetPage` (§3) |
| `CreateChildPage`, `EditChildPage` | `ChildProfileSetupPage` (create/edit by parameter) |
| `ProfilePickerPage` | `ChildSelectorPage` |
| `HomePage` | `HomePage` |
| (shelf only) | `CategoryPage`, `FavoritesPage` (new dedicated pages) |
| `StoryDetailsPage` + `LockedStoryPage` | `StoryDetailsPage` with `KSLockedStoryOverlay` |
| `ReaderPage`, `StoryCompletePage` | `StoryReaderPage` (completion is an overlay state) |
| `ParentalGatePage` | `ParentGatePage` |
| `PaywallPage`, `SubscriptionPage` | `SubscriptionPage` (states: plans / subscribed) |
| `ParentAreaPage`, `ChildrenListPage`, `AccountPage`, `DeleteAccountPage` | `ParentDashboardPage` + `SettingsPage` (delete-account confirmation inside Settings) |
| `SplashPage`, `BlockedPage` | `SplashPage` (blocked states are page states) |

### 1.4 Navigation map
```
SplashPage ─┬─ not signed in ──▶ ParentWelcomePage ──▶ ParentSignInPage ──(sign-up)──▶ ChildProfileSetupPage(onboarding)
            ├─ signed in, 0 children ─────────────────────────────────────────────────▶ ChildProfileSetupPage(onboarding)
            ├─ signed in, ≥1 child ──▶ ChildSelectorPage ──▶ HomePage ─┬─▶ CategoryPage ──▶ StoryDetailsPage
            └─ blocked (maintenance / update) ──▶ SplashPage blocked state            ├─▶ FavoritesPage ──▶ StoryDetailsPage
                                                                                      ├─▶ StoryDetailsPage ──▶ StoryReaderPage
                                                                                      └─▶ [للأهل] ──▶ ParentGatePage ──▶ ParentDashboardPage ─┬─▶ ChildProfileSetupPage
StoryDetailsPage (locked) ──▶ KSLockedStoryOverlay ──[للأهل]──▶ ParentGatePage(returnTo: SubscriptionPage)              ├─▶ SubscriptionPage
                                                                                                                       └─▶ SettingsPage
```
Back behaviour: child pages pop normally; leaving any parent page for a child page clears `gateUnlockedUntil` (re-lock). Android back on `ChildSelectorPage` exits the app (no return to auth pages).

### 1.5 Route guards **[FF-ACT]**
| Guard | Pages | Implementation |
|---|---|---|
| Requires auth | Everything except `SplashPage`, `ParentWelcomePage`, `ParentSignInPage`, `ParentPasswordResetPage` | FlutterFlow "requires authentication" page setting; unauthenticated → `ParentWelcomePage` |
| Requires active child | `HomePage`, `CategoryPage`, `FavoritesPage`, `StoryDetailsPage`, `StoryReaderPage` | On load: if `activeChildId` empty → replace with `ChildSelectorPage` |
| Requires gate | `ParentDashboardPage`, `SubscriptionPage`, `SettingsPage`, `ChildProfileSetupPage` (unless `isOnboarding == true`) | On load: if `gateUnlockedUntil` is null or < now → replace with `ParentGatePage(returnTo: <this page>, returnParams)` |
| Never reachable from child UI | `SubscriptionPage` | Only navigations: `ParentGatePage` success with `returnTo == SubscriptionPage`, `ParentDashboardPage`, `SettingsPage` (all gated) — audit per AC-67 |

### 1.6 Global app state (FlutterFlow App State)
| Name | Type | Persisted | Notes |
|---|---|---|---|
| `activeChildId` | String | yes | |
| `activeChildNickname`, `activeChildAgeGroup`, `activeChildAvatarId`, `activeChildPreferredMode` | String | yes | Cached profile fields |
| `narrationAutoplay` | bool | yes | Default true |
| `autoAdvance` | bool | yes | Default from `appConfig.playback.autoAdvanceDefault` |
| `playbackSpeed` | double | yes | Default `appConfig.playback.defaultSpeed` |
| `defaultMode` | String (`read`/`listen`) | yes | |
| `gateUnlockedUntil` | DateTime? | **no** | Session only |
| `isPremiumUi` | bool | no | Display-only, from RevenueCat SDK |
| `arabicTtsAvailable` | bool? | no | null = not checked yet |
| `appConfigLoaded` | bool | no | |
| `featuredStoryIds`, `avatarIds`, `ageGroups` (JSON), `playbackSpeeds` | List | no | Cached from `appConfig/public` on splash |
| `onboardingInProgress` | bool | no | Set after sign-up until first child is created |

### 1.7 Shared patterns
- **Loading**: `KSLoadingState` for first load; skeleton variants for grids/reader; never a blank white screen (cream background at minimum).
- **Empty**: `KSEmptyState` with a child- or adult-variant illustration.
- **Error**: `KSErrorState` with retry; offline is a distinct message ("لا يوجد اتصال بالإنترنت"). Child pages never show error codes.
- **Permission-denied on premium pages** is rendered as the lock overlay, not as an error (see `StoryDetailsPage` / `StoryReaderPage`).
- **External links**: always `ExternalLinkConfirmDialog` ("سيتم فتح المتصفح") after the gate.
- **RTL check per page**: chevrons mirrored; media icons not; text `start`-aligned; page transitions slide from the left.
- **Semantics**: every icon-only control gets `semanticLabel`; page titles are announced on open.

### 1.8 Firebase query reference
Queries are referenced by the IDs in [FIREBASE_SCHEMA.md §13](FIREBASE_SCHEMA.md) (Q1–Q16). Every `stories` query includes `status == "published"`; every child-scoped query is under `users/{uid}/children/{activeChildId}/…`.

### 1.9 Custom Dart reference
`StoryNarrator`, `StoryMediaImage` (widgets); `checkArabicTtsVoice`, `openTtsSettings`, `prefetchPageMedia`, `purgePremiumCache`, `saveProgress`, `toggleFavorite`, `syncEntitlement`, `identifyRevenueCatUser`/`logOutRevenueCat` (if needed), `callDeleteAccount`, `initAppCheck` (if needed) (actions); `generateGateChallenge`, `numberToArabicWords`, `toArabicIndicDigits`, `formatSubscriptionDate`, `formatPriceAr`, `isAccessAllowedOffline`, `computeBestValue(monthlyAmount, annualAmount)` (functions). Signatures in [MONETIZATION_AND_TTS.md §15](MONETIZATION_AND_TTS.md).

---

## 2. Page specifications

### 2.1 SplashPage
| | |
|---|---|
| Purpose | Bootstrap: auth state, `appConfig`, entitlement refresh, routing. Also hosts the blocked states (maintenance / forced update). |
| Mode | Neutral (night-sky background, logo) |
| Route / params | `/` — none |

**Widget hierarchy [FF-UI]**
- `Scaffold` (background `storyBlueDark`)
  - `Stack`
    - `Image` `bg_night_sky_phone|tablet` (decorative, excluded from semantics)
    - `Column` centred
      - `Image` logo **[ASSET NEEDED]** 160 px
      - `Text` "Kids Stories" wordmark (`displayMedium`, `white`) — replaced by the Arabic wordmark when D-29 is decided
      - `KSLoadingState(spinner, messageAr: "جارٍ التحميل…")`
    - Conditional `Container` blocked state (cream card, `radius.lg`, max width 480)
      - `Text` title (`headlineMedium`): "التطبيق قيد الصيانة" **or** "يلزم تحديث التطبيق"
      - `Text` body (`bodyLarge`): `maintenanceMessageAr` or update explanation
      - `KSPrimaryButton(variant: adult, label: "تحديث التطبيق")` → gate → external store link (update state only)

**Page state**: `bootState: enum {loading, maintenance, forceUpdate, error}`.

**Firebase [FB]**: read `appConfig/public` (rules: signed-in read; for signed-out users the read is skipped and config defaults apply **[ASSUMPTION]** — or make `appConfig/public` readable without auth **[DECISION NEEDED — D-30]**; default: skip until signed in).

**Actions [FF-ACT]**
1. On load: read `appConfig/public` (if signed in) → cache into app state; compare `minSupportedBuild` with the running build number → `forceUpdate`; `maintenanceMode` → `maintenance`.
2. If signed in: `identifyRevenueCatUser()` if needed **[DART]**; update `isPremiumUi` from RevenueCat active entitlements (Phase 4); background `syncEntitlement(force: false)` **[DART]**; `checkArabicTtsVoice()` **[DART]** (non-blocking).
3. Route: not signed in → `ParentWelcomePage`; signed in and `children` count 0 → `ChildProfileSetupPage(isOnboarding: true)`; else → `ChildSelectorPage`. Use replace navigation.
4. Error reading config: proceed with cached/default values; show nothing to the child; log.

**States**: loading (spinner ≥ 400 ms to avoid flash), maintenance, force-update, config error (silent fallback).

**Responsive**: logo 160 / 220 on tablets; blocked card max width 480.

**Accessibility**: announce "Kids Stories، جارٍ التحميل"; blocked card focus first.

| Work split | |
|---|---|
| [FF-UI] | Background, logo, blocked card |
| [FF-ACT] | Config read, routing, entitlement refresh calls |
| [FB] | `appConfig/public` seed and rule; decision D-30 |
| [DART] | `syncEntitlement`, `checkArabicTtsVoice`, `identifyRevenueCatUser` |
| [CC] | Seed script for `appConfig`; unit test for build-number comparison helper; review exported routing for replace semantics |

---

### 2.2 ParentWelcomePage
| | |
|---|---|
| Purpose | First screen for signed-out parents: brand, value, sign-up / sign-in entry. |
| Mode | Child-style visuals allowed (magical background) but adult targets and copy — this screen is parent-only |
| Route / params | `/welcome` — none |

**Widget hierarchy [FF-UI]**
- `Scaffold` → `Stack`
  - Background night sky (decorative)
  - `SafeArea` → `Column`
    - `Spacer`
    - Hero illustration (castle + book) 220 px **[ASSET NEEDED]**
    - Cream card (`radius.lg`, padding 24, max width 480, bottom-aligned)
      - `Text` wordmark / app name (`displayLarge` 34)
      - `Text` one-line promise (`bodyLarge`): "قصص عربية آمنة وممتعة للأطفال من سنة إلى ست سنوات" **[ASSUMPTION copy]**
      - `KSPrimaryButton(adult, "إنشاء حساب")`
      - `KSSecondaryButton(adult, "تسجيل الدخول")`
      - `Text` `bodySmall` legal line with two links (privacy, terms) → confirm dialog → external (no gate needed: parent-only surface with no child session)

**Actions [FF-ACT]**: buttons → `ParentSignInPage(mode: signUp | signIn)`; legal links → `ExternalLinkConfirmDialog` → launch URL from `appConfig.legalUrls` (fallback constants if config not loaded **[ASSUMPTION]**).

**States**: none (static). **Responsive**: card max width 480 centred; illustration scales to 280 on tablets. **Accessibility**: heading semantics on the app name; buttons labelled.

| Work split | |
|---|---|
| [FF-UI] | Layout, illustration, card |
| [FF-ACT] | Navigation, external-link dialog |
| [FB] | `legalUrls` in `appConfig` |
| [DART] | — |
| [CC] | Copy review for RTL/bidi; link-safety review of exported URL launching |

---

### 2.3 ParentSignInPage
| | |
|---|---|
| Purpose | Email + password sign-in and sign-up (mode toggle), password-reset entry. |
| Mode | Parent (calm) |
| Route / params | `/auth?mode=signIn|signUp` |

**Widget hierarchy [FF-UI]**
- `Scaffold` (`parentBackground`) → `AppBar` (title "تسجيل الدخول" / "إنشاء حساب", back "رجوع")
  - `SingleChildScrollView` → centred `Column` (max width 480)
    - Segmented control (2 pills, adult 48): "تسجيل الدخول" | "إنشاء حساب"
    - `TextField` email (`bodyMedium` 16, keyboard email, `outlineStrong` border, `radius.sm`, height 56, label "البريد الإلكتروني", text direction LTR **inside** the field for the email value, label RTL)
    - `TextField` password (obscure, toggle visibility button 48, label "كلمة المرور")
    - Sign-up only: `Checkbox` (48 target) + `RichText` "أوافق على شروط الاستخدام وسياسة الخصوصية" with links (confirm dialog → external)
    - `KSPrimaryButton(adult, "تسجيل الدخول" | "إنشاء الحساب", isLoading)`
    - Sign-in only: `TextButton` "نسيت كلمة المرور؟" (48) → `ParentPasswordResetPage`
    - Inline error `Text` (`errorText`, `bodyMedium`)

**Page state**: `mode`, `email`, `password`, `acceptedTerms`, `isSubmitting`, `errorMessage`.

**Firebase [FB]**: Auth email/password; on sign-up FlutterFlow creates `users/{uid}` with auto-fields → immediately update with `locale`, `settings` (defaults from `appConfig.playback`), `consent` (versions + server time) — rules require these on create/update ([SECURITY_AND_PRIVACY.md §4.2](SECURITY_AND_PRIVACY.md)) **[VERIFY FlutterFlow's create-user-document fields can include custom fields in one write; otherwise allow a two-step create in rules]**.

**Actions [FF-ACT]**
1. Validate: email format, password ≥ 8, terms accepted (sign-up).
2. Sign-up → create Auth user → user doc → set `onboardingInProgress = true` → replace to `ChildProfileSetupPage(isOnboarding: true)`.
3. Sign-in → replace to `SplashPage` (re-runs bootstrap) **[ASSUMPTION: simplest routing]**.
4. Auth errors → Arabic messages mapped from error codes (wrong password, user not found, email in use, weak password, network).

**States**: submitting (button loading, fields disabled), error inline, offline message. **Responsive**: max width 480; tablet keeps single column. **Accessibility**: fields labelled; error announced; password toggle labelled "إظهار كلمة المرور".

| Work split | |
|---|---|
| [FF-UI] | Form, segmented control, error text |
| [FF-ACT] | Auth actions, validation, error mapping, user-doc update, routing |
| [FB] | `users` create/update rules incl. `consent`; password policy (owner) |
| [DART] | — (unless bidi helper needed for email display) |
| [CC] | Rules tests for user create shape; error-code→Arabic map review; onboarding-flag logic review |

---

### 2.4 ChildProfileSetupPage
| | |
|---|---|
| Purpose | Create or edit a child profile: nickname, age group, avatar. Nothing else is collected. **[CONFIRMED]** |
| Mode | Child-style magical background with a large cream form card; adult targets on the form, child-size primary CTA |
| Route / params | `/child-setup?isOnboarding=bool&childId=String?` (edit when `childId` present) |

**Widget hierarchy [FF-UI]**
- `Scaffold` → `Stack`
  - Background night sky (decorative)
  - `SafeArea` → `SingleChildScrollView` → centred `Column`
    - Top row: back `KSCircularIconButton(adult, chevron, mirrorInRtl, "رجوع")` (hidden when onboarding and no children exist)
    - Cream form card (`radius.lg`, padding 24, max width 560 / 640 tablet, `shadow.soft2`)
      - `Text` title (`displaySmall` 28): "من سيقرأ معنا؟" (create) / "تعديل الملف" (edit) **[ASSUMPTION copy]**
      - `Text` label "اسم الدلع" (`titleSmall`)
      - `TextField` nickname (`bodyLarge` 18, max 20 chars with counter, Arabic keyboard, `radius.sm`, height 56)
      - Helper `Text` "اسم الدلع فقط، لا داعي للاسم الكامل" (`bodySmall`, `textSecondary`)
      - `Text` label "الفئة العمرية"
      - `KSAgeGroupSelector(options: appState.ageGroups, selectedId)`
      - `Text` label "اختر صورة"
      - `KSAvatarSelector(avatarIds: appState.avatarIds, selectedId, columns: 4|6)`
      - `KSPrimaryButton(child, "ابدأ الحكاية")` (create) / `KSPrimaryButton(adult, "حفظ")` (edit) **[CONFIRMED CTA]**
      - Edit only: `KSSecondaryButton(danger, "حذف الملف")` → confirmation dialog

**Fields not present by design**: full name, date of birth, email, location, photo upload, gender. Nothing in the widget tree collects them; the rules reject any extra field (AC-06).

**Page state**: `nickname`, `ageGroup`, `avatarId`, `isSaving`, `validationError`.

**Firebase [FB]**: create `users/{uid}/children/{autoId}` with exactly `nickname`, `ageGroup`, `avatarId`, `createdAt`, `updatedAt` (server time); edit = update the same fields + `updatedAt`; delete = delete doc (Function cascades). Client-side max profiles check against `appConfig.maxChildrenPerParent` (AC-09). Also increment `users/{uid}.childrenCount` **[ASSUMPTION]**.

**Actions [FF-ACT]**
1. Guard: gate required unless `isOnboarding == true` (§1.5).
2. Validate: nickname 1–20 after trim; age group chosen; avatar chosen → otherwise inline Arabic error and disabled CTA.
3. Create → set `activeChild*` app state to the new profile → `onboardingInProgress = false` → replace to `HomePage` (onboarding) or pop to `ParentDashboardPage` (from dashboard).
4. Edit → save → if editing the active child, refresh `activeChild*` → pop.
5. Delete → confirm ("سيتم حذف المفضلة والتقدم") → delete → if active child, clear `activeChild*` and replace to `ChildSelectorPage`.

**States**: saving (CTA loading), validation errors inline, max-profiles reached (empty state card explaining the limit, adult tone), offline (save queues via Firestore persistence; show "سيتم الحفظ عند الاتصال" **[ASSUMPTION]**).

**Responsive**: phone — stacked; tablet — age-group options in a row, avatar grid 6 columns, card max width 640.

**Accessibility**: radio-group semantics for age group and avatars; nickname counter announced; CTA disabled state explained ("اختر صورة للمتابعة").

| Work split | |
|---|---|
| [FF-UI] | Card, fields, selectors, both modes |
| [FF-ACT] | Validation, create/update/delete, app-state updates, routing, gate guard |
| [FB] | `children` rules (shape, validators), `onChildProfileDeleted` Function, `appConfig.avatarIds`/`ageGroups` |
| [DART] | — (FlutterFlow standard actions suffice; auto-ID is fine here) |
| [CC] | Rules tests for child create/update/delete; verify exported create action writes no extra fields; a11y review of selectors |

---

### 2.5 ChildSelectorPage
| | |
|---|---|
| Purpose | "من يقرأ اليوم؟" — pick the active child; entry to the parent area. |
| Mode | Child |
| Route / params | `/who` — none |

**Widget hierarchy [FF-UI]**
- `Scaffold` → `Stack`
  - Background night sky
  - `SafeArea` → `Column`
    - Top bar `Row`: start spacer; trailing `KSCircularIconButton(child 64? → adult 48, icon parent, caption "للأهل")` **[ASSUMPTION: 56 to satisfy child minimum]**
    - `Text` "من يقرأ اليوم؟" (`displayLarge` 34, `white` on sky with a soft `scrim` pill behind, or on a cream card)
    - Cream card → `GridView` of profile tiles (2 columns phone / 3–4 tablet): avatar 96 circle + nickname (`titleLarge`), tile 140 × 160, `radius.card`, tap target whole tile
    - `KSSecondaryButton(child, "إضافة طفل")` (visible only if count < max) → gate → `ChildProfileSetupPage`

**Firebase [FB]**: Q1 `children` ordered by `createdAt`.

**Actions [FF-ACT]**: tile tap → set `activeChild*` (incl. `activeChildPreferredMode`) → replace to `HomePage`; "للأهل" → `ParentGatePage(returnTo: ParentDashboardPage)`; single profile + returning launch → optional auto-select **[ASSUMPTION J9]**.

**States**: loading skeleton tiles; empty (0 children — should not occur; fall back to `ChildProfileSetupPage(isOnboarding)`); error with retry.

**Responsive**: tiles 140 → 180 on tablets; grid columns 2 / 3 / 4.

**Accessibility**: tile label "{nickname}، اختر هذا الملف"; parent button "للأهل"; heading semantics.

| Work split | |
|---|---|
| [FF-UI] | Grid, tiles, header |
| [FF-ACT] | Query binding, app-state set, navigation |
| [FB] | Q1 index (automatic) |
| [DART] | — |
| [CC] | Verify exported tile semantics; snapshot test for tile sizing at 130 % text scale (if a Flutter toolchain exists in CI) |

---

### 2.6 HomePage
| | |
|---|---|
| Purpose | Child library home: shelves for continue reading, featured, free stories, categories, favourites shortcut, and all stories for the child's age group. |
| Mode | Child |
| Route / params | `/home` — none |

**Widget hierarchy [FF-UI]**
- `Scaffold` (`backgroundCream`) → `Stack`
  - Background (day/night variant, decorative, low density)
  - `SafeArea` → `CustomScrollView` / `ListView`
    - Header `Row`: avatar 56 + "أهلاً {nickname}" (`headlineMedium`) at start; trailing small `KSCircularIconButton(adult 48 → 56, parent icon, caption "للأهل")`
    - Shelf "تابع القراءة" (visible if ≥ 1 in-progress): `ShelfRow` of `KSStoryCard(shelf, progressFraction)`
    - Shelf "قصص مميزة": `KSStoryCard` for `featuredStoryIds` (published only)
    - Shelf "قصص مجانية": `KSStoryCard` (Q14)
    - Row "الفئات": horizontal `KSCategoryCard` list → `CategoryPage`
    - Big entry card "المفضلة" (cream, heart, `headlineMedium`) → `FavoritesPage`
    - Section "كل القصص" (`headlineMedium`) + grid `KSStoryCard(grid)` (Q3 by `activeChildAgeGroup`)

**Page state**: `isRefreshing`.

**Firebase [FB]**: Q3 (age group), Q14 (free), Q7 (progress in-progress, joined in memory), Q6 (featured by ID), Q13 (categories). Locked state per card = `accessLevel == "premium" && !isPremiumUi` (display only).

**Actions [FF-ACT]**: on load guard active child; card tap → `StoryDetailsPage(storyId)`; category tap → `CategoryPage(categoryId)`; pull-to-refresh optional **[ASSUMPTION]**; "للأهل" → gate.

**States**: loading skeleton shelves; empty catalog (no published stories for age group) → `KSEmptyState(child, "لا توجد قصص بعد")` + show all-ages grid; offline with cache → normal; offline without cache → `KSErrorState` child variant "لا يوجد اتصال بالإنترنت".

**Responsive**: shelf card 160 / 200; grid 2 / 3 / 4 columns; gutters 16 / 24.

**Accessibility**: shelves have heading semantics; cards labelled with lock/progress state (AC-44); the parent button is the last item in traversal order **[ASSUMPTION]**.

| Work split | |
|---|---|
| [FF-UI] | Shelves, grid, header, empty/error states |
| [FF-ACT] | Queries, in-memory joins for progress/favourites, navigation |
| [FB] | Indexes I-1, I-2, I-7, I-5; `featuredStoryIds` |
| [DART] | Optional `catalogCache` helper if in-memory joins prove awkward in FlutterFlow |
| [CC] | Verify each exported query includes `status == published`; index coverage test; a11y label review |

---

### 2.7 CategoryPage
| | |
|---|---|
| Purpose | Stories of one category, filtered to the active child's age group with an "all ages" toggle. |
| Mode | Child |
| Route / params | `/category?categoryId=String` (+ `nameAr`, `iconId` passed for instant header) |

**Widget hierarchy [FF-UI]**
- `Scaffold` (`backgroundCream`) → `SafeArea` → `Column`
  - Top bar: back `KSCircularIconButton(child 56, chevron mirrored, "رجوع")` at start; `Text` category name (`displaySmall`); category icon 40
  - Filter chips (pill 44 → 56 target): "لعمر {ageGroup label}" (selected) | "كل الأعمار" **[ASSUMPTION]**
  - `GridView` `KSStoryCard(grid)`

**Firebase [FB]**: Q4 (`categoryIds array-contains`) with client-side age-group filter when not "all ages" (only one `array-contains` per query — I-3).

**Actions [FF-ACT]**: card tap → `StoryDetailsPage`; chip toggles filter.

**States**: loading skeleton grid; empty → `KSEmptyState(child, "لا توجد قصص في هذه الفئة بعد")` with action "كل الأعمار" if filtered; error/offline as HomePage.

**Responsive**: grid 2 / 3 / 4. **Accessibility**: chips as toggle buttons; heading semantics.

| Work split | |
|---|---|
| [FF-UI] | Header, chips, grid |
| [FF-ACT] | Query + client filter, navigation |
| [FB] | Index I-3 |
| [DART] | — |
| [CC] | Test that the age filter never hides free stories unintentionally; a11y review |

---

### 2.8 StoryDetailsPage
| | |
|---|---|
| Purpose | Story overview, mode selection, single primary CTA, favourite; premium lock overlay when not entitled. |
| Mode | Child |
| Route / params | `/story?storyId=String` |

**Widget hierarchy [FF-UI]**
- `Scaffold` → `Stack`
  - Background night sky (decorative)
  - `SafeArea` → `SingleChildScrollView` → `Column`
    - Top bar: back (start), favourite `KSCircularIconButton(child 64, heart, isSelected)` (trailing)
    - Cover `StoryMediaImage(coverImageUrl)` 3:4, `radius.card`, max height 45 % (phone) / 360 px (tablet)
    - Cream card (`radius.lg`, padding 24, max width 640)
      - `Text` title (`displaySmall` 28 / `displayMedium` 30 tablet)
      - Meta chips row: age groups, "{n} دقائق", "{m} صفحات", audio availability chip (`audioSource == "tts"` → "بصوت الجهاز") **[ASSUMPTION]**
      - `Text` summary (`bodyLarge`)
      - `KSReadingModeSelector(mode: initial from progress.lastMode ?? activeChildPreferredMode ?? defaultMode, listenAvailable)`
      - `KSPrimaryButton(child, "ابدأ الحكاية" | "تابع من الصفحة {n}")` — the only primary action
      - Credits (`bodySmall`, `textSecondary`) — parent-oriented, small **[ASSUMPTION: shown in child mode too]**
  - Conditional `KSLockedStoryOverlay` when `accessLevel == "premium" && !isPremiumUi`

**Page state**: `selectedMode`, `progressDoc?`, `isFavorite`, `isLocked`.

**Firebase [FB]**: Q11 (`stories/{id}` + `progress/{id}`), Q10 favourite check; write `favorites/{storyId}` via `toggleFavorite` **[DART]** (deterministic ID; allowed even when locked).

**Actions [FF-ACT]**
1. On load: read story; if `status != published` → `KSErrorState` child "القصة غير متاحة الآن" with "رجوع".
2. Compute `isLocked`; if locked show overlay; overlay "للأهل" → `ParentGatePage(returnTo: SubscriptionPage, returnParams: {storyId})`; overlay "رجوع" → pop.
3. CTA → `StoryReaderPage(storyId, mode, startPage: progress.lastPageNumber ?? 1)`.
4. Favourite → `toggleFavorite` → optimistic UI.
5. `listenAvailable = audioSource != "tts" || arabicTtsAvailable == true`; if false and mode listen selected → show `TtsUnavailableNotice` inline (child line + gated parent hint).

**States**: loading skeleton; not found / unpublished; locked overlay; offline (cached story works; uncached → error state).

**Responsive**: tablet — cover left/right split? Keep stacked; cover max 360, card max width 640, centred.

**Accessibility**: title heading; favourite "إضافة إلى المفضلة"/"إزالة من المفضلة"; overlay modal semantics; CTA label includes page number when resuming.

| Work split | |
|---|---|
| [FF-UI] | Layout, chips, overlay placement |
| [FF-ACT] | Reads, lock computation, mode default, navigation with params |
| [FB] | `stories` published-only rule; favourites rule; entitlement mirror (Phase 4) |
| [DART] | `toggleFavorite`, `StoryMediaImage`, `checkArabicTtsVoice` result usage |
| [CC] | Rules tests (favourite on locked story allowed); verify exported page shows no prices; a11y review of overlay |

---

### 2.9 StoryReaderPage
| | |
|---|---|
| Purpose | Page-by-page reading in "اقرأ بنفسي" or "استمع إلى القصة" with the hybrid narrator. |
| Mode | Child |
| Route / params | `/reader?storyId=String&mode=read|listen&startPage=int` |

**Widget hierarchy [FF-UI]** (phone portrait)
- `Scaffold` (`backgroundCream`) → `Stack`
  - Soft background (very low detail; optional)
  - `SafeArea` → `Column`
    - **Top bar** `Row` (height 64): start `KSCircularIconButton(child 56, home, caption none, semantic "الرئيسية")`; centre `Text` story title (`displaySmall` 28 phone / `displayMedium` tablet, 1 line ellipsis); trailing `Row`: `KSReadingModeSelector(compact)`, `KSCircularIconButton(child 56, heart, "المفضلة")`
    - **Illustration** `StoryMediaImage(imagePath, imageUrl, imageAlt)` inside a cream frame `radius.card`, aspect 4:3 (`1-2` layout: 1:1 and larger), `shadow.soft2`
    - **Text** `KSStoryTextCard(displayTextAr, ageGroup, isHighlighted: mode == listen && playing)`
    - **Page indicator** `Text` "الصفحة {n} من {m}" (`bodyLarge`, Arabic-Indic digits) + dots
    - **Bottom control area** (cream floating bar, `shadow.soft3`, height 96 + safe area)
      - `KSPageNavigation` (next at far left, previous at far right, indicator centred) — outer row
      - `KSAudioControls(state, speed, speeds, mode)` — inner row (listen mode: full; read mode: single ▶ "استمع لهذه الصفحة" + speed chip hidden) **[ASSUMPTION]**
    - Hidden `StoryNarrator` custom widget (no visual; drives `KSAudioControls` via callbacks/page state)
  - Overlays: `KSLoadingState(skeletonReader)`; completion overlay (stars, "انتهت القصة!", `KSPrimaryButton(gold, "اقرأ مرة أخرى")`, `KSSecondaryButton(child, "قصة أخرى")`); `KSLockedStoryOverlay` if a permission-denied occurs mid-story

**RTL navigation [CONFIRMED]**: the **left** control advances to the next page; the **right** control returns to the previous page; both carry captions "التالي"/"السابق" and semantic labels "الصفحة التالية"/"الصفحة السابقة". Swipe: drag from left to right = next.

**Page state**: `pages: List<PagesRecord>`, `currentPage: int` (1-based), `mode`, `narratorState`, `speed`, `autoAdvanceArmed`, `isFavorite`, `ttsAvailable`, `errorKind`.

**Firebase [FB]**: Q12 pages ordered by `pageNumber` (rules: published + free-or-entitled); `saveProgress` writes `progress/{storyId}` on every page change and completion **[DART]**; favourite toggle.

**Actions [FF-ACT] + [DART]**
1. On load: query pages → if `permission-denied` → show `KSLockedStoryOverlay` (not an error); if empty → error state "القصة غير متاحة". Clamp `startPage` to `[1, pageCount]` (AC-65). If mode == listen → `checkArabicTtsVoice` if `audioSource != "prepared"`.
2. Page shown → `prefetchPageMedia(next page)`; if listen mode and `narrationAutoplay` → narrator `play()`.
3. `KSPageNavigation.onNext/onPrevious` and swipe → stop narration → `currentPage ±1` → `saveProgress(mode, page, pageCount, contentVersion, speed, isLastPage)`.
4. `StoryNarrator.onCompleted` → if `autoAdvance` effective (page override → setting) and not last page and `pageKind != question` → arm delay 1500 ms; any tap cancels; on fire → next.
5. `KSAudioControls`: play/pause/stop/repeat/speed → narrator; speed persists to `playbackSpeed` app state and to `settings.playbackSpeed` (parent setting) **[ASSUMPTION: session choice becomes the default]**.
6. `KSReadingModeSelector` → switch mode in place (keeps page); listen → autoplay current page.
7. Last page reached → `saveProgress(completed)` → completion overlay after narration ends (listen) or immediately (read).
8. Home → stop narration → replace to `HomePage`.
9. Narrator `onError(kind)` → `narratorState = audioUnavailable | ttsUnavailable`; controls show the state; page remains usable (AC-59, AC-61).

**States**: loading (skeleton reader), audio unavailable, TTS voice unavailable (child line + "للأهل" hint → gate → `openTtsSettings`), locked/permission denied, story missing, offline (cached pages OK; uncached → error), completion.

**Responsive**: phone — stacked as above; tablet portrait — illustration max height 50 %, text card max width 900, controls bar spans with larger gaps; tablet landscape (if D-08 enables) — `Row`: illustration (right, 55 %) | text card (left, 45 %); control bar full width.

**Accessibility**: traversal order home → title → mode → favourite → illustration (alt) → text → previous (right) → indicator → next (left) → audio controls (verify FlutterFlow's generated order); narration state announced; text scaling clamp 130 %.

| Work split | |
|---|---|
| [FF-UI] | Layout, control bars, overlays, tablet variants |
| [FF-ACT] | Page query, page state, navigation callbacks, saveProgress calls, completion routing |
| [FB] | Pages rule (free/entitled), progress rule, Storage rules for media |
| [DART] | `StoryNarrator`, `StoryMediaImage`, `saveProgress`, `prefetchPageMedia`, `checkArabicTtsVoice`, `openTtsSettings`, `toArabicIndicDigits` |
| [CC] | Unit tests for narrator source selection, chunking, auto-advance timing, clamp logic; rules tests for premium pages; a11y traversal review of the exported reader |

---

### 2.10 FavoritesPage
| | |
|---|---|
| Purpose | The active child's favourites. |
| Mode | Child |
| Route / params | `/favorites` — none |

**Widget hierarchy [FF-UI]**: `Scaffold` → `SafeArea` → `Column`: top bar (back at start, title "المفضلة" `displaySmall`, heart icon) → `GridView` `KSStoryCard(grid, showFavorite: true)`.

**Firebase [FB]**: Q9 favourites ordered by `createdAt desc` → join with catalog (in memory or per-ID reads); unpublished stories are hidden; locked premium favourites show the lock badge.

**Actions [FF-ACT]**: card tap → `StoryDetailsPage`; heart → `toggleFavorite` → optimistic removal (with a brief "تمت الإزالة" snackbar and no undo timer pressure **[ASSUMPTION]**).

**States**: loading; empty → `KSEmptyState(child, "لا توجد قصص مفضلة بعد", action "اكتشف القصص" → HomePage)`; error/offline.

**Responsive**: grid 2 / 3 / 4. **Accessibility**: heading; card labels; heart labelled.

| Work split | |
|---|---|
| [FF-UI] | Grid, empty state |
| [FF-ACT] | Query + join, navigation |
| [FB] | Favourites rule |
| [DART] | `toggleFavorite` |
| [CC] | Rules test; review of join logic in exported code |

---

### 2.11 ParentGatePage
| | |
|---|---|
| Purpose | Adult gate before any parent surface, the subscription screen, external links, and destructive actions. |
| Mode | Parent |
| Route / params | `/gate?returnTo=String&returnParams=JSON?` |

**Widget hierarchy [FF-UI]**: `Scaffold` (`parentBackground`) → `AppBar` (title "للأهل فقط", close "إغلاق" → pop) → centred `KSParentGate(challenge, attemptsLeft, cooldownSeconds)` inside a cream card (max width 480) + `Text` explanation (`bodyMedium`): "هذه المنطقة مخصصة للأهل. أجب عن السؤال للمتابعة."

**Page state**: `challenge`, `attemptsLeft = 3`, `cooldownUntil`, `answer`.

**Actions [FF-ACT] + [DART]**
1. On load: `challenge = generateGateChallenge()` **[DART]**.
2. Confirm: if `answer == challenge.answer` → `gateUnlockedUntil = now + 5 min` → replace to `returnTo` with `returnParams`; else `attemptsLeft--`, new challenge, error text; at 0 → `cooldownUntil = now + 30 s`, disable until then, then reset attempts.
3. Close → pop to the child screen (no unlock).
4. Never persist unlock state; never show the answer.

**States**: idle, wrong answer, cooldown (adult-facing countdown text). **Responsive**: card max width 480. **Accessibility**: prompt announced; numeric keyboard; error live region; the gate is standard adult sizing (48 targets, 56 field).

| Work split | |
|---|---|
| [FF-UI] | Page shell, card |
| [FF-ACT] | Attempts, cooldown timer, unlock state, return navigation |
| [FB] | — |
| [DART] | `generateGateChallenge`, `numberToArabicWords` |
| [CC] | Unit tests for challenge generation (two-digit operands, words not digits, answer range); verify no unlock persistence in exported code |

---

### 2.12 SubscriptionPage
| | |
|---|---|
| Purpose | Parent paywall and subscription status: monthly and annual only; store-returned prices; restore; manage; legal. Reachable only after the gate. **[CONFIRMED]** |
| Mode | Parent (calm) |
| Route / params | `/subscription?storyId=String?` (to return to a story after success) |

**Widget hierarchy [FF-UI]**
- `Scaffold` (`parentBackground`) → `AppBar` (title "المكتبة المميزة", back "رجوع" — always visible, standard position, no disguised close)
  - `SingleChildScrollView` → centred `Column` (max width 560)
    - Intro card (cream, `outline`): small illustration (lantern) 96, `Text` what premium includes (`bodyMedium`): number of premium stories (from catalog count or config), both modes, all age groups — factual, no urgency language
    - **State A — not subscribed**
      - `KSSubscriptionPlanCard(monthly, titleAr, priceString, periodAr)`
      - `KSSubscriptionPlanCard(annual, titleAr, priceString, periodAr, perMonthEquivalent, showBestValue)` — badge only when `computeBestValue(monthlyAmount, annualAmount) > 0` **[CONFIRMED: real discount only]**
      - Recurring-billing explanation `Text` (`bodyMedium`, `sub.recurringNotice`, **[LEGAL wording]**), including that the price shown is charged per period through the store account
      - `KSPrimaryButton(adult, "اشترك الآن", isEnabled: planSelected, isLoading: purchasing)`
      - `KSSecondaryButton(adult, "استعادة المشتريات")`
    - **State B — subscribed** (`isPremiumUi` or mirror active)
      - Status card: plan name, "يتجدد في {date}" / "ينتهي في {date}" (from mirror via `formatSubscriptionDate`), billing-issue banner when `billingIssueDetectedAt` set (`accentGold` background, `textDarkBlue`, link "تحديث طريقة الدفع" → confirm → store billing URL)
      - `KSSecondaryButton(adult, "إدارة الاشتراك")` → confirm dialog → `appConfig.subscription.manageUrls[platform]`
      - `KSSecondaryButton(adult, "استعادة المشتريات")`
    - Footer links `Row`: "سياسة الخصوصية" · "شروط الاستخدام" (48 targets) → confirm → external
    - Small `Text` (`bodySmall`, `textSecondary`): "الشراء يتم عبر حساب الأهل في المتجر" **[ASSUMPTION copy]**

**Page state**: `offering` (packages with store strings), `selectedPlan`, `uiState: enum {loading, plans, purchasing, success, cancelled, error, subscribed}`, `errorMessage`, `mirror` (from `entitlements/{uid}`).

**Firebase / RevenueCat [FB] + [FF-ACT]**: read `entitlements/{uid}` (Q15, may not exist); RevenueCat offerings via FlutterFlow integration; purchase/restore actions; `syncEntitlement(force: true)` **[DART]** after purchase/restore.

**Actions [FF-ACT]**
1. Guard: gate (§1.5). On load: fetch offerings → `plans`; if `isPremiumUi` → `subscribed`.
2. Select plan → highlight; "اشترك الآن" → RevenueCat purchase (platform sheet) → outcomes: success → `syncEntitlement(force)` → `success` state ("تم تفعيل الاشتراك", `KSPrimaryButton(adult, "العودة إلى القصة" | "العودة")`); user cancelled → `cancelled` (neutral text "لم تكتمل عملية الشراء", stay on plans); pending (Ask to Buy) → info text "بانتظار الموافقة"; error → `error` with retry; already subscribed → suggest restore.
3. Restore → RevenueCat restore → `syncEntitlement(force)` → success or "لم يتم العثور على مشتريات" (with the transfer warning before restore per D-21 **[DECISION NEEDED]**).
4. Return: success with `storyId` → replace to `StoryDetailsPage(storyId)` (gate re-locks on leaving parent surfaces).

**States**: loading (skeleton plan cards — never placeholder prices), plans, purchasing (buttons disabled, spinner), success, cancelled, error (retry), subscribed, billing issue, offline ("يلزم الاتصال بالإنترنت للاشتراك").

**Prohibited here**: hard-coded prices, countdown timers, fake or crossed-out prices, "limited time" language, three-month/lifetime/per-story products, pre-selected annual plan **[ASSUMPTION: no default selection]**, child-directed wording, hidden or delayed back button.

**Responsive**: max width 560 centred; tablet shows plan cards side by side (2 columns) **[ASSUMPTION]**.

**Accessibility**: plan cards as radio buttons with full labels; purchase progress announced; success announced; links labelled with "يفتح في المتصفح".

| Work split | |
|---|---|
| [FF-UI] | Layout, plan cards, states, footer |
| [FF-ACT] | Offerings binding, purchase/restore actions, state machine, return routing |
| [FB] | `entitlements` read rule; `syncEntitlement` Function; webhook |
| [DART] | `syncEntitlement`, `computeBestValue`, `formatPriceAr`, `formatSubscriptionDate` |
| [CC] | Unit tests for `computeBestValue` (badge only on real discount) and formatting; review exported page for hard-coded prices and reachability (AC-66/67); Functions tests |

---

### 2.13 ParentDashboardPage
| | |
|---|---|
| Purpose | Parent overview: children, subscription status, settings, account. Calm style. |
| Mode | Parent |
| Route / params | `/parent` — none (gated) |

**Widget hierarchy [FF-UI]**
- `Scaffold` (`parentBackground`) → `AppBar` (title "لوحة الأهل", action "العودة إلى الأطفال" text button 48 → replace to `ChildSelectorPage` and clear `gateUnlockedUntil`)
  - `SingleChildScrollView` → `Column` (max width 640)
    - Section "الأطفال" (`titleSmall`): list of child rows (avatar 48, nickname `titleSmall`, age label `bodySmall`, edit chevron mirrored) → `ChildProfileSetupPage(childId)`; `KSSecondaryButton(adult, "إضافة طفل")` (hidden at max)
    - Section "الاشتراك": status card — "غير مشترك" + `KSPrimaryButton(adult, "المكتبة المميزة")` → `SubscriptionPage`; or active plan + renewal/expiry + `KSSecondaryButton(adult, "إدارة الاشتراك")` (→ SubscriptionPage state B). Plain language only.
    - Section "الإعدادات": list tile → `SettingsPage`
    - Section "الحساب": tiles "تسجيل الخروج", "حذف الحساب" (`errorText`) → `SettingsPage` account section (or inline dialogs **[ASSUMPTION: inline]**)
    - Footer links: privacy, terms, support (confirm → external)

**Firebase [FB]**: Q1 children; Q15 entitlement mirror; `users/{uid}` settings (display only here).

**Actions [FF-ACT]**: navigation as above; sign-out → confirm → `logOutRevenueCat` (if needed) → `purgePremiumCache` → Auth sign-out → clear app state → replace to `ParentWelcomePage`.

**States**: loading; children empty (should not happen; show add button); offline (cached data shown; subscription status from cache with "آخر تحديث" note **[ASSUMPTION]**).

**Responsive**: max width 640; tablet two-column (children | subscription) **[ASSUMPTION]**. **Accessibility**: section headings; list tiles labelled; destructive tile hint.

| Work split | |
|---|---|
| [FF-UI] | Sections, tiles, calm styling |
| [FF-ACT] | Queries, sign-out flow, navigation, gate re-lock on leave |
| [FB] | Rules already covered |
| [DART] | `purgePremiumCache`, `logOutRevenueCat` (if needed), `formatSubscriptionDate` |
| [CC] | Review sign-out sequence in exported code; verify no purchasing language in strings |

---

### 2.14 SettingsPage
| | |
|---|---|
| Purpose | Playback preferences, TTS status, account actions, legal. |
| Mode | Parent |
| Route / params | `/settings` — none (gated) |

**Widget hierarchy [FF-UI]**
- `Scaffold` (`parentBackground`) → `AppBar` (title "الإعدادات", back)
  - `ListView` (max width 640)
    - Section "القراءة والاستماع"
      - Switch tile "تشغيل السرد تلقائيًا" (`narrationAutoplay`)
      - Switch tile "الانتقال التلقائي للصفحة التالية" (`autoAdvance`)
      - Tile "السرعة الافتراضية" + segmented pills from `appConfig.playback.speeds` (`playbackSpeed`)
      - Tile "الوضع الافتراضي" + `KSReadingModeSelector` (adult sizing) (`defaultMode`)
      - Switch tile "المؤثرات الصوتية" (`soundEffects`) **[ASSUMPTION]**
    - Section "الصوت العربي"
      - Status row: "صوت عربي متاح على هذا الجهاز" / "لا يوجد صوت عربي" (from `arabicTtsAvailable`) + `KSSecondaryButton(adult, "إعادة الفحص")` → `checkArabicTtsVoice`
      - `KSSecondaryButton(adult, "فتح إعدادات الصوت")` → confirm → `openTtsSettings` **[DART]**
    - Section "الحساب"
      - Tile "البريد الإلكتروني: {email}" (bidi isolate)
      - Tile "تسجيل الخروج" → confirm → sign-out flow (as dashboard)
      - Tile "حذف الحساب" (`errorText`) → confirmation sheet: explanation incl. "يجب إلغاء الاشتراك من المتجر بشكل منفصل" → re-authenticate (password field) → `callDeleteAccount` **[DART]** → sign out → `ParentWelcomePage`
    - Section "معلومات": privacy, terms, support links (confirm → external); app version (`bodySmall`)

**Firebase [FB]**: update `users/{uid}.settings` (rules: allowed fields only); `deleteAccount` Function.

**Actions [FF-ACT]**: each control writes app state immediately and `users/{uid}.settings` (debounced **[ASSUMPTION]**); delete flow with re-auth; errors mapped to Arabic.

**States**: saving indicators per tile (subtle), delete in progress (blocking sheet with spinner "جارٍ حذف الحساب…"), delete error with retry (safe to retry by design), offline (settings queue; delete requires network).

**Responsive**: max width 640. **Accessibility**: switches labelled with state; destructive tile hint; re-auth field labelled.

| Work split | |
|---|---|
| [FF-UI] | Lists, switches, sheets |
| [FF-ACT] | Settings writes, re-auth, delete flow, sign-out |
| [FB] | `users` update rule; `deleteAccount` Function + tests |
| [DART] | `checkArabicTtsVoice`, `openTtsSettings`, `callDeleteAccount`, `purgePremiumCache` |
| [CC] | Functions tests; rules test for settings-only updates; review that delete requires recent auth |

---

## 3. Additional screens / sub-flows required (not in the requested list)

| Screen or flow | Why | Spec summary |
|---|---|---|
| `ParentPasswordResetPage` | AC-03 | Parent mode; email field; `KSPrimaryButton(adult, "إرسال رابط الاستعادة")`; success text; back |
| Story-complete overlay | AC-21 | Part of `StoryReaderPage` (§2.9); gold celebration once; two actions |
| `ExternalLinkConfirmDialog` (component) | AC-31 | Adult dialog: "سيتم فتح المتصفح" · "متابعة" / "إلغاء" |
| `TtsUnavailableNotice` (component) | AC-59 | Child line + adult hint + gated "فتح الإعدادات" |
| `BillingIssueBanner` (component) | AC-52 | Parent-only banner on `SubscriptionPage` / dashboard |
| Delete-account confirmation sheet | AC-32 | Inside `SettingsPage` |
| Blocked states | AC-16/17 | Inside `SplashPage` |

---

## 4. Claude Code post-export checklist (safe tasks only)
1. Confirm every `stories` query in the export contains `status == "published"` and that no page reads `pages` for a locked story before the overlay decision.
2. Grep the export for literal hex colours, Latin-only font names, and `TextAlign.right/left` (should be `start/end`).
3. Verify no price strings or product IDs are hard-coded; `SubscriptionPage` is reachable only via gated routes.
4. Verify `gateUnlockedUntil` is never written to persisted state.
5. Run rules tests for every page's reads/writes; add fixtures for entitled/unentitled/expired.
6. Unit-test custom functions (`generateGateChallenge`, `numberToArabicWords`, `toArabicIndicDigits`, `computeBestValue`, formatting helpers) and narrator logic that is pure (source selection, chunking, auto-advance timing).
7. Produce an a11y report per page from the exported semantics (labels present, traversal order in the reader).
8. Update this spec with any deviations found in the export; never edit generated widget files.

---

## 5. Open items introduced by this spec

| ID | Item | Default |
|---|---|---|
| D-29 | Arabic app name / wordmark | **[ASSET NEEDED]**; Latin wordmark meanwhile |
| D-30 | Is `appConfig/public` readable before sign-in (for maintenance/update checks on the welcome flow)? | No — checks run after sign-in |
| D-08 | Tablet landscape | Off until decided; reader landscape layout is specified if enabled |
| — | Sign-in routes back through `SplashPage` vs. direct routing | Through Splash (simplest) |
| — | Speed chosen in the reader becomes the parent default | Yes (assumption) |
| — | Annual plan pre-selected on the paywall | No (avoid nudging) |
| — | Age filter default on `CategoryPage` | Active child's group with "كل الأعمار" toggle |
