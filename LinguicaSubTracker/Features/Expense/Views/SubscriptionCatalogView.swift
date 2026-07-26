import SwiftUI

/// Searchable grid of popular subscription templates. UI-agnostic: it owns no
/// store and no view model — callers pass the already-filtered templates and
/// handle selection however their flow needs (push a form, fill one in place).
struct SubscriptionCatalogView: View {
    let templates: [SubscriptionTemplate]
    @Binding var searchText: String
    let showEmptyCTA: Bool
    var onSelect: (SubscriptionTemplate) -> Void
    var onCreateBlank: (String) -> Void

    @State private var isSearchFocused: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            if showEmptyCTA {
                emptyCTA
                    .padding()
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()), GridItem(.flexible()),
                    ],
                    spacing: 8
                ) {
                    ForEach(templates) { service in
                        Button {
                            onSelect(service)
                        } label: {
                            VStack(spacing: 8) {
                                LogoCircle(
                                    size: 48,
                                    customization:
                                        service.makeCustomization(
                                            id: service.id
                                        ),
                                    logoName: service.logo,
                                    name: service.name
                                )

                                Text(service.name)
                                    .typography(.bodyMedium)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
        }
        .appSearchable(
            text: $searchText,
            isPresented: $isSearchFocused,
            prompt: "Search subscriptions"
        )
        .appBackground()
        .navigationTitle("Popular Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var emptyCTA: some View {
        Button {
            onCreateBlank(searchText)
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.primary)

                VStack(spacing: 4) {
                    Text("Create \"\(searchText)\"")
                        .typography(.titleLarge.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text("Build a custom expense")
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Catalog") {
    @Previewable @State var search = ""
    NavigationStack {
        SubscriptionCatalogView(
            templates: SubscriptionTemplate.mock,
            searchText: $search,
            showEmptyCTA: false,
            onSelect: { _ in },
            onCreateBlank: { _ in }
        )
    }
}

#Preview("Empty CTA") {
    @Previewable @State var search = "Figma"
    NavigationStack {
        SubscriptionCatalogView(
            templates: [],
            searchText: $search,
            showEmptyCTA: true,
            onSelect: { _ in },
            onCreateBlank: { _ in }
        )
    }
}
