/// KidStoryApp — Batch B1a: make the AuthEntryPage retry actually reachable.
///
/// Found by reading the exported Dart after B1 landed. FlutterFlow emits
///
///     final user = await authManager.signInAnonymously(context);
///     if (user == null) { return; }
///
/// straight after a login action, so NOTHING later in that chain runs when
/// sign-in fails. Two consequences, both fixed here:
///
///  1. The `phase = 'failed'` detector was dead code, so the error card never
///     appeared and the page span forever on its spinner.
///  2. A retry guarded on `phase == 'failed'` could never fire, and any
///     pessimistic "attempt in flight" flag would deadlock for the same
///     reason — nothing can reset it after a failure.
///
/// Fix: the retry control is unconditional, and its guard is "there is still
/// no uid", which self-clears. The Arabic error text stays bound to
/// `phase == 'failed'` for the returned-user-without-uid case.
///
/// B1 used app.ensurePage, which no-ops once the page exists, so these
/// changes have to go through the edit APIs.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '../lib/flutterflow_project.dart' as ff;
import '_cli.dart';
import '_schema_util.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildB1a,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectId: options.projectId,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

void buildB1a(App app) {
  // ---- FlutterFlow's user-collection contract ----------------------------
  // Turning on Create User Document makes FlutterFlow validate the user
  // collection, and it REQUIRES photo_url and phone_number:
  //
  //   Collection for user ("users") must contain field "photo_url".
  //   Collection for user ("users") must contain field "phone_number".
  //
  // They are FlutterFlow's standard auth-user fields. Both stay NULL for an
  // anonymous user, and createUsersRecordData() drops nulls, so neither is
  // ever written by this flow — but the schema must declare them or the
  // configuration will not compile.
  //
  // Creating users/{uid} by hand instead is not an option: FirestoreCreate
  // exposes no document-ID parameter, so the DSL cannot write to a document
  // keyed by the uid.
  //
  // Neither field is a privileged key, so the deployed users rule is
  // unaffected and NO rules change is required.
  app.raw((project) {
    final users = findCollectionByName(project, 'users');
    if (users == null) {
      throw StateError('users collection not found');
    }
    // photo_url must be an ImagePath, not a String — FlutterFlow validates
    // the type as well as the presence.
    final required = <String, FFDataTypeV2>{
      'photo_url': FFDataTypeV2(scalarType: FFBaseDataType.ImagePath),
      'phone_number': fsString,
    };
    for (final entry in required.entries) {
      final present =
          users.fields.values.any((f) => f.identifier.name == entry.key);
      if (present) continue;
      users.fields[entry.key] = FFParameter(
        identifier: FFIdentifier(name: entry.key, key: entry.key),
        dataType: entry.value,
      );
    }
  });

  // ---- Phase 7, for real this time --------------------------------------
  // B1 used app.ensureFirebaseAuth, which is idempotent: Firebase auth was
  // ALREADY configured on this project (with no providers), so the call
  // no-opped and the routing never changed. The project was left on its old
  // config — homePage StorySelectionPage, signInPage HomePage, zero
  // providers. app.firebaseAuth UPDATES an existing configuration instead of
  // skipping it, which is what this needs.
  //
  // signInPage = logged-out Entry Page; homePage = Logged In Page.
  // Anonymous only: no email, phone, Google or Apple.
  app.firebaseAuth(
    providers: [FirebaseAuthProvider.anonymous],
    homePage: ff.Pages.appBootstrapPage,
    signInPage: ff.Pages.authEntryPage,
    autoCreateUserDocument: true,
    userCollectionName: 'users',
  );

  final phase = ff.Pages.authEntryPage.state.phase;

  app.editPage(ff.Pages.authEntryPage, (page) {
    // The card itself is always on screen; only the error sentence inside it
    // is conditional. Previously the whole card was gated on a flag that
    // could never be set, which hid the retry button too.
    page.bindVisible(page.findByKey('Container_rtpzfec1'), true);

    page.bindVisible(
      page.findByKey('Text_18z5a0zu'),
      Equals(State(phase), 'failed'),
    );

    page.ensureActions(
      page.findByKey('Button_ijldozx4'),
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        If(
          Equals(AuthUser(AuthUserField.userId), ''),
          then: [
            SetState(phase, 'loading'),
            LoginAnonymously(),
            If(
              Equals(AuthUser(AuthUserField.userId), ''),
              then: [SetState(phase, 'failed')],
            ),
          ],
          orElse: [
            Navigate(
              ff.Pages.appBootstrapPage,
              replaceRoute: true,
              allowBack: false,
            ),
          ],
        ),
      ],
    );
  });
}
