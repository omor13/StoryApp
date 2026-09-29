/// KidStoryApp — Schema Batch F: add the two genuinely new progress fields.
///
/// `completionPercent` (double) and `startedAt` (DateTime) had no equivalent in
/// the schema. The other three names raised in review already exist under their
/// agreed names and are NOT duplicated:
///
///   currentPage  -> lastPageNumber
///   readingMode  -> lastMode
///   lastReadAt   -> updatedAt
///
/// Keeping one source of truth per concept avoids two fields drifting apart.
/// `updatedAt` in particular is referenced by index I-5 and query Q7.
///
/// progress goes from 15 to 17 fields. No other collection is touched.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';
import '_schema_util.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildF,
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

void buildF(App app) {
  app.raw((project) {
    final progress = findCollectionByName(project, 'progress');
    if (progress == null) {
      throw StateError('Collection "progress" not found.');
    }
    final additions = <String, FFDataTypeV2>{
      // 0.0–100.0. Lets a shelf render a progress ring without loading the
      // story to learn its pageCount.
      'completionPercent': fsDouble,
      // First time this child opened this story, never overwritten after.
      // Distinct from updatedAt, which moves on every write.
      'startedAt': fsTimestamp,
    };
    for (final entry in additions.entries) {
      final exists = progress.fields.values.any(
        (f) => f.identifier.name == entry.key,
      );
      if (exists) continue;
      progress.fields[entry.key] = FFParameter(
        identifier: FFIdentifier(name: entry.key, key: entry.key),
        dataType: entry.value,
      );
    }
  });
}
