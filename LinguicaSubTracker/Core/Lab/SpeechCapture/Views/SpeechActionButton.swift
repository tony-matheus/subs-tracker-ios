import SwiftUI

/// Lab component. The floating action button that supports both a plain tap
/// and a WhatsApp-style hold-to-speak gesture.
///
/// Tap  → calls `onAdd` or `onBackToCurrent` depending on calendar position.
/// Hold → arms `VoiceCaptureViewModel` for speech capture after 250 ms.
///
/// Rendering is delegated to `SpeechPillButton` (pill ↔ orb morph) so this
/// file stays focused on gesture and state.
struct SpeechActionButton: View {
    let voiceViewModel: VoiceCaptureViewModel
    var isOnCurrentMonth: Bool
    var onAdd: () -> Void
    var onBackToCurrent: () -> Void

    @State private var holdTask: Task<Void, Never>?
    @State private var holdDidBegin = false

    var body: some View {
        ZStack {
            if voiceViewModel.isRecording {
                // Glowing ring, breathing with the mic level.
                Circle()
                    .stroke(Color.appPurple.opacity(0.7), lineWidth: 3)
                    .frame(width: 82, height: 82)
                    .blur(radius: 5)
                    .scaleEffect(1 + CGFloat(voiceViewModel.level) * 0.14)
                    .animation(
                        .spring(response: 0.22, dampingFraction: 0.6),
                        value: voiceViewModel.level
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }

            SpeechPillButton(
                isOnCurrentMonth: isOnCurrentMonth,
                isRecording: voiceViewModel.isRecording,
                isProcessing: voiceViewModel.isProcessing
            )
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: voiceViewModel.isRecording
        )
        // WhatsApp-style hold: touch-down arms a short timer; finger movement
        // never cancels it (unlike LongPressGesture's 10pt limit, which made
        // holds silently fail). Release before the timer = plain tap.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard holdTask == nil else { return }
                    holdTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(250))
                        guard !Task.isCancelled else { return }
                        holdDidBegin = true
                        voiceViewModel.beginHold()
                    }
                }
                .onEnded { _ in
                    holdTask?.cancel()
                    holdTask = nil
                    // MainActor serialization: after cancel() the pending
                    // timer body can no longer flip holdDidBegin.
                    if holdDidBegin {
                        holdDidBegin = false
                        voiceViewModel.endHold()
                    } else if !voiceViewModel.isActive {
                        if isOnCurrentMonth {
                            onAdd()
                        } else {
                            onBackToCurrent()
                        }
                    }
                }
        )
    }
}
