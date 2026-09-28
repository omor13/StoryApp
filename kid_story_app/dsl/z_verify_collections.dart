/// KidStoryApp — read-only diagnostic: print each Firestore collection with
/// its map key, identifier key, parent name and parent key, plus its fields.
///
/// Run with --dry-run only; the raw callback reads and prints, never mutates.
/// The generated typed SDK exposes collections as a flat list and hides
/// `parentCollectionIdentifier`, which is the field that proves nesting.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildVerify,
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

void buildVerify(App app) {
  app.raw((project) {
    final cols = project.ensureBackend().collections;
    stdout.writeln('### COLLECTION REPORT (${cols.length} total)');
    final entries = cols.entries.toList()
      ..sort((a, b) => a.value.identifier.name.compareTo(b.value.identifier.name));
    for (final e in entries) {
      final c = e.value;
      final pName = c.parentCollectionIdentifier.name;
      final pKey = c.parentCollectionIdentifier.key;
      final path = pName.isEmpty
          ? c.identifier.name
          : '$pName/{id}/${c.identifier.name}';
      final fields = c.fields.values.map((f) => f.identifier.name).toList()
        ..sort();
      stdout.writeln('  PATH   : $path');
      stdout.writeln('    mapKey : ${e.key}');
      stdout.writeln('    idKey  : ${c.identifier.key}');
      stdout.writeln('    parent : ${pName.isEmpty ? "(top-level)" : pName}');
      stdout.writeln('    pKey   : ${pKey.isEmpty ? "-" : pKey}');
      stdout.writeln('    fields : ${fields.length} -> ${fields.join(", ")}');
    }
    stdout.writeln('### END REPORT');
  });
}
