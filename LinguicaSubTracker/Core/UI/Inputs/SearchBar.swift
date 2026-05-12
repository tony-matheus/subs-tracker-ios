import SwiftUI

/// Native search field + inline keyboard dictation — same pattern as Apple's
/// Photos app:
/// ```
/// .searchable(text:, isPresented:, prompt:)
/// .searchDictationBehavior(.inline(activation: .onSelect))
/// ```
///
/// - `dismissAlwaysPresent`: when `true`, adds a `SearchDismissButton` as a
///   trailing toolbar item so the user can always dismiss the screen.
/// - `onDismiss`: fires when the native Cancel button or the dismiss button
///   flips `isPresented` to `false`.
extension View {
    func appSearchable(
        text: Binding<String>,
        isPresented: Binding<Bool>,
        prompt: String = "Search",
        onDismiss: (() -> Void)? = nil,
        dismissAlwaysPresent: Bool = false
    ) -> some View {
        self
            .searchable(text: text, isPresented: isPresented, prompt: prompt)
            .searchDictationBehavior(.inline(activation: .onSelect))
            .onChange(of: isPresented.wrappedValue) { wasPresented, isNowPresented in
                if wasPresented && !isNowPresented {
                    onDismiss?()
                }
            }
    }
}
