import SwiftUI
import PhotosUI
import UIKit

enum LogoTab: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case emoji = "Emoji"
    case symbols = "Symbols"
    var id: String { rawValue }
}

struct LogoSheet: View {
    @Binding var customization: LogoCustomization
    let name: String
    var onDismiss: () -> Void

    @State private var tab: LogoTab

    init(
        customization: Binding<LogoCustomization>,
        name: String,
        onDismiss: @escaping () -> Void
    ) {
        self._customization = customization
        self.name = name
        self.onDismiss = onDismiss
        let initial: LogoTab
        switch customization.wrappedValue.style {
        case .photo: initial = .photo
        case .emoji: initial = .emoji
        case .symbol: initial = .symbols
        }
        self._tab = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 16) {
            LogoCircle(
                size: 96,
                customization: customization,
                name: name
            )
            .padding(.top, 16)

            LogoTabPicker(tab: $tab)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 16) {
                    GlassSection {
                        LogoColorPalette(customization: $customization)
                    }

                    GlassSection {
                        Group {
                            switch tab {
                            case .photo:
                                PhotoTabBody(customization: $customization, name: name)
                            case .emoji:
                                EmojiTabBody(customization: $customization)
                            case .symbols:
                                SymbolTabBody(customization: $customization)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .appBackground()
        .onChange(of: tab) { _, newTab in
            switch newTab {
            case .photo: customization.style = .photo
            case .emoji: customization.style = .emoji
            case .symbols: customization.style = .symbol
            }
        }
    }
}


// MARK: - Tab Picker

private struct LogoTabPicker: View {
    @Binding var tab: LogoTab

    private let gradient = LinearGradient(
        colors: [Color(red: 0.30, green: 0.85, blue: 0.45), Color(red: 0.05, green: 0.40, blue: 0.20)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        CustomSegmentedPicker(
            selection: $tab,
            segments: [
                segment(.photo, symbol: "photo.fill", text: "Photo"),
                segment(.emoji, symbol: "face.smiling.inverse", text: "Emoji"),
                segment(.symbols, symbol: "star.fill", text: "Symbols"),
            ]
        )
    }

    private func segment(_ value: LogoTab, symbol: String, text: String) -> CustomSegment<LogoTab> {
        CustomSegment(
            value: value,
            leading: {
                Image(systemName: symbol)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(gradient)
                    .font(.system(size: 14, weight: .semibold))
            },
            center: {
                Text(text)
                    .typography(.bodyMedium.weight(.semibold))
                    .foregroundStyle(tab == value ? Color.primary : Color.secondary)
            }
        )
    }
}


// MARK: - Color rows

struct LogoColorRow: View {
    let title: String
    @Binding var selectedHex: String

    init(title: String = "COLOR", selectedHex: Binding<String>) {
        self.title = title
        self._selectedHex = selectedHex
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .typography(.labelMedium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LogoPalette.colors, id: \.self) { hex in
                        Button {
                            selectedHex = hex
                        } label: {
                            colorSwatch(hex: hex, selected: selectedHex == hex)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }
}

struct OptionalLogoColorRow: View {
    let title: String
    @Binding var selectedHex: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .typography(.labelMedium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        selectedHex = nil
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: selectedHex == nil ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                            Image(systemName: "slash.circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(LogoPalette.colors, id: \.self) { hex in
                        Button {
                            selectedHex = hex
                        } label: {
                            colorSwatch(hex: hex, selected: selectedHex == hex)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
    }
}

@ViewBuilder
private func colorSwatch(hex: String, selected: Bool) -> some View {
    Circle()
        .fill(Color(hex: hex))
        .frame(width: 36, height: 36)
        .overlay(
            Circle()
                .stroke(.white, lineWidth: selected ? 3 : 0)
        )
        .overlay(
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
}

struct LogoColorPalette: View {
    @Binding var customization: LogoCustomization

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LogoColorRow(title: "PRIMARY", selectedHex: $customization.primaryColorHex)
            OptionalLogoColorRow(title: "BACKGROUND", selectedHex: $customization.backgroundColorHex)
            OptionalLogoColorRow(title: "SECONDARY", selectedHex: $customization.secondaryColorHex)
            OptionalLogoColorRow(title: "SHADOW", selectedHex: $customization.shadowColorHex)
        }
    }
}


// MARK: - Symbol body

private struct SymbolTabBody: View {
    @Binding var customization: LogoCustomization

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RENDERING")
                .typography(.labelMedium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            Picker("", selection: $customization.symbolRendering) {
                Text("Solid").tag(SymbolRendering.solid)
                Text("Multicolor").tag(SymbolRendering.multicolor)
                Text("Gradient").tag(SymbolRendering.gradient)
            }
            .pickerStyle(.segmented)

            Divider().opacity(0.3)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SymbolCatalog.symbols, id: \.self) { symbol in
                    Button {
                        customization.symbolName = symbol
                        customization.style = .symbol
                    } label: {
                        symbolCell(symbol)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func symbolCell(_ symbol: String) -> some View {
        let isSelected = customization.symbolName == symbol
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isSelected
                        ? Color(hex: customization.primaryColorHex).opacity(0.35)
                        : Color.primary.opacity(0.06)
                )
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(height: 56)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isSelected
                        ? Color(hex: customization.primaryColorHex)
                        : .clear,
                    lineWidth: 2
                )
        )
    }
}


// MARK: - Emoji body

private struct EmojiTabBody: View {
    @Binding var customization: LogoCustomization
    @State private var search: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $search)
                    .typography(.bodyMedium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.08), in: Capsule())

            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(EmojiCatalog.filtered(search)) { category in
                    Text(category.name)
                        .typography(.labelMedium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(category.emojis, id: \.char) { entry in
                            Button {
                                customization.emoji = entry.char
                                customization.style = .emoji
                            } label: {
                                Text(entry.char)
                                    .font(.system(size: 30))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                customization.emoji == entry.char
                                                    ? Color(hex: customization.primaryColorHex).opacity(0.4)
                                                    : .clear
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Photo body

private struct PhotoTabBody: View {
    @Binding var customization: LogoCustomization
    let name: String

    @State private var pickerItem: PhotosPickerItem? = nil

    private var hasImage: Bool { customization.imageData != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sliderRow(
                label: "Zoom",
                icon: "plus.magnifyingglass",
                value: $customization.imageScale,
                range: 1.0...3.0
            )
            sliderRow(
                label: "Horizontal",
                icon: "arrow.left.and.right",
                value: $customization.imageOffsetX,
                range: -1.0...1.0
            )
            sliderRow(
                label: "Vertical",
                icon: "arrow.up.and.down",
                value: $customization.imageOffsetY,
                range: -1.0...1.0
            )
            .padding(.bottom, 4)

            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text(hasImage ? "Replace photo" : "Select custom photo")
                        .typography(.titleMedium.weight(.semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }

            if hasImage {
                Button(role: .destructive) {
                    customization.imageData = nil
                    customization.imageOffsetX = 0
                    customization.imageOffsetY = 0
                    customization.imageScale = 1.0
                } label: {
                    Text("Remove photo")
                        .typography(.bodyMedium.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .opacity(hasImage ? 1 : 0.95)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadPhoto(newItem) }
        }
    }

    private func sliderRow(
        label: String,
        icon: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .typography(.bodyMedium)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .tint(Color(hex: customization.primaryColorHex))
                .disabled(!hasImage)
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let raw = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: raw) else { return }
        let resized = downscale(ui, maxEdge: 512)
        guard let jpeg = resized.jpegData(compressionQuality: 0.7) else { return }
        await MainActor.run {
            customization.imageData = jpeg
            customization.style = .photo
            customization.imageOffsetX = 0
            customization.imageOffsetY = 0
            customization.imageScale = 1.0
        }
    }

    private func downscale(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        let largest = max(w, h)
        guard largest > maxEdge else { return image }
        let scale = maxEdge / largest
        let newSize = CGSize(width: w * scale, height: h * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}


// MARK: - Preview

#Preview("Symbols — Solid") {
    @Previewable @State var customization = LogoCustomization(
        id: UUID(),
        primaryColorHex: "#1DB954",
        backgroundColorHex: "#000000",
        style: .symbol,
        symbolName: "music.note",
        symbolRendering: .solid
    )
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            LogoSheet(
                customization: $customization,
                name: "Spotify",
                onDismiss: {}
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
        }
}

#Preview("Symbols — Multicolor") {
    @Previewable @State var customization = LogoCustomization(
        id: UUID(),
        primaryColorHex: "#F6F6F5",
        backgroundColorHex: "#1C1C1E",
        style: .symbol,
        symbolName: "cloud.sun.rain.fill",
        symbolRendering: .multicolor
    )
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            LogoSheet(
                customization: $customization,
                name: "Weather",
                onDismiss: {}
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
        }
}

#Preview("Symbols — Gradient") {
    @Previewable @State var customization = LogoCustomization(
        id: UUID(),
        primaryColorHex: "#1DB954",
        backgroundColorHex: "#000000",
        style: .symbol,
        symbolName: "music.note",
        symbolRendering: .gradient
    )
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            LogoSheet(
                customization: $customization,
                name: "Spotify",
                onDismiss: {}
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
        }
}

#Preview("Emoji") {
    @Previewable @State var customization = LogoCustomization(
        id: UUID(),
        primaryColorHex: "#FF9500",
        style: .emoji,
        emoji: "🎬"
    )
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            LogoSheet(
                customization: $customization,
                name: "Netflix",
                onDismiss: {}
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
        }
}

#Preview("Photo") {
    @Previewable @State var customization = LogoCustomization(
        id: UUID(),
        primaryColorHex: "#007AFF",
        style: .photo
    )
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            LogoSheet(
                customization: $customization,
                name: "iCloud",
                onDismiss: {}
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
        }
}
