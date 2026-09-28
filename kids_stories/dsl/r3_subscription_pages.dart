/// Kids Stories — Rebuild R3: the reference's four subscription pages.
///
/// Mirrors kid-story-app-vel697 exactly, as requested: a `subscription` hub
/// with three plan tiles (شهري / 3 أشهر / سنوي, the middle one badged
/// "الأكثر شيوعاً"), plus one detail page per plan listing what it includes.
///
/// TWO THINGS TO KNOW BEFORE RELEASE:
/// 1. The three-month plan and the multi-page layout come from the reference
///    and override the earlier "monthly and annual only, one page" rule.
/// 2. The prices below are the reference's own literals. Apple and Google both
///    require the *store-returned localised* price to be displayed, so these
///    strings must be replaced with store values before any real purchase
///    flow ships. Each price node is named PriceNew*/PriceOld* so they are
///    easy to rebind.
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
      buildR3,
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

void buildR3(App app) {
  // ---- Plan detail pages are created first so the hub can link to them. ----
  final monthly = _planDetailPage(
    app,
    pageName: 'subscription1months',
    route: '/subscription-1-month',
    periodAr: ' شهر',
    priceAr: '19 \$',
    icon: kIconCalendar,
  );
  final quarterly = _planDetailPage(
    app,
    pageName: 'subscription3months',
    route: '/subscription-3-months',
    periodAr: '3 أشهر',
    priceAr: '49 \$',
    icon: kCover3,
  );
  final yearly = _planDetailPage(
    app,
    pageName: 'subscription1year',
    route: '/subscription-1-year',
    periodAr: 'سنة',
    priceAr: '149 \$',
    icon: kIconMoon,
  );

  // =========================================================================
  // subscription — the plan hub
  // =========================================================================
  app.page(
    'subscription',
    route: '/subscription-plans',
    description:
        'Plan hub mirrored on the reference: three tiles with old/new price '
        'and a popularity badge on the middle one. Prices are the reference '
        'literals and must be replaced with store-returned values.',
    body: Scaffold(
      body: Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              kBgTablet,
              isNetwork: false,
              fit: ImageFit.cover,
              width: double.infinity,
              height: double.infinity,
              name: 'subscriptionBackground',
            ),
            Column(
              crossAxis: CrossAxis.stretch,
              children: [
                headerBar(
                  titleAr: 'إدارة الاشتراك',
                  rightButton: headerButton(
                    name: 'SubHomeButton',
                    iconName: 'home',
                    captionAr: 'الرئيسية',
                    onTap: [Navigate(ff.Pages.homePage)],
                  ),
                  leftButton: headerButton(
                    name: 'SubSettingsButton',
                    iconName: 'settings',
                    captionAr: 'الإعدادات',
                    onTap: [Navigate(ff.Pages.setting)],
                  ),
                ),
                Expanded(
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      scrollable: true,
                      crossAxis: CrossAxis.stretch,
                      spacing: 14,
                      children: [
                        Icon(
                          'star_rounded',
                          size: 34,
                          color: Colors.tertiary,
                        ),
                        Text(
                          'اختر البرنامج',
                          style: Styles.titleLarge,
                          color: Colors.accent4,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        starDivider(),
                        Row(
                          spacing: 10,
                          crossAxis: CrossAxis.start,
                          children: [
                            Expanded(
                              _planTile(
                                name: 'PlanMonthly',
                                titleAr: 'شهري',
                                oldPrice: '29 \$',
                                newPrice: '19\$',
                                icon: kIconCalendar,
                                badgeAr: '',
                                onTap: [
                                  UpdateAppState.set(
                                    ff.AppState.selectedPlan,
                                    'monthly',
                                  ),
                                  Navigate(monthly),
                                ],
                              ),
                            ),
                            Expanded(
                              _planTile(
                                name: 'PlanQuarterly',
                                titleAr: '3 أشهر',
                                oldPrice: '75 \$',
                                newPrice: '49\$',
                                icon: kCover3,
                                badgeAr: 'الأكثر شيوعاً',
                                onTap: [
                                  UpdateAppState.set(
                                    ff.AppState.selectedPlan,
                                    'quarterly',
                                  ),
                                  Navigate(quarterly),
                                ],
                              ),
                            ),
                            Expanded(
                              _planTile(
                                name: 'PlanYearly',
                                titleAr: 'سنوي',
                                oldPrice: '199 \$',
                                newPrice: '149\$',
                                icon: kIconMoon,
                                badgeAr: '',
                                onTap: [
                                  UpdateAppState.set(
                                    ff.AppState.selectedPlan,
                                    'annual',
                                  ),
                                  Navigate(yearly),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'يتجدد الاشتراك تلقائيًا ويُحصَّل عبر حسابك في '
                          'المتجر. يمكنك الإلغاء في أي وقت.',
                          style: Styles.bodySmall,
                          color: Colors.secondaryText,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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

/// One plan detail page — the reference's "تفاصيل البرنامج" layout.
PageHandle _planDetailPage(
  App app, {
  required String pageName,
  required String route,
  required String periodAr,
  required String priceAr,
  required String icon,
}) => app.page(
  pageName,
  route: route,
  description:
      'Plan detail mirrored on the reference. The price literal must be '
      'replaced with the store-returned localised price before release.',
  body: Scaffold(
    body: Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(
            kBgTablet,
            isNetwork: false,
            fit: ImageFit.cover,
            width: double.infinity,
            height: double.infinity,
            name: 'planBackground',
          ),
          Column(
            crossAxis: CrossAxis.stretch,
            children: [
              headerBar(
                titleAr: 'إدارة الاشتراك',
                rightButton: headerButton(
                  name: 'PlanHomeButton',
                  iconName: 'home',
                  captionAr: 'الرئيسية',
                  onTap: [Navigate(ff.Pages.homePage)],
                ),
                leftButton: headerButton(
                  name: 'PlanBackButton',
                  iconName: 'arrow_forward',
                  captionAr: 'رجوع',
                  onTap: [NavigateBack()],
                ),
              ),
              Expanded(
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    scrollable: true,
                    crossAxis: CrossAxis.stretch,
                    spacing: 14,
                    children: [
                      Icon('star_rounded', size: 32, color: Colors.tertiary),
                      Text(
                        'تفاصيل البرنامج',
                        style: Styles.titleLarge,
                        color: Colors.accent4,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      // ---- Selected plan card --------------------------
                      creamCard(
                        name: 'Selectedplancard',
                        child: Row(
                          crossAxis: CrossAxis.center,
                          spacing: 14,
                          children: [
                            Image(
                              icon,
                              isNetwork: false,
                              width: 72,
                              height: 72,
                              borderRadius: 18,
                            ),
                            Expanded(
                              Column(
                                crossAxis: CrossAxis.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    periodAr,
                                    style: Styles.titleSmall,
                                    color: Colors.accent2,
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    priceAr,
                                    style: Styles.headlineSmall,
                                    color: Colors.primary,
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    name: 'PriceNewDetail',
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              'check_circle',
                              size: 34,
                              color: Colors.success,
                            ),
                          ],
                        ),
                      ),
                      // ---- What the plan includes ----------------------
                      creamCard(
                        name: 'IncludesCard',
                        child: Column(
                          crossAxis: CrossAxis.stretch,
                          spacing: 14,
                          children: [
                            Row(
                              mainAxis: MainAxis.center,
                              crossAxis: CrossAxis.center,
                              spacing: 8,
                              children: [
                                Icon(
                                  'star_rounded',
                                  size: 22,
                                  color: Colors.tertiary,
                                ),
                                Text(
                                  'يشمل البرنامج',
                                  style: Styles.titleSmall,
                                  color: Colors.accent2,
                                  maxLines: 1,
                                ),
                                Icon(
                                  'star_rounded',
                                  size: 22,
                                  color: Colors.tertiary,
                                ),
                              ],
                            ),
                            Row(
                              mainAxis: MainAxis.spaceEvenly,
                              crossAxis: CrossAxis.start,
                              spacing: 8,
                              children: [
                                Expanded(
                                  _benefit(kIconBook, 'جميع القصص'),
                                ),
                                Expanded(
                                  _benefit(kIconMoon, 'تحديثات مستمرة'),
                                ),
                                Expanded(
                                  _benefit(kIconCake, 'بدون إعلانات'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ---- Subscribe (prototype only) ------------------
                      Container(
                        name: 'PlanSubscribeButton',
                        height: 66,
                        borderRadius: 999,
                        color: Colors.primary,
                        alignment: Alignment.center,
                        shadow: cardShadow(),
                        onTap: [
                          Snackbar('الشراء غير مفعّل في النموذج الأولي'),
                        ],
                        child: Text(
                          'اشترك الآن',
                          style: Styles.titleMedium,
                          color: Colors.hex(kWhite),
                          maxLines: 1,
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
  ),
);

/// One plan tile on the hub: icon, period, struck-through old price, new price
/// and an optional popularity badge.
DslWidget _planTile({
  required String name,
  required String titleAr,
  required String oldPrice,
  required String newPrice,
  required String icon,
  required String badgeAr,
  required List<DslAction> onTap,
}) => Container(
  name: name,
  borderRadius: 24,
  color: Colors.primaryBackground,
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
  shadow: cardShadow(),
  onTap: onTap,
  child: Column(
    crossAxis: CrossAxis.center,
    spacing: 8,
    children: [
      Container(
        borderRadius: 999,
        color: Colors.tertiary,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visible: badgeAr == '' ? false : true,
        child: Text(
          badgeAr == '' ? 'الأكثر شيوعاً' : badgeAr,
          style: Styles.labelSmall,
          color: Colors.hex(kIndigo),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Image(icon, isNetwork: false, width: 62, height: 62, fit: ImageFit.contain),
      Text(
        titleAr,
        style: Styles.titleSmall,
        color: Colors.accent2,
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
      Text(
        oldPrice,
        style: Styles.bodySmall,
        color: Colors.secondaryText,
        textAlign: TextAlign.center,
        maxLines: 1,
        name: 'PriceOld$name',
      ),
      Text(
        newPrice,
        style: Styles.titleMedium,
        color: Colors.primary,
        textAlign: TextAlign.center,
        maxLines: 1,
        name: 'PriceNew$name',
      ),
    ],
  ),
);

DslWidget _benefit(String imagePath, String labelAr) => Column(
  crossAxis: CrossAxis.center,
  spacing: 6,
  children: [
    Image(imagePath, isNetwork: false, width: 54, height: 54, fit: ImageFit.contain),
    Text(
      labelAr,
      style: Styles.labelSmall,
      color: Colors.primaryText,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  ],
);
