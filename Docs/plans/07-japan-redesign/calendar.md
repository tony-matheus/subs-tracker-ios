# Calendar — Japanese wall calendar (Koyomi) month view

## Goal
- **What the user asked for:**
  - "Search for the common models for real world Calendar design in japan, it's structure, element positioning."
  - "Try to match the elements with a plan to the current calendar behaviour."
  - Follow the reference photo and notesofnomads.com, "but remember to leave space for the expenses on that month, the elements of each expense should still be present, the variations may change after first version is done".
  - "To indicate which day of the week it is use a brush circling the day in a non-closed imperfect circle."
- **What this doc delivers:**
  - **Koyomi (暦) month header:** era year, a giant shu month numeral, the English month with its 和風月名, a 二十四節気 line, and faint previous/next month labels that page the calendar.
  - **Sumi weekday band:** `SUN` + `日` … `SAT` + `土`, with Sunday in shu and Saturday in `ai`.
  - **Hairline grid cells:** the numeral sits top-left, holidays get a shu numeral plus a `祝` mark, and the lower "memo line" area holds **every expense element the cell shows today**.
  - **Ensō (円相) today marker:** an open brush circle with a seeded imperfect shape and a 0.55s draw-on.
  - **Shared data:** a static JP holiday table (2026–2027), month names and solar terms.
  - **A new `.koyomi` `CalendarStyle`**, which becomes the default.
  - **Rewind and widget:** an ink-wipe rewind and the widget's today ensō.
- **Not in this doc (pointers):**
  - Toolbar, Year grid and the Home layout: `home_screen_ux.md`.
  - `ExpensesInDay` rows: `list_view.md`.
  - The "CAD" fix and `MoneyFormatter`: `price_display.md`.

**Depends on:**
- `general_app_ui.md`, already applied in the working tree. It provides:
  - the tokens `paper`, `paperRaised`, `ink`, `inkSecondary`, `rule`, `ruleStrong`, `shu`, `ai` (`LinguicaSubTracker/Core/Utils/AppTheme.swift:52-63`)
  - `AppFont` (`:66-70`) and `AppRadius` (`:72-75`)
  - `KasagiHeader` / `Rule` (`LinguicaSubTracker/Core/UI/Motifs/Torii.swift:18-27`, `:57-69`)
  - Fragment Mono, and ripple removal from `MonthView`/`DayCell`
- `list_view.md` step 2: the `LogoCircle(glass:)` parameter. `list_view.md` runs after this doc, so do that one step first; it is self-contained and `list_view.md` then verifies it.
- `price_display.md` step 4: the `"CAD"` → `MoneyFormatter` fix in `ExpensesInDay` (verified in step 14, not edited here).
- `home_screen_ux.md`:
  - It deletes the toolbar month title (`HomeToolbar.swift:90-106`).
  - It owns the final `HomeView` composition (its step 9), which mounts this doc's `KoyomiHeader`.
  - The two docs can land in either order (see step 13).

**References:**
- Formats:
  - [Mynavi](https://osusume.mynavi.jp/articles/5589/)
  - [Maruzen](https://www.maruzenjunkudo.co.jp/products/4517163855409)
  - [NDL 暦](https://www.ndl.go.jp/koyomi/chapter3/index.html)
  - [DreamNews 文字月表](https://www.dreamnews.jp/index.php/press/0000280557)
  - [Hobonichi](https://www.1101.com/store/techo/en/2021/all_about/dayfree/about03.html)
  - [MUJI](https://www.muji.com/jp/ja/shop/045835/articles/muji-staff/1631841)
  - [bungu.store MD](https://bungu.store/products/md-bi-fold-wall-calendar-2026-midori)
- Data:
  - [CAO holidays](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html)
  - [NAOJ 暦要項 2026](https://eco.mtk.nao.ac.jp/koyomi/yoko/2026/rekiyou262.html)
  - [NDL 和風月名](https://www.ndl.go.jp/koyomi/chapter3/s8.html)
  - [bestcalendar 和風月名](https://bestcalendar.jp/guides/koyomi/wafu-getsumei)
  - [gihyo era format](https://gihyo.jp/dev/serial/01/swift-introduction/0050)
- Conventions:
  - [Berlitz](https://www.berlitz.com/blog/days-of-the-week-japanese)
  - [FinancialField week start](https://financial-field.com/living/entry-377145)
  - [TalkPhotography 5 vs 6 rows](https://www.talkphotography.co.uk/threads/calendar-with-5-or-6-rows-which-do-you-think-is-best.686047/)
- Ensō:
  - [Wikipedia Ensō](https://en.wikipedia.org/wiki/Ens%C5%8D)
  - [calligraphy terms](https://selftaughtjapanese.com/2020/08/25/japanese-vocabulary-list-calligraphy-terms)
  - [Swift Forums variable-width strokes](https://forums.swift.org/t/drawing-strokes-with-a-different-width-at-each-point-of-the-lines-curves/40068)
  - [HWS trim](https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-part-of-a-solid-shape-using-trim)
- Platform:
  - [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
  - [Fontsource Fragment Mono](https://fontsource.org/fonts/fragment-mono/about)
- Reference photo: notesofnomads.com wall calendar (described in Target design §1).

**Doc set (pointers, not duplicated here):**

| Doc | Owns |
|---|---|
| `general_app_ui.md` | tokens, font, shapes, glass rules, `Torii.swift` motifs, ripple removal, widget base |
| `calendar.md` (this) | Koyomi header, weekday band, day cells, `EnsoShape`/`EnsoMark` spec + draw-on, holiday/節気 tables, rewind overlay, widget today ensō |
| `forms.md` | form minimalism; `CalendarStyleSheet` selection styling |
| `charts.md` | budget scale options, `HankoStamp` |
| `price_display.md` | `InkReveal`, the total, every `"CAD"` → `MoneyFormatter` |
| `list_view.md` | notebook rows, `ExpensesInDay` rows/header, `LogoCircle(glass:)` |
| `home_screen_ux.md` | toolbar, Year grid (`MonthPickerSheet`), filter sheet, `HomeView` composition |
| `research_results_and_future_points.md` | index, sources, all open points |

## Current state
Everything here describes the **current working tree**, after the foundation pass. The git `HEAD` is the pre-redesign code.

### Composition
- **`HomeView`** (`LinguicaSubTracker/Features/Home/Views/HomeView.swift`):
  - The `VStack` at `:33-63` holds `TotalView` (`:35-44`, `maxHeight: .infinity`) and then `CalendarView` (`:45-53`). It reads `vm.settingsStore.calendarStyle` at `:51`.
  - The month title lives in the toolbar: `HomeToolbar.monthButton` (`LinguicaSubTracker/Features/Home/Views/Components/HomeToolbar.swift:90-106`) shows `monthKey` and opens `MonthPickerSheet`, a wheel (`LinguicaSubTracker/Features/Home/Views/Components/MonthPickerSheet.swift:9-19`).
- **`CalendarView`** (`LinguicaSubTracker/Features/Home/Views/Components/Calendar/CalendarView.swift`):
  - A paged `TabView` (`:29-47`) wraps one `MonthView` per month, with `.padding(.horizontal, 12)` at `:44`.
  - The whole `TabView` goes to opacity 0 while `rewindPair` is set (`:48`).
  - `CalendarRewindOverlay` (`:50-66`) is pushed down with `.padding(.top, 60)` (`:64`).
  - The frame is `calendarStyle.gridHeight + 60` (`:68-69`). The 60 is the weekday header (52) plus the `VStack` spacing (8) in `MonthView`.
- **`MonthView`** (`.../Calendar/Month/MonthView.swift`):
  - `columns` uses spacing 4 (`:20`), and `weekdaysList = ["S","M","T","W","T","F","S"]` (`:21`).
  - `VStack(spacing: 8)` (`:24`) holds the `weekdaysHeader` (`:30-40`): `.font(.caption)`, `.gray`, height 52.
  - `monthGrid` (`:42-61`) is a `LazyVGrid`.
  - `cellHeight` (`:63-68`) derives the row count from `grid.count / 7`, so a month has 4, 5 or 6 rows and the cell height jumps.
  - `status(for:)` (`:70-74`) returns `.none` / `.current` / `.normal`.
  - The defaults are `style: .rounded` (`:11`), `height: 370` (`:12`) and `spacing: 4` (`:13`).
- **`DayCell`** (`.../Calendar/Month/DayCell.swift`):
  - `DayStatus` (`:4-8`).
  - The quick-actions `contextMenu` + delete `.alert` apply when `style.hasQuickActions` (`:28-63`).
  - `cellButton` (`:69-101`):
    - numeral overlay `.font(.system(size: 12))`, opacity 0.6, inset 8 or 5 (`:76-86`, font at `:79`)
    - expense overlay (`:87-95`)
    - `.clipShape(RoundedRectangle)` (`:96`), then `.overlay(borderOverlay)` (`:97`)
  - `.none` cells are still `Button`s (`handleTap` guards `date`, `:107-110`).
  - `expenseFloatingLayer` (`:112-129`): an overflow badge plus 2 logos, `HStack(spacing: -10)`, bottom-trailing.
  - `dotsLayer` (`:135-157`): up to 4 dots (3 for compact) plus `"+n"` in `.system(size: 8, weight: .bold)` (`:150`).
  - `overflowBadge` (`:159-171`).
  - `logoCircle` (`:173-180`) is `LogoCircle` with glass and shadow (`LinguicaSubTracker/Core/Components/LogoCircle.swift:16-25`).
  - `cellBackground` is a gray fill plus a brand-gradient tint (`:182-210`).
  - **Today** = three `Color.primary` strokes, one of them blurred, which counts as a glow (`borderOverlay` `.current`, `:222-245`).
  - `DayClickStyle`: scale 0.95 with `.spring(duration: 0.2, bounce: 0.4)` and a light haptic (`:277-295`).
- **`DayCellViewModel`** (`LinguicaSubTracker/Features/Home/ViewModels/DayCellViewModel.swift:20-31`): `primaryExpense`, `primaryColor`, `overflowCount` (count − 2), `displayDay`, `dayNumber`. It has no weekday and no holiday.
- **`CalendarRewindOverlay`** (`.../Calendar/CalendarRewindOverlay.swift`):
  - It rebuilds its own grid of `DayCell`s (`:47-83`).
  - Motion: `matchedGeometryEffect` (`:64`), `.spring(response: 0.6, dampingFraction: 0.78)` (`:37`), and empty cells inserted with a scale-0.4 spring (`:69-77`).
  - `onComplete` fires after 750 ms (`:40-43`).
- **`CalendarStyle`** (`LinguicaSubTracker/Features/Settings/Models/CalendarStyle.swift`):
  - Five cases (`:6-10`), with a lenient decoder falling back to `.rounded` (`:18-21`).
  - Exhaustive switches: `displayName` `:23-31`, `icon` `:33-41`, `subtitle` `:43-51`, `gridHeight` `:56-62` (370/460/260), `cornerRadius` `:64-71`.
  - Flags: `logoSize` `:73`, `usesDots` `:76`, `showsGradientTint` `:79`, `hasBrandBorder` `:82`, `hasQuickActions` `:85`.
  - Stored as optional `AppSettings.calendarStyle` (`LinguicaSubTracker/Features/Settings/Models/AppSettings.swift:13-14`), with nil read as `.rounded` (`LinguicaSubTracker/Features/Settings/Stores/SettingsStore.swift:40-43`).
- **`CalendarViewModel`** (`LinguicaSubTracker/Features/Home/ViewModels/CalendarViewModel.swift`):
  - `months` `:8`, `rewindPair` `:9`, `currentMonthIndex` + `didSet` `:15-17`, `currentMonth` `:18`
  - `monthKey` `:42-44`, asserted by `LinguicaSubTrackerTests/CalendarViewModelTests.swift:44`
  - `currentMonthIndexBinding()` `:46-51`, the single writer
  - `jumpToCurrentMonth()` `:58-70`
- **Week start:** Sunday is hard-wired in three places, which matches ja_JP 日→土:
  - `CalendarService.daysGrid(startingOn: .sunday)` (`LinguicaSubTracker/Features/Home/Services/CalendarService.swift:25-28`)
  - `ExpenseService.weekInterval` (`LinguicaSubTracker/Core/Services/ExpenseService.swift:356-361`)
  - the widget (`SatoruWidgets/WidgetData.swift:163`)
- **Month window:** `CalendarService.generateMonths()` returns −1…+12 months (`:16-23`). On 2026-10-12, index 0 = Sep 2026, 1 = Oct 2026 and 13 = Oct 2027.
- **`ExpensesInDay`** (`LinguicaSubTracker/Features/ExpensesInDay/Views/ExpensesInDay.swift`):
  - header `:95-105`
  - hardcoded `.currency(code: "CAD")` at `:219`, and in `ExpensesInDayViewModel.rowSubtitle` (`.../ViewModels/ExpensesInDayViewModel.swift:45-49`)
  - `compactHeight` `:28-34`
- **Widget** (`SatoruWidgets/WidgetViews.swift`):
  - The month grid (`:379-415`) marks today with a shu numeral (`:396`) and a 1pt shu `Rectangle` stroke with `.widgetAccentable()` (`:404-409`).
  - Weekday letters come from `Calendar.current.veryShortWeekdaySymbols` (`:345`).
- **Onboarding:** `OnboardingCalendarHero` renders the real `MonthView` at `height: 300` inside `.rippleCard()`, a `layerEffect` (`LinguicaSubTracker/Features/Onboarding/Views/Components/Heroes/OnboardingCalendarHero.swift:15-24`).
- **No holiday, 節気, era or kanji data exists anywhere in the repo.**

### Already done by the foundation pass (verify, do not redo)
- **Ripple removed from the calendar:** `MonthView` no longer has `rippleSpace`, `.coordinateSpace` or `.rippleEffect`. `DayCell` no longer has `onRipple`, `@State center` or `centerReader`.
  - `git diff HEAD -- LinguicaSubTracker/Features/Home/Views/Components/Calendar` shows the deletions.
  - Check: `grep -rn "rippleEffect\|onRipple\|rippleSpace" LinguicaSubTracker/Features/Home` returns nothing.
- **Overflow badge** fill is `Color.paperRaised.opacity(0.8)` (`DayCell.swift:162`).
- **`CalendarStyleSheet`** is on tokens (`paperRaised`, `rule`, `ink`, `AppRadius.card`) and uses the mono preview numeral (`LinguicaSubTracker/Features/Settings/Views/Components/CalendarStyleSheet.swift:71-77,115-116`).
- **Widget:** uses the `mono()` font (`SatoruWidgets/WidgetViews.swift:8-10`), the shu today numeral and the square today stroke (`:396`, `:404-409`). Step 15 replaces that stroke with the ensō.
- **`Theme.font(size:relativeTo:)`** (`LinguicaSubTracker/Core/Utils/Theme.swift:8-10`) and the `.typography(_:)` styles exist (`LinguicaSubTracker/Core/Utils/Typography.swift:10-22`; `labelMedium` = 11pt, uppercase, tracking 1.2).
- **`appAccent`/`appSurface` are deleted**, not re-pointed. Use `Color.shu`/`Color.paperRaised`.

## Target design

### 1. Real-world Japanese calendar models
| Model | What it is | What the app borrows |
|---|---|---|
| **月めくり** (one month per sheet, wall) | The standard home calendar | **The main model:** one month per page, paged like tearing a sheet |
| **2–3ヶ月** wall sheets | Previous, current and next month on one sheet ([Mynavi](https://osusume.mynavi.jp/articles/5589/), [Maruzen](https://www.maruzenjunkudo.co.jp/products/4517163855409)) | The neighbouring months echoed as faint header labels |
| **文字月表** (text-only corporate) | The best-selling custom-printed type: bold numerals, 前後月 mini calendars, 六曜, seasonal events ([DreamNews](https://www.dreamnews.jp/index.php/press/0000280557)) | **Closest to the reference photo:** grid language, big numerals, mini months, annotations |
| **日めくり** (daily tear-off) | One day per sheet with 和風月名 and 干支 ([NDL](https://www.ndl.go.jp/koyomi/chapter3/index.html)) | Only the "turn the sheet" idea for the rewind; rejected as a layout (step 12) |
| **卓上** (desk) | The wall layout shrunk and ring-bound | Confirms the layout survives at small sizes |

**Standard anatomy of a monthly sheet:**

| Element | Usual position |
|---|---|
| Month numeral | Top-centre or top-left; the largest element, about 3–5× a day numeral |
| Year + era | In the header, e.g. `2026 / 令和8年` ([Hobonichi](https://www.1101.com/store/techo/en/2021/all_about/dayfree/about03.html)) |
| 和風月名 / English month | Next to the numeral, letter-spaced |
| Mini previous/next months | Top corners, or the empty cells of the first/last row ([MUJI](https://www.muji.com/jp/ja/shop/045835/articles/muji-staff/1631841)) |
| Weekday row | Directly above the grid; `日 月 火 水 木 金 土`, often with `SUN…SAT` |
| Cell | Numeral top-left; holiday name small under it; 六曜/干支/九星 tiny at the top-right; 節気 under the numeral |
| Memo space | The lower part of each cell, ruled ([bungu.store](https://bungu.store/products/md-bi-fold-wall-calendar-2026-midori)) |
| Colours | Sunday + holidays red, Saturday blue (Saturday was a half working day; blue was the remaining ink, [Berlitz](https://www.berlitz.com/blog/days-of-the-week-japanese)) |

**Reference photo** (notesofnomads.com, observed):
- Top corners hold mini months: `12` on the left, with 土 and 2 9 16 23 30, the 23 in red; `2` on the right, with 日 and 4 11 18 25 in red.
- The header row has `平成30年` bold on the left, a giant red `1` in the centre and `睦 月` letter-spaced on the right.
- Below that is a solid black weekday band with white kanji and thin white separators that continue into the grid.
- Cells have heavy black numerals, with 先勝 / 癸巳 / 三碧 stacked at the top-right.
- The 1st has a red numeral and red `元日` under it; the 5th has `小寒` under it.
- The lower part of each cell has dotted memo lines. The paper is white and nothing is rounded.

**Mapping every reference element to the app** (the phone cell is about 54×62pt on an iPhone 17 Pro and 50×62pt on an SE):

| Reference element | Decision | App element | Reason |
|---|---|---|---|
| Mini previous month (top-left) | **Adapt** | Faint `‹ SEP` label at the header's leading edge; tap pages back | A 7×6 mini month at phone width would have about 5pt numerals, which nobody can read |
| Mini next month (top-right) | **Adapt** | `NOV ›` at the trailing edge | Same reason |
| Era year `平成30年` | **Keep** | `令和8年` (Hiragino Mincho W6) over `2026` (Fragment Mono) | Cheap via `Calendar(identifier: .japanese)` |
| Giant red month numeral | **Keep** | `10`, Fragment Mono 56pt, `shu`, centred | This is the calendar's identity; it replaces the toolbar title |
| 和風月名 `睦 月` | **Keep** | `神無月` (Mincho W6, tracking 4) under `OCTOBER` | The user asked for real-world structure |
| 二十四節気 under a day | **Move** | One header line, e.g. `寒露 10.8 · 霜降 10.23` | Exactly two per month, so it fits a line; no room in a cell |
| Solid black weekday band, white kanji | **Keep** | Sumi band `SUN 日` … `SAT 土` | The most recognisable element |
| White separators continuing into the grid | **Keep** | Band separators aligned with the grid's vertical hairlines | Grid spacing becomes 0, so the x positions match |
| Heavy black day numerals | **Adapt** | 20pt Fragment Mono `ink` | Fragment Mono has one weight ([Fontsource](https://fontsource.org/fonts/fragment-mono/about)), so hierarchy comes from size |
| Holiday red numeral | **Keep** | `shu` numeral plus a `祝` mark in the annotation slot | The mark is the non-colour cue (WCAG 1.4.1) |
| Holiday name `元日` under the numeral | **Move** | `ExpensesInDay` sheet line and the VoiceOver label | "Sports Day" is about 48pt at 8pt mono, too wide for a 50pt cell |
| 六曜 `先勝` (top-right) | **Drop in v1; slot reserved** | Top-right annotation slot (12–14pt wide), v2 | NAOJ doesn't publish 六曜, and `.chinese` runs on UTC+8 (Open points) |
| 干支 `癸巳`, 九星 `三碧` | **Drop** | — | No room, and no value for expense tracking |
| Special-day label (一粒万倍日) | **Drop** | — | Same reason |
| Dotted memo lines in the lower cell | **Adapt** | **The expense slot:** one dotted line, with logos, overflow or dots "written" under it | The user's requirement: the expense elements stay |
| Vertical rules between columns, hairline between weeks | **Keep** | `ruleStrong` hairlines (1 px), drawn once per grid | Straight lines, no rounded cards |
| White paper, square corners | **Keep** | `paper` token, `AppRadius.grid` (0) | Matches the canonical shape rules |
| Sunday red / Saturday blue | **Keep** | `shu` / `ai` | Saturday colour is an open point |
| Days from neighbouring months | **Drop (blank)** | Empty cells, not tappable | The minis are in the header now; 23/30 split cells read poorly ([TalkPhotography](https://www.talkphotography.co.uk/threads/calendar-with-5-or-6-rows-which-do-you-think-is-best.686047/)) |
| Printer mark (bottom-right) | **Drop** | — | — |

### 2. Koyomi header (`KoyomiHeader`, new)
- **Placement:** outside the paged `TabView`, mounted by `HomeView` above the total in **both** view modes.
  - The rewind hides the whole `TabView` (`CalendarView.swift:48`), and list mode has no `CalendarView` at all.
  - The toolbar month title is deleted by `home_screen_ux.md` step 4.
- **Signature (contract with `home_screen_ux.md` step 9):** `KoyomiHeader(viewModel: CalendarViewModel)`, in `LinguicaSubTracker/Features/Home/Views/Components/Calendar/KoyomiHeader.swift` (new).
- **Data:** everything derives from `viewModel.currentMonth`. `monthKey` is untouched, because `CalendarViewModelTests.swift:44` asserts its format and `TotalView.swift:77,81` uses it.

```
iPhone 17 Pro, 402pt wide; header padded 12pt each side (378pt) to align with the grid
┌──────────────────────────────────────────────────────────────┐
│⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒⌒│ KasagiHeader: 2pt ink kasagi
│──────────────────────────────────────────────────────────────│ + 1pt ink shimaki (≈9pt)
│                                                              │ 6pt
│ ‹ SEP │ 令和8年                ███        OCTOBER │ NOV ›     │ 48pt row:
│  44pt │ 2026                   ███        神 無 月 │ 44pt      │ edge · era/year · numeral · month/和風月名 · edge
│       │                     "10" 56pt shu        │           │
│              寒露 10.8  ·  霜降 10.23                         │ 3pt + 14pt 節気 line
└──────────────────────────────────────────────────────────────┘
 total = 9 + 6 + 48 + 3 + 14 = 80pt; frame(minHeight: 80), grows with Dynamic Type
```

| Part | Spec | Light | Dark |
|---|---|---|---|
| Lintel | `KasagiHeader()` (the only Kasagi on Home) | `ink` #1E1A17 | `ink` #F4EFE6 |
| Era | `JapaneseCalendar.eraYear(for:)` → `令和8年`; `.font(.custom(AppFont.kanjiBold, size: 15, relativeTo: .headline))` | `ink` | `ink` |
| Western year | `String(year)` (no locale grouping) in `.typography(.labelMedium)` | `inkSecondary` #6B635C | #A8A096 |
| Month numeral | `Text("\(month)")`, `.font(.custom(AppFont.mono, fixedSize: 56))`, `.contentTransition(.opacity)` | `shu` #C1352A | `shu` #E84A33 |
| English month | en_US_POSIX `.month(.wide)` in `.typography(.labelMedium)` (`OCTOBER`), trailing-aligned | `inkSecondary` | `inkSecondary` |
| 和風月名 | `JapaneseCalendar.wafuMonthNames[month - 1]`, `kanjiBold` 15 relativeTo `.headline`, `.tracking(4)` | `ink` | `ink` |
| Edge labels | `chevron.left` + `SEP` / `NOV` + `chevron.right`; `.typography(.labelMedium)` and `.iconStyle(size: 9, color: .inkSecondary)`; frame ≥ 44×44; hidden (44pt clear spacer) at the window bounds | `inkSecondary` | `inkSecondary` |
| 節気 line | `JapaneseCalendar.sekki(year:month:)`. The names use `AppFont.kanji` 12 relativeTo `.caption`; dates use `.typography(.labelMedium)` as `M.d`, separated by `·`. If no entry exists (2027 for now), the 14pt line stays empty | `inkSecondary` | `inkSecondary` |

- **Height budget** (it must leave the grid all its room):
  - Header 80pt + band 28pt replace the toolbar title and the old 52 + 8pt weekday header: +48pt net, which the shrunken `TotalView` absorbs (`home_screen_ux.md`).
  - The grid stays 370pt. `home_screen_ux.md` budgets header 80 + band 28 + grid 370.
  - Text that scales is capped with `.dynamicTypeSize(...DynamicTypeSize.accessibility2)`. Every stack text has `.lineLimit(1).minimumScaleFactor(0.6)`.
- **Tap targets:**
  - The edge labels page the month: `withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { viewModel.currentMonthIndexBinding().wrappedValue = target }`. This is the same single writer as paging.
  - Swiping still works.
  - The year button and the Year grid belong to `home_screen_ux.md`.
- **Month change:** the numeral and the names cross-fade with `.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewModel.currentMonthIndex)`. No `numericText` roll and no bounce.
- **Accessibility:**
  - The centre group (era, numeral, month, 和風月名) is one element: label `"October 2026"`, trait `.isHeader`.
  - The edge buttons: label "Previous month" / "Next month", value "September" / "November".
  - The 節気 line is `.accessibilityHidden(true)` (decorative kanji).

**和風月名** ([NDL](https://www.ndl.go.jp/koyomi/chapter3/s8.html), [bestcalendar](https://bestcalendar.jp/guides/koyomi/wafu-getsumei)):

| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 睦月 | 如月 | 弥生 | 卯月 | 皐月 | 水無月 | 文月 | 葉月 | 長月 | 神無月 | 霜月 | 師走 |

**二十四節気 2026, Japan time** ([NAOJ 暦要項 2026](https://eco.mtk.nao.ac.jp/koyomi/yoko/2026/rekiyou262.html)):

| Month | Terms | Month | Terms |
|---|---|---|---|
| 1 | 小寒 1/5, 大寒 1/20 | 7 | 小暑 7/7, 大暑 7/23 |
| 2 | 立春 2/4, 雨水 2/19 | 8 | 立秋 8/7, 処暑 8/23 |
| 3 | 啓蟄 3/5, 春分 3/20 | 9 | 白露 9/7, 秋分 9/23 |
| 4 | 清明 4/5, 穀雨 4/20 | 10 | 寒露 10/8, 霜降 10/23 |
| 5 | 立夏 5/5, 小満 5/21 | 11 | 立冬 11/7, 小雪 11/22 |
| 6 | 芒種 6/6, 夏至 6/21 | 12 | 大雪 12/7, 冬至 12/22 |

**Era year:** `Calendar(identifier: .japanese)` with `Locale(identifier: "ja_JP")` and the date format `Gy年` gives `令和8年` ([gihyo](https://gihyo.jp/dev/serial/01/swift-introduction/0050)). `.japanese` is the Gregorian calendar with era names, so month and day are unchanged.

### 3. Weekday band (`WeekdayBand`, new)
- **Placement:** directly above the grid, **outside** the `TabView` (it is the same for every month), inside `CalendarView`.
  - This also fixes today's bug where the rewind overlay drew no weekday header.
- **Size:** height 28 for every style. It replaces the 52pt header and the 8pt spacing.
- **Labels:**
  - per column, `HStack(alignment: .firstTextBaseline, spacing: 3)`
  - `JapaneseCalendar.weekdayLatin[i]` (`SUN`), `.font(.custom(AppFont.mono, fixedSize: 10)).tracking(0.6)`
  - `JapaneseCalendar.weekdayKanji[i]` (`日`), `.font(.custom(AppFont.kanjiBold, fixedSize: 11))`
  - Index 0 is Sunday; the order is fixed and Sunday-first.
- **`.koyomi` band (sumi):**
  - Fill `Color.paperRaised` with `.environment(\.colorScheme, .dark)` applied to the band.
  - **Every token inside the band resolves to its dark (lacquer) variant in both app modes:**
    - fill #1C1816
    - labels `ink` #F4EFE6
    - Sunday `shu` #E84A33 (4.58:1 on #1C1816)
    - Saturday `ai` #6F93D6 (≈5.7:1)
  - Column separators: `Color.ink.opacity(0.25)` at `1 / displayScale`, trailing edge of columns 0–5. They line up with the grid's vertical hairlines.
  - **Light mode:** a near-black band on washi, which is the reference's "solid black bar with white kanji".
  - **Dark mode (decision): ink-on-`paperRaised`, not a shu band.**
    - A full-width shu band would be a second filled shu shape (the `+` CTA is the screen's one).
    - It would also push accent far past the 5% in 70/25/5.
    - The raised lacquer band keeps the "band" reading through tone plus `Rule(color: .ruleStrong)` hairlines top and bottom, drawn **outside** the forced dark environment and only when the outer `colorScheme == .dark`. `ruleStrong` is #746B63, 3.74:1, which meets 1.4.11.
- **Other styles (plain row):**
  - same labels, no fill, no separators
  - colours from the normal environment: Sunday `shu`, Saturday `ai`, other days `inkSecondary`
- `.accessibilityHidden(true)`: each `DayCell` label already speaks its weekday.

```
light:  ██ SUN日 ┃ MON月 ┃ TUE火 ┃ WED水 ┃ THU木 ┃ FRI金 ┃ SAT土 ██   fill #1C1816, text #F4EFE6, SUN #E84A33, SAT #6F93D6
dark:   ── ruleStrong ──────────────────────────────────────────
        ▓▓ SUN日 ┃ MON月 ┃ …                          ┃ SAT土 ▓▓   same band on paper #0E0C0B
        ── ruleStrong ──────────────────────────────────────────
```

### 4. Day cell anatomy (`.koyomi`)
- **Grid:**
  - `LazyVGrid` spacing 0, **fixed 6 rows** (42 cells), so the height never jumps between 4-, 5- and 6-row months.
  - Cell = 370 / 6 ≈ **61.7pt** tall; (402 − 24) / 7 = **54pt** wide on a 17 Pro, **50pt** on an SE.
  - Hairlines are drawn **once** by a `KoyomiGridLines` shape overlay on the grid: 6 vertical lines between the columns, plus one horizontal line under each row. `Color.ruleStrong`, `lineWidth: 1 / displayScale`. There are no outer verticals, as in the reference.
  - No cell fill, no rounded cards, no clip shape: paper shows through.

```
one .koyomi cell, 54 × 61.7pt (17 Pro)
┌──────────────────────────────────────────────┐
│┌────────────────────────┐              ┌──┐  │  numeral box 38×38 at (0,0); numeral centred, 20pt mono
││        ╭─ ─ ─╮         │              │祝│  │  annotation slot: 12–14pt wide, top-trailing, inset 4/3
││       ╱  12   ╲        │              └──┘  │  (v1: 祝 for holidays; v2: 六曜 stacked under it)
││       ╲       ╱ ensō   │                    │
││         ╰─  ─╯ ← gap   │                    │
│└────────────────────────┘                    │
│ ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ │  memo line at y = 39: dotted [1,3], `rule`, inset 4
│              (+2)◖◖(N)◖(Y)                   │  expense slot y ≈ 39.7…59.7: logos 20pt, overlap −7,
└──────────────────────────────────────────────┘  inset 2, bottom-trailing (or dots + "+n" for dot styles)
```

- **Numeral:**
  - `.font(.custom(AppFont.mono, fixedSize: style.dayNumeralSize))` (20 for `.koyomi`, 12 for the other styles), centred in a `style.ensoSize` box (38 / 28) at `numeralInset` (0 for `.koyomi` and `.compact`, 2 for the others).
  - Fixed size, because the cell geometry is fixed. VoiceOver carries the date.
- **Numeral colour** (all styles):

| Day | Colour | Light | Dark |
|---|---|---|---|
| Today (`.current`), including today on a Sunday or holiday | `ink` (sits inside the shu ensō) | #1E1A17 | #F4EFE6 |
| Holiday or Sunday | `shu` | #C1352A (5.0:1 on paper) | #E84A33 (5.07:1) |
| Saturday (not a holiday) | `ai` | #1E50A2 | #6F93D6 |
| Other | `ink` | #1E1A17 | #F4EFE6 |

- **Holiday indicator:** a `shu` numeral plus `祝` (`AppFont.kanjiBold`, fixed 9pt, `shu`) in the top-right annotation slot.
  - The holiday **name** is never in the cell. It appears in the `ExpensesInDay` sheet (step 14) and in the VoiceOver label.
  - **Today on a holiday** (test case: today, 2026-10-12, is a Monday and スポーツの日): the numeral is `ink` inside the shu ensō. The holiday stays visible through `祝`. A shu numeral inside a shu ring would blur into one red blob.
- **Memo line + expense slot.** This is the user's requirement: **every current expense element stays.**
  - **Logo styles** (`.koyomi`, `.rounded`, `.contrastRounded`, `.bigger`): `expenseFloatingLayer` unchanged in structure.
    - overflow badge `+n` + second logo + primary logo, bottom-trailing
    - `.koyomi` uses `logoSize` 20, overlap −7 and inset 2: 20 + 13 + 13 = 46pt, which fits the SE's 50pt cell minus insets
  - **Dot styles** (`.straight`, `.compact`): `dotsLayer` unchanged. Up to 4 dots (3 compact) in the brand colour, plus `+n` in mono 8pt `inkSecondary`.
  - **Quick actions:** the `contextMenu` (View/Edit/Delete) and the delete `.alert` stay for `.compact` and are **enabled for `.koyomi` too** (`hasQuickActions`).
  - **Logos in cells** pass `glass: false` (`list_view.md`'s `LogoCircle(glass:)`) in **all** styles. Calendar cells are content, so no glass and no coloured shadow ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)). This also removes the black-material risk under the onboarding `rippleCard`.
- **Overflow badge:** `Circle().fill(Color.paperRaised)` with a `Circle().stroke(Color.ruleStrong, lineWidth: 1 / displayScale)` ring. Text `+n` in `.custom(AppFont.mono, fixedSize: 9)`, `ink`.
- **Neighbour-month cells (`grid` nil, `.none`):**
  - **blank**: no numeral, memo line or logo
  - **not a `Button`** and not hit-testable
  - `.accessibilityHidden(true)`
  - They keep their grid hairlines (drawn by the grid overlay).
- **Selected vs today:**
  - There is no persistent selected state in v1. A tap opens the day sheet immediately (`coordinator.selectedDay`).
  - Press feedback is the face at `opacity(0.6)`, `.smooth(duration: 0.15)` (none under Reduce Motion), plus the existing light haptic. No scale and no bounce.
  - A persistent selection, if ever needed, is an open point (1pt `kin` underline, never a second circle).
- **Other styles keep working as variations:**
  - same numeral colours, ensō and fonts
  - their rounded fill becomes `Color.ink.opacity(0.06)` (`.none` 0.03; compact 0.05 / 0.025) instead of gray
  - their brand gradient tint and the contrast border stay
  - the blurred "glow" today stroke is replaced by the ensō
  - "Variations may change after first version."

### 5. `CalendarStyle` strategy: add `.koyomi` and make it the default
- **Decision:**
  - Add `case koyomi` as the **first** case, so it leads `CalendarStyleSheet`.
  - Make it the value for **nil** (`SettingsStore.swift:41`) and for unknown stored values (`CalendarStyle.swift:20`).
  - Users who explicitly picked another style keep it. Everyone who never chose (all new installs and untouched existing installs) gets Koyomi, which matches the app-wide redesign.
- **Why not restyle `.straight`:**
  - It would silently change the look for users who picked "Straight".
  - Straight's dots-only slot would drop the logos.
  - The style sheet would lose a variation.
  - A new case also makes the compiler list every exhaustive switch.
- **Persistence:** `AppSettings.calendarStyle` stays `CalendarStyle?` (optional, so old blobs decode). The lenient decoder already exists. Older app builds decode `"koyomi"` as `.rounded` instead of wiping settings.
- **Tokens for `.koyomi`:**

| Member | `.koyomi` | Others |
|---|---|---|
| `displayName` / `icon` / `subtitle` | "Koyomi" / `"calendar"` / "Wall-calendar grid, brush circle on today" | unchanged |
| `gridHeight` | 370 | unchanged (370/460/260) |
| `cornerRadius` | `AppRadius.grid` (0) | unchanged |
| `logoSize` | 20 | 34 bigger, 26 others |
| `usesDots` | false | unchanged |
| `showsGradientTint` | false | `!usesDots` |
| `hasBrandBorder` | false | unchanged |
| `hasQuickActions` | **true** | `.compact` only |
| `fixedRows` (new) | 6 | nil (rows follow the month) |
| `ensoSize` (new) | 38 | 28 |
| `dayNumeralSize` (new) | 20 | 12 |

- **Exhaustive switches the compiler will flag:**
  - `CalendarStyle.swift`: `displayName` `:24`, `icon` `:34`, `subtitle` `:44`, `gridHeight` `:57`, `cornerRadius` `:65`
  - `CalendarStyleSheet.swift`: `previewHeight` `:91`
- **Sites the compiler will NOT flag (update by hand):**
  - `DayCell.swift:204` `baseBackgroundColor`. Its tuple switch uses `_` wildcards, so `.koyomi` silently matches `(_, .current)`.
  - Comparisons: `DayCell.swift:24`, `:25`, `:131`, `:136`; `CalendarStyleSheet.swift:155-156`
  - Flags: `CalendarStyle.swift:73`, `:76`, `:79`, `:82`, `:85`
  - Fallbacks and defaults:
    - `CalendarStyle.swift:20` (decoder fallback)
    - `SettingsStore.swift:41` (nil default)
    - the `.rounded` default parameters at `CalendarView.swift:14`, `MonthView.swift:11`, `DayCell.swift:12`, `CalendarRewindOverlay.swift:8`
    - `CalendarRewindOverlayPreviewHost.swift:18`
  - Doc comments: `CalendarStyle.swift:3-4`, `AppSettings.swift:13`
  - `TotalViewModel.swift:48` (`isCompactStyle`) needs **no** change. The compact budget breakdown stays compact-only.

### 6. Ensō today marker (`EnsoShape` + `EnsoMark`, new)
- **What the user asked for:** "a brush circling the day in a non-closed imperfect circle". An ensō is one unrevised brush stroke; the open form means movement and incompleteness ([Wikipedia](https://en.wikipedia.org/wiki/Ens%C5%8D)).
- **Stroke anatomy** ([calligraphy terms](https://selftaughtjapanese.com/2020/08/25/japanese-vocabulary-list-calligraphy-terms)):
  - 起筆: heavy entry blob
  - 送筆: steady travel
  - はらい: lifting taper
  - かすれ: dry-brush streaks in the last third
- **File:** `LinguicaSubTracker/Core/UI/Motifs/EnsoShape.swift` (new). It contains:
  - `EnsoShape`
  - `EnsoMark`
  - two `EnvironmentValues` entries
  - SwiftUI and Foundation only, so it also compiles in the widget target
- **API:** `EnsoShape(seed: UInt64, gap: Double = 40.0/360, maxWidth: Double = 0.0875)`. This matches the `general_app_ui.md` §7 contract. This doc is the single owner of the ensō spec; every other doc (list headers, Year grid, widget) only instantiates it.

**Geometry** (SwiftUI screen angles: 0° is 3 o'clock, clockwise is positive):

| Parameter | Value |
|---|---|
| Box | **38pt** in `.koyomi` cells (range 38–42); 28pt other styles; 34pt list headers (`list_view.md`); 40pt Year grid cells (`home_screen_ux.md`); about 2.2 × numeral size in widgets |
| Start angle | **150° ± 8°** (seeded), about 8 o'clock |
| Sweep / gap | **320°** clockwise; **40° gap** at lower-left. Never closed |
| Base radius | `r0 = side/2 × 0.84` |
| Radius drift | ±4%: `0.04·(0.6·sin(4πt+φ1) + 0.4·sin(6πt+φ2))`, with φ seeded |
| Tail overshoot | +6% radius, smoothstep from t = 0.8 to 1, so the end flicks outward |
| Width profile | `w(t) = wMax·(0.55 + 0.45·(1−t)^1.5)`; entry press `1.15·wMax` blending into the profile over t < 0.04; linear taper to `0.15·wMax` from t = 0.85 |
| wMax | **3.5pt at 40pt** (`maxWidth` 0.0875 × the shorter side); 3.3pt at 38pt |
| 起筆 blob | A circle with diameter `1.15·wMax`, unioned at t = 0 |
| かすれ | From t = 0.65: 2–3 (seeded) sub-strokes at radius offsets spread over −0.8…+0.8pt, `lineWidth 0.6`, dash `[8, 2, 3, 1]` with a seeded phase. **Subtracted** from the fill, so they read as white streaks |
| Containment | Max outer radius `r0·1.10 + w/2` < side/2. The stroke never leaves its box |
| Seed | `yyyyMMdd` via `EnsoShape.seed(for:)` (e.g. `20261012`): stable for a day, different between days. Every surface that marks today (cells, list headers, Year grid, widget) passes `EnsoShape.seed(for: today)`, so today's brush is the same shape everywhere |
| PRNG | A 6-line SplitMix64 (no GameplayKit, so it is widget-safe) |
| Colour | `shu` (#C1352A light / #E84A33 dark), a stroke shape, so it doesn't count against "one filled shu shape" |

```swift
// LinguicaSubTracker/Core/UI/Motifs/EnsoShape.swift (new): app + widget
struct EnsoShape: Shape {
    var seed: UInt64
    var gap: Double = 40.0 / 360            // open fraction → 320° sweep
    var maxWidth: Double = 0.0875           // wMax ÷ shorter side (3.5pt at 40pt)

    static func seed(for date: Date, calendar: Calendar = .current) -> UInt64 {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return UInt64((c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0))
    }
    /// 150° ± 8°; the draw-on mask starts here too (first PRNG draw).
    var startDegrees: Double { var g = SplitMix(state: seed); return 142 + g.next() * 16 }

    func path(in rect: CGRect) -> Path {
        var g = SplitMix(state: seed)
        let start = (142 + g.next() * 16) * .pi / 180
        let p1 = g.next() * 2 * .pi, p2 = g.next() * 2 * .pi
        let side = Double(min(rect.width, rect.height))
        let cx = Double(rect.midX), cy = Double(rect.midY)
        let r0 = side / 2 * 0.84, wMax = side * maxWidth, sweep = (1 - gap) * 2 * .pi
        func radius(_ t: Double) -> Double {
            let drift = 0.04 * (0.6 * sin(4 * .pi * t + p1) + 0.4 * sin(6 * .pi * t + p2))
            let s = min(max((t - 0.8) / 0.2, 0), 1)
            return r0 * (1 + drift + 0.06 * s * s * (3 - 2 * s))
        }
        func point(_ r: Double, _ t: Double) -> CGPoint {
            let a = start + t * sweep
            return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
        }
        var outer: [CGPoint] = [], inner: [CGPoint] = []
        for k in 0...72 {
            let t = Double(k) / 72, w = Self.width(t) * wMax
            outer.append(point(radius(t) + w / 2, t)); inner.append(point(radius(t) - w / 2, t))
        }
        var body = Path(); body.addLines(outer + inner.reversed()); body.closeSubpath()
        let b = point(radius(0), 0), br = 1.15 * wMax / 2                         // 起筆
        body = body.union(Path(ellipseIn: CGRect(x: b.x - br, y: b.y - br, width: 2 * br, height: 2 * br)))
        var streaks = Path()                                                      // かすれ
        let n = 2 + Int(g.next() * 2)
        for i in 0..<n {
            let off = -0.8 + 1.6 * Double(i) / Double(n - 1)
            streaks.addLines(stride(from: 0.65, through: 1.0, by: 0.01).map { point(radius($0) + off, $0) })
        }
        let holes = streaks.strokedPath(StrokeStyle(lineWidth: 0.6, dash: [8, 2, 3, 1], dashPhase: g.next() * 14))
        return body.subtracting(holes)
    }

    /// w(t) as a fraction of wMax: 起筆 press → 送筆 → はらい taper.
    static func width(_ t: Double) -> Double {
        func base(_ t: Double) -> Double { 0.55 + 0.45 * pow(1 - t, 1.5) }
        if t < 0.04 { return 1.15 + (base(0.04) - 1.15) * t / 0.04 }
        if t > 0.85 { return base(0.85) + (0.15 - base(0.85)) * (t - 0.85) / 0.15 }
        return base(t)
    }
}

private struct SplitMix {                     // seeded PRNG → [0, 1)
    var state: UInt64
    mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Double((z ^ (z >> 31)) >> 11) / 9_007_199_254_740_992
    }
}
```

- **Draw-on: mask it, never `trim` the outline.** The filled outline runs out along the outer edge and back along the inner edge, so trimming it looks wrong ([HWS](https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-part-of-a-solid-shape-using-trim)). Variable width needs a filled outline in the first place ([Swift Forums](https://forums.swift.org/t/drawing-strokes-with-a-different-width-at-each-point-of-the-lines-curves/40068)).

```swift
/// Today marker with brush draw-on. Static under Reduce Motion.
struct EnsoMark: View {
    let date: Date
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.ensoReplay) private var replay
    @State private var progress = 0.0

    var body: some View {
        let enso = EnsoShape(seed: EnsoShape.seed(for: date))
        enso.fill(Color.shu)
            .frame(width: size, height: size)
            .mask {
                Circle().trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: size / 2, lineCap: .butt)) // covers radii size/4…3size/4
                    .rotationEffect(.degrees(enso.startDegrees - 6))                  // start just before the 起筆 blob
            }
            .accessibilityHidden(true)
            .onAppear(perform: draw)
            .onChange(of: replay) { draw() }
    }

    private func draw() {
        guard !reduceMotion else { progress = 1; return }
        progress = 0
        Task { @MainActor in   // next tick, so 0 → 1 is a real animation, not a coalesced no-op
            withAnimation(.timingCurve(0.2, 0.7, 0.3, 1, duration: 0.55)) { progress = 1 }
        }
    }
}

extension EnvironmentValues {
    @Entry var ensoReplay: Int = 0      // bump to redraw today's ensō (CalendarView after a rewind)
    @Entry var showsEnso: Bool = true   // false inside the rewind overlay
}
```

- **Motion:**
  - draw-on 0.55s, ease-out `.timingCurve(0.2, 0.7, 0.3, 1)`: fast entry, slow into the taper, matching the canonical "mask reveal ~0.55–0.7s ease-out"
  - **Reduce Motion:** drawn complete, no animation
  - redraws when the page first appears and every time `ensoReplay` changes
- **Redraw on Today:**
  - `CalendarView` keeps `@State private var ensoReplay = 0` and bumps it in the rewind's `onComplete`.
  - Today → rewind (ink wipe, ensō hidden) → `rewindPair = nil` → the brush circles today.
  - This is the contract `home_screen_ux.md` relies on.
- **Placement, not clipped:**
  - In `.koyomi` cells the ensō box (38) sits at (0,0), inside the 50–54pt cell, and there is no clip shape.
  - In the other styles it is an `.overlay(alignment: .topLeading)` applied **after** `.clipShape` (`DayCell.swift:96`), at the same inset as the numeral box. The rounded clip never cuts it.
- **Performance:** one ensō per visible month (plus the Year grid). `path(in:)` runs boolean ops on about 150 points, and the shape is not `Animatable` (the mask animates), so the path is not rebuilt per frame. No `Canvas`, blur or shader.
- **Vector-asset alternative** (if the procedural stroke looks too synthetic on a device):
  - 3–5 hand-drawn ensō SVGs in `Resources/Assets.xcassets` as `enso_0…enso_4` (Preserve Vector Data, Template rendering). The catalog is already shared with the widget.
  - Pick one with `seed % n`, rotate it so its gap sits lower-left, and tint it `shu`.
  - The draw-on is the same trimmed-circle mask.
  - `EnsoMark`'s API is unchanged; only its body swaps `EnsoShape` for `Image`.

### 7. JP holiday + calendar data (`JapaneseCalendar`, new, shared)
- **File:** `LinguicaSubTracker/Core/Utils/JapaneseCalendar.swift` (new). Foundation only. Added to the **widget** exception set too (step 4).
- **API:**
  - `JapaneseCalendar.Holiday { ja, en }`
  - `holidays: [Int: Holiday]`, keyed `yyyyMMdd`
  - `holiday(on: Date, calendar: Calendar = .current) -> Holiday?`
  - `weekdayLatin` (`SUN…SAT`), `weekdayKanji` (`日…土`), both indexed by weekday − 1
  - `wafuMonthNames` (index month − 1)
  - `sekki(year:month:) -> [(name: String, day: Int)]`
  - `eraYear(for:) -> String`
  - `list_view.md` uses `weekdayKanji` (it keeps no table of its own).

**2026** ([CAO](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html); 16 national holidays + 2 other days off = 18):

| Date | ja | en | Date | ja | en |
|---|---|---|---|---|---|
| 1/1 Thu | 元日 | New Year's Day | 7/20 Mon | 海の日 | Marine Day |
| 1/12 Mon | 成人の日 | Coming of Age Day | 8/11 Tue | 山の日 | Mountain Day |
| 2/11 Wed | 建国記念の日 | National Foundation Day | 9/21 Mon | 敬老の日 | Respect for the Aged Day |
| 2/23 Mon | 天皇誕生日 | Emperor's Birthday | 9/22 Tue | 国民の休日 | Citizens' Holiday |
| 3/20 Fri | 春分の日 | Vernal Equinox Day | 9/23 Wed | 秋分の日 | Autumnal Equinox Day |
| 4/29 Wed | 昭和の日 | Shōwa Day | 10/12 Mon | スポーツの日 | Sports Day |
| 5/3 Sun | 憲法記念日 | Constitution Memorial Day | 11/3 Tue | 文化の日 | Culture Day |
| 5/4 Mon | みどりの日 | Greenery Day | 11/23 Mon | 勤労感謝の日 | Labor Thanksgiving Day |
| 5/5 Tue | こどもの日 | Children's Day | | | |
| 5/6 Wed | 振替休日 | Substitute Holiday | | | |

**2027** (17 days). These are derived from the holiday rules. The equinox days (3/21, 9/23) are astronomical predictions that no research file confirms, so cross-check every row against [CAO](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html) before shipping (Open points):

| Date | ja | Date | ja |
|---|---|---|---|
| 1/1 Fri | 元日 | 5/5 Wed | こどもの日 |
| 1/11 Mon | 成人の日 | 7/19 Mon | 海の日 |
| 2/11 Thu | 建国記念の日 | 8/11 Wed | 山の日 |
| 2/23 Tue | 天皇誕生日 | 9/20 Mon | 敬老の日 |
| 3/21 Sun | 春分の日 | 9/23 Thu | 秋分の日 |
| 3/22 Mon | 振替休日 | 10/11 Mon | スポーツの日 |
| 4/29 Thu | 昭和の日 | 11/3 Wed | 文化の日 |
| 5/3 Mon | 憲法記念日 | 11/23 Tue | 勤労感謝の日 |
| 5/4 Tue | みどりの日 | | |

- **Rules note** (keep as a doc comment on the table, for whoever extends it):
  - **振替休日:** when a national holiday falls on a Sunday, the next weekday that is not a holiday becomes a holiday (e.g. 2026-05-03 Sun → 5/6, because 5/4 and 5/5 are already holidays).
  - **国民の休日:** a single weekday sandwiched between two national holidays becomes a holiday (e.g. 2026-09-22).
  - Equinox days are fixed each February by NAOJ for the following year. Happy-Monday holidays are the 2nd Monday (成人の日, スポーツの日) or the 3rd Monday (海の日, 敬老の日).
- **Colouring:** 振替休日 and 国民の休日 are red, like any holiday.
- **Era formatter** (one formatter per call; the header renders rarely):

```swift
static func eraYear(for date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .japanese)
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "Gy年"
    return f.string(from: date)   // "令和8年"
}
```

### 8. Rewind overlay: ink wipe (`CalendarRewindOverlay`)
- **Contract kept:**
  - the signature `CalendarRewindOverlay(store:source:target:height:style:onComplete:)`
  - `onComplete` after **750 ms**
  - `CalendarView` sets `rewindPair = nil` with `.easeOut(0.2)`
- **New motion:**
  - Source and target are both drawn by the real `MonthView(…, showsWeekdayHeader: false)`. That deletes the overlay's private grid, `cellHeight`, `status(for:)` and `@Namespace`.
  - The target sits on an opaque `Color.paper` and is revealed by a mask: `Rectangle().scaleEffect(x: progress, y: 1, anchor: forward ? .trailing : .leading)`. `forward` = target month later than source, so the new sheet slides in from the side you'd swipe from.
  - Timing: `.timingCurve(0.2, 0.7, 0.3, 1, duration: 0.55)`. No spring, no `matchedGeometryEffect`, no scale.
  - **Reduce Motion:** the mask is full and the target's opacity animates 0 → 1 with `.easeOut(duration: 0.2)`.
  - The overlay sets `.environment(\.showsEnso, false)`. The ensō appears only after the wipe, via `ensoReplay`.
- **Page-tear rejected:**
  - 日めくり is a daily format.
  - A curl needs per-frame geometry (`Canvas`/shader), and the project forbids `layerEffect` near content with materials.

### 9. Sheets
- **`ExpensesInDay`:**
  - Rows, header and total restyle: `list_view.md` steps 8–9.
  - "CAD" (`ExpensesInDay.swift:219`, `ExpensesInDayViewModel.swift:47`): owned by `price_display.md` step 4, using `MoneyFormatter.format(_:settings:)` (`LinguicaSubTracker/Core/Utils/MoneyFormatter.swift:19`). `price_display.md` runs before this doc in the execution order (`research_results_and_future_points.md`); this doc only verifies it. Add no second path.
  - **This doc adds** the holiday line under the header (step 14).
- **`MonthPickerSheet`:** it becomes the Year grid in `home_screen_ux.md` step 6, which uses a static `EnsoShape` for the current month. Nothing in this doc touches it.

### 10. Widgets
- **Month grid today marker:**
  - Replace the 1pt shu `Rectangle` stroke (`SatoruWidgets/WidgetViews.swift:404-409`) with a **static** ensō (`EnsoShape(seed:).fill(Color.shu)`, diameter `numberSize * 2.2`) behind the numeral, keeping `.widgetAccentable()`.
  - The today numeral becomes `ink` (`:396`), matching the app.
  - Widgets never animate.
- **Week widgets** (`:443`, `:490`) keep the shu numeral (no room for a circle in the row layout). A weekday/holiday colouring pass for widgets is an open point.

### 11. Accessibility
- **`DayCell`:**
  - `.accessibilityElement(children: .ignore)`
  - label from `DayCellViewModel.accessibilityLabel`, e.g. `"Monday, October 12, Today, Sports Day, 2 expenses: Notion, YouTube"`
  - The weekday comes from `.dateTime.weekday(.wide).month(.wide).day()`.
  - "Today" is added for `.current`, then the holiday's `en` name, then "No expenses" / "1 expense: X" / "N expenses: A, B, C" (first three names).
  - Hint: `"Shows the day's expenses"`, or `"Adds an expense"` when the day is empty (`HomeView.swift:170-175` opens the add form for empty days).
  - The quick-actions context menu surfaces as VoiceOver actions automatically.
- **Hidden elements:** blank `.none` cells, the weekday band, the ensō and the 節気 line.
- **Reduce Motion:** the ensō is static, the rewind is a cross-fade, and the header cross-fade and press dim are off.
- **Week start:** Sunday-first stays. It is hard-wired in the three places in Current state and matches `ja_JP`. Monday-first is an open point.

## Implementation steps
Do them in order and build after each step.

1. **Verify the baseline.**
   - Already done by the foundation pass (verify): the items under "Already done by the foundation pass".
   - Build with `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build`.
   - Confirm `LogoCircle` has a `glass:` parameter (`list_view.md` step 2). If it doesn't, do that step now.

2. **Create `LinguicaSubTracker/Core/Utils/JapaneseCalendar.swift` (new)** with the API in Target design §7:
   - the 2026 + 2027 holiday tables with `en` names (35 entries, plus the rules doc comment)
   - `weekdayLatin` / `weekdayKanji` / `wafuMonthNames`
   - the 2026 `sekki` table keyed `year * 100 + month`
   - `eraYear(for:)`
   - a private `key(_:_:)` that returns `y*10000 + m*100 + d` from `calendar.dateComponents`
   - Import Foundation only.

3. **Create `LinguicaSubTracker/Core/UI/Motifs/EnsoShape.swift` (new)** with `EnsoShape`, `SplitMix`, `EnsoMark` and the two `@Entry` values, exactly as in §6. Import SwiftUI only.

4. **Share both files with the widget.** In `LinguicaSubTracker.xcodeproj/project.pbxproj`, exception set `18A8E7B03068400000A50CC2` (`:78-107`), add to `membershipExceptions` in alphabetical order:
   - `Core/UI/Motifs/EnsoShape.swift,` after `Core/Services/StorageService.swift,` (`:90`)
   - `Core/Utils/JapaneseCalendar.swift,` after `Core/Utils/Extensions/Color.swift,` (`:93`)

   The app target picks the files up on its own (synchronized root group).

5. **`CalendarStyle.swift`:**
   - Add `case koyomi` above `case rounded` (`:6`).
   - Decoder fallback `?? .rounded` → `?? .koyomi` (`:20`). Fix the doc comments at `:3-4`, `:15`.
   - Add the `.koyomi` arms to `displayName`/`icon`/`subtitle`/`gridHeight`/`cornerRadius` (`.koyomi: AppRadius.grid`) per the §5 table.
   - Flags:
     - `logoSize` → `self == .bigger ? 34 : (self == .koyomi ? 20 : 26)`
     - `showsGradientTint` → `!usesDots && self != .koyomi`
     - `hasQuickActions` → `self == .compact || self == .koyomi`
   - Append:
     ```swift
     /// Koyomi pins 6 rows so the grid never jumps between 4/5/6-week months.
     var fixedRows: Int? { self == .koyomi ? 6 : nil }
     /// Box for the day numeral and the today ensō.
     var ensoSize: CGFloat { self == .koyomi ? 38 : 28 }
     var dayNumeralSize: CGFloat { self == .koyomi ? 20 : 12 }
     ```
   - `SettingsStore.swift:41`: `?? .rounded` → `?? .koyomi`.
   - `AppSettings.swift:13` comment: `(nil → .koyomi)`.

6. **`CalendarStyleSheet.swift`:**
   - Add `.koyomi` to the `previewHeight` switch (`:91-95`): `case .koyomi, .rounded, .contrastRounded, .straight: 52`.
   - In `CalendarStylePreviewCell.body` (`:100-137`), branch `if style == .koyomi { koyomiPreview } else { …existing… }`:
     ```swift
     private var koyomiPreview: some View {
         ZStack(alignment: .topLeading) {
             Rectangle().fill(Color.paperRaised)
             EnsoShape(seed: 20261012).fill(Color.shu).frame(width: 24, height: 24)
             Text("17").font(.custom(AppFont.mono, fixedSize: 10)).foregroundStyle(Color.ink)
                 .frame(width: 24, height: 24)
             Circle().fill(mockColors[0]).frame(width: 12, height: 12)
                 .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(3)
         }
         .frame(width: 56, height: previewHeight)
         .overlay(Rectangle().stroke(Color.ruleStrong, lineWidth: 0.5))
     }
     ```
   - The row's selection styling is `forms.md`'s.

7. **`DayCellViewModel.swift`:** add after `dayNumber` (`:28-31`):
   ```swift
   var weekday: Int? { date.map { Calendar.current.component(.weekday, from: $0) } }   // 1 = Sun
   var holiday: JapaneseCalendar.Holiday? { date.flatMap { JapaneseCalendar.holiday(on: $0) } }
   var accessibilityLabel: String {
       guard let date else { return "" }
       var parts = [date.formatted(.dateTime.weekday(.wide).month(.wide).day())]
       if status == .current { parts.append("Today") }
       if let holiday { parts.append(holiday.en) }
       switch expenses.count {
       case 0: parts.append("No expenses")
       case 1: parts.append("1 expense: \(expenses[0].name)")
       default: parts.append("\(expenses.count) expenses: " + expenses.prefix(3).map(\.name).joined(separator: ", "))
       }
       return parts.joined(separator: ", ")
   }
   ```

8. **`DayCell.swift`:**
   - **Defaults and environment:**
     - default `style` `.rounded` → `.koyomi` (`:12`)
     - add `@Environment(\.showsEnso) private var showsEnso`, `@Environment(\.displayScale) private var displayScale`
   - **Insets:**
     - replace `dayLabelInset` (`:25`) with `private var numeralInset: CGFloat { style == .koyomi || style == .compact ? 0 : 2 }`
     - `expenseInset` (`:24`) → `style == .koyomi ? 2 : (style == .bigger ? 6 : 4)`
   - **`body` (`:27-67`):** first branch `if viewModel.status == .none { cellFace.allowsHitTesting(false).accessibilityHidden(true) }`. The existing quick-actions branch and the plain `cellButton` branch follow unchanged.
   - **Split `cellButton` (`:69-101`):** `Button(action: handleTap) { cellFace }` keeps `.buttonStyle(DayClickStyle(showsPressFeedback: isSelectable))`, then add:
     ```swift
     .accessibilityElement(children: .ignore)
     .accessibilityLabel(viewModel.accessibilityLabel)
     .accessibilityHint(viewModel.expenses.isEmpty ? "Adds an expense" : "Shows the day's expenses")
     ```
     `cellFace` is `@ViewBuilder`: `if style == .koyomi { koyomiFace } else { classicFace }`. `classicFace` is the current `ZStack { cellBackground }` chain from `:71-98`, with these changes:
     - **Numeral overlay (`:76-86`):** `Text("\(dayNumber)").font(.custom(AppFont.mono, fixedSize: style.dayNumeralSize)).foregroundStyle(numeralColor).frame(width: style.ensoSize, height: style.ensoSize).padding(.top, numeralInset).padding(.leading, numeralInset)`. Delete `.opacity(0.6)`.
     - Replace `.overlay(borderOverlay)` (`:97`) with `.overlay(borderOverlay).overlay(alignment: .topLeading) { todayEnso }`, both after `.clipShape`.
   - **`koyomiFace`:**
     ```swift
     private var koyomiFace: some View {
         ZStack(alignment: .topLeading) {
             if viewModel.displayDay, let day = viewModel.dayNumber {
                 Text("\(day)")
                     .font(.custom(AppFont.mono, fixedSize: style.dayNumeralSize))
                     .foregroundStyle(numeralColor)
                     .frame(width: style.ensoSize, height: style.ensoSize)
                 if viewModel.holiday != nil {
                     Text("祝").font(.custom(AppFont.kanjiBold, fixedSize: 9)).foregroundStyle(Color.shu)
                         .padding(.top, 4).padding(.trailing, 3)
                         .frame(maxWidth: .infinity, alignment: .topTrailing)
                 }
                 MemoLine()
                     .stroke(Color.rule, style: StrokeStyle(lineWidth: 1 / displayScale, dash: [1, 3]))
                     .frame(height: 1).padding(.horizontal, 4)
                     .offset(y: style.ensoSize + 1)
             }
         }
         .frame(maxWidth: .infinity, alignment: .topLeading)
         .frame(height: height, alignment: .top)
         .overlay { if let primary = viewModel.primaryExpense {
             if style.usesDots { dotsLayer } else { expenseFloatingLayer(primary: primary) } } }
         .overlay(alignment: .topLeading) { todayEnso }
         .contentShape(Rectangle())
     }
     ```
     ```swift
     private struct MemoLine: Shape {           // file-private, below DayCell
         func path(in r: CGRect) -> Path { Path { $0.move(to: CGPoint(x: r.minX, y: r.midY)); $0.addLine(to: CGPoint(x: r.maxX, y: r.midY)) } }
     }
     ```
   - **Today, numeral colour, glow removal:**
     ```swift
     @ViewBuilder private var todayEnso: some View {
         if viewModel.status == .current, showsEnso, let date = viewModel.date {
             EnsoMark(date: date, size: style.ensoSize)
                 .padding(.top, numeralInset).padding(.leading, numeralInset)
                 .allowsHitTesting(false)
         }
     }
     private var numeralColor: Color {
         if viewModel.status == .current { return .ink }
         if viewModel.holiday != nil || viewModel.weekday == 1 { return .shu }
         return viewModel.weekday == 7 ? .ai : .ink
     }
     ```
     - Delete the whole `.current` case body in `borderOverlay` (`:222-245`, the glow), leaving `case .current: EmptyView()`.
   - **Expense layers:**
     - `expenseFloatingLayer` `HStack(spacing: -10)` (`:113`) → `HStack(spacing: style == .koyomi ? -7 : -10)`
     - `dotsLayer` `"+n"` (`:150-151`) → `.font(.custom(AppFont.mono, fixedSize: 8))`, `.foregroundStyle(Color.inkSecondary)`
   - **`overflowBadge` (`:159-171`):**
     - fill `Color.paperRaised`
     - stroke `Color.ruleStrong`, `lineWidth: 1 / displayScale`
     - text `.font(.custom(AppFont.mono, fixedSize: 9))`, `.foregroundStyle(Color.ink)`
   - **`logoCircle` (`:173-180`):** pass `glass: false`.
   - **`baseBackgroundColor` (`:203-210`):** `Color.gray.opacity(x)` → `Color.ink.opacity(…)` with 0.05 / 0.025 for compact and 0.06 / 0.03 for the others. Add `case (.koyomi, _): Color.clear` as the **first** arm. `koyomiFace` doesn't use it, but keep the switch honest.
   - **`DayClickStyle` (`:277-295`):**
     - Replace `.scaleEffect` + `.spring(duration: 0.2, bounce: 0.4)` with `.opacity(pressed ? 0.6 : 1)` and `.animation(reduceMotion ? nil : .smooth(duration: 0.15), value: pressed)`. Add `@Environment(\.accessibilityReduceMotion)` to the style.
     - Keep the haptic.

9. **Create `LinguicaSubTracker/Features/Home/Views/Components/Calendar/Month/WeekdayBand.swift` (new):**
   ```swift
   struct WeekdayBand: View {
       var style: CalendarStyle = .koyomi
       @Environment(\.colorScheme) private var scheme
       @Environment(\.displayScale) private var displayScale

       var body: some View {
           Group {
               if style == .koyomi {
                   HStack(spacing: 0) {
                       ForEach(0..<7, id: \.self) { i in
                           label(i, plain: Color.ink)
                               .frame(maxWidth: .infinity, maxHeight: .infinity)
                               .overlay(alignment: .trailing) {
                                   if i < 6 { Rectangle().fill(Color.ink.opacity(0.25)).frame(width: 1 / displayScale) }
                               }
                       }
                   }
                   .background(Color.paperRaised)
                   .environment(\.colorScheme, .dark)          // sumi band in both modes
                   .overlay(alignment: .top) { if scheme == .dark { Rule(color: .ruleStrong) } }
                   .overlay(alignment: .bottom) { if scheme == .dark { Rule(color: .ruleStrong) } }
               } else {
                   HStack(spacing: 0) {
                       ForEach(0..<7, id: \.self) { i in label(i, plain: Color.inkSecondary).frame(maxWidth: .infinity) }
                   }
               }
           }
           .frame(height: 28)
           .accessibilityHidden(true)
       }

       private func label(_ i: Int, plain: Color) -> some View {
           HStack(alignment: .firstTextBaseline, spacing: 3) {
               Text(JapaneseCalendar.weekdayLatin[i]).font(.custom(AppFont.mono, fixedSize: 10)).tracking(0.6)
               Text(JapaneseCalendar.weekdayKanji[i]).font(.custom(AppFont.kanjiBold, fixedSize: 11))
           }
           .foregroundStyle(i == 0 ? Color.shu : (i == 6 ? Color.ai : plain))
       }
   }
   ```

10. **`MonthView.swift`:**
    - **Parameters:**
      - default `style` → `.koyomi` (`:11`)
      - add `var showsWeekdayHeader = true` **directly after `height` (`:12`)**, so the memberwise order is `…style:height:showsWeekdayHeader:onTap:…`
      - delete the stored `spacing` (`:13`) and add `private var spacing: CGFloat { style == .koyomi ? 0 : 4 }`
      - make `columns` (`:20`) a computed `var` using `spacing`
      - delete `weekdaysList` (`:21`)
      - add `@Environment(\.displayScale) private var displayScale`
    - **`body` (`:23-28`):** `VStack(spacing: 0) { if showsWeekdayHeader { WeekdayBand(style: style) }; monthGrid }`. Delete `weekdaysHeader` (`:30-40`).
    - **Rows:**
      - `private var rows: Int { style.fixedRows ?? grid.count / 7 }`
      - `cellHeight` (`:63-68`) uses `CGFloat(rows)`
      - `monthGrid` iterates `ForEach(0..<rows * 7, id: \.self) { index in … }` with `let date = index < grid.count ? grid[index] : nil` and `expenses: index < expenses.count ? expenses[index] : []`
    - **Grid lines:** `.overlay { if style == .koyomi { KoyomiGridLines(rows: rows).stroke(Color.ruleStrong, lineWidth: 1 / displayScale).allowsHitTesting(false) } }` after `.frame(height: height)` (`:60`). Add the file-private shape:
      ```swift
      private struct KoyomiGridLines: Shape {
          let rows: Int
          func path(in r: CGRect) -> Path {
              var p = Path()
              for c in 1..<7 {
                  let x = r.minX + r.width * CGFloat(c) / 7
                  p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY))
              }
              for row in 1...rows {
                  let y = r.minY + r.height * CGFloat(row) / CGFloat(rows)
                  p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y))
              }
              return p
          }
      }
      ```

11. **`CalendarView.swift`: update the 60-point constants together.**
    - Default `calendarStyle: CalendarStyle = .rounded` (`:14`) → `.koyomi`.
    - Add `@State private var ensoReplay = 0`.
    - Body: `VStack(spacing: 0) { WeekdayBand(style: calendarStyle).padding(.horizontal, 12); ZStack { …TabView…; …overlay… }.frame(height: calendarStyle.gridHeight).environment(\.ensoReplay, ensoReplay) }`. Keep the two observation reads (`:25-26`) at the top of `body`.
    - Pass `showsWeekdayHeader: false` to `MonthView` (`:31-42`).
    - Delete `.padding(.top, 60)` (`:64`), the comment (`:68`) and `.frame(height: calendarStyle.gridHeight + 60)` (`:69`). The `+60`, the `top: 60` and `MonthView`'s 52 + 8 are now all gone together, and the band is a fixed 28pt.
    - `onComplete` (`:57-61`): `withAnimation(.easeOut(duration: 0.2)) { viewModel.rewindPair = nil }; ensoReplay += 1`.

12. **`CalendarRewindOverlay.swift`: rewrite the body as the ink wipe.**
    - Keep the stored properties (`:4-9`), with the default `style` → `.koyomi`.
    - Delete `@Namespace`, `showTarget`, `columns`, `spacing`, `cellHeight`, `grid(for:isTarget:)` and `status(for:)` (`:11-23`, `:47-87`).
    ```swift
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 0.0

    var body: some View {
        let forward = target.date > source.date
        ZStack {
            page(source)
            page(target)
                .mask { Rectangle().scaleEffect(x: reduceMotion ? 1 : progress, y: 1,
                                                anchor: forward ? .trailing : .leading) }
                .opacity(reduceMotion ? progress : 1)
        }
        .frame(height: height)
        .allowsHitTesting(false)
        .environment(\.showsEnso, false)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2)
                          : .timingCurve(0.2, 0.7, 0.3, 1, duration: 0.55)) { progress = 1 }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 750_000_000)
                onComplete()
            }
        }
    }

    private func page(_ month: MonthData) -> some View {
        MonthView(store: store, month: month.date, grid: month.grid, expenseCounts: month.expenseCounts,
                  expenses: month.expenses, style: style, height: height,
                  showsWeekdayHeader: false, onTap: { _ in })
            .background(Color.paper)
    }
    ```
    - `CalendarRewindOverlayPreviewHost.swift:18`: `CalendarStyle.koyomi.gridHeight`.

13. **Create `LinguicaSubTracker/Features/Home/Views/Components/Calendar/KoyomiHeader.swift` (new)** to the §2 spec:
    ```swift
    struct KoyomiHeader: View {
        let viewModel: CalendarViewModel
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        private static let posix = Locale(identifier: "en_US_POSIX")

        var body: some View {
            let date = viewModel.currentMonth
            let month = Calendar.current.component(.month, from: date)
            let year = Calendar.current.component(.year, from: date)
            VStack(spacing: 0) {
                KasagiHeader()
                HStack(spacing: 0) {
                    edge(-1)
                    HStack(spacing: 0) {                                   // one VoiceOver element
                        VStack(alignment: .leading, spacing: 2) {
                            Text(JapaneseCalendar.eraYear(for: date))
                                .font(.custom(AppFont.kanjiBold, size: 15, relativeTo: .headline))
                                .foregroundStyle(Color.ink)
                            Text(String(year)).typography(.labelMedium).foregroundStyle(Color.inkSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(month)").font(.custom(AppFont.mono, fixedSize: 56)).foregroundStyle(Color.shu)
                            .contentTransition(.opacity)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(date.formatted(Date.FormatStyle(locale: Self.posix).month(.wide)))
                                .typography(.labelMedium).foregroundStyle(Color.inkSecondary)
                            Text(JapaneseCalendar.wafuMonthNames[month - 1])
                                .font(.custom(AppFont.kanjiBold, size: 15, relativeTo: .headline)).tracking(4)
                                .foregroundStyle(Color.ink)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(date.formatted(Date.FormatStyle(locale: Self.posix).month(.wide).year()))
                    .accessibilityAddTraits(.isHeader)
                    edge(+1)
                }
                .frame(minHeight: 48)
                .padding(.top, 6)
                sekkiLine(year: year, month: month).padding(.top, 3)
            }
            .frame(minHeight: 80)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewModel.currentMonthIndex)
        }

        /// Faint neighbour-month label (echo of the wall calendar's corner minis); tap pages.
        @ViewBuilder private func edge(_ step: Int) -> some View {
            let target = viewModel.currentMonthIndex + step
            if viewModel.months.indices.contains(target) {
                let other = viewModel.months[target].date
                Button {
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
                        viewModel.currentMonthIndexBinding().wrappedValue = target
                    }
                } label: {
                    HStack(spacing: 3) {
                        if step < 0 { Image(systemName: "chevron.left").iconStyle(size: 9, color: .inkSecondary) }
                        Text(other.formatted(Date.FormatStyle(locale: Self.posix).month(.abbreviated)))
                            .typography(.labelMedium).foregroundStyle(Color.inkSecondary)
                        if step > 0 { Image(systemName: "chevron.right").iconStyle(size: 9, color: .inkSecondary) }
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(step < 0 ? "Previous month" : "Next month")
                .accessibilityValue(other.formatted(Date.FormatStyle(locale: Self.posix).month(.wide)))
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }

        /// "寒露 10.8 · 霜降 10.23"; empty (same height) when the year has no table yet.
        private func sekkiLine(year: Int, month: Int) -> some View {
            HStack(spacing: 6) {
                ForEach(Array(JapaneseCalendar.sekki(year: year, month: month).enumerated()), id: \.offset) { i, term in
                    if i > 0 { Text("·").typography(.labelMedium) }
                    Text(term.name).font(.custom(AppFont.kanji, size: 12, relativeTo: .caption))
                    Text("\(month).\(term.day)").typography(.labelMedium)
                }
            }
            .foregroundStyle(Color.inkSecondary)
            .frame(height: 14)
            .accessibilityHidden(true)
        }
    }
    ```
    - **Mount it** in `HomeView.swift` as the first child of the `VStack` (`:33`), before `if viewType == .calendar` (`:34`): `KoyomiHeader(viewModel: vm.calendarViewModel).padding(.horizontal, 12)`. It shows in both modes.
    - When `home_screen_ux.md` step 9 lands, it replaces that `VStack` and mounts the same `KoyomiHeader(viewModel:)` call.
    - Do **not** touch `HomeToolbar`. Until `home_screen_ux.md` step 4 lands, the month also shows in the toolbar.

14. **`ExpensesInDay` holiday line.**
    - Directly under the header (`header`, `ExpensesInDay.swift:95-105`, or `list_view.md`'s `NotebookDayHeader` if that has landed), add:
      ```swift
      if let holiday = JapaneseCalendar.holiday(on: viewModel.date) {
          HStack(spacing: 6) {
              Text("祝 \(holiday.ja)").font(.custom(AppFont.kanji, size: 13, relativeTo: .footnote)).foregroundStyle(Color.shu)
              Text(holiday.en).typography(.labelMedium).foregroundStyle(Color.inkSecondary)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Holiday: \(holiday.en)")
          .padding(.bottom, 8)
      }
      ```
    - In `ExpensesInDayViewModel.compactHeight` (`:28-34`, or `list_view.md`'s replacement formula), add `+ (JapaneseCalendar.holiday(on: date) == nil ? 0 : 24)` before the `min(…, 520)`.
    - "CAD": do not edit here. Verify `price_display.md` step 4 already replaced `:219` with `MoneyFormatter.format(vm.total, settings: settingsStore.settings)`; if it has not landed, stop and run that step first.
    - `list_view.md` (which runs after this doc) replaces the header with `NotebookDayHeader` and rewrites `compactHeight`; its steps 8–9 keep this holiday line and the `+24` term.

15. **Widget today ensō** (`SatoruWidgets/WidgetViews.swift`):
    - In `monthGrid` (`:393-397`), change today's numeral colour to `Color.ink` and add to the `Text`:
      ```swift
      .background {
          if day.isToday {
              EnsoShape(seed: EnsoShape.seed(for: date)).fill(Color.shu)
                  .frame(width: numberSize * 2.2, height: numberSize * 2.2)
                  .widgetAccentable()
          }
      }
      ```
    - Delete the `.background { if day.isToday { Rectangle()… } }` block (`:404-409`).
    - Leave `:443` and `:490`.

16. **Previews.**
    - `DayCellPreviewHost.swift`:
      - pass `style: .koyomi` and `height: 62`, and set grid `spacing: 0` (`:24`, `:27`)
      - add `let sub3 = Expense(name: "Notion", price: 8, billingCycle: .monthly, startDate: weekStart)` and use `[sub1, sub2, sub3]` at index 4 (`:19`) to show the overflow badge
      - The fixture week (Sun 2026-05-03 …) already covers: a Sunday holiday (5/3), weekday holidays (5/4–5/6, including 振替休日) and today-on-holiday (index 2, 5/5 `.current`).
    - `MonthViewPreviewHost` and `CalendarViewPreviewHost` compile unchanged (default style `.koyomi`).

17. **Tests:** create `LinguicaSubTrackerTests/JapaneseCalendarTests.swift` (new):
    ```swift
    import Foundation
    import SwiftUI
    import Testing
    @testable import LinguicaSubTracker

    @Suite("Japanese calendar data")
    @MainActor
    struct JapaneseCalendarTests {
        private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
            Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
        }

        @Test("Holidays: fixed, substitute, sandwiched, and today's スポーツの日")
        func holidays() {
            #expect(JapaneseCalendar.holiday(on: day(2026, 10, 12))?.ja == "スポーツの日")
            #expect(JapaneseCalendar.holiday(on: day(2026, 5, 6))?.ja == "振替休日")
            #expect(JapaneseCalendar.holiday(on: day(2026, 9, 22))?.ja == "国民の休日")
            #expect(JapaneseCalendar.holiday(on: day(2027, 3, 22))?.ja == "振替休日")
            #expect(JapaneseCalendar.holiday(on: day(2026, 10, 13)) == nil)
            #expect(JapaneseCalendar.holidays.keys.filter { $0 / 10_000 == 2026 }.count == 18)
            #expect(JapaneseCalendar.holidays.keys.filter { $0 / 10_000 == 2027 }.count == 17)
        }

        @Test("Header data: era, month names, two solar terms per 2026 month")
        func headerData() {
            #expect(JapaneseCalendar.eraYear(for: day(2026, 10, 12)) == "令和8年")
            #expect(JapaneseCalendar.wafuMonthNames[9] == "神無月")
            #expect((1...12).allSatisfy { JapaneseCalendar.sekki(year: 2026, month: $0).count == 2 })
        }

        @Test("Ensō is seeded by day, deterministic, and stays inside its box")
        func enso() {
            let seed = EnsoShape.seed(for: day(2026, 10, 12))
            #expect(seed == 20261012)
            let box = CGRect(x: 0, y: 0, width: 40, height: 40)
            let path = EnsoShape(seed: seed).path(in: box)
            #expect(!path.isEmpty)
            #expect(box.contains(path.boundingRect))
            #expect(path == EnsoShape(seed: seed).path(in: box))
            #expect(EnsoShape.width(0) > EnsoShape.width(0.5) && EnsoShape.width(1) < 0.2)
        }

        @Test("Stored style 'koyomi' decodes; unknown values fall back to Koyomi")
        func styleDecoding() throws {
            let data = Data(#"["koyomi","fromTheFuture","rounded"]"#.utf8)
            #expect(try JSONDecoder().decode([CalendarStyle].self, from: data) == [.koyomi, .koyomi, .rounded])
        }
    }
    ```
    - `CalendarViewModelTests` (`:10-25`, `:30-46`) must pass **unchanged**.

18. **Cleanup grep.** Each of these must return nothing:
    ```
    grep -rn "weekdaysList\|weekdaysHeader\|matchedGeometryEffect\|dayLabelInset\|gridHeight + 60\|padding(.top, 60)" LinguicaSubTracker/Features/Home
    grep -rn "\.font(\.system" LinguicaSubTracker/Features/Home/Views/Components/Calendar
    grep -rn "rippleEffect\|onRipple\|rippleSpace" LinguicaSubTracker/Features/Home
    grep -n "Color.gray\|Color.primary" LinguicaSubTracker/Features/Home/Views/Components/Calendar/Month/DayCell.swift
    ```

## Preserve
- **Month state:**
  - `currentMonthIndexBinding()` stays the single writer: paging, the header edges, the Year grid, Today and `DEBUG_MONTH_INDEX` all go through it (`CalendarViewModel.swift:46-51`).
  - `monthKey` format (`:42-44`; `CalendarViewModelTests.swift:44`; `TotalViewModel.swift:22`; `TotalView.swift:77,81`).
  - `jumpToCurrentMonth()` + `rewindPair` (`:58-70`); the rewind's `onComplete` after 750 ms.
- **Observation hooks:** `let _ = store.expenses` / `let _ = coordinator.filter` (`CalendarView.swift:25-26`). `HomeView` reads `calendarStyle` at `:51` for live style switching.
- **Navigation:**
  - `onTap` → `coordinator.selectedDay` (`CalendarView.swift:39`); an empty day opens add (`HomeView.swift:167-185`).
  - `onEditExpense` / `onDeleteExpense` (`:40-41`).
- **Quick actions:** the context menu View/Edit/Delete and the "Delete Expense" alert copy (`DayCell.swift:30-63`), now also on `.koyomi`.
- **Every expense element in a cell:**
  - logos + overflow badge (logo styles)
  - dots + `+n` (dot styles)
  - the brand border (`.contrastRounded`)
  - the gradient tint (`.rounded`/`.bigger`)
- **Settings safety:**
  - `AppSettings.calendarStyle` stays optional.
  - The lenient decoder stays lenient.
  - The `CalendarStyleSheet` live re-render and `.sensoryFeedback(.selection)` (`CalendarStyleSheet.swift:27`) stay.
- **Week start:** Sunday-first in `CalendarService.swift:27`, `ExpenseService.swift:356-361` and `WidgetData.swift:163`. The weekday tables assume index 0 = Sunday.
- **Widget:**
  - `.widgetAccentable()` on the today marker
  - widget day `Link`s (`WidgetViews.swift:417-426`)
  - `WidgetViews.swift`/`WidgetData.swift` still compile into the app for the DEBUG gallery
- **DEBUG hooks:**
  - `SIMCTL_CHILD_DEBUG_HOME_VIEW=list|calendar` (`HomeView.swift:85-89`)
  - `SIMCTL_CHILD_DEBUG_MONTH_INDEX=<n>` (`:93-99`)
  - `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=<section>` (`:101`)
  - `SIMCTL_CHILD_DEBUG_OPEN_SETTINGS_PAGE=calendarstyle` (`SettingsView.swift:86`)
  - `DEBUG_OPEN_SHEET` (owned by `home_screen_ux.md` / `HomeListView`)
- **Onboarding:** `OnboardingCalendarHero` still compiles and renders (`MonthView` default style is now `.koyomi`, no glass in cells).
- **Previews:** `DayCellPreviewHost`, `MonthViewPreviewHost`, `CalendarViewPreviewHost`, `CalendarRewindOverlayPreviewHost`, the `CalendarStyleSheet` `#Preview`.

## Risks / gotchas
- **`general_app_ui.md` vs this doc:**
  - Its `EnsoShape` contract originally listed `maxWidth: Double = 0.12`; the cross-doc pass aligned it to this doc's **0.0875 of the box side**, which gives the canonical 3.5pt wMax at 40pt (0.12 would be 4.8pt). If an older copy of the contract shows 0.12, this doc wins.
  - Its §10 widget today marker (square stroke) is the interim it planned; step 15 swaps it for the ensō, as that section anticipates.
  - Its DayCell line refs (`:87,170,188`) predate the ripple removal. The current lines are `:79`, `:150`, `:168`.
- **Forced dark environment on the band:** `.environment(\.colorScheme, .dark)` must make the `UIColor { traits in … }` tokens resolve to their dark variants.
  - SwiftUI resolves dynamic `UIColor`s against the environment's colour scheme. Verify on a device, in light mode: band #1C1816, text #F4EFE6.
  - Fallback if it doesn't: hardcode the band with `Color(hex:)` dark values in `WeekdayBand` only.
- **`Path.union` / `subtracting` / `strokedPath`** are iOS 17+ SwiftUI `Path` APIs (the target is 26.4). If boolean ops leave slivers at the 起筆 blob, drop the blob union. The entry width of `1.15·wMax` already reads as a press.
- **Draw-on retrigger:** setting `progress = 0` and animating to 1 in the same transaction coalesces into no animation. That's why `draw()` animates in a `Task`. If a flash of the full ensō shows before the draw, set `progress = 0` inside `withTransaction(Transaction(animation: nil))`.
- **Paged `TabView` lifecycle:** adjacent pages may be built before they're visible, so `onAppear` can fire off-screen and the draw-on may have finished by the time the user swipes in. That's acceptable: the explicit Today replay always runs.
- **The onboarding hero is 300pt tall:** 6 rows of 50pt mean the 20pt logos touch the 38pt numeral box. It renders inside `.rippleCard()` (`layerEffect`). That is safe because cells now have no glass or material (`LogoCircle(glass: false)`). Onboarding is restyled later (plan).
- **Default change reaches existing users:** anyone whose `calendarStyle` is nil switches to Koyomi. That's intended.
  - With iCloud settings sync (`SettingsStore.applyRemote`, `SettingsStore.swift:25-33`), a second device on an **older** build decodes `"koyomi"` as `.rounded`. If it then saves settings, it can write `"rounded"` back.
  - Note this in release notes; no code fix.
- **Logos at 20pt** show less detail. Three or more expenses in a 50pt cell = 2 logos + `+n`, same as today.
- **Dynamic Type:** cell numerals and band labels are fixed-size, because the grid geometry is fixed. The header scales (capped at `.accessibility2`) and grows past 80pt. `home_screen_ux.md`'s `ScrollView` absorbs that.
- **Kanji fonts:** Fragment Mono has no CJK. Every kanji is a separate `Text` with `AppFont.kanji`/`kanjiBold` (Hiragino Mincho ships with iOS). Mixing them in one `Text` falls back to the system sans.
- **Locale:** `OCTOBER`, `SEP`, the year and the accessibility month use `en_US_POSIX`. A ja_JP device would otherwise render `10月`/`2026年` next to the kanji.
- **Header leads the wipe:** `jumpToCurrentMonth()` writes `currentMonthIndex` immediately, so the header shows the target month while the grid is still wiping. That is intended (the header is the "sheet title").
- **Empty-day holiday:** an empty day opens the add form, not `ExpensesInDay`, so the holiday name only shows for days with expenses (plus VoiceOver).
- **The widget extension is nonisolated and the app defaults to MainActor.** `JapaneseCalendar` and `EnsoShape` hold only value types and Foundation/SwiftUI calls, so they compile in both. Mark new test suites `@MainActor`, as `CalendarViewModelTests` does.
- **Stale builds:** if the simulator shows the old rounded cells after `BUILD SUCCEEDED`, delete `DerivedData/…/Build/Intermediates.noindex` and rebuild with `COMPILATION_CACHE_ENABLE_CACHING=NO`.

## Verification
1. **Build:** `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build`. It must compile with no warnings in the new files.
2. **Tests:** `xcodebuild … test -only-testing:LinguicaSubTrackerTests/JapaneseCalendarTests -only-testing:LinguicaSubTrackerTests/CalendarViewModelTests`. All pass, and `CalendarViewModelTests` is unedited.
3. **Grep:** step 18 returns nothing.
4. **Screenshots**, light and dark. Cold launch, wait about 8s, then `xcrun simctl io <udid> screenshot`. Switch the theme in Settings → Appearance with simulator `control` taps. On 2026-10-12 the indices are 0 = Sep 2026, 1 = Oct 2026, 6 = Mar 2027, 8 = May 2027.

   | Launch env (`SIMCTL_CHILD_…`) | Check |
   |---|---|
   | `DEBUG_HOME_VIEW=calendar` | Header: kasagi, `‹ SEP`, `令和8年`/`2026`, shu `10`, `OCTOBER`/`神無月`, `NOV ›`, `寒露 10.8 · 霜降 10.23`. Sumi band `SUN日…SAT土`, SUN shu, SAT ai. 6 rows, hairline grid, no rounded cells. **12 has an open shu ensō (gap lower-left), ink numeral, `祝` top-right.** Sundays shu, Saturdays ai. Logos + `+n` in the memo area. Blank leading/trailing cells. |
   | same, dark | Band is #1C1816 with `ruleStrong` hairlines top and bottom, not a shu band. Ensō #E84A33. |
   | `DEBUG_HOME_VIEW=calendar DEBUG_MONTH_INDEX=0` | After 2s, September: 21/22/23 shu with `祝`; the header reads 長月 / 白露 9.7 · 秋分 9.23. |
   | `… DEBUG_MONTH_INDEX=6` | March 2027: 21 (Sun) and 22 (振替休日) shu + `祝`; the 節気 line is empty (no 2027 table). |
   | `… DEBUG_MONTH_INDEX=8` | May 2027: a real 6-week month, and the grid height is identical to October. 3/4/5 May are holidays. |
   | `DEBUG_HOME_VIEW=list` | The Koyomi header shows above the list (mounted in `HomeView`). |
   | `DEBUG_OPEN_SETTINGS_PAGE=calendarstyle` | "Koyomi" is the first row, with a square preview + ensō; every other style still renders. Select each in turn: Home re-renders live, and every style shows the ensō, mono numerals and weekday colours. |
   | `DEBUG_WIDGET_GALLERY=calendar-month` and `calendar-month-dark` | Today's numeral is ink inside a small shu ensō, with no square stroke. |
5. **Interaction** (simulator `control` taps):
   - Tap `NOV ›`: it pages to November. At the last month the edge is hidden.
   - Page to December and tap Today: the grid wipes back to October, **then** the ensō draws on (about 0.55s).
   - Long-press a day with an expense in Koyomi: View / Edit / Delete; Delete asks for confirmation.
   - Tap the 12th, after adding an expense on it: the `ExpensesInDay` sheet shows `祝 スポーツの日  SPORTS DAY` under the header, and the total uses the settings currency.
   - Tap a blank cell: nothing happens, with no press dim.
6. **Accessibility:**
   - **VoiceOver on today:** "Monday, October 12, Today, Sports Day, …". Blank cells and the band are skipped. The header reads "October 2026, heading", and the edges read "Previous month, September".
   - **Reduce Motion:** the ensō is static on launch and after Today, the rewind is a cross-fade, and the press doesn't animate.
   - **Largest Dynamic Type:** the header grows, nothing truncates mid-glyph, and the grid keeps 370pt.
7. **Onboarding:** `SIMCTL_CHILD_ONBOARDING_PAGE=0` (`.calendar` is the first `OnboardingPage`, `OnboardingViewModel.swift:4-6`) after a reinstall. The hero shows the Koyomi grid with no black flashes during the ripple.
8. **Previews:** every preview listed in Preserve renders.

## Open points / dig deeper
- **六曜 in the annotation slot (v2).**
  - What to research: `(旧暦 month + day) % 6` via `Calendar(identifier: .chinese)`. That calendar is computed for UTC+8, so check dates where a new moon falls near JST midnight against a Japanese almanac. NAOJ doesn't publish 旧暦, and the lunar calendar's rules break down in 2033 ([bestcalendar 六曜](https://bestcalendar.jp/guides/kichijitsu/rokuyo), [Apple NSChineseCalendar](https://developer.apple.com/documentation/foundation/nschinesecalendar)).
  - Why: the reference shows 六曜, and a wrong value is worse than none.
- **Holiday data past 2027 and 2027 verification.**
  - What to research: whether to bundle the CAO `syukujitsu.csv` (machine-readable, unchecked) or keep extending the static table yearly. Confirm the 2027 equinox dates against the CAO page.
  - Why: the table is a hard dependency of the cell colours and of `list_view.md`'s headers.
- **二十四節気 2027.**
  - What to research: add the NAOJ 暦要項 2027 table.
  - Why: until then the header's 節気 line is empty for Jan–Oct 2027 (the window runs to +12 months).
- **Who sees JP holidays.**
  - What to research: show them for every user, only when `Locale.current.region == .japan`, or behind a setting.
  - Why: the default currency is CAD, and a Canadian user may read red weekday numerals as errors.
- **Saturday `ai` vs monochrome.**
  - What to research: a 70/25/5 pixel histogram of the month grid; compare against Midori's no-red-ink trend ([bungu.store](https://bungu.store/products/md-wall-calendar-with-pencil-2027-md-product)).
  - Why: blue is outside the red/black/gold palette.
- **Monday-first option.**
  - What to research: a `weekStart` setting threaded through `CalendarService.daysGrid`, `ExpenseService.weekInterval`, `WidgetData` and the weekday-table indexing.
  - Why: business calendars trend Monday-first ([FinancialField](https://financial-field.com/living/entry-377145)). It is hard-wired Sunday today.
- **Ensō authenticity.**
  - What to research: tune `w(t)`, the drift and the kasure against real brush scans. Decide procedural vs 3–5 hand-drawn SVG assets, and who draws or licenses them.
  - Why: a synthetic stroke can read as clip-art.
- **Path boolean-op cost.**
  - What to research: profile `EnsoShape.path(in:)` on an older device inside the paging `TabView` and the Year grid.
  - Why: `union`/`subtracting` are heavier than plain fills. Verify on device.
- **Forced colour scheme on the band.**
  - What to research: verify on device that `.environment(\.colorScheme, .dark)` resolves the `UIColor`-backed tokens dark.
  - Why: the band's whole look depends on it.
- **Persistent selection state.**
  - What to research: if iPad or multi-select ever needs a selected day, a 1pt `kin` underline under the numeral.
  - Why: two circles (selection + ensō) would be ambiguous.
- **Real mini months.**
  - What to research: put 7×6 minis in the blank first/last-row cells when there are three or more blanks, like 文字月表. Check photos of Todan, 新日本カレンダー, Kokuyo and Delfonics sheets.
  - Why: placement evidence is weak, and the minis are the reference's signature.
- **Widget weekday/holiday colours and the week-widget ensō.**
  - What to research: apply the numeral colour rule in the widget month grid, and size an ensō for `weekColumns` (`WidgetViews.swift:488-490`).
  - Why: consistency with the app. Left out of v1 to keep widget changes minimal.
- **Cell density.**
  - What to research: whether the 20pt logos stay legible for brand assets, or whether `.koyomi` should switch to count + first logo.
  - Why: the user wants every element kept, and the slot is about 20pt tall.
- **Onboarding hero.**
  - What to research: a 340–370pt hero height or a dedicated Koyomi hero.
  - Why: 300pt crowds a 6-row grid.

**Status: proposed, not implemented.**
