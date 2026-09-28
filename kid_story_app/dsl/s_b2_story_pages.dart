/// KidStoryApp — Schema Batch B2: `stories/{storyId}/pages/{pageId}`.
///
/// Fields are exactly docs/FIREBASE_SCHEMA.md §8. Authored as a genuine
/// SUBCOLLECTION of `stories` — the documented nesting is preserved, not
/// flattened.
///
/// Note the §8 access rule the schema relies on: `imageUrl` and `audioUrl` are
/// present ONLY for free stories; premium pages carry `imagePath` / `audioPath`
/// and are fetched through the Storage SDK under rules. Creating the fields
/// here does not grant access to anything — that is the security-rules phase.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';
import '_schema_util.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildB2,
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

void buildB2(App app) {
  app.raw((project) {
    ensureSubcollection(
      project,
      parentName: 'stories',
      name: 'pages',
      description:
          'Ordered story pages. pageNumber is 1-based and contiguous. '
          'imageUrl/audioUrl exist only for FREE stories; premium pages are '
          'reached by Storage path under rules. See '
          'docs/FIREBASE_SCHEMA.md section 8.',
      fields: {
        'pageNumber': fsInt,
        'displayTextAr': fsString,
        'ttsTextAr': fsString,
        'imagePath': fsString,
        'imageUrl': fsString,
        'imageAlt': fsString,
        'audioPath': fsString,
        'audioUrl': fsString,
        'audioSource': fsString,
        'audioDurationMs': fsInt,
        'autoAdvance': fsBool,
        'autoAdvanceDelayMs': fsInt,
        'pageKind': fsString,
      },
    );
  });
}
