import SwiftUI

struct MonthPickerSheetPreviewHost: View {
    private let store = HomePreviewData.makeStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        let calendarVM = CalendarViewModel(store: store, coordinator: coordinator)
        calendarVM.onAppear()
        return MonthPickerSheet(calendarViewModel: calendarVM, onDone: {})
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        MonthPickerSheetPreviewHost()
    }
}
