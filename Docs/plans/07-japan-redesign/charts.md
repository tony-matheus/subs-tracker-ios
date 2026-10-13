# Charts: ink, rule and seal data visualization

## Goal
- **What the user asked for:** a Charts restyle in the "modern Japan" direction: straight lines with subtle curves, a red + black + gold (dark) / red + white + gold (light) palette, Fragment Mono, Liquid Glass kept for controls. The planning answer for the budget conflict was: "docs propose options and recommend one".
- **In practice:**
  - Charts are drawn like a ledger: ink bars, the current period in shu, a dashed gold (`kin`) reference line, and dotted notebook grid lines. Corners are square, line caps are butt, and every axis label uses Fragment Mono.
  - The Stats dial loses its glow and glass disc. It gets butt-capped segments and a small hanko (seal) pointer, and keeps its drag, inertia and selection behaviour exactly.
  - The legend becomes notebook rows: a square swatch, a 2pt `Rectangle` progress bar, and a shu left rule on the selected row.
  - Coins become mon coins (square hole, no reeded edge). Empty slots use `Color.rule`.
  - The budget status scale moves from green → red to the Japanese ledger scale 黒字 / 赤字 (black ink = surplus, red ink = deficit). It is implemented once in `BudgetColor.swift` and shared with the widget. This doc owns the options analysis and the `HankoStamp` component.

**Depends on:**
- `general_app_ui.md`, **already implemented in the working tree** (uncommitted; `git diff HEAD -- <path>` shows it). This doc uses its tokens (`LinguicaSubTracker/Core/Utils/AppTheme.swift:52-63`), `AppFont` (`:66-70`), `AppRadius` (`:72-75`), the paper-card `GlassSection` (`LinguicaSubTracker/Core/UI/Containers/GlassSection.swift:4-29`), `SectionLabel`/`Rule`/`Hashira` (`LinguicaSubTracker/Core/UI/Motifs/Torii.swift:29-69`) and the mono `AppTypography` styles (`LinguicaSubTracker/Core/Utils/Typography.swift:10-22`).
- `price_display.md` consumes the `BudgetColor.Tier` contract and `HankoStamp` from this doc. Its step 9 deletes the `TotalView` breakdown and the `CoinProgress` call; this doc's step 14 depends on that.
- `home_screen_ux.md` deletes the toolbar stats ring (`HomeToolbar.swift:64-70`) and `HomeViewModel.budgetTint`. This doc does not restyle the ring.
- `calendar.md` owns the widget today marker (ensō) and `EnsoShape`.
- `list_view.md` owns the `HomeListView` rows and the `categoryStacks` labels (`HomeListView.swift:155-161`). This doc owns `CoinStack` itself.

**References:**
- [JGJE 赤字](https://www.tkgje.jp/entries/04500/04712_akaji.html): red ink = deficit. [JGJE 朱肉](https://www.tkgje.jp/entries/06000/06192_shuniku.html): seal paste is vermilion cinnabar.
- [WCAG 2.2 1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color)
- [Machado et al. CVD simulation](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html), used for the colourblind numbers below.
- [RetireJapan forum](https://retirejapan.com/forum/viewtopic.php?p=12877): Japanese stock screens show rising prices in red (anecdotal).
- [和色大辞典 colordic](https://www.colordic.org/w) and [Traditional colors of Japan, Wikipedia](https://en.wikipedia.org/wiki/Traditional_colors_of_Japan): pigment hexes.
- [Takase seal design](https://www.takase.com/custom-seal-design/): the hanko as a compositional accent.
- [SectorMark](https://developer.apple.com/documentation/charts/sectormark): Apple suggests 5–7 sectors at most.
- [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials): no glass in the content layer.
- [Applying custom fonts to text](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text): SwiftUI does not synthesize bold.

## Current state
All line numbers refer to the **current working tree** (foundation applied).

**What the foundation already did here (verify, don't redo)**
- `GlassSection` is a flat paper card: `paperRaised` fill, 1pt `rule` border, radius `AppRadius.card` (4) (`GlassSection.swift:15-19`). Every Stats card is therefore already paper.
- `MenuPicker(style: .glassy)`, used by `YearMenu`/`DimensionMenu`, is square rect glass (`LinguicaSubTracker/Core/UI/Inputs/MenuPicker.swift:47-57`).
- `CustomSegmentedPicker` has a rect glass highlight on a `paperRaised` track with a `rule` border, and is gated on Reduce Motion (`LinguicaSubTracker/Core/UI/Inputs/CustomSegmentedPicker.swift:38-64`).
- `.weight(...)` was removed from Stats typography calls (`StatsCard.swift:16`, `StatsLegendList.swift:37,48`, `StatsSheet.swift:99,102`). `AppTypography.Style` no longer has `.weight`.
- Widgets: fonts go through `mono(_:)` (`SatoruWidgets/WidgetViews.swift:8-10`); `WidgetBackdrop` is `Color.paper` (`:610-614`); the today marker is a 1pt `shu` `Rectangle` stroke with `.widgetAccentable()` (`:405-408`) and shu numerals (`:396`, `:443`, `:490`).

**Stats sheet: `LinguicaSubTracker/Features/Stats/Views/StatsSheet.swift`**
- `scaleHeader` `:17-35`: title `.typography(.titleSmall)` `.foregroundStyle(.secondary)` (`:20-23`), plus a system segmented `AppPicker` (Monthly/Yearly), 160pt wide (`:27-33`).
- `NavigationStack`, `.appBackground()` `:42`, title "Stats", `xmark` close button `:45-53`.
- `createWidgetCard` `:58-79`: "Coming soon" badge on a `Capsule` with `primary.opacity(0.08)` (`:71-76`).
- Controls cluster `:87-111`: `YearMenu` `:89`, `DimensionMenu` `:91`, `CustomSegmentedPicker` Breakdown/Trend with `chart.pie.fill`/`chart.bar.fill` icons `:94-104`, the active-count line `:106-110`.
- Breakdown tab `:113-142`: `GlassSection { scaleHeader + SpendDial }`, dial height 250 (`:116-128`); legend card `:130-140` (insets 8).
- Trend tab `:144-178`: `SpendTrendChart` height 220 (`:155-161`); "By expense in …" header `:168-170`; `ExpenseLineChart` height 240 (`:172-173`).
- `StatsCard` pair `:181-187`; `createWidgetCard` `:189`.
- Motion: `.transition(.blurReplace.combined(with: .scale(0.96)))` `:142`, `:178`; four `.spring(response: 0.45, dampingFraction: 0.85)` at `:195-198`. None is gated on Reduce Motion.
- Preview host `LinguicaSubTracker/Features/Stats/Views/Previews/StatsSheetPreviewHost.swift:8` uses `Color.black`.

**View model: `LinguicaSubTracker/Features/Stats/ViewModels/StatsViewModel.swift`**
- `fallbackPalette` `:21-24`: `#5E5CE6 #FF9F0A #30D158 #FF375F #64D2FF #BF5AF2 #FFD60A #FF6482` (iOS system colours).
- `items` `:36-50` are sorted by amount and coloured by `color(for:fallbackIndex:)` `:223-235`. Categories and lists use the user's `colorHex`; payment methods always use the fallback palette by rank (`:230-231`).
- `trendBarColor` `:104-109`: the `BudgetColor` tier when a budget is set, else `fallbackPalette[0]` (indigo).
- `monthlyTrendPoints` `:111-122` / `yearlyTrendPoints` `:124-136` set `highlighted` for the current month / current year.
- `expenseLineSeries` `:197-221`: top 6 expenses by yearly total (`.prefix(6)` `:212`), each coloured by the expense's brand colour (`:217`).

**`LinguicaSubTracker/Features/Stats/Views/Components/SpendDial.swift`**
- Constants: `ringWidth` 16 `:20`, `gapPoints` 24 `:21`. The gap is converted to degrees per radius at `:43-45`.
- Glow: `glowColor` `:46`, a `RadialGradient` with blur 30 `:49-57`.
- Glass disc: `Circle().glassEffect(.regular, in: Circle())` `:59-61`. This is glass in the content layer.
- Segments: trimmed `Circle` strokes, `lineCap: .round` (`:64-81`), rotated by `rotation` with `RingHitShape` hit area and the drag gesture (`:82-84`).
- Pointer: a white `Triangle` at `Color.white.opacity(0.85)` (`:86-90`, shape `:284-293`).
- Center label `:126-150`: `.headlineMedium` name, `minimumScaleFactor(0.7)`, `.bodyMedium` "amount • %".
- Behaviour:
  - drag `:153-186`
  - inertia: a 60 Hz `Timer`, ×0.975 decay, 220°/s threshold (`:189-209`)
  - `segmentIndexAtTop` with `approxGapFraction = 0.012` (`:219-236`, constant at `:228`)
  - `rotateToSegment` is a no-op when the segment is already on top, then a `.spring(response: 0.6, dampingFraction: 0.8)` (`:246-264`)
  - `updateSelection` with a light haptic (`:266-281`, haptic `:278`)
  - reset on `items` change `:100-106`; the onboarding hint `.spring(response: 0.9, dampingFraction: 0.55)` (`:110-120`)
  - no Reduce Motion check anywhere in the file
- Preview `.background(.black)` `:323`.
- Also used by `LinguicaSubTracker/Features/Onboarding/Views/Components/Heroes/OnboardingStatsHero.swift:15-23` (`hintRotationOnAppear: true`). That page sits under `OnboardingView`'s `.liquidRipple` (`LinguicaSubTracker/Features/Onboarding/Views/OnboardingView.swift:30`), a `layerEffect`, which renders the dial's glass disc black.

**`SpendTrendChart.swift`** (same folder)
- `BarMark(x: label, y: value)`, `.foregroundStyle(point.color.opacity(point.highlighted ? 1 : 0.45))`, `.cornerRadius(4)` (`:22-29`).
- X axis: first letter only when `abbreviateLabels`, `.typography(.labelMedium)` (`:32-42`).
- Y axis: `AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))` and a bare `AxisValueLabel()` in the **system font** (`:43-49`).
- `.animation(.spring(response: 0.5, dampingFraction: 0.8), value: points)` `:50`.

**`ExpenseLineChart.swift`**
- `LineMark` per series with `.interpolationMethod(.catmullRom)` and `lineWidth: 2, lineCap: .round` (`:30-37`).
- The axes copy `SpendTrendChart`; the Y `AxisValueLabel()` uses the system font (`:52-58`).
- Spring animation `:59`.
- The legend is a horizontal scroll of 8pt `Circle` chips (`:62-79`).

**`StatsLegendList.swift`**
- Rows `:21-72`: a 10pt `Circle` (`:32-34`), label, %, amount, and a 4pt `Capsule` progress bar on `primary.opacity(0.08)` (`:52-61`).
- The selected row gets a `RoundedRectangle(cornerRadius: 12)` fill of `primary.opacity(0.08)` (`:65-69`). Selection writes `selectedID` inside a spring (`:25-28`).

**`StatsCard.swift`**
- Title `.titleSmall` `.secondary` (`:9-13`).
- Value `.headlineLarge`, `.numericText()`, spring (`:15-19`). price_display.md owns `:17-19`.
- `.padding(16).glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))` (`:21-23`): glass in the content layer.

**`YearMenu.swift` / `DimensionMenu.swift`**
- Thin wrappers over `MenuPicker(style: .glassy)`. Their previews use `.background(.black)` (`YearMenu.swift:21`, `DimensionMenu.swift:20`).

**Coins: `LinguicaSubTracker/Core/Components/CoinProgress/`**
- `Views/Coin.swift`:
  - `CoinShape` `:4-78` is a 512×512 side-view coin: top ellipse, cylinder body, and five vertical "reeding" lines (`:54-68`).
  - `Coin` `:81-119`: `fill` defaults to `Color.white` (`:84`), `stroke` to `Color.black` (`:86`, invisible on lacquer); placeholder `Color.primary.opacity(0.07)` (`:98`); stroke `16 * scale`, round cap/join (`:106-113`).
- `Views/CoinStack.swift`:
  - The 10-coin pile is used by Home list mode (`LinguicaSubTracker/Features/Home/Views/Components/HomeListView.swift:142-174`).
  - `color(at:filled:)` `:51-54`: `.red` for every coin when over budget, `Color.white` for empty slots.
  - Accessibility summary `:56-59`.
  - `CoinEntrance.claim()` once per launch `:66-75`, claimed at `HomeListView.swift:173`.
  - `CoinDrop` physics `:84-113` (`restitution` 0.55, "metal coin" `:87-88`).
  - `DroppingCoin` keyframes `:150-190`: a fall `:159-164` plus two bounces `:165-188`. Skipped under Reduce Motion (`:126`, `:144`).
- `Views/CoinProgress.swift`: the horizontal coin row, wave on tap, Reduce Motion guard `:92`. Its only production caller is `TotalView.swift:111-125`, behind `showCoins`, which `HomeView.swift:35-43` never sets. **Unreachable in production.**
- `ViewModels/CoinProgressViewModel.swift`: `coins` `:27-65` (placeholder `Color.white` `:32`, `:64`), `filledCoinCount` `:71-74`, `allocate` `:85-124`.
- Tests: `LinguicaSubTrackerTests/CoinProgressAllocationTests.swift` (pins `Color.white` placeholders at `:41`, `:55`, `:67`, `:79`), `BudgetSplitTests.swift:59-69` (`filledCoinCount`), `CoinDropTests.swift` (physics and `CoinEntrance`).

**Dead or unreachable**
- `TotalView` breakdown share bar `TotalView.swift:150-199`: `Capsule` slices of at least 3pt, height 8, 2pt gaps, and a top-5 list. It is shown only via `isBreakdownVisible` (`:146-148`), toggled from the unreachable `CoinProgress` tap.
- `TotalViewModel.glowOpacity` returns `0.0` (`LinguicaSubTracker/Features/Home/ViewModels/TotalViewModel.swift:39-42`), so the `RadialGradient` (`TotalView.swift:44-63`) never shows. `BudgetColor.glowOpacity` (`LinguicaSubTracker/Core/Utils/BudgetColor.swift:19-24`) has no live caller.
- price_display.md step 9 deletes all of these. **Do not restyle them.**

**Budget colour: `LinguicaSubTracker/Core/Utils/BudgetColor.swift:7-17`** (not yet changed by the foundation)
- `<0.5` green, `0.5–0.75` yellow, `0.75–0.9` orange, `0.9–1.0` #FF5900, `≥1.0` red. With no budget it returns `.primary`.
- The file is compiled into the widget target (`LinguicaSubTracker.xcodeproj/project.pbxproj:92`).
- Direct callers (6):
  1. `TotalViewModel.swift:35-37` `budgetTint` → total digits (`TotalView.swift:90,104`, `HomeListView.swift:75`)
  2. `HomeViewModel.swift:39-41` `budgetTint` → toolbar ring (`HomeView.swift:118`); home_screen_ux.md deletes both
  3. `StatsViewModel.swift:104-109` `trendBarColor`
  4. `LinguicaSubTracker/Features/Settings/Views/Components/BudgetEditor.swift:22-40` (`progressGradient`, `progressColor`)
  5. `OnboardingBudgetHero.swift:14`
  6. `SatoruWidgets/WidgetViews.swift:110`
- Hardcoded budget reds outside `BudgetColor`:
  - `CoinStack.swift:52`
  - `WidgetViews.swift:151`, `:203`, `:230`
  - `BudgetEditor.swift:137` (price_display.md owns it)
  - `BudgetDetailsSheet.swift:82`, `:88`, `:119`, `:201` (`LinguicaSubTracker/Features/Settings/Views/Components/`); the warning reds `:151`, `:154` belong to forms.md (`FormErrorLabel`)

**Home toolbar stats ring** `HomeToolbar.swift:64-70` (`ring.dashed`, `variableValue: budgetRatio`): deleted by home_screen_ux.md. Not restyled here.

**Widgets: `SatoruWidgets/WidgetViews.swift`**
- `WidgetRing` `:15-35`: track `primary.opacity(0.12)` `:23`; scheduled `color.opacity(0.35)` and paid `color`, both `lineCap: .round` (`:24-31`); `.widgetAccentable()` `:33`.
- Budget `color` `:110`.
- Over-budget text `.red` at `:151`, `:203`, `:230`. The words "over"/"Over" are already present (`:117`, `:230`).
- `categoryBars` `:165-177`: 6pt `Circle` swatch `:169`, `.widgetAccentable()` `:176`.
- `chart` `:260-307`:
  - week: `BarMark` `.cornerRadius(3)`, future days at 0.35 opacity (`:264-268`); narrow weekday labels in the system font (`:269-273`)
  - month: cumulative `LineMark` `.stepEnd` (`:281-286`); dashed "Pace" line in `Color.secondary.opacity(0.6)` (`:287-294`); today `RuleMark` in `primary.opacity(0.2)` (`:295-296`); day labels in the system font (`:300-304`)
  - `.widgetAccentable()` `:275`, `:305`
- Gauges `:309-330`: `.accessoryCircularCapacity` and `.accessoryLinearCapacity` (system-drawn).
- `WidgetData.swift:42-44` `categoryColor` falls back to `.gray`. `BudgetStatus.isOver` is `remaining < 0` (`:89`).

## Target design

### Principles
- **Ink first (70/25/5):** data marks are `ink` at two densities. Shu marks only the current period, the selection and the 赤字 state. `kin` appears only as thin dashed reference lines. User category and brand colours stay, but only as marks (segments, swatches, coin fills, lines), never as row or card fills.
- **One filled shu shape per screen:** Breakdown tab = the hanko pointer; Trend tab = the current-period bar. Everything else in shu is a 1–3pt stroke (the hashira in `SectionLabel`, the legend selection rule).
- **Shapes:** radius 0 for marks, bars, progress and swatches; radius `AppRadius.card` (4) for cards (already true). No `Capsule` and no `.round` caps in chart code.
- **Glass:** only on controls: `YearMenu`/`DimensionMenu`, the Breakdown/Trend picker, the system segmented control and the nav bar. The dial disc and `StatsCard` become paper.
- **Motion:** no glow, no bounce, no spring overshoot. Data changes use `.smooth(duration: 0.25)`, the dial snap uses `.smooth(duration: 0.4)`, and the onboarding hint uses `.easeOut(duration: 0.7)`. Every one is `nil` under `accessibilityReduceMotion`. Dial inertia stays, because it is direct manipulation.

### Stats sheet layout (iPhone 17 Pro, 402pt; light shown, dark swaps tokens)
```
┌──────────────────────────────────────────┐
│                 Stats                (✕) │ nav bar: system glass, Fragment Mono
│ [2026 ⌃⌄]                [Categories ⌃⌄] │ MenuPicker .glassy (rect glass, r4)
│ ┌───────────────────┬──────────────────┐ │
│ │▒ ◔ Breakdown ▒▒▒▒▒│   ▥ Trend        │ │ CustomSegmentedPicker (unchanged)
│ └───────────────────┴──────────────────┘ │
│ You have 12 active expenses              │ bodyMedium, inkSecondary
│ ┌──────────────────────────────────────┐ │ paper card (paperRaised, 1pt rule, r4)
│ │▌OCTOBER 2026        [Monthly│Yearly] │ │ SectionLabel (3pt shu hashira) + system segmented
│ │                  ■                   │ │ hanko pointer: 8pt filled shu square, −3°
│ │            ━━━━━━━ ━━━━              │ │ ring: 16pt, butt caps, 4pt cuts,
│ │         ┃                  ┃         │ │   user colours, no glow, no glass disc
│ │         ┃   Entertainment  ┃         │ │ headlineMedium, ink
│ │         ┃  $930.00 · 69%   ┃         │ │ bodyMedium, inkSecondary
│ │            ━━━━ ━━━━━━━━━            │ │
│ └──────────────────────────────────────┘ │
│ ┌──────────────────────────────────────┐ │ legend card (insets 8)
│ │▌■ Entertainment         69%  $930.00 │ │ selected: 3pt shu left rule
│ │▌  ████████████████████░░░░░░░░░░░░   │ │ 2pt Rectangle; track = rule
│ │──────────────────────────────────────│ │ Rule() hairline
│ │ ■ Productivity          19%  $250.00 │ │ 8pt square swatch
│ │   █████░░░░░░░░░░░░░░░░░░░░░░░░░░░   │ │
│ └──────────────────────────────────────┘ │
│ ┌─────────────────┐ ┌──────────────────┐ │ StatsCard: paper + 1pt rule, r4
│ │YEARLY FORECAST  │ │AVERAGE MONTHLY   │ │ labelLarge (caps), inkSecondary
│ │$1,346.00        │ │$112.17           │ │ headlineLarge, ink
│ └─────────────────┘ └──────────────────┘ │
│ ┌──────────────────────────────────────┐ │
│ │ ▤  Create Chart Widget      ┌──────┐ │ │ badge: square, 1pt rule border
│ │                             │ SOON │ │ │
│ └──────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

Trend tab, top card (the line-chart card below follows the same rules):
```
│ │▌MONTHLY SPEND IN 2026 [same picker] │ │
│ │ 200 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ │ │ grid: 0.5pt ruleStrong, dash [1,3]
│ │ 150 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ BUDGET │ │ RuleMark: 1pt kin, dash [4,3]; label kinText
│ │ 100 ┄┄▌┄┄▌┄┄▌┄┄▌┄┄▌┄┄▌┄┄▌┄┄▌┄┄█┄┄▌┄ │ │ bars: ink @0.45, current month shu @1,
│ │  50   ▌  ▌  ▌  ▌  ▌  ▌  ▌  ▌  █  ▌  │ │   cornerRadius 0, width .ratio(0.5)
│ │       J  F  M  A  M  J  J  A  S  O  │ │ x + y labels: labelMedium (Fragment Mono)
```

### Component specs
| Surface | Current | Target |
|---|---|---|
| Card headers | `.titleSmall` `.secondary` | `SectionLabel(title)` (hashira + `.labelLarge` caps, `inkSecondary`); the "By expense in …" header too |
| `SpendDial` ring | round caps, 24pt gap (visual ≈ 8pt), glow, glass disc | `lineCap: .butt`, `gapPoints` 4 (visual cut = 4pt), no glow, no disc. `ringWidth` 16 unchanged (hit area, label padding) |
| `SpendDial` pointer | white `Triangle` | `Rectangle().fill(Color.shu)`, 8×8, `.rotationEffect(.degrees(-3))`, same offset. The tab's one filled shu shape |
| `SpendDial` label | `.primary` / `.secondary` | `Color.ink` / `Color.inkSecondary`; "•" → "·" |
| `SpendTrendChart` bars | user/budget colour, r4 | `Point.color` = `.shu` for the highlighted point, `.ink` otherwise; opacity rule unchanged (1 / 0.45); `.cornerRadius(0)`; `width: .ratio(0.5)` |
| Reference line | none | `RuleMark(y:)`, 1pt `kin`, dash [4,3], top-trailing annotation `BUDGET` or `AVG` in `.labelMedium` `kinText` |
| Grid | `primary.opacity(0.08)` solid | `AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [1, 3]))` `.foregroundStyle(Color.ruleStrong)`, Y only, 4 values |
| Axis labels | X mono, Y system | both `Text(...).typography(.labelMedium).foregroundStyle(Color.inkSecondary)`; Y as `.number.notation(.compactName)` |
| `ExpenseLineChart` | `.catmullRom`, 2pt round | `.interpolationMethod(.stepEnd)` (ledger steps; month values are piecewise constant), `StrokeStyle(lineWidth: 1.5, lineCap: .butt, lineJoin: .miter)`; same grid/labels as bars |
| Line legend | 8pt `Circle` chips | 8×8 `Rectangle` swatch + `.bodySmall` `inkSecondary` name |
| `StatsLegendList` row | circle, capsule, 12pt rounded fill | 44pt min height; 8×8 `Rectangle` swatch; `Rule()` between rows; 2pt `Rectangle` progress (track `Color.rule`, fill `item.color`); selected = 3pt shu `Rectangle` on the leading edge plus `.isSelected` trait; no fill |
| `StatsCard` | glass, r20 | `paperRaised` + 1pt `rule` border, r4; title `.labelLarge` `inkSecondary`; value `lineLimit(1)`, `minimumScaleFactor(0.6)` |
| "Coming soon" badge | `Capsule` fill | text `SOON` `.labelMedium` `inkSecondary`, `Rectangle().strokeBorder(Color.rule)`, no fill |
| `Coin` | metal coin, reeded edge, black stroke | mon coin: square hole knocked out of the top face, no reeding, `Color.ink` stroke, butt/miter; placeholder `Color.rule` |
| `CoinStack` | `.red` when over; white empty | over: all ten coins in their tint, stroke `Color.shu`, plus an `OVER` label (`.labelMedium`, `shu`) on top; empty slot `Color.rule`; no bounce |
| Widget ring/bars/line | round caps, r3, system labels | butt caps, r0, `mono(10)` labels, `kin` dashed pace, `ruleStrong` today rule, progress colour per tier |

**Light / dark values used above** (from `AppTheme.swift:52-63`)
| Token | Light (washi) | Dark (lacquer) | Chart use |
|---|---|---|---|
| `paperRaised` | #FFFFFC | #1C1816 | card ground |
| `ink` | #1E1A17 | #F4EFE6 | bars (0.45 / 1), labels, coin stroke |
| `inkSecondary` | #6B635C | #A8A096 | axis labels, secondary text |
| `rule` | #E2DCCF | #3A332E | row hairlines, progress track, empty coin |
| `ruleStrong` | #8C8378 | #746B63 | dotted grid, calm progress, widget today rule |
| `shu` | #C1352A | #E84A33 | current bar, pointer, selection rule, 赤字 |
| `kin` | #C9A13B | #D4A72C | dashed reference line (decoration; 2.4:1 in light, so never text) |
| `kinText` | #8A6B1F | #E6B422 | `BUDGET`/`AVG` label, near-budget progress |

### Category and series colours
- **User data stays.** Category and list `colorHex`, and expense brand colours in the line chart, are untouched. The default-palette swap for new installs belongs to the research file.
- **`fallbackPalette` (payment methods, rank-ordered) becomes a traditional-pigment set** taken from the research palette ([colordic](https://www.colordic.org/w)). It is ordered so that neighbours differ (adjacent ΔE76 ≥ 31). ΔE76 was computed against `shu` light #C1352A / dark #E84A33:

| # | Name | Hex | ΔE vs shu (L / D) | Contrast on `paperRaised` (L / D) |
|---|---|---|---|---|
| 0 | 縹 hanada | #2792C3 | 100 / 109 | 3.50 / 5.02 |
| 1 | 萌黄 moegi | #AACF53 | 93 / 94 | 1.78 / 9.87 |
| 2 | 菖蒲 ayame | #CC7EB1 | 59 / 66 | 2.92 / 6.03 |
| 3 | 青磁 seiji | #7EBEA5 | 92 / 97 | 2.14 / 8.22 |
| 4 | 藤紫 fujimurasaki | #A59ACA | 78 / 85 | 2.60 / 6.78 |
| 5 | 若竹 wakatake | #68BE8D | 98 / 103 | 2.24 / 7.84 |
| 6 | 鴇 toki | #F4B3C2 | 59 / 62 | 1.74 / 10.13 |
| 7 | 鼠 nezumi | #949495 | 70 / 77 | 3.03 / 5.81 |

- Every entry is at least ΔE 59 from shu, so no payment method reads as "deficit red". No entry is gold-adjacent except 萌黄 (ΔE 36 vs `kin`), which is acceptable because `kin` is only ever a dashed line.
- In light mode most entries are below 3:1. This is acceptable because colour is never the only cue (every slice and line has a text label in the legend and center label), but it is an open point (lightness clamp).
- `fallbackPalette[0]` is no longer used for trend bars; bars are ink.

### Budget status: options
Scale today: green → yellow → orange → #FF5900 → red (`BudgetColor.swift:7-17`).

**Findings that drive the choice**
- **Colourblindness:** the current #34C759 vs #FF3B30 under deuteranopia has contrast 1.24 and ΔE76 20.7 ([Machado](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html)). The existing scale already fails, so colour must not carry the state alone.
- **Brand clash:** shu is now the brand red (torii mark, CTA, Sundays). A red-means-bad scale makes every brand red read as a warning.
- **[WCAG 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color):** the state needs a non-colour cue: a word, a shape or a position.
- **Culture:** red is auspicious in Japan, and Japanese stock screens show *rising* prices in red ([RetireJapan](https://retirejapan.com/forum/viewtopic.php?p=12877)). A red total alone is ambiguous to a Japanese reader. The accounting idiom 赤字 / 黒字 is not ambiguous ([JGJE](https://www.tkgje.jp/entries/04500/04712_akaji.html)).

| | A. Ink density 黒字/赤字 (**recommended**) | B. Gold → vermilion ramp | C. Keep semantic green/red |
|---|---|---|---|
| Scale | <75% `ink`; 75–99% `ink` + `kinText` underline/progress + "LEFT" label; ≥100% `shu` + `HankoStamp` "赤字"/OVER | <50% ink, 50–75% `kin`, 75–99% `kinText`, ≥100% `shu` | today's 5 tiers |
| CVD | Safe: two hues only, and the over state also has a stamp and a word | Fails: light shu vs `kinText` under deuteranopia is **ΔE 0.4, contrast 1.01** (identical); dark ΔE 26.1, contrast 1.78 | Fails (contrast 1.24) |
| WCAG 1.4.1 | Met (stamp shape + "OVER"/"LEFT" words) | Needs labels added to every surface | Needs labels added |
| Brand fit | Red is reserved for one meaning (deficit); everything else is ink | Gold fills break "gold is a fleck, never a field" | Green/yellow/orange are outside the palette; red clashes with shu |
| JP reading | Native idiom (赤字 = deficit) | Neutral | Red = rising on stock screens, so ambiguous |
| Cost | One file + one component | One file + labels everywhere | Zero, but fails the redesign |

**Recommendation: A.** Thresholds keep the existing boundaries at 0.75 and 1.0; the 0.5 and 0.9 steps are merged away.

### `BudgetColor.swift` (exact rewrite; shared with the widget target)
```swift
import SwiftUI

/// Budget state on the Japanese ledger scale: 黒字 (black ink, within budget)
/// vs 赤字 (red ink, deficit). Colour is never the only cue: callers pair `.over`
/// with the word OVER or a `HankoStamp` (WCAG 1.4.1). Shared with the widget
/// target, so no app-only types here.
enum BudgetColor {
    /// none = no budget · calm < 75% · near 75–99% · over ≥ 100%
    enum Tier { case none, calm, near, over }

    static func tier(spent: Double, budget: Double?) -> Tier {
        guard let budget, budget > 0 else { return .none }
        switch spent / budget {
        case ..<0.75: return .calm
        case ..<1.0:  return .near
        default:      return .over
        }
    }

    /// Text/number tint: ink, or shu once over budget.
    static func color(spent: Double, budget: Double?) -> Color {
        tier(spent: spent, budget: budget) == .over ? .shu : .ink
    }

    /// Progress rule / ring / bar tint: ruleStrong → kinText → shu.
    static func progressColor(spent: Double, budget: Double?) -> Color {
        switch tier(spent: spent, budget: budget) {
        case .none, .calm: .ruleStrong
        case .near: .kinText
        case .over: .shu
        }
    }
}
```
- `color` and `tier` match price_display.md's contract exactly. `progressColor` is additive. `glowOpacity` is deleted.
- **Callers after this change:**
  1. `TotalViewModel.budgetTint` (`:35-37`): unchanged call; price_display.md adds `budgetTier`.
  2. `HomeViewModel.budgetTint` (`:39-41`): unchanged until home_screen_ux.md deletes it.
  3. `StatsViewModel.trendBarColor` (`:104-109`): deleted (step 4).
  4. `BudgetEditor` (`:22-40`): gradient deleted; the bar uses `progressColor` (step 15).
  5. `OnboardingBudgetHero` (`:14`): switches to `progressColor` (step 15).
  6. `WidgetViews.swift:110`: switches to `progressColor` (step 16).
- **Hardcoded reds:** `CoinStack.swift:52` (step 13), `WidgetViews.swift:151,203,230` (step 16; this doc is the single owner of widget colours), `BudgetDetailsSheet.swift:119,201` (step 15), `BudgetDetailsSheet.swift:82,88` (price_display.md step 11, the budget amount and its summary text), `:151`, `:154` (forms.md's `FormErrorLabel`), `BudgetEditor.swift:137` (price_display.md).

### `HankoStamp` (new, app-only): `LinguicaSubTracker/Core/UI/Motifs/HankoStamp.swift`
Contract (from general_app_ui.md §7): `HankoStamp(text: String = "赤字", accessibilityText: String = "Over budget", size: CGFloat = 28)`.
- A **square** of `size`×`size`, radius 0, with a **1.5pt `shu` border** (stroked, not filled, so it does not count as the screen's filled shu shape).
- Text is set in `AppFont.kanjiBold` (Hiragino Mincho W6) in `shu`. Fragment Mono has no CJK.
- **Rotated −3°**, opacity 0.9, `.multiply` blend in light mode only (ink soaked into washi), normal blend in dark mode.
- Labels: `"赤字"` (default) or `"OVER"`. Use **at most one per screen.** It is never placed in widgets (the font and Motifs are not in the widget target).
```swift
import SwiftUI

/// Square vermilion seal (朱肉) marking a deficit. Shape + word carry the
/// meaning (WCAG 1.4.1). At most one per screen. App-only.
struct HankoStamp: View {
    var text: String = "赤字"
    var accessibilityText: String = "Over budget"
    var size: CGFloat = 28
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text)
            .font(.custom(AppFont.kanjiBold, fixedSize: size * 0.36))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(Color.shu)
            .padding(3)
            .frame(width: size, height: size)
            .overlay(Rectangle().strokeBorder(Color.shu, lineWidth: 1.5))
            .rotationEffect(.degrees(-3))
            .opacity(0.9)
            .blendMode(scheme == .light ? .multiply : .normal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }
}
```
- **Consumers:** the Home total in `BudgetMark` (price_display.md). No chart surface uses it: the charts already show the over state through position (bar above the `BUDGET` line) or a word (`OVER` on coin piles, "Over by" in `BudgetEditor`). Home can show several piles at once, so a hanko on each pile would break the one-per-screen rule.

### Mon coin
```
 side view (512×512 space)           top face
   ╭──────────────╮                  ellipse (16,80,480,256)
  │    ┌──────┐    │ ← square hole:   rect (200,178,112,60) =
  │    └──────┘    │   112 wide, 112·(256/480) ≈ 60 tall (a square in perspective)
  ├╮              ╭┤ ← body sides, no reeding lines
   ╰──────────────╯
```
- Real 寛永通宝 holes are about 1/4 of the diameter; 112/480 ≈ 0.23.
- The hole is **knocked out** (`.blendMode(.destinationOut)` inside `.compositingGroup()`), so the coin below shows through in a pile. Its outline is stroked in the coin's stroke colour.

### Widgets
- `WidgetRing`: track `Color.rule`; paid and scheduled arcs `lineCap: .butt`; colour = `BudgetColor.progressColor`. The ring is ruleStrong when calm, kinText when near, shu when over; the "left"/"over" text beside it carries the word. Keep `.widgetAccentable()`.
- Week bars: `.cornerRadius(0)`, future days at 0.35 opacity (kept).
- Month line: `.stepEnd` kept, `lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .butt))`. Pace line: `Color.kin`, `StrokeStyle(lineWidth: 1, dash: [4, 3])`. Today `RuleMark`: `Color.ruleStrong`, `lineWidth: 0.5`.
- Axis labels: add `.font(mono(10))` and `.foregroundStyle(Color.inkSecondary)` to both `AxisValueLabel`s.
- Over text `.red` becomes `Color.shu`. The word "over"/"Over" is already present.
- Category swatch: `Circle` becomes a 6×6 `Rectangle`.
- Gauges stay system-drawn (`.accessoryCircularCapacity` / `.accessoryLinearCapacity`).
- The today marker belongs to `calendar.md` (the foundation's shu square stroke at `:405-408` becomes the ensō there).

## Implementation steps
1. **Verify the foundation (no edits).**
   - Already done by the foundation pass (verify):
     - tokens at `AppTheme.swift:52-63`
     - `AppFont.kanjiBold == "HiraMinProN-W6"` (`:69`)
     - `GlassSection` paper card (`GlassSection.swift:15-19`)
     - `MenuPicker` `.glassy` rect glass (`MenuPicker.swift:57`)
     - `CustomSegmentedPicker` rect glass highlight (`CustomSegmentedPicker.swift:40-43`)
     - widget `mono(_:)` (`WidgetViews.swift:8-10`) and `WidgetBackdrop` (`:610-614`)
   - `grep -rn "\.weight(" LinguicaSubTracker/Features/Stats` returns nothing.

2. **`BudgetColor.swift`.**
   - Replace the whole file with the rewrite in Target design.
   - If price_display.md already added `Tier`/`tier`, keep them; they are identical. Add `progressColor` and delete `glowOpacity`.
   - Add `LinguicaSubTrackerTests/BudgetColorTests.swift` (new; `import Testing` and `@testable import LinguicaSubTracker`, inside a `@Suite("Budget tiers") struct`):
     ```swift
     @Test func tiers() {
         #expect(BudgetColor.tier(spent: 10, budget: nil) == BudgetColor.Tier.none)
         #expect(BudgetColor.tier(spent: 10, budget: 0) == BudgetColor.Tier.none)
         #expect(BudgetColor.tier(spent: 74.9, budget: 100) == .calm)
         #expect(BudgetColor.tier(spent: 75, budget: 100) == .near)
         #expect(BudgetColor.tier(spent: 99.9, budget: 100) == .near)
         #expect(BudgetColor.tier(spent: 100, budget: 100) == .over)
     }
     ```
   - Confirm the file joined the test target (the test folder is synchronized like the app folder; check the target membership in Xcode if the test is not discovered).

3. **`HankoStamp`.** Create `LinguicaSubTracker/Core/UI/Motifs/HankoStamp.swift` (new) with the code in Target design. App target only. Do **not** add it to the widget exception set in `project.pbxproj`.

4. **`StatsViewModel.swift`.**
   - `:21-24`: replace the hexes with `"#2792C3", "#AACF53", "#CC7EB1", "#7EBEA5", "#A59ACA", "#68BE8D", "#F4B3C2", "#949495"`, in that order. Add the comment `// Traditional pigments (colordic), rank-ordered; ≥ ΔE 59 from shu.`
   - Delete `trendBarColor` (`:103-109`).
   - `:118`: `color: entry.month == highlightMonth ? .shu : .ink`.
   - `:132`: `color: entry.year == currentYear ? .shu : .ink`, and delete the comment at `:130`.
   - Add the reference line after `yearlyTrendPoints`:
     ```swift
     /// Dashed kin line on the trend chart: the monthly budget in monthly scale
     /// when one is set, otherwise the average of the plotted bars.
     var trendReference: (label: String, value: Double)? {
         if scale == .monthly, let budget = settingsStore.effectiveBudget, budget > 0 {
             return ("Budget", budget)
         }
         let values = (scale == .monthly ? monthlyTrendPoints : yearlyTrendPoints).map(\.value)
         let nonZero = values.filter { $0 > 0 }
         guard !nonZero.isEmpty else { return nil }
         return ("Avg", nonZero.reduce(0, +) / Double(nonZero.count))
     }
     ```
   - Do not touch `items`, `selectedItem`, `expenseLineSeries` (top 6), `color(for:)` logic or any label math.

5. **`SpendTrendChart.swift`.**
   - Add `var reference: (label: String, value: Double)? = nil` after `abbreviateLabels` (`:17`), and `@Environment(\.accessibilityReduceMotion) private var reduceMotion`.
   - Replace `:22-29`:
     ```swift
     BarMark(x: .value("Period", point.label), y: .value("Amount", point.value), width: .ratio(0.5))
         .foregroundStyle(point.color.opacity(point.highlighted ? 1 : 0.45))
         .cornerRadius(0)
     ```
   - After the `ForEach` (`:30`), inside `Chart`:
     ```swift
     if let reference {
         RuleMark(y: .value(reference.label, reference.value))
             .foregroundStyle(Color.kin)
             .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
             .annotation(position: .top, alignment: .trailing) {
                 Text(reference.label).typography(.labelMedium).foregroundStyle(Color.kinText)
             }
     }
     ```
   - `:38`: `.foregroundStyle(Color.inkSecondary)`.
   - Replace the Y axis `:43-49`:
     ```swift
     .chartYAxis {
         AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
             AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [1, 3]))
                 .foregroundStyle(Color.ruleStrong)
             AxisValueLabel {
                 if let v = value.as(Double.self) {
                     Text(v, format: .number.notation(.compactName))
                         .typography(.labelMedium)
                         .foregroundStyle(Color.inkSecondary)
                 }
             }
         }
     }
     ```
   - `:50`: `.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: points)`.
   - Preview `:62`: `color: idx == 6 ? .shu : .ink`.
   - `StatsSheet.swift:155-160`: pass `reference: viewModel.trendReference`.

6. **`ExpenseLineChart.swift`.**
   - `:36-37`: `.interpolationMethod(.stepEnd)` and `.lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .butt, lineJoin: .miter))`.
   - `:47`: `.foregroundStyle(Color.inkSecondary)`.
   - Replace `:52-58` with the same Y axis as step 5.
   - `:59`: Reduce-Motion-gated `.smooth(duration: 0.25)` (add the same `@Environment`).
   - `:67-69`: `Rectangle().fill(line.color).frame(width: 8, height: 8)`.
   - `:72`: `.foregroundStyle(Color.inkSecondary)`.
   - Update the doc comment `:4-5` to "Legend swatches underneath."

7. **`SpendDial.swift`.**
   - `:21`: `gapPoints: CGFloat = 4`.
   - Delete `glowColor` (`:46`) and the glow (`:49-57`).
   - Delete the glass disc (`:59-61`).
   - `:76`: `lineCap: .butt`.
   - `:87-90`: replace with
     ```swift
     Rectangle()
         .fill(Color.shu)
         .frame(width: 8, height: 8)
         .rotationEffect(.degrees(-3))
         .offset(y: -(size / 2 + 8))
         .accessibilityHidden(true)
     ```
   - Delete `Triangle` (`:284-293`).
   - `:228`: `let approxGapFraction = 0.006` and update its comment to `// ≈ 4pt / 105pt radius at the 250pt sheet frame (2.2°)`. It must stay ≈ the drawn gap; recompute it if `gapPoints`, `ringWidth` or the 250pt frame change.
   - Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion`.
   - In `onAppear` (`:112-119`): run the hint only when `hintRotationOnAppear && !reduceMotion`, with `withAnimation(.easeOut(duration: 0.7).delay(0.35))`.
   - `:261`: `withAnimation(reduceMotion ? nil : .smooth(duration: 0.4))`.
   - `:132`: `.foregroundStyle(Color.ink)`; `:139`: `Text("·")`; `:143`, `:148`: `.foregroundStyle(Color.inkSecondary)`.
   - Preview `:323`: `.background(Color.paper)`.
   - Leave untouched: the drag `:153-186`, decay `:189-209`, `topFraction`, `segmentIndexAtTop`'s loop, `updateSelection` (haptic `:278`), `onChange` handlers, and `RingHitShape`.

8. **`StatsLegendList.swift`.**
   - `:12`: `VStack(spacing: 0)`. Insert `if item.id != items.first?.id { Rule() }` before each `legendRow` in the `ForEach`.
   - `:18`: `.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: items)` (add the environment value).
   - `:26`: `withAnimation(reduceMotion ? nil : .smooth(duration: 0.25))`.
   - `:32-34`: `Rectangle().fill(item.color).frame(width: 8, height: 8)`.
   - `:38`, `:49`: `Color.ink`; `:45`: `Color.inkSecondary`.
   - Replace the progress `:52-61`:
     ```swift
     GeometryReader { geo in
         ZStack(alignment: .leading) {
             Rectangle().fill(Color.rule)
             Rectangle().fill(item.color).frame(width: geo.size.width * fraction)
         }
     }
     .frame(height: 2)
     ```
   - Replace `:63-69`:
     ```swift
     .padding(.horizontal, 12)
     .padding(.vertical, 10)
     .frame(minHeight: 44)
     .overlay(alignment: .leading) {
         if isSelected { Rectangle().fill(Color.shu).frame(width: 3) }
     }
     .contentShape(Rectangle())
     ```
   - After `.buttonStyle(.plain)` (`:71`): `.accessibilityAddTraits(isSelected ? .isSelected : [])`.
   - Update the doc comment `:3` to "square swatch + label + amount + 2pt share rule".

9. **`StatsCard.swift`** (`:9-13`, `:16`, `:21-23`; price_display.md owns `:17-19`).
   - `:10-11`: `.typography(.labelLarge)` and `.foregroundStyle(Color.inkSecondary)`.
   - After `:16`: `.lineLimit(1)` and `.minimumScaleFactor(0.6)`.
   - Replace `:23`:
     ```swift
     .background(Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))
     .overlay(RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(Color.rule, lineWidth: 1))
     ```

10. **`StatsSheet.swift`.**
    - `scaleHeader` `:20-23` becomes `SectionLabel(title)`. Keep `.contentTransition(.opacity)` on it and keep the `Spacer` and `AppPicker`.
    - `:168-170` becomes `SectionLabel("By expense in \(String(vm.year))")`.
    - Badge `:71-76`:
      ```swift
      Text("Soon")
          .typography(.labelMedium)
          .foregroundStyle(Color.inkSecondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .overlay(Rectangle().strokeBorder(Color.rule, lineWidth: 1))
      ```
    - `:62`, `:67`, `:98`, `:101`, `:108`: `.secondary` becomes `Color.inkSecondary` (and drop `weight: .semibold` from `iconStyle` at `:98`, `:101`).
    - `:142`, `:178`: `.transition(.opacity)`.
    - `:195-198`: add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to `StatsSheet` and use `reduceMotion ? nil : .smooth(duration: 0.25)` for all four.
    - `StatsSheetPreviewHost.swift:8`: `Color.paper.ignoresSafeArea()`.

11. **Menus.** `YearMenu.swift:21`, `DimensionMenu.swift:20`: `.background(Color.paper)`. There are no other edits; the glass style is already done (step 1).

12. **`Coin.swift` (mon coin).**
    - Delete the reeding lines `:54-68` (the comment line and the five `move`/`addLine` pairs).
    - Add below `CoinShape`:
      ```swift
      /// Square hole of a mon coin (寛永通宝) on the top face, in CoinShape's 512 space.
      struct MonHole: Shape {
          func path(in rect: CGRect) -> Path {
              Path(CGRect(x: 200, y: 178, width: 112, height: 60))
                  .applying(CGAffineTransform(scaleX: rect.width / 512, y: rect.height / 512))
          }
      }
      ```
    - `:84`: `var fill: (any ShapeStyle)? = nil`. `:86`: `var stroke: any ShapeStyle = Color.ink`. `:98`: `AnyShapeStyle(Color.rule)`.
    - Replace the `ZStack` `:101-114`:
      ```swift
      ZStack {
          CoinShape(forFill: true).fill(resolvedFill)
          MonHole().fill(.black).blendMode(.destinationOut)
          let style = StrokeStyle(lineWidth: 16 * scale, lineCap: .butt, lineJoin: .miter)
          CoinShape(forFill: false).stroke(AnyShapeStyle(stroke), style: style)
          MonHole().stroke(AnyShapeStyle(stroke), style: style)
      }
      .compositingGroup()
      ```
      Keep `.rotationEffect` `:115` and the aspect ratio.
    - Preview: `:141` becomes `.background(Color.paper)`; replace the `LinearGradient` variant with `Coin(fill: Color(hex: "#2792C3"))`.

13. **`CoinStack.swift`.**
    - `color(at:filled:)` `:51-54`:
      ```swift
      private func color(at index: Int, filled: Int) -> Color {
          if isOverBudget { return tint }                // pile full; the shu stroke + OVER mark it
          return index < filled ? tint : Color.rule
      }
      ```
    - Give `DroppingCoin` a `let stroke: Color` and pass `Coin(fill: color, stroke: stroke, rotation: 0)` (`:140`).
    - In `CoinStack.body` pass `stroke: isOverBudget ? Color.shu : Color.ink`.
    - On the `VStack`, after its closing brace (`:42`) and before `.contentShape` (`:43`):
      ```swift
      .overlay(alignment: .top) {
          if isOverBudget {
              Text("Over").typography(.labelMedium).foregroundStyle(Color.shu).offset(y: -16)
          }
      }
      ```
    - `accessibilitySummary` `:58`: append `isOverBudget ? ", over budget" : ""`.
    - **No bounce:** delete the four bounce `CubicKeyframe`s `:165-188`. Keep the hold and the fall (`:155-164`). Keep `CoinDrop` and its tests unchanged (see Open points).
    - Update the doc comments at `:3-6` ("goes fully red" becomes "outlined in shu with an OVER mark") and `:87` ("Metal coin…" becomes "Coin landing on paper.").
    - Replace `#Preview` `:195-197`:
      ```swift
      #Preview {
          HStack(alignment: .bottom, spacing: 20) {
              CoinStack(spent: 40, budget: 100, tint: Color(hex: "#2792C3"))
              CoinStack(spent: 120, budget: 100, tint: Color(hex: "#CC7EB1"))
              CoinStack(spent: 0, budget: 100, tint: Color(hex: "#68BE8D"))
          }
          .padding(40)
          .appBackground()
      }
      ```

14. **`CoinProgress` (dead after price_display.md step 9).**
    - Check `grep -rn "CoinProgress(" LinguicaSubTracker --include='*.swift'` lists only `CoinProgressPreviewHost.swift`.
    - If so, delete `Views/CoinProgress.swift` and `Previews/CoinProgressPreviewHost.swift`.
    - Keep `CoinProgressViewModel.swift` unchanged: `filledCoinCount` drives `CoinStack`, and `coins`/`allocate` are pinned by `CoinProgressAllocationTests` (including its `Color.white` expectations).
    - In the execution order this doc runs **before** price_display.md, so the check normally still finds `TotalView.swift`. Skip the step then; price_display.md step 9 ends by running this step once its `TotalView` rewrite removes the last caller. Until then `CoinProgress` picks up the `Coin` restyle automatically.
    - Do not restyle the `TotalView` share bar (`:150-199`); price_display.md deletes it.

15. **Budget surfaces in Settings and onboarding.**
    - `BudgetEditor.swift`:
      - Delete `progressGradient` (`:22-32`).
      - `bugdetIndicator` `:96`: default `height: CGFloat = 4`.
      - `:101-117`: `Rectangle()`s; the track is `.fill(Color.rule)` and the fill is `.fill(BudgetColor.progressColor(spent: viewModel.monthlyTotal, budget: settingsStore.effectiveBudget))`.
      - `:111-117`: `.animation(.smooth(duration: 0.25), value: vm.ratio)`.
      - `progressColor` (`:35-40`, text tint) stays as is. `:137` belongs to price_display.md.
    - `BudgetDetailsSheet.swift`:
      - `:82`, `:88` (`.red` → `Color.shu`) belong to price_display.md step 11. Do not edit them here.
      - `allocationBar` `:115-121`: `Rectangle()`s, track `Color.rule`, fill `vm.isOverAllocated ? (vm.isStrict ? Color.shu : Color.kinText) : Color.ink`; `:124` height 4.
      - `:198-202`: `Text("\(vm.formatted(spend)) spent" + (vm.isOverspent(category.name, spend: spend) ? " · over" : ""))` with `.foregroundStyle(vm.isOverspent(...) ? Color.shu : Color.inkSecondary)`.
      - `:190-192`: `Rectangle()` 8×8 swatch.
    - `OnboardingBudgetHero.swift:14`: `let color = BudgetColor.progressColor(spent: ratio, budget: 1)`. The steps `[0, 0.2, 0.9]` now demo ruleStrong → kinText. The rest of the onboarding restyle is deferred by the plan.

16. **Widgets (`SatoruWidgets/WidgetViews.swift`).**
    - `:23`: `Circle().stroke(Color.rule, lineWidth: lineWidth)`. `:26`, `:30`: `lineCap: .butt`.
    - `:110`: `BudgetColor.progressColor(spent: status.total, budget: status.budget)`.
    - `:151`, `:203`: `.foregroundStyle(status.isOver ? Color.shu : Color.ink)`. `:230`: `tint: status.isOver ? Color.shu : nil`.
    - `:169`: `Rectangle().fill(snapshot.categoryColor(category.name)).frame(width: 6, height: 6)`.
    - `:267`: `.cornerRadius(0)`. `:271`: append `.font(mono(10)).foregroundStyle(Color.inkSecondary)`.
    - `:286`: add `.lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .butt))`.
    - `:291-292`: `.foregroundStyle(Color.kin)` and `.lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))`.
    - `:296`: `.foregroundStyle(Color.ruleStrong).lineStyle(StrokeStyle(lineWidth: 0.5))`.
    - `:302`: append `.font(mono(10)).foregroundStyle(Color.inkSecondary)`.
    - Leave the gauges `:309-330`, every `.widgetAccentable()` and the calendar section (calendar.md) untouched.
    - `SatoruWidgets/WidgetData.swift:43`: `?? .gray` becomes `?? Color.inkSecondary`.

17. **Sweep and build.**
    - `grep -rnE "cornerRadius\((3|4)\)|catmullRom|lineCap: \.round|RadialGradient|Capsule\(\)|Color\.white|\.red([^A-Za-z]|$)" LinguicaSubTracker/Features/Stats LinguicaSubTracker/Core/Components/CoinProgress/Views SatoruWidgets/WidgetViews.swift` returns nothing. `CoinProgressViewModel.swift` is out of the path on purpose.
    - Build and test with the commands under Verification.

## Preserve
- **Dial behaviour:**
  - two-way `selectedID` sync between dial and legend
  - `rotateToSegment`'s early return when the segment is already on top (no fight with the drag)
  - drag on the ring band only (`RingHitShape`, `ringWidth + 16`)
  - inertia (60 Hz timer, ×0.975, 220°/s threshold, stop at 2°/s)
  - the light haptic on segment change
  - reset on `items` change
  - `hintRotationOnAppear` for onboarding
  - `approxGapFraction` updated with the gap
- **Trend data:** the `highlighted` opacity rule (1 vs 0.45), `abbreviateLabels` first-letter labels, monthly/yearly point math, `highlightMonth`, and the yearly series over `yearOptions`.
- **Line chart:** top-6 `expenseLineSeries`, brand colours, 12 values per series.
- **View-model math:** `items` ordering, `total`, `selectedAmountLabel`/`selectedPercentLabel`, `forecastLabel`, `averageMonthlyLabel` (`monthsRemaining`), `breakdownTitle`, `referenceMonth`, `activeCountLabel`.
- **User colours:** category and list `colorHex` and expense brand colours. Only the fallback palette changes.
- **Coins:**
  - `CoinProgressViewModel.allocate`/`filledCoinCount`/`coins` and their tests (`CoinProgressAllocationTests`, `BudgetSplitTests.swift:59-69`, `CoinDropTests`)
  - `CoinEntrance.claim()` once per launch (`HomeListView.swift:173`)
  - the Reduce Motion guards in `DroppingCoin` (`:126`, `:144`) and `CoinProgress` (`:92`, if kept)
  - the accessibility summaries/actions in `CoinStack` (`:45-48`)
  - the tap → `BudgetDetailsSheet` action
- **Widgets:** every `.widgetAccentable()` (ring `:33`, `Dots` `:53`, category bars `:176`, charts `:275`, `:305`, today marker `:407`); the paid-solid / scheduled-0.35 ring split; the "Pace" dashed line; the today `RuleMark`; the gauge styles; `BudgetStatus` math.
- **Contracts:** the `BudgetColor.color(spent:budget:)` signature, and `Tier`/`tier(spent:budget:)` exactly as price_display.md codes against them.
- **DEBUG hooks:** `DEBUG_OPEN_SHEET=budget` (`HomeListView.swift:59-64`), `DEBUG_HOME_VIEW`, `DEBUG_WIDGET_GALLERY`, `DEBUG_MONTH_INDEX`.
- **Accessibility:** the dial center label is not hit-testable; legend rows stay `Button`s. Add `.isSelected` on legend rows (new).

## Risks / gotchas
- **Widget target sharing:** `BudgetColor.swift` compiles into `SatoruWidgetsExtension` (`project.pbxproj:92`). Use only `Color` tokens from `AppTheme.swift` (shared at `:91`); never `AppTypography`, `HankoStamp` or `Theme`. `HankoStamp` and `Core/UI/Motifs/` are app-only.
- **Tier vs widget `isOver`:** at exactly 100%, `BudgetColor.tier` is `.over` (the ring turns shu) while `BudgetStatus.isOver` (`WidgetData.swift:89`) is false (the text says "$0.00 left" in ink). This mirrors today's behaviour (`default: .red` at ratio 1.0). Leave it.
- **`approxGapFraction` is radius-blind:** 0.006 matches the 250pt Stats frame. Onboarding uses 260pt (`OnboardingStatsHero.swift:22`), about 2% different, which is harmless. If the gap is ever made much larger than the constant, the pointer can sit over a visible gap and still select a segment.
- **Butt caps change the visual gap:** round caps used to eat 16pt of the 24pt gap. With butt caps the full `gapPoints` shows, which is why it drops to 4. Slices shorter than the gap are skipped by the `trimEnd > trimStart` guard (`:71`). At 4pt that hides far fewer slices than the 24pt gap does today.
- **`destinationOut` needs `.compositingGroup()`.** Without it the hole punches through to the card. It is not a `layerEffect` shader, so the materials-render-black issue does not apply, but verify inside `OnboardingView`'s `.liquidRipple` page if coins ever appear in onboarding.
- **Glass disc removal fixes onboarding:** `OnboardingStatsHero` sits under `.liquidRipple` (`OnboardingView.swift:30`), a `layerEffect` that renders `glassEffect` black. Deleting `SpendDial.swift:59-61` removes that conflict.
- **Mono width:** `StatsCard` values at 24pt need about 14.8pt per character ("$12,345.67" ≈ 148pt in a ≈147pt column on 402pt), hence `minimumScaleFactor(0.6)`. Y-axis labels with `labelMedium` tracking 1.2 are wider than the system labels; `.compactName` keeps them to 4 characters.
- **One filled shu shape per screen:** Breakdown = pointer; Trend = current bar. Do not also fill the selected legend row or make the segmented picker's selection shu.
- **`SectionLabel` is uppercase** (`labelLarge`). "October 2026" renders "OCTOBER 2026", which is intended. `.contentTransition(.opacity)` still works on its `Text`.
- **Shared files:** `StatsCard.swift:17-19` (price_display.md), `HomeListView.swift:155-161` labels (list_view.md), `BudgetEditor.swift:137` (price_display.md), `TotalView.swift` (price_display.md), `HomeToolbar.swift` (home_screen_ux.md), the widget calendar section and today marker (calendar.md). Edit only the lines named here.
- **general_app_ui.md vs code:** general_app_ui.md §9 lists `glowOpacity` at `BudgetColor.swift:19-24` and names 6 callers. Both still hold. Its sweep list cites `BudgetEditor.swift:136` for "Over by"; the `.red` is actually on `:137`.
- **Gauges** are system-drawn; on the Lock Screen they render monochrome and ignore tokens. That is expected.

## Verification
- **Build:** `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build`. This builds the widget extension too, which proves `BudgetColor.swift` still compiles there.
- **Tests:** the same command with `test`. `BudgetColorTests` (new), `CoinProgressAllocationTests`, `BudgetSplitTests`, `CoinDropTests`, `WidgetLogicTests` and `ThemeFontTests` all pass.
- **Grep:** the step 17 sweep is empty; `grep -rn "glowOpacity" LinguicaSubTracker SatoruWidgets` matches nothing in `BudgetColor.swift`.
- **Stats sheet** (no DEBUG hook): launch, tap the Home total (the simulator `control` tool's taps register), then screenshot Breakdown and Trend in light and dark. Alternatively use the `StatsSheetPreviewHost` preview. Check:
  - no glow and no glass disc; butt segments with 4pt cuts; a shu square pointer
  - drag spins with inertia, the haptic fires, the legend selection follows
  - tapping a legend row rotates the dial without a fight
  - bars are ink and the current month is shu; the dashed kin `BUDGET` line appears with a budget set, `AVG` without
  - dotted grid; mono labels on both axes; step lines with square swatches
  - Reduce Motion on: no hint spin, instant snaps
- **List mode coins:** `SIMCTL_CHILD_DEBUG_HOME_VIEW=list`. Mon coins with square holes and `rule` empties. An over-budget category shows a shu outline + "OVER". The drop plays once per launch (switch views and back: no replay) and lands without bouncing.
- **Budget sheet:** `SIMCTL_CHILD_DEBUG_HOME_VIEW=list SIMCTL_CHILD_DEBUG_OPEN_SHEET=budget`. The allocation bar is a 4pt rule; over-allocation shows shu plus the warning text.
- **Widgets:** `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=week`, `month`, `week-dark`, `month-dark` (add `live-` for real data). Check butt ring caps, square bars, dashed kin pace, mono axis labels, and "over" in shu.
- **Tiers:** set a budget below, at ~80% of, and above the month total. Expect ruleStrong / kinText / shu progress in `BudgetEditor` and the widget ring.

## Open points / dig deeper
- **Hanko wording:** research 赤字 alone vs OVER alone vs both for non-Japanese users. Red reads as "rising" on JP stock screens, so check how Japanese users read the stamp and a red total. This decides the `HankoStamp` default `text`.
- **CVD on device:** check the 28pt hanko, the `kinText` progress and the shu current bar under the Settings → Accessibility colour filters (deuteranopia, protanopia) at small sizes. The numbers above are simulations.
- **Light-mode pigment contrast:** 5 of the 8 fallback pigments are below 3:1 on `paperRaised` light (1.74–2.92). Prototype the research's per-mode OKLCH lightness clamp (light L ≤ 0.62, dark L ≥ 0.55), applied to any user hex in `color(for:)` and `DialItem`, to see whether it is worth one function.
- **Payment-method colours:** payment methods have no `colorHex`, so they always use the fallback palette by rank, and a method's colour changes when the ranking changes. Research whether `AppSettings` should store a colour per method (optional field, lenient decoding).
- **`destinationOut` hole:** verify the knock-out renders correctly in the stacked pile on device and in the widget gallery (if coins are ever shared there), and measure its cost with 10 coins × N categories while scrolling.
- **Coin bounce helpers:** after the no-bounce landing is accepted, decide whether to delete `CoinDrop.bounceHeight/bounceSpeed/bounceRise` and their two tests (`CoinDropTests` `bounceDecay`, `selfConsistency`). They are kept now only to avoid touching tests.
- **`BarMark(width: .ratio(0.5))` and `AxisValueLabel(...).font(_:)`:** both are expected Swift Charts API (iOS 16+). Verify on device that the ratio width and the custom font apply in WidgetKit's rendering (vibrant/accented modes may force system fonts).
- **Ensō behind the dial:** consider drawing calendar.md's `EnsoShape` faintly behind the ring (or trimming it to spent ÷ budget) once that component exists. It needs a performance check while the inertia timer writes `@State` 60×/s.
- **Hanko texture:** v1 is a clean square. Research uneven edges / kasure (a static mask image, no shader) if the stamp reads too digital.
- **Trend reference in yearly scale:** today it shows the average year. Decide whether a yearly budget line (monthly budget × 12) is more useful.
- **Restyle `CoinProgress` instead of deleting:** only if a product use returns. It would need its `coins` placeholder changed to `nil` (and the 4 `Color.white` test expectations updated).

**Status: proposed, not implemented.**
