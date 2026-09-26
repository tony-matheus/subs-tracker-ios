# Phase 6: Visual Intelligence + Smart Receipts

Flags (project-level Active Compilation Conditions), each removable on its own:
- `FF_SMART_RECEIPTS`: the in-app scanner upgrade.
- `FF_VISUAL_INTELLIGENCE`: Satoru as a Visual Intelligence result.

## Findings
- **Visual Intelligence can't improve the in-app camera.** Its API (`IntentValueQuery` + `SemanticContentDescriptor`) is an entry point: when the user points Visual Intelligence at something, apps can offer results.
- **SDK availability:** the `VisualIntelligence` framework ships only in the **device** SDK. The query is wrapped in `canImport(VisualIntelligence)` and can't run on the simulator.
- **Where the scanner improvement comes from:** iOS 26 Vision (`RecognizeDocumentsRequest`) and on-device FoundationModels.

## Smart receipts (`FF_SMART_RECEIPTS`)
- **OCR** (`ReceiptOCRService`): document recognition (`RecognizeDocumentsRequest`) maps its lines to the existing `OCRToken`s. It falls back to `VNRecognizeTextRequest` when it finds nothing or the flag is off.
- **Parsing** (`ReceiptSmartParser`):
  - FoundationModels guided generation (`GeneratedReceipt`) reads the OCR lines and returns items with name, price and category.
  - **Grounding:** an item is kept only if its price is printed on the receipt (checked with `ReceiptParser.priceValue` over the tokens) and its name isn't a summary line (`ReceiptParser.noiseKeywords`).
  - Confidence comes from the token that printed the price. Categories snap through `VoiceExpenseParser.snapCategory`.
  - It falls back to the heuristic `ReceiptParser` when the model is unavailable, fails, or nothing survives grounding.
- **Saving:** `ScannedExpenseItem.category` carries the model's category. The default stays "Entertainment" when there isn't one.

## Visual Intelligence (`FF_VISUAL_INTELLIGENCE`)
- **`Core/Intents/ReceiptVisualIntelligence.swift`:**
  - **`ReceiptVisualQuery`** (device only): converts the pixel buffer to a `CGImage`, then runs the same OCR and smart parse. It returns a `ReceiptCaptureEntity` ("Add 3 items to Satoru · Latte, Sesame Bagel, Orange Juice · $12.70"), or nothing if the image isn't a receipt with items.
  - **`OpenReceiptCaptureIntent`** (an `OpenIntent`) sets `IntentRouter.pendingReceiptID`. The app root then presents `ReceiptScanSheet` prefilled through `ReceiptScanViewModel(items:)`.
  - **Result cache:** results sit in the in-memory `ReceiptCaptureCache` (a `ponytail:` note covers persisting them if needed).

## Verification
- **Tests:**
  - `ReceiptSmartParserTests`: grounding keeps printed prices, drops invented prices, summary lines and short names, and snaps categories. There's also a fallback test for when no model is present.
  - `ReceiptOCRIntegrationTests`: the heuristic pipeline passes through document OCR, and the new `smartPipelineExtractsGroundedItems` runs the real on-device model (available on this simulator) and gets 3 grounded items with no totals.
- **Simulator:** `SIMCTL_CHILD_DEBUG_SCAN_SAMPLE=1` runs a rendered receipt through the Visual Intelligence capture path. The review opened with Latte 5.50, Sesame Bagel 3.20 and Orange Juice 4.00, and "Add 3" saved them.
- **Device build:** `xcodebuild -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` compiles `ReceiptVisualQuery`, and it appears in `Metadata.appintents`. With the flags off it's absent.
- **Manual (Apple Intelligence iPhone):** use Visual Intelligence on a paper receipt, check that Satoru's result appears, tap it and confirm the review sheet.

**Status: implemented. The Visual Intelligence check on a device is still pending.**
