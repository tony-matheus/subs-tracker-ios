# Calendar — restyle day cells in the existing month grid

## Goal and order

Implement this plan immediately after `general_app_ui.md`. The Home calendar remains the bottom element in calendar mode. Preserve the existing seven-column grid and its four-, five- or six-week month height behavior; this pass focuses on day cells and their settings choices. Japanese wall calendars inspire its paper, rules, numerals and brushwork; the dates are localized for worldwide use. Do not add Japanese holidays, era years or seasonal date markers.

Ship exactly three styles: **Default, Compact, Large**. Default restores the original calendar's 12pt dates, with a faint red-to-transparent wash and brand-colored square expense seals on ruled paper. Compact keeps its density and dots, with a larger centered date and overflow inline to the right of the dots. Large uses larger square expense seals, gives expenses more room, and reduces the Home price display. All styles allow up to 20% indicator overlap and use more natural ink-brush marks. Additional iPad layouts and styles are post-release work.

**Dependencies:** the palette, `AppFont` and paper/rule motifs from `general_app_ui.md`. Build the app and widget without running `charts.md`, `price_display.md`, `list_view.md` or `home_screen_ux.md`. The latter plans reuse these finished interfaces.

## Grid and navigation

- Preserve `CalendarService.daysGrid(for:)`: it already pads only to the whole weeks the month needs. Use `weekCount = grid.count / 7` as the layout input for the app, rewind and previews. February 2026 needs 28 slots, October 2026 needs 35 and May 2026 needs 42. Blank cells complete only the first/last week, stay noninteractive and are hidden from accessibility. Do not introduce a second grid builder or fixed six-row padding.
- Preserve `MonthView`'s existing height division: `cellHeight = (gridHeight - (weekCount - 1) * spacing) / weekCount`. `CalendarRewindOverlay` already uses the active source or target grid for the same calculation; keep both pages aligned during a row-count change. If a shared `CalendarGridLayout` is extracted, it must reuse this behavior rather than replace it. Draw any new shared rules from the active row count.
- Keep the existing seven equal columns, **4pt horizontal and vertical gutters**, 12pt outer horizontal padding, and style grid heights (370pt Default, 260pt Compact, 460pt Large). This is a day-cell restyle, not a grid-spacing change. Do not add a gap between month pages. Preserve the Sunday-first `CalendarService.daysGrid(for:)` default for this release.
- Localize the weekday labels in the current header geometry (52pt band with the current 8pt gap to the grid). If extracting a shared `WeekdayBand` outside the paged `TabView`, keep that visible geometry and column alignment; moving the band must not shrink or stretch the grid. Do not introduce a new 28pt band in this pass.
- Create `KoyomiHeader` in this plan as the sole visible month title in both Home modes, above the calendar/list body switch. Move the existing `HomeToolbar.monthButton` picker action to `KoyomiHeader(viewModel:onMonthPicker:)`, remove the duplicate toolbar month title, and keep `MonthPickerSheet`, the existing month window, swipe paging, Today, day selection, filters and widget grid working. The header's previous/next controls and month cross-fade are new work here; the existing toolbar month button is the starting point.
- Preserve the current horizontal page motion, `CalendarRewindOverlay`'s source/target transition, and `DayClickStyle`'s press scale and light haptic. Implement the planned ink-wipe rewind, its Reduce Motion cross-fade, and the 0.55s today-brush draw-on/replay in this plan; these are additions, not animations already present in the checkout. Settings previews must not cause replay.
- Create the shared lightweight `EnsoShape` and calendar `EnsoMark` in this plan. Add the widget's static today marker here. Later list and Year-grid work reuses `EnsoShape` without changing its geometry API.

### Retain the month-selector concept

Keep the concept's prominent month numeral beside the localized month name and year, an explicit picker affordance/caret, and previous/next controls as the direction for further implementation. Build `KoyomiHeader(viewModel:onMonthPicker:)` here with the existing `MonthPickerSheet` callback, while leaving the concept's fuller selector treatment to `home_screen_ux.md`. The later Year-grid picker must reuse the same selected-month state and header entry point. The concept's browser dropdown is a prototype of that action, not a new native picker requirement.

## Three styles and saved settings

Replace the five selectable `CalendarStyle` cases with three cases whose raw values are `default`, `compact` and `large` (escape the Swift `default` case name if required). Show them in that order in `CalendarStyleSheet`, with three accurate miniature previews and live `SettingsStore` selection. The five old raw values remain **decode-only aliases**:

| Saved raw value | New selection |
|---|---|
| `rounded`, `contrastRounded`, `straight` | Default |
| `compact` | Compact |
| `bigger` | Large |
| `default`, `large` | Matching new case |
| Missing or unrecognized | Default |

Implement this mapping in `CalendarStyle.init(from:)`; encode only the new raw values on the next save. Do not leave the former five in `allCases` or the picker. Preserve `AppSettings.calendarStyle`'s optional fallback and verify an unknown value does not reset unrelated settings. Update every exhaustive style switch in app, widget, previews and tests.

| Style | Cell and expense treatment | Grid height / gutter |
|---|---|---|
| **Default** | Square ruled-paper cell; **12pt date**, matching the original calendar on `main`; natural brush, faint red wash, inset memo divider close below the number, up to two 18pt brand-colored square seals plus `+n`. | 370pt / 4pt |
| **Compact** | Short paper cell with a **14pt date as the initial target**, centered horizontally in the cell's date area with the brush centered on it; faint red wash, fine rule, up to three brand-color dots followed by `+n` on their right in the same row. Retain its long-press View/Edit/Delete menu. | 260pt / 4pt |
| **Large** | Taller square paper cell with a 13pt date and more memo room; faint red wash, up to two larger **square** brand-colored expense seals plus `+n` (start at 23pt). Selecting Large makes the total smaller, without enlarging the date numeral. | 460pt / 4pt |

**Font-size reference:** local `main` at `6ff3ce0`, `LinguicaSubTracker/Features/Home/Views/Components/Calendar/Month/DayCell.swift:87`, renders the day with `.font(.system(size: 12))`. Default must use that 12pt size; the earlier 13pt concept is superseded. Keep the redesign's typography family. Compact's proposed 14pt target is larger than both its previous 11pt concept and Default; verify one- and two-digit dates in the shortest cells.

Default and Large share the square seal treatment, with different sizes. Reuse logo/customization resolution in a calendar seal view; do not put a circular background inside Large's square container. Compact keeps dots. Preserve the shared `LogoCircle(glass:)` API for callers outside these calendar indicators. Dates with no expenses still show the numeral and paper treatment. Preserve the localized full-date, Today, expense-count and expense-name VoiceOver label; hide decorative strokes from accessibility.

## Expense indicators and memo space

- Render up to two **18pt square seals in Default** and two larger square seals in Large (initial target 23pt), using muted brand colors. Paper shows through their interior, optionally with a very faint brand tint. Use a thin, slightly irregular border with a few tiny ink gaps; keep the logo crisp and level. Border irregularity is deterministic and subtle. No circular disc, glass, raised shadow or glow.
- Use the actual expense logo and user customization. Template marks can use the brand ink; preserve recognizable multicolor/raster artwork and emoji. The concept's letter marks are placeholders: initials are a fallback when no logo exists. Keep dark-mode contrast adequate without turning every seal red.
- **Overlap limit, all styles:** start with approximately 2pt separation; if needed, permit horizontal overlap of at most **20% of the smaller adjacent indicator's width**. For equal-size indicators, center-to-center distance must be at least `0.8 * size`: at most 3.6pt overlap for 18pt seals, 4.6pt for 23pt seals, and 1pt for 5pt dots. Keep stable stacking order and distinct, recognizable marks. This is an allowed maximum, not mandatory overlap on every day. Never overlap the overflow text, date, brush or divider; do not restore the old fixed `HStack(spacing: -10)`.
- **Compact overflow:** use one horizontal row containing up to three dots, then `+n` immediately to their right, with vertical centers aligned and a small non-overlapping text gap. Center the combined row beneath the date. The `+2` example must sit beside the dots, never above them, on the left, or on a second line. Use proportional spacing compression within the 20% limit before sacrificing readability.
- **Narrow-cell overflow in Default and Large:** measure the available cell width after insets. Put `+n` beside the seal pair only when both seals, their permitted spacing/overlap, a separate text gap and the entire overflow label fit. Otherwise put `+n` on its own line immediately above the seal row, still below the divider. At 375pt screen width, the current 4pt-gutter grid gives a column about 47pt wide; two 23pt Large seals already need at least 41.4pt at the maximum 20% overlap, so a side-by-side overflow label cannot fit there. Do not shrink the logos or overlap the label to force a single line. If accessibility text sizing leaves insufficient height for two seals and the overflow line in a six-week cell, show one seal and recompute `+n` to include every hidden expense. The whole day retains its existing tap action.
- **Move the rule closer to the number in every style:** measure the visible numeral and brush-ink bounds, not the padded SVG/frame box. Start with `ruleY = max(numeralInkMaxY + 2pt, brushInkMaxY + 1pt)`; tune the brush's vertical extent so the rule reads close to the numeral, usually 2–4pt below it, while keeping clear of the ink. Remove unused lower padding in the date area. The entire remaining cell height belongs to expenses. Keep the hairline horizontally inset and clear of seals and overflow.
- Fit the brush around each style's numeral and derive the date-area height from those actual painted bounds. The earlier fixed 32/27/35pt brush boxes are not layout requirements. In Compact, keep the larger numeral horizontally centered in the date area; its vertical position must reserve a separate divider and indicator row. Extra height in four- and five-week months increases the expense compartment, not the numeral or empty space above it. Verify the smallest six-week cells before fixing dimensions.
- Keep the maximum of two visible seals in Default/Large and three dots in Compact, plus overflow. More memo space is for readable placement and breathing room, not an automatic increase in indicator count. The three settings previews must show their actual indicators and a busy-day overflow example.

## Faint red paper wash

Apply a restrained vertical `shu`-to-transparent wash to each real day cell, including empty-expense days. Start at about **7% opacity** at the top, about **2%** one-third down, and transparent by roughly **70%** of the cell height. Blank padding cells remain plain paper. This is decorative ink on paper, independent of expense amount, paid state or brand color. Tune the wash together with the ordinary brushes in a complete month, so it reads as paper color rather than 28–42 competing red highlights. Keep today's brush as the strong date accent, with brand colors reserved for expense seals/dots/logos.

This is the approved bokashi-inspired direction from the concept. Additional washi-fiber textures and the alternative ink-ledger treatment remain explorations; they do not add settings or change the three shipped styles.

## A distinct, natural ink brush for each date

Use `EnsoShape.seed(for: date)` to derive a stable, visibly different open brush circle for each real date in the month. Vary entry angle, opening, pressure/width, radius drift, taper and dry-brush streaks from the seed. The same date must reproduce the same shape across redraws; nearby dates must not appear to be copies. Do not use render-time randomness. Blank padding cells have no stroke.

The target is a Japanese ink-painting brush impression: a loaded entry, pressure-shaped body, uneven bristle edges, fine longitudinal dry streaks, and a lifted, depleted tail. A uniformly stroked wobbly circle alone does not meet this requirement. Ordinary dates use a quiet ink/rule-color watermark treatment: their different shapes remain visible on close inspection at phone size but recede behind numerals, expense marks and today's strong `shu` stroke when viewing the whole month. Keep texture restrained enough that the date stays readable.

### Quick brush-engine research and implementation direction

Research checked 2026-10-14:

- Drawing applications build strokes from repeated brush-tip impressions (“dabs”); tip spacing and input-driven changes in size and opacity determine the result. See [Krita's Pixel Brush Engine](https://docs.krita.org/en/reference_manual/brushes/brush_engines/pixel_brush_engine.html) and [MyPaint's stroke/dab model](https://www.mypaint.app/en/docs/manuals/v0.9.0/concepts/).
- Krita's bristle engine models individual bristle trails, density, spreading, and ink depletion. These are useful mechanisms for the desired broken-edge and dry-tail appearance. See [Krita's Bristle Brush Engine](https://docs.krita.org/en/reference_manual/brushes/brush_engines/bristle_engine.html).
- SwiftUI offers immediate-mode 2D drawing through [Canvas](https://developer.apple.com/documentation/swiftui/canvas) and [GraphicsContext](https://developer.apple.com/documentation/swiftui/graphicscontext), including paths, images, transforms, compositing and masks.

**Proposed adaptation for this calendar** (implementation choices inferred from those techniques, not a claim that these settings reproduce a specific physical brush):

1. Generate a smooth, date-seeded open centerline and sample it by arc length. Attach synthetic pressure, tip angle and ink-load curves along the stroke; no pen input is needed for a decorative calendar mark. Use continuous seeded variation rather than independent random noise at each sample.
2. Stamp a small asymmetric bristle-tip alpha mask along the centerline, rotating with the tangent and varying width with pressure. Begin prototyping with spacing around 10–20% of the local tip width, then tune at actual device scale so individual dabs do not appear as beads. Create the tip procedurally or use a project-owned texture.
3. Model several stable bristle tracks within the tip. Let pressure spread them and let ink load gradually thin them toward the tail. Preserve a fuller core and a few coherent paper gaps; avoid arbitrary speckles across the numeral. Build texture in a monochrome alpha mask, then tint it with the existing ink/`shu` tokens so light and dark appearances share geometry.
4. Render with a small shared `InkBrushRenderer` using Canvas/Core Graphics. Create `EnsoShape`'s public geometry/seed API here for later list and Year-grid callers and the widget; let the calendar's new `EnsoMark` add the textured rendering and replay interface. Keep this work inside the calendar plan and build both targets without another feature plan.
5. Cache completed masks or sampled geometry by date seed, brush parameters, size and display scale. Bound the cache to the visible/adjacent month needs; include appearance in the key only if the cached output is already tinted. Avoid rebuilding bristle geometry on every animation frame.
6. Implement the specified **0.55s** draw-on, `.timingCurve(0.2, 0.7, 0.3, 1)` and rewind replay for today's new `EnsoMark`. Reveal the cached textured stroke in centerline order with a mask expanded enough to include the bristle edges; the final animated frame must match the static mask. Reduce Motion renders the completed mark directly; widgets use a static today-only marker through the shared lightweight renderer. Profile paging and rewind on the smallest supported device before increasing texture detail.

Each ordinary date's stroke is quiet ink/rule color behind its numeral; **today** alone uses a strong `shu` stroke and the 0.55s `EnsoMark` draw-on created here. Non-today strokes render fully formed, without simultaneous animation across the month. Sunday keeps a `shu` numeral, Saturday an `ai` numeral, and today an `ink` numeral inside its red stroke. The stroke must stay clear of the expense area. In Compact, reduce its size or weight rather than removing date-specific variation. Compare a full, busy six-week month at 1× in light and dark mode: Today should be found first, then dates and expenses, with ordinary brush details discovered last.

Add `ensoReplay` on rewind completion and the widget's today-only marker because its grid is smaller. Keep the lightweight `EnsoShape` available for later consumers; tune the calendar brush at 1× viewing size before committing to more detail. The brush research and these specifications update the implementation plan; they do not require a Figma change.

## Calendar at the bottom; smaller price in Large

`HomeView` currently uses a `VStack` with `TotalView` above `CalendarView`; the total's flexible frame already holds the calendar at the bottom. Preserve that order and bottom anchoring while adding the new `KoyomiHeader` above the calendar/list body switch and retaining the small calendar bottom inset. Do not reverse the two views or add a scroll view on phones where the content fits. On shorter phones and in Large, provide vertical scrolling with at least viewport-height content and a flexible spacer so no row or control is clipped and the calendar still rests at the bottom when there is room; horizontal month paging remains intact. Keep list-mode composition and the existing picker sheet.

The app's price display is `TotalView`'s `MoneyDisplay`. Read the selected `CalendarStyle` for its fitted size: Default and Compact retain the current `48...92pt` range; Large uses `40...72pt`, including its lower bound for long amounts. Keep width fitting and the total's Stats action. This style-triggered size range belongs here. When `price_display.md` later changes the normal range to `44...84pt`, it must retain a smaller Large range (`36...68pt`) instead of overwriting the style behavior.

## Implementation sequence

1. Change `CalendarStyle` to three cases with decode aliases. Update fallback, style tokens, exhaustive switches, settings previews and tests. Build app and widget to catch stale references.
2. Preserve `CalendarService`, `MonthView` and rewind's existing 4–6-row calculation and 4pt grid gutters. Localize the weekday labels without changing the band geometry; if extracting a shared band/layout helper, verify it produces the same column positions and row heights. Update previews to exercise the existing 4-, 5- and 6-week behavior.
3. Restyle `DayCell`: restore Default's 12pt date, enlarge and center Compact's date, align Compact overflow to the right of its dots, and use square seals in Default and Large. Add the shared 20% overlap cap, measured narrow-cell overflow fallback, faint red wash, and a divider positioned from visible number/brush bounds. Preserve expense counts, Compact quick actions, touch behavior, accessibility and the shared `LogoCircle(glass:)` API for other callers.
4. Create and cache the natural ink-brush rendering described above, with stable date-seeded variation and quiet ordinary marks; today alone is the animated accent. Add the ink-wipe rewind and Reduce Motion fallback while preserving current page/press feedback. Check entry, bristle breakup and lifted tail on the first, middle and last dates in all three sizes, then inspect a complete month for visual hierarchy.
5. Add `KoyomiHeader` above both Home modes, move the existing toolbar month-picker action into it and remove the duplicate toolbar title. Preserve `HomeView`'s total-above-calendar, bottom-anchored order while adding a short-screen scroll fallback. Make `TotalView`'s `MoneyDisplay` range style-aware for Large. Keep the header, picker and toolbar contracts for `home_screen_ux.md`.
6. Build app and widget. Verify persistence, layout, motion and accessibility before continuing to another feature plan.

## Acceptance checks

- App and widget build after `general_app_ui.md` plus this plan. Settings shows exactly Default, Compact, Large and updates Home live. Old saved values map as above; new saves use the three new values; unknown values preserve unrelated settings.
- Verify February 2026 (4 weeks), October 2026 (5) and May 2026 (6) in the Sunday-first grid: exactly 28, 35 and 42 slots respectively, with no wholly empty trailing row. Cells share the available grid height with the existing 4pt row/column gutters; the localized weekday band retains its current height, gap and alignment. Check paging and rewind between different week counts. Calendar stays at the bottom of Home; every row remains reachable on the smallest supported iPhone in light/dark mode and Large.
- Check zero, one, two and many expenses in all styles, including `+2` and a multi-digit overflow count. Default and Large show square brand-colored seals, with `+n` above the seals whenever it cannot fit beside them; Compact shows dots with `+n` vertically centered to their right in the same row. Test the narrowest column and a six-week month before accepting sizes. Verify actual logos, emoji, custom artwork and initials fallback. Border texture must leave the mark recognizable.
- Compare Default's 12pt numeral with the original `main` reference. Verify Compact's larger 14pt target is horizontally centered with its brush for both one- and two-digit days; it does not displace or clip the expense row.
- The divider follows the visible number/brush closely and gives the remaining space to expenses. Compare busy days in 4- and 6-week months. Only adjacent expense indicators may overlap, by at most 20% of the smaller indicator width; overflow text, numeral, brush and divider remain separate. Test both separated and maximum-overlap layouts.
- Every real day has the faint red fade and a stable, distinct painted brush with pressure variation, bristle breakup and a tapered tail visible on close inspection at normal viewing size. In a complete month, ordinary brushes recede like watermarks while Today remains immediately identifiable. Today's final animated frame matches the static mask, with no texture flicker during paging or replay. Today alone has the strong `shu` brush and draw-on; the background wash, Sunday numeral and brand ink are separate color uses. Verify swiping, existing picker, Today, rewind ink wipe, compact quick actions and static widget marker. Reduce Motion makes today static and rewind cross-fade.
- Retain the new month-selector visual concept and its existing picker callback for the later native picker work; do not introduce a second month selection state or make that future work a dependency.
- VoiceOver announces localized date and expenses once per real day, skips blanks and decorative strokes, and keeps action hints. In English, French and Japanese locales no Japanese holidays, era years or seasonal markers appear.

## Deferred

- iPad layouts and further cell variants belong to the post-release iPad discussion.
- A configurable or locale-derived week start may be planned later. This release stays Sunday-first across grid and band.
