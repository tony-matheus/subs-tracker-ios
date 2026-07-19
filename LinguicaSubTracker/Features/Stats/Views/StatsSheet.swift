import SwiftUI

struct StatsSheet: View {
    @State private var viewModel: StatsViewModel
    @State private var viewMode: ViewMode = .breakdown
    @Environment(\.dismiss) private var dismiss

    enum ViewMode: Hashable {
        case breakdown, trend
    }

    init(store: AppStore, settingsStore: SettingsStore) {
        _viewModel = State(initialValue: StatsViewModel(store: store, settingsStore: settingsStore))
    }

    /// Card header: period title + Monthly/Yearly scale switch.
    private func scaleHeader(vm: StatsViewModel, title: String) -> some View {
        @Bindable var vm = vm
        return HStack {
            Text(title)
                .typography(.titleSmall)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)

            Spacer()

            AppPicker(
                title: "",
                selection: $vm.scale,
                options: StatsScale.allCases.map { (value: $0, label: $0.label) },
                pickerStyle: .segmented
            )
            .frame(width: 160)
        }
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            statsContent(vm: vm)
                .appBackground()
                .navigationTitle("Stats")
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

    private func statsContent(vm: StatsViewModel) -> some View {
        @Bindable var vm = vm

        return ScrollView {
            VStack(spacing: 16) {
                HStack {
                    YearMenu(year: $vm.year, options: viewModel.yearOptions)
                    Spacer()
                    DimensionMenu(dimension: $vm.dimension)
                }

                CustomSegmentedPicker(
                    selection: $viewMode,
                    segments: [
                        .init(value: .breakdown,
                              leading: { Image(systemName: "chart.pie.fill").iconStyle(size: 14, weight: .semibold, color: .secondary) },
                              center: { Text("Breakdown").typography(.bodyMedium.weight(.semibold)) }),
                        .init(value: .trend,
                              leading: { Image(systemName: "chart.bar.fill").iconStyle(size: 14, weight: .semibold, color: .secondary) },
                              center: { Text("Trend").typography(.bodyMedium.weight(.semibold)) }),
                    ]
                )

                Text(viewModel.activeCountLabel)
                    .typography(.bodyMedium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                switch viewMode {
                case .breakdown:
                    Group {
                        GlassSection {
                            VStack(spacing: 12) {
                                scaleHeader(vm: vm, title: viewModel.breakdownTitle)

                                SpendDial(
                                    items: viewModel.items,
                                    selectedID: $vm.selectedID,
                                    totalLabel: viewModel.selectedAmountLabel,
                                    percentLabel: viewModel.selectedPercentLabel
                                )
                                .frame(height: 250)
                            }
                        }

                        if !viewModel.items.isEmpty {
                            GlassSection {
                                StatsLegendList(
                                    items: viewModel.items,
                                    total: viewModel.total,
                                    selectedID: $vm.selectedID,
                                    format: viewModel.format
                                )
                            }
                            .contentInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                        }
                    }
                    .transition(.blurReplace.combined(with: .scale(0.96)))

                case .trend:
                    Group {
                        GlassSection {
                            VStack(alignment: .leading, spacing: 12) {
                                scaleHeader(
                                    vm: vm,
                                    title: vm.scale == .monthly
                                        ? "Monthly spend in \(String(vm.year))"
                                        : "Yearly spend"
                                )

                                SpendTrendChart(
                                    points: vm.scale == .monthly
                                        ? viewModel.monthlyTrendPoints
                                        : viewModel.yearlyTrendPoints,
                                    abbreviateLabels: vm.scale == .monthly
                                )
                                .frame(height: 220)
                            }
                        }

                        if !viewModel.expenseLineSeries.isEmpty {
                            GlassSection {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("By expense in \(String(vm.year))")
                                        .typography(.titleSmall)
                                        .foregroundStyle(.secondary)

                                    ExpenseLineChart(series: viewModel.expenseLineSeries)
                                        .frame(height: 240)
                                }
                            }
                        }
                    }
                    .transition(.blurReplace.combined(with: .scale(0.96)))
                }

                HStack(spacing: 12) {
                    StatsCard(title: "Yearly\nForecast", value: viewModel.forecastLabel)
                    StatsCard(
                        title: "Average\nMonthly Cost",
                        value: viewModel.averageMonthlyLabel
                    )
                }
            }
            .padding(20)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewMode)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.scale)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.year)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: vm.dimension)
    }
}

#Preview {
    StatsSheetPreviewHost()
}
