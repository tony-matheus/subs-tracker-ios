# Future calendar UX improvements

All items here are optional follow-ups. The baseline remains the flexible 4–6-row, Sunday-first worldwide calendar described in [calendar.md](../calendar.md).

## Next: make busy days easier to inspect

**Hypothesis:** the existing seals, logos or dots and `+n` correctly communicate density, but a person may want to see which expenses are hidden without losing their position in the month.

Prototype a clearer transition from the whole-day tap to the existing day sheet, with the date and expense count easy to identify. Compare the current indicator layout with a slightly stronger overflow label, keeping the total logo/dot capacity and the same tap target. Do not make the tiny `+n` badge the only way to open the day.

**Validation:** use days with 0, 1, 2, 3, and 10 expenses across Default, Compact and Large. Ask participants to find a hidden expense, dismiss the sheet, and find today's date. Verify Default's two 18pt square seals and Large's larger square seals fit with overflow in six-week months. Compact's overflow stays to the right of its dots in the same row beneath the larger centered date. Indicator overlap never exceeds 20%; the divider stays close to the visible number/brush so expenses use the remaining height. All names remain available through the sheet and VoiceOver; empty days still lead to the existing add flow. Any baseline clipping is fixed before this experiment.

**Likely touchpoints:** `DayCell`, `DayCellViewModel`, the day-selection route, and `ExpensesInDay`. Coordinate changes to the sheet's visual design with [list_view.md](../list_view.md).

## Next: preserve context through navigation

Observe whether people understand the header's previous/next month buttons, center month picker, horizontal swipes, and Today transition. Record whether opening Stats or a day sheet causes uncertainty about the current month or active filter.

Evaluate the Year grid and visible filter state when [home_screen_ux.md](../home_screen_ux.md) implements them. Keep that plan's single source of month state and avoid introducing a second date selection model here.

Retain the concept's large month numeral, localized month/year, picker caret and previous/next controls for that follow-up. Its browser dropdown demonstrates the selection action; the current native sheet continues to work until the Year grid lands.

**Validation:** start from a distant available month, change a filter, open and dismiss an expense, switch Calendar/List, then return to today. The visible month, summary, expense days, and picker selection agree throughout. At the generated window bounds, navigation does not create an empty page or silently jump elsewhere.

## Later: configurable first weekday

**Hypothesis:** a Sunday/Monday setting or a locale-based default improves familiarity for users whose week starts on Monday.

Plan the setting and its default together with persisted settings compatibility. Propagate it through `CalendarService.daysGrid`, the weekday band, `ExpenseService.weekInterval`, `CalendarCache`, previews, and `WidgetData`. Keep weekday colors tied to the date's weekday rather than its column index. Calendar and widget must agree after a settings change; refresh cached grids when necessary.

**Validation:** Sunday and Monday starts, months beginning on every weekday, month/year boundaries, and existing saved settings. Verify weekday labels, expense placement, week totals, and widget output together. This is a future product decision; the current release remains Sunday-first everywhere.

## Later: a wider month window

The existing generated window is limited to the previous month through twelve months ahead. Explore full-year navigation if Year-grid testing shows disabled months are confusing. Coordinate with [home_screen_ux.md](../home_screen_ux.md), which owns the picker.

Measure `CalendarCache.monthData` and expense recurrence work before extending the window. Consider preparing months on demand while retaining the selected month by identity when the window changes. A wider window must not silently alter recurrence, expense filtering, or totals.

**Validation:** navigate across December/January, choose the first and last month, jump to today, and reopen after the real date changes. Compare loading and paging performance with the current window using a large representative expense fixture.

## Later: calendar-system and time-zone consistency

The current plan explicitly formats the month header with Gregorian components, while calendar services and several date consumers use `Calendar.current`. Evaluate the full experience when the device uses a non-Gregorian calendar, and document the product's intended calendar-system policy before expanding support.

Audit the header, grid, day accessibility label, month picker, `monthKey` callers, cache keys, today seed, expense recurrence, and widgets as one change. Preserve `monthKey`'s existing contract in the current implementation.

**Validation:** switch locales independently from calendar systems; cross midnight and a daylight-saving boundary; change time zones while the app is backgrounded. Every visible day, today mark, and expense assignment refers to the same intended date. Do not introduce era names or holiday data as a side effect.

## Later: iPad and larger text layouts

Prototype a selected-day detail pane beside the calendar on iPad, with a clear selected-day treatment distinct from today's ensō. Explore keyboard navigation, focus continuity, and denser or more spacious layouts as one coherent tablet design. Any extra style needs its own persistence and migration decision; preserve the three shipped raw values and their legacy decode aliases.

For very large accessibility text, evaluate an optional agenda-first presentation or a taller grid. This builds on the baseline's accessible labels and reachable scrolling; it does not excuse clipping or inaccessible controls in the current release.

**Validation:** portrait/landscape, narrow multitasking widths, large text, VoiceOver, and keyboard use. Opening details must not lose the month, shift expense dates, or leave a selected day that cannot be found in the grid.
