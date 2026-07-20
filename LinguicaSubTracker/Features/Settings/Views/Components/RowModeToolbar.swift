import SwiftUI

/// Shared navigation toolbar for the settings management sheets
/// (Categories / Lists / Payment Methods).
///
/// It is UI-agnostic: it renders the leading dismiss button and the
/// mode-dependent trailing actions, delegating all behavior to the supplied
/// closures. Each action is wrapped in `withAnimation` so mode changes animate
/// consistently across sheets.
struct RowModeToolbar: ToolbarContent {
    let mode: RowMode
    /// Whether any rows are selected — drives the delete button's enabled state.
    var hasSelection: Bool

    var onDismiss: () -> Void
    var onEnterEdit: () -> Void
    var onEnterSelect: () -> Void
    var onDeleteSelected: () -> Void
    var onDone: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
        }

        switch mode {
        case .viewing:
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation { onEnterEdit() }
                } label: {
                    Image(systemName: "pencil")
                }
                .tint(.green)

                Button {
                    withAnimation { onEnterSelect() }
                } label: {
                    Image(systemName: "checkmark.circle")
                }
                .tint(.appAccent)
            }

        case .editing:
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { onDone() }
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .tint(.green)
            }

        case .selecting:
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    withAnimation { onDeleteSelected() }
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
                .disabled(!hasSelection)

                Button("Done") {
                    withAnimation { onDone() }
                }
            }
        }
    }
}
