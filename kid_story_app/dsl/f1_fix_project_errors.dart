/// KidStoryApp — F1: clear the two project errors that block code generation.
///
/// `flutterflow export-code --project kid-story-app-vel697` fails with
/// HTTP 400 "Error generating code for the project. Make sure there are no
/// project errors." Nothing in `inspect --debug` reports them — its Preflight
/// Diagnostics section is empty on every page — so they were found by diffing
/// against a project that exports cleanly.
///
/// 1. `setting` > `logoutButton` (Container_ipdmxxb6) fires `auth: LOGOUT`
///    while the project has NO authentication configured (the project JSON
///    contains zero occurrences of "auth" or "firebase"). An auth action with
///    no auth provider is a hard project error.
///    -> remove the trigger. The button stays in place and gets re-wired when
///       anonymous auth lands; leaving the action would keep codegen broken.
///
/// 2. `HomePage` > `Containergirl` > inner Row (Row_to3qbtrk) carries an
///    incomplete "Update App State" action: `localStateUpdate` with
///    `updateType: WIDGET`, `stateVariableType: APP_STATE` and an EMPTY
///    `updates` array — it assigns nothing.
///    -> remove the trigger. Gender selection is unaffected: it is handled by
///       the parent container's widget-class `selectedGender` state, which
///       still writes and is still read back by the container colours.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kid_story_app/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildF1,
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

void buildF1(App app) {
  // 1. Logout action with no authentication provider.
  app.editPage(ff.Pages.setting, (page) {
    page.removeTrigger(
      ff.Pages.setting.widgets.byKey('Container_ipdmxxb6').single,
      FFActionTriggerType.ON_TAP,
    );
  });

  // 2. Incomplete app-state update that assigns no fields.
  app.editPage(ff.Pages.homePage, (page) {
    page.removeTrigger(
      ff.Pages.homePage.widgets.byKey('Row_to3qbtrk').single,
      FFActionTriggerType.ON_TAP,
    );
  });
}
