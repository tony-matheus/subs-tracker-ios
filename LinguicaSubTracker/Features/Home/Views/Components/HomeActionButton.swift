import SwiftUI

/// Home's primary action. At rest it's the classic "Add expense" text pill —
/// visually identical to the original toolbar button, so the hold-to-speak
/// easter egg stays hidden. While the user holds (~500ms), it morphs into a
/// purple recording orb; on release it springs back. Tap handling lives in
/// `HomeView`'s gesture, not here.
struct HomeActionButton: View {
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
        .accessibilityLabel(isOnCurrentMonth ? "Add expense" : "Back to current month")
        .accessibilityHint("Double-tap to add. Touch and hold to speak expenses.")
    }

    /// The original bottom-bar pill, restored: icon + label in a glass capsule.
    private var pill: some View {
        ZStack {
            HStack(spacing: 8) {
                Image(systemName: isOnCurrentMonth ? "plus" : "arrow.uturn.left")
                    .foregroundStyle(Color.appAccent.gradient)
                Text(isOnCurrentMonth ? "Add expense" : "Back to current")
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
                .fill(Color.purple.gradient)
                .frame(width: 64, height: 64)
                .shadow(color: Color.purple.opacity(0.55), radius: 18, x: 0, y: 4)

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
                HomeActionButton(isOnCurrentMonth: true, isRecording: recording)
                Button("Toggle recording") { recording.toggle() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
    return Demo()
}
