/// KidStoryApp — Schema Batch C: favorites and progress.
///
/// `users/{uid}/children/{childId}/favorites/{storyId}`  — §5
/// `users/{uid}/children/{childId}/progress/{storyId}`   — §6
///
/// Both are subcollections of `children`. The reading-progress collection uses
/// its documented exact name, `progress` — not readingProgress, not
/// reading_progress.
///
/// Document IDs are the story ID in both cases, so favouriting is a set/delete
/// and progress is a single-document upsert.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';
import '_schema_util.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildC,
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

void buildC(App app) {
  app.raw((project) {
    // §5 — favourite marker. Document ID is the story ID.
    ensureSubcollection(
      project,
      parentName: 'children',
      name: 'favorites',
      description:
          'Favourite marker for one child. Document ID is the story ID, so '
          'toggling is a set/delete and duplicates are impossible. '
          'Favouriting a premium story is allowed without a subscription — it '
          'stays locked in the shelf. See docs/FIREBASE_SCHEMA.md section 5.',
      fields: {'storyId': fsString, 'createdAt': fsTimestamp},
    );

    // §6 — reading and listening progress. Documented name: `progress`.
    ensureSubcollection(
      project,
      parentName: 'children',
      name: 'progress',
      description:
          'Reading and listening progress for one child and story. Document '
          'ID is the story ID. Drives "continue reading" ordering via '
          'updatedAt. See docs/FIREBASE_SCHEMA.md section 6.',
      fields: {
        'storyId': fsString,
        'lastPageNumber': fsInt,
        'pageCount': fsInt,
        'contentVersion': fsInt,
        'lastMode': fsString,
        'lastPlaybackSpeed': fsDouble,
        'completed': fsBool,
        'readCompletedCount': fsInt,
        'listenCompletedCount': fsInt,
        'completedAt': fsTimestamp,
        'updatedAt': fsTimestamp,
      },
    );
  });
}
