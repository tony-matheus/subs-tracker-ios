import Foundation
import Testing

@testable import LinguicaSubTracker

nonisolated private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}

@MainActor
private func monthly(_ name: String, _ start: Date, active: Bool = true, end: Date? = nil) -> Expense {
    Expense(name: name, price: 15.99, billingCycle: .monthly, startDate: start, isActive: active, endDate: end)
}

@MainActor
@Suite("Renewal reminders")
struct RenewalRemindersTests {
    // Sep 10, 2026, 8 AM: before that day's 9 AM reminder slot.
    let now = day(2026, 9, 10, hour: 8)

    @Test("fires lead days before the renewal at 9 AM", arguments: [0, 1, 3])
    func leadTime(leadDays: Int) throws {
        let netflix = monthly("Netflix", day(2026, 1, 15))
        let first = try #require(RenewalReminders.plan(expenses: [netflix], now: now, leadDays: leadDays).first)
        #expect(first.chargeDate == day(2026, 9, 15))
        #expect(first.fireDate == day(2026, 9, 15 - leadDays, hour: 9))
    }

    @Test("skips one-time, inactive and ended expenses")
    func skips() {
        let expenses = [
            Expense(name: "Dinner", price: 40, billingCycle: .oneTime, type: .expense, startDate: day(2026, 9, 20)),
            monthly("Paused", day(2026, 1, 15), active: false),
            monthly("Cancelled", day(2026, 1, 15), end: day(2026, 8, 31)),
        ]
        #expect(RenewalReminders.plan(expenses: expenses, now: now, leadDays: 1).isEmpty)
    }

    @Test("drops reminders whose fire time already passed")
    func pastFireTime() {
        // Renews today (Sep 10); a 1-day lead fired yesterday, a same-day lead fires at 9 (still ahead at 8 AM).
        let gym = monthly("Gym", day(2026, 1, 10))
        let nextDayLead = RenewalReminders.plan(expenses: [gym], now: now, leadDays: 1)
        #expect(nextDayLead.first?.chargeDate == day(2026, 10, 10))
        let sameDay = RenewalReminders.plan(expenses: [gym], now: now, leadDays: 0)
        #expect(sameDay.first?.chargeDate == day(2026, 9, 10))
    }

    @Test("soonest first, capped at the limit")
    func orderAndCap() {
        let expenses = (1...28).map { monthly("Sub \($0)", day(2026, 1, $0)) }
        let plan = RenewalReminders.plan(expenses: expenses, now: now, leadDays: 0, limit: 10)
        #expect(plan.count == 10)
        #expect(plan.map(\.fireDate) == plan.map(\.fireDate).sorted())
        #expect(Set(plan.map(\.id)).count == 10)
    }

    @Test("title wording follows the lead time")
    func titles() throws {
        let netflix = monthly("Netflix", day(2026, 1, 15))
        func title(_ lead: Int) throws -> String {
            RenewalReminders.title(for: try #require(RenewalReminders.plan(expenses: [netflix], now: now, leadDays: lead).first))
        }
        #expect(try title(0) == "Netflix renews today")
        #expect(try title(1) == "Netflix renews tomorrow")
        #expect(try title(3) == "Netflix renews in 3 days")
    }
}
