import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var subscriptionToDelete: Subscription?
    @State private var isSearchFocused: Bool = false

    @Environment(\.dismiss) private var dismiss

    let store: AppStore
    let settingsStore: SettingsStore
    let coordinator: AppCoordinator

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator
    ) {
        self.store = store
        self.settingsStore = settingsStore
        self.coordinator = coordinator
        _viewModel = State(
            initialValue: SearchViewModel(
                store: store,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel
        // Force re-evaluation on store changes (computed-prop tracking is
        // unreliable through @Observable chains — same pattern as HomeView).
        let _ = store.subscriptions
        let items = vm.displayedSubscriptions

        // `.searchable` requires a NavigationStack/SplitView ancestor; wrap
        // here so the cover host staysˆ simple. Native search bar lives in the
        // nav drawer, mic + dictation owned by iOS per Photos pattern.
        NavigationStack {
            VStack(spacing: 0) {
                header(vm: vm, totalCount: items.count)
                    .padding(.horizontal, 20)

                content(vm: vm, items: items)

                if vm.isSelectionMode {
                    bulkActionBar(vm: vm)
                }
            }
            .appBackground()
            .navigationBarTitleDisplayMode(.inline)
            .appSearchable(
                text: $vm.searchText,
                isPresented: $isSearchFocused,
                prompt: "Search your library...",
                onDismiss: {
                    dismiss()
                },
                dismissAlwaysPresent: true,
            )
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
        .onAppear {
            // Defer focus until the fullScreenCover presentation animation
            // settles; setting isPresented=true too early causes the keyboard
            // to intermittently not appear.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSearchFocused = true
            }
        }
        .sheet(isPresented: vm.selectedSubscriptionBinding()) {
            if let sub = vm.selectedSubscription {
                SubscriptionSummarySheet(
                    subscription: sub,
                    store: store,
                    settingsStore: settingsStore,
                    coordinator: coordinator
                )
            }
        }
        .sheet(isPresented: $vm.showAddSheet) {
            SubscriptionListSheet(
                date: Date(),
                store: store,
                settingsStore: settingsStore
            )
        }
        .alert(
            "Delete \"\(subscriptionToDelete?.name ?? "")\"?",
            isPresented: .init(
                get: { subscriptionToDelete != nil },
                set: { if !$0 { subscriptionToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let sub = subscriptionToDelete {
                    vm.delete(sub)
                }
                subscriptionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                subscriptionToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert(
            "Delete \(vm.selectionCount) subscription\(vm.selectionCount == 1 ? "" : "s")?",
            isPresented: $vm.showBulkDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                withAnimation { vm.deleteSelected() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header
    @ViewBuilder
    private func header(vm: SearchViewModel, totalCount: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if vm.isSelectionMode {
                Button {
                    if vm.selectionCount == totalCount {
                        vm.selectedIDs.removeAll()
                    } else {
                        vm.selectAll()
                    }
                } label: {
                    Text(
                        vm.selectionCount == totalCount && totalCount > 0
                            ? "Deselect All" : "Select All"
                    )
                    .typography(.bodyMedium.weight(.semibold))
                }
            } else {
                Text("All Subs")
                    .typography(.displaySmall.weight(.bold))
                    .foregroundStyle(.primary)
            }
            if !vm.storeIsEmpty {
                SortChip(
                    sort: vm.sort,
                    direction: vm.direction,
                    onPick: { vm.handleSortPick($0) }
                )
            }

            Spacer()
            if !vm.storeIsEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85))
                    {
                        if vm.isSelectionMode {
                            vm.exitSelectionMode()
                        } else {
                            vm.enterSelectionMode()
                        }
                    }
                } label: {
                    Label(
                        vm.isSelectionMode ? "Cancel" : "Select",
                        systemImage: "checkmark.circle"
                    )
                    .typography(.bodyMedium.weight(.semibold))
                }
            }
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Content (empty CTA / no matches / list)
    @ViewBuilder
    private func content(vm: SearchViewModel, items: [Subscription])
        -> some View
    {
        if vm.storeIsEmpty {
            emptyStoreCTA(vm: vm)
        } else if items.isEmpty {
            noMatchesState(query: vm.searchText)
        } else {
            list(vm: vm, items: items)
        }
    }

    @ViewBuilder
    private func list(vm: SearchViewModel, items: [Subscription]) -> some View {
        // `List` provides native cell virtualization — no memory leak risk
        // even with thousands of rows.
        List {
            ForEach(items) { sub in
                rowView(sub: sub, vm: vm)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !vm.isSelectionMode {
                            Button("Delete", systemImage: "trash") {
                                subscriptionToDelete = sub
                            }
                            .tint(.red)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.top, 12)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.85),
            value: vm.sort
        )
        .animation(
            .spring(response: 0.45, dampingFraction: 0.85),
            value: vm.direction
        )
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: vm.searchText
        )
    }

    @ViewBuilder
    private func rowView(sub: Subscription, vm: SearchViewModel) -> some View {
        HStack(spacing: 12) {
            if vm.isSelectionMode {
                Image(
                    systemName: vm.isSelected(sub)
                        ? "checkmark.circle.fill" : "circle"
                )
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(
                    vm.isSelected(sub) ? Color.accentColor : .secondary
                )
                .padding(.leading, 16)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            SubscriptionRow(subscription: sub) {
                if vm.isSelectionMode {
                    withAnimation(
                        .spring(response: 0.25, dampingFraction: 0.85)
                    ) {
                        vm.toggleSelection(sub)
                    }
                } else {
                    vm.selectSubscription(sub)
                }
            }
        }
        .contentShape(Rectangle())
        .animation(
            .spring(response: 0.3, dampingFraction: 0.85),
            value: vm.isSelectionMode
        )
    }

    // MARK: - Empty + no-match states
    @ViewBuilder
    private func emptyStoreCTA(vm: SearchViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No subscriptions yet")
                .typography(.titleLarge.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Track your first subscription to see it here.")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            AppButton(
                title: "Add Subscription",
                icon: "plus",
                style: .primary,
                appearance: .solid,
                action: { vm.showAddSheet = true }
            )
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    @ViewBuilder
    private func noMatchesState(query: String) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No matches for \"\(query)\"")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    // MARK: - Bulk action bar
    @ViewBuilder
    private func bulkActionBar(vm: SearchViewModel) -> some View {
        HStack {
            Text("\(vm.selectionCount) selected")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
            Spacer()
            AppButton(
                title: "Delete",
                icon: "trash",
                style: .destructive,
                appearance: .solid,
                size: .medium,
                action: { vm.showBulkDeleteAlert = true }
            )
            .disabled(!vm.hasSelection)
            .opacity(vm.hasSelection ? 1 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    let store = SearchPreviewData.makeDemoStore()
    let settingsStore = SettingsStore()
    let coordinator = AppCoordinator()
    return NavigationStack {
        SearchView(
            store: store,
            settingsStore: settingsStore,
            coordinator: coordinator
        )
    }
    .environment(store)
    .environment(settingsStore)
    .environment(coordinator)
}
