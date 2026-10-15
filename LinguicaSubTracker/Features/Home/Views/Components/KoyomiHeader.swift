import SwiftUI

struct KoyomiHeader: View {
    @Bindable var viewModel: CalendarViewModel
    var onMonthPicker: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onMonthPicker) {
                HStack(spacing: 12) {
                    Text(viewModel.currentMonth.formatted(.dateTime.month(.twoDigits).locale(locale)))
                        .font(.custom(AppFont.mono, fixedSize: 40))
                        .foregroundStyle(Color.shu)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentMonth.formatted(.dateTime.month(.wide).locale(locale)))
                            .font(.custom(AppFont.mono, size: 16, relativeTo: .headline))
                        Text(viewModel.currentMonth.formatted(.dateTime.year().locale(locale)))
                            .font(.custom(AppFont.mono, size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.inkSecondary)
                    }
                    Image(systemName: "chevron.down").font(.system(size: 12))
                }
                .id(viewModel.currentMonth)
                .transition(.opacity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.monthKey)
            .accessibilityHint("Choose month")
            Spacer(minLength: 0)
            navigationButton("Previous month", symbol: "chevron.left", offset: -1)
            navigationButton("Next month", symbol: "chevron.right", offset: 1)
        }
        .foregroundStyle(Color.ink)
        .frame(minHeight: 64)
        .padding(.horizontal, 12)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.currentMonth)
    }

    private func navigationButton(_ label: LocalizedStringKey, symbol: String, offset: Int) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) {
                viewModel.currentMonthIndex += offset
            }
        } label: {
            Image(systemName: symbol).font(.system(size: 12))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.months.indices.contains(viewModel.currentMonthIndex + offset))
        .accessibilityLabel(label)
    }
}
