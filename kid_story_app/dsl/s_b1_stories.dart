/// KidStoryApp — Schema Batch B1: the `stories` top-level collection.
///
/// Fields are exactly docs/FIREBASE_SCHEMA.md §7.
///
/// `credits` is documented as `map` and is authored as JSON for the same
/// reason as users.settings — FlutterFlow has no bare map type. Its shape
/// ({ author, illustrator, narrator }) is specified in §7 and is parent-area
/// display only.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildB1,
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

void buildB1(App app) {
  app.collection(
    'stories',
    description:
        'Story catalog entry. Only status == "published" is readable by '
        'parents; accessLevel is readable by all signed-in parents so the '
        'lock badge can render. No preview or partial-story mechanism '
        'exists. See docs/FIREBASE_SCHEMA.md section 7.',
    fields: {
      'titleAr': string,
      'summaryAr': string,
      'language': string,
      'ageGroups': listOf(string),
      'categoryIds': listOf(string),
      'accessLevel': string,
      'coverImagePath': string,
      'coverImageUrl': string,
      'pageCount': int_,
      'estimatedMinutes': int_,
      'audioSource': string,
      'layout': string,
      'status': string,
      'sortOrder': int_,
      'publishedAt': dateTime,
      'contentVersion': int_,
      'credits': json,
      'createdAt': dateTime,
      'updatedAt': dateTime,
    },
  );
}
