import SwiftUI

struct TotalViewPreviewHost: View {
    private let store = HomePreviewData.makeStore()
    private let settingsStore = HomePreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        let calendarVM = CalendarViewModel(
            store: store,
            coordinator: coordinator
        )
        TotalView(
            store: store,
            settingsStore: settingsStore,
            coordinator: coordinator,
            calendarViewModel: calendarVM
        )
        .padding()
        .background(.black)
    }
}
