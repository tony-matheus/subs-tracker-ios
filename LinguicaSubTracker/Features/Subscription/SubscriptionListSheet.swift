import SwiftUI

struct SubscriptionListSheet: View {
    let date: Date

    @State private var selectedService: SubscriptionTemplate? = nil
    @State private var active = true
    @State private var searchText: String = ""
    @State private var blankRoute: BlankRoute? = nil

    struct BlankRoute: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }

    @Environment(\.dismiss) private var dismiss

    let services = SubscriptionTemplate.mock

    var filteredServices: [SubscriptionTemplate] {
        if searchText.isEmpty {
            return services
        }

        return services.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var showEmptyCTA: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
            && filteredServices.isEmpty
    }

    func handleNavTap() {
        active = !active
    }

    func onCreate(sub: Subscription) {
        dismiss()
    }

    func onCommit(sub: Subscription) {
        dismiss()
    }

    var body: some View {
        NavigationStack {
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
                        ForEach(filteredServices) { service in
                            Button {
                                selectedService = service
                            } label: {
                                VStack(spacing: 8) {
                                    SubscriptionLogoCircle(
                                        size: 48,
                                        color: service.color,
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
            .safeAreaInset(edge: .bottom) {
                SearchBar(text: $searchText)
                    .padding(.bottom, 8)
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .animation(
                        .spring(duration: 0.35, bounce: 0.4),
                        value: selectedService
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        blankRoute = BlankRoute(name: "")
                    } label: {
                        Label("New", systemImage: "plus")
                            .typography(.bodyMedium.weight(.semibold))
                    }
                }
            }
            .navigationDestination(item: $selectedService) { service in
                SubscriptionFormView(
                    mode: .create(template: service, date: date),
                    onCommit: onCommit
                )
            }
            .navigationDestination(item: $blankRoute) { route in
                SubscriptionFormView(
                    mode: .createBlank(name: route.name, date: date),
                    onCommit: onCommit
                )
            }
        }
    }

    private var emptyCTA: some View {
        Button {
            blankRoute = BlankRoute(name: searchText)
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.white)

                VStack(spacing: 4) {
                    Text("Create \"\(searchText)\"")
                        .typography(.titleLarge.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text("Build a custom subscription")
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SubscriptionListSheet(date: Date())
        .environmentObject(AppStore())
        .environmentObject(SettingsStore())
}
