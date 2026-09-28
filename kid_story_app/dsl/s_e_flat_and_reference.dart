/// KidStoryApp — Schema Batch E: the four remaining top-level collections.
///
/// `favorites`  — FIREBASE_SCHEMA.md §5, flattened per ADR-01
/// `progress`   — §6, flattened per ADR-01
/// `categories` — §9
/// `appConfig`  — §10 (the single document `public`)
///
/// ADR-01: favorites and progress were specified three levels deep
/// (users/{uid}/children/{childId}/…), which FlutterFlow cannot model — it
/// supports only one level of subcollection nesting. They are top-level here
/// and carry ownership in fields: ownerUid, childId, childRef, storyId,
/// storyRef.
///
/// Document IDs are Firestore auto-IDs. The DSL has NO way to supply a
/// deterministic ID — `FirestoreCreate` takes no `documentId` and
/// `DocumentReferenceOf` cannot build a reference from a path string. The
/// intended one-row-per-(ownerUid, childId, storyId) identity is therefore a
/// client-side query-before-create invariant, documented in §5.1 / §6.1, not
/// something the key or the rules can enforce.
///
/// No sample or production documents are created by this batch.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kid_story_app/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildE,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

void buildE(App app) {
  // -------------------------------------------------------------------------
  // favorites — §5 (top-level, ADR-01)
  // -------------------------------------------------------------------------
  app.collection(
    'favorites',
    description:
        'Favourite marker. TOP-LEVEL per ADR-01 (FlutterFlow supports only '
        'one subcollection level). Ownership is carried by ownerUid + '
        'childRef, not by the path, so every query MUST filter on ownerUid '
        'and rules must verify it. Auto-ID: uniqueness per '
        '(ownerUid, childId, storyId) is a client query-before-create '
        'invariant — see FIREBASE_SCHEMA.md section 5.1.',
    fields: {
      'ownerUid': string,
      'childId': string,
      'childRef': docRef(ff.Collections.children),
      'storyId': string,
      'storyRef': docRef(ff.Collections.stories),
      'createdAt': dateTime,
    },
  );

  // -------------------------------------------------------------------------
  // progress — §6 (top-level, ADR-01). All previously agreed progress fields
  // are preserved; only the ownership fields are added.
  // -------------------------------------------------------------------------
  app.collection(
    'progress',
    description:
        'Reading and listening progress. TOP-LEVEL per ADR-01. Ownership via '
        'ownerUid + childRef. Auto-ID: one row per (ownerUid, childId, '
        'storyId) is a client query-before-update invariant — see '
        'FIREBASE_SCHEMA.md section 6.1. updatedAt orders "continue reading".',
    fields: {
      // Ownership (ADR-01)
      'ownerUid': string,
      'childId': string,
      'childRef': docRef(ff.Collections.children),
      'storyRef': docRef(ff.Collections.stories),
      // Previously agreed progress fields, unchanged
      'storyId': string,
      'lastPageNumber': int_,
      'pageCount': int_,
      'contentVersion': int_,
      'lastMode': string,
      'lastPlaybackSpeed': double_,
      'completed': bool_,
      'readCompletedCount': int_,
      'listenCompletedCount': int_,
      'completedAt': dateTime,
      'updatedAt': dateTime,
    },
  );

  // -------------------------------------------------------------------------
  // categories — §9
  // -------------------------------------------------------------------------
  app.collection(
    'categories',
    description:
        'Story categories. Document ID is a lowercase ASCII slug (animals, '
        'family, nature, bedtime). Inactive categories are hidden but keep '
        'their ID. Admin-write only. See FIREBASE_SCHEMA.md section 9.',
    fields: {
      'nameAr': string,
      'iconId': string,
      'sortOrder': int_,
      'isActive': bool_,
    },
  );

  // -------------------------------------------------------------------------
  // appConfig — §10. Single document `public`; readable by any signed-in
  // parent, admin-write only. Map-typed fields are JSON, consistent with
  // users.settings / users.consent / stories.credits.
  // -------------------------------------------------------------------------
  app.collection(
    'appConfig',
    description:
        'Remote configuration. The only document is "public". Deliberately '
        'carries NO product IDs or prices — those come from RevenueCat and '
        'the stores at runtime. Admin-write only. See FIREBASE_SCHEMA.md '
        'section 10.',
    fields: {
      'minSupportedBuild': json,
      'maintenanceMode': bool_,
      'maintenanceMessageAr': string,
      'featuredStoryIds': listOf(string),
      'maxChildrenPerParent': int_,
      'ageGroups': json,
      'avatarIds': listOf(string),
      'legalUrls': json,
      'playback': json,
      'subscription': json,
      'updatedAt': dateTime,
    },
  );
}
