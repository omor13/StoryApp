# Kids Stories — Firestore Security & Index Plan

| | |
|---|---|
| Status | Draft v0.1 — **prepared, not deployed.** Written 2026-09-27 alongside the Firestore schema work in FlutterFlow project `kid-story-app-vel697`. |
| Scope | Firestore rules and composite indexes only. Storage rules, Cloud Functions, and the RevenueCat webhook are explicitly out of scope. |
| Source of truth | [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) — §12 ownership, §13 queries, §14 indexes. [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md). [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) §5 entitlement model. |
| Firebase project | `kid-story-app-vel697`. Android `google-services.json` and iOS `GoogleService-Info.plist` both point at it; package and bundle identifier both `com.mycompany.kidstoryapp`. |
| Firestore database | `(default)`, FIRESTORE_NATIVE, STANDARD edition, **location `eur3`** (Europe multi-region), created 2026-09-25. Retrieved read-only via `firebase firestore:databases:get`. The location is permanent. |
| Contains no secrets | No credentials, API keys, or Firebase config-file contents appear in this document, by policy. |

---

## 1. Deployment status

**Nothing in this document is deployed.** Rules live here as a plan until:

1. The premium-access half can be enforced — which requires the server-written `entitlements/{uid}` mirror, which requires Cloud Functions, which requires Blaze billing. None of these exist yet.
2. The owner deploys `firestore.rules` and `firestore.indexes.json` from a `backend/` directory using the Firebase CLI.

FlutterFlow's own rules deployment stays **off** — rules are owned by the repository, not the builder.

> **Resolved 2026-09-29: Firestore is no longer in test mode** — the rules below are deployed and govern the database. The original warning, kept for context: test mode grants blanket read/write to any authenticated (or even unauthenticated) caller and expires silently.

---

## 2. Principles

| # | Principle |
|---|---|
| P-01 | **Deny by default.** No `match /{document=**}` allow rule at any level. Every collection is enumerated explicitly. |
| P-02 | A parent reaches only their own `users/{uid}` document and everything beneath it. |
| P-03 | A child profile belongs to exactly one owning user; ownership is proven by the path, never by a field. |
| P-04 | Favourites and progress inherit the same single-owner rule from their path. |
| P-05 | **A client can never grant itself a subscription or entitlement.** No premium flag exists on any client-writable document. |
| P-06 | Story writes require an admin claim, which no client has. Content arrives via the Admin SDK. |
| P-07 | `draft` and `archived` stories are not readable by any client. |
| P-08 | Published story *metadata* is readable by authenticated users (needed for the lock badge on premium covers). |
| P-09 | Free story *pages* are readable by authenticated users. |
| P-10 | **Premium story pages stay denied** until server-managed entitlement verification exists. Locked is the correct behaviour today, not a gap. |
| P-11 | `entitlements/**` is never client-writable. `entitlements/{uid}` is owner-readable; `entitlements/{uid}/events/**` has no client access at all. |

---

## 3. Rules

> **The authoritative rules now live in [`backend/firebase/firestore.rules`](../backend/firebase/firestore.rules).** The listing below is the design rationale; the file is what gets deployed. If the two ever disagree, the file wins and this section should be corrected.

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ---- helpers ---------------------------------------------------------
    function isSignedIn() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }
    // No client holds this claim. Content is written with the Admin SDK.
    function isAdmin() {
      return isSignedIn() && request.auth.token.admin == true;
    }
    function storyIsPublished(storyId) {
      return get(/databases/$(database)/documents/stories/$(storyId))
               .data.status == 'published';
    }
    function storyIsFree(storyId) {
      return get(/databases/$(database)/documents/stories/$(storyId))
               .data.accessLevel == 'free';
    }

    // ---- parent account --------------------------------------------------
    match /users/{uid} {
      allow read:   if isOwner(uid);
      allow create: if isOwner(uid);
      // Reject any attempt to introduce a premium/subscription key (P-05).
      allow update: if isOwner(uid)
                    && !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['premiumActive', 'entitlement', 'entitlementId',
                                  'isPremium', 'subscription', 'accessExpiresAt']);
      allow delete: if false;   // account deletion is a server-side flow

      match /children/{childId} {
        allow read, write: if isOwner(uid);

        match /favorites/{storyId} {
          allow read, write: if isOwner(uid);
        }

        match /progress/{storyId} {
          allow read, write: if isOwner(uid);
        }
      }
    }

    // ---- story catalogue -------------------------------------------------
    match /stories/{storyId} {
      // P-07 / P-08: published metadata only, never drafts or archives.
      allow read:  if isSignedIn() && resource.data.status == 'published';
      allow write: if isAdmin();

      match /pages/{pageId} {
        // P-09 free pages readable; P-10 premium pages DENIED for now.
        //
        // When the entitlement mirror goes live, extend this with:
        //   || (storyIsPublished(storyId)
        //       && exists(/databases/$(database)/documents/entitlements/$(request.auth.uid))
        //       && get(/databases/$(database)/documents/entitlements/$(request.auth.uid)).data.premiumActive == true
        //       && get(/databases/$(database)/documents/entitlements/$(request.auth.uid)).data.accessExpiresAt > request.time)
        // Do NOT add that clause before the mirror is server-written.
        allow read:  if isSignedIn()
                     && storyIsPublished(storyId)
                     && storyIsFree(storyId);
        allow write: if isAdmin();
      }
    }

    // ---- reference data --------------------------------------------------
    match /categories/{categoryId} {
      allow read:  if isSignedIn();
      allow write: if isAdmin();
    }

    match /appConfig/{configId} {
      allow read:  if isSignedIn();
      allow write: if isAdmin();
    }

    // ---- subscription mirror (server-written only) ------------------------
    match /entitlements/{uid} {
      allow read:   if isOwner(uid) || isAdmin();   // display only
      allow create, update, delete: if false;       // P-11, Admin SDK only

      match /events/{eventId} {
        allow read, write: if false;                // no client access at all
      }
    }
  }
}
```

### Notes on the rules

- **`accessExpiresAt` is checked against `request.time`**, so a stale mirror cannot extend access (FIREBASE_SCHEMA.md §11).
- The `update` guard on `users/{uid}` is belt-and-braces for P-05: even if a field were added to the schema later, a client cannot set it.
- `storyIsPublished` / `storyIsFree` each cost a document read per page query. §13 accounts for this: one query per story open plus the rule reads.
- No collection-group rules are defined, so child and entitlement data is never queryable across parents (§13).

---

## 4. Index plan

Index IDs match [FIREBASE_SCHEMA.md §14](FIREBASE_SCHEMA.md); the deployable
file is [`backend/firebase/firestore.indexes.json`](../backend/firebase/firestore.indexes.json).
Every index names the query it serves — none is speculative.

| ID | Collection | Fields | Serves (§13) |
|---|---|---|---|
| I-1 | `stories` | status, sortOrder | Q2 library, published ordered |
| I-2 | `stories` | status, ageGroups CONTAINS, sortOrder | Q3 by age group |
| I-3 | `stories` | status, categoryIds CONTAINS, sortOrder | Q4 by category |
| I-4 | `stories` | status, publishedAt DESC | Q5 newest |
| I-7 | `stories` | status, accessLevel, sortOrder | Q14 free / premium shelves |
| I-5 | `progress` | ownerUid, childId, completed, updatedAt DESC | Q7 continue reading |
| I-9 | `progress` | ownerUid, childId, storyId | Q11 story detail + lookup (§6.2) |
| I-10 | `progress` | ownerUid, childId, completed | Q8 completed badges |
| I-11 | `favorites` | ownerUid, childId, createdAt DESC | Q9 favourites shelf |
| I-8 | `favorites` | ownerUid, childId, storyId | Q10 is-favourite + upsert probe (§5.1) |
| I-6 | `categories` | isActive, sortOrder | Q13 active categories |

**Changed by ADR-01.** I-5 was `completed, updatedAt DESC` on the nested
`progress` subcollection, where the path scoped the query to one child.
Flattening removed that scoping, so every `favorites` / `progress` index now
leads with `ownerUid, childId`. I-8 to I-11 are new: I-8/I-9 back the
lookup queries Q10/Q11 (they do NOT enforce uniqueness — the deterministic
document ID does), and I-10/I-11 replace what used to be automatic single-field indexes on the
nested collections. I-8 and I-9 are **lookup indexes only** — uniqueness comes
from the deterministic document ID, not from a query.

**I-12 was removed (2026-09-29).** It proposed a composite index on `events`
with the single field `eventAt DESC`. Firestore composite indexes require at
least two fields, so that definition is invalid and would be rejected on
deploy. The intended query is **parent-scoped** — `entitlements/{uid}/events`
ordered by `eventAt desc` for one parent, read by admin tooling through the
Admin SDK — and a parent-scoped single-field sort is served by Firestore's
**automatic single-field index**. No custom index is needed. A collection-group
index across all parents' events is deliberately **not** created (§13), so the
audit trail can never be queried across accounts.


**I-12 was removed (2026-09-29).** It proposed a composite index on `events`
with the single field `eventAt DESC`. Firestore composite indexes require at
least two fields, so that definition is invalid and would be rejected on
deploy. The intended query is **parent-scoped** —
`entitlements/{uid}/events` ordered by `eventAt desc` for one parent, read by
admin tooling through the Admin SDK — and a parent-scoped single-field sort is
served by Firestore's **automatic single-field index**. No custom index is
needed. A collection-group index across all parents' events is deliberately
**not** created (§13), so the audit trail can never be queried across accounts.


Still served by automatic single-field indexes — **do not create composites**:
Q1 children by `createdAt`, Q12 pages by `pageNumber`.

**Deployment status: none created.**

Optional, from §14: consider single-field index exemptions for `displayTextAr`
and `ttsTextAr` on `pages` — large strings that are never queried.

---

## 5. ADR-01 — favorites and progress were flattened

`favorites` and `progress` were originally specified three levels deep
(`users/{uid}/children/{childId}/…`). FlutterFlow supports only one level of
subcollection nesting, so that shape could not be modelled at all. Both are now
**top-level collections** carrying explicit ownership fields — see ADR-01 in
[FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) §2.

The security consequence is the important part: **ownership used to be implied
by the path and is now a client-supplied field.** The rules therefore have to
do work the path used to do for free. For both collections every rule checks:

1. `ownerUid == request.auth.uid` — on read, create and update.
2. `ownerUid` is unchanged across updates (no transferring a row).
3. `childRef == /users/{request.auth.uid}/children/{childId}` **and** that child exists — so a row cannot point at another parent's child.
4. `storyRef == /stories/{storyId}` — the reference and the id field agree.

`progress` additionally validates the value semantics of
[`FIREBASE_SCHEMA.md`](FIREBASE_SCHEMA.md) §6.1: `0 <= lastPageNumber <= pageCount`
(0 means not started), non-negative counters, `contentVersion > 0`,
`completionPercent` in `0.0 .. 100.0` and 0 when there are no pages,
`completed` true only at 100% and only with a `completedAt`, `lastPlaybackSpeed`
in `0.75 .. 1.25`, `lastMode in ['read','listen']`, and `startedAt` write-once.
Optional fields are validated only when present, because the FlutterFlow schema
marks nothing required.

**Document identity is deterministic.** Both collections use
`{ownerUid}_{childId}_{storyId}` as the document ID, and the rules enforce it:
a create is rejected unless the wildcard ID equals
`request.auth.uid + "_" + childId + "_" + storyId`, and an update must keep the
ID matching its identity fields. That restores the one-row-per-tuple guarantee
the nested path used to provide, without a Cloud Function or custom Dart.

The ID is configured with the **Custom ID** toggle on the Create Document action
in the FlutterFlow Action Flow Editor. That is a FlutterFlow editor capability;
it simply cannot be authored through the current AI SDK, whose `FirestoreCreate`
exposes no document-ID parameter. **Until the UI actions are wired with Custom
ID, the app must not create favorites or progress documents** — an auto-ID write
would now be rejected by the rules, which is the intended safety behaviour.

Query-before-create is a lookup convenience, not the uniqueness mechanism.

Cross-parent isolation also no longer comes from the path — it comes from rule 1
plus indexes that lead with `ownerUid`, so a query without an `ownerUid`
equality filter is rejected rather than returning another parent's rows.

---

## 6. Open decisions

| ID | Question |
|---|---|
| D-26 | Should production rules ignore sandbox entitlements (`isSandbox == true`)? Affects the premium clause added in §3. |
| — | ~~Whether to model `favorites` / `progress` in FlutterFlow~~ — **resolved by ADR-01**: flattened to top-level, created in FlutterFlow 2026-09-28. |
| — | Whether to add a Cloud Function or custom Dart action for transactional favourite/progress upserts, which would restore exact-once identity (§5). |
| — | Admin claim mechanism: custom claim vs an `admins/{uid}` document. `isAdmin()` above assumes a custom claim. |

---

## 7. Verification status

**Rules:** verified by the emulator suite in
[`backend/firebase/tests/`](../backend/firebase/tests/) — **77 tests, all
passing**, last run 2026-09-29 against `firestore.rules` as committed. The suite
covers deny-by-default, owner-by-field access on the two flattened collections,
deterministic document IDs, query-shape enforcement, the §6.1 progress
semantics, premium-page denial, collection-group isolation, and all three states
of the `admin` custom claim (absent, `false`, `true`).

**Optional fields are read through `Map.get` with a default, never through an
`in` guard.** Rules evaluate both operands of `||`, so
`!('x' in data) || data.x >= 0` still evaluates `data.x` on a row that omits
`x`. The verdict is correct — `true || error` is `true` — but the rule is then
allowing a write only because an error was absorbed, and every such request
writes an evaluation error into the audit log. The same reasoning applies to
`isAdmin()`, which reads `request.auth.token.get('admin', false)`.

Running it needs **JDK 21 or newer** — `firebase-tools` 15.x refuses to start
the Firestore emulator on JDK 17. The emulator runs under the offline project id
`demo-kids-stories-rules`, so no test can reach `kid-story-app-vel697`.

**Indexes:** all 11 composite indexes are deployed and READY in production,
matching `firestore.indexes.json` field-for-field. They still carry no
*query-level* verification: composite indexes cannot be exercised by the rules
emulator, and no query has yet run against them. Firestore appends an implicit
`__name__` tiebreaker to every composite index; that is automatic and is not
written in the file.

**Deployment: live.** Rules and indexes were deployed to `kid-story-app-vel697`
(`(default)` database, `eur3`) at 2026-09-29T09:55Z from commit `e09e52f`. The
rules release succeeded and all 11 composite indexes are READY. The database is
no longer in test mode. No data, Auth, Storage, Functions or billing change was
made. See [`backend/firebase/DEPLOYMENT_LOG.md`](../backend/firebase/DEPLOYMENT_LOG.md).

