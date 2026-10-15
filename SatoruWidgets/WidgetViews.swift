import Charts
import SwiftUI
import WidgetKit

// Views for every widget family. Pure functions of a `WidgetSnapshot` +
// family, so the DEBUG gallery in the app can render them too.

private func mono(_ size: CGFloat) -> Font {
    .custom(AppFont.mono, fixedSize: size)
}

// MARK: - Shared pieces

/// Budget ring: paid solid, scheduled translucent on top.
struct WidgetRing: View {
    let paid: Double
    let scheduled: Double
    let color: Color
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: paid, to: paid + scheduled)
                .stroke(color.opacity(0.35), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: paid)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .widgetAccentable()
    }
}

private struct Dots: View {
    let colors: [Color]
    let max: Int
    var size: CGFloat = 4

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(colors.prefix(max).enumerated()), id: \.offset) { _, color in
                DotCircle(color: color, size: size)
            }
            if colors.count > max {
                Text("+\(colors.count - max)")
                    .font(mono(size * 1.8))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .widgetAccentable()
    }
}

/// Hairline outline keeps dark brand colors (Spotify black) visible in dark mode.
private struct DotCircle: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle().fill(color)
            .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 0.5))
            .frame(width: size, height: size)
    }
}

private struct ExpenseLine: View {
    let snapshot: WidgetSnapshot
    let date: Date
    let expense: Expense
    var logoSize: CGFloat = 24
    var showsDay = true

    var body: some View {
        Link(destination: DeepLink.day(date).url) {
            HStack(spacing: 8) {
                LogoCircle(size: logoSize, customization: snapshot.logo(for: expense),
                           logoName: expense.logoName, name: expense.name)
                VStack(alignment: .leading, spacing: 0) {
                    Text(expense.name).font(mono(13)).lineLimit(1)
                    if showsDay {
                        Text(dayLabel(date, now: snapshot.now))
                            .font(mono(11)).foregroundStyle(Color.inkSecondary)
                    }
                }
                Spacer(minLength: 4)
                Text(snapshot.money(expense.price)).font(mono(13)).monospacedDigit()
            }
            .foregroundStyle(Color.primary)
        }
        .tint(Color.primary)
    }
}

// MARK: - Budget

struct BudgetWidgetView: View {
    let status: BudgetStatus
    let snapshot: WidgetSnapshot
    let family: WidgetFamily

    init(_ period: BudgetPeriod, snapshot: WidgetSnapshot, family: WidgetFamily) {
        self.status = BudgetStatus(period, snapshot: snapshot)
        self.snapshot = snapshot
        self.family = family
    }

    private var color: Color { BudgetColor.color(spent: status.total, budget: status.budget) }
    private var percent: String {
        guard let budget = status.budget, budget > 0 else { return "–" }
        return "\(Int((status.total / budget * 100).rounded()))%"
    }
    private var remainingText: String {
        guard let remaining = status.remaining else { return snapshot.money(status.total) }
        return remaining >= 0 ? "\(snapshot.money(remaining)) left" : "\(snapshot.money(-remaining)) over"
    }
    private var periodWord: String { status.period == .week ? "this week" : "this month" }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: Text(status.budget == nil ? "\(snapshot.money(status.total)) \(periodWord)" : "\(remainingText) \(periodWord)")
        case .systemMedium: medium
        case .systemLarge: large
        default: small
        }
    }

    private var ring: some View {
        WidgetRing(paid: status.paidFraction, scheduled: status.scheduledFraction, color: color)
    }

    private var noBudgetNote: some View {
        Text("Set a budget in Satoru").font(mono(11)).foregroundStyle(Color.inkSecondary)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(status.title).font(mono(13)).foregroundStyle(Color.inkSecondary)
            if status.budget != nil {
                ZStack {
                    ring
                    Text(percent).font(mono(17)).monospacedDigit()
                }
                .frame(width: 64, height: 64)
                Spacer(minLength: 0)
                Text(remainingText)
                    .font(mono(15)).foregroundStyle(status.isOver ? .red : .primary)
                    .minimumScaleFactor(0.7).lineLimit(1)
                Text("of \(snapshot.money(status.budget ?? 0))")
                    .font(mono(11)).foregroundStyle(Color.inkSecondary)
            } else {
                Spacer(minLength: 0)
                Text("Spent").font(mono(12)).foregroundStyle(Color.inkSecondary)
                Text(snapshot.money(status.total)).font(mono(24)).minimumScaleFactor(0.6).lineLimit(1)
                noBudgetNote
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var categoryBars: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(status.topCategories, id: \.name) { category in
                HStack(spacing: 6) {
                    Circle().fill(snapshot.categoryColor(category.name)).frame(width: 6, height: 6)
                    Text(category.name).font(mono(11)).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(snapshot.compactMoney(category.value)).font(mono(11)).monospacedDigit()
                }
            }
        }
        .widgetAccentable()
    }

    private var header: some View {
        HStack {
            Text(status.title).font(mono(14))
            Spacer()
            Text(status.daysLeft == 1 ? "1 day left" : "\(status.daysLeft) days left")
                .font(mono(12)).foregroundStyle(Color.inkSecondary)
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ZStack {
                ring
                VStack(spacing: 0) {
                    Text(percent).font(mono(22)).monospacedDigit()
                    Text("used").font(mono(11)).foregroundStyle(Color.inkSecondary)
                }
            }
            .frame(width: 100, height: 100)
            .opacity(status.budget == nil ? 0.3 : 1)

            VStack(alignment: .leading, spacing: 4) {
                header
                Text(remainingText)
                    .font(mono(20)).foregroundStyle(status.isOver ? .red : .primary)
                    .minimumScaleFactor(0.7).lineLimit(1)
                if let budget = status.budget {
                    Text("of \(snapshot.money(budget))").font(mono(11)).foregroundStyle(Color.inkSecondary)
                } else {
                    noBudgetNote
                }
                Spacer(minLength: 0)
                categoryBars
            }
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            HStack(spacing: 16) {
                ZStack {
                    ring
                    Text(percent).font(mono(22)).monospacedDigit()
                }
                .frame(width: 96, height: 96)
                .opacity(status.budget == nil ? 0.3 : 1)
                VStack(alignment: .leading, spacing: 6) {
                    stat("Spent", status.paid)
                    stat("Scheduled", status.scheduled)
                    if let remaining = status.remaining {
                        stat(remaining >= 0 ? "Left" : "Over", abs(remaining), tint: status.isOver ? .red : nil)
                    } else {
                        noBudgetNote
                    }
                }
            }
            chart.frame(maxHeight: .infinity)
            HStack(alignment: .top) {
                categoryBars
                if let biggest = status.biggest {
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Biggest").font(mono(11)).foregroundStyle(Color.inkSecondary)
                        Text(biggest.name).font(mono(12)).lineLimit(1)
                        Text(snapshot.money(biggest.value)).font(mono(12)).monospacedDigit()
                    }
                }
            }
        }
    }

    private func stat(_ label: String, _ value: Double, tint: Color? = nil) -> some View {
        HStack {
            Text(label).font(mono(12)).foregroundStyle(Color.inkSecondary)
            Spacer()
            Text(snapshot.money(value)).font(mono(14)).monospacedDigit()
                .foregroundStyle(tint ?? .primary)
        }
    }

    @ViewBuilder
    private var chart: some View {
        switch status.period {
        case .week:
            Chart(status.days) { day in
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Spent", day.amount))
                    .foregroundStyle(day.date > snapshot.now ? color.opacity(0.35) : color)
                    .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .chartYAxis(.hidden)
            .widgetAccentable()
        case .month:
            let cumulative = status.days.reduce(into: [BudgetStatus.Day]()) { running, day in
                running.append(.init(date: day.date, amount: (running.last?.amount ?? 0) + day.amount))
            }
            Chart {
                ForEach(cumulative) { day in
                    LineMark(x: .value("Day", day.date, unit: .day), y: .value("Spent", day.amount),
                             series: .value("Series", "Spent"))
                        .foregroundStyle(color)
                        .interpolationMethod(.stepEnd)
                }
                if let budget = status.budget, let first = status.days.first, let last = status.days.last {
                    ForEach([(first.date, 0.0), (last.date, budget)], id: \.0) { date, value in
                        LineMark(x: .value("Day", date, unit: .day), y: .value("Spent", value),
                                 series: .value("Series", "Pace"))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }
                }
                RuleMark(x: .value("Today", snapshot.now, unit: .day))
                    .foregroundStyle(Color.primary.opacity(0.2))
            }
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .widgetAccentable()
        }
    }

    private var circular: some View {
        Gauge(value: status.budget == nil ? 0 : min(status.total / max(status.budget ?? 1, 1), 1)) {
            Text(status.period == .week ? "Wk" : "Mo")
        } currentValueLabel: {
            Text(status.budget == nil ? snapshot.compactMoney(status.total) : percent)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(status.period == .week ? "Week" : "Month") · \(remainingText)")
                .font(mono(14)).lineLimit(1)
            if let budget = status.budget {
                Gauge(value: min(status.total / max(budget, 1), 1)) { EmptyView() }
                    .gaugeStyle(.accessoryLinearCapacity)
                Text("of \(snapshot.money(budget))").font(mono(11)).foregroundStyle(Color.inkSecondary)
            } else {
                Text("Spent \(periodWord)").font(mono(11)).foregroundStyle(Color.inkSecondary)
            }
        }
    }
}

// MARK: - Calendar

struct CalendarWidgetView: View {
    let range: CalendarRange
    let snapshot: WidgetSnapshot
    let family: WidgetFamily

    private var days: [CalendarDay] { snapshot.calendarDays(range) }
    private var colors: (CalendarDay) -> [Color] {
        { day in day.expenses.map { snapshot.logo(for: $0).resolvedBackground } }
    }
    private var total: Double { days.reduce(0) { $0 + $1.total } }
    private var weekdaySymbols: [String] { Calendar.current.veryShortWeekdaySymbols }

    var body: some View {
        switch (range, family) {
        case (.month, .systemSmall): monthGrid(numberSize: 9, dotMax: 1, dotSize: 3, linked: false)
        case (.month, .systemMedium):
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.now.formatted(.dateTime.month(.wide)))
                        .font(mono(15))
                    Text(snapshot.money(total)).font(mono(13)).monospacedDigit()
                    Text("\(days.reduce(0) { $0 + $1.expenses.count }) charges")
                        .font(mono(11)).foregroundStyle(Color.inkSecondary)
                    Spacer(minLength: 0)
                }
                .frame(width: 84, alignment: .leading)
                monthGrid(numberSize: 9, dotMax: 3, dotSize: 3, linked: true)
            }
        case (.month, _):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(snapshot.now.formatted(.dateTime.month(.wide).year()))
                        .font(mono(16))
                    Spacer()
                    Text(snapshot.money(total)).font(mono(14)).monospacedDigit()
                }
                monthGrid(numberSize: 13, dotMax: 3, dotSize: 5, linked: true)
            }
        case (.week, .systemSmall): weekRows(logos: false)
        case (.week, .systemMedium): weekColumns
        case (.week, _): weekRows(logos: true)
        }
    }

    private func monthGrid(numberSize: CGFloat, dotMax: Int, dotSize: CGFloat, linked: Bool) -> some View {
        let rows = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
        return VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(mono(numberSize - 1)).foregroundStyle(Color.inkSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(row) { day in
                        dayLink(day, linked: linked) {
                            VStack(spacing: 1) {
                                if let date = day.date {
                                    Text(date.formatted(.dateTime.day()))
                                        .font(mono(numberSize))
                                        .foregroundStyle(Color.ink)
                                        .background {
                                            if day.isToday {
                                                InkBrush(seed: EnsoShape.seed(for: date),
                                                         size: CGSize(width: numberSize * 2.2, height: numberSize * 1.7))
                                                    .widgetAccentable()
                                            }
                                        }
                                    Dots(colors: colors(day), max: dotMax, size: dotSize)
                                        .frame(height: dotSize)
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayLink(_ day: CalendarDay, linked: Bool, @ViewBuilder content: () -> some View) -> some View {
        if linked, let date = day.date {
            // Links tint their label; keep the calendar's own colors.
            Link(destination: DeepLink.day(date).url) { content().foregroundStyle(Color.primary) }
                .tint(Color.primary)
        } else {
            content()
        }
    }

    private func weekRows(logos: Bool) -> some View {
        VStack(alignment: .leading, spacing: logos ? 6 : 2) {
            if logos {
                HStack {
                    Text("This week").font(mono(16))
                    Spacer()
                    Text(snapshot.money(total)).font(mono(14)).monospacedDigit()
                }
            }
            ForEach(days) { day in
                dayLink(day, linked: logos) {
                    HStack(spacing: 8) {
                        if let date = day.date {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(mono(logos ? 13 : 11))
                                .foregroundStyle(day.isToday ? Color.shu : .secondary)
                                .frame(width: logos ? 36 : 28, alignment: .leading)
                            Text(date.formatted(.dateTime.day()))
                                .font(mono(logos ? 13 : 11))
                                .frame(width: 18, alignment: .leading)
                        }
                        if logos {
                            HStack(spacing: -6) {
                                ForEach(day.expenses.prefix(3)) { expense in
                                    LogoCircle(size: 24, customization: snapshot.logo(for: expense),
                                               logoName: expense.logoName, name: expense.name)
                                }
                            }
                            if day.expenses.count > 3 {
                                Text("+\(day.expenses.count - 3)").font(mono(11)).foregroundStyle(Color.inkSecondary)
                            }
                            Spacer(minLength: 4)
                            if day.total > 0 {
                                Text(snapshot.money(day.total)).font(mono(13)).monospacedDigit()
                            }
                        } else {
                            Dots(colors: colors(day), max: 4, size: 5)
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }

    private var weekColumns: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("This week").font(mono(14))
                Spacer()
                Text(snapshot.money(total)).font(mono(13)).monospacedDigit()
            }
            HStack(spacing: 4) {
                ForEach(days) { day in
                    dayLink(day, linked: true) {
                        VStack(spacing: 4) {
                            if let date = day.date {
                                Text(date.formatted(.dateTime.weekday(.narrow)))
                                    .font(mono(11)).foregroundStyle(Color.inkSecondary)
                                Text(date.formatted(.dateTime.day()))
                                    .font(mono(14))
                                    .foregroundStyle(Color.ink)
                                        .background {
                                            if day.isToday {
                                                InkBrush(seed: EnsoShape.seed(for: date),
                                                         size: CGSize(width: 28, height: 24))
                                                    .widgetAccentable()
                                            }
                                        }
                            }
                            VStack(spacing: 3) {
                                ForEach(Array(colors(day).prefix(3).enumerated()), id: \.offset) { _, color in
                                    DotCircle(color: color, size: 6)
                                }
                            }
                            .widgetAccentable()
                            Spacer(minLength: 0)
                            Text(day.total > 0 ? snapshot.compactMoney(day.total) : " ")
                                .font(mono(10)).monospacedDigit().lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming

struct UpcomingWidgetView: View {
    let snapshot: WidgetSnapshot
    let family: WidgetFamily
    private let upcoming: UpcomingCharges

    init(snapshot: WidgetSnapshot, family: WidgetFamily) {
        self.snapshot = snapshot
        self.family = family
        self.upcoming = UpcomingCharges(snapshot: snapshot)
    }

    var body: some View {
        if upcoming.items.isEmpty {
            empty
        } else {
            switch family {
            case .systemMedium: list(limit: 3, grouped: false)
            case .systemLarge: list(limit: 8, grouped: true)
            default: small
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This week").font(mono(13)).foregroundStyle(Color.inkSecondary)
            Spacer(minLength: 0)
            Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(Color.inkSecondary)
                .widgetAccentable()
            Text("Nothing else due this week").font(mono(14))
            if let next = upcoming.nextAfterWeek {
                Text("Next: \(next.expense.name), \(next.date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(mono(11)).foregroundStyle(Color.inkSecondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var small: some View {
        let first = upcoming.items[0]
        let rest = upcoming.items.count - 1
        return VStack(alignment: .leading, spacing: 4) {
            Text("Next up").font(mono(13)).foregroundStyle(Color.inkSecondary)
            Spacer(minLength: 0)
            LogoCircle(size: 34, customization: snapshot.logo(for: first.expense),
                       logoName: first.expense.logoName, name: first.expense.name)
            Text(first.expense.name).font(mono(15)).lineLimit(1)
            Text(snapshot.money(first.expense.price)).font(mono(20)).monospacedDigit()
                .minimumScaleFactor(0.7).lineLimit(1)
            Text(dayLabel(first.date, now: snapshot.now)).font(mono(12)).foregroundStyle(Color.inkSecondary)
            if rest > 0 {
                Text("+\(rest) more · \(snapshot.money(upcoming.total))")
                    .font(mono(11)).foregroundStyle(Color.inkSecondary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(DeepLink.day(first.date).url)
    }

    private func list(limit: Int, grouped: Bool) -> some View {
        let shown = Array(upcoming.items.prefix(limit))
        let days = Dictionary(grouping: shown, by: { $0.date }).sorted { $0.key < $1.key }
        return VStack(alignment: .leading, spacing: grouped ? 8 : 6) {
            HStack {
                Text("This week").font(mono(14))
                Spacer()
                Text(snapshot.money(upcoming.total)).font(mono(13)).monospacedDigit()
            }
            if grouped {
                ForEach(days, id: \.key) { day, items in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayLabel(day, now: snapshot.now).uppercased())
                            .font(mono(10)).foregroundStyle(Color.inkSecondary)
                        ForEach(items, id: \.expense.id) { item in
                            ExpenseLine(snapshot: snapshot, date: item.date, expense: item.expense,
                                        logoSize: 26, showsDay: false)
                        }
                    }
                }
            } else {
                ForEach(shown, id: \.expense.id) { item in
                    ExpenseLine(snapshot: snapshot, date: item.date, expense: item.expense)
                }
            }
            Spacer(minLength: 0)
            if upcoming.items.count > limit {
                Text("+\(upcoming.items.count - limit) more").font(mono(11)).foregroundStyle(Color.inkSecondary)
            } else if let next = upcoming.nextAfterWeek {
                Text("Next week: \(next.expense.name), \(next.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
                    .font(mono(11)).foregroundStyle(Color.inkSecondary).lineLimit(1)
            }
        }
    }
}

/// Flat paper backdrop shared with the app.
struct WidgetBackdrop: View {
    var body: some View {
        Color.paper
    }
}
