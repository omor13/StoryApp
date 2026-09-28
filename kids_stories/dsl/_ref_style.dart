/// Shared building blocks of the KidStoryApp (kid-story-app-vel697) design,
/// reproduced for Kids Stories.
///
/// The reference builds every screen from the same four pieces: a full-bleed
/// background image, a header stack with two captioned side buttons and a
/// centred title pill, a star divider, and cream cards. These helpers keep
/// those consistent across the rebuilt pages.
library;

import 'package:flutterflow_ai/flutterflow_ai.dart';

// --- Asset storage paths (uploaded from the reference project) -------------
const String kBgHomeMobile =
    'projects/kids-stories-81ff8u/assets/bf3a50cad78a1f31/ks_bg_home_mobile.png';
const String kBgHomeTablet =
    'projects/kids-stories-81ff8u/assets/a6e3bfff35c4ad04/ks_bg_home_tablet.png';
const String kBgSettings =
    'projects/kids-stories-81ff8u/assets/65b921522630feae/ks_bg_settings_tablet.png';
const String kBgTablet =
    'projects/kids-stories-81ff8u/assets/e1c6d676401a622e/ks_bg_tablet.png';
const String kAvatarBoy =
    'projects/kids-stories-81ff8u/assets/44aeea0f4c0ef441/ks_avatar_boy.png';
const String kAvatarGirl =
    'projects/kids-stories-81ff8u/assets/3ad0c4fac5303977/ks_avatar_girl.png';
const String kIconBook =
    'projects/kids-stories-81ff8u/assets/6f19d87c93afd5c1/ks_icon_book.png';
const String kIconCake =
    'projects/kids-stories-81ff8u/assets/38632b3543ba1924/ks_icon_cake.png';
const String kIconCalendar =
    'projects/kids-stories-81ff8u/assets/79791ac64ef3b30c/ks_icon_calendar.png';
const String kIconMoon =
    'projects/kids-stories-81ff8u/assets/4838b9fb82077782/ks_icon_moon.png';
const String kCover1 =
    'projects/kids-stories-81ff8u/assets/a6ad39594ac3a2a7/ks_story_cover_1.png';
const String kCover2 =
    'projects/kids-stories-81ff8u/assets/9052dbd4b6548790/ks_story_cover_2.png';
const String kCover3 =
    'projects/kids-stories-81ff8u/assets/7567bea83d819f67/ks_story_cover_3.png';
const String kCover4 =
    'projects/kids-stories-81ff8u/assets/a02a4db0629bfc71/ks_story_cover_4.png';

// --- Palette values with no theme slot --------------------------------------
const int kWhite = 0xFFFFFFFF;
const int kCreamAlt = 0xFFFDF4E3;
const int kCreamLight = 0xFFFFF9F2;
const int kDusty = 0xFFD9C8C0;
const int kClay = 0xFFC9B3A8;
const int kBrownTitle = 0xFF59422B;
const int kIndigo = 0xFF1E1165;
const int kLabelBlue = 0xFF153B96;
const int kSoftShadow = 0x1F000000;

Shadow cardShadow() => Shadow(blur: 18, dy: 6, color: Colors.hex(kSoftShadow));

Shadow chipShadow() => Shadow(blur: 8, dy: 3, color: Colors.hex(kSoftShadow));

/// The reference's star divider: a hairline, a star, a hairline.
DslWidget starDivider({String? name}) => Row(
  mainAxis: MainAxis.center,
  crossAxis: CrossAxis.center,
  spacing: 10,
  name: name,
  children: [
    Expanded(Container(height: 1.5, color: Colors.tertiary)),
    Icon('star_rounded', size: 22, color: Colors.tertiary),
    Expanded(Container(height: 1.5, color: Colors.tertiary)),
  ],
);

/// One captioned header button: a 62x62 rounded tile with an icon and an
/// Arabic caption underneath.
DslWidget headerButton({
  required String iconName,
  required String captionAr,
  required List<DslAction> onTap,
  String? name,
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
      child: Icon(iconName, size: 30, color: Colors.primary),
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

/// The reference header: two captioned buttons with a centred title pill.
/// Under RTL the first child renders on the right.
DslWidget headerBar({
  required String titleAr,
  required DslWidget rightButton,
  required DslWidget leftButton,
  String? titleIcon,
}) => Container(
  name: 'HeaderStack',
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  child: Row(
    mainAxis: MainAxis.spaceBetween,
    crossAxis: CrossAxis.center,
    children: [
      rightButton,
      Flexible(
        Container(
          name: 'storyTitleContainer',
          height: 54,
          borderRadius: 999,
          color: Colors.primaryBackground,
          padding: EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          shadow: chipShadow(),
          child: Row(
            name: 'CenterTitleRow',
            mainAxis: MainAxis.center,
            crossAxis: CrossAxis.center,
            spacing: 8,
            children: [
              Flexible(
                Text(
                  titleAr,
                  style: Styles.titleLarge,
                  color: Colors.accent4,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (titleIcon != null)
                Icon(titleIcon, size: 24, color: Colors.primary),
            ],
          ),
        ),
      ),
      leftButton,
    ],
  ),
);

/// A form-section label: Arabic text with a small illustration beside it,
/// exactly as the reference labels its fields.
DslWidget fieldLabel({
  required String labelAr,
  required String imagePath,
  String? name,
}) => Row(
  name: name,
  mainAxis: MainAxis.start,
  crossAxis: CrossAxis.center,
  spacing: 10,
  children: [
    Text(
      labelAr,
      style: Styles.labelMedium,
      color: Colors.accent3,
      textAlign: TextAlign.start,
      maxLines: 1,
    ),
    Image(imagePath, isNetwork: false, width: 34, height: 34),
  ],
);

/// The cream card the reference floats over every background.
DslWidget creamCard({
  required DslWidget child,
  String? name,
  double radius = 28,
  Object? padding,
}) => Container(
  name: name,
  borderRadius: radius,
  color: Colors.primaryBackground,
  padding: padding ?? EdgeInsets.all(20),
  shadow: cardShadow(),
  child: child,
);
