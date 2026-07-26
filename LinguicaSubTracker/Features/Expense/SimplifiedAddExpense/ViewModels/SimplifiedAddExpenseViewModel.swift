import Foundation
import Observation
import SwiftUI

/// Drives the one-screen add-expense flow. Composes `ExpenseFormViewModel`
/// rather than duplicating it, so validation, persistence, start-of-day
/// normalization and the settings-derived picker options all come from the
/// existing form model. This type only adds what the simplified flow needs:
/// the popular-services catalog, the template lock and the reset behaviour.
@Observable
@MainActor
final class SimplifiedAddExpenseViewModel {
    let form: ExpenseFormViewModel

    /// Template the form was filled from, if any. Drives the logo lock and
    /// the brand logo asset lookup.
    private(set) var selectedTemplate: SubscriptionTemplate? = nil

    var showCatalog = false
    var searchText = ""

    private let templates: [SubscriptionTemplate]

    init(
        mode: ExpenseFormMode,
        store: AppStore,
        settingsStore: SettingsStore,
        templates: [SubscriptionTemplate] = SubscriptionTemplate.mock,
        onCommit: @escaping (Expense) -> Void
    ) {
        self.templates = templates
        self.form = ExpenseFormViewModel(
            mode: mode,
            store: store,
            settingsStore: settingsStore,
            onCommit: onCommit
        )
    }

    /// Editing an existing expense reuses the whole screen minus the
    /// popular-services fill — the look is already established.
    var isEditMode: Bool { form.isEditMode }

    // MARK: - Logo

    /// A brand logo is fixed for as long as its template is applied — clearing
    /// the template (the row's ✕) is what makes the logo editable again.
    var isLogoLocked: Bool { selectedTemplate != nil }

    /// `nil` outside of template mode — `LogoCircle` then falls back to the
    /// symbol/initials rendering from the customization.
    var logoName: String? {
        selectedTemplate?.logo ?? SubscriptionTemplate.logoName(for: form.name)
    }

    func openLogoSheet() {
        guard !isLogoLocked else { return }
        form.showLogoSheet = true
    }

    // MARK: - Theme

    /// Contrast is measured against the darkened background actually drawn,
    /// not the raw brand color.
    var accent: Color { backgroundBase.contrastingForeground }

    /// The brand color stays recognizable but is darkened so white text and
    /// the card material read against it.
    var backgroundBase: Color { form.themePrimary.mix(with: .black, by: 0.35) }

    var backgroundShade: Color { form.themePrimary.mix(with: .black, by: 0.7) }

    // MARK: - Catalog

    var filteredTemplates: [SubscriptionTemplate] {
        templates.smartSearch(query: searchText, by: \.name)
    }

    var showEmptyCTA: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
            && filteredTemplates.isEmpty
    }

    func apply(_ template: SubscriptionTemplate) {
        selectedTemplate = template
        form.customization = template.makeCustomization(id: form.customization.id)
        form.name = template.name
        form.type = .subscription
        form.clearNameErrorIfFixed()
        showCatalog = false
    }

    /// Empty-state CTA: keep the typed name, drop back to a blank custom logo.
    func applyBlank(named name: String) {
        form.name = name
        clearTemplate()
        form.clearNameErrorIfFixed()
        showCatalog = false
    }

    /// Explicit clear (the row's ✕): drop the template *and* its look, so the
    /// logo goes back to the generic one for whatever name is typed.
    func clearTemplate() {
        selectedTemplate = nil
        form.customization = LogoCustomization.resolved(
            for: form.customization.id,
            name: form.name,
            in: form.store
        )
    }

    /// Typing over a template's name only detaches it — the brand colors stay
    /// so renaming "Netflix" to "Netflix Family" doesn't wipe the look.
    func detachTemplate() {
        selectedTemplate = nil
    }

    // MARK: - Commit

    func add() -> Bool {
        form.commit() != nil
    }

    /// "Create and add another" — persists, then resets the form *and* the
    /// template lock for the next entry without closing the sheet.
    func addAnother() -> Bool {
        guard form.commitStayingOpen() else { return false }
        // `commitStayingOpen` already reset the form's customization.
        selectedTemplate = nil
        searchText = ""
        return true
    }
}
