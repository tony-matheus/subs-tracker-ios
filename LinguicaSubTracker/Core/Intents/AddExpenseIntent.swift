import AppIntents
import Foundation

/// Siri / Shortcuts entry point: adds a one-time expense to the calendar.
/// Writes through `StorageService` so it works whether or not the app is
/// running; the live `AppStore` re-reads on next foreground.
struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Expense"
    static let description = IntentDescription(
        "Adds an expense to your calendar.",
        categoryName: "Expenses"
    )

    @Parameter(title: "Name") var name: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Date") var date: Date?
    @Parameter(title: "Category") var category: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount)") {
            \.$date
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0 else {
            return .result(dialog: "I need a name and an amount above zero.")
        }

        // Snap a spoken category to an existing one; unknown → "Other".
        let categories = StorageService.loadSettings().categories.map(\.name)
        let snapped = category.flatMap { spoken in
            categories.first { $0.caseInsensitiveCompare(spoken) == .orderedSame }
        } ?? "Other"

        let day = Calendar.current.startOfDay(for: date ?? .now)
        var expenses = StorageService.load()
        expenses.append(
            Expense(
                name: trimmed,
                price: amount,
                billingCycle: .oneTime,
                type: .expense,
                startDate: day,
                category: snapped,
                list: "Personal"
            )
        )
        StorageService.save(expenses)

        return .result(dialog: "Added \(trimmed).")
    }
}

/// Surfaces the intent to Siri and the Shortcuts app.
struct SatoruShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Log an expense in \(.applicationName)",
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle.fill"
        )
    }
}
