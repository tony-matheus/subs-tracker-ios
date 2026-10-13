import SwiftUI

/// A `GlassSection` with its title sitting *outside* the card, so the label
/// reads against the page background instead of the card.
struct LabeledSection<Content: View>: View {
    let title: String
    var titleColor: Color = .inkSecondary
    let content: Content

    init(
        _ title: String,
        titleColor: Color = .inkSecondary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleColor = titleColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title, color: titleColor)

            GlassSection { content }
        }
    }
}

#Preview {
    ZStack {
        Color.paper
            .ignoresSafeArea()

        VStack(spacing: 24) {
            LabeledSection("Categorization", titleColor: Color.inkSecondary) {
                FormRow(label: "Type", labelColor: Color.ink) {
                    Text("Subscription").typography(.bodyMedium)
                }
                Divider()
                FormRow(label: "Category", labelColor: Color.ink) {
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
