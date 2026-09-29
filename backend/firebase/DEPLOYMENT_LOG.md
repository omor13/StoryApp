# Firestore deployment log

Every production deployment of `firestore.rules` and `firestore.indexes.json`
from this directory, newest first. Rules and indexes only — nothing in this
directory deploys Functions, Hosting, Storage or Realtime Database.

No credentials, tokens or debug logs belong in this file.

---

## 2026-09-29T09:55:20Z — 2026-09-29T09:55:31Z — first production deployment

### Target

| | |
|---|---|
| Firebase project | `kid-story-app-vel697` (KidStoryApp) |
| Project number | 503625555017 |
| Database | `(default)` — FIRESTORE_NATIVE, STANDARD edition |
| Region | `eur3` |
| Delete protection | `DELETE_PROTECTION_DISABLED` (pre-existing; unchanged) |
| Point-in-time recovery | `POINT_IN_TIME_RECOVERY_DISABLED` (pre-existing; unchanged) |

### What was deployed

| | |
|---|---|
| Git commit | `e09e52f45a5533e6f6f7d97494bf8c64b05c0418` (`e09e52f`), working tree clean |
| Config | `backend/firebase/firebase.json` — declares `firestore` only |
| Rules | `backend/firebase/firestore.rules`, 13,621 bytes |
| Rules SHA-256 | `3f287e040bddd35c05fd17901e6290a285a59594cf6c7334a1e0d761c5cabb8b` |
| Indexes | `backend/firebase/firestore.indexes.json`, 4,151 bytes |
| Indexes SHA-256 | `557ab1e0a309fe4194b2ab2cb17ee1d04f2b507aaecc85d39e1dd38e6c3c63da` |

### Toolchain

| | |
|---|---|
| Java | OpenJDK 21.0.12.1 (Temurin-21.0.12.1+1 LTS) |
| Firebase CLI | 15.28.2 |
| Authenticated as | the project owner account (see `firebase login:list`) |

### Pre-deployment verification

- **Emulator suite: 77 tests, 77 passing, 0 failing**, run against
  `firestore.rules` as committed, under the offline project id
  `demo-kids-stories-rules`. Zero `Property admin is undefined` warnings; the
  five remaining rule-evaluation errors all belong to requests that were denied
  anyway.
- `firebase deploy --only firestore --dry-run` compiled the rules successfully
  and resolved both paths inside `backend/firebase`.
- No blanket `allow` rule and no `match /{document=**}` allow rule.
- The FlutterFlow export's `firebase/firestore.rules` — fully permissive, 43
  occurrences of `if true` — was **not** referenced. Its sibling
  `firebase.json` additionally declares `functions`, `storage` and `hosting`,
  which is why deployment never runs from that directory.
- Android `google-services.json` and iOS `GoogleService-Info.plist` both name
  `kid-story-app-vel697` / 503625555017.
- No `.firebaserc` exists anywhere in the repository, so `--project` was passed
  explicitly and no global active project was set or changed.

### Pre-deployment state

Captured to the gitignored directory
`backend/firebase/backups/predeploy-20260929T095417Z/`.

- **Composite indexes before deployment: 0.** Field overrides: 0. The
  deployment could therefore only add indexes; nothing was eligible for
  deletion and the CLI proposed none.
- **Deployed rules source: not retrievable.** `firebase-tools` 15.28.2 exposes
  no command that reads the deployed Firestore Rules source or the current
  release identifier — the `firestore` subcommands are `delete`, `bulkdelete`,
  `indexes`, `locations`, `operations`, `databases` and `backups`. The
  documented Rules REST API would need an OAuth token; `gcloud` is not
  installed on this machine, and the only other token is inside the Firebase
  CLI's private credential store, which this deployment would not touch. No
  release identifier was obtainable. See `RULES_RETRIEVAL.md` in that
  directory.

This is not a rollback risk: **Firebase retains every previous Rules release**,
and earlier rulesets can be inspected and re-released from the Firebase console
under *Firestore Database → Rules → history*.

### Command

Run from `backend/firebase`, using the repo-owned `firebase.json` in that
directory:

```
firebase deploy --only firestore --project kid-story-app-vel697
```

No `--force`. No `firebase init`. No sub-targets.

### Outcome: success

The CLI reported, in order:

```
i  deploying firestore
+  cloud.firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
i  firestore: deploying indexes...
+  firestore: deployed indexes in firestore.indexes.json successfully for (default) database
+  firestore: released rules firestore.rules to cloud.firestore
+  Deploy complete!
```

**Rules release ID: not available.** The CLI confirms the release
(`released rules firestore.rules to cloud.firestore`) but does not print a
ruleset or release identifier, and no supported command retrieves one.

### Index states

All 11 intended composite indexes are present in production and match the
repository definitions exactly — same collection group, same fields, same
order/array configuration — with no unexpected index live. Firestore appends an
implicit `__name__` tiebreaker to every composite index; that is automatic and
is not written in `firestore.indexes.json`.

| ID | Collection | Fields | State |
|---|---|---|---|
| I-1 | `stories` | status ↑, sortOrder ↑ | READY |
| I-2 | `stories` | status ↑, ageGroups (contains), sortOrder ↑ | READY |
| I-3 | `stories` | status ↑, categoryIds (contains), sortOrder ↑ | READY |
| I-4 | `stories` | status ↑, publishedAt ↓ | READY |
| I-5 | `progress` | ownerUid ↑, childId ↑, completed ↑, updatedAt ↓ | READY |
| I-6 | `categories` | isActive ↑, sortOrder ↑ | READY |
| I-7 | `stories` | status ↑, accessLevel ↑, sortOrder ↑ | READY |
| I-8 | `favorites` | ownerUid ↑, childId ↑, storyId ↑ | READY |
| I-9 | `progress` | ownerUid ↑, childId ↑, storyId ↑ | READY |
| I-10 | `progress` | ownerUid ↑, childId ↑, completed ↑ | READY |
| I-11 | `favorites` | ownerUid ↑, childId ↑, createdAt ↓ | READY |

All 11 reached **READY**. They were `CREATING` at deploy time and finished
building roughly three minutes later, verified at 2026-09-29T10:00Z by
`firebase firestore:indexes --project kid-story-app-vel697 --database "(default)"`,
compared field-by-field against `firestore.indexes.json`. No index is in
`ERROR`, and none is `MISSING`.

### Rollback

1. **Rules.** Firebase console → Firestore Database → Rules → history. Select
   the previous release and re-publish it. Alternatively, check out the earlier
   commit of `backend/firebase/firestore.rules` and re-run the deploy command
   above — that is the reliable path, since the repository is the source of
   truth for everything deployed here.
2. **Indexes.** Composite indexes are additive and do not change query results,
   only which queries are servable, so rolling them back is rarely necessary.
   To remove one, delete it in the Firebase console, or remove it from
   `firestore.indexes.json` and deploy — the CLI will then prompt before
   deleting anything, and that prompt must be answered deliberately.
3. **Blast radius.** No document data was read, written or deleted, so there is
   nothing to restore.

### Explicitly not changed

No production **data** was created, modified or deleted. No **Authentication**
configuration, provider or user. No **Storage** bucket or rules. No **Cloud
Functions**. No **billing** change — the project stays on its existing plan, and
nothing deployed here requires Blaze. No **region** change. No **schema** or
seed data. No **UI** or FlutterFlow project change. The FlutterFlow-generated
permissive rules were not deployed. The deployment touched exactly two things:
the Firestore rules release and the Firestore composite index set.
