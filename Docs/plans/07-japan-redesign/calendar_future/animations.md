# Future animation experiments

The natural bristle/ink rendering, ensō's 0.55-second masked draw-on, month-header cross-fade, ink-wipe rewind, and Reduce Motion alternatives already belong to [calendar.md](../calendar.md). Implement and verify them now. This page concerns optional refinement after that baseline.

## Next: tune the brush on a real device

Compare the baseline dab/bristle renderer with a small set of hand-drawn vector studies at actual calendar and widget sizes. Preserve the open gap, readable numeral, date-derived seed, `EnsoShape`/`EnsoMark` APIs, and static widget rendering. Tune existing pressure, ink-load and tip parameters first; preserve the shared lightweight shape fallback for other consumers.

**Experiment:** capture the same dates in light/dark appearance at 26, 32, 38, and 40pt. Compare the entry, taper, and dry-brush streaks at normal viewing scale. Record which details survive at each size instead of judging only enlarged screenshots.

**Adopt when:** today is easy to locate, the mark is visibly open, the day numeral stays readable, and the stroke remains fully inside its box. Profile boolean-path work and month paging on a lower-performance supported device. Any containment or performance bug in the baseline is fixed immediately.

## Play: a quiet acknowledgment after saving

Prototype a short opacity reveal of the affected day's expense indicators after an expense is saved. Keep it confined to that day and play it once. No shifting numerals, bouncing cells, or repeated animation while scrolling.

**Adopt when:** people notice the changed day sooner and can continue interacting immediately. Under Reduce Motion, update the content directly. Verify save, edit, delete, sheet dismissal, off-screen months, and switching styles mid-update; all paths must show the final data regardless of animation state.

## Play: paper-inspired month transitions

Try a restrained edge reveal or ink-opacity treatment at the end of an explicit month-button action. The existing horizontal page gesture remains the primary navigation behavior. Avoid page curls, parallax, blur, or effects that distort the grid and suggest dates are moving between cells.

**Adopt when:** navigation direction becomes clearer without increasing the time to read or tap the target month. Interrupt rapid previous/next actions and Today jumps; the final page, header, and expense data must always agree. Keep the weekday band fixed, with no gap between adjacent pages. Reduce Motion uses a direct change or the existing minimal fade.

## Play: an optional pet gesture

A pet could acknowledge an explicit tap with one small head tilt or a short blink. Keep this in the decorative placement defined in [pets_and_mascots.md](pets_and_mascots.md), outside day cells and date controls.

**Adopt when:** it adds personality without making people wait, hiding content, or triggering repeated motion. Use a static pose with Reduce Motion; pause off-screen or in the background. The pet preference and device accessibility settings must take effect immediately.

## Review every animation with the same checks

- Compare a recording with the static baseline; state the user benefit in one sentence.
- Test normal motion, Reduce Motion enabled at launch, and toggled while the screen is visible.
- Interrupt with page swipes, repeated taps, sheet presentation, backgrounding, and a style change.
- Confirm no repeating timers or off-screen animation work, and no widget animation.
- Confirm accessible labels and input routes do not depend on the reveal finishing.

Sound, confetti, bounce, glow, and spending streak celebrations are outside these proposals. Financial information should remain calm and readable.
