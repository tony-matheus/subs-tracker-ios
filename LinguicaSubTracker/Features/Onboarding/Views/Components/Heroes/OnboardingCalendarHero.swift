import SwiftUI

/// Calendar hero — the real `MonthView` from the Home feature, seeded with
/// mock brand expenses so renewal days show actual logos. Its opaque card
/// stays compatible with onboarding effects; the calendar itself is static.
struct OnboardingCalendarHero: View {
    private let store = OnboardingMockData.makeStore()

    var body: some View {
        let month = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()
        let data = CalendarCache.shared.monthData(for: month, expenses: store.expenses)

        MonthView(
            store: store,
            month: data.date,
            grid: data.grid,
            expenseCounts: data.expenseCounts,
            expenses: data.expenses,
            height: 300,
            onTap: { _ in }
        )
        .rippleCard()
    }
}

#Preview {
    OnboardingCalendarHero()
        .padding(24)
        .appBackground()
}
