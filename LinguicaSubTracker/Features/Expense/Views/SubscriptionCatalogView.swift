import SwiftUI

/// Searchable catalog of popular subscription templates, pushed from the
/// add-expense hub. Selecting a template (or the empty-state CTA) sets a
/// route on the shared view model; the hub's `navigationDestination`s
/// push the expense form from there.
struct SubscriptionCatalogView: View {
    @Bindable var viewModel: ExpenseTemplateSheetViewModel
    @State private var isSearchFocused: Bool = false

    var body: some View {
        ScrollView {
            if viewModel.showEmptyCTA {
                emptyCTA
                    .padding()
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()), GridItem(.flexible()),
                    ],
                    spacing: 8
                ) {
                    ForEach(viewModel.filteredServices) { service in
                        Button {
                            viewModel.selectTemplate(service)
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
                                    .foregroundStyle(.primary)
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
            text: $viewModel.searchText,
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
            viewModel.createBlankWithSearch()
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.primary)

                VStack(spacing: 4) {
                    Text("Create \"\(viewModel.searchText)\"")
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
