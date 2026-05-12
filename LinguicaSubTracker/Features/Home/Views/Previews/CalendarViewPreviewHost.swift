import SwiftUI

struct CalendarViewPreviewHost: View {
    private let store = HomePreviewData.makeStore()
    private let settingsStore = HomePreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        let calendarVM = CalendarViewModel(store: store, coordinator: coordinator)
        CalendarView(store: store, coordinator: coordinator, viewModel: calendarVM)
            .environment(store)
            .environment(settingsStore)
            .environment(coordinator)
    }
}
