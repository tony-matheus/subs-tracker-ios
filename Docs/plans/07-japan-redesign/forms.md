# Forms — minimal, color only on icons

## Goal
- **User brief (quote):** "keep the changes minimalist, mainly focusing on removing the background color change and keep the colors only for the Icon itself."
- **What that means here:**
  - No form screen, card, chip, cell or button changes its background color because of the logo, the category or a state. Pages are flat `paper`. Cards are `paperRaised` with a hairline.
  - Color is allowed in exactly three places:
    1. the logo itself (`LogoCircle`, user and brand colors untouched)
    2. SF Symbol icons (row icons, the mic, the trash glyph, the error triangle)
    3. one filled `shu` primary CTA per screen
  - Light Japanese touches only: 4pt radius on fields and cards, hairline rules between rows (notebook ruling), Fragment Mono uppercase tracked section labels with the existing shu hashira tick, and a writing line under the name and the amount.
- **Out of scope:** new form features, layout reflow, validation logic, persistence.
- **Depends on:** `general_app_ui.md`. It is **already implemented in the working tree** (uncommitted). It provides:
  - tokens `paper`, `paperRaised`, `ink`, `inkSecondary`, `rule`, `ruleStrong`, `shu`, `shuPressed`, `kin`, `kinText`, `beni`, `ai` (`LinguicaSubTracker/Core/Utils/AppTheme.swift:52-63`)
  - `AppRadius.card` = 4 and `AppRadius.grid` = 0 (`AppTheme.swift:72-75`); `AppFont.mono` (`AppTheme.swift:66-70`)
  - `.appBackground()` = flat `paper` (`AppTheme.swift:77-88`)
  - `AccentColor.colorset` = shu (light #C1352A, dark #E84A33)
  - `GlassSection` as a paper card (`LinguicaSubTracker/Core/UI/Containers/GlassSection.swift:7,18-19`)
  - `Hashira`, `SectionLabel`, `Rule` in `LinguicaSubTracker/Core/UI/Motifs/Torii.swift:29-69`
  - the `AppButton` color mapping (`LinguicaSubTracker/Core/UI/Buttons/AppButton.swift:191-223`)
  - Fragment Mono through `.typography()`; `AppTypography.Style` has no `weight` any more (`LinguicaSubTracker/Core/Utils/Typography.swift:4-27`)
- **Optional:** `list_view.md` adds `CategoryMark(name:)` in `LinguicaSubTracker/Core/UI/Containers/Notebook.swift` (new). Reuse it if it exists; otherwise use the inline square-dot spec below. Both render the same thing.
- **Pointers into other docs:**
  - `price_display.md`: `NumKeyPadAmountDisplay`, the freeform `MoneyDisplay`, every hardcoded `"CAD"`
  - `list_view.md`: `CategoryMark`, the `LogoCircle` `glass:` param
  - `charts.md`: the `BudgetEditor` progress bar and budget colors
- **References:**
  - [HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials): no glass in the content layer; form fields are opaque paper
  - [HIG Color](https://developer.apple.com/design/human-interface-guidelines/color): color on glass only for the primary action; toolbar symbols monochrome
  - [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
  - [WCAG 1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color)
  - [Applying custom fonts](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text): SwiftUI does not synthesize bold
  - [Kokuyo Campus Basic](https://www.kokuyo.com/en/stationery/series/campus/campus-notebook/basic): notebook rulings
  - [Japan House LA on 間 ma](https://japanhousela.com/articles/a-perspective-on-the-japanese-concept-of-ma)

## Current state
All line numbers are from the current working tree (foundation already applied).

**Entry points**
- **Main add/edit form:** `SimplifiedAddExpenseView`.
  - Opened from `LinguicaSubTracker/Features/Home/Views/HomeView.swift:141` and `:171`, and from `LinguicaSubTracker/Features/ExpensesInDay/Views/ExpensesInDay.swift:52`.
  - Opened for editing from `LinguicaSubTracker/Features/Expense/Views/ExpenseSummarySheet.swift:52`.
- **Legacy form:** `ExpenseFormView`.
  - Only reached from `LinguicaSubTracker/Features/Expense/Views/ExpenseTemplateSheet.swift:115-130` (two `.navigationDestination(item:)`).
  - That hub is only opened from `LinguicaSubTracker/Features/Search/Views/SearchView.swift:82-88`.
  - It uses the same `ExpenseFormViewModel` as the Simplified form, with an older layout.

**Page backgrounds driven by the logo color (the main problem)**
- `LinguicaSubTracker/Features/Expense/SimplifiedAddExpense/Views/SimplifiedAddExpenseView.swift:49-54` draws a full-page `LinearGradient([vm.backgroundBase, vm.backgroundShade])`. The values come from `LinguicaSubTracker/Features/Expense/SimplifiedAddExpense/ViewModels/SimplifiedAddExpenseViewModel.swift:61-71`:
  - `accent = backgroundBase.contrastingForeground` (`:65`)
  - `backgroundBase = form.themePrimary.mix(with: .black, by: 0.35)` (`:69`)
  - `backgroundShade` = same with `by: 0.7` (`:71`)
- `vm.accent` then tints the page:
  - `.tint(vm.accent)` on the `NavigationStack` (`:166`)
  - section titles `titleColor: vm.accent.opacity(0.85)` (`:71`, `:91`, `:102`, `:115`)
  - the `accent:` / `tint:` params (`:64`, `:95`, `:111`, `:121`)
- `LinguicaSubTracker/Features/Expense/Views/ExpenseFormView.swift:309-314` draws `themePrimary` → `themePrimary.darker(by: 0.35)`. Colors come from `LinguicaSubTracker/Features/Expense/ViewModels/ExpenseFormViewModel.swift:111` (`themePrimary`) and `:114` (`themeAccent`). `themeAccent` is used at `ExpenseFormView.swift:31`, `:50`, `:70`, `:92`, `:124`, `:174`, `:181-294`. `ExpenseFormViewModel.swift:108` `themeColor` is unused.

**Shared building blocks (foundation already changed these)**
- `LinguicaSubTracker/Core/UI/Containers/FormRow.swift`: `iconColor` and `labelColor` both default to `.inkSecondary` (`:6-7`, `:13-14`); content is forced `Color.ink` (`:35`); `.frame(minHeight: 44)` (`:37`). Call sites in `CategorizationSection` and `MoreDetailsSection` still pass `labelColor: tint`.
- `LinguicaSubTracker/Core/UI/Containers/LabeledSection.swift`: renders `SectionLabel(title, color: titleColor)` (`:22`) above a `GlassSection`. `SectionLabel` = 3×12pt shu `Hashira` + `.typography(.labelLarge)` (12pt, uppercase, +1.2) in `inkSecondary` (`Torii.swift:36-55`). Also used by `LinguicaSubTracker/Features/Settings/Views/Components/BudgetDetailsSheet.swift:132,167`.
- `GlassSection`: `paperRaised` + 1pt `rule` stroke, radius `AppRadius.card`.
- `Rule` (`Torii.swift:57-69`): `Rule(color: .rule, thickness: nil → 1/displayScale)`; this is the hairline the foundation uses instead of `Divider()`.
- Section components with a `tint`/`accent` param that colors icon, label and value alike:
  - `.../SimplifiedAddExpense/Views/Components/CategorizationSection.swift:15`
  - `.../MoreDetailsSection.swift:11`
  - `.../LogoHeaderSection.swift:11`
  - `.../PopularServicesRow.swift:9`
- **Errors are hue only:**
  - red text: `SimplifiedAddExpenseView.swift:80-85`, `LogoHeaderSection.swift:35-39`, `ExpenseTemplateSheet.swift:378-383`
  - red amount digits: `.../Components/AmountField.swift:16`
  - red stroke: `ExpenseFormView.swift:104-107`

**CTAs**
- **Create mode:** toolbar `Add` is `.glassProminent` with no tint, so it takes `vm.accent` (`SimplifiedAddExpenseView.swift:233-236`). Bottom "Create and add another" is `AppButton(style: .neutral, appearance: .solid)` (`:133-149`), which the foundation now maps to an **ink**-tinted glass chip with a paper label (`AppButton.swift:195`). That is a second filled shape.
- **Edit mode:** toolbar trash is `.glassProminent.tint(.red)` (`:225-231`), plus the ink `Save` chip: two filled shapes.

**Fonts**
- `.typography()` (`LinguicaSubTracker/Core/Utils/Theme.swift:64-66`) is Fragment Mono. All `.typography(x.weight(...))` calls were removed by the foundation; weight is no longer a selection cue anywhere.
- `general_app_ui.md` assigns these stray system fonts on `Text` to **this doc**: `ExpenseSummarySheet.swift:87,131,137,169,178,186,196,211,223`. (`:89` and `:156` are on SF Symbols and stay `.system`.)
- `NumKeyPadAmountDisplay` fonts (`NumKeyPadSheet.swift:232,242,251,257`) belong to `price_display.md`.

**Foundation interim state to replace here:** `ExpenseTemplateSheet.swift:428-432` hold button is now a solid `Color.shu` fill, r24, paper text, `scaleEffect(1.02)` while recording.

## Target design
### Principles (apply to every file below)
1. **Background:** pages use `.appBackground()` (flat `paper`). Cards use `GlassSection`. Never derive a fill from `LogoCustomization`, a category, a list or a state.
2. **Text:** labels and typed values `ink`; placeholders and secondary text `inkSecondary`; prices always `ink`, including in error. Menu-picker values keep `AppPicker`'s default tint (`AppPicker.swift:27`).
3. **Color lives on icons only:**
   - row icons default to `inkSecondary` (already the `FormRow` default)
   - the **Category** row icon takes the category's `colorHex`; the **List** row icon takes the list's `colorHex`
   - meaning-carrying icons use a token: mic `shu`, trash `beni`, error triangle `beni`
   - the logo keeps all its colors
4. **Selection:** a checkmark in `ink` (same as the foundation's Settings checkmarks) or a 1pt `ink` stroke. Never a fill, never a weight change.
5. **Chips become a square dot plus text:** `CategoryMark(name:)` if it exists, else `HStack(spacing: 4) { Rectangle().fill(color).frame(width: 6, height: 6).accessibilityHidden(true); Text(name) }`. Radius 0, no capsule, no fill. Text `ink`.
6. **Fields:** radius `AppRadius.card`. Stand-alone tappable fields (amount pills, search) get a 1pt `ruleStrong` stroke and no fill (`ruleStrong` passes 3:1 on both papers; `rule` is decorative only). Fields inside a card rely on the card.
7. **Rows:** keep the 44pt `FormRow` pitch. Separate rows with `Rule()`.
8. **Section labels:** `LabeledSection` / `SectionLabel` as they are (hashira + `labelLarge`). Inside custom cards use `.typography(.labelMedium).foregroundStyle(Color.inkSecondary)` (11pt, uppercase, +1.2) without a hashira.
9. **CTAs:**
   - primary: toolbar `.buttonStyle(.glassProminent)` with no tint (AccentColor = shu) and a `Color.paper` label, or `AppButton(style: .primary, appearance: .solid)`
   - secondary: `AppButton(style: .primary, appearance: .glassy)` = untinted glass, `ink` text, `shu` icon (`AppButton.swift:200-211`)
   - destructive: untinted `.glass` with a `beni` glyph; `AppButton(style: .destructive)` default `.glassy` already renders `ink` text + `beni` icon
   - at most **one** filled shu shape per screen; forms stop using `.neutral .solid`
10. **Errors (never hue alone):** the writing line under the field turns `beni`, and `FormErrorLabel` (new) shows a `beni` `exclamationmark.triangle.fill` plus the message in `ink`. Prices stay `ink`.
11. **Motion:** no bounce or scale on press; selection/value springs become `.easeOut(duration: 0.2)` or nil under `accessibilityReduceMotion`; symbol effects gated on `accessibilityReduceMotion`; no ripple or `layerEffect` (it renders glass and materials black).

### Add-expense form: before and after (light)
```
BEFORE (create mode)
┌───────────────────────────────────┐
│░Cancel                      (Add)░│  <- (Add) = .glassProminent tinted vm.accent
│░           ╭──────╮              ░│
│░           │ LOGO │              ░│
│░           ╰──────╯              ░│
│░          Netflix                ░│  <- name in vm.accent
│░Amount                           ░│  <- title vm.accent.opacity(0.85)
│░╭───────────────────────────────╮░│
│░│            $15.99             │░│
│░╰───────────────────────────────╯░│
│░Categorization                   ░│
│░╭───────────────────────────────╮░│
│░│# Type            Subscription │░│  <- icon + label + picker in vm.accent
│░│───────────────────────────────│░│
│░│# Category       Entertainment │░│
│░╰───────────────────────────────╯░│
│░[+] Create and add another       ░│  <- .neutral .solid (ink chip)
└───────────────────────────────────┘
░ = full-page LinearGradient from the logo color (backgroundBase -> backgroundShade)

AFTER (create mode)
┌───────────────────────────────────┐
│ Cancel                      [Add] │  <- .glassProminent shu, paper label: the one filled shu
│            ╭──────╮               │
│            │ LOGO │               │  <- logo keeps its own colors
│            ╰──────╯               │
│           Netflix                 │  <- ink
│        ───────────────            │  <- writing line Rule(ruleStrong, 1pt); beni on error
│ ▌AMOUNT                           │  <- SectionLabel: Hashira 3x12 shu + labelLarge UPPER, inkSecondary
│ ┌───────────────────────────────┐ │  <- GlassSection: paperRaised, r4, 1pt rule
│ │            $15.99             │ │  <- ink, always
│ │          ──────────           │ │
│ └───────────────────────────────┘ │
│ ▌CATEGORIZATION                   │
│ ┌───────────────────────────────┐ │
│ │#  Type          Subscription ▾│ │  <- icon inkSecondary, label ink
│ │───────────────────────────────│ │  <- Rule() hairline, 44pt rows
│ │■  Category     Entertainment ▾│ │  <- ■ = folder.fill in the category colorHex
│ │───────────────────────────────│ │
│ │■  List              Personal ▾│ │  <- ■ = list.dash in the list colorHex
│ └───────────────────────────────┘ │
│ ┌───────────────────────────────┐ │  <- .primary .glassy: untinted glass r4
│ │ +  Create and add another     │ │  <- ink text, shu icon
│ └───────────────────────────────┘ │
└───────────────────────────────────┘
(Fill from popular services and More details follow the same card + Rule pattern.)
```
**Edit mode (after):** toolbar trailing = trash, `.buttonStyle(.glass)`, glyph `beni`. Bottom = `Save`, `AppButton(style: .primary, appearance: .solid)`: the screen's only filled shu.

**Error state (after):**
```
│            (empty)                │
│        ───────────────            │ <- writing line turns beni
│   [!] Give it a name first        │ <- [!] exclamationmark.triangle.fill beni, text ink
```

### Light and dark specifics
| Element | Light (washi) | Dark (lacquer) |
|---|---|---|
| Page | `paper` #F8F4E6 | `paper` #0E0C0B |
| Card | `paperRaised` #FFFFFC + `rule` #E2DCCF hairline | `paperRaised` #1C1816 + `rule` #3A332E hairline |
| Labels, values, prices | `ink` #1E1A17 | `ink` #F4EFE6 |
| Section labels, row icons, placeholders | `inkSecondary` #6B635C | `inkSecondary` #A8A096 |
| Writing lines, stand-alone field strokes | `ruleStrong` #8C8378 (3.72:1 on paperRaised) | `ruleStrong` #746B63 (3.38:1) |
| Primary CTA fill / label | `shu` #C1352A / `paper` #F8F4E6 (5.0:1) | `shu` #E84A33 / `paper` #0E0C0B (5.1:1). Washi text on dark shu is only 3.5:1, which is why the label is `Color.paper`, not white |
| Shu icons (mic, secondary-CTA icon, hashira) | #C1352A | #E84A33 |
| Error icon + line, trash glyph | `beni` #A22041 | `beni` #EE5A62 |
| Selection stroke / checkmark | `ink`, 1pt | `ink`, 1pt |
| Logo, category, list colors | unchanged (user data) | unchanged |

### Every background-color-change site and its new treatment
"Done" = already done by the foundation pass; verify only.

| # | path:line | Today | Color source | New treatment |
|---|---|---|---|---|
| 1 | `SimplifiedAddExpenseView.swift:49-54` | full-page gradient following the logo | `backgroundBase`/`backgroundShade` (`SimplifiedAddExpenseViewModel.swift:69,71`) | delete; `.appBackground()` on the `ZStack` |
| 2 | `SimplifiedAddExpenseView.swift:166` | `.tint(vm.accent)` recolors toolbar, pickers, date pickers | `accent` (`:65`) | delete; AccentColor (shu) applies |
| 3 | `ExpenseFormView.swift:309-314`, `:31` | same gradient + tint | `themePrimary`/`themeAccent` (`ExpenseFormViewModel.swift:111,114`) | delete the file (step 9); fallback 9b |
| 4 | `ExpenseFormView.swift:139-164` | category chip: capsule filled with the category color when selected, `color.opacity(0.14)` + 0.55 stroke otherwise | `category.colorHex` | gone with the file; fallback: square dot + text, selection = 1pt `ink` underline |
| 5 | `ExpenseFormView.swift:103-107` | amount button `.ultraThinMaterial` r24, red stroke on error | material + `.red` | gone with the file; fallback = `AmountField` spec |
| 6 | `ExpenseTemplateSheet.swift:304-318` | `categoryChipMenu` label `Capsule().fill(color)` + `contrastingForeground` text | category `colorHex` | square dot + `ink` text + `chevron.up.chevron.down` `inkSecondary`; no fill. Fallback color `:322` `Color.gray` → `Color.inkSecondary` |
| 7 | `ExpenseTemplateSheet.swift:424-432` (`holdButton`) | solid `Color.shu` r24, paper text, `scaleEffect(1.02)` | foundation interim | untinted glass r4 + 1pt `ruleStrong`, `ink` text, mic/waveform `shu`, no scale (spec below) |
| 8 | `ExpenseTemplateSheet.swift:469-470` (`AddOptionCard`) | `tint.gradient` or `gray.opacity(0.15)`, `.cornerRadius(20)` | `tint` (`:454`) is never passed: dead | delete `tint` (`:454`), the `tint != nil` line (`:477`) and the doc-comment sentence (`:443-444`); `foreground` (`:476-479`) becomes `isEnabled ? Color.ink : Color.inkSecondary`; background `paperRaised` r4 + 1pt `rule` |
| 9 | `ExpenseTemplateSheet.swift:498` | "Coming soon" `Capsule().fill(Color.primary.opacity(0.08))` | neutral | no fill; 1pt `rule` stroke r4 |
| 10 | `ExpenseTemplateSheet.swift:279-287`, `BatchAddView.swift:111-118` | amount pill text `.green` when > 0, `.ultraThinMaterial` capsule | hardcoded | text `ink` (`inkSecondary` for "Amount"); no fill; 1pt `ruleStrong` stroke, `.rect(cornerRadius: AppRadius.card)` |
| 11 | `ExpenseTemplateSheet.swift:81-82` | voice "Add N" `.glassProminent.tint(Color.green.gradient)` | hardcoded | delete `.tint`; label `.foregroundStyle(Color.paper)` |
| 12 | `ExpenseTemplateSheet.swift:210` | listening waveform | — | Done: `Color.shu` (icon) |
| 13 | `LogoSheet.swift:277-301` (`symbolCell`) | selected fill `primaryColorHex` 0.35 + 2pt brand stroke; others `primary.opacity(0.06)`, r14 | `primaryColorHex` | no fill; unselected 1pt `rule`, selected 1pt `ink`, r4; glyph `ink` |
| 14 | `LogoSheet.swift:338-348` (emoji cell) | selected fill `primaryColorHex` 0.4, r10 | `primaryColorHex` | no fill; selected 1pt `ink` stroke r4 |
| 15 | `LogoSheet.swift:88-92`, `:109-112` (`LogoTabPicker`) | hardcoded green gradient on every segment icon | hardcoded | delete `gradient`; icon `shu` when selected, else `inkSecondary`; text `:117` `ink`/`inkSecondary`. The glass highlight is Done (`CustomSegmentedPicker.swift:37-44`) |
| 16 | `LogoSheet.swift:315-323` | emoji search `Color.primary.opacity(0.08)` capsule | neutral | no fill; 1pt `ruleStrong`, `.rect(cornerRadius: AppRadius.card)` |
| 17 | `LogoSheet.swift:392-402` | PhotosPicker CTA `.white` fill r16, `.black` text (vanishes on washi) | hardcoded | `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))`, `ink` text, `photo.on.rectangle` `shu` |
| 18 | `LogoSheet.swift:441` | slider `.tint(Color(hex: customization.primaryColorHex))` | `primaryColorHex` | `.tint(Color.ink)`; the preview at `:38-43` already shows the color |
| 19 | `LogoSheet.swift:211-224`, `:176-187` | swatch ring and "none" swatch use `.white` strokes/fill (invisible on washi) | hardcoded | spec below; swatch fills stay user colors |
| 20 | `ExpenseSummarySheet.swift:17-21` | blurred 130pt `LogoCircle` (`.blur(radius:50)`) = colored bloom behind the sheet | logo colors | delete the `VStack` |
| 21 | `ExpenseSummarySheet.swift:40` | `.presentationBackground(.ultraThinMaterial)` lets the calendar colors bleed in | material | `.presentationBackground(Color.paper)` |
| 22 | `ExpenseSummarySheet.swift:207-209` | category dot filled with `vm.themeColor` = the **logo** background (wrong source) | `ExpenseSummaryViewModel.swift:34` | square dot in the category `colorHex` |
| 23 | `ExpenseSummarySheet.swift:83-85` | status dot `.green`/`.gray` | hardcoded | 8×8 `Rectangle`: `ink` fill when active; no fill + 1pt `ruleStrong` when inactive. The word carries the meaning |
| 24 | `ExpenseSummarySheet.swift:104` | pencil `.tint(.green)` | hardcoded | delete; glyph `.foregroundStyle(Color.ink)` |
| 25 | `ExpenseSummarySheet.swift:373-377` (`QuickPickSheet`) | selected row `primary.opacity(0.08)` r14 | neutral | delete the fill; `contentShape(Rectangle())`; checkmark `ink` |
| 26 | `LogoHeaderSection.swift:64` | lock badge `.ultraThinMaterial` circle | material | `.background(Color.paperRaised, in: Circle()).overlay(Circle().strokeBorder(Color.rule))`; glyph `inkSecondary` |
| 27 | `SubscriptionCatalogView.swift:46-50`, `:90-93` | tiles `gray.opacity(0.15)` r20, `.white/.black` text; empty CTA `primary.opacity(0.08)` r24 | neutral | `paperRaised` r4 + 1pt `rule`; text `ink`; empty-CTA icon (`:73-75`) `shu` |
| 28 | `AppButton.swift:191-198` | `.neutral .solid` = ink glass chip | foundation | forms move off it: `SimplifiedAddExpenseView.swift:136-137`, `NumKeyPadSheet.swift:69-70`, `ExpenseSummarySheet.swift:308-309` |
| 29 | `CalendarStyleSheet.swift:70-78` | row | — | Done: constant `paperRaised` r4, stroke `ink` when selected else `rule`; checkmark `ink` (`:63-68`) |
| 30 | `BudgetEditor.swift:45-68` "Clear?" | — | — | Done: untinted rect glass, `beni` glyph, `ink` label |
| 31 | `RowModeToolbar.swift:32-67` | — | — | Done: tints removed, `:66` `beni` + "Delete selected" label |
| 32 | `ListsSheet.swift:70-72`, `CategoriesSheet.swift:78-80`, `PaymentMethodsSheet.swift:61-63` | checkmarks | — | Done: `ink` |

**Derived text colors that become ink tokens (not backgrounds):**
| Site | Today | New |
|---|---|---|
| `LogoHeaderSection.swift:49` name field | `accent` | `ink` |
| `LogoHeaderSection.swift:62` lock glyph | `accent` | `inkSecondary` |
| `SimplifiedAddExpenseView.swift:71,91,102,115` section titles | `vm.accent.opacity(0.85)` | `LabeledSection` default (`inkSecondary`) |
| `PopularServicesRow.swift:18,34,41` icons | `accent` | `inkSecondary` |
| `PopularServicesRow.swift:23` "Choose a service" | `accent` | `inkSecondary` (a chosen name stays `ink`) |
| `CategorizationSection.swift:23,42,59,76` labels | `tint` | `ink` (new `FormRow` default) |
| `CategorizationSection.swift:22,41,58,75` icons | `tint` | `inkSecondary`; Category and List take the data color |
| `CategorizationSection.swift:31,48,65,82` picker values | `tint` | `AppPicker` default |
| `MoreDetailsSection.swift:19,33,77` labels, `:100` Notes | `tint` | `ink` |
| `MoreDetailsSection.swift:18,32,76,96` icons | `tint` | `inkSecondary` |
| `MoreDetailsSection.swift:24,48` DatePicker `.tint`, `:85` picker `tint:` | `tint` | delete |
| `MoreDetailsSection.swift:67` "Set End Date" | `tint` | `inkSecondary` |

### Component specs
**`FormErrorLabel` (new)**, `LinguicaSubTracker/Core/UI/Containers/FormErrorLabel.swift`:
```swift
struct FormErrorLabel: View {
    let message: String
    var body: some View {
        Label {
            Text(message).typography(.bodySmall).foregroundStyle(Color.ink)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .iconStyle(size: 12, weight: .semibold, color: .beni)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}
```

**Writing line** (name and amount): `Rule(color: hasError ? .beni : .ruleStrong, thickness: 1).frame(width: W)` placed 4pt below the text. `W` = 220 under the name, 180 under the amount (fits "$99,999.99", the keypad max, at 28pt mono).

**LogoSheet swatch** (replaces `colorSwatch` body `LogoSheet.swift:213-223`; mirror it on the "none" swatch `:177-187` with a clear fill):
```swift
Circle().fill(Color(hex: hex)).frame(width: 36, height: 36)
    .overlay(Circle().strokeBorder(Color.rule, lineWidth: 1))
    .padding(3)
    .overlay(Circle().strokeBorder(selected ? Color.ink : .clear, lineWidth: 2))
```

**Hold & Speak button** (body of `ExpenseTemplateSheet.swift:408-439`; the gesture and hit-testing lines stay):
```
┌──────────────────────────────────────┐
│        (mic.fill)  Hold & Speak      │  76pt, untinted glass r4 + 1pt ruleStrong; mic shu, text ink
└──────────────────────────────────────┘
recording:  (waveform, variableColor) Release to add   same surface, no scale
processing: ProgressView (inkSecondary)  Adding…
```
```swift
HStack(spacing: 10) {
    if voice.isProcessing {
        ProgressView().tint(Color.inkSecondary)
        Text("Adding…")
    } else {
        Image(systemName: voice.isRecording ? "waveform" : "mic.fill")
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(Color.shu)
            .symbolEffect(.variableColor.iterative, isActive: voice.isRecording && !reduceMotion)
        Text(voice.isRecording ? "Release to add" : "Hold & Speak")
    }
}
.typography(.titleMedium)
.foregroundStyle(Color.ink)          // the Image overrides with shu
.frame(maxWidth: .infinity).frame(height: 76)
.contentShape(.rect(cornerRadius: AppRadius.card))
.glassEffect(.regular, in: .rect(cornerRadius: AppRadius.card)) // no .interactive(): the DragGesture owns the press
.overlay(RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(Color.ruleStrong))
// keep .gesture(DragGesture…) and .allowsHitTesting(!voice.isProcessing) exactly as today
```
Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to `ExpenseTemplateSheet`. Also gate the waveform at `:211` with `isActive: !reduceMotion`.

**Keypad** (`LinguicaSubTracker/Core/Components/NumKeyPadSheet.swift`):
```
│ CAD ($) v                         x │
│               AMOUNT                │ <- labelMedium, inkSecondary
│              $ 15.99                │ <- NumKeyPadAmountDisplay: price_display.md
│ ┌────────┐  ┌────────┐  ┌────────┐  │ <- paperRaised r4 + 1pt rule, 64pt
│ │   1    │  │   2    │  │   3    │  │    headlineMedium (Fragment Mono 22), ink
│ └────────┘  └────────┘  └────────┘  │
│   ... 4-9 ...                       │
│     C       ┌────────┐   delete.left│ <- utility keys: no fill, inkSecondary
│             │   0    │              │
│ [############## Done ##############]│ <- AppButton .primary .solid (shu)
```
```swift
// KeypadButton.body label
Group {
    if case .backspace = key { Image(systemName: "delete.left").font(.system(size: 20)) }
    else { Text(key.label) }
}
.typography(.headlineMedium)
.foregroundStyle(isUtility ? Color.inkSecondary : Color.ink)
.frame(maxWidth: .infinity).frame(height: 64)
.background(isUtility ? Color.clear : Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))
.overlay { if !isUtility { RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(Color.rule) } }
.accessibilityLabel(a11yLabel)   // "Delete digit", "Clear", "Decimal point", or the digit
```
- `⌫` (U+232B, `:286`) is replaced by the `delete.left` symbol: Fragment Mono covers only GF Latin Plus, so the glyph would fall back.
- `KeypadButtonStyle`: replace the scale + spring (`:324-328`) with `.opacity(configuration.isPressed ? 0.55 : 1).animation(.easeOut(duration: 0.1), value: configuration.isPressed)`. Keep the haptic (`:329-333`).

## Implementation steps
1. **Precondition (foundation).** Verify, do not redo:
   - `grep -n "static let shu\|static let paperRaised\|static let beni" LinguicaSubTracker/Core/Utils/AppTheme.swift` returns 3 hits.
   - `LinguicaSubTracker/Core/UI/Motifs/Torii.swift` defines `SectionLabel` and `Rule`.
   - `GlassSection.swift:18-19` is `paperRaised` + `rule`.
   - If any is missing, stop and implement `general_app_ui.md` first.
2. **`FormErrorLabel` (new).** Create `LinguicaSubTracker/Core/UI/Containers/FormErrorLabel.swift` (spec above). The project uses `PBXFileSystemSynchronizedRootGroup`; no pbxproj edit. Do not add it to the widget target.
3. **`FormRow.swift`.**
   - Change the `labelColor` default from `.inkSecondary` to `.ink` (`:7`, `:14`).
   - Already done by the foundation pass (verify): `iconColor` default `.inkSecondary` (`:6`, `:13`), content `Color.ink` (`:35`), `minHeight: 44` (`:37`).
   - `ExpenseSummarySheet` rows (`:166-220`) pick up `ink` labels. Intended.
4. **`LabeledSection.swift`.** Already done by the foundation pass (verify): `SectionLabel` (`:22`), `inkSecondary` defaults (`:7`, `:12`), paper preview (`:31`). Only edit the preview: drop `labelColor: Color.ink` (`:36`, `:40`) and change `Divider()` (`:39`) to `Rule()`.
5. **Simplified components** (folder `LinguicaSubTracker/Features/Expense/SimplifiedAddExpense/Views/Components/`):
   - **`LogoHeaderSection.swift`:**
     - delete `accent` (`:11`)
     - name field `.foregroundStyle(Color.ink)` (`:49`)
     - in the `VStack(spacing: 4)` (`:32-40`): `nameField`, then the writing line (W 220, `beni` when `nameError != nil`), then replace `:35-39` with `if let nameError { FormErrorLabel(message: nameError) }`
     - lock badge: glyph `Color.inkSecondary` (`:62`), background per table row 26 (`:64`)
     - previews: replace the `LinearGradient`s (`:76-77`, `:93-94`) with `Color.paper.ignoresSafeArea()`; delete `accent: .white` (`:85`, `:100`)
   - **`AmountField.swift`:**
     - text always `Color.ink` (`:16`)
     - wrap the `Text` in `VStack(spacing: 4) { Text…; Rule(color: hasError ? .beni : .ruleStrong, thickness: 1).frame(width: 180) }` inside the button label
     - replace the spring (`:18`) with `.animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: amount)` and add `@Environment(\.accessibilityReduceMotion) private var reduceMotion`
     - preview: `:29` → `Color.paper`; drop `titleColor:` (`:33`, `:38`); `:41-44` → `FormErrorLabel(message: "Enter an amount above zero")`
   - **`PopularServicesRow.swift`:**
     - delete `accent` (`:9`)
     - icons `Color.inkSecondary` (`:18`, `:34`, `:41`; drop the `.opacity`)
     - `:23` → `.foregroundStyle(selectedName == nil ? Color.inkSecondary : Color.ink)`
     - preview: `:49` → `Color.paper`; drop `titleColor:` (`:53`, `:57`) and `accent:` (`:54`, `:60`)
   - **`CategorizationSection.swift`:**
     - replace `var tint` (`:15`) with `var categoryColor: Color = .inkSecondary` and `var listColor: Color = .inkSecondary`
     - delete every `iconColor: tint` and `labelColor: tint` except: Category row `iconColor: categoryColor` (`:41`), List row `iconColor: listColor` (`:58`)
     - delete every `tint: tint` passed to `AppPicker` (`:31`, `:48`, `:65`, `:82`); keep `.fixedSize` (`:33`, `:50`, `:67`, `:84`) and `.lineLimit(1)` (`:90`)
     - `Divider()` (`:36`, `:53`, `:70`) → `Rule()`
     - preview: `:101` → `Color.paper`; drop `titleColor:` (`:104`) and `tint: .white` (`:122`)
   - **`MoreDetailsSection.swift`:**
     - delete `tint` (`:11`) and every use: `iconColor:`/`labelColor:` args (`:18-19`, `:32-33`, `:76-77`), `.tint(tint)` (`:24`, `:48`), `tint: tint` (`:85`)
     - `:67` → `Color.inkSecondary`; `:96` → `.iconStyle(size: 16, weight: .medium, color: .inkSecondary)`; `:100` → `Color.ink`
     - `Divider()` (`:27`, `:71`) → `Rule()`; `:91` → `Rule().padding(.bottom, 8)`
     - preview: `:120` → `Color.paper`; drop `titleColor:` (`:124`) and `tint: .white` (`:130`)
6. **`ExpenseFormViewModel.swift`.** Add after `listOptions` (`:171-173`). Name lookup matches how `category`/`list` are stored; a missing name falls back to `inkSecondary`:
   ```swift
   var categoryColor: Color {
       settingsStore.settings.categories.first { $0.name == category }.map { Color(hex: $0.colorHex) } ?? .inkSecondary
   }
   var listColor: Color {
       settingsStore.settings.lists.first { $0.name == list }.map { Color(hex: $0.colorHex) } ?? .inkSecondary
   }
   ```
7. **`SimplifiedAddExpenseViewModel.swift`.** Delete the `// MARK: - Theme` block (`:61-71`): `accent`, `backgroundBase`, `backgroundShade`.
8. **`SimplifiedAddExpenseView.swift`.**
   - Delete the `LinearGradient` (`:49-54`); add `.appBackground()` to the `ZStack` (after its closing brace at `:152`, before `.toolbar`).
   - Delete `accent: vm.accent` (`:64`), `accent: vm.accent` (`:95`) and every `titleColor:` arg (`:71`, `:91`, `:102`, `:115`).
   - Replace `:80-85` with `if let priceError = form.priceError { FormErrorLabel(message: priceError).padding(.horizontal, 8) }`.
   - `CategorizationSection`: replace `tint: vm.accent` (`:111`) with `categoryColor: form.categoryColor, listColor: form.listColor`. Delete `tint: vm.accent` (`:121`).
   - Bottom `AppButton` (`:133-149`): `style: .primary`, `appearance: vm.isEditMode ? .solid : .glassy`.
   - Delete `.tint(vm.accent)` (`:166`).
   - Toolbar:
     - trash (`:225-231`): `.buttonStyle(.glass)`, delete `.tint(.red)`, image `.foregroundStyle(Color.beni)`, add `.accessibilityLabel("Delete expense")`.
     - Add (`:233-236`): `Button { if viewModel.add() { dismiss() } else { revealErrors() } } label: { Text("Add").foregroundStyle(Color.paper) }` with `.buttonStyle(.glassProminent)` and no `.tint` (same pattern as `RowModeToolbar.swift:49-54`).
     - Cancel (`:219`): screenshot; only if it renders shu, add `.tint(Color.ink)` on that `Button`.
   - Replace the blank init (`:13-25`) with a template-aware one. Existing callers compile unchanged:
   ```swift
   init(date: Date, name: String = "", template: SubscriptionTemplate? = nil,
        store: AppStore, settingsStore: SettingsStore,
        onCommit: @escaping (Expense) -> Void = { _ in }) {
       let vm = SimplifiedAddExpenseViewModel(mode: .createBlank(name: name, date: date),
                                              store: store, settingsStore: settingsStore, onCommit: onCommit)
       if let template { vm.apply(template) }   // same path as its own catalog: locks the logo
       _viewModel = State(initialValue: vm)
   }
   ```
9. **Route the legacy form to Simplified (recommended).**
   - In `ExpenseTemplateSheet.swift`, delete both `.navigationDestination(item:)` (`:115-130`). Attach two sheets to the `NavigationStack` itself, next to `.sheet(isPresented: keypadBinding)` (`:138`), so they present even while the catalog is pushed:
     ```swift
     .sheet(item: $vm.selectedService) { service in
         SimplifiedAddExpenseView(date: vm.date, template: service, store: store,
                                  settingsStore: settingsStore, onCommit: { _ in dismiss() })
     }
     .sheet(item: $vm.blankRoute) { route in
         SimplifiedAddExpenseView(date: vm.date, name: route.name, store: store,
                                  settingsStore: settingsStore, onCommit: { _ in dismiss() })
     }
     ```
   - Sheets, not pushes: `SimplifiedAddExpenseView` owns a `NavigationStack` (`:47`). `SubscriptionTemplate` and `BlankRoute` are `Identifiable`.
   - Delete `LinguicaSubTracker/Features/Expense/Views/ExpenseFormView.swift` and `LinguicaSubTracker/Features/Expense/Views/Previews/ExpenseFormViewPreviewHost.swift`.
   - Delete now-dead `ExpenseFormViewModel` members (none are used by `LinguicaSubTrackerTests/ExpenseFormResetTests.swift`); rebuild after the batch:
     - `isLogoExpanded` (`:24`), `themeColor` (`:108`), `themePrimary` (`:111`), `themeAccent` (`:114`), `logoName` (`:116-122`)
     - `navigationTitle` (`:144-146`), `primaryButtonTitle` (`:148-151`)
     - `openLogoSheet`, `closeLogoSheet`, `dismissNativeKeyboard` (`:191-206`)
   - Leave `ExpenseFormMode.create(template:date:)` and `Color.contrastingForeground`/`darker(by:)` (`LinguicaSubTracker/Core/Utils/Extensions/Color.swift:52-61`, shared with the widget target).
   - **9b. If routing is rejected,** restyle `ExpenseFormView` in place with the same rules:
     - delete `:309-314` (the `.appBackground()` at `:29` and `:34` stays) and `.tint` (`:31`)
     - every `vm.themeAccent` foreground → `ink`; "Amount"/"Category" labels (`:90-92`, `:122-124`) → `.typography(.labelMedium).foregroundStyle(Color.inkSecondary)`
     - drop every `labelColor:`, `tint:`, `iconColor: vm.themeAccent` arg; `Divider()` → `Rule()`
     - `categoryChip` (`:139-164`): square-dot chip (principle 5); selected = 1pt `ink` underline `Rule(color: .ink, thickness: 1)` under the text; spring `:144` → `.easeOut(duration: 0.2)`
     - `amountButton` (`:84-116`): price `ink`; `.ultraThinMaterial` r24 → `paperRaised` r4 + 1pt `rule`; error = `beni` writing line + `FormErrorLabel` (replaces `:104-107`, `:109-113`); name error `:75-79` → `FormErrorLabel`
     - delete the material under the Done glass (`:369`) and make `:371` `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))`
     - `:376-386` → `.primary .solid`; `:389-401` → `.primary .glassy`; edit trash `:57` → `.glass` + `beni` glyph
10. **`ExpenseTemplateSheet.swift`.**
    - Table rows 6–11 and the hold-button spec.
    - `voice.errorMessage` (`:380-383`) → `FormErrorLabel(message: message).multilineTextAlignment(.center)`.
    - Keep the `voiceControls` shadow (`:401`): it is a floating control.
11. **`BatchAddView.swift:111-118`.** Amount pill per table row 10.
12. **`SubscriptionCatalogView.swift`.** Table row 27. Text `:46` → `Color.ink`; delete the now-unused `colorScheme` (`:15`).
13. **`LogoSheet.swift`.** Table rows 13–19 and the swatch spec.
    - "Remove photo" (`:410-415`): `Label("Remove photo", systemImage: "trash")`, icon `beni`, text `ink`; keep `role: .destructive`.
    - `Divider().opacity(0.3)` (`:261`) → `Rule()`.
    - Section labels (`:137-139`, `:166-168`, `:249-251`) already use `.labelMedium`; only their color changes (step 17).
14. **`NumKeyPadSheet.swift`.**
    - Done button (`:67-74`): `style: .primary, appearance: .solid`.
    - "Amount" (`:107-109`): `.typography(.labelMedium).foregroundStyle(Color.inkSecondary)`.
    - `KeypadButton` (`:305-318`) and `KeypadButtonStyle` (`:321-335`) per the keypad spec; add `private var a11yLabel: String` to `KeypadButton`.
    - Do **not** touch the cents/freeform logic (`:138-211`), `NumKeyPadAmountDisplay` (`:219-263`, `price_display.md`), the freeform display (`:114-119`, `price_display.md`) or the `.height(560)` detents at call sites.
15. **`ExpenseSummarySheet.swift`.**
    - Table rows 20–25.
    - Category dot (`:207-209`): `CategoryMark(name: vm.expense.category)` replacing the whole `HStack` (`:206-212`) if it exists (it reads `@Environment(SettingsStore.self)`, injected app-wide at `LinguicaSubTracker/App/LinguicaSubTrackerApp.swift:54`; add `.environment(settingsStore)` in `ExpenseSummarySheetPreviewHost` if the preview crashes); else `Rectangle().fill(settingsStore.settings.categories.first { $0.name == vm.expense.category }.map { Color(hex: $0.colorHex) } ?? .inkSecondary).frame(width: 6, height: 6)`.
    - Delete `ExpenseSummaryViewModel.themeColor` (`LinguicaSubTracker/Features/Expense/ViewModels/ExpenseSummaryViewModel.swift:34`).
    - `QuickNameSheet` Save (`:306-313`): `.primary .solid`.
    - `QuickPickSheet`: dot (`:358-360`) → 6×6 `Rectangle`; checkmark (`:368`) `color: .ink`; row 25.
    - Delete button (`:110-117`): keep `style: .destructive`. Already done by the foundation pass (verify): `.glassy` destructive = `ink` text, `beni` icon (`AppButton.swift:200-211,221-223`).
    - Stray fonts on `Text` (this doc owns them): `:131` → `.typography(.displaySmall)`; `:87`, `:137`, `:169`, `:186`, `:196`, `:211`, `:223` → `.typography(.titleSmall)`; `:178` → `.typography(.bodySmall)`. Leave `:89` and `:156` (SF Symbols).
    - `Divider()` (`:174`, `:182`) → `Rule()`.
    - The hardcoded `"CAD"` at `:168`, `:185` and `ExpenseSummaryViewModel.swift:50` is fixed by `price_display.md` (`MoneyFormatter`). Do not fix it here.
16. **Settings, light touch.**
    - Already done by the foundation pass (verify): table rows 29–32, `CalendarStyleSheet.swift:22-25` animation (`.smooth(duration: 0.25)`, nil under Reduce Motion), swatch strokes `Color.rule` (`CategoriesSheet.swift:121`, `ListsSheet.swift:113`).
    - `BudgetDetailsSheet.swift:148-156`: the budget warning is `.red` icon + `.red` text. Replace the `HStack` (`:148-154`) with `FormErrorLabel(message: warning)`; keep `.padding(.top, 10)` and `.transition(.opacity)` (`:155-156`).
    - Keep the color swatches as circles (`CategoriesSheet.swift:86`, `ListsSheet.swift:78`): they are pickers, not tags.
    - `BudgetEditor` progress bar and stats colors: `charts.md`.
17. **Hierarchical text styles → tokens.** System `.primary`/`.secondary` ignore the washi/lacquer palette. In the files this doc touches, `.foregroundStyle(.primary)` → `Color.ink` and `.foregroundStyle(.secondary)` → `Color.inkSecondary`:
    - `ExpenseTemplateSheet.swift:214,257,294,339,372,395,495`
    - `ExpenseSummarySheet.swift:91,138,157,297,333,364`
    - `LogoSheet.swift:139,168,190,251,289,317,329,435,438`
    - `SubscriptionCatalogView.swift:80,84` (`:75` is the empty-CTA icon: `shu`, row 27)
    - `BatchAddView.swift:87`, `MoreDetailsSection.swift:54`
    - `NumKeyPadSheet.swift:109` (step 14) and `:309` (keypad spec). Leave `:233`, `:252` (`NumKeyPadAmountDisplay`, `price_display.md`).
18. **Previews.** Every form preview that still paints a `LinearGradient` or `.black` behind a form gets `Color.paper.ignoresSafeArea()` (covered in step 5). `LogoSheet`/`NumKeyPadSheet` previews put a sheet over `Color.black`; leave them.
19. **Build, tests, greps** (see Verification).

## Preserve
- **`SimplifiedAddExpenseViewModel` API:** `selectedTemplate`, `isLogoLocked`, `logoName`, `openLogoSheet`, `apply`, `applyBlank`, `clearTemplate`, `detachTemplate`, `add`, `addAnother`, `filteredTemplates`, `showEmptyCTA`; the rename-detaches-template binding (`SimplifiedAddExpenseView.swift:251-262`).
- **`SimplifiedAddExpenseView` behavior:** keyboard tracking (`:167-172`), 0.35s name autofocus when empty (`:173-182`), `revealErrors` scroll-to-top (`:243-247`), delete alert (`:183-191`), keypad sheet with `.environment(form.settingsStore)` and `.height(560)` (`:192-203`), LogoSheet sheet (`:204-213`), catalog `navigationDestination` (`:156-164`).
- **`ExpenseFormViewModel` logic:** fields, validation messages (`:128-134`), `commit`, `commitStayingOpen`, `reset`, start-of-day normalization in `persist` (`:242-278`), `deleteOriginal`. `LinguicaSubTrackerTests/ExpenseFormResetTests.swift` stays green.
- **`NumKeyPadSheet`:** decimal cents with `maxCents` 9_999_999 (`:32`), the freeform buffer, the `@Environment(SettingsStore.self)` requirement (every caller keeps `.environment(...)`).
- **`ExpenseTemplateSheet`:** hold `DragGesture(minimumDistance: 0)` with `beginHold`/`endHold` (`:433-437`), `.allowsHitTesting(!voice.isProcessing)` (`:438`), mic-denied "Open Settings" (`:384-390`).
- **`ExpenseSummarySheet`:** quick-edit flows; `QuickPickSheet` detent math `options.count * 52 + 92` (`:344`), so keep 48pt rows + 4pt spacing.
- **`LogoSheet`:** `onChange(of: tab)` style sync (`:72-78`).
- **Accessibility labels:** `LogoHeaderSection.swift:65-69`, `PopularServicesRow.swift:37`, `LinguicaSubTracker/Core/Components/CurrencyMenu.swift:38`, `AppButton.swift:185-188`, `RowModeToolbar.swift:64`, and the new ones from steps 8, 10, 14.
- **User data colors** (`AppCategory.colorHex`, `ExpenseList.colorHex`, `LogoCustomization.primaryColorHex`) render as given. Never remap them to the palette.
- **No new `AppSettings` fields in this doc.** If one is ever added it must be optional with lenient enum decoding (pattern at `AppTheme.swift:11-18`); a failed decode wipes all settings.
- **DEBUG hooks untouched:** `SIMCTL_CHILD_DEBUG_HOME_VIEW` (`HomeView.swift:83-89`), `DEBUG_MONTH_INDEX` (`HomeView.swift:91-98`), `DEBUG_WIDGET_GALLERY` (`HomeView.swift:100-101`), `DEBUG_OPEN_SHEET=budget` (`LinguicaSubTracker/Features/Home/Views/Components/HomeListView.swift:58-65`), `DEBUG_OPEN_SETTINGS_PAGE` (`LinguicaSubTracker/Features/Settings/Views/SettingsView.swift:79-90`).

## Risks / gotchas
- **`general_app_ui.md` vs code (follow the code):**
  - the doc describes `appAccent`/`appSurface` as re-pointed aliases; the working tree removed them and `appPurple` entirely. Use `Color.shu`/`Color.paperRaised` directly.
  - `AppTypography.Style` has no `weight` member; any `.typography(x.weight(...))` fails to compile.
  - the doc calls `FormRow` a fixed 44pt row; the code is already `.frame(minHeight: 44)`.
  - `SectionLabel` always draws the shu `Hashira`; there is no off switch. See Open points.
- **Two filled shapes.** Until step 8 lands, edit mode shows the red `.glassProminent` trash and the ink `.neutral .solid` Save together.
- **Toolbar text tint.** With AccentColor = shu, plain toolbar text ("Cancel", the pencil) can render shu. Check every form toolbar; add `.tint(Color.ink)` to that button only, never to a container holding the `.glassProminent` CTA.
- **Nested `NavigationStack`.** Never push `SimplifiedAddExpenseView`; present it as a sheet (step 9).
- **Double dismiss.** On commit from the hub, `onCommit` dismisses the hub while Simplified dismisses itself. Test: Add once, both sheets close, the expense is saved once.
- **`LabeledSection` is shared.** `BudgetDetailsSheet` ("RULE", "CATEGORIES") already shows the new label. Screenshot it after step 4.
- **Mono width.** Fragment Mono is about 0.6 em per glyph. "Entertainment" plus label plus icon can overflow the `.fixedSize` menu pickers (`CategorizationSection.swift:33,50,67,84`) at large Dynamic Type. Test at XXL.
- **`.glassProminent` contrast.** The paper label sits on translucent shu glass. Verify over both papers and with iOS 26.1 "Tinted" glass on ([Six Colors](https://sixcolors.com/post/2025/11/soaping-up-liquid-glass-less-transparency-more-contrast/)).
- **`.interactive()` with a rect shape** was reported to snap to a capsule on press during the beta. Check table rows 17 and the Done key. The hold button deliberately omits `.interactive()`.
- **Untinted glass on flat paper is faint.** That is why the hold button adds a 1pt `ruleStrong` border (same as `AppButton` `.neutral .outline`).
- **Pale data colors on washi.** Some category colors are about 1.7:1 on washi (萌黄, 鴇). The label text remains the cue, but faint icons will be noticed. See Open points.
- **No `layerEffect` / ripple** over any form card, glass or material. Forms have none today.
- **Widget target** shares `AppTheme.swift`, `Color.swift`, `LogoCircle.swift`, `AppSettings.swift`, `Category.swift`, `ExpenseList.swift`, not the form files or `Torii.swift`. Do not delete helpers from `Color.swift`.
- **Stale builds.** If the sim still shows gradients after `BUILD SUCCEEDED`, delete the Intermediates folder and rebuild with `COMPILATION_CACHE_ENABLE_CACHING=NO`.

## Verification
- **Build** (iPhone 17 Pro sim UDID):
  `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build`
- **Tests:** same command with `test -only-testing:LinguicaSubTrackerTests/ExpenseFormResetTests`, then the full suite (includes `ThemeFontTests`).
- **Greps** (repo root; each must print nothing):
  - `grep -rn "backgroundBase\|backgroundShade\|themeAccent\|themePrimary\|vm\.accent" LinguicaSubTracker`
  - `grep -rnE "(labelColor|tint|accent): (tint|vm\.|\.white)" LinguicaSubTracker/Features/Expense LinguicaSubTracker/Core/UI/Containers`
  - `grep -rn "LinearGradient" LinguicaSubTracker/Features/Expense LinguicaSubTracker/Core/Components/LogoSheet.swift LinguicaSubTracker/Core/UI/Containers`
  - `grep -rnE "\.green|\.gray|Color\.red|\.red[) ,]|appPurple" LinguicaSubTracker/Features/Expense LinguicaSubTracker/Core/Components/LogoSheet.swift LinguicaSubTracker/Core/Components/NumKeyPadSheet.swift`
  - `grep -rnE "cornerRadius(: |\()(1[0-9]|2[0-9])" LinguicaSubTracker/Features/Expense LinguicaSubTracker/Core/Components/LogoSheet.swift LinguicaSubTracker/Core/Components/NumKeyPadSheet.swift`
  - `grep -rn "ExpenseFormView(" LinguicaSubTracker` (when step 9 was taken)
  - `grep -nE "foregroundStyle\(\.(primary|secondary)\)" LinguicaSubTracker/Features/Expense/Views/ExpenseTemplateSheet.swift LinguicaSubTracker/Features/Expense/Views/ExpenseSummarySheet.swift LinguicaSubTracker/Core/Components/LogoSheet.swift LinguicaSubTracker/Features/Expense/Views/SubscriptionCatalogView.swift`
- **Simulator.** `SIMCTL_CHILD_DEBUG_HOME_VIEW=calendar xcrun simctl launch <UDID> com.dtx.LinguicaSubTracker`, wait ~8s, then `xcrun simctl io <UDID> screenshot`. Drive taps with the iOS-simulator `control` tool. Switch light/dark in Settings → Appearance. Screenshot each in **light and dark**:
  1. Home `+` → blank form: paper page, no gradient, ink text, hashira section labels, shu `Add`, untinted "Create and add another" with a shu icon.
  2. Popular services → Netflix: logo turns red, page stays paper; Category icon takes the category color.
  3. Add on an empty form: `beni` writing lines under name and amount, `FormErrorLabel` rows, scroll jumps to top, digits stay ink.
  4. Amount → keypad: square keys, Fragment Mono digits, `delete.left` symbol, shu Done, no scale on press; type 1, 5, 4, 9 → 15.49.
  5. Logo → LogoSheet: no cell fills, `ink` selection strokes, tab icons shu/inkSecondary, swatch ring visible on washi, ink slider.
  6. Tap an existing expense → summary: no bloom, paper sheet, square dot in the **category** color, status square, ink pencil. Pencil → edit form: glass trash with a beni glyph, shu `Save`.
  7. Search → `+` → hub: bento tiles on paper, hold button neutral with a shu mic (sim has no on-device speech, so the "not available" message shows as a `FormErrorLabel`). "Add Custom" and "Add Subscriptions → pick one" open the Simplified form as a sheet; saving closes both sheets once.
  8. `SIMCTL_CHILD_DEBUG_OPEN_SHEET=budget` (list view) → BudgetDetailsSheet: new labels; the warning, when shown, is a `FormErrorLabel`.
- **Accessibility:** VoiceOver reads "Error: Give it a name first", "Delete expense", "Delete digit", "Clear". Dynamic Type XXL: no clipped labels or pickers. Reduce Motion: no variable-color waveform, no amount animation.
- **Color budget:** each screen has at most one filled shu shape; everything else colored is an icon, a hashira tick or the logo.

## Open points / dig deeper
- **Row icon color source.** v1: `inkSecondary`, data colors only on Category and List. Prototype the alternative (every row icon takes the logo `primaryColor`) and ask the user, because "color only on the icon" can mean either. The brand variant needs a contrast clamp: white or black brand colors vanish on washi or lacquer.
- **Lightness clamp for user colors.** Evaluate the per-mode OKLCH clamp from the palette research (light L ≤ 0.62, dark L ≥ 0.55) for icons and dots; pastel defaults are 1.7–2.6:1 on washi. Decide together with `list_view.md` so dots and icons match.
- **Hashira density in forms.** The add form shows four shu ticks (hashira are strokes, not fills). Measure against 70/25/5 and 間 ma; if too loud, use `general_app_ui.md`'s fallback (`ruleStrong` ticks), which needs a color param on `Hashira`.
- **LogoCircle colored shadow.** `LinguicaSubTracker/Core/Components/LogoCircle.swift:20-25` adds a shadow of radius `size * 0.22` (~26pt on the 120pt hero): a small colored bloom against the "no glow" rule. Decide with `list_view.md` (`glass:` param) whether to drop it; dropping it orphans the "SHADOW" row at `LogoSheet.swift:234`.
- **Summary sheet background.** `.presentationBackground(Color.paper)` hides the iOS 26 sheet glass. Compare with deleting the line (system sheet background) on device.
- **Notebook-ruled notes field.** Faint `rule` lines behind the Notes `TextEditor` (`MoreDetailsSection.swift:103-106`) tracking line height; needs matching line metrics under Dynamic Type.
- **Square glass next to capsule system glass.** Toolbar `Add` is a capsule; the bottom CTA and hold button are r4. Check on device whether the mix reads as intentional.
- **Toolbar `glassProminent` label color.** Verify on device that `Text("Add").foregroundStyle(Color.paper)` wins over the system label color inside `.glassProminent`.
- **Fragment Mono glyph coverage** in `CurrencyMenu` labels (`R$`, `¥`, `€`, `£`): run the `CTFontGetGlyphsForCharacters` check from the tech research; a fallback glyph inside a mono label breaks alignment.
- **Hub routing UX.** Sheet-over-sheet (step 9) versus letting `SimplifiedAddExpenseView` optionally skip its own `NavigationStack` so it can be pushed. Test which feels right after picking from the hub catalog.
- **`ReceiptScanSheet` (hub → Scan with Camera) is not covered:** capture tiles `primary.opacity(0.08)` r20 (`LinguicaSubTracker/Features/ReceiptScan/Views/ReceiptScanSheet.swift:153-156`) and a hue-only green/orange/red confidence dot (`:232-234`, `:259-263`, fails WCAG 1.4.1). Decide whether forms v2 or a receipts doc owns it.
- **Settings swatch shape.** Circles are kept for color pickers while content tags are squares. Confirm with the user.

**Status: proposed, not implemented.**
