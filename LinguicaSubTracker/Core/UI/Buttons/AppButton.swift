import SwiftUI

struct AppButton: View {
    /// Global toggle: when `true`, `.outline` appearance also gets liquid glass.
    /// Flip to `false` to render outline as a flat stroked capsule.
    static var glassOnOutline: Bool = true

    let title: String
    let icon: String?
    let dimension: Dimension
    var style: ButtonVariant = .primary
    var size: ButtonSize = .medium
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var appearance: Appearance = .glassy
    var expands: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    enum Dimension {
        case standard
        case icon
    }

    enum Appearance {
        case solid  // flat opaque bg (white in dark mode, black in light mode), no glass
        case glassy  // ultraThinMaterial + glassEffect (default)
        case outline  // hairline stroke, optional glass via glassOnOutline
        case ghost  // no bg, no glass, no border
    }

    enum ButtonVariant {
        case primary, secondary, neutral, destructive
    }

    enum ButtonSize {
        case small, medium, large

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }

        var font: Font {
            switch self {
            case .small:
                return Theme.font(
                    size: AppTypography.Style.bodySmall.size,
                    weight: AppTypography.Style.bodySmall.weight
                )
            case .medium:
                return Theme.font(
                    size: AppTypography.Style.titleMedium.size,
                    weight: AppTypography.Style.titleMedium.weight
                )
            case .large:
                return Theme.font(
                    size: AppTypography.Style.titleLarge.size,
                    weight: AppTypography.Style.titleLarge.weight
                )
            }
        }

        var iconSide: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
    }

    init(
        title: String,
        icon: String? = nil,
        style: ButtonVariant = .primary,
        appearance: Appearance = .glassy,
        size: ButtonSize = .medium,
        expands: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.dimension = .standard
        self.style = style
        self.appearance = appearance
        self.size = size
        self.expands = expands
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    init(
        icon: String,
        accessibilityTitle title: String,
        style: ButtonVariant = .primary,
        appearance: Appearance = .glassy,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.dimension = .icon
        self.style = style
        self.appearance = appearance
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: iconForegroundColor)
                        )
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                }

                if let icon, !isLoading {
                    Image(systemName: icon)
                        .contentTransition(.symbolEffect(.replace))
                        .symbolColorRenderingMode(.gradient)
                        .foregroundColor(iconForegroundColor)
                        .accessibilityHidden(true)
                }

                if dimension == .standard {
                    Text(title)
                }
            }
            .font(size.font)
            .foregroundColor(foregroundColor)
            .padding(
                .horizontal,
                dimension == .icon
                    ? size.horizontalPadding : size.horizontalPadding
            )
            .padding(
                .vertical,
                dimension == .icon
                    ? size.horizontalPadding : size.verticalPadding
            )
            .frame(
                maxWidth: (dimension == .standard && expands) ? .infinity : nil
            )
            .frame(
                width: dimension == .icon ? size.iconSide : nil,
                height: dimension == .icon ? size.iconSide : nil
            )
            .background {
                switch appearance {
                case .outline:
                    Capsule().strokeBorder(
                        accentColor.opacity(0.6),
                        lineWidth: 1
                    )
                case .glassy, .ghost, .solid:
                    Color.clear
                }
            }
            .modifier(
                GlassIfNeeded(active: shouldApplyGlass, tint: glassTintColor)
            )
        }
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(
            isDisabled ? [.isButton, .isStaticText] : .isButton
        )
    }

    private var glassTintColor: Color {
        switch appearance {
        case .solid:
            switch style {
            case .primary: return .green
            case .secondary: return .purple
            case .neutral: return .white
            case .destructive: return .red
            }
        case .glassy, .outline, .ghost:
            return .clear
        }
    }

    private var accentColor: Color {
        switch style {
        case .destructive: .red
        case .neutral: colorScheme == .dark ? .white : .black
        case .primary: .green
        case .secondary: .purple
        }
    }

    private var iconForegroundColor: Color {
        switch appearance {
        case .glassy:
            switch style {
            case .neutral: return .white
            case .destructive: return .red
            case .primary: return .green
            case .secondary: return .purple
            }
        case .solid:
            switch style {
            case .neutral: return .black
            case .destructive, .primary, .secondary:
                return colorScheme == .dark ? .black : .white
            }
        case .outline, .ghost:
            return accentColor
        }
    }

    private var shouldApplyGlass: Bool {
        switch appearance {
        case .solid, .glassy: return true
        case .outline: return Self.glassOnOutline
        case .ghost: return false
        }
    }

    private var solidBackgroundColor: Color {
        switch style {
        case .destructive: Color.red
        case .neutral: Color.white
        case .primary: Color.green
        case .secondary: Color.purple
        }
    }

    private var foregroundColor: Color {
        switch appearance {
        case .glassy:
            switch style {
            case .destructive: return .red
            case .neutral: return colorScheme == .dark ? .white : .black
            case .primary, .secondary: return .primary
            }
        case .solid:
            switch style {
            case .neutral: return .black
            case .destructive, .primary, .secondary:
                return colorScheme == .dark ? .black : .white
            }
        case .outline, .ghost:
            return .primary
        }
    }
}

private struct GlassIfNeeded: ViewModifier {
    let active: Bool
    let tint: Color

    func body(content: Content) -> some View {
        if active {
            content.glassEffect(
                .regular.tint(tint).interactive(),
                in: Capsule()
            )
        } else {
            content
        }
    }
}

#Preview("AppButton") {
    @Previewable @State var size = AppButton.ButtonSize.medium
    @Previewable @State var isLoading = false
    @Previewable @State var isDisabled = false

    ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 10) {
                Picker("Size", selection: $size) {
                    Text("S").tag(AppButton.ButtonSize.small)
                    Text("M").tag(AppButton.ButtonSize.medium)
                    Text("L").tag(AppButton.ButtonSize.large)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)

                Button(isLoading ? "Loading ✓" : "Loading") {
                    isLoading.toggle()
                }
                .buttonStyle(.bordered)
                Button(isDisabled ? "Disabled ✓" : "Disabled") {
                    isDisabled.toggle()
                }
                .buttonStyle(.bordered)
                Spacer(minLength: 0)
            }

            ForEach(
                [AppButton.Appearance.glassy, .solid, .outline, .ghost],
                id: \.self
            ) { app in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard — \(label(for: app))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        GlassEffectContainer {
                            HStack(spacing: 8) {
                                AppButton(
                                    title: "Primary",
                                    icon: "plus",
                                    style: .primary,
                                    appearance: app,
                                    size: size,
                                    isLoading: isLoading,
                                    isDisabled: isDisabled,
                                    action: {}
                                )
                                AppButton(
                                    title: "Secondary",
                                    icon: "leaf.fill",
                                    style: .secondary,
                                    appearance: app,
                                    size: size,
                                    isLoading: isLoading,
                                    isDisabled: isDisabled,
                                    action: {}
                                )
                                AppButton(
                                    title: "Neutral",
                                    icon: "minus",
                                    style: .neutral,
                                    appearance: app,
                                    size: size,
                                    isLoading: isLoading,
                                    isDisabled: isDisabled,
                                    action: {}
                                )
                                AppButton(
                                    title: "Delete",
                                    icon: "trash",
                                    style: .destructive,
                                    appearance: app,
                                    size: size,
                                    isLoading: isLoading,
                                    isDisabled: isDisabled,
                                    action: {}
                                )
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .scrollClipDisabled()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon-only (a11y label preserved)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    GlassEffectContainer {
                        HStack(spacing: 8) {
                            AppButton(
                                icon: "plus",
                                accessibilityTitle: "Add expense",
                                style: .primary,
                                appearance: .solid,
                                size: size,
                                isLoading: isLoading,
                                isDisabled: isDisabled,
                                action: {}
                            )
                            AppButton(
                                icon: "magnifyingglass",
                                accessibilityTitle: "Search",
                                style: .secondary,
                                appearance: .outline,
                                size: size,
                                isLoading: isLoading,
                                isDisabled: isDisabled,
                                action: {}
                            )
                            AppButton(
                                icon: "ellipsis",
                                accessibilityTitle: "More options",
                                style: .primary,
                                appearance: .ghost,
                                size: size,
                                isLoading: isLoading,
                                isDisabled: isDisabled,
                                action: {}
                            )
                            AppButton(
                                icon: "trash",
                                accessibilityTitle: "Delete",
                                style: .destructive,
                                appearance: .outline,
                                size: size,
                                isLoading: isLoading,
                                isDisabled: isDisabled,
                                action: {}
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollClipDisabled()
            }
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
}

private func label(for app: AppButton.Appearance) -> String {
    switch app {
    case .solid: "solid"
    case .glassy: "glassy"
    case .outline: "outline"
    case .ghost: "ghost"
    }
}

extension AppButton.Appearance: Hashable {}
