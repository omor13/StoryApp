/// Kids Stories — Batch 5: ParentGatePage, SubscriptionPage, FavoritesPage,
/// ParentDashboardPage, plus the parent/favourites/unlock wiring.
///
/// Deliberate omissions in this phase:
/// - No working PIN. The four-digit field is a placeholder and the only way
///   forward is a clearly-labelled debug preview action that must be deleted
///   before production.
/// - No real prices. Both plan cards show the placeholder "السعر من المتجر",
///   structured so a localised store string can replace it later.
/// - No purchase, restore or management call. Those buttons show a prototype
///   notice; RevenueCat is not enabled on the project.
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
      buildBatch5,
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
const int kErrorText = 0xFFC4404C;

Shadow softShadow() => Shadow(blur: 20, dy: 6, color: Colors.hex(kShadow));

void buildBatch5(App app) {
  // Where the gate should continue to once it is passed.
  app.state(
    'gateReturnTo',
    string.withDefault('ParentDashboardPage'),
    description:
        'Prototype only: which parent page the gate preview continues to.',
  );

  // =========================================================================
  // ParentGatePage
  // =========================================================================
  app.page(
    'ParentGatePage',
    route: '/parent-gate',
    description:
        'Keeps children out of purchases and adult settings. The PIN field is '
        'a placeholder: no PIN is stored, checked or hard-coded. Real PIN '
        'creation and validation is a future Firebase-backed task.',
    body: Scaffold(
      body: Container(
        name: 'GateBackground',
        color: Colors.secondaryBackground,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 20,
          children: [
            Container(
              name: 'GateCard',
              borderRadius: 24,
              color: Colors.primaryBackground,
              borderColor: Colors.hex(kOutline),
              borderWidth: 1,
              padding: EdgeInsets.all(24),
              shadow: softShadow(),
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 16,
                children: [
                  Row(
                    spacing: 10,
                    crossAxis: CrossAxis.center,
                    children: [
                      Icon(
                        'family_restroom',
                        size: 30,
                        color: Colors.primary,
                      ),
                      Text(
                        'منطقة الأهل',
                        style: Styles.titleLarge,
                        color: Colors.primaryText,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  Text(
                    'هذه الخطوة مخصصة للأهل',
                    style: Styles.bodyMedium,
                    color: Colors.primaryText,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                  ),
                  Text(
                    'أدخل الرمز المكوّن من أربعة أرقام للمتابعة.',
                    style: Styles.bodySmall,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                  ),
                  PinCode(name: 'GatePinField', length: 4, obscureText: true),
                  Text(
                    'ملاحظة للفريق: لا يوجد رمز فعلي في النموذج الأولي. '
                    'إنشاء الرمز والتحقق منه مهمة لاحقة عبر Firebase.',
                    style: Styles.bodySmall,
                    color: Colors.secondaryText,
                    textAlign: TextAlign.start,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Continue: intentionally does NOT validate anything.
                  ksPrimaryButton.call(
                    name: 'GateContinueButton',
                    label: 'متابعة',
                    iconName: 'none',
                    enabled: true,
                    loading: false,
                    onPressed: [
                      Snackbar(
                        'التحقق من الرمز غير مفعّل في النموذج الأولي',
                      ),
                    ],
                  ),
                  ksSecondaryButton.call(
                    name: 'GateCancelButton',
                    label: 'إلغاء',
                    iconName: 'back',
                    enabled: true,
                    onPressed: [NavigateBack()],
                  ),
                ],
              ),
            ),

            // ---- Debug-only preview. Remove before production. -----------
            Container(
              name: 'GateDebugPreviewCard',
              borderRadius: 16,
              color: Colors.secondaryBackground,
              borderColor: Colors.hex(kErrorText),
              borderWidth: 2,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 10,
                children: [
                  Row(
                    spacing: 8,
                    crossAxis: CrossAxis.center,
                    children: [
                      Icon(
                        'bug_report',
                        size: 22,
                        color: Colors.hex(kErrorText),
                      ),
                      Text(
                        'DEBUG ONLY — remove before production',
                        style: Styles.labelSmall,
                        color: Colors.hex(kErrorText),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  ksSecondaryButton.call(
                    name: 'GateDebugSkipButton',
                    label: 'تخطٍ للعرض التجريبي (Debug)',
                    iconName: 'none',
                    enabled: true,
                    onPressed: [
                      If(
                        Equals(AppState('gateReturnTo'), 'SubscriptionPage'),
                        then: [Navigate('SubscriptionPage')],
                        orElse: [Navigate('ParentDashboardPage')],
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
  // SubscriptionPage — monthly and annual only.
  // =========================================================================
  app.page(
    'SubscriptionPage',
    route: '/subscription',
    description:
        'Parent-facing plans. Exactly two cards (monthly, annual); annual is '
        'selected by default and carries the الأفضل قيمة badge. Prices are '
        'placeholders — no price, discount or countdown is invented.',
    body: Scaffold(
      body: Container(
        name: 'SubscriptionBackground',
        color: Colors.secondaryBackground,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 20,
          children: [
            Row(
              mainAxis: MainAxis.spaceBetween,
              crossAxis: CrossAxis.center,
              children: [
                Flexible(
                  Text(
                    'افتحوا مكتبة الحكايات كاملة',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  name: 'SubscriptionCloseButton',
                  width: 48,
                  height: 48,
                  borderRadius: 999,
                  color: Colors.primaryBackground,
                  alignment: Alignment.center,
                  onTap: [NavigateBack()],
                  child: Icon('close', size: 24, color: Colors.primaryText),
                ),
              ],
            ),
            Text(
              'اشتراك واحد يفتح كل القصص المميزة لجميع أطفالكم، بلا إعلانات.',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
              textAlign: TextAlign.start,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // ---- Exactly two plans --------------------------------------
            ksSubscriptionPlanCard.call(
              name: 'MonthlyPlanCard',
              planName: 'اشتراك شهري',
              billingPeriod: 'يتجدد كل شهر',
              priceText: 'السعر من المتجر',
              recommended: false,
              selected: Equals(AppState(ff.AppState.selectedPlan), 'monthly'),
              onSelect: [
                UpdateAppState.set(ff.AppState.selectedPlan, 'monthly'),
              ],
            ),
            ksSubscriptionPlanCard.call(
              name: 'AnnualPlanCard',
              planName: 'اشتراك سنوي',
              billingPeriod: 'يتجدد كل سنة',
              priceText: 'السعر من المتجر',
              recommended: true,
              selected: Equals(AppState(ff.AppState.selectedPlan), 'annual'),
              onSelect: [
                UpdateAppState.set(ff.AppState.selectedPlan, 'annual'),
              ],
            ),

            Text(
              'يتجدد الاشتراك تلقائيًا ويُحصَّل عبر حسابك في المتجر. يمكنك '
              'الإلغاء في أي وقت من إعدادات الاشتراكات في المتجر.',
              style: Styles.bodySmall,
              color: Colors.secondaryText,
              textAlign: TextAlign.start,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            ksPrimaryButton.call(
              name: 'SubscribeButton',
              label: 'اشترك الآن',
              iconName: 'none',
              enabled: true,
              loading: false,
              onPressed: [
                Snackbar('الشراء غير مفعّل في النموذج الأولي'),
              ],
            ),

            // ---- Secondary parent actions --------------------------------
            _parentLinkRow('استعادة المشتريات', 'restore', 'RestoreLink'),
            _parentLinkRow('إدارة الاشتراك', 'settings', 'ManageLink'),
            _parentLinkRow('سياسة الخصوصية', 'privacy', 'PrivacyLink'),
            _parentLinkRow('شروط الاستخدام', 'terms', 'TermsLink'),
          ],
        ),
      ),
    ),
  );

  // =========================================================================
  // FavoritesPage
  // =========================================================================
  app.page(
    'FavoritesPage',
    route: '/favorites',
    description:
        'Prototype favourites shelf with an Arabic empty state. Favourites are '
        'held in local app state only.',
    body: Scaffold(
      body: Container(
        name: 'FavoritesBackground',
        color: Colors.primaryBackground,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 20,
          children: [
            Row(
              spacing: 12,
              crossAxis: CrossAxis.center,
              children: [
                ksCircularIconButton.call(
                  name: 'FavoritesHomeButton',
                  iconName: 'home',
                  variant: 'cream',
                  caption: 'الرئيسية',
                  enabled: true,
                  onPressed: [Navigate(ff.Pages.homePage)],
                ),
                Flexible(
                  Text(
                    'المفضلة',
                    style: Styles.headlineSmall,
                    color: Colors.primaryText,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Favourite story — shown once the reader marks one.
            ksStoryCard.call(
              name: 'FavoriteStoryCard',
              titleAr: 'ليلى والنجمة الصغيرة',
              descriptionAr: 'حكاية لطيفة عن المساعدة والصداقة والشجاعة.',
              ageGroupLabel: '٣–٤ سنوات',
              durationMinutes: 4,
              accessLevel: 'free',
              coverVariant: 'night',
              isFavorite: true,
              visible: AppState(ff.AppState.isSelectedStoryFavorite),
              onTap: [
                UpdateAppState.set(ff.AppState.selectedStoryId, 'laila-star'),
                UpdateAppState.set(
                  ff.AppState.selectedStoryTitle,
                  'ليلى والنجمة الصغيرة',
                ),
                UpdateAppState.set(
                  ff.AppState.selectedStoryDescription,
                  'حكاية لطيفة عن المساعدة والصداقة والشجاعة.',
                ),
                UpdateAppState.set(
                  ff.AppState.selectedStoryAgeGroup,
                  '٣–٤ سنوات',
                ),
                UpdateAppState.set(ff.AppState.selectedStoryMinutes, 4),
                UpdateAppState.set(ff.AppState.selectedStoryAccess, 'free'),
                Navigate(ff.Pages.storyDetailsPage),
              ],
            ),

            // Empty state.
            ksEmptyState.call(
              name: 'FavoritesEmptyState',
              titleAr: 'لم تضف أي حكاية إلى المفضلة بعد',
              bodyAr: 'اضغط على القلب أثناء القراءة لتحفظ حكايتك المفضلة.',
              actionLabel: 'تصفّح الحكايات',
              showAction: true,
              visible: Not(AppState(ff.AppState.isSelectedStoryFavorite)),
              onAction: [Navigate(ff.Pages.homePage)],
            ),
          ],
        ),
      ),
    ),
  );

  // =========================================================================
  // ParentDashboardPage — calmer, less decoration.
  // =========================================================================
  app.page(
    'ParentDashboardPage',
    route: '/parent-dashboard',
    description:
        'Calm parent area: child profile, subscription status placeholder, '
        'reading settings, subscription management, privacy, and placeholders '
        'for delete account and logout (no backend in this phase).',
    body: Scaffold(
      body: Container(
        name: 'DashboardBackground',
        color: Colors.secondaryBackground,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          scrollable: true,
          crossAxis: CrossAxis.stretch,
          spacing: 16,
          children: [
            Row(
              spacing: 12,
              crossAxis: CrossAxis.center,
              children: [
                Container(
                  name: 'DashboardBackButton',
                  width: 48,
                  height: 48,
                  borderRadius: 999,
                  color: Colors.primaryBackground,
                  alignment: Alignment.center,
                  onTap: [Navigate(ff.Pages.homePage)],
                  child: Icon(
                    'chevron_right',
                    size: 26,
                    color: Colors.primaryText,
                  ),
                ),
                Flexible(
                  Text(
                    'لوحة الأهل',
                    style: Styles.titleLarge,
                    color: Colors.primaryText,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ---- Child profiles ------------------------------------------
            _dashboardCard(
              titleAr: 'الأطفال',
              child: Row(
                spacing: 12,
                crossAxis: CrossAxis.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    borderRadius: 999,
                    color: Colors.alternate,
                    alignment: Alignment.center,
                    child: Icon('pets', size: 28, color: Colors.primary),
                  ),
                  Expanded(
                    Column(
                      crossAxis: CrossAxis.start,
                      spacing: 2,
                      children: [
                        Text(
                          AppState(ff.AppState.childNickname),
                          style: Styles.titleSmall,
                          color: Colors.primaryText,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppState(ff.AppState.selectedAgeGroup),
                          style: Styles.bodySmall,
                          color: Colors.secondaryText,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    name: 'DashboardEditChildButton',
                    width: 48,
                    height: 48,
                    borderRadius: 999,
                    color: Colors.alternate,
                    alignment: Alignment.center,
                    onTap: [Navigate(ff.Pages.childProfileSetupPage)],
                    child: Icon('edit', size: 22, color: Colors.primary),
                  ),
                ],
              ),
            ),

            // ---- Subscription status placeholder -------------------------
            _dashboardCard(
              titleAr: 'الاشتراك',
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 12,
                children: [
                  Row(
                    spacing: 8,
                    crossAxis: CrossAxis.center,
                    children: [
                      Icon('info', size: 22, color: Colors.secondary),
                      Flexible(
                        Text(
                          'الحالة: غير مفعّل (نموذج أولي)',
                          style: Styles.bodyMedium,
                          color: Colors.primaryText,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  ksSecondaryButton.call(
                    name: 'DashboardManageSubscription',
                    label: 'إدارة الاشتراك',
                    iconName: 'settings',
                    enabled: true,
                    onPressed: [Navigate('SubscriptionPage')],
                  ),
                ],
              ),
            ),

            // ---- Reading settings ----------------------------------------
            _dashboardCard(
              titleAr: 'إعدادات القراءة',
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 12,
                children: [
                  Text(
                    'وضع القراءة الافتراضي',
                    style: Styles.bodyMedium,
                    color: Colors.primaryText,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                  ),
                  ff.Components.ksreadingModeSelector(
                    name: 'DashboardModeSelector',
                  ),
                ],
              ),
            ),

            // ---- Legal + account placeholders -----------------------------
            _dashboardCard(
              titleAr: 'الحساب والخصوصية',
              child: Column(
                crossAxis: CrossAxis.stretch,
                spacing: 8,
                children: [
                  _parentLinkRow('سياسة الخصوصية', 'privacy', 'DashPrivacy'),
                  _parentLinkRow('شروط الاستخدام', 'terms', 'DashTerms'),
                  _parentLinkRow('تسجيل الخروج', 'logout', 'DashLogout'),
                  _parentLinkRow('حذف الحساب', 'delete', 'DashDelete'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // =========================================================================
  // Rewire the entry points left as placeholders in batches 3 and 4.
  // =========================================================================
  app.editPage(ff.Pages.homePage, (page) {
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_23qasg9j').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [Navigate('FavoritesPage')],
    );
    page.ensureActions(
      ff.Pages.homePage.widgets.byKey('Container_99ps3etk').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set('gateReturnTo', 'ParentDashboardPage'),
        Navigate('ParentGatePage'),
      ],
    );
  });
}

// ---------------------------------------------------------------------------
// Local builders
// ---------------------------------------------------------------------------

/// A calm parent-mode card with a section heading.
DslWidget _dashboardCard({required String titleAr, required DslWidget child}) =>
    Container(
      borderRadius: 24,
      color: Colors.primaryBackground,
      borderColor: Colors.hex(kOutline),
      borderWidth: 1,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxis: CrossAxis.stretch,
        spacing: 12,
        children: [
          Text(
            titleAr,
            style: Styles.titleSmall,
            color: Colors.primaryText,
            textAlign: TextAlign.start,
            maxLines: 1,
          ),
          child,
        ],
      ),
    );

/// One adult-sized secondary row. All of these are prototype placeholders.
DslWidget _parentLinkRow(String labelAr, String kind, String widgetName) =>
    Container(
      name: widgetName,
      height: 56,
      borderRadius: 16,
      color: Colors.primaryBackground,
      padding: EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      onTap: [Snackbar('غير مفعّل في النموذج الأولي')],
      child: Row(
        spacing: 12,
        crossAxis: CrossAxis.center,
        children: [
          Icon(
            _linkIcon(kind),
            size: 22,
            color: kind == 'delete' ? Colors.hex(kErrorText) : Colors.primary,
          ),
          Expanded(
            Text(
              labelAr,
              style: Styles.bodyMedium,
              color: Colors.primaryText,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon('chevron_left', size: 22, color: Colors.secondaryText),
        ],
      ),
    );

/// Material glyph for each parent-row kind. Icons are literals in the DSL, so
/// the choice happens here in Dart rather than through a widget condition.
String _linkIcon(String kind) => switch (kind) {
  'restore' => 'restore',
  'settings' => 'settings',
  'privacy' => 'privacy_tip',
  'terms' => 'description',
  'logout' => 'logout',
  'delete' => 'delete_outline',
  _ => 'chevron_left',
};
