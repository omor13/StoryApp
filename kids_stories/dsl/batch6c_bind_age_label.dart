/// Kids Stories — Batch 6c: bind the two age-group readouts to the Arabic
/// label field.
///
/// Batch 6b declared `selectedAgeGroupLabel` and wired the selector to write
/// it, but the two `bindText` calls in the same run left the Text nodes on the
/// old field — the field did not exist yet when they compiled. This run binds
/// them through the now-generated typed handle.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch6c,
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

void buildBatch6c(App app) {
  // `bindText` no-ops on a node that is already bound to a state field, so
  // the two Text nodes are replaced outright (the key is preserved).
  app.editPage(ff.Pages.homePage, (page) {
    page.ensureReplaced(
      ff.Pages.homePage.widgets.byKey('Text_go7m9714').single,
      Text(
        AppState(ff.AppState.selectedAgeGroupLabel),
        style: Styles.labelSmall,
        color: Colors.hex(0xFFFFFFFF),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        name: 'HomeAgeChipText',
      ),
    );
  });

  app.editPage(ff.Pages.parentDashboardPage, (page) {
    page.ensureReplaced(
      ff.Pages.parentDashboardPage.widgets.byKey('Text_8xx8seol').single,
      Text(
        AppState(ff.AppState.selectedAgeGroupLabel),
        style: Styles.bodySmall,
        color: Colors.secondaryText,
        textAlign: TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        name: 'DashboardChildAgeText',
      ),
    );
  });
}
