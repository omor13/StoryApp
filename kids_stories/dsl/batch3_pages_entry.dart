/// Kids Stories — Batch 3: SplashPage, ChildProfileSetupPage, HomePage.
///
/// HomePage already existed in the project as FlutterFlow's blank placeholder,
/// so it is edited in place (body replaced, app bar retitled) rather than
/// declared again.
///
/// Actions that point at pages built in later batches (StoryDetailsPage,
/// FavoritesPage, ParentGatePage) are wired as clearly-labelled prototype
/// placeholders here and rewired in batches 4 and 5.
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
      buildBatch3,
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
const int kScrim = 0x8C0D1F45;
const int kStoryBlueDark = 0xFF122EA1;
const int kStoryBlue = 0xFF066CDE;
const int kTextDarkBlue = 0xFF0D1F45;

Shadow softShadow() => Shadow(blur: 20, dy: 6, color: Colors.hex(kShadow));

/// Night-sky placeholder background. Decorative only — no text sits on it.
Gradient nightSky() => Gradient.linear([
  GradientStop(Colors.hex(kTextDarkBlue), 0),
  GradientStop(Colors.hex(kStoryBlueDark), 0.55),
  GradientStop(Colors.hex(kStoryBlue), 1),
], angle: 90);

void buildBatch3(App app) {
  // =========================================================================
  // SplashPage
  // =========================================================================
  app.page(
    'SplashPage',
    route: '/',
    isInitial: true,
    description:
        'Brand splash. After a short delay it replaces itself with '
        'ChildProfileSetupPage. No authentication in this phase.',
    onLoad: [
      Wait(1600),
      Navigate(
        'ChildProfileSetupPage',
        replaceRoute: true,
        transition: NavigateTransition(
          NavigateTransitionType.fadeIn,
          durationMillis: 300,
        ),
      ),
    ],
    body: Scaffold(
      body: Container(
        name: 'SplashBackground',
        gradient: nightSky(),
        padding: EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxis: MainAxis.center,
          crossAxis: CrossAxis.center,
          spacing: 20,
          children: [
            // Placeholder brand mark: a book inside a soft star halo.
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 168,
                  height: 168,
                  borderRadius: 999,
                  color: Colors.hex(0x33FFFFFF),
                ),
                Container(
                  width: 128,
                  height: 128,
                  borderRadius: 999,
                  color: Colors.primaryBackground,
                  alignment: Alignment.center,
                  shadow: softShadow(),
                  child: Icon('auto_stories', size: 64, color: Colors.primary),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Icon('star', size: 30, color: Colors.tertiary),
                ),
                Container(
                  alignment: Alignment.bottomRight,
                  child: Icon('star', size: 22, color: Colors.tertiary),
                ),
              ],
            ),
            // The product name stays in English by design.
            Text(
              'Kids Stories',
              style: Styles.headlineMedium,
              color: Colors.hex(kWhite),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            Text(
              'قصص عربية صغيرة لعالم كبير من الخيال',
              style: Styles.bodyMedium,
              color: Colors.hex(kWhite),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            ProgressBar.circular(size: 36, thickness: 3),
          ],
        ),
      ),
    ),
  );

  // =========================================================================
  // ChildProfileSetupPage
  // =========================================================================
  app.page(
    'ChildProfileSetupPage',
    route: '/child-profile-setup',
    description:
        'Prototype onboarding: optional nickname, age group and a built-in '
        'avatar. Nothing is stored outside local app state; no full name, '
        'birth date, gender or photograph is ever requested.',
    body: Scaffold(
      body: Container(
        name: 'ProfilePageBackground',
        color: Colors.primaryBackground,
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          spacing: 24,
          children: [
            Container(
              name: 'ProfileFormCard',
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 24,
                children: [
                  Column(
                    crossAxis: CrossAxis.start,
                    spacing: 8,
                    children: [
                      Text(
                        'لنبدأ الحكاية',
                        style: Styles.headlineSmall,
                        color: Colors.primaryText,
                        textAlign: TextAlign.start,
                        maxLines: 2,
                      ),
                      Text(
                        'اختر الاسم والفئة العمرية والصورة، ثم ابدأ القراءة.',
                        style: Styles.bodyMedium,
                        color: Colors.secondaryText,
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // ---- Nickname (optional) -------------------------------
                  Container(
                    borderRadius: 24,
                    color: Colors.primaryBackground,
                    borderColor: Colors.hex(kOutline),
                    borderWidth: 1,
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxis: CrossAxis.stretch,
                      spacing: 10,
                      children: [
                        Text(
                          'اسم الطفل',
                          style: Styles.titleSmall,
                          color: Colors.primaryText,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                        ),
                        Text(
                          'اسم الدلع فقط، ولا داعي للاسم الكامل. يمكنك تركه فارغًا.',
                          style: Styles.bodySmall,
                          color: Colors.secondaryText,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        TextField(
                          name: 'nicknameField',
                          hint: 'اسم الطفل (اختياري)',
                          keyboard: Keyboard.text,
                        ),
                      ],
                    ),
                  ),
                  // ---- Age group ------------------------------------------
                  Column(
                    crossAxis: CrossAxis.stretch,
                    spacing: 12,
                    children: [
                      Text(
                        'الفئة العمرية',
                        style: Styles.titleLarge,
                        color: Colors.primaryText,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                      ),
                      ff.Components.ksageGroupSelector(name: 'AgeSelector'),
                    ],
                  ),
                  // ---- Avatar ---------------------------------------------
                  Column(
                    crossAxis: CrossAxis.stretch,
                    spacing: 12,
                    children: [
                      Text(
                        'اختر صورة',
                        style: Styles.titleLarge,
                        color: Colors.primaryText,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                      ),
                      ff.Components.ksavatarSelector(name: 'AvatarSelector'),
                    ],
                  ),
                  // ---- Single primary action -------------------------------
                  ksPrimaryButton.call(
                    name: 'StartStoryButton',
                    label: 'ابدأ الحكاية',
                    iconName: 'book',
                    enabled: true,
                    loading: false,
                    onPressed: [
                      UpdateAppState.set(
                        ff.AppState.childNickname,
                        WidgetState('nicknameField', WidgetStateProperty.text),
                      ),
                      Navigate(
                        'HomePage',
                        transition: NavigateTransition(
                          NavigateTransitionType.fadeIn,
                          durationMillis: 260,
                        ),
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
  );

  // =========================================================================
  // HomePage — edit the existing blank placeholder in place.
  // =========================================================================
  app.editPage(ff.Pages.homePage, (page) {
    // The wordmark stays English; all other copy is Arabic.
    page.bindText(
      ff.Pages.homePage.widgets.byPath('HomePage.appBar[0].title[0]').single,
      'Kids Stories',
    );

    page.ensureReplaced(
      ff.Pages.homePage.widgets.byPath('HomePage.body[0]').single,
      Container(
        name: 'HomeBackground',
        color: Colors.primaryBackground,
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          spacing: 24,
          children: [
            // ---- Greeting + age chip ----------------------------------
            Container(
              name: 'HomeGreetingCard',
              borderRadius: 24,
              gradient: nightSky(),
              padding: EdgeInsets.all(20),
              shadow: softShadow(),
              child: Column(
                crossAxis: CrossAxis.start,
                spacing: 8,
                children: [
                  Row(
                    spacing: 8,
                    crossAxis: CrossAxis.center,
                    children: [
                      Text(
                        'أهلًا',
                        style: Styles.titleLarge,
                        color: Colors.hex(kWhite),
                        maxLines: 1,
                      ),
                      Flexible(
                        Text(
                          AppState(ff.AppState.childNickname),
                          style: Styles.titleLarge,
                          color: Colors.tertiary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          name: 'HomeNicknameText',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'اختر حكايتك',
                    style: Styles.headlineSmall,
                    color: Colors.hex(kWhite),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    name: 'HomeHeading',
                  ),
                  Row(
                    spacing: 8,
                    crossAxis: CrossAxis.center,
                    children: [
                      Container(
                        borderRadius: 999,
                        color: Colors.hex(0x33FFFFFF),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Row(
                          spacing: 6,
                          crossAxis: CrossAxis.center,
                          children: [
                            Icon(
                              'child_care',
                              size: 20,
                              color: Colors.hex(kWhite),
                            ),
                            Text(
                              AppState(ff.AppState.selectedAgeGroup),
                              style: Styles.labelSmall,
                              color: Colors.hex(kWhite),
                              maxLines: 1,
                              name: 'HomeAgeChipText',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---- Quick actions: favourites + parent area ----------------
            Row(
              mainAxis: MainAxis.spaceEvenly,
              crossAxis: CrossAxis.start,
              children: [
                ksCircularIconButton.call(
                  name: 'HomeFavoritesButton',
                  iconName: 'favorite',
                  variant: 'cream',
                  caption: 'المفضلة',
                  enabled: true,
                  onPressed: [Snackbar('المفضلة — تُوصَل في الدفعة الخامسة')],
                ),
                ksCircularIconButton.call(
                  name: 'HomeParentButton',
                  iconName: 'parent',
                  variant: 'cream',
                  caption: 'للأهل',
                  enabled: true,
                  onPressed: [Snackbar('منطقة الأهل — تُوصَل في الدفعة الخامسة')],
                ),
              ],
            ),

            // ---- Featured ------------------------------------------------
            _sectionHeading('حكاية اليوم'),
            ksStoryCard.call(
              name: 'FeaturedStoryCard',
              titleAr: 'ليلى والنجمة الصغيرة',
              descriptionAr: 'حكاية لطيفة عن المساعدة والصداقة والشجاعة.',
              ageGroupLabel: '٣–٤ سنوات',
              durationMinutes: 4,
              accessLevel: 'free',
              coverVariant: 'night',
              isFavorite: false,
              onTap: [Snackbar('تفاصيل الحكاية — تُوصَل في الدفعة الرابعة')],
            ),

            // ---- Free stories --------------------------------------------
            _sectionHeading('قصص مجانية'),
            Row(
              spacing: 12,
              crossAxis: CrossAxis.start,
              children: [
                Expanded(
                  ksStoryCard.call(
                    name: 'FreeStoryCard1',
                    titleAr: 'ليلى والنجمة الصغيرة',
                    descriptionAr: 'حكاية لطيفة عن المساعدة والصداقة.',
                    ageGroupLabel: '٣–٤ سنوات',
                    durationMinutes: 4,
                    accessLevel: 'free',
                    coverVariant: 'night',
                    isFavorite: false,
                    onTap: [Snackbar('تفاصيل الحكاية — الدفعة الرابعة')],
                  ),
                ),
                Expanded(
                  ksStoryCard.call(
                    name: 'FreeStoryCard2',
                    titleAr: 'الأرنب الذي نسي قبعته',
                    descriptionAr: 'حكاية مرحة عن التعاون والانتباه.',
                    ageGroupLabel: '١–٢ سنة',
                    durationMinutes: 3,
                    accessLevel: 'free',
                    coverVariant: 'garden',
                    isFavorite: false,
                    onTap: [Snackbar('تفاصيل الحكاية — الدفعة الرابعة')],
                  ),
                ),
              ],
            ),

            // ---- Premium stories ------------------------------------------
            _sectionHeading('قصص مميزة'),
            Row(
              spacing: 12,
              crossAxis: CrossAxis.start,
              children: [
                Expanded(
                  ksStoryCard.call(
                    name: 'PremiumStoryCard1',
                    titleAr: 'رحلة القمر إلى البحر',
                    descriptionAr: 'مغامرة هادئة قبل النوم.',
                    ageGroupLabel: '٥–٦ سنوات',
                    durationMinutes: 6,
                    accessLevel: 'premium',
                    coverVariant: 'night',
                    isFavorite: false,
                    onTap: [Snackbar('قصة مميزة — الدفعة الرابعة')],
                  ),
                ),
                Expanded(
                  ksStoryCard.call(
                    name: 'PremiumStoryCard2',
                    titleAr: 'سر الفانوس الذهبي',
                    descriptionAr: 'حكاية عن الصبر ومساعدة الآخرين.',
                    ageGroupLabel: '٣–٤ سنوات',
                    durationMinutes: 5,
                    accessLevel: 'premium',
                    coverVariant: 'day',
                    isFavorite: false,
                    onTap: [Snackbar('قصة مميزة — الدفعة الرابعة')],
                  ),
                ),
              ],
            ),
            Row(
              spacing: 12,
              crossAxis: CrossAxis.start,
              children: [
                Expanded(
                  ksStoryCard.call(
                    name: 'PremiumStoryCard3',
                    titleAr: 'غيمة تحب الرسم',
                    descriptionAr: 'حكاية عن الخيال والألوان.',
                    ageGroupLabel: '٣–٤ سنوات',
                    durationMinutes: 4,
                    accessLevel: 'premium',
                    coverVariant: 'garden',
                    isFavorite: false,
                    onTap: [Snackbar('قصة مميزة — الدفعة الرابعة')],
                  ),
                ),
                Expanded(Container(name: 'PremiumGridFiller')),
              ],
            ),
          ],
        ),
      ),
    );
  });
}

DslWidget _sectionHeading(String labelAr) => Row(
  spacing: 8,
  crossAxis: CrossAxis.center,
  children: [
    Container(width: 8, height: 28, borderRadius: 8, color: Colors.tertiary),
    Text(
      labelAr,
      style: Styles.titleLarge,
      color: Colors.primaryText,
      textAlign: TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ],
);
