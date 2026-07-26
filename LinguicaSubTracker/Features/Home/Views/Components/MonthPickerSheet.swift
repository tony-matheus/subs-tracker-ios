import SwiftUI

struct MonthPickerSheet: View {
    let calendarViewModel: CalendarViewModel
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            Picker("Month", selection: calendarViewModel.currentMonthIndexBinding()) {
                ForEach(Array(calendarViewModel.months.enumerated()), id: \.offset) { idx, month in
                    Text(
                        month.date.formatted(
                            .dateTime.month(.wide).year()
                        )
                    )
                    .tag(idx)
                }
            }
            .pickerStyle(.wheel)
            .navigationTitle("Jump to Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }
}
