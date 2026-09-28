/// Kids Stories — Rebuild R6: match the reference's page structure.
///
/// - Wires the settings "الاشتراك" row to the new subscription hub.
/// - Makes HomePage the entry page (the reference has no splash).
/// - Removes the six pages the reference does not have.
///
/// The removals are deliberate and were confirmed: SplashPage,
/// ChildProfileSetupPage, StoryDetailsPage, ParentGatePage, SubscriptionPage
/// and ParentDashboardPage. Every navigation into them was already replaced in
/// R4 and R5, so nothing is left dangling. They remain recoverable from the
/// project's commit history in FlutterFlow.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildR6,
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

void buildR6(App app) {
  // ---- Settings -> subscription hub -------------------------------------
  app.editPage(ff.Pages.setting, (page) {
    page.ensureActions(
      ff.Pages.setting.widgets.byKey('Container_xeyp61rw').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [Navigate(ff.Pages.subscription)],
    );
  });

  // ---- HomePage becomes the entry page ----------------------------------
  app.raw((project) {
    project.initialPageKeyRef = FFNodeKeyReference(key: 'Scaffold_ht2po5sa');
  });

  // ---- Drop the pages the reference does not have -----------------------
  app.removePage('SplashPage');
  app.removePage('ChildProfileSetupPage');
  app.removePage('StoryDetailsPage');
  app.removePage('ParentGatePage');
  app.removePage('SubscriptionPage');
  app.removePage('ParentDashboardPage');
}
