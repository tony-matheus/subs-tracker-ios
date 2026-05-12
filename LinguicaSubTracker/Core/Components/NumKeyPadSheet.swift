import SwiftUI

// MARK: - Typing Style

enum NumKeyPadTypingStyle {
    /// Right-to-left, cents-based (POS/ATM style).
    /// Digits fill from the cent positions leftward; the decimal is always implicit.
    /// Bottom-left key is "C" (clear to 0.00).
    case decimal

    /// Left-to-right, explicit decimal point (classic calculator style).
    /// The user types freely and places the dot manually.
    /// Bottom-left key is "." (dot).
    case freeform
}

// MARK: - Sheet

struct NumKeyPadSheet: View {
    @Binding var amount: Double
    @Binding var currencyCode: String
    var typingStyle: NumKeyPadTypingStyle = .decimal
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) var settingsStore

    // MARK: Decimal state

    /// Integer cents, e.g. 1549 = $15.49. Only used in `.decimal` mode.
    @State private var cents: Int = 0
    private let maxCents = 9_999_999 // caps at 99,999.99

    // MARK: Freeform state

    /// String buffer for `.freeform` mode.
    @State private var buffer: String = "0"
    /// True once the user presses a key; first digit/dot resets the pre-filled buffer.
    @State private var hasUserInput: Bool = false

    // MARK: Shared

    private var currentSymbol: String {
        MoneyFormatter.symbol(for: currencyCode)
    }

    private var keys: [[KeypadKey]] {
        let bottomLeft: KeypadKey = (typingStyle == .decimal) ? .clear : .dot
        return [
            [.digit("1"), .digit("2"), .digit("3")],
            [.digit("4"), .digit("5"), .digit("6")],
            [.digit("7"), .digit("8"), .digit("9")],
            [bottomLeft,  .digit("0"), .backspace],
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                amountDisplay
                    .padding(.vertical, 16)

                keypadGrid

                Spacer(minLength: 12)

                AppButton(
                    title: "Done",
                    style: .neutral,
                    appearance: .solid,
                    size: .large,
                    expands: true,
                    action: commitAmount
                )
            }
            .padding(.horizontal, 16)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CurrencyMenu(code: $currencyCode)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .onAppear {
            if currencyCode.isEmpty {
                currencyCode = settingsStore.settings.currencyCode
            }
            switch typingStyle {
            case .decimal:
                cents = Int((amount * 100).rounded())
            case .freeform:
                buffer = formattedBuffer(for: amount)
                hasUserInput = false
            }
        }
    }

    // MARK: Sub-views

    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text("Amount")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)

            switch typingStyle {
            case .decimal:
                NumKeyPadAmountDisplay(cents: cents, symbol: currentSymbol)
            case .freeform:
                MoneyDisplay(text: "\(currentSymbol)\(buffer)", size: 48)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: buffer)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var keypadGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 12
        ) {
            ForEach(keys.flatMap { $0 }) { key in
                KeypadButton(key: key) { handleKey(key) }
            }
        }
    }

    // MARK: Actions

    private func commitAmount() {
        switch typingStyle {
        case .decimal:
            amount = Double(cents) / 100.0
        case .freeform:
            amount = Double(buffer) ?? 0
        }
        onDone()
    }

    private func handleKey(_ key: KeypadKey) {
        switch typingStyle {
        case .decimal:  handleDecimalKey(key)
        case .freeform: handleFreeformKey(key)
        }
    }

    private func handleDecimalKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            guard let digit = Int(d) else { return }
            let newCents = cents * 10 + digit
            guard newCents <= maxCents else { return }
            cents = newCents
        case .backspace:
            cents = cents / 10
        case .clear:
            cents = 0
        case .dot:
            break
        }
    }

    private func handleFreeformKey(_ key: KeypadKey) {
        if !hasUserInput {
            switch key {
            case .digit, .dot: buffer = "0"
            case .backspace, .clear: break
            }
            hasUserInput = true
        }

        switch key {
        case .digit(let d):
            if buffer == "0" {
                buffer = d
            } else {
                if let dotIndex = buffer.firstIndex(of: ".") {
                    let decimals = buffer.distance(
                        from: buffer.index(after: dotIndex),
                        to: buffer.endIndex
                    )
                    if decimals >= 2 { return }
                }
                buffer.append(contentsOf: d)
            }
        case .dot:
            if !buffer.contains(".") { buffer.append(".") }
        case .backspace:
            if buffer.count > 1 { buffer.removeLast() } else { buffer = "0" }
        case .clear:
            break
        }
    }

    /// Returns a plain, non-grouped buffer string for `amount` suitable for freeform display.
    /// Trailing zero decimals are trimmed (e.g. `12.0` → `"12"`, `12.50` → `"12.5"`).
    private func formattedBuffer(for amount: Double) -> String {
        guard amount > 0 else { return "0" }
        let rounded = (amount * 100).rounded() / 100
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        let raw = String(format: "%.2f", rounded)
        return raw.hasSuffix("0") ? String(raw.dropLast()) : raw
    }
}

// MARK: - Amount Display (decimal mode)

/// Renders `cents` as a dollar amount with a queue-style animation:
/// dollar digits slide in from the right when added and exit to the right on
/// backspace. The two cent digits roll in-place with a numeric text transition.
struct NumKeyPadAmountDisplay: View {
    let cents: Int
    let symbol: String

    /// Dollar digits as an array of characters, e.g. 1549 → ["1", "5"].
    private var dollarChars: [Character] { Array(String(cents / 100)) }

    /// Cent digits always zero-padded to exactly 2, e.g. 9 → ["0", "9"].
    private var centChars: [Character] { Array(String(format: "%02d", cents % 100)) }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(symbol)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.trailing, 2)

            // Dollar digits — stable by position from the left.
            // Adding a digit appends at the highest offset (enters from the right).
            // Backspacing removes the highest offset (exits to the right).
            // A digit whose value changes in-place rolls via numericText.
            ForEach(Array(dollarChars.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .transition(.asymmetric(
                        insertion: .push(from: .trailing).combined(with: .opacity),
                        removal:   .push(from: .leading).combined(with: .opacity)
                    ))
            }

            Text(".")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)

            // Cent digits — always 2 positions, values roll numerically.
            ForEach(Array(centChars.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: cents)
    }
}

// MARK: - Key Model

enum KeypadKey: Identifiable {
    case digit(String)
    case dot
    case backspace
    case clear

    var id: String {
        switch self {
        case .digit(let d): return "digit_\(d)"
        case .dot:          return "dot"
        case .backspace:    return "backspace"
        case .clear:        return "clear"
        }
    }

    var label: String {
        switch self {
        case .digit(let d): return d
        case .dot:          return "."
        case .backspace:    return "⌫"
        case .clear:        return "C"
        }
    }
}

// MARK: - Key Button

struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void

    private var isUtility: Bool {
        switch key {
        case .clear, .backspace: return true
        default: return false
        }
    }

    var body: some View {
        Button(action: action) {
            Text(key.label)
                .typography(.headlineMedium)
                .foregroundStyle(isUtility ? .secondary : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    isUtility ? Color.clear : Color(UIColor.systemFill),
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .buttonStyle(KeypadButtonStyle())
    }
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.65),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

// MARK: - Preview

#Preview("Decimal (default)") {
    @Previewable @State var amount: Double = 0
    @Previewable @State var currency = "CAD"

    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NumKeyPadSheet(amount: $amount, currencyCode: $currency) {}
                .environment(SettingsStore())
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
        }
}

#Preview("Freeform") {
    @Previewable @State var amount: Double = 0
    @Previewable @State var currency = "CAD"

    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            NumKeyPadSheet(amount: $amount, currencyCode: $currency, typingStyle: .freeform) {}
                .environment(SettingsStore())
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
        }
}
