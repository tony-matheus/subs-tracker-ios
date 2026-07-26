import SwiftUI

/// Lab copy of the hold-to-speak pill → orb morph. Renamed so it can coexist
/// with the restored plain `HomeActionButton` in the same module.
///
/// At rest: a glass capsule pill ("Add expense" / "Today").
/// While the user holds and the mic is active: morphs into a purple recording orb.
/// Tap handling and gesture wiring live in `SpeechActionButton`; this view is
/// pure rendering.
struct SpeechPillButton: View {
    let isOnCurrentMonth: Bool
    var isRecording: Bool = false
    var isProcessing: Bool = false

    private var showsOrb: Bool { isRecording || isProcessing }

    var body: some View {
        ZStack {
            if showsOrb {
                orb
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else {
                pill
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        // Fixed to the pill's height so the (taller) orb overflows evenly and
        // both states share the same center — no jump when morphing.
        .frame(height: 44)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showsOrb)
        .accessibilityLabel(isOnCurrentMonth ? "Add expense" : "Today")
        .accessibilityHint("Double-tap to add. Touch and hold to speak expenses.")
    }

    /// The original bottom-bar pill, restored: icon + label in a glass capsule.
    private var pill: some View {
        ZStack {
            HStack(spacing: 8) {
                Image(systemName: isOnCurrentMonth ? "plus" : "arrow.uturn.left")
                    .foregroundStyle(
                        (isOnCurrentMonth ? Color.appAccent : Color.appPurple).gradient
                    )
                Text(isOnCurrentMonth ? "Add expense" : "Today")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.primary.gradient)
            .id(isOnCurrentMonth)
            .transition(.liquidRipple)
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.62),
            value: isOnCurrentMonth
        )
        .padding(.horizontal, 24)
        .frame(height: 44)
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    /// Recording state: compact purple orb with a live waveform.
    private var orb: some View {
        ZStack {
            Circle()
                .fill(Color.appPurple.gradient)
                .frame(width: 64, height: 64)
                .shadow(color: Color.appPurple.opacity(0.55), radius: 18, x: 0, y: 4)

            if isProcessing {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, isActive: isRecording)
            }
        }
        .scaleEffect(isRecording ? 1.15 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRecording)
    }
}

#Preview {
    struct Demo: View {
        @State var recording = false
        var body: some View {
            VStack(spacing: 40) {
                SpeechPillButton(isOnCurrentMonth: true, isRecording: recording)
                Button("Toggle recording") { recording.toggle() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
    return Demo()
}
