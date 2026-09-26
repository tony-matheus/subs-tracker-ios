#if DEBUG
import SwiftUI
import WidgetKit

/// Renders every widget at real iPhone sizes for screenshot checks, since
/// headless simulators can't place widgets on the Home Screen.
/// `SIMCTL_CHILD_DEBUG_WIDGET_GALLERY=week|month|calendar-month|calendar-week|upcoming|lock`
/// (prefix `live-` for the app's real data instead of the sample; suffix
/// `-dark` to force dark mode).
struct WidgetGallery: View {
    let section: String

    private var snapshot: WidgetSnapshot {
        section.hasPrefix("live-") ? .load() : .sample
    }
    private var isDark: Bool { section.hasSuffix("-dark") }
    private var name: String {
        var name = section.hasPrefix("live-") ? String(section.dropFirst(5)) : section
        if isDark { name = String(name.dropLast(5)) }
        return name
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(name).font(.caption.monospaced()).foregroundStyle(.secondary)
                if name == "lock" {
                    lockScreen
                } else {
                    ForEach([WidgetFamily.systemSmall, .systemMedium, .systemLarge], id: \.self) { family in
                        tile(family) { content(family) }
                    }
                }
            }
            .padding()
        }
        .background(Color(white: 0.45).ignoresSafeArea())
        .environment(\.colorScheme, isDark ? .dark : .light)
    }

    @ViewBuilder
    private func content(_ family: WidgetFamily) -> some View {
        switch name {
        case "month": BudgetWidgetView(.month, snapshot: snapshot, family: family)
        case "calendar-month": CalendarWidgetView(range: .month, snapshot: snapshot, family: family)
        case "calendar-week": CalendarWidgetView(range: .week, snapshot: snapshot, family: family)
        case "upcoming": UpcomingWidgetView(snapshot: snapshot, family: family)
        default: BudgetWidgetView(.week, snapshot: snapshot, family: family)
        }
    }

    /// iPhone 17 Pro widget sizes, with the system's default content margins.
    private func tile(_ family: WidgetFamily, @ViewBuilder content: () -> some View) -> some View {
        let size: CGSize = switch family {
        case .systemMedium: CGSize(width: 364, height: 170)
        case .systemLarge: CGSize(width: 364, height: 382)
        default: CGSize(width: 170, height: 170)
        }
        return content()
            .padding(16)
            .frame(width: size.width, height: size.height)
            .background(WidgetBackdrop())
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var lockScreen: some View {
        VStack(spacing: 16) {
            ForEach([BudgetPeriod.week, .month], id: \.self) { period in
                HStack(spacing: 12) {
                    BudgetWidgetView(period, snapshot: snapshot, family: .accessoryCircular)
                        .frame(width: 72, height: 72)
                    BudgetWidgetView(period, snapshot: snapshot, family: .accessoryRectangular)
                        .frame(width: 172, height: 76)
                }
                BudgetWidgetView(period, snapshot: snapshot, family: .accessoryInline)
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(Color.black, in: RoundedRectangle(cornerRadius: 24))
    }
}
#endif
