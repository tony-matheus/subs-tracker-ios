import SwiftUI

struct CurrencyPickerSheet: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    private let currencies: [(code: String, flag: String, symbol: String, name: String)] = [
        ("CAD", "🇨🇦", "$",  "Canadian Dollar"),
        ("USD", "🇺🇸", "$",  "US Dollar"),
        ("EUR", "🇪🇺", "€",  "Euro"),
        ("BRL", "🇧🇷", "R$", "Brazilian Real"),
        ("GBP", "🇬🇧", "£",  "British Pound"),
        ("JPY", "🇯🇵", "¥",  "Japanese Yen"),
    ]

    var body: some View {
        NavigationStack {
            List(currencies, id: \.code) { currency in
                Button {
                    settingsStore.settings.currencyCode = currency.code
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(currency.flag)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .typography(.titleSmall)
                                .foregroundStyle(.primary)
                            Text(currency.name)
                                .typography(.bodySmall)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(currency.symbol)
                            .typography(.titleMedium)
                            .foregroundStyle(.secondary)

                        if settingsStore.settings.currencyCode == currency.code {
                            Image(systemName: "checkmark")
                                .iconStyle(size: 14, weight: .semibold, color: .primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Main Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .iconStyle(size: 13, weight: .semibold, color: .secondary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CurrencyPickerSheet()
                .environmentObject(SettingsStore())
        }
}
