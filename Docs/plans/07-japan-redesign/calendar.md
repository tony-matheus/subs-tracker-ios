# Calendar — worldwide month view with Japanese wall-calendar motifs

## Goal and build order

Implement this plan **immediately after `general_app_ui.md`**. It needs that plan's `paper`, `ink`, `rule`, `shu`, `ai`, `AppFont`, `AppRadius`, and `KasagiHeader` tokens and motifs. It does not need `charts.md`, `price_display.md`, `forms.md`, `list_view.md`, or `home_screen_ux.md`. Build the app and widget at the end of this plan before moving to another feature plan.

The month view uses the visual structure of a Japanese wall calendar: a prominent month number, dark weekday band, paper and hairline rules, space for daily notes, and an open brush circle around today. It is a worldwide expense calendar. **Do not add Japanese holidays, a holiday badge, era years, traditional Japanese month names, solar terms, or country-specific date annotations.** Use the device's localized month, year, and weekday text. Keep the existing Sunday-first grid in this release.

The default cell stays minimalist while showing expenses: up to two small brand logos and a `+n` overflow badge. Settings continues to expose five day-cell variants, with live changes. A later iPad plan may add layouts and variants after release; no iPad-specific calendar design belongs here.

**Ownership:** This plan owns the calendar header, weekday band, all five cell appearances and settings previews, the small `LogoCircle(glass:)` opt-out, `EnsoShape`/`EnsoMark`, Home integration needed to ship this feature alone, rewind, and the widget's month-grid today mark. `price_display.md` owns money formatting and the existing `CAD` fixes. `list_view.md` owns notebook rows and `ExpensesInDay` styling. `home_screen_ux.md` later replaces the wheel picker with a Year grid and redesigns the remaining toolbar.

## Current code to change

- `HomeView` puts an expanding `TotalView` above `CalendarView`; its toolbar currently repeats the month name and owns the wheel `MonthPickerSheet`. The new header must own that picker action and work in calendar **and** list modes.
- `CalendarView` contains the paged `TabView` and rewind overlay. Its frame includes 60pt for `MonthView`'s 52pt weekday row plus 8pt gap. Change these together when moving the weekday band outside the page.
- `MonthView` uses 4pt column and row gaps and 4–6 rows. The default grid becomes a stable six-row ruled sheet; all other variants also use six rows so month changes do not jump.
- `DayCell` already has two-logo-plus-overflow and dots-based expense layers, a `.compact` context menu, and a glowing today border. Preserve those expense semantics, remove the glow, and draw the ensō.
- `CalendarStyle` has exactly five persisted raw values: `.rounded`, `.contrastRounded`, `.straight`, `.bigger`, `.compact`. `AppSettings.calendarStyle` is optional; nil and unknown values resolve to `.rounded`. **Keep those raw values and fallbacks.** Do not add `.koyomi` or migrate stored settings.
- `CalendarStyleSheet` already writes to `SettingsStore`, and `HomeView` explicitly reads the selected style so changes render live. Keep that data flow and replace all five miniature previews.
- The widget target shares `LogoCircle`, `CalendarStyle`, assets, and foundation theme code through `project.pbxproj`; share `EnsoShape.swift` there too. App-only typography helpers must not enter widget code.

## Target design

### 1. Month header and navigation

Create `KoyomiHeader(viewModel: CalendarViewModel, onMonthPicker: @escaping () -> Void)` in the calendar component folder. Mount it as the first child of the `HomeView` content stack, above both calendar and list modes, with the same 12pt horizontal alignment as the grid. Read `viewModel.currentMonth`; leave `CalendarViewModel.monthKey` unchanged for its callers and test.

- `KasagiHeader` above a compact header row. Use a 56pt Fragment Mono numeric month in `shu`, a 12pt year in `inkSecondary`, and a 13pt localized month name in `ink`. The header's minimum height is 72pt and may grow for Dynamic Type. Use Gregorian date components with the device's locale and time zone to format labels; do not hardcode English or inject a Japanese era.
- The central month group is a 44pt-or-larger button that calls `onMonthPicker` and has an accessibility label such as “Choose month, October 2026.” Keep the existing `MonthPickerSheet` and its `showMonthPicker` state until `home_screen_ux.md` replaces the picker.
- At the edges, 44×44pt previous/next buttons show faint localized abbreviated month names and move `currentMonthIndex` through `currentMonthIndexBinding()`. Hide and disable them at the generated month-window bounds. Horizontal page swipes still work.
- Keep a 2pt gap from the header to the weekday band, with no extra empty seasonal-data line. Cross-fade the header text on a month change; disable that animation under Reduce Motion.
- Remove the `.principal` `monthButton`, `monthKey`, and `onMonthPicker` API from `HomeToolbar` in this plan. The header becomes the sole visible month title and picker trigger in both Home modes. Keep all other toolbar controls for `home_screen_ux.md`.

### 2. Weekday band and grid geometry

Create `WeekdayBand(style:)` directly above the grid and outside the paged `TabView`, so rewind and month changes retain the same weekday row. Format seven localized abbreviated weekday labels in **Sunday-first** order, matching `CalendarService.daysGrid(for:)`; derive them from the calendar/locale rather than a Japanese or English lookup table. The labels are decorative because each day cell announces its full date to VoiceOver.

- Default `.rounded` uses a 28pt ink band: apply `.environment(\.colorScheme, .dark)` to the band subtree so `paperRaised` resolves to #1C1816, `ink` to #F4EFE6, `shu` to #E84A33 and `ai` to #6F93D6 in both app appearances. Draw hairline column dividers. Sunday uses `shu`, Saturday `ai`, and other weekdays `ink`. The four variants use the same 28pt label row on paper, without a filled band. No holiday coloring exists.
- Use a six-row, seven-column grid for every style. Pad short months with noninteractive, accessibility-hidden blank cells. Default `.rounded` has **0pt** column and row spacing. Draw the six internal vertical rules and six row rules once over its paper grid, using `ruleStrong` at `1 / displayScale`; no individual card backgrounds or rounded corners. The band dividers align with those rules.
- The four variants use **2pt** column and row gutters, including between weeks. Keep the existing style grid-height targets (370pt normal, 460pt expanded, 260pt compact), but do not let the Home layout stretch the gaps. Month pages remain a single horizontal paging surface; do not insert visual spacing between adjacent month states.
- Give each weekday label one column, `.lineLimit(1)` and `.minimumScaleFactor(0.7)` so longer localized abbreviations fit without moving the dividers.
- Replace `CalendarView`'s `+60` frame calculation and rewind's 60pt top offset with a 28pt band plus the grid's explicit height. `MonthView` can expose `showsWeekdayHeader` for onboarding previews, while `CalendarView` mounts one shared band and passes `false` to each page.

### 3. Five settings variants and expenses

Keep the persisted `CalendarStyle` cases and order. Change only display names, subtitles, visual properties, and previews:

| Raw value | Settings name | Cell design | Expense indicator |
|---|---|---|---|
| `.rounded` | Koyomi | Default paper, square ruled cell, 20pt date numeral, open ensō on today | Two 20pt logos plus `+n` overflow |
| `.contrastRounded` | Framed | Paper cell with a subtle expense-color border, restrained 2pt gutters | Two logos plus `+n` |
| `.straight` | Dots | Square paper cell with a hairline and no tint | Up to four brand-color dots plus `+n` |
| `.bigger` | Expanded | Taller ruled paper cell and larger date/logo area | Two larger logos plus `+n` |
| `.compact` | Compact | Short ruled paper cell; retain its long-press View/Edit/Delete menu | Up to three dots plus `+n` |

- **Style tokens:** `.rounded`: radius 0, logo 20, numeral 20, ensō 38, grid 370. `.contrastRounded`: radius 4, logo 22, numeral 16, ensō 32, grid 370. `.straight`: radius 0, numeral 16, ensō 32, grid 370. `.bigger`: radius 0, logo 28, numeral 22, ensō 40, grid 460. `.compact`: radius 0, numeral 12, ensō 26, grid 260. Keep `usesDots` true only for `.straight` and `.compact`, `hasBrandBorder` true only for `.contrastRounded`, and `hasQuickActions` true only for `.compact`. Set `showsGradientTint` false for all five; expense color stays in indicators and the Framed border.
- Every real cell shows its day number. Today uses an `ink` numeral inside the `shu` ensō; Sunday uses `shu`, Saturday `ai`, and other days `ink`. The marker is a stroke, not a fill or glow. There is no holiday check or annotation slot.
- Reserve the lower cell area for expenses. For logo styles retain the existing first/second logo and overflow-count behavior; for dot styles retain dots and overflow. Use an inset rule above the lower area in the default. The default's two 20pt logos, overlap, and badge must fit a 50pt-wide cell without covering the numeral.
- Add `var glass: Bool = true` as the last stored property of `LogoCircle`. When false, omit glass and its colored shadow and use a `Color.rule` hairline ring; use `glass: false` from all calendar logo cells. Existing callers, including widgets, keep the `true` default. This API is owned here; `list_view.md` only reuses it.

  ```swift
  @Environment(\.displayScale) private var displayScale
  // Keep the existing logo content on top of this disc.
  let disc = Circle().fill(customization.resolvedBackground)
      .frame(width: size, height: size)
  if glass {
      disc.glassEffect(.regular.interactive())
          .shadow(color: customization.resolvedShadow.opacity(0.5),
                  radius: size * 0.22, x: 0, y: size * 0.08)
  } else {
      disc.overlay(Circle().strokeBorder(Color.rule, lineWidth: 1 / displayScale))
  }
  ```
- Restyle `CalendarStyleSheet`'s five miniature previews to show the actual date, today marker, and respective expense indicator. Keep the existing store binding, selection feedback, and immediate Home redraw. Nil settings and unknown decoded values still use `.rounded`; users who explicitly chose another case retain that case after the redesign.
- Keep blank cells noninteractive. Day tap opens the existing day sheet or add flow. Keep `.compact` quick actions and delete confirmation. Replace scale/bounce press feedback with a subtle dim and the existing light haptic, with no animation under Reduce Motion.
- `DayCellViewModel.accessibilityLabel` speaks the localized full weekday/month/day, “Today” when applicable, and the expense count plus up to three names. It never announces a Japan-specific date. Keep the day action hint and hide the decorative ensō.

### 4. Ensō today marker (`EnsoShape` + `EnsoMark`, new)
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
| Box | **38pt** in the default `.rounded` cells (range 38–42); 28pt other styles; 34pt list headers (`list_view.md`); 40pt Year grid cells (`home_screen_ux.md`); about 2.2 × numeral size in widgets |
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
  - In default `.rounded` cells the ensō box (38) sits at (0,0), inside the 50–54pt cell, and there is no clip shape.
  - In the other styles it is an `.overlay(alignment: .topLeading)` applied after any cell clip, at the same inset as the numeral box. The clip never cuts it.
- **Performance:** one ensō per visible month (plus the Year grid). `path(in:)` runs boolean ops on about 150 points, and the shape is not `Animatable` (the mask animates), so the path is not rebuilt per frame. No `Canvas`, blur or shader.
- **Vector-asset alternative** (if the procedural stroke looks too synthetic on a device):
  - 3–5 hand-drawn ensō SVGs in `Resources/Assets.xcassets` as `enso_0…enso_4` (Preserve Vector Data, Template rendering). The catalog is already shared with the widget.
  - Pick one with `seed % n`, rotate it so its gap sits lower-left, and tint it `shu`.
  - The draw-on is the same trimmed-circle mask.
  - `EnsoMark`'s API is unchanged; only its body swaps `EnsoShape` for `Image`.

### 5. Rewind, widget, and Home height

- Rewrite `CalendarRewindOverlay` to render source and target `MonthView`s without their weekday bands, masking the target from its travel edge like an ink wipe. Use an opacity cross-fade under Reduce Motion. It must use the selected style's same six-row geometry and finish by clearing `rewindPair`; then increment `ensoReplay` so today's brush redraws.
- In the widget month grid, replace today's square stroke with a static `EnsoShape(seed:).fill(Color.shu)` behind an `ink` numeral, retaining `.widgetAccentable()`. Widgets never animate. Leave the compact week widgets' marker unchanged.
- Make `HomeView` fit the new header immediately, without waiting for `home_screen_ux.md`: remove `TotalView`'s unbounded vertical expansion in calendar mode and place the total and fixed-height `CalendarView` in a vertical `ScrollView` below the header. Set the total's minimum height to 96pt and keep a small bottom inset. On short phones, the content scrolls vertically while calendar pages still swipe horizontally. List mode retains its existing list scroll under the shared header. `home_screen_ux.md` may replace this temporary composition later.
- Keep the existing month window, day-selection routes, expense filtering and `CalendarViewModel.monthKey` format. Do not change `ExpensesInDay` or money formatting in this plan.

## Implementation sequence

1. Verify the `general_app_ui.md` foundation with an app-and-widget build. Do not run any prerequisite step from `list_view.md` or `price_display.md`.
2. Add `EnsoShape.swift` with the full §4 API and share it with the widget target. Add `LogoCircle(glass:)` as described in §3; build both targets.
3. Restyle the five existing `CalendarStyle` cases and `CalendarStyleSheet` previews. Preserve persisted raw values, nil/default handling, and live store selection.
4. Update `DayCellViewModel`, `DayCell`, and `MonthView` for localized accessibility, expense indicators, the ensō, six-row geometry, and the five appearances. Use no holiday or seasonal data model.
5. Add `WeekdayBand`, update `CalendarView` and rewind to use the shared band and matching grid geometry, and raise `OnboardingCalendarHero`'s `MonthView` height from 300pt to 370pt so all six rows and the weekday band fit.
6. Add `KoyomiHeader`; mount it in `HomeView`, route its center button to the existing month picker, remove the toolbar's principal month title, and give calendar mode the scrollable height budget from §5.
7. Update the widget month-grid today marker. Build the app and widget; run calendar-related tests and the visual checks below before moving to another feature plan.

## Verification and handoff

- Build the app **and** widget with only `general_app_ui.md` and this plan applied. No missing `JapaneseCalendar`, new `.koyomi` case, `MoneyFormatter.exact`, `Notebook`, `HankoStamp`, or future `HomeToolbar` API should be required.
- Verify the five settings selections and previews, saved `.rounded`/other styles and unknown-value fallback, live switching, 4/5/6-week months padded to six rows, and days with 0, 1, 2, and 3+ expenses. Logos, dots, and `+n` must stay readable and inside their cells.
- Verify month swipes, edge buttons, month picker, today jump, rewind, day tap, compact quick actions, and widget today mark. Check light/dark appearances and the smallest supported iPhone; the header, total, band, grid, and bottom controls must remain reachable by vertical scrolling.
- Verify VoiceOver date/expense labels, 44pt header buttons, hidden blanks, and Reduce Motion. Check English, French, and Japanese device locales: date text changes locale, the grid and weekday band remain aligned, and no Japan-specific holiday, era, or seasonal marks render.
- `list_view.md` may now consume `EnsoShape` and `LogoCircle(glass:)` without implementing them; its day-header colors use today/Sunday/Saturday only. `price_display.md` still owns every `CAD` fix. `home_screen_ux.md` replaces the wheel picker and remaining toolbar later while keeping the header as the month title.

## Deferred

- iPad calendar layouts and additional day-cell variants belong to the post-release iPad discussion.
- A configurable or locale-derived week start may be planned later. This release keeps Sunday-first consistently in the grid, band, week calculations, and widget.
