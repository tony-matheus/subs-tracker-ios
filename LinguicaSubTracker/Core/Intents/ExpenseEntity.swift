import AppIntents
import CoreSpotlight
import Foundation

/// A transaction as Siri, Shortcuts, Spotlight and Apple Intelligence see it.
struct ExpenseEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Transaction",
        numericFormat: "\(placeholder: .int) transactions"
    )
    static let defaultQuery = ExpenseQuery()

    let id: UUID
    @Property(title: "Name") var name: String
    @Property(title: "Amount") var amount: Double
    @Property(title: "Date") var date: Date
    @Property(title: "Category") var category: String
    /// Amount with the user's currency, e.g. "$4.50".
    let amountText: String

    /// `date` defaults to the start date; pass an occurrence date for
    /// recurring expenses found inside a period.
    init(_ expense: Expense, settings: AppSettings, date: Date? = nil) {
        id = expense.id
        amountText = MoneyFormatter.format(expense.price, settings: settings)
        self.name = expense.name
        self.amount = expense.price
        self.date = date ?? expense.startDate
        self.category = expense.category
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(amountText) · \(date.formatted(.dateTime.month(.abbreviated).day()))"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let set = CSSearchableItemAttributeSet()
        set.displayName = name
        set.contentDescription = "\(amountText) · \(category)"
        set.keywords = [category]
        return set
    }
}

struct ExpenseQuery: EntityStringQuery {
    @Dependency private var store: AppStore
    @Dependency private var settingsStore: SettingsStore

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ExpenseEntity] {
        let wanted = Set(identifiers)
        return store.expenses
            .filter { wanted.contains($0.id) }
            .map { ExpenseEntity($0, settings: settingsStore.settings) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ExpenseEntity] {
        let needle = string.trimmingCharacters(in: .whitespaces)
        return recent(store.expenses.filter { $0.name.localizedCaseInsensitiveContains(needle) })
    }

    @MainActor
    func suggestedEntities() async throws -> [ExpenseEntity] {
        Array(recent(store.expenses).prefix(10))
    }

    /// Newest first.
    @MainActor
    private func recent(_ expenses: [Expense]) -> [ExpenseEntity] {
        expenses
            .sorted { $0.startDate > $1.startDate }
            .map { ExpenseEntity($0, settings: settingsStore.settings) }
    }
}

/// Day choices for the add-expense phrase. A phrase can only interpolate an
/// enum or entity, so "Add an expense for yesterday" needs this.
enum ExpenseDay: String, AppEnum {
    case today, yesterday

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Day"
    static let caseDisplayRepresentations: [ExpenseDay: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "today", synonyms: ["now", "this day"]),
        .yesterday: DisplayRepresentation(title: "yesterday", synonyms: ["last night"]),
    ]

    var date: Date {
        let today = Calendar.current.startOfDay(for: .now)
        return self == .today ? today : Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }
}

enum SpendingPeriod: String, AppEnum {
    case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Period"
    static let caseDisplayRepresentations: [SpendingPeriod: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "today", synonyms: ["this day"]),
        .yesterday: "yesterday",
        .thisWeek: DisplayRepresentation(title: "this week", synonyms: ["the week", "my week", "week"]),
        .lastWeek: DisplayRepresentation(title: "last week", synonyms: ["previous week", "past week"]),
        .thisMonth: DisplayRepresentation(title: "this month", synonyms: ["the month", "my month", "month"]),
        .lastMonth: DisplayRepresentation(title: "last month", synonyms: ["previous month", "past month"]),
    ]

    /// Lowercase phrase for sentences, e.g. "this week".
    var spokenName: String {
        switch self {
        case .today: "today"
        case .yesterday: "yesterday"
        case .thisWeek: "this week"
        case .lastWeek: "last week"
        case .thisMonth: "this month"
        case .lastMonth: "last month"
        }
    }

    /// Half-open calendar interval (end = start of the next period).
    func interval(now: Date = .now, calendar: Calendar = .current) -> DateInterval {
        func period(_ component: Calendar.Component, offset: Int) -> DateInterval {
            let anchor = calendar.date(byAdding: component, value: offset, to: now) ?? now
            return calendar.dateInterval(of: component, for: anchor)
                ?? DateInterval(start: calendar.startOfDay(for: anchor), duration: 86_400)
        }
        switch self {
        case .today: return period(.day, offset: 0)
        case .yesterday: return period(.day, offset: -1)
        case .thisWeek: return period(.weekOfYear, offset: 0)
        case .lastWeek: return period(.weekOfYear, offset: -1)
        case .thisMonth: return period(.month, offset: 0)
        case .lastMonth: return period(.month, offset: -1)
        }
    }
}

/// Category names from Settings, offered as picker options in Shortcuts/Siri.
struct CategoryOptions: DynamicOptionsProvider {
    @Dependency private var settingsStore: SettingsStore

    @MainActor
    func results() async throws -> [String] {
        settingsStore.settings.categories.map(\.name)
    }
}

/// Keeps Spotlight (and Siri's semantic index) in step with local data.
enum ExpenseSpotlight {
    static func index(_ expenses: [Expense]) {
        guard !expenses.isEmpty else { return }
        let settings = StorageService.loadSettings()
        let entities = expenses.map { ExpenseEntity($0, settings: settings) }
        Task { try? await CSSearchableIndex.default().indexAppEntities(entities) }
    }

    static func remove(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        Task { try? await CSSearchableIndex.default().deleteAppEntities(identifiedBy: ids, ofType: ExpenseEntity.self) }
    }
}
