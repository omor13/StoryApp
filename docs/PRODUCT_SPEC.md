# Product Specification — Arabic Children's Storytelling App (MVP)

| | |
|---|---|
| Status | Draft v0.2 — planning phase, nothing implemented. v0.2 incorporates the confirmed decisions of 2026-09-21 (ages 1–6, two reading modes, hybrid audio, freemium subscription). |
| Last updated | 2026-09-21 |
| Related docs | [ARCHITECTURE.md](ARCHITECTURE.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels used in this document**

- **[CONFIRMED]** — decided by the product owner on 2026-09-21.
- **[ASSUMPTION]** — a working assumption that has not been confirmed by the product owner.
- **[DECISION NEEDED]** — an open question that must be resolved before the affected item is built.
- **[VERIFY]** — a claim about a third-party tool or store policy that must be checked before relying on it.

---

## 1. Product goals

1. **A safe, calm, ad-free reading and listening space.** Give Arabic-speaking children aged 1–6 illustrated stories in simple Modern Standard Arabic (MSA), with nothing in the child area that leads outside the app.
2. **Two ways to enjoy every story.** Every published story works in **"اقرأ بنفسي"** (read myself — independent or parent-assisted) and **"استمع إلى القصة"** (listen — prepared audio, or device text-to-speech as a fallback). **[CONFIRMED]**
3. **Parent is the account holder and gatekeeper.** Only parents authenticate. Children use lightweight profiles (nickname, age group, avatar). Every purchase, price, restore action, setting, account action, and external link sits behind a parental gate.
4. **Freemium that respects families.** Several complete stories are permanently free and never artificially shortened; the rest of the library requires a monthly or annual subscription bought by the parent through Apple In-App Purchase or Google Play Billing. **[CONFIRMED]**
5. **Content is data, not code.** Stories, pages, images, and audio are managed remotely (Firestore + Storage) so new stories and corrections ship without an app-store release.
6. **Privacy by design.** Collect the minimum data needed to run the product; store no child birth date, email, location, photo, or free-text identity data. Only an age-group identifier is stored for a child. **[CONFIRMED]**
7. **Store-compliant from day one.** Design to satisfy Apple's Kids Category guidelines and Google Play's Families policy (parental gate, no ads, no third-party tracking in the child area, subscriptions only via the platform billing systems). Legal review is still required — see [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md).
8. **A foundation that scales.** The schema, security rules, entitlement model, and branching model should support more content, offline reading, and richer reading features later without a rewrite.

### Non-goals (for the whole product direction, not only MVP)

- Being a social platform, a game, or a general-purpose e-book reader.
- Serving dialectal Arabic content in the first release (MSA only).
- Replacing parent involvement — the app is meant to be used *with* a parent, and for the youngest group it is explicitly parent-assisted.
- Selling digital content through any channel other than the platform in-app purchase systems (no Stripe, no external checkout). **[CONFIRMED]**

---

## 2. Target users

### 2.1 Primary: children aged 1–6 **[CONFIRMED]**

| Age group | ID used in data | Experience the app must provide | Design consequences |
|---|---|---|---|
| 1–2 years | `1-2` | **Parent-assisted listening.** Very short text, very large illustrations, gentle narration. The parent holds the device and turns pages. | Image-dominant page layout; one or two short sentences per page; large, obvious play control; no expectation that the child taps anything. |
| 3–4 years | `3-4` | **Listening, interaction, repetition, and simple questions.** Short pages, repeated phrases, occasional simple question pages ("ماذا ترى في الصورة؟"). | Replay and repeat are one tap; question pages are ordinary pages with a question in the text (**[UNRESOLVED]** whether a dedicated interaction field is needed later — see [FIREBASE_SCHEMA.md §8](FIREBASE_SCHEMA.md)). |
| 5–6 years | `5-6` | **Listening and early independent reading.** Longer pages, clear large text with diacritics, "read myself" mode encouraged. | Text is prominent; narration can be turned off; playback speed selection helps following along. |

Only the age-group identifier is stored for a child — never a date of birth. **[CONFIRMED]**

Common design consequences: no reading required to navigate the child area; large targets; no timers or pressure; every action is reversible; no destructive actions or purchases reachable without the gate.

### 2.2 Secondary: parents and guardians

- Create the account, add child profiles, pick stories with the child, control settings, and buy or restore the subscription.
- May be non-technical. Interface is Arabic-only in MVP; a future English UI must not be blocked by design.
- Expect to see what the child read, to manage the subscription clearly (status, renewal, cancellation via the store), and to delete data easily.

### 2.3 Tertiary: content administrator (internal)

- Publishes and updates stories using tooling outside the mobile app (scripts / Firebase console; see [ARCHITECTURE.md §9](ARCHITECTURE.md)).
- Has an admin custom claim on a Firebase Auth account (see [SECURITY_AND_PRIVACY.md §5](SECURITY_AND_PRIVACY.md)).
- No admin UI ships inside the mobile app in MVP.

---

## 3. MVP features

| ID | Feature | Notes |
|---|---|---|
| F-01 | **Parent authentication** | Email + password sign-up/sign-in, password reset, email-verification prompt. **[DECISION NEEDED — D-01]** Google / Apple sign-in. (If any third-party sign-in is offered on iOS, Sign in with Apple must also be offered.) |
| F-02 | **Child profiles** | Nickname (1–20 chars), age group (`1-2`, `3-4`, `5-6`), avatar chosen from a predefined bundled set. **[ASSUMPTION]** max 5 profiles per parent. Create / edit / delete from the parent area only. |
| F-03 | **Profile picker** | Child-friendly "من يقرأ اليوم؟" screen with avatars and nicknames. Selecting a profile sets the *active child* (local app state, not authentication). |
| F-04 | **Story library** | Browse all published stories — free and premium. Shelves: featured, continue reading, favorites, free stories, by category. The age-group filter defaults to the active child's group. Premium stories are always visible with a clear lock badge. **[CONFIRMED]** |
| F-05 | **Story details** | Cover, title, short summary, duration, page count, age groups, favorite toggle, mode buttons "اقرأ بنفسي" / "استمع إلى القصة", "ابدأ" / "تابع". Locked stories show the child-facing lock screen instead (F-16). |
| F-06 | **Reader — "اقرأ بنفسي"** | One page at a time: illustration + display text. Manual page turning (RTL: next page enters from the left). Optional narration on demand per page. |
| F-07 | **Listen — "استمع إلى القصة"** | Same pages with narration driven by the hybrid audio engine (F-08): play, pause, resume, stop, playback-speed selection, optional automatic page advance after playback. **[CONFIRMED]** |
| F-08 | **Hybrid audio engine** | Prefer a prepared, quality-controlled Arabic audio file for the page; fall back to on-device Arabic TTS using `ttsTextAr`; verify an Arabic voice exists before speaking; never switch silently to a non-Arabic voice; graceful behaviour when neither is available. Details in [MONETIZATION_AND_TTS.md §10–13](MONETIZATION_AND_TTS.md). **[CONFIRMED]** |
| F-09 | **Favorites** | Per child profile. Toggle from details and reader; "المفضلة" shelf in the library. |
| F-10 | **Reading & listening progress** | Per child per story: last page, last mode, completed flag, per-mode completion counts. "تابع القراءة" shelf; completed badge on covers; resume in the last mode. **[CONFIRMED]** |
| F-11 | **Parental gate** | Required before the parent area, paywall, prices, purchases, restore, subscription management, account actions, and any external link. Arithmetic challenge written in Arabic words (see [SECURITY_AND_PRIVACY.md §7](SECURITY_AND_PRIVACY.md)). |
| F-12 | **Parent area** | Manage children, settings (narration autoplay, auto-advance, default playback speed, default mode), subscription status, account (sign out, delete account), legal links (open externally, behind the gate). |
| F-13 | **Remote content management** | Catalog and pages read from Firestore; media from Storage. Publish / unpublish / correct a story, or change its access level, without a release. |
| F-14 | **Resilience & remote configuration** | Firestore offline persistence; cached media; Arabic error and empty states; a single config document controls minimum supported build, maintenance mode, featured stories, playback options. |
| F-15 | **Subscription (freemium)** | Entitlement `premium_library` unlocks all premium stories. Monthly and annual auto-renewing subscriptions via Apple IAP / Google Play Billing through RevenueCat (FlutterFlow integration). Purchases are made by the parent only. **[CONFIRMED]** |
| F-16 | **Lock screen & paywall** | Tapping a locked story shows a child-facing lock screen (no prices) whose only forward action is "للأهل" → parental gate → parent paywall with monthly/annual options, prices, disclosures, restore, and legal links. **[CONFIRMED]** |
| F-17 | **Restore purchases** | Manual "استعادة المشتريات" action on the paywall and in the subscription settings, behind the gate. **[CONFIRMED]** |
| F-18 | **Subscription status** | Parent area shows: active/inactive, plan, renewal or expiry date, billing-issue warning during a grace period, and a gated link to the store's subscription management. |

---

## 4. Explicitly excluded features (MVP)

**Excluded by policy (child safety / privacy / store compliance)**
- Advertising of any kind, including "house ads" and third-party ad SDKs.
- Social features: sharing, comments, likes, leaderboards, friends, chat, messaging.
- User-generated content: voice recording, custom stories, drawings, photo uploads.
- External links, web views, app-store links, prices, or purchase prompts reachable inside the child area without the gate.
- Child accounts, child sign-in, or any child email / phone number.
- Collection of a child's full name, date of birth, email, phone, photo, precise or coarse location, contacts, or advertising identifiers. **[CONFIRMED]**
- Purchasing digital content through Stripe, a website, or any checkout outside Apple IAP / Google Play Billing. **[CONFIRMED]**
- Push notifications (no engagement nudges aimed at children).
- Gamification that creates pressure: streaks, timers, rewards for time spent.
- Any "preview" or "first N pages" mechanic for free stories — free stories are complete stories. **[CONFIRMED]**

**Excluded to keep MVP small (candidates for later phases)**
- Free trials or introductory offers. **[DECISION NEEDED — D-19]**; default: none in MVP (the free stories are the trial).
- Family sharing / multiple parent accounts on one subscription (store-level family sharing may still work **[VERIFY]**).
- Lifetime / one-time purchase products.
- Word-level highlighting synchronised with audio (needs per-word timestamps in content).
- Full offline download manager ("download this story"). MVP relies on Firestore persistence and media caching only.
- Quizzes, comprehension questions with scoring, games.
- Multiple UI languages (English UI). Strings must still be kept in FlutterFlow's localisation system so this is possible later.
- Dialect content.
- An admin panel inside the mobile app (content is managed by scripts / console).
- Product analytics. **[DECISION NEEDED — D-04]** — crash reporting only vs. crash reporting + Firebase Analytics with advertising-ID collection disabled. Default assumption: crash reporting only.
- Tablet-optimised layouts. **[ASSUMPTION]** MVP is phone-first, portrait-only, and merely stretches acceptably on tablets.

---

## 5. User journeys

Each journey lists the screens in order. Screen names are proposals for the FlutterFlow page names.

### J1 — First launch and parent onboarding
1. `SplashPage` → checks auth state and `appConfig/public` (min version, maintenance).
2. `WelcomePage` (Arabic, RTL) → "إنشاء حساب" / "تسجيل الدخول".
3. `SignUpPage` → email, password, accept terms & privacy (the link opens the external browser; this screen is a parent-only surface, not part of the child area).
4. `CreateChildPage` → nickname, age group (three chips), avatar grid. Saves the first child profile.
5. `ProfilePickerPage` → the new profile is shown; tapping it opens `HomePage`.

Success: a parent can reach the child home in under two minutes with no help.

### J2 — Child picks a profile and listens to a free story (happy path)
1. `ProfilePickerPage` → tap avatar.
2. `HomePage` → shelves: مميزة, تابع القراءة, المفضلة, قصص مجانية, categories.
3. Tap a free cover → `StoryDetailsPage` → "استمع إلى القصة".
4. `ReaderPage` (listen mode) → narration plays (prepared audio if present, else Arabic TTS); child taps ▶/⏸ or swipes to the next page (left-to-right in RTL); if auto-advance is on, the next page opens after narration ends.
5. Last page → "انتهت القصة" state → "اقرأ مرة أخرى", "قصة أخرى".

Success: progress is saved after every page with `lastMode = "listen"`; the story appears as completed on `HomePage`.

### J3 — Read myself (5–6 group) and resume later
1. `StoryDetailsPage` → "اقرأ بنفسي" → `ReaderPage` (read mode): large text with diacritics; narration only on demand.
2. Child exits on page 5 of 12.
3. Later, `HomePage` → "تابع القراءة" shows the cover with a progress ring → `StoryDetailsPage` shows "تابع من الصفحة ٥" → opens page 5 in read mode.

### J4 — Favorite a story and find it later
1. From `StoryDetailsPage` or `ReaderPage`, tap ♥.
2. `HomePage` → "المفضلة" shelf shows it; tapping ♥ again removes it.
3. Favorites are per child; a sibling's favorites are not shown.

### J5 — Parent adds a second child
1. `ProfilePickerPage` → "الأهل" button → `ParentalGatePage`.
2. Correct answer → `ParentAreaPage` → "الأطفال" → "إضافة طفل".
3. `CreateChildPage` → save → back to `ProfilePickerPage` with two profiles.

### J6 — Parent changes settings / opens the privacy policy
1. Any child screen → "الأهل" (small, top corner) → `ParentalGatePage`.
2. `ParentAreaPage` → `SettingsPage` → toggle narration autoplay / auto-advance, choose default speed.
3. `ParentAreaPage` → "سياسة الخصوصية" → confirmation "سيتم فتح المتصفح" → external browser.
4. Leaving the parent area (back to child screens) re-locks the gate.

### J7 — Parent deletes a child profile
1. `ParentAreaPage` → "الأطفال" → select child → "حذف الملف".
2. Confirmation dialog explains that favorites and progress are removed.
3. Profile disappears; if it was the active child, the app returns to `ProfilePickerPage`.

### J8 — Parent deletes the account
1. `ParentAreaPage` → "الحساب" → "حذف الحساب".
2. Re-authentication (password) → final confirmation, including a note that an active subscription must be cancelled in the store separately.
3. Server-side deletion runs (see [SECURITY_AND_PRIVACY.md §9](SECURITY_AND_PRIVACY.md)); the app signs out and returns to `WelcomePage`.

### J9 — Returning launch
1. `SplashPage` → parent session is still valid → entitlement is refreshed in the background → `ProfilePickerPage` (or directly `HomePage` if a single profile exists **[ASSUMPTION]**).

### J10 — Content update arrives (no app update)
1. Admin publishes a new story, corrects a page, or changes a story's access level (see [ARCHITECTURE.md §9](ARCHITECTURE.md)).
2. On the next `HomePage` load the change is visible; corrected media loads because asset paths are versioned.

### J11 — Error and edge states
- No network on first launch: Arabic message + retry; the cached catalog is shown if available.
- Story missing / unpublished while open: the reader closes gracefully with a friendly message.
- App build below `minSupportedBuild`: blocking Arabic screen; the "update" button is behind the parental gate because it opens the store.
- Maintenance mode: blocking Arabic screen.

### J12 — Free to paid (child taps a locked story) **[CONFIRMED]**
1. `HomePage` → child taps a cover with a lock badge.
2. `LockedStoryPage` (child-facing): friendly illustration, "هذه القصة من المكتبة المميزة — اطلب من أحد الوالدين", single button "للأهل". **No prices, no store dialogs.**
3. "للأهل" → `ParentalGatePage` → correct answer → `PaywallPage` (parent-facing): what premium includes, monthly and annual options with store-localised prices, auto-renewal disclosure, "استعادة المشتريات", terms & privacy links.
4. Parent picks annual → platform purchase sheet → success.
5. App refreshes entitlement (RevenueCat SDK) and asks the server to sync the mirror; within seconds the locked story opens directly in `StoryDetailsPage` without restarting.
6. Parent leaves the parent flow → gate re-locks; the child continues with the now-unlocked library.

### J13 — Restore purchases on a reinstalled or new device **[CONFIRMED]**
1. Parent signs in on a new device → RevenueCat is identified with the Firebase UID → entitlement is already active → premium works with no action.
2. If a store subscription exists but is not linked (edge case), parent → gate → `PaywallPage` or `SubscriptionPage` → "استعادة المشتريات" → RevenueCat restore → sync → premium works. If nothing is found, an Arabic explanation is shown.

### J14 — Subscription ends
1. Parent cancels auto-renewal in the store → the app keeps premium until the paid period ends; `SubscriptionPage` shows "ينتهي الاشتراك في <date>".
2. On expiry, premium stories show the lock badge again; a premium story open at that moment ends gracefully at the next page load with the lock screen; progress is kept.
3. A failed renewal with a grace period keeps access and shows a billing-issue banner in the parent area with a gated link to store billing.

### J15 — No Arabic TTS voice on the device
1. Child taps "استمع إلى القصة" on a page that has no prepared audio.
2. The engine checks for an Arabic voice; none is found.
3. The reader shows a calm Arabic message (no other-language speech, no crash) and offers "اقرأ بنفسي"; a parent-oriented hint "للأهل: يمكن تثبيت صوت عربي من إعدادات الجهاز" leads to the gate before opening device settings.

### J16 — Prepared audio fails to load
1. Listen mode on a page with prepared audio; the download fails or the file is unplayable.
2. One retry; then fallback to Arabic TTS if a voice exists; otherwise the J15 message. Text and illustration remain usable throughout.

---

## 6. Accessibility and Arabic RTL requirements

| ID | Requirement |
|---|---|
| R-01 | App locale is fixed to `ar`. The entire widget tree runs under RTL directionality regardless of device language. |
| R-02 | Layout mirrors correctly: navigation, back chevrons, progress bars, sliders, list leading/trailing, page-swipe direction (next page is to the left; the user swipes from left to right to advance). Play/pause icons are **not** mirrored (media icons are direction-neutral by convention **[VERIFY against Material guidance]**); next/previous icons are. |
| R-03 | Typography: an Arabic font with full coverage for tashkeel (diacritics) and ligatures. Candidate families to evaluate (none selected yet): Noto Naskh Arabic, Cairo, Tajawal, Amiri. **[DECISION NEEDED — D-06]** final font(s). Story text must be evaluated *with* diacritics because content for this age uses them. |
| R-04 | Reader text: large (**[ASSUMPTION]** 24–28 sp on phones; larger in image-dominant layout for `1-2`), line height ≥ 1.8 to leave room for diacritics, short lines, start-aligned, no justified text. |
| R-05 | Digits: consistent choice across the app. **[DECISION NEEDED — D-05]** Arabic-Indic digits (٠١٢٣) — proposed default for the child area — vs. Western digits (0123). Prices on the paywall use the store-localised format as returned by the store. |
| R-06 | Bidi correctness: mixed strings (e.g., "الصفحة ٣ من ١٢", prices with currency symbols, dates, email addresses, error codes) render correctly using isolate marks where needed. |
| R-07 | Tap targets: ≥ 48 × 48 dp everywhere; primary child controls ≥ 64 dp with ≥ 16 dp spacing. No gesture-only or long-press-only actions in the child area. |
| R-08 | No time limits, no countdowns, no auto-dismissing dialogs in the child area. Auto-advance after narration is the only timed transition and is always cancellable by a tap. |
| R-09 | Audio-first navigation: every child-area action is understandable from its icon alone. Text labels are supplementary. |
| R-10 | Screen readers: every interactive element has an Arabic semantics label; images have Arabic descriptions (`imageAlt` from content). Test with TalkBack and VoiceOver. |
| R-11 | Colour and contrast: text contrast ≥ 4.5:1; state (selected, completed, favourite, locked) is never shown by colour alone — the lock is an icon plus label. |
| R-12 | Motion: respect the OS reduce-motion setting; no flashing content. |
| R-13 | Text scaling: the parent area respects system text scaling; the child area must not break at 130 %. |
| R-14 | Keyboard: Arabic keyboard for nickname entry; numeric keyboard for the parental gate; nickname allows Arabic letters, spaces, and length 1–20. |
| R-15 | Audio: prepared narration is AAC, loudness-normalised across stories; playback pauses on interruption (call) and resumes manually; TTS uses only Arabic voices; speed selection applies to both sources. |
| R-16 | 1–2 group: image-dominant layout, at most two short sentences per page, controls large enough for a parent holding a toddler. |
| R-17 | Every screen passes the RTL/accessibility checklist in §7 before it is merged to `develop`. |

---

## 7. Acceptance criteria

Criteria are written so they can be checked manually by QA or automated later. "Parent" means a signed-in Firebase Auth user; "child" means the active child profile; "entitled" means `premium_library` is active in RevenueCat **and** mirrored server-side.

### Authentication (F-01)
- AC-01 A new parent can sign up with email + password and lands on `CreateChildPage`.
- AC-02 A parent cannot proceed past sign-up without accepting the terms and privacy policy.
- AC-03 Password reset sends an email and shows an Arabic confirmation.
- AC-04 Killing and relaunching the app keeps the parent signed in.
- AC-05 No screen in the app allows creating an account for a child.

### Child profiles (F-02, F-03)
- AC-06 A child profile stores exactly: nickname, age group, avatar ID, optional preferred mode, timestamps. Firestore rules reject any other field.
- AC-07 Nickname validation: 1–20 characters after trimming; empty or 21+ characters is rejected client-side and by rules.
- AC-08 Avatar must be one of the bundled avatar IDs; an unknown ID is rejected by rules. Age group must be one of `1-2`, `3-4`, `5-6`.
- AC-09 The parent cannot create more than the configured maximum number of profiles (client-enforced; **[ASSUMPTION]** 5).
- AC-10 Deleting a profile removes its favorites and progress within 1 minute (server-side cleanup).
- AC-11 `ProfilePickerPage` shows every profile of the parent and none from other parents.

### Library and details (F-04, F-05, F-13, F-14)
- AC-12 Only stories with `status == "published"` are visible; a draft story is not readable even if its ID is known.
- AC-13 Changing a story's title in Firestore is reflected on the next `HomePage` load with no app update.
- AC-14 The age-group filter defaults to the active child's group; a story tagged with several groups appears for each.
- AC-15 A new published story appears in the library without an app update.
- AC-16 When `appConfig/public.maintenanceMode == true` the app shows the maintenance screen on launch.
- AC-17 When the running build number is below `minSupportedBuild` for its platform the app shows the update screen; the store link is behind the gate.

### Reader and listen modes (F-06, F-07, F-08)
- AC-18 Pages are shown in `pageNumber` order; page N+1 is reached by swiping from left to right.
- AC-19 Each page shows its illustration and `displayTextAr`; in listen mode narration plays from the prepared audio file when present, otherwise from Arabic TTS of `ttsTextAr`.
- AC-20 Narration stops when leaving the page or the reader.
- AC-21 The last page shows the completion state and offers "read again" / "another story".
- AC-22 The reader works with the network disabled if the story was opened earlier in the session (Firestore cache + media cache). Prepared audio not yet cached requires network; TTS does not.
- AC-68 Play, pause, resume, and stop work for both prepared audio and TTS; pause/resume on TTS continues from the current sentence at worst.
- AC-69 Playback-speed selection offers the configured speeds; the choice persists for the session and as the parent's default; it applies to both sources.
- AC-70 With auto-advance enabled, the next page opens after narration ends (plus the configured delay); a tap during the delay cancels the advance; the last page never auto-advances.
- AC-71 Switching mode mid-story keeps the current page and does not lose progress.

### Favorites and progress (F-09, F-10)
- AC-23 Toggling ♥ creates / deletes `favorites/{storyId}` under the active child; no duplicates are possible.
- AC-24 Turning a page writes `progress/{storyId}` with `lastPageNumber`, `pageCount`, and `lastMode`; reaching the last page sets `completed = true` and increments `readCompletedCount` or `listenCompletedCount` according to the mode.
- AC-25 "تابع القراءة" lists stories with `completed == false` ordered by most recent activity.
- AC-26 Favorites and progress of child A are never shown for child B, and never for another parent.
- AC-64 Exiting on page N → later "تابع" resumes at page N in the last mode with the same playback speed; narration starts from the beginning of that page.
- AC-65 If a newer content version has fewer pages than `lastPageNumber`, resume clamps to the last page without error.

### Parental gate and parent area (F-11, F-12)
- AC-27 Entering the parent area, opening the paywall, any price display, purchase, restore, subscription management, any external link, sign-out, and any deletion require passing the gate.
- AC-28 The gate question is written in Arabic words (not digits) and changes on every attempt.
- AC-29 Three wrong answers trigger a cooldown of at least 30 seconds.
- AC-30 Leaving the parent area re-locks the gate; the gate does not stay unlocked across app restarts.
- AC-31 External links always show an Arabic confirmation ("سيتم فتح المتصفح") before leaving the app.
- AC-32 Account deletion requires recent re-authentication and removes: the Auth user, `users/{uid}` with all subcollections, `entitlements/{uid}`, and the RevenueCat subscriber record. A subsequent sign-in with the same email creates a fresh, empty account.

### Free story access (F-15)
- AC-41 A parent with no subscription (and no `entitlements/{uid}` document at all) can open every `accessLevel == "free"` story, read all pages in both modes with narration, and never sees a lock, paywall, or price.
- AC-42 Free stories are complete: the imported page count equals the authored story; the schema has no preview/sample mechanism; the content validator rejects any manifest that marks a free story as partial.
- AC-43 Rules tests: `pages` of a free story and its Storage media are readable by any signed-in parent without an entitlement.

### Locked premium content (F-16)
- AC-44 Premium stories appear in the library shelves with a lock badge (icon + label); their covers load for unsubscribed users.
- AC-45 Tapping a locked story shows `LockedStoryPage` with no prices and no store dialog; the only forward action is "للأهل", which opens the gate.
- AC-46 Rules tests: without an entitlement, `pages` of a premium story are not readable, premium page media cannot be fetched from Storage, and no tokened download URL exists for any premium page object (audit script passes).
- AC-47 Rules tests: the client cannot create, update, or delete `entitlements/{uid}` or anything beneath it.

### Successful monthly purchase (F-15, F-16)
- AC-48 After the gate, `PaywallPage` shows monthly and annual options with store-localised prices, the auto-renewal disclosure, terms and privacy links, and "استعادة المشتريات". A sandbox monthly purchase completes; the RevenueCat SDK reports `premium_library` active; within 10 seconds `entitlements/{uid}.premiumActive == true` with `productId` equal to the monthly placeholder; the locked story opens without restarting the app.

### Successful annual purchase
- AC-49 Same as AC-48 for annual; the mirror's `productId` equals the annual placeholder and `expiresAt` reflects the annual period (accelerated in sandbox).

### Purchase cancellation
- AC-50 Cancelling auto-renewal in the store (sandbox) produces a cancellation event; the mirror shows `willRenew == false` while `premiumActive` stays true until `expiresAt`; `SubscriptionPage` shows "ينتهي الاشتراك في <date>"; premium stays accessible until then.
- AC-51 Abandoning the platform purchase sheet leaves no entitlement, shows a neutral Arabic message on the paywall, and never surfaces anything in the child area.

### Grace period
- AC-52 A failed renewal that enters a billing grace period produces a billing-issue event; the mirror sets `billingIssueDetectedAt` and `gracePeriodExpiresAt`, keeps `premiumActive == true`, and `accessExpiresAt` equals the grace end; the parent area shows a payment-issue banner with a gated link to store billing; premium stays accessible until the grace period ends.

### Expired subscription
- AC-53 After expiry (expiration event, or `accessExpiresAt` in the past even before the event arrives), premium stories show the lock badge, rules deny their pages and media, an open premium story ends gracefully with the lock screen at the next page load, and progress is preserved (the story stays in "تابع القراءة" with a lock).
- AC-54 Re-subscribing restores access and previous progress.

### Restore purchases (F-17)
- AC-55 On a fresh install with the same Firebase account, premium is active without pressing restore (RevenueCat identified by UID).
- AC-56 "استعادة المشتريات" (behind the gate) with an active store subscription linked to this user re-syncs and activates premium; with no purchases it shows an Arabic "لم يتم العثور على مشتريات" message; it never crashes and never shows in the child area.
- AC-57 Restoring on a different Firebase account with the same store account follows the configured transfer policy (**[DECISION NEEDED — D-21]**) and the parent is warned before the transfer.

### Use on a second device
- AC-58 Signing in on device B activates premium within one entitlement sync (≤ 10 s) without a purchase; progress and favorites appear; simultaneous use on devices A and B works and does not revoke either.

### Missing Arabic TTS voice
- AC-59 On a device with no Arabic TTS voice, listen mode on a page without prepared audio shows the calm Arabic message, does not speak in any other language, offers "اقرأ بنفسي", and the "open TTS settings" hint is behind the gate.
- AC-60 The voice check runs before the first utterance of a session and again when the app returns from the background (a voice may have been installed).

### Missing or failed audio download
- AC-61 If prepared audio fails to download (offline, 404, timeout) the engine retries once, then falls back to Arabic TTS when a voice exists, otherwise shows the AC-59 message; text and illustration remain usable; the failure is logged without personal data.
- AC-62 A corrupt or unplayable audio file triggers the same fallback.

### RTL rendering (monetisation and audio surfaces)
- AC-63 `LockedStoryPage`, `PaywallPage`, `SubscriptionPage`, and the narration controls render correctly in RTL: prices with currency symbols and dates display correctly in the Arabic locale, next/previous are mirrored, play/pause are not, no clipped text at 130 % scale in the parent area.

### Child cannot reach the paywall without the gate
- AC-66 From every child-area screen, no sequence of taps reveals prices, store dialogs, or restore actions without passing the gate (exploratory test of at least 10 minutes per screen plus explicit checks on the lock screen, subscription banners, update screen, and the "الأهل" entry).
- AC-67 The platform purchase sheet is invoked only from `PaywallPage`, and `PaywallPage` is reachable only through the gate component (code review + navigation audit).

### Privacy and content (cross-cutting)
- AC-33 The child area contains no ads, links, share sheets, web views, prices, or text inputs other than the parental gate answer.
- AC-34 No crash log or Cloud Function log contains a nickname or email in plain text beyond what is needed to operate (see [SECURITY_AND_PRIVACY.md §8](SECURITY_AND_PRIVACY.md)).
- AC-35 A signed-in parent cannot read another parent's documents by ID (verified by rules unit tests).
- AC-36 A client cannot write to `stories`, `categories`, `appConfig`, or `entitlements` (verified by rules unit tests).
- AC-72 TTS receives only story text (`ttsTextAr`), never a nickname or any child data.

### RTL / accessibility checklist (per screen)
- AC-37 Screen renders correctly in RTL: text start-aligned, directional icons mirrored, no clipped text at 130 % text scale (parent area).
- AC-38 All interactive elements ≥ 48 dp and have Arabic semantics labels.
- AC-39 No information depends on colour alone; contrast ≥ 4.5:1.
- AC-40 No text in the child area is required to complete the primary action.

---

## 8. Decisions summary

| ID | Decision | Affects | Status / default |
|---|---|---|---|
| D-01 | Sign-in providers (email only vs. + Google / Apple) | F-01, store review | **Open** — default email + password only |
| D-02 | Age groups | Schema, child form, filters, content | **Confirmed**: `1-2`, `3-4`, `5-6` |
| D-03 | Monetisation | Schema, rules, gate, store review | **Confirmed**: freemium subscription, monthly + annual, RevenueCat via FlutterFlow, entitlement `premium_library` |
| D-04 | Analytics (none vs. Firebase Analytics with ad-ID disabled) | Privacy policy, SDK list | **Open** — default crash reporting only |
| D-05 | Digits style (Arabic-Indic vs. Western) | All screens | **Open** — default Arabic-Indic in child area |
| D-06 | Font family for UI and story text | Theme, content QA | **Open** — evaluate candidates in Phase 1 |
| D-07 | Max child profiles per parent | Client validation | **Open** — default 5 |
| D-08 | Orientation and tablet support | Layout | **Open** — default portrait only, phone-first |
| D-19 | Free trial / introductory offer | Paywall, RevenueCat products, store setup | **Open** — default none in MVP |
| D-20 | Price points and currencies for monthly / annual | Store products | **Open** — owner decision; placeholders only |
| D-21 | Restore-across-accounts (RevenueCat transfer) policy | AC-57, support | **Open** — default: transfer to the restoring account with a warning |
| D-22 | Playback-speed options | F-07 | **Open** — default 0.75×, 1×, 1.25× |
| D-23 | Source of prepared audio (human narration vs. generated by a cloud TTS in the content pipeline) | Content pipeline, quality | **Open** — default: generated where no human narration exists, always reviewed before publish |
| D-24 | Auto-advance default and delay | F-07 | **Open** — default on for listen mode, 1.5 s delay |
