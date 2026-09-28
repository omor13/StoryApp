/// Kids Stories — Batch 6: navigation, RTL, responsive and accessibility pass.
///
/// Corrections applied here:
/// 1. Navigation — the premium CTA on StoryDetailsPage now routes through
///    ParentGatePage with the gate set to continue to SubscriptionPage.
/// 2. Responsive — reading and form content gets a comfortable maximum width
///    so story text never stretches across a tablet.
/// 3. Accessibility — Arabic semantic labels on the interactive nodes. These
///    live on `FFNode.annotations.semanticLabel`, which the greenfield widget
///    surface cannot set, so they are written through `mutateNode`.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch6,
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

/// Writes an Arabic screen-reader label onto a node.
void _label(dynamic page, Object selection, String labelAr) {
  page.mutateNode(selection, (FFNode node) {
    node.ensureAnnotations().semanticLabel = FFValue(
      inputValue: FFParameterValue(serializedValue: labelAr),
    );
  });
}

void buildBatch6(App app) {
  // =========================================================================
  // StoryDetailsPage — premium routes through the parent gate.
  // =========================================================================
  app.editPage(ff.Pages.storyDetailsPage, (page) {
    page.ensureActions(
      ff.Pages.storyDetailsPage.widgets.byKey('Container_zvvohau0').single,
      triggerType: FFActionTriggerType.ON_TAP,
      actions: [
        UpdateAppState.set(ff.AppState.gateReturnTo, 'SubscriptionPage'),
        Navigate(ff.Pages.parentGatePage),
      ],
    );

    // Reading column capped for tablets.
    page.update(
      ff.Pages.storyDetailsPage.widgets.byKey('Container_dxjvyiz2').single,
      (patch) => patch.maxSize(width: 720),
    );

    _label(
      page,
      ff.Pages.storyDetailsPage.widgets.byKey('Container_od1fk08g').single,
      'رجوع',
    );
    _label(
      page,
      ff.Pages.storyDetailsPage.widgets.byKey('Container_zb545o4m').single,
      'ابدأ القراءة',
    );
    _label(
      page,
      ff.Pages.storyDetailsPage.widgets.byKey('Container_zvvohau0').single,
      'افتح جميع القصص، يتابع أحد الوالدين',
    );
    _label(
      page,
      ff.Pages.storyDetailsPage.widgets.byKey('Container_qfdgs1wk').single,
      'اختيار وضع القراءة',
    );
  });

  // =========================================================================
  // StoryReaderPage — reading width + labels.
  // =========================================================================
  app.editPage(ff.Pages.storyReaderPage, (page) {
    page.update(
      ff.Pages.storyReaderPage.widgets.byKey('Container_40mbr9lk').single,
      (patch) => patch.maxSize(width: 720),
    );

    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_pipukhst').single,
      'العودة إلى الصفحة الرئيسية',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_b2he8qev').single,
      'أضف الحكاية إلى المفضلة',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_pt7pid91').single,
      'أزل الحكاية من المفضلة',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_inhkha83').single,
      'رسم توضيحي مؤقت للحكاية',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_xrjm1bfd').single,
      'نص الحكاية، الصفحة الأولى من ثلاث',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_rhp0zcsc').single,
      'نص الحكاية، الصفحة الثانية من ثلاث',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_hfwr5dvd').single,
      'نص الحكاية، الصفحة الثالثة من ثلاث',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_cspysg7s').single,
      'اختيار وضع القراءة',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_kx45lye8').single,
      'أدوات الاستماع، غير مفعّلة في النموذج الأولي',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_bij8dw06').single,
      'تنقل بين الصفحات، الصفحة الأولى، السابق غير متاح',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_g2rj6plw').single,
      'تنقل بين الصفحات، الصفحة الثانية',
    );
    _label(
      page,
      ff.Pages.storyReaderPage.widgets.byKey('Container_2kyhitnj').single,
      'تنقل بين الصفحات، الصفحة الأخيرة، انتهت الحكاية',
    );
  });

  // =========================================================================
  // HomePage — labels for the shelves and the two quick actions.
  // =========================================================================
  app.editPage(ff.Pages.homePage, (page) {
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_23qasg9j').single,
      'المفضلة',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_99ps3etk').single,
      'منطقة الأهل',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_mn0i8kxl').single,
      'حكاية اليوم: ليلى والنجمة الصغيرة، مجانية',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_8ov88ump').single,
      'قصة ليلى والنجمة الصغيرة، مجانية',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_bh6aksww').single,
      'قصة الأرنب الذي نسي قبعته، مجانية',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_ng46z9l1').single,
      'قصة رحلة القمر إلى البحر، مميزة ومقفلة',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_ds38nmcp').single,
      'قصة سر الفانوس الذهبي، مميزة ومقفلة',
    );
    _label(
      page,
      ff.Pages.homePage.widgets.byKey('Container_6nya1pkp').single,
      'قصة غيمة تحب الرسم، مميزة ومقفلة',
    );
  });

  // =========================================================================
  // ChildProfileSetupPage — form width + labels.
  // =========================================================================
  app.editPage(ff.Pages.childProfileSetupPage, (page) {
    page.update(
      ff.Pages.childProfileSetupPage.widgets
          .byKey('Container_sjczy4en')
          .single,
      (patch) => patch.maxSize(width: 640),
    );

    _label(
      page,
      ff.Pages.childProfileSetupPage.widgets
          .byKey('Container_oopfywgy')
          .single,
      'اختيار الفئة العمرية',
    );
    _label(
      page,
      ff.Pages.childProfileSetupPage.widgets
          .byKey('Container_2jyjapuo')
          .single,
      'اختيار الصورة الرمزية',
    );
    _label(
      page,
      ff.Pages.childProfileSetupPage.widgets
          .byKey('Container_m4r7lmsj')
          .single,
      'ابدأ الحكاية',
    );
  });

  // =========================================================================
  // ParentGatePage — card width + labels.
  // =========================================================================
  app.editPage(ff.Pages.parentGatePage, (page) {
    page.update(
      ff.Pages.parentGatePage.widgets.byKey('Container_rl04its9').single,
      (patch) => patch.maxSize(width: 480),
    );

    _label(
      page,
      ff.Pages.parentGatePage.widgets.byKey('PinCode_xfl9ba81').single,
      'الرمز المكوّن من أربعة أرقام، غير مفعّل في النموذج الأولي',
    );
    _label(
      page,
      ff.Pages.parentGatePage.widgets.byKey('Container_a8zofiz5').single,
      'متابعة',
    );
    _label(
      page,
      ff.Pages.parentGatePage.widgets.byKey('Container_zwz1dqfr').single,
      'إلغاء',
    );
    _label(
      page,
      ff.Pages.parentGatePage.widgets.byKey('Container_0175z5zg').single,
      'تخطٍ للعرض التجريبي، للتطوير فقط',
    );
  });

  // =========================================================================
  // SubscriptionPage — labels.
  // =========================================================================
  app.editPage(ff.Pages.subscriptionPage, (page) {
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_5b6t3p56').single,
      'إغلاق',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_748p569f').single,
      'خطة الاشتراك الشهري، السعر من المتجر',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_09rovicj').single,
      'خطة الاشتراك السنوي، الأفضل قيمة، السعر من المتجر',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_kma9fjrw').single,
      'اشترك الآن',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_gqi14rfk').single,
      'استعادة المشتريات',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_394ofnez').single,
      'إدارة الاشتراك',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_tp50g4xg').single,
      'سياسة الخصوصية',
    );
    _label(
      page,
      ff.Pages.subscriptionPage.widgets.byKey('Container_2yzddwbt').single,
      'شروط الاستخدام',
    );
  });

  // =========================================================================
  // FavoritesPage — labels.
  // =========================================================================
  app.editPage(ff.Pages.favoritesPage, (page) {
    _label(
      page,
      ff.Pages.favoritesPage.widgets.byKey('Container_5274ybz5').single,
      'العودة إلى الصفحة الرئيسية',
    );
    _label(
      page,
      ff.Pages.favoritesPage.widgets.byKey('Container_n2srjj3l').single,
      'قصة ليلى والنجمة الصغيرة، في المفضلة',
    );
    _label(
      page,
      ff.Pages.favoritesPage.widgets.byKey('Container_p6uqa2zs').single,
      'لم تضف أي حكاية إلى المفضلة بعد',
    );
  });

  // =========================================================================
  // ParentDashboardPage — labels.
  // =========================================================================
  app.editPage(ff.Pages.parentDashboardPage, (page) {
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_zm0vjzfu').single,
      'رجوع',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_l21rptzn').single,
      'تعديل ملف الطفل',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_ewvjbdmj').single,
      'إدارة الاشتراك',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_v1se43a2').single,
      'وضع القراءة الافتراضي',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_24wschyc').single,
      'سياسة الخصوصية',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_p8mbw3qc').single,
      'شروط الاستخدام',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_gz22dxda').single,
      'تسجيل الخروج',
    );
    _label(
      page,
      ff.Pages.parentDashboardPage.widgets.byKey('Container_u6nwbgr8').single,
      'حذف الحساب',
    );
  });
}
