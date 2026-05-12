import SwiftUI

struct SubscriptionListSheet: View {
    @State private var viewModel: SubscriptionListSheetViewModel
    @State private var isSearchFocused: Bool = false
    @Environment(\.dismiss) private var dismiss

    let store: AppStore
    let settingsStore: SettingsStore

    init(date: Date, store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        _viewModel = State(
            initialValue: SubscriptionListSheetViewModel(date: date)
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                if vm.showEmptyCTA {
                    emptyCTA(vm: vm)
                        .padding()
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 8
                    ) {
                        ForEach(vm.filteredServices) { service in
                            Button {
                                vm.selectTemplate(service)
                            } label: {
                                VStack(spacing: 8) {
                                    SubscriptionLogoCircle(
                                        size: 48,
                                        customization:
                                            service.makeCustomization(
                                                id: service.id
                                            ),
                                        logoName: service.logo,
                                        name: service.name
                                    )

                                    Text(service.name)
                                        .typography(.bodyMedium)
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
            }
            .appSearchable(
                text: $vm.searchText,
                isPresented: $isSearchFocused,
                prompt: "Search"
            )
            .appBackground()
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.createBlank()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.green.gradient)
                }
            }
            .navigationDestination(item: $vm.selectedService) { service in
                SubscriptionFormView(
                    mode: .create(template: service, date: vm.date),
                    store: store,
                    settingsStore: settingsStore,
                    onCommit: { _ in dismiss() }
                )
            }
            .navigationDestination(item: $vm.blankRoute) { route in
                SubscriptionFormView(
                    mode: .createBlank(name: route.name, date: vm.date),
                    store: store,
                    settingsStore: settingsStore,
                    onCommit: { _ in dismiss() }
                )
            }
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func emptyCTA(vm: SubscriptionListSheetViewModel) -> some View {
        Button {
            vm.createBlankWithSearch()
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.primary)

                VStack(spacing: 4) {
                    Text("Create \"\(vm.searchText)\"")
                        .typography(.titleLarge.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text("Build a custom subscription")
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SubscriptionListSheetPreviewHost()
}
