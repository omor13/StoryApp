/// Kids Stories — Rebuild R1: adopt the KidStoryApp (kid-story-app-vel697)
/// colour system.
///
/// Values were read out of that project's own page trees, not invented: the
/// cream/sand surfaces, the purple actions, the indigo headings and the warm
/// brown body text are the colours it actually paints with.
///
/// Because every KS component binds theme slots rather than literals, moving
/// the slots restyles the whole component library in one push.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildR1,
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
// Palette lifted from kid-story-app-vel697
// ---------------------------------------------------------------------------
const int kPurple = 0xFF5E35B1; // primary actions, active icons
const int kPurpleDeep = 0xFF5632AA; // emphasised purple text
const int kTeal = 0xFF96BBB4; // muted supporting surface
const int kSand = 0xFFE7D2B7; // sand panels, chips
const int kWarmGrey = 0xFFD8CEBF; // secondary surface
const int kCream = 0xFFFDF5E7; // main card / page surface
const int kOffWhite = 0xFFFFFCFA; // raised card
const int kBody = 0xFF232323; // body text
const int kBrown = 0xFF594531; // secondary text
const int kIndigo = 0xFF1E1165; // headings
const int kLabelBlue = 0xFF153B96; // form labels
const int kTitleViolet = 0xFF32287B; // page titles
const int kSuccess = 0xFF249689;
const int kWarning = 0xFFF9CF58;
const int kError = 0xFFE53935;
const int kInfo = 0xFF8FB6D1;

// No-slot tokens.
const int kWhite = 0xFFFFFFFF;
const int kCreamAlt = 0xFFFDF4E3;
const int kCreamLight = 0xFFFFF9F2;
const int kDusty = 0xFFD9C8C0;
const int kClay = 0xFFC9B3A8;
const int kBlush = 0xFFE7D9D6;
const int kSlate = 0xFF36465C;
const int kBrownTitle = 0xFF59422B;
const int kShadow = 0x1F000000;

const String kDisplayFont = 'Baloo Bhaijaan 2';
const String kBodyFont = 'Tajawal';

void buildR1(App app) {
  // -------------------------------------------------------------------------
  // Colour slots
  // -------------------------------------------------------------------------
  app.themeColor('primary', kPurple);
  app.themeColor('secondary', kTeal);
  app.themeColor('tertiary', kSand);
  app.themeColor('alternate', kWarmGrey);
  app.themeColor('primaryBackground', kCream);
  app.themeColor('secondaryBackground', kOffWhite);
  app.themeColor('primaryText', kBody);
  app.themeColor('secondaryText', kBrown);
  app.themeColor('accent1', kPurpleDeep);
  app.themeColor('accent2', kIndigo);
  app.themeColor('accent3', kLabelBlue);
  app.themeColor('accent4', kTitleViolet);
  app.themeColor('success', kSuccess);
  app.themeColor('warning', kWarning);
  app.themeColor('error', kError);
  app.themeColor('info', kInfo);

  // Named palette entries for the tones that have no slot.
  app.raw((project) {
    const namedPalette = <String, int>{
      'white': kWhite,
      'creamAlt': kCreamAlt,
      'creamLight': kCreamLight,
      'dusty': kDusty,
      'clay': kClay,
      'blush': kBlush,
      'slate': kSlate,
      'brownTitle': kBrownTitle,
      'shadowColor': kShadow,
      // Retired Kids Stories tones, kept so existing widgets keep a name.
      'errorText': 0xFFC4404C,
      'successText': 0xFF2F7A4B,
      'outline': 0xFFE3D3B6,
      'outlineStrong': 0xFFC9B48A,
      'disabledSurface': 0xFFEFE6D6,
      'disabledText': 0xFF8E8178,
      'scrim': 0x8C0D1F45,
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
  // Typography — same two families as the reference; the Kids Stories scale is
  // kept because the reference sizes its text with responsive conditionals
  // that the DSL cannot author.
  // -------------------------------------------------------------------------
  app.primaryFont(kDisplayFont);
  app.secondaryFont(kBodyFont);

  app.typography(
    'headlineMedium',
    fontFamily: kDisplayFont,
    fontSize: 34,
    fontWeight: 800,
    lineHeight: 1.3,
    color: kIndigo,
  );
  app.typography(
    'headlineSmall',
    fontFamily: kDisplayFont,
    fontSize: 30,
    fontWeight: 700,
    lineHeight: 1.3,
    color: kIndigo,
  );
  app.typography(
    'titleLarge',
    fontFamily: kDisplayFont,
    fontSize: 24,
    fontWeight: 600,
    lineHeight: 1.35,
    color: kTitleViolet,
  );
  app.typography(
    'titleMedium',
    fontFamily: kBodyFont,
    fontSize: 20,
    fontWeight: 700,
    lineHeight: 1.4,
    color: kBody,
  );
  app.typography(
    'titleSmall',
    fontFamily: kBodyFont,
    fontSize: 18,
    fontWeight: 700,
    lineHeight: 1.4,
    color: kIndigo,
  );
  app.typography(
    'bodyLarge',
    fontFamily: kBodyFont,
    fontSize: 22,
    fontWeight: 500,
    lineHeight: 1.9,
    color: kBody,
  );
  app.typography(
    'bodyMedium',
    fontFamily: kBodyFont,
    fontSize: 18,
    fontWeight: 400,
    lineHeight: 1.6,
    color: kBody,
  );
  app.typography(
    'bodySmall',
    fontFamily: kBodyFont,
    fontSize: 14,
    fontWeight: 400,
    lineHeight: 1.5,
    color: kBrown,
  );
  app.typography(
    'labelMedium',
    fontFamily: kBodyFont,
    fontSize: 16,
    fontWeight: 700,
    lineHeight: 1.4,
    color: kLabelBlue,
  );
  app.typography(
    'labelSmall',
    fontFamily: kBodyFont,
    fontSize: 14,
    fontWeight: 500,
    lineHeight: 1.4,
    color: kBrown,
  );
}
