import SwiftUI

struct SubscriptionFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let service: SubscriptionTemplate
    let date: Date
    let onCreate: (Subscription) -> Void

    @State private var name: String
    @State private var price: Double
    @State private var schedule: SubscriptionSchedule
    @State private var startDate: Date
    @State private var category: String
    @State private var paymentMethod: String
    @State private var notes: String

    init(
        service: SubscriptionTemplate,
        date: Date,
        onCreate: @escaping (Subscription) -> Void
    ) {
        self.service = service
        self.date = date
        self.onCreate = onCreate

        _name = State(initialValue: "Spotify")
        _price = State(initialValue: 0)
        _schedule = State(initialValue: SubscriptionSchedule.monthly)
        _startDate = State(initialValue: date)
        _category = State(initialValue: "Entertainment")
        _paymentMethod = State(initialValue: "None")
        _notes = State(initialValue: "")

    }

    private func isValid() -> Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }

        guard price > 0 else {
            return false
        }

        return true
    }

    private func saveSubscription() {
        guard isValid() else {
            print("Validation failed")
            return
        }

        let subscription = Subscription(
            name: name,
            price: price,
            colorHex: service.color.toHex(),
            schedule: schedule,
            startDate: startDate,
            paymentMethod: paymentMethod == "None" ? nil : paymentMethod,
            notes: notes.isEmpty ? nil : notes,
            category: category,
            list: "Default"
        )

        store.subscriptions.append(subscription)

        dismiss()
        onCreate(subscription)
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // 🔥 Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // 🟢 Top blur gradient (sticky feel)
                LinearGradient(
                    colors: [
                        service.color.opacity(0.6),
                        Color.black.opacity(0.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 40)
                .frame(height: 200)
                .ignoresSafeArea()

                Spacer()
            }

            // 🧾 Content
            ScrollView {
                VStack(spacing: 16) {

                    // 🟢 Header icon (no container)
                    Circle()
                        .fill(service.color)
                        .frame(width: 72, height: 72)
                        .padding(.top, 16)

                    // 📦 Main section
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
                        }

                        Divider()

                        Row(label: "Start Date") {
                            DatePicker(
                                "",
                                selection: $startDate,
                                displayedComponents: .date,
                            )
                            .labelsHidden()
                        }
                    }

                    // 💰 Amount
                    GlassSection {
                        Row(label: "Amount") {
                            TextField(
                                "",
                                value: $price,
                                format: .currency(code: "CAD")
                            )
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        }
                    }

                    // 📦 Extra
                    GlassSection {
                        Row(label: "Category") {
                            Picker("", selection: $category) {
                                Text("Entertainment").tag("Entertainment")
                                Text("Productivity").tag("Productivity")
                            }
                            .pickerStyle(.menu)
                        }

                        Divider()

                        Row(label: "Pay with") {
                            Picker("", selection: $paymentMethod) {
                                Text("None").tag("None")
                                Text("Credit").tag("Credit")
                                Text("Debit").tag("Debit")
                            }
                            .pickerStyle(.menu)
                        }

                        Divider()

                        Row(label: "List") {
                            Text("Personal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 📝 Notes
                    GlassSection {
                        VStack(alignment: .leading, spacing: 8) {  // Aligns children to the left
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                        }

                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }

            // 🔘 Sticky button
            Button {
                saveSubscription()
            } label: {
                Text("Add Subscription")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding()
        }
        .navigationTitle("New Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
        }
    }
}

struct Row<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            content
                .foregroundStyle(.primary)
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
        VStack(spacing: 0) {
            content
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    SubscriptionFormView(
        service: SubscriptionTemplate.init(name: "YouTube", color: .red),
        date: Date(),
        onCreate: { _ in }
    ).environmentObject(AppStore())
}
