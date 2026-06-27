import Foundation
import SwiftUI

enum DayStatus {
    case current
    case normal
    case none
}

struct DayCell: View {
    let viewModel: DayCellViewModel
    var height: CGFloat = 68
    var onTap: (Date) -> Void
    /// Reports the cell's center (in `MonthView.rippleSpace`) so the parent can
    /// originate a ripple from the tapped day.
    var onRipple: ((CGPoint) -> Void)?

    @State private var center: CGPoint = .zero

    private let logoSize: CGFloat = 26
    private let cornerRadius: CGFloat = 20
    private let expenseInset: CGFloat = 4
    private let dayLabelInset: CGFloat = 8

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                cellBackground
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(centerReader)
            .overlay(alignment: .topLeading) {
                if viewModel.displayDay, let dayNumber = viewModel.dayNumber {
                    Text("\(dayNumber)")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .opacity(0.6)
                        .padding(.top, dayLabelInset)
                        .padding(.leading, dayLabelInset)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if let primary = viewModel.primaryExpense {
                    expenseFloatingLayer(primary: primary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(DayClickStyle(showsPressFeedback: isSelectable))
    }

    private var isSelectable: Bool {
        viewModel.status != .none && viewModel.date != nil
    }

    private func handleTap() {
        onRipple?(center)
        guard let date = viewModel.date else { return }
        onTap(date)
    }

    private var centerReader: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named(MonthView.rippleSpace))
            Color.clear
                .onAppear { center = CGPoint(x: frame.midX, y: frame.midY) }
                .onChange(of: frame) { _, newFrame in
                    center = CGPoint(x: newFrame.midX, y: newFrame.midY)
                }
        }
    }

    private func expenseFloatingLayer(primary: Expense) -> some View {
        HStack(spacing: -10) {
            if viewModel.overflowCount > 0 {
                overflowBadge(remaining: viewModel.overflowCount)
            }
            if viewModel.expenses.count >= 2 {
                logoCircle(expense: viewModel.expenses[1])
            }
            logoCircle(expense: primary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .bottomTrailing
        )
        .padding(expenseInset)
        .allowsHitTesting(false)
    }

    private func overflowBadge(remaining: Int) -> some View {
        ZStack {
            Circle()
                .fill(Color.appSurface.opacity(0.8))
                .frame(width: logoSize, height: logoSize)
                .overlay(
                    Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
            Text("+\(remaining)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.primary)
        }
    }

    private func logoCircle(expense: Expense) -> some View {
        LogoCircle(
            size: logoSize,
            customization: expense.logoCustomization(in: viewModel.store),
            logoName: expense.logoName,
            name: expense.name
        )
    }

    @ViewBuilder
    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(baseBackgroundColor)
            .overlay(
                Group {
                    if let color = viewModel.primaryColor,
                        viewModel.status != .none
                    {
                        LinearGradient(
                            colors: [.clear, color.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
            )
    }

    private var baseBackgroundColor: Color {
        switch viewModel.status {
        case .current, .normal: Color.gray.opacity(0.2)
        case .none: Color.gray.opacity(0.1)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch viewModel.status {
        case .current:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 4)
                    .blur(radius: 6)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.7),
                                Color.primary.opacity(0.1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: 1)
                    .stroke(Color.primary.opacity(0.6), lineWidth: 2)
            }
            .allowsHitTesting(false)
        default:
            EmptyView()
        }
    }
}

struct DayClickStyle: ButtonStyle {
    /// When false (e.g. empty `.none` cells), the cell still triggers a ripple
    /// but skips the press scale + haptic so it doesn't feel selectable.
    var showsPressFeedback: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = showsPressFeedback && configuration.isPressed
        return configuration.label
            .scaleEffect(pressed ? 0.95 : 1)
            .animation(
                .spring(duration: 0.2, bounce: 0.4),
                value: pressed
            )
            .onChange(of: configuration.isPressed) { _, newValue in
                if newValue && showsPressFeedback {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

#Preview {
    DayCellPreviewHost()
}
