import SwiftUI

// MARK: - Amount Keypad Sheet

struct AmountKeypadSheet: View {
    @Binding var amount: Double
    @Binding var currencyCode: String
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var buffer: String = "0"

    private let currencies: [(code: String, symbol: String)] = [
        ("CAD", "$"), ("USD", "$"), ("EUR", "€"), ("BRL", "R$")
    ]

    private var currentSymbol: String {
        currencies.first { $0.code == currencyCode }?.symbol ?? "$"
    }

    private let keys: [[KeypadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.dot,        .digit("0"), .backspace  ],
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

            amountDisplay
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            keypadGrid
                .padding(.horizontal, 16)

            Spacer(minLength: 12)

            doneButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .onAppear {
            if amount > 0 {
                buffer = amount.asPeriodCurrency
            } else {
                buffer = "0"
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Menu {
                ForEach(currencies, id: \.code) { item in
                    Button {
                        currencyCode = item.code
                    } label: {
                        Text("\(item.code) (\(item.symbol))")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("\(currencyCode) (\(currentSymbol))")
                        .typography(.labelLarge)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .iconStyle(size: 11, weight: .semibold, color: .secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .tint(.secondary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .iconStyle(size: 13, weight: .semibold, color: .secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text("Amount")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)

            MoneyDisplay(text: "\(currentSymbol)\(buffer)", size: 48)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Keypad Grid

    private var keypadGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
            spacing: 12
        ) {
            ForEach(keys.flatMap { $0 }) { key in
                KeypadButton(key: key) {
                    handleKey(key)
                }
            }
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            amount = Double(buffer) ?? 0
            onDone()
        } label: {
            Text("Done")
                .typography(.titleMedium)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: - Input Logic

    private func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let d):
            if buffer == "0" {
                buffer = d
            } else {
                if let dotIndex = buffer.firstIndex(of: ".") {
                    let decimals = buffer.distance(from: buffer.index(after: dotIndex), to: buffer.endIndex)
                    if decimals >= 2 { return }
                }
                buffer.append(contentsOf: d)
            }

        case .dot:
            if !buffer.contains(".") {
                buffer.append(".")
            }

        case .backspace:
            if buffer.count > 1 {
                buffer.removeLast()
            } else {
                buffer = "0"
            }
        }
    }
}

// MARK: - KeypadKey

enum KeypadKey: Identifiable {
    case digit(String)
    case dot
    case backspace

    var id: String {
        switch self {
        case .digit(let d): return "digit_\(d)"
        case .dot:          return "dot"
        case .backspace:    return "backspace"
        }
    }

    var label: String {
        switch self {
        case .digit(let d): return d
        case .dot:          return "."
        case .backspace:    return "⌫"
        }
    }
}

// MARK: - KeypadButton

struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(key.label)
                .typography(.headlineMedium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color(UIColor.systemFill), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(KeypadButtonStyle())
    }
}

// MARK: - KeypadButtonStyle

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var amount: Double = 0
    @Previewable @State var currency = "CAD"

    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AmountKeypadSheet(amount: $amount, currencyCode: $currency) {}
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
        }
}
