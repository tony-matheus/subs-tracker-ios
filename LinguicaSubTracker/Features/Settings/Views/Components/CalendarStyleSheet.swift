import SwiftUI

/// Radio-style picker for the three calendar looks, each row with a static
/// miniature day-cell preview. Writes straight to `SettingsStore` so the
/// home calendar re-renders live behind the sheet.
struct CalendarStyleSheet: View {
    let settingsStore: SettingsStore
    @State private var previewStore = AppStore()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(CalendarStyle.allCases) { style in
                        styleRow(style)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .animation(
                    reduceMotion ? nil : .smooth(duration: 0.25),
                    value: settingsStore.calendarStyle
                )
            }
            .sensoryFeedback(.selection, trigger: settingsStore.calendarStyle)
            .appBackground()
            .navigationTitle("Calendar Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.ink)
                    }
                    .accessibilityLabel("Close calendar styles")
                }
            }
        }
    }

    private func styleRow(_ style: CalendarStyle) -> some View {
        let isSelected = settingsStore.calendarStyle == style

        return Button {
            settingsStore.calendarStyle = style
        } label: {
            HStack(spacing: 14) {
                CalendarStylePreviewCell(style: style, store: previewStore)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName)
                        .typography(.bodyLarge)
                        .foregroundStyle(Color.ink)
                    Text(style.subtitle)
                        .typography(.bodySmall)
                        .foregroundStyle(Color.inkSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .iconStyle(
                        size: 20,
                        weight: .semibold,
                        color: isSelected ? Color.ink : Color.inkSecondary
                    )
            }
            .padding(14)
            .background(Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(
                        isSelected ? Color.ink : Color.rule,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar-style-\(style.rawValue)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Uses the real day cell at its six-week height; it never replays today's mark.
private struct CalendarStylePreviewCell: View {
    let style: CalendarStyle
    let store: AppStore
    private var date: Date { Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 17))! }
    var body: some View {
        let names = ["Spotify", "Netflix", "Apple Music", "Dropbox", "iCloud"]
        let expenses = names.prefix(style == .compact ? 5 : 4).map {
            Expense(name: $0, price: 9, billingCycle: .monthly, startDate: date)
        }
        DayCell(viewModel: DayCellViewModel(store: store, date: date, status: .current, expenses: expenses),
                style: style, height: (style.gridHeight - 20) / 6, onTap: { _ in }, animatesToday: false)
            .frame(width: 48)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    CalendarStyleSheet(settingsStore: SettingsStore())
}
