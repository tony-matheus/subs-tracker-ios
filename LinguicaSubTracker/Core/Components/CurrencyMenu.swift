import SwiftUI

struct CurrencyMenu: View {
    @Binding var code: String

    private let currencies: [(code: String, symbol: String)] = [
        ("CAD", "$"),
        ("USD", "$"),
        ("EUR", "€"),
        ("BRL", "R$"),
        ("GBP", "£"),
        ("JPY", "¥"),
    ]

    private var symbol: String { MoneyFormatter.symbol(for: code) }

    var body: some View {
        Menu {
            ForEach(currencies, id: \.code) { item in
                Button {
                    code = item.code
                } label: {
                    Text("\(item.code) (\(item.symbol))")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("\(code) (\(symbol))")
                    .typography(.labelLarge)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .iconStyle(size: 11, weight: .semibold, color: .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .tint(.secondary)
        .accessibilityLabel("Currency")
    }
}

#Preview {
    @Previewable @State var code: String = "CAD"
    CurrencyMenu(code: $code)
        .padding()
        .background(.black)
}
