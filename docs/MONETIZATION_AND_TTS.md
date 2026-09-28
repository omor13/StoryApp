# Monetisation (Freemium Subscription) and Hybrid Audio / TTS

| | |
|---|---|
| Status | Draft v0.1 — planning phase. No RevenueCat project, store products, Functions, or app code exist. |
| Last updated | 2026-09-21 |
| Related docs | [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels:** **[CONFIRMED]** decided by the owner on 2026-09-21 · **[ASSUMPTION]** · **[DECISION NEEDED]** · **[VERIFY]** claim about a third-party tool or store to check before relying on it · **[UNRESOLVED]** implementation detail deliberately left open · **[OWNER]** action only the owner can take · **[LEGAL]**.

**Placeholders used throughout (not final identifiers):** entitlement `premium_library` **[CONFIRMED name]**; products `PLACEHOLDER_PREMIUM_MONTHLY`, `PLACEHOLDER_PREMIUM_ANNUAL`; RevenueCat offering `default`. Final store product IDs, prices, and subscription-group names are owner decisions (D-20) and must not be invented here.

---

## 1. Overview and principles

| # | Principle | Source |
|---|---|---|
| M-01 | Several complete stories are permanently free; the rest of the library requires an active subscription. Free stories are never shortened, watermarked, or time-limited. | **[CONFIRMED]** |
| M-02 | Two auto-renewing subscriptions — monthly and annual — both unlocking the same entitlement `premium_library`. | **[CONFIRMED]** |
| M-03 | Purchases are made by the parent only, through Apple In-App Purchase and Google Play Billing, via RevenueCat's FlutterFlow integration. No Stripe, no web checkout, no external payment for digital content. | **[CONFIRMED]** |
| M-04 | Paywalls, prices, purchase and restore actions, subscription management, account management, and external links sit behind the parental gate. Children see a lock badge and a price-free lock screen only. | **[CONFIRMED]** |
| M-05 | RevenueCat subscription state is the source of truth. The client never grants itself premium; a server-written Firestore mirror (`entitlements/{uid}`) is what Firestore and Storage rules enforce. | **[CONFIRMED]** |
| M-06 | Premium media is never exposed through unrestricted Storage URLs. | **[CONFIRMED]** |
| M-07 | Every published story supports "اقرأ بنفسي" and "استمع إلى القصة". Listening prefers a prepared, quality-controlled Arabic audio file and falls back to on-device Arabic TTS; it never switches silently to a non-Arabic voice. | **[CONFIRMED]** |
| M-08 | Listening and reading progress are both saved; auto-advance after playback is supported and always cancellable. | **[CONFIRMED]** |

---

## 2. Free-to-paid user journey

```
Child                                   Parent
─────                                   ──────
HomePage: sees free + locked covers
 └─ taps a locked cover
     └─ LockedStoryPage (no prices)
          └─ "للأهل" ─────────────────▶ ParentalGatePage (Arabic-words arithmetic)
                                          └─ PaywallPage: value, monthly / annual, prices,
                                             auto-renew disclosure, restore, terms/privacy
                                              └─ platform purchase sheet (Apple / Google)
                                                  └─ success → SDK: premium_library active
                                                      └─ syncEntitlement (callable) → mirror
                                                          └─ "تم التفعيل" → back to the story
Child continues: story opens; every lock badge disappears
```

Touchpoints and copy rules:

| Step | Screen | Rules |
|---|---|---|
| 1 | `HomePage` / shelves | Premium covers show a lock badge (icon + short label "مميزة"). Premium stories are never hidden or filtered out. **[CONFIRMED]** |
| 2 | `StoryDetailsPage` (free) / `LockedStoryPage` (premium, not entitled) | The lock screen is child-facing: friendly illustration, one sentence, one button "للأهل". No prices, product names, timers, or store logos. |
| 3 | `ParentalGatePage` | Standard gate (see [SECURITY_AND_PRIVACY.md §7](SECURITY_AND_PRIVACY.md)). |
| 4 | `PaywallPage` | Parent-facing. Contents required by the stores **[VERIFY wording]**: what premium includes (number of stories, both modes), each plan's price and period as returned by the store, auto-renewal statement, how to cancel, "استعادة المشتريات", links to terms and privacy (external, confirmation dialog). Annual shows the equivalent monthly price and savings. |
| 5 | Platform sheet | Native; may require store authentication or "Ask to Buy" approval. |
| 6 | Post-purchase | Brief "جارٍ التفعيل…" while `syncEntitlement` runs (≤ 10 s target); then "تم التفعيل" and return to the originally requested story. If sync fails, the UI still shows premium from SDK state and retries sync in the background; pages may be briefly denied by rules (T19) — show a retry state, never an error to the child. |
| 7 | Later | `SubscriptionPage` in the parent area shows status, renewal date, plan, and gated store-management links. |

Other entry points to the paywall (all gated): `SubscriptionPage` → "اشترك", and a small "المكتبة المميزة" card on `ParentAreaPage`. **No** paywall entry exists on the child home besides the lock screen → gate path.

---

## 3. Monthly and annual subscription design

| Aspect | Design | Status |
|---|---|---|
| Products | Two auto-renewing subscriptions: monthly and annual. Placeholders `PLACEHOLDER_PREMIUM_MONTHLY`, `PLACEHOLDER_PREMIUM_ANNUAL`. Same entitlement for both. | **[CONFIRMED]** structure; IDs **[OWNER]** (D-20) |
| Apple setup | One subscription group containing both products so the store handles upgrade/downgrade and only one is active at a time **[VERIFY]**. Billing grace period enabled in App Store Connect **[VERIFY setting name]**. | **[OWNER]** |
| Google setup | One subscription product with two base plans (monthly, annual) or two products — RevenueCat supports both **[VERIFY]**. Grace period enabled (store-configurable, e.g., 3–30 days) **[VERIFY]**. Account hold behaviour accepted (access suspended during hold). | **[OWNER]** |
| RevenueCat | Entitlement `premium_library` attached to both products on both platforms; offering `default` with a monthly and an annual package (RevenueCat's standard package types **[VERIFY identifiers]**). Paywall reads the current offering — never hard-coded prices. | Phase 4 |
| Prices & currencies | Owner decision; shown as store-localised strings. Annual priced to show a clear saving **[ASSUMPTION]**. | **[DECISION NEEDED — D-20]** |
| Free trial / intro offer | Not in MVP by default; the free stories are the trial. If added later, both stores' trial rules and RevenueCat `periodType` handling apply. | **[DECISION NEEDED — D-19]** |
| Plan change | MVP: a subscribed parent changes plan in the store (gated link). In-app upgrade/downgrade is post-MVP. | **[ASSUMPTION]** |
| Family Sharing (Apple) / multiple parents | Not designed for in MVP; enabling Apple Family Sharing on the product is an owner choice that RevenueCat supports **[VERIFY]**. | **[DECISION NEEDED — D-28]** |
| Lifetime / one-time | Excluded from MVP. | — |
| Refunds | Handled by the stores; RevenueCat reports them; mirror updates via webhook. | — |
| Sandbox vs production | Separate RevenueCat projects for non-prod and prod (D-25); production rules ignore sandbox entitlements by default (D-26). | Open |

---

## 4. Parental-gate flow for monetisation surfaces

The gate component is the same one used for the parent area ([SECURITY_AND_PRIVACY.md §7](SECURITY_AND_PRIVACY.md)). Monetisation-specific rules:

| # | Rule |
|---|---|
| PG-01 | Surfaces that require a passed gate: `PaywallPage`, any price display, purchase action, restore action, `SubscriptionPage`, store subscription-management links, store billing links, "update app" store link, external legal links, device TTS-settings link. **[CONFIRMED]** |
| PG-02 | `LockedStoryPage` is the only child-facing monetisation surface and contains no purchase affordance except "للأهل" → gate. |
| PG-03 | The gate unlock is session-scoped; returning to the child area re-locks it, so a child cannot reopen the paywall after the parent hands the device back. |
| PG-04 | The platform purchase sheet is only ever invoked from `PaywallPage` (navigation audit, AC-67). |
| PG-05 | Post-purchase confirmation returns the parent to the story details, not to a purchase-related screen, so the child does not see purchase UI. |
| PG-06 | `BillingIssueBanner` (grace period) is shown in the parent area only; the child area shows nothing about billing. |

---

## 5. RevenueCat entitlement model

| Element | Value / behaviour |
|---|---|
| App user ID | The Firebase Auth UID, set right after sign-in (`logIn`) and cleared on sign-out (`logOut`). **[CONFIRMED]** FlutterFlow's integration is expected to do this automatically **[VERIFY]**; otherwise custom actions `identifyRevenueCatUser()` / `logOutRevenueCat()`. Purchases are impossible while anonymous because the paywall is unreachable without a signed-in parent. |
| Entitlement | `premium_library` — active when any of the two products is active (including grace periods per store policy). **[CONFIRMED]** |
| Client-side state | `CustomerInfo.entitlements.active` contains `premium_library` → app state `isPremiumUi = true`. **Display only**: it controls lock badges, the paywall's "already subscribed" state, and `SubscriptionPage`. It never unlocks data — rules do (via the mirror). |
| Server-side state | `entitlements/{uid}` mirror ([FIREBASE_SCHEMA.md §11](FIREBASE_SCHEMA.md)), computed from RevenueCat's subscriber record fetched by the server. |
| Source-of-truth order | RevenueCat (authoritative) → mirror (enforcement) → SDK cache (display). Conflicts are resolved by re-fetching from RevenueCat. |
| Attributes | None containing personal data. Optionally `$displayName` is **not** set. No email is passed. **[CONFIRMED privacy stance]** |
| Environments | Non-prod RevenueCat project(s) receive sandbox purchases; prod project real purchases. Public SDK keys per environment live in FlutterFlow settings (never in git/docs). |

### 5.1 Entitlement states (as seen by the app)

| State | RevenueCat signal | Mirror (`premiumActive`, `accessExpiresAt`) | UI |
|---|---|---|---|
| Never subscribed | no entitlement | doc absent or `false` | lock badges; paywall offers both plans |
| Active, renewing | active, `willRenew` true | `true`, `expiresAt` | unlocked; "يتجدد في <date>" |
| Active, cancelled (auto-renew off) | active, `willRenew` false, `unsubscribeDetectedAt` | `true`, `expiresAt` | unlocked; "ينتهي في <date>"; "إعادة التفعيل" → store |
| Grace period (billing issue) | active, `billingIssueDetectedAt`, `gracePeriodExpiresAt` | `true`, `max(expiresAt, grace)` | unlocked; `BillingIssueBanner` in parent area |
| Account hold (Google) / billing retry after grace | inactive | `false` | locked; parent area explains how to fix payment |
| Paused (Google) | inactive, `SUBSCRIPTION_PAUSED` | `false` | locked; explanation |
| Expired | inactive, `EXPIRATION` | `false`, `revokedAt` | locked; paywall offers re-subscribe |
| Refunded | inactive (store-initiated) | `false` | locked |
| Manual support grant | n/a (admin script) | `true`, `manualGrant.expiresAt` | unlocked; no store dates shown |

---

## 6. Purchase and restore-purchase flows

### 6.1 Purchase (parent, behind the gate)
1. `PaywallPage` loads the offering (FlutterFlow RevenueCat action / generated helper). If loading fails: Arabic error with retry; never a blank paywall.
2. Parent selects a package → FlutterFlow "purchase package" action.
3. Outcomes:
   - **Success** → SDK customer info shows `premium_library` → app calls custom action `syncEntitlement()` → callable writes the mirror → "تم التفعيل" → navigate back to the requested story.
   - **User cancelled** → neutral message, stay on paywall, no error logged as failure.
   - **Payment pending / deferred** (e.g., Apple "Ask to Buy") → "بانتظار الموافقة" state; the app re-checks on resume and on the next launch; the webhook will arrive when approved.
   - **Already owned / active on this store account but different app user** → show restore guidance (see 6.2 and D-21).
   - **Store or network error** → Arabic message with retry; log error code without personal data.
4. Sandbox and production are indistinguishable in UI; the mirror carries `isSandbox`.

### 6.2 Restore purchases (parent, behind the gate) **[CONFIRMED manual action]**
1. Entry points: `PaywallPage` → "استعادة المشتريات"; `SubscriptionPage` → same.
2. FlutterFlow "restore purchases" action → RevenueCat syncs the store account's receipts to the current app user ID.
3. Then `syncEntitlement()` → mirror.
4. Outcomes:
   - Entitlement found → "تمت الاستعادة" → unlocked.
   - Nothing found → "لم يتم العثور على مشتريات لهذا الحساب" with a hint to check the store account used at purchase.
   - **Transfer case**: the store account's subscription is currently attached to a *different* Firebase account. RevenueCat's restore behaviour setting decides: transfer to the current app user (default, emits `TRANSFER`), or keep with the original. **[DECISION NEEDED — D-21]** Default: transfer, with an in-app warning before restore: "قد يؤدي ذلك إلى نقل الاشتراك من حساب آخر". The webhook handler updates both mirrors.
5. Restore is idempotent and safe to repeat; it is rate-limited in the UI (one in-flight at a time).

### 6.3 Second device / reinstall
- Sign-in on another device → RevenueCat `logIn(uid)` → customer info already includes the entitlement → `isPremiumUi` true; mirror already true → premium works immediately (AC-58). No restore needed.
- Simultaneous use on several devices with the same parent account is allowed; no device limit in MVP **[ASSUMPTION]**.

### 6.4 Deletion and subscriptions
- Deleting the account removes the mirror and the RevenueCat subscriber but **cannot** cancel the store subscription; the UI says so before deletion ([SECURITY_AND_PRIVACY.md §9.2](SECURITY_AND_PRIVACY.md)).

---

## 7. Expiration, cancellation, grace period, and offline behaviour

### 7.1 Lifecycle events → mirror → app

| Event (RevenueCat) **[VERIFY names]** | Mirror update | App behaviour |
|---|---|---|
| `INITIAL_PURCHASE`, `RENEWAL`, `UNCANCELLATION` | `premiumActive=true`, `expiresAt`, `willRenew=true`, `grantedAt` if first | Unlocked |
| `CANCELLATION` (auto-renew off) | `willRenew=false`, `unsubscribeDetectedAt`; access unchanged | Unlocked until `expiresAt`; parent area shows end date |
| `CANCELLATION` with refund reason | `premiumActive=false`, `revokedAt` | Locked |
| `BILLING_ISSUE` | `billingIssueDetectedAt`, `gracePeriodExpiresAt`, `accessExpiresAt=max(...)` | Unlocked during grace; banner in parent area with gated link to store billing |
| `EXPIRATION` | `premiumActive=false`, `revokedAt` | Locked; progress kept |
| `PRODUCT_CHANGE` | `productId`, `expiresAt` | Unlocked; status text updates |
| `SUBSCRIPTION_PAUSED` (Google) | `premiumActive=false` | Locked with explanation |
| `TRANSFER` | old uid → `premiumActive=false`; new uid → recomputed from RevenueCat | Old device locks on next sync; new unlocked |
| `TEST` | no mirror change; logged | — |

Time-based safety independent of events: rules require `accessExpiresAt > request.time`, so an expired subscription locks even if `EXPIRATION` never arrives (T18). A scheduled Function re-syncs mirrors whose `accessExpiresAt` falls within the next 48 h **[ASSUMPTION]** and any mirror not synced for 7 days.

### 7.2 Client behaviour on expiry while reading
- The reader checks `isPremiumUi` and the mirror on each page load; on denial (rules error or local expiry) it shows the lock screen at the next page turn, saves progress, and returns to the library. Narration stops. No crash, no partial content bleed.

### 7.3 Offline behaviour
| Situation | Behaviour |
|---|---|
| Offline, free story cached | Works fully (Firestore persistence + media cache; TTS on-device). |
| Offline, premium story cached, entitlement valid at last check | Works from cache while `now < min(accessExpiresAt, lastVerifiedAt + 7 days)` **[ASSUMPTION: 7-day offline allowance]**. The RevenueCat SDK's cached customer info and the cached mirror provide the dates. |
| Offline, premium story cached, allowance exceeded or expired | Lock screen with "يلزم الاتصال بالإنترنت للتحقق من الاشتراك". |
| Offline, premium pages never fetched | Lock/offline message; nothing to show (rules were never evaluated). |
| Offline purchase / restore | Not possible; paywall explains. |
| Back online | Background `syncEntitlement()` if stale; UI reconciles silently. |

Note: Firestore's offline cache serves previously fetched documents without re-evaluating rules; this is inherent and acceptable because they were fetched legitimately. The client-side allowance above governs UI behaviour; premium cache purge on entitlement loss limits the window (T23).

---

## 8. Server-side entitlement synchronisation

### 8.1 Components (Cloud Functions, `backend/functions/`)

| Function | Trigger | Responsibility |
|---|---|---|
| `revenuecatWebhook` | HTTPS (public URL registered in RevenueCat) | Verify the shared-secret `Authorization` header (constant-time compare); reject others with 401. Parse event; ignore unknown `app_user_id` formats (anonymous IDs) with a warning; enforce idempotency by `event.id`; **re-fetch the subscriber from the RevenueCat REST API**; compute and write the mirror; append `events/{eventId}`; for `TRANSFER` process both `transferred_from` and `transferred_to` **[VERIFY field names]**; respond 200 quickly (RevenueCat retries on non-2xx). |
| `syncEntitlement` | Callable (auth + App Check) | For `context.auth.uid` only: rate-limit (≥ 30 s between calls per uid unless `force` after purchase/restore **[ASSUMPTION]**); fetch subscriber from RevenueCat; compute and write the mirror with `lastSyncSource="callable"`; return the mirror summary to the client. |
| `resyncExpiringEntitlements` | Scheduled (daily **[ASSUMPTION]**) | Re-fetch mirrors with `accessExpiresAt` within 48 h or `lastSyncedAt` older than 7 days; write with `lastSyncSource="scheduled"`. |
| `auditPremiumTokens` | Scheduled (daily) | List `stories/premium/**/pages/**` objects; alert (log + optional email **[OWNER]**) and strip `firebaseStorageDownloadTokens` metadata if any object has one (T15). |
| `purgeEntitlementEvents` | Scheduled (weekly) | Delete `events` older than 90 days **[ASSUMPTION]**. |

### 8.2 Mirror computation (described, not code)
1. Fetch subscriber for `uid` from RevenueCat (REST API, secret key from Secret Manager) **[VERIFY endpoint/version]**.
2. Locate entitlement `premium_library`. If absent → `premiumActive=false`, `accessExpiresAt=now`, keep audit fields.
3. `expiresAt` = entitlement expiration (null → far-future sentinel for non-expiring grants); `gracePeriodExpiresAt` from the underlying subscription if present.
4. `accessExpiresAt = max(expiresAt, gracePeriodExpiresAt)`.
5. `premiumActive = accessExpiresAt > now`; in production additionally `isSandbox == false` unless D-26 changes.
6. Write with server timestamps: `lastSyncedAt`, `lastSyncSource`, `lastEventType/Id/At` (webhook path), `grantedAt` on first activation, `revokedAt` on deactivation, `updatedAt`.
7. Never trust the webhook payload's entitlement fields alone — the fetched subscriber record wins (T17). Out-of-order webhooks are harmless because each handler re-fetches current state.

### 8.3 Secrets and configuration **[OWNER, not in this phase]**
- RevenueCat webhook `Authorization` value and REST API key → Secret Manager (per environment).
- Public SDK keys → FlutterFlow settings only.
- Nothing in git, docs, Firestore, or FlutterFlow custom code. **[CONFIRMED]**

### 8.4 Failure handling and observability
- Webhook handler errors → 5xx so RevenueCat retries; alerts on repeated failures.
- `syncEntitlement` errors → client shows retry; SDK state still drives display.
- Logs contain uid and event type only; raw payloads at debug level with short retention.
- A support script (`backend/tools/admin/resync-entitlement --uid`) forces a sync; `grant-manual-entitlement` writes a bounded manual grant with a reason.

### 8.5 Testing without cloud resources
- Functions unit tests with recorded RevenueCat payload fixtures (sandbox `TEST` event and hand-built examples) against the Emulator Suite; the RevenueCat REST call is stubbed.
- End-to-end sandbox flow requires the `dev` project, Blaze billing, store sandbox accounts, and a RevenueCat project — all **[OWNER]** prerequisites.

---

## 9. Firestore and Storage access considerations

Summary of the enforcement model (details in [FIREBASE_SCHEMA.md §12–15](FIREBASE_SCHEMA.md) and [SECURITY_AND_PRIVACY.md §4](SECURITY_AND_PRIVACY.md)):

| Layer | Free stories | Premium stories |
|---|---|---|
| `stories/{id}` (metadata, cover URL, `accessLevel`) | readable when published | readable when published (needed for lock badge) |
| `stories/{id}/pages/**` | readable when published | readable only when published **and** entitled (mirror check) |
| Storage covers | tokened URL (readable by all signed-in users) | tokened URL — covers are non-sensitive by design |
| Storage page media | tokened URLs stored in `imageUrl` / `audioUrl` | **no tokens**; SDK read by path under rules with entitlement check; `imageUrl` / `audioUrl` absent |
| App Check | enforced | enforced |
| Offline | Firestore cache + media cache | same, bounded by the client allowance (§7.3) and cache purge |
| Admin | full read | full read (for review) |

Consequences and cautions:
- The UI must handle a `permission-denied` on pages of a premium story as "locked", not as a crash — it is the expected outcome for non-entitled users who somehow reach the reader (e.g., stale `isPremiumUi`).
- Cross-service Storage rules (Storage reading Firestore) add a Firestore read per premium object fetch; the disk cache keeps this to one fetch per page media per version. **[VERIFY availability and pricing]**
- Fallback if cross-service rules are not available: `signStoryMediaUrls` callable returns short-lived signed URLs for one story after checking the mirror server-side; TTL ≤ 60 min **[ASSUMPTION]**; still no permanent tokens.
- Firestore `in` queries with mixed free/premium IDs are fine (metadata is readable for both); only page queries differ.
- Changing a story from premium to free (or back) is a re-import with a new `contentVersion` and path prefix — never a metadata-only edit, so tokens and paths stay consistent with `accessLevel`.

---

## 10. TTS and hybrid audio architecture

### 10.1 Source selection **[CONFIRMED order]**
```
page opened in listen mode (or ▶ tapped in read mode)
 ├─ page.audioPath present?
 │    ├─ yes → fetch via cache (URL for free, SDK path for premium)
 │    │        ├─ ok → play prepared audio
 │    │        └─ fail (network / 404 / corrupt) → retry once → fall through to TTS
 │    └─ no  → TTS
 └─ TTS: Arabic voice available? (see §11)
        ├─ yes → speak page.ttsTextAr with the selected speed
        └─ no  → "unavailable" state (see §12); never speak in another language
```

### 10.2 `StoryNarrator` custom widget — state machine
States: `idle` → `loading` → `playing` ⇄ `paused` → `completed` | `error(kind)`; `stopped` returns to `idle`.

| Control | Prepared audio | TTS |
|---|---|---|
| play | start from 0 | speak sentence 1 |
| pause | pause position | stop engine; remember current sentence index (native pause where supported **[VERIFY per platform]**) |
| resume | resume position | speak from the remembered sentence |
| stop | stop, reset | stop, reset index |
| speed | player rate (0.75 / 1.0 / 1.25 **[D-22]**) | engine rate mapped per platform (Android and iOS use different scales **[VERIFY]**) |
| completion | player completed | last sentence completion callback |

Sentence chunking: `ttsTextAr` is split on Arabic/Latin sentence punctuation (`.`, `!`, `؟`, `،` optionally) so pause/resume and progress are at worst sentence-granular and long texts do not hit engine input limits.

### 10.3 Auto-advance **[CONFIRMED optional]**
- Effective flag = `page.autoAdvance` if present, else the parent setting (`settings.autoAdvance`, default from `appConfig.playback.autoAdvanceDefault`).
- Never on the last page; never on `pageKind == "question"`.
- On completion: wait `autoAdvanceDelayMs` (page override → setting → config default 1500 ms); a tap anywhere cancels; then invoke the FlutterFlow callback `onAdvance` which navigates to the next page and saves progress.
- In read mode, auto-advance is off unless the user pressed ▶ on the page **[ASSUMPTION]**.

### 10.4 Autoplay and lifecycle
- Listen mode: narration autoplays on page open if `settings.narrationAutoplay` (default true). Read mode: manual ▶.
- App backgrounded / phone call / audio focus loss → pause; no background playback in MVP **[ASSUMPTION]**.
- Leaving the page or the reader → stop and release the engine/player.
- Prefetch: when a page opens, the widget requests the next page's image and audio via `prefetchPageMedia`.

### 10.5 Progress
- Page turn (manual or auto) → `saveProgress(mode)`; completion on the last page increments `listenCompletedCount` or `readCompletedCount`. Resume uses `lastPageNumber`, `lastMode`, `lastPlaybackSpeed`.

### 10.6 Content-side TTS considerations
- `ttsTextAr` is authored for engines (numbers as words, punctuation for pauses); validators reject empty values.
- Prepared audio is the quality path; generating it in the content pipeline with a cloud TTS (D-23) and reviewing it is preferred over relying on device TTS for premium stories. `stories.audioSource` tells the UI whether a story depends on device TTS so `StoryDetailsPage` can warn when no Arabic voice exists.

---

## 11. Arabic voice availability checks

| # | Requirement |
|---|---|
| V-01 | Check runs: on app start (async, non-blocking), before the first TTS utterance of a session, and when the app returns to the foreground (a voice may have been installed). Result cached in app state `arabicTtsAvailable`. **[CONFIRMED: verify before playback]** |
| V-02 | Detection: enumerate installed voices/languages via the TTS plugin; accept only voices whose locale starts with `ar` (preferred order configurable, e.g., `ar-SA`, `ar-EG`, `ar-AE`, generic `ar` **[UNRESOLVED: add `ttsPreferredLocales` to `appConfig.playback`]**). |
| V-03 | Android: "language available" and "voice data installed" are different states; treat only *installed* as available. Some engines report availability but need a download **[VERIFY plugin API for install status]**. Engine choice is left to the system default; do not force a specific engine in MVP. |
| V-04 | iOS: use the system voice list; Arabic compact voices are typically present but enhanced voices may need download **[VERIFY per iOS version]**. |
| V-05 | After setting the language, confirm the engine's effective voice locale is Arabic; if the engine silently substituted a default voice, treat as unavailable. **[CONFIRMED: never silently switch to a non-Arabic voice]** |
| V-06 | Never speak a "test" utterance audibly to probe availability. |
| V-07 | When unavailable: listen mode still opens (pages are fully usable), the narration control shows the unavailable state (§12), and `StoryDetailsPage` shows a small notice for stories with `audioSource == "tts"`. |
| V-08 | Parent-facing remedy: "للأهل: يمكن تثبيت صوت عربي من إعدادات الجهاز" → gate → open device TTS settings (platform-specific; a custom action; may only open general settings on iOS **[VERIFY]**). |

---

## 12. Audio fallback behaviour

| Situation | Behaviour | Child sees |
|---|---|---|
| Prepared audio present and loads | Play it | Normal controls |
| Prepared audio download fails (offline, 404, timeout) | Retry once (short backoff) → TTS if Arabic voice → else unavailable state | At most a brief loading indicator; then narration or the calm notice |
| Prepared audio corrupt / player error | Same as above; mark the file as bad in cache (evict) | Same |
| No prepared audio, Arabic voice present | TTS of `ttsTextAr` | Normal controls |
| No prepared audio, no Arabic voice | Unavailable state: calm Arabic text + illustration remains; ▶ replaced by an "unavailable" icon with label; "اقرأ بنفسي" suggested | No sound in any other language, no error dialog |
| TTS engine error mid-page | Stop; show the unavailable state for this page; allow manual next | Same |
| Speed unsupported by engine | Fall back to 1.0× and show the effective speed | Speed chip shows 1× |
| Auto-advance pending when playback fails | Cancel auto-advance; wait for manual turn | — |
| Premium page media denied (not entitled / expired) | Treat as locked, not as audio failure (§7.2) | Lock screen at next page load |

Logging: failures are logged with story ID, page number, source, and error kind — never with child data (AC-61, P-16).

---

## 13. Audio (and image) caching recommendations

| Topic | Recommendation |
|---|---|
| Cache key | The Storage object path (contains `contentVersion`), never the URL. Free media URLs embed the path, so the same key works. |
| Fetchers | Two fetch strategies behind one cache: HTTP for tokened URLs (free/covers); Storage SDK file download for premium paths (rules-enforced). |
| Location | App-private storage; premium files in a separate directory that is purged on sign-out, account deletion, and entitlement loss; excluded from OS backups **[VERIFY platform flags]**. |
| Size and eviction | LRU with a cap (e.g., 300 MB total, 150 MB premium **[ASSUMPTION]**); audio ≤ ~1 MB per page at 64–96 kbps. |
| Prefetch | Next page's image + audio when a page opens; optionally the whole story on Wi-Fi when opened **[ASSUMPTION]**. |
| Immutability | Objects are immutable per version → cache entries never revalidate; a new version is a new key. |
| TTS output | Not cached in MVP (engines synthesise live; capturing output is platform-specific). The durable answer is prepared/generated audio in the pipeline (D-23). |
| Images | Same cache for illustrations; covers may use FlutterFlow's default network image caching **[VERIFY which package FlutterFlow uses]**. |
| Package candidates | `flutter_cache_manager` with a custom file fetcher; `just_audio` or `audioplayers` for playback; `flutter_tts` for TTS — all **[VERIFY]** for FlutterFlow custom-code compatibility and current maintenance status. |

---

## 14. Required FlutterFlow actions (built-in, configured in the editor)

| Area | FlutterFlow capability | Where used |
|---|---|---|
| RevenueCat integration | Enable in FlutterFlow settings with per-platform public keys; entitlement identifier `premium_library`; offering `default` **[VERIFY setting names]** | Project settings |
| Purchase | RevenueCat "purchase package" action with the selected package | `PaywallPage` |
| Restore | RevenueCat "restore purchases" action | `PaywallPage`, `SubscriptionPage` |
| Entitlement state (display) | RevenueCat active-entitlement check in conditional visibility / app state update | Lock badges, paywall state, `SubscriptionPage` |
| Offerings/prices | RevenueCat offerings data for package cards | `PaywallPage` |
| Auth | Sign up / sign in / sign out / re-authenticate / password reset | Auth pages, `AccountPage` |
| Firestore | Query collections (Q1–Q15), create/update documents (children, settings), document reads by reference | Everywhere |
| Navigation | Guarded navigation: `PaywallPage` only from gate success; `LockedStoryPage` for premium + not entitled | Child area |
| App state | Persisted state for active child, settings, session gate state | Global |
| Launch URL | External links after gate + confirmation | Parent area, paywall |
| Custom widget callbacks | Action parameters for `onAdvance`, `onCompleted`, `onError` from `StoryNarrator` **[VERIFY support]** | `ReaderPage` |
| Localisation | All strings in the localisation table (Arabic) | Global |

---

## 15. Required custom actions and custom widgets (authored through FlutterFlow custom code)

| Kind | Name | Inputs → outputs | Notes |
|---|---|---|---|
| Widget | `StoryNarrator` | `displayTextAr`, `ttsTextAr`, `audioPath?`, `audioUrl?`, `accessLevel`, `speed`, `autoAdvance`, `autoAdvanceDelayMs`, `autoplay`, `isLastPage`, `pageKind`; callbacks `onAdvance`, `onCompleted`, `onError`, `onSourceResolved` | The hybrid engine (§10–12). Owns player + TTS lifecycle. |
| Widget | `StoryMediaImage` | `imagePath`, `imageUrl?`, `imageAlt` | Free → URL via cache; premium → SDK path via cache; shows placeholder/lock on denial. |
| Action | `checkArabicTtsVoice()` | → `bool` (+ updates app state) | §11. |
| Action | `openTtsSettings()` | → `bool` | Behind the gate; platform-specific **[VERIFY]**. |
| Action | `prefetchPageMedia(imagePath?, imageUrl?, audioPath?, audioUrl?, accessLevel)` | → `void` | Warms cache for the next page. |
| Action | `purgePremiumCache()` | → `void` | On sign-out, deletion, entitlement loss. |
| Action | `saveProgress(childId, storyId, pageNumber, pageCount, contentVersion, mode, speed, isLastPage)` | → `void` | Deterministic ID, merge write, mode counters. |
| Action | `toggleFavorite(childId, storyId)` | → `bool` (new state) | Deterministic ID. |
| Action | `syncEntitlement(force)` | → mirror summary map | Calls the callable; used after purchase/restore/sign-in/stale. |
| Action | `identifyRevenueCatUser()` / `logOutRevenueCat()` | → `void` | Only if the integration does not handle it **[VERIFY]**. |
| Action | `callDeleteAccount()` | → result | Callable + sign-out + purge. |
| Action | `initAppCheck()` | → `void` | Only if needed **[VERIFY]**. |
| Function | `generateGateChallenge()` | → `{promptAr, answer}` | Gate. |
| Function | `numberToArabicWords(int)` | → `String` | Gate prompt. |
| Function | `toArabicIndicDigits(String)` | → `String` | D-05. |
| Function | `formatSubscriptionDate(DateTime)` / `formatPriceAr(String)` | → `String` | Bidi-safe formatting for `SubscriptionPage` / paywall. |
| Function | `isAccessAllowedOffline(mirrorSummary, lastVerifiedAt)` | → `bool` | §7.3 allowance. |

All custom code depends only on pub packages declared in FlutterFlow and on generated record classes ([ARCHITECTURE.md §8.2](ARCHITECTURE.md)). No code is written in this phase.

---

## 16. Testing matrix — Android and iOS

### 16.1 Environments and tools **[OWNER prerequisites]**
- Apple: sandbox tester accounts in App Store Connect; accelerated renewals in sandbox (e.g., monthly ≈ 5 min **[VERIFY]**); billing-retry/grace simulation for sandbox testers **[VERIFY availability]**; TestFlight builds.
- Google: license testers; test payment methods ("always approves", "always declines", "slow" cards) **[VERIFY]**; accelerated renewals; internal testing track.
- RevenueCat: non-prod project, webhook pointing at the `dev` Functions URL, "send test event".
- Firebase `dev` project with Blaze billing (Functions, Storage) — **blocker until approved**.

### 16.2 Purchase and entitlement scenarios

| # | Scenario | Android | iOS | Expected (AC) |
|---|---|---|---|---|
| S1 | Free story, no subscription, both modes | ✓ | ✓ | AC-41, AC-43 |
| S2 | Locked story → lock screen → gate → paywall | ✓ | ✓ | AC-44, AC-45, AC-66, AC-67 |
| S3 | Monthly purchase (sandbox) | ✓ | ✓ | AC-48 |
| S4 | Annual purchase (sandbox) | ✓ | ✓ | AC-49 |
| S5 | Abandon purchase sheet | ✓ | ✓ | AC-51 |
| S6 | Deferred purchase ("Ask to Buy") | — | ✓ | pending state, later activation |
| S7 | Cancel auto-renew in store, keep access until expiry | ✓ | ✓ | AC-50 |
| S8 | Renewal failure → grace period | ✓ (decline card) | ✓ (sandbox toggle) | AC-52 |
| S9 | Expiry after accelerated renewals | ✓ | ✓ | AC-53 |
| S10 | Re-subscribe after expiry | ✓ | ✓ | AC-54 |
| S11 | Restore on reinstall (same account) | ✓ | ✓ | AC-55, AC-56 |
| S12 | Restore with different Firebase account (transfer policy) | ✓ | ✓ | AC-57 |
| S13 | Second device sign-in | ✓ | ✓ | AC-58 |
| S14 | Webhook delayed / offline after purchase | ✓ | ✓ | callable sync unlocks; T19 |
| S15 | Mirror tampering attempt from client | ✓ | ✓ | AC-47 (rules tests) |
| S16 | Premium media fetch without entitlement (SDK path) | ✓ | ✓ | AC-46 |
| S17 | Token audit on premium objects | n/a | n/a | AC-46 (script) |
| S18 | Sandbox entitlement against prod rules (D-26) | ✓ | ✓ | locked (if default kept) |
| S19 | Account deletion with active subscription | ✓ | ✓ | AC-32; store subscription continues; UI warned |
| S20 | Offline allowance for cached premium | ✓ | ✓ | §7.3 |

### 16.3 Audio / TTS scenarios

| # | Scenario | Android | iOS | Expected |
|---|---|---|---|---|
| A1 | Prepared audio, online | ✓ | ✓ | plays; controls work (AC-68) |
| A2 | Prepared audio, cached, offline | ✓ | ✓ | plays from cache (AC-22) |
| A3 | Prepared audio, uncached, offline | ✓ | ✓ | retry → TTS fallback (AC-61) |
| A4 | Prepared audio 404 / corrupt | ✓ | ✓ | fallback (AC-61, AC-62) |
| A5 | No prepared audio, Arabic voice installed | ✓ (Google TTS with Arabic data) | ✓ | TTS plays (AC-19) |
| A6 | No prepared audio, Arabic voice **not** installed | ✓ (voice data removed) | ✓ (if removable) | unavailable state; no other language (AC-59) |
| A7 | Voice installed while app is backgrounded | ✓ | ✓ | re-check on resume (AC-60) |
| A8 | Third-party TTS engine set as default | ✓ (e.g., Samsung TTS) | n/a | still Arabic-only or unavailable |
| A9 | Speed selection for both sources | ✓ | ✓ | AC-69 |
| A10 | Pause/resume TTS mid-page | ✓ (sentence granularity) | ✓ | AC-68 |
| A11 | Auto-advance on/off, cancel by tap, last page, question page | ✓ | ✓ | AC-70 |
| A12 | Interruption (call / audio focus) | ✓ | ✓ | pauses; manual resume |
| A13 | Mode switch mid-story | ✓ | ✓ | AC-71 |
| A14 | Resume in last mode with last speed | ✓ | ✓ | AC-64 |
| A15 | Content re-import with fewer pages | ✓ | ✓ | AC-65 |
| A16 | Long `ttsTextAr` (near engine limits) | ✓ | ✓ | chunked; completes |
| A17 | Bidi/RTL of narration controls and paywall | ✓ | ✓ | AC-63 |
| A18 | TalkBack / VoiceOver on reader and paywall | ✓ | ✓ | AC-38 |

### 16.4 Device matrix **[ASSUMPTION]**
- Android: one low-end (Android 10/11), one mid (12/13), one recent (14/15); at least one Samsung device (different default TTS engine) and one Pixel.
- iOS: one older device (iOS 16), one recent (iOS 17/18); iPad in portrait for stretch check.
- Network: Wi-Fi, cellular, throttled, airplane mode.

---

## 17. Risks — children's privacy and third-party SDKs

| # | Risk | Mitigation | Owner |
|---|---|---|---|
| K-01 | RevenueCat SDK in a Kids Category / Families app: store reviewers scrutinise third-party SDKs. | RevenueCat is purchase infrastructure (no ads/analytics); app user ID = UID only; no attributes with personal data; do **not** enable device-identifier (IDFA/GAID/IDFV) or ad-attribution collection **[VERIFY SDK option names]**; document in privacy labels; review Play Families and Apple Kids requirements before submission **[VERIFY]** **[LEGAL]**. | Phase 4 / 6 |
| K-02 | Purchase data is inherently the parent's personal data (store account, receipts). | Handled by RevenueCat/stores; app stores only the mirror (no store account identifiers); deletion flow removes the RevenueCat subscriber. | Phase 5 |
| K-03 | TTS engines processing text off-device (some Android engines / network voices). | Only story text is ever sent; no child data; note in privacy policy **[LEGAL]**; prefer prepared audio for premium stories. | Phase 3 |
| K-04 | Audio/TTS plugins with permissions (e.g., audio focus, notifications for background playback). | No background playback in MVP → no notification permission; review each plugin's manifest additions in the `flutterflow → develop` sync PR. | Phase 3 |
| K-05 | Cached premium content remaining on a child's device after subscription ends. | Private cache, purge on entitlement loss/sign-out, offline allowance bounded (T23). | Phase 4 |
| K-06 | A child reaching a purchase via OS prompts or a stale unlocked gate. | Gate is session-scoped and re-locks on leaving the parent area; purchase sheet only from `PaywallPage`; store parental controls apply (T24). | Phase 4 |
| K-07 | Price/plan strings shown to a child by mistake (e.g., in a banner). | Copy review checklist: no prices outside gated screens (AC-66). | Phase 6 |
| K-08 | Sandbox/test purchases unlocking production content. | Separate RevenueCat projects; `isSandbox` honoured only outside prod (D-26). | Phase 4 |
| K-09 | Webhook or REST key leakage. | Secret Manager only; rotation procedure; never in FlutterFlow or git (T22). | Phase 4 |
| K-10 | Crash reporting capturing purchase details or nicknames. | No custom keys with personal data (P-05, D-18). | Phase 5 |
| K-11 | Regulatory: subscriptions marketed to children / dark patterns. | Paywall is parent-only, plain language, clear cancellation info; no countdowns or scarcity messages **[LEGAL]**. | Phase 6 |

---

## 18. Decisions and unresolved details

| ID | Item | Status / default |
|---|---|---|
| D-03 | Freemium subscription via RevenueCat/FlutterFlow, entitlement `premium_library` | **Confirmed** |
| D-09 | Premium media via SDK path under rules; no tokens | **Confirmed direction** |
| D-19 | Free trial / intro offer | Open — none in MVP |
| D-20 | Product IDs, prices, currencies | Open — **[OWNER]**; placeholders only |
| D-21 | Restore/transfer policy across Firebase accounts | Open — transfer with warning |
| D-22 | Playback speeds | Open — 0.75×, 1×, 1.25× |
| D-23 | Prepared audio source (human vs. generated + reviewed) | Open — generated where no human narration; always reviewed |
| D-24 | Auto-advance default and delay | Open — on in listen mode, 1.5 s |
| D-25 | RevenueCat projects per environment | Open — one non-prod, one prod |
| D-26 | Sandbox entitlements in production rules | Open — ignored in prod |
| D-27 | Progress writes for premium stories without entitlement | Open — allowed |
| D-28 | Apple Family Sharing on the products | Open — not enabled in MVP |
| — | Android "voice data installed" detection approach | **[UNRESOLVED]** — decide after plugin evaluation in Phase 3 |
| — | Native pause/resume support for TTS per platform | **[UNRESOLVED]** — sentence-level fallback is the design floor |
| — | `ttsPreferredLocales` in `appConfig.playback` | **[UNRESOLVED]** — add if engine selection proves inconsistent |
| — | Whether FlutterFlow's RevenueCat integration performs `logIn(uid)` / `logOut()` | **[VERIFY]** in Phase 4 |
| — | Offline allowance duration for cached premium content | **[ASSUMPTION]** 7 days |
