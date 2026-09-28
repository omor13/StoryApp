/// Kids Stories — Rebuild R2: HomePage mirrored on the reference project.
///
/// The reference HomePage is the entry screen: a full-bleed illustrated
/// background with one cream form card carrying the child's name, age and
/// gender, and a single "ابدأ المغامرة" action. This replaces the shelf-style
/// HomePage the earlier phase built.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';
import '_ref_style.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildR2,
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

void buildR2(App app) {
  app.editPage(ff.Pages.homePage, (page) {
    // The reference has no app bar — the header lives in the body.
    page.ensureRemoved(
      ff.Pages.homePage.widgets.byPath('HomePage.appBar[0]').single,
    );

    page.ensureReplaced(
      ff.Pages.homePage.widgets.byPath('HomePage.body[0]').single,
      Container(
        name: 'mainStack',
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ---- Full-bleed background -------------------------------
            Image(
              kBgHomeMobile,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: double.infinity,
              name: 'backgroundImageMobile',
            ),
            // ---- The one form card -----------------------------------
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                scrollable: true,
                crossAxis: CrossAxis.stretch,
                mainAxis: MainAxis.center,
                children: [
                  creamCard(
                    name: 'formCard',
                    padding: EdgeInsets.all(22),
                    child: Column(
                      name: 'formContent',
                      crossAxis: CrossAxis.stretch,
                      spacing: 14,
                      children: [
                        // ---- Name --------------------------------------
                        fieldLabel(
                          name: 'nameHeader',
                          labelAr: 'اسم الطفل :',
                          imagePath: kAvatarBoy,
                        ),
                        Container(
                          height: 56,
                          borderRadius: 18,
                          color: Colors.hex(kCreamLight),
                          borderColor: Colors.tertiary,
                          borderWidth: 1.5,
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          child: TextField(
                            name: 'childNameField',
                            hint: 'اكتب اسم الطفل',
                            keyboard: Keyboard.text,
                            // Written as the parent types: a replacement tree
                            // cannot read a widget it is creating in the same
                            // run, so the field feeds app state directly.
                            onChanged: [
                              UpdateAppState.set(
                                ff.AppState.childNickname,
                                TextValue(),
                              ),
                            ],
                          ),
                        ),
                        starDivider(name: 'HeaderDividerRow'),

                        // ---- Age ---------------------------------------
                        fieldLabel(
                          name: 'ageheader',
                          labelAr: 'عُمر الطفل :',
                          imagePath: kIconCake,
                        ),
                        Container(
                          height: 56,
                          borderRadius: 18,
                          color: Colors.hex(kCreamLight),
                          borderColor: Colors.tertiary,
                          borderWidth: 1.5,
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          child: Dropdown(
                            name: 'ageDropdown',
                            options: const [
                              '١–٢ سنة',
                              '٣–٤ سنوات',
                              '٥–٦ سنوات',
                            ],
                            hint: 'اختر العمر',
                            onChanged: [
                              UpdateAppState.set(
                                ff.AppState.selectedAgeGroupLabel,
                                WidgetValue(),
                              ),
                            ],
                          ),
                        ),
                        starDivider(name: 'HeaderDividerRow2'),

                        // ---- Gender ------------------------------------
                        fieldLabel(
                          name: 'gender',
                          labelAr: 'الجنس :',
                          imagePath: kCover1,
                        ),
                        Row(
                          name: 'genderSelectionRow',
                          mainAxis: MainAxis.spaceEvenly,
                          crossAxis: CrossAxis.center,
                          spacing: 12,
                          children: [
                            Expanded(
                              _genderTile(
                                name: 'boy',
                                labelAr: 'ولد',
                                imagePath: kAvatarBoy,
                                value: 'boy',
                              ),
                            ),
                            Expanded(
                              _genderTile(
                                name: 'Containergirl',
                                labelAr: 'بنت',
                                imagePath: kAvatarGirl,
                                value: 'girl',
                              ),
                            ),
                          ],
                        ),

                        // ---- Single primary action ---------------------
                        Container(
                          name: 'startAdventureButton',
                          height: 66,
                          borderRadius: 999,
                          color: Colors.primary,
                          alignment: Alignment.center,
                          shadow: cardShadow(),
                          onTap: [Navigate(ff.Pages.storySelectionPage)],
                          child: Row(
                            mainAxis: MainAxis.center,
                            crossAxis: CrossAxis.center,
                            spacing: 10,
                            children: [
                              Text(
                                'ابدأ المغامرة',
                                style: Styles.titleMedium,
                                color: Colors.hex(kWhite),
                                maxLines: 1,
                              ),
                              Image(
                                kIconBook,
                                isNetwork: false,
                                width: 36,
                                height: 36,
                                fit: ImageFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}

/// One gender tile — selected state shows a purple border plus a check, so the
/// state never rides on colour alone.
DslWidget _genderTile({
  required String name,
  required String labelAr,
  required String imagePath,
  required String value,
}) => Container(
  name: name,
  height: 104,
  borderRadius: 22,
  color: Colors.hex(kCreamLight),
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  onTap: [UpdateAppState.set(ff.AppState.childGender, value)],
  child: Stack(
    alignment: Alignment.center,
    children: [
      Container(
        borderRadius: 22,
        borderColor: Colors.tertiary,
        borderWidth: 1.5,
        visible: Not(Equals(AppState(ff.AppState.childGender), value)),
      ),
      Container(
        borderRadius: 22,
        borderColor: Colors.primary,
        borderWidth: 3,
        visible: Equals(AppState(ff.AppState.childGender), value),
      ),
      Row(
        mainAxis: MainAxis.center,
        crossAxis: CrossAxis.center,
        spacing: 8,
        children: [
          Text(
            labelAr,
            style: Styles.titleSmall,
            color: Colors.accent2,
            maxLines: 1,
          ),
          Image(imagePath, isNetwork: false, width: 56, height: 56),
        ],
      ),
      Container(
        alignment: Alignment.topLeft,
        visible: Equals(AppState(ff.AppState.childGender), value),
        child: Icon('check_circle', size: 22, color: Colors.primary),
      ),
    ],
  ),
);
