# List View — Japanese notebook

## Goal
Make every expense list look like a page of a Japanese notebook (Kokuyo Campus, Hobonichi, Midori MD). Rows sit directly on flat paper and are separated by ruled hairlines on a 44pt pitch. A vermilion margin rule runs down the page, day headers sit on a thicker rule, and prices are written in a right-aligned Fragment Mono ink column. This doc covers four surfaces:
- Home list mode (`HomeListView`)
- Home rows (`HomeExpenseRow`, which this doc deletes)
- Search rows (`ExpenseRow`, plus its status badge, payment icon, selection mode, `SortChip` and bulk bar)
- `ExpensesInDay` sheet rows

All three row types are merged into one notebook `ExpenseRow`.

**Depends on:**
- `general_app_ui.md`: **already implemented in the working tree** (uncommitted). It provides the tokens (`LinguicaSubTracker/Core/Utils/AppTheme.swift:52-63`), `AppFont.mono` / `AppFont.kanji` (`:66-70`), `AppRadius.card` = 4 (`:72-75`), flat `.appBackground()` (`:77-88`), `GlassSection` as a paper card (`LinguicaSubTracker/Core/UI/Containers/GlassSection.swift:15-19`), `Rule` (`LinguicaSubTracker/Core/UI/Motifs/Torii.swift:57-69`), the `AppButton` colour mapping, the squared `SortChip`, and Fragment Mono through `.typography()` with all `.weight(…)` chains removed.
- `price_display.md`: the single `MoneyFormatter` path, the "CAD" fix, and `MoneyDisplay`.
- `charts.md`: `CoinStack` styling.
- `calendar.md` (runs immediately after the foundation): `EnsoShape`, `LogoCircle(glass:)`, the shared Home month header, and the existing day-sheet presentation. This doc reuses those interfaces; the calendar provides no holiday or Japanese date table.
- `home_screen_ux.md`: the toolbar and how list mode is switched on.

**References:**
- Notebook rulings and marks:
  - [Kokuyo Campus Basic](https://www.kokuyo.com/en/stationery/series/campus/campus-notebook/basic): rulings and the counting mark every 5 lines
  - [Kokuyo dot ruled](https://www.kokuyo.com/en/stationery/category/notebook-paper/notebook/10591): dots on the rule as column guides
  - [Kokuyo Store NO-201U](https://kokuyostore.com/en_FR/campus-notebook-notebook-a4-brown-wide-horizontal-ruled-40-sheets/NO-201U.html): a thicker 3rd line for title or date
  - [1101.com Hobonichi spec](https://www.1101.com/store/techo/en/2027/pc/detail_cover/ob27_jan_en/)
  - [Mountain of Ink, Midori MD](https://mountainofink.com/blog/midori-md-notebook): tick dots every 5 squares
  - [tkgje genkō yōshi](https://www.tkgje.jp/entries/15500/15790_genkouyoushi.html)
- Fonts: [Apple, Applying custom fonts](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text) (no synthesized bold, `relativeTo:`) and the [iOS font list gist](https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9) (`HiraMinProN-W3`).
- [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials): no glass in the content layer.
- [WCAG 1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color).

## Current state
Paths are repo-relative. App sources are in `LinguicaSubTracker/`. All line numbers are from the current working tree (foundation already applied).

**Home list mode.** `LinguicaSubTracker/Features/Home/Views/HomeView.swift:55-61` mounts `HomeListView` when `viewType == .list`. `.appBackground()`, now flat `paper`, is applied at `HomeView.swift:64`.
- **Body** (`LinguicaSubTracker/Features/Home/Views/Components/HomeListView.swift:48-66`): `VStack(spacing: 12) { summaryBlock; listBlock }`. `.padding(.horizontal, 16)` at `:54` applies to both blocks. The `DEBUG_OPEN_SHEET=budget` hook is at `:59-64`.
- **`summaryBlock`** (`:70-96`): `MoneyDisplay(size: 40, onTapGesture: onStats)` at `:72-77`. Below it, either `categoryStacks` or `budgetCTA` (`:82-86`). There is a spring animation on `hasBudget` at `:90`.
- **`budgetCTA`** (`:99-138`):
  - a `GlassSection`, already a paper card: `paperRaised` + 1pt `rule`, radius `AppRadius.card` (`GlassSection.swift:15-19`); text and icon still use system `.primary`/`.secondary` (`:104`, `:108`, `:111`)
  - "Set budget": `AppButton .neutral/.glassy` (`:116-123`)
  - "Not now" writes `@AppStorage("budget_cta_dismissed")` (`:17`, `:130`)
  - a scale+opacity transition at `:137`
- **`categoryStacks`** (`:142-174`):
  - `CoinStack` piles (`:147-154`)
  - the amount below each pile is painted in **category colour** (`:155-157`), with the name below it (`:158-161`)
  - `CoinEntrance.claim()` at `:173`
- **`listBlock`** (`:178-210`):
  - `GlassSection` → `ScrollView` → `LazyVStack(spacing: 0)` → `Section` per day from `days` (`:41-46`, `ExpenseService.occurrencesByDay`, `LinguicaSubTracker/Core/Services/ExpenseService.swift:283`)
  - `Divider().padding(.leading, 76)` between rows (`:192`)
  - a row tap sets `coordinator.selectedExpense` (`:194-196`)
  - no swipe actions
- **`dayHeader`** (`:212-224`): shows "Today" or "October 12" in `.typography(.labelMedium)` (11pt, uppercase, +1.2, so it renders `TODAY` / `OCTOBER 12`) in system `.secondary`. There is no weekday and no rule.

**`HomeExpenseRow`** (`LinguicaSubTracker/Features/Home/Views/Components/HomeExpenseRow.swift`):
- `HStack(spacing: 14)`, padding 16h/12v (`:22`, `:45-46`)
- `LogoCircle(size: 44)` (`:23-28`)
- name `.typography(.titleMedium)` in system `.primary` (`:31-33`)
- meta `"type · cycle"` (`:16-18`, `:34-36`); the **category is missing**
- price `.currency(code:)` (`:12-14`) in `.typography(.titleLarge)` (`:41-43`)
- It is used only at `HomeListView.swift:194` and in its own preview (`:53-66`).

**Search row** (`LinguicaSubTracker/Core/Components/ExpenseRow.swift`):
- the same skeleton with `LogoCircle(size: 44)` (`:33-38`)
- the price buried in the subtitle `"schedule • price"` (`:44`)
- an Active/Inactive **`Capsule`** badge tinted `.green`/`.gray` at 0.18 (`:10-16`, `:51-56`)
- a 32pt filled `Circle` payment icon with `.font(.system(size: 13, weight: .semibold))` (`:58-65`)
- Its only caller is `SearchView.swift:241`.

**Search screen** (`LinguicaSubTracker/Features/Search/Views/SearchView.swift`):
- **Header** (`:123-173`): "All Subs" in `.typography(.displaySmall)` (`:140-142`) plus `SortChip` (`:145-149`).
- **List** (`:190-223`):
  - `List` `.plain` (`:193`, `:208`), `.listRowBackground(Color.clear)` and zero insets (`:196-197`)
  - system separators are left on: there is no `.listRowSeparator` call
  - `.swipeActions` Delete `.tint(.red)`, hidden in selection mode (`:198-205`), leads to the alert (`:89-107`)
  - `.padding(.top, 12)` (`:210`)
- **Selection checkbox** (`:228-239`): a 22pt `checkmark.circle.fill`/`circle` in `Color.accentColor` (now shu, via `AccentColor.colorset`), inserted *before* the row, which shifts the row right.
- **Bulk bar** (`:312-333`): `.background(.ultraThinMaterial)` at `:331`, with the bulk alert at `:108-118`.
- **Selection API**: `SearchViewModel.swift:61-96` (`enterSelectionMode`, `exitSelectionMode`, `toggleSelection`, `isSelected`, `selectAll`, `deleteSelected`, `selectExpense`).

**`SortChip`** (`LinguicaSubTracker/Core/UI/Inputs/SortChip.swift:28-40`): already done by the foundation pass (verify): untinted `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))` (`:40`), `ink` label, `inkSecondary` chevron, `.smooth(duration: 0.25)` sort animation that is nil under Reduce Motion (`:15`).

**`ExpensesInDay` sheet** (`LinguicaSubTracker/Features/ExpensesInDay/Views/ExpensesInDay.swift`):
- **Chrome:**
  - custom `Capsule` handle (`:87-93`) with `.presentationDragIndicator(.hidden)` (`:50`)
  - header `Text("Expenses")` `.headline` plus the date `.subheadline` (`:95-105`)
  - `.appBackground()` (`:48`), detent `.height(compactHeight)` (`:49`)
- **`mainList`** (`:108-142`):
  - a `GlassSection` → `List` with `rowHeight = 64` (`:110`) and insets 4/12 (`:111`)
  - `.swipeActions(allowsFullSwipe: false)` (`:121-127`) opens a `confirmationDialog` offering "Delete current" or "Delete all" (`:58-77`)
  - `.scrollDisabled(true)` and a fixed frame height (`:132-134`)
- **`expenseTile`** (`:144-179`): `LogoCircle(size: 40)` (`:152-157`), system fonts (`:161`, `:165`), chevron (`:171-173`).
- **`addRow`** (`:182-207`): a `tertiarySystemFill` circle.
- **`totalBlock`** (`:210-224`): a `GlassSection`, with `.currency(code: "CAD")` hard-coded at `:219`.
- **ViewModel** (`LinguicaSubTracker/Features/ExpensesInDay/ViewModels/ExpensesInDayViewModel.swift`):
  - `compactHeight` (`:28-34`, rowH 56, cap 520)
  - `selectExpense` (dismisses, then waits 0.35 s; `:36-43`)
  - `rowSubtitle` with hard-coded "CAD" (`:45-49`)
  - `deleteFromCurrentDay` / `deleteAll` (`:54-66`)

**`LogoCircle`** (`LinguicaSubTracker/Core/Components/LogoCircle.swift:16-25`):
- It always applies `.glassEffect(.regular.interactive())` (`:19`) and a coloured shadow (`:20-25`). The foundation already moved the initials to `.custom(AppFont.mono, fixedSize:)` (`:111`).
- It compiles into the widget extension (exception set `LinguicaSubTracker.xcodeproj/project.pbxproj:78-105`; the entry is at `:81`).
- Call sites:
  - 13 in the app (rows, `DayCell.swift:174`, forms, onboarding, its own preview)
  - 3 in widgets (`SatoruWidgets/WidgetViews.swift:79`, `:452`, `:558`)

**Category colour lookup** is duplicated inline as `settings.categories.first { $0.name == name }?.colorHex` (`LinguicaSubTracker/Features/Home/ViewModels/TotalViewModel.swift:88-89`, `LinguicaSubTracker/Features/Stats/ViewModels/StatsViewModel.swift:227`). `Expense.category` is a plain `String` (`LinguicaSubTracker/Core/Models/Expense.swift:49`). `AppStore`, `SettingsStore` and `AppCoordinator` are injected at the root (`LinguicaSubTracker/App/LinguicaSubTrackerApp.swift:53-55`, after a root `Theme.font(size: 15)` and `.foregroundStyle(Color.ink)` at `:51-52`), so sheets inherit them.

## Target design

### Principles
- **The page is the card.** List rows sit directly on `paper`, with no `GlassSection` and no material. This follows the "glass on controls only" decision ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)). Rules run full-bleed, edge to edge, like ruled paper; this also gives the torii "nuki overhang" for free.
- **Two rule weights only:**
  - Hairline `rule` at `1 / displayScale`: one device pixel, 0.33pt @3x.
  - 1pt `ruleStrong` for day headers and the sum line. This is the Kokuyo "thick 3rd line" ([NO-201U](https://kokuyostore.com/en_FR/campus-notebook-notebook-a4-brown-wide-horizontal-ruled-40-sheets/NO-201U.html)).
- **Colour budget:**
  - Prices are `ink`.
  - Category colour appears only as a 6pt square dot and the logo.
  - Shu appears only as the 1pt margin rule, Sunday numerals, the TODAY label and the ensō stroke. There are no filled shu shapes in lists.

### Geometry (all surfaces)
| Element | Spec |
|---|---|
| Row pitch | 44pt (`.frame(minHeight: 44)`), and header pitch 44pt. This sits between the Kokuyo A (7 mm ≈ 42pt) and U (8 mm ≈ 48pt) rulings and meets the HIG minimum. |
| Row rule | Bottom edge of each row, full width, height `1 / displayScale`, `Color.rule` |
| Margin rule | Vertical, x = 56pt from the leading screen edge, 1pt wide, `Color.shu.opacity(0.6)`, full row height. Each row and header draws its own segment, so the segments join into one line. |
| Margin column | x 0…56. It holds the logo (`LogoCircle` 28pt, `glass: false`, centred at x = 28), the day numeral in headers, the checkbox in selection mode, and `+` in the add row. |
| Text column | Starts at x = 64 (8pt after the margin rule) |
| Price column | Trailing, width `@ScaledMetric(relativeTo: .body) 104` (≈11 mono glyphs at 15pt), `alignment: .trailing`, then 16pt trailing padding |
| Column dot | 1.5pt circle, `Color.ruleStrong`, centred on the row rule at x = width − 16 − priceColumn − 4. It works as a column guide, as on [Kokuyo dot ruled](https://www.kokuyo.com/en/stationery/category/notebook-paper/notebook/10591) paper. It is omitted at accessibility text sizes. |
| Header rule | 1pt `Color.ruleStrong`, full width, at the header's bottom edge |
| Counting tick (optional, last step) | 4 × 1pt `Color.ruleStrong` on the row rule, x 52…56, every 5th row ([Kokuyo Campus](https://www.kokuyo.com/en/stationery/series/campus/campus-notebook/basic) counting mark) |

### Typography
These are the existing `AppTypography` styles (`LinguicaSubTracker/Core/Utils/Typography.swift:10-22`), rendered in Fragment Mono by `.typography()` (`LinguicaSubTracker/Core/Utils/Theme.swift:31-49`), which also applies each style's tracking and uppercase. `AppTypography.Style` has no `weight` member (compile error), and `.bold()` on Fragment Mono is a silent no-op ([Apple](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text)). A `.tracking()` placed after `.typography()` does not override the style's tracking; use a custom `AppTypography.Style` instead.

| Text | Style | Colour |
|---|---|---|
| Row name | `.typography(.bodyLarge)` (15pt), `lineLimit(1)` | `ink` |
| Row meta (`■ Category · Cycle`) | `.typography(.bodySmall)` (11pt), `lineLimit(1)` | `inkSecondary` |
| Row price | `.typography(.bodyLarge)`, right-aligned | `ink` |
| Header numeral `12` | `.typography(.headlineSmall)` (20pt) | Sun `shu`, Sat `ai`, otherwise `ink` |
| Header weekday | `.typography(.labelMedium)` (11pt; the style uppercases and tracks +1.2), localized abbreviated weekday | `inkSecondary` |
| `TODAY` label | same as the weekday | `shu` |
| Status stamp | `.typography(AppTypography.Style(size: 10, textStyle: .caption2, letterSpacing: 0.8, uppercase: true))` | see below |
| Sum line `TOTAL 合計` / amount | `.labelMedium` + 13pt `AppFont.kanji` / `.typography(.titleLarge)` (17pt) | `inkSecondary` / `ink` |

### Light and dark tokens used here
| Token | Light (washi) | Dark (lacquer) | Used for |
|---|---|---|---|
| `paper` | #F8F4E6 | #0E0C0B | page under rows (via `.appBackground()`) |
| `ink` / `inkSecondary` | #1E1A17 / #6B635C | #F4EFE6 / #A8A096 | name, price / meta, weekday, inactive stamp |
| `rule` | #E2DCCF | #3A332E | row hairline, logo hairline ring |
| `ruleStrong` | #8C8378 | #746B63 | header rule, column dot, tick, stamp border |
| `shu` | #C1352A | #E84A33 | margin rule at 60 %, Sunday numeral, TODAY, ensō |
| `ai` | #1E50A2 | #6F93D6 | Saturday numeral |
| `beni` | #A22041 | #EE5A62 | swipe Delete tint |

### Home list page with header + 3 rows

The mocks use this notation:
- `(N)` = 28pt flat logo
- `{12}` = today's numeral inside the ensō
- `┃` = shu margin rule
- `━` = 1pt `ruleStrong`
- `─` = hairline `rule`
- `·` on a rule = column dot

```
LIGHT · washi        page = paper #F8F4E6 · no card · no material
x=0         x=56                                         x=W-16
            ┃ shu #C1352A @60% · 1pt
   {12}     ┃ MON  TODAY                                   ← header 44pt (weekday localized)
━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  1pt ruleStrong #8C8378
    (N)     ┃ Notion                                $8.00   ink #1E1A17
            ┃ ■ Productivity · Monthly                      inkSecondary #6B635C
────────────╂─────────────────────────────·─────────────── rule #E2DCCF · dot #8C8378
    (Y)     ┃ YouTube                              $13.99
            ┃ ■ Entertainment · Monthly
────────────╂─────────────────────────────·───────────────
    (C)     ┃ ChatGPT                              $20.00
            ┃ ■ Productivity · Monthly
────────────╂─────────────────────────────·───────────────
    18      ┃ SAT 土                                        ← "18" in ai #1E50A2
━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                         └ price column 104pt ┘
```

```
DARK · lacquer       page = paper #0E0C0B
   {12}     ┃ MON  TODAY              numeral ink #F4EFE6 · ensō + TODAY shu #E84A33
━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━  ruleStrong #746B63
    (N)     ┃ Notion           $8.00   ink #F4EFE6
            ┃ ■ Productivity · Monthly inkSecondary #A8A096
────────────╂──────────·────────────── rule #3A332E · dot #746B63
    (Y)     ┃ YouTube         $13.99   margin shu #E84A33 @60%
            ┃ ■ Entertainment · Monthly
────────────╂──────────·──────────────
    (C)     ┃ ChatGPT         $20.00   logo: no glass, no shadow,
            ┃ ■ Productivity · Monthly hairline ring in rule #3A332E
────────────╂──────────·──────────────
```

The summary block above the list is unchanged in structure:
- `MoneyDisplay` is owned by `price_display.md`.
- `CoinStack` piles are owned by `charts.md`.
- The `budgetCTA` card is a paper card via `general_app_ui.md`.

The list rules start at the first day header. Coin-pile labels change to an `ink` amount over a `CategoryMark` (square dot + name), because an amount painted in category colour breaks the "prices are ink" rule.

### Search row (status stamp, payment glyph, selection)
```
All Subs   [Name ⇅]                                   Select
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  1pt ruleStrong title line
    (N)     ┃ Netflix                              $15.99
            ┃ ■ Entertainment · Monthly · ▭      ┌ACTIVE┐     solid 1pt ruleStrong border, ink text
────────────╂─────────────────────────────·────────────────
    (A)     ┃ Adobe Creative Clou…                 $89.99   name truncates, price never does
            ┃ ■ Productivity · Yearly · ☺      ┊INACTIVE┊    dashed 1pt inkSecondary border
────────────╂─────────────────────────────·────────────────

selection mode: the margin swaps logo → checkbox (no row shift)
    ☐       ┃ Netflix                              $15.99
    ■✓      ┃ Adobe Creative Clou…                 $89.99   checkmark.square.fill in ink (not shu)
```
- **Status stamp:** a square text stamp, radius 0, not rotated, under the price, right-aligned. It shows `ACTIVE` in `ink` with a solid border, or `INACTIVE` in `inkSecondary` with a dashed `[2,2]` border. The shape difference plus the word satisfies [WCAG 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color). The shu hanko (`HankoStamp`, `charts.md`) is **not** used here: it is limited to one per screen.
- **Payment glyph:** a bare SF Symbol inline at the end of the meta line, `creditcard` (method set) or `person` (none), via `.iconStyle(size: 10, color: .inkSecondary)`. It has no circle fill.
- **Selection:** a 20pt `square` / `checkmark.square.fill`, `ruleStrong` when unselected and `ink` when selected. It crossfades with the logo using `.transition(.opacity)`.
- **Bulk bar:** a control, so glass is allowed: `.glassEffect(.regular, in: .rect(cornerRadius: AppRadius.card))` replaces `.ultraThinMaterial`.
- **`SortChip`:** already done by the foundation pass (verify `SortChip.swift:40`). This doc changes nothing on it.

### `ExpensesInDay` sheet
```
               ▬  (system drag indicator)
   {12}     ┃ MON  TODAY                           OCT 2026
━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    (N)     ┃ Notion                                   $8.00
            ┃ ■ Productivity · Monthly
────────────╂──────────────────────────────·────────────────
    (Y)     ┃ YouTube                                 $13.99
            ┃ ■ Entertainment · Monthly
────────────╂──────────────────────────────·────────────────
     +      ┃ Add expense                                       inkSecondary, next blank line
━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  1pt sum line (ruleStrong)
              TOTAL 合計                                $21.99   17pt ink, no rule below
```
- The rows are the same notebook `ExpenseRow`. The chevron is dropped, matching the Home rows.
- The sheet keeps `.appBackground()`, which is opaque paper. Ruled lines on glass lose the paper metaphor.

### Shared views (new file: `LinguicaSubTracker/Core/UI/Containers/Notebook.swift`, app target only)
```swift
enum Notebook {
    static let pitch: CGFloat = 44
    static let margin: CGFloat = 56
    static let trailing: CGFloat = 16
    static let priceColumn: CGFloat = 104          // wrap in @ScaledMetric(relativeTo: .body)
}
// Day headers format weekday and month/year with the device's locale.

/// Ruled-paper strip behind one row/header: bottom rule, shu margin segment, optional dot/tick.
struct NotebookLine: View {
    enum Weight { case hairline, strong }
    var weight: Weight = .hairline
    var dot = false
    var tick = false
    @Environment(\.displayScale) private var scale
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var priceColumn = Notebook.priceColumn

    var body: some View {
        Canvas { ctx, size in
            let h: CGFloat = weight == .hairline ? 1 / scale : 1
            let y = size.height - h
            ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: h)),
                     with: .color(weight == .hairline ? Color.rule : Color.ruleStrong))
            ctx.fill(Path(CGRect(x: Notebook.margin, y: 0, width: 1, height: size.height)),
                     with: .color(Color.shu.opacity(0.6)))
            if dot, !typeSize.isAccessibilitySize {
                let x = size.width - Notebook.trailing - priceColumn - 4
                ctx.fill(Path(ellipseIn: CGRect(x: x - 0.75, y: y + h / 2 - 0.75, width: 1.5, height: 1.5)),
                         with: .color(Color.ruleStrong))
            }
            if tick {
                ctx.fill(Path(CGRect(x: Notebook.margin - 4, y: y + h / 2 - 0.5, width: 4, height: 1)),
                         with: .color(Color.ruleStrong))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
```
The same file holds two more views:
- **`NotebookDayHeader(date: Date, trailing: String? = nil)`:**
  - **Layout:** an `HStack(spacing: 0)` of three parts:
    - the numeral, framed to `Notebook.margin` and centred
    - localized abbreviated weekday (+ `TODAY`) with `.padding(.leading, 8)` and `firstTextBaseline` alignment
    - `Spacer`, then the optional `trailing` text
  - **Frame:** `.padding(.trailing, 16)`, `.frame(minHeight: 44)`, `.background(NotebookLine(weight: .strong))`.
  - **Weekday:** `Calendar.current.component(.weekday, from:)`.
  - **Today marker:** today is detected with `Calendar.current.isDateInToday`. `EnsoShape(seed: EnsoShape.seed(for: date))` (from `calendar.md`, the same seed as that date's calendar cell) is drawn at 34pt, filled `shu`, in its final state behind the numeral, with no draw-on animation in scrolling lists. Today's numeral is `ink` inside the ensō even on a Sunday.
  - **Accessibility:** `.accessibilityElement(children: .ignore)`, `.accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))`, `.accessibilityAddTraits(.isHeader)`.
- **`CategoryMark(name: String)`:**
  - It reads `@Environment(SettingsStore.self)` and resolves the colour as `settings.categories.first { $0.name == name }.map { Color(hex: $0.colorHex) } ?? Color.inkSecondary`.
  - It renders `HStack(spacing: 4) { Rectangle().fill(color).frame(width: 6, height: 6).accessibilityHidden(true); Text(name) }`.
  - Font and colour are inherited from the caller.

### Notebook `ExpenseRow` (rewrite of `LinguicaSubTracker/Core/Components/ExpenseRow.swift`)
The new API is `ExpenseRow(expense:, showsStatus: Bool = false, selected: Bool? = nil, onTap:)`. A non-nil `selected` means selection mode. The row does **not** draw its own `NotebookLine`; callers attach it (see Implementation steps), so that inside a `List` it can be a `listRowBackground`.
```swift
HStack(spacing: 0) {
    marginMark.frame(width: Notebook.margin)        // LogoCircle(size: 28, …, glass: false) or checkbox
    VStack(alignment: .leading, spacing: 2) {
        Text(expense.name)                          // ink, lineLimit 1, minimumScaleFactor 0.85, .tail
        HStack(spacing: 4) {
            CategoryMark(name: expense.category)
            Text("· \(expense.billingCycle.displayName)")
            if showsStatus { paymentGlyph }
        }                                           // bodySmall 11, inkSecondary, lineLimit 1
    }
    .padding(.leading, 8)
    Spacer(minLength: 8)
    VStack(alignment: .trailing, spacing: 2) {
        Text(priceText)                             // ink, lineLimit 1, minimumScaleFactor 0.7
        if showsStatus { StatusStamp(isActive: expense.isActive) }
    }
    .frame(width: priceColumn, alignment: .trailing)
}
.padding(.trailing, Notebook.trailing)
.frame(minHeight: Notebook.pitch)
.contentShape(Rectangle())
```
- **`priceText`:** `MoneyFormatter.format(expense.price, settings: settingsStore.settings)`, the single formatting path from `price_display.md` (`LinguicaSubTracker/Core/Utils/MoneyFormatter.swift:19-23`).
- **Meta:** drops `type.displayName`. With it, "Entertainment · Installment · Bi-weekly" is 39 glyphs and does not fit the ~180pt text column. Category is the new required field.
- **Accessibility sizes** (`dynamicTypeSize.isAccessibilitySize`): replace the trailing price column with the price as a third line in the leading `VStack`. The row grows freely and `NotebookLine` hides the column dot.
- **`StatusStamp`:** stays private in the same file:
```swift
Text(isActive ? "ACTIVE" : "INACTIVE")
    .typography(AppTypography.Style(size: 10, textStyle: .caption2, letterSpacing: 0.8, uppercase: true))
    .foregroundStyle(isActive ? Color.ink : Color.inkSecondary)
    .padding(.horizontal, 4).padding(.vertical, 1)
    .overlay(Rectangle().strokeBorder(isActive ? Color.ruleStrong : Color.inkSecondary,
             style: StrokeStyle(lineWidth: 1, dash: isActive ? [] : [2, 2])))
```

### `LogoCircle(glass:)`
`calendar.md` owns and implements this opt-out immediately after the foundation. Verify that `glass: false` removes glass and shadow and adds a `Color.rule` hairline ring. This doc passes `glass: false` for notebook rows; widget callers retain the default `true`.

### Long names and mono width
Fragment Mono is ≈0.6 em per glyph, ≈9pt per glyph at 15pt. On a 375pt screen the name column is 375 − 56 − 8 − 8 − 104 − 16 ≈ 183pt, about 20 glyphs.
- **Name:** `lineLimit(1)`, `.minimumScaleFactor(0.85)`, then `.truncationMode(.tail)`. Never wrap to a second line at default sizes, because that would break the pitch.
- **Meta:** `lineLimit(1)`, tail truncation. Category comes first, so it survives.
- **Price:** **never truncated**: `lineLimit(1)` and `.minimumScaleFactor(0.7)`. The 104pt column fits "R$12,345.67" at full size; "$1,234,567.89" scales to ≈0.76.
- **Header:** fixed short strings; `trailing` uses `lineLimit(1)`.

### Motion
- Rows and rules are static. There is no ripple, bounce or glow, and no `layerEffect` anywhere in these views.
- The only list animations are the logo ↔ checkbox opacity crossfade, the existing sort/selection list animations (curve swapped to `.smooth(duration: 0.25)`, nil under Reduce Motion, per `general_app_ui.md` §8), and the `budgetCTA` change from scale+opacity to `.opacity` only.
- The today ensō in list headers is drawn in its final state, so there is nothing to gate on Reduce Motion.

## Implementation steps
1. **Prerequisite check.** Already done by the foundation pass (verify, do not redo):
   - `Color.paper`, `ink`, `inkSecondary`, `rule`, `ruleStrong`, `shu`, `ai`, `beni` and `AppFont.kanji` exist (`LinguicaSubTracker/Core/Utils/AppTheme.swift:52-70`).
   - `GlassSection` is a paper card (`GlassSection.swift:15-19`); `SortChip` is squared glass (`SortChip.swift:40`).
   - `grep -rn "typography(.*\.weight(" LinguicaSubTracker` prints nothing.
   - If any is missing, stop and implement `general_app_ui.md` first.
   - `calendar.md` has landed: `EnsoShape.swift` and `LogoCircle(glass:)` exist. If either is missing, implement `calendar.md` first.
2. **Verify `LogoCircle`** (`LinguicaSubTracker/Core/Components/LogoCircle.swift`). Confirm the calendar-owned `glass:` API matches the contract above and leaves the widget's default behavior intact; do not add a second implementation.
3. **Create `LinguicaSubTracker/Core/UI/Containers/Notebook.swift`** (new) with `Notebook`, `NotebookLine`, `NotebookDayHeader` and `CategoryMark`, exactly as specified.
   - Day header numeral colour (same rule as calendar.md's `DayCell.numeralColor`): today → `ink` (inside the ensō); else weekday 1 → `shu`; weekday 7 → `ai`; else `ink`.
   - Format weekday text using the device's locale and the same calendar as the day grid; do not introduce a weekday lookup table.
   - Do **not** add this file to the widget target.
4. **Rewrite `LinguicaSubTracker/Core/Components/ExpenseRow.swift`** as the notebook row:
   - New API with `showsStatus` / `selected`.
   - The margin mark is `if let selected { Image(systemName: selected ? "checkmark.square.fill" : "square").iconStyle(size: 20, color: selected ? .ink : .ruleStrong) } else { LogoCircle(size: 28, customization:, logoName:, name:, glass: false) }`, with `.transition(.opacity)` on both branches.
   - Add `.accessibilityAddTraits(selected == true ? .isSelected : [])` on the button.
   - Delete `statusColor`, the `Capsule` badge (`:51-56`), the payment `Circle` (`:58-65`) and the price-in-subtitle (`:44`).
   - Update the preview (`:76-89`): drop `Divider().padding(.leading, 76)` and `.background(Color.black)`, attach `.background(NotebookLine(dot: true))` per row, and add one fixture named "Adobe Creative Cloud All Apps" priced 1234567.89 so truncation is visible.
5. **Delete `LinguicaSubTracker/Features/Home/Views/Components/HomeExpenseRow.swift`.** Its only caller is `HomeListView.swift:194`.
6. **`HomeListView.swift`:**
   - **Padding:** move `.padding(.horizontal, 16)` from the body (`:54`) onto `summaryBlock`, so `listBlock` is full-bleed.
   - **`listBlock` (`:178-210`):**
     - Remove the `GlassSection` wrapper and its `.contentInsets` / `.clipsContent` (`:207-208`); keep `.frame(maxHeight: .infinity)`.
     - Bind `let days = self.days` once.
     - Keep `ScrollView` → `LazyVStack(spacing: 0)` → `Section`.
     - Rows: `ExpenseRow(expense: expense) { coordinator.selectedExpense = expense }.background(NotebookLine(dot: true))`.
     - Delete the `Divider` (`:191-193`).
     - Header: `NotebookDayHeader(date: group.day)`.
     - Keep the empty state text, restyled to `inkSecondary`.
   - **Delete `dayHeader`** (`:212-224`).
   - **`categoryStacks` labels:** in `:155-161`, change the amount's `.foregroundStyle(spend.color)` to `Color.ink` and replace `Text(spend.name)` with `CategoryMark(name: spend.name)` (keep `.typography(.bodySmall)`, `lineLimit(1)`). Leave `CoinStack` itself to `charts.md`.
   - **`budgetCTA`:** change `.transition(.opacity.combined(with: .scale(scale: 0.97)))` (`:137`) to `.transition(.opacity)`. Its `GlassSection` is already a paper card (foundation, verify). Icon `color: .secondary` (`:104`) → `.inkSecondary`; text `:108` → `Color.ink`, `:111` → `Color.inkSecondary`.
   - **Summary spring** (`:90`): `.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewModel.hasBudget)`, with `@Environment(\.accessibilityReduceMotion) private var reduceMotion`.
   - **`categoryStacks` name colour:** `.secondary` (`:160`) → `Color.inkSecondary` (covered by the `CategoryMark` swap below).
7. **`SearchView.swift`:**
   - **Title line:** after `header(...)` (`:42-43`) insert a full-bleed `Rectangle().fill(Color.ruleStrong).frame(height: 1).padding(.top, 12)`, and remove `.padding(.top, 12)` from the list (`:210`).
   - **`list`:** iterate `ForEach(Array(items.enumerated()), id: \.element.id)`. Per row:
     - replace `.listRowBackground(Color.clear)` with `.listRowBackground(NotebookLine(dot: true))`
     - keep `.listRowInsets(EdgeInsets())`
     - add `.listRowSeparator(.hidden)`
     - change the swipe `.tint(.red)` (`:203`) to `.tint(Color.beni)`
   - **`rowView` (`:226-258`):** collapse to `ExpenseRow(expense:, showsStatus: true, selected: vm.isSelectionMode ? vm.isSelected(expense) : nil) { …same closure (:242-250)… }`. Delete the leading checkbox `HStack` branch (`:228-239`) and keep the `.animation(…, value: vm.isSelectionMode)`.
   - **`bulkActionBar`:** replace `.background(.ultraThinMaterial)` (`:331`) with `.glassEffect(.regular, in: .rect(cornerRadius: AppRadius.card))`, then add `.padding(.horizontal, 12).padding(.bottom, 8)` outside it. Its count label `.secondary` (`:316`) → `Color.inkSecondary`.
   - **Springs → smooth:** the `.spring(…)` curves at `:155`, `:211-222`, `:243-245` and `:254-257` become `reduceMotion ? nil : .smooth(duration: 0.25)` (add `@Environment(\.accessibilityReduceMotion) private var reduceMotion`). Values and triggers stay.
   - **Text tokens:** "All Subs" `:142` and the header `:172` `.primary` → `Color.ink`.
8. **`ExpensesInDay.swift`:**
   - **Chrome:**
     - Delete `handle` (`:87-93`) and set `.presentationDragIndicator(.visible)` (`:50`).
     - Replace `header` (`:95-105`) with `NotebookDayHeader(date: viewModel.date, trailing: viewModel.date.formatted(.dateTime.month(.abbreviated).year()).uppercased())` plus `.padding(.top, 20)`.
     - Remove `.padding(.horizontal)` (`:44`) and set the inner `VStack` spacing to 0 (`:40`).
   - **`mainList`:**
     - Drop the `GlassSection` (`:113`, `:141`).
     - Set `rowHeight` to `Notebook.pitch` (`:110`) and `rowInsets` to `EdgeInsets()` (`:111`).
     - Rows: `ExpenseRow(expense: expense) { vm.selectExpense(expense) }` with `.listRowBackground(NotebookLine(dot: true))`, `.listRowInsets(EdgeInsets())` and `.listRowSeparator(.hidden)`.
     - Keep the swipe block (`:121-127`) and add `.tint(Color.beni)`.
     - Delete `expenseTile` (`:144-179`).
   - **`addRow`:**
     - The margin holds `Image(systemName: "plus").iconStyle(size: 15, color: .inkSecondary)` framed to `Notebook.margin`; remove the `tertiarySystemFill` circle.
     - Text "Add expense" in `.typography(.bodyLarge)`, `inkSecondary`, `.padding(.leading, 8)`.
     - `.frame(minHeight: Notebook.pitch)`, `.background(NotebookLine(weight: .strong))`. This is the sum line.
   - **`totalBlock` → sum line:**
     - Remove the `GlassSection`.
     - Layout: `HStack(spacing: 0) { Color.clear.frame(width: Notebook.margin); "TOTAL" + "合計"; Spacer; amount framed to the price column }`, with `.padding(.trailing, 16)`, `.frame(height: 44)` and no `NotebookLine`.
     - Amount: `MoneyFormatter.format(vm.total, settings: settingsStore.settings)`. This replaces the "CAD" at `:219`; the fix is owned by `price_display.md`, so reuse whatever that doc produced and add no second path.
9. **`ExpensesInDayViewModel.swift`:**
   - Delete `rowSubtitle` (`:45-49`), which carries the other "CAD", now that `ExpenseRow` renders the meta.
   - Change `compactHeight` (`:28-34`) to `min(20 + 44 + CGFloat(expenses.count + 1) * Notebook.pitch + 44 + 24, 520)`: top inset, header, rows plus the add row, sum line, and bottom padding.
10. **Counting ticks (optional; ship after steps 1–9 verify).**
    - Search: pass `tick: (index + 1) % 5 == 0` to `NotebookLine`.
    - Home: compute `let offsets = days.reduce(into: [0]) { $0.append($0.last! + $1.expenses.count) }`, iterate `days.enumerated()`, and pass `tick: (offsets[g] + i + 1) % 5 == 0`.
    - Skip ticks in `ExpensesInDay`, whose lists are short.
11. **Search the repo:**
    - `grep -rn "HomeExpenseRow\|rowSubtitle" LinguicaSubTracker` must return nothing.
    - `grep -n "GlassSection\|ultraThinMaterial\|Capsule" LinguicaSubTracker/Core/Components/ExpenseRow.swift LinguicaSubTracker/Features/ExpensesInDay/Views/ExpensesInDay.swift` must return nothing.
    - In `HomeListView.swift`, the only remaining `GlassSection` is `budgetCTA`.

## Preserve
- **Home:**
  - `LazyVStack` inside `ScrollView`, with **no swipe actions** (switching to `List` is out of scope)
  - `Section` per day from `ExpenseService.occurrencesByDay(coordinator.filtered(store.expenses), month:)` (`HomeListView.swift:41-46`)
  - a row tap sets `coordinator.selectedExpense = expense`, which opens `ExpenseSummarySheet` (`HomeView.swift:186-195`)
- **Home summary:**
  - `@AppStorage("budget_cta_dismissed")` and the "Not now" write (`HomeListView.swift:17`, `:130`)
  - `showBudget` → `BudgetDetailsSheet` (`:91-95`)
  - `animateCoins = CoinEntrance.claim()` (`:173`)
  - the `CoinStack` tap → `showBudget`, with its accessibility label and action (`LinguicaSubTracker/Core/Components/CoinProgress/Views/CoinStack.swift:45-48`)
  - `MoneyDisplay` `onTapGesture: onStats`
- **Search:**
  - `List(.plain)` with native virtualisation
  - trailing `.swipeActions(allowsFullSwipe: true)`, hidden in selection mode, leading to the "Delete …?" alert (`SearchView.swift:89-107`)
  - the bulk delete alert (`:108-118`)
  - `SearchViewModel` selection API (`:61-96`) and the Select/Deselect All logic (`:126-131`)
  - the `let _ = store.expenses` observation hook (`:34`)
  - `.appSearchable` and the 0.5 s focus delay (`:53-71`)
  - the sort/search list animations (`:211-222`)
- **`ExpensesInDay`:**
  - `confirmationDialog` semantics: "Delete current" → `deleteFromCurrentDay` (sets `endDate`), "Delete all" → `deleteAll` (`ExpensesInDay.swift:58-77`, `ExpensesInDayViewModel.swift:54-66`)
  - `allowsFullSwipe: false`
  - `selectExpense`'s dismiss-then-0.35 s hand-off (`:36-43`)
  - `showAddSheet` → `SimplifiedAddExpenseView`
  - the `let _ = store.expenses` hook (`ExpensesInDay.swift:33`)
  - the `.height(compactHeight)` detent, capped at 520
- **`LogoCircle`:** default behaviour is identical for every caller that does not pass `glass:`. The calendar and notebook rows pass `glass: false`; forms, onboarding and widget callers keep their defaults.
- **DEBUG hooks:** `SIMCTL_CHILD_DEBUG_HOME_VIEW=list|calendar` (`HomeView.swift:85-89`), `DEBUG_MONTH_INDEX` (`:93-99`), `DEBUG_OPEN_SHEET=budget` (`HomeListView.swift:59-64`), `DEBUG_WIDGET_GALLERY` (`HomeView.swift:101`).
- **Previews:** `HomeViewPreviewHost`, `ExpensesInDayPreviewHost`, the `SearchView` `#Preview` and the `ExpenseRow` `#Preview` must still compile.

## Risks / gotchas
- **Widget target sharing.** `LogoCircle.swift`, `AppTheme.swift`, `MoneyFormatter.swift`, `AppSettings.swift`, `Assets.xcassets` and the Fragment Mono `.ttf`s compile into `SatoruWidgetsExtension` (`project.pbxproj:78-105`). `Theme.swift` and `Typography.swift` do **not**. (`general_app_ui.md` says the fonts are not in that set; the code has them at `:102-103`. Follow the code.)
  - Inside `LogoCircle`, use only `AppTheme` tokens and system APIs: no `typography()`, `Notebook` or `iconStyle`.
  - `Notebook.swift` stays app-only.
- **System separators.** A plain `List` draws its own separators. Without `.listRowSeparator(.hidden)` every row gets a double line.
- **Row backgrounds during a swipe.** `.listRowBackground(NotebookLine…)` may slide with the swipe or stay put, depending on the OS. Both are acceptable. Do not move the line into the row content for `List` rows, or the margin segment travels with the text.
- **Fixed-height inner `List`** in `ExpensesInDay` (`frame(height: count * pitch)`). Rows taller than 44pt at large text sizes get clipped. This limitation already exists with the 64pt rows; see Open points.
- **Hairline visibility.** Light `rule` #E2DCCF on #F8F4E6 is only 1.24:1 at one device pixel. That is intended to be faint, like Kokuyo's pale lines, but check it on a device. The column dot in `ruleStrong` keeps the column readable either way.
- **Fractional heights blur hairlines.** Keep row and header heights integral (`minHeight: 44`, content < 44 at default sizes).
- **Weights.** `.typography(x.weight(…))` no longer compiles (the foundation removed `Style.weight`). The system `.font(…weight…)` calls left in `ExpensesInDay.swift` (`:161`, `:172`, `:193`, `:198`, `:220`) disappear with this doc's rewrite of those views. Hierarchy comes from size, case, tracking and colour only.
- **Kanji fallback.** Fragment Mono has no CJK glyphs. `合計` must be a separate `Text` view with `AppFont.kanji` (`HiraMinProN-W3`); otherwise it renders in the system sans.
- **`ExpensesInDay` header ownership.** This doc replaces the sheet header with `NotebookDayHeader`; `calendar.md` leaves the sheet untouched.
- **`Canvas` colours.** `NotebookLine` fills with dynamic `UIColor`-backed tokens; `GraphicsContext` resolves them from the view's environment. Confirm in the dark screenshots that rules switch with the theme.
- **Locale.** Format day and month labels with the device's locale, matching the calendar header. Keep the decorative notebook marks independent of date localization.
- **Shu budget.** At most one filled shu shape per screen. Checkboxes are `ink`, stamps are ink or grey, and the margin and ensō are strokes. Do not tint the selection with `Color.accentColor`, which `general_app_ui.md` makes shu.
- **Materials and shaders.** No `layerEffect` exists in these views, and none may be added. Removing `GlassSection` from rows also removes the material-renders-black risk.
- **`HomeListView.days` is computed.** It runs `occurrencesByDay` on every access. Bind it once per `listBlock` evaluation, especially once ticks need `offsets`.
- **Stale builds.** If the simulator shows old row layouts after BUILD SUCCEEDED, delete `Intermediates` and rebuild with `COMPILATION_CACHE_ENABLE_CACHING=NO` (Xcode CAS issue known in this repo).

## Verification
1. **Build** (this also builds the widget extension, which compiles `LogoCircle`):
   `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build`
2. **Tests:** run the same command with `test`. No test references these rows. `CalendarViewModelTests` must stay green, since `monthKey` is untouched.
3. **Home list screenshots:**
   - Install, then run `SIMCTL_CHILD_DEBUG_HOME_VIEW=list xcrun simctl launch 9BF66402-1F99-44CB-89A9-03A7C31ECBD2 com.dtx.LinguicaSubTracker`, wait about 8 s, then `xcrun simctl io 9BF66402-1F99-44CB-89A9-03A7C31ECBD2 screenshot list-light.png`.
   - Add `SIMCTL_CHILD_DEBUG_MONTH_INDEX=<n>` to reach a busy month.
   - For dark mode, set Settings → Appearance → Dark (`simctl ui appearance` does not reliably reach the app) and repeat to get `list-dark.png`.
4. **`HomeViewPreviewHost` in Xcode Previews**, light and dark. Day 11 has 4 fixtures, so it shows a header plus several rows. Zoom the screenshot to check:
   - the margin rule at x = 56 is continuous through headers and rows
   - the column dots line up vertically
   - the header rule is visibly heavier than the row rules
   - the logos have no glass and no shadow
   - `月` renders in Mincho
   - prices are ink, not category colour
5. **Search** (open with the magnifier):
   - stamps show solid ACTIVE and dashed INACTIVE
   - swipe → Delete (beni) → alert → row removed
   - Select → checkboxes replace the logos in the margin without a horizontal shift → Select All → bulk Delete → alert
   - the long-name fixture truncates the name, never the price
6. **`ExpensesInDay`** (tap a day with expenses in calendar mode):
   - the header shows the tapped day's numeral and localized weekday, with Sunday numerals in shu and Saturday in ai
   - swipe → dialog with "Delete current" / "Delete all"
   - tapping a row dismisses the sheet, then opens the summary
   - the detent fits the rows without scrolling for ≤ 6 expenses
   - the total uses the settings currency, not "CAD" (switch the currency in Settings to confirm)
7. **Accessibility:**
   - At Dynamic Type AX3, rows grow, the price drops under the name and no text clips on Home or Search.
   - VoiceOver reads the headers as "Sunday, October 11, heading" and the rows as "name, category · cycle, price[, ACTIVE]".
   - Selected rows announce "selected".
8. **Widget gallery is unchanged:** `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=week` and `week-dark`. The logos still have glass.

## Open points / dig deeper
- **Snap rows to the grid at large text.** Research rounding row heights up to multiples of 44pt at large Dynamic Type sizes (as GoodNotes/Notes-style ruled pages do), so the ruling never breaks. Today rows simply grow.
- **`ExpensesInDay` row clipping at AX sizes.** Measure the actual row heights (a `PreferenceKey` sum) instead of `count × pitch`, so they don't clip. Do this only if AX testing shows clipping.
- **Day subtotal on headers.** Ledger-style "12 MON … $42.98" would make the list read as a kakeibo (household ledger). Validate with the user before adding; it was skipped as unrequested.
- **Pinned day headers.** `LazyVStack(pinnedViews: [.sectionHeaders])` with a `paper` background would keep the date visible while scrolling. Check that it doesn't fight the glass top bar.
- **Continue ruled lines to the page bottom.** Empty rules under the last row (a blank notebook page) would strengthen the metaphor. Measure the cost and whether it reads as "more rows" (false affordance).
- **Hairline contrast on device.** Check `rule` at one pixel in light mode, with Increase Contrast on. Fall back to `ruleStrong.opacity(0.4)` if it disappears.
- **Expense type dropped from the meta line.** Decide whether "Subscription/Expense/Installment" belongs back in the row, for example as a 1-glyph mark, or stays only in `ExpenseSummarySheet`.
- **Bilingual stamps.** 有効 / 停止 next to ACTIVE / INACTIVE would need localization review before shipping.
- **Scroll under the bottom bar.** Let the Home list scroll under the glass bottom bar (remove `.padding(.bottom, 8)`, extend into the bottom safe area) so glass has content to refract. This is owned by `home_screen_ux.md`'s layout work.
- **Counting ticks.** Ticks every 5 rows may be noise on short months. Decide after a user look whether to keep them on Home only, Search only, or drop them.
- **Genkō cell grid for prices.** Research suggested faint per-glyph cells, which are too busy for rows. Evaluate only for the hero total (`price_display.md`).
- **Washi texture behind rows.** Check whether a multiply tile (a `general_app_ui.md` open point) still lets one-pixel rules read cleanly, or whether rules need `ruleStrong` on texture.

**Status: proposed, not implemented.**
