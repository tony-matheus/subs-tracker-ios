import SwiftUI

/// Sunday-first, matching CalendarService. Preserve the original 52pt band.
struct WeekdayBand: View {
    @Environment(\.locale) private var locale
    var body: some View {
        let formatter = DateFormatter()
        let _ = formatter.locale = locale
        HStack(spacing: 4) {
            ForEach(Array(formatter.veryShortStandaloneWeekdaySymbols.enumerated()), id: \.offset) { index, day in
                Text(day)
                    .font(.custom(AppFont.mono, fixedSize: 12))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(index == 0 ? Color.shu : index == 6 ? Color.ai : Color.inkSecondary)
            }
        }
        .frame(height: 52)
        .accessibilityHidden(true)
    }
}
