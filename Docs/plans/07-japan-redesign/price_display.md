# Price Display: brush-ink amount

## Goal
- **What the user asked for:** the price "needs to use the new colors and looks more like a brush, and in the animation be more like a brush too, all interactions and water metal animation about the Price should be removed."
- **In practice:**
  - The Home total is set in Fragment Mono in `Color.ink`. The currency symbol is smaller and in `Color.inkSecondary`.
  - A gold (`kin`) brush stroke underlines the amount.
  - A new value writes itself in glyph by glyph (the `InkReveal` text renderer), and the underline is drawn on behind the digits.
  - There is no ripple, no bounce, no digit roll, no glow and no Metal on the price. The only thing a tap on the total does is open Stats (unchanged).
  - Every other money string goes through `MoneyFormatter`, which also fixes the hardcoded `"CAD"` bug.

**Depends on:**
- `general_app_ui.md`, **already implemented in the working tree** (verify in step 1): palette tokens in `LinguicaSubTracker/Core/Utils/AppTheme.swift:47-64`, `AppFont.mono` (`AppTheme.swift:66-70`), Fragment Mono registered in the app and widget targets, `Theme.FontName` collapsed (`Theme.swift:4-6`), the new `AppTypography` styles (`Typography.swift:10-22`), `.rippleOnTap()` removed from the total.
- `charts.md` (budget scale option A): it owns `BudgetColor.swift` (the `Tier` contract below) and creates `HankoStamp` at `LinguicaSubTracker/Core/UI/Motifs/HankoStamp.swift` (new). Step 2 says what to do if it has not landed.
- Shared files with `list_view.md` (rows), `forms.md` (`NumKeyPadSheet` keys, `AmountField`, deletes `ExpenseFormView`) and `charts.md` (`StatsCard` chrome, `BudgetEditor` stats). Each step names the overlap.

**References:**
- [WWDC24 10151](https://developer.apple.com/videos/play/wwdc2024/10151/): the per-glyph `TextRenderer` pattern.
- [Applying custom fonts to text](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text): SwiftUI does not synthesize bold.
- [Fragment Mono repo](https://github.com/weiweihuanghuang/fragment-mono) and [Fontsource](https://fontsource.org/fonts/fragment-mono): one weight, OFL.
- [JGJE 赤字](https://www.tkgje.jp/entries/04500/04712_akaji.html): red ink = deficit.
- [WCAG 1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color)
- [HWS trim](https://www.hackingwithswift.com/quick-start/swiftui/how-to-draw-part-of-a-solid-shape-using-trim): mask filled outlines, never trim them.

## Current state
All line numbers are the current working tree (foundation applied, uncommitted). `git diff HEAD -- <path>` shows what the foundation changed.

**Price engine: `LinguicaSubTracker/Features/Home/Views/Components/TextAnimatedView.swift`**
- **API (`:3-16`):** `text`, `size` (62), `minSize` (24), `availableWidth`, `tint` (`.primary`), `onTapGesture`. `nil` attaches no gesture so an enclosing `Button` gets the tap (`:42-46`).
- **State:** `displayedValue` `:18`; `scale` `:19` (bounce only).
- **Style:** `AppTypography.Style.displayMedium` at `:21` = 34pt, `.largeTitle`, tracking **−0.5** (`Typography.swift:10`).
- **Render chain (`:25-40`):**
  - `FluidFontSize` `:26` (struct `:117-131`): `Animatable` font size; at `:128` it uses `Theme.font(size:relativeTo:)`, which is `Font.custom(_:size:relativeTo:)` and **scales with Dynamic Type** (`Theme.swift:8-10`).
  - `.monospacedDigit()` `:27`, `.minimumScaleFactor` `:29`
  - `.contentTransition(.numericText())` `:30` (digit roll)
  - tint `.easeInOut(0.4)` `:32`, `sizeSpring` (0.45s, bounce 0.15) `:33`
  - `.scaleEffect(scale)` `:34`
  - `valueSpring` (0.4s, bounce 0.35) `:39`, `scaleSpring` (0.3s, bounce 0.5) `:40`
- **Bounce:** `animateChange` (`:94-100`) calls `bounce()` (`:102-106`, scale 1.15 with `scaleBounce` = spring 0.3s / bounce 0.6), then `resetScale` (`:108-112`, `scaleReturn` = 0.4s / bounce 0.4, delay 0.05). Constants `:133-155`.
- **Entry:** `animateEntry` (`:86-92`) sets `displayedValue = ""`, then calls `animateChange(to: text)` 0.05s later, so the first appearance also bounces.
- **Fitting:**
  - `fittedSize` (`:55-62`) = `size * availableWidth / measuredWidth(at: size)`, clamped to `min(minSize, size)...size`.
  - `minimumScaleFactor` (`:65-71`): 0.9 with a width, `min(1, minSize/size)` without.
  - `measuredWidth` (`:73-84`): **already done by the foundation pass (verify):** `:75-76` measure with `UIFont(name: AppFont.mono, …) ?? .monospacedSystemFont(…, weight: .regular)`. It still substitutes every digit with `0` (`:79`) and measures without Dynamic Type scaling.
- **Accessibility:** Reduce Motion is not read in this file.

**Wrapper: `LinguicaSubTracker/Core/Components/MoneyDisplay.swift:5-29`.** Passes the six parameters through (`:20-27`). Doc comment `:3` says it "bounces". `tint` default `.primary` (`:14`). Preview `:31-38` forces `.preferredColorScheme(.dark)` (`:37`).

**Home total: `LinguicaSubTracker/Features/Home/Views/Components/TotalView.swift`**
- **Constants:** `totalInset` 24 (`:15`), `totalSizeRange` `48...92` (`:18`).
- **Glow:** `ZStack` `:43`; `if viewModel.hasBudget { RadialGradient … }` `:44-63` (endRadius 160, tinted `budgetTint.opacity(glowOpacity)`, animated 0.6s/0.4s). Invisible: `TotalViewModel.glowOpacity` returns `0.0` (`TotalViewModel.swift:39-42`), so `BudgetColor.glowOpacity` (`BudgetColor.swift:19-24`) is dead.
- **`Button(action: action)`** `:66`, `.buttonStyle(.plain)` `:109`. The action is `vm.showStats = true` (`HomeView.swift:40-42`).
- **Water metal: already done by the foundation pass (verify):** `.rippleOnTap()` (HEAD `TotalView.swift:110`) is gone; `grep -n rippleOnTap LinguicaSubTracker/Features/Home` returns nothing.
- **Dead code:** `showCoins` (`:10`) and `showDate` (`:11`) are never `true` (`HomeView.swift:35`, `TotalViewPreviewHost.swift:13` use defaults). Unreachable as a result:
  - month label with `.transition(.monthRipple)` (`:68-83`, transition `:78`)
  - compact `MoneyDisplay` size 40 (`:85-97`)
  - `CoinProgress` (`:111-125`)
  - breakdown (`:127-130`, `isBreakdownVisible` `:146-148`, `breakdown` `:150-199`)
  - `MonthRippleModifier` (`:202-223`) and `AnyTransition.monthRipple` (`:225-236`)
- **Live price:** `MoneyDisplay` `:99-105` (`size: 92`, `minSize: 48`, `availableWidth: totalWidth`, `tint: viewModel.budgetTint`). `totalWidth` `:141-144`.
- `TotalViewPreviewHost.swift:20`: `.background(.black)`.

**How the water metal worked (still in the repo for onboarding only)**
- `rippleOnTap` (`LinguicaSubTracker/Core/UI/Effects/RippleEffect.swift:152-157`) installs `TapRippleModifier` (`:79-98`): a simultaneous `SpatialTapGesture` stores `origin` and bumps `count`.
- `RippleEffect` (`:22-44`) runs a `keyframeAnimator` linearly 0 → 0.9s; `RippleModifier` (`:47-73`) applies `visualEffect { layerEffect(ShaderLibrary.Ripple(origin, t, amplitude 12, frequency 15, decay 8, speed 1200), maxSampleOffset 12×12, isEnabled: 0 < t < 0.9) }`. Defaults in `RippleStyle` (`:4-17`).
- Shader (`LinguicaSubTracker/Core/UI/Effects/Ripple.metal:13-40`): local time `t' = max(0, t − distance/1200)`; displacement `12·sin(15·t')·e^(−8·t')` along the radial direction (`:29-32`); `color.rgb += 0.3·(disp/12)·alpha` (`:37`) — the light/dark crest band that reads as "metal".
- `layerEffect` renders materials black, which is why `Features/Onboarding/Views/Components/Heroes/RippleCard.swift:6-16` uses opaque `Color.paperRaised`. Remaining callers are onboarding heroes only (general_app_ui.md keeps them).

**Budget tint today: `BudgetColor.color` (`LinguicaSubTracker/Core/Utils/BudgetColor.swift:7-17`, not yet changed)**

| Spent / budget | Color |
|---|---|
| No budget | `.primary` |
| < 0.5 | `.green` |
| 0.5 – 0.75 | `.yellow` |
| 0.75 – 0.9 | `.orange` |
| 0.9 – 1.0 | RGB(1, 0.35, 0) |
| ≥ 1.0 | `.red` |

Used by `TotalViewModel.budgetTint` (`:35-37`) and the widget (`SatoruWidgets/WidgetViews.swift:110`).

**Every other money rendering**

| Site | Today | Problem |
|---|---|---|
| `Features/Home/Views/Components/HomeListView.swift:72-77` | `MoneyDisplay` 40, `onTapGesture: onStats` | bounce + roll |
| `HomeListView.swift:155-157` | category amount, `.foregroundStyle(spend.color)` | user colour on text |
| `Features/Settings/Views/Components/BudgetDetailsSheet.swift:79-84` | `MoneyDisplay` 48; `.red` when strict + over-allocated (`:82`, `:88`) | red, bounce |
| `Core/Components/NumKeyPadSheet.swift:115-119` | freeform `MoneyDisplay` 48 + extra `numericText` + spring 0.28/0.72 | bounce per keystroke |
| `NumKeyPadSheet.swift:219-263` `NumKeyPadAmountDisplay` | `.system(size: 28/52, design: .rounded)` at `:232`, `:242`, `:251`, `:257`; `.secondary` `:233`; `.tertiary` dot `:252`; spring 0.28/0.72 `:261` | rounded font, springs |
| `Features/Home/Views/Components/HomeExpenseRow.swift:12-14` | `.currency(code:)` | bypasses `MoneyFormatter` (`CA$` vs `$`, ignores round/abbreviate) |
| `Core/Components/ExpenseRow.swift:22-24` (Search, `SearchView.swift:241`) | `.currency(code:)` | same |
| `Features/Expense/SimplifiedAddExpense/Views/Components/AmountField.swift:14` | `Text(amount, format: .currency(code:))` | same |
| `Features/Expense/Views/ExpenseFormView.swift:93` | `.currency(code: vm.currencyCode)` | same |
| `Features/Expense/Views/ExpenseSummarySheet.swift:168`, `:185` | **`.currency(code: "CAD")`** | wrong currency |
| `Features/Expense/ViewModels/ExpenseSummaryViewModel.swift:49-51` (shown at `ExpenseSummarySheet.swift:136`) | **`"CAD"`** | wrong currency |
| `Features/ExpensesInDay/Views/ExpensesInDay.swift:219` | **`"CAD"`** | wrong currency |
| `Features/ExpensesInDay/ViewModels/ExpensesInDayViewModel.swift:45-49` (shown at `ExpensesInDay.swift:164`) | **`"CAD"`** | wrong currency |
| `Core/Utils/Theme.swift:77-87` `asPeriodCurrency`, used at `BatchAddView.swift:166-167`, `ExpenseTemplateSheet.swift:345-346`, `OnboardingQuickAddPage.swift:160-161` | symbol + hand-rolled number | duplicates `formatNumber` |
| `Features/Stats/Views/Components/StatsCard.swift:15-19` | `headlineLarge`, `.primary`, `numericText` + spring 0.4/0.85 | roll |
| `Features/Settings/Views/Components/BudgetEditor.swift:134-139` | "Over by" `color: .red` at `:137` | red |
| `SatoruWidgets/WidgetViews.swift:151`, `:203`, `:230` | `status.isOver ? .red : .primary` / `nil` | red |

**Already correct (`MoneyFormatter`):** `TotalViewModel.swift:31-33`, `:66-70`, `:99-101`; `StatsViewModel.swift:60-80`, `:139` (feeds `SpendDial.swift:138`, `StatsLegendList.swift:47`, `StatsSheet.swift:182-186`); `BudgetEditorViewModel.swift:32-62`; `BudgetDetailsViewModel.swift:109-116`; `ExpenseTemplateSheet.swift:331-336`; `ReceiptScanSheet.swift:205-209`; Intents/notifications (`ExpenseIntents.swift:251`, `ExpenseEntity.swift:25`, `ReceiptVisualIntelligence.swift:45`, `RenewalReminders.swift:132`); `SatoruWidgets/WidgetData.swift:30-36`.

**Already done by the foundation pass (verify):** widget amounts use `mono(_:)` = `.custom(AppFont.mono, fixedSize:)` (`SatoruWidgets/WidgetViews.swift:8-10`); fonts are in the widget exception set (`project.pbxproj:102-104`); `ThemeFontTests.swift:8-18` asserts Fragment Mono is registered and has `$ € R £ ¥`.

**Out of scope (editable inputs):** `ReceiptScanSheet.swift:242-247` and `VoiceCaptureOverlay.swift:99-104` are `TextField`s with a symbol prefix. Leave them.

## Target design

### Look
| Element | Spec | Light (washi) | Dark (lacquer) |
|---|---|---|---|
| Ground | flat `Color.paper` (already via `.appBackground()`); no glow, no gradient | #F8F4E6 | #0E0C0B |
| Digits | `AppFont.mono` at `fixedSize:` = fitted size; tracking `displayMedium.letterSpacing` (−0.5) | `ink` #1E1A17 | `ink` #F4EFE6 |
| Currency symbol | same font at **0.55×** digit size, shared baseline, `Color.inkSecondary` (token, not opacity) | #6B635C | #A8A096 |
| Over-budget digits | `Color.shu` (symbol stays `inkSecondary`) | #C1352A (5.0:1) | #E84A33 (5.1:1) |
| Brush underline | `BrushStroke` filled shape, full text width, height `max(3, 0.08 × size)`, bottom of the line box (descender band, 0.25 em) | `kin` #C9A13B | `kin` #D4A72C |
| Underline, 75–99 % | `Color.kinText` | #8A6B1F | #E6B422 |
| "LEFT" label, 75–99 % | `.typography(.labelLarge)` (12pt `.caption`, uppercase, tracking 1.2 — `Typography.swift:21`), `kinText`, text `"$215.50 left"` | 4.5:1 | 10:1 |
| Over, ≥ 100 % | `HankoStamp()` (defaults "赤字", "Over budget", 28pt: square 1.5pt `shu` border, −3°, 0.9 opacity, `.multiply` light only) + `"$128.00 over"` label in `shu` | | |

**Budget state** (charts.md option A, 黒字/赤字). The contract this doc codes against (general_app_ui.md §9):
```swift
// BudgetColor.swift (charts.md owns it; shared with the widget)
enum Tier { case none, calm, near, over }      // no budget, <75 %, 75–99 %, ≥100 %
static func tier(spent: Double, budget: Double?) -> Tier
static func color(spent: Double, budget: Double?) -> Color   // Color.ink unless .over → Color.shu
```

**Palette rules respected:** prices default to `ink`; gold is a ≤7pt-tall stroke, never a fill over 24pt; the hanko is stroked, so the Home `+` (home_screen_ux.md) stays the screen's one filled shu shape; red on a number only means 赤字; the tier is carried by words and the stamp shape, not hue (WCAG 1.4.1).

### Layout (Home calendar mode, iPhone 17 Pro 402pt, `totalInset` 20 → 362pt text width)
```
   calm (<75 %) / no budget            near (75–99 %)                  over (≥100 %)
┌──────────────────────────────┐ ┌──────────────────────────────┐ ┌──────────────────────────────┐
│                              │ │                              │ │                              │
│          $1,284.50           │ │          $1,284.50           │ │          $1,612.00  ← shu    │
│          ▇▇▇▇▇▇▇▆▅▄▃▂▁       │ │          ▇▇▇▇▇▇▇▆▅▄▃▂▁       │ │          ▇▇▇▇▇▇▇▆▅▄▃▂▁       │
│          └ kin stroke        │ │          └ kinText stroke    │ │          └ kin stroke        │
│      (calm: blank 28pt row;  │ │        $215.50 LEFT          │ │     ┌──┐                     │
│       no budget: no row)     │ │        └ kinText 12pt caps   │ │     │赤│ $128.00 OVER        │
│                              │ │                              │ │     │字│ └ shu 12pt caps     │
└──────────────────────────────┘ └──────────────────────────────┘ └──────────────────────────────┘
  "$" = 0.55× size, inkSecondary.   Whole block = the Stats Button.  Hanko stroked, −3°, not filled.
  Stroke: heavy rounded entry (起筆) at the left, tapering to a point (はらい) at the right.
```
- **Light:** ink digits on ivory paper; `kin` stroke reads as gold leaf; hanko `.multiply`.
- **Dark:** off-white ink on lacquer; `kin`/`kinText` both read bright (they barely differ — see Open points); hanko normal blend.
- `BudgetMark` reserves its 28pt row whenever `tier != .none`, so crossing a threshold never shifts the layout.
- List mode (`HomeListView` summary) uses the same stack at size 40 with no width fitting.

### Motion (brush)
| t (s) | What happens |
|---|---|
| 0 | New value set; glyphs invisible; underline length 0 |
| 0 → 0.70 | `InkReveal`, ease-out: per glyph opacity 0→1, blur 5pt→0, x −2pt→0; 3-glyph overlap, left to right, symbol first |
| 0.35 → 0.70 | Underline drawn on left to right with a scale mask (`easeOut`), trailing the ink front and finishing with the last glyph |

- Total 0.7s, inside the canonical 0.55–0.7s brush range.
- **Triggers:** first appearance (the existing 0.05s blank-then-set entry), every change of `text` (month paging, add/delete, filter). A change mid-reveal restarts from 0.
- **Removed:** bounce, `numericText` roll, all springs, size spring (size snaps while glyphs are invisible), ripple, glow, `monthRipple`.
- **Reduce Motion:** one uniform opacity fade 0→1 in 0.25s, no blur, no drift; underline static at full length.
- **Lists, rows, cards, widgets:** static ink, no reveal. Rows recycle while scrolling; a 0.7s blur per row is noise and N× cost.
- **Inputs (keypad, amount fields):** no reveal; re-inking every keystroke reads as lag.

### Amount styling elsewhere
| Site | Color | Motion | Owner |
|---|---|---|---|
| `TotalView` total | `budgetTint` (ink/shu) | InkReveal + underline + `BudgetMark` | this doc |
| `HomeListView` total (`:72`) | same | same, size 40 | this doc |
| `BudgetDetailsSheet` (`:79`) | `Color.shu` if strict + over-allocated, else `Color.ink` | InkReveal, no underline | this doc |
| Keypad freeform (`NumKeyPadSheet:115`) | digits `ink`, symbol `inkSecondary` | static `Text` | this doc |
| `NumKeyPadAmountDisplay` | digits `ink`; symbol and `.` `inkSecondary` | keep push/`numericText` (input feedback), animation `.easeOut(duration: 0.2)` | this doc (forms.md owns the keys) |
| `HomeExpenseRow`, `ExpenseRow`, `ExpensesInDay` | `ink` (meta `inkSecondary`) | static | list_view.md (this doc only swaps the formatter) |
| `HomeListView:155-157` category amount | `ink` (category colour stays on the coin) | static | list_view.md step 6 |
| `StatsCard` value | `ink` | `.contentTransition(.opacity)`, `.easeOut(duration: 0.25)` | this doc; chrome `:21-23` charts.md |
| `SpendDial`, `StatsLegendList` | `ink` | static | charts.md |
| `BudgetEditor` "Over by" (`:137`) | `Color.shu` | — | this doc (one token; rest charts.md) |
| `AmountField`, `ExpenseFormView` | per forms.md | per forms.md | forms.md (this doc only swaps the formatter) |
| Widgets | `Color.ink`; over → `Color.shu` | static | charts.md step 16 (colour), general_app_ui.md (font, done) |

## Implementation steps
1. **Verify the foundation** (all should already hold; fix nothing in other docs' scope):
   - `AppTheme.swift:52-63` defines `paper`…`ai`; `AppFont.mono == "FragmentMono-Regular"` (`:67`).
   - `TextAnimatedView.swift:75` uses `AppFont.mono`.
   - `grep -rn "rippleOnTap" LinguicaSubTracker/Features/Home` returns nothing.
   - `ThemeFontTests` passes.

2. **Budget contract.**
   - charts.md runs before this doc in the execution order (`research_results_and_future_points.md`), so `BudgetColor.Tier` and `HankoStamp` should already exist. Use them as is.
   - If not, add exactly this to `BudgetColor.swift` (it is general_app_ui.md §9's contract, so charts.md will keep it) and delete `glowOpacity` (`:19-24`):
     ```swift
     enum Tier { case none, calm, near, over }
     static func tier(spent: Double, budget: Double?) -> Tier {
         guard let budget, budget > 0 else { return .none }
         switch spent / budget { case ..<0.75: return .calm; case ..<1: return .near; default: return .over }
     }
     static func color(spent: Double, budget: Double?) -> Color {
         tier(spent: spent, budget: budget) == .over ? .shu : .ink
     }
     ```
   - If `HankoStamp` does not exist yet, build `BudgetMark` (step 8) without it; the word OVER is the non-colour cue. Add `HankoStamp()` when charts.md lands.

3. **`MoneyFormatter.exact`.** Add after `format` (`LinguicaSubTracker/Core/Utils/MoneyFormatter.swift:19-23`). Foundation-only, so the widget target keeps compiling.
   ```swift
   /// Full precision in `currencyCode`, ignoring round/abbreviate: for input echoes, where "$1.2k" would lie.
   static func exact(_ value: Double, currencyCode: String) -> String {
       symbol(for: currencyCode) + formatNumber(value, round: false, abbreviate: false)
   }
   ```
   Output equals today's `symbol + asPeriodCurrency` (both en_US, 2 decimals).

4. **Route every site through `MoneyFormatter`** (fixes every `"CAD"`):
   - `HomeExpenseRow.swift:13` and `ExpenseRow.swift:23`: `MoneyFormatter.format(expense.price, settings: settingsStore.settings)`. Skip a file if list_view.md already deleted/rewrote it.
   - `ExpenseSummarySheet.swift:168`: `Text(MoneyFormatter.format(vm.expense.price, settings: settingsStore.settings))`; keep `.contentTransition(.numericText())` (`:170`, quick-edit echo).
   - `ExpenseSummarySheet.swift:185`: `Text(MoneyFormatter.format(vm.totalSpent, settings: settingsStore.settings))`.
   - `ExpenseSummaryViewModel.swift:49-51`: replace the property with `func scheduleAndPriceText(settings: AppSettings) -> String` returning `"\(expense.billingCycle.displayName) • \(MoneyFormatter.format(expense.price, settings: settings))"`. Call site `ExpenseSummarySheet.swift:136`: `vm.scheduleAndPriceText(settings: settingsStore.settings)`.
   - `ExpensesInDayViewModel.swift:45-49`: signature `rowSubtitle(for expense: Expense, settings: AppSettings)`, price `MoneyFormatter.format(expense.price, settings: settings)`. Call site `ExpensesInDay.swift:164` passes `settingsStore.settings` (property at `:9`). Skip if list_view.md already deleted `rowSubtitle`.
   - `ExpensesInDay.swift:219`: `Text(MoneyFormatter.format(vm.total, settings: settingsStore.settings))`. This doc is the single owner of that fix; the earlier calendar pass leaves this sheet unchanged and list_view.md's sum-line rewrite keeps the same call.
   - `AmountField.swift:14`: `Text(MoneyFormatter.exact(amount, currencyCode: currencyCode))`. Do not touch `:16-18` (forms.md).
   - `ExpenseFormView.swift:93`: `Text(MoneyFormatter.exact(vm.price, currencyCode: vm.currencyCode))`. Skip if forms.md step 9 deleted the file.
   - `BatchAddView.swift:166-167`, `ExpenseTemplateSheet.swift:345-346`, `OnboardingQuickAddPage.swift:160-161`: `return MoneyFormatter.exact(<draft.price | item.amount>, currencyCode: currencyCode)`. Then delete `asPeriodCurrency` (`Theme.swift:77-87`).
   - Leave the `"CAD"` initial values at `ExpenseSummaryViewModel.swift:21` and `BudgetDetailsViewModel.swift:37`; they are overwritten from settings (`ExpenseSummarySheet.swift:43`, `BudgetDetailsViewModel.swift:43`).

5. **Rewrite `TextAnimatedView.swift`.** Replace the whole file except `fittedSize` / `minimumScaleFactor` (`:49-71`, copy verbatim) and the `#Preview` (`:157-159`). This deletes `scale`, `FluidFontSize` (`:115-131`), `animateChange`/`bounce`/`resetScale` (`:94-112`), the `Animation` extension (`:133-155`), `.monospacedDigit()` and `.contentTransition(.numericText())`.
   ```swift
   import SwiftUI

   struct TextAnimatedView: View {
       let text: String
       var size: CGFloat = 62
       var minSize: CGFloat = 24
       var availableWidth: CGFloat? = nil
       var tint: Color = .ink
       /// Brush underline colour; `nil` draws none.
       var underline: Color? = nil
       /// Optional on purpose: an always-attached tap gesture would swallow taps
       /// meant for an enclosing Button.
       var onTapGesture: (() -> Void)? = nil

       @State private var displayedValue = ""
       @Environment(\.accessibilityReduceMotion) private var reduceMotion

       private static let style = AppTypography.Style.displayMedium   // letterSpacing only
       private static let symbolScale: CGFloat = 0.55

       @ViewBuilder
       var body: some View {
           // Hoisted so the keyframe closures capture plain values only.
           let size = fittedSize
           let stroke = underline
           let staggered = !reduceMotion
           let content = inked(at: size)
               .lineLimit(1)
               .minimumScaleFactor(minimumScaleFactor)
               .animation(.easeInOut(duration: 0.4), value: tint)
               .keyframeAnimator(initialValue: Reveal(), trigger: displayedValue) { view, r in
                   view
                       .textRenderer(InkReveal(progress: r.ink, staggered: staggered))
                       .background(alignment: .bottomLeading) {
                           if let stroke {
                               BrushStroke().fill(stroke)
                                   .frame(height: max(3, size * 0.08))
                                   .mask { Rectangle().scaleEffect(x: r.stroke, y: 1, anchor: .leading) }
                           }
                       }
               } keyframes: { _ in
                   KeyframeTrack(\.ink) {
                       MoveKeyframe(0)
                       LinearKeyframe(1, duration: staggered ? 0.7 : 0.25, timingCurve: .easeOut)
                   }
                   KeyframeTrack(\.stroke) {
                       MoveKeyframe(staggered ? 0 : 1)
                       LinearKeyframe(staggered ? 0 : 1, duration: 0.35)        // let the first glyphs land
                       LinearKeyframe(1, duration: 0.35, timingCurve: .easeOut)  // ends with the last glyph
                   }
               }
               .onAppear(perform: animateEntry)
               .onChange(of: text) { _, new in displayedValue = new }

           if let onTapGesture { content.onTapGesture(perform: onTapGesture) } else { content }
       }

       /// One `Text` via interpolation, so the renderer sees every glyph (symbol included)
       /// and both parts share a baseline.
       private func inked(at size: CGFloat) -> Text {
           let (symbol, number) = Self.split(displayedValue)
           let s = Text(symbol).font(.custom(AppFont.mono, fixedSize: size * Self.symbolScale))
               .foregroundStyle(Color.inkSecondary)
           let n = Text(number).font(.custom(AppFont.mono, fixedSize: size)).foregroundStyle(tint)
           return Text("\(s)\(n)").tracking(Self.style.letterSpacing)
       }

       /// "$1,234.50" → ("$", "1,234.50"); "R$-5.00" → ("R$", "-5.00"); "Not set" → ("", "Not set").
       private static func split(_ s: String) -> (Substring, Substring) {
           guard let i = s.firstIndex(where: { $0.isNumber || $0 == "-" }) else { return ("", s[...]) }
           return (s[..<i], s[i...])
       }

       // fittedSize and minimumScaleFactor: verbatim from old :49-71.

       private func measuredWidth(at pointSize: CGFloat) -> CGFloat {
           func width(_ s: Substring, _ pt: CGFloat) -> CGFloat {
               let font = UIFont(name: AppFont.mono, size: pt) ?? .monospacedSystemFont(ofSize: pt, weight: .regular)
               return (String(s) as NSString).size(withAttributes: [.font: font, .kern: Self.style.letterSpacing]).width
           }
           let (symbol, number) = Self.split(displayedValue)
           return width(symbol, pointSize * Self.symbolScale) + width(number, pointSize)
       }

       private func animateEntry() {
           displayedValue = ""
           DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { displayedValue = text }
       }
   }

   private struct Reveal { var ink = 1.0; var stroke = 1.0 }
   ```
   - **Why:** `fixedSize:` because `measuredWidth` does not scale with Dynamic Type and `Font.custom(_:size:)` would (`Theme.swift:9`), overflowing the fitted width. The all-zeros substitution (old `:79`) and `.monospacedDigit()` go because every Fragment Mono glyph has the same 618/1000 em advance. `keyframeAnimator` + `MoveKeyframe(0)` is the trigger pattern already used at `RippleEffect.swift:28-42`.
   - Add both helpers to the same file, `private`:
   ```swift
   /// Brush write-in: per glyph, opacity 0→1, blur 5→0, x −2→0; three glyphs overlap.
   private struct InkReveal: TextRenderer {
       var progress: Double
       var staggered = true                                     // false = Reduce Motion: uniform fade
       var animatableData: Double { get { progress } set { progress = newValue } } // lets a Transition drive it too
       var displayPadding: EdgeInsets { EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8) } // blur room

       func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
           guard progress < 1, staggered else {                   // at rest / reduced: no filters
               ctx.opacity = staggered ? 1 : progress
               for line in layout { ctx.draw(line) }
               return
           }
           let glyphs = layout.flatMap { $0 }.flatMap { $0 }       // Line → Run → RunSlice ≈ glyph
           let window = 3.0
           for (i, glyph) in glyphs.enumerated() {
               let t = min(max((progress * (Double(glyphs.count) + window - 1) - Double(i)) / window, 0), 1)
               guard t > 0 else { continue }
               var g = ctx
               g.opacity = t
               if t < 1 { g.addFilter(.blur(radius: (1 - t) * 5)) }
               g.translateBy(x: (1 - t) * -2, y: 0)
               g.draw(glyph, options: .disablesSubpixelQuantization)
           }
       }
   }

   /// Filled sumi stroke: rounded heavy entry (起筆) at minX, thins while travelling,
   /// sweeps to a point (はらい) at maxX. Fill it; mask (never trim) to draw it on.
   private struct BrushStroke: Shape {
       func path(in r: CGRect) -> Path {
           let h = r.height
           var p = Path()
           p.move(to: CGPoint(x: r.minX + h * 0.4, y: r.minY))
           p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.4),
                          control: CGPoint(x: r.minX + r.width * 0.6, y: r.minY + h * 0.1))
           p.addQuadCurve(to: CGPoint(x: r.minX + h * 0.4, y: r.maxY),
                          control: CGPoint(x: r.minX + r.width * 0.55, y: r.maxY))
           p.addQuadCurve(to: CGPoint(x: r.minX + h * 0.4, y: r.minY),
                          control: CGPoint(x: r.minX - h * 0.2, y: r.midY))
           p.closeSubpath()
           return p
       }
   }
   ```
   - **Mask-wipe fallback** (only if step 15 measures hitches): replace the `.textRenderer(...)` line with
   ```swift
   .mask(alignment: .leading) {
       LinearGradient(stops: [.init(color: .black, location: 0),
                              .init(color: .black, location: min(1, max(0, r.ink * 1.2 - 0.2))),
                              .init(color: .clear, location: min(1, r.ink * 1.2))],
                      startPoint: .leading, endPoint: .trailing)
   }
   ```

6. **`MoneyDisplay.swift`.**
   - Add `var underline: Color? = nil` between `tint` (`:14`) and `onTapGesture` (`:17`); pass it through in `:20-27`.
   - Default `tint` → `.ink`.
   - Doc comment `:3` → "Brush-ink money display: writes itself in on every value change."
   - Preview `:31-38`: add `MoneyDisplay(text: "$1,284.50", underline: .kin)` and delete `.preferredColorScheme(.dark)` (`:37`).

7. **`TotalViewModel.swift`.**
   - Delete `glowOpacity` (`:39-42`), `isCompactStyle` and `budgetProgress` (`:46-56`). Their only callers are in TotalView code deleted in step 9.
   - Add after `budgetTint` (`:35-37`):
   ```swift
   var budgetTier: BudgetColor.Tier { BudgetColor.tier(spent: total, budget: settingsStore.effectiveBudget) }
   var underlineTint: Color { budgetTier == .near ? .kinText : .kin }
   /// |budget − spent| for the LEFT / OVER label.
   var formattedBudgetGap: String? { settingsStore.effectiveBudget.map { formatted(abs($0 - total)) } }
   ```

8. **`BudgetMark` (new): `LinguicaSubTracker/Features/Home/Views/Components/BudgetMark.swift`.** Used by TotalView and HomeListView; app-only.
   ```swift
   /// Budget state under a total. Words and the stamp carry the meaning; colour is secondary (WCAG 1.4.1).
   struct BudgetMark: View {
       let tier: BudgetColor.Tier
       let gap: String?

       var body: some View {
           Group {
               switch tier {
               case .near: label("\(gap ?? "") left", .kinText)
               case .over:
                   HStack(spacing: 8) {
                       HankoStamp()                        // "赤字", a11y "Over budget", 28pt (charts.md)
                       label("\(gap ?? "") over", .shu)
                   }
               case .none, .calm: Color.clear
               }
           }
           .frame(height: tier == .none ? 0 : 28)
       }

       private func label(_ s: String, _ color: Color) -> some View {
           Text(s).typography(.labelLarge).foregroundStyle(color)   // 12pt caps, tracking 1.2, Bold Text aware
       }
   }
   ```

9. **`TotalView.swift`.**
   - Replace the body (`:42-139`) with the code below.
   - `totalInset` (`:15`) → **20**. Preserve the calendar style sizing from `calendar.md`: Default/Compact use **`44...84`**, while Large stays smaller at **`36...68`**. Keep `totalSizeRange` as a computed range that reads `viewModel.settingsStore.calendarStyle`.
   - Delete `showBreakdown` (`:5-7`), `showCoins`/`showDate` (`:10-11`), init params `:25-26`, assignments `:29-30`, `isBreakdownVisible` + `breakdown` (`:146-199`), `MonthRippleModifier` + `monthRipple` (`:202-236`).
   - Keep `totalWidth` (`:141-144`), the struct's closing brace (`:200`) and `#Preview` (`:238-240`).
   ```swift
   var body: some View {
       Button(action: action) {
           VStack(spacing: 6) {
               MoneyDisplay(
                   text: viewModel.formattedTotal,
                   size: totalSizeRange.upperBound,
                   minSize: totalSizeRange.lowerBound,
                   availableWidth: totalWidth,
                   tint: viewModel.budgetTint,
                   underline: viewModel.underlineTint
               )
               BudgetMark(tier: viewModel.budgetTier, gap: viewModel.formattedBudgetGap)
           }
       }
       .buttonStyle(.plain)                       // no ripple, no extra gesture
       .frame(maxWidth: .infinity)
       .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
   }
   ```
   - **Re-tune maths** (Fragment Mono advance measured from `Resources/Fonts/FragmentMono-Regular.ttf`: 618/1000 em for digits, `$ € £ ¥ R , . -`):
     - "$1,234.50" = 0.55×0.618 + 8×0.618 ≈ 5.28 em → fits 362pt at ≈ 69pt.
     - "$1,234,567.89" ≈ 7.76 em → ≈ 47pt, above the 44 floor.
     - "R$1,234.50" ≈ 5.62 em → ≈ 64pt. "$0.00" at the 84 cap ≈ 236pt wide.
     - The normal upper cap (84 vs 92) leaves vertical room for the underline and the 28pt `BudgetMark` above the calendar. Large uses the smaller 68pt cap so its taller grid remains reachable.
     - These em figures ignore tracking. The code's `displayMedium` tracking is −0.5pt per glyph (not the plan's "~0"); `measuredWidth` passes it as `.kern`, so the fit already accounts for it (≈ −4.5pt over 9 glyphs).
   - `CoinProgress` then has no production caller (only `CoinProgressPreviewHost.swift:90`). Now run charts.md step 14 (delete `CoinProgress.swift` + its preview host, keep the view model); charts.md ran before this doc and skipped it.
   - `TotalViewPreviewHost.swift:20`: `.background(.black)` → `.background(Color.paper)`.

10. **`HomeListView.swift` summary.**
    - `:72-77`: add `underline: viewModel.underlineTint`; keep `onTapGesture: onStats` (`:76`).
    - Insert `BudgetMark(tier: viewModel.budgetTier, gap: viewModel.formattedBudgetGap)` after `.frame(maxWidth: .infinity)` (`:78`).
    - Do not touch the coin-pile labels (`:155-161`, list_view.md step 6) or `listBlock` (`:178+`, list_view.md).

11. **`BudgetDetailsSheet.swift`.** `:82` `.red : .primary` → `Color.shu : Color.ink`; `:88` `.red : .secondary` → `Color.shu : Color.inkSecondary`. Keep `onTapGesture: { vm.beginEdit(.total) }` (`:83`). No underline.

12. **`NumKeyPadSheet.swift`** (forms.md restyles the keys and the "Amount" label; do not touch `:138-211`).
    - Replace `:115-119` with a static echo:
      ```swift
      Text("\(Text(currentSymbol).font(.custom(AppFont.mono, fixedSize: 26)).foregroundStyle(Color.inkSecondary))\(buffer)")
          .font(.custom(AppFont.mono, fixedSize: 48)).foregroundStyle(Color.ink)
          .lineLimit(1).minimumScaleFactor(0.5)
      ```
    - `NumKeyPadAmountDisplay`: `:232` → `.font(.custom(AppFont.mono, fixedSize: 28))`, `:233` → `Color.inkSecondary`; `:242`, `:251`, `:257` → `.font(.custom(AppFont.mono, fixedSize: 52))`; `:252` `.tertiary` → `Color.inkSecondary`; add `.foregroundStyle(Color.ink)` on the `HStack` (`:230`); `:261` spring → `.easeOut(duration: 0.2)`.

13. **Remaining sites.**
    - `StatsCard.swift:17-19`: `.foregroundStyle(Color.ink)`, `.contentTransition(.opacity)`, `.animation(.easeOut(duration: 0.25), value: value)`. Leave `:21-23` (charts.md).
    - `BudgetEditor.swift:137`: `.red` → `Color.shu`. charts.md owns the rest of the stats colours there.
    - `SatoruWidgets/WidgetViews.swift:151`, `:203`, `:230` (over-budget text): owned by charts.md step 16, which runs before this doc. Verify only: `status.isOver ? Color.shu : Color.ink` and `tint: status.isOver ? Color.shu : nil`.

14. **Tests.**
    - New `LinguicaSubTrackerTests/MoneyFormatterTests.swift` (Swift Testing, same shape as `WidgetLogicTests.swift`):
    ```swift
    import Testing
    @testable import LinguicaSubTracker

    @MainActor @Suite("MoneyFormatter")
    struct MoneyFormatterTests {
        @Test("symbol follows settings.currencyCode, never a hardcoded CAD", arguments: [
            ("CAD", "$"), ("EUR", "€"), ("BRL", "R$"), ("GBP", "£"), ("JPY", "¥"), ("AUD", "AUD"),
        ])
        func followsSettings(code: String, symbol: String) {
            var s = AppSettings.default
            s.currencyCode = code
            #expect(MoneyFormatter.format(12.5, settings: s) == "\(symbol)12.50")
        }

        @Test func overrideWins() {
            #expect(MoneyFormatter.format(3, settings: .default, currencyCode: "GBP") == "£3.00")
        }

        @Test func exactIgnoresRoundAndAbbreviate() {
            var s = AppSettings.default
            s.roundAmounts = true; s.abbreviateLargeNumbers = true
            #expect(MoneyFormatter.format(1234.5, settings: s) == "$1k")
            #expect(MoneyFormatter.exact(1234.5, currencyCode: "USD") == "$1,234.50")
        }
    }
    ```
    - Add to `LinguicaSubTrackerTests/ThemeFontTests.swift` (registration and glyphs are already covered at `:8-18`) the assumption the fitting maths relies on:
    ```swift
    @Test("Fragment Mono advance is 0.618 em, so TotalView's 44...84 tuning holds")
    func monoAdvance() throws {
        let font = try #require(UIFont(name: AppFont.mono, size: 100))
        #expect(abs(("0" as NSString).size(withAttributes: [.font: font]).width - 61.8) < 0.5)
    }
    ```

15. **Build, test, verify** (see Verification). Profile the reveal: Instruments (SwiftUI + Animation Hitches) on the oldest supported device while paging months quickly. If hitches show, switch to the step 5 mask-wipe fallback.

## Preserve
- **`MoneyDisplay` / `TextAnimatedView` API:** `text`, `size`, `minSize`, `availableWidth`, `tint`, `onTapGesture` with `nil` attaching no gesture. `underline` is additive, default `nil`.
- **Fitting:** `fittedSize` formula and clamp (`min(minSize, size)` floor); `minimumScaleFactor` 0.9 with a width, `min(1, minSize/size)` without.
- **TotalView:** `Button(action:)` opens Stats (`HomeView.swift:40-42`), `.buttonStyle(.plain)`, `onGeometryChange` → `containerWidth`, `totalWidth`. No gesture of any kind added to the price.
- **HomeListView:** `onTapGesture: onStats` (`:76`) and the `@AppStorage("budget_cta_dismissed")` flow (`:17`).
- **BudgetDetailsSheet:** tap-to-edit (`:83`).
- **`MoneyFormatter.format`:** honours `currencyCode`, `roundAmounts`, `abbreviateLargeNumbers` (`AppSettings.swift:4-6`) and the `currencyCode:` override. It stays free of UIKit (widget target).
- **`TotalViewModel`** members used by `HomeListView`: `formattedTotal`, `budgetTint`, `hasBudget`, `categorySpends`, `budget(for:)`, `formatted`, `currentMonth`.
- **Accessibility:** the amount is one `Text`, read verbatim; the Button combines total, hanko ("Over budget") and the LEFT/OVER label; Reduce Motion honoured (pattern: `SyncToast.swift:7`, `CoinStack.swift:126`); `AmountField.hasError` and `ExpenseFormView.priceError` states stay.
- **No new `AppSettings` fields.** If one is ever added it must be optional (`AppSettings.swift:11-19`) with lenient enum decoding (`AppTheme.swift:15-18`).
- **DEBUG hooks:** `DEBUG_HOME_VIEW` and `DEBUG_MONTH_INDEX` (`HomeView.swift:84-98`), `DEBUG_WIDGET_GALLERY` (`HomeView.swift:100-101`), `DEBUG_OPEN_SHEET=budget` (`HomeListView.swift:60-63`).
- **Onboarding ripple heroes** and the rest of `RippleEffect.swift`/`Ripple.metal`: untouched (general_app_ui.md).

## Risks / gotchas
- **Docs vs code (code wins):**
  - The plan says tracking "~0"; the code ships `displayMedium.letterSpacing = -0.5` (`Typography.swift:10`). This doc reads the style, so retuning it there retunes the price.
  - general_app_ui.md writes the font as `Theme.FontName.regular.rawValue`; the code's shared name is `AppFont.mono` (in the widget-shared `AppTheme.swift`). Both equal `"FragmentMono-Regular"` (`ThemeFontTests.swift:10`). Use `AppFont.mono`.
  - general_app_ui.md §7 says to pair `InkReveal` with `.id(value)`. This doc drives it with `keyframeAnimator`; the Transition + `.id` route is the fallback below. `InkReveal`'s API (`progress`, `staggered`, `Animatable`) matches that contract.
- **Silent font fallback:** a wrong PostScript name makes `UIFont(name:)` nil; measurement then uses SF Mono while SwiftUI draws another font, so totals clip or float. `ThemeFontTests` catches it.
- **Dynamic Type:** `Theme.font` scales, `measuredWidth` does not. Every fitted amount uses `fixedSize:`. The hero total stays width-bound by design.
- **Keyframe first frame:** trigger and new text land in the same update. With Debug → Slow Animations, check no frame shows the new value fully inked before `MoveKeyframe(0)`. If one does, switch to Apple's Transition pattern: `private struct InkTransition: Transition` whose `body` is `content.transaction { if !$0.disablesAnimations { $0.animation = .easeOut(duration: 0.7) } } body: { $0.textRenderer(InkReveal(progress: phase.isIdentity ? 1 : 0)) }`, applied as `inked(at:).id(displayedValue).transition(.asymmetric(insertion: InkTransition(), removal: .identity))` inside a `ZStack`, with `withAnimation { displayedValue = new }` in `onChange` (a `VStack` parent would stack the outgoing and incoming `Text`).
- **Blur cost:** `addFilter(.blur)` runs per glyph per frame for 0.7s; the at-rest path skips filters. Never use the renderer in rows.
- **Shaders:** `InkReveal` is not a `layerEffect`, so it is safe near glass. Never reintroduce a `layerEffect` on or over the price (renders materials black).
- **Shared files:** `HomeListView.swift` (list_view.md owns `:178+`), `StatsCard.swift` (charts.md `:21-23`), `NumKeyPadSheet.swift` (forms.md keys), `BudgetColor.swift` + `BudgetEditor.swift` stats (charts.md), `AmountField.swift` `:16-18` and `ExpenseFormView.swift` (forms.md), `HomeExpenseRow`/`ExpenseRow`/`rowSubtitle` (list_view.md replaces them). Edit only the lines named here.
- **Widget target:** `BudgetMark`, `TextAnimatedView`, `HankoStamp`, `Theme.swift` and `Typography.swift` are app-only; never reference them from `SatoruWidgets/`. Shared: `AppTheme`, `BudgetColor`, `MoneyFormatter`, `AppSettings`.
- **Kanji in the hanko:** Fragment Mono has no CJK; `HankoStamp` must set `AppFont.kanjiBold` itself (charts.md), or CoreText falls back to a sans.
- **Deuteranopia:** light `shu` vs `kinText` is ΔE 0.4 (contrast 1.01) under simulation. The tiers stay distinct through LEFT/OVER and the stamp shape, never hue.

## Verification
- **Build:** `xcodebuild -project LinguicaSubTracker.xcodeproj -scheme LinguicaSubTracker -destination 'platform=iOS Simulator,id=9BF66402-1F99-44CB-89A9-03A7C31ECBD2' build`. If the simulator runs old code, delete Intermediates and rebuild with `COMPILATION_CACHE_ENABLE_CACHING=NO`.
- **Tests:** same destination, `test -only-testing:LinguicaSubTrackerTests/MoneyFormatterTests -only-testing:LinguicaSubTrackerTests/ThemeFontTests`, then the full suite.
- **Greps (each must return nothing):**
  - `grep -rn 'rippleOnTap\|monthRipple\|glowOpacity\|scaleBounce\|FluidFontSize' LinguicaSubTracker/Features/Home LinguicaSubTracker/Core/Utils/BudgetColor.swift`
  - `grep -n 'numericText\|spring' LinguicaSubTracker/Features/Home/Views/Components/TextAnimatedView.swift LinguicaSubTracker/Features/Home/Views/Components/TotalView.swift LinguicaSubTracker/Core/Components/MoneyDisplay.swift` (the earlier calendar pass removed the toolbar month title's `numericText`)
  - `grep -rn '\.currency(code' LinguicaSubTracker`
  - `grep -rn 'asPeriodCurrency' LinguicaSubTracker`
  - `grep -rn '"CAD"' LinguicaSubTracker` lists only `MoneyFormatter.swift:6`, `CurrencyMenu.swift`, `CurrencyPickerViewModel.swift:22`, `AppSettings.swift:22`, the two overwritten VM defaults and `@Previewable` previews.
- **Simulator** (light, then dark via Settings → Appearance; screenshot ~8s after a cold launch with `xcrun simctl io <udid> screenshot`):
  - Calendar total: `SIMCTL_CHILD_DEBUG_HOME_VIEW=calendar xcrun simctl launch <udid> com.dtx.LinguicaSubTracker`.
  - Reveal on month change: add `SIMCTL_CHILD_DEBUG_MONTH_INDEX=<n>` and record with `xcrun simctl io <udid> recordVideo`. Expect glyphs writing in left to right, underline trailing, everything settled by 0.7s, no scale bounce.
  - List total + budget sheet: `SIMCTL_CHILD_DEBUG_HOME_VIEW=list`, then `SIMCTL_CHILD_DEBUG_OPEN_SHEET=budget`.
  - Widgets: `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=month` and `month-dark`.
- **Tiers:** set a monthly budget (budget sheet) above, at ~80 % of, and below the current total. Expect calm (kin underline, blank row), near (kinText underline + LEFT), over (shu digits + hanko + OVER). No layout jump between calm and near.
- **Interactions:** tapping the calendar total opens Stats with no ripple or scale; tapping the list total opens Stats; tapping the budget amount in BudgetDetailsSheet opens the editor.
- **Currency:** switch to EUR, BRL, JPY. Summary sheet, day sheet, rows, keypad, widgets all show the new symbol; nothing shows `CA$`, or `$` for EUR.
- **Reduce Motion:** enable it; confirm with `xcrun simctl spawn <udid> defaults read com.apple.Accessibility ReduceMotionEnabled` (the simulator needs a reboot to apply a change). Expect a plain 0.25s fade, no blur, static underline.
- **VoiceOver:** the over-budget total reads roughly "$1,612.00, Over budget, $128.00 over, button".

## Open points / dig deeper
- **"All interactions … should be removed" (confirm with the user):** v1 reads the brief as the interaction *effects* (ripple, bounce, digit roll, glow) and keeps the plain tap → Stats, because `home_screen_ux.md` uses the total as the main Stats entry (the view menu also has Stats). If the user meant no tap at all, delete the `Button` in `TotalView` and the `onTapGesture: onStats` in `HomeListView`, and rely on the view menu.
- **Width tuning on real screens:** the 0.618 em advance is measured from the bundled TTF; re-tune both `44...84` and Large's `36...68` range with `totalInset` 20 from screenshots at the smallest supported width and with the Koyomi header and bottom calendar in place.
- **Verify on device — `keyframeAnimator` first frame:** confirm no fully inked flash on the trigger frame (Risks). Decides keyframe vs Transition driver.
- **Verify on device — Transition fallback:** confirm `.transition(.asymmetric(insertion: InkTransition(), removal: .identity))` removes the old value immediately, without overlap.
- **Verify on compile — isolation:** the app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Shapes already compile that way (`Torii.swift:4`); if Xcode flags `InkReveal`'s `TextRenderer` conformance, declare it `nonisolated private struct`.
- **Verify on SDK — `Text + Text`:** this doc uses interpolation either way; confirm whether the iOS 26 SDK warns on `+` before sweeping other call sites.
- **Reveal performance:** blur cost on the oldest supported device during fast paging. Decides renderer vs mask-wipe fallback.
- **Genkō digit cells:** faint `rule` cells behind the hero digits, one per 0.618 em advance, drawn in the same renderer ([tkgje genkōyōshi](https://www.tkgje.jp/entries/15500/15790_genkouyoushi.html)). Check legibility at large sizes and whether it competes with the Koyomi header. list_view.md rejects it for rows.
- **Kasure underline:** dry-brush streaks via a grayscale bristle-noise mask (`.luminanceToAlpha()`) or a scanned stroke asset replacing `BrushStroke`. Needs an asset and a licence decision.
- **Calm-tier underline:** kin vs no underline vs ink. In dark mode kin #D4A72C and kinText #E6B422 barely differ; test whether near needs more than the LEFT label.
- **JPY formatting:** `formatNumber` always prints two decimals (`¥1,200.00`) but the yen has no minor unit. Research a per-currency `fractionLength` in `MoneyFormatter` and its effect on widgets and the keypad's cents mode.
- **Hanko wording:** 赤字 alone, OVER alone or both for non-Japanese users; how Japanese users read a red total (red = rising on JP stock screens).
- **Bold Text:** Fragment Mono has one weight; `AppTextModifier` swaps to SF Mono semibold under `legibilityWeight == .bold` (`Theme.swift:43-45`), but the fitted price uses `fixedSize` Fragment Mono and cannot. Decide whether the hero follows (re-measure with the system mono) or stays.
- **`CoinProgress`:** no production caller after step 9; charts.md decides whether to delete it.

**Status: proposed, not implemented.**
