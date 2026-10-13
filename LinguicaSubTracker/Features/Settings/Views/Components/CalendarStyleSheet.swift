import SwiftUI

/// Radio-style picker for the five calendar looks, each row with a static
/// miniature day-cell preview. Writes straight to `SettingsStore` so the
/// home calendar re-renders live behind the sheet.
struct CalendarStyleSheet: View {
    let settingsStore: SettingsStore
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
                CalendarStylePreviewCell(style: style)

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
    }
}

/// Static miniature of a day cell in the given style — mock colors, no store.
private struct CalendarStylePreviewCell: View {
    let style: CalendarStyle

    private let mockColors: [Color] = [.blue, .green, .orange]

    private var previewHeight: CGFloat {
        switch style {
        case .rounded, .contrastRounded, .straight: 52
        case .bigger: 62
        case .compact: 34
        }
    }

    private var radius: CGFloat { style.cornerRadius * 0.7 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.gray.opacity(0.25))
                .overlay {
                    if style.showsGradientTint {
                        LinearGradient(
                            colors: [.clear, mockColors[0].opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: radius))
                    }
                }

            Text("17")
                .font(.custom(AppFont.mono, fixedSize: 9))
                .foregroundStyle(Color.ink)
                .opacity(0.6)
                .padding(4)

            indicator
        }
        .frame(width: 56, height: previewHeight)
        .overlay {
            if style.hasBrandBorder {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: mockColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        }
    }

    @ViewBuilder
    private var indicator: some View {
        if style.usesDots {
            HStack(spacing: 2.5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(mockColors[index])
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 4)
        } else {
            Circle()
                .fill(mockColors[0])
                .frame(
                    width: style == .bigger ? 18 : 14,
                    height: style == .bigger ? 18 : 14
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(3)
        }
    }
}

#Preview {
    CalendarStyleSheet(settingsStore: SettingsStore())
}
