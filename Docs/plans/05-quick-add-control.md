# Phase 5: Quick Add Control (English voice)

Flag: `FF_QUICK_ADD` (project-level Active Compilation Condition). Remove it and the control, the intent and the voice overlay all drop out of the build.

## What it does
- A **"Speak an Expense"** control for Control Center, the Lock Screen and the Action Button.
- One press opens Satoru already listening. You say something like "Coffee four fifty and lunch twelve dollars yesterday", tap stop, review the rows and add them.
- Speech is **on-device** (`SpeechAnalyzer`/`SpeechTranscriber`, iOS 26) and English only for now: it asks for `en-US` and falls back to any English locale.
- **Understanding is natural language:** when recording stops, the whole transcript is re-read by the on-device **FoundationModels** model through `VoiceExpenseParser.naturalParse`, which extracts name, amount, day and category.
  - Regex is kept only for the instant live preview, and as the fallback on devices without Apple Intelligence.
- **No-code alternative:** the existing Siri "Add Transaction" shortcut can also be assigned to the Action Button. It asks for the name and price by voice.

## How it works
- **`Core/Intents/QuickAddIntent.swift`** (shared with the widget): `QuickAddIntent` with `supportedModes = .foreground`. It runs in the app and sets `IntentRouter.pendingQuickAdd`.
- **`Core/Intents/IntentRouter.swift`**: an observable hand-off from intents to the UI, registered with `AppDependencyManager`.
- **`SatoruWidgets/QuickAddControl.swift`**: a `ControlWidgetButton`, added to the bundle under `#if FF_QUICK_ADD`.
- **`Features/VoiceAdd/Views/QuickVoiceAddView.swift`**: reuses the Lab `VoiceCaptureViewModel` and `VoiceCaptureOverlay` with tap-to-talk. The app root overlays it while `pendingQuickAdd` is set.
- **`SpeechTranscriptionService`**:
  - takes a `locale` (see `pickLocale`, which is tested)
  - reports "not available on this device" when `SpeechTranscriber.isAvailable` is false

## Verification
- Tests: `SpeechLocaleTests` (exact match, same-language fallback, unsupported).
- Metadata: `QuickAddIntent` is in both the app and extension `Metadata.appintents` when the flag is on, and in neither when it's off.
- Simulator: `SIMCTL_CHILD_DEBUG_QUICK_ADD=1` opens the overlay and asks for the microphone. The simulator has no on-device transcriber, so it shows the "not available on this device" message.
- Device (manual):
  - Add the control to Control Center.
  - Press it and say two expenses.
  - Check that FoundationModels splits them correctly, then add them.

**Status: implemented. Checking speech on a device is still pending.**
