/// Kids Stories — Batch 2b: story, reader and subscription components.
///
/// Components in this batch:
///   KSStoryCard · KSStoryTextCard · KSAudioControls · KSPageNavigation
///   KSSubscriptionPlanCard · KSLockedStoryOverlay
///
/// Cover art is an explicitly labelled placeholder: a gradient panel with a
/// built-in icon. No third-party illustration is copied or downloaded.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch2b,
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
const int kPrimary = 0xFF7442C8;
const int kPrimaryLight = 0xFF916BC1;
const int kAccentGold = 0xFFF5B83D;
const int kAccentPink = 0xFFEE7692;
const int kTextDarkBlue = 0xFF0D1F45;

Shadow softShadow() => Shadow(blur: 20, dy: 6, color: Colors.hex(kShadow));

Shadow chipShadow() => Shadow(blur: 8, dy: 2, color: Colors.hex(kShadow));

/// Placeholder cover art: a two-stop gradient panel carrying a built-in icon.
Gradient _coverGradient(int from, int to) => Gradient.linear([
  GradientStop(Colors.hex(from), 0),
  GradientStop(Colors.hex(to), 1),
], angle: 120);

void buildBatch2b(App app) {
  // -------------------------------------------------------------------------
  // 10. KSStoryCard
  // -------------------------------------------------------------------------
  app.component(
    'KSStoryCard',
    description:
        'Library tile: placeholder cover, Arabic title, age group, duration, '
        'lock badge for premium and a favourite heart. Params: titleAr, '
        'descriptionAr, ageGroupLabel, durationMinutes, accessLevel '
        '(free/premium), coverVariant (night/day/garden), isFavorite, onTap.',
    params: {
      'titleAr': string.withDefault('حكاية'),
      'descriptionAr': string.withDefault(''),
      'ageGroupLabel': string.withDefault('٣–٤ سنوات'),
      'durationMinutes': int_.withDefault(4),
      'accessLevel': string.withDefault('free'),
      'coverVariant': string.withDefault('night'),
      'isFavorite': bool_.withDefault(false),
      'onTap': action,
    },
    body: Container(
      name: 'StoryCardRoot',
      borderRadius: 24,
      color: Colors.primaryBackground,
      shadow: softShadow(),
      onTap: ParamAction('onTap'),
      child: Column(
        crossAxis: CrossAxis.stretch,
        children: [
          // ---- Placeholder cover -------------------------------------------
          Container(
            height: 132,
            borderRadius: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 132,
                  borderRadius: 24,
                  gradient: _coverGradient(kStoryBlueDark, kStoryBlue),
                  visible: Equals(Param('coverVariant'), 'night'),
                ),
                Container(
                  height: 132,
                  borderRadius: 24,
                  gradient: _coverGradient(kPrimary, kAccentPink),
                  visible: Equals(Param('coverVariant'), 'day'),
                ),
                Container(
                  height: 132,
                  borderRadius: 24,
                  gradient: _coverGradient(kPrimaryLight, kAccentGold),
                  visible: Equals(Param('coverVariant'), 'garden'),
                ),
                Icon('auto_stories', size: 48, color: Colors.hex(kWhite)),
                // Lock badge — icon plus Arabic word, never colour alone.
                Container(
                  alignment: Alignment.topRight,
                  padding: EdgeInsets.all(10),
                  visible: Equals(Param('accessLevel'), 'premium'),
                  child: Container(
                    borderRadius: 999,
                    color: Colors.tertiary,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      spacing: 6,
                      crossAxis: CrossAxis.center,
                      children: [
                        Icon('lock', size: 18, color: Colors.hex(kTextDarkBlue)),
                        Text(
                          'مميزة',
                          style: Styles.labelSmall,
                          color: Colors.hex(kTextDarkBlue),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Favourite heart.
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(10),
                  visible: Param('isFavorite'),
                  child: Container(
                    width: 36,
                    height: 36,
                    borderRadius: 999,
                    color: Colors.primaryBackground,
                    alignment: Alignment.center,
                    child: Icon('favorite', size: 20, color: Colors.accent2),
                  ),
                ),
                // Placeholder caption so nobody mistakes this for final art.
                Container(
                  alignment: Alignment.bottomRight,
                  padding: EdgeInsets.all(8),
                  child: Container(
                    borderRadius: 8,
                    color: Colors.hex(kScrim),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          // ---- Text block ---------------------------------------------------
          Container(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxis: CrossAxis.start,
              spacing: 6,
              children: [
                Text(
                  Param('titleAr'),
                  style: Styles.titleSmall,
                  color: Colors.primaryText,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Param('descriptionAr'),
                  style: Styles.bodySmall,
                  color: Colors.secondaryText,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  visible: Not(Equals(Param('descriptionAr'), '')),
                ),
                Row(
                  spacing: 8,
                  crossAxis: CrossAxis.center,
                  children: [
                    Container(
                      borderRadius: 999,
                      color: Colors.alternate,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        Param('ageGroupLabel'),
                        style: Styles.labelSmall,
                        color: Colors.primaryText,
                        maxLines: 1,
                      ),
                    ),
                    Icon('schedule', size: 18, color: Colors.secondaryText),
                    Text(
                      Param('durationMinutes'),
                      style: Styles.labelSmall,
                      color: Colors.secondaryText,
                      maxLines: 1,
                    ),
                    Text(
                      'دقائق',
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
  );

  // -------------------------------------------------------------------------
  // 11. KSStoryTextCard — opaque cream card, never text on busy artwork.
  // -------------------------------------------------------------------------
  app.component(
    'KSStoryTextCard',
    description:
        'Opaque cream card holding the Arabic story text plus the page '
        'indicator. Params: textAr, pageNumber, totalPages.',
    params: {
      'textAr': string.withDefault(''),
      'pageNumber': int_.withDefault(1),
      'totalPages': int_.withDefault(3),
    },
    body: Container(
      name: 'StoryTextCardRoot',
      borderRadius: 24,
      color: Colors.primaryBackground,
      padding: EdgeInsets.all(24),
      shadow: softShadow(),
      child: Column(
        crossAxis: CrossAxis.start,
        spacing: 12,
        children: [
          Text(
            Param('textAr'),
            style: Styles.bodyLarge,
            color: Colors.primaryText,
            textAlign: TextAlign.start,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            spacing: 6,
            crossAxis: CrossAxis.center,
            children: [
              Text(
                'الصفحة',
                style: Styles.bodySmall,
                color: Colors.secondaryText,
                maxLines: 1,
              ),
              Text(
                Param('pageNumber'),
                style: Styles.bodySmall,
                color: Colors.secondaryText,
                maxLines: 1,
              ),
              Text(
                'من',
                style: Styles.bodySmall,
                color: Colors.secondaryText,
                maxLines: 1,
              ),
              Text(
                Param('totalPages'),
                style: Styles.bodySmall,
                color: Colors.secondaryText,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // 12. KSAudioControls — prototype only, nothing is played.
  // -------------------------------------------------------------------------
  app.component(
    'KSAudioControls',
    description:
        'Prototype playback bar (play/pause/stop/repeat/speed). Drives the '
        'isNarrating and playbackSpeed app state only — no audio or TTS is '
        'connected in this phase.',
    params: const {},
    body: Container(
      name: 'AudioControlsRoot',
      borderRadius: 28,
      color: Colors.primaryBackground,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shadow: softShadow(),
      child: Column(
        crossAxis: CrossAxis.center,
        spacing: 8,
        children: [
          Row(
            mainAxis: MainAxis.spaceEvenly,
            crossAxis: CrossAxis.center,
            children: [
              // Order from the right under RTL: repeat, stop, play/pause, speed.
              _audioButton(
                iconName: 'replay',
                captionAr: 'إعادة',
                filled: false,
                onTap: [
                  UpdateAppState.set(ff.AppState.isNarrating, false),
                  Snackbar('إعادة الصفحة (نموذج أولي)'),
                ],
              ),
              _audioButton(
                iconName: 'stop',
                captionAr: 'إيقاف',
                filled: false,
                onTap: [UpdateAppState.set(ff.AppState.isNarrating, false)],
              ),
              // Play / pause swap on the same spot.
              Column(
                crossAxis: CrossAxis.center,
                spacing: 4,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    borderRadius: 999,
                    color: Colors.primary,
                    alignment: Alignment.center,
                    shadow: chipShadow(),
                    visible: Not(AppState(ff.AppState.isNarrating)),
                    onTap: UpdateAppState.set(ff.AppState.isNarrating, true),
                    child: Icon(
                      'play_arrow',
                      size: 40,
                      color: Colors.hex(kWhite),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    borderRadius: 999,
                    color: Colors.primary,
                    alignment: Alignment.center,
                    shadow: chipShadow(),
                    visible: AppState(ff.AppState.isNarrating),
                    onTap: UpdateAppState.set(ff.AppState.isNarrating, false),
                    child: Icon('pause', size: 40, color: Colors.hex(kWhite)),
                  ),
                  Text(
                    'تشغيل',
                    style: Styles.labelSmall,
                    color: Colors.primaryText,
                    maxLines: 1,
                    visible: Not(AppState(ff.AppState.isNarrating)),
                  ),
                  Text(
                    'إيقاف مؤقت',
                    style: Styles.labelSmall,
                    color: Colors.primaryText,
                    maxLines: 1,
                    visible: AppState(ff.AppState.isNarrating),
                  ),
                ],
              ),
              // Speed chip cycles 1x -> 0.75x -> 1x.
              Column(
                crossAxis: CrossAxis.center,
                spacing: 4,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    borderRadius: 999,
                    color: Colors.alternate,
                    alignment: Alignment.center,
                    onTap: [
                      If(
                        Equals(AppState(ff.AppState.playbackSpeed), '1x'),
                        then: [UpdateAppState.set(ff.AppState.playbackSpeed, '0.75x')],
                        orElse: [UpdateAppState.set(ff.AppState.playbackSpeed, '1x')],
                      ),
                    ],
                    child: Text(
                      AppState(ff.AppState.playbackSpeed),
                      style: Styles.labelMedium,
                      color: Colors.primary,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    'السرعة',
                    style: Styles.labelSmall,
                    color: Colors.primaryText,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
          Text(
            'الصوت غير مفعّل في النموذج الأولي',
            style: Styles.bodySmall,
            color: Colors.secondaryText,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // 13. KSPageNavigation — RTL: next sits on the left, previous on the right.
  // -------------------------------------------------------------------------
  app.component(
    'KSPageNavigation',
    description:
        'Reader navigation. Under RTL the first child renders on the right, so '
        'previous is on the right and next on the left. On the last page next '
        'is replaced by انتهت الحكاية. Params: pageNumber, totalPages, isFirst, '
        'isLast, onPrevious, onNext, onFinish.',
    params: {
      'pageNumber': int_.withDefault(1),
      'totalPages': int_.withDefault(3),
      'isFirst': bool_.withDefault(true),
      'isLast': bool_.withDefault(false),
      'onPrevious': action,
      'onNext': action,
      'onFinish': action,
    },
    body: Container(
      name: 'PageNavigationRoot',
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxis: MainAxis.spaceBetween,
        crossAxis: CrossAxis.center,
        children: [
          // Previous (rendered on the right under RTL).
          Column(
            crossAxis: CrossAxis.center,
            spacing: 4,
            children: [
              Container(
                width: 64,
                height: 64,
                borderRadius: 999,
                color: Colors.primaryBackground,
                alignment: Alignment.center,
                shadow: chipShadow(),
                onTap: If(
                  Not(Param('isFirst')),
                  then: ParamAction('onPrevious'),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon('chevron_right', size: 34, color: Colors.primary),
                    Container(
                      width: 64,
                      height: 64,
                      borderRadius: 999,
                      color: Colors.hex(0xCCEFE6D6),
                      visible: Param('isFirst'),
                    ),
                  ],
                ),
              ),
              Text(
                'السابق',
                style: Styles.labelSmall,
                color: Colors.primaryText,
                maxLines: 1,
              ),
            ],
          ),
          // Page indicator.
          Row(
            spacing: 6,
            crossAxis: CrossAxis.center,
            children: [
              Text(
                'الصفحة',
                style: Styles.bodyMedium,
                color: Colors.primaryText,
                maxLines: 1,
              ),
              Text(
                Param('pageNumber'),
                style: Styles.bodyMedium,
                color: Colors.primaryText,
                maxLines: 1,
              ),
              Text(
                'من',
                style: Styles.bodyMedium,
                color: Colors.primaryText,
                maxLines: 1,
              ),
              Text(
                Param('totalPages'),
                style: Styles.bodyMedium,
                color: Colors.primaryText,
                maxLines: 1,
              ),
            ],
          ),
          // Next (rendered on the left under RTL) / end-of-story action.
          Column(
            crossAxis: CrossAxis.center,
            spacing: 4,
            children: [
              Container(
                width: 64,
                height: 64,
                borderRadius: 999,
                color: Colors.primaryBackground,
                alignment: Alignment.center,
                shadow: chipShadow(),
                visible: Not(Param('isLast')),
                onTap: ParamAction('onNext'),
                child: Icon('chevron_left', size: 34, color: Colors.primary),
              ),
              Text(
                'التالي',
                style: Styles.labelSmall,
                color: Colors.primaryText,
                maxLines: 1,
                visible: Not(Param('isLast')),
              ),
              Container(
                height: 64,
                borderRadius: 999,
                color: Colors.primary,
                padding: EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                shadow: chipShadow(),
                visible: Param('isLast'),
                onTap: ParamAction('onFinish'),
                child: Row(
                  mainAxis: MainAxis.center,
                  spacing: 8,
                  children: [
                    Icon('star', size: 26, color: Colors.hex(kWhite)),
                    Text(
                      'انتهت الحكاية',
                      style: Styles.titleMedium,
                      color: Colors.hex(kWhite),
                      maxLines: 1,
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

  // -------------------------------------------------------------------------
  // 14. KSSubscriptionPlanCard — store prices only, never invented numbers.
  // -------------------------------------------------------------------------
  app.component(
    'KSSubscriptionPlanCard',
    description:
        'One selectable plan. priceText is a placeholder that the store price '
        'replaces later — no price is hard-coded. Params: planName, '
        'billingPeriod, priceText, selected, recommended, onSelect.',
    params: {
      'planName': string.withDefault('اشتراك شهري'),
      'billingPeriod': string.withDefault('كل شهر'),
      'priceText': string.withDefault('السعر من المتجر'),
      'selected': bool_.withDefault(false),
      'recommended': bool_.withDefault(false),
      'onSelect': action,
    },
    body: Container(
      name: 'PlanCardRoot',
      borderRadius: 24,
      color: Colors.primaryBackground,
      padding: EdgeInsets.all(20),
      onTap: ParamAction('onSelect'),
      child: Stack(
        children: [
          // Unselected outline.
          Container(
            borderRadius: 24,
            borderColor: Colors.hex(kOutline),
            borderWidth: 1,
            visible: Not(Param('selected')),
          ),
          Column(
            crossAxis: CrossAxis.start,
            spacing: 10,
            children: [
              Row(
                spacing: 10,
                crossAxis: CrossAxis.center,
                children: [
                  Icon(
                    'radio_button_unchecked',
                    size: 26,
                    color: Colors.secondaryText,
                    visible: Not(Param('selected')),
                  ),
                  Icon(
                    'check_circle',
                    size: 26,
                    color: Colors.primary,
                    visible: Param('selected'),
                  ),
                  Expanded(
                    Text(
                      Param('planName'),
                      style: Styles.titleSmall,
                      color: Colors.primaryText,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    borderRadius: 999,
                    color: Colors.tertiary,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visible: Param('recommended'),
                    child: Text(
                      'الأفضل قيمة',
                      style: Styles.labelSmall,
                      color: Colors.hex(kTextDarkBlue),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              // Price placeholder — replaced by the localised store string.
              Text(
                Param('priceText'),
                style: Styles.titleLarge,
                color: Colors.primary,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                name: 'PlanPriceText',
              ),
              Text(
                Param('billingPeriod'),
                style: Styles.bodyMedium,
                color: Colors.secondaryText,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Selected border drawn on top so the state is not colour-only.
          Container(
            borderRadius: 24,
            borderColor: Colors.primary,
            borderWidth: 3,
            visible: Param('selected'),
          ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // 15. KSLockedStoryOverlay — child-facing lock. No prices, no store words.
  // -------------------------------------------------------------------------
  app.component(
    'KSLockedStoryOverlay',
    description:
        'Child-facing lock for premium stories. Shows no price and no store '
        'branding; the only way on is the parent area. Params: titleAr, '
        'onParentTap, onClose.',
    params: {
      'titleAr': string.withDefault('هذه الحكاية مميزة'),
      'onParentTap': action,
      'onClose': action,
    },
    body: Container(
      name: 'LockedOverlayRoot',
      color: Colors.hex(kScrim),
      padding: EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Container(
        borderRadius: 28,
        color: Colors.primaryBackground,
        padding: EdgeInsets.all(24),
        shadow: softShadow(),
        child: Column(
          crossAxis: CrossAxis.center,
          spacing: 16,
          children: [
            Container(
              width: 120,
              height: 120,
              borderRadius: 999,
              color: Colors.alternate,
              alignment: Alignment.center,
              child: Icon('lock', size: 56, color: Colors.primary),
            ),
            Text(
              Param('titleAr'),
              style: Styles.titleLarge,
              color: Colors.primaryText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'هذه القصة من المكتبة المميزة — اطلب من أحد الوالدين',
              style: Styles.bodyMedium,
              color: Colors.secondaryText,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              height: 64,
              borderRadius: 999,
              color: Colors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              onTap: ParamAction('onParentTap'),
              child: Row(
                mainAxis: MainAxis.center,
                spacing: 10,
                children: [
                  Icon(
                    'family_restroom',
                    size: 26,
                    color: Colors.hex(kWhite),
                  ),
                  Text(
                    'للأهل',
                    style: Styles.titleMedium,
                    color: Colors.hex(kWhite),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Container(
              height: 56,
              borderRadius: 999,
              color: Colors.primaryBackground,
              borderColor: Colors.primary,
              borderWidth: 2,
              padding: EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              onTap: ParamAction('onClose'),
              child: Text(
                'رجوع',
                style: Styles.titleMedium,
                color: Colors.primary,
                maxLines: 1,
              ),
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

/// One secondary transport control with a visible Arabic caption.
DslWidget _audioButton({
  required String iconName,
  required String captionAr,
  required bool filled,
  required List<DslAction> onTap,
}) => Column(
  crossAxis: CrossAxis.center,
  spacing: 4,
  children: [
    Container(
      width: 56,
      height: 56,
      borderRadius: 999,
      color: filled ? Colors.primary : Colors.alternate,
      alignment: Alignment.center,
      onTap: onTap,
      child: Icon(
        iconName,
        size: 28,
        color: filled ? Colors.hex(kWhite) : Colors.primary,
      ),
    ),
    Text(
      captionAr,
      style: Styles.labelSmall,
      color: Colors.primaryText,
      maxLines: 1,
    ),
  ],
);
