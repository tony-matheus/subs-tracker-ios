import SwiftUI

/// Lab component. A bottom-aligned overlay that owns the voice-capture view
/// model and composes the full hold-to-speak experience:
///
/// 1. `VoiceCaptureOverlay` — full-screen transcription HUD while active.
/// 2. `WaveformLine`        — live mic-level bar, shown while recording.
/// 3. `SpeechActionButton`  — pill ↔ orb button with the hold gesture.
///
/// Drop this into a `ZStack(alignment: .bottom)` on top of any host view to
/// activate the feature. Remove it and restore the plain `HomeActionButton`
/// in the bottom toolbar to disable it.
struct SpeechCaptureLayer: View {
    private let store: AppStore
    private let settingsStore: SettingsStore
    var isOnCurrentMonth: Bool
    var onAdd: () -> Void
    var onBackToCurrent: () -> Void

    @State private var voiceViewModel: VoiceCaptureViewModel

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        isOnCurrentMonth: Bool,
        onAdd: @escaping () -> Void,
        onBackToCurrent: @escaping () -> Void
    ) {
        self.store = store
        self.settingsStore = settingsStore
        self.isOnCurrentMonth = isOnCurrentMonth
        self.onAdd = onAdd
        self.onBackToCurrent = onBackToCurrent
        _voiceViewModel = State(
            initialValue: VoiceCaptureViewModel(store: store, settingsStore: settingsStore)
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if voiceViewModel.isActive {
                VoiceCaptureOverlay(viewModel: voiceViewModel)
                    .transition(.opacity)
            }

            // Negative padding drops the pill onto the bottom-bar line so it
            // sits exactly where the original toolbar button did.
            VStack(spacing: 16) {
                if voiceViewModel.isRecording {
                    WaveformLine(level: voiceViewModel.level)
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .transition(
                            .opacity.combined(with: .move(edge: .bottom))
                        )
                }
                SpeechActionButton(
                    voiceViewModel: voiceViewModel,
                    isOnCurrentMonth: isOnCurrentMonth,
                    onAdd: onAdd,
                    onBackToCurrent: onBackToCurrent
                )
            }
            .padding(.bottom, -4)
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85),
            value: voiceViewModel.isActive
        )
    }
}

#Preview {
    let store = HomePreviewData.makeStore()
    let settingsStore = HomePreviewData.makeSettingsStore()

    ZStack(alignment: .bottom) {
        Color.black.ignoresSafeArea()

        SpeechCaptureLayer(
            store: store,
            settingsStore: settingsStore,
            isOnCurrentMonth: true,
            onAdd: {},
            onBackToCurrent: {}
        )
    }
}
