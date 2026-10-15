import Foundation
import SwiftUI

enum DayStatus {
    case current
    case normal
    case none
}

struct DayCell: View {
    let viewModel: DayCellViewModel
    var style: CalendarStyle = .default
    var height: CGFloat = 68
    var onTap: (Date) -> Void
    /// Compact-style quick actions; operate on the day's primary expense.
    var onEdit: ((Expense) -> Void)? = nil
    var onDelete: ((Expense) -> Void)? = nil

    /// Set by the compact context menu's Delete; drives the confirmation alert.
    @State private var pendingDelete: Expense? = nil

    var ensoReplay = 0
    var animatesToday = true
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .caption2) private var overflowSize: CGFloat = 8

    var body: some View {
        if !isSelectable {
            Color.paperRaised.frame(height: height).accessibilityHidden(true)
        } else if style.hasQuickActions, let primary = viewModel.primaryExpense {
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
            GeometryReader { geometry in
                if let date = viewModel.date, viewModel.displayDay {
                    dayContent(date: date, width: geometry.size.width)
                } else {
                    Color.paperRaised
                }
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
        }
        .buttonStyle(DayClickStyle(showsPressFeedback: isSelectable))
        .disabled(!isSelectable)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityHint(viewModel.expenses.isEmpty ? Text("Add an expense", tableName: "Calendar") : Text("View expenses", tableName: "Calendar"))
        .accessibilityHidden(!isSelectable)
    }

    private var isSelectable: Bool { viewModel.status != .none && viewModel.date != nil }

    private func handleTap() {
        guard let date = viewModel.date else { return }
        onTap(date)
    }

    private var accessibilityIdentifier: String {
        guard let date = viewModel.date else { return "calendar-blank" }
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "calendar-day-\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    private var accessibilityLabel: String {
        guard let date = viewModel.date else { return "" }
        var parts = [date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(locale))]
        if viewModel.status == .current { parts.append(String(localized: "Today", table: "Calendar", locale: locale)) }
        parts.append(String(localized: "\(viewModel.expenses.count) expenses", table: "Calendar", locale: locale))
        parts.append(contentsOf: viewModel.expenses.map(\.name))
        return parts.joined(separator: ", ")
    }

    private func dayContent(date: Date, width: CGFloat) -> some View {
        let brushSize = CGSize(width: 28, height: style == .default ? 20 : 24)
        let mask = InkBrushRenderer.mask(seed: EnsoShape.seed(for: date), size: brushSize, scale: displayScale)
        let font = UIFont(name: AppFont.mono, size: style.dateSize) ?? .monospacedSystemFont(ofSize: style.dateSize, weight: .regular)
        // Center the visible caps with the brush, then derive the rule from the
        // painted lower edge. Frame padding never determines the memo boundary.
        let numeralBottom = 2 + brushSize.height / 2 + font.capHeight / 2
        let ruleY = max(numeralBottom + 2, 2 + mask.bounds.maxY + 1)
        let memoHeight = max(0, height - ruleY - 4)
        return ZStack(alignment: .top) {
            Color.paperRaised
            LinearGradient(stops: [.init(color: .shu.opacity(0.07), location: 0),
                                   .init(color: .shu.opacity(0.02), location: 0.33),
                                   .init(color: .clear, location: 0.70)], startPoint: .top, endPoint: .bottom)
            ZStack {
                EnsoMark(date: date, size: brushSize, isToday: viewModel.status == .current,
                         animates: animatesToday, replay: ensoReplay)
                Text(date.formatted(.dateTime.day().locale(locale)))
                    .font(.custom(AppFont.mono, fixedSize: style.dateSize))
                    .foregroundStyle(numeralColor(date: date))
            }
            .frame(width: brushSize.width, height: brushSize.height)
            .offset(y: 2)
            Rectangle().fill(Color.rule).frame(height: 0.5)
                .padding(.horizontal, 4).offset(y: ruleY)
            indicators(width: max(0, width - 4), height: memoHeight)
                .frame(width: max(0, width - 4), height: memoHeight, alignment: .center)
                .offset(y: ruleY + 2)
        }
        .clipped()
    }

    private func numeralColor(date: Date) -> Color {
        if viewModel.status == .current { return .ink }
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .shu
        case 7: return .ai
        default: return .ink
        }
    }

    private var overflowFont: UIFont {
        UIFont(name: AppFont.mono, size: overflowSize) ?? .monospacedSystemFont(ofSize: overflowSize, weight: .regular)
    }
    private func overflowWidth(_ count: Int) -> CGFloat {
        ceil(("+\(count)" as NSString).size(withAttributes: [.font: overflowFont]).width)
    }
    private func overflow(_ count: Int, size: CGFloat? = nil) -> some View {
        Text("+\(count)")
            .font(.custom(AppFont.mono, fixedSize: size ?? overflowSize))
            .foregroundStyle(Color.inkSecondary)
            .fixedSize()
    }

    private func fittedOverflowSize(_ count: Int, width: CGFloat, height: CGFloat) -> CGFloat {
        CalendarIndicatorLayout.fittedLabelSize(requested: overflowSize,
            measuredWidth: overflowWidth(count), lineHeight: overflowFont.lineHeight,
            width: width, height: height)
    }

    @ViewBuilder
    private func indicators(width: CGFloat, height: CGFloat) -> some View {
        if style.usesDots {
            let count = min(3, viewModel.expenses.count)
            let hidden = max(0, viewModel.expenses.count - count)
            let minimumDotsWidth = CGFloat(count) * 5 - CGFloat(max(0, count - 1))
            let labelSize = fittedOverflowSize(hidden, width: width - minimumDotsWidth - 4, height: height)
            let labelWidth = overflowWidth(hidden) * labelSize / overflowSize
            let available = width - (hidden > 0 ? labelWidth + 4 : 0)
            HStack(spacing: 4) {
                HStack(spacing: CalendarIndicatorLayout.spacing(count: count, size: 5, available: available)) {
                    ForEach(Array(viewModel.expenses.prefix(count).enumerated()), id: \.offset) { _, expense in
                        Circle().fill(CalendarSeal.brandInk(expense.logoCustomization(in: viewModel.store), scheme: colorScheme))
                            .frame(width: 5, height: 5)
                    }
                }
                if hidden > 0 { overflow(hidden, size: labelSize) }
            }
        } else {
            let layout = CalendarIndicatorLayout.seals(count: viewModel.expenses.count, style: style,
                width: width, height: height, textWidth: overflowWidth, textHeight: overflowFont.lineHeight)
            // At the largest accessibility sizes, a single mark and fitted
            // count use one row. VoiceOver still reads the full expense list.
            let above = layout.overflowAbove && layout.visibleCount > 1
            let markWidth = CGFloat(layout.visibleCount) * layout.size + CGFloat(max(0, layout.visibleCount - 1)) * layout.spacing
            let labelSize = fittedOverflowSize(layout.overflowCount,
                width: above ? width : width - markWidth - 4,
                height: above ? height - layout.size - 2 : height)
            VStack(spacing: 2) {
                if above { overflow(layout.overflowCount, size: labelSize) }
                HStack(spacing: 4) {
                    HStack(spacing: layout.spacing) {
                        ForEach(Array(viewModel.expenses.prefix(layout.visibleCount).enumerated()), id: \.offset) { index, expense in
                            CalendarSeal(size: layout.size, customization: expense.logoCustomization(in: viewModel.store),
                                         logoName: expense.logoName, name: expense.name)
                                .zIndex(Double(2 - index))
                        }
                    }
                    if layout.overflowCount > 0 && !above { overflow(layout.overflowCount, size: labelSize) }
                }
            }
        }
    }
}

struct DayClickStyle: ButtonStyle {
    /// Empty cells skip press feedback so they do not feel selectable.
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
