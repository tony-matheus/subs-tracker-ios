import SwiftUI

struct FormRow<Content: View>: View {
    let label: String
    var icon: String? = nil
    var iconColor: Color = .inkSecondary
    var labelColor: Color = .inkSecondary
    let content: Content

    init(
        label: String,
        icon: String? = nil,
        iconColor: Color = .inkSecondary,
        labelColor: Color = .inkSecondary,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.labelColor = labelColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .iconStyle(size: 16, weight: .medium, color: iconColor)
                    .frame(width: 20)
            }
            Text(label)
                .typography(.bodyLarge)
                .foregroundStyle(labelColor)
            Spacer()
            content.foregroundStyle(Color.ink)
        }
        .frame(minHeight: 44)
    }
}
