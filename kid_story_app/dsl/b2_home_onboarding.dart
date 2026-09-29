/// KidStoryApp — Batch B2: first-child onboarding on HomePage.
///
/// Replaces the unconditional `Navigate('StorySelectionPage')` on
/// "ابدأ المغامرة" with validate → create → navigate.
///
/// The ولد / بنت cards are an AVATAR picker, not a gender question. They had
/// no tap action at all before this (the only onTap on the page was the
/// navigate), so wiring them is purely additive. The choice persists through
/// `children.avatarId` using the canonical ids from FIREBASE_SCHEMA.md 4.1:
/// ولد -> avatar_01, بنت -> avatar_02. No gender value is written anywhere.
///
/// The age DropDown shipped with placeholder options
/// ['Option 1','Option 2','Option 3']; it is repointed at the three canonical
/// ageGroup values.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '../lib/flutterflow_project.dart' as ff;
import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildB2,
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

const _avatarBoy = 'avatar_01';
const _avatarGirl = 'avatar_02';

void buildB2(App app) {
  final home = ff.Pages.homePage;
  final children = ff.Collections.children;

  app.editPageState(home, (state) {
    // Live avatar choice for this form. Page state, not app state: the app
    // state copy is only written once the child document exists.
    state.ensureField('selectedAvatarId', string.withDefault(''));
    // Double-submit guard for the create.
    state.ensureField('isCreatingChild', bool_.withDefault(false));
  });

  app.editPage(home, (page) {
    // Plain names, not typed handles: these fields are created by the
    // editPageState call above in this same run, so the generated
    // HomePageState does not carry them yet.
    const selectedAvatarId = 'selectedAvatarId';
    const isCreatingChild = 'isCreatingChild';

    // Selections for editing...
    final ageDropdownSel = page.findByKey('DropDown_jb86mjhm');
    // ...and generated widget handles for reading runtime state. The
    // DropDown carries no name, so it can only be referenced by key.
    final nameField = 'childNameField';
    final ageDropdown =
        ff.Pages.homePage.widgets.byKey('DropDown_jb86mjhm').single;

    // ---- age options -----------------------------------------------------
    // EDITOR STEP: the DropDown still ships FlutterFlow's placeholder
    // options ['Option 1','Option 2','Option 3']. EditWidgetPatch exposes no
    // options/optionsLabels method, so they cannot be repointed from here.
    // Set them by hand to the three canonical ageGroup values — 1-2, 3-4,
    // 5-6 — with Arabic labels. Until then the age validation below rejects
    // nothing useful, because any placeholder option is a non-empty string.

    // ---- avatar cards ----------------------------------------------------
    page.ensureActions(
      page.findByKey('Container_vp8fv5c7'), // ولد
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [SetState(selectedAvatarId, _avatarBoy)],
    );
    page.ensureActions(
      page.findByKey('Container_7s6ybf7w'), // بنت
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [SetState(selectedAvatarId, _avatarGirl)],
    );

    // ---- ابدأ المغامرة ---------------------------------------------------
    page.ensureActions(
      page.findByKey('Row_a4bsh0hf'),
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        If(
          // Double-submit guard. Repeated taps while a create is in flight
          // do nothing, so two children can never be made from one form.
          Not(Equals(State(isCreatingChild), true)),
          then: [
            If(
              Equals(WidgetState(nameField, WidgetStateProperty.text), ''),
              then: [Snackbar('من فضلك اكتب اسم الطفل.')],
              orElse: [
                If(
                  Equals(State(selectedAvatarId), ''),
                  then: [Snackbar('من فضلك اختر صورة الطفل.')],
                  orElse: [
                    If(
                      Equals(
                          WidgetState(ageDropdown, WidgetStateProperty.value),
                          ''),
                      then: [Snackbar('من فضلك اختر عمر الطفل.')],
                      orElse: [
                        If(
                          Not(Equals(
                              Global(GlobalProperty.isUserLoggedIn), true)),
                          // No uid means no parent document to write under.
                          then: [
                            Snackbar('تعذّر حفظ ملف الطفل. حاول مرة أخرى.')
                          ],
                          orElse: [
                        SetState(isCreatingChild, true),
                        // users/{currentUserUid}/children/{autoId}, with
                        // exactly the six documented fields. No gender, no
                        // real name, no invented field.
                        FirestoreCreate(
                          children,
                          parentReference:
                              AuthUser(AuthUserField.documentReference),
                          fields: {
                            children.fields.nickname:
                                WidgetState(nameField, WidgetStateProperty.text),
                            children.fields.ageGroup: WidgetState(
                                ageDropdown, WidgetStateProperty.value),
                            children.fields.avatarId: State(selectedAvatarId),
                            children.fields.preferredMode: 'read',
                            children.fields.createdAt: Global(GlobalProperty.currentTimestamp),
                            children.fields.updatedAt: Global(GlobalProperty.currentTimestamp),
                          },
                          outputAs: 'createdChild',
                        ),
                        UpdateAppState.set(
                          'Name',
                          WidgetState(nameField, WidgetStateProperty.text),
                        ),
                        UpdateAppState.set(
                          'age',
                          WidgetState(ageDropdown, WidgetStateProperty.value),
                        ),
                        UpdateAppState.set(
                            'selectedAvatarId', State(selectedAvatarId)),
                        // EDITOR STEP: set selectedChildId from
                        // createdChild > Document ID here. The DSL cannot
                        // read a document id off an action output.
                        SetState(isCreatingChild, false),
                        Navigate(
                          ff.Pages.storySelectionPage,
                          replaceRoute: true,
                          allowBack: false,
                        ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });
}
