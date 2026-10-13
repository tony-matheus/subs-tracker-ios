# Research results and future points: "Modern Japan" redesign

## Purpose and how to use this set
- **What this file is:** the general file the user asked for ("a General markdown file to indicate what to dig more in the research"). It is also the index of the doc set in `Docs/plans/07-japan-redesign/`.
- **Who reads it:** an AI coding agent (or a person) with no prior context. Read this file first, then implement one feature doc at a time in the order below.
- **What it holds:**
  - the doc index and who owns each shared piece
  - the execution order across docs
  - the design direction and the canonical tokens
  - the research findings, with numbers and sources
  - every open point from every doc and research note, prioritised
- **Priorities used below:** **P1** = decide or verify before shipping v1. **P2** = check during or right after v1. **P3** = later or optional.
- **Code baseline:** `general_app_ui.md` (the foundation) is already implemented in the working tree (uncommitted). Git `HEAD` (6d7c109) is the pre-redesign code. Every feature doc describes the working tree.
- **One owner per change.** Each shared piece has exactly one owner doc with the full spec. Other docs point to it and only consume it. If two docs seem to disagree, the owner in the table below wins.

| File | Scope | Depends on | Owns (shared pieces) |
|---|---|---|---|
| `general_app_ui.md` | Palette tokens, Fragment Mono migration, radius tokens, torii motifs, paper background and paper cards, Liquid Glass rules, `AppButton` mapping, ripple removal (except onboarding), widget base, hardcoded-colour sweep | nothing (**already implemented**) | `Color.paper`…`Color.ai`, `AppFont`, `AppRadius` (`LinguicaSubTracker/Core/Utils/AppTheme.swift:52-75`); `Kasagi`, `KasagiHeader`, `Hashira`, `SectionLabel`, `Rule` (`LinguicaSubTracker/Core/UI/Motifs/Torii.swift`); `GlassSection` as a paper card; `Theme.font`, `AppTypography` styles; `ThemeFontTests`; the component API contracts in its §7 |
| `charts.md` | Stats sheet (dial, trend bars, line chart, legend, cards), coins (mon coin), widget charts, budget scale options | `general_app_ui.md` | `BudgetColor.swift` (`Tier`, `tier`, `color`, `progressColor`); `HankoStamp` (`Core/UI/Motifs/HankoStamp.swift`, new); widget ring/bars/line and widget budget colours; `CoinStack`, `Coin`, `CoinProgress` deletion (step 14) |
| `price_display.md` | Brush-ink Home total, `InkReveal`, brush underline, `BudgetMark`, single `MoneyFormatter` path ("CAD" bug) | `general_app_ui.md`, `charts.md` | `TextAnimatedView`, `MoneyDisplay`, `TotalView`, `BudgetMark` (new), `MoneyFormatter.exact` (new), every `"CAD"` → `MoneyFormatter` fix (including `ExpensesInDay.swift:219`), `BudgetDetailsSheet` amount colours, `BudgetEditor` "Over by" |
| `forms.md` | Minimal forms: no logo-driven backgrounds, colour only on icons, square fields, error label, keypad keys, logo sheet, summary sheet, legacy-form routing | `general_app_ui.md` (optional: `list_view.md`'s `CategoryMark`) | `FormErrorLabel` (new), `FormRow` label default, `SimplifiedAddExpenseView` + sections, `ExpenseTemplateSheet`, `LogoSheet`, `NumKeyPadSheet` keys, `ExpenseSummarySheet` styling, deletion of `ExpenseFormView` |
| `calendar.md` | Koyomi month header, sumi weekday band, hairline cells, ensō today marker, holiday and 二十四節気 data, `.koyomi` style, ink-wipe rewind, widget today ensō | `general_app_ui.md`, `price_display.md` (CAD fix, verify only), `list_view.md` step 2 (applied early) | `KoyomiHeader` (new, mounted in `HomeView`), `WeekdayBand` (new), `EnsoShape` + `EnsoMark` (`Core/UI/Motifs/EnsoShape.swift`, new), `JapaneseCalendar` (`Core/Utils/JapaneseCalendar.swift`, new: holidays, 節気, 和風月名, weekday kanji, era), `CalendarStyle.koyomi`, `DayCell`/`MonthView`/`CalendarView`/`CalendarRewindOverlay`, widget month-grid today marker, `ExpensesInDay` holiday line |
| `list_view.md` | Notebook rows on paper: Home list, Search rows, `ExpensesInDay` rows/header/sum line | `general_app_ui.md`, `price_display.md`, `charts.md`, `calendar.md` | `Notebook`, `NotebookLine`, `NotebookDayHeader`, `CategoryMark` (`Core/UI/Containers/Notebook.swift`, new); notebook `ExpenseRow` (deletes `HomeExpenseRow`); `LogoCircle(glass:)`; `HomeListView` list body + coin-pile labels |
| `home_screen_ux.md` | Creative part: declutter Home after Apple Calendar; toolbar, Year grid, filter sheet, final `HomeView` composition | `general_app_ui.md`; step 6 needs `calendar.md`; step 9 needs `calendar.md`, `price_display.md`, `list_view.md` | `HomeToolbar` rewrite, `MonthPickerSheet` → Year grid, `HomeFilterSheet` (new), `HomeView` composition (step 9), deletion of `HomeActionButton`, toolbar stats ring, `HomeViewModel.budgetTint` |
| `research_results_and_future_points.md` (this) | Index, execution order, research summary, all open points, sources | all | nothing in code |

## Execution order
Build and run the tests after every step. Each doc's Verification section lists its own checks.

| # | Doc | Rationale |
|---|---|---|
| 0 | `general_app_ui.md` | **Already done.** Verify only: build, `ThemeFontTests`, and the grep gates in its Verification. Every other doc compiles against its tokens and motifs. |
| 1 | `charts.md` | Owns `BudgetColor.Tier` and `HankoStamp`, which `price_display.md` consumes. Skip its step 14 (`CoinProgress` deletion); `price_display.md` step 9 triggers it. |
| 2 | `price_display.md` | Creates the single `MoneyFormatter` path that `forms.md`, `calendar.md` and `list_view.md` rely on, and the `TotalView` that `home_screen_ux.md` step 9 composes. Ends step 9 by running `charts.md` step 14. |
| 3 | `forms.md` | Self-contained after 1–2. It may run in parallel with 4–5. Uses the inline square-dot spec, because `CategoryMark` does not exist yet (both render the same). |
| 4 | `calendar.md` | Runs `list_view.md` step 2 (`LogoCircle(glass:)`) first, then creates `JapaneseCalendar`, `EnsoShape`, `KoyomiHeader` and the cell redesign. Only verifies the CAD fix from step 2. |
| 5 | `list_view.md` | Needs `EnsoShape`, `JapaneseCalendar.weekdayKanji` and the holiday table from 4, and `MoneyFormatter` from 2. Keeps `calendar.md`'s `ExpensesInDay` holiday line and its `+24` height term. |
| 6 | `home_screen_ux.md` | Steps 1–5, 7–8 and 10–11 can land any time after 0 (in parallel with 1–5). Step 6 (Year grid ensō) needs 4. **Step 9 (final `HomeView` composition) lands last**, because it mounts 4's `KoyomiHeader`, 2's `TotalView` and 5's `HomeListView`. |

**Contract handoffs to check at each boundary:**
- After 1: `BudgetColor.tier(spent:budget:)` and `HankoStamp()` exist; the widget still builds.
- After 2: `grep -rn '\.currency(code' LinguicaSubTracker` is empty; `CoinProgress.swift` is gone.
- After 4: `KoyomiHeader(viewModel: vm.calendarViewModel).padding(.horizontal, 12)` is the first child of `HomeView`'s `VStack`; the toolbar still shows the month until 6.
- After 5: `HomeExpenseRow` is deleted; list headers show today's ensō with an `ink` numeral.
- After 6: one filled shu shape (the `+`) on Home; the top centre is empty.

## Design direction summary
**Concept: modern Japan.** Straight lines with one subtle curve, taken from the torii gate. Notebook ruling for lists. The Japanese wall calendar for the month view. Brush, old paper and seal ink as secondary references. Liquid Glass stays, but only on controls.
- **Torii (main reference):** straight posts, one gently curved lintel (kasagi). Double-rule headers, a shu vertical tick (hashira) as section marker, divider rules that overhang slightly (nuki).
- **Notebooks (main reference):** Kokuyo Campus, Hobonichi, Midori MD. Hairline rules on a 44pt pitch, a vermilion margin rule, a thicker rule for dates, dots as column guides.
- **Wall calendars (main reference):** 月めくり and 文字月表 sheets. Giant red month numeral, era year, 和風月名, black weekday band, numerals top-left, memo lines in each cell.
- **Brush (secondary):** an open ensō for today; the price writes itself in like ink; a tapering gold underline.
- **Old paper (secondary):** washi ivory in light mode, rō-iro lacquer in dark mode. Flat in v1; texture is an open point.
- **Ma (間) and restraint:** emptiness is deliberate space ([Japan House LA](https://japanhousela.com/articles/a-perspective-on-the-japanese-concept-of-ma)). One red symbol per screen, as in Kenya Hara's argument for a single powerful red ([Minimalissimo: White](https://minimalissimo.com/articles/white-by-kenya-hara)).

**Canonical tokens** (copied exactly from the approved plan; implemented in `AppTheme.swift:52-63`):

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

Rules: 70/25/5 ground/ink/accent; max one filled shu shape per screen; gold never a fill >24pt; prices default to ink; user category/logo colors untouched (icons/dots only), default category palette swap proposed in research file (new installs only).

**Typography**
- Fragment Mono (`FragmentMono-Regular`) everywhere Latin text renders; only Regular + Italic exist, both weight 400. No CJK glyphs.
- Hierarchy comes from size, case, tracking and the colour token. All `.weight(…)` chains were deleted; `AppTypography.Style` has no `weight` member.
- 13 styles from 34pt (`displayMedium`) to 11pt (`bodySmall`, `labelMedium`), registered with `relativeTo:` for Dynamic Type. Label styles are uppercase with +1.2 tracking. Display styles keep −0.5 / −0.3 tracking (the code supersedes the plan's "~0").
- Bold Text swaps to SF Mono semibold. Kanji go in a separate `Text` in Hiragino Mincho (`AppFont.kanji` W3, `AppFont.kanjiBold` W6). SF Symbols and emoji stay `.system`.
- The widget target has its own font registration and uses `mono(_:)` with `AppFont.mono`; `Theme.swift`/`Typography.swift` are app-only.

**Shapes**
- Two radius tokens: `AppRadius.grid = 0` (grid, rows, rules, marks) and `AppRadius.card = 4` (cards, chips, keys, custom glass). Capsules only where the system draws glass.
- Two line weights: hairline (`1 / displayScale`, `rule`) and 1pt (`ruleStrong`).
- Torii motifs: `KasagiHeader` (2pt kasagi with ends lifted 3pt, 3pt gap, 1pt shimaki; at most one per screen), `Hashira` (3pt shu tick), nuki overhang of 3pt on section dividers.
- No shadows on cards or toasts. Depth is paper on paper plus a rule.

**Glass scope**
- Liquid Glass on controls and navigation only: toolbars, sheets, floating buttons, pickers, menus, segmented controls.
- Content is opaque paper: cards (`GlassSection` is now a paper card), rows, calendar cells, list logos, stats cards.
- Untinted `.regular` by default; only the primary CTA is tinted (shu via `AccentColor`). Text on glass is `ink`.
- Never put a `layerEffect` shader on or over glass or a material: it renders black.

**Motion**
- No ripple, bounce, glow or metal. The ripple shader survives only in onboarding heroes (restyle later).
- Brush motions are a mask reveal, 0.55–0.7s ease-out: the ensō draw-on (0.55s), the price ink reveal (0.7s), the rewind ink wipe (0.55s).
- State changes use `.smooth(duration: 0.25)`. Every animation is gated on `accessibilityReduceMotion`.

## Research results

### Japanese palette and contrast findings
- **Traditional sources disagree on hexes** ([Wikipedia](https://en.wikipedia.org/wiki/Traditional_colors_of_Japan), [colordic](https://www.colordic.org/w), [NIPPON COLORS](https://nipponcolors.com/)). Example: 朱色 is #EB6101 on colordic but #FF3500 on Wikipedia. The UI tokens are tuned between 緋 #D3381C and 紅緋 #F35336 to pass contrast, so they are not canonical pigments.
- **Cultural anchors:**
  - Torii red is cinnabar, read as protective ([Japaholic](https://en.japaholic.com/why-is-a-torii-red/), [Torii](https://en.wikipedia.org/wiki/Torii)).
  - Lacquerware is black and vermilion, with gold maki-e over black rō-iro ([JAANUS urushi-nuri](https://projects.mcah.columbia.edu/jaanus/node/360), [Shibui](https://shibuiswords.com/Lacquer-ware.htm)).
  - Seal paste (朱肉) is vermilion ([JGJE shuniku](https://www.tkgje.jp/entries/06000/06192_shuniku.html)).
  - The flag's red is 紅 beni, not 朱 shu ([Flag of Japan](https://en.wikipedia.org/wiki/Flag_of_Japan)). Hence shu for brand, beni for destructive.
- **Contrast (WCAG 2.x):**
  - `ink` on `paper`: 17.0:1 dark, 15.7:1 light. `inkSecondary`: 7.6:1 and 5.4:1.
  - `shu` as text: 5.07:1 dark, 5.01:1 light.
  - `kinText` on light paper: 4.54:1 (just passes). `kin` light: 2.2:1, decoration only.
  - `ruleStrong`: 3.74 / 3.39:1, passes 1.4.11 for visible rules. `rule`: 1.57 / 1.24:1, decorative only.
  - `paperRaised` vs `paper`: about 1.1:1 in both modes, so cards need a rule.
- **Failures designed around:**
  - Washi text on dark shu: 3.36:1. Text on any shu or beni fill is `paper` in both modes.
  - Light-mode gold can never be text.
  - Tertiary greys (#7A726B dark, #8A8178 light) fail 4.5:1; no third text token.
  - Under deuteranopia, light `shu` vs `kinText` is ΔE 0.4, contrast 1.01: identical ([Machado CVD simulation](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html)). State is never shu-vs-gold alone.
  - The old green/red budget scale already fails deuteranopia: contrast 1.24, ΔE76 20.7.
  - Current default categories collide with shu: Entertainment #FF3B30 is ΔE 13 from dark shu; Health #FF6B00, Finance #FF9500 and the Family list #FF9500 crowd the shu/gold band.
- **Proposed traditional category defaults** (new installs only, colordic hexes, each ≥ ΔE 59 from shu): 藤紫 #A59ACA, 若竹 #68BE8D, 萌黄 #AACF53, 縹 #2792C3, 青磁 #7EBEA5, 鴇 #F4B3C2, 菖蒲 #CC7EB1, 鼠 #949495. They are 1.7–2.6:1 on light paper (萌黄 1.78, 鴇 1.74), hence the proposed OKLCH clamp (light L ≤ 0.62, dark L ≥ 0.55). `charts.md` uses the same set, re-ordered, as the payment-method fallback palette.
- **Glass and colour:** Apple says to "refrain from adding color throughout Liquid Glass solely to evoke your brand" ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color), [mirror](https://glama.ai/mcp/servers/@tmaasen/apple-dev-mcp/blob/b82f0efe2115dc4539c83a2374a714a84aeb350a/content/universal/color.md), [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)).
- **Reference palette:** kanagawa.nvim is a tested red + black + gold "modern Japan" theme ([colors.lua](https://raw.githubusercontent.com/rebelot/kanagawa.nvim/master/lua/kanagawa/colors.lua)).

### Fragment Mono facts
- Wei Huang with URW Design Studio; a monospaced Nimbus Sans; SIL OFL 1.1 ([METADATA.pb](https://raw.githubusercontent.com/google/fonts/main/ofl/fragmentmono/METADATA.pb), [repo](https://github.com/weiweihuanghuang/fragment-mono)).
- Two styles only, Regular and Italic, weight 400 ([Fontsource](https://fontsource.org/fonts/fragment-mono), [Fontsource about](https://fontsource.org/fonts/fragment-mono/about), [Figma](https://www.figma.com/fonts/fragment-mono/)).
- Subsets latin, latin-ext, cyrillic-ext (GF Latin Plus). **No CJK.**
- Currency class in the source: $ ¢ £ ¥ € ₩ ₹ ₺ ₽ ₿ ₱ ₦. `ThemeFontTests` checks `$ € R £ ¥` at runtime.
- Metrics: cap height 699, x-height 524, ascender 729, descender −218 (per 1000). Advance 618/1000 em per glyph, measured from the bundled TTF (`price_display.md`); about 9pt per glyph at 15pt, about 38 characters across 375pt.
- OpenType: `zero`, `smcp`, `c2sc`, `case`, `frac`, `sups`, `sinf`, `ss01`–`ss07` (ss07 = serif 1). No `tnum` needed: every glyph is the same width.
- SwiftUI "doesn't synthesize bold or italic styling" ([Apple](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text)). Every `.bold()`/`.fontWeight()` on it is a no-op.
- Each target registers fonts in its own `UIAppFonts`. Kanji fall back to a sans unless set separately (Hiragino Mincho `HiraMinProN-W3/W6`, [font list](https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9)) or through a `cascadeList` ([sarunw](https://sarunw.com/posts/how-to-use-different-fonts-for-different-languages-in-ios-application/)).

### Japanese calendar conventions
- **Formats** ([Mynavi](https://osusume.mynavi.jp/articles/5589/), [Maruzen](https://www.maruzenjunkudo.co.jp/products/4517163855409), [NDL 暦](https://www.ndl.go.jp/koyomi/chapter3/index.html), [DreamNews](https://www.dreamnews.jp/index.php/press/0000280557)):
  - 月めくり (one month per wall sheet): the app's model.
  - 2–3ヶ月 sheets: previous/current/next month together.
  - 文字月表 (text-only corporate): the best-selling custom-printed type; bold numerals, 前後月 minis, 六曜. Closest to the reference photo.
  - 日めくり (daily tear-off) and 卓上 (desk).
- **Monthly-sheet anatomy:** month numeral is the largest element (about 3–5× a day numeral, from samples); year + era (`2026 / 令和8年`, [Hobonichi](https://www.1101.com/store/techo/en/2021/all_about/dayfree/about03.html)); 和風月名 and English month beside it; minis in the top corners or blank cells ([MUJI](https://www.muji.com/jp/ja/shop/045835/articles/muji-staff/1631841)); weekday row `日…土`, often with `SUN…SAT`; cell numeral top-left; memo space lower ([bungu.store MD](https://bungu.store/products/md-bi-fold-wall-calendar-2026-midori)).
- **Reference photo anatomy** (notesofnomads.com wall calendar, observed):
  - top-left mini previous month (`12`), top-right mini next month (`2`), Sundays/holidays red
  - header: era `平成30年` bold left, giant red `1` centre, letter-spaced `睦 月` right
  - full-width solid black weekday band, white kanji, thin white separators continuing into the grid
  - heavy black numerals; tiny 六曜/干支/九星 stacked top-right; holiday name (元日) small red under the numeral; 節気 (小寒) under the numeral; special-day label tiny top-left
  - dotted memo lines in the lower half of each cell; thin vertical rules, hairlines between weeks, white paper, no rounded corners
  - **Mapping decided in `calendar.md` §1:** minis become faint `‹ SEP` / `NOV ›` edge labels; 節気 moves to one header line; holiday names move to the day sheet and VoiceOver; memo lines become the expense slot that keeps every current expense element; 六曜/干支/九星 dropped in v1.
- **Week start:** no national rule. Sunday-first is the home norm; Monday-first grows in business ([FinancialField](https://financial-field.com/living/entry-377145)). Takahashi and Midori default to Monday. The app stays Sunday-first (hard-wired, matches `ja_JP`).
- **Colours:** Sundays and holidays red, Saturdays blue (Saturday was a half day; blue was the remaining ink, [Berlitz](https://www.berlitz.com/blog/days-of-the-week-japanese)). Counter-trend: Midori's MD 2027 dropped red ink ([bungu.store 2027](https://bungu.store/products/md-wall-calendar-with-pencil-2027-md-product)).
- **Neighbour days:** grey, blank, or split `23/30` cells. Split cells read poorly ([TalkPhotography](https://www.talkphotography.co.uk/threads/calendar-with-5-or-6-rows-which-do-you-think-is-best.686047/)). The app leaves them blank and fixes 6 rows. Sunday-first 2026: February needs 4 rows, May and August 6, the rest 5.
- **Holidays 2026** ([CAO](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html)): 16 national holidays + 2 other days off = 18, including 振替休日 5/6 and 国民の休日 9/22. **Test case:** 2026-10-12 (today) is a Monday and スポーツの日. Decision: today's numeral is `ink` inside the shu ensō; `祝` keeps the holiday visible. 2027 is derived from the rules and must be checked against CAO.
- **和風月名** ([NDL](https://www.ndl.go.jp/koyomi/chapter3/s8.html), [bestcalendar](https://bestcalendar.jp/guides/koyomi/wafu-getsumei)): 睦月 如月 弥生 卯月 皐月 水無月 文月 葉月 長月 神無月 霜月 師走. Old lunar names now on Gregorian months, so their seasons run 1–2 months off.
- **二十四節気 2026, JST** ([NAOJ 暦要項](https://eco.mtk.nao.ac.jp/koyomi/yoko/2026/rekiyou262.html)): exactly two per month (e.g. 寒露 10/8, 霜降 10/23), so they fit one header line.
- **Era:** `Calendar(identifier: .japanese)` + `ja_JP` + `Gy年` → `令和8年` ([gihyo](https://gihyo.jp/dev/serial/01/swift-introduction/0050)).
- **六曜:** `(旧暦 month + day) % 6` → 大安, 赤口, 先勝, 友引, 先負, 仏滅 ([bestcalendar 六曜](https://bestcalendar.jp/guides/kichijitsu/rokuyo)). NAOJ does not publish it; the lunar rules break down in 2033 ([NAOJ wiki](https://eco.mtk.nao.ac.jp/koyomi/wiki/C2C0B1A2C2C0CDDBCEF12F2033C7AFCCE4C2EA.html)). Swift needs `.chinese` ([NSChineseCalendar](https://developer.apple.com/documentation/foundation/nschinesecalendar)), computed for UTC+8.

### Notebooks and paper
- **Kokuyo Campus:** rulings A 7mm, B 6mm, C 5mm, U 8mm, UL 10mm; a counting mark every 5 lines ([Campus Basic](https://www.kokuyo.com/en/stationery/series/campus/campus-notebook/basic)). Dot-ruled paper puts dots on the rule as column guides ([dot ruled](https://www.kokuyo.com/en/stationery/category/notebook-paper/notebook/10591), [getnavi](https://getnavi.jp/variety/500620/2/)). NO-201U has a thicker third line for title or date ([NO-201U](https://kokuyostore.com/en_FR/campus-notebook-notebook-a4-brown-wide-horizontal-ruled-40-sheets/NO-201U.html)).
- **Hobonichi:** A6, 3.7mm daily grid, 3.45mm monthly grid, a colour per month, moon phases ([1101.com](https://www.1101.com/store/techo/en/2027/pc/detail_cover/ob27_jan_en/)).
- **Midori MD:** cream paper, 5mm grid, tick dots every 5 and 10 squares ([Mountain of Ink](https://mountainofink.com/blog/midori-md-notebook), [simplepaper](https://simplepaper.co/products/md-notebook-a6-grid)).
- **Genkō yōshi:** 20×20 cells with a 魚尾 fold mark ([tkgje](https://www.tkgje.jp/entries/15500/15790_genkouyoushi.html), [All About](https://news.allabout.co.jp/articles/o/60480/?page=2), [kotobank](https://kotobank.jp/word/原稿用紙), [Kokuyo manuscript](https://www.kokuyo.com/en/stationery/category/notebook-paper/manuscript/3727)).
- **Points:** at @3x, 1mm ≈ 6.04pt; 7mm ≈ 42pt, 8mm ≈ 48pt. The list uses a 44pt pitch (between A and U, and the HIG minimum), a margin rule at x = 56pt, 1.5pt column dots, and a 1pt date rule.
- **Washi:** kōzo fibres over a mottled base, not uniform noise ([JAANUS washi](https://projects.mcah.columbia.edu/jaanus/node/294)). Candidate source photo: [Pakutaso](https://www.pakutaso.com/en/20200300064post-23800.html) (licence unchecked). Use a static tile ([Fatbobman](https://fatbobman.com/en/posts/how-to-tile-images-in-swiftui/), [ResizingMode](https://developer.apple.com/documentation/swiftui/image/resizingmode.md)), not a shader ([Cindori](https://cindori.com/developer/swiftui-metal-shaders-effects)).

### Torii geometry
- Parts ([JAANUS myōjin torii](https://projects.mcah.columbia.edu/jaanus/node/2276), [JAANUS kasagi](https://aisf.or.jp/~jaanus/deta/k/kasagi.htm)): kasagi (top lintel), shimaki (secondary lintel), nuki (tie beam projecting about 1/5 past the pillars), gakuzuka (central strut/tablet), hashira (pillars, leaning inward), kamebara (base stones).
- Styles ([JAANUS torii](https://projects.mcah.columbia.edu/jaanus/node/566)): Shinmei (straight), Myōjin (curved ends), Ise ("barely perceptible" curve), Inari (strong curve, thick ends).
- Proportions: pillar diameter ≈ 1/10 of the span; the opening is close to square; the nuki sits one diameter below the lintels.
- **UI translation:** 2pt kasagi with 3pt end lift (≈0.8% of 390pt, an Ise-style curve) + 3pt gap + 1pt shimaki; nuki overhang 3pt; shu hashira 3pt wide; card radius 2–4pt. The 3pt lift is a guess (see open points).

### Brush, ensō and hanko
- **Ensō:** one or two unrevised strokes; the open form means movement and incompleteness ([Wikipedia Ensō](https://en.wikipedia.org/wiki/Ens%C5%8D), [Wikipedia Enso](https://www.wikipedia.com/wiki/Enso), [concepts.dsebastien](https://concepts.dsebastien.net/concept/enso/)). No canonical direction.
- **Stroke anatomy** ([calligraphy terms](https://selftaughtjapanese.com/2020/08/25/japanese-vocabulary-list-calligraphy-terms)): 起筆 heavy entry, 送筆 steady travel, はらい lifting taper, かすれ dry-brush streaks in the last third.
- **Spec (owned by `calendar.md` §6):** start 150° ± 8°, 320° sweep, 40° gap at lower-left; radius drift ±4%, tail +6%; `w(t) = wMax·(0.55 + 0.45·(1−t)^1.5)`, entry 1.15·wMax, taper to 0.15·wMax from t = 0.85; wMax 3.5pt at 40pt (`maxWidth` 0.0875); かすれ from t = 0.65; seed `yyyyMMdd`; draw-on 0.55s `.timingCurve(0.2, 0.7, 0.3, 1)`.
- **Variable width needs a filled outline** ([Swift Forums](https://forums.swift.org/t/drawing-strokes-with-a-different-width-at-each-point-of-the-lines-curves/40068)); draw it on with a trimmed-circle **mask**, never by trimming the outline ([HWS](https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-part-of-a-solid-shape-using-trim)). Cheaper alternative: 3–5 hand-drawn SVG assets with the same mask.
- **Brush text:** per-glyph `TextRenderer` reveal ([WWDC24 10151](https://developer.apple.com/videos/play/wwdc2024/10151/)); 3-glyph overlap, opacity + blur + 2pt drift, 0.7s. Fallback is a mask wipe.
- **Benchmark:** Zen Brush 3 (3D brush, nijimi, bokashi, 30 traditional colours, washi templates) ([App Store](https://apps.apple.com/us/app/-/id1531841731)).
- **Hanko:** a vermilion square seal balances a composition ([Takase](https://www.takase.com/custom-seal-design/), [UMMA](https://umma.umich.edu/objects/calligraphy-with-seal-2022-2-7)). Spec (owned by `charts.md`): square, 1.5pt shu border, −3°, 0.9 opacity, `.multiply` in light only, at most one per screen.
- **Kintsugi gold:** no authoritative hex; hairlines and accents only.

### Liquid Glass and HIG constraints
- APIs (iOS 26): `glassEffect(_:in:)`, `Glass.regular/.clear/.identity`, `.tint`, `.interactive`, `GlassEffectContainer`, `.buttonStyle(.glass/.glassProminent)`, `ToolbarSpacer`, `.sharedBackgroundVisibility(.hidden)`, `.badge` on toolbar items, `.scrollEdgeEffectStyle` ([Applying Liquid Glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views), [Glass](https://developer.apple.com/documentation/swiftui/glass), [WWDC25-323](https://developer.apple.com/videos/play/wwdc2025/323/)).
- No glass in the content layer; use it sparingly ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)). Colour on glass only for the primary action or status; toolbar symbols monochrome ([HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)).
- Toolbars: aim for at most 3 groups; one primary action, trailing, tinted; never mix text and symbol buttons in one group; a crowded bar is a cue to remove things ([HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars), [WWDC25-356](https://developer.apple.com/videos/play/wwdc2025/356/)). Hit targets ≥ 44×44pt ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)).
- On flat washi, glass has little to refract and reads as a frosted chip; it only "liquifies" when content scrolls under it.
- iOS 26.1 added a user Clear/Tinted glass setting; test both ([Six Colors](https://sixcolors.com/post/2025/11/soaping-up-liquid-glass-less-transparency-more-contrast/)).
- System bars stay capsules; custom glass can be `.rect(cornerRadius: 4)`. A beta report saw `.interactive()` rect glass snap to a capsule on press.
- `layerEffect` renders materials black (project memory). Shaders never go near glass.
- Large-title + title toolbar items have reported bugs ([forum 811877](https://developer.apple.com/forums/thread/811877), [largeTitle](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/largetitle.md), [subtitle](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/subtitle.md)).

### Apple Calendar declutter findings
- **iOS 26 Calendar month view** ([view events](https://support.apple.com/guide/iphone/change-how-you-view-events-iphfd1054569/26.0/ios/26.0), [create events](https://support.apple.com/guide/iphone/create-and-edit-events-iph3d110f84/26.0/ios/26.0), [multiple calendars](https://support.apple.com/guide/iphone/use-multiple-calendars-iph3d1110d4/26.0/ios/26.0)):
  - top-leading `‹ 2026` back to the Year view (not confirmed on a device)
  - month title in the content, not the bar
  - top-trailing view menu (Compact / Stacked / Details / List), Search, Add
  - bottom bar: Today (text, always visible, [Zapier](https://zapier.com/blog/best-iphone-calendar-apps/)), Calendars (centre, checklist sheet), Inbox (right)
- **Apple's mistake:** iOS 26 removed Show All / Hide All from the Calendars sheet and users complained ([Apple Community](https://discussions.apple.com/thread/256200863)). Satoru keeps a one-tap Show All.
- **Third-party precedent:** Fantastical moved controls into a glass bottom toolbar ([Apple design gallery](https://developer.apple.com/design/new-design-gallery-2026)).
- **Current Home problems:** a mixed filter + view-mode pill top-left with no active state; an unlabeled 18pt stats ring bottom-left that duplicates the total tap; an Add ↔ Today swap that hides Add off-month; a duplicate month selector top-centre; 8 controls.
- **Decision (layout A, `home_screen_ux.md`):** `2026` top-leading → Year grid sheet; month in the Koyomi header; top-trailing view menu (Calendar/List, Stats, Settings) + Search; bottom bar Today · Filter (badge) · shu `+`. Stats opens from the total. 7 controls, 0 mixed groups. Alternatives B (Mail/Fantastical, keeps the top-centre title, `toolbarTitleMenu` [docs](https://developer.apple.com/documentation/swiftui/toolbartitlemenu), `navigationSubtitle` [docs](https://developer.apple.com/documentation/swiftui/view/navigationsubtitle(_:).md)) and C (minimal, `…` menu) are documented there.

## Budget color: options
- **Problem:** shu is now the brand red; a green → red budget scale makes every brand red read as a warning, and green/red already fails deuteranopia (contrast 1.24). Red is also auspicious in Japan and means "rising" on stock screens ([RetireJapan](https://retirejapan.com/forum/viewtopic.php?p=12877)).
- **A. Ink density 黒字/赤字 (recommended, implemented by `charts.md`):** under 75% `ink`; 75–99% `ink` + `kinText` brush underline + "LEFT"; ≥ 100% `shu` + `HankoStamp` "赤字" + "OVER". Uses the accounting idiom (black ink = surplus, red ink = deficit, [JGJE 赤字](https://www.tkgje.jp/entries/04500/04712_akaji.html)). Shape and word carry the state ([WCAG 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color)).
- **B. Gold → vermilion ramp:** fails CVD (light shu vs kinText is identical under deuteranopia) and needs gold fields.
- **C. Keep semantic green/red:** zero cost, but fails CVD and clashes with the palette.
- Full comparison, the `BudgetColor.swift` rewrite and the `HankoStamp` spec: `charts.md` → "Budget status: options". Rendering on the Home total: `price_display.md` (`BudgetMark`).

## Future points / dig deeper
Every "Open points / dig deeper" bullet from the 7 docs and every open question in the research notes, deduplicated. "Docs" names the doc(s) the result changes.

### Brand and palette
| Pri | Point: what to research, and why | Docs |
|---|---|---|
| P1 | **Saturday `ai` vs monochrome.** Run a 70/25/5 pixel histogram of the month grid; compare muted 藍, dark gold #8B6B12, or no Saturday colour (the Midori no-red trend). Blue sits outside red/black/gold. | calendar, list_view, general_app_ui |
| P1 | **Hanko wording and red perception.** 赤字 alone, OVER alone, or both; how Japanese users read a red total when red means "rising" on stock screens. Decides `HankoStamp`'s default `text`. | charts, price_display, general_app_ui |
| P1 | **Brand mark consistency.** `BrandLogoStyle.green` (`BrandLogo.swift:87-91`) is still hardcoded green, so `BrandLogo` renders half shu, half green, both as gradients. Decide the torii/hanko mark in shu and fix it. | general_app_ui |
| P2 | **Default category palette for new installs** (藤紫, 若竹, 萌黄, 縹, 青磁, 鴇, 菖蒲, 鼠) and whether existing stored defaults are remapped. The Family list colour (柿 #ED6D3D is ΔE 15 from shu) needs another choice, e.g. 利休 #8F8667. | general_app_ui, charts |
| P2 | **OKLCH lightness clamp for user colours** (light L ≤ 0.62, dark L ≥ 0.55), applied in one function to icons, dots, dial segments and the fallback palette. 5 of 8 pigments are under 3:1 on light paper. Decide once for forms, lists and charts. | general_app_ui, forms, charts, list_view |
| P2 | **70/25/5 measurement.** A pixel-histogram script over the verification screenshots, so the ratio is measured, not eyeballed. | general_app_ui, calendar |
| P2 | **Hashira density.** Settings shows up to 7 shu ticks and the add form 4. Fallback: `ruleStrong` ticks (needs a colour parameter on `Hashira`) with shu only on the first section. | general_app_ui, forms |
| P2 | **Shu toggles vs the one-filled-shu rule.** Settings shows up to 4 shu toggle tracks (`SettingsView.swift:206,276,356,382` in the working tree); keep the AccentColor exemption or use `.tint(Color.ink)`. | general_app_ui |
| P2 | **Card and hairline edges in light mode.** `rule` is 1.24:1 on `paper`; check cards and list rules on device with Increase Contrast; fall back to `ruleStrong` (hairline) or `ruleStrong.opacity(0.4)`. | general_app_ui, list_view |
| P2 | **OCR confidence colours** (`ReceiptScanSheet.swift:259-263`, hue-only green/orange/red). Choose ink + glyph or `kinText`/`beni` + a word; decide whether forms v2 or a receipts doc owns `ReceiptScanSheet`. | general_app_ui, forms |
| P2 | **`LogoCircle` coloured shadow on the form hero** (`LogoCircle.swift:20-25`, radius `size * 0.22`). Drop it (orphans the SHADOW row at `LogoSheet.swift:234`) or keep. | forms, list_view |
| P3 | **Brand red choice.** Measure real torii photos (Fushimi Inari, Itsukushima); confirm shu over beni. | general_app_ui |
| P3 | **Official NIPPON COLORS values** (fetch returned no hexes; values differ from Wikipedia). | general_app_ui |
| P3 | **Payment-method colours.** Store a colour per method (optional `AppSettings` field, lenient decoding) instead of rank-ordered fallback colours that change with ranking. | charts |
| P3 | **Kasagi curve proportion.** Search 笠木 反り 寸法 and the 1608 *Shōmei* for real sori ratios; the 3pt lift is a guess. | general_app_ui |
| P3 | **Rename `GlassSection` → `PaperSection`** once all feature docs land. | general_app_ui |
| P3 | **Settings swatch shape.** Colour pickers stay circles while content tags are squares; confirm with the user. | forms |
| P3 | **Glass over shu content.** How glass refracts a red ensō or stamp beneath it. | general_app_ui |
| P3 | **Washi texture.** A 512px seamless tile, `.multiply` ≤ 5% in light, omitted in dark. Check the [Pakutaso](https://www.pakutaso.com/en/20200300064post-23800.html) licence or scan our own; test under `glassEffect` with Increase Contrast and Reduce Transparency; confirm contrast numbers and one-pixel list rules still read on it. | general_app_ui, list_view |
| P3 | **Per-month colour** (Hobonichi): does it fit a strict red/black/gold palette, or only as a tint on a small marker? | general_app_ui, calendar |
| P3 | **Shide (紙垂) zigzag** as a divider or loading motif. Unexplored; may read as kitsch. | general_app_ui |

### Typography
| Pri | Point | Docs |
|---|---|---|
| P1 | **Currency glyphs on device.** Run `CTFontGetGlyphsForCharacters` for `¥ € £ ₩ ₹ ₽ ₿` and `R$`, check "CA$"-style outputs and `CurrencyMenu` labels; a fallback glyph breaks mono alignment. | general_app_ui, forms, price_display |
| P1 | **Navigation titles and toolbar text on iOS 26 glass bars.** Does the legacy `titleTextAttributes` proxy apply; do custom `Text` labels (`2026`, `Today`) keep Fragment Mono; do 17pt inline titles ("Popular Subscriptions") fit. | general_app_ui, home_screen_ux |
| P1 | **Hero total width tuning.** Re-tune `44...84` and `totalInset` 20 from screenshots at the smallest width with the Koyomi header in place. | price_display, home_screen_ux |
| P2 | **Bold escape hatch.** Use SF Mono semibold for emphasis in normal mode (price, row names)? Should the fitted hero follow Bold Text (it uses fixed-size Fragment Mono)? Prototype one row both ways. | general_app_ui, price_display |
| P2 | **Widget fonts in accented, vibrant, Lock Screen and Control Center contexts**, including chart `AxisValueLabel` fonts and `BarMark(width: .ratio)` in WidgetKit. | general_app_ui, charts |
| P3 | **OpenType features:** slashed zero (`zero`), serif one (`ss07`) for a ledger look. | general_app_ui |
| P3 | **Mixed Latin + kanji in one string:** a `cascadeList` descriptor with `UIFontMetrics` rescaling. | general_app_ui |
| P3 | **Compile checks:** `TextRenderer` isolation (`nonisolated` if flagged) and whether the iOS 26 SDK warns on `Text + Text`. | price_display |
| P3 | **Audience:** English UI with kanji accents vs a full ja localisation; decides how much 和風 text appears. | general_app_ui, calendar |

### Calendar
| Pri | Point | Docs |
|---|---|---|
| P1 | **Forced dark environment on the weekday band.** Verify on device that `.environment(\.colorScheme, .dark)` resolves the `UIColor`-backed tokens dark in light mode; fallback is hardcoded dark hexes in `WeekdayBand`. | calendar |
| P2 | **Cell density.** Are 20pt logos legible for brand assets, or should `.koyomi` show count + first logo? | calendar |
| P2 | **Extend the month window** (`CalendarService.swift:20`, −1…+12) to whole years, so no Year-grid cell is disabled; measure `CalendarCache.monthData` cost and widget assumptions. | home_screen_ux, calendar |
| P3 | **Real mini months** in blank first/last-row cells when ≥ 3 are blank (文字月表 style). Placement evidence is weak: check photos of Todan, 新日本カレンダー, Kokuyo, Delfonics sheets. | calendar |
| P3 | **Persistent selection state** (iPad, multi-select): a 1pt `kin` underline, never a second circle. | calendar |
| P3 | **Monday-first option:** a `weekStart` setting through `CalendarService.daysGrid`, `ExpenseService.weekInterval`, `WidgetData` and the weekday tables (or follow `Calendar.current.firstWeekday`). | calendar, list_view |

### Brush and motion
| Pri | Point | Docs |
|---|---|---|
| P1 | **`keyframeAnimator` first frame and the Transition fallback.** Confirm no fully inked flash on the trigger frame, and that the fallback removes the old value without overlap. | price_display |
| P1 | **Reveal performance.** Per-glyph blur cost on the oldest device during fast paging; decides renderer vs mask wipe. | price_display |
| P2 | **Ensō authenticity.** Tune `w(t)`, drift and かすれ against real brush scans (e.g. Kanjuro Shibata XX); procedural vs 3–5 SVGs; who draws or licenses them. | calendar |
| P2 | **Path boolean-op cost.** Profile `EnsoShape.path(in:)` (union/subtract) in the paging `TabView` and the Year grid on an older device. | calendar |
| P2 | **Calm-tier underline:** `kin`, ink or none; in dark mode `kin` #D4A72C and `kinText` #E6B422 barely differ. | price_display |
| P2 | **`destinationOut` mon-coin hole.** Verify the knock-out in stacked piles and its cost with 10 coins × N categories while scrolling. | charts |
| P3 | **Genkō digit cells** behind the hero total, one faint `rule` cell per 0.618 em advance ([tkgje](https://www.tkgje.jp/entries/15500/15790_genkouyoushi.html)). Check legibility at XXL and whether it competes with the Koyomi header; rejected for rows. | price_display, list_view |
| P3 | **Kasure underline and hanko texture.** A grayscale bristle-noise mask (`.luminanceToAlpha()`) or scanned assets; needs a licence decision. | price_display, charts |
| P3 | **Coin bounce helpers.** Delete `CoinDrop.bounceHeight/bounceSpeed/bounceRise` and their two tests once the no-bounce landing is accepted. | charts |
| P3 | **Ensō behind the Stats dial** (or trimmed to spent ÷ budget); check cost while the inertia timer writes 60×/s. | charts |

### Glass and accessibility
| Pri | Point | Docs |
|---|---|---|
| P1 | **Toolbar badge colour.** The system `.badge` may draw a red circle next to the shu `+` (a second red fill). Verify `Button.badge` vs a `ToolbarItem`-level badge; fallback is a filled filter symbol. | home_screen_ux |
| P1 | **`.glassProminent` tint in toolbars.** Does it follow `.tint(Color.shu)` and keep a `paper` label, or is `Button(role: .confirm)` the supported route? | home_screen_ux, forms |
| P1 | **CVD on device.** The 赤字 stamp, `kinText` underline and shu current bar at 11–13pt under deuteranopia/protanopia filters. | general_app_ui, charts, price_display |
| P2 | **Square custom glass next to capsule system glass**, and `.interactive()` rect glass snapping to a capsule on press. | general_app_ui, forms |
| P2 | **Reduce Transparency / Increase Contrast** on bars over paper; keep ≥ 3:1 for the `+` glyph. | home_screen_ux |
| P2 | **Summary sheet background.** `.presentationBackground(Color.paper)` hides the iOS 26 sheet glass; compare with the system sheet background. | forms |
| P2 | **`ExpensesInDay` rows at AX sizes.** Measure real row heights (`PreferenceKey`) instead of `count × pitch` if clipping shows. | list_view |
| P3 | **Snap rows to the 44pt grid at large text** so the ruling never breaks. | list_view |
| P3 | **Notebook-ruled Notes field** behind the `TextEditor`, matching line metrics under Dynamic Type. | forms |

### Data (holidays, 六曜)
| Pri | Point | Docs |
|---|---|---|
| P1 | **Verify the 2027 holiday table** (equinoxes 3/21, 9/23 are predictions) against CAO before shipping, and plan updates past 2027: bundle CAO `syukujitsu.csv` or extend the static table yearly. | calendar, list_view |
| P1 | **二十四節気 2027.** Add the NAOJ 暦要項 2027 table; until then the header line is empty for Jan–Oct 2027. | calendar |
| P1 | **Who sees JP holidays:** everyone, only `Locale.current.region == .japan`, or behind a setting. The default currency is CAD; a Canadian user may read red weekdays as errors. | calendar, list_view |
| P2 | **JPY formatting.** `formatNumber` prints `¥1,200.00`; research a per-currency `fractionLength` in `MoneyFormatter` and its effect on widgets and the keypad's cents mode. | price_display |
| P3 | **六曜 (v2):** `(旧暦 month + day) % 6` via `.chinese`; check new moons near JST midnight against an almanac (UTC+8 offset); rules break in 2033. A wrong value is worse than none. | calendar |

### Widgets and icon
| Pri | Point | Docs |
|---|---|---|
| P1 | **App icon.** `Resources/AppIcon.icon` is still green/purple (`logo-green.svg`/`logo-purple.svg`). Research a torii or hanko mark in shu on lacquer, and its tinted/clear icon modes. Decide whether the crow mascot stays. | general_app_ui |
| P3 | **Widget weekday/holiday colours and a week-widget ensō** (`WidgetViews.swift:488-490`). Left out of v1 to keep widget changes small. | calendar |

### Onboarding (ripple heroes left for later)
| Pri | Point | Docs |
|---|---|---|
| P2 | **Onboarding restyle.** Heroes keep the ripple (`rippleCard`, `rippleOnTap`, `liquidRipple`) for now; plan a pass to paper + brush motion, then delete the remaining `RippleEffect.swift`/`Ripple.metal`. Never add glass inside a hero (black render). | general_app_ui |
| P3 | **Calendar hero height.** 300pt crowds a 6-row Koyomi grid; use 340–370pt or a dedicated Koyomi hero. | calendar |
| P3 | **Budget hero** (`OnboardingBudgetHero`): only its colour moves to `progressColor` in v1; the rest waits for the onboarding pass. Verify mon coins inside `.liquidRipple` if they ever appear there. | charts |

### UX validation
| Pri | Point | Docs |
|---|---|---|
| P1 | **Check iOS 26 Calendar on a device:** text-only year button, whether search/view menu/`+` share one capsule, red current-month title. | home_screen_ux |
| P1 | **iOS 27 is shipping.** Review Calendar's iOS 27 layout and new toolbar APIs before locking layout A. | home_screen_ux |
| P1 | **Price tap.** The brief says "all interactions … about the Price should be removed". v1 removes every effect (ripple, bounce, roll, glow) but keeps the plain tap → Stats, which layout A uses as the Stats entry. Confirm, or drop the tap and rely on the view menu. | price_display, home_screen_ux |
| P1 | **Row icon colour source in forms.** v1: `inkSecondary`, data colours only on Category and List. Alternative: every row icon takes the logo colour (needs a contrast clamp). Ask the user; "colour only on the icon" can mean either. | forms |
| P2 | **Today semantics.** Apple keeps Today always enabled; should Satoru's stay enabled, scroll list mode to today's header and replay the ensō? | home_screen_ux |
| P2 | **Active-filter visibility.** Is a count badge enough, or add a one-line filter summary under the Koyomi header? | home_screen_ux |
| P2 | **List scrolls under the bottom bar.** Drop `HomeListView`'s `.padding(.bottom, 8)` so glass has content to refract; keep the last row reachable. | home_screen_ux, list_view |
| P2 | **List-mode density.** A compact Koyomi header in list mode; move coin piles into Stats? Header + total + coins leave about 6 rows on an SE. | home_screen_ux |
| P2 | **Hub routing UX.** Sheet-over-sheet vs letting `SimplifiedAddExpenseView` skip its `NavigationStack` so it can be pushed. | forms |
| P2 | **Expense type dropped from the row meta.** Bring back "Subscription/Expense/Installment" as a 1-glyph mark, or keep it only in `ExpenseSummarySheet`. | list_view |
| P3 | **Year-root `NavigationStack`** (future): prototype the paged `TabView` against the swipe-from-edge Back gesture. | home_screen_ux |
| P3 | **Persist `viewType`** with `@AppStorage("home_view_type")` (not `AppSettings`). | home_screen_ux |
| P3 | **Year grid content:** mini month thumbnails or a budget tick; readability at AX sizes. | home_screen_ux |
| P3 | **Search as system search** (`.searchable` + `.searchToolbarBehavior(.minimize)`). | home_screen_ux |
| P3 | **`+` long-press menu** (`Menu(primaryAction:)`) for voice (`FF_QUICK_ADD`) and receipt scan (`FF_SMART_RECEIPTS`). | home_screen_ux |
| P3 | **Trend reference in yearly scale:** average year vs monthly budget × 12. | charts |
| P3 | **Restyle `CoinProgress` instead of deleting** only if a product use returns. | charts |
| P3 | **Notebook extras:** day subtotal on headers (kakeibo), pinned day headers, ruled lines to the page bottom, counting ticks (keep or drop), bilingual stamps 有効/停止 (native-speaker check). | list_view |
| P3 | **Kokuyo "No. / Date" header:** confirm from physical Japanese-market stock whether Campus pages print it, before using it as a list-header motif. | list_view |
| P3 | **Swap forms' inline category dot for `CategoryMark`** in `ExpenseSummarySheet` once `list_view.md` lands (same render, one source). | forms, list_view |

### Resolved during planning (kept for the record)
- **The user's reference screenshot** was unavailable to the calendar research; the photo was later described (Research results → reference photo anatomy) and mapped in `calendar.md` §1.
- **Today on a red date:** `ink` numeral inside the shu ensō, holiday kept by `祝` (`calendar.md`, `list_view.md`).
- **Week start:** Sunday-first kept (matches `ja_JP`); Monday-first is a P3 option above.
- **Selected vs today:** no persistent selection in v1; a `kin` underline if ever needed.
- **One weight:** hierarchy from size, case, tracking and colour; Bold Text → SF Mono semibold.
- **EnsoShape `maxWidth`:** 0.0875 (3.5pt at 40pt), owned by `calendar.md`.
- **Display tracking:** −0.5 / −0.3, as implemented (the plan's "~0" is superseded).
- **Dark-mode red tuning:** the tech research's #F0524A drifted to coral; the canonical dark `shu` is #E84A33 (5.07:1 on lacquer).
- **`CoinProgress`:** deleted (charts.md step 14, run at the end of price_display.md step 9); its view model and tests stay.

## Variations to explore after v1
- **Calendar style variations:** the other `CalendarStyle` cases already survive as variations (rounded, contrast, bigger, straight, compact). Try a denser 文字月表 variant, a 2–3-month sheet (previous/next minis in blank cells), a 日めくり day view, and the dark-mode shu weekday band that v1 rejected.
- **Washi texture:** a 512px seamless tile, `.multiply` ≤ 5% in light, omitted in dark; check rules and glass legibility on top of it.
- **Glass cards:** an opt-in style that puts content cards back on glass over a textured ground, to test whether more refraction reads better than flat paper.
- **Monday-first** week start and a locale-following default.
- **六曜** in the cell annotation slot, plus 干支/九星 in day detail.
- **Kanji-only mode:** weekday kanji without English, 和風月名 as the main month label, or a full ja localisation.
- **Per-month colour** (Hobonichi): a per-month tint on the Koyomi numeral or a 魚尾/gakuzuka marker only.
- **Mon coins:** 寛永通宝-style face inscription, or coins as the Stats dial's marker.
- **Monochrome Midori mode:** no Saturday blue, no red ink except the 赤字 stamp.
- **Genkō cells** behind the hero digits; **kintsugi gold** borders for reactivated subscriptions; **shide** (紙垂) zigzag as a divider or loading motif (risk: kitsch).
- **Kasagi strength:** an Inari-style stronger curve on the Koyomi header only.
- **Home layouts B and C** and the Year-root navigation from `home_screen_ux.md`.
- **Hand-drawn ensō and hanko assets** replacing the procedural shapes.

## Sources
Apple and platform
- [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [HIG Color (mirror)](https://glama.ai/mcp/servers/@tmaasen/apple-dev-mcp/blob/b82f0efe2115dc4539c83a2374a714a84aeb350a/content/universal/color.md)
- [HIG Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [Glass](https://developer.apple.com/documentation/swiftui/glass)
- [Applying custom fonts to text](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text)
- [Image.ResizingMode](https://developer.apple.com/documentation/swiftui/image/resizingmode.md)
- [toolbarTitleMenu](https://developer.apple.com/documentation/swiftui/toolbartitlemenu)
- [navigationSubtitle](https://developer.apple.com/documentation/swiftui/view/navigationsubtitle(_:).md)
- [ToolbarItemPlacement.largeTitle](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/largetitle.md)
- [ToolbarItemPlacement.subtitle](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/subtitle.md)
- [Developer forum 811877](https://developer.apple.com/forums/thread/811877)
- [SectorMark](https://developer.apple.com/documentation/charts/sectormark)
- [NSChineseCalendar](https://developer.apple.com/documentation/foundation/nschinesecalendar)
- [WWDC24 10151](https://developer.apple.com/videos/play/wwdc2024/10151/)
- [WWDC25-323](https://developer.apple.com/videos/play/wwdc2025/323/)
- [WWDC25-356](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Apple design gallery 2026](https://developer.apple.com/design/new-design-gallery-2026)
- [Change how you view events (iOS 26)](https://support.apple.com/guide/iphone/change-how-you-view-events-iphfd1054569/26.0/ios/26.0)
- [Create and edit events (iOS 26)](https://support.apple.com/guide/iphone/create-and-edit-events-iph3d110f84/26.0/ios/26.0)
- [Set up multiple calendars (iOS 26)](https://support.apple.com/guide/iphone/use-multiple-calendars-iph3d1110d4/26.0/ios/26.0)
- [Apple Community: Show All removed](https://discussions.apple.com/thread/256200863)
- [Zapier: best iPhone calendar apps](https://zapier.com/blog/best-iphone-calendar-apps/)
- [Six Colors: Liquid Glass settings](https://sixcolors.com/post/2025/11/soaping-up-liquid-glass-less-transparency-more-contrast/)

SwiftUI techniques
- [Swift Forums: variable-width strokes](https://forums.swift.org/t/drawing-strokes-with-a-different-width-at-each-point-of-the-lines-curves/40068)
- [Hacking with Swift: trim](https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-part-of-a-solid-shape-using-trim)
- [Fatbobman: tiling images](https://fatbobman.com/en/posts/how-to-tile-images-in-swiftui/)
- [Cindori: Metal shaders](https://cindori.com/developer/swiftui-metal-shaders-effects)
- [sarunw: per-language fonts](https://sarunw.com/posts/how-to-use-different-fonts-for-different-languages-in-ios-application/)
- [iOS font list gist](https://gist.github.com/tadija/cb4ec0cbf0a89886d488d1d8b595d0e9)
- [gihyo: Japanese era format](https://gihyo.jp/dev/serial/01/swift-introduction/0050)

Fragment Mono
- [Fragment Mono repo](https://github.com/weiweihuanghuang/fragment-mono)
- [google/fonts METADATA.pb](https://raw.githubusercontent.com/google/fonts/main/ofl/fragmentmono/METADATA.pb)
- [Fontsource](https://fontsource.org/fonts/fragment-mono)
- [Fontsource about](https://fontsource.org/fonts/fragment-mono/about)
- [Figma fonts](https://www.figma.com/fonts/fragment-mono/)

Colour and accessibility
- [Traditional colors of Japan (Wikipedia)](https://en.wikipedia.org/wiki/Traditional_colors_of_Japan)
- [和色大辞典 colordic](https://www.colordic.org/w)
- [NIPPON COLORS](https://nipponcolors.com/)
- [kanagawa.nvim colors.lua](https://raw.githubusercontent.com/rebelot/kanagawa.nvim/master/lua/kanagawa/colors.lua)
- [WCAG 2.2 1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color)
- [Machado et al. CVD simulation](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html)
- [Flag of Japan (Wikipedia)](https://en.wikipedia.org/wiki/Flag_of_Japan)
- [Japaholic: why torii are red](https://en.japaholic.com/why-is-a-torii-red/)
- [Torii (Wikipedia)](https://en.wikipedia.org/wiki/Torii)
- [JAANUS urushi-nuri](https://projects.mcah.columbia.edu/jaanus/node/360)
- [Shibui: lacquer ware](https://shibuiswords.com/Lacquer-ware.htm)
- [JGJE 赤字](https://www.tkgje.jp/entries/04500/04712_akaji.html)
- [JGJE 朱肉](https://www.tkgje.jp/entries/06000/06192_shuniku.html)
- [RetireJapan forum](https://retirejapan.com/forum/viewtopic.php?p=12877)

Calendars
- [Mynavi](https://osusume.mynavi.jp/articles/5589/)
- [Maruzen](https://www.maruzenjunkudo.co.jp/products/4517163855409)
- [NDL 暦](https://www.ndl.go.jp/koyomi/chapter3/index.html)
- [NDL 和風月名](https://www.ndl.go.jp/koyomi/chapter3/s8.html)
- [DreamNews 文字月表](https://www.dreamnews.jp/index.php/press/0000280557)
- [Hobonichi day-free](https://www.1101.com/store/techo/en/2021/all_about/dayfree/about03.html)
- [MUJI calendars](https://www.muji.com/jp/ja/shop/045835/articles/muji-staff/1631841)
- [bungu.store MD bi-fold 2026](https://bungu.store/products/md-bi-fold-wall-calendar-2026-midori)
- [bungu.store MD 2027](https://bungu.store/products/md-wall-calendar-with-pencil-2027-md-product)
- [bestcalendar 和風月名](https://bestcalendar.jp/guides/koyomi/wafu-getsumei)
- [bestcalendar 六曜](https://bestcalendar.jp/guides/kichijitsu/rokuyo)
- [FinancialField week start](https://financial-field.com/living/entry-377145)
- [Berlitz days of the week](https://www.berlitz.com/blog/days-of-the-week-japanese)
- [TalkPhotography 5 vs 6 rows](https://www.talkphotography.co.uk/threads/calendar-with-5-or-6-rows-which-do-you-think-is-best.686047/)
- [CAO national holidays](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html)
- [NAOJ 暦要項 2026](https://eco.mtk.nao.ac.jp/koyomi/yoko/2026/rekiyou262.html)
- [NAOJ 2033 problem](https://eco.mtk.nao.ac.jp/koyomi/wiki/C2C0B1A2C2C0CDDBCEF12F2033C7AFCCE4C2EA.html)

Notebooks, paper, torii, brush
- [Kokuyo Campus Basic](https://www.kokuyo.com/en/stationery/series/campus/campus-notebook/basic)
- [Kokuyo dot ruled](https://www.kokuyo.com/en/stationery/category/notebook-paper/notebook/10591)
- [Kokuyo manuscript paper](https://www.kokuyo.com/en/stationery/category/notebook-paper/manuscript/3727)
- [Kokuyo Store NO-201U](https://kokuyostore.com/en_FR/campus-notebook-notebook-a4-brown-wide-horizontal-ruled-40-sheets/NO-201U.html)
- [getnavi](https://getnavi.jp/variety/500620/2/)
- [Hobonichi 2027 spec](https://www.1101.com/store/techo/en/2027/pc/detail_cover/ob27_jan_en/)
- [Mountain of Ink: Midori MD](https://mountainofink.com/blog/midori-md-notebook)
- [simplepaper MD grid](https://simplepaper.co/products/md-notebook-a6-grid)
- [tkgje 原稿用紙](https://www.tkgje.jp/entries/15500/15790_genkouyoushi.html)
- [All About 魚尾](https://news.allabout.co.jp/articles/o/60480/?page=2)
- [kotobank 原稿用紙](https://kotobank.jp/word/原稿用紙)
- [JAANUS washi](https://projects.mcah.columbia.edu/jaanus/node/294)
- [Pakutaso washi photo](https://www.pakutaso.com/en/20200300064post-23800.html)
- [JAANUS kasagi](https://aisf.or.jp/~jaanus/deta/k/kasagi.htm)
- [JAANUS myōjin torii](https://projects.mcah.columbia.edu/jaanus/node/2276)
- [JAANUS torii](https://projects.mcah.columbia.edu/jaanus/node/566)
- [Wikipedia Ensō](https://en.wikipedia.org/wiki/Ens%C5%8D)
- [Wikipedia Enso (alt)](https://www.wikipedia.com/wiki/Enso)
- [concepts.dsebastien: ensō](https://concepts.dsebastien.net/concept/enso/)
- [Calligraphy terms](https://selftaughtjapanese.com/2020/08/25/japanese-vocabulary-list-calligraphy-terms)
- [Zen Brush 3](https://apps.apple.com/us/app/-/id1531841731)
- [Takase seal design](https://www.takase.com/custom-seal-design/)
- [UMMA calligraphy with seal](https://umma.umich.edu/objects/calligraphy-with-seal-2022-2-7)

Modern Japan and ma
- [Japan House LA on ma](https://japanhousela.com/articles/a-perspective-on-the-japanese-concept-of-ma)
- [Dezeen: Kenya Hara](https://www.dezeen.com/?p=1161111)
- [Minimalissimo: White by Kenya Hara](https://minimalissimo.com/articles/white-by-kenya-hara)
- [Fireart: Japanese minimalism in UI](https://fireart.studio/blog/japanese-minimalism-in-ui-design-for-digital-products/)
- [daisyUI trend: Japanese minimalism](https://trends.daisyui.com/trend/japanese-minimalism/)

**Status: proposed, not implemented.**
