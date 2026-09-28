/// Kids Stories — Batch 2a: prototype app state + core reusable components.
///
/// Components in this batch:
///   KSPrimaryButton · KSSecondaryButton · KSCircularIconButton
///   KSAgeGroupSelector · KSAvatarSelector · KSReadingModeSelector
///   KSEmptyState · KSErrorState · KSLoadingState
///
/// Prototype phase: local app state only. No Firebase, RevenueCat or TTS.
///
/// DSL constraints that shape these components (see the batch report):
/// - Icon glyphs and colours are literals in the DSL, so "optional icon" and
///   "background colour" are modelled as a small set of named choices rendered
///   with conditional visibility rather than as free-form values.
/// - Components cannot own internal state, so the selectors read and write the
///   prototype app-state fields directly.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch2a,
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

// Palette values that have no theme slot.
const int kWhite = 0xFFFFFFFF;
const int kDisabledSurface = 0xFFEFE6D6;
const int kDisabledText = 0xFF8E8178;
const int kOutline = 0xFFE3D3B6;
const int kShadow = 0x2E0D1F45;

Shadow softShadow() => Shadow(blur: 20, dy: 6, color: Colors.hex(kShadow));

Shadow chipShadow() => Shadow(blur: 8, dy: 2, color: Colors.hex(kShadow));

void buildBatch2a(App app) {
  // -------------------------------------------------------------------------
  // Prototype app state — local only, nothing is persisted to a backend.
  // -------------------------------------------------------------------------
  app.state(
    'childNickname',
    string.withDefault(''),
    description: 'Prototype only: nickname typed on ChildProfileSetupPage.',
  );
  app.state(
    'selectedAgeGroup',
    string.withDefault('3-4'),
    description: 'Age group: 1-2, 3-4 or 5-6.',
  );
  app.state(
    'selectedAvatarId',
    string.withDefault('rabbit'),
    description: 'Id of the chosen built-in placeholder avatar.',
  );
  app.state(
    'readingMode',
    string.withDefault('read'),
    description: 'Reading mode: read (اقرأ بنفسي) or listen (استمع).',
  );
  app.state(
    'selectedStoryId',
    string.withDefault('laila-star'),
    description: 'Id of the story opened from the library.',
  );
  app.state(
    'selectedStoryTitle',
    string.withDefault('ليلى والنجمة الصغيرة'),
    description: 'Arabic title of the story opened from the library.',
  );
  app.state(
    'selectedStoryDescription',
    string.withDefault(''),
    description: 'Short Arabic description of the selected story.',
  );
  app.state(
    'selectedStoryAgeGroup',
    string.withDefault('3-4'),
    description: 'Age group of the selected story.',
  );
  app.state(
    'selectedStoryMinutes',
    int_.withDefault(4),
    description: 'Estimated reading time of the selected story, in minutes.',
  );
  app.state(
    'selectedStoryAccess',
    string.withDefault('free'),
    description: 'Access level of the selected story: free or premium.',
  );
  app.state(
    'currentStoryPage',
    int_.withDefault(0),
    description: 'Zero-based page index inside StoryReaderPage.',
  );
  app.state(
    'favoriteStoryIds',
    listOf(string),
    description: 'Prototype favourites, held in memory only.',
  );
  app.state(
    'selectedPlan',
    string.withDefault('annual'),
    description: 'Subscription plan highlighted on SubscriptionPage.',
  );
  app.state(
    'isNarrating',
    bool_.withDefault(false),
    description: 'Prototype playback flag — no real audio is played.',
  );
  app.state(
    'playbackSpeed',
    string.withDefault('1x'),
    description: 'Prototype playback speed label.',
  );

  // -------------------------------------------------------------------------
  // 1. KSPrimaryButton — the single filled action on a screen.
  // -------------------------------------------------------------------------
  app.component(
    'KSPrimaryButton',
    description:
        'Primary child/parent action. Pill, 64 high, purple. Params: label, '
        'iconName (none/book/play/lock/star), enabled, loading, onPressed.',
    params: {
      'label': string.withDefault('ابدأ الحكاية'),
      'iconName': string.withDefault('none'),
      'enabled': bool_.withDefault(true),
      'loading': bool_.withDefault(false),
      'onPressed': action,
    },
    body: Column(
      crossAxis: CrossAxis.stretch,
      children: [
        // Enabled state.
        Container(
          name: 'PrimaryButtonEnabled',
          visible: Param('enabled'),
          height: 64,
          borderRadius: 999,
          color: Colors.primary,
          padding: EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          shadow: softShadow(),
          onTap: ParamAction('onPressed'),
          child: Row(
            mainAxis: MainAxis.center,
            crossAxis: CrossAxis.center,
            spacing: 12,
            children: [
              Icon(
                'auto_stories',
                size: 28,
                color: Colors.hex(kWhite),
                visible: Equals(Param('iconName'), 'book'),
              ),
              Icon(
                'play_arrow',
                size: 28,
                color: Colors.hex(kWhite),
                visible: Equals(Param('iconName'), 'play'),
              ),
              Icon(
                'lock_open',
                size: 28,
                color: Colors.hex(kWhite),
                visible: Equals(Param('iconName'), 'lock'),
              ),
              Icon(
                'star',
                size: 28,
                color: Colors.hex(kWhite),
                visible: Equals(Param('iconName'), 'star'),
              ),
              Text(
                Param('label'),
                style: Styles.titleMedium,
                color: Colors.hex(kWhite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                visible: Not(Param('loading')),
              ),
              ProgressBar.circular(
                size: 26,
                thickness: 3,
                visible: Param('loading'),
              ),
            ],
          ),
        ),
        // Disabled state — same footprint, no tap target.
        Container(
          name: 'PrimaryButtonDisabled',
          visible: Not(Param('enabled')),
          height: 64,
          borderRadius: 999,
          color: Colors.hex(kDisabledSurface),
          padding: EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          child: Text(
            Param('label'),
            style: Styles.titleMedium,
            color: Colors.hex(kDisabledText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  // -------------------------------------------------------------------------
  // 2. KSSecondaryButton — outlined, never competes with the primary action.
  // -------------------------------------------------------------------------
  app.component(
    'KSSecondaryButton',
    description:
        'Secondary outlined pill action, 56 high. Params: label, iconName '
        '(none/back/refresh/restore/settings), enabled, onPressed.',
    params: {
      'label': string.withDefault('رجوع'),
      'iconName': string.withDefault('none'),
      'enabled': bool_.withDefault(true),
      'onPressed': action,
    },
    body: Column(
      crossAxis: CrossAxis.stretch,
      children: [
        Container(
          name: 'SecondaryButtonEnabled',
          visible: Param('enabled'),
          height: 56,
          borderRadius: 999,
          color: Colors.primaryBackground,
          borderColor: Colors.primary,
          borderWidth: 2,
          padding: EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          onTap: ParamAction('onPressed'),
          child: Row(
            mainAxis: MainAxis.center,
            crossAxis: CrossAxis.center,
            spacing: 10,
            children: [
              Icon(
                'arrow_forward',
                size: 24,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'back'),
              ),
              Icon(
                'refresh',
                size: 24,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'refresh'),
              ),
              Icon(
                'restore',
                size: 24,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'restore'),
              ),
              Icon(
                'settings',
                size: 24,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'settings'),
              ),
              Text(
                Param('label'),
                style: Styles.titleMedium,
                color: Colors.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          name: 'SecondaryButtonDisabled',
          visible: Not(Param('enabled')),
          height: 56,
          borderRadius: 999,
          color: Colors.primaryBackground,
          borderColor: Colors.hex(kOutline),
          borderWidth: 2,
          padding: EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          child: Text(
            Param('label'),
            style: Styles.titleMedium,
            color: Colors.hex(kDisabledText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  // -------------------------------------------------------------------------
  // 3. KSCircularIconButton — 64 px child-sized icon control with a caption.
  // -------------------------------------------------------------------------
  app.component(
    'KSCircularIconButton',
    description:
        'Round 64 px icon control with an Arabic caption. Params: iconName '
        '(home/favorite/favoriteOff/next/previous/parent), variant '
        '(cream/filled), caption, semanticLabel, enabled, onPressed.',
    params: {
      'iconName': string.withDefault('home'),
      'variant': string.withDefault('cream'),
      'caption': string.withDefault(''),
      'enabled': bool_.withDefault(true),
      'onPressed': action,
    },
    body: Column(
      crossAxis: CrossAxis.center,
      spacing: 4,
      children: [
        Container(
          name: 'CircleTapTarget',
          width: 64,
          height: 64,
          borderRadius: 999,
          onTap: If(Param('enabled'), then: ParamAction('onPressed')),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Backgrounds by variant.
              Container(
                width: 64,
                height: 64,
                borderRadius: 999,
                color: Colors.primaryBackground,
                shadow: chipShadow(),
                visible: Not(Equals(Param('variant'), 'filled')),
              ),
              Container(
                width: 64,
                height: 64,
                borderRadius: 999,
                color: Colors.primary,
                shadow: chipShadow(),
                visible: Equals(Param('variant'), 'filled'),
              ),
              // Cream variant icons — purple glyphs.
              Icon(
                'home',
                size: 32,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'home'),
              ),
              Icon(
                'favorite',
                size: 32,
                color: Colors.accent2,
                visible: Equals(Param('iconName'), 'favorite'),
              ),
              Icon(
                'favorite_border',
                size: 32,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'favoriteOff'),
              ),
              // RTL: "next" moves the story forward and points to the left.
              Icon(
                'chevron_left',
                size: 34,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'next'),
              ),
              Icon(
                'chevron_right',
                size: 34,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'previous'),
              ),
              Icon(
                'family_restroom',
                size: 30,
                color: Colors.primary,
                visible: Equals(Param('iconName'), 'parent'),
              ),
              // Disabled look: a translucent sand veil over the whole circle.
              Container(
                width: 64,
                height: 64,
                borderRadius: 999,
                color: Colors.hex(0xCCEFE6D6),
                visible: Not(Param('enabled')),
              ),
            ],
          ),
        ),
        Text(
          Param('caption'),
          style: Styles.labelSmall,
          color: Colors.primaryText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          visible: Not(Equals(Param('caption'), '')),
        ),
      ],
    ),
  );

  // -------------------------------------------------------------------------
  // 4. KSAgeGroupSelector — writes the prototype app state directly.
  // -------------------------------------------------------------------------
  app.component(
    'KSAgeGroupSelector',
    description:
        'Three age-group pills (١–٢ / ٣–٤ / ٥–٦). Reads and writes the '
        'selectedAgeGroup app-state field.',
    params: const {},
    body: Column(
      crossAxis: CrossAxis.stretch,
      spacing: 12,
      children: [
        _ageOption('1-2', '١–٢ سنة', 'child_care'),
        _ageOption('3-4', '٣–٤ سنوات', 'toys'),
        _ageOption('5-6', '٥–٦ سنوات', 'school'),
      ],
    ),
  );

  // -------------------------------------------------------------------------
  // 5. KSAvatarSelector — six neutral built-in placeholders, no photographs.
  // -------------------------------------------------------------------------
  app.component(
    'KSAvatarSelector',
    description:
        'Six neutral built-in avatar placeholders. Never asks for a child '
        'photograph. Reads and writes the selectedAvatarId app-state field.',
    params: const {},
    body: Column(
      crossAxis: CrossAxis.stretch,
      spacing: 12,
      children: [
        Row(
          mainAxis: MainAxis.spaceEvenly,
          children: [
            _avatarOption('rabbit', 'pets'),
            _avatarOption('star', 'star'),
            _avatarOption('cloud', 'cloud'),
          ],
        ),
        Row(
          mainAxis: MainAxis.spaceEvenly,
          children: [
            _avatarOption('moon', 'nightlight'),
            _avatarOption('boat', 'sailing'),
            _avatarOption('flower', 'local_florist'),
          ],
        ),
      ],
    ),
  );

  // -------------------------------------------------------------------------
  // 6. KSReadingModeSelector — اقرأ بنفسي / استمع إلى القصة
  // -------------------------------------------------------------------------
  app.component(
    'KSReadingModeSelector',
    description:
        'Segmented selector for the two reading modes. Reads and writes the '
        'readingMode app-state field (read / listen).',
    params: const {},
    body: Container(
      borderRadius: 999,
      color: Colors.alternate,
      padding: EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(_modeSegment('read', 'اقرأ بنفسي', 'menu_book')),
          Expanded(_modeSegment('listen', 'استمع إلى القصة', 'headphones')),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // 7. KSEmptyState
  // -------------------------------------------------------------------------
  app.component(
    'KSEmptyState',
    description:
        'Friendly Arabic empty state with an optional action. Params: titleAr, '
        'bodyAr, actionLabel, showAction, onAction.',
    params: {
      'titleAr': string.withDefault('لا يوجد شيء هنا بعد'),
      'bodyAr': string.withDefault(''),
      'actionLabel': string.withDefault(''),
      'showAction': bool_.withDefault(false),
      'onAction': action,
    },
    body: Container(
      padding: EdgeInsets.all(24),
      borderRadius: 24,
      color: Colors.primaryBackground,
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
            child: Icon('auto_stories', size: 56, color: Colors.primary),
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
            Param('bodyAr'),
            style: Styles.bodyMedium,
            color: Colors.secondaryText,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            visible: Not(Equals(Param('bodyAr'), '')),
          ),
          Container(
            visible: Param('showAction'),
            height: 56,
            borderRadius: 999,
            color: Colors.primary,
            padding: EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            onTap: ParamAction('onAction'),
            child: Text(
              Param('actionLabel'),
              style: Styles.titleMedium,
              color: Colors.hex(kWhite),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // 8. KSErrorState
  // -------------------------------------------------------------------------
  app.component(
    'KSErrorState',
    description:
        'Recoverable error with an Arabic retry action. Params: titleAr, '
        'bodyAr, retryLabel, onRetry.',
    params: {
      'titleAr': string.withDefault('حدث خطأ'),
      'bodyAr': string.withDefault('حاول مرة أخرى بعد قليل.'),
      'retryLabel': string.withDefault('حاول مجددًا'),
      'onRetry': action,
    },
    body: Container(
      padding: EdgeInsets.all(24),
      borderRadius: 24,
      color: Colors.primaryBackground,
      child: Column(
        crossAxis: CrossAxis.center,
        spacing: 16,
        children: [
          Container(
            width: 104,
            height: 104,
            borderRadius: 999,
            color: Colors.alternate,
            alignment: Alignment.center,
            child: Icon('error_outline', size: 52, color: Colors.error),
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
            Param('bodyAr'),
            style: Styles.bodyMedium,
            color: Colors.secondaryText,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            height: 56,
            borderRadius: 999,
            color: Colors.primary,
            padding: EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            onTap: ParamAction('onRetry'),
            child: Row(
              mainAxis: MainAxis.center,
              spacing: 8,
              children: [
                Icon('refresh', size: 24, color: Colors.hex(kWhite)),
                Text(
                  Param('retryLabel'),
                  style: Styles.titleMedium,
                  color: Colors.hex(kWhite),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // 9. KSLoadingState
  // -------------------------------------------------------------------------
  app.component(
    'KSLoadingState',
    description: 'Page-level loading indicator with an Arabic message.',
    params: {'messageAr': string.withDefault('جارٍ تحضير القصة…')},
    body: Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxis: MainAxis.center,
        crossAxis: CrossAxis.center,
        spacing: 16,
        children: [
          ProgressBar.circular(size: 48, thickness: 4),
          Text(
            Param('messageAr'),
            style: Styles.bodyMedium,
            color: Colors.secondaryText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Local builders
// ---------------------------------------------------------------------------

/// One age-group pill. Selected and unselected are two stacked containers so
/// the state reads from colour *and* a check icon, never colour alone.
DslWidget _ageOption(String id, String labelAr, String iconName) => Stack(
  children: [
    // Unselected.
    Container(
      height: 64,
      borderRadius: 999,
      color: Colors.alternate,
      padding: EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      visible: Not(Equals(AppState('selectedAgeGroup'), id)),
      onTap: UpdateAppState.set('selectedAgeGroup', id),
      child: Row(
        crossAxis: CrossAxis.center,
        spacing: 12,
        children: [
          Icon(iconName, size: 28, color: Colors.primary),
          Text(
            labelAr,
            style: Styles.titleMedium,
            color: Colors.primaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    // Selected.
    Container(
      height: 64,
      borderRadius: 999,
      color: Colors.primary,
      padding: EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      shadow: chipShadow(),
      visible: Equals(AppState('selectedAgeGroup'), id),
      child: Row(
        crossAxis: CrossAxis.center,
        spacing: 12,
        children: [
          Icon(iconName, size: 28, color: Colors.hex(kWhite)),
          Expanded(
            Text(
              labelAr,
              style: Styles.titleMedium,
              color: Colors.hex(kWhite),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon('check_circle', size: 26, color: Colors.hex(kWhite)),
        ],
      ),
    ),
  ],
);

/// One built-in avatar placeholder: a coloured disc with a friendly glyph.
DslWidget _avatarOption(String id, String iconName) => Container(
  width: 88,
  height: 88,
  onTap: UpdateAppState.set('selectedAvatarId', id),
  child: Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 80,
        height: 80,
        borderRadius: 999,
        color: Colors.alternate,
        borderColor: Colors.hex(kOutline),
        borderWidth: 2,
        alignment: Alignment.center,
        visible: Not(Equals(AppState('selectedAvatarId'), id)),
        child: Icon(iconName, size: 40, color: Colors.primary),
      ),
      Container(
        width: 84,
        height: 84,
        borderRadius: 999,
        color: Colors.alternate,
        borderColor: Colors.tertiary,
        borderWidth: 4,
        alignment: Alignment.center,
        visible: Equals(AppState('selectedAvatarId'), id),
        child: Icon(iconName, size: 44, color: Colors.primary),
      ),
      Container(
        width: 26,
        height: 26,
        borderRadius: 999,
        color: Colors.primary,
        alignment: Alignment.center,
        visible: Equals(AppState('selectedAvatarId'), id),
        child: Icon('check', size: 18, color: Colors.hex(kWhite)),
      ),
    ],
  ),
);

/// One reading-mode segment.
DslWidget _modeSegment(String id, String labelAr, String iconName) => Container(
  height: 56,
  onTap: UpdateAppState.set('readingMode', id),
  child: Stack(
    alignment: Alignment.center,
    children: [
      Container(
        height: 56,
        borderRadius: 999,
        alignment: Alignment.center,
        visible: Not(Equals(AppState('readingMode'), id)),
        child: Row(
          mainAxis: MainAxis.center,
          spacing: 8,
          children: [
            Icon(iconName, size: 24, color: Colors.primaryText),
            Flexible(
              Text(
                labelAr,
                style: Styles.labelMedium,
                color: Colors.primaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      Container(
        height: 56,
        borderRadius: 999,
        color: Colors.primary,
        alignment: Alignment.center,
        shadow: chipShadow(),
        visible: Equals(AppState('readingMode'), id),
        child: Row(
          mainAxis: MainAxis.center,
          spacing: 8,
          children: [
            Icon(iconName, size: 24, color: Colors.hex(kWhite)),
            Flexible(
              Text(
                labelAr,
                style: Styles.labelMedium,
                color: Colors.hex(kWhite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
