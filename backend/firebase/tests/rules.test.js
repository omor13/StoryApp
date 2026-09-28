/**
 * Kids Stories — Firestore security-rule tests.
 *
 * Runs against the Firestore emulator only. Nothing here touches a real
 * Firebase project and nothing deploys.
 *
 *   cd backend/firebase/tests
 *   npm install
 *   npm test
 *
 * `npm test` starts the emulator via the Firebase CLI, which requires a JDK.
 * With the emulator already running, `npm run test:nostart` skips the start.
 *
 * Rules under test: ../firestore.rules (repo-owned, authoritative).
 * NEVER point these at the FlutterFlow export's firebase/firestore.rules —
 * that file is permissive and would make every assertion here pass vacuously.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  addDoc,
} from 'firebase/firestore';

const here = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ID = 'kids-stories-rules-test';

const ALICE = 'alice_uid';
const BOB = 'bob_uid';
const ADMIN = 'admin_uid';

const ALICE_CHILD = 'child_a1';
const BOB_CHILD = 'child_b1';
const FREE_STORY = 'laila-and-the-star';
const PREMIUM_STORY = 'al-ghayma-al-saghira';
const DRAFT_STORY = 'not-published-yet';

let testEnv;

/** A favourite row owned by `uid` for `childId` / `storyId`. */
function favouriteRow(db, uid, childId, storyId) {
  return {
    ownerUid: uid,
    childId,
    childRef: doc(db, `users/${uid}/children/${childId}`),
    storyId,
    storyRef: doc(db, `stories/${storyId}`),
    createdAt: new Date(),
  };
}

/** A valid progress row; overrides let a test bend one field at a time. */
function progressRow(db, uid, childId, storyId, overrides = {}) {
  return {
    ownerUid: uid,
    childId,
    childRef: doc(db, `users/${uid}/children/${childId}`),
    storyId,
    storyRef: doc(db, `stories/${storyId}`),
    lastPageNumber: 3,
    pageCount: 12,
    contentVersion: 1,
    lastMode: 'read',
    lastPlaybackSpeed: 1.0,
    completed: false,
    readCompletedCount: 0,
    listenCompletedCount: 0,
    updatedAt: new Date(),
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.resolve(here, '../firestore.rules'), 'utf8'),
    },
  });

  // Seed catalogue + owned data with rules disabled.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `users/${ALICE}`), { uid: ALICE, locale: 'ar' });
    await setDoc(doc(db, `users/${BOB}`), { uid: BOB, locale: 'ar' });
    await setDoc(doc(db, `users/${ALICE}/children/${ALICE_CHILD}`), {
      nickname: 'نور',
      ageGroup: '3-4',
      avatarId: 'avatar_03',
    });
    await setDoc(doc(db, `users/${BOB}/children/${BOB_CHILD}`), {
      nickname: 'سيف',
      ageGroup: '5-6',
      avatarId: 'avatar_05',
    });

    await setDoc(doc(db, `stories/${FREE_STORY}`), {
      titleAr: 'ليلى والنجمة',
      status: 'published',
      accessLevel: 'free',
      sortOrder: 10,
    });
    await setDoc(doc(db, `stories/${FREE_STORY}/pages/p001`), {
      pageNumber: 1,
      displayTextAr: 'في مساءٍ هادئ…',
      ttsTextAr: 'في مساءٍ هادئ…',
    });

    await setDoc(doc(db, `stories/${PREMIUM_STORY}`), {
      titleAr: 'الغيمة الصغيرة',
      status: 'published',
      accessLevel: 'premium',
      sortOrder: 20,
    });
    await setDoc(doc(db, `stories/${PREMIUM_STORY}/pages/p001`), {
      pageNumber: 1,
      displayTextAr: 'غيمةٌ صغيرة…',
      ttsTextAr: 'غيمةٌ صغيرة…',
    });

    await setDoc(doc(db, `stories/${DRAFT_STORY}`), {
      titleAr: 'مسودة',
      status: 'draft',
      accessLevel: 'free',
      sortOrder: 30,
    });

    await setDoc(doc(db, 'categories/nature'), {
      nameAr: 'الطبيعة',
      iconId: 'cat_nature',
      sortOrder: 20,
      isActive: true,
    });
    await setDoc(doc(db, 'appConfig/public'), { maintenanceMode: false });
    await setDoc(doc(db, 'appConfig/secret'), { internal: true });

    await setDoc(doc(db, `entitlements/${ALICE}`), {
      premiumActive: true,
      entitlementId: 'premium_library',
      accessExpiresAt: new Date(Date.now() + 86_400_000),
    });

    // Pre-existing owned rows, for update/delete tests.
    await setDoc(doc(db, 'favorites/fav_alice_1'), {
      ownerUid: ALICE,
      childId: ALICE_CHILD,
      childRef: doc(db, `users/${ALICE}/children/${ALICE_CHILD}`),
      storyId: FREE_STORY,
      storyRef: doc(db, `stories/${FREE_STORY}`),
      createdAt: new Date(),
    });
    await setDoc(doc(db, 'progress/prog_alice_1'), {
      ownerUid: ALICE,
      childId: ALICE_CHILD,
      childRef: doc(db, `users/${ALICE}/children/${ALICE_CHILD}`),
      storyId: FREE_STORY,
      storyRef: doc(db, `stories/${FREE_STORY}`),
      lastPageNumber: 2,
      pageCount: 12,
      contentVersion: 1,
      lastMode: 'read',
      completed: false,
      readCompletedCount: 0,
      listenCompletedCount: 0,
      updatedAt: new Date(),
    });
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

const aliceDb = () => testEnv.authenticatedContext(ALICE).firestore();
const bobDb = () => testEnv.authenticatedContext(BOB).firestore();
const adminDb = () =>
  testEnv.authenticatedContext(ADMIN, { admin: true }).firestore();
const anonDb = () => testEnv.unauthenticatedContext().firestore();

// ---------------------------------------------------------------------------

describe('unauthenticated access', () => {
  it('denies reading any user document', async () => {
    await assertFails(getDoc(doc(anonDb(), `users/${ALICE}`)));
  });

  it('denies reading a published free story', async () => {
    await assertFails(getDoc(doc(anonDb(), `stories/${FREE_STORY}`)));
  });

  it('denies creating a favourite', async () => {
    const db = anonDb();
    await assertFails(
      addDoc(collection(db, 'favorites'), favouriteRow(db, ALICE, ALICE_CHILD, FREE_STORY)),
    );
  });
});

describe('users/{uid}', () => {
  it('lets a user read their own document', async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), `users/${ALICE}`)));
  });

  it('lets a user update their own document', async () => {
    await assertSucceeds(
      updateDoc(doc(aliceDb(), `users/${ALICE}`), { locale: 'ar' }),
    );
  });

  it("denies reading another user's document", async () => {
    await assertFails(getDoc(doc(aliceDb(), `users/${BOB}`)));
  });

  it('denies setting a privileged field on self', async () => {
    await assertFails(
      updateDoc(doc(aliceDb(), `users/${ALICE}`), { premiumActive: true }),
    );
  });
});

describe('children', () => {
  it('lets a user manage their own child', async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), `users/${ALICE}/children/${ALICE_CHILD}`), {
        nickname: 'نور',
        ageGroup: '3-4',
        avatarId: 'avatar_04',
      }),
    );
  });

  it("denies access to another user's child", async () => {
    await assertFails(
      getDoc(doc(aliceDb(), `users/${BOB}/children/${BOB_CHILD}`)),
    );
  });
});

describe('favorites (top-level, ADR-01)', () => {
  it('lets a user create and read their own favourite', async () => {
    const db = aliceDb();
    await assertSucceeds(
      addDoc(collection(db, 'favorites'), favouriteRow(db, ALICE, ALICE_CHILD, PREMIUM_STORY)),
    );
    await assertSucceeds(getDoc(doc(db, 'favorites/fav_alice_1')));
  });

  it("denies reading another user's favourite", async () => {
    await assertFails(getDoc(doc(bobDb(), 'favorites/fav_alice_1')));
  });

  it('denies ownerUid spoofing on create', async () => {
    const db = bobDb();
    // Bob claims Alice owns the row.
    await assertFails(
      addDoc(collection(db, 'favorites'), favouriteRow(db, ALICE, ALICE_CHILD, FREE_STORY)),
    );
  });

  it('denies a mismatched childId / childRef', async () => {
    const db = aliceDb();
    const row = favouriteRow(db, ALICE, ALICE_CHILD, FREE_STORY);
    row.childRef = doc(db, `users/${BOB}/children/${BOB_CHILD}`);
    await assertFails(addDoc(collection(db, 'favorites'), row));
  });

  it('denies a mismatched storyId / storyRef', async () => {
    const db = aliceDb();
    const row = favouriteRow(db, ALICE, ALICE_CHILD, FREE_STORY);
    row.storyRef = doc(db, `stories/${PREMIUM_STORY}`);
    await assertFails(addDoc(collection(db, 'favorites'), row));
  });

  it('denies changing ownerUid on update', async () => {
    await assertFails(
      updateDoc(doc(aliceDb(), 'favorites/fav_alice_1'), { ownerUid: BOB }),
    );
  });
});

describe('progress (top-level, ADR-01)', () => {
  it('lets a user update their own progress', async () => {
    const db = aliceDb();
    await assertSucceeds(
      setDoc(
        doc(db, 'progress/prog_alice_1'),
        progressRow(db, ALICE, ALICE_CHILD, FREE_STORY, { lastPageNumber: 5 }),
      ),
    );
  });

  it("denies updating another user's progress", async () => {
    const db = bobDb();
    await assertFails(
      updateDoc(doc(db, 'progress/prog_alice_1'), { lastPageNumber: 9 }),
    );
  });

  it('denies lastPageNumber greater than pageCount', async () => {
    const db = aliceDb();
    await assertFails(
      addDoc(
        collection(db, 'progress'),
        progressRow(db, ALICE, ALICE_CHILD, FREE_STORY, {
          lastPageNumber: 99,
          pageCount: 12,
        }),
      ),
    );
  });

  it('denies an invalid lastMode', async () => {
    const db = aliceDb();
    await assertFails(
      addDoc(
        collection(db, 'progress'),
        progressRow(db, ALICE, ALICE_CHILD, FREE_STORY, { lastMode: 'sing' }),
      ),
    );
  });
});

describe('entitlements', () => {
  it('lets the owner read their own entitlement', async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), `entitlements/${ALICE}`)));
  });

  it('denies a client writing an entitlement', async () => {
    await assertFails(
      setDoc(doc(aliceDb(), `entitlements/${ALICE}`), { premiumActive: true }),
    );
  });

  it("denies reading another user's entitlement", async () => {
    await assertFails(getDoc(doc(bobDb(), `entitlements/${ALICE}`)));
  });

  it('denies client reads of the events audit trail', async () => {
    await assertFails(
      getDoc(doc(aliceDb(), `entitlements/${ALICE}/events/evt_1`)),
    );
  });
});

describe('stories and pages', () => {
  it('allows reading a published free story', async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), `stories/${FREE_STORY}`)));
  });

  it('allows reading a page of a published free story', async () => {
    await assertSucceeds(
      getDoc(doc(aliceDb(), `stories/${FREE_STORY}/pages/p001`)),
    );
  });

  it('denies reading an unpublished story', async () => {
    await assertFails(getDoc(doc(aliceDb(), `stories/${DRAFT_STORY}`)));
  });

  it('allows reading premium story METADATA (for the lock badge)', async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), `stories/${PREMIUM_STORY}`)));
  });

  it('DENIES premium page reads while entitlement enforcement is incomplete', async () => {
    // Intentional: the entitlement mirror is not server-written yet, so there
    // is nothing trustworthy to check. Alice HAS an entitlements doc with
    // premiumActive true and this must still fail. Do not relax the rule to
    // make this pass.
    await assertFails(
      getDoc(doc(aliceDb(), `stories/${PREMIUM_STORY}/pages/p001`)),
    );
  });

  it('denies an ordinary user writing a story', async () => {
    await assertFails(
      setDoc(doc(aliceDb(), `stories/${FREE_STORY}`), { titleAr: 'مُخترق' }),
    );
  });

  it('allows an admin to write a story', async () => {
    await assertSucceeds(
      setDoc(doc(adminDb(), 'stories/admin-made'), {
        titleAr: 'قصة جديدة',
        status: 'draft',
        accessLevel: 'free',
        sortOrder: 40,
      }),
    );
  });
});

describe('categories and appConfig', () => {
  it('allows an authenticated user to read an active category', async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), 'categories/nature')));
  });

  it('denies an ordinary user writing a category', async () => {
    await assertFails(
      setDoc(doc(aliceDb(), 'categories/nature'), { isActive: false }),
    );
  });

  it('allows an authenticated user to read appConfig/public', async () => {
    await assertSucceeds(getDoc(doc(aliceDb(), 'appConfig/public')));
  });

  it('denies reading a non-public appConfig document', async () => {
    await assertFails(getDoc(doc(aliceDb(), 'appConfig/secret')));
  });
});

describe('collection-group isolation', () => {
  it('denies an ordinary user a collection-group read of children', async () => {
    const { collectionGroup, getDocs } = await import('firebase/firestore');
    await assertFails(getDocs(collectionGroup(aliceDb(), 'children')));
  });
});
