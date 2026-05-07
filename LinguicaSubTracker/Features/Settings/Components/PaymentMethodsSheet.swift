import SwiftUI

struct PaymentMethodsSheet: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(settingsStore.settings.paymentMethods) { method in
                        Text(method.name)
                            .typography(.bodyLarge)
                            .foregroundStyle(.primary)
                            .padding(.vertical, 2)
                            .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        settingsStore.deletePaymentMethods(at: offsets)
                    }
                }
                .listStyle(.automatic)
                addBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .iconStyle(size: 13, weight: .semibold, color: .secondary)
                            .frame(width: 32, height: 32)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .typography(.bodyMedium)
                }
            }
            
        }
    }

    private var addBar: some View {
        HStack(spacing: 12) {
            TextField("New Payment Method", text: $newName)
                .typography(.bodyLarge)
                .submitLabel(.done)
                .onSubmit { commitAdd() }

            Button("Add") { commitAdd() }
                .typography(.titleSmall)
                .foregroundStyle(newName.isEmpty ? .secondary : .primary)
                .disabled(newName.isEmpty)
        }
        .frame(height: 44)
    }

    private func commitAdd() {
        settingsStore.addPaymentMethod(newName)
        newName = ""
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaymentMethodsSheet()
                .environmentObject(SettingsStore())
        }
}
