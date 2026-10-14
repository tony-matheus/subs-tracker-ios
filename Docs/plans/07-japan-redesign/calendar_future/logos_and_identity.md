# Future logos and visual identity

There are two separate design questions: the expense logos that help users recognize services, and Satoru's own app identity. [calendar.md](../calendar.md) already owns square seals in Default/Large, Compact dots with inline right-side overflow, indicator sizes, and the maximum 20% overlap. It preserves `LogoCircle(glass:)` for other callers. Those requirements are not deferred.

## Next: improve recognition at calendar sizes

Create a contact sheet of existing assets and user logo modes at the calendar's 18pt Default and initial 23pt Large seal sizes. Include wide wordmarks, thin strokes, pale symbols, dark symbols, two-letter initials, emoji, and cropped user photos. Review them on light and dark paper with the broken square border, both separated and at the permitted 20% overlap.

| Problem to investigate | Small experiment | Adoption criterion |
|---|---|---|
| Wide wordmarks become unreadable | Adjust per-asset optical inset or choose an existing compact mark | Better recognition without replacing the user's chosen logo. |
| Pale artwork disappears against paper | Compare a restrained contrast treatment for catalog defaults | Improved separation in both appearances; custom foreground/background choices stay intact. |
| Initials are ambiguous | Compare initials with an existing symbol in the logo picker preview | Users can identify the expense at 18pt; the full name remains in the day sheet and accessibility label. |
| Overlapping logos resemble one service | Tune optical spacing within the existing cell capacity | Two services and the overflow count remain distinguishable at 50pt cell width. |

Use deterministic bundled artwork; calendar viewing should not fetch logo images. Do not recolor third-party marks to the app's shu/ink palette or overwrite user photos/customizations as part of a visual refresh. Any added catalog artwork needs its source and permitted use recorded.

**Likely touchpoints:** `Core/Components/LogoCircle.swift`, `Core/Models/LogoCustomization.swift`, the asset catalog, and the logo picker. Keep changes to user data separate from calendar styling and preserve existing callers' `glass` default.

## Play: explore Satoru's own mark

The wider redesign already raises the app-icon question in [research_results_and_future_points.md](../research_results_and_future_points.md). Coordinate with the foundation/brand work; this calendar implementation does not replace `Resources/AppIcon.icon` or the app icon set.

| Direction | Sketch brief | Main risk to evaluate |
|---|---|---|
| Torii | One gently curved top beam and two clear posts, using the established motif proportions | May look like a place or travel app without context. |
| Open brush mark | A compact open stroke related to the calendar's ensō | May blur the distinction between app identity and the today indicator. |
| Crow | A simple silhouette consistent with the companion exploration | Fine features may disappear at small icon sizes. |
| Ruled calendar | A month-sheet outline with one distinctive ink/ shu detail | May become a generic calendar icon rather than a recognizable identity. |

Start with monochrome vector sketches, then test shu/ink/paper applications. Keep typography and small decorative details out of the smallest mark. The icon can express the app's personality without adding extra filled accent shapes inside the calendar screen.

**Review deliverable:** a side-by-side sheet with each candidate at small icon size, normal app-icon size, light/dark surroundings, and the platform's supported alternate appearances at implementation time. Compare recognition, silhouette, consistency with the calendar, and distinction from service logos. Verify current platform asset requirements when preparing production files.

**Adopt when:** one direction remains legible and identifiable at small sizes, works with the chosen mascot policy, and has editable source art plus documented rights. Ship an app-wide identity change through a dedicated plan, including icon assets and other brand placements together.

## Keep identity separate from financial meaning

The today marker identifies a date; an expense logo identifies a service; a pet adds optional personality; the app mark identifies Satoru. Do not reuse a decorative mascot pose or logo color as the sole indication of an expense, budget state, selection, or error.
