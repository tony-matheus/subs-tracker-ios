import SwiftUI

/// A `GlassSection` with its title sitting *outside* the card, so the label
/// reads against the page background instead of the material.
struct LabeledSection<Content: View>: View {
    let title: String
    var titleColor: Color = .secondary
    let content: Content

    init(
        _ title: String,
        titleColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleColor = titleColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .typography(.labelLarge)
                .foregroundStyle(titleColor)
                .padding(.horizontal, 8)

            GlassSection { content }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack(spacing: 24) {
            LabeledSection("Categorization", titleColor: .white.opacity(0.85)) {
                FormRow(label: "Type", labelColor: .white) {
                    Text("Subscription").typography(.bodyMedium)
                }
                Divider()
                FormRow(label: "Category", labelColor: .white) {
                    Text("Entertainment").typography(.bodyMedium)
                }
            }

            LabeledSection("More details") {
                FormRow(label: "Start Date") {
                    Text("Today").typography(.bodyMedium)
                }
            }
        }
        .padding()
    }
}
