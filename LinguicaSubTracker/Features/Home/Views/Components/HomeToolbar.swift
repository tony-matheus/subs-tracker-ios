import SwiftUI

/// Which body the Home screen shows. Not persisted — resets to calendar on launch.
enum HomeViewType {
    case calendar
    case list

    /// Icon of the view this toggle switches *to*.
    var targetIcon: String {
        switch self {
        case .calendar: "list.bullet"
        case .list: "calendar"
        }
    }

    mutating func toggle() {
        self = self == .calendar ? .list : .calendar
    }
}

/// Every Home toolbar item in one place: the month picker and settings up top,
/// the filter/view pill top-leading, and the bottom bar's stats ring, add
/// button and search.
struct HomeToolbar: ToolbarContent {
    let monthKey: String
    let isFilterActive: Bool
    let lists: [ExpenseList]
    let categories: [AppCategory]
    let paymentMethods: [PaymentMethod]
    @Binding var selectedList: String?
    @Binding var selectedCategory: String?
    @Binding var selectedPayment: String?
    @Binding var viewType: HomeViewType
    var onClearFilter: () -> Void

    let isOnCurrentMonth: Bool
    let budgetRatio: Double
    let budgetTint: Color
    var onAdd: () -> Void
    var onBackToCurrent: () -> Void
    var onSearch: () -> Void
    var onStats: () -> Void
    var onMonthPicker: () -> Void
    var onSettings: () -> Void

    var body: some ToolbarContent {
        // Pill sits top-leading; the stats ring took its place in the bottom bar.
        ToolbarItem(placement: .topBarLeading) {
            leadingPill
        }

        ToolbarItem(placement: .principal) {
            monthButton
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .foregroundStyle(Color.primary.gradient.opacity(0.8))
            }
        }

        ToolbarItemGroup(placement: .bottomBar) {
            Button(action: onStats) {
                Image(systemName: "ring.dashed", variableValue: budgetRatio)
                    .font(.system(size: 18))
                    .foregroundStyle(budgetTint.gradient)
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.easeInOut, value: budgetRatio)
            }

            Spacer()

            HomeActionButton(
                isOnCurrentMonth: isOnCurrentMonth,
                onAdd: onAdd,
                onBackToCurrent: onBackToCurrent
            )

            Spacer()

            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
        }
    }

    private var monthButton: some View {
        Button(action: onMonthPicker) {
            HStack(spacing: 4) {
                Text(monthKey)
                    .typography(.headlineSmall)
                    .contentTransition(.numericText())
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8),
                        value: monthKey
                    )
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    /// WhatsApp-style double button: filter menu + calendar/list switch in one capsule.
    private var leadingPill: some View {
        HStack(spacing: 20) {
            filterMenu

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewType.toggle()
                }
            } label: {
                Image(systemName: viewType.targetIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.primary.gradient.opacity(0.8))
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(viewType == .calendar ? "Switch to list view" : "Switch to calendar view")
        }
        .padding(.horizontal, 4)
    }

    private var filterMenu: some View {
        Menu {
            Button(action: onClearFilter) {
                if isFilterActive {
                    Text("All Expenses")
                } else {
                    Label("All Expenses", systemImage: "checkmark")
                }
            }

            Divider()

            Menu("Lists") {
                Picker("Lists", selection: $selectedList) {
                    Text("All Lists").tag(String?.none)
                    ForEach(lists) { list in
                        Text(list.name).tag(String?.some(list.name))
                    }
                }
            }

            Menu("Categories") {
                Picker("Categories", selection: $selectedCategory) {
                    Text("All Categories").tag(String?.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(String?.some(category.name))
                    }
                }
            }

            Menu("Payment Methods") {
                Picker("Payment Methods", selection: $selectedPayment) {
                    Text("All Payments").tag(String?.none)
                    ForEach(paymentMethods) { method in
                        Text(method.name).tag(String?.some(method.name))
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 14))
                .foregroundStyle(Color.primary.gradient.opacity(0.8))
        }
    }
}

#Preview {
    struct Demo: View {
        @State var selectedList: String?
        @State var selectedCategory: String?
        @State var selectedPayment: String?
        @State var viewType: HomeViewType = .calendar

        var body: some View {
            NavigationStack {
                Text("Home content")
                    .toolbar {
                        HomeToolbar(
                            monthKey: "August 2026",
                            isFilterActive: false,
                            lists: [],
                            categories: [],
                            paymentMethods: [],
                            selectedList: $selectedList,
                            selectedCategory: $selectedCategory,
                            selectedPayment: $selectedPayment,
                            viewType: $viewType,
                            onClearFilter: {},
                            isOnCurrentMonth: true,
                            budgetRatio: 0.6,
                            budgetTint: .green,
                            onAdd: {},
                            onBackToCurrent: {},
                            onSearch: {},
                            onStats: {},
                            onMonthPicker: {},
                            onSettings: {}
                        )
                    }
            }
        }
    }
    return Demo()
}
