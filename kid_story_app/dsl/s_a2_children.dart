/// KidStoryApp — Schema Batch A2: `users/{uid}/children/{childId}`.
///
/// Fields are exactly docs/FIREBASE_SCHEMA.md §4. The collection is named
/// `children` (never `child_profiles`) and is a SUBCOLLECTION of `users`.
///
/// §4 is explicit that nothing else is allowed on these documents — no birth
/// date, real name, gender, photo, school, location or device identifier. Only
/// the six documented fields are created here.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';
import '_schema_util.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildA2,
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

void buildA2(App app) {
  app.raw((project) {
    ensureSubcollection(
      project,
      parentName: 'users',
      name: 'children',
      description:
          'Child profile under a parent account. Only the age GROUP is '
          'stored, never a date of birth. No real name, gender, photo, '
          'location or device identifier. See docs/FIREBASE_SCHEMA.md '
          'section 4.',
      fields: {
        'nickname': fsString,
        'ageGroup': fsString,
        'avatarId': fsString,
        'preferredMode': fsString,
        'createdAt': fsTimestamp,
        'updatedAt': fsTimestamp,
      },
    );
  });
}
