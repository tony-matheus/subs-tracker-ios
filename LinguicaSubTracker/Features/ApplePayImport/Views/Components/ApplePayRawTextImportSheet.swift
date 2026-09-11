import SwiftUI

struct ApplePayRawTextImportSheet: View {
    @State private var textInput: String = ""
    @Environment(\.dismiss) private var dismiss

    var currencyCode: String = "BRL"
    let onImport: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Paste transaction text, CSV, or notification:")
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                        Text(currencyCode)
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.appPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.appPurple.opacity(0.12), in: Capsule())
                }

                TextEditor(text: $textInput)
                    .typography(.bodyMedium)
                    .padding(8)
                    .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Examples:")
                        .typography(.labelLarge)
                        .foregroundStyle(.primary)
                    Text("• Apple Pay: R$ 45,90 em Starbucks em 10/09\n• Uber Trip - $18.50 - Apple Pay\n• Date, Merchant, Amount\n  2026-09-10, Netflix, 55.90")
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                AppButton(
                    title: "Parse Transactions",
                    icon: "sparkles",
                    style: .primary,
                    expands: true
                ) {
                    onImport(textInput)
                    dismiss()
                }
                .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .appBackground()
            .navigationTitle("Paste Apple Pay Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ApplePayRawTextImportSheet(currencyCode: "BRL", onImport: { _ in })
}
