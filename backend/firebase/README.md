# backend/firebase — repo-owned Firestore rules and indexes

**Authoritative** Firestore security rules and composite indexes for Kids Stories
(FlutterFlow project `kid-story-app-vel697`).

---

## ⚠️ Do not deploy the FlutterFlow export's rules

The FlutterFlow code export contains its own `firebase/firestore.rules`. **It is
generated, fully permissive, and must never be deployed.** As exported it reads:

```
match /entitlements/{document} {
  allow create: if true;  allow read: if true;
  allow write:  if true;  allow delete: if true;
}
match /{path=**}/children/{document} { allow read: if true; }
```

Every collection is `if true`, including `entitlements` — which must never be
client-writable — plus collection-group reads that `FIREBASE_SCHEMA.md` §13
explicitly forbids.

Three things follow:

1. **FlutterFlow will regenerate that file** every time collections change, and
   it will keep being permissive. Never copy it here, never deploy it.
2. **Keep FlutterFlow's own rules deployment switched off** in project settings.
3. **Always deploy with this directory's `firebase.json`**, which points only at
   the two repo-owned files beside it — never from the export directory and
   never from the repository root.

## 🚩 Deployment status: NONE

**No Firebase deployment has been performed.** No rules, no indexes, no schema,
no data. Everything here is reviewed-but-undeployed. Until it is deployed,
whatever is live in the Firebase console still governs the database — if that is
still test mode, treat the database as unprotected and keep real user data out
of it.

## Deploying (when authorised)

Run from this directory. Requires the Firebase CLI and a selected project.

```
cd backend/firebase
firebase deploy --only firestore:rules,firestore:indexes --project <your-project-id>
```

Rules and indexes only. Nothing here needs Blaze billing; there are no Cloud
Functions in this task.

Dry-run the rules first if you want a syntax check without deploying:

```
firebase deploy --only firestore:rules --project <your-project-id> --dry-run
```

## Files

| File | Purpose |
|---|---|
| `firestore.rules` | Deny-by-default security rules. Authoritative. |
| `firestore.indexes.json` | The 11 composite indexes below. |
| `firebase.json` | Points **only** at the two files above, by relative path. |

## Index map

Each index names the query it serves; none is speculative. **I-8 and I-9 are
lookup indexes for Q10/Q11 — they do not enforce uniqueness; the deterministic
document ID does.** IDs match
[`docs/FIREBASE_SCHEMA.md`](../../docs/FIREBASE_SCHEMA.md) §14 and the queries
in §13.

| ID | Collection | Fields | Serves |
|---|---|---|---|
| I-1 | `stories` | status, sortOrder | Q2 library, published ordered |
| I-2 | `stories` | status, ageGroups (contains), sortOrder | Q3 library by age group |
| I-3 | `stories` | status, categoryIds (contains), sortOrder | Q4 library by category |
| I-4 | `stories` | status, publishedAt ↓ | Q5 newest stories |
| I-7 | `stories` | status, accessLevel, sortOrder | Q14 free shelf / premium shelf |
| I-5 | `progress` | ownerUid, childId, completed, updatedAt ↓ | Q7 continue reading |
| I-9 | `progress` | ownerUid, childId, storyId | Q11 story detail + progress lookup (§6.2) |
| I-10 | `progress` | ownerUid, childId, completed | Q8 completed badges |
| I-11 | `favorites` | ownerUid, childId, createdAt ↓ | Q9 favourites shelf |
| I-8 | `favorites` | ownerUid, childId, storyId | Q10 is-favourite + favourite upsert probe (§5.1) |
| I-6 | `categories` | isActive, sortOrder | Q13 active categories |

**Why the `favorites` / `progress` indexes lead with `ownerUid`:** ADR-01
flattened both to top-level because FlutterFlow supports only one subcollection
level. The path no longer scopes a query to one parent, so the rules require an
`ownerUid` equality filter on every read — and an index that starts with
`ownerUid` is what makes those queries servable.

## Security model in one paragraph

Deny by default; no `match /{document=**}` allow rule exists. `users/**` is
owner-only by path. `favorites` and `progress` are owner-only **by field**:
rules check `ownerUid == request.auth.uid` on read and write, pin `ownerUid`
across updates, and cross-validate `childRef` / `storyRef` against the id fields
so a row cannot be pointed at another parent's child or a different story.
Stories are readable only when `status == "published"`; story pages only when
the story is also `accessLevel == "free"`. **Premium pages are denied to all
ordinary clients** — the entitlement mirror is not yet server-written, so there
is nothing trustworthy to check, and the commented-out clause in
`firestore.rules` must stay commented until a Cloud Function writes that mirror.
`entitlements/**` is never client-writable; the audit trail is not client-
readable at all. Writes to `stories`, `categories` and `appConfig` require an
`admin` custom claim that no client is issued.

## Related documents

- [`docs/FIREBASE_SCHEMA.md`](../../docs/FIREBASE_SCHEMA.md) — collections, fields, ADR-01, queries, indexes
- [`docs/FIREBASE_SECURITY_PLAN.md`](../../docs/FIREBASE_SECURITY_PLAN.md) — principles and open decisions
- [`backend/firebase/tests/`](tests/) — emulator rule tests
