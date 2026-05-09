import SwiftUI
import PhotosUI
import UIKit

enum LogoTab: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case emoji = "Emoji"
    case symbols = "Symbols"
    var id: String { rawValue }
}

struct SubscriptionLogoSheet: View {
    @Binding var customization: LogoCustomization
    let subscriptionName: String
    var onDismiss: () -> Void

    @State private var tab: LogoTab

    init(
        customization: Binding<LogoCustomization>,
        subscriptionName: String,
        onDismiss: @escaping () -> Void
    ) {
        self._customization = customization
        self.subscriptionName = subscriptionName
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
            Picker("", selection: $tab) {
                ForEach(LogoTab.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            Group {
                switch tab {
                case .photo:
                    PhotoTabView(customization: $customization, name: subscriptionName)
                case .emoji:
                    EmojiTabView(customization: $customization)
                case .symbols:
                    SymbolTabView(customization: $customization)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .onChange(of: tab) { _, newTab in
            switch newTab {
            case .photo: customization.style = .photo
            case .emoji: customization.style = .emoji
            case .symbols: customization.style = .symbol
            }
        }
    }
}

// MARK: - Color Row

struct LogoColorRow: View {
    @Binding var selectedHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COLOR")
                .typography(.labelMedium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LogoPalette.colors, id: \.self) { hex in
                        Button {
                            selectedHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: selectedHex == hex ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Symbol Tab

struct SymbolTabView: View {
    @Binding var customization: LogoCustomization

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LogoColorRow(selectedHex: $customization.colorHex)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SymbolCatalog.symbols, id: \.self) { symbol in
                        Button {
                            customization.symbolName = symbol
                            customization.style = .symbol
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        customization.symbolName == symbol
                                            ? Color(hex: customization.colorHex).opacity(0.35)
                                            : Color.white.opacity(0.06)
                                    )
                                Image(systemName: symbol)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        customization.symbolName == symbol
                                            ? Color(hex: customization.colorHex)
                                            : .clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Emoji Tab

struct EmojiTabView: View {
    @Binding var customization: LogoCustomization
    @State private var search: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 12) {
            LogoColorRow(selectedHex: $customization.colorHex)
                .padding(.horizontal)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $search)
                    .typography(.bodyMedium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: Capsule())
            .padding(.horizontal)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    ForEach(EmojiCatalog.filtered(search)) { category in
                        Section {
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
                                                            ? Color(hex: customization.colorHex).opacity(0.4)
                                                            : .clear
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            Text(category.name)
                                .typography(.labelMedium)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Photo Tab

struct PhotoTabView: View {
    @Binding var customization: LogoCustomization
    let name: String

    @State private var pickerItem: PhotosPickerItem? = nil

    private var hasImage: Bool { customization.imageData != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LogoColorRow(selectedHex: $customization.colorHex)
                    .padding(.horizontal)

                GlassSection {
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
                    }
                }
                .padding(.horizontal)
                .opacity(hasImage ? 1 : 0.4)
                .disabled(!hasImage)

                Spacer(minLength: 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(hasImage ? "Replace photo" : "Select custom photo")
                            .typography(.titleMedium.weight(.semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
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
                .tint(Color(hex: customization.colorHex))
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
