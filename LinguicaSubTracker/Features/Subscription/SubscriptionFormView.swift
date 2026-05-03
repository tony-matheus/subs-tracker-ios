import SwiftUI

// MARK: - Mode

enum SubscriptionFormMode {
    case create(template: SubscriptionTemplate, date: Date)
    case edit(Subscription)
}

// MARK: - Form View

struct SubscriptionFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let mode: SubscriptionFormMode
    let onCommit: (Subscription) -> Void

    @State private var name: String
    @State private var price: Double
    @State private var schedule: SubscriptionSchedule
    @State private var startDate: Date
    @State private var category: String
    @State private var paymentMethod: String
    @State private var notes: String
    @State private var showDeleteAlert = false

    private let originalID: UUID?
    private let themeColor: Color

    init(mode: SubscriptionFormMode, onCommit: @escaping (Subscription) -> Void) {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create(let template, let date):
            originalID   = nil
            themeColor   = template.color
            _name        = State(initialValue: template.name)
            _price       = State(initialValue: 10.00)
            _schedule    = State(initialValue: .monthly)
            _startDate   = State(initialValue: date)
            _category    = State(initialValue: "Entertainment")
            _paymentMethod = State(initialValue: "None")
            _notes       = State(initialValue: "")

        case .edit(let sub):
            originalID   = sub.id
            themeColor   = Color(hex: sub.colorHex)
            _name        = State(initialValue: sub.name)
            _price       = State(initialValue: sub.price)
            _schedule    = State(initialValue: sub.schedule)
            _startDate   = State(initialValue: sub.startDate)
            _category    = State(initialValue: sub.category)
            _paymentMethod = State(initialValue: sub.paymentMethod ?? "None")
            _notes       = State(initialValue: sub.notes ?? "")
        }
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var colorHex: String {
        if case .create(let template, _) = mode {
            return template.brandHex ?? template.fallbackColor.toHex()
        }
        if case .edit(let sub) = mode { return sub.colorHex }
        return "#888888"
    }

    private var logoName: String? {
        switch mode {
        case .create(let template, _): return template.logo
        case .edit: return SubscriptionTemplate.logoName(for: name)
        }
    }

    // MARK: - Validation

    private func isValid() -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && price > 0
    }

    // MARK: - Save

    private func commit() {
        guard isValid() else { return }

        let subscription = Subscription(
            id: originalID ?? UUID(),
            name: name,
            price: price,
            colorHex: colorHex,
            schedule: schedule,
            startDate: startDate,
            paymentMethod: paymentMethod == "None" ? nil : paymentMethod,
            notes: notes.isEmpty ? nil : notes,
            category: category,
            list: "Default"
        )

        if !isEditMode {
            store.add(subscription)
        }

        dismiss()
        onCommit(subscription)
    }

    // MARK: - Body

    var body: some View {
        if isEditMode {
            NavigationStack {
                formContent
                    .toolbar { editToolbar }
            }
        } else {
            formContent
        }
    }

    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel", role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    private var formContent: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [themeColor.opacity(0.6), Color.black.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 40)
                .frame(height: 200)
                .ignoresSafeArea()

                Spacer()
            }

            ScrollView {
                VStack(spacing: 16) {
                    SubscriptionLogoCircle(
                        size: 72,
                        color: themeColor,
                        logoName: logoName,
                        name: name
                    )
                    .padding(.top, 16)

                    GlassSection {
                        Row(label: "Name") {
                            TextField("", text: $name)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider()

                        Row(label: "Payment Schedule") {
                            Picker("", selection: $schedule) {
                                Text("Monthly").tag(SubscriptionSchedule.monthly)
                                Text("Yearly").tag(SubscriptionSchedule.yearly)
                            }
                            .pickerStyle(.menu)
                            .tint(Color.secondary)
                        }

                        Divider()

                        Row(label: "Start Date") {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                                .tint(themeColor)
                        }
                    }

                    GlassSection {
                        Row(label: "Amount") {
                            TextField("", value: $price, format: .currency(code: "CAD"))
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    }

                    GlassSection {
                        Row(label: "Category", icon: "tag.fill", iconColor: themeColor) {
                            Picker("", selection: $category) {
                                Text("Entertainment").tag("Entertainment")
                                Text("Productivity").tag("Productivity")
                            }
                            .pickerStyle(.menu)
                            .tint(Color.secondary)
                        }

                        Divider()

                        Row(label: "Pay with", icon: "wallet.bifold.fill", iconColor: themeColor) {
                            Picker("", selection: $paymentMethod) {
                                Text("None").tag("None")
                                Text("Credit").tag("Credit")
                                Text("Debit").tag("Debit")
                            }
                            .pickerStyle(.menu)
                            .tint(Color.secondary)
                        }

                        Divider()

                        Row(label: "List", icon: "list.dash", iconColor: themeColor) {
                            Text("Personal").foregroundStyle(.secondary)
                        }
                    }

                    GlassSection {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .typography(.titleSmall)
                                .foregroundStyle(.secondary)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            Button { commit() } label: {
                Text(isEditMode ? "Save Changes" : "Add Subscription")
                    .typography(.titleMedium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
            }
            .background(themeColor.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding()
        }
        .navigationTitle(isEditMode ? "Edit Subscription" : "New Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Subscription", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let id = originalID {
                    store.subscriptions.removeAll { $0.id == id }
                    StorageService.save(store.subscriptions)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(name) will be permanently removed.")
        }
    }

}

// MARK: - Supporting Views (shared)

struct Row<Content: View>: View {
    let label: String
    var icon: String? = nil
    var iconColor: Color = .secondary
    let content: Content

    init(
        label: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .iconStyle(size: 14, weight: .medium, color: iconColor)
                    .frame(width: 20)
            }
            Text(label)
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
            Spacer()
            content.foregroundStyle(.primary)
        }
        .frame(height: 44)
    }
}

struct GlassSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Preview

#Preview("Create") {
    NavigationStack {
        SubscriptionFormView(
            mode: .create(
                template: .init(name: "YouTube", brandHex: "#FF0000", fallbackColor: .red, logo: "youtube-logo"),
                date: Date()
            ),
            onCommit: { _ in }
        )
    }
    .environmentObject(AppStore())
}

#Preview("Edit") {
    let sub = Subscription(
        name: "Spotify", price: 9.99, colorHex: "#1DB954",
        schedule: .monthly, startDate: Date()
    )
    return NavigationStack {
        SubscriptionFormView(mode: .edit(sub), onCommit: { _ in })
    }
    .environmentObject(AppStore())
}
