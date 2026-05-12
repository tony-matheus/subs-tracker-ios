import SwiftUI

/// Mock subscription card built from the real Netflix `SubscriptionTemplate`
/// (logo + brand colors) — taps send a water-drop ripple through it.
struct OnboardingEditingHero: View {
    /// Netflix from the shared template catalog; falls back to a plain
    /// customization if the entry is ever renamed.
    private let template = SubscriptionTemplate.template(matching: "Netflix")

    var body: some View {
        Group {
            HStack(spacing: 16) {
                if let template {
                    SubscriptionLogoCircle(
                        size: 48,
                        customization: template.makeCustomization(id: template.id),
                        logoName: template.logo,
                        name: template.name
                    )
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(template?.name ?? "Netflix")
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                    Text("Entertainment · Monthly")
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("$16.99")
                    .typography(.titleMedium)
                    .foregroundStyle(.primary)
            }
        }
        .rippleCard()
        .rippleOnTap()
    }
}

#Preview {
    OnboardingEditingHero()
        .padding(32)
        .appBackground()
}
