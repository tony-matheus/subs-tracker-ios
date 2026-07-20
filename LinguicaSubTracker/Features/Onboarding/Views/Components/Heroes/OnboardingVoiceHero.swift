import SwiftUI

/// Voice-entry hero — a mic badge beside a live-looking waveform (reuses
/// `WaveformLine` fed with synthetic levels), with an example spoken phrase
/// underneath, mirroring the real hold-to-talk capture on Home.
struct OnboardingVoiceHero: View {
    @State private var level: Float = 0
    @State private var animation: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "mic.fill")
                    .iconStyle(size: 18, weight: .semibold, color: .white)
                    .frame(width: 44, height: 44)
                    .background(Color.appPurple.gradient, in: Circle())

                WaveformLine(level: level)
                    .frame(height: 36)
            }

            Text("“50 dollars on Safeway, 20 at Starbucks…”")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .rippleCard()
        .rippleOnTap()
        .onAppear { start() }
        .onDisappear { animation?.cancel() }
    }

    /// Random targets read as speech once `WaveformLine` eases between them.
    private func start() {
        animation?.cancel()
        animation = Task { @MainActor in
            while !Task.isCancelled {
                level = Float.random(in: 0.15...1.0)
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }
}

#Preview {
    OnboardingVoiceHero()
        .padding(32)
        .appBackground()
}
