import SwiftUI

struct CalendarRewindOverlayPreviewHost: View {
    private let store = HomePreviewData.makeStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        let calendarVM = CalendarViewModel(store: store, coordinator: coordinator)
        calendarVM.onAppear()
        let months = calendarVM.months
        let target = months[calendarVM.currentMonthIndex]
        let source = months[calendarVM.currentMonthIndex > 0 ? calendarVM.currentMonthIndex - 1 : 1]

        return CalendarRewindOverlay(
            store: store,
            source: source,
            target: target,
            height: CalendarStyle.rounded.gridHeight,
            onComplete: {}
        )
        .padding(.horizontal, 12)
    }
}

#Preview {
    CalendarRewindOverlayPreviewHost()
}
