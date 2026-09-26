import AppIntents
import Foundation
import FoundationModels

// Siri, Shortcuts and Apple Intelligence all run these same intents. They run
// in the app process and write through `AppStore`, so iCloud sync and the
// live UI pick up every change.

enum ExpenseIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notFound: "That transaction no longer exists."
        }
    }
}

// MARK: - Add

struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Transaction"
    static let description = IntentDescription(
        "Adds a one-time transaction to your calendar.",
        categoryName: "Transactions"
    )

    @Parameter(title: "Name", requestValueDialog: "What did you buy?")
    var name: String
    @Parameter(title: "Amount", requestValueDialog: "How much was it?")
    var amount: Double
    @Parameter(title: "Day")
    var day: ExpenseDay?
    @Parameter(title: "Date")
    var date: Date?
    @Parameter(title: "Category", optionsProvider: CategoryOptions())
    var category: String?

    @Dependency private var store: AppStore
    @Dependency private var settingsStore: SettingsStore

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount)") {
            \.$date
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ExpenseEntity> & ProvidesDialog {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw $name.needsValueError("What did you buy?") }
        guard amount > 0 else { throw $amount.needsValueError("It needs to be above zero. How much was it?") }

        let settings = settingsStore.settings
        let expense = Expense(
            name: trimmed,
            price: amount,
            billingCycle: .oneTime,
            type: .expense,
            startDate: Calendar.current.startOfDay(for: date ?? day?.date ?? .now),
            category: VoiceExpenseParser.snapCategory(category, to: settings.categories.map(\.name)),
            list: "Personal"
        )
        store.add(expense)

        let entity = ExpenseEntity(expense, settings: settings)
        return .result(value: entity, dialog: "Added \(trimmed), \(entity.amountText), in \(expense.category).")
    }
}

// MARK: - Edit

struct EditExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Edit Transaction"
    static let description = IntentDescription(
        "Changes the name, amount, date or category of a transaction.",
        categoryName: "Transactions"
    )

    @Parameter(title: "Transaction")
    var expense: ExpenseEntity
    @Parameter(title: "New Name")
    var name: String?
    @Parameter(title: "New Amount")
    var amount: Double?
    @Parameter(title: "New Date")
    var date: Date?
    @Parameter(title: "New Category", optionsProvider: CategoryOptions())
    var category: String?

    @Dependency private var store: AppStore
    @Dependency private var settingsStore: SettingsStore

    static var parameterSummary: some ParameterSummary {
        Summary("Edit \(\.$expense)") {
            \.$name
            \.$amount
            \.$date
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ExpenseEntity> & ProvidesDialog {
        guard var updated = store.expenses.first(where: { $0.id == expense.id }) else {
            throw ExpenseIntentError.notFound
        }
        // Nothing to change yet: the amount is the most common edit.
        if name == nil, amount == nil, date == nil, category == nil {
            throw $amount.needsValueError("What's the new amount?")
        }
        if let amount, amount <= 0 {
            throw $amount.needsValueError("It needs to be above zero. What's the new amount?")
        }

        let settings = settingsStore.settings
        if let name = name?.trimmingCharacters(in: .whitespaces), !name.isEmpty { updated.name = name }
        if let amount { updated.price = amount }
        if let date { updated.startDate = Calendar.current.startOfDay(for: date) }
        if let category {
            updated.category = VoiceExpenseParser.snapCategory(category, to: settings.categories.map(\.name))
        }
        store.update(updated)

        let entity = ExpenseEntity(updated, settings: settings)
        return .result(value: entity, dialog: "Updated \(updated.name), \(entity.amountText).")
    }
}

// MARK: - Delete

struct DeleteExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Delete Transaction"
    static let description = IntentDescription("Deletes a transaction.", categoryName: "Transactions")

    @Parameter(title: "Transaction")
    var expense: ExpenseEntity

    @Dependency private var store: AppStore

    static var parameterSummary: some ParameterSummary {
        Summary("Delete \(\.$expense)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let target = store.expenses.first(where: { $0.id == expense.id }) else {
            throw ExpenseIntentError.notFound
        }
        try await requestConfirmation(dialog: "Delete \(expense.name), \(expense.amountText)?")
        store.delete(target)
        return .result(dialog: "Deleted \(target.name).")
    }
}

// MARK: - Find

struct FindExpensesIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Transactions"
    static let description = IntentDescription(
        "Finds transactions by name, period or category.",
        categoryName: "Transactions"
    )

    @Parameter(title: "Search")
    var text: String?
    @Parameter(title: "Period")
    var period: SpendingPeriod?
    @Parameter(title: "Category", optionsProvider: CategoryOptions())
    var category: String?

    @Dependency private var store: AppStore
    @Dependency private var settingsStore: SettingsStore

    static var parameterSummary: some ParameterSummary {
        Summary("Find \(\.$text) transactions") {
            \.$period
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ExpenseEntity]> & ProvidesDialog {
        let settings = settingsStore.settings
        let needle = text?.trimmingCharacters(in: .whitespaces) ?? ""
        let matching = store.expenses.filter { expense in
            (needle.isEmpty || expense.name.localizedCaseInsensitiveContains(needle))
                && (category.map { expense.category.caseInsensitiveCompare($0) == .orderedSame } ?? true)
        }

        let entities: [ExpenseEntity]
        if let period {
            // One entity per expense, dated at its latest charge in the period.
            var latest: [UUID: (date: Date, expense: Expense)] = [:]
            for hit in ExpenseService.occurrences(in: period.interval(), matching) {
                latest[hit.expense.id] = hit
            }
            entities = latest.values
                .sorted { $0.date > $1.date }
                .map { ExpenseEntity($0.expense, settings: settings, date: $0.date) }
        } else {
            entities = matching
                .sorted { $0.startDate > $1.startDate }
                .map { ExpenseEntity($0, settings: settings) }
        }

        guard !entities.isEmpty else {
            return .result(value: [], dialog: "I didn't find any transactions.")
        }
        let listed = entities.prefix(5)
            .map { "\($0.name) \($0.amountText) \($0.date.formatted(.relative(presentation: .named)))" }
            .joined(separator: ", ")
        let more = entities.count > 5 ? ", and \(entities.count - 5) more" : ""
        return .result(value: entities, dialog: "Found \(entities.count): \(listed)\(more).")
    }
}

// MARK: - Summarize

struct SummarizeSpendingIntent: AppIntent {
    static let title: LocalizedStringResource = "Summarize Spending"
    static let description = IntentDescription(
        "Totals your spending for a period: count, top categories, biggest charge and budget left.",
        categoryName: "Transactions"
    )

    @Parameter(title: "Period", default: .thisWeek)
    var period: SpendingPeriod

    @Dependency private var store: AppStore
    @Dependency private var settingsStore: SettingsStore

    static var parameterSummary: some ParameterSummary {
        Summary("Summarize \(\.$period)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // "Spent" means charges up to today, not renewals later this period.
        let full = period.interval()
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? full.end
        let interval = DateInterval(start: full.start, end: max(full.start, min(full.end, endOfToday)))

        let settings = settingsStore.settings
        let summary = SpendingSummary(ExpenseService.occurrences(in: interval, store.expenses))
        let budgetLeft = period == .thisMonth ? settingsStore.effectiveBudget.map { $0 - summary.total } : nil
        let facts = summary.sentence(
            period: period.spokenName,
            budgetLeft: budgetLeft,
            format: { MoneyFormatter.format($0, settings: settings) }
        )
        let text = await SpendingSummary.naturalized(facts)
        return .result(value: text, dialog: "\(text)")
    }
}

extension SpendingSummary {
    /// Rephrases computed facts with the on-device model when available.
    /// Falls back to the template if the model drops or changes any number.
    static func naturalized(_ facts: String) async -> String {
        guard case .available = SystemLanguageModel.default.availability else { return facts }
        do {
            let session = LanguageModelSession(instructions: """
                Rewrite these spending facts as at most two short, friendly sentences \
                for a voice assistant. Keep every number and amount exactly as written. \
                Do not add facts, advice or greetings.
                """)
            let text = try await session.respond(to: facts).content
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let numbers = facts.matches(of: /\d[\d.,]*/)
                .map { String($0.output).trimmingCharacters(in: CharacterSet(charactersIn: ".,")) }
            return !text.isEmpty && numbers.allSatisfy(text.contains) ? text : facts
        } catch {
            return facts
        }
    }
}

// MARK: - Siri phrases

struct SatoruShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "Add a transaction in \(.applicationName)",
                "Add an expense for \(\.$day) in \(.applicationName)",
                "Log an expense for \(\.$day) in \(.applicationName)",
            ],
            shortTitle: "Add Transaction",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: SummarizeSpendingIntent(),
            phrases: [
                "Summarize my spending in \(.applicationName)",
                "Summarize \(\.$period) in \(.applicationName)",
                "How much did I spend \(\.$period) in \(.applicationName)",
                "What did I spend \(\.$period) in \(.applicationName)",
            ],
            shortTitle: "Summarize Spending",
            systemImageName: "chart.bar.fill"
        )
        AppShortcut(
            intent: FindExpensesIntent(),
            phrases: [
                "Find a transaction in \(.applicationName)",
                "Search transactions in \(.applicationName)",
                "Show \(\.$period) transactions in \(.applicationName)",
            ],
            shortTitle: "Find Transactions",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: EditExpenseIntent(),
            phrases: [
                "Edit a transaction in \(.applicationName)",
                "Change a transaction in \(.applicationName)",
            ],
            shortTitle: "Edit Transaction",
            systemImageName: "pencil"
        )
        AppShortcut(
            intent: DeleteExpenseIntent(),
            phrases: [
                "Delete a transaction in \(.applicationName)",
                "Remove a transaction in \(.applicationName)",
            ],
            shortTitle: "Delete Transaction",
            systemImageName: "trash"
        )
    }
}
