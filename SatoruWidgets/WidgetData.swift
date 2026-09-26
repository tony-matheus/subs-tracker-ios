import SwiftUI
import WidgetKit

// Shared by the widget extension and (for the DEBUG widget gallery) the app.
// Everything here is derived from local data through the same pure helpers
// the app uses, so numbers match what the app shows.

/// Local data as of one timeline date.
struct WidgetSnapshot {
    var now: Date
    let expenses: [Expense]
    let settings: AppSettings
    let logos: [UUID: LogoCustomization]

    static func load(now: Date = .now) -> WidgetSnapshot {
        WidgetSnapshot(
            now: now,
            expenses: StorageService.load(),
            settings: StorageService.loadSettings(),
            logos: StorageService.loadCustomizations()
        )
    }

    func at(_ date: Date) -> WidgetSnapshot {
        var copy = self
        copy.now = date
        return copy
    }

    func money(_ value: Double) -> String { MoneyFormatter.format(value, settings: settings) }

    /// Short money for tight spots ("$1.2k").
    func compactMoney(_ value: Double) -> String {
        MoneyFormatter.symbol(for: settings.currencyCode)
            + MoneyFormatter.formatNumber(value, round: true, abbreviate: true)
    }

    func logo(for expense: Expense) -> LogoCustomization {
        expense.logoCustomization(customizations: logos)
    }

    func categoryColor(_ name: String) -> Color {
        settings.categories.first { $0.name == name }.map { Color(hex: $0.colorHex) } ?? .gray
    }
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    var relevance: TimelineEntryRelevance? = nil
    /// Calendar widget configuration (ignored by the other widgets).
    var range: CalendarRange = .month

    init(snapshot: WidgetSnapshot, relevance: TimelineEntryRelevance? = nil, range: CalendarRange = .month) {
        self.date = snapshot.now
        self.snapshot = snapshot
        self.relevance = relevance
        self.range = range
    }
}

// MARK: - Budget

enum BudgetPeriod {
    case week, month
}

struct BudgetStatus {
    struct Day: Identifiable {
        let date: Date
        let amount: Double
        var id: Date { date }
    }

    let period: BudgetPeriod
    let interval: DateInterval
    let budget: Double?
    /// Charges up to the end of today.
    let paid: Double
    /// Charges later in the period (renewals, planned one-offs).
    let scheduled: Double
    let daysLeft: Int
    let topCategories: [SpendingSummary.Amount]
    let biggest: SpendingSummary.Amount?
    let days: [Day]

    var total: Double { paid + scheduled }
    var remaining: Double? { budget.map { $0 - total } }
    var isOver: Bool { (remaining ?? 0) < 0 }
    /// 0…1 of the budget, split paid vs scheduled for the ring.
    var paidFraction: Double { fraction(paid) }
    var scheduledFraction: Double { min(fraction(total), 1) - paidFraction }

    var title: String {
        switch period {
        case .week: "This week"
        case .month: interval.start.formatted(.dateTime.month(.wide))
        }
    }

    init(_ period: BudgetPeriod, snapshot: WidgetSnapshot) {
        let calendar = Calendar.current
        let now = snapshot.now
        self.period = period
        switch period {
        case .week:
            interval = ExpenseService.weekInterval(containing: now)
            budget = snapshot.settings.weekBudget(for: now)
        case .month:
            interval = calendar.dateInterval(of: .month, for: now)
                ?? DateInterval(start: calendar.startOfDay(for: now), duration: 30 * 86_400)
            budget = snapshot.settings.effectiveBudget
        }

        let hits = ExpenseService.occurrences(in: interval, snapshot.expenses)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        paid = hits.filter { $0.date < endOfToday }.reduce(0) { $0 + $1.expense.price }
        scheduled = hits.filter { $0.date >= endOfToday }.reduce(0) { $0 + $1.expense.price }
        daysLeft = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: interval.end).day ?? 0)

        let summary = SpendingSummary(hits)
        topCategories = summary.topCategories
        biggest = summary.biggest

        let byDay = Dictionary(grouping: hits, by: { $0.date })
        var days: [Day] = []
        var day = interval.start
        while day < interval.end {
            days.append(Day(date: day, amount: byDay[day]?.reduce(0) { $0 + $1.expense.price } ?? 0))
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }
        self.days = days
    }

    private func fraction(_ value: Double) -> Double {
        guard let budget, budget > 0 else { return 0 }
        return min(max(value / budget, 0), 1)
    }
}

// MARK: - Calendar

enum CalendarRange: String {
    case week, month
}

struct CalendarDay: Identifiable {
    let id: Int
    /// nil for padding cells before/after the month.
    let date: Date?
    let expenses: [Expense]
    let isToday: Bool

    var total: Double { expenses.reduce(0) { $0 + $1.price } }
}

extension WidgetSnapshot {
    func calendarDays(_ range: CalendarRange) -> [CalendarDay] {
        let calendar = Calendar.current
        let dates: [Date?]
        switch range {
        case .month:
            dates = CalendarService.daysGrid(for: now, startingOn: .sunday)
        case .week:
            let start = ExpenseService.weekInterval(containing: now).start
            dates = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: start) }
        }
        return dates.enumerated().map { index, date in
            CalendarDay(
                id: index,
                date: date,
                expenses: date.map { ExpenseService.expenses(for: $0, expenses: expenses) } ?? [],
                isToday: date.map { calendar.isDate($0, inSameDayAs: now) } ?? false
            )
        }
    }
}

// MARK: - Upcoming

struct UpcomingCharges {
    let items: [(date: Date, expense: Expense)]
    /// First charge after this week, for the empty state.
    let nextAfterWeek: (date: Date, expense: Expense)?

    var total: Double { items.reduce(0) { $0 + $1.expense.price } }

    init(snapshot: WidgetSnapshot) {
        items = ExpenseService.upcoming(from: snapshot.now, snapshot.expenses)
            .sorted { ($0.date, $0.expense.name) < ($1.date, $1.expense.name) }
        let weekEnd = ExpenseService.weekInterval(containing: snapshot.now).end
        nextAfterWeek = ExpenseService.occurrences(
            in: DateInterval(start: weekEnd, duration: 62 * 86_400),
            snapshot.expenses
        ).first
    }

    /// Smart Stack hint: surface the widget when something is due today/tomorrow.
    func relevance(now: Date) -> TimelineEntryRelevance {
        let calendar = Calendar.current
        let soon = items.contains {
            calendar.isDate($0.date, inSameDayAs: now)
                || calendar.isDate($0.date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        }
        return TimelineEntryRelevance(score: soon ? 1 : 0.1)
    }
}

func dayLabel(_ date: Date, now: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDate(date, inSameDayAs: now) { return "Today" }
    if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
       calendar.isDate(date, inSameDayAs: tomorrow) { return "Tomorrow" }
    return date.formatted(.dateTime.weekday(.wide))
}

// MARK: - Sample data (placeholders, previews, DEBUG gallery)

extension WidgetSnapshot {
    static var sample: WidgetSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today) ?? today }
        var settings = AppSettings.default
        settings.monthlyBudget = 1200
        let expenses = [
            Expense(name: "Netflix", price: 15.99, billingCycle: .monthly, startDate: day(1), category: "Entertainment"),
            Expense(name: "Spotify", price: 10.99, billingCycle: .monthly, startDate: day(-3), category: "Entertainment"),
            Expense(name: "ChatGPT", price: 20, billingCycle: .monthly, startDate: day(2), category: "Productivity"),
            Expense(name: "Groceries", price: 86.40, billingCycle: .oneTime, type: .expense, startDate: day(-1), category: "Lifestyle"),
            Expense(name: "Coffee", price: 4.50, billingCycle: .oneTime, type: .expense, startDate: day(0), category: "Lifestyle"),
            Expense(name: "Gym", price: 45, billingCycle: .monthly, startDate: day(-9), category: "Health"),
            Expense(name: "Internet", price: 70, billingCycle: .monthly, startDate: day(-15), category: "Utilities"),
            Expense(name: "Dinner", price: 62, billingCycle: .oneTime, type: .expense, startDate: day(3), category: "Lifestyle"),
        ]
        return WidgetSnapshot(now: .now, expenses: expenses, settings: settings, logos: [:])
    }
}
