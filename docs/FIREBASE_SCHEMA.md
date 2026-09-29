# Firebase Schema — Firestore and Storage

| | |
|---|---|
| Status | Draft v0.2 — planning phase. No collection, index, or bucket exists yet. v0.2 adds `accessLevel`, display vs. TTS text, playback metadata, the server-only entitlement mirror, and switches app-defined field names to camelCase (D-16 resolved). |
| Last updated | 2026-09-21 |
| Related docs | [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels:** **[CONFIRMED]** · **[ASSUMPTION]** · **[DECISION NEEDED]** · **[VERIFY]** · **[UNRESOLVED]** (an implementation detail deliberately left open).

---

## 1. Conventions

| Convention | Rule |
|---|---|
| Field naming | **camelCase** for every app-defined field (`displayTextAr`, `accessLevel`, `pageNumber`), matching the names in the confirmed product decisions. **Exception:** the auth-related fields FlutterFlow creates automatically on the users collection (`email`, `display_name`, `uid`, `created_time`) keep FlutterFlow's names because FlutterFlow controls them **[VERIFY exact set on first export]**. D-16 is thereby resolved. |
| Timestamps | Firestore `timestamp`. Server timestamps for `createdAt` / `updatedAt` on client writes; Functions write their own server-side times. |
| Enumerations | Lowercase string values listed in this document; rules enforce membership. |
| Document IDs | Deterministic where the ID carries meaning (stories, pages, categories, favorites, progress, entitlements); Firebase Auth UID for users and entitlements; Firestore auto-ID for child profiles. |
| Booleans | Never absent on documents the client queries by them (Firestore cannot match a missing field). |
| Denormalisation | Minimal. Story metadata is *not* copied into favorites/progress; the client joins with the loaded catalog. |
| Localisation | Story content is Arabic-only in MVP; each story carries `language: "ar"` and every text field is suffixed `Ar` so a second language can be added later without renaming. |
| Trusted-server-only data | `entitlements/**` is written exclusively by Cloud Functions / admin scripts using the Admin SDK. No client write path exists, and no premium flag exists anywhere a client can write. **[CONFIRMED]** |
| Access level | Every story has `accessLevel` ∈ {`free`, `premium`}. The schema has **no** preview, sample, or partial-story mechanism. **[CONFIRMED]** |

Type notation: `string`, `int`, `double`, `bool`, `timestamp`, `array<string>`, `map`. "Req." = required on every document.

---

## 2. Collection map

```
users/{uid}                                   parent account document
└── children/{childId}                        child profile

favorites/{favoriteId}                        favourite marker    — owner fields, see §5
progress/{progressId}                         reading / listening progress — owner fields, see §6

stories/{storyId}                             story catalog entry (metadata, accessLevel)
└── pages/{pageId}                            ordered story pages (display text, TTS text, media)

categories/{categoryId}                       story categories
appConfig/{configId}                          remote configuration (single doc: "public")

entitlements/{uid}                            subscription mirror — SERVER-WRITTEN ONLY
└── events/{eventId}                          entitlement audit trail — SERVER-WRITTEN ONLY
```

### ADR-01 — favorites and progress are top-level, not nested **[2026-09-28]**

`favorites` and `progress` were originally specified as
`users/{uid}/children/{childId}/favorites|progress/{storyId}` — three levels
deep. **FlutterFlow supports only one level of subcollection nesting**, so that
shape cannot be modelled in the builder at all. Verified by probe against
`kid-story-app-vel697`: a subcollection under a top-level collection compiles,
while one under an existing subcollection fails with *"Collection … is a
subcollection but the parent collection no longer exists."* Firestore itself is
happy with the depth; the constraint is FlutterFlow's data model and its UI
binding.

Both collections are therefore **flattened to top level**, and the ownership
that the path used to express is carried by explicit fields instead:
`ownerUid`, `childId`, `childRef`, `storyId`, `storyRef`.

Consequences, each addressed below:

| Was implied by the path | Now enforced by |
|---|---|
| Ownership (`users/{uid}/…`) | `ownerUid == request.auth.uid` in rules (§12), on read *and* write |
| Child scoping | `childId` + `childRef`, cross-checked against `users/{uid}/children/{childId}` in rules |
| Story identity as the document ID | `storyId` + `storyRef` fields; the document ID is now opaque |
| Uniqueness (one doc per story, free) | Restored by a **deterministic document ID** `{ownerUid}_{childId}_{storyId}`, enforced in rules — see §5.1 |
| No cross-parent queries | Rules require `ownerUid` equality; queries must filter on it |

---

## 3. `users/{uid}` — parent account

| Field | Type | Req. | Notes |
|---|---|---|---|
| `uid` | string | yes | Equals the document ID (FlutterFlow auto-field). |
| `email` | string | yes | FlutterFlow auto-field. |
| `display_name` | string | no | Optional parent name; FlutterFlow auto-field. Not shown to children. |
| `created_time` | timestamp | yes | FlutterFlow auto-field. |
| `updatedAt` | timestamp | no | Server timestamp on updates. |
| `locale` | string | yes | `"ar"` in MVP. |
| `settings` | map | yes | `{ narrationAutoplay: bool, autoAdvance: bool, autoAdvanceDelayMs: int, playbackSpeed: double, defaultMode: "read"\|"listen", soundEffects: bool }`. Defaults from `appConfig/public.playback`. |
| `consent` | map | yes | `{ termsVersion: string, privacyVersion: string, acceptedAt: timestamp }` — record of what was accepted at sign-up. |
| `childrenCount` | int | no | Optional cached count for the max-profiles check; maintained by the client. **[ASSUMPTION]** acceptable inaccuracy; the hard limit is UX, not security. |

**Deliberately absent:** any subscription or premium field. Subscription state lives only in `entitlements/{uid}` (server-written) and in RevenueCat. Rules reject unknown keys on this document, so a client cannot add one.

**Do not add:** `photo_url`, `phone_number`, or other FlutterFlow auto-fields that are not needed. Remove them from the FlutterFlow users-collection schema **[VERIFY: FlutterFlow allows removing default auth fields]**.

**Document ID:** Firebase Auth UID (also the RevenueCat app user ID).

**Example**
```json
{
  "uid": "8fQ2…",
  "email": "parent@example.com",
  "display_name": "",
  "created_time": "2026-10-01T08:12:00Z",
  "updatedAt": "2026-10-01T08:12:00Z",
  "locale": "ar",
  "settings": { "narrationAutoplay": true, "autoAdvance": true, "autoAdvanceDelayMs": 1500, "playbackSpeed": 1.0, "defaultMode": "listen", "soundEffects": true },
  "consent": { "termsVersion": "2026-10", "privacyVersion": "2026-10", "acceptedAt": "2026-10-01T08:12:00Z" },
  "childrenCount": 1
}
```

---

## 4. `users/{uid}/children/{childId}` — child profile

| Field | Type | Req. | Notes |
|---|---|---|---|
| `nickname` | string | yes | 1–20 characters after trimming. Arabic letters, spaces, and digits allowed **[ASSUMPTION]**. |
| `ageGroup` | string | yes | One of `"1-2"`, `"3-4"`, `"5-6"`. **[CONFIRMED]** Only the group identifier is stored — never a date of birth. |
| `avatarId` | string | yes | Matches `^avatar_(0[1-9]|1[0-2])$` (12 bundled avatars **[ASSUMPTION]**). |
| `preferredMode` | string | no | `"read"` or `"listen"`; overrides the parent default for this child **[ASSUMPTION: useful for mixed-age families]**. |
| `createdAt` | timestamp | yes | |
| `updatedAt` | timestamp | yes | |

**Nothing else is allowed.** Rules must reject unknown fields. Explicitly *not* stored: birth date, real name, gender, photo, school, location, device identifiers.

**Document ID:** Firestore auto-ID (opaque; never derived from the nickname).

**Example**
```json
{
  "nickname": "نور",
  "ageGroup": "3-4",
  "avatarId": "avatar_03",
  "preferredMode": "listen",
  "createdAt": "2026-10-01T08:15:00Z",
  "updatedAt": "2026-10-01T08:15:00Z"
}
```

---

## 5. `favorites/{favoriteId}` — top-level (see ADR-01)

| Field | Type | Req. | Notes |
|---|---|---|---|
| `ownerUid` | string | yes | `request.auth.uid` of the owning parent. Immutable after create (rules). Every query MUST filter on it. |
| `childId` | string | yes | ID of the owning child profile. |
| `childRef` | reference | yes | `users/{ownerUid}/children/{childId}`. Rules verify it matches `ownerUid` + `childId`. |
| `storyId` | string | yes | ID of the favourited story. |
| `storyRef` | reference | yes | `stories/{storyId}`. Rules verify it matches `storyId`. |
| `createdAt` | timestamp | yes | Server timestamp; orders the favourites shelf. |

**Document ID:** deterministic —
`favorites/{ownerUid}_{childId}_{storyId}`. See §5.1 for how and when this is
configured.

Favouriting a premium story is still allowed without a subscription; it stays
locked in the shelf.

**Example** (document `favorites/7Hq2mK…`)
```json
{
  "ownerUid": "8fQ2…",
  "childId": "abc123",
  "childRef": "/users/8fQ2…/children/abc123",
  "storyId": "al-ghayma-al-saghira",
  "storyRef": "/stories/al-ghayma-al-saghira",
  "createdAt": "2026-10-02T17:03:00Z"
}
```

### 5.1 Document identity — deterministic IDs

The document ID is **`{ownerUid}_{childId}_{storyId}`**. That makes identity
structural again: one document per owner, child and story, and repeating the
operation for the same tuple addresses the **same document** instead of creating
another one. Favouriting becomes a set; un-favouriting a delete.

**Tooling status — read this before wiring any write:**

| Capability | Status |
|---|---|
| Creating the collection + fields | ✅ Supported by the FlutterFlow AI SDK/DSL — already done. |
| Configuring a Create Document action with a **Custom ID** | ✅ Supported by the **FlutterFlow visual editor** — the Create Document action has a Custom ID toggle ([Firestore Actions docs](https://docs.flutterflow.io/integrations/database/cloud-firestore/firestore-actions/)). |
| Authoring that Custom ID **through the AI SDK/DSL** | ❌ Not available in the current SDK surface: `FirestoreCreate(collection, {fields, parentReference, outputAs})` exposes no document-ID parameter. |

So this is a **limitation of the AI SDK's action surface, not of FlutterFlow.**
The Custom ID will be set in the Action Flow Editor when the UI actions are
wired, using the expression `{ownerUid}_{childId}_{storyId}`.

**Until that UI wiring exists, the app must not create any favorites document.**
There is no supported path today that would give it the right ID, and a write
with an auto-ID would break the uniqueness guarantee the rules now enforce.

Query-before-create is **not** the uniqueness mechanism — deterministic IDs are.
A lookup query may still be used to read an existing favourite (Q10), but it is
a lookup, not a guard. Neither a Cloud Function nor a custom Dart action is
required for this.

The rules enforce the convention: a create is rejected unless the document ID
equals `request.auth.uid + "_" + childId + "_" + storyId`, so a mismatched or
auto-generated ID cannot land.

## 6. `progress/{progressId}` — reading and listening progress, top-level (see ADR-01)

**Ownership fields** (new in ADR-01 — these replace the path that used to carry ownership):

| Field | Type | Req. | Notes |
|---|---|---|---|
| `ownerUid` | string | yes | `request.auth.uid` of the owning parent. Immutable after create (rules). Every query MUST filter on it. |
| `childId` | string | yes | ID of the owning child profile. |
| `childRef` | reference | yes | `users/{ownerUid}/children/{childId}`. Rules verify it matches `ownerUid` + `childId`. |
| `storyRef` | reference | yes | `stories/{storyId}`. Rules verify it matches `storyId`. |

**Progress fields** (unchanged from the original agreement):

| Field | Type | Req. | Notes |
|---|---|---|---|
| `storyId` | string | yes | ID of the story this progress belongs to. No longer the document ID. |
| `lastPageNumber` | int | yes | 1-based; clamped to `pageCount` by the client if content shrinks. |
| `pageCount` | int | yes | Page count of the story at the time of the last write (progress rings without reading the story). |
| `contentVersion` | int | yes | Story version at the last write; lets the client detect a re-import and clamp safely. |
| `lastMode` | string | yes | `"read"` or `"listen"` — resume in the same mode. **[CONFIRMED: save listening and reading progress]** |
| `lastPlaybackSpeed` | double | no | Speed used last time in listen mode. |
| `completed` | bool | yes | Always present (queried). True once the last page was reached in any mode. |
| `readCompletedCount` | int | yes | Times finished in read mode; starts at 0. |
| `listenCompletedCount` | int | yes | Times finished in listen mode; starts at 0. |
| `completedAt` | timestamp | no | Set when `completed` first becomes true. |
| `updatedAt` | timestamp | yes | Used for "continue reading" ordering (Q7 / index I-5). |
| `completionPercent` | double | no | 0.0–100.0; progress ring without loading the story. Added 2026-09-29. |
| `startedAt` | timestamp | no | First open of this story by this child; never overwritten. Added 2026-09-29. |

**Document ID:** deterministic —
`progress/{ownerUid}_{childId}_{storyId}`, same convention and tooling status as
§5.1.

**Example** (document `progress/Kd8sPq…`)
```json
{
  "ownerUid": "8fQ2…",
  "childId": "abc123",
  "childRef": "/users/8fQ2…/children/abc123",
  "storyId": "al-ghayma-al-saghira",
  "storyRef": "/stories/al-ghayma-al-saghira",
  "lastPageNumber": 5,
  "pageCount": 12,
  "contentVersion": 1,
  "lastMode": "listen",
  "lastPlaybackSpeed": 1.0,
  "completed": false,
  "readCompletedCount": 0,
  "listenCompletedCount": 0,
  "updatedAt": "2026-10-02T17:20:00Z"
}
```

### 6.1 Field semantics **[AUTHORITATIVE]**

These names are authoritative. `currentPage`, `readingMode` and `lastReadAt` do
**not** exist — `lastPageNumber`, `lastMode` and `updatedAt` carry those
meanings, and there is exactly one field per concept.

| Field | Meaning and rules |
|---|---|
| `lastPageNumber` | The last **successfully opened** story page. `0` before reading starts; page numbers begin at `1` once reading begins. Never negative. |
| `pageCount` | The number of pages of the **story version being read** (pairs with `contentVersion`). Never negative. |
| `completionPercent` | `0.0`–`100.0`. **Derived** from `lastPageNumber` and `pageCount`: `100.0 * lastPageNumber / pageCount`. If `pageCount == 0`, it **must** be `0.0`. Always clamp into `0.0`–`100.0`. |
| `lastMode` | Exactly `"read"` or `"listen"`. **Never store the Arabic labels** (اقرأ بنفسي / استمع إلى القصة) — those are presentation only. |
| `startedAt` | Set **once**, when the progress document is first created. It must **not** change on any later update. |
| `updatedAt` | Updated whenever the child reads, listens, turns a page, or playback progress changes. Ordering key for Q7 / index I-5. |
| `completed` | `true` **only** when `completionPercent` has reached `100.0`. |
| `completedAt` | Null until the story is completed. Set when `completed` first becomes `true`. **Not reset** by ordinary progress updates. |
| `contentVersion` | Which version of the story content produced this progress state. Positive integer. Lets the client detect a re-import and clamp `lastPageNumber` safely. |
| `readCompletedCount` / `listenCompletedCount` | Times the story was finished in each mode. Non-negative integers, starting at `0`. |
| `lastPlaybackSpeed` | Within the app's supported range, currently **0.75–1.25** (`appConfig/public.playback.speeds` = `[0.75, 1.0, 1.25]`, D-22 still open). Optional. |

**Derivation example.** Page 3 of 12 → `completionPercent = 100.0 * 3 / 12 = 25.0`,
`completed = false`, `completedAt` absent. Page 12 of 12 → `100.0`,
`completed = true`, `completedAt` set once.

**Optionality.** The FlutterFlow schema marks no field as required, so a first
write need not carry the completion fields. `completionPercent`, `startedAt`,
`completedAt` and `lastPlaybackSpeed` are validated **only when present** — with
two exceptions that follow from the semantics above: when `completed` is `true`,
both `completionPercent` (≥ 100.0) and `completedAt` **must** be present.

### 6.2 Document identity

Identical to §5.1: the ID is **`{ownerUid}_{childId}_{storyId}`**, so one
document per owner, child and story, and a repeated write updates that same
document rather than adding another. The Custom ID is configured in the
FlutterFlow Action Flow Editor when the reader's progress-saving action is
wired — it cannot be authored through the current AI SDK.

**No progress document should be written from the app until that wiring
exists.** Rules reject any create whose document ID does not match the tuple.

Two new fields were added 2026-09-29:

| Field | Type | Notes |
|---|---|---|
| `completionPercent` | double | 0.0–100.0. Lets a shelf draw a progress ring without loading the story to learn `pageCount`. |
| `startedAt` | timestamp | First time this child opened this story; never overwritten. Distinct from `updatedAt`, which moves on every write. |

Deliberately **not** added, to avoid two sources of truth for one concept:
`currentPage` (use `lastPageNumber`), `readingMode` (use `lastMode`),
`lastReadAt` (use `updatedAt` — also the ordering key for Q7 and index I-5).

## 7. `stories/{storyId}` — catalog entry

| Field | Type | Req. | Notes |
|---|---|---|---|
| `titleAr` | string | yes | Arabic title. |
| `summaryAr` | string | yes | Arabic, 1–2 sentences, ≤ 200 characters **[ASSUMPTION]**. |
| `language` | string | yes | `"ar"`. |
| `ageGroups` | array<string> | yes | Non-empty subset of `"1-2"`, `"3-4"`, `"5-6"`. |
| `categoryIds` | array<string> | yes | IDs from `categories`; may be empty. |
| `accessLevel` | string | yes | `"free"` or `"premium"`. **[CONFIRMED]** Readable by all signed-in parents (needed for the lock badge). |
| `coverImagePath` | string | yes | Storage object path (canonical), under the access-level prefix. |
| `coverImageUrl` | string | yes | Tokened download URL — covers are always fetchable so locked stories show a real cover. |
| `pageCount` | int | yes | Number of documents in `pages`; maintained by the import script. |
| `estimatedMinutes` | int | yes | Listening time shown to parents. |
| `audioSource` | string | yes | Summary of narration availability: `"prepared"` (every page has a prepared file), `"tts"` (no prepared files — listen mode relies on device TTS), `"mixed"`. Lets the UI warn when TTS is unavailable before opening. |
| `layout` | string | no | `"imageDominant"` (default for stories targeting `1-2`) or `"standard"` **[ASSUMPTION]**. |
| `status` | string | yes | `"draft"` · `"published"` · `"archived"`. Only `published` is readable by parents. |
| `sortOrder` | int | yes | Manual ordering within shelves (lower first). |
| `publishedAt` | timestamp | no | Set when first published; used for "new" ordering. |
| `contentVersion` | int | yes | Incremented on every re-import; part of the Storage path. |
| `credits` | map | no | `{ author: string, illustrator: string, narrator: string }` — shown in the parent area only. |
| `createdAt` | timestamp | yes | |
| `updatedAt` | timestamp | yes | |

**Document ID:** lowercase ASCII slug, hyphen-separated, stable forever (e.g. `al-ghayma-al-saghira`). Never reuse an ID for a different story; archive instead. Changing `accessLevel` keeps the ID and bumps `contentVersion` (media moves to the other prefix).

**Example**
```json
{
  "titleAr": "الغيمة الصغيرة",
  "summaryAr": "غيمةٌ صغيرةٌ تبحثُ عن مكانٍ تُمطرُ فيه.",
  "language": "ar",
  "ageGroups": ["3-4", "5-6"],
  "categoryIds": ["nature"],
  "accessLevel": "premium",
  "coverImagePath": "stories/premium/al-ghayma-al-saghira/v2/cover.webp",
  "coverImageUrl": "https://firebasestorage.googleapis.com/…",
  "pageCount": 12,
  "estimatedMinutes": 6,
  "audioSource": "prepared",
  "layout": "standard",
  "status": "published",
  "sortOrder": 10,
  "publishedAt": "2026-10-05T09:00:00Z",
  "contentVersion": 2,
  "credits": { "author": "…", "illustrator": "…", "narrator": "…" },
  "createdAt": "2026-10-04T12:00:00Z",
  "updatedAt": "2026-10-05T09:00:00Z"
}
```

---

## 8. `stories/{storyId}/pages/{pageId}` — story pages

| Field | Type | Req. | Notes |
|---|---|---|---|
| `pageNumber` | int | yes | 1-based, contiguous, unique within the story. Ordering key. **[CONFIRMED]** |
| `displayTextAr` | string | yes | Text shown on screen (may include tashkeel and line breaks). **[CONFIRMED]** |
| `ttsTextAr` | string | yes | Text sent to the TTS engine when no prepared audio is used: numbers as words, punctuation for pauses, diacritics where they improve pronunciation. Never empty (validator). **[CONFIRMED]** |
| `imagePath` | string | no | Storage path of the illustration; a page may have no illustration. |
| `imageUrl` | string | no | Tokened download URL — **present only for free stories**; absent for premium pages. **[CONFIRMED]** |
| `imageAlt` | string | no | Arabic description for screen readers. Recommended. |
| `audioPath` | string | no | Storage path of the prepared narration; absent when the page relies on TTS. |
| `audioUrl` | string | no | Tokened download URL — **present only for free stories**; absent for premium pages. **[CONFIRMED]** |
| `audioSource` | string | no | `"human"` or `"generated"` when `audioPath` exists; absent otherwise (→ TTS fallback). |
| `audioDurationMs` | int | no | For progress display, pre-buffering, and auto-advance timing. |
| `autoAdvance` | bool | no | Page-level override of automatic advance after playback; absent → use the story/user default. **[CONFIRMED: optional]** |
| `autoAdvanceDelayMs` | int | no | Page-level override of the pause before advancing. |
| `pageKind` | string | no | `"story"` (default) or `"question"` for 3–4 interaction pages; the UI may show a "repeat" affordance and never auto-advances a question page. **[UNRESOLVED]** whether richer interaction data is needed later. |

**Document ID:** `p` + zero-padded page number (`p001`, `p002`, …). Zero-padding keeps console listings in order; queries still sort by `pageNumber`.

**Example — free story page** (document `stories/al-arnab-wal-jazar/pages/p004`)
```json
{
  "pageNumber": 4,
  "displayTextAr": "نَظَرَ الأَرْنَبُ إلى الجَزَرَةِ الكَبيرَةِ وَقالَ: يا لَها مِنْ جَزَرَةٍ!",
  "ttsTextAr": "نظر الأرنب إلى الجزرة الكبيرة، وقال: يا لها من جزرة!",
  "imagePath": "stories/free/al-arnab-wal-jazar/v1/pages/p004/image.webp",
  "imageUrl": "https://firebasestorage.googleapis.com/…",
  "imageAlt": "أرنب ينظر إلى جزرة كبيرة في الحقل",
  "audioPath": "stories/free/al-arnab-wal-jazar/v1/pages/p004/audio.m4a",
  "audioUrl": "https://firebasestorage.googleapis.com/…",
  "audioSource": "human",
  "audioDurationMs": 7400,
  "autoAdvance": true
}
```

**Example — premium story page** (no URLs; media only via the Storage SDK under rules)
```json
{
  "pageNumber": 4,
  "displayTextAr": "نَظَرَتِ الغَيْمَةُ إلى الحَقْلِ الجافِّ، فَقالَتْ: هُنا سَأُمْطِرُ!",
  "ttsTextAr": "نظرت الغيمة إلى الحقل الجاف، فقالت: هنا سأمطر!",
  "imagePath": "stories/premium/al-ghayma-al-saghira/v2/pages/p004/image.webp",
  "imageAlt": "غيمة تنظر إلى حقل جاف تحت الشمس",
  "audioPath": "stories/premium/al-ghayma-al-saghira/v2/pages/p004/audio.m4a",
  "audioSource": "generated",
  "audioDurationMs": 9800
}
```

---

## 9. `categories/{categoryId}`

| Field | Type | Req. | Notes |
|---|---|---|---|
| `nameAr` | string | yes | Arabic display name. |
| `iconId` | string | yes | ID of a bundled icon asset **[ASSUMPTION: icons bundled, not in Storage — D-15]**. |
| `sortOrder` | int | yes | |
| `isActive` | bool | yes | Inactive categories are hidden but keep their ID. |

**Document ID:** lowercase ASCII slug (`animals`, `family`, `nature`, `bedtime`).

**Example**
```json
{ "nameAr": "الطبيعة", "iconId": "cat_nature", "sortOrder": 20, "isActive": true }
```

---

## 10. `appConfig/public` — remote configuration (single document)

| Field | Type | Req. | Notes |
|---|---|---|---|
| `minSupportedBuild` | map | yes | `{ android: int, ios: int }` — build numbers below this are blocked. |
| `maintenanceMode` | bool | yes | |
| `maintenanceMessageAr` | string | no | Arabic message. |
| `featuredStoryIds` | array<string> | yes | Ordered; the client filters out unpublished IDs. |
| `maxChildrenPerParent` | int | yes | D-07, default 5. |
| `ageGroups` | array<map> | yes | `[{ id: "1-2", labelAr: "١–٢ سنة" }, { id: "3-4", labelAr: "٣–٤ سنوات" }, { id: "5-6", labelAr: "٥–٦ سنوات" }]` — labels are data so they can be corrected remotely. |
| `avatarIds` | array<string> | yes | Valid avatar IDs (must match bundled assets of the running build). |
| `legalUrls` | map | yes | `{ privacy: string, terms: string, support: string }` — opened only behind the parental gate. |
| `playback` | map | yes | `{ speeds: [0.75, 1.0, 1.25], defaultSpeed: 1.0, ttsLocale: "ar", autoAdvanceDefault: true, autoAdvanceDelayMs: 1500 }` (D-22, D-24). |
| `subscription` | map | yes | `{ entitlementId: "premium_library", offeringId: "default", manageUrls: { ios: string, android: string } }` — display/config only; **no product IDs or prices here** (they come from RevenueCat/stores at runtime). |
| `updatedAt` | timestamp | yes | |

**Document ID:** `public`. Readable by any signed-in parent; writable by admins only (Admin SDK).

### Story manifest (content tooling input, not a Firestore document)
```json
{
  "id": "al-ghayma-al-saghira",
  "titleAr": "الغيمة الصغيرة",
  "summaryAr": "…",
  "ageGroups": ["3-4", "5-6"],
  "categoryIds": ["nature"],
  "accessLevel": "premium",
  "estimatedMinutes": 6,
  "layout": "standard",
  "sortOrder": 10,
  "credits": { "author": "…", "illustrator": "…", "narrator": "…" },
  "cover": "cover.webp",
  "pages": [
    { "displayTextAr": "…", "ttsTextAr": "…", "image": "pages/01.webp", "audio": "pages/01.m4a", "audioSource": "human", "imageAlt": "…", "autoAdvance": true },
    { "displayTextAr": "…", "ttsTextAr": "…", "image": "pages/02.webp", "imageAlt": "…", "pageKind": "question", "autoAdvance": false }
  ]
}
```
`contentVersion` is supplied on the command line and must be greater than the currently stored value. The validator rejects: empty `ttsTextAr`, non-contiguous pages, missing cover, unknown `accessLevel`, and any field suggesting partial content.

---

## 11. `entitlements/{uid}` — subscription mirror (SERVER-WRITTEN ONLY) **[CONFIRMED]**

This document mirrors RevenueCat's view of the parent's `premium_library` entitlement so that **Firestore and Storage rules** can enforce premium access. It is derived only from data the server fetches from RevenueCat; the client can read its own document and can never write it.

| Field | Type | Req. | Notes |
|---|---|---|---|
| `premiumActive` | bool | yes | Server-computed: entitlement active per RevenueCat at last sync (includes grace periods). |
| `accessExpiresAt` | timestamp | yes | Server-computed `max(expiresAt, gracePeriodExpiresAt)`; rules require this to be in the future, so a stale mirror cannot extend access. Far-future sentinel for non-expiring manual grants. |
| `entitlementId` | string | yes | `"premium_library"`. |
| `productId` | string | no | Store product identifier as reported by RevenueCat (placeholders in non-prod). |
| `store` | string | no | `"app_store"`, `"play_store"`, `"promotional"`, `"stripe"` (never expected), etc., as reported by RevenueCat **[VERIFY value set]**. |
| `periodType` | string | no | `"normal"`, `"trial"`, `"intro"` **[VERIFY]**. |
| `purchasedAt` | timestamp | no | Latest purchase/renewal time. |
| `expiresAt` | timestamp | no | RevenueCat expiration for the entitlement. |
| `willRenew` | bool | no | False after cancellation of auto-renew. |
| `unsubscribeDetectedAt` | timestamp | no | Cancellation of auto-renew detected. |
| `billingIssueDetectedAt` | timestamp | no | Renewal failed; grace period may apply. |
| `gracePeriodExpiresAt` | timestamp | no | End of the store grace period, if any. |
| `isSandbox` | bool | yes | True for sandbox purchases; production rules may ignore sandbox entitlements **[DECISION NEEDED — D-26]**. |
| `revenuecatAppUserId` | string | yes | Equals the Firebase UID by design; recorded for audit. |
| `originalAppUserId` | string | no | From RevenueCat; differs after a transfer. |
| `lastEventType` | string | no | Last webhook event type applied. |
| `lastEventId` | string | no | Idempotency key of the last applied webhook. |
| `lastEventAt` | timestamp | no | Event timestamp as reported by RevenueCat. |
| `lastSyncedAt` | timestamp | yes | When the server last fetched RevenueCat state (audit). |
| `lastSyncSource` | string | yes | `"webhook"`, `"callable"`, `"admin"`, `"scheduled"` (audit). |
| `grantedAt` | timestamp | no | First time `premiumActive` became true (audit). |
| `revokedAt` | timestamp | no | Last time `premiumActive` became false (audit). |
| `manualGrant` | map | no | `{ reason: string, grantedBy: string, expiresAt: timestamp }` — support grants via admin script only; still expressed through `accessExpiresAt`. |
| `updatedAt` | timestamp | yes | |

**Document ID:** Firebase Auth UID.

**Rules:** read → owner or admin; create/update/delete → **denied for all clients**. Functions and admin scripts use the Admin SDK.

**Example**
```json
{
  "premiumActive": true,
  "accessExpiresAt": "2026-11-05T09:00:00Z",
  "entitlementId": "premium_library",
  "productId": "PLACEHOLDER_PREMIUM_MONTHLY",
  "store": "app_store",
  "periodType": "normal",
  "purchasedAt": "2026-10-05T09:00:00Z",
  "expiresAt": "2026-11-05T09:00:00Z",
  "willRenew": true,
  "isSandbox": true,
  "revenuecatAppUserId": "8fQ2…",
  "originalAppUserId": "8fQ2…",
  "lastEventType": "INITIAL_PURCHASE",
  "lastEventId": "evt_…",
  "lastEventAt": "2026-10-05T09:00:02Z",
  "lastSyncedAt": "2026-10-05T09:00:03Z",
  "lastSyncSource": "webhook",
  "grantedAt": "2026-10-05T09:00:03Z",
  "updatedAt": "2026-10-05T09:00:03Z"
}
```

### 11.1 `entitlements/{uid}/events/{eventId}` — audit trail (SERVER-WRITTEN ONLY)

| Field | Type | Req. | Notes |
|---|---|---|---|
| `type` | string | yes | RevenueCat event type (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `UNCANCELLATION`, `EXPIRATION`, `BILLING_ISSUE`, `PRODUCT_CHANGE`, `TRANSFER`, `TEST`, …) **[VERIFY list]**. |
| `eventAt` | timestamp | yes | RevenueCat event timestamp. |
| `receivedAt` | timestamp | yes | Server receipt time. |
| `productId` | string | no | |
| `store` | string | no | |
| `environment` | string | yes | `"SANDBOX"` / `"PRODUCTION"`. |
| `resultPremiumActive` | bool | yes | Mirror state after applying this event. |
| `payloadDigest` | string | no | Hash of the raw payload (raw payloads are kept in Cloud Logging, not Firestore, to avoid storing store-account data). |

**Document ID:** the RevenueCat event ID (idempotency). Retention: purge events older than 90 days by a scheduled Function **[ASSUMPTION]**. No client access at all.

---

## 12. Ownership model

| Path | Owner | Client read | Client write |
|---|---|---|---|
| `users/{uid}` | Parent `uid` | own document | create on sign-up, update allowed fields; delete **only** via Function |
| `users/{uid}/children/**` | Parent `uid` | own tree | create / update / delete child docs |
| `favorites/{favoriteId}` | Parent `ownerUid` (by field, see ADR-01) | own rows only (`ownerUid == uid`) | create / update / delete own rows; `ownerUid` immutable |
| `progress/{progressId}` | Parent `ownerUid` (by field, see ADR-01) | own rows only (`ownerUid == uid`) | create / update / delete own rows; `ownerUid` immutable |
| `stories/{storyId}` | Admin (claim) | signed-in parents: `status == "published"` (free **and** premium metadata); admins: all | none |
| `stories/{storyId}/pages/**` | Admin | signed-in parents: parent story published **and** (`accessLevel == "free"` **or** entitled); admins: all | none |
| `categories/**` | Admin | signed-in parents | none |
| `appConfig/public` | Admin | signed-in parents | none |
| `entitlements/{uid}` | System (Functions / admin scripts) | own document | **none** |
| `entitlements/{uid}/events/**` | System | **none** | **none** |

"Entitled" in rules means: `entitlements/{uid}` exists, `premiumActive == true`, and `accessExpiresAt > request.time`.

Ownership is expressed by **path** for `users/**`, and by **field** for
`favorites` and `progress` since ADR-01 flattened them. The entitlement mirror
is keyed by the same UID but sits in its own top-level collection so that "no
client writes" is a single rule.

For the two field-owned collections the rules must do more work than a path
check, because a client controls the field values. Every rule therefore
verifies all four of:

1. `ownerUid == request.auth.uid` — on read, create and update.
2. `ownerUid` is unchanged on update (no transferring a row to another parent).
3. `childRef == /users/{ownerUid}/children/{childId}` — the reference and the two ID fields agree, so a client cannot point a row at another parent's child.
4. `storyRef == /stories/{storyId}` — likewise for the story.

---

## 13. Query patterns

| # | Screen / feature | Query | Notes |
|---|---|---|---|
| Q1 | Profile picker | `users/{uid}/children` order by `createdAt asc` | Single-field index (automatic). |
| Q2 | Home — all published | `stories` where `status == "published"` order by `sortOrder asc` | Composite index I-1. Returns free and premium; lock badge decided client-side. |
| Q3 | Home — by age group | `stories` where `status == "published"` and `ageGroups array-contains "3-4"` order by `sortOrder asc` | Composite index I-2. One `array-contains` per query. |
| Q4 | Home — by category | `stories` where `status == "published"` and `categoryIds array-contains "nature"` order by `sortOrder asc` | Composite index I-3. |
| Q5 | Home — newest | `stories` where `status == "published"` order by `publishedAt desc` limit 10 | Composite index I-4. |
| Q6 | Featured | `appConfig/public.featuredStoryIds` → individual `get` per ID (ignore permission errors for drafts) | Avoids `in` queries interacting with the published-only rule. |
| Q7 | Continue reading | `progress` where `ownerUid ==` uid and `childId ==` child and `completed == false` order by `updatedAt desc` limit 10 | Composite index **I-5** (redefined by ADR-01). |
| Q8 | Completed badges | `progress` where `ownerUid ==` uid and `childId ==` child and `completed == true` | Composite index **I-10**. Previously a single-field index on a nested collection. |
| Q9 | Favorites shelf | `favorites` where `ownerUid ==` uid and `childId ==` child order by `createdAt desc` | Composite index **I-11**. |
| Q10 | Is favourite? / upsert probe | `favorites` where `ownerUid ==` uid and `childId ==` child and `storyId ==` story limit 1 | Composite index **I-8**. No longer a single-document read — see §5.1. |
| Q11 | Story detail | get `stories/{storyId}` + `progress` where `ownerUid ==` uid and `childId ==` child and `storyId ==` story limit 1 | One read plus one query (index **I-9**). |
| Q12 | Reader | `stories/{storyId}/pages` order by `pageNumber asc` | Single-field index. Rules perform up to two `get()` calls (story, entitlement) once per query. |
| Q13 | Categories | `categories` where `isActive == true` order by `sortOrder asc` | Composite index I-6. |
| Q14 | Free stories shelf | `stories` where `status == "published"` and `accessLevel == "free"` order by `sortOrder asc` | Composite index I-7. |
| Q15 | Entitlement (display) | get `entitlements/{uid}` (may not exist) | Display of status/dates in the parent area; UI unlock uses the RevenueCat SDK state, rules use this doc. |
| Q16 | Admin: drafts / audit | `stories` where `status == "draft"`; `entitlements` where `premiumActive == true` | Admin tooling only (Admin SDK). |

No collection-group queries are used in MVP. No collection-group index is created on `children` or `events`, so child and entitlement data is never queryable across parents.

Since ADR-01, `favorites` and `progress` are **top-level**, so cross-parent isolation can no longer come from the path. It is enforced instead by the rules in [FIREBASE_SECURITY_PLAN.md](FIREBASE_SECURITY_PLAN.md): a read is only permitted where `resource.data.ownerUid == request.auth.uid`. A query without an `ownerUid` equality filter is rejected by the rules engine rather than returning another parent's rows — which is why every index for these two collections leads with `ownerUid`.

Read-cost notes: the catalog is small (tens of stories); Q2–Q5, Q14 are served from Firestore persistence after the first load. Reader page loads are one query per story open plus two rule `get()`s for premium stories.

---

## 14. Required Firestore composite indexes

| ID | Collection | Fields | Query scope |
|---|---|---|---|
| I-1 | `stories` | `status ASC`, `sortOrder ASC` | Collection |
| I-2 | `stories` | `status ASC`, `ageGroups ARRAY_CONTAINS`, `sortOrder ASC` | Collection |
| I-3 | `stories` | `status ASC`, `categoryIds ARRAY_CONTAINS`, `sortOrder ASC` | Collection |
| I-4 | `stories` | `status ASC`, `publishedAt DESC` | Collection |
| I-5 | `progress` | `ownerUid ASC`, `childId ASC`, `completed ASC`, `updatedAt DESC` | Collection |
| I-6 | `categories` | `isActive ASC`, `sortOrder ASC` | Collection |
| I-7 | `stories` | `status ASC`, `accessLevel ASC`, `sortOrder ASC` | Collection |
| I-8 | `favorites` | `ownerUid ASC`, `childId ASC`, `storyId ASC` | Collection |
| I-9 | `progress` | `ownerUid ASC`, `childId ASC`, `storyId ASC` | Collection |
| I-10 | `progress` | `ownerUid ASC`, `childId ASC`, `completed ASC` | Collection |
| I-11 | `favorites` | `ownerUid ASC`, `childId ASC`, `createdAt DESC` | Collection |

**Changed by ADR-01.** I-5 was `completed ASC, updatedAt DESC` on the nested
`progress` subcollection, where the path already scoped the query to one child.
Flattening removes that scoping, so every `favorites` / `progress` index must
now lead with `ownerUid, childId`. I-8 to I-11 are new and exist only because
of the flattening; each one names the query it serves in §13. **I-8 and I-9 are
lookup indexes only** — they back the Q10/Q11 reads. They do NOT enforce
uniqueness; the deterministic document ID does (§5.1 / §6.2).

**I-12 was removed (2026-09-29).** It proposed a composite index on `events`
with the single field `eventAt DESC`. Firestore composite indexes require at
least two fields, so that definition is invalid and would be rejected on
deploy. The intended query is **parent-scoped** — `entitlements/{uid}/events`
ordered by `eventAt desc` for one parent, read by admin tooling through the
Admin SDK — and a parent-scoped single-field sort is served by Firestore's
**automatic single-field index**. No custom index is needed. A collection-group
index across all parents' events is deliberately **not** created (§13), so the
audit trail can never be queried across accounts.


Illustrative `firestore.indexes.json` entry for I-2 (to be created in `backend/` during Phase 2, not now):
```json
{
  "collectionGroup": "stories",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "ageGroups", "arrayConfig": "CONTAINS" },
    { "fieldPath": "sortOrder", "order": "ASCENDING" }
  ]
}
```

Single-field exemptions: consider disabling automatic indexing of `displayTextAr` and `ttsTextAr` on `pages` (large strings, never queried) to save index storage **[ASSUMPTION: worthwhile at scale, optional for MVP]**.

---

## 15. Storage folder structure

```
stories/
├── free/
│   └── {storyId}/
│       └── v{contentVersion}/
│           ├── cover.webp                    # tokened download URL created
│           └── pages/{pageId}/
│               ├── image.webp                # tokened download URL created
│               └── audio.m4a                 # tokened download URL created
└── premium/
    └── {storyId}/
        └── v{contentVersion}/
            ├── cover.webp                    # tokened download URL created (covers are public to signed-in users)
            └── pages/{pageId}/
                ├── image.webp                # NO download token — SDK access under rules only
                └── audio.m4a                 # NO download token — SDK access under rules only
categories/                                   # only if icons are not bundled (see §9)
└── {categoryId}/icon.png
```

Rules summary (full requirements in [SECURITY_AND_PRIVACY.md §4](SECURITY_AND_PRIVACY.md)):
- `stories/free/**`, `stories/{level}/{storyId}/{version}/cover.*`, `categories/**`: read if signed in; write denied.
- `stories/premium/{storyId}/{version}/pages/**`: read if signed in **and** entitled (cross-service lookup of `entitlements/{uid}`) or admin; write denied.
- Any other path: denied.
- App Check enforced at the service level on top of the rules.

The access level is encoded in the **path** so that the premium rule needs only one Firestore lookup (the entitlement) and so that a scheduled audit can list `stories/premium/**/pages/**` and assert that no object carries a `firebaseStorageDownloadTokens` metadata entry. **[CONFIRMED: premium media never exposed through unrestricted URLs]**

Versioned paths (`v{contentVersion}`) guarantee that every corrected asset — and every access-level change — has a new path, so caches never show stale content and tokens are never inherited. Old versions are deleted by an admin cleanup script after a grace period **[ASSUMPTION: 7 days]**.

Object metadata: `Cache-Control: public, max-age=31536000, immutable` for free/cover objects; `Cache-Control: private, max-age=0` for premium page objects **[ASSUMPTION]** (the app's own disk cache handles reuse).

---

## 16. Decisions (schema)

| ID | Decision | Status / default |
|---|---|---|
| D-02 | Age groups | **Confirmed**: `1-2`, `3-4`, `5-6` |
| D-03 | Subscription model, `accessLevel`, `entitlements` mirror | **Confirmed** |
| D-07 | Max children per parent | Open — default 5 |
| D-09 | Media access | **Confirmed direction**: tokened URLs for covers and free page media; SDK path only (no tokens) for premium page media |
| D-15 | Category icons bundled vs. in Storage | Open — default bundled |
| D-16 | Field-name convention | **Resolved**: camelCase for app-defined fields; FlutterFlow auth auto-fields keep their names |
| D-26 | Do production rules honour sandbox entitlements (`isSandbox == true`)? | Open — default: honoured in dev/staging, ignored in prod (so test purchases cannot unlock production content) |
| — | `pageKind: "question"` sufficiency for 3–4 interaction pages | **[UNRESOLVED]** — revisit after the first content batch |
