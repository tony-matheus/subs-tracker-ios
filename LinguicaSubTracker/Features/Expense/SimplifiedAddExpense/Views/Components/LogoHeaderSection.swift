import SwiftUI

/// Logo + name header. When `isLocked` the logo came from a popular service
/// and is fixed — the badge is a state indicator, not a control.
struct LogoHeaderSection: View {
    let customization: LogoCustomization
    let logoName: String?
    @Binding var name: String
    var nameError: String? = nil
    var isLocked: Bool = false
    var accent: Color = .primary
    var onTapLogo: () -> Void = {}

    var nameFieldFocus: FocusState<Bool>.Binding?

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onTapLogo) {
                LogoCircle(
                    size: 120,
                    customization: customization,
                    logoName: logoName,
                    name: name
                )
            }
            .buttonStyle(.plain)
            // Block the tap without `.disabled`, which would dim the brand
            // logo — the lock badge already says it isn't editable.
            .allowsHitTesting(!isLocked)
            .overlay(alignment: .bottomTrailing) { lockBadge }

            VStack(spacing: 4) {
                nameField

                if let nameError {
                    Text(nameError)
                        .typography(.bodySmall)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private var nameField: some View {
        let field = TextField("Expense name", text: $name)
            .multilineTextAlignment(.center)
            .typography(.headlineMedium)
            .foregroundStyle(accent)
            .submitLabel(.done)

        if let nameFieldFocus {
            field.focused(nameFieldFocus)
        } else {
            field
        }
    }

    private var lockBadge: some View {
        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(accent)
            .frame(width: 34, height: 34)
            .background(.ultraThinMaterial, in: Circle())
            .accessibilityLabel(
                isLocked
                    ? "Logo locked to the selected service"
                    : "Logo can be customized"
            )
    }
}

#Preview("Locked — template") {
    @Previewable @State var name = "Netflix"
    ZStack {
        LinearGradient(colors: [Color(hex: "#E50914"), .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        LogoHeaderSection(
            customization: SubscriptionTemplate.mock
                .first { $0.name == "Netflix" }!
                .makeCustomization(id: UUID()),
            logoName: "netflix-logo",
            name: $name,
            isLocked: true,
            accent: .white
        )
    }
}

#Preview("Unlocked — blank") {
    @Previewable @State var name = ""
    ZStack {
        LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        LogoHeaderSection(
            customization: LogoCustomization(id: UUID(), primaryColorHex: "#5856D6"),
            logoName: nil,
            name: $name,
            nameError: "Give it a name first",
            accent: .white
        )
    }
}
