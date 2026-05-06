import SwiftUI
import UIKit

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
    @State private var list: String
    @State private var showDeleteAlert = false
    @State private var showKeypad = false
    @State private var currencyCode: String = "CAD"
    @State private var isNativeKeyboardVisible = false

    private let originalID: UUID?
    private let themeColor: Color

    init(mode: SubscriptionFormMode, onCommit: @escaping (Subscription) -> Void)
    {
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .create(let template, let date):
            originalID = nil
            themeColor = template.color
            _name = State(initialValue: template.name)
            _price = State(initialValue: 0.00)
            _schedule = State(initialValue: .monthly)
            _startDate = State(initialValue: date)
            _category = State(initialValue: "Entertainment")
            _paymentMethod = State(initialValue: "None")
            _notes = State(initialValue: "")
            _list = State(initialValue: "Personal")

        case .edit(let sub):
            originalID = sub.id
            themeColor = Color(hex: sub.colorHex)
            _name = State(initialValue: sub.name)
            _price = State(initialValue: sub.price)
            _schedule = State(initialValue: sub.schedule)
            _startDate = State(initialValue: sub.startDate)
            _category = State(initialValue: sub.category)
            _paymentMethod = State(initialValue: sub.paymentMethod ?? "None")
            _notes = State(initialValue: sub.notes ?? "")
            _list = State(
                initialValue: sub.list == "Default" ? "Personal" : sub.list
            )
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

    private func dismissNativeKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

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
            list: list
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
                    colors: [
                        themeColor.opacity(0.6), Color.black.opacity(0.0),
                    ],
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
                                .typography(.bodyMedium)
                        }

                        Divider()

                        Row(label: "Payment Schedule") {
                            Picker("", selection: $schedule) {
                                Text("Monthly").tag(
                                    SubscriptionSchedule.monthly
                                )
                                Text("Yearly").tag(SubscriptionSchedule.yearly)
                            }
                            .pickerStyle(.menu)
                            .typography(.bodyMedium)
                            .tint(Color.secondary)
                        }

                        Divider()

                        Row(label: "Start Date") {
                            DatePicker(
                                "",
                                selection: $startDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .typography(.bodyMedium)
                            .tint(themeColor)
                        }
                    }

                    GlassSection {
                        Button {
                            showKeypad = true
                        } label: {
                            Row(label: "Amount") {
                                Text(
                                    price,
                                    format: .currency(code: currencyCode)
                                )
                                .typography(.headlineSmall.weight(.regular))
                                .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    GlassSection {
                        Row(
                            label: "Category",
                            icon: "tag.fill",
                            iconColor: themeColor
                        ) {
                            Picker("", selection: $category) {
                                Text("Entertainment").tag("Entertainment")
                                Text("Productivity").tag("Productivity")
                            }
                            .pickerStyle(.menu)
                            .typography(.bodyMedium)
                            .tint(Color.secondary)
                        }

                        Divider()

                        Row(
                            label: "Pay with",
                            icon: "wallet.bifold.fill",
                            iconColor: themeColor
                        ) {
                            Picker("", selection: $paymentMethod) {
                                Text("None").tag("None")
                                Text("Credit").tag("Credit")
                                Text("Debit").tag("Debit")
                            }
                            .pickerStyle(.menu)
                            .typography(.bodyMedium)
                            .tint(Color.secondary)
                        }

                        Divider()

                        Row(
                            label: "List",
                            icon: "list.dash",
                            iconColor: themeColor
                        ) {
                            Picker("", selection: $list) {
                                Text("Personal").tag("Personal")
                                Text("Work").tag("Work")
                                Text("Family").tag("Family")
                            }
                            .pickerStyle(.menu)
                            .typography(.bodyMedium)
                            .tint(Color.secondary)
                        }
                    }

                    GlassSection {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .typography(.titleMedium)
                                .foregroundStyle(.secondary)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .typography(.bodyMedium)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            Group {
                if isNativeKeyboardVisible {
                    HStack {
                        Spacer()
                        Button {
                            dismissNativeKeyboard()
                        } label: {
                            Text("Close")
                                .typography(.bodyMedium.weight(.semibold))
                                .foregroundStyle(.foreground)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .glassEffect(.regular.interactive())
                        .padding()
                    }
                } else {
                    Button {
                        commit()
                    } label: {
                        Text(isEditMode ? "Save Changes" : "Add Subscription")
                            .typography(.titleLarge.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.black)
                    }
                    .frame(height: 54)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .padding()
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardDidShowNotification
            )
        ) { _ in
            isNativeKeyboardVisible = true
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardDidHideNotification
            )
        ) { _ in
            isNativeKeyboardVisible = false
        }
        .sheet(isPresented: $showKeypad) {
            AmountKeypadSheet(amount: $price, currencyCode: $currencyCode) {
                showKeypad = false
            }
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
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
                    .iconStyle(size: 16, weight: .medium, color: iconColor)
                    .frame(width: 20)
            }
            Text(label)
                .typography(.bodyLarge)
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
                template: .init(
                    name: "YouTube",
                    brandHex: "#FF0000",
                    fallbackColor: .red,
                    logo: "youtube-logo"
                ),
                date: Date()
            ),
            onCommit: { _ in }
        )
    }
    .environmentObject(AppStore())
}

#Preview("Edit") {
    let sub = Subscription(
        name: "Spotify",
        price: 9.99,
        colorHex: "#1DB954",
        schedule: .monthly,
        startDate: Date()
    )
    return NavigationStack {
        SubscriptionFormView(mode: .edit(sub), onCommit: { _ in })
    }
    .environmentObject(AppStore())
}
