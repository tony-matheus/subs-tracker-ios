import Foundation
import Observation

@Observable
@MainActor
final class ExpenseTemplateSheetViewModel {
    var selectedService: SubscriptionTemplate? = nil
    var searchText: String = ""
    var blankRoute: BlankRoute? = nil

    let date: Date
    let services: [SubscriptionTemplate] = SubscriptionTemplate.mock

    init(date: Date) {
        self.date = date
    }

    var filteredServices: [SubscriptionTemplate] {
        services.smartSearch(query: searchText, by: \.name)
    }

    var showEmptyCTA: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
            && filteredServices.isEmpty
    }

    func selectTemplate(_ template: SubscriptionTemplate) {
        selectedService = template
    }

    func createBlank() {
        blankRoute = BlankRoute(name: "")
    }

    func createBlankWithSearch() {
        blankRoute = BlankRoute(name: searchText)
    }
}
