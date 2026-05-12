import SwiftUI

/// Calendar hero — the real `MonthView` from the Home feature, seeded with
/// mock brand subscriptions so renewal days show actual logos. `MonthView`
/// brings its own tap-driven ripple, so no `rippleOnDrag` here (it would
/// fight the onboarding swipe-to-page gesture).
struct OnboardingCalendarHero: View {
    private let store = OnboardingMockData.makeStore()

    var body: some View {
        let month = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()
        let data = CalendarCache.shared.monthData(for: month, subs: store.subscriptions)

        MonthView(
            store: store,
            month: data.date,
            grid: data.grid,
            subscriptionCounts: data.subscriptionCounts,
            subscriptions: data.subscriptions,
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
