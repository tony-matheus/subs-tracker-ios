import SwiftUI

/// Big tap target that shows the current amount and hands off to the keypad.
/// The error *message* is the caller's job — red on the card material washes
/// out, so it belongs outside the section next to the other form errors.
struct AmountField: View {
    let amount: Double
    let currencyCode: String
    var hasError: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(amount, format: .currency(code: currencyCode))
                .typography(.displaySmall)
                .foregroundStyle(hasError ? Color.red : Color.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: amount)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.teal, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack(spacing: 24) {
            LabeledSection("Amount", titleColor: .white.opacity(0.85)) {
                AmountField(amount: 15.99, currencyCode: "USD") {}
            }

            VStack(alignment: .leading, spacing: 6) {
                LabeledSection("Amount", titleColor: .white.opacity(0.85)) {
                    AmountField(amount: 0, currencyCode: "USD", hasError: true) {}
                }
                Text("Enter an amount above zero")
                    .typography(.bodySmall)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
            }
        }
        .padding()
    }
}
