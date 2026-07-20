import Foundation
import SwiftUI

enum DayStatus {
    case current
    case normal
    case none
}

struct DayCell: View {
    let viewModel: DayCellViewModel
    var style: CalendarStyle = .rounded
    var height: CGFloat = 68
    var onTap: (Date) -> Void
    /// Reports the cell's center (in `MonthView.rippleSpace`) so the parent can
    /// originate a ripple from the tapped day. Nil skips the geometry tracking
    /// entirely — the dot styles don't ripple.
    var onRipple: ((CGPoint) -> Void)?
    /// Compact-style quick actions; operate on the day's primary expense.
    var onEdit: ((Expense) -> Void)? = nil
    var onDelete: ((Expense) -> Void)? = nil

    @State private var center: CGPoint = .zero
    /// Set by the compact context menu's Delete; drives the confirmation alert.
    @State private var pendingDelete: Expense? = nil

    private var logoSize: CGFloat { style.logoSize }
    private var cornerRadius: CGFloat { style.cornerRadius }
    private var expenseInset: CGFloat { style == .bigger ? 6 : 4 }
    private var dayLabelInset: CGFloat { style == .compact ? 5 : 8 }

    var body: some View {
        if style.hasQuickActions, let primary = viewModel.primaryExpense {
            cellButton
                .contextMenu {
                    Button {
                        if let date = viewModel.date { onTap(date) }
                    } label: {
                        Label("View", systemImage: "eye")
                    }
                    Button {
                        onEdit?(primary)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        pendingDelete = primary
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                // Deleting removes the whole expense (every recurrence), so it
                // confirms first — same convention as the form's delete flow.
                .alert(
                    "Delete Expense",
                    isPresented: Binding(
                        get: { pendingDelete != nil },
                        set: { if !$0 { pendingDelete = nil } }
                    ),
                    presenting: pendingDelete
                ) { expense in
                    Button("Delete", role: .destructive) {
                        onDelete?(expense)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { expense in
                    Text("\(expense.name) will be permanently removed.")
                }
        } else {
            cellButton
        }
    }

    private var cellButton: some View {
        Button(action: handleTap) {
            ZStack {
                cellBackground
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                if onRipple != nil { centerReader }
            }
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
                    if style.usesDots {
                        dotsLayer
                    } else {
                        expenseFloatingLayer(primary: primary)
                    }
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

    private var maxDots: Int { style == .compact ? 3 : 4 }

    /// Apple-Calendar-like indicator row: one dot per expense in its brand
    /// color, with a tiny "+n" when the day has more than fit.
    private var dotsLayer: some View {
        let dotSize: CGFloat = style == .compact ? 5 : 6
        let colors = viewModel.expenses.prefix(maxDots).map {
            $0.logoCustomization(in: viewModel.store).resolvedBackground
        }
        let overflow = viewModel.expenses.count - maxDots

        return HStack(spacing: 3) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, style == .compact ? 4 : 6)
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
                    if style.showsGradientTint,
                        let color = viewModel.primaryColor,
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
        switch (style, viewModel.status) {
        case (.compact, .current), (.compact, .normal): Color.gray.opacity(0.15)
        case (.compact, .none): Color.gray.opacity(0.08)
        case (_, .current), (_, .normal): Color.gray.opacity(0.2)
        case (_, .none): Color.gray.opacity(0.1)
        }
    }

    /// Brand colors of the day's expenses (up to 3) for the contrast border.
    private var brandBorderColors: [Color] {
        viewModel.expenses.prefix(3).map {
            $0.logoCustomization(in: viewModel.store).resolvedBackground
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
        case .normal:
            if style.hasBrandBorder, !brandBorderColors.isEmpty {
                brandBorder
            }
        case .none:
            EmptyView()
        }
    }

    /// Contrast-style stroke: a gradient built from the day's expense brand
    /// colors (a single expense fades its own color instead).
    private var brandBorder: some View {
        let colors = brandBorderColors
        let gradientColors = colors.count == 1
            ? [colors[0].opacity(0.9), colors[0].opacity(0.3)]
            : colors

        return RoundedRectangle(cornerRadius: cornerRadius)
            .inset(by: 0.75)
            .stroke(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .allowsHitTesting(false)
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
