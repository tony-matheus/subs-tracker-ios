# Optional in-app pets and mascots

This is an exploration for a companion inside Satoru. It does not create or activate a ChatGPT Work pet, use a pet plugin, or add assets to the app. Start with a static concept before choosing an animation format.

## Play: choose a role before choosing a character

A small companion could welcome the user to an empty month or appear in an optional decorative space outside the grid. Its role is warmth and personality. It must not explain financial status through an emotion, scold for spending, ask to be fed, or reward purchase frequency.

| Direction | Visual idea | Small prototype | Decision to make |
|---|---|---|---|
| Crow | A compact ink silhouette with a clear beak and one restrained shu detail | Static neutral and curious poses | The broader redesign notes mention a crow; confirm whether it should carry the app identity. |
| Brush creature | A tiny irregular ink shape with simple eyes and a soft taper | One still pose and one blink | Can it remain distinct from today's ensō and expense dots? |
| Paper companion | A folded-paper bird or small origami animal | A still pose beside an empty-state message | Does the angular silhouette fit the ruled calendar at small sizes? |

These are alternatives to compare, not three characters to ship.

## Placement and controls

Begin with an empty-state illustration or a Settings preview. Avoid the header's month button, previous/next targets, weekday band, all 42 day positions, overflow badges, and bottom controls. On narrow screens or at large text sizes, the decoration can disappear before functional content shrinks.

Propose a simple opt-in preference with Off and Static before adding Animated. An animated mode should remain static under Reduce Motion and pause when its view is not visible. A decorative image is hidden from accessibility; an interactive pet needs a meaningful label and a 44pt target. Tapping it must not intercept calendar gestures.

## First prototype

1. Draw one neutral silhouette at its intended display size and test it on light/dark paper.
2. Place it in an empty-state mockup with the normal add action still prominent.
3. Compare the mockup with the same layout without a pet.
4. Only if the static version helps, try one optional tap response from [animations.md](animations.md).

**Adopt when:** participants can still find Today, change months, add an expense, and read a busy day as easily as before. Ask whether the companion feels pleasant or distracting without suggesting a preferred answer. Check that there are no spending judgments, urgency cues, streaks, notifications, or care obligations.

## Implementation boundaries for a future plan

Keep presentation state separate from `CalendarViewModel`, expense recurrence, budget calculations, and persisted calendar style. Decide whether the preference is local or synchronized before adding storage; old settings must decode safely. Bundle any accepted art locally with its source and usage rights documented.

Start without widgets. If a later widget companion is considered, use a static image and assess whether it displaces useful expense information. The calendar remains fully functional with the feature disabled or all companion assets removed.
