/// KidStoryApp — Schema Batch A1: the `users` top-level collection.
///
/// Fields are exactly docs/FIREBASE_SCHEMA.md §3. The four auth fields keep
/// FlutterFlow's snake_case names per the §1 convention exception
/// (`uid`, `email`, `display_name`, `created_time`); every app-defined field is
/// camelCase.
///
/// `settings` and `consent` are documented as `map`. FlutterFlow has no bare
/// map field type, so they are authored as JSON — the shapes are specified in
/// prose in §3. If typed sub-field binding is wanted later, convert them to
/// Data Structs; that is a deliberate decision, not done here.
///
/// Authentication is NOT touched by this batch: the collection is created but
/// not wired as the auth user collection.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildA1,
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

void buildA1(App app) {
  app.collection(
    'users',
    description:
        'Parent account document. Document ID is the Firebase Auth UID. '
        'Deliberately carries NO subscription or premium field — that lives '
        'only in entitlements/{uid}, which is server-written. See '
        'docs/FIREBASE_SCHEMA.md section 3.',
    fields: {
      // FlutterFlow auth auto-fields (snake_case by convention exception).
      'uid': string,
      'email': string,
      'display_name': string,
      'created_time': dateTime,
      // App-defined fields (camelCase).
      'updatedAt': dateTime,
      'locale': string,
      'settings': json,
      'consent': json,
      'childrenCount': int_,
    },
  );
}
