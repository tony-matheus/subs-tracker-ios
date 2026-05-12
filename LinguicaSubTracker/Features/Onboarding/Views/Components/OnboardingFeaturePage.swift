import SwiftUI

/// Shared layout for the feature-highlight pages: a centered hero with a
/// title + subtitle underneath. The hero is fixed-size (not scrollable) so
/// it can safely host `rippleOnDrag`.
struct OnboardingFeaturePage<Hero: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let hero: () -> Hero

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            hero()
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Text(title)
                    .typography(.displaySmall)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .typography(.bodyLarge)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingFeaturePage(
        title: "Your month at a glance",
        subtitle: "Every subscription lands on its renewal day."
    ) {
        OnboardingEditingHero()
    }
    .appBackground()
}
