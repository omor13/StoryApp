/// Kids Stories — Batch 1: project configuration, Arabic/RTL, colours, type.
///
/// Prototype phase. No Firebase, RevenueCat, TTS, or store configuration.
///
/// Sources of truth:
/// - docs/DESIGN_SYSTEM.md  §3 colours, §4 typography, §5 spacing, §6 shape
/// - docs/FLUTTERFLOW_SCREEN_SPEC.md §1.2 project settings checklist
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildBatch1,
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

// ---------------------------------------------------------------------------
// Colour tokens (docs/DESIGN_SYSTEM.md §3.1 / §3.2)
// ---------------------------------------------------------------------------
const int kPrimary = 0xFF7442C8; // primary
const int kPrimaryLight = 0xFF916BC1; // primaryLight
const int kStoryBlueDark = 0xFF122EA1; // storyBlueDark
const int kStoryBlue = 0xFF066CDE; // storyBlue
const int kBackgroundCream = 0xFFFFF8EA; // backgroundCream
const int kSurfaceSand = 0xFFF0DCB2; // surfaceSand
const int kParentBackground = 0xFFF8ECE9; // parentBackground
const int kAccentGold = 0xFFF5B83D; // accentGold
const int kAccentPink = 0xFFEE7692; // accentPink
const int kTextPrimary = 0xFF40352F; // textPrimary
const int kTextDarkBlue = 0xFF0D1F45; // textDarkBlue
const int kError = 0xFFE95763; // error
const int kSuccess = 0xFF4FAE70; // success
const int kWhite = 0xFFFFFFFF; // white

// Derived tokens — needed for contrast and state styling.
const int kTextSecondary = 0xFF6B5E56;
const int kErrorText = 0xFFC4404C;
const int kSuccessText = 0xFF2F7A4B;
const int kOutline = 0xFFE3D3B6;
const int kOutlineStrong = 0xFFC9B48A;
const int kDisabledSurface = 0xFFEFE6D6;
const int kDisabledText = 0xFF8E8178;
const int kScrim = 0x8C0D1F45; // textDarkBlue @ 55%
const int kShadowColor = 0x2E0D1F45; // textDarkBlue @ 18%

// ---------------------------------------------------------------------------
// Fonts — both ship full Arabic coverage (docs/DESIGN_SYSTEM.md §4.1)
// ---------------------------------------------------------------------------
const String kDisplayFont = 'Baloo Bhaijaan 2';
const String kBodyFont = 'Tajawal';

void buildBatch1(App app) {
  // -------------------------------------------------------------------------
  // 1. Arabic as the only app language (drives RTL through the Flutter
  //    localisation delegates already wired into the generated app).
  // -------------------------------------------------------------------------
  app.raw((project) {
    final arabic = FFLanguage(language: 'ar');
    final i18n = project.ensureAppSettings()
        .ensureInternationalizationSettings();
    i18n.languages.clear();
    i18n.languages.add(arabic);
    i18n.primaryLanguage = arabic;
    i18n.displayLanguage = arabic;
  });

  // -------------------------------------------------------------------------
  // 2. Colour scheme — slot mapping from docs/DESIGN_SYSTEM.md §3.3.
  //    Light theme only in MVP, so no `dark:` variants are declared.
  // -------------------------------------------------------------------------
  app.themeColor('primary', kPrimary);
  app.themeColor('secondary', kStoryBlue);
  app.themeColor('tertiary', kAccentGold);
  app.themeColor('alternate', kSurfaceSand);
  app.themeColor('primaryBackground', kBackgroundCream);
  app.themeColor('secondaryBackground', kParentBackground);
  app.themeColor('primaryText', kTextPrimary);
  app.themeColor('secondaryText', kTextSecondary);
  app.themeColor('accent1', kPrimaryLight);
  app.themeColor('accent2', kAccentPink);
  app.themeColor('accent3', kStoryBlueDark);
  app.themeColor('accent4', kTextDarkBlue);
  app.themeColor('success', kSuccess);
  app.themeColor('warning', kAccentGold);
  app.themeColor('error', kError);
  app.themeColor('info', kStoryBlue);

  // Tokens with no theme slot — exposed in the editor palette so visual work
  // picks the same values. `app.customPaletteColor` cannot name a colour and
  // FlutterFlow rejects unnamed palette entries, so these go in raw.
  app.raw((project) {
    const namedPalette = <String, int>{
      'white': kWhite,
      'errorText': kErrorText,
      'successText': kSuccessText,
      'outline': kOutline,
      'outlineStrong': kOutlineStrong,
      'disabledSurface': kDisabledSurface,
      'disabledText': kDisabledText,
      'scrim': kScrim,
      'shadowColor': kShadowColor,
    };
    final scheme = project.ensureTheme().ensureColorScheme();
    for (final entry in namedPalette.entries) {
      final colour = ffColor(entry.value)..paletteColorName = entry.key;
      final index = scheme.customPaletteColors.indexWhere(
        (c) => c.paletteColorName == entry.key,
      );
      if (index >= 0) {
        scheme.customPaletteColors[index] = colour;
      } else {
        scheme.customPaletteColors.add(colour);
      }
    }
  });

  // -------------------------------------------------------------------------
  // 3. Light theme only + breakpoints (docs/DESIGN_SYSTEM.md §5.3)
  //    Compact < 600 · Medium 600-839 · Expanded >= 840.
  // -------------------------------------------------------------------------
  app.darkMode(enabled: false);
  app.breakpoints(small: 599, medium: 839, large: 1199);

  // -------------------------------------------------------------------------
  // 4. Typography.
  //
  //    Only ten style tokens can be bound from widgets (headlineMedium,
  //    headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge,
  //    bodyMedium, bodySmall, labelMedium, labelSmall), so the Kids Stories
  //    scale is mapped onto those ten. The display/headlineLarge/labelLarge
  //    slots are still configured so the editor theme is complete.
  // -------------------------------------------------------------------------
  app.primaryFont(kDisplayFont);
  app.secondaryFont(kBodyFont);

  // Display title 34 — splash wordmark, biggest child headings.
  app.typography(
    'headlineMedium',
    fontFamily: kDisplayFont,
    fontSize: 34,
    fontWeight: 800,
    lineHeight: 1.3,
    color: kTextPrimary,
  );
  // Page title 30.
  app.typography(
    'headlineSmall',
    fontFamily: kDisplayFont,
    fontSize: 30,
    fontWeight: 700,
    lineHeight: 1.3,
    color: kTextPrimary,
  );
  // Section title 24.
  app.typography(
    'titleLarge',
    fontFamily: kDisplayFont,
    fontSize: 24,
    fontWeight: 600,
    lineHeight: 1.35,
    color: kTextPrimary,
  );
  // Button text 20.
  app.typography(
    'titleMedium',
    fontFamily: kBodyFont,
    fontSize: 20,
    fontWeight: 700,
    lineHeight: 1.4,
    color: kTextPrimary,
  );
  // Card / list titles 18.
  app.typography(
    'titleSmall',
    fontFamily: kBodyFont,
    fontSize: 18,
    fontWeight: 700,
    lineHeight: 1.4,
    color: kTextPrimary,
  );
  // Story text 22 with the generous Arabic line height.
  app.typography(
    'bodyLarge',
    fontFamily: kBodyFont,
    fontSize: 22,
    fontWeight: 500,
    lineHeight: 1.9,
    color: kTextPrimary,
  );
  // Body text 18.
  app.typography(
    'bodyMedium',
    fontFamily: kBodyFont,
    fontSize: 18,
    fontWeight: 400,
    lineHeight: 1.6,
    color: kTextPrimary,
  );
  // Caption 14 — parent surfaces only.
  app.typography(
    'bodySmall',
    fontFamily: kBodyFont,
    fontSize: 14,
    fontWeight: 400,
    lineHeight: 1.5,
    color: kTextSecondary,
  );
  // Chips and icon-button captions 16.
  app.typography(
    'labelMedium',
    fontFamily: kBodyFont,
    fontSize: 16,
    fontWeight: 700,
    lineHeight: 1.4,
    color: kTextPrimary,
  );
  // Small parent-side labels 14.
  app.typography(
    'labelSmall',
    fontFamily: kBodyFont,
    fontSize: 14,
    fontWeight: 500,
    lineHeight: 1.4,
    color: kTextSecondary,
  );

  // Configured for completeness; widgets cannot bind these tokens.
  app.typography(
    'displayLarge',
    fontFamily: kDisplayFont,
    fontSize: 34,
    fontWeight: 800,
    lineHeight: 1.3,
  );
  app.typography(
    'displayMedium',
    fontFamily: kDisplayFont,
    fontSize: 30,
    fontWeight: 700,
    lineHeight: 1.3,
  );
  app.typography(
    'displaySmall',
    fontFamily: kDisplayFont,
    fontSize: 28,
    fontWeight: 700,
    lineHeight: 1.3,
  );
  app.typography(
    'headlineLarge',
    fontFamily: kDisplayFont,
    fontSize: 26,
    fontWeight: 600,
    lineHeight: 1.35,
  );
  app.typography(
    'labelLarge',
    fontFamily: kBodyFont,
    fontSize: 16,
    fontWeight: 700,
    lineHeight: 1.4,
  );

  // -------------------------------------------------------------------------
  // 5. Design tokens — 8-point spacing, storybook radii, soft shadows.
  // -------------------------------------------------------------------------
  // The project already ships xs/sm/md/lg/xl spacing (4/8/16/24/32) and
  // sm/md/lg/full radii (8/16/24/9999), which already sit on the 8-point
  // scale — only the tokens Kids Stories adds are declared here.
  app.spacingToken('xxl', 48);

  app.radiusToken('card', 24);
  app.radiusToken('xl', 28);

  app.shadowToken('soft1', blurRadius: 8, dy: 2, color: kShadowColor);
  app.shadowToken('soft2', blurRadius: 20, dy: 6, color: kShadowColor);
  app.shadowToken(
    'soft3',
    blurRadius: 32,
    dy: 12,
    spreadRadius: -4,
    color: kShadowColor,
  );

  // Scroll + refresh polish in brand colours.
  app.pullToRefresh(
    indicatorColor: kPrimary,
    backgroundColor: kBackgroundCream,
    strokeWidth: 3,
  );
}
