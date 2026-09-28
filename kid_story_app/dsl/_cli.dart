/// Shared CLI boilerplate for the Kids Stories batch scripts.
///
/// Every batch file parses the same flags, so the option parsing lives here
/// instead of being copy-pasted into each script.
library;

import 'dart:io';

final class CliOptions {
  const CliOptions({
    this.apiKey,
    this.baseUrl,
    this.projectName,
    this.projectId,
    this.findOrCreate = false,
    this.allowNewProject = false,
    this.dryRun = false,
    this.commitMessage,
  });

  final String? apiKey;
  final String? baseUrl;
  final String? projectName;
  final String? projectId;
  final bool findOrCreate;
  final bool allowNewProject;
  final bool dryRun;
  final String? commitMessage;
}

CliOptions parseCliOptions(List<String> args) {
  String? apiKey;
  String? baseUrl;
  String? projectName;
  String? projectId;
  String? commitMessage;
  var findOrCreate = false;
  var allowNewProject = false;
  var dryRun = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--help':
      case '-h':
        printUsage();
        exit(0);
      case '--api-key':
        apiKey = requireValue(args, ++i, '--api-key');
      case '--base-url':
        baseUrl = requireValue(args, ++i, '--base-url');
      case '--project-name':
        projectName = requireValue(args, ++i, '--project-name');
      case '--project-id':
        projectId = requireValue(args, ++i, '--project-id');
      case '--commit-message':
        commitMessage = requireValue(args, ++i, '--commit-message');
      case '--find-or-create':
        findOrCreate = true;
      case '--allow-new-project':
        allowNewProject = true;
      case '--dry-run':
        dryRun = true;
      default:
        stderr.writeln('Unknown option: $arg');
        printUsage();
        exit(64);
    }
  }

  return CliOptions(
    apiKey: apiKey,
    baseUrl: baseUrl,
    projectName: projectName,
    projectId: projectId,
    findOrCreate: findOrCreate,
    allowNewProject: allowNewProject,
    dryRun: dryRun,
    commitMessage: commitMessage,
  );
}

String requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    stderr.writeln('Missing value for $flag.');
    printUsage();
    exit(64);
  }
  return args[index];
}

void printUsage() {
  stdout.writeln('''
Run a Kids Stories FlutterFlow AI batch script.

Options:
  --api-key <key>           FlutterFlow API key. Defaults to FF_API_KEY.
  --base-url <url>          Override the FlutterFlow API base URL.
  --project-id <id>         Push into an existing project by ID.
  --commit-message <text>   Commit message for the push.
  --dry-run                 Compile and validate without pushing.
  --help, -h                Show this help.
''');
}
