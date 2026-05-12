import SwiftUI

struct SubscriptionInDay: View {
    private let store: AppStore
    private let coordinator: AppCoordinator
    @State private var viewModel: SubscriptionInDayViewModel
    @State private var subscriptionPendingDeletion: Subscription?

    let settingsStore: SettingsStore

    init(
        date: Date,
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator
    ) {
        self.store = store
        self.coordinator = coordinator
        self.settingsStore = settingsStore
        _viewModel = State(
            initialValue: SubscriptionInDayViewModel(
                date: date,
                store: store,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel
        // Direct observation hook so the day-sheet rebuilds when a new
        // subscription is added on this date.
        let _ = store.subscriptions

        VStack(spacing: 0) {
            handle
            header

            ScrollView {
                VStack(spacing: 12) {
                    mainList(vm: vm)
                    totalBlock(vm: vm)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .appBackground()
        .presentationDetents([.height(viewModel.compactHeight)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $vm.showAddSheet) {
            SubscriptionListSheet(
                date: vm.date,
                store: vm.store,
                settingsStore: settingsStore
            )
        }
        .confirmationDialog(
            "Delete \(subscriptionPendingDeletion?.name ?? "")?",
            isPresented: deletionDialogBinding(),
            titleVisibility: .visible,
            presenting: subscriptionPendingDeletion
        ) { sub in
            Button("Delete current", role: .destructive) {
                vm.deleteFromCurrentDay(sub)
                subscriptionPendingDeletion = nil
            }
            Button("Delete all", role: .destructive) {
                vm.deleteAll(sub)
                subscriptionPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                subscriptionPendingDeletion = nil
            }
        } message: { _ in
            Text("Stop from this day forward, or remove the subscription entirely.")
        }
    }

    private func deletionDialogBinding() -> Binding<Bool> {
        Binding(
            get: { subscriptionPendingDeletion != nil },
            set: { if !$0 { subscriptionPendingDeletion = nil } }
        )
    }

    private var handle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("Subscriptions")
                .font(.headline)

            Text(viewModel.date, format: .dateTime.day().month(.wide).year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func mainList(vm: SubscriptionInDayViewModel) -> some View {
        let subs = vm.subscriptions
        let rowHeight: CGFloat = 64
        let rowInsets = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

        GlassSection {
            VStack(spacing: 0) {
                if !subs.isEmpty {
                    List {
                        ForEach(Array(subs.enumerated()), id: \.element.id) { index, sub in
                            subscriptionTile(sub, vm: vm)
                                .listRowBackground(Color.clear)
                                .listRowInsets(rowInsets)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        subscriptionPendingDeletion = sub
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .scrollClipDisabled()
                    .frame(height: CGFloat(subs.count) * rowHeight)
                }

                addRow(vm: vm)
                    .padding(rowInsets)
            }
        }
        .contentInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
    }

    private func subscriptionTile(
        _ sub: Subscription,
        vm: SubscriptionInDayViewModel
    ) -> some View {
        Button {
            vm.selectSubscription(sub)
        } label: {
            HStack(spacing: 12) {
                SubscriptionLogoCircle(
                    size: 40,
                    customization: sub.logoCustomization(in: vm.store),
                    logoName: sub.logoName,
                    name: sub.name
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(vm.rowSubtitle(for: sub))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func addRow(vm: SubscriptionInDayViewModel) -> some View {
        Button {
            vm.showAddSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Text("Add Subscription")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func totalBlock(vm: SubscriptionInDayViewModel) -> some View {
        GlassSection {
            HStack {
                Text("Total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(vm.total, format: .currency(code: "CAD"))
                    .font(.subheadline.weight(.bold))
            }
            .frame(height: 44)
        }
    }
}

#Preview {
    SubscriptionInDayPreviewHost()
}
