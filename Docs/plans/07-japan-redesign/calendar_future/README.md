# Calendar future

This folder records room to improve the calendar after the implementation of [calendar.md](../calendar.md). These are proposals to evaluate, not additional requirements for that implementation. No mascot, animation experiment, logo asset, or app-icon change is implemented by these documents.

## What belongs to the current implementation

[calendar.md](../calendar.md) remains the source of truth for the localized month header, retained month-selector concept, Sunday-first weekday band and flexible 4–6-row grid; three cell styles and their previews; legacy style decoding; 12pt Default dates and larger centered Compact dates; Default/Large square expense seals, inline Compact overflow and the 20% overlap cap; the rule close to the number and enlarged expense area; faint red day-cell washes; natural date-specific ink-brush rendering and today's draw-on; ink-wipe rewind; Reduce Motion; accessible day labels; compact quick actions; the bottom Home calendar; and the widget month-grid today marker. Density, clipping, contrast, or accessibility failures in these features are release defects to fix now, not future enhancements.

The shipped choices are Default, Compact and Large. The five previous raw values remain readable through the migration in `calendar.md`; nil and unknown settings use Default. The worldwide calendar does not add Japanese holidays, era labels, traditional month names, or seasonal annotations.

## Explore next

The priorities below apply only to optional work in this folder. **Next** means a focused follow-up after baseline verification. **Later** means a separate product/design discussion. **Play** means an experiment that can be discarded without affecting the calendar.

| Priority | Area | Starting point | Evidence required before adoption |
|---|---|---|---|
| Next | Dense-day discovery and context | [UX improvements](ux_improvements.md) | People can find hidden expenses and retain the selected month without more clutter. |
| Next | Brush and transition refinement | [Animations](animations.md) | Clearer feedback, good performance, and complete static alternatives. |
| Next | Logo legibility | [Logos and identity](logos_and_identity.md) | Better recognition at existing calendar sizes, preserving user customizations. |
| Later | Week start, wider date window, and iPad | [UX improvements](ux_improvements.md) | A coordinated app/widget design with consistent dates, expense totals, and navigation. |
| Play | An optional in-app pet | [Pets and mascots](pets_and_mascots.md) | Delight without obscuring dates, nudging spending, or adding maintenance pressure. |
| Play | New app identity directions | [Logos and identity](logos_and_identity.md) | Small-size recognition, palette fit, and a chosen relationship to the mascot. |

## Related work already has an owner

- [home_screen_ux.md](../home_screen_ux.md) owns the Year grid, permanent Today/Add controls, filter sheet and badge, and final Home toolbar/layout. This folder may suggest evaluation scenarios but does not replace that plan.
- [list_view.md](../list_view.md) owns notebook rows and the day-expense sheet styling.
- [price_display.md](../price_display.md) owns money formatting and CAD fixes.
- [general_app_ui.md](../general_app_ui.md) owns shared palette, typography, and brand-wide visual rules. App-icon exploration here must be coordinated with that work.
- [research_results_and_future_points.md](../research_results_and_future_points.md) is the wider redesign backlog. Where its older prioritization differs, the current feature-owner plan wins; the calendar grid and its three styles are requirements of `calendar.md`.

## How to use this folder

Choose one hypothesis, build the smallest reversible prototype, and compare it against the shipped baseline. Record the device, locale, appearance, text size, motion settings, outcome, and decision in a short note beside the relevant document. Promote accepted work into its own implementation plan with ownership, data migration needs, and verification steps. Keep rejected experiments documented with the reason; do not silently add them to the baseline.
