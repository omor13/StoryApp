# Kids Stories — Design System

| | |
|---|---|
| Status | Draft v0.1 — planning phase. Defines the visual system used by [FLUTTERFLOW_SCREEN_SPEC.md](FLUTTERFLOW_SCREEN_SPEC.md) and encoded in [design/design_tokens.json](../design/design_tokens.json). No artwork, fonts, or FlutterFlow theme exist yet. |
| Last updated | 2026-09-21 |
| Related docs | [PRODUCT_SPEC.md](PRODUCT_SPEC.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [FIREBASE_SCHEMA.md](FIREBASE_SCHEMA.md) · [SECURITY_AND_PRIVACY.md](SECURITY_AND_PRIVACY.md) · [MONETIZATION_AND_TTS.md](MONETIZATION_AND_TTS.md) · [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |

**Labels:** **[CONFIRMED]** decided by the owner · **[DERIVED]** a value this document derives from confirmed tokens (may be tuned) · **[ASSUMPTION]** · **[DECISION NEEDED]** · **[VERIFY]** check against the tool/font/store before relying on it · **[ASSET NEEDED]** an artwork or brand asset that does not exist yet.

Units: "px" means Flutter logical pixels (dp) throughout.

---

## 1. Brand

| Item | Value |
|---|---|
| Public product name | **Kids Stories** **[CONFIRMED]** |
| Arabic display name / wordmark | **[ASSET NEEDED — DECISION NEEDED D-29]** No Arabic name has been confirmed. Screens use the Latin wordmark "Kids Stories" until an Arabic name or Arabic wordmark is provided. Do not invent one. |
| Audience | Children aged 1–6 (three groups: `1-2`, `3-4`, `5-6`) and their parents. Arabic-first, fully RTL. |
| Personality | Warm, safe, joyful, magical, calm. Never scary, never loud, never salesy. |
| Two visual modes | **Child mode** — magical storybook: illustrated night skies, cream surfaces, purple actions, gold highlights. **Parent mode** — calm: soft cream and blush backgrounds, reduced decoration, clear headings, no child-directed purchasing language. |
| Tagline / voice | Arabic copy is short, friendly, and addressed to the child in child mode ("من يقرأ اليوم؟") and to the adult in parent mode ("للأهل"). Simple MSA. |

---

## 2. Visual direction and illustration guidance

### 2.1 Direction (reference-inspired, not copied) **[CONFIRMED]**
A polished magical storybook: friendly fantasy landscapes, deep blue night skies with soft stars, soft clouds, small castles, lanterns, open books, and gentle animal characters. Large rounded cream surfaces float over the artwork; purple carries the actions; gold is used sparingly for highlights and celebration.

**Originality rule:** the reference images describe a *mood*, not assets. All illustrations, characters, backgrounds, icons, and avatars must be original commissions or properly licensed stock with a licence that covers commercial mobile-app use and, where relevant, app-store marketing. Never trace, redraw, or "closely inspire" from a specific third-party image, character, or franchise. Keep a licence record per asset in the asset inventory (§14).

### 2.2 Style attributes for illustrators
| Attribute | Guidance |
|---|---|
| Shapes | Soft, rounded, chunky. No sharp points near characters' faces. |
| Faces | Big friendly eyes, closed-mouth or gentle smiles; no fangs, claws, or angry brows. |
| Characters | Gentle animals (rabbit, cloud-sheep, owl, fox, bear cub, cat) and everyday objects with faces are welcome; no monsters, skeletons, or realistic predators. |
| Lighting | Night scenes are *cosy*, not dark: lanterns, moonlight, glowing windows; shadows are soft and blue, never black. |
| Palette | Sky: `storyBlueDark` → `storyBlue` gradients; stars and lantern glow in `accentGold`; blush accents in `accentPink`; grass/hills desaturated teal-greens **[DERIVED — illustration only, not UI]**; UI surfaces in `backgroundCream` / `surfaceSand`. |
| Texture | Subtle paper grain allowed on illustrations; UI surfaces stay flat and clean. |
| Density | Backgrounds have a **low-detail zone** (see 2.4) where UI cards sit. Story-page illustrations may be dense; UI backgrounds must not be. |
| Text in art | Never bake text (Arabic or Latin) into illustrations. |
| Motion | Gentle drift (clouds, stars twinkle) only; nothing flashes. |

### 2.3 Forbidden content in child-facing artwork
Scary faces or silhouettes, weapons, fire as danger, darkness as threat, injury, crying that is not immediately comforted, food/brand logos, screens/phones, and any real-world commercial mascots.

### 2.4 Background assets (child mode)
| Asset | Spec | Notes |
|---|---|---|
| `bg_night_sky_phone` | 1080 × 2340 px portrait, WebP, ≤ 350 KB | Top 55 %: sky, stars, castle silhouettes; bottom 45 %: low-detail soft hills/clouds where the form card sits. |
| `bg_night_sky_tablet` | 1600 × 2560 px portrait (+ 2560 × 1600 landscape if D-08 enables landscape), WebP, ≤ 600 KB | Same zoning; safe zone scales with layout. |
| `bg_home_day` **[ASSUMPTION]** | Same sizes | Softer daytime variant for `HomePage` if night everywhere feels heavy — decide after first mock. |
| `bg_parent_calm` | Flat colour `parentBackground` with an optional 5 %-opacity cloud motif | No characters in parent mode. |
| Overlays | Decorative sticker layers (stars, small clouds) as separate PNG/SVG so they can be hidden under reduce-motion or on small screens. | |

Rule: **important text never sits directly on artwork**. Text lives on `backgroundCream` (opaque) or `surfaceSand` cards over the background. If a translucent surface is ever used, keep it ≥ 92 % opaque and re-check contrast.

---

## 3. Colour system

### 3.1 Base tokens **[CONFIRMED]**
| Token | Hex | Role |
|---|---|---|
| `primary` | `#7442C8` | Primary actions, selected states, progress, links in parent mode |
| `primaryLight` | `#916BC1` | Pressed/hover of primary, decorative fills, secondary chips — **not** for small white text (contrast 4.1:1) |
| `storyBlueDark` | `#122EA1` | Night-sky gradient start, deep decorative panels, headline accents on cream |
| `storyBlue` | `#066CDE` | Sky gradient end, informational accents, "listen" mode accent |
| `backgroundCream` | `#FFF8EA` | Main opaque surface for cards and child screens |
| `surfaceSand` | `#F0DCB2` | Secondary surface: chips, unselected options, dividers' background |
| `parentBackground` | `#F8ECE9` | Page background in parent mode |
| `accentGold` | `#F5B83D` | Highlights, stars, "best value" badge, celebration; always with dark text |
| `accentPink` | `#EE7692` | Favourite (heart) fill, soft decorative accents; always with dark text |
| `textPrimary` | `#40352F` | Default text on cream/sand/blush |
| `textDarkBlue` | `#0D1F45` | Headings on cream, text on gold/pink, scrim base |
| `error` | `#E95763` | Error fills, icons, borders — body-size error *text* uses `errorText` |
| `white` | `#FFFFFF` | Text on primary / blue, icon on filled buttons |

### 3.2 Derived tokens **[DERIVED — tune after first build]**
| Token | Hex / value | Why |
|---|---|---|
| `textSecondary` | `#6B5E56` | Secondary text on cream (5.9:1) |
| `textOnPrimary` | `#FFFFFF` | Alias |
| `textOnGold` | `#0D1F45` | Alias of `textDarkBlue` |
| `errorText` | `#C4404C` | `error` on cream is only 3.3:1; this darker shade reaches 4.8:1 for body-size error messages |
| `success` | `#2F7A4B` | Completion/purchase success (5.2:1 with white; 5.0:1 on cream). No success colour was in the base palette. |
| `outline` | `#E3D3B6` | Card borders on cream, dividers |
| `outlineStrong` | `#C9B48A` | Text-field borders (parent mode) |
| `disabledSurface` | `#EFE6D6` | Disabled fills |
| `disabledText` | `#8E8178` | Disabled labels (≈ 3.6:1 on cream; WCAG exempts inactive controls, but keep them legible) |
| `scrim` | `rgba(13,31,69,0.55)` | Overlays (lock, dialogs) — `textDarkBlue` at 55 % |
| `shadowColor` | `rgba(13,31,69,0.18)` | All soft shadows |
| `gradientNightSky` | `#0D1F45 → #122EA1 → #066CDE` (top → bottom) | Decorative only; never behind body text |
| `gradientCelebration` | `#F5B83D → #EE7692` | Story-complete state accents only |

### 3.3 Semantic roles and FlutterFlow theme-slot mapping
FlutterFlow's theme exposes named colour slots; map them once so every widget picks tokens by role **[VERIFY slot names in the current FlutterFlow version]**.

| FlutterFlow slot | Token |
|---|---|
| Primary | `primary` |
| Secondary | `storyBlue` |
| Tertiary | `accentGold` |
| Alternate | `surfaceSand` |
| Primary Text | `textPrimary` |
| Secondary Text | `textSecondary` |
| Primary Background | `backgroundCream` |
| Secondary Background | `parentBackground` |
| Accent 1 | `primaryLight` |
| Accent 2 | `accentPink` |
| Accent 3 | `storyBlueDark` |
| Accent 4 | `textDarkBlue` |
| Success | `success` |
| Error | `error` |
| Warning | `accentGold` |
| Info | `storyBlue` |

Custom colours to add in FlutterFlow beyond the slots: `errorText`, `outline`, `outlineStrong`, `disabledSurface`, `disabledText`, `scrim`, `white`.

### 3.4 Contrast table (WCAG 2.x, computed — re-verify with a contrast tool before sign-off)
| Foreground on background | Ratio | Use |
|---|---|---|
| `textPrimary` on `backgroundCream` | ≈ 11.2:1 | Body text ✔ |
| `textPrimary` on `surfaceSand` | ≈ 8.8:1 | Chips ✔ |
| `textPrimary` on `parentBackground` | ≈ 10.3:1 | Parent body ✔ |
| `textDarkBlue` on `backgroundCream` | ≈ 15:1 | Headings ✔ |
| `white` on `primary` | ≈ 6.3:1 | Primary buttons ✔ |
| `white` on `storyBlue` | ≈ 5.0:1 | Listen accents ✔ |
| `white` on `storyBlueDark` | ≈ 10.9:1 | Sky panels ✔ |
| `primary` on `backgroundCream` | ≈ 5.9:1 | Purple text/links ✔ |
| `primary` on `surfaceSand` | ≈ 4.7:1 | Purple text on chips ✔ (borderline — keep ≥ 16 px) |
| `white` on `primaryLight` | ≈ 4.1:1 | ✘ for small text; ✔ only for text ≥ 18.7 px bold / 24 px regular |
| `textDarkBlue` on `accentGold` | ≈ 9.1:1 | Badges ✔ |
| `textDarkBlue` on `accentPink` | ≈ 5.9:1 | Pink chips ✔ |
| `white` on `accentGold` / `accentPink` | ≈ 1.8:1 / 2.8:1 | ✘ never |
| `errorText` on `backgroundCream` | ≈ 4.8:1 | Error messages ✔ |
| `error` on `backgroundCream` | ≈ 3.3:1 | Icons/borders only (non-text ≥ 3:1 ✔), not body text |
| `white` on `error` | ≈ 3.5:1 | Only large bold text (e.g., 20 px bold on a danger button) |
| `success` on `backgroundCream` | ≈ 5.0:1 | Success text ✔ |

### 3.5 Usage rules
1. Child screens: `backgroundCream` cards over illustrated backgrounds; `primary` for the one primary action; `accentGold` only for badges, stars, and completion; `accentPink` for the favourite heart.
2. Parent screens: `parentBackground` page, `backgroundCream` cards, `primary` actions, `storyBlue` for informational text, `errorText` for destructive/error text. No gradients, no illustrated backgrounds, no gold except the "best value" badge.
3. Never place `textPrimary` on `primary`, `storyBlue`, or gradients. Never place white on gold, pink, `primaryLight` (small), or cream.
4. One light theme only in MVP; no dark mode **[ASSUMPTION]** (the night-sky art already provides the "night" feel; a true dark theme would need a second contrast pass).

---

## 4. Typography

### 4.1 Families **[CONFIRMED]**
| Role | Family | Weights used | Notes |
|---|---|---|---|
| Display and playful headings | **Baloo Bhaijaan 2** | 600, 700, 800 | Arabic-native display face; used for page titles, story titles, celebratory text, big numbers. |
| Body, story text, forms, controls | **Tajawal** | 400, 500, 700 (800 for emphasis only) | All running text, buttons, labels, inputs. Tajawal has no 600 weight — use 700. |

Requirements: both families ship Arabic glyphs natively; **never** configure a Latin-only font anywhere (including FlutterFlow defaults such as Roboto/Inter for a "secondary" style) — Flutter would silently fall back to a system Arabic font and the UI would mix typefaces. Licensing: both are expected to be Google Fonts under the SIL Open Font License **[VERIFY licence and bundle the font files in the app rather than relying on runtime download]**.

**Diacritics (tashkeel) verification [VERIFY — Phase 1 gate]:** story text carries fatha/damma/kasra/shadda/sukun. Before locking the theme, render three real diacritised pages in Tajawal at 26 px on Android and iOS and check: marks do not collide with the line above, shadda + vowel stacks are legible, and no glyph falls back to a system font. If Tajawal fails this test for story body text only, the documented fallback candidate is Noto Naskh Arabic for `storyBody` while Tajawal remains for UI — this would be a deviation to record (D-06 amendment).

### 4.2 Type scale (roles → FlutterFlow typography slots)
| Role | Family / weight | Size (px) | Line height | FlutterFlow slot | Used for |
|---|---|---|---|---|---|
| `displayLarge` | Baloo 800 | 34 | 1.3 | Display Large | Child page titles ("من يقرأ اليوم؟") |
| `displayMedium` | Baloo 700 | 30 | 1.3 | Display Medium | Story title on details/reader (tablet) |
| `displaySmall` | Baloo 700 | 28 | 1.3 | Display Small | Parent page titles, story title on phone reader |
| `headlineMedium` | Baloo 600 | 24 | 1.35 | Headline Medium | Shelf headings, card section titles |
| `headlineSmall` | Baloo 600 | 22 | 1.35 | Headline Small | Dialog titles |
| `titleLarge` | Tajawal 700 | 22 | 1.4 | Title Large | Primary button (child), plan names |
| `titleMedium` | Tajawal 700 | 20 | 1.4 | Title Medium | Primary button (adult), secondary button, chips selected |
| `titleSmall` | Tajawal 700 | 18 | 1.4 | Title Small | Card titles, list titles |
| `storyBody` | Tajawal 500 | 26 default (min 22; 28 for `3-4`; 30 for `1-2`) | 1.9 | Body Large (overridden per widget) | Story text card only |
| `bodyLarge` | Tajawal 400 | 18 | 1.6 | Body Large | Child-mode helper text, descriptions |
| `bodyMedium` | Tajawal 400 | 16 | 1.6 | Body Medium | Parent body, form input text, legal explanation |
| `bodySmall` | Tajawal 400 | 14 | 1.5 | Body Small | Parent-only captions, timestamps; **never in child mode** |
| `labelLarge` | Tajawal 700 | 16 | 1.4 | Label Large | Chips, tab labels, icon-button captions |
| `labelMedium` | Tajawal 500 | 14 | 1.4 | Label Medium | Parent-only labels |

Rules:
- Story body text ≥ 22 px always; primary button text 20–22 px; page titles 28–34 px. **[CONFIRMED]**
- Line height ≥ 1.8 wherever diacritics may appear (`storyBody`, story titles); ≥ 1.5 elsewhere.
- No letter-spacing on Arabic. No faux bold/italic. No all-caps (irrelevant for Arabic, but keep Latin wordmark as designed).
- Text alignment: `start` (renders right in RTL). No justified text.
- Minimum text size in child mode: 16 px; in parent mode: 14 px.
- Respect system text scaling in parent mode up to 130 %; in child mode clamp `storyBody` scaling to 130 % and keep layout intact (AC-37, R-13).

### 4.3 Numerals and bidi
- Digits in child mode: Arabic-Indic (٠١٢٣) by default (D-05 still open; the token file records the default). Parent mode follows the same choice for consistency; store-returned price strings are shown **exactly as returned** (their locale formatting wins).
- Wrap mixed-direction fragments (prices, emails, codes, "الصفحة ٣ من ١٢") in bidi isolates (`⁨ … ⁩`) via the `formatPriceAr` / `toArabicIndicDigits` helpers.

---

## 5. Layout and spacing

### 5.1 Spacing scale (8-point) **[CONFIRMED]**
`space.1 = 4`, `space.2 = 8`, `space.3 = 12`, `space.4 = 16`, `space.5 = 24`, `space.6 = 32`, `space.7 = 40`, `space.8 = 48`, `space.9 = 64`.

- Page gutter: 16 (phone), 24 (tablet).
- Card padding: 24 (child), 20 (parent).
- Gap between child-mode primary controls: ≥ 16.
- Section spacing between shelves: 32.

### 5.2 Direction **[CONFIRMED]**
The app runs under `Directionality.rtl` with locale `ar`. Leading = right, trailing = left. Rows, lists, and stacks flow right-to-left; page transitions slide from the left for "forward".

### 5.3 Breakpoints and grids
| Class | Width | Story grid columns | Avatar grid | Form max width | Reader max width |
|---|---|---|---|---|---|
| Compact (phones) | < 600 | 2 | 4 × 3 | full width − gutters | full width |
| Medium (small tablets, large phones) | 600–839 | 3 | 6 × 2 | 560 | 720 |
| Expanded (tablets) | ≥ 840 | 4 | 6 × 2 | 640 | 900 |

FlutterFlow: implement with the editor's responsive breakpoints and conditional values for cross-axis counts and max widths **[VERIFY FlutterFlow breakpoint values match; adjust the table to FlutterFlow's if they differ]**.

### 5.4 Orientation and tablets
- Phones: portrait only (D-08 default).
- Tablets: portrait supported at MVP with the scaled layouts above. Landscape on tablets is **[DECISION NEEDED — D-08 refinement]**; if enabled, `StoryReaderPage` places the illustration on the right and the text card on the left (RTL reading order), and forms stay centred at their max width. All other pages simply widen.

### 5.5 Safe areas and system UI
Respect top/bottom safe areas; bottom control bars add 16 px above the home indicator. Status bar icons dark on cream; light on night-sky headers.

---

## 6. Shape and elevation

| Token | Value | Use |
|---|---|---|
| `radius.xs` | 8 | Progress bars, small tags |
| `radius.sm` | 12 | Text fields (parent), small chips |
| `radius.md` | 16 | Category cards (small), list tiles |
| `radius.card` | 24 (allowed 20–28) **[CONFIRMED]** | Story cards, text cards, form cards, plan cards |
| `radius.lg` | 28 | Large hero cards, lock overlay card |
| `radius.pill` | 999 | All buttons, chips, segmented selectors **[CONFIRMED]** |
| `radius.circle` | 50 % | Avatars, circular icon buttons |

Shadows (all `shadowColor`, soft, never harsh):
| Token | Offset / blur / spread | Use |
|---|---|---|
| `shadow.soft1` | 0 2 / 8 / 0 | Chips, small cards |
| `shadow.soft2` | 0 6 / 20 / 0 | Story cards, form cards, buttons at rest |
| `shadow.soft3` | 0 12 / 32 / −4 | Floating control bar, dialogs, lock card |

Borders: 1 px `outline` on cream cards over cream backgrounds (parent mode); no border when a card floats on artwork.

---

## 7. Iconography

- Base set: a rounded, filled icon family (e.g., Material Symbols Rounded, filled) **[ASSUMPTION — any Arabic-neutral rounded set works]**; custom illustrated icons for categories and reading modes **[ASSET NEEDED]**.
- Sizes: 24 (parent inline), 32 (child inline / circular buttons 56–64), 40 (category cards), 48 (hero states).
- Stroke/fill: filled or 2.5 px rounded strokes; single colour (`primary`, `textPrimary`, or `white`).
- **Mirroring in RTL:** mirror directional icons (back/forward chevrons, "next/previous", undo/redo, list bullets). **Do not mirror** play, pause, stop, repeat, volume, clock, search, or check icons (R-02).
- Every icon-only control has a visible Arabic caption in child mode or, at minimum, an Arabic semantic label.

---

## 8. Motion

| Token | Duration | Use |
|---|---|---|
| `duration.fast` | 120 ms | Button press feedback, chip selection |
| `duration.normal` | 200 ms | Fades, state changes |
| `duration.slow` | 320 ms | Card expansion, overlay in/out |
| `duration.pageTurn` | 350 ms | Reader page slide (from the left in RTL) |
| `duration.celebration` | 900 ms | Story-complete stars (once, no loop) |
| `duration.autoAdvanceDelay` | 1500 ms | Pause before automatic page advance (D-24) |
| `duration.skeleton` | 1200 ms | Skeleton shimmer cycle |

Easing: standard ease-out for entrances, ease-in-out for page turns. Under the OS reduce-motion setting: no shimmer, no drifting clouds, page turns become cross-fades (`duration.normal`). Nothing flashes more than once per second (R-12).

---

## 9. Touch and interaction

| Rule | Value |
|---|---|
| Child-facing minimum target | 56 × 56 px **[CONFIRMED]** (supersedes the earlier "48 everywhere" wording in PRODUCT_SPEC R-07) |
| Adult-facing minimum target | 48 × 48 px **[CONFIRMED]** |
| Primary child button height | 64 px default (60 minimum) **[CONFIRMED]** |
| Primary adult button height | 56 px |
| Circular icon buttons | 64 px (child), 48 px (adult) |
| Spacing between adjacent child targets | ≥ 16 px |
| Feedback | Scale to 0.97 + shadow reduce on press (`duration.fast`); optional soft tick sound if `soundEffects` is on |
| Gestures | Tap and horizontal swipe (reader) only. No long-press, double-tap, or drag-to-reorder in child mode. |
| Timing | No auto-dismissing dialogs; the only timed transition is auto-advance, always cancellable by a tap. |
| One primary action | Each child screen has at most one filled `primary` button visible at a time; other actions are secondary or icon buttons. **[CONFIRMED]** |

---

## 10. Component library (FlutterFlow components, prefix `KS`)

All components: RTL by inheritance (no hard-coded left/right — use start/end), accept `isLoading` and `isEnabled` where interactive, expose Arabic `semanticLabel` inputs, and use tokens only (no literal hex in components). Inputs are FlutterFlow component parameters; callbacks are FlutterFlow *action* parameters. Component page state is internal unless listed as an output.

### 10.1 KSPrimaryButton
| | |
|---|---|
| Purpose | The single primary action on a screen ("ابدأ الحكاية", "اشترك الآن"). |
| Inputs | `label: String`, `iconName: String?`, `variant: enum {child, adult, gold}`, `isLoading: bool`, `isEnabled: bool`, `fullWidth: bool = true`, `semanticLabel: String?` |
| Outputs | `onPressed` (action) |
| Dimensions | Height 64 (child) / 56 (adult); min width 200; horizontal padding 24; icon 28 (child) / 24 (adult); radius pill |
| Colours | `child`/`adult`: `primary` fill, `white` text/icon, `shadow.soft2`; pressed: `primaryLight` fill; `gold`: `accentGold` fill, `textDarkBlue` text (celebration/completion only) |
| Typography | `titleLarge` 22 px (child) / `titleMedium` 20 px (adult), Tajawal 700 |
| RTL | Icon sits at the start (right) of the label; label `start`-aligned within a centred row |
| Loading / disabled | Loading: label hidden, 24 px white spinner, button stays same size, taps ignored. Disabled: `disabledSurface` fill, `disabledText` label, no shadow |
| Accessibility | `Semantics(button: true, label: label or semanticLabel, enabled)`; loading announces "جارٍ التحميل"; min target 56/48 |

### 10.2 KSSecondaryButton
| | |
|---|---|
| Purpose | Secondary actions ("تسجيل الدخول", "استعادة المشتريات", "اقرأ مرة أخرى"). |
| Inputs | `label`, `iconName?`, `variant: enum {child, adult, danger}`, `isLoading`, `isEnabled`, `fullWidth`, `semanticLabel?` |
| Outputs | `onPressed` |
| Dimensions | Height 56 (child) / 48 (adult); padding 24; radius pill; 2 px border |
| Colours | Transparent or `backgroundCream` fill, `primary` border and text; pressed: `surfaceSand` fill. `danger` (parent only): `errorText` border and text, never a red fill |
| Typography | `titleMedium` 20 px Tajawal 700 |
| RTL | As primary |
| Loading / disabled | Spinner in `primary`; disabled: `outline` border, `disabledText` text |
| Accessibility | Button semantics; `danger` adds hint "إجراء لا يمكن التراجع عنه" |

### 10.3 KSCircularIconButton
| | |
|---|---|
| Purpose | Icon controls: home, favourite, previous/next, play/pause, stop, repeat, parent entry. |
| Inputs | `iconName`, `size: enum {child 64, adult 48, hero 72}`, `variant: enum {filled, cream, ghost}`, `caption: String?` (visible label under the button), `semanticLabel: String` (required), `isSelected: bool`, `isLoading`, `isEnabled`, `mirrorInRtl: bool = false` |
| Outputs | `onPressed` |
| Dimensions | Diameter 64 / 48 / 72; icon 32 / 24 / 36; caption 4 px below, `labelLarge` 16 px |
| Colours | `filled`: `primary` bg, `white` icon; `cream`: `backgroundCream` bg, `primary` icon, `shadow.soft1`; `ghost`: no bg, `textPrimary` icon. Selected favourite: `accentPink` fill with `textDarkBlue` heart icon |
| Typography | Caption `labelLarge` |
| RTL | Icon mirrored only when `mirrorInRtl` is true (chevrons); media icons never mirrored |
| Loading / disabled | Loading: spinner replaces icon; disabled: `disabledSurface` bg, `disabledText` icon, caption stays |
| Accessibility | `Semantics(button, label: semanticLabel, selected: isSelected)`; `hero` size for play/pause |

### 10.4 KSStoryCard
| | |
|---|---|
| Purpose | Cover tile in shelves and grids with lock, progress, completion, and favourite indicators. |
| Inputs | `storyRef: DocumentReference`, `titleAr`, `coverImageUrl`, `accessLevel`, `isEntitled: bool`, `progressFraction: double?`, `isCompleted: bool`, `isFavorite: bool`, `showFavorite: bool = false`, `estimatedMinutes: int?`, `size: enum {shelf, grid}` |
| Outputs | `onTap`, `onFavoriteToggle?` |
| Dimensions | `shelf`: width 160 (phone) / 200 (tablet), cover 3:4 with `radius.card`; `grid`: fills column; title block 56 high on `backgroundCream`; `shadow.soft2` |
| Colours | Lock badge: `accentGold` pill with lock icon + "مميزة" in `textDarkBlue`; progress ring `primary` on `surfaceSand` track; completed check in `success`; favourite heart `accentPink` |
| Typography | Title `titleSmall` 18 px, max 2 lines, ellipsis; minutes `labelLarge` |
| RTL | Title `start`-aligned; badges at top-start (right); progress ring bottom-start |
| Loading / disabled | Skeleton: sand rectangle + shimmer; image error: `surfaceSand` placeholder with book icon |
| Accessibility | Label: "قصة {titleAr}، {مقفلة|متاحة}، {مكتملة|الصفحة N من M}"; favourite has its own semantics |

### 10.5 KSCategoryCard
| | |
|---|---|
| Purpose | Entry to a category. |
| Inputs | `categoryId`, `nameAr`, `iconId`, `storyCount: int?`, `isSelected` |
| Outputs | `onTap` |
| Dimensions | 140 × 110 (phone), 168 × 128 (tablet); `radius.card`; icon 40 |
| Colours | `surfaceSand` fill, `primary` icon; selected: `primary` fill, `white` icon/text |
| Typography | `titleSmall` 18 px, 1–2 lines |
| RTL | Icon above text, centred; row scrolls from the right |
| Loading / disabled | Skeleton sand block |
| Accessibility | "فئة {nameAr}" + optional "{N} قصص" |

### 10.6 KSStoryTextCard
| | |
|---|---|
| Purpose | The opaque cream card carrying `displayTextAr` in the reader. |
| Inputs | `text: String`, `ageGroup: String` (`1-2`/`3-4`/`5-6`), `fontSizeOverride: double?`, `isHighlighted: bool` (listen mode active), `maxHeightFraction: double = 0.4` |
| Outputs | — |
| Dimensions | Full width − gutters; padding 24; `radius.card`; min height 120; scrolls internally if text exceeds `maxHeightFraction` of the screen (content limits should prevent this) |
| Colours | `backgroundCream` fill ≥ 100 % opaque, `textPrimary`; highlighted: 3 px `storyBlue` border |
| Typography | `storyBody` — 30 px (`1-2`), 28 px (`3-4`), 26 px (`5-6`), min 22; line height 1.9; `start` aligned; Tajawal 500 |
| RTL | Inherits; never `TextAlign.right` literal — use `start` |
| Loading / disabled | Skeleton: three sand lines; empty text: shows "…" placeholder and logs a content error |
| Accessibility | `Semantics(label: text, readOnly, liveRegion: false)`; text scaling clamped to 130 % |

### 10.7 KSAgeGroupSelector
| | |
|---|---|
| Purpose | Choose one of the three age groups. |
| Inputs | `options: List<{id, labelAr, iconName}>` (from `appConfig.ageGroups`), `selectedId: String?`, `isEnabled` |
| Outputs | `onChanged(id)` |
| Dimensions | Vertical stack of 3 pills, each 64 high, full width (phone) / row of 3 (tablet ≥ 600); gap 12; radius pill |
| Colours | Unselected: `surfaceSand` fill, `textPrimary`; selected: `primary` fill, `white` text/icon, `shadow.soft1` |
| Typography | `titleMedium` 20 px |
| RTL | Icon at start (right), label after it; order top-to-bottom 1–2, 3–4, 5–6 |
| Loading / disabled | Disabled: `disabledSurface`/`disabledText` |
| Accessibility | Radio-group semantics: "الفئة العمرية، {label}، محدد/غير محدد" |

### 10.8 KSAvatarSelector
| | |
|---|---|
| Purpose | Pick one of the predefined bundled avatars. |
| Inputs | `avatarIds: List<String>` (from `appConfig.avatarIds`), `selectedId: String?`, `columns: int` (4 phone / 6 tablet) |
| Outputs | `onChanged(id)` |
| Dimensions | Cell 88 × 88 (avatar circle 72 + 8 ring margin), gap 12; target ≥ 56 |
| Colours | Unselected: `backgroundCream` ring 2 px `outline`; selected: 4 px `accentGold` ring + `primary` check badge |
| Typography | None (optional avatar names hidden — avatars are pictures) |
| RTL | Grid fills from the right |
| Loading / disabled | Missing asset → sand circle with animal-silhouette placeholder |
| Accessibility | "الصورة الرمزية {n} من {total}، {محدد}"; each avatar asset ships an Arabic description **[ASSET NEEDED]** |

### 10.9 KSReadingModeSelector
| | |
|---|---|
| Purpose | Switch between "اقرأ بنفسي" and "استمع إلى القصة". |
| Inputs | `mode: enum {read, listen}`, `listenAvailable: bool` (false when no prepared audio and no Arabic TTS), `compact: bool` (icon-only in reader top bar) |
| Outputs | `onChanged(mode)` |
| Dimensions | Segmented pill, height 56, two equal segments; compact: 56 × 56 toggle |
| Colours | Track `surfaceSand`; selected segment `primary` with `white`; `listen` segment uses `storyBlue` icon accent when unselected |
| Typography | `titleMedium` 20 px |
| RTL | First segment (read) at the right |
| Loading / disabled | If `listenAvailable` false: listen segment stays enabled but shows a small warning dot and selecting it opens the TTS-unavailable notice |
| Accessibility | Tab/toggle semantics: "وضع القراءة: اقرأ بنفسي، محدد" |

### 10.10 KSAudioControls
| | |
|---|---|
| Purpose | Playback controls bound to the `StoryNarrator` widget's state. |
| Inputs | `state: enum {idle, loading, playing, paused, completed, audioUnavailable, ttsUnavailable}`, `speed: double`, `speeds: List<double>`, `mode`, `showStop: bool = true`, `showRepeat: bool = true` |
| Outputs | `onPlay`, `onPause`, `onStop`, `onRepeat`, `onSpeedChanged(double)`, `onTtsHelp` (opens the parent-oriented notice) |
| Dimensions | Row: repeat 56 · stop 56 · play/pause 72 (hero) · speed chip 56 × ≥ 72; gaps 16; sits on a cream floating bar 96 high with `shadow.soft3` |
| Colours | Play/pause `primary` filled; others `cream` variant; speed chip `surfaceSand` with `primary` text ("١×") |
| Typography | Speed chip `labelLarge`; captions `labelLarge` |
| RTL | Order from the right: repeat, stop, play/pause, speed **[ASSUMPTION — validate with families]**; media icons not mirrored |
| Loading / disabled | `loading`: play button shows spinner, others disabled; `audioUnavailable`: play replaced by a muted icon + caption "الصوت غير متاح"; `ttsUnavailable`: same plus a small "للأهل" link to the notice |
| Accessibility | Play: "تشغيل الصفحة"; pause: "إيقاف مؤقت"; stop: "إيقاف"; repeat: "إعادة الصفحة"; speed: "سرعة التشغيل {value}"; state changes announced via live region |

### 10.11 KSPageNavigation
| | |
|---|---|
| Purpose | Previous/next page with the page indicator. |
| Inputs | `pageNumber: int`, `pageCount: int`, `canGoNext`, `canGoPrevious`, `isEnabled` |
| Outputs | `onNext`, `onPrevious` |
| Dimensions | Row: **next button at the far left**, **previous at the far right**, indicator centred; buttons 64 circular with captions "التالي" / "السابق"; indicator dots (≤ 12) or "الصفحة ٣ من ١٢" |
| Colours | Buttons `cream` variant with `primary` chevrons; indicator dots `surfaceSand`, current `primary` |
| Typography | Captions `labelLarge`; indicator `bodyLarge` |
| RTL | Chevrons are mirrored (`mirrorInRtl: true`): the left button's chevron points left, the right button's points right. Left = forward, right = back. **[CONFIRMED]** |
| Loading / disabled | At first/last page the corresponding button is disabled (visible, 38 % opacity) |
| Accessibility | "الصفحة التالية" / "الصفحة السابقة" (required even when captions are visible); indicator "الصفحة {n} من {m}" |

### 10.12 KSLockedStoryOverlay
| | |
|---|---|
| Purpose | Child-facing lock for premium stories when not entitled (replaces the earlier `LockedStoryPage`). |
| Inputs | `titleAr`, `illustrationAsset` (lock/lantern) |
| Outputs | `onParentTap` (→ gate with returnTo SubscriptionPage), `onClose` (back to library) |
| Dimensions | Full-screen `scrim`; centred cream card `radius.lg`, padding 24, max width 480; illustration 160 |
| Colours | Card `backgroundCream`; lock badge `accentGold`; button `primary` |
| Typography | Title `headlineMedium`; body `bodyLarge`: "هذه القصة من المكتبة المميزة — اطلب من أحد الوالدين" |
| RTL | Inherits |
| Loading / disabled | None |
| Accessibility | Modal semantics; focus moves to the card; **no prices, product names, or store branding** (G-09); close control labelled "رجوع" |

### 10.13 KSParentGate
| | |
|---|---|
| Purpose | Arabic-words arithmetic challenge (G-01…G-08). |
| Inputs | `challenge: {promptAr, answer}` (from `generateGateChallenge`), `attemptsLeft: int`, `cooldownSeconds: int` |
| Outputs | `onSuccess`, `onCancel`, `onNewChallenge` |
| Dimensions | Adult layout: card max width 480, prompt area, numeric field 56 high, buttons 56 (adult primary) |
| Colours | `parentBackground` page, `backgroundCream` card, `primary` button, `errorText` for wrong-answer message |
| Typography | Heading "للأهل فقط" `displaySmall`; prompt `titleLarge` (words, not digits); field `bodyMedium` 18 px |
| RTL | Field text `start`; numeric keyboard |
| Loading / disabled | Cooldown: field and confirm disabled with countdown text "حاول بعد ٣٠ ثانية" (the only countdown allowed, and it is adult-facing) |
| Accessibility | Prompt read by screen reader in Arabic; field labelled "الإجابة"; errors announced |

### 10.14 KSSubscriptionPlanCard
| | |
|---|---|
| Purpose | One selectable plan (monthly or annual) using store-returned strings. |
| Inputs | `planId: enum {monthly, annual}`, `titleAr: String` (store title or app label), `priceString: String` (store-localised), `periodAr: String` (derived from store period), `perMonthEquivalent: String?` (annual only, computed from store price amounts), `showBestValue: bool` (true **only** when the computed annual discount vs. 12 × monthly > 0), `isSelected`, `isEnabled` |
| Outputs | `onSelected(planId)` |
| Dimensions | Min height 140, full width, `radius.card`, padding 20; radio indicator 24 at the start |
| Colours | `backgroundCream` card, 1 px `outline`; selected: 3 px `primary` border; badge `accentGold` pill "الأفضل قيمة" with `textDarkBlue` text |
| Typography | Title `titleLarge`; price `displaySmall` (Baloo 700 28) with bidi isolate; period `bodyMedium`; equivalent `bodySmall` |
| RTL | Radio at right, badge at top-left corner (trailing) |
| Loading / disabled | Loading: skeleton (no prices ever hard-coded); disabled while purchase in flight |
| Accessibility | "خطة {title}، {price} {period}، {الأفضل قيمة}، محدد" |

### 10.15 KSEmptyState
| | |
|---|---|
| Purpose | Friendly empty content (no favourites, no stories in category). |
| Inputs | `illustrationAsset`, `titleAr`, `bodyAr?`, `actionLabel?`, `variant: enum {child, adult}` |
| Outputs | `onAction?` |
| Dimensions | Illustration 160 (child) / 120 (adult); max width 480; centred |
| Colours | Cream card in child mode; plain on `parentBackground` in adult mode |
| Typography | Title `headlineMedium`; body `bodyLarge`/`bodyMedium` |
| RTL | Centred |
| Loading / disabled | — |
| Accessibility | Whole block as one semantic label; action is a button |

### 10.16 KSErrorState
| | |
|---|---|
| Purpose | Recoverable errors with retry. |
| Inputs | `titleAr`, `bodyAr?`, `retryLabel = "حاول مجددًا"`, `variant`, `errorCode: String?` (parent mode only, small) |
| Outputs | `onRetry`, `onSecondary?` |
| Dimensions | As empty state |
| Colours | Icon `error` (non-text), body text `textPrimary`; error code `errorText` `bodySmall` (adult only) |
| Typography | As empty state |
| RTL | Centred |
| Loading / disabled | Retry shows loading spinner |
| Accessibility | Announced as alert; retry button labelled |

### 10.17 KSLoadingState
| | |
|---|---|
| Purpose | Page-level loading and skeletons. |
| Inputs | `variant: enum {spinner, skeletonGrid, skeletonReader, skeletonList}`, `messageAr?` |
| Outputs | — |
| Dimensions | Spinner 48 `primary`; skeleton blocks in `surfaceSand` with shimmer (disabled under reduce-motion) |
| Colours | As above |
| Typography | Message `bodyLarge` |
| RTL | Skeleton blocks `start`-aligned |
| Loading / disabled | — |
| Accessibility | `Semantics(label: messageAr ?? "جارٍ التحميل", liveRegion: true)`; excluded children |

---

## 11. Accessibility and screen readers

| # | Requirement |
|---|---|
| A-01 | Every interactive element has an Arabic semantic label; icon-only child controls also show a visible caption. |
| A-02 | Focus/traversal order follows RTL visual order (right → left, top → bottom); FlutterFlow's default traversal must be checked on `StoryReaderPage` where the *left* button is "next". |
| A-03 | Images: illustrations use `imageAlt` from content; decorative backgrounds are excluded from semantics. |
| A-04 | Contrast per §3.4; state never by colour alone (lock = icon + label; selected = border + check). |
| A-05 | Text scaling: parent mode supports 130 %+ without clipping; child mode clamps to 130 % and keeps single-primary-action layouts intact. |
| A-06 | Reduce motion honoured (§8). |
| A-07 | Live regions: narration state changes, purchase progress, and gate errors are announced. |
| A-08 | Touch targets per §9. |
| A-09 | TalkBack and VoiceOver walkthrough of every page is part of the definition of done (AC-37…AC-40, AC-63). |
| A-10 | Audio is never the only carrier of information; every audio state has visible text/icon. |

---

## 12. Child mode vs parent mode

| Aspect | Child mode | Parent mode |
|---|---|---|
| Background | Illustrated night sky / soft day art | `parentBackground` flat, optional 5 % cloud motif |
| Surfaces | Cream cards with `shadow.soft2` over art | Cream cards with 1 px `outline` |
| Headings | Baloo `displayLarge`/`headlineMedium` | Baloo `displaySmall` only for page titles; sections in Tajawal `titleSmall` |
| Actions | One primary per screen; 64 px buttons; 64 px icon buttons | 56 px buttons; 48 px icon buttons; clear labelled back/close ("رجوع", "إغلاق") |
| Decoration | Stars, clouds, characters | None beyond a small illustration in empty states |
| Text minimum | 16 px | 14 px |
| Purchasing | Never visible; lock badge + lock overlay only | Plain language, store prices, recurring-billing explanation, no countdowns, no fake discounts, no "limited offer" language, badges only for real discounts |
| Navigation | Big cards, swipes, home button | Standard app bar with title and back |
| Entry | Default | Only via `KSParentGate` (except onboarding right after sign-up) |

---

## 13. Arabic copy glossary (UI strings — content team may refine wording, not meaning)

| Key | Arabic | Where |
|---|---|---|
| `app.parentEntry` | للأهل | Child screens (small trailing button) |
| `child.whoReads` | من يقرأ اليوم؟ | ChildSelectorPage |
| `child.startStory` | ابدأ الحكاية | ChildProfileSetupPage CTA, StoryDetailsPage CTA **[CONFIRMED]** |
| `child.continueFrom` | تابع من الصفحة {n} | StoryDetailsPage |
| `mode.read` | اقرأ بنفسي | Mode selector **[CONFIRMED]** |
| `mode.listen` | استمع إلى القصة | Mode selector **[CONFIRMED]** |
| `reader.next` / `reader.previous` | التالي / السابق | KSPageNavigation captions |
| `reader.pageOf` | الصفحة {n} من {m} | Indicator |
| `reader.play` / `pause` / `stop` / `repeat` | تشغيل / إيقاف مؤقت / إيقاف / إعادة الصفحة | KSAudioControls |
| `reader.speed` | السرعة | Speed chip label |
| `reader.audioUnavailable` | الصوت غير متاح الآن | Audio state |
| `reader.ttsUnavailable` | لا يوجد صوت عربي على هذا الجهاز | TTS state (child-facing line) |
| `reader.ttsUnavailableParent` | للأهل: يمكن تثبيت صوت عربي من إعدادات الجهاز | TTS state (adult hint, gated action) |
| `reader.loading` | جارٍ تحضير القصة… | Loading |
| `reader.finished` | انتهت القصة! | Completion |
| `reader.readAgain` / `anotherStory` | اقرأ مرة أخرى / قصة أخرى | Completion |
| `home.continue` / `featured` / `free` / `favorites` / `categories` | تابع القراءة / قصص مميزة / قصص مجانية / المفضلة / الفئات | HomePage shelves |
| `lock.badge` | مميزة | KSStoryCard badge |
| `lock.body` | هذه القصة من المكتبة المميزة — اطلب من أحد الوالدين | KSLockedStoryOverlay |
| `gate.title` | للأهل فقط | KSParentGate |
| `gate.answer` | الإجابة | Field label |
| `gate.wrong` | الإجابة غير صحيحة، حاول مرة أخرى | Error |
| `sub.title` | المكتبة المميزة | SubscriptionPage |
| `sub.monthly` / `annual` | اشتراك شهري / اشتراك سنوي | Plan titles (may be replaced by store titles) |
| `sub.bestValue` | الأفضل قيمة | Badge (real discount only) |
| `sub.subscribe` | اشترك الآن | CTA |
| `sub.restore` | استعادة المشتريات | Secondary |
| `sub.manage` | إدارة الاشتراك | Secondary (external, gated) |
| `sub.recurringNotice` | يتجدد الاشتراك تلقائيًا ويُحصَّل عبر حسابك في المتجر. يمكنك الإلغاء في أي وقت من إعدادات الاشتراكات في المتجر. | Explanation **[LEGAL wording]** |
| `sub.success` | تم تفعيل الاشتراك | Success |
| `sub.cancelled` | لم تكتمل عملية الشراء | User cancelled purchase sheet |
| `sub.error` | تعذّر إتمام العملية، حاول مجددًا | Error |
| `legal.privacy` / `terms` | سياسة الخصوصية / شروط الاستخدام | Links |
| `external.confirm` | سيتم فتح المتصفح | Confirmation dialog |
| `profile.nickname` | اسم الدلع | Field |
| `profile.nicknameHint` | اسم الدلع فقط، لا داعي للاسم الكامل | Helper |
| `profile.ageGroup` | الفئة العمرية | Section |
| `profile.avatar` | اختر صورة | Section |
| `ageGroup.1-2` / `3-4` / `5-6` | ١–٢ سنة / ٣–٤ سنوات / ٥–٦ سنوات | From `appConfig.ageGroups` |
| `parent.dashboard` | لوحة الأهل | ParentDashboardPage |
| `parent.children` / `addChild` | الأطفال / إضافة طفل | Dashboard |
| `parent.settings` | الإعدادات | |
| `parent.signOut` / `deleteAccount` | تسجيل الخروج / حذف الحساب | |
| `common.back` / `close` / `retry` / `cancel` | رجوع / إغلاق / حاول مجددًا / إلغاء | |

---

## 14. Asset inventory and missing brand assets

| Asset | Status | Spec |
|---|---|---|
| Arabic app name / wordmark | **[ASSET NEEDED — D-29]** | Owner decision; Latin "Kids Stories" wordmark also needs a designed lockup |
| App icon | **[ASSET NEEDED]** | 1024 × 1024 master; adaptive icon layers (Android); no text in icon; night-sky + book/lantern motif |
| Splash logo | **[ASSET NEEDED]** | Vector or 1024 PNG on `storyBlueDark` |
| Backgrounds (§2.4) | **[ASSET NEEDED]** | Phone/tablet night sky (+ optional day) with low-detail bottom zone |
| Avatar set | **[ASSET NEEDED]** | 12 gentle-animal avatars, 512 × 512 PNG, circle-safe, with Arabic descriptions |
| Category icons | **[ASSET NEEDED]** | ≈ 8 illustrated icons, 256 × 256, matching `categories.iconId` |
| Reading-mode icons | **[ASSET NEEDED]** | Book (read) and headphones/ear (listen), 64 px |
| State illustrations | **[ASSET NEEDED]** | Empty favourites, empty category, error, offline, locked (lantern + lock), TTS unavailable, story complete (stars) — 160 px versions |
| Celebration effect | **[ASSET NEEDED]** | Star burst (Lottie or sprite) ≤ 900 ms, reduce-motion fallback static |
| Sound effects | **[ASSET NEEDED — ASSUMPTION `soundEffects` setting]** | Soft tap, page turn, completion chime (≤ 1 s, −16 LUFS) |
| Fonts | **[VERIFY licence]** | Baloo Bhaijaan 2 (600/700/800), Tajawal (400/500/700/800) bundled |
| Store screenshots/marketing | **[ASSET NEEDED]** | Arabic captions, phone + tablet sizes, Kids-category compliant |
| Licence log | **[ASSET NEEDED]** | Per-asset source, licence, and scope |

---

## 15. Decisions recorded and contradictions with earlier documents

| ID | Decision / reconciliation | Status |
|---|---|---|
| D-06 | Fonts: Baloo Bhaijaan 2 (display) + Tajawal (body/story/forms) | **Resolved [CONFIRMED]** — supersedes the candidate list in PRODUCT_SPEC R-03; diacritics test remains a Phase 1 gate |
| D-05 | Digits | Still open; token default `arabic-indic` in child mode |
| D-08 | Orientation/tablet | Phones portrait; tablets portrait supported; tablet landscape still open |
| D-29 | Arabic app name / wordmark | **New — open** |
| R-04 | Story text size | Reconciled: default 26 (28 / 30 for younger groups), minimum 22 (was "24–28 [ASSUMPTION]") |
| R-07 / AC-38 | Touch targets | Reconciled: child ≥ 56, adult ≥ 48, primary child buttons 64 (60 min) — earlier "≥ 48 everywhere; primary child ≥ 64" |
| Page naming | Earlier docs use `ProfilePickerPage`, `ReaderPage`, `PaywallPage`, `LockedStoryPage`, `ParentalGatePage`, `ParentAreaPage`, `CreateChildPage`, … | Superseded by the names in [FLUTTERFLOW_SCREEN_SPEC.md §1.3](FLUTTERFLOW_SCREEN_SPEC.md); a rename pass over the v0.2 docs is pending |
| Lock screen | `LockedStoryPage` (page) | Now `KSLockedStoryOverlay` on `StoryDetailsPage`; behaviour unchanged (no prices, only "للأهل") |
| Paywall | `PaywallPage` + `SubscriptionPage` | Merged into one `SubscriptionPage` with subscribed/not-subscribed states |
| StoryDetailsPage actions | Two mode buttons + start | Now one `KSReadingModeSelector` + one primary CTA "ابدأ الحكاية" / "تابع" (one primary action rule) |
| Parent area pages | `ParentAreaPage`, `ChildrenListPage`, `AccountPage`, `DeleteAccountPage` | Consolidated into `ParentDashboardPage` + `SettingsPage` (delete-account is a confirmation flow inside Settings) |
| Product name | Earlier docs use a generic working title | "Kids Stories" **[CONFIRMED]**; earlier titles to be updated in the rename pass |
