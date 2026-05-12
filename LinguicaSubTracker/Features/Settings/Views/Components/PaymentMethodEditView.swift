import SwiftUI

struct PaymentMethodEditView: View {
    let methodID: UUID
    @Bindable var vm: PaymentMethodsViewModel
    @State private var name: String = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .typography(.bodyLarge)
                    .submitLabel(.done)
            }
        }
        .navigationTitle("Edit Payment Method")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let m = vm.paymentMethod(for: methodID) {
                name = m.name
            }
        }
        .onChange(of: name) { _, new in
            vm.rename(id: methodID, name: new)
        }
    }
}
