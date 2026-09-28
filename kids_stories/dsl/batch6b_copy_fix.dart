/// Kids Stories — Batch 6b: Arabic copy correction found in the audit.
///
/// The age chip on HomePage and the child row on ParentDashboardPage were
/// bound straight to `selectedAgeGroup`, which holds the machine id ("3-4").
/// Child- and parent-facing copy must be Arabic, so the selector now also
/// writes an Arabic label and those two places bind to it.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch6b,
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

void buildBatch6b(App app) {
  app.state(
    'selectedAgeGroupLabel',
    string.withDefault('٣–٤ سنوات'),
    description:
        'Arabic label of the selected age group, for child- and parent-facing '
        'copy. selectedAgeGroup keeps the machine id.',
  );

  // Each unselected age pill now writes both the id and the Arabic label.
  app.editComponent(ff.Components.ksageGroupSelector, (component) {
    component.ensureActions(
      ff.Components.ksageGroupSelector.widgets
          .byKey('Container_k45t1co2')
          .single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set(ff.AppState.selectedAgeGroup, '1-2'),
        UpdateAppState.set('selectedAgeGroupLabel', '١–٢ سنة'),
      ],
    );
    component.ensureActions(
      ff.Components.ksageGroupSelector.widgets
          .byKey('Container_mp2snmh7')
          .single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set(ff.AppState.selectedAgeGroup, '3-4'),
        UpdateAppState.set('selectedAgeGroupLabel', '٣–٤ سنوات'),
      ],
    );
    component.ensureActions(
      ff.Components.ksageGroupSelector.widgets
          .byKey('Container_slwnyjvv')
          .single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set(ff.AppState.selectedAgeGroup, '5-6'),
        UpdateAppState.set('selectedAgeGroupLabel', '٥–٦ سنوات'),
      ],
    );
  });

  // HomePage age chip shows the Arabic label.
  app.editPage(ff.Pages.homePage, (page) {
    page.bindText(
      ff.Pages.homePage.widgets.byKey('Text_go7m9714').single,
      AppState('selectedAgeGroupLabel'),
    );
  });

  // Parent dashboard child row: the age line under the nickname.
  app.editPage(ff.Pages.parentDashboardPage, (page) {
    page.bindText(
      ff.Pages.parentDashboardPage.widgets.byKey('Text_8xx8seol').single,
      AppState('selectedAgeGroupLabel'),
    );
  });
}
