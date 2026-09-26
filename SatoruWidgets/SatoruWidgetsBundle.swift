import AppIntents
import SwiftUI
import WidgetKit

@main
struct SatoruWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WeekBudgetWidget()
        MonthBudgetWidget()
        CalendarWidget()
        UpcomingWidget()
        #if FF_QUICK_ADD
        QuickAddControl()
        #endif
    }
}

// MARK: - Timeline

/// Today plus the next 6 midnights, so day-dependent content (today ring,
/// "Tomorrow", week rollover) stays right without the app running. The app
/// reloads timelines on every data write (StorageService).
private func dailyTimeline(
    _ snapshot: WidgetSnapshot,
    range: CalendarRange = .month,
    relevance: (WidgetSnapshot) -> TimelineEntryRelevance? = { _ in nil }
) -> Timeline<SnapshotEntry> {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: snapshot.now)
    let dates = [snapshot.now] + (1...6).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    let entries = dates.map { date in
        let dated = snapshot.at(date)
        return SnapshotEntry(snapshot: dated, relevance: relevance(dated), range: range)
    }
    return Timeline(entries: entries, policy: .atEnd)
}

struct SnapshotProvider: TimelineProvider {
    var relevance: (WidgetSnapshot) -> TimelineEntryRelevance? = { _ in nil }

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(snapshot: context.isPreview ? .sample : .load()))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<SnapshotEntry>) -> Void) {
        completion(dailyTimeline(.load(), relevance: relevance))
    }
}

private extension View {
    func widgetChrome() -> some View {
        containerBackground(for: .widget) { WidgetBackdrop() }
    }
}

// MARK: - Budget

struct WeekBudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WeekBudget", provider: SnapshotProvider()) { entry in
            BudgetEntryView(period: .week, entry: entry)
        }
        .configurationDisplayName("Week Budget")
        .description("How much of this week's share of your budget is left.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct MonthBudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MonthBudget", provider: SnapshotProvider()) { entry in
            BudgetEntryView(period: .month, entry: entry)
        }
        .configurationDisplayName("Month Budget")
        .description("Spent, scheduled and left in this month's budget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct BudgetEntryView: View {
    let period: BudgetPeriod
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        BudgetWidgetView(period, snapshot: entry.snapshot, family: family)
            .widgetChrome()
    }
}

// MARK: - Calendar

enum CalendarRangeOption: String, AppEnum {
    case week, month

    var value: CalendarRange { self == .week ? .week : .month }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Range"
    static let caseDisplayRepresentations: [CalendarRangeOption: DisplayRepresentation] = [
        .week: "This Week",
        .month: "This Month",
    ]
}

struct CalendarWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Calendar"
    static let description = IntentDescription("Choose whether the calendar shows this week or this month.")

    @Parameter(title: "Show", default: .month)
    var range: CalendarRangeOption
}

struct CalendarProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(snapshot: .sample)
    }

    func snapshot(for configuration: CalendarWidgetIntent, in context: Context) async -> SnapshotEntry {
        SnapshotEntry(snapshot: context.isPreview ? .sample : .load(), range: configuration.range.value)
    }

    func timeline(for configuration: CalendarWidgetIntent, in context: Context) async -> Timeline<SnapshotEntry> {
        dailyTimeline(.load(), range: configuration.range.value)
    }

    func recommendations() -> [AppIntentRecommendation<CalendarWidgetIntent>] {
        [CalendarRangeOption.month, .week].map { option in
            let intent = CalendarWidgetIntent()
            intent.range = option
            return AppIntentRecommendation(intent: intent, description: option == .month ? "This Month" : "This Week")
        }
    }
}

struct CalendarWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "Calendar", intent: CalendarWidgetIntent.self, provider: CalendarProvider()) { entry in
            CalendarEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Your charges as dots on this week or this month.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct CalendarEntryView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        CalendarWidgetView(range: entry.range, snapshot: entry.snapshot, family: family)
            .widgetChrome()
    }
}

// MARK: - Upcoming

struct UpcomingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "Upcoming",
            provider: SnapshotProvider(relevance: { UpcomingCharges(snapshot: $0).relevance(now: $0.now) })
        ) { entry in
            UpcomingEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming This Week")
        .description("Charges still coming up this week.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct UpcomingEntryView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        UpcomingWidgetView(snapshot: entry.snapshot, family: family)
            .widgetChrome()
    }
}
