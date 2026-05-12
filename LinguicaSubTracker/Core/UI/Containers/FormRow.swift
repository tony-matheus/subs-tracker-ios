import SwiftUI

struct FormRow<Content: View>: View {
    let label: String
    var icon: String? = nil
    var iconColor: Color = .secondary
    var labelColor: Color = .secondary
    let content: Content

    init(
        label: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        labelColor: Color = .secondary,
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
            content.foregroundStyle(.primary)
        }
        .frame(height: 44)
    }
}
