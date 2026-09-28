/// Kids Stories — Batch 4: StoryDetailsPage, StoryReaderPage, mock wiring.
///
/// StoryReaderPage is a working three-page prototype of
/// "ليلى والنجمة الصغيرة": next/previous move local page state, previous is
/// disabled on page 1, the last page swaps next for انتهت الحكاية, and finishing
/// opens a gentle completion dialog. No audio or TTS is connected.
///
/// This batch also rewires the HomePage story cards, which batch 3 left on
/// labelled prototype placeholders.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';
import '_ks.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch4,
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

const int kWhite = 0xFFFFFFFF;
const int kOutline = 0xFFE3D3B6;
const int kShadow = 0x2E0D1F45;
const int kStoryBlueDark = 0xFF122EA1;
const int kStoryBlue = 0xFF066CDE;
const int kTextDarkBlue = 0xFF0D1F45;
const int kScrim = 0x8C0D1F45;

Shadow softShadow() => Shadow(blur: 20, dy: 6, color: Colors.hex(kShadow));

Gradient nightSky() => Gradient.linear([
  GradientStop(Colors.hex(kTextDarkBlue), 0),
  GradientStop(Colors.hex(kStoryBlueDark), 0.55),
  GradientStop(Colors.hex(kStoryBlue), 1),
], angle: 90);

/// The three prototype pages of the sample story.
const String kPage1 =
    'في مساءٍ هادئ، رأت ليلى نجمةً صغيرةً تلمع قرب نافذتها.';
const String kPage2 =
    'قالت النجمة: أضعتُ طريقي إلى السماء. هل تساعدينني؟';
const String kPage3 =
    'رفعت ليلى الفانوس، فعادت النجمة إلى مكانها وهي تقول: شكرًا يا صديقتي!';

/// Selecting a story writes it into prototype app state, then opens details.
List<DslAction> _openStory({
  required String id,
  required String titleAr,
  required String descriptionAr,
  required String ageGroupLabel,
  required int minutes,
  required String access,
}) => [
  UpdateAppState.set(ff.AppState.selectedStoryId, id),
  UpdateAppState.set(ff.AppState.selectedStoryTitle, titleAr),
  UpdateAppState.set(ff.AppState.selectedStoryDescription, descriptionAr),
  UpdateAppState.set(ff.AppState.selectedStoryAgeGroup, ageGroupLabel),
  UpdateAppState.set(ff.AppState.selectedStoryMinutes, minutes),
  UpdateAppState.set(ff.AppState.selectedStoryAccess, access),
  Navigate(
    'StoryDetailsPage',
    transition: NavigateTransition(
      NavigateTransitionType.fadeIn,
      durationMillis: 260,
    ),
  ),
];

void buildBatch4(App app) {
  // Prototype favourite flag for the story currently open in the reader.
  // favoriteStoryIds stays a list for the library; this bool drives the
  // reader's two-state heart, which needs a boolean condition.
  app.state(
    'isSelectedStoryFavorite',
    bool_.withDefault(false),
    description: 'Prototype: is the open story marked as a favourite.',
  );

  // =========================================================================
  // StoryDetailsPage
  // =========================================================================
  app.page(
    'StoryDetailsPage',
    route: '/story-details',
    description:
        'Details for the story held in app state: placeholder cover, title, '
        'description, age group, duration, free/premium status and the reading '
        'mode selector. Free stories open the reader; premium stories route '
        'through the parent gate.',
    body: Scaffold(
      body: Container(
        name: 'DetailsBackground',
        color: Colors.primaryBackground,
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 20,
          padding: EdgeInsets.only(bottom: 24),
          children: [
            // ---- Large placeholder cover --------------------------------
            Container(
              name: 'DetailsCover',
              height: 260,
              gradient: nightSky(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon('auto_stories', size: 84, color: Colors.hex(kWhite)),
                  Container(
                    alignment: Alignment.topRight,
                    padding: EdgeInsets.all(12),
                    child: ksCircularIconButton.call(
                      name: 'DetailsBackButton',
                      iconName: 'previous',
                      variant: 'cream',
                      caption: 'رجوع',
                      enabled: true,
                      onPressed: [NavigateBack()],
                    ),
                  ),
                  Container(
                    alignment: Alignment.bottomLeft,
                    padding: EdgeInsets.all(10),
                    child: Container(
                      borderRadius: 8,
                      color: Colors.hex(kScrim),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        'رسم مؤقت',
                        style: Styles.labelSmall,
                        color: Colors.hex(kWhite),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Title, description, meta --------------------------------
            Container(
              name: 'DetailsContent',
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 16,
                children: [
                  Text(
                    AppState(ff.AppState.selectedStoryTitle),
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    name: 'DetailsTitle',
                  ),
                  Text(
                    AppState(ff.AppState.selectedStoryDescription),
                    style: Styles.bodyMedium,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.start,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    spacing: 8,
                    crossAxis: CrossAxis.center,
                    children: [
                      _metaChip(
                        iconName: 'child_care',
                        value: AppState(ff.AppState.selectedStoryAgeGroup),
                      ),
                      _metaChip(
                        iconName: 'schedule',
                        value: AppState(ff.AppState.selectedStoryMinutes),
                        suffixAr: 'دقائق',
                      ),
                      // Free / premium status — icon plus word, not colour.
                      Container(
                        borderRadius: 999,
                        color: Colors.alternate,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        visible: Equals(
                          AppState(ff.AppState.selectedStoryAccess),
                          'free',
                        ),
                        child: Row(
                          spacing: 6,
                          crossAxis: CrossAxis.center,
                          children: [
                            Icon(
                              'lock_open',
                              size: 18,
                              color: Colors.primary,
                            ),
                            Text(
                              'مجانية',
                              style: Styles.labelSmall,
                              color: Colors.primaryText,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        borderRadius: 999,
                        color: Colors.tertiary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        visible: Equals(
                          AppState(ff.AppState.selectedStoryAccess),
                          'premium',
                        ),
                        child: Row(
                          spacing: 6,
                          crossAxis: CrossAxis.center,
                          children: [
                            Icon(
                              'lock',
                              size: 18,
                              color: Colors.hex(kTextDarkBlue),
                            ),
                            Text(
                              'مميزة',
                              style: Styles.labelSmall,
                              color: Colors.hex(kTextDarkBlue),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ---- Reading mode --------------------------------------
                  Column(
                    crossAxis: CrossAxis.stretch,
                    spacing: 12,
                    children: [
                      Text(
                        'كيف تحب أن تقرأ؟',
                        style: Styles.titleLarge,
                        color: Colors.primaryText,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                      ),
                      ff.Components.ksreadingModeSelector(
                        name: 'DetailsModeSelector',
                      ),
                    ],
                  ),

                  // ---- Single primary action -----------------------------
                  // Free story -> reader.
                  ksPrimaryButton.call(
                    name: 'DetailsStartReadingButton',
                    label: 'ابدأ القراءة',
                    iconName: 'book',
                    enabled: true,
                    loading: false,
                    visible: Equals(
                      AppState(ff.AppState.selectedStoryAccess),
                      'free',
                    ),
                    onPressed: [
                      UpdateAppState.set(ff.AppState.currentStoryPage, 0),
                      Navigate(
                        'StoryReaderPage',
                        transition: NavigateTransition(
                          NavigateTransitionType.fadeIn,
                          durationMillis: 260,
                        ),
                      ),
                    ],
                  ),
                  // Premium story -> parent gate (wired in batch 5).
                  ksPrimaryButton.call(
                    name: 'DetailsUnlockButton',
                    label: 'افتح جميع القصص',
                    iconName: 'lock',
                    enabled: true,
                    loading: false,
                    visible: Equals(
                      AppState(ff.AppState.selectedStoryAccess),
                      'premium',
                    ),
                    onPressed: [
                      Snackbar('منطقة الأهل — تُوصَل في الدفعة الخامسة'),
                    ],
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
  // StoryReaderPage — working three-page prototype.
  // =========================================================================
  app.page(
    'StoryReaderPage',
    route: '/story-reader',
    description:
        'Three-page local reader for ليلى والنجمة الصغيرة. Page state drives '
        'the text, the indicator and the navigation; no audio is played.',
    body: Scaffold(
      body: Container(
        name: 'ReaderBackground',
        color: Colors.primaryBackground,
        child: Column(
          crossAxis: CrossAxis.stretch,
          children: [
            // ---- Top bar: home + title + favourite -----------------------
            Container(
              name: 'ReaderTopBar',
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxis: MainAxis.spaceBetween,
                crossAxis: CrossAxis.center,
                children: [
                  ksCircularIconButton.call(
                    name: 'ReaderHomeButton',
                    iconName: 'home',
                    variant: 'cream',
                    caption: 'الرئيسية',
                    enabled: true,
                    onPressed: [
                      UpdateAppState.set(ff.AppState.isNarrating, false),
                      Navigate('HomePage'),
                    ],
                  ),
                  Flexible(
                    Text(
                      AppState(ff.AppState.selectedStoryTitle),
                      style: Styles.titleLarge,
                      color: Colors.primaryText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      name: 'ReaderTitle',
                    ),
                  ),
                  // Favourite toggle — two states, never colour alone.
                  ksCircularIconButton.call(
                    name: 'ReaderFavoriteOff',
                    iconName: 'favoriteOff',
                    variant: 'cream',
                    caption: 'أضف للمفضلة',
                    enabled: true,
                    visible: Not(AppState('isSelectedStoryFavorite')),
                    onPressed: [
                      UpdateAppState.set('isSelectedStoryFavorite', true),
                      Snackbar('أُضيفت إلى المفضلة'),
                    ],
                  ),
                  ksCircularIconButton.call(
                    name: 'ReaderFavoriteOn',
                    iconName: 'favorite',
                    variant: 'cream',
                    caption: 'في المفضلة',
                    enabled: true,
                    visible: AppState('isSelectedStoryFavorite'),
                    onPressed: [
                      UpdateAppState.set('isSelectedStoryFavorite', false),
                      Snackbar('أُزيلت من المفضلة'),
                    ],
                  ),
                ],
              ),
            ),

            // ---- Scrollable reading area ---------------------------------
            Expanded(
              Container(
                name: 'ReaderContentArea',
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  scrollable: true,
                  crossAxis: CrossAxis.stretch,
                  spacing: 16,
                  children: [
                    // Large illustration placeholder — no text sits on it.
                    Container(
                      name: 'ReaderIllustration',
                      height: 200,
                      borderRadius: 24,
                      gradient: nightSky(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            'nightlight',
                            size: 72,
                            color: Colors.tertiary,
                            visible: Equals(
                              AppState(ff.AppState.currentStoryPage),
                              0,
                            ),
                          ),
                          Icon(
                            'star',
                            size: 72,
                            color: Colors.tertiary,
                            visible: Equals(
                              AppState(ff.AppState.currentStoryPage),
                              1,
                            ),
                          ),
                          Icon(
                            'lightbulb',
                            size: 72,
                            color: Colors.tertiary,
                            visible: Equals(
                              AppState(ff.AppState.currentStoryPage),
                              2,
                            ),
                          ),
                          Container(
                            alignment: Alignment.bottomLeft,
                            padding: EdgeInsets.all(10),
                            child: Container(
                              borderRadius: 8,
                              color: Colors.hex(kScrim),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                'رسم مؤقت',
                                style: Styles.labelSmall,
                                color: Colors.hex(kWhite),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // One opaque story-text card per page.
                    ff.Components.ksstoryTextCard(
                      name: 'ReaderTextPage1',
                      textAr: kPage1,
                      pageNumber: 1,
                      totalPages: 3,
                      visible: Equals(
                        AppState(ff.AppState.currentStoryPage),
                        0,
                      ),
                    ),
                    ff.Components.ksstoryTextCard(
                      name: 'ReaderTextPage2',
                      textAr: kPage2,
                      pageNumber: 2,
                      totalPages: 3,
                      visible: Equals(
                        AppState(ff.AppState.currentStoryPage),
                        1,
                      ),
                    ),
                    ff.Components.ksstoryTextCard(
                      name: 'ReaderTextPage3',
                      textAr: kPage3,
                      pageNumber: 3,
                      totalPages: 3,
                      visible: Equals(
                        AppState(ff.AppState.currentStoryPage),
                        2,
                      ),
                    ),

                    // Reading mode + prototype audio bar (listen mode only).
                    ff.Components.ksreadingModeSelector(
                      name: 'ReaderModeSelector',
                    ),
                    ff.Components.ksaudioControls(
                      name: 'ReaderAudioControls',
                      visible: Equals(
                        AppState(ff.AppState.readingMode),
                        'listen',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Page navigation -----------------------------------------
            // One instance per page so isFirst / isLast are literal and the
            // page indicator always matches the visible text card.
            _readerNav(
              instanceName: 'ReaderNavPage1',
              pageIndex: 0,
              pageNumber: 1,
              isFirst: true,
              isLast: false,
            ),
            _readerNav(
              instanceName: 'ReaderNavPage2',
              pageIndex: 1,
              pageNumber: 2,
              isFirst: false,
              isLast: false,
            ),
            _readerNav(
              instanceName: 'ReaderNavPage3',
              pageIndex: 2,
              pageNumber: 3,
              isFirst: false,
              isLast: true,
            ),
          ],
        ),
      ),
    ),
  );

  // =========================================================================
  // Rewire the HomePage cards now that the story pages exist.
  // =========================================================================
  app.editPage(ff.Pages.homePage, (page) {
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_mn0i8kxl').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: _openStory(
        id: 'laila-star',
        titleAr: 'ليلى والنجمة الصغيرة',
        descriptionAr: 'حكاية لطيفة عن المساعدة والصداقة والشجاعة.',
        ageGroupLabel: '٣–٤ سنوات',
        minutes: 4,
        access: 'free',
      ),
    );
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_8ov88ump').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: _openStory(
        id: 'laila-star',
        titleAr: 'ليلى والنجمة الصغيرة',
        descriptionAr: 'حكاية لطيفة عن المساعدة والصداقة والشجاعة.',
        ageGroupLabel: '٣–٤ سنوات',
        minutes: 4,
        access: 'free',
      ),
    );
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_bh6aksww').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: _openStory(
        id: 'rabbit-hat',
        titleAr: 'الأرنب الذي نسي قبعته',
        descriptionAr: 'حكاية مرحة عن التعاون والانتباه.',
        ageGroupLabel: '١–٢ سنة',
        minutes: 3,
        access: 'free',
      ),
    );
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_ng46z9l1').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: _openStory(
        id: 'moon-sea',
        titleAr: 'رحلة القمر إلى البحر',
        descriptionAr: 'مغامرة هادئة قبل النوم.',
        ageGroupLabel: '٥–٦ سنوات',
        minutes: 6,
        access: 'premium',
      ),
    );
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_ds38nmcp').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: _openStory(
        id: 'golden-lantern',
        titleAr: 'سر الفانوس الذهبي',
        descriptionAr: 'حكاية عن الصبر ومساعدة الآخرين.',
        ageGroupLabel: '٣–٤ سنوات',
        minutes: 5,
        access: 'premium',
      ),
    );
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_6nya1pkp').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: _openStory(
        id: 'drawing-cloud',
        titleAr: 'غيمة تحب الرسم',
        descriptionAr: 'حكاية عن الخيال والألوان.',
        ageGroupLabel: '٣–٤ سنوات',
        minutes: 4,
        access: 'premium',
      ),
    );
  });
}

// ---------------------------------------------------------------------------
// Local builders
// ---------------------------------------------------------------------------

DslWidget _metaChip({
  required String iconName,
  required Object value,
  String? suffixAr,
}) => Container(
  borderRadius: 999,
  color: Colors.alternate,
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Row(
    spacing: 6,
    crossAxis: CrossAxis.center,
    children: [
      Icon(iconName, size: 18, color: Colors.primary),
      Text(
        value,
        style: Styles.labelSmall,
        color: Colors.primaryText,
        maxLines: 1,
      ),
      if (suffixAr != null)
        Text(
          suffixAr,
          style: Styles.labelSmall,
          color: Colors.primaryText,
          maxLines: 1,
        ),
    ],
  ),
);

/// One KSPageNavigation instance, visible only on its own page.
DslWidget _readerNav({
  required String instanceName,
  required int pageIndex,
  required int pageNumber,
  required bool isFirst,
  required bool isLast,
}) => ksPageNavigation.call(
  name: instanceName,
  pageNumber: pageNumber,
  totalPages: 3,
  isFirst: isFirst,
  isLast: isLast,
  visible: Equals(AppState(ff.AppState.currentStoryPage), pageIndex),
  onPrevious: [
    UpdateAppState.set(ff.AppState.currentStoryPage, pageIndex - 1),
    UpdateAppState.set(ff.AppState.isNarrating, false),
  ],
  onNext: [
    UpdateAppState.set(ff.AppState.currentStoryPage, pageIndex + 1),
    UpdateAppState.set(ff.AppState.isNarrating, false),
  ],
  onFinish: [
    UpdateAppState.set(ff.AppState.isNarrating, false),
    ShowDialog.message(
      title: 'انتهت الحكاية!',
      message: 'أحسنت! هل تحب أن تقرأ حكاية أخرى؟',
      dismissText: 'حسنًا',
    ),
    UpdateAppState.set(ff.AppState.currentStoryPage, 0),
    Navigate('HomePage'),
  ],
);
