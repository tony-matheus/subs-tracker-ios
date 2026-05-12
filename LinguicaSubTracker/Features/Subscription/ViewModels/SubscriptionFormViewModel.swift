import Foundation
import Observation
import SwiftUI
import UIKit

@Observable
@MainActor
final class SubscriptionFormViewModel {
    var name: String
    var price: Double
    var schedule: SubscriptionSchedule
    var startDate: Date
    var endDate: Date?
    var category: String
    var paymentMethod: String
    var notes: String
    var list: String
    var customization: LogoCustomization

    var showDeleteAlert = false
    var showKeypad = false
    var showLogoSheet = false
    var isLogoExpanded = false
    var isNativeKeyboardVisible = false
    var currencyCode: String = ""

    var nameError: String? = nil
    var priceError: String? = nil
    var showErrors: Bool = false

    let mode: SubscriptionFormMode
    let store: AppStore
    let settingsStore: SettingsStore
    let onCommit: (Subscription) -> Void

    private let originalID: UUID?

    init(
        mode: SubscriptionFormMode,
        store: AppStore,
        settingsStore: SettingsStore,
        onCommit: @escaping (Subscription) -> Void
    ) {
        self.mode = mode
        self.store = store
        self.settingsStore = settingsStore
        self.onCommit = onCommit

        switch mode {
        case .create(let template, let date):
            let newID = UUID()
            self.originalID = nil
            self.customization = template.makeCustomization(id: newID)
            self.name = template.name
            self.price = 0.00
            self.schedule = .monthly
            self.startDate = date
            self.endDate = nil
            self.category = "Entertainment"
            self.paymentMethod = "None"
            self.notes = ""
            self.list = "Personal"

        case .createBlank(let initialName, let date):
            let newID = UUID()
            self.originalID = nil
            // Use the unified resolver so a typed name that matches a known
            // template still pre-fills with that template's colors/logo.
            self.customization = LogoCustomization.resolved(
                for: newID,
                name: initialName,
                in: store
            )
            self.name = initialName
            self.price = 0.00
            self.schedule = .monthly
            self.startDate = date
            self.endDate = nil
            self.category = "Entertainment"
            self.paymentMethod = "None"
            self.notes = ""
            self.list = "Personal"

        case .edit(let sub):
            self.originalID = sub.id
            self.customization = sub.logoCustomization(in: store)
            self.name = sub.name
            self.price = sub.price
            self.schedule = sub.schedule
            self.startDate = sub.startDate
            self.endDate = sub.endDate
            self.category = sub.category
            self.paymentMethod = sub.paymentMethod ?? "None"
            self.notes = sub.notes ?? ""
            self.list = sub.list == "Default" ? "Personal" : sub.list
        }
    }

    var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    var themeColor: Color { customization.resolvedBackground }

    /// Primary brand color used for the form's background gradient + accents.
    var themePrimary: Color { customization.primaryColor }

    /// Foreground color (icons, key text) that contrasts against `themePrimary`.
    var themeAccent: Color { themePrimary.contrastingForeground }

    var logoName: String? {
        switch mode {
        case .create(let template, _): return template.logo
        case .createBlank: return nil
        case .edit: return SubscriptionTemplate.logoName(for: name)
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && price > 0
    }

    @discardableResult
    func validate() -> Bool {
        nameError = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Name is required" : nil
        priceError = price <= 0 ? "Amount must be greater than zero" : nil
        showErrors = nameError != nil || priceError != nil
        return !showErrors
    }

    func clearNameErrorIfFixed() {
        if !name.trimmingCharacters(in: .whitespaces).isEmpty { nameError = nil }
    }

    func clearPriceErrorIfFixed() {
        if price > 0 { priceError = nil }
    }

    var navigationTitle: String {
        isEditMode ? "Edit Subscription" : "New Subscription"
    }

    var primaryButtonTitle: String {
        isEditMode ? "Save Changes" : "Add Subscription"
    }

    var deleteAlertMessage: String {
        "\(name) will be permanently removed."
    }

    var categoryOptions: [(value: String, label: String)] {
        settingsStore.settings.categories.map { (value: $0.name, label: $0.name) }
    }

    var paymentOptions: [(value: String, label: String)] {
        [(value: "None", label: "None")] + settingsStore.settings.paymentMethods.map {
            (value: $0.name, label: $0.name)
        }
    }

    var listOptions: [(value: String, label: String)] {
        settingsStore.settings.lists.map { (value: $0.name, label: $0.name) }
    }

    func customizationBinding() -> Binding<LogoCustomization> {
        Binding(
            get: { self.customization },
            set: { self.customization = $0 }
        )
    }

    func onAppear() {
        if currencyCode.isEmpty {
            currencyCode = settingsStore.settings.currencyCode
        }
    }

    func keyboardAppeared() { isNativeKeyboardVisible = true }
    func keyboardDismissed() { isNativeKeyboardVisible = false }

    func openLogoSheet() {
        showLogoSheet = true
        isLogoExpanded = true
    }

    func closeLogoSheet() {
        showLogoSheet = false
        isLogoExpanded = false
    }

    func dismissNativeKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    func commit() -> Subscription? {
        guard validate() else { return nil }

        let resolvedID = originalID ?? customization.id
        // Strip time-of-day so the calendar's start-of-day cell matches the
        // subscription's first billing day. Without this, a sub created at
        // 14:32 today renders only from the same day *next* month.
        let normalizedStart = Calendar.current.startOfDay(for: startDate)

        let normalizedEnd = endDate.map { Calendar.current.startOfDay(for: $0) }

        let subscription = Subscription(
            id: resolvedID,
            name: name,
            price: price,
            schedule: schedule,
            startDate: normalizedStart,
            endDate: normalizedEnd,
            paymentMethod: paymentMethod == "None" ? nil : paymentMethod,
            notes: notes.isEmpty ? nil : notes,
            category: category,
            list: list
        )

        if isEditMode {
            store.update(subscription)
        } else {
            store.add(subscription)
        }

        var saved = customization
        saved.id = resolvedID
        store.setCustomization(saved)

        onCommit(subscription)
        return subscription
    }

    func deleteOriginal() {
        guard let id = originalID else { return }
        store.subscriptions.removeAll { $0.id == id }
        StorageService.save(store.subscriptions)
        store.clearCustomization(id: id)
    }
}
