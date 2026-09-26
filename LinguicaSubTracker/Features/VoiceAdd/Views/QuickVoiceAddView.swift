#if FF_QUICK_ADD
import SwiftUI

/// Voice capture opened by the Quick Add control: listens right away in
/// English, tap the mic to stop (no hold), then the usual review rows.
/// Reuses the Lab capture pieces (`VoiceCaptureViewModel`, `VoiceCaptureOverlay`).
struct QuickVoiceAddView: View {
    @State private var viewModel: VoiceCaptureViewModel
    private let onClose: () -> Void

    init(store: AppStore, settingsStore: SettingsStore, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: VoiceCaptureViewModel(
            store: store,
            settingsStore: settingsStore,
            // English first; the service falls back to any English locale.
            locale: Locale(identifier: "en-US")
        ))
        self.onClose = onClose
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VoiceCaptureOverlay(viewModel: viewModel, holdToSpeak: false)

            VStack(spacing: 16) {
                if viewModel.isRecording {
                    WaveformLine(level: viewModel.level)
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                micButton
            }
            .padding(.bottom, 20)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isRecording)
        .onAppear { viewModel.beginHold() }
        // Save, discard and close all end in `dismiss()`, which clears isActive.
        .onChange(of: viewModel.isActive) { _, active in
            if !active { onClose() }
        }
    }

    private var micButton: some View {
        Button {
            viewModel.isRecording ? viewModel.endHold() : viewModel.beginHold()
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? Color("AppPurple") : Color.appSurface)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                if viewModel.isProcessing {
                    ProgressView()
                } else {
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(viewModel.isRecording ? Color.white : Color.primary)
                }
            }
            .frame(width: 68, height: 68)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing)
        .accessibilityLabel(viewModel.isRecording ? "Stop listening" : "Start listening")
    }
}
#endif
