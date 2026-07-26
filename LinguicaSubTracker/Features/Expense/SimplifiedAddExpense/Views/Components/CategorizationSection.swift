import SwiftUI

/// Type / Category / List / Paid with — the four "what kind of thing is this"
/// pickers, all driven by the same menu-style `AppPicker`.
struct CategorizationSection: View {
    @Binding var type: ExpenseType
    @Binding var category: String
    @Binding var list: String
    @Binding var paymentMethod: String

    let categoryOptions: [(value: String, label: String)]
    let listOptions: [(value: String, label: String)]
    let paymentOptions: [(value: String, label: String)]

    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 0) {
            FormRow(
                label: "Type",
                icon: "tag.fill",
                iconColor: tint,
                labelColor: tint
            ) {
                AppPicker(
                    title: "",
                    selection: $type,
                    options: ExpenseType.allCases.map {
                        (value: $0, label: $0.displayName)
                    },
                    tint: tint
                )
                .fixedSize(horizontal: true, vertical: false)
            }

            Divider()

            FormRow(
                label: "Category",
                icon: "folder.fill",
                iconColor: tint,
                labelColor: tint
            ) {
                AppPicker(
                    title: "",
                    selection: $category,
                    options: categoryOptions,
                    tint: tint
                )
                .fixedSize(horizontal: true, vertical: false)
            }

            Divider()

            FormRow(
                label: "List",
                icon: "list.dash",
                iconColor: tint,
                labelColor: tint
            ) {
                AppPicker(
                    title: "",
                    selection: $list,
                    options: listOptions,
                    tint: tint
                )
                .fixedSize(horizontal: true, vertical: false)
            }

            Divider()

            FormRow(
                label: "Paid with",
                icon: "wallet.bifold.fill",
                iconColor: tint,
                labelColor: tint
            ) {
                AppPicker(
                    title: "",
                    selection: $paymentMethod,
                    options: paymentOptions,
                    tint: tint
                )
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        // Row icons cost horizontal space. Menu pickers ignore `lineLimit`
        // on their label, so pin each to its ideal width instead — otherwise
        // "Entertainment" wraps mid-word.
        .lineLimit(1)
    }
}

#Preview {
    @Previewable @State var type: ExpenseType = .subscription
    @Previewable @State var category = "Entertainment"
    @Previewable @State var list = "Personal"
    @Previewable @State var payment = "None"

    ZStack {
        LinearGradient(colors: [.purple, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        LabeledSection("Categorization", titleColor: .white.opacity(0.85)) {
            CategorizationSection(
                type: $type,
                category: $category,
                list: $list,
                paymentMethod: $payment,
                categoryOptions: [
                    (value: "Entertainment", label: "Entertainment"),
                    (value: "Utilities", label: "Utilities"),
                ],
                listOptions: [
                    (value: "Personal", label: "Personal"),
                    (value: "Work", label: "Work"),
                ],
                paymentOptions: [
                    (value: "None", label: "None"),
                    (value: "Credit Card", label: "Credit Card"),
                ],
                tint: .white
            )
        }
        .padding()
    }
}
