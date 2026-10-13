# Modern Japan redesign: context summary

A short version of the planning conversation. Full details are in the other docs in this folder. Start with `research_results_and_future_points.md`.

## Why
The app used a metal-grey gradient background, green (#1DB954) and purple accents, SF Compact Rounded, and a Metal "water ripple" effect on the price. It no longer fits. The new direction is **modern Japan**: straight lines with subtle curves, a Japanese palette and Fragment Mono, while keeping Liquid Glass.

## References
- **Main:** torii gate ("Japanese portal"), Japanese notebooks, Japanese wall calendars.
- **Secondary:** brushes (sumi-e, ensō), old washi paper, drawing.
- **Calendar reference photo:** [notesofnomads.com/japanese-date-system](https://notesofnomads.com/japanese-date-system/). It shows:
  - the giant red month numeral, with the era year on the left and the traditional month name on the right
  - mini previous and next months in the top corners
  - a black weekday band
  - heavy day numerals with holiday names in red
  - dotted memo lines in each cell

## Decisions made with the user
- **Torii:** straight posts with one gently curved top beam, used for headers, dividers and section markers.
- **Weekday labels:** English (Fragment Mono) plus small kanji (日 月 火 水 木 金 土, Hiragino Mincho).
- **Calendar cells:** the lower "memo" area holds expenses. **Every expense element shown today stays.** Variations come after v1.
- **Today marker:** an open, imperfect brush circle (ensō) in red.
- **Liquid Glass:** on controls and navigation only (toolbars, sheets, floating buttons, pickers, menus). Content cards become flat paper with hairline rules.
- **Ripple shader:** removed everywhere except the onboarding heroes, which are left for later.
- **Budget red conflict:** red is now the brand colour, so the docs propose options. Recommended:
  - ink by default
  - a gold underline when nearing the budget
  - a red **赤字 / OVER seal stamp** when over (Japanese accounting: 黒字 means black ink, profit; 赤字 means red ink, deficit)

## Canonical palette (`Core/Utils/AppTheme.swift`)
| Token | Dark (lacquer) | Light (washi) | Use |
|---|---|---|---|
| `paper` | #0E0C0B | #F8F4E6 | background (flat) |
| `paperRaised` | #1C1816 | #FFFFFC | cards |
| `ink` / `inkSecondary` | #F4EFE6 / #A8A096 | #1E1A17 / #6B635C | text |
| `rule` / `ruleStrong` | #3A332E / #746B63 | #E2DCCF / #8C8378 | hairlines |
| `shu` / `shuPressed` | #E84A33 / #C23B26 | #C1352A / #9E2A1E | brand red |
| `kin` / `kinText` | #D4A72C / #E6B422 | #C9A13B / #8A6B1F | gold accents / gold text |
| `beni` | #EE5A62 | #A22041 | destructive |
| `ai` | #6F93D6 | #1E50A2 | Saturday |

Colour rules:
- Proportions: 70% background, 25% ink, 5% accent.
- At most one filled red shape per screen.
- Gold is only ever a line or a fleck, never a fill.
- Prices are ink.
- User category and logo colours are untouched; they appear only on icons and dots.

## Typography, shapes, motion
- **Fragment Mono ships Regular and Italic only, with no Japanese glyphs.**
  - Hierarchy comes from size, case, letter-spacing and colour. Bold does nothing.
  - Kanji use the system Hiragino font.
  - The font must be registered in both the app and the widget targets.
- **Corner radius:** 0 for grids and rows, 4 for cards and chips. Capsules only appear where the system draws glass.
- **Motion:**
  - no ripple, bounce, glow or metal
  - brush-like draw-on and ink reveals, about 0.55–0.7s ease-out
  - everything respects Reduce Motion

## Feature summaries
- **Forms:** minimal changes. Remove every background colour change; colour stays only on icons. Retire the legacy `ExpenseFormView` (recommended).
- **Price display:** the amount reveals per glyph like ink (`InkReveal`) and gets a gold brush underline. All ripple, glow and bounce are removed. Every amount goes through `MoneyFormatter`, which fixes the hardcoded "CAD" bug.
- **List view:** pages like a Japanese notebook:
  - 44pt ruled lines
  - a red margin line
  - date headers such as "12 MON 月"
  - a category dot on each row
- **Charts:** ink bars with a red current period and a gold average line. Square ends, notebook grid, seal-stamp markers, mon-coin restyle.
- **Home screen** (decluttered, modelled on Apple Calendar):
  - **Top-left:** year button that opens a 12-month grid.
  - **Month:** moves into the calendar header, not the toolbar.
  - **Top-right:** view menu (Calendar/List, Stats, Settings) and Search.
  - **Bottom:** **Today** (always visible), **Filter** (with an active-filter badge), red **+**.
  - **Stats:** opened by tapping the total.
  - **Removed:** the old top-left filter pill, the bottom-left stats ring, and the Add/Today swap button.

## Status and order
- **Foundation:** `general_app_ui.md` is already implemented in the working tree, uncommitted. Git HEAD 6d7c109 is the pre-redesign code.
- **Feature docs:** describe the current working tree. Steps the foundation already did are marked "already done (verify)".
- **Order:** general UI (done) → charts → price display → forms / calendar → list view → home screen (the final Home layout lands last).

## Open decisions for the user
- Price tap: keep tap-the-total → Stats, or remove the tap too?
- Saturday colour: blue (`ai`) or monochrome?
- Seal stamp text: 赤字, OVER, or both?
- Japanese holidays: shown to everyone, only Japan-region users, or behind a setting?
- Should the new `.koyomi` calendar style become the default for existing users who never picked one?
- Remap existing users' category colours, or apply the new palette to new installs only?
- The 2027 holiday and 二十四節気 data need checking against the Cabinet Office list.
