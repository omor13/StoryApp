/// Kids Stories — Rebuild R5: StoryReaderPage and FavoritesPage in the
/// reference design.
///
/// Reader  — header bar (home / favourite), a 300 tall image card, a 250 tall
///           cream text card, then the reference navigation row: previous and
///           next as captioned tiles with a listen pill between them.
/// Favorites — header bar, a count card with a sort chip, then story rows.
///
/// The three-page local story logic from the earlier phase is preserved: page
/// state still drives the text, previous is disabled on page one and the last
/// page swaps next for انتهت الحكاية.
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
      buildR5,
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

const String kPage1 =
    'في مساءٍ هادئ، رأت ليلى نجمةً صغيرةً تلمع قرب نافذتها.';
const String kPage2 =
    'قالت النجمة: أضعتُ طريقي إلى السماء. هل تساعدينني؟';
const String kPage3 =
    'رفعت ليلى الفانوس، فعادت النجمة إلى مكانها وهي تقول: شكرًا يا صديقتي!';

void buildR5(App app) {
  // =========================================================================
  // StoryReaderPage
  // =========================================================================
  app.editPage(ff.Pages.storyReaderPage, (page) {
    page.ensureReplaced(
      ff.Pages.storyReaderPage.widgets.byPath('StoryReaderPage.body[0]').single,
      Container(
        name: 'ReaderRoot',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              kBgTablet,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: double.infinity,
              name: 'readerBackground',
            ),
            Column(
              crossAxis: CrossAxis.stretch,
              children: [
                headerBar(
                  titleAr: 'قصة ليلى والنجمة الصغيرة',
                  rightButton: headerButton(
                    name: 'ReaderHomeButton',
                    iconName: 'home',
                    captionAr: 'الرئيسية',
                    onTap: [
                      UpdateAppState.set(ff.AppState.isNarrating, false),
                      Navigate(ff.Pages.homePage),
                    ],
                  ),
                  leftButton: headerButton(
                    name: 'ReaderFavoriteButton',
                    iconName: 'favorite',
                    captionAr: 'المفضلة',
                    onTap: [
                      UpdateAppState.set(
                        ff.AppState.isSelectedStoryFavorite,
                        true,
                      ),
                      Navigate(ff.Pages.favoritesPage),
                    ],
                  ),
                ),
                Expanded(
                  Container(
                    name: 'ReaderContentArea',
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      scrollable: true,
                      crossAxis: CrossAxis.stretch,
                      spacing: 14,
                      children: [
                        // ---- Illustration card -----------------------
                        Container(
                          name: 'storyImageCard',
                          height: 300,
                          borderRadius: 28,
                          color: Colors.primaryBackground,
                          shadow: cardShadow(),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image(
                                kCover1,
                                isNetwork: false,
                                fit: ImageFit.cover,
                                width: double.infinity,
                                height: 300,
                                borderRadius: 28,
                                visible: Equals(
                                  AppState(ff.AppState.currentStoryPage),
                                  0,
                                ),
                              ),
                              Image(
                                kCover2,
                                isNetwork: false,
                                fit: ImageFit.cover,
                                width: double.infinity,
                                height: 300,
                                borderRadius: 28,
                                visible: Equals(
                                  AppState(ff.AppState.currentStoryPage),
                                  1,
                                ),
                              ),
                              Image(
                                kCover4,
                                isNetwork: false,
                                fit: ImageFit.cover,
                                width: double.infinity,
                                height: 300,
                                borderRadius: 28,
                                visible: Equals(
                                  AppState(ff.AppState.currentStoryPage),
                                  2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ---- Story text card -------------------------
                        Container(
                          name: 'storyTextCard',
                          height: 250,
                          borderRadius: 28,
                          color: Colors.primaryBackground,
                          padding: EdgeInsets.all(20),
                          shadow: cardShadow(),
                          child: Column(
                            crossAxis: CrossAxis.stretch,
                            mainAxis: MainAxis.center,
                            spacing: 10,
                            children: [
                              _pageText(kPage1, 0, 'storyTextPage1'),
                              _pageText(kPage2, 1, 'storyTextPage2'),
                              _pageText(kPage3, 2, 'storyTextPage3'),
                              Row(
                                mainAxis: MainAxis.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    'الصفحة',
                                    style: Styles.bodySmall,
                                    color: Colors.secondaryText,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '١',
                                    style: Styles.bodySmall,
                                    color: Colors.secondaryText,
                                    maxLines: 1,
                                    visible: Equals(
                                      AppState(ff.AppState.currentStoryPage),
                                      0,
                                    ),
                                  ),
                                  Text(
                                    '٢',
                                    style: Styles.bodySmall,
                                    color: Colors.secondaryText,
                                    maxLines: 1,
                                    visible: Equals(
                                      AppState(ff.AppState.currentStoryPage),
                                      1,
                                    ),
                                  ),
                                  Text(
                                    '٣',
                                    style: Styles.bodySmall,
                                    color: Colors.secondaryText,
                                    maxLines: 1,
                                    visible: Equals(
                                      AppState(ff.AppState.currentStoryPage),
                                      2,
                                    ),
                                  ),
                                  Text(
                                    'من ٣',
                                    style: Styles.bodySmall,
                                    color: Colors.secondaryText,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ---- Navigation row, the reference layout -------------
                Container(
                  name: 'navigationRow',
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxis: MainAxis.spaceBetween,
                    crossAxis: CrossAxis.center,
                    children: [
                      // First child renders on the right under RTL.
                      _navTile(
                        name: 'PreviousTile',
                        iconName: 'arrow_forward_rounded',
                        captionAr: 'الصفحة السابقة',
                        dimmedWhenFirst: true,
                        onTap: [
                          If(
                            Equals(AppState(ff.AppState.currentStoryPage), 1),
                            then: [
                              UpdateAppState.set(
                                ff.AppState.currentStoryPage,
                                0,
                              ),
                            ],
                            orElse: [
                              If(
                                Equals(
                                  AppState(ff.AppState.currentStoryPage),
                                  2,
                                ),
                                then: [
                                  UpdateAppState.set(
                                    ff.AppState.currentStoryPage,
                                    1,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Listen pill, prototype only.
                      Container(
                        name: 'ListenPill',
                        width: 200,
                        height: 68,
                        borderRadius: 999,
                        color: Colors.primary,
                        alignment: Alignment.center,
                        shadow: chipShadow(),
                        onTap: [
                          Snackbar('الصوت غير مفعّل في النموذج الأولي'),
                        ],
                        child: Row(
                          mainAxis: MainAxis.center,
                          crossAxis: CrossAxis.center,
                          spacing: 10,
                          children: [
                            Icon(
                              'headphones_rounded',
                              size: 28,
                              color: Colors.hex(kWhite),
                            ),
                            Text(
                              'استمع للقصة',
                              style: Styles.titleMedium,
                              color: Colors.hex(kWhite),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // Next / end of story.
                      Column(
                        crossAxis: CrossAxis.center,
                        spacing: 4,
                        children: [
                          Container(
                            name: 'NextTile',
                            width: 62,
                            height: 62,
                            borderRadius: 20,
                            color: Colors.primaryBackground,
                            alignment: Alignment.center,
                            shadow: chipShadow(),
                            visible: Not(
                              Equals(
                                AppState(ff.AppState.currentStoryPage),
                                2,
                              ),
                            ),
                            onTap: [
                              If(
                                Equals(
                                  AppState(ff.AppState.currentStoryPage),
                                  0,
                                ),
                                then: [
                                  UpdateAppState.set(
                                    ff.AppState.currentStoryPage,
                                    1,
                                  ),
                                ],
                                orElse: [
                                  UpdateAppState.set(
                                    ff.AppState.currentStoryPage,
                                    2,
                                  ),
                                ],
                              ),
                            ],
                            child: Icon(
                              'arrow_back_rounded',
                              size: 30,
                              color: Colors.primary,
                            ),
                          ),
                          Container(
                            name: 'FinishTile',
                            height: 62,
                            borderRadius: 20,
                            color: Colors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            shadow: chipShadow(),
                            visible: Equals(
                              AppState(ff.AppState.currentStoryPage),
                              2,
                            ),
                            onTap: [
                              ShowDialog.message(
                                title: 'انتهت الحكاية!',
                                message: 'أحسنت! هل تحب أن تقرأ حكاية أخرى؟',
                                dismissText: 'حسنًا',
                              ),
                              UpdateAppState.set(
                                ff.AppState.currentStoryPage,
                                0,
                              ),
                              Navigate(ff.Pages.storySelectionPage),
                            ],
                            child: Text(
                              'انتهت الحكاية',
                              style: Styles.titleMedium,
                              color: Colors.hex(kWhite),
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            'الصفحة التالية',
                            style: Styles.labelSmall,
                            color: Colors.accent2,
                            maxLines: 1,
                            visible: Not(
                              Equals(
                                AppState(ff.AppState.currentStoryPage),
                                2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  });

  // =========================================================================
  // FavoritesPage
  // =========================================================================
  app.editPage(ff.Pages.favoritesPage, (page) {
    page.ensureReplaced(
      ff.Pages.favoritesPage.widgets.byPath('FavoritesPage.body[0]').single,
      Container(
        name: 'FavoritesRoot',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              kBgTablet,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: double.infinity,
              name: 'favoritesBackground',
            ),
            Column(
              crossAxis: CrossAxis.stretch,
              children: [
                headerBar(
                  titleAr: 'المفضلة',
                  titleIcon: 'favorite',
                  rightButton: headerButton(
                    name: 'FavHomeButton',
                    iconName: 'home',
                    captionAr: 'الرئيسية',
                    onTap: [Navigate(ff.Pages.homePage)],
                  ),
                  leftButton: headerButton(
                    name: 'FavSettingsButton',
                    iconName: 'settings',
                    captionAr: 'الإعدادات',
                    onTap: [Navigate(ff.Pages.setting)],
                  ),
                ),
                Expanded(
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      scrollable: true,
                      crossAxis: CrossAxis.stretch,
                      spacing: 14,
                      children: [
                        // ---- Count card + sort chip -------------------
                        Row(
                          name: 'favoriteInfoRow',
                          mainAxis: MainAxis.spaceBetween,
                          crossAxis: CrossAxis.center,
                          spacing: 10,
                          children: [
                            Expanded(
                              Container(
                                name: 'favoriteCountCard',
                                height: 76,
                                borderRadius: 22,
                                color: Colors.primaryBackground,
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                shadow: chipShadow(),
                                child: Row(
                                  crossAxis: CrossAxis.center,
                                  spacing: 12,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      borderRadius: 999,
                                      color: Colors.tertiary,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        'favorite',
                                        size: 26,
                                        color: Colors.primary,
                                      ),
                                    ),
                                    Expanded(
                                      Column(
                                        crossAxis: CrossAxis.start,
                                        mainAxis: MainAxis.center,
                                        children: [
                                          Text(
                                            'عدد القصص',
                                            style: Styles.bodySmall,
                                            color: Colors.secondaryText,
                                            textAlign: TextAlign.start,
                                            maxLines: 1,
                                          ),
                                          Text(
                                            '١',
                                            style: Styles.titleSmall,
                                            color: Colors.accent2,
                                            textAlign: TextAlign.start,
                                            maxLines: 1,
                                            visible: AppState(
                                              ff.AppState
                                                  .isSelectedStoryFavorite,
                                            ),
                                          ),
                                          Text(
                                            '٠',
                                            style: Styles.titleSmall,
                                            color: Colors.accent2,
                                            textAlign: TextAlign.start,
                                            maxLines: 1,
                                            visible: Not(
                                              AppState(
                                                ff.AppState
                                                    .isSelectedStoryFavorite,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              name: 'sortChip',
                              height: 76,
                              borderRadius: 22,
                              color: Colors.primaryBackground,
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              shadow: chipShadow(),
                              child: Row(
                                crossAxis: CrossAxis.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    'الأحدث أولاً',
                                    style: Styles.labelSmall,
                                    color: Colors.accent2,
                                    maxLines: 1,
                                  ),
                                  Icon(
                                    'keyboard_arrow_down',
                                    size: 22,
                                    color: Colors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // ---- One favourite row -----------------------
                        Container(
                          name: 'favoriteStoryCard',
                          borderRadius: 24,
                          color: Colors.primaryBackground,
                          padding: EdgeInsets.all(12),
                          shadow: cardShadow(),
                          visible: AppState(
                            ff.AppState.isSelectedStoryFavorite,
                          ),
                          onTap: [
                            UpdateAppState.set(
                              ff.AppState.currentStoryPage,
                              0,
                            ),
                            Navigate(ff.Pages.storyReaderPage),
                          ],
                          child: Row(
                            crossAxis: CrossAxis.center,
                            spacing: 12,
                            children: [
                              Image(
                                kCover1,
                                isNetwork: false,
                                width: 92,
                                height: 92,
                                borderRadius: 18,
                              ),
                              Expanded(
                                Column(
                                  crossAxis: CrossAxis.start,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      'قصة ليلى والنجمة الصغيرة',
                                      style: Styles.titleSmall,
                                      color: Colors.accent2,
                                      textAlign: TextAlign.start,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'رحلة صداقة مليئة بالحب والمغامرة',
                                      style: Styles.bodySmall,
                                      color: Colors.primaryText,
                                      textAlign: TextAlign.start,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      spacing: 6,
                                      crossAxis: CrossAxis.center,
                                      children: [
                                        Icon(
                                          'menu_book_rounded',
                                          size: 18,
                                          color: Colors.primary,
                                        ),
                                        Text(
                                          '٣ صفحات',
                                          style: Styles.labelSmall,
                                          color: Colors.secondaryText,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ---- Empty state ------------------------------
                        Container(
                          name: 'favoritesEmpty',
                          borderRadius: 24,
                          color: Colors.primaryBackground,
                          padding: EdgeInsets.all(24),
                          shadow: cardShadow(),
                          visible: Not(
                            AppState(ff.AppState.isSelectedStoryFavorite),
                          ),
                          child: Column(
                            crossAxis: CrossAxis.center,
                            spacing: 12,
                            children: [
                              Image(
                                kIconBook,
                                isNetwork: false,
                                width: 110,
                                height: 110,
                                fit: ImageFit.contain,
                              ),
                              Text(
                                'لم تضف أي حكاية إلى المفضلة بعد',
                                style: Styles.titleSmall,
                                color: Colors.accent2,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                              Text(
                                'اضغط على القلب أثناء القراءة لتحفظ حكايتك.',
                                style: Styles.bodySmall,
                                color: Colors.secondaryText,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                              Container(
                                height: 58,
                                borderRadius: 999,
                                color: Colors.primary,
                                padding: EdgeInsets.symmetric(horizontal: 22),
                                alignment: Alignment.center,
                                onTap: [
                                  Navigate(ff.Pages.storySelectionPage),
                                ],
                                child: Text(
                                  'تصفّح الحكايات',
                                  style: Styles.titleMedium,
                                  color: Colors.hex(kWhite),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
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
    );
  });
}

// ---------------------------------------------------------------------------
// Local builders
// ---------------------------------------------------------------------------

DslWidget _pageText(String textAr, int index, String name) => Text(
  textAr,
  style: Styles.bodyLarge,
  color: Colors.primaryText,
  textAlign: TextAlign.start,
  maxLines: 6,
  overflow: TextOverflow.ellipsis,
  name: name,
  visible: Equals(AppState(ff.AppState.currentStoryPage), index),
);

/// A captioned navigation tile. The previous tile dims on the first page.
DslWidget _navTile({
  required String name,
  required String iconName,
  required String captionAr,
  required bool dimmedWhenFirst,
  required List<DslAction> onTap,
}) => Column(
  crossAxis: CrossAxis.center,
  spacing: 4,
  children: [
    Container(
      name: name,
      width: 62,
      height: 62,
      borderRadius: 20,
      color: Colors.primaryBackground,
      alignment: Alignment.center,
      shadow: chipShadow(),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(iconName, size: 30, color: Colors.primary),
          Container(
            width: 62,
            height: 62,
            borderRadius: 20,
            color: Colors.hex(0xCCFDF5E7),
            visible: Equals(AppState(ff.AppState.currentStoryPage), 0),
          ),
        ],
      ),
    ),
    Text(
      captionAr,
      style: Styles.labelSmall,
      color: Colors.accent2,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ],
);
