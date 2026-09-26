import Foundation
import Testing

@testable import LinguicaSubTracker

@MainActor
private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
}

@MainActor
private func expense(_ name: String, _ price: Double, _ cycle: BillingCycle, _ start: Date, _ category: String) -> Expense {
    Expense(name: name, price: price, billingCycle: cycle, type: .expense, startDate: start, category: category)
}

@MainActor
@Suite("Siri spending summary")
struct SpendingSummaryTests {

    // Week of Sun Sep 20 – Sat Sep 26, 2026 (half-open end Sep 27).
    let week = DateInterval(start: day(2026, 9, 20), end: day(2026, 9, 27))

    @Test("occurrences count one-time charges in range and monthly renewals once")
    func occurrencesInWeek() {
        let expenses = [
            expense("Coffee", 4.5, .oneTime, day(2026, 9, 22), "Food"),
            expense("Groceries", 52, .oneTime, day(2026, 9, 25), "Food"),
            expense("Outside", 99, .oneTime, day(2026, 9, 27), "Other"),   // day after the range
            expense("Netflix", 15, .monthly, day(2026, 3, 24), "Entertainment"),
            expense("Rent", 1200, .monthly, day(2026, 1, 1), "Housing"),     // renews on the 1st
        ]
        let hits = ExpenseService.occurrences(in: week, expenses)
        #expect(hits.map(\.expense.name).sorted() == ["Coffee", "Groceries", "Netflix"])
        #expect(hits.first { $0.expense.name == "Netflix" }?.date == day(2026, 9, 24))
    }

    @Test("summary totals, top category and biggest charge")
    func summary() {
        let hits = ExpenseService.occurrences(in: week, [
            expense("Coffee", 4.5, .oneTime, day(2026, 9, 22), "Food"),
            expense("Groceries", 52, .oneTime, day(2026, 9, 25), "Food"),
            expense("Netflix", 15, .monthly, day(2026, 3, 24), "Entertainment"),
        ])
        let summary = SpendingSummary(hits)
        #expect(summary.total == 71.5)
        #expect(summary.count == 3)
        #expect(summary.topCategories.map(\.name) == ["Food", "Entertainment"])
        #expect(summary.topCategories.first?.value == 56.5)
        #expect(summary.biggest == .init(name: "Groceries", value: 52))

        let text = summary.sentence(period: "this week", budgetLeft: 100) { "$\($0)" }
        #expect(text == "This week you spent $71.5 across 3 transactions. Most went to Food ($56.5). Biggest: Groceries $52.0. $100.0 left in your budget.")
    }

    @Test("empty period reads naturally")
    func emptySummary() {
        let text = SpendingSummary([]).sentence(period: "today", budgetLeft: nil) { "$\($0)" }
        #expect(text == "Today you haven't spent anything.")
    }

    @Test("period intervals for this and last week")
    func periodIntervals() {
        let now = day(2026, 9, 23).addingTimeInterval(15 * 3600)  // Wed 3pm
        let calendar = Calendar.current
        let thisWeek = SpendingPeriod.thisWeek.interval(now: now)
        let lastWeek = SpendingPeriod.lastWeek.interval(now: now)
        #expect(thisWeek.contains(now))
        #expect(thisWeek.start == calendar.dateInterval(of: .weekOfYear, for: now)?.start)
        #expect(lastWeek.end == thisWeek.start)
        #expect(calendar.dateComponents([.day], from: lastWeek.start, to: lastWeek.end).day == 7)
        #expect(SpendingPeriod.yesterday.interval(now: now).start == day(2026, 9, 22))
    }
}
