import SwiftUI

struct SubscriptionListSheet: View {
    let date: Date

    @State private var selectedService: SubscriptionTemplate? = nil
    @State private var active = true
    @State private var searchText: String = ""

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
            }
            .navigationDestination(item: $selectedService) { service in
                SubscriptionFormView(
                    mode: .create(template: service, date: date),
                    onCommit: onCommit
                )
            }
        }
    }
}

#Preview {
    SubscriptionListSheet(date: Date()).environmentObject(AppStore())
}
