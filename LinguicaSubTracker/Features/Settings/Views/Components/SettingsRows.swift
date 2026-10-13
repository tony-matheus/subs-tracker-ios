import SwiftUI

/// Settings cards share a 16-point horizontal inset; vertical insets can balance their contents.
struct SettingsCard<Content: View>: View {
    let content: Content
    let topInset: CGFloat
    let bottomInset: CGFloat

    init(
        topInset: CGFloat = 16,
        bottomInset: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.topInset = topInset
        self.bottomInset = bottomInset
    }

    var body: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 0) { content }
        }
        .contentInsets(.init(top: topInset, leading: 16, bottom: bottomInset, trailing: 16))
    }
}

struct SettingsRowLabel: View {
    let icon: String
    let title: String
    var description: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .iconStyle(size: 16, weight: .medium, color: Color.inkSecondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .typography(.bodyLarge)
                    .foregroundStyle(Color.ink)
                if let description {
                    Text(description)
                        .typography(.bodySmall)
                        .foregroundStyle(Color.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var description: String? = nil
    @Binding var isOn: Bool
    var onChange: (Bool) -> Void = { _ in }

    var body: some View {
        Toggle(isOn: $isOn) {
            SettingsRowLabel(icon: icon, title: title, description: description)
        }
        .toggleStyle(SwitchToggleStyle(tint: Color.shu))
        .settingsRowFrame()
        .onChange(of: isOn) { _, newValue in onChange(newValue) }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    var description: String? = nil
    var actionText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SettingsRowLabel(icon: icon, title: title, description: description)
                if let actionText, !actionText.isEmpty {
                    Text(actionText)
                        .typography(.bodyMedium)
                        .foregroundStyle(Color.inkSecondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .iconStyle(size: 12, weight: .semibold, color: Color.inkSecondary)
                    .accessibilityHidden(true)
            }
            .settingsRowFrame()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsRowFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minHeight: 44, alignment: .center)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func settingsRowFrame() -> some View {
        modifier(SettingsRowFrame())
    }
}
