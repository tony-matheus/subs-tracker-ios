import SwiftUI

struct CurrencyPickerSheet: View {
    @State private var viewModel: CurrencyPickerViewModel
    @Environment(\.dismiss) private var dismiss

    init(settingsStore: SettingsStore) {
        _viewModel = State(initialValue: CurrencyPickerViewModel(settingsStore: settingsStore))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.currencies) { currency in
                Button {
                    viewModel.select(currency)
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

                        if viewModel.isSelected(currency) {
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
                    }
                }
            }
        }
    }
}

#Preview {
    CurrencyPickerSheetPreviewHost()
}
