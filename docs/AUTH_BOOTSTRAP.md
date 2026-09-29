# Anonymous auth bootstrap and child onboarding

How a parent gets a Firebase identity and a child profile, what the DSL could
author, and what must still be done by hand in the FlutterFlow editor.

FlutterFlow project `kid-story-app-vel697` · Firebase project
`kid-story-app-vel697` · Firestore `(default)` in `eur3`.

---

## 1. Why two pages

FlutterFlow navigates a successfully authenticated user to its configured
**Logged In Page** automatically. Putting the anonymous sign-in on HomePage
would fire that redirect the moment sign-in succeeded and **skip child
onboarding entirely**. So the two jobs are split:

| Page | Role | Requires auth |
|---|---|---|
| `AuthEntryPage` | Logged-out **Entry Page**. Signs in anonymously, then lets FlutterFlow redirect. | **No** |
| `AppBootstrapPage` | **Logged In Page**. Reads the parent's children and routes. | Yes |

```
AuthEntryPage ──anonymous sign-in──▶ AppBootstrapPage
                                          │
                        no children ──────┼────── one or more children
                                          │
                                     HomePage            StorySelectionPage
                                   (onboarding)
```

Loop safety: `AuthEntryPage` is never the Logged In Page, `AppBootstrapPage`
never routes back to `AuthEntryPage`, `HomePage` performs no sign-in of its
own, and `StorySelectionPage` is not the automatic Logged In Page.

---

## 2. Editor-only steps — REQUIRED

These could not be authored through the FlutterFlow AI SDK. Each was verified
against the SDK, not assumed; §5 records how.

### 2.1 Enable the Anonymous provider ⚠️ blocking

Firebase Console → **Authentication** → **Sign-in method** → **Anonymous** →
Enable → Save.

Change no other provider. Do not enable email, phone, Google or Apple.

This could not be verified programmatically: `firebase-tools` 15.28.2 exposes
only `auth:export` / `auth:import` (which read *accounts*, not provider
configuration), and the Firebase MCP server was not reachable in the session
that built this. Until it is enabled, `LoginAnonymously()` fails and
`AuthEntryPage` shows its Arabic retry state — which is the correct, safe
failure.

### 2.2 Set the Parent Document Reference on the children query ⚠️ blocking

**AppBootstrapPage** → page-load action **Query a collection (children)** →
**Parent Document Reference** → `Authenticated User` → `Document Reference`.

Repeat on the `bootstrapRetryButton` **On Tap** query.

**Why this matters more than it looks.** `FirestoreQuery` in the DSL takes no
parent. The generated helper is:

```dart
static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
    parent != null
        ? parent.collection('children')
        : FirebaseFirestore.instance.collectionGroup('children');
```

So an unparented query becomes a **collection-group query**, which the
deployed rules deny for every non-admin:

```
match /{path=**}/children/{childId} { allow read, write: if isAdmin(); }
```

There is already a passing emulator test for that denial. Until the parent is
set, bootstrap fails closed — no data leak, but the app cannot get past
`AppBootstrapPage`. That is why its retry button is always visible.

### 2.2b Set the age DropDown options

**HomePage** → the age `DropDown` (`DropDown_jb86mjhm`) still carries
FlutterFlow's placeholder options `['Option 1','Option 2','Option 3']`. Set
them to the three canonical `ageGroup` values with Arabic labels:

| Value | Label |
|---|---|
| `1-2` | سنة إلى سنتين |
| `3-4` | ٣ إلى ٤ سنوات |
| `5-6` | ٥ إلى ٦ سنوات |

`EditWidgetPatch` has no `options` / `optionsLabels` method, so this cannot be
authored. Until it is done, onboarding writes a placeholder string into
`children.ageGroup`, which no `ageGroup` consumer will match.

### 2.3 Mark pages as requiring authentication

Page settings → **Requires Authentication**, on:

`AppBootstrapPage`, `HomePage`, `StorySelectionPage`, `StoryReaderPage`,
`FavoritesPage`, `setting`, `subscription`, `subscription1months`,
`subscription3months`, `subscription1year`.

**Leave `AuthEntryPage` unchecked.**

### 2.4 Populate `selectedChildId` from the created child

**HomePage** → `startAdventureButton` On Tap → after **Create Document
(children)** → add **Update App State** → `selectedChildId` ← the created
document's **Document ID** (`Action Output > createdChild > Document ID`),
before the navigation action.

The DSL cannot express this: document-field access requires a generated field
handle, and `id` / `reference` are not schema fields, so
`ActionOutput('createdChild')['id']` is rejected at compile time with
`resolveProjectFieldName: Expected a generated FlutterFlow field handle`.

### 2.5 Restore the selected child on bootstrap

**AppBootstrapPage**, in the "has children" branch, before navigating:

1. **Update App State** → `selectedChildId` ← `bootstrapChildren > Item at
   Index 0 > Document ID`.
2. **Update App State** → `Name` ← `bootstrapChildren[0] > nickname`.
3. **Update App State** → `age` ← `bootstrapChildren[0] > ageGroup`.
4. **Update App State** → `selectedAvatarId` ← `bootstrapChildren[0] >
   avatarId`. This is what restores the ولد / بنت card highlight — see §6.

The DSL has no list-index expression, so none of this is authorable.

**On retaining the previous `selectedChildId`:** the DSL has no list-membership
test either, so "keep it if it is still one of this user's children" cannot be
authored. Taking item 0 of the parent-scoped query is the safe fallback — it
never trusts local state. If you want retention, do it in the editor with a
conditional comparing `selectedChildId` against the query result, and keep the
rule that an unverified id is discarded rather than used.

---

## 3. What the code does today

### App state

| Field | Type | Persisted | Purpose |
|---|---|---|---|
| `selectedChildId` | String | yes | Firestore document ID of the active child. Empty by default. Cleared when the parent has no children. **Never an authorization input.** |
| `selectedAvatarId` | String | yes | Canonical `avatar_NN` for the active child. Mirrors that child's `avatarId`. Drives the ولد / بنت card highlight — see §6. |
| `Name`, `age` | String | yes | Pre-existing, kept for the existing HomePage UI. |
| `gender` | String | yes | Pre-existing and now **unused**. Never written to Firestore. See §6. |

### AuthEntryPage

Page state `phase`: `loading` while an attempt is in flight, `failed` after a
failure.

On load: if a uid already exists, replace-navigate to `AppBootstrapPage`;
otherwise set `phase = loading`, run `LoginAnonymously()`, and set
`phase = failed` if there is still no uid afterwards.

That last check is the failure detector. FlutterFlow catches
`FirebaseAuthException` inside `_signInOrCreateAccount`, shows its own
snackbar and returns `null` — a failed sign-in never throws into the action
chain, so "did a uid appear?" is the only reliable signal.

**Double-submit guard:** the retry body is wrapped in
`If(Equals(phase, 'failed'))` and its first action sets `phase = loading`.
Repeated taps after the first cannot start a second sign-in.

Arabic strings: `جارٍ تجهيز عالم الحكايات...`, retry `إعادة المحاولة`, error
`تعذّر الاتصال. تحقّق من الإنترنت وحاول مرة أخرى.`

### AppBootstrapPage

Queries `children` ordered by `createdAt`, limit **5** — matching
`appConfig.maxChildrenPerParent` (D-07 default). `createdAt` is the only
ordering field the children schema defines.

`Count(...) == 0` → clear `selectedChildId`, replace-navigate to HomePage.
Otherwise replace-navigate to StorySelectionPage.

Arabic strings: `جارٍ تحميل ملف الطفل...`, failure `حدث خطأ أثناء تحميل الملف.`,
retry `إعادة المحاولة`.

---

## 3b. The ولد / بنت cards are an avatar picker

**No gender field is written to Firestore, ever.** The privacy decision in
[`FIREBASE_SCHEMA.md`](FIREBASE_SCHEMA.md) §4 stands: gender is on the explicit
not-stored list, beside birth date, real name, photo, school and location.

The two cards persist through **`children.avatarId`** instead:

| Card | `avatarId` |
|---|---|
| ولد | `avatar_01` |
| بنت | `avatar_02` |

**Why these IDs and not `child_boy_01` / `child_girl_01`.** Canonical avatar IDs
already exist: `FIREBASE_SCHEMA.md` §4 requires
`^avatar_(0[1-9]|1[0-2])$`, `ARCHITECTURE.md` documents twelve bundled avatars
`avatar_01`…`avatar_12`, and `SECURITY_AND_PRIVACY.md` §121 specifies an
`isValidAvatar` rule validator against that same pattern. A `child_boy_01`
value would be accepted by the rules deployed today — they do not yet validate
child fields — and would start failing the moment that validator ships, with
the bad values already in the database. The fallback IDs are therefore not
used; the mapping is recorded in `FIREBASE_SCHEMA.md` §4.1.

What is written is an **artwork identifier**, not a declared gender: two
children who pick the same card are indistinguishable in the data, and nothing
in Firestore says which card is "for" whom.

**Per child, `avatarId` is authoritative.** A parent with three children has
three `avatarId` values, one per document. Nothing about the selection lives
outside those documents, so there is no shared or remembered value to go stale.

**State handling.** HomePage keeps the live choice in page state
`selectedAvatarId` (it had none before — the cards were entirely static, with
no tap action). On create it is written straight to `children.avatarId`; on
bootstrap it is read back from the selected child's `avatarId`. The pre-existing
`gender` app-state field is left in place so nothing that might reference it
breaks, but it is **no longer read or written**, and it never reaches Firestore.

## 4. The user document

`autoCreateUserDocument: true` with `userCollectionName: 'users'`, so
FlutterFlow writes `users/{currentUserUid}` on first sign-in through
`createUsersRecordData()`, which emits **only fields present in the schema**
and drops nulls.

For an anonymous user there is no email, display name, photo or phone, so the
document is:

```json
{ "uid": "<uid>", "created_time": "<server timestamp>" }
```

`photo_url` and `phone_number` are not in the `users` schema at all, so
FlutterFlow never writes them.

**This is accepted by the deployed rule.** `users/{uid}` create requires
`isOwner(uid)` and that the payload carries none of
`premiumActive, entitlement, entitlementId, isPremium, subscription,
accessExpiresAt, admin, role, claims`. A `{uid, created_time}` document at
`users/{uid}` satisfies both. **No rules change is required**, and none was
made. The emulator suite pins this with a test that writes the exact payload.

---

## 4b. Three traps found by reading the exported Dart

Each of these compiled and pushed cleanly, and each was wrong. The DSL is
intent; the generated Dart is what runs.

**1. `ensureFirebaseAuth` silently kept the old routing.** Firebase auth was
already configured on this project (with zero providers), and `ensure*` is
idempotent — so the call no-opped and the project stayed on
`homePage: StorySelectionPage, signInPage: HomePage`. The push reported
success. Only the next compile surfaced it:

```
LoginAnonymously() requires auth provider ANONYMOUS.
Active auth backend: Firebase.
```

`app.firebaseAuth(...)` **updates** an existing configuration; `ensure…` skips
it. The same applies to `app.ensurePage`: once a page exists, edits to its body
must go through `app.editPage`, not a re-run of `ensurePage`.

**2. A failed sign-in cannot be observed by later actions.** FlutterFlow emits

```dart
final user = await authManager.signInAnonymously(context);
if (user == null) { return; }
```

so everything after a login action is skipped precisely when sign-in fails.
The first version set `phase = 'failed'` after `LoginAnonymously()` — dead
code. Worse, any pessimistic "attempt in flight" flag **deadlocks**: nothing
can reset it after a failure, so a retry gated on it could never fire. The
retry control is therefore unconditional and guarded on *"there is still no
uid"*, which self-clears.

Residual risk: two taps in the same instant can start two sign-ins, since the
guard is not a lock. The cost is a stray empty anonymous account, not data
loss. A page-state lock is not usable here for the reason above.

**3. An unparented subcollection query is a collection-group query** — §2.2.

## 5. SDK capability audit

Verified by compiling against the SDK, not by reading signatures.

| Capability | Result |
|---|---|
| Create pages (`app.ensurePage`, with `state:` / `onLoad:`) | supported |
| Anonymous sign-in (`LoginAnonymously()`) | supported |
| `FirebaseAuthProvider.anonymous` | supported |
| Entry / Logged In page (`app.ensureFirebaseAuth(signInPage:, homePage:)`) | supported |
| Create User Document (`autoCreateUserDocument:`, `userCollectionName:`) | supported |
| Conditional actions (`If` / `Equals` / `Not` / `Count`) | supported |
| Replace/clear-stack nav (`Navigate(replaceRoute: true, allowBack: false)`) | supported |
| Persisted String app state (`app.state(..., persisted: true)`) | supported |
| Subcollection **create** (`FirestoreCreate(parentReference:)`) | supported |
| Document field read via generated field handle | supported |
| **Subcollection query parent reference** | **not supported** — `FirestoreQuery` has no `parentReference`; §2.2 |
| **List index access** (`ActionOutput(list)[0]`) | **not supported** — §2.5 |
| **Document `id` / `reference` off an action output** | **not supported** — needs a generated field handle; §2.4 |
| **Per-page Requires Authentication** | **not supported** — `app.setPageRequiresAuth` is not on `App`, and the brownfield helper is not exported; §2.3 |

Conditions are limited to `Equals` and `Not`; there are no comparison or
boolean-combination operators, which is why every branch above is an equality
test.

---

## 6. Anonymous-identity lifecycle ⚠️

**Logout stays disabled, deliberately.** An anonymous UID is held only by the
install. Signing out discards the only handle on it, and the parent's
children, favourites, progress and entitlements become permanently
unreachable. Anonymous users must not be offered a logout control.

The same risk exists without logout:

- **Clearing app data or uninstalling before the account is linked loses the
  anonymous UID**, and with it every child profile, favourite, progress row and
  entitlement. There is no recovery path.
- The anonymous identity is **per-install**. It cannot sync across a parent's
  devices.

When a permanent login is added later:

- It must use **credential linking** (`linkWithCredential`) on the existing
  anonymous user — **never** a fresh sign-in, which would mint a new UID and
  orphan everything under the old one.
- Linking must preserve the UID, and therefore `users/{uid}`,
  `users/{uid}/children/**`, and every `favorites` / `progress` row whose
  `ownerUid` is that UID, plus `entitlements/{uid}`.
- Because `favorites` and `progress` are keyed `{ownerUid}_{childId}_{storyId}`
  (ADR-01), a UID change would also invalidate every document ID, not just the
  ownership field.

**Subscriptions.** Before anything is sold, purchasing needs a restore/link
strategy: an entitlement bought on an anonymous UID is stranded if the install
is lost. The link-to-permanent-account path should land **before** launch, and
RevenueCat's user identity must be re-aliased to the same UID at link time.

Not implemented in this task, and deliberately unchanged: account linking,
entitlement rules, premium page access.

---

## 7. Related documents

- [`FIREBASE_SCHEMA.md`](FIREBASE_SCHEMA.md) — `users` §3, `children` §4
- [`FIREBASE_SECURITY_PLAN.md`](FIREBASE_SECURITY_PLAN.md) — rules and principles
- [`../backend/firebase/DEPLOYMENT_LOG.md`](../backend/firebase/DEPLOYMENT_LOG.md) — what is live
