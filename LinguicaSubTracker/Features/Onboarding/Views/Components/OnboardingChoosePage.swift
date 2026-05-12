import SwiftUI

/// Final fork — doubles as the "edit anything" explainer. Shows the live
/// Netflix subscription card (tap it for a ripple), explains that anything can
/// be tweaked later, then offers the two paths: add a batch now (Next) or jump
/// straight into the app (Skip).
struct OnboardingChoosePage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            OnboardingEditingHero()
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Text("Edit anything, anytime")
                    .typography(.displaySmall)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text("Tap a subscription to tweak its price, schedule or logo. Add a few now, or jump straight in and add them whenever you like.")
                    .typography(.bodyLarge)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                AppButton(
                    title: "Add subscriptions",
                    icon: "arrow.right",
                    style: .primary,
                    appearance: .solid,
                    size: .large,
                    expands: true
                ) {
                    viewModel.go(to: .quickAdd)
                }

                AppButton(
                    title: "Skip",
                    style: .neutral,
                    appearance: .outline,
                    size: .large,
                    expands: true
                ) {
                    onFinish()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingChoosePage(
        viewModel: OnboardingViewModel(store: AppStore(), settingsStore: SettingsStore()),
        onFinish: {}
    )
    .appBackground()
}
