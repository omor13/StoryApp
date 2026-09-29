# Firestore security-rule tests

Emulator tests for [`../firestore.rules`](../firestore.rules). **Nothing here
deploys anything, and nothing here touches a real Firebase project.**

Status: **70 tests, all passing** (last run 2026-09-29).

## Prerequisites

| Requirement | Notes |
|---|---|
| **JDK 21 or newer** | Hard requirement. `firebase-tools` 15.x refuses to start the Firestore emulator on anything older: *"firebase-tools no longer supports Java version before 21."* JDK 17 is **not** enough. |
| Node 18+ | For mocha and the Firebase JS SDK. |
| Dev dependencies | Project-local only — `npm install` in this directory. Nothing is installed globally. |

The emulator is downloaded and run by `firebase emulators:exec`; the Firebase
CLI comes from `npx`, so no global install is needed.

## Running

Set `JAVA_HOME` **for the command only** — do not edit a shell profile:

```bash
# bash
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot"
export PATH="$JAVA_HOME/bin:$PATH"
npm test
```

```powershell
# PowerShell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
npm test
```

`npm test` starts the Firestore emulator, runs mocha against it, and shuts the
emulator down. `npm run test:nostart` runs mocha against an emulator you started
yourself.

### Why the project id is `demo-kids-stories-rules`

The emulator treats any project id beginning with `demo-` as **offline-only**:
it never contacts Google, needs no login, and cannot reach the real
`kid-story-app-vel697` project. The id in `package.json`'s `--project` flag and
the `PROJECT_ID` constant in `rules.test.js` must stay identical, and must keep
the `demo-` prefix.

### Expected noise

The emulator prints `Property admin is undefined on object` on almost every
write. This is not a failure. `isAdmin()` reads `request.auth.token.admin`,
which is absent for ordinary users; in Firestore rules an erroring operand of
`||` still lets the other branch decide, so the rule evaluates correctly and the
emulator merely warns. Only the mocha pass/fail counts matter.

## What is covered

| Area | Checks |
|---|---|
| Unauthenticated access | Every collection is denied without a signed-in user. |
| `users/{uid}` and `children` | Owner-only by path; privileged keys are unwritable. |
| `favorites`, `progress` | Owner-only **by field** (ADR-01); `ownerUid` pinned on update; `childRef`/`storyRef` cross-validated. |
| Deterministic IDs | The document ID must equal `{uid}_{childId}_{storyId}`, built from `request.auth.uid` — a forged `ownerUid` cannot produce a matching ID. |
| Collection queries | An owner-filtered query is allowed; an unfiltered one and one filtered to another user are denied. |
| Progress values | The eleven validations from `FIREBASE_SCHEMA.md` §6.1 — paging bounds, counters, `completionPercent` range, `completed`/`completedAt` consistency, playback speed, `lastMode` enum, write-once `startedAt`. |
| Stories and pages | Published metadata only; free published pages only; **premium pages denied to all ordinary clients**. |
| `entitlements` | Owner-readable, never client-writable; the audit trail is not client-readable at all. |
| Collection-group isolation | `children`, `pages` and `events` group reads are admin-only. |

## Writing new tests

Two fixture rules matter, both learned from real failures:

1. **`startedAt` is write-once.** `progressRow()` therefore defaults it to the
   fixed `SEEDED_STARTED_AT`, not `new Date()`. A fresh value per call makes
   every repeat write to the same row an illegal update.
2. **Tests share the emulator within a run**, so a `setDoc` on an id an earlier
   test already created is an *update*, not a create. A test that must exercise
   a create needs a document id no other test has written —
   `UNTOUCHED_STORY` exists for exactly that.

Never relax a rule to make a test pass. If a test fails, decide first whether
the rule is wrong or the fixture is; so far it has always been the fixture.
