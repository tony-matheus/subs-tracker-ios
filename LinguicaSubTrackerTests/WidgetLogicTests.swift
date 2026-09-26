import Foundation
import Testing

@testable import LinguicaSubTracker

nonisolated private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}

@MainActor
@Suite("Widget logic")
struct WidgetLogicTests {

    @Test("week budget prorates the monthly budget by days in month", arguments: [
        (day(2026, 2, 10), 28.0), (day(2026, 9, 10), 30.0), (day(2026, 10, 10), 31.0),
    ])
    func weekBudget(date: Date, days: Double) {
        var settings = AppSettings.default
        settings.monthlyBudget = 1200
        #expect(settings.weekBudget(for: date) == 1200 * 7 / days)
        settings.monthlyBudget = nil
        #expect(settings.weekBudget(for: date) == nil)
    }

    @Test("effective budget: flexible grows to its slices, strict doesn't")
    func effectiveBudget() {
        var settings = AppSettings.default
        settings.monthlyBudget = 500
        settings.categoryBudgets = ["Lifestyle": 400, "Utilities": 300]
        #expect(settings.effectiveBudget == 700)
        settings.strictBudget = true
        #expect(settings.effectiveBudget == 500)
    }

    @Test("week interval starts Sunday and spans 7 days")
    func weekInterval() {
        let week = ExpenseService.weekInterval(containing: day(2026, 9, 23, hour: 15))  // Wednesday
        #expect(week.start == day(2026, 9, 20))
        #expect(week.end == day(2026, 9, 27))
    }

    @Test("upcoming keeps today through Saturday, drops the past and next week")
    func upcoming() {
        func one(_ name: String, _ date: Date) -> Expense {
            Expense(name: name, price: 5, billingCycle: .oneTime, type: .expense, startDate: date)
        }
        let items = ExpenseService.upcoming(from: day(2026, 9, 23, hour: 15), [
            one("Yesterday", day(2026, 9, 22)),
            one("Today", day(2026, 9, 23)),
            one("Saturday", day(2026, 9, 26)),
            one("Next Sunday", day(2026, 9, 27)),
        ])
        #expect(items.map(\.expense.name) == ["Today", "Saturday"])
    }

    @Test("deep links round-trip and reject unknown URLs")
    func deepLinks() {
        #expect(DeepLink(url: DeepLink.add.url) == .add)
        let date = day(2026, 9, 26)
        #expect(DeepLink.day(date).url.absoluteString == "satoru://day/2026-09-26")
        #expect(DeepLink(url: DeepLink.day(date).url) == .day(date))
        #expect(DeepLink(url: URL(string: "satoru://budget")!) == nil)
        #expect(DeepLink(url: URL(string: "https://day/2026-09-26")!) == nil)
    }

    @Test("storage migration moves a key into the shared suite once")
    func migration() throws {
        let old = try #require(UserDefaults(suiteName: "test.migration.old"))
        let new = try #require(UserDefaults(suiteName: "test.migration.new"))
        defer {
            old.removePersistentDomain(forName: "test.migration.old")
            new.removePersistentDomain(forName: "test.migration.new")
        }
        old.set(Data([1, 2, 3]), forKey: "expenses")

        StorageService.migrateIfNeeded("expenses", from: old, to: new)
        #expect(new.data(forKey: "expenses") == Data([1, 2, 3]))
        #expect(old.object(forKey: "expenses") == nil)

        // Already migrated: a stale old value must not overwrite the shared one.
        old.set(Data([9]), forKey: "expenses")
        StorageService.migrateIfNeeded("expenses", from: old, to: new)
        #expect(new.data(forKey: "expenses") == Data([1, 2, 3]))
    }
}
