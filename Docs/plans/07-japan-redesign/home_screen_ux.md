# Home Screen UX — declutter (creative)

## Goal
- **What the user asked for:** Home looks too crowded. Use Apple Calendar as the reference. The user named three problems:
  1. the Filter + ViewMode pill in the top-left corner
  2. the chart (the stats ring) in the bottom-left corner
  3. the month selector in the top centre
- **What this doc delivers:**
  - **Toolbar.** A new `HomeToolbar` with Apple Calendar's layout:
    - top-leading: a `2026` year button that opens a Year grid
    - top-trailing: one group holding the view menu and Search
    - bottom bar: `Today` · `Filter` · `+`
  - **Year grid.** `MonthPickerSheet` is restyled from a wheel picker into a 3×4 grid of months with monthly totals.
  - **Filter sheet.** A new sheet modelled on Apple's "Calendars" sheet, with a filter badge.
  - **Content order.** Home content is recomposed: Koyomi header → total → calendar grid, or Koyomi header → total → notebook list.
  - **Deletions.** `HomeActionButton`, the leading pill, the stats ring and two dead view-model members.
- **What this doc does not restyle** (it only composes these pieces):
  - Koyomi header, cells and ensō: `calendar.md`
  - the total: `price_display.md`
  - list rows: `list_view.md`

**Depends on:**
- `general_app_ui.md` (the foundation). It is already applied in the working tree: tokens, Fragment Mono, `.appBackground()` paper, `Torii.swift`, ink toolbar glyphs.
- `calendar.md`: the existing Koyomi header and month-picker callback, three cell styles, bottom calendar order, ensō draw-on contract (step 9), and `EnsoShape` (step 6's Year-grid ensō).
- `price_display.md`: the `TotalView` rewrite and style-aware `totalSizeRange` it keeps (step 9 only).
- `list_view.md`: the `HomeListView` notebook body (list mode only).
- Follow the execution order in `research_results_and_future_points.md`: `calendar.md` has already landed, so step 4 sees the header and no principal month title; step 6 can use `EnsoShape`. Step 9 lands after `price_display.md` and `list_view.md`.

**References:**
- Apple Calendar on iOS 26:
  - [Change how you view events (iOS 26)](https://support.apple.com/guide/iphone/change-how-you-view-events-iphfd1054569/26.0/ios/26.0)
  - [Create and edit events (iOS 26)](https://support.apple.com/guide/iphone/create-and-edit-events-iph3d110f84/26.0/ios/26.0)
  - [Set up multiple calendars (iOS 26)](https://support.apple.com/guide/iphone/use-multiple-calendars-iph3d1110d4/26.0/ios/26.0)
  - [Apple Community: Show All removed](https://discussions.apple.com/thread/256200863)
  - [Zapier review 2026](https://zapier.com/blog/best-iphone-calendar-apps/)
- Bars and toolbars:
  - [HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
  - [WWDC25-356](https://developer.apple.com/videos/play/wwdc2025/356/)
  - [WWDC25-323](https://developer.apple.com/videos/play/wwdc2025/323/)
  - [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- Glass and colour:
  - [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
  - [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
  - [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- Third-party bottom-bar precedent: Fantastical in the [Apple design gallery](https://developer.apple.com/design/new-design-gallery-2026).

**Doc set (pointers, not duplicated here):**

| Doc | Owns |
|---|---|
| `general_app_ui.md` | tokens, font, shapes, glass rules, `Torii.swift` motifs, ripple removal |
| `calendar.md` | Koyomi header, weekday band, day cells, `EnsoShape` and draw-on, rewind overlay |
| `forms.md` | add and edit forms (the `+` destination `SimplifiedAddExpenseView`) |
| `charts.md` | Stats sheet, `BudgetColor` options, `HankoStamp` |
| `price_display.md` | `TotalView`, `MoneyDisplay`, `InkReveal`, `BudgetMark` |
| `list_view.md` | notebook rows in `HomeListView`, `CategoryMark`; `LogoCircle(glass:)` already comes from `calendar.md` |
| `home_screen_ux.md` (this doc) | Home toolbar and layout, the Year grid, the filter sheet |
| `research_results_and_future_points.md` | index, sources, every open point |

## Calendar handoff and baseline
The component order below is the expected handoff after `calendar.md`. The cited `HomeView`/`HomeToolbar` line numbers, control inventory and “Before” measurements describe the earlier foundation-only checkout; verify them against the code before editing.

### Composition: calendar mode, top to bottom
`calendar.md` creates the header while preserving the existing total-above-calendar, bottom-anchored Home order.

1. **Navigation bar** (`LinguicaSubTracker/Features/Home/Views/HomeView.swift` → `HomeToolbar`)
   - **Top-leading `leadingPill`** (`LinguicaSubTracker/Features/Home/Views/Components/HomeToolbar.swift:108-126`). It is one `HStack(spacing: 20)` holding two unrelated controls:
     - the filter `Menu` (`:128-171`): "All Expenses" (`:130-136`), a `Divider`, then three submenus with `Picker`s for Lists, Categories and Payment Methods (`:140-165`)
     - the view toggle `Button` (`:113-123`), which flips `viewType` with a spring
   - **Principal `monthButton` in the pre-calendar baseline** (`:90-106`): `Text(monthKey)` in `.typography(.headlineSmall)` with `.numericText`, plus `chevron.down`. The picker trigger is now in `KoyomiHeader`; verify the duplicate toolbar title is gone before this plan's toolbar rewrite.
   - **Top-trailing gear** (`HomeToolbar.swift:56-61`): opens Settings.
2. **`KoyomiHeader`** above the calendar/list body, opening the existing month picker.
3. **`TotalView`** above the calendar; `calendar.md` keeps its existing Stats action and gives Large a smaller price range.
4. **`CalendarView`** at the bottom of the calendar body; `calendar.md` retains its placement and adds scrolling only when the content cannot fit.
   - A paged `TabView` beneath the shared `WeekdayBand`, which keeps the pre-redesign header's 52pt height and 8pt grid gap. `calendar.md` preserves the existing 4–6-row month calculation, 4pt grid gutters and flexible row heights, and keeps the calendar below the total.
   - The currently saved cases use 370pt for `.rounded/.contrastRounded/.straight`, 260pt for `.compact` and 460pt for `.bigger`. The calendar plan maps them to Default, Compact and Large.
5. **Bottom bar** (`HomeToolbar.swift:63-87`), one `ToolbarItemGroup`:
   - the stats ring `ring.dashed` with `variableValue: budgetRatio` (`:64-70`)
   - `Spacer`, then `HomeActionButton` (`:74-78`), then `Spacer`
   - Search, which opens the full-screen `SearchView` (`:82-86`)

### Composition: list mode
- **Toolbar:** identical to calendar mode.
- **Body:** `HomeListView` (`HomeView.swift:55-61`). Its sections:
  - `summaryBlock` (`LinguicaSubTracker/Features/Home/Views/Components/HomeListView.swift:70-96`): a `MoneyDisplay` at size 40 with `onTapGesture: onStats` (`:72-77`)
  - then either coin piles (`:142-174`) or the budget CTA card (`:99-138`)
  - then `listBlock` (`:178-210`), a `GlassSection` with its own `ScrollView`
- `KoyomiHeader` also provides the month label and picker entry point in list mode; `calendar.md` removes the old toolbar title.

### Pre-calendar control count (excluding day cells and rows)

| Mode | Controls | Mixed-purpose groups | Controls that change meaning |
|---|---|---|---|
| Calendar | **8**: filter, view toggle, month, gear, total, ring, add/today, search | 1 (the leading pill) | 1 (`HomeActionButton`) |
| List | **7** toolbar items + the `MoneyDisplay` tap, + N coin piles or 2 CTA buttons | 1 | 1 |

### Problems
1. **Mixed pill top-left, with no active-filter state.** The pill holds a data filter and a presentation toggle in one group, which goes against grouping by function ([WWDC25-356](https://developer.apple.com/videos/play/wwdc2025/356/)). `isFilterActive` only moves a checkmark inside the menu (`HomeToolbar.swift:131-135`). Nothing on screen says a filter is on.
2. **Redundant, unlabeled stats ring bottom-left.**
   - The total already opens Stats (`HomeView.swift:40-42`), and so does the list-mode total (`HomeView.swift:60`).
   - The ring is an 18pt gauge (`HomeToolbar.swift:65-66`) with no accessibility label. VoiceOver reads only "button", and sighted users get no clue what it is.
3. **The Add ↔ Today swap hides Add off-month.** `HomeActionButton` (`LinguicaSubTracker/Features/Home/Views/Components/HomeActionButton.swift:11-41`) shows "Add expense" only when `isOnCurrentMonth` is true. On any other month the button becomes "Today", so you can't add an expense while browsing. Apple keeps Today and Add as separate controls that are always visible ([Zapier review 2026](https://zapier.com/blog/best-iphone-calendar-apps/)).
4. **Month picker after `calendar.md`.** The wheel picker remains, but its trigger is in `KoyomiHeader`. This plan replaces the wheel with the Year grid; the toolbar centre stays empty.
   - Retain the approved month-selector concept: prominent month numeral, localized month/year, explicit picker affordance/caret and previous/next controls. Reuse the header callback and selected-month state when implementing the Year grid.
5. **Bar glyph styling.**
   - The gradients are gone (see the foundation list below).
   - Every glyph still forces a custom `.font(.system(size:))`: `HomeToolbar.swift:66,84` (18), `:101` (11 semibold), `:119,168` (14). The HIG asks for system-rendered, monochrome bar items with no custom tints ([HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)).
6. **Missing accessibility labels.**
   - Only the view toggle has one (`HomeToolbar.swift:123`).
   - The filter menu, ring, search and gear are image-only, so VoiceOver announces raw symbol names.
   - The total `Button` has no hint.
7. **Dead code.** These are unused anywhere:
   - `HomeViewModel.filterLabel` (`LinguicaSubTracker/Features/Home/ViewModels/HomeViewModel.swift:43-48`)
   - `HomeViewModel.clearSelectedDay()` (`:85`)

   Once the ring goes, these become unused too, because the toolbar was their only reader:
   - `monthlyTotal` (`:27-32`)
   - `budgetRatio` (`:34-37`)
   - `budgetTint` (`:39-41`)
8. **Wasted height in the pre-calendar baseline.** The old `TotalView` filled about 231pt to show a price at most 92pt tall. The calendar plan preserves the grid's bottom placement and adds a short-screen scroll fallback; this plan keeps that placement.

### Already done by the foundation pass (verify, do not redo)
- **Toolbar glyph colours:** every glyph is `Color.ink`, with no `.gradient` and no `budgetTint`. See `HomeToolbar.swift:59,67,85,103,120,169`. `git diff HEAD` shows the old `Color.primary.gradient.opacity(0.8)` / `budgetTint.gradient`.
- **`HomeActionButton`:** `.transition(.opacity)` replaces `.liquidRipple` (`HomeActionButton.swift:26,40`), and it uses ink glyphs and `.typography(.titleMedium)` (`:17-23,31-37`). The file is deleted in step 5 anyway.
- **Total ripple:** `.rippleOnTap()` has been removed from the total (`TotalView.swift:109` is now the plain `.buttonStyle(.plain)`).
- **Paper background:** `.appBackground()` is flat paper (`LinguicaSubTracker/Core/Utils/AppTheme.swift:78-88`), applied at `HomeView.swift:64`.
- **Accent colour:** `AccentColor.colorset` is shu (light `#C1352A`, dark `#E84A33`; `LinguicaSubTracker/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`). `.glassProminent` therefore defaults to shu.
- **Fonts and appearance:**
  - Navigation titles use Fragment Mono through `Theme.applyUIKitAppearance()` (`LinguicaSubTracker/Core/Utils/Theme.swift:12-28`, called at `LinguicaSubTracker/App/LinguicaSubTrackerApp.swift:45`).
  - The root environment font is `Theme.font(size: 15)` with `.foregroundStyle(Color.ink)` (`LinguicaSubTrackerApp.swift:51-52`).
- **Motifs:** `SectionLabel`, `Rule` and `KasagiHeader` exist in `LinguicaSubTracker/Core/UI/Motifs/Torii.swift:36-55`, `:57-69` and `:18-27`.

### State and data the redesign reuses
- **Filter** (`LinguicaSubTracker/App/AppCoordinator.swift:5-17`):
  - `ExpenseFilter` is single-select per dimension (`list`, `category`, `paymentMethod`, each `String?`).
  - Helpers: `isActive` (`:12`), `activeNames` (`:14-16`), `.all` (`:10`).
  - `HomeViewModel` exposes `lists/categories/paymentMethods` (`HomeViewModel.swift:52-54`), `listBinding()/categoryBinding()/paymentBinding()` (`:58-68`), `clearFilter()` (`:56`) and `isFilterActive` (`:50`).
- **Month** (`LinguicaSubTracker/Features/Home/ViewModels/CalendarViewModel.swift`):
  - `months` (`:8`), `rewindPair` (`:9`), `currentMonthIndex` with `didSet` sync (`:15-17`)
  - `isOnCurrentMonth` (`:38-40`), `monthKey` (`:42-44`)
  - `currentMonthIndexBinding()` (`:46-51`), the single writer path
  - `jumpToCurrentMonth()` (`:58-70`)
- **Month window:** `CalendarService.generateMonths()` returns months **−1…+12** around today (`LinguicaSubTracker/Features/Home/Services/CalendarService.swift:16-23`, range at `:20`). On 2026-10-12 that is Sep 2026 → Oct 2027, so Jan–Aug 2026 and Nov–Dec 2027 do not exist as pages.
- **Totals:** `ExpenseService.totalForMonth(_:month:)` (`LinguicaSubTracker/Core/Services/ExpenseService.swift:314`) and `MoneyFormatter.format(_:settings:currencyCode:)` (`LinguicaSubTracker/Core/Utils/MoneyFormatter.swift:19`).
- **Typography** (`LinguicaSubTracker/Core/Utils/Typography.swift:10-22`):
  - `.typography(_:)` styles: `titleMedium` 16, `headlineMedium` 22, `bodyMedium` 13
  - `labelMedium` 11, uppercase, tracking 1.2
  - `.size(_:)` (`:24`)
  - There is no `.weight()` helper any more.

## Target design

### Apple Calendar (iOS 26) anatomy

| Zone | Apple Calendar | Satoru (recommended) |
|---|---|---|
| Top-leading | Year back button (`‹ 2026`) to the Year view (check on a device) | `2026` text button that opens the Year grid **sheet**. No chevron, because it is not a Back. |
| Month title | In the content, large and left-aligned, not in the bar | Koyomi header in the content (`calendar.md`) |
| Top-trailing | View menu (Compact / Stacked / Details / **List**), Search, Add ([view options](https://support.apple.com/guide/iphone/change-how-you-view-events-iphfd1054569/26.0/ios/26.0), [create events](https://support.apple.com/guide/iphone/create-and-edit-events-iph3d110f84/26.0/ios/26.0)) | One group: view menu (Calendar/List, Stats, Settings) + Search |
| Bottom-leading | **Today**, as text and always present | **Today**, as text and always present, disabled on the current month |
| Bottom-centre | **Calendars**, which opens a checklist sheet ([multiple calendars](https://support.apple.com/guide/iphone/use-multiple-calendars-iph3d1110d4/26.0/ios/26.0)) | **Filter**, which opens a checklist sheet, with a badge |
| Bottom-trailing | Inbox | **`+`**, the single primary action, `.glassProminent` shu |

**Lesson from Apple's mistake.** iOS 26 removed Show All / Hide All from the Calendars sheet, and users complained ([Apple Community](https://discussions.apple.com/thread/256200863)). Satoru keeps a one-tap **Show All**.

**HIG toolbar rules applied** ([HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars), [WWDC25-356](https://developer.apple.com/videos/play/wwdc2025/356/), [WWDC25-323](https://developer.apple.com/videos/play/wwdc2025/323/)):

| Rule | How layout A meets it |
|---|---|
| At most 3 groups per bar | Top: 2 (year \| view menu + search). Bottom: 3 (Today \| Filter \| `+`). |
| One primary action, trailing, tinted | `+` bottom-trailing, `.buttonStyle(.glassProminent)` + `.tint(Color.shu)`. It is the only tinted item. |
| Text and symbol buttons never share a group | `2026` and `Today` each sit alone, separated by `ToolbarSpacer` or by placement |
| Monochrome symbols, no custom tints or gradients | System-rendered `Button(_:systemImage:)` / `Label`. No `.font(.system(size:))`. Glyphs read `ink`. |
| Group by function | Navigation in time: year and Today. Presentation: the view menu. Data: Filter and Search. Create: `+`. |
| Hit targets ≥ 44×44pt ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)) | System toolbar items. No custom frames. |
| A crowded bar is a cue to remove things | The ring is gone. Settings and Stats move into the view menu. Month selection moves into the content or a sheet. |

**APIs used** (all iOS 26; the target is 26.4):
- `ToolbarSpacer(.flexible, placement:)`
- `.badge(_:)` on a toolbar item
- `.buttonStyle(.glassProminent)`
- `Picker` inside `Menu`

### The user's three concerns, resolved

| Concern | Today | After |
|---|---|---|
| Filter + ViewMode pill, top-left | `leadingPill` (`HomeToolbar.swift:108-126`) | **Split.** View mode joins the top-trailing view menu. Filter becomes a bottom-centre button with an active-count badge and a sheet. Top-left holds only the year. |
| Chart, bottom-left | `ring.dashed` (`HomeToolbar.swift:64-70`) | **Deleted.** Stats opens from a tap on the total (existing) or from the view menu's "Stats" item. Bottom-left becomes `Today`. |
| Month selector, top-centre | `calendar.md` already removed `monthButton`; the header opens the wheel `MonthPickerSheet` | Keep the bar centre empty. Replace the wheel with the Year grid; the header's month button and `2026` year button both open it. |

### Recommended layout (A): toolbar spec

| Zone | Control | API | Accessibility | Light | Dark |
|---|---|---|---|---|---|
| Top-leading | `2026` (year of `currentMonth`) | `ToolbarItem(.topBarLeading)`, `Button { Text(yearTitle).typography(.titleMedium) }` | label "Year 2026", hint "Shows the year to pick a month" | text `ink` #1E1A17 on system glass | `ink` #F4EFE6 |
| Top-trailing group | View menu | `Menu` with `Picker` (Calendar / List), `Divider`, Stats, Settings. Label `Label("View options", systemImage: viewType.icon)` | label "View options", value "Calendar" / "List" | glyph `ink` | glyph `ink` |
| Top-trailing group | Search | `Button("Search", systemImage: "magnifyingglass")` | "Search" | `ink` | `ink` |
| Bottom-leading | Today | `Button { Text("Today").typography(.titleMedium) }.disabled(isOnCurrentMonth)` | "Today", hint "Goes to the current month"; disabled is read as "dimmed" | `ink`; disabled is system-dimmed | same |
| Bottom-centre | Filter | `Button("Filter", systemImage: "line.3.horizontal.decrease").badge(activeFilterCount)` | "Filter", value "Showing all" / "2 active" | glyph `ink`, system badge | same |
| Bottom-trailing | `+` | `Label("Add Expense", systemImage: "plus")`, `.buttonStyle(.glassProminent)`, `.tint(Color.shu)`, label `.foregroundStyle(Color.paper)` | "Add Expense" | fill shu #C1352A, glyph paper #F8F4E6 (≈5.0:1) | fill shu #E84A33, glyph paper #0E0C0B (≈5.1:1) |

- **Glass:** system bar glass only. No custom backgrounds behind bar items ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)).
- **Filled shu:** the `+` is the screen's **one filled shu shape**. The ensō and the hanko are strokes (`general_app_ui.md`, `price_display.md`).
- **Stats** is reached by tapping the total (calendar mode `TotalView`, list mode `MoneyDisplay`) or from the view menu. It is never a bar button.

**Why this differs from the research's first sketch** (which put `+` top-trailing and a Stats button in Apple's Inbox slot):
- `+` moves to the bottom-trailing slot for thumb reach. That matches Mail and Fantastical, and Apple's bottom-trailing slot already holds a frequent action.
- A Stats bar button would duplicate the total tap, which is the same redundancy problem 2 describes.

### Before → after (calendar mode, iPhone 17 Pro, light)

```
BEFORE (pre-calendar baseline)                AFTER (layout A)
┌──────────────────────────────────────┐      ┌──────────────────────────────────────┐
│ (≡▾ ▤)     October 2026 ⌄       (⚙)  │      │ (2026)                      (▦▾  ⌕) │ ← year · [view menu | search]
│                                      │      │┌────────────────────────────────────┐│
│                                      │      ││ Koyomi header — calendar.md        ││ ← localized year/month · giant numeral
│                                      │      ││ (faint prev ‹ … › next, kasagi rule) ││   center opens Year grid
│            $1,284.50                 │      │└────────────────────────────────────┘│
│      (≈231pt flex band, ≈139 empty)  │      │        $1,284.50                     │ ← TotalView (price_display.md)
│                                      │      │        ▔▔▔▔▔▔▔▔▔▔▔▔▔ kin underline    │   tap → Stats
│                                      │      │         $215.50 LEFT                 │ ← BudgetMark row (budget only)
│  S    M    T    W    T    F    S     │      │               (ma ≈73pt)             │ ← flexible spacer
│ ╭──╮ ╭──╮ ╭──╮ ╭──╮ ╭──╮ ╭──╮ ╭──╮   │      │ ██SUN┃MON┃TUE┃WED┃THU┃FRI┃SAT ██ │ ← localized weekday band (calendar.md)
│ │  │ │  │ │  │ │  │ │  │ │  │ │  │   │      │ │ 1 │ 2 │ 3 │ … hairline grid       │
│ ╰──╯ ╰──╯ ╰──╯ ╰──╯ ╰──╯ ╰──╯ ╰──╯   │      │ │…│ ⑫ │ … ensō on today           │
│   … rounded cells, grid 370pt        │      │   … grid 370pt                       │
│                                      │      │                                      │
│ (◌)     (+ Add expense)        (⌕)   │      │ (Today)          (≡²)          (✚)   │ ← Today · Filter(badge) · + shu
└──────────────────────────────────────┘      └──────────────────────────────────────┘
 8 controls · 1 mixed group · 1 shape-shifter   7 controls · 0 mixed groups · 0 shape-shifters
```
- `(…)` marks a system glass group.
- `▦` is `calendar` in calendar mode and `list.bullet` in list mode.
- `²` is the system badge with the active filter count, hidden at 0.
- `(Today)` is dimmed when the current month is shown.

### After (list mode)

```
┌──────────────────────────────────────┐
│ (2026)                      (☰▾  ⌕) │  menu label shows list.bullet
│┌────────────────────────────────────┐│
││ Koyomi header — calendar.md        ││  same component, same height: switching modes
│└────────────────────────────────────┘│  keeps month + total fixed; only the body swaps
│            $1,284.50                 │  HomeListView summary (size 40, price_display.md)
│ [ coin piles — only with a budget ]  │  charts.md / list_view.md (unchanged structure)
│   {12}  ┃ MON  TODAY                │  notebook list (list_view.md)
│ ━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│   (N)   ┃ Notion              $8.00  │
│ ────────╂────────────────·─────────  │
│   (Y)   ┃ YouTube            $13.99  │
│ (Today)          (≡)           (✚)   │
└──────────────────────────────────────┘
```

### Vertical budget (calendar mode)
These are estimates, to be checked against screenshots in Verification. iPhone 17 Pro is 402×874pt: top safe area 62, inline bar ≈44, bottom bar ≈49, home indicator 34, which leaves **≈685pt of content**.

| Block | Before | After | Owner |
|---|---|---|---|
| Koyomi header | — (month is in the bar) | ≈80 | `calendar.md` |
| Total | ≈231 flex band (≤92 digits, ≈139 empty) | ≈118 typical: digits in `44...84` (or `36...68` with Large) + 6 + `BudgetMark` 28; ≈135 max | `calendar.md`, `price_display.md` |
| Spacer | VStack default 8 | `Spacer(minLength: 12)`, ≈73 on 17 Pro | this doc |
| Weekday header / band | 52 + 8 | ≈28 | `calendar.md` |
| Grid | 370 | 370 | `CalendarStyle.swift:58` |
| Bottom padding | 16 | 16 | this doc |
| **Sum** | 685 | ≥624, so ≈61pt spare on 17 Pro | |

**What this buys:**
- **Same height, more on it.** The earlier dead band and tall weekday header give way to the Koyomi header and compact weekday band. The header contains localized month and year only.
- **Nothing in the top centre.** The nav bar keeps its height (the leading and trailing items need it), but its centre slot is empty.
- **iPhone SE (3rd gen), 375×667:**
  - Content is ≈554pt (top 20, bar 44, bottom bar 49), and the stack needs ≥624. The overflow is ≈70pt.
  - Calendar mode is therefore wrapped in a `ScrollView` with `.scrollBounceBehavior(.basedOnSize)`. It stays still on tall phones and scrolls only on short phones or at large Dynamic Type.
  - The same wrapper lets content pass under the glass bars, so the glass has something to refract.

### Year grid sheet (restyled `MonthPickerSheet`)
- **Keep:** the type name and its init `MonthPickerSheet(calendarViewModel:onDone:)`, so `HomeView.swift:127-131` and the preview host still compile.
- **Replace:** the wheel `Picker` (`MonthPickerSheet.swift:9-19`) and the detent (`:28`).
- **Layout:**
  - `NavigationStack`, title = the shown year (for example "2026").
  - Prev/next-year chevrons top-leading.
  - `Done` (`checkmark`) at `.confirmationAction`.
  - `KasagiHeader()` (`Torii.swift:18-27`) is the lintel above the grid. It is the only Kasagi on this screen.
- **Grid:**
  - 3 columns × 4 rows; 2 columns when `dynamicTypeSize.isAccessibilitySize`.
  - Radius 0 (`AppRadius.grid`), a hairline `Rule()` under each cell, 16pt side gutter.
  - Detents `[.medium, .large]`. Four rows of ≈88pt plus the bar fit `.medium` on a 17 Pro.
- **Cell, top to bottom:**
  - month numeral: `.typography(.headlineMedium)` (22), `ink`, in a 40×40 frame
  - abbreviation `OCT`: `.typography(.labelMedium)` (11, auto-uppercase), `inkSecondary`
  - month total: `MoneyFormatter.format(calendarViewModel.total(for:), settings:)`, `.typography(.bodyMedium)`, `ink`, `lineLimit(1)`, `minimumScaleFactor(0.7)`
- **States:**

| State | Rule | Light | Dark |
|---|---|---|---|
| Today's month | static `EnsoShape(seed: EnsoShape.seed(for: Date()))` (the seed `calendar.md` uses for today's cell) filled `shu`, 40pt, behind the numeral (no draw-on in this sheet); numeral stays `ink` | ensō #C1352A | ensō #E84A33 |
| Shown month (`currentMonthIndex`) | 1pt `ink` `Rectangle().strokeBorder` (radius 0) + `.isSelected` trait | #1E1A17 | #F4EFE6 |
| Outside the −1…+12 window (`monthIndex(for:) == nil`) | `.disabled(true)`, all text `inkSecondary` + `.opacity(0.5)` (the `general_app_ui.md` disabled spec), total shown as `—` | | |
| Year chevrons at the first/last year in `months` | `.disabled(true)` | | |

- **Tap behaviour:** `calendarViewModel.currentMonthIndexBinding().wrappedValue = index`, then `onDone()`. That is the same single writer that paging and Today use.
- **Accessibility:** each cell is one element. Label `"October, $1,284.50"`. For a disabled cell, hint `"Outside the calendar range"`.

```
┌──────────────────────────────────────┐
│ (‹ ›)            2026           (✓)  │
│ ⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒ │ KasagiHeader (ink 2pt kasagi + 1pt rule)
│ ──────────────────────────────────── │
│  1          2           3            │ Jan–Aug 2026: outside window
│  JAN        FEB         MAR          │ inkSecondary @ 50 %, total "—",
│  —          —           —            │ not tappable
│ ──────────────────────────────────── │ hairline rule
│  …                                   │
│ ──────────────────────────────────── │
│  9          ◯10          11          │ ◯ = static shu ensō (this month)
│  SEP        OCT          NOV         │
│  $1,102.00  $1,284.50   $1,310.99    │
│            ┗━━━━━━━━━━┛ 1pt ink box = month shown on Home
└──────────────────────────────────────┘
```

### Filter sheet (`HomeFilterSheet`, new)
- **File:** `LinguicaSubTracker/Features/Home/Views/Components/HomeFilterSheet.swift` (new). It takes the existing `HomeViewModel` (`HomeFilterSheet(viewModel:)`).
- **No new filter state.** It reuses the exact `Picker` data the old `filterMenu` used (`HomeToolbar.swift:140-165`): `vm.lists/categories/paymentMethods` and `vm.listBinding()/categoryBinding()/paymentBinding()`.
- **Model:** Apple's Calendars sheet ([multiple calendars](https://support.apple.com/guide/iphone/use-multiple-calendars-iph3d1110d4/26.0/ios/26.0)). A checklist per dimension, applied live, with `Done` top-right.
- **Structure, top to bottom:**
  1. **Show All.** A row with a trailing `checkmark` when `!vm.isFilterActive`. Tap → `vm.clearFilter()`. This is the one-tap reset that Apple removed.
  2. **`SectionLabel("Lists")`** (hashira header, `Torii.swift:36-55`). An inline `Picker`: "All Lists" (`String?.none`) plus each list, with a 6pt square swatch in `Color(hex: list.colorHex)`.
  3. **`SectionLabel("Categories")`.** "All Categories" plus each category with a 6pt square swatch in `Color(hex: category.colorHex)`.
  4. **`SectionLabel("Payment Methods")`.** "All Payments" plus each method. There is no swatch, because `PaymentMethod` has no colour (`LinguicaSubTracker/Features/Settings/Models/PaymentMethod.swift:3-6`).
  - A section whose option array is empty is omitted.
- **Style:**
  - `.listStyle(.plain)`; rows on `paper` (`.scrollContentBackground(.hidden)` + `.appBackground()`, the same pattern `ExpensesInDay` uses for its sheet).
  - Separators `.listRowSeparatorTint(Color.rule)`; square corners.
  - Checkmarks `ink` via `.tint(Color.ink)` on the `List`, so AccentColor shu does not tint them (`general_app_ui.md`: selection is a checkmark in `ink`).
  - Swatches are user data, shown at icon size only.
  - Detents `[.medium, .large]`, drag indicator visible.
- **Badge:** `activeFilterCount = coordinator.filter.activeNames.count` (0–3) drives the bar badge.

```
┌──────────────────────────────────────┐
│               Filter            (✓)  │
│ Show All                             │  (✓ here when nothing is filtered)
│ ┃ LISTS                              │  SectionLabel: shu hashira + labelLarge
│ All Lists                         ✓  │  ink checkmark
│ ■ Personal                           │
│ ■ Work                               │
│ ┃ CATEGORIES                         │
│ All Categories                       │
│ ■ Entertainment                   ✓  │  ← active: badge on the bar shows 1
│ ┃ PAYMENT METHODS                    │
│ All Payments                      ✓  │
│ Visa                                 │
└──────────────────────────────────────┘
```

### Motion
- **View switch:** `.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewType)` on the Home body, with the default opacity transition. The `.spring` at `HomeToolbar.swift:114` is gone.
- **Today:**
  - `vm.jumpToCurrentMonth()` keeps the existing rewind overlay (`CalendarView.swift:50-66`, owned by `calendar.md`).
  - **Contract with `calendar.md`:** when `viewModel.rewindPair` returns to `nil` (`CalendarView.swift:57-61`), today's ensō replays its draw-on (0.55s ease-out, static under Reduce Motion). This is the "ensō redraw" that Today triggers.
- **Year grid:** a tap selects and dismisses with no extra animation. The ensō in the grid is static.
- **No bounce, ripple or glow anywhere on Home.** `symbolEffect` replace transitions on bar icons are removed with the custom glyphs.

### Light and dark specifics
- **Ground:** `paper` #F8F4E6 / #0E0C0B under every Home body and both sheets. The bars are system glass. On flat paper they read as frosted chips and refract only when the grid or list scrolls under them. That is expected ([Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)).
- **Text and glyphs:** `ink` in both modes: #1E1A17 light, #F4EFE6 dark. Disabled `Today` uses system dimming.
- **Red:** one filled shu (`+`) per screen. The Year grid ensō is a stroke shape. The filter badge is the system badge (see Risks).
- **Gold:** none in the chrome. `kin` appears only in the total's underline (`price_display.md`).

### Alternatives (documented, not recommended)

| Function | **A: Apple Calendar mapping (recommended)** | **B: bottom reach (Mail / Fantastical)** | **C: minimal wall calendar** |
|---|---|---|---|
| Month / year | `2026` top-leading → Year grid; header in content | Title "October" + `navigationSubtitle("2026")`; `toolbarTitleMenu` holds "Choose month…" and view mode | `2026` as plain text (`.sharedBackgroundVisibility(.hidden)`) → Year grid |
| View mode | Top-trailing view menu | Inside the title menu | Inside a top-trailing `…` menu |
| Filter | Bottom-centre button + sheet + badge | Bottom-leading filter `Menu` | Inside `…` |
| Search | Top-trailing | `DefaultToolbarItem(kind: .search, placement: .bottomBar)` + `.searchToolbarBehavior(.minimize)` | Inside `…` |
| Add | Bottom-trailing `+` (prominent) | Bottom-trailing `+` (prominent) | Bottom-trailing `+` (prominent) |
| Today | Bottom-leading text | Bottom-leading text | Bottom-leading text |
| Stats / Settings | Total tap + view menu | Total tap / top-trailing gear | Total tap / `…` |
| Groups (top / bottom) | 2 / 3 | 1–2 / 3 | 2 / 2 |
| Pros | Fixes all three complaints; every control has one job; matches the platform's own calendar | Best one-thumb reach; system search; Fantastical precedent ([gallery](https://developer.apple.com/design/new-design-gallery-2026)) | Calmest screen, closest to a paper wall calendar |
| Cons | Search sits top, not the iPhone 26 bottom default | **Keeps the month selector top-centre** (complaint 3); view mode is hidden behind a title chevron many users miss; an active filter must surface elsewhere | Creates the "junk drawer" `…` menu the HIG discourages; filter and search become hard to find |

The ring and the Add/Today swap disappear in every option. Stats stays on the total tap in every option.

### Future: a real Year-root `NavigationStack`
- **Shape:**
  - `NavigationStack(path:)` with a full-screen Year view as root.
  - The path is seeded with the current month, so launch lands on the month.
  - `‹ 2026` becomes a genuine Back, which is how Apple Calendar does it.
  - The Year grid sheet then becomes that root view.
- **Blocker:** the paged `TabView` (`CalendarView.swift:29-47`) uses horizontal swipes. A right-swipe that starts near the leading edge competes with the interactive pop gesture, so paging back one month could pop to the Year view instead.
- **Prerequisites:**
  - A gesture prototype (see Open points).
  - The "Back retraces a hierarchy" requirement in [HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars).
  - Not in v1.

## Implementation steps
Do steps 1–8 and 10–11 in order. The calendar header and `EnsoShape` are already available. Step 9 waits for `price_display.md` (`TotalView`) and `list_view.md` (`HomeListView`).

1. **Verify the foundation baseline.**
   - Already done by the foundation pass (verify): the items under "Already done by the foundation pass".
   - Build once before you touch anything, so later failures are yours.

2. **`LinguicaSubTracker/Features/Home/ViewModels/CalendarViewModel.swift`: add three members** after `monthKey` (`:42-44`). Do not touch `monthKey`; `LinguicaSubTrackerTests/CalendarViewModelTests.swift:44` asserts its format.
   ```swift
   /// Toolbar year label, e.g. "2026". Not `.formatted(.dateTime.year())`, which a
   /// Japanese-locale device renders as "2026年".
   var yearTitle: String { String(Calendar.current.component(.year, from: currentMonth)) }

   /// Page index for the month containing `date`; nil outside the −1…+12 window.
   func monthIndex(for date: Date) -> Int? {
       months.firstIndex { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
   }

   /// Filtered total for any month (Year grid), same math as TotalViewModel.total.
   func total(for month: Date) -> Double {
       ExpenseService.totalForMonth(coordinator.filtered(store.expenses), month: month)
   }
   ```
   - Then reuse `monthIndex(for: Date())`:
     - in `jumpToCurrentMonth()`, replacing the inline `firstIndex` at `:62-64`
     - in `syncToCurrentMonth()`, replacing it at `:97-99`
   - Behaviour is unchanged.

3. **`LinguicaSubTracker/Features/Home/ViewModels/HomeViewModel.swift`.**
   - **Delete:**
     - `monthlyTotal` (`:27-32`)
     - `budgetRatio` (`:34-37`)
     - `budgetTint` (`:39-41`)
     - `filterLabel` (`:43-48`)
     - `clearSelectedDay()` (`:85`)
   - **Add** next to the other sheet flags (`:8-11`):
     ```swift
     var showFilter = false
     ```
   - **Add** next to `isFilterActive` (`:50`):
     ```swift
     var activeFilterCount: Int { coordinator.filter.activeNames.count }
     ```
   - **Keep everything else:** bindings, `clearFilter`, `jumpToCurrentMonth`, `didTapAdd`, `isOnCurrentMonth`, `selectedDay*` and `selectedExpense*`.

4. **Rewrite `LinguicaSubTracker/Features/Home/Views/Components/HomeToolbar.swift`.**
   - In `HomeViewType` (`:3-19`), replace `targetIcon` (`:9-14`) and `toggle()` (`:16-18`) with `icon` (the current mode's symbol). Keep the "Not persisted" comment.
   - Verify `monthButton`, `monthKey`, and the toolbar's `onMonthPicker` callback were removed by `calendar.md`; delete `leadingPill`, `filterMenu`, and the ring.
   - Replace the struct with:
   ```swift
   /// Which body the Home screen shows. Not persisted — resets to calendar on launch.
   enum HomeViewType {
       case calendar, list
       /// Symbol of the view currently shown (Apple Calendar's view-menu icon).
       var icon: String { self == .calendar ? "calendar" : "list.bullet" }
   }

   /// Apple Calendar layout: year top-leading, view menu + search top-trailing,
   /// Today · Filter · Add along the bottom.
   struct HomeToolbar: ToolbarContent {
       let yearTitle: String
       let isOnCurrentMonth: Bool
       let activeFilterCount: Int
       @Binding var viewType: HomeViewType
       var onYear: () -> Void
       var onToday: () -> Void
       var onFilter: () -> Void
       var onAdd: () -> Void
       var onSearch: () -> Void
       var onStats: () -> Void
       var onSettings: () -> Void

       var body: some ToolbarContent {
           ToolbarItem(placement: .topBarLeading) {
               Button(action: onYear) { Text(yearTitle).typography(.titleMedium) }
                   .accessibilityLabel("Year \(yearTitle)")
                   .accessibilityHint("Shows the year to pick a month")
           }
           ToolbarItemGroup(placement: .topBarTrailing) {
               Menu {
                   Picker("View", selection: $viewType) {
                       Label("Calendar", systemImage: "calendar").tag(HomeViewType.calendar)
                       Label("List", systemImage: "list.bullet").tag(HomeViewType.list)
                   }
                   Divider()
                   Button("Stats", systemImage: "chart.pie", action: onStats)
                   Button("Settings", systemImage: "gearshape", action: onSettings)
               } label: {
                   Label("View options", systemImage: viewType.icon)
               }
               .accessibilityValue(viewType == .calendar ? "Calendar" : "List")
               Button("Search", systemImage: "magnifyingglass", action: onSearch)
           }
           ToolbarItem(placement: .bottomBar) {
               Button(action: onToday) { Text("Today").typography(.titleMedium) }
                   .disabled(isOnCurrentMonth)
                   .accessibilityHint("Goes to the current month")
           }
           ToolbarSpacer(.flexible, placement: .bottomBar)
           ToolbarItem(placement: .bottomBar) {
               Button("Filter", systemImage: "line.3.horizontal.decrease", action: onFilter)
                   .badge(activeFilterCount)
                   .accessibilityValue(activeFilterCount == 0 ? "Showing all" : "\(activeFilterCount) active")
           }
           ToolbarSpacer(.flexible, placement: .bottomBar)
           ToolbarItem(placement: .bottomBar) {
               Button(action: onAdd) {
                   Label("Add Expense", systemImage: "plus").foregroundStyle(Color.paper)
               }
               .buttonStyle(.glassProminent)
               .tint(Color.shu)
           }
       }
   }
   ```
   - No `.font(.system(size:))` and no `.foregroundStyle` on the non-primary glyphs: the system renders them monochrome.
   - Screenshot both modes. If any non-primary glyph renders shu (because AccentColor is shu), add `.tint(Color.ink)` to **that item only**, never to a container that holds the `+` (`general_app_ui.md` risk "The accent now tints everything untinted").
   - Update the `#Preview` (`:174-211`) to the new initializer.

5. **Delete `LinguicaSubTracker/Features/Home/Views/Components/HomeActionButton.swift`** (whole file, including its `#Preview`).
   - The app target uses a synchronized root group, so no `project.pbxproj` edit is needed.
   - Two Lab doc comments mention it. Make them say "the bottom-bar `+` and `Today`" instead:
     - `LinguicaSubTracker/Core/Lab/SpeechCapture/Views/SpeechCaptureLayer.swift:11-12`
     - `LinguicaSubTracker/Core/Lab/SpeechCapture/Views/SpeechPillButton.swift:3-4`
   - These are comment-only edits.

6. **Rewrite the `MonthPickerSheet` body as the Year grid** (`LinguicaSubTracker/Features/Home/Views/Components/MonthPickerSheet.swift`).
   - Keep `let calendarViewModel: CalendarViewModel` and `var onDone: () -> Void` (`:4-5`).
   - Add:
     - `@Environment(SettingsStore.self) private var settingsStore`. It is injected at the app root (`LinguicaSubTrackerApp.swift:54`), and sheets inherit it.
     - `@Environment(\.dynamicTypeSize) private var typeSize`
     - `@State private var year`, set in `.onAppear` to the year of `calendarViewModel.currentMonth`
   - **Years:** `Set(calendarViewModel.months.map { Calendar.current.component(.year, from: $0.date) }).sorted()`. That gives two years normally, and three when today is in January.
   - **Body:** `ScrollView { KasagiHeader(); LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: typeSize.isAccessibilitySize ? 2 : 3), spacing: 0) { ForEach(1...12, id: \.self) { cell(month: $0) } } }`, with 16pt horizontal padding and `.appBackground()`.
   - **Month date:** `Calendar.current.date(from: DateComponents(year: year, month: month))!`
   - **Cell:**
     ```swift
     let index = calendarViewModel.monthIndex(for: date)
     Button {
         guard let index else { return }
         calendarViewModel.currentMonthIndexBinding().wrappedValue = index
         onDone()
     } label: { /* numeral (+ static EnsoShape when this month), OCT, total or "—" — see Target design */ }
     .buttonStyle(.plain)
     .disabled(index == nil)
     .overlay(alignment: .bottom) { Rule() }
     ```
   - Apply the state table from Target design (ensō, the shown-month box, disabled styling, accessibility).
   - **Nav:**
     - `.navigationTitle(String(year))`, `.navigationBarTitleDisplayMode(.inline)`
     - `ToolbarItemGroup(placement: .topBarLeading)` with `Button("Previous Year", systemImage: "chevron.left")` / `Button("Next Year", systemImage: "chevron.right")`, disabled at the bounds of the years list
     - `ToolbarItem(placement: .confirmationAction) { Button("Done", systemImage: "checkmark", action: onDone) }`
   - **Detents:** replace `.presentationDetents([.height(260)])` (`:28`) with `[.medium, .large]`. Keep `.presentationDragIndicator(.visible)` (`:29`).
   - **Preview host** (`LinguicaSubTracker/Features/Home/Views/Previews/MonthPickerSheetPreviewHost.swift:10`): append `.environment(HomePreviewData.makeSettingsStore())` (the helper is at `LinguicaSubTracker/Features/Home/Views/Previews/HomePreviewData.swift:29`).
   - **If `EnsoShape` does not exist yet** (`calendar.md` creates `LinguicaSubTracker/Core/UI/Motifs/EnsoShape.swift` (new)): stop and land `calendar.md` first. Do not ship a temporary shu numeral; nobody owns removing it later.

7. **Create `LinguicaSubTracker/Features/Home/Views/Components/HomeFilterSheet.swift` (new)** to the Target design spec. Skeleton:
   ```swift
   struct HomeFilterSheet: View {
       let viewModel: HomeViewModel
       @Environment(\.dismiss) private var dismiss

       var body: some View {
           NavigationStack {
               List {
                   Button { viewModel.clearFilter() } label: {
                       HStack { Text("Show All"); Spacer(); if !viewModel.isFilterActive { Image(systemName: "checkmark") } }
                   }
                   .accessibilityAddTraits(viewModel.isFilterActive ? [] : .isSelected)
                   section("Lists", viewModel.listBinding(), all: "All Lists",
                           viewModel.lists.map { ($0.name, Optional($0.colorHex)) })
                   section("Categories", viewModel.categoryBinding(), all: "All Categories",
                           viewModel.categories.map { ($0.name, Optional($0.colorHex)) })
                   section("Payment Methods", viewModel.paymentBinding(), all: "All Payments",
                           viewModel.paymentMethods.map { ($0.name, nil) })
               }
               .listStyle(.plain)
               .scrollContentBackground(.hidden)
               .listRowSeparatorTint(Color.rule)
               .tint(Color.ink)
               .appBackground()
               .navigationTitle("Filter")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .confirmationAction) {
                       Button("Done", systemImage: "checkmark") { dismiss() }
                   }
               }
           }
           .presentationDetents([.medium, .large])
           .presentationDragIndicator(.visible)
       }

       @ViewBuilder
       private func section(_ title: String, _ selection: Binding<String?>, all: String,
                            _ options: [(name: String, hex: String?)]) -> some View {
           if !options.isEmpty {
               Section {
                   Picker(title, selection: selection) {
                       Text(all).tag(String?.none)
                       ForEach(options, id: \.name) { option in
                           HStack(spacing: 8) {
                               if let hex = option.hex {
                                   Rectangle().fill(Color(hex: hex)).frame(width: 6, height: 6)
                                       .accessibilityHidden(true)
                               }
                               Text(option.name)
                           }
                           .tag(String?.some(option.name))
                       }
                   }
                   .pickerStyle(.inline)
                   .labelsHidden()
               } header: { SectionLabel(title) }
           }
       }
   }
   ```
   - Rows must sit on `paper`, not on the system row background. If the plain list paints rows white or black, add `.listRowBackground(Color.clear)` to the Show All button and to each `Picker`. Do the same with `.listRowSeparatorTint(Color.rule)` if the `List`-level modifier does not reach the rows (verify on device).
   - The `#Preview` builds `HomeViewModel(store: HomePreviewData.makeStore(), settingsStore: HomePreviewData.makeSettingsStore(), coordinator: AppCoordinator())`.

8. **`LinguicaSubTracker/Features/Home/Views/HomeView.swift`: wire up the chrome.**
   - Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion`.
   - Replace the `HomeToolbar(...)` call (`:105-125`):
     ```swift
     HomeToolbar(
         yearTitle: vm.calendarViewModel.yearTitle,
         isOnCurrentMonth: vm.isOnCurrentMonth,
         activeFilterCount: vm.activeFilterCount,
         viewType: $viewType,
         onYear: { showMonthPicker = true },
         onToday: {
             vm.jumpToCurrentMonth()
             // CalendarView isn't mounted in list mode; don't leave a rewind queued
             // to play the next time the user switches to calendar.
             if viewType == .list { vm.calendarViewModel.rewindPair = nil }
         },
         onFilter: { vm.showFilter = true },
         onAdd: { vm.didTapAdd() },
         onSearch: { vm.showSearch = true },
         onStats: { vm.showStats = true },
         onSettings: { vm.showSettings = true }
     )
     ```
   - Add `.sheet(isPresented: $vm.showFilter) { HomeFilterSheet(viewModel: vm) }` next to the other sheets (`:140-195`).
   - Add `.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewType)` to the body container (the `VStack` at `:33` until step 9 replaces it).
   - **DEBUG hook:** inside the existing `#if DEBUG` block (`:82-102`), add:
     ```swift
     // SIMCTL_CHILD_DEBUG_OPEN_SHEET=year|filter ("budget" stays in HomeListView)
     switch ProcessInfo.processInfo.environment["DEBUG_OPEN_SHEET"] {
     case "year": showMonthPicker = true
     case "filter": vm.showFilter = true
     default: break
     }
     ```
   - Keep the `showMonthPicker` name and the sheet at `:127-131`. That sheet is now the Year grid.

9. **`HomeView.swift`: content composition.** Do this after `calendar.md` and `price_display.md`.
   - `calendar.md` keeps `KoyomiHeader(viewModel:onMonthPicker:)` in `HomeView` and anchors the calendar below the total. Preserve that order and the header in both modes, passing `onMonthPicker: { showMonthPicker = true }`; the same sheet now shows the Year grid.
   - Replace the `VStack` at `:33-63` with:
     ```swift
     Group {
         if viewType == .calendar {
             ScrollView {
                 VStack(spacing: 0) {
                     KoyomiHeader(viewModel: vm.calendarViewModel,
                                  onMonthPicker: { showMonthPicker = true })
                         .padding(.horizontal, 12)
                     TotalView(store: vm.store, settingsStore: vm.settingsStore,
                               coordinator: coordinator, calendarViewModel: vm.calendarViewModel,
                               action: { vm.showStats = true })
                         .accessibilityHint("Opens stats")
                     Spacer(minLength: 12)
                     CalendarView(store: vm.store, coordinator: coordinator,
                                  viewModel: vm.calendarViewModel,
                                  calendarStyle: vm.settingsStore.calendarStyle) // keep the read here (:49-51 comment)
                 }
                 .padding(.bottom, 16)
                 .frame(minHeight: viewportHeight, alignment: .top)
             }
             .scrollBounceBehavior(.basedOnSize)
             .scrollIndicators(.hidden)
             .onScrollGeometryChange(for: CGFloat.self) {
                 $0.containerSize.height - $0.contentInsets.top - $0.contentInsets.bottom
             } action: { _, height in viewportHeight = height }
         } else {
             VStack(spacing: 0) {
                 KoyomiHeader(viewModel: vm.calendarViewModel,
                              onMonthPicker: { showMonthPicker = true })
                     .padding(.horizontal, 12)
                 HomeListView(store: vm.store, settingsStore: vm.settingsStore,
                              coordinator: coordinator, calendarViewModel: vm.calendarViewModel,
                              onStats: { vm.showStats = true })
             }
         }
     }
     ```
   - Add `@State private var viewportHeight: CGFloat = 0`.
   - The `.frame(maxWidth: .infinity, maxHeight: .infinity)` on `TotalView` (`:44`) and the `.padding(.bottom, 16)` on `CalendarView` (`:53`) are removed. The spacer and the min-height frame take over their roles.
   - Keep `.appBackground()` (`:64`), `.navigationBarTitleDisplayMode(.inline)` (`:65`), every `.onChange`, `.onAppear` and sheet unchanged.
   - Optional, behind a screenshot check: `.scrollEdgeEffectStyle(.hard, for: .top)` on the calendar `ScrollView`, the sharper edge [WWDC25-323](https://developer.apple.com/videos/play/wwdc2025/323/) suggests for dense calendar screens.

10. **Test** (`LinguicaSubTrackerTests/CalendarViewModelTests.swift`): add one case. This is the only new logic with branches.
    ```swift
    @Test("Year grid maps a date to its page and disables months outside the window")
    func monthIndexForYearGrid() throws {
        let vm = CalendarViewModel(store: AppStore(), coordinator: AppCoordinator())
        vm.onAppear()
        let index = try #require(vm.monthIndex(for: Date()))
        #expect(Calendar.current.isDate(vm.months[index].date, equalTo: Date(), toGranularity: .month))
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
        #expect(vm.monthIndex(for: threeYearsAgo) == nil)
        #expect(vm.yearTitle == String(Calendar.current.component(.year, from: vm.currentMonth)))
    }
    ```
    The two existing tests must still pass unchanged (`:10-25`, `:30-46`).

11. **Cleanup grep.** This must return nothing under `LinguicaSubTracker/`:
    ```
    grep -rnE "HomeActionButton\(|leadingPill|filterMenu|monthButton|ring\.dashed|targetIcon|filterLabel|clearSelectedDay|budgetRatio|onBackToCurrent: \{ vm" LinguicaSubTracker --include='*.swift'
    ```
    `SpeechCaptureLayer` keeps its own `onBackToCurrent` parameter (Lab, preview-only). Leave it.

## Preserve
- **Filter state and API:**
  - `coordinator.filter` (`AppCoordinator.swift:24`)
  - `vm.listBinding()/categoryBinding()/paymentBinding()` (`HomeViewModel.swift:58-68`)
  - `vm.clearFilter()` (`:56`)
  - `vm.isFilterActive` (`:50`)
  - The filter still applies live, and `.onChange(of: coordinator.filter)` → `onFilterChange()` (`HomeView.swift:71-73`) still refreshes `months`.
- **Month state:**
  - `currentMonthIndexBinding()` stays the single writer (`CalendarViewModel.swift:46-51`) for paging, the Year grid, Today and `DEBUG_MONTH_INDEX`.
  - `jumpToCurrentMonth()` and the `rewindPair` cue (`:58-70`).
  - `isOnCurrentMonth` (`:38-40`, via `HomeViewModel.swift:25`).
  - `monthKey` format (`:42-44`, asserted at `CalendarViewModelTests.swift:44`). It is still used by `TotalViewModel.swift:22`.
- **Sheets and covers** (`HomeView.swift:127-195`):
  - month picker (now the Year grid)
  - DEBUG widget gallery
  - add (`SimplifiedAddExpenseView`)
  - Settings (`.large`)
  - Stats (`.large`)
  - Search (`fullScreenCover`)
  - selected-day: `ExpensesInDay`, or Add when the day is empty
  - selected-expense: `ExpenseSummarySheet`
- **Widget deep link:** `satoru://add`, from `AppCoordinator.handle` (`AppCoordinator.swift:31,36`) through `.onChange(of: coordinator.didRequestAdd)` (`HomeView.swift:75-79`) to `vm.didTapAdd()`.
- **`.onChange(of: store.expenses)`** → `onExpensesChange()` (`HomeView.swift:68-70`).
- **DEBUG hooks:**
  - `SIMCTL_CHILD_DEBUG_HOME_VIEW=list|calendar` (`HomeView.swift:85-89`)
  - `SIMCTL_CHILD_DEBUG_MONTH_INDEX=<n>` (`:93-99`)
  - `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=<section>` (`:101`, `:133-138`)
  - `SIMCTL_CHILD_DEBUG_OPEN_SHEET=budget` (`HomeListView.swift:59-64`)
  - plus the new `year|filter`
- **`viewType` is not persisted:** `@State` at `HomeView.swift:8`, documented at `HomeToolbar.swift:3`. Persisting it is an open point.
- **Stats from the total:** `TotalView`'s `Button(action:)` (`HomeView.swift:40-42`) and `HomeListView`'s `onTapGesture: onStats` (`HomeListView.swift:76`).
- **Live calendar style:** `vm.settingsStore.calendarStyle` is read in `HomeView` (`:51`), so the calendar re-renders when the style changes. Keep the read there.
- **`@AppStorage("budget_cta_dismissed")`** (`HomeListView.swift:17`).
- **Previews:** these must still compile and render:
  - `HomeViewPreviewHost` (`LinguicaSubTracker/Features/Home/Views/Previews/HomeViewPreviewHost.swift`)
  - `MonthPickerSheetPreviewHost`
  - the `HomeToolbar` `#Preview`
  - the new `HomeFilterSheet` `#Preview`
- **Accessibility:**
  - every bar item has a spoken label (table above)
  - the view menu exposes the current mode as its value, which replaces the label at `HomeToolbar.swift:123`
  - Year-grid cells and filter rows expose `.isSelected`

## Risks / gotchas
- **`.badge` on a `ToolbarItem`.**
  - [WWDC25-323](https://developer.apple.com/videos/play/wwdc2025/323/) shows badges on toolbar items. The sketch puts `.badge(activeFilterCount)` on the `Button` inside the item (the form the research verified). If no badge renders, move it to the `ToolbarItem` (verify on device).
  - The system badge is a small filled red circle, so it could read as a second red fill next to the `+`.
  - **Fallback if it reads that way in screenshots:** drop the badge and switch the symbol to `line.3.horizontal.decrease.circle.fill` when `activeFilterCount > 0`. Keep the `accessibilityValue`.
- **AccentColor is shu.** Plain toolbar items, `Menu` checkmarks and the filter-sheet checkmarks may render shu.
  - Toolbar: add `.tint(Color.ink)` per item, never on a container that also holds the `+`.
  - Sheet: `.tint(Color.ink)` on the `List` (step 7).
- **Toolbar text font.** UIKit bar-button titles do not inherit the SwiftUI environment font. That is why `2026` and `Today` use a custom `Text(...).typography(.titleMedium)` label; `HomeActionButton.swift:22` already did this inside the bar. If they still render in SF, file it under the open point on toolbar fonts. Do not hack it with `UIBarButtonItem.appearance()`, which would also restyle system Done buttons.
- **`.glassProminent` + `.tint` inside a `ToolbarItem`.** Verify the fill is shu, not system blue or the default accent. The label must render `paper`; the system may force white, which is acceptable. `Button(role: .confirm)` is the documented alternative (open point).
- **`general_app_ui.md` vs the working tree:**
  - The doc describes re-pointing `appAccent`/`appSurface`. The working tree **deleted** them (no `appAccent`/`appSurface` symbol exists). Use `Color.shu`, `Color.paperRaised` and `Color.paper` directly.
  - `Theme.font(size:relativeTo:)` has no `weight:` parameter (`Theme.swift:8-10`), and `AppTypography.Style` has no `.weight()` (`Typography.swift:24` has only `.size(_:)`).
  - Do not chain weights in any new code.
- **The month window is −1…+12** (`CalendarService.swift:20`). The Year grid **must** disable months whose `monthIndex(for:)` is `nil`. Writing an out-of-range index would be clamped by `syncDisplayedMonth()` (`CalendarViewModel.swift:104-112`) while `currentMonthIndex` stays wrong, so the `TabView` selection would desync.
- **Deferred rewind.** `jumpToCurrentMonth()` sets `rewindPair` even when `CalendarView` is not mounted (`CalendarViewModel.swift:66-68`). Without step 8's list-mode reset, the rewind plays later, the moment the user switches to calendar. The behaviour existed before this change, but an always-visible Today makes it easy to trigger.
- **Wrapping in a `ScrollView`:**
  - The paged `TabView` must keep a fixed height (`CalendarView.swift:69`, later `calendar.md`'s value), or it collapses to zero inside the vertical scroll.
  - Calendar-mode content now scrolls under the glass bars. Check `DayCell`'s `contextMenu` and the long-press preview still work, and that vertical scrolling doesn't steal horizontal page swipes.
- **Koyomi header location.** `calendar.md` mounts the header in `HomeView`, outside `CalendarView`, so list mode keeps the month label and rewind never hides it. Step 9 must keep it outside `CalendarView` in both branches and retain its `onMonthPicker` callback.
- **Deleting `HomeViewModel.budgetTint`** drops one `BudgetColor.color` caller. `charts.md` and `general_app_ui.md` list "HomeViewModel" among its callers. Expect one fewer, and keep the signature for the rest.
- **Search stays top-trailing,** which differs from the iOS 26 iPhone default (bottom-bar search). This is a deliberate trade-off. Layout B is the one with system bottom search.
- **`Picker` in `Menu` doesn't animate on its own.** The view-mode change is animated by the `HomeView`-level `.animation(_:value:)` (step 8), not inside the toolbar.
- **Stale builds.** If screenshots show the old pill after a successful build, the compilation cache served stale objects. Delete `DerivedData/.../Build/Intermediates.noindex` and rebuild with `COMPILATION_CACHE_ENABLE_CACHING=NO`.

## Verification
1. **Build:**
   ```
   xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build
   ```
   This is the iPhone 17 Pro simulator on iOS 26.4. Use the UDID, not a name.
2. **Tests:** `xcodebuild … test -only-testing:LinguicaSubTrackerTests/CalendarViewModelTests`. All three cases must pass.
3. **Grep:** step 11 returns nothing. `LinguicaSubTracker/Features/Home/Views/Components/HomeActionButton.swift` no longer exists.
4. **Screenshots** (cold launch, wait ≈8s before `xcrun simctl io <udid> screenshot`), in **light and dark**. Switch the theme with Settings → Appearance through the simulator `control` taps.

   | Launch env (`SIMCTL_CHILD_…`) | Check |
   |---|---|
   | `DEBUG_HOME_VIEW=calendar` | Top: `2026` alone leading; one trailing group (view icon `calendar` + search); empty centre. Bottom: Today dimmed · Filter · shu `+`. No ring. All non-primary glyphs ink. Exactly one filled shu shape. |
   | `DEBUG_HOME_VIEW=calendar DEBUG_MONTH_INDEX=0` | After 2s the month changes. **Today becomes enabled and `+` is still there.** |
   | `DEBUG_HOME_VIEW=list` | Same bars; view icon `list.bullet`; Koyomi header and total in the same place as calendar mode. |
   | `DEBUG_OPEN_SHEET=year` | 3×4 grid; this month has a shu ensō; the shown month has a 1pt ink box; Jan–Aug 2026 dimmed with "—"; totals in Fragment Mono; ‹ disabled at 2026, › moves to 2027. |
   | `DEBUG_OPEN_SHEET=filter` | Show All ✓; three `SectionLabel` sections with ink checkmarks; rows on paper; swatches square. |
   | `DEBUG_OPEN_SHEET=budget DEBUG_HOME_VIEW=list` | Existing hook still opens `BudgetDetailsSheet`. |

5. **Interaction** (simulator `control` taps):
   - Pick a category in Filter. The bar badge shows 1, the calendar and total update live, and Show All resets the badge to none.
   - Tap Nov in the Year grid. The sheet closes and Home shows November.
   - Tap Today. The rewind plays, then today's ensō draws on (the `calendar.md` contract).
   - Tap the total. Stats opens.
   - View menu → Stats / Settings open their sheets.
   - In list mode tap Today, switch to calendar, and confirm **no** rewind replays.
6. **Deep link:** `xcrun simctl openurl <udid> satoru://add` opens the add sheet from both modes.
7. **Small screen:**
   - Create an iPhone SE (3rd generation) simulator (`xcrun simctl create "SE3" "iPhone SE (3rd generation)"`) if none exists.
   - Calendar mode must scroll by about 70pt with nothing clipped. On the 17 Pro it must not bounce.
   - Measure the real bar heights against the budget table and correct the table if they are off by more than 8pt.
8. **Accessibility:**
   - **Accessibility Inspector:** every bar item has a label. The view menu's value is "Calendar"/"List". Filter's value is "Showing all"/"N active". Year-grid cells read "October, $1,284.50"; disabled cells read as dimmed.
   - **Largest Dynamic Type (AX5):** the Year grid switches to 2 columns, and the totals shrink rather than truncate.
   - **Reduce Motion:** the view switch is instant and the ensō is static.
   - **Reduce Transparency:** the bars stay legible.
9. **Previews:** `HomeViewPreviewHost`, `MonthPickerSheetPreviewHost`, the `HomeToolbar` preview and the `HomeFilterSheet` preview all render.

## Open points / dig deeper
- **Check iOS 26 Calendar on a device.**
  - What to check: is the top-leading year text-only, do search, view menu and `+` share one glass capsule, and is the current month's title still red?
  - Why: the mapping above relies on Apple Support text, not on a device capture.
- **iOS 27 is shipping.**
  - What to check: review Calendar's iOS 27 layout and any new SwiftUI toolbar APIs before locking layout A.
  - Why: the reference app may have moved since iOS 26.
- **Year-root `NavigationStack`** (future).
  - What to check: prototype the paged `TabView` against the swipe-from-edge Back gesture. Does a right swipe near the leading edge page or pop?
  - Why: a real hierarchy is the only way to make `‹ 2026` a true Back.
- **Toolbar badge.**
  - What to check (verify on device): the colour and shape of `.badge` on iOS 26 toolbar items, and whether `Button.badge` (used in the sketch) or a `ToolbarItem`-level badge is the supported form.
  - Why: it may count as a second red fill and break the one-shu rule.
- **`.glassProminent` tint in toolbars.**
  - What to check: does it follow `.tint(Color.shu)`, or is `Button(role: .confirm)` the supported route for a tinted primary item?
  - Why: it decides whether the CTA is reliably shu.
- **Active-filter visibility.**
  - What to check: is the badge enough, or should a one-line filter summary sit under the Koyomi header (for example `FILTER · Entertainment · Visa`), the way B would use the subtitle?
  - Why: a count does not say *what* is filtered.
- **Persist `viewType`.**
  - What to check: `@AppStorage("home_view_type")` with a `String` raw value, **not** `AppSettings`. Any `AppSettings` field would have to be optional with lenient decoding, or a decode failure wipes settings.
  - Why: the user might expect Home to reopen in list mode. This is a product call.
- **Extend the month window** (`CalendarService.swift:20`).
  - What to check: generate whole calendar years (for example the previous year through the next year) so no Year-grid cell is disabled. Measure the `CalendarCache.monthData` cost per extra month and the effect on the widget's assumptions.
  - Why: disabled past months in a year view look broken.
- **Year grid content.**
  - What to check: should cells add mini month thumbnails like Apple's Year view, or a per-month budget tick?
  - Why: the totals alone are easy to scan but say little about the shape of the month. Measure readability at AX sizes.
- **Search as system search.**
  - What to check: move `SearchView` from `fullScreenCover` to `.searchable` + `.searchToolbarBehavior(.minimize)`.
  - Why: it is needed if layout B is ever adopted, and it would also free the top-trailing slot in A.
- **Toolbar fonts.**
  - What to check: does a custom `Text` label in an iOS 26 glass toolbar keep Fragment Mono, and do `UINavigationBarAppearance` attributes still reach glass bars?
  - Why: `2026` and `Today` must not render in SF.
- **Today semantics.**
  - What to check: Apple keeps Today always enabled (it scrolls to today). Should Satoru's Today stay enabled on the current month, scroll list mode to today's header, and replay the ensō?
  - Why: a disabled control is less discoverable.
- **`+` long-press menu.**
  - What to check: `Menu(primaryAction:)` on the `+` for "Speak an expense" (`FF_QUICK_ADD`) and "Scan receipt" (`FF_SMART_RECEIPTS`).
  - Why: it reaches the flagged add flows without adding bar items.
- **List scrolls under the bottom bar.** `list_view.md` defers this here: drop `HomeListView`'s `.padding(.bottom, 8)` (`HomeListView.swift:55`) and let the list extend into the bottom safe area so the glass bar has content to refract. Check that the last row stays reachable above the bar.
- **List-mode density.**
  - What to check: a compact Koyomi header variant in list mode, and whether coin piles should move into Stats.
  - Why: header + total + coins can leave only about 6 rows on an SE.
- **Reduce Transparency / Increase Contrast.**
  - What to check: bar legibility over paper, and whether the shu `+` keeps ≥3:1 for its glyph under both settings.
  - Why: glass contrast changes with these settings, and the iOS 26.1 Clear/Tinted glass option adds another variable.

**Status: proposed, not implemented.**
