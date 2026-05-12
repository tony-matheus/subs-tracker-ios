
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(PrimaryButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
//            .background(Color.blue)
//            .foregroundColor(.white)
//            .cornerRadius(10)
            .glassEffect(.regular.interactive(), in: Capsule())
    }
}

#Preview {
    PrimaryButton(title:"Primary Button", action: {})
}
