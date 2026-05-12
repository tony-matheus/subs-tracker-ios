import SwiftUI

struct StatsSheet: View {
    @State private var viewModel: StatsViewModel

    init(store: AppStore, settingsStore: SettingsStore) {
        _viewModel = State(initialValue: StatsViewModel(store: store, settingsStore: settingsStore))
    }

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 16) {
            HStack {
                YearMenu(year: $vm.year, options: viewModel.yearOptions)
                Spacer()
                DimensionMenu(dimension: $vm.dimension)
            }

            Text(viewModel.activeCountLabel)
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            SpendDial(
                items: viewModel.items,
                selectedID: $vm.selectedID,
                totalLabel: viewModel.selectedAmountLabel,
                percentLabel: viewModel.selectedPercentLabel
            )
            .frame(height: 250)
            Spacer()

            HStack(spacing: 12) {
                StatsCard(title: "Yearly\nForecast", value: viewModel.forecastLabel)
                StatsCard(
                    title: "Average\nMonthly Cost",
                    value: viewModel.averageMonthlyLabel
                )
            }
        }
        .padding(20)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                YearMenu(year: $vm.year, options: viewModel.yearOptions)
            }
            ToolbarItem(placement: .topBarTrailing) {
                DimensionMenu(dimension: $vm.dimension)
            }
        }
    }
}

#Preview {
    StatsSheetPreviewHost()
}
