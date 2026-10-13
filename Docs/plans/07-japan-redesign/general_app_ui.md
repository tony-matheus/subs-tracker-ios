# General App UI — modern Japan foundation

## Goal
- **What the user asked for:** replace the metal-grey and green/purple look with a "modern Japan" one:
  - straight lines with subtle curves (the torii gate)
  - a Japanese palette: dark mode is red + black + gold, light mode is red + white + gold
  - Fragment Mono as the app font
  - Liquid Glass kept
- **This doc builds the shared base the feature docs use:**
  - the palette tokens, and how each token applies to every element type
  - the Fragment Mono migration
  - radius tokens and torii motifs
  - flat paper backgrounds and paper cards
  - the Liquid Glass rules and the `AppButton` mapping
  - the shared motif components
  - ripple removal everywhere except onboarding
  - the widget base
  - the hardcoded-colour sweep
- **Implement it first.** No feature doc compiles against the new tokens until this lands.

**Depends on:** nothing. Every other doc in `Docs/plans/07-japan-redesign/` depends on this one.

**References:**
- Palette sources: [Traditional colors of Japan (Wikipedia)](https://en.wikipedia.org/wiki/Traditional_colors_of_Japan) and [和色大辞典 colordic](https://www.colordic.org/w)
- Restraint (ma): [Japan House LA on ma](https://japanhousela.com/articles/a-perspective-on-the-japanese-concept-of-ma)
- Budget wording: [JGJE 赤字](https://www.tkgje.jp/entries/04500/04712_akaji.html)
- Accessibility and colour-blindness: [WCAG 1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color) and [Machado CVD simulation](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html)
- Liquid Glass: [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color), [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) and [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- Fragment Mono: [repo](https://github.com/weiweihuanghuang/fragment-mono), [google/fonts METADATA.pb](https://raw.githubusercontent.com/google/fonts/main/ofl/fragmentmono/METADATA.pb) and [Fontsource](https://fontsource.org/fonts/fragment-mono)
- Fonts in SwiftUI: [Applying custom fonts to text](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text) and the [iOS font list gist](https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9)
- Torii parts: [JAANUS kasagi](https://aisf.or.jp/~jaanus/deta/k/kasagi.htm) and [JAANUS myōjin torii](https://projects.mcah.columbia.edu/jaanus/node/2276)
- Every option and open point is collected in `research_results_and_future_points.md`.

**Doc set (pointers, not duplicated here):**

| Doc | Owns |
|---|---|
| `general_app_ui.md` (this) | tokens, font, shapes, glass, shared motif components, ripple removal, widget base, hardcode sweep |
| `calendar.md` | `KoyomiHeader` (mounted in `HomeView`), weekday band, day cells, `EnsoShape`/`EnsoMark` spec + draw-on, `JapaneseCalendar` (holidays, 節気, weekday kanji), widget today ensō |
| `forms.md` | add/edit forms, `FormRow`, logo sheet, form CTAs, `ExpenseSummarySheet` |
| `charts.md` | Stats, coins, widget charts + widget budget colours, budget scale options, `BudgetColor.swift`, `HankoStamp` spec |
| `price_display.md` | `TextAnimatedView`/`TotalView` brush price, `InkReveal`, `MoneyFormatter` routing |
| `list_view.md` | notebook rows (Home list, Search, `ExpensesInDay` rows + header + sum line), `CategoryMark`, `LogoCircle(glass:)` |
| `home_screen_ux.md` | Home toolbar/layout, year grid, filter sheet, deletes `HomeActionButton` |
| `research_results_and_future_points.md` | index, sources, every open point |

## Current state
**Tokens (`LinguicaSubTracker/Core/Utils/AppTheme.swift`)**
- `ThemeMode` (`:4-44`) decodes leniently at `:15-18`.
- `Color.appAccent` is #1DB954 (`:51`) and `appAccentDeep` is #0B5F2D (`:57`). Both are static, not adaptive.
- `appSurface` (`:60-64`) is #1B1C1F dark / #E5E8EC light.
- `appBackgroundTop` (`:66-70`) is #3B3E43 / #F4F5F7, and `appBackgroundBottom` (`:72-76`) is #141518 / #C4C9CF.
- `AppBackground` (`:91-104`) draws a topLeading→bottomTrailing `LinearGradient`. `.appBackground()` (`:106-110`) has **31 call sites**.
- Call-site counts:
  - `appAccent`: 22 (`AppButton.swift` 8, `SatoruWidgets/WidgetViews.swift` 6)
  - `appAccentDeep`: 1 (`BrandLogo.swift:94`)
  - `appSurface`: 9
  - `appBackgroundTop/Bottom`: `AppTheme.swift:97` and `SatoruWidgets/WidgetViews.swift:617`
- Asset colors:
  - `LinguicaSubTracker/Resources/Assets.xcassets/AppPurple.colorset` (#9D00FF) generates `Color.appPurple`. It is used for the voice UI:
    - `Core/Lab/SpeechCapture/Views/SpeechActionButton.swift:25`
    - `SpeechPillButton.swift:41,63,65`
    - `Features/Expense/Views/ExpenseTemplateSheet.swift:210,430`
    - `Features/VoiceAdd/Views/VoiceCaptureOverlay.swift:225`
    - `Features/Onboarding/Views/Components/Heroes/OnboardingVoiceHero.swift:16`
    - as a string at `Features/VoiceAdd/Views/QuickVoiceAddView.swift:50`
  - `AccentColor.colorset` is **empty**, so every system control is system blue.
- `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` (`LinguicaSubTracker.xcodeproj/project.pbxproj:441,505`). Any colorset generates a `Color.<name>` symbol.

**Typography**
- `LinguicaSubTracker/Core/Utils/Theme.swift`:
  - `Theme.FontName` (`:4-9`) holds 4 `SFCompactRounded-*` names, and `Theme.font(size:weight:)` (`:11-13`) wraps `.custom(_:size:)`.
  - `AppButtonStyle` (`:16-23`) and `LiquidGlassButtonStyle`/`.liquidGlass` (`:25-35`) have **no callers**.
  - `AppTextModifier` (`:37-45`) and `IconModifier` (`:47-57`, `.system` for SF Symbols).
- `LinguicaSubTracker/Core/Utils/Typography.swift:3-96`: 13 styles from 34 to 12pt, most of them semibold. Display/headline use tracking −0.8. Helpers `.size()` `:80` and `.weight()` `:88`.
- Usage: 208 `.typography(` calls, and **34** of them chain `.weight(…)`: 32 literal `.weight(.semibold|.bold)` (for example `HomeExpenseRow.swift:32,42` and `SearchView.swift:141`) plus 2 conditional `.weight(isSelected ? .semibold : .regular)` (`ExpenseSummarySheet.swift:363`, `StatsLegendList.swift:37`).
- `Theme.font(` call sites:
  - `AppButton.swift:59,64,69`
  - `Theme.swift:19,42`
  - `LinguicaSubTracker/App/LinguicaSubTrackerApp.swift:50,75` (the root `\.font` environment)
  - `Features/Home/Views/Components/TextAnimatedView.swift:128`
- `TextAnimatedView.swift:75-76` measures with `UIFont(name: Self.style.weight.rawValue)` and falls back to the system font.
- Fonts on disk: `LinguicaSubTracker/Info.plist:16-27` lists 9 `SF-Compact-Rounded-*.otf` in `UIAppFonts`, and the files live in `LinguicaSubTracker/Resources/Fonts/`. `SatoruWidgets/Info.plist` has no `UIAppFonts`.
- The widget target shares files through the exception set at `project.pbxproj:78-104`. That set includes `AppTheme.swift`, `BudgetColor.swift`, `Color.swift`, `LogoCircle.swift`, `CalendarStyle.swift`, `AppSettings.swift`, `MoneyFormatter.swift` and `Resources/Assets.xcassets`. It does **not** include `Theme.swift`, `Typography.swift` or the fonts.
- `SatoruWidgets/WidgetViews.swift:8-10` `rounded()` returns `.system(design: .rounded)` and is used for every widget string.

**Shapes and containers**
- `GlassSection` (`Core/UI/Containers/GlassSection.swift`):
  - `RoundedRectangle(cornerRadius: 24)` (`:6,14`) on `.ultraThinMaterial` (`:17`)
  - API `contentInsets(_:)` / `cornerRadius(_:)` / `clipsContent(_:)` (`:29-46`)
  - 33 references in 14 files
- `LabeledSection.swift:20-29` puts a `labelLarge` title outside a `GlassSection`. `SettingsView.swift:167-178` duplicates that title styling in a private `section(_:content:)`.
- Capsules:
  - `AppButton.swift:175` (outline) and `:280-283` (`GlassIfNeeded` glass in `Capsule()`)
  - `CustomSegmentedPicker.swift:39-48`
  - `AppearanceSelector.swift:13-27`
  - `MenuPicker.swift:57`
  - `SortChip.swift:39`
  - `SyncToast.swift:24-25`
- There are no radius tokens. `cornerRadius` appears 58 times, with values 24, 20, 14, 12 and smaller.

**Glass and materials**
- `.glassEffect(` appears 13 times, `.buttonStyle(.glassProminent)` 6 times, and `.ultraThinMaterial` 16 times.
- Content currently on glass:
  - `LogoCircle.swift:19`
  - `StatsCard.swift:23`
  - `SpendDial.swift:61`
  - `GlassSection`
- `AppButton` `.neutral .solid`:
  - tints the glass `.white` (`AppButton.swift:200`) with a `.black` label (`:264`), which disappears on a light background
  - the comment at `:27` says "white in dark mode, black in light mode", but the code ignores the color scheme

**Effects (ripple)**
- `Core/UI/Effects/RippleEffect.swift` + `Ripple.metal`:
  - `rippleEffect` `:303`, `rippleOnTap` `:314`, `rippleOnDrag` `:330`
  - `AnyTransition.liquidRipple` `:282-297`
  - Metal `Ripple` `:13-40` and `RippleWake` `:50-91`
- Call sites:
  - `Features/Home/Views/Components/TotalView.swift:110` (`.rippleOnTap()` on the total)
  - `Features/Home/Views/Components/Calendar/Month/MonthView.swift:31-32`, fed by `DayCell.onRipple` (`DayCell.swift:18,82,116,121-130`)
  - `.liquidRipple` in `HomeActionButton.swift:25,39`, `SpeechPillButton.swift:48` and `OnboardingView.swift:29-33`
  - onboarding heroes: `rippleCard()` + `rippleOnTap()`
- `layerEffect` renders materials **black**. That is why `RippleCard.swift:3-15` and `SyncToast.swift:22-24` use opaque `appSurface`.

**Widgets**
- `WidgetBackdrop` (`WidgetViews.swift:614-619`) draws the `appBackgroundTop/Bottom` gradient.
- Today markers use `Color.appAccent` at `:396`, `:406`, `:443`, `:490`, `:507` and `:546`.

**Budget colour:** `BudgetColor.swift:7-17` maps green → yellow → orange → #FF5900 → red, and `glowOpacity` at `:19-24` is dead (its only use is hardcoded to 0).

## Target design

### 1. Palette tokens (canonical, exact)
Define the tokens in code in `AppTheme.swift` with the existing `Color(UIColor { traits in … })` pattern. **Do not** add colorsets: asset-symbol generation would create a duplicate `Color.<name>` and break the build.

| Token | Dark (lacquer) | Light (washi) | Use |
|---|---|---|---|
| `paper` | #0E0C0B | #F8F4E6 | background, flat, no gradient |
| `paperRaised` | #1C1816 | #FFFFFC | cards; separated by hairline, not tone |
| `ink` / `inkSecondary` | #F4EFE6 / #A8A096 | #1E1A17 / #6B635C | text |
| `rule` / `ruleStrong` | #3A332E / #746B63 | #E2DCCF / #8C8378 | hairlines / visible rules |
| `shu` / `shuPressed` | #E84A33 / #C23B26 | #C1352A / #9E2A1E | brand: torii mark, ensō, primary CTA, Sun/holiday, 赤字 stamp |
| `kin` / `kinText` | #D4A72C / #E6B422 | #C9A13B / #8A6B1F | gold: hairlines, underlines, flecks only; `kinText` for text |
| `beni` | #EE5A62 | #A22041 | destructive (never hue alone) |
| `ai` | #6F93D6 | #1E50A2 | Saturday (open point: keep or go monochrome) |

**Contrast facts that drive the rules:**
- On `paper`, `ink` measures 17.0:1 (dark) and 15.7:1 (light). `inkSecondary` measures 7.6:1 and 5.4:1.
- `shu` passes for text in both modes: 5.07:1 dark and 5.01:1 light.
- `kin` in light mode is 2.2:1, so it is decoration only. Gold text uses `kinText`, which is 4.54:1 on light `paper`.
- **Text on a filled shu or beni shape is `paper` in both modes:**
  - On shu: dark #0E0C0B gives 5.07:1, light #F8F4E6 about 5.0:1.
  - Washi-white on dark shu is only 3.36:1 and fails.
- `paperRaised` vs `paper` is about 1.1:1, so cards **must** have a rule, not just a tone change.
- Under deuteranopia, light `shu` and `kinText` become the same colour (ΔE 0.4). Never encode state with shu vs gold alone. Add shape and a label.

### 2. How every element type uses the tokens

| Element | Light (washi) | Dark (lacquer) | Rule |
|---|---|---|---|
| Screen background | `paper` #F8F4E6 | `paper` #0E0C0B | Flat, via `.appBackground()`. No gradient, glow, metal or texture (washi tile is an open point) |
| Cards, sections (`GlassSection`) | `paperRaised` + 1pt `rule` border, radius 4 | same tokens | No material, no shadow, no tinted fill |
| Primary text | `ink` | `ink` | Prices default to `ink`, never red |
| Secondary text | `inkSecondary` | `inkSecondary` | Hierarchy comes from the token, not from `.opacity()`. Alpha drops below 4.5:1 |
| Disabled | `inkSecondary` + `.opacity(0.5)` | same | Disabled state only |
| Row and grid lines | `rule` at `1 / displayScale` | same | "hairline" |
| Visible rules (headers, nuki dividers) | `ruleStrong` 1pt | same | Two line weights only: hairline and 1pt |
| Kasagi double rule | `ink` 2pt curved + `ink` 1pt straight | same | At most one per screen (torii lintel is black-capped) |
| Hashira section marker | `shu` 3pt × label height | same | A stroke, not a fill |
| Toolbar / nav icons | `ink`, monochrome | same | Never `.gradient` and never shu ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)) |
| Primary CTA | `.buttonStyle(.glassProminent)` filled `shu`, label `paper` | same | **The one filled shu shape on the screen** |
| Secondary actions | untinted glass, label `ink`, icon `ink` or `shu` | same | |
| Selection (segments, rows, chips, swatches) | untinted glass highlight (controls) or 1pt `ink` outline / checkmark in `ink` | same | No tinted fill. Lists may add a 2pt `shu` leading rule |
| Destructive | `beni` glyph (`trash`) + text label + `role: .destructive` + confirmation | same | Never hue alone. Text stays `ink` |
| Status OK / active | `ink` + glyph or word (for example "ACTIVE") | same | `.green` retires |
| Budget 75–99% | `ink` number + `kinText` brush underline + "left" label | same | See §9 |
| Budget ≥100% | `shu` number + `HankoStamp` "赤字" | same | Shape + label ([WCAG 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color)) |
| Category / logo user colours | glyph, 6pt square dot, `LogoCircle` fill, 2pt margin rule | same | User data is never changed and never used as a row, card or page fill |
| Gold | `kin` hairlines, underlines, flecks; `kinText` for text | `kin` / `kinText` | Never a fill over 24pt |
| System controls (Toggle, DatePicker, Stepper, ProgressView, text cursor, `Link`) | `AccentColor.colorset` = `shu` | `shu` | Fixed once in the asset |
| Glass surfaces | untinted `.regular`, text `ink` | same | Tint only the primary CTA |
| Voice recording | mic button fill `shu` (label `paper`) while recording; `ink` glyph on `paperRaised` while idle | same | Replaces `appPurple` |
| Saturday numerals / labels | `ai` | `ai` | calendar.md |
| Scrims / dimming | `Color.black.opacity(…)` | same | Scrims stay black |

**Global rules**
- **70 / 25 / 5:**
  - 70% ground (`paper`/`paperRaised`)
  - 25% ink (text, rules, icons)
  - 5% accent: about 4% shu and 1% or less gold
- **At most one filled shu shape per screen.** That means one `.glassProminent` CTA, *or* a recording mic button, *or* one hanko fill. All other shu is text or a 1–3pt stroke (hashira, ensō, holiday numerals). System controls coloured by `AccentColor` (Toggle on-track, DatePicker selection) are exempt; see Open points.
- **Gold is a fleck, never a field.**
- **No gradients** (`.gradient`, `LinearGradient`, `RadialGradient`) on chrome, text or icons. **No shadows** on cards and toasts.
- **User category and logo colours** (`LogoCustomization`, `AppCategory.colorHex`) are never rewritten.
  - `LogoPalette.swift:4-15` stays unchanged in v1.
  - Swapping the default category palette for new installs is an open point.

**Light vs dark specifics**
- The light-mode ground is old-paper ivory (象牙 #F8F4E6) with gofun-white (#FFFFFC) cards. Gold is decoration only.
- The dark-mode ground is warm rō-iro lacquer (#0E0C0B) with #1C1816 cards. `kinText` (#E6B422) reads as text.
- `HankoStamp`:
  - light: `.blendMode(.multiply)` at 0.9 opacity
  - dark: normal blend at 0.9
- A future washi texture applies to light mode only.

### 3. Migration map (old → new)

| Old | New | How |
|---|---|---|
| `Color.appAccent` (#1DB954) | `Color.shu` | Re-pointed alias first (step 2), renamed at the end (step 19) |
| `Color.appAccentDeep` | `Color.shuPressed` | Same |
| `Color.appSurface` | `Color.paperRaised` | Same |
| `Color.appBackgroundTop/Bottom` | `Color.paper` | **Deleted.** Only `AppBackground` and `WidgetBackdrop` used them |
| `AppBackground` gradient | flat `Color.paper` | Same modifier name, so all 31 call sites follow |
| `AppPurple.colorset` / `Color.appPurple` | `Color.shu` (recording) / `Color.ink` (idle) | Colorset deleted. Per-site mapping in step 4 |
| `AccentColor.colorset` (empty) | `shu` light/dark | JSON in step 3 |
| `BudgetColor` green→red | ink-density scale | charts.md (contract in §9) |
| `.primary` / `.secondary` | `Color.ink` / `Color.inkSecondary` | Root `.foregroundStyle(Color.ink)` warms the defaults. Feature docs replace explicit uses in the views they restyle |
| `.green` "success/active" | `ink` + glyph/word | Per owning doc; Settings and voice here |
| `.red` destructive | `Color.beni` + glyph | Same |

**Convention for all docs:** write tokens as explicit `Color.<token>` (`.foregroundStyle(Color.ink)`, `.fill(Color.shu)`). Do not add `ShapeStyle` shorthands. `.tint(.shu)` works because `tint` takes `Color`.

### 4. Typography: Fragment Mono
**Facts (verified upstream):**
- Fragment Mono is by Wei Huang with URW Design Studio, a monospaced Nimbus Sans, licensed SIL OFL 1.1 ([METADATA.pb](https://raw.githubusercontent.com/google/fonts/main/ofl/fragmentmono/METADATA.pb)).
- It has **only two styles**, `FragmentMono-Regular` and `FragmentMono-Italic`, both weight 400 ([Fontsource](https://fontsource.org/fonts/fragment-mono)).
- Subsets are latin, latin-ext and cyrillic-ext. There are **no CJK glyphs**.
- The `.glyphs` source lists dollar, cent, sterling, yen, euro, won, rupee, lira, ruble, bitcoin, peso and naira. The app prints `$ € R$ £ ¥` (`MoneyFormatter.swift:5-8`), and the runtime test in step 18 checks them.
- Every glyph advances about 0.6 em, so digits are already tabular and `.monospacedDigit()` is a no-op. At 15pt that is about 38 characters across a 375pt screen.
- Download from the [repo](https://github.com/weiweihuanghuang/fragment-mono): `fonts/ttf/FragmentMono-Regular.ttf`, `fonts/ttf/FragmentMono-Italic.ttf` and `OFL.txt`.
- SwiftUI "doesn't synthesize bold or italic styling" ([Apple](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text)). With one weight, every `.weight(.semibold)`, `.bold()` and `.fontWeight()` on Fragment Mono text is a no-op.
- This doc therefore **deletes** the 34 `.typography(x.weight(…))` chains instead of leaving silent no-ops. The only `.fontWeight` (`LogoCircle.swift:88`) is on an SF Symbol and stays.

**Single-weight scale.** Hierarchy comes from size, case, tracking and the colour token. The style names stay the same, so all 208 call sites keep compiling. Sizes shrink 1–2pt because a monospaced font is wider.

| Style | Was | Size | `relativeTo` | Case | Tracking | Opacity · colour |
|---|---|---|---|---|---|---|
| `displayMedium` | 34 semibold −0.8 | 34 | `.largeTitle` | as written | −0.5 | 1.0 · `ink` |
| `displaySmall` | 28 semibold −0.8 | 28 | `.title` | as written | −0.3 | 1.0 · `ink` |
| `headlineLarge` | 24 semibold −0.8 | 24 | `.title` | as written | 0 | 1.0 · `ink` |
| `headlineMedium` | 22 semibold −0.8 | 22 | `.title2` | as written | 0 | 1.0 · `ink` |
| `headlineSmall` | 20 semibold −0.8 | 20 | `.title3` | as written | 0 | 1.0 · `ink` |
| `titleLarge` | 18 bold | 17 | `.headline` | as written | 0 | 1.0 · `ink` |
| `titleMedium` | 16 semibold | 16 | `.callout` | as written | 0 | 1.0 · `ink` |
| `titleSmall` | 14 semibold | 14 | `.subheadline` | as written | +0.2 | 1.0 · `ink` |
| `bodyLarge` | 16 regular | 15 | `.body` | as written | 0 | 1.0 · `ink` |
| `bodyMedium` | 14 regular | 13 | `.footnote` | as written | 0 | 1.0 · `ink` or `inkSecondary` |
| `bodySmall` | 12 regular | 11 | `.caption2` | as written | +0.2 | 1.0 · `inkSecondary` |
| `labelLarge` | 14 semibold +0.25 | 12 | `.caption` | UPPER | +1.2 | 1.0 · `inkSecondary` |
| `labelMedium` | 12 semibold +0.25 | 11 | `.caption2` | UPPER | +1.2 | 1.0 · `inkSecondary` |

- **Tracking:** the two display styles keep a slight negative tracking (−0.5 / −0.3), as implemented in `Typography.swift:10-11`. The plan's "tracking → ~0" is superseded by the code; price_display.md reads `displayMedium.letterSpacing` and so inherits −0.5.
- **"Opacity · colour"** is the default foreground the caller should pass. `AppTextModifier` does **not** apply it, so callers can still colour text (shu holidays, beni destructive).
- **Case:**
  - The label styles apply `.textCase(.uppercase)` inside the modifier. Do not uppercase the source strings.
  - The `smcp` OpenType feature is not used in v1.
- **Bold Text accessibility** (`legibilityWeight == .bold`) cannot thicken Fragment Mono. The modifier switches to SF Mono semibold at the same Dynamic-Type-scaled size (snippet in step 7).
- **Kanji** go in a **separate** `Text`:
  - `.font(.custom(AppFont.kanji, size: 11, relativeTo: .caption2))` with `HiraMinProN-W3`
  - or `AppFont.kanjiBold` with `HiraMinProN-W6`, used for the 赤字 stamp and the weekday band
  - Use a `UIFontDescriptor` cascade list only when Latin and kanji share one string ([sarunw](https://sarunw.com/posts/how-to-use-different-fonts-for-different-languages-in-ios-application/)). Without a cascade, CoreText falls back to a sans, not a mincho.
- **These stay `.system`:**
  - SF Symbols (`IconModifier`, every `Image(systemName:)` `.font(.system…)`)
  - emoji (`LogoCircle.swift:41`, `LogoSheet.swift:339`, `CurrencyPickerSheet.swift:20` flags)
  - debug/preview text (`WidgetGallery.swift:26`, `SubscriptionTemplate.swift:89` mock preview, `AppButton.swift:323,378` previews)
- **UIKit chrome** does not read the SwiftUI environment font. Navigation titles and `UISegmentedControl` get an appearance proxy (step 8). These stay SF Pro, which is accepted:
  - alerts
  - `Menu` rows
  - context menus
  - swipe-action labels
  - the `.searchable` field
  - `DatePicker` internals

**Stray text fonts (`.font(.system…)` on `Text`, or semantic styles):**

| Site | Owner |
|---|---|
| `LogoCircle.swift:111` initials | this doc |
| `CalendarStyleSheet.swift:116` sample "17" | this doc |
| `SpeechPillButton.swift:45` (Lab) | this doc |
| `SatoruWidgets/WidgetViews.swift:8-10` `rounded()` | this doc |
| `DayCell.swift:87,170,188`, `MonthView.swift:39` | calendar.md |
| `NumKeyPadSheet.swift:232,242,251,257` (`design: .rounded`) | price_display.md |
| `ExpenseSummarySheet.swift:87,89,131,137,156,169,178,186,196,211,223` | forms.md |
| `ExpensesInDay.swift:98,101` (header) | list_view.md (replaced by `NotebookDayHeader`) |
| `ExpensesInDay.swift:161,165,172,198,214,220` (rows) | list_view.md |
| `HomeActionButton.swift:21,35` | home_screen_ux.md (file deleted) |

**Where monospaced width will break** (each owner re-tunes its own):
- `TotalView.swift:15,18`: `totalInset` 24 and `totalSizeRange` 48…92 (price_display.md)
- `DayCell.swift:87`: 12pt numerals in roughly 50pt cells (calendar.md)
- `HomeToolbar.swift:93-94`: month title `headlineSmall` in `.principal` (home_screen_ux.md)
- Rows with a 44pt logo, a name and a price (list_view.md):
  - `HomeExpenseRow.swift:32,42`
  - `ExpenseRow.swift:42,52`
- `CustomSegmentedPicker` segments truncate with `lineLimit(1)` (`:86`), e.g. the "Breakdown" segment at `StatsSheet.swift:99`
- `FormRow.swift:37`: fixed 44pt height; label and value side by side (forms.md)
- Widgets (this doc; check every family):
  - `WidgetViews.swift:158` 24pt spent, `minimumScaleFactor(0.6)`
  - `:500` 10pt day totals
  - `:395` month numerals
- Navigation titles: every screen uses `.navigationBarTitleDisplayMode(.inline)` (e.g. `DataInfoSheet.swift:49`), so the 17pt inline title is what renders. "Popular Subscriptions" (21 characters, `SubscriptionCatalogView.swift:63`) is about 214pt and must fit between the bar buttons.

### 5. Shape language
- **Radius tokens** (`AppRadius` in `AppTheme.swift`, shared with the widget):
  - `grid = 0` for calendar grid, rows and rules
  - `card = 4` for cards, chips, keys and custom glass
  - Nothing else. New code never writes a literal radius.
- **Capsules remain only where the system draws glass:**
  - toolbars and tab bars
  - system nav buttons
  - `.buttonStyle(.glass/.glassProminent)` in toolbars
  - the sheet grabber
- Every custom shape is `RoundedRectangle(cornerRadius: AppRadius.card)` or `.rect(cornerRadius: AppRadius.card)`.
- **Kasagi (笠木) double-rule header:**
  - a 2pt `ink` top rule whose ends lift 3pt (about 0.8% of 390pt, a "barely perceptible" Ise-style curve)
  - a 3pt gap, then a straight 1pt `ink` rule (the shimaki)
  - full content width, at most one per screen
  - placed directly under the nav bar at the top of the scroll content
  - This doc places it on `SettingsView`. calendar.md places it in the Koyomi header. Other screens decide in their own doc.
- **Hashira (柱):** a `shu` vertical rule, 3pt wide, as tall as the section label (12pt), 6pt before the label. It is the section marker for `LabeledSection` and Settings sections.
- **Nuki (貫) overhang:** section-level divider rules (`ruleStrong` 1pt) run 3pt past the content column on both sides. Row hairlines inside cards do not overhang.
- **Corners and depth:** no shadows on cards or toasts. `paper` vs `paperRaised` plus a rule carry depth, like paper on paper.

```swift
// Core/UI/Motifs/Torii.swift (new)
struct Kasagi: Shape {              // stroke it; ends sit `lift` above the flat middle
    var lift: CGFloat = 3
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + lift),
                       control: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + lift))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.maxX - r.width * 0.2, y: r.minY + lift))
        return p
    }
}

struct KasagiHeader: View {         // 2pt kasagi, 3pt gap, 1pt shimaki
    var body: some View {
        VStack(spacing: 4) {        // 3pt visible gap under the 2pt stroke's centre
            Kasagi().stroke(Color.ink, lineWidth: 2).frame(height: 3)
            Rectangle().fill(Color.ink).frame(height: 1)
        }
        .padding(.top, 1)
        .accessibilityHidden(true)
    }
}
```

**ASCII mock: Settings after this doc (light; dark values in brackets)**
```
┌───────────────────────────────────────────────┐ paper #F8F4E6 [#0E0C0B], flat
│                  Settings                 (✕) │ system glass bar (capsules stay); inline title Fragment Mono 17, ink; xmark ink
│  ╲_________________________________________╱  │ Kasagi 2pt ink, ends lifted 3pt (exaggerated here)
│  ───────────────────────────────────────────  │ shimaki 1pt ink, 3pt below
│                                               │
│  ▌BUDGET                                      │ Hashira 3×12 shu + labelLarge UPPER +1.2, inkSecondary
│  ┌─────────────────────────────────────────┐  │ paperRaised #FFFFFC [#1C1816], 1pt rule #E2DCCF [#3A332E], r=4
│  │ Monthly budget                $1,200.00 │  │ amounts ink, never green/red
│  └─────────────────────────────────────────┘  │
│  ▌APPEARANCE                                  │
│  ┌─────────────────────────────────────────┐  │
│  │ ┌───────────┐                           │  │ CustomSegmentedPicker: paperRaised track, r=4
│  │ │  System   │   Light        Dark       │  │ selected = untinted glass rect r=4, ink label
│  │ └───────────┘                           │  │
│  │ ─────────────────────────────────────── │  │ Rule hairline (1/displayScale, rule)
│  │ ◫ Calendar Style             Koyomi  ›  │  │ SF Symbol ink, text ink, detail inkSecondary
│  └─────────────────────────────────────────┘  │
│  ▌DANGER ZONE                                 │
│  ┌─────────────────────────────────────────┐  │
│  │ [🗑 Delete all data]                    │  │ AppButton .destructive .glassy: beni glyph, ink text
│  └─────────────────────────────────────────┘  │
│            Made with ♥ by @tony_linguica      │ heart static (no bounce), shu glyph
└───────────────────────────────────────────────┘
```

### 6. Liquid Glass rules
- **Glass goes on controls and navigation only:**
  - toolbars, sheets and floating buttons
  - pickers, menus and segmented controls
  - Content is opaque paper: cards, rows, calendar cells, list logos, stats cards ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)).
- **Untinted `.regular` by default.** Apple says to "refrain from adding color throughout Liquid Glass solely to evoke your brand". The only tinted glass is the primary CTA:
  - `.buttonStyle(.glassProminent)` (shu via `AccentColor`)
  - or `AppButton(style: .primary, appearance: .solid)`
- **Custom glass shape:** `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))`. System bars stay capsules.
- **Text on glass is `ink`.** Test both Clear and Tinted glass (iOS 26.1 user setting; [Six Colors](https://sixcolors.com/post/2025/11/soaping-up-liquid-glass-less-transparency-more-contrast/)).
- **Never put a `layerEffect` shader on or over glass or a material.** It renders black.
- On flat `paper`, glass has little to refract and reads as a frosted chip. That is expected. Let lists scroll under the bars.
- **Destructive toolbar buttons** use `.buttonStyle(.glass)` with a `beni` trash glyph, never `.glassProminent.tint(.red)`. That keeps the single filled-shu rule and the "never hue alone" rule.

**`AppButton` mapping** (`Core/UI/Buttons/AppButton.swift`). Glass shape is `.rect(cornerRadius: 4)` everywhere.

| Appearance \ style | `.primary` / `.secondary` | `.neutral` | `.destructive` |
|---|---|---|---|
| `.glassy` | untinted glass; icon `shu`; text `ink` | untinted; icon + text `ink` | untinted; icon `beni`; text `ink` |
| `.solid` | glass tint `shu`; icon + text `paper` | glass tint `ink`; icon + text `paper` | glass tint `beni`; icon + text `paper` |
| `.outline` | 1pt `shu` border r=4 (+ glass if `glassOnOutline`); icon `shu`; text `ink` | 1pt `ruleStrong`; `ink` | 1pt `beni`; icon `beni`; text `ink` |
| `.ghost` | no background; icon `shu`; text `ink` | `ink` | icon `beni`; text `ink` |

- **The `.neutral .solid` "white-glass CTA" problem.**
  - Today it is `.white` glass with a `.black` label. On washi (#F8F4E6) the white tint has nothing to contrast with, so the button reads as bare text.
  - New behaviour is an `ink` tint with a `paper` label: a sumi chip in light mode and a washi chip in dark mode. That is what the comment at `:27` intended.
  - Call sites:
    - `NumKeyPadSheet.swift:67-70`
    - `BudgetDetailsSheet.swift:95-99`
    - `ExpenseFormView.swift:376-380`
    - `ExpenseSummarySheet.swift:306-309`
    - `SimplifiedAddExpenseView.swift:133-137`
  - forms.md may move its own sites off `.neutral .solid`. The mapping lives here.

**Glass and material sites by owner**
- **This doc:**
  - `GlassSection.swift:17` becomes a paper card.
  - `AppButton.swift:280-283` becomes a rect.
  - `CustomSegmentedPicker.swift:41,48`, `AppearanceSelector.swift:15,27`, `MenuPicker.swift:57`: rect glass highlight, `paperRaised` track.
  - `SortChip.swift:39` becomes rect glass.
  - `BudgetEditor.swift:66` becomes untinted rect glass with a `beni` glyph and an `ink` label.
  - The bottom add-bars at `CategoriesSheet.swift:39`, `ListsSheet.swift:29` and `PaymentMethodsSheet.swift:27` get a `Color.paper` background with a top `Rule()`.
  - Delete the dead code: `PrimaryButton.swift` and `Theme.swift:25-35`.
- **list_view.md:** `LogoCircle.swift:19` (`glass:` parameter) and `SearchView.swift:331` (bulk bar).
- **charts.md:** `StatsCard.swift:23` and `SpendDial.swift:61`.
- **forms.md:** `ExpenseFormView.swift:57,103,369-371`, `ExpenseSummarySheet.swift:40`, `LogoHeaderSection.swift:64`, `ExpenseTemplateSheet.swift:81-82,286`, `BatchAddView.swift:118` and `SimplifiedAddExpenseView.swift:230-236`.
- **Keep:** `VoiceCaptureOverlay.swift:16`, a full-screen overlay at navigation level.
- **Onboarding:** later.

### 7. Shared motif components (`Core/UI/Motifs/`, new folder)
Each component is created by the doc that owns its detailed spec. The API below is the contract every doc codes against. The app target picks up new files automatically (synchronized root group). A file joins the widget only if it is added to the exception set at `project.pbxproj:78-104`.

| Component | File | API (contract) | Detailed spec / creator |
|---|---|---|---|
| `Kasagi`, `KasagiHeader` | `Core/UI/Motifs/Torii.swift` (new) | `Kasagi(lift: 3)` is a `Shape`; `KasagiHeader()` is a full-width view | **this doc** (§5) |
| `Hashira`, `SectionLabel` | `Torii.swift` (new) | `Hashira(height: 12)`; `SectionLabel(_ title: String, color: Color = .inkSecondary)` | **this doc** (step 11) |
| `Rule` | `Torii.swift` (new) | `Rule(color: Color = .rule, thickness: CGFloat? = nil /* nil = 1/displayScale */, overhang: CGFloat = 0)`, horizontal | **this doc** (step 11) |
| `EnsoShape` | `Core/UI/Motifs/EnsoShape.swift` (new) | `EnsoShape(seed: UInt64, gap: Double = 40.0/360, maxWidth: Double = 0.0875)`: a filled `Shape` in `shu`, a 320° sweep with taper; `maxWidth` × the box's shorter side = wMax (3.5pt at 40pt). Draw-on is a trimmed-circle mask (`EnsoMark`), 0.55s ease-out, static under Reduce Motion | **calendar.md** (full spec, §6; it wins on any detail). list_view.md, home_screen_ux.md and widgets depend on calendar.md for it. Keep the file free of app-only types so it can join the widget target |
| `HankoStamp` | `Core/UI/Motifs/HankoStamp.swift` (new) | `HankoStamp(text: String = "赤字", accessibilityText: String = "Over budget", size: CGFloat = 28)`: a square, 1.5pt `shu` border, `AppFont.kanjiBold` text in `shu`, rotated −3°, opacity 0.9, `.multiply` in light only. At most one per screen | **charts.md** (price_display.md consumes it). App-only |
| `InkReveal` | private in its first consumer; moves to `Core/UI/Motifs/InkReveal.swift` (new) when a second consumer appears | `InkReveal(progress: Double, staggered: Bool)`: a `TextRenderer` + `Animatable` per-glyph opacity/blur reveal, about 0.7s. Driven by a `keyframeAnimator` on the displayed value; a `Transition` + `.id(value)` is the fallback. Uniform fade under Reduce Motion | **price_display.md** (step 5; it wins on any detail) |

### 8. Motion
- No ripple, bounce, glow or metal.
- Brush motions use a trimmed-stroke or mask reveal, 0.55–0.7s ease-out.
- State changes use `.smooth(duration: 0.25)` (no overshoot).
- Every animation is gated on `@Environment(\.accessibilityReduceMotion)`. `SyncToast.swift:7` already shows the pattern.
- **Bounce sites:**
  - `AppearanceSelector.swift:56,65,73` (`.symbolEffect(.bounce…)`): this doc
  - `SettingsView.swift:58-62` heart: this doc
  - `TextAnimatedView.swift:133-155`: price_display.md
  - `DayCell.swift:307` `DayClickStyle`: calendar.md
  - spring 0.35/0.82 at `CustomSegmentedPicker.swift:62` and `AppearanceSelector.swift:28`: this doc

### 9. Budget colour (summary; implementation in charts.md)
- **Recommended: an ink-density scale based on Japanese accounting** (黒字 black ink = surplus, 赤字 red ink = deficit; [JGJE](https://www.tkgje.jp/entries/04500/04712_akaji.html)):
  - **Under 75%:** `ink`.
  - **75–99%:** `ink`, plus a `kinText` brush underline and a "left" label.
  - **100% and over:** `shu`, plus a square `HankoStamp` "赤字"/OVER.
  - Shape and label carry the meaning, which meets WCAG 1.4.1. The current green/red ramp already fails deuteranopia (contrast 1.24).
- **Contract other docs rely on** (charts.md implements `BudgetColor.swift`, shared with the widget):
  - `BudgetColor.color(spent:budget:)` keeps its signature for all 6 callers (TotalViewModel, StatsViewModel, HomeViewModel, BudgetEditor, OnboardingBudgetHero, `WidgetViews.swift:110`). It returns `Color.ink` with no budget or below 100%, and `Color.shu` at 100% and over. home_screen_ux.md step 3 later deletes the HomeViewModel caller; charts.md deletes the StatsViewModel caller (`trendBarColor`) and moves BudgetEditor's bar, OnboardingBudgetHero and the widget to its additive `progressColor`.
  - `BudgetColor.Tier { none, calm, near, over }` with `tier(spent:budget:)`, as used by price_display.md.
  - `glowOpacity` (`BudgetColor.swift:19-24`) is deleted.
- **Alternatives:** a gold→vermilion ramp, or keeping semantic green/red. They are documented in charts.md and `research_results_and_future_points.md`. The rendering of the total belongs to price_display.md.

### 10. Widgets (base only; charts are in charts.md)
- **`WidgetBackdrop`** (`WidgetViews.swift:614-619`) becomes a flat `Color.paper`. `containerBackground` (`SatoruWidgetsBundle.swift:56`) is unchanged.
- **Font:**
  - Rename `rounded(_:_:)` (`:8-10`) to `mono(_ size:)`, returning `.custom(AppFont.mono, fixedSize: size)`. `fixedSize` keeps today's non-scaling widget behaviour.
  - Delete the weight argument at every call.
  - Register the font in the widget target (step 5).
- **Today marker:**
  - Numerals at `:396`, `:443` and `:490` become `Color.shu`.
  - The month-grid stroke at `:405-408` becomes `Rectangle().stroke(Color.shu, lineWidth: 1)` with radius 0. Keep `.widgetAccentable()`. This is an interim: calendar.md step 15 swaps it for a static ensō and turns the month-grid today numeral (`:396`) to `ink` inside it. The week rows (`:443`, `:490`) keep the shu numeral.
  - Delete the week fill at `:506-508` (no tinted fills). The shu numeral marks today.
  - The checkmark at `:546` becomes `Color.inkSecondary`.
- `.monospacedDigit()` calls in widgets become no-ops. Leave them.

## Implementation steps
Keep the build green after every step. Build with the command in Verification.

1. **Tokens.** In `LinguicaSubTracker/Core/Utils/AppTheme.swift`, replace the colour block (`:46-89`, including the commented mascot colours) with:
   ```swift
   extension Color {
       /// Light (washi) / dark (lacquer) pair, resolved per trait. Hexes are canonical — see general_app_ui.md §1.
       private static func pair(light: String, dark: String) -> Color {
           let l = UIColor(Color(hex: light)), d = UIColor(Color(hex: dark))
           return Color(UIColor { $0.userInterfaceStyle == .dark ? d : l })
       }
       static let paper        = pair(light: "#F8F4E6", dark: "#0E0C0B")
       static let paperRaised  = pair(light: "#FFFFFC", dark: "#1C1816")
       static let ink          = pair(light: "#1E1A17", dark: "#F4EFE6")
       static let inkSecondary = pair(light: "#6B635C", dark: "#A8A096")
       static let rule         = pair(light: "#E2DCCF", dark: "#3A332E")
       static let ruleStrong   = pair(light: "#8C8378", dark: "#746B63")
       static let shu          = pair(light: "#C1352A", dark: "#E84A33")
       static let shuPressed   = pair(light: "#9E2A1E", dark: "#C23B26")
       static let kin          = pair(light: "#C9A13B", dark: "#D4A72C")
       static let kinText      = pair(light: "#8A6B1F", dark: "#E6B422")
       static let beni         = pair(light: "#A22041", dark: "#EE5A62")
       static let ai           = pair(light: "#1E50A2", dark: "#6F93D6")

       // Legacy names, re-pointed so every call site switches at once. Deleted in step 19.
       static let appAccent     = shu
       static let appAccentDeep = shuPressed
       static let appSurface    = paperRaised
   }

   enum AppFont {               // shared with the widget (Theme.swift is app-only)
       static let mono      = "FragmentMono-Regular"
       static let kanji     = "HiraMinProN-W3"
       static let kanjiBold = "HiraMinProN-W6"
   }

   enum AppRadius {
       static let grid: CGFloat = 0
       static let card: CGFloat = 4
   }
   ```
   `Color(hex:)` lives in `Core/Utils/Extensions/Color.swift:4-20`, which the widget already compiles.

2. **Flat background.**
   - `AppBackground.body` (`AppTheme.swift:93-103`) becomes `content.background(Color.paper.ignoresSafeArea())`. Update the doc comment at `:91`.
   - Step 1 already removed `appBackgroundTop` and `appBackgroundBottom`, so steps 1 and 2 land together; build after this step, not between them.
   - In the same step, change `WidgetBackdrop.body` (`SatoruWidgets/WidgetViews.swift:616-618`) to `Color.paper` and fix its comment at `:614`. The widget referenced the deleted tokens.
   - Root text colour: add `.foregroundStyle(Color.ink)` next to the `\.font` environment at `LinguicaSubTracker/App/LinguicaSubTrackerApp.swift:50` and `:75`.

3. **System accent.** Replace `LinguicaSubTracker/Resources/Assets.xcassets/AccentColor.colorset/Contents.json` with shu. The widget compiles this catalog too, and both targets set `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`.
   ```json
   { "colors" : [
       { "color" : { "color-space" : "srgb", "components" : { "red" : "0.757", "green" : "0.208", "blue" : "0.165", "alpha" : "1.000" } }, "idiom" : "universal" },
       { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
         "color" : { "color-space" : "srgb", "components" : { "red" : "0.910", "green" : "0.290", "blue" : "0.200", "alpha" : "1.000" } }, "idiom" : "universal" } ],
     "info" : { "author" : "xcode", "version" : 1 } }
   ```

4. **Retire purple.**
   - Delete the `AppPurple.colorset` folder (its comment at `AppTheme.swift:53-54` went with step 1). The compiler then flags every `Color.appPurple`. The string lookup is not compile-checked, so grep for `"AppPurple"`.
   - Mapping:
     - **Recording / active → `Color.shu`:**
       - `QuickVoiceAddView.swift:50`
       - `OnboardingVoiceHero.swift:16` (drop `.gradient`)
       - `SpeechPillButton.swift:63` (drop `.gradient`, delete the shadow at `:65`)
       - `SpeechActionButton.swift:25` (ring stroke; delete the glow `.blur(radius: 5)` at `:27`)
       - `ExpenseTemplateSheet.swift:210` (the "Listening…" waveform)
     - **Idle → `Color.ink`:** `SpeechPillButton.swift:41`. Drop `.gradient`.
     - **Waveform bars → `Color.ink.opacity(0.35 + magnitude * 0.65)`:** `VoiceCaptureOverlay.swift:225`. Shu is reserved for the mic button.
     - **`ExpenseTemplateSheet.swift:430`** hold button: replace with `Color.shu` now. forms.md restyles it to neutral with a coloured mic.
   - Foreground on those fills changes from `.white` to `Color.paper`:
     - `QuickVoiceAddView.swift:57`
     - `OnboardingVoiceHero.swift:14`
     - `ExpenseTemplateSheet.swift:415` (`.tint(.white)`) and `:425`
     - `SpeechPillButton.swift:69` and `:73`
   - Delete the shadow at `QuickVoiceAddView.swift:51`.

5. **Font files and registration.**
   - Download (or have the user provide) `FragmentMono-Regular.ttf`, `FragmentMono-Italic.ttf` and `OFL.txt` from the repo. Put them in `LinguicaSubTracker/Resources/Fonts/`. The synchronized group adds them to the app bundle, and `OFL.txt` ships as the licence notice.
   - Delete the 9 `SF-Compact-Rounded-*.otf` files from that folder.
   - `LinguicaSubTracker/Info.plist:16-27`: replace the 9 strings with `FragmentMono-Regular.ttf` and `FragmentMono-Italic.ttf`.
   - `SatoruWidgets/Info.plist`: add a `UIAppFonts` array with the same two strings, as a sibling of `NSExtension`.
   - `project.pbxproj`, exception set `18A8E7B03068400000A50CC2` (`:78-104`): add `Resources/Fonts/FragmentMono-Italic.ttf,` and `Resources/Fonts/FragmentMono-Regular.ttf,` after `Resources/Assets.xcassets,` (`:101`). On a group owned by another target, `membershipExceptions` *adds* the files to the widget.

6. **Theme.swift** (`LinguicaSubTracker/Core/Utils/Theme.swift`):
   - `FontName` (`:4-9`) collapses to a single case, `case regular = "FragmentMono-Regular"`. It must equal `AppFont.mono`, and the step-18 test asserts that. New code (including price_display.md) uses `AppFont.mono`, which the widget can also see.
   - `font(size:weight:)` (`:11-13`) becomes:
     ```swift
     static func font(size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
         .custom(AppFont.mono, size: size, relativeTo: style)
     }
     ```
   - Delete `AppButtonStyle` (`:16-23`) and `LiquidGlassButtonStyle` + `.liquidGlass` (`:25-35`). There are no callers.
   - Replace `AppTextModifier` (`:37-45`) with:
     ```swift
     struct AppTextModifier: ViewModifier {
         let style: AppTypography.Style
         @ScaledMetric private var boldSize: CGFloat
         @Environment(\.legibilityWeight) private var legibility

         init(style: AppTypography.Style) {
             self.style = style
             _boldSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
         }

         func body(content: Content) -> some View {
             content
                 .font(legibility == .bold   // Bold Text: Fragment Mono has no bold
                       ? .system(size: boldSize, weight: .semibold, design: .monospaced)
                       : Theme.font(size: style.size, relativeTo: style.textStyle))
                 .tracking(style.letterSpacing)
                 .textCase(style.uppercase ? .uppercase : nil)
         }
     }
     ```

7. **Typography.swift** (`LinguicaSubTracker/Core/Utils/Typography.swift`):
   - `Style` becomes `size`, `textStyle: Font.TextStyle`, `letterSpacing` (name kept; price_display.md reads it) and `uppercase: Bool = false`.
   - Rewrite the 13 statics with the §4 table values.
   - `size(_:)` (`:80-86`) copies all fields.
   - **Delete** `weight(_:)` (`:88-94`) and the `weight` field.
   - Fix every compile error by deletion:
     - the 34 `.typography(x.weight(…))` chains become `.typography(x)`, including the 2 conditional ones (list them with `grep -rn 'typography(.*\.weight(' --include='*.swift' LinguicaSubTracker`)
     - `AppButton.swift:56-74` becomes `Theme.font(size: S.size, relativeTo: S.textStyle)` for `bodySmall`/`titleMedium`/`titleLarge`
     - `LinguicaSubTrackerApp.swift:50,75` becomes `Theme.font(size: 15)`
     - `TextAnimatedView.swift:128` becomes `.font(Theme.font(size: size, relativeTo: style.textStyle))`
   - Do not restyle those views. Their owning docs do that.

8. **UIKit chrome.** Add `@MainActor static func applyUIKitAppearance()` to `Theme` and call it at the end of `SatoruApp.init()` (`LinguicaSubTrackerApp.swift:23-45`):
   ```swift
   guard let title = UIFont(name: AppFont.mono, size: 17),
         let large = UIFont(name: AppFont.mono, size: 28),
         let seg = UIFont(name: AppFont.mono, size: 13) else {
       return assertionFailure("Fragment Mono not registered")
   }
   UINavigationBar.appearance().titleTextAttributes =
       [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: title)]
   UINavigationBar.appearance().largeTitleTextAttributes =
       [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
   UISegmentedControl.appearance().setTitleTextAttributes(
       [.font: UIFontMetrics(forTextStyle: .footnote).scaledFont(for: seg)], for: .normal)
   ```
   - Use the legacy proxy properties so the iOS 26 glass bar backgrounds stay untouched.
   - If the titles do not change on iOS 26, fall back to `UINavigationBarAppearance()` + `configureWithDefaultBackground()` with the same attributes on `standardAppearance` / `scrollEdgeAppearance` / `compactAppearance`, and screenshot that the glass is unchanged.

9. **TextAnimatedView font measurement** (`Features/Home/Views/Components/TextAnimatedView.swift:74-76`): use `UIFont(name: AppFont.mono, size: pointSize) ?? .monospacedSystemFont(ofSize: pointSize, weight: .regular)`. Everything else in that file belongs to price_display.md.

10. **Stray fonts this doc owns** (rows marked "this doc" in §4):
    - `LogoCircle.swift:111`: `.font(.custom(AppFont.mono, fixedSize: size * 0.33))`. Shared with the widget, hence `AppFont`.
    - `CalendarStyleSheet.swift:116`: `.font(.custom(AppFont.mono, fixedSize: 9))`.
    - `SpeechPillButton.swift:45`: `.typography(.titleMedium)`.
    - The widget `rounded` → `mono` rename (§10). Apply it with a regex over `SatoruWidgets/WidgetViews.swift`: `rounded\(([^,()]+(?:\([^()]*\))?)(?:,[^)]*)?\)` → `mono($1)`. It converts all 59 calls (it leaves `.rounded()` at `:113` alone) and also rewrites the declaration at `:8` to `mono(_ size: CGFloat)`, so then set its body by hand to `.custom(AppFont.mono, fixedSize: size)`.

11. **Motif primitives**: create `LinguicaSubTracker/Core/UI/Motifs/Torii.swift` (new) with `Kasagi` and `KasagiHeader` (§5 snippet), plus:
    ```swift
    struct Hashira: View {
        var height: CGFloat = 12
        var body: some View {
            Rectangle().fill(Color.shu).frame(width: 3, height: height).accessibilityHidden(true)
        }
    }

    struct SectionLabel: View {
        let title: String
        var color: Color = .inkSecondary
        init(_ title: String, color: Color = .inkSecondary) { self.title = title; self.color = color }
        var body: some View {
            HStack(spacing: 6) {
                Hashira()
                Text(title).typography(.labelLarge).foregroundStyle(color)
            }
            .padding(.horizontal, 8)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }

    struct Rule: View {
        var color: Color = .rule
        var thickness: CGFloat? = nil      // nil = hairline
        var overhang: CGFloat = 0          // nuki: 3 for section dividers
        @Environment(\.displayScale) private var scale
        var body: some View {
            Rectangle().fill(color)
                .frame(height: thickness ?? 1 / scale)
                .padding(.horizontal, -overhang)
                .accessibilityHidden(true)
        }
    }
    ```

12. **Paper cards and section labels.**
    - `GlassSection.swift`:
      - default `cornerRadius = AppRadius.card` (`:6`)
      - `:17` becomes `.background(Color.paperRaised, in: shape).overlay(shape.strokeBorder(Color.rule, lineWidth: 1))`
      - keep the type name and the three modifiers (`:29-46`)
      - add a doc comment: "Paper card (formerly glass). Name kept for API stability."
    - `LabeledSection.swift`:
      - the title (`:22-25`) becomes `SectionLabel(title, color: titleColor)`
      - the `titleColor` default becomes `Color.inkSecondary` (`:7,12`)
      - forms.md removes the tinted `titleColor:` arguments
    - `SettingsView.swift:172-175`: the title becomes `SectionLabel(title)`.
    - Insert `KasagiHeader()` as the first child of the `VStack` at `SettingsView.swift:37`.
    - Inside `GlassSection` content owned by this doc (Settings, `SettingsView.swift`), replace `Divider()` with `Rule()`. Leave `Divider()` inside `Menu`s (for example `HomeToolbar`) alone.
    - Feature docs convert dividers in their own views.

13. **`AppButton`.**
    - Apply the §6 table. The colour switches are at `:194-206`, `:208-215`, `:217-235` and `:254-271`.
    - `.outline` background (`:175`): `RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(…, lineWidth: 1)`.
    - `GlassIfNeeded` (`:280-283`): `in: .rect(cornerRadius: AppRadius.card)`.
    - Delete the unused `solidBackgroundColor` (`:245-252`).
    - Remove `.symbolColorRenderingMode(.gradient)` (`:144`). No gradients.
    - Rewrite the stale `Appearance` comments at `:27-28` (`.solid` = tinted glass with a `paper` label; `.glassy` = untinted glass). The `ultraThinMaterial` grep gate in Verification otherwise matches `:28`.
    - Keep `accessibilityLabel(title)` and the traits (`:187-191`).

14. **Pickers, chips and toast.**
    - `CustomSegmentedPicker.swift`:
      - highlight (`:39-41`): `RoundedRectangle(cornerRadius: AppRadius.card).fill(.clear).glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))`
      - track (`:48`): `.background(Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))` + `.overlay(RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(Color.rule))`
      - `.contentShape(Capsule())` (`:49`, `:90`) becomes `Rectangle()`
      - animation (`:62`): `.smooth(duration: 0.25)`
      - keep the drag-to-select overlay (`:50-61`)
    - `AppearanceSelector.swift`: the same changes at `:13-19` and `:26-28`. Delete `.symbolEffect(.bounce…)` (`:56,65,73`) and `.scaleEffect` (`:55,63,72`). Keep `.sensoryFeedback(.selection)` (`:29`).
    - `MenuPicker.swift`: `.tint(.gray)`/`.foregroundStyle(.gray)` (`:32,45,54`) become `Color.inkSecondary`. Glass (`:57`) becomes `in: .rect(cornerRadius: AppRadius.card)`.
    - `SortChip.swift:39`: `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))`.
    - `SyncToast.swift:24-26`:
      - `Capsule()` becomes `RoundedRectangle(cornerRadius: AppRadius.card)`
      - stroke `Color.rule`
      - delete the shadow
      - replace the stale comment at `:22-23` with "Opaque paper surface; toasts are content, not glass."

15. **Ripple removal (all except onboarding).** Skip any line a feature doc already removed.
    - `TotalView.swift:110`: delete `.rippleOnTap()`. Glow, `monthRipple` and the bounce belong to price_display.md.
    - `MonthView.swift`: delete `rippleSpace` (`:4`), `rippleOrigin`/`rippleTrigger` (`:20-21`), `.coordinateSpace(...)` + `.rippleEffect(...)` (`:31-32`), and the `onRipple:` argument (`:60-67`).
    - `DayCell.swift`: delete `onRipple` + its comment (`:15-18`), `@State center` (`:23`), the `.background { if onRipple != nil { centerReader } }` (`:81-83`), `onRipple?(center)` (`:116`) and `centerReader` (`:121-130`). Fix the stale comment at `:297-298`.
    - `HomeActionButton.swift:25,39` and `SpeechPillButton.swift:48`: `.transition(.liquidRipple)` becomes `.transition(.opacity)`. home_screen_ux.md later deletes `HomeActionButton`.
    - **Dead code in `Core/UI/Effects/RippleEffect.swift`:** delete
      - `WakeStyle` (`:19-37`)
      - `WakeModifier` (`:120-150`)
      - `DragRippleModifier` (`:152-249`)
      - the `rippleEffect(origin:trigger:style:)` extension (`:300-309`, now uncalled)
      - `rippleOnDrag` (`:321-332`)
    - In `Ripple.metal`, delete `RippleWake` (`:42-91`).
    - **Keep for onboarding:**
      - `RippleStyle`, `RippleEffect`, `RippleModifier`, `TapRippleModifier`
      - `LiquidRevealModifier`, `AnyTransition.liquidRipple` and `liquidRipple(from:)` (used at `OnboardingView.swift:29-33`)
      - `rippleOnTap`
      - the Metal `Ripple`
      - `RippleCard.swift` (`rippleCard()`, which `OnboardingEditingHero:35`, `OnboardingVoiceHero:27`, `OnboardingOrganizeHero:26`, `OnboardingStatsHero:23`, `OnboardingBudgetHero:49` and `OnboardingCalendarHero:25` use; `rippleOnTap()` is at `OnboardingEditingHero:36`, `OnboardingVoiceHero:28` and `OnboardingOrganizeHero:27`)
    - Fix the stale comments at `OnboardingFeaturePage.swift:4-5` and `OnboardingCalendarHero.swift:4-6`. The latter's `MonthView` no longer ripples.

16. **Hardcode sweep** for files this doc owns. Audit command: `grep -rnE '\.(white|black)\b' --include='*.swift' LinguicaSubTracker SatoruWidgets`, which gives about 106 hits. Classify each hit:

    | Pattern | Replace with |
    |---|---|
    | `colorScheme == .dark ? .white : .black` | `Color.ink` |
    | `.white` text/icon/`ProgressView.tint` on a shu, beni or ink fill | `Color.paper` |
    | `.white.opacity(x)` / `.black.opacity(x)` strokes on paper (swatch rings) | `Color.rule` (selected ring: `Color.ink`) |
    | `.shadow(color: .black…)` on cards/toasts/buttons | delete |
    | Scrims (`Color.black.opacity` dimming) | keep |
    | User/data colours: `LogoCustomization.swift:69`, `Color.swift:52` `contrastingForeground` | keep |
    | UIKit image rendering: `ReceiptVisualIntelligence.swift:123,127` | keep |
    | Preview-only `.background(.black)` / gradients | `Color.paper` when touching the file; otherwise leave |

    This doc's sites:
    - `CategoriesSheet.swift:120`, `CategoryEditView.swift:31`, `ListsSheet.swift:112`, `ListEditView.swift:31`: these are `.white.opacity(0.3)` strokes and become `Color.rule`.
    - `ColorPresetPicker.swift:32` becomes `Color.ink`.
    - `AppButton.swift`: covered by step 13.
    - `MenuPicker`/`CustomSegmentedPicker`/`AppPicker`/`LabeledSection`/`CurrencyMenu` previews become `Color.paper`.

    Other files are swept by their owners:
    - forms.md: `LogoSheet` (12), `PopularServicesRow`, `LogoHeaderSection`, `CategorizationSection`, `MoreDetailsSection`, `AmountField`, form view models
    - charts.md: `Coin*`, `SpendDial`, `YearMenu`, `DimensionMenu`
    - list_view.md: `ExpenseRow`, `HomeExpenseRow`
    - price_display.md: `NumKeyPadSheet`

    Semantic colours in this doc's files:
    - `RowModeToolbar.swift`:
      - `:37`, `:44` and `:55`: delete the `.tint`. `:55` keeps `.glassProminent`, so shu comes from the accent.
      - `:65`: `.tint(Color.beni)`. The trash glyph is already there.
    - `ReceiptScanSheet.swift:69`: delete `.tint(Color.green.gradient)`.
    - Selection checkmarks become `Color.ink`: `ListsSheet.swift:69-71`, `PaymentMethodsSheet.swift:61` and `CategoriesSheet.swift:78`.
    - `BudgetEditor.swift:56-66` "Clear?": `.red` becomes a `beni` glyph with an `ink` label, on untinted rect glass.
    - `SettingsView.swift`:
      - delete `isFooterVisible` (`:16-18`), `.symbolEffect(.bounce…)` (`:58-62`) and `.onScrollVisibilityChange` (`:78-80`)
      - the heart's `.red` (`:63`) becomes `Color.shu`
      - `SwitchToggleStyle(tint: .green)` (`:219`, `:289`, `:369`, `:395`) becomes `SwitchToggleStyle(tint: Color.shu)` (system control, AccentColor rule)
    - Error text `.red` at `VoiceCaptureOverlay.swift:152` and `ReceiptScanSheet.swift:114` becomes `Color.beni` (the message carries the meaning).
    - Leave the budget-state reds/oranges (`BudgetEditor.swift:136`, `BudgetDetailsSheet.swift:82,88,119,151,154,201`) and the OCR confidence colours (`ReceiptScanSheet.swift:259-263`) alone here; the first follow charts.md's budget scale, the second are an open point.
    - `OnboardingView.swift:143` (`appAccent.gradient`): drop `.gradient` only. Onboarding is restyled later.

17. **Widget today marker**: apply §10 at `WidgetViews.swift:396,405-408,443,490,506-508,546`.

18. **Font test**: create `LinguicaSubTrackerTests/ThemeFontTests.swift` (new):
    ```swift
    import CoreText
    import Testing
    import UIKit
    @testable import LinguicaSubTracker

    @Suite("Theme fonts")
    struct ThemeFontTests {
        @Test("Fragment Mono is registered and covers every currency symbol MoneyFormatter prints")
        func fragmentMono() throws {
            #expect(Theme.FontName.regular.rawValue == AppFont.mono)
            let font = try #require(UIFont(name: AppFont.mono, size: 15)) as CTFont
            for symbol in ["$", "€", "R", "£", "¥"] {
                let chars = Array(symbol.utf16)
                var glyphs = [CGGlyph](repeating: 0, count: chars.count)
                #expect(CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count), "missing \(symbol)")
            }
        }

        @Test func kanjiFontsExist() {
            #expect(UIFont(name: AppFont.kanji, size: 13) != nil)
            #expect(UIFont(name: AppFont.kanjiBold, size: 13) != nil)
        }
    }
    ```

19. **Rename and delete aliases** (last step, after everything builds):
    - Replace `Color.appAccent`/`.appAccent` with `Color.shu`/`.shu`, `appAccentDeep` with `shuPressed`, and `appSurface` with `paperRaised` across `LinguicaSubTracker/` and `SatoruWidgets/`.
    - Then delete the three alias lines.
    - From here on, feature docs use only the new names.

## Preserve
- **Settings decoding:**
  - `ThemeMode` lenient decoding (`AppTheme.swift:15-18`) and `AppSettings.themeMode/calendarStyle` being optional (`AppSettings.swift:11-19`).
  - This doc adds **no** `AppSettings` fields. Any future theme field must be optional with a lenient enum decoder. Otherwise `StorageService` falls back to `.default` and wipes every setting.
- **Appearance plumbing:**
  - `.preferredColorScheme(settingsStore.themeMode.colorScheme)` (`LinguicaSubTrackerApp.swift:69,76`)
  - `SettingsViewModel.themeModeBinding()` (used at `SettingsView.swift:184`)
  - `AppearanceSelector` `.sensoryFeedback(.selection)`
- **Shared APIs:**
  - `GlassSection` API (`contentInsets`, `cornerRadius`, `clipsContent`) and every caller's layout, including `HomeListView.swift:207-208`.
  - `LabeledSection(_:titleColor:content:)` signature.
  - `AppButton` both inits (`:85-127`), `accessibilityLabel(title)` and the disabled traits (`:187-191`).
  - `CustomSegmentedPicker` drag-to-select (`:50-61`) and `matchedGeometryEffect`.
  - `BudgetColor.color(spent:budget:)` signature (6 callers, including the widget).
  - `TextAnimatedView` fitting maths (`fittedSize`, `measuredWidth`, the 0.9 minimum scale), which keeps working with the new font name.
- **User data:** `LogoCustomization` colours (`resolvedBackground/Foreground/Shadow`) and `AppCategory.colorHex` are never rewritten.
- **Onboarding:** the ripple stays (`rippleCard`, `rippleOnTap`, `liquidRipple(from:)`). Never add glass or materials inside a hero (black render).
- **SyncToast:** Reduce Motion transition (`SyncToast.swift:31-33`) and `AccessibilityNotification.Announcement`.
- **Widgets:**
  - `.widgetAccentable()` on today markers
  - `containerBackground` (`SatoruWidgetsBundle.swift:56`)
  - `WidgetViews.swift`/`WidgetData.swift` still compile into the app for `Features/Debug/WidgetGallery.swift`
- **DEBUG hooks:**
  - `SIMCTL_CHILD_DEBUG_HOME_VIEW` (`HomeView.swift:84-89`)
  - `DEBUG_MONTH_INDEX` (`:91-98`)
  - `DEBUG_WIDGET_GALLERY` (`:100-101`, `WidgetGallery.swift:7`)
  - `DEBUG_OPEN_SHEET=budget` (`HomeListView.swift:60-61`)
  - `DEBUG_OPEN_SETTINGS_PAGE` (`SettingsView.swift:92-93`)
- **Feature flags:** `FF_*` compilation conditions (`project.pbxproj:496,553`) stay untouched.

## Risks / gotchas
- **Colorset name clash.** Never add colorsets named after tokens (`Paper`, `Ink`, `Shu`, …). The generated `Color.paper` duplicates the `static let` and the build fails.
- **`Color("AppPurple")` is a string.** It compiles after the colorset is deleted and renders clear at runtime. Grep for it.
- **The widget target is separate:**
  - `Theme.swift`/`Typography.swift` are app-only, so widget code uses `AppFont.mono` and `AppRadius` from `AppTheme.swift`.
  - The **DEBUG widget gallery renders inside the app**, so it proves nothing about the extension's font registration. Check a real Home Screen widget.
  - `LogoCircle.swift` is shared, so its initials font must use `AppFont`, not `Theme`.
- **Weight loss.** Deleting `.weight()` removes emphasis in 34 places. Restyling them (size, case, colour) belongs to the owning docs. Until then, rows look flatter. That is expected.
- **The accent now tints everything untinted:**
  - With `AccentColor` = shu, plain toolbar `Button`s, alert buttons, `Link`s and `Menu` checkmarks may render shu.
  - Toolbar glyphs must read `ink`. Screenshot every toolbar. Where a glyph renders shu, add `.tint(Color.ink)` to that button only, never to a container that also holds the `.glassProminent` CTA.
- **Two filled shu shapes.**
  - `SimplifiedAddExpenseView.swift:230-231` and `ExpenseFormView.swift:57` use `.glassProminent` + `.tint(.red)` for the delete trash. With shu as the accent they read as a second red fill. (`SimplifiedAddExpenseView.swift:236` is the untinted "Add" CTA and correctly becomes shu.)
  - forms.md moves them to `.glass` + `beni`.
- **Metal still compiles.** `Ripple.metal` stays (onboarding), so builds still need the Metal toolchain (`xcodebuild -downloadComponent MetalToolchain` after Xcode updates).
- **Line metrics.** Fragment Mono's ascender is 729 and descender −218 per 1000 units. Fixed-height containers can clip descenders at large Dynamic Type: `FormRow.swift:37` (44pt) and `DayCell` heights.
- **Dynamic Type mismatch.**
  - `Theme.font` scales with Dynamic Type while `TextAnimatedView.measuredWidth` measures unscaled. price_display.md switches fitted amounts to `fixedSize:`.
  - The UIKit appearance fonts are computed once at launch and do not follow a live Dynamic Type change until relaunch.
- **Gold and red under CVD.** Light `shu` and `kinText` are indistinguishable under deuteranopia (ΔE 0.4). Budget and status meaning must carry a shape or word.
- **Interactive glass shape snap.** One beta report saw `.interactive()` glass on a non-capsule shape snap to a capsule on press. Verify on the shipping OS.
- **Stale builds.** Xcode's compilation cache can serve old code. If screenshots show old UI, delete `DerivedData/.../Build/Intermediates.noindex` and build with `COMPILATION_CACHE_ENABLE_CACHING=NO`.
- **Inline titles.** Every screen is `.inline`, so the 17pt `titleTextAttributes` font is the one that matters; the 28pt large-title font in step 8 only covers future large titles. At 0.6 em per character mono runs wider than SF Pro: check "Popular Subscriptions" and "Edit Payment Method" beside their bar buttons.

## Verification
1. **Build:** `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=<UDID>' build`. Use the simulator UDID (on the author's Mac: iPhone 17 Pro `9BF66402-1F99-44CB-89A9-03A7C31ECBD2`); name+OS strings fail on 26.4.1.
2. **Tests:** run the same command with `test`. Every existing suite plus `ThemeFontTests` must pass.
3. **Grep gates.** Each of these must return nothing:
   - `grep -rn "SFCompactRounded\|SF-Compact-Rounded" LinguicaSubTracker SatoruWidgets`
   - `grep -rn "appBackgroundTop\|appBackgroundBottom\|appPurple\|AppPurple" --include='*.swift' LinguicaSubTracker SatoruWidgets`
   - `grep -rn "rippleEffect(\|rippleOnDrag\|RippleWake\|WakeStyle\|onRipple\|centerReader" LinguicaSubTracker`
   - `grep -rn 'typography(.*\.weight(' --include='*.swift' LinguicaSubTracker`
   - `grep -rn "Capsule()" LinguicaSubTracker/Core/UI LinguicaSubTracker/Core/Components/SyncToast.swift LinguicaSubTracker/Features/Settings/Views/Components/AppearanceSelector.swift`
   - `grep -rn "ultraThinMaterial" LinguicaSubTracker/Core/UI`
   - After step 19: `grep -rn "appAccent\|appSurface" --include='*.swift' LinguicaSubTracker SatoruWidgets`
4. **Screenshots, light and dark.** Switch with Settings → Appearance (taps register). `xcrun simctl ui <UDID> appearance dark` does not reach the app reliably. Wait about 8s after launch.
   - `SIMCTL_CHILD_DEBUG_HOME_VIEW=calendar` and `=list`, plus `SIMCTL_CHILD_DEBUG_MONTH_INDEX=<n>`: the ground is flat paper and no screen shows green or purple.
   - `SIMCTL_CHILD_DEBUG_HOME_VIEW=list SIMCTL_CHILD_DEBUG_OPEN_SHEET=budget` (the hook lives in `HomeListView`, so list mode is required): paper cards, uppercase section labels with hashira.
   - Open Settings by tap, with `SIMCTL_CHILD_DEBUG_OPEN_SETTINGS_PAGE=calendarstyle|privacy|datainfo` set at launch, plus Settings root: kasagi header, squared appearance picker, nav title in Fragment Mono, the "How My Data Is Saved" title.
   - `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=week|month|calendar-month|calendar-week|upcoming|lock` and each `-dark` variant: paper backdrop, shu today numeral, no rounded fonts, nothing truncated.
   - `SIMCTL_CHILD_ONBOARDING_PAGE=0…5` (after reinstall): the heroes still ripple on tap and the hero cards are not black.
5. **Real widget:** add a Satoru widget to the simulator Home Screen. It must show Fragment Mono, which proves the extension registration.
6. **Checklist per screen:**
   - at most one filled shu shape
   - toolbar glyphs `ink`
   - no gradients or shadows on cards
   - card borders visible in light mode
   - destructive actions show glyph + word
7. **Accessibility:**
   - Settings → Accessibility → Bold Text on: labels switch to SF Mono semibold.
   - Largest Dynamic Type on Settings and Home: no clipped `FormRow`s.
   - VoiceOver announces section labels as headings.
   - Reduce Motion: no segmented-highlight motion beyond a fade.

## Open points / dig deeper
- **Washi texture.** A 512px seamless tile, `.multiply` at ≤5% in light and omitted in dark. Research the [Pakutaso](https://www.pakutaso.com/en/20200300064post-23800.html) licence or scan our own, test the look under `glassEffect` with Increase Contrast and Reduce Transparency on, and check that contrast numbers do not move. Tiling technique: [Fatbobman](https://fatbobman.com/en/posts/how-to-tile-images-in-swiftui/).
- **App icon, `BrandLogo`, mascot.**
  - `Resources/AppIcon.icon` is still green and purple (`logo-green.svg`/`logo-purple.svg` layers). In-app, `BrandLogoStyle.deepGreen` (`BrandLogo.swift:93-97`) re-points to shu→shuPressed, but `BrandLogoStyle.green` (`:87-91`) is hardcoded green, so `BrandLogo` renders half shu, half green, and both are gradients (against the no-gradient rule).
  - Research a torii or hanko mark in shu on lacquer and its tinted/clear icon modes. Decide whether the crow mascot stays.
  - Why it matters: the Home Screen is the first brand touchpoint.
- **Currency glyphs on device.** The test covers `$ € R £ ¥`. Also check `.currency(code:)` outputs such as "CA$" in Search rows, and any future currency (₩ ₹ ₽ ₿), at small sizes for legibility.
- **Bold escape hatch.** Should SF Mono semibold also be used for emphasis in normal mode (price, row names)? It would restore hierarchy that size and case may not carry. Prototype one Home list row both ways.
- **Navigation titles on iOS 26 glass bars (verify on device).** Confirm that the legacy `titleTextAttributes` proxy applies, and that the 17pt inline titles fit beside the bar buttons. Why: some UIKit appearance changes reset the glass background.
- **Shu toggles vs the one-filled-shu rule.** Settings shows up to 4 shu toggle tracks at once (`SettingsView.swift:206,276,356,382` in the working tree). Screenshot both modes and decide whether toggles keep the AccentColor exemption or take `.tint(Color.ink)`.
- **OCR confidence colours.** `ReceiptScanSheet.swift:259-263` maps confidence to green/orange/red by hue alone. Decide a palette-safe encoding (ink + glyph, or `kinText`/`beni` plus a word).
- **Widget fonts in accented, vibrant and Control Center contexts.** Check whether `QuickAddControl` and lock-screen families force the system font, and whether Fragment Mono survives `.widgetAccentable()` tinting.
- **Square custom glass next to capsule system glass.** Prototype the Home toolbar (capsules) above squared pickers, and check the `.interactive()` press-shape behaviour.
- **Saturday `ai`.** Keep the blue or go monochrome? calendar.md decides after a 70/25/5 histogram of the month grid.
- **Default category palette and `LogoPalette`.**
  - The research proposes traditional defaults (藤紫, 若竹, 萌黄, 縹, 青磁, 鴇, 菖蒲, 鼠) for new installs only.
  - Also consider an OKLCH lightness clamp for user colours: L ≤ 0.62 in light mode and ≥ 0.55 in dark.
  - Today Entertainment #FF3B30 sits ΔE 13 from dark shu.
- **Rename `GlassSection`.** Rename it to `PaperSection` once all feature docs land, to remove the misleading name.
- **Kasagi curve proportion.** Search 笠木 反り 寸法 for real sori ratios. The 3pt lift is a guess at an Ise-style "barely perceptible" curve.
- **Hashira density.** Settings shows up to 7 section labels with shu ticks. Measure against 70/25/5. Fallback: `ruleStrong` ticks, with shu only on the first section.
- **Card edge in light mode.** A 1pt `rule` is 1.24:1 against `paper`. Confirm it reads on device, or move cards to `ruleStrong` at hairline weight.
- **70/25/5 measurement.** Build a pixel-histogram script over the verification screenshots, so the ratio is checked rather than eyeballed.
- **CVD on device.** Check the 赤字 stamp and `kinText` underline legibility at 11–13pt under deuteranopia filters.
- **Red perception.** Japanese stock screens show rises in red, so red totals may not read as "bad". Validate the hanko label wording (赤字 vs OVER) with Japanese users.
- **OpenType features.** Slashed zero (`zero`) and serif one (`ss07`) via `UIFontDescriptor` feature settings could make prices more ledger-like. Not in v1.
- **Mixed Latin + kanji strings.** If any string mixes Latin and kanji (for example "12 MON 月" in one `Text`), research a `cascadeList` descriptor with `UIFontMetrics` rescaling.
- **Onboarding restyle.** The heroes keep ripple and `rippleCard` for now. Plan a later pass to bring them to paper + brush motion.

**Status: proposed, not implemented.**
