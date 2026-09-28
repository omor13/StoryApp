/// Kids Stories — Rebuild R2: the two pages the reference has and we did not.
///
/// `setting`            — background image + one cream settings card whose rows
///                        are illustration + title + subtitle.
/// `StorySelectionPage` — header bar, star divider, and a Wrap of story cards
///                        (cover on top, cream text area underneath).
///
/// Created before HomePage is rewired, because the DSL resolves navigation
/// targets against pages that already exist.
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
  app.state(
    'childGender',
    string.withDefault('boy'),
    description: 'Prototype only: boy / girl, as the reference HomePage asks.',
  );

  // =========================================================================
  // setting
  // =========================================================================
  final settingPage = app.page(
    'setting',
    route: '/setting',
    description:
        'Parent settings, mirrored on the reference: illustrated background '
        'with one cream card of tappable rows.',
    body: Scaffold(
      body: Container(
        name: 'mainStack',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              kBgSettings,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: double.infinity,
              name: 'mobileBackground',
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                scrollable: true,
                crossAxis: CrossAxis.stretch,
                spacing: 16,
                children: [
                  creamCard(
                    name: 'settingsCard',
                    child: Column(
                      name: 'settingsContent',
                      crossAxis: CrossAxis.stretch,
                      spacing: 14,
                      children: [
                        Row(
                          name: 'settingsTitleRow',
                          mainAxis: MainAxis.center,
                          crossAxis: CrossAxis.center,
                          spacing: 10,
                          children: [
                            Icon(
                              'star_rounded',
                              size: 24,
                              color: Colors.tertiary,
                            ),
                            Text(
                              'الإعدادات',
                              style: Styles.titleLarge,
                              color: Colors.accent4,
                              maxLines: 1,
                            ),
                            Icon(
                              'star_rounded',
                              size: 24,
                              color: Colors.tertiary,
                            ),
                          ],
                        ),
                        starDivider(),
                        _settingRow(
                          name: 'childInformationItem',
                          titleAr: 'معلومات الطفل',
                          subtitleAr: 'بيانات الطفل',
                          imagePath: kAvatarBoy,
                          onTap: [Navigate(ff.Pages.homePage)],
                        ),
                        _settingRow(
                          name: 'languageItem',
                          titleAr: 'اللغة',
                          subtitleAr: 'اختر لغة التطبيق',
                          imagePath: kIconMoon,
                          onTap: [
                            ShowDialog.message(
                              title: 'اللغة',
                              message: 'العربية هي لغة النموذج الأولي.',
                              dismissText: 'حسنًا',
                            ),
                          ],
                        ),
                        _settingRow(
                          name: 'aboutAppItem',
                          titleAr: 'عن التطبيق',
                          subtitleAr: 'معلومات مختصرة',
                          imagePath: kIconBook,
                          onTap: [
                            ShowDialog.message(
                              title: 'عن التطبيق',
                              message:
                                  'Kids Stories — قصص عربية قصيرة للأطفال. '
                                  'نموذج أولي للتصميم.',
                              dismissText: 'إغلاق',
                            ),
                          ],
                        ),
                        _settingRow(
                          name: 'subscriptionItem',
                          titleAr: 'الاشتراك',
                          subtitleAr: 'إدارة البرنامج',
                          imagePath: kIconCalendar,
                          onTap: [
                            Snackbar('صفحة الاشتراك تُنشأ في الدفعة التالية'),
                          ],
                        ),
                        _settingRow(
                          name: 'favoritesItem',
                          titleAr: 'المفضلة',
                          subtitleAr: 'القصص المحفوظة',
                          imagePath: kCover2,
                          onTap: [Navigate(ff.Pages.favoritesPage)],
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
    ),
  );

  // =========================================================================
  // StorySelectionPage
  // =========================================================================
  app.page(
    'StorySelectionPage',
    route: '/story-selection',
    description:
        'Story shelf mirrored on the reference: header bar, star divider and a '
        'Wrap of cover cards with an Arabic title and one-line description.',
    body: Scaffold(
      body: Container(
        name: 'MainBackgroundContainer',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              kBgTablet,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: double.infinity,
              name: 'selectionBackground',
            ),
            Column(
              name: 'MainColumn',
              crossAxis: CrossAxis.stretch,
              children: [
                headerBar(
                  titleAr: 'اختر قصة لطفلك',
                  rightButton: headerButton(
                    name: 'BackButtonContainer',
                    iconName: 'arrow_forward',
                    captionAr: 'رجوع',
                    onTap: [Navigate(ff.Pages.homePage)],
                  ),
                  leftButton: headerButton(
                    name: 'SettingsButtonContainer',
                    iconName: 'settings_rounded',
                    captionAr: 'الإعدادات',
                    onTap: [Navigate(settingPage)],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: starDivider(name: 'HeaderDividerRow'),
                ),
                Container(name: 'HeaderGap', height: 12),
                Expanded(
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      scrollable: true,
                      crossAxis: CrossAxis.stretch,
                      spacing: 14,
                      children: [
                        Row(
                          spacing: 14,
                          crossAxis: CrossAxis.start,
                          children: [
                            Expanded(
                              _storyCard(
                                name: 'StoryCard1',
                                titleAr: 'ليلى والنجمة الصغيرة',
                                descAr: 'حكاية عن المساعدة والصداقة والشجاعة.',
                                cover: kCover1,
                                access: 'free',
                                storyId: 'laila-star',
                              ),
                            ),
                            Expanded(
                              _storyCard(
                                name: 'StoryCard2',
                                titleAr: 'الأرنب الذي نسي قبعته',
                                descAr: 'حكاية مرحة عن التعاون والانتباه.',
                                cover: kCover2,
                                access: 'free',
                                storyId: 'rabbit-hat',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 14,
                          crossAxis: CrossAxis.start,
                          children: [
                            Expanded(
                              _storyCard(
                                name: 'StoryCard3',
                                titleAr: 'رحلة القمر إلى البحر',
                                descAr: 'مغامرة هادئة قبل النوم.',
                                cover: kCover3,
                                access: 'premium',
                                storyId: 'moon-sea',
                              ),
                            ),
                            Expanded(
                              _storyCard(
                                name: 'StoryCard4',
                                titleAr: 'سر الفانوس الذهبي',
                                descAr: 'حكاية عن الصبر ومساعدة الآخرين.',
                                cover: kCover4,
                                access: 'premium',
                                storyId: 'golden-lantern',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Local builders
// ---------------------------------------------------------------------------

/// One settings row: illustration, title, subtitle, chevron.
DslWidget _settingRow({
  required String name,
  required String titleAr,
  required String subtitleAr,
  required String imagePath,
  required List<DslAction> onTap,
}) => Container(
  name: name,
  height: 84,
  borderRadius: 22,
  color: Colors.hex(kCreamLight),
  borderColor: Colors.tertiary,
  borderWidth: 1.5,
  padding: EdgeInsets.symmetric(horizontal: 14),
  onTap: onTap,
  child: Row(
    crossAxis: CrossAxis.center,
    spacing: 12,
    children: [
      Image(
        imagePath,
        isNetwork: false,
        width: 54,
        height: 54,
        borderRadius: 16,
      ),
      Expanded(
        Column(
          crossAxis: CrossAxis.start,
          mainAxis: MainAxis.center,
          spacing: 2,
          children: [
            Text(
              titleAr,
              style: Styles.titleSmall,
              color: Colors.accent2,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitleAr,
              style: Styles.bodySmall,
              color: Colors.secondaryText,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      Icon('chevron_left', size: 24, color: Colors.primary),
    ],
  ),
);

/// One shelf card: cover image on top, cream text area underneath, plus a
/// lock badge for premium stories (icon + Arabic word, never colour alone).
DslWidget _storyCard({
  required String name,
  required String titleAr,
  required String descAr,
  required String cover,
  required String access,
  required String storyId,
}) => Container(
  name: name,
  borderRadius: 24,
  color: Colors.primaryBackground,
  shadow: cardShadow(),
  onTap: [
    UpdateAppState.set(ff.AppState.selectedStoryId, storyId),
    UpdateAppState.set(ff.AppState.selectedStoryTitle, titleAr),
    UpdateAppState.set(ff.AppState.selectedStoryDescription, descAr),
    UpdateAppState.set(ff.AppState.selectedStoryAccess, access),
    UpdateAppState.set(ff.AppState.currentStoryPage, 0),
    Navigate(ff.Pages.storyReaderPage),
  ],
  child: Column(
    crossAxis: CrossAxis.stretch,
    children: [
      Container(
        height: 168,
        borderRadius: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              cover,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: 168,
              borderRadius: 24,
            ),
            Container(
              alignment: Alignment.topRight,
              padding: EdgeInsets.all(8),
              visible: access == 'premium' ? true : false,
              child: Container(
                borderRadius: 999,
                color: Colors.tertiary,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  spacing: 5,
                  crossAxis: CrossAxis.center,
                  children: [
                    Icon('lock', size: 16, color: Colors.hex(kIndigo)),
                    Text(
                      'مميزة',
                      style: Styles.labelSmall,
                      color: Colors.hex(kIndigo),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        name: 'TextArea',
        height: 100,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxis: CrossAxis.start,
          spacing: 4,
          children: [
            Text(
              titleAr,
              style: Styles.titleSmall,
              color: Colors.accent2,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              descAr,
              style: Styles.bodySmall,
              color: Colors.primaryText,
              textAlign: TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  ),
);
