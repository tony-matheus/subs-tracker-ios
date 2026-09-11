import Testing

@testable import LinguicaSubTracker

private let categories = [
    "Entertainment", "Productivity", "Lifestyle", "Utilities",
    "Finance", "Health", "Gaming", "Other",
]

@Suite("ApplePayCategorizer")
struct ApplePayCategorizerTests {

    @Test("specific food delivery beats generic ride keyword")
    func uberEatsVsUber() {
        #expect(category("UBER EATS") == "Lifestyle")
        #expect(category("Uber Trip") == "Utilities")
        #expect(category("UBER   *TRIP") == "Utilities")
    }

    @Test("iFood card descriptor")
    func ifoodDescriptor() {
        #expect(category("IFD*RESTAURANTE XYZ") == "Lifestyle")
        #expect(category("iFood") == "Lifestyle")
    }

    @Test("accent-insensitive grocery match")
    func accentedMerchant() {
        #expect(category("Pão de Açúcar") == "Lifestyle")
    }

    @Test("pharmacy and streaming")
    func commonMerchants() {
        #expect(category("Drogasil Farmácia") == "Health")
        #expect(category("Netflix Subscription") == "Entertainment")
        #expect(category("Apple App Store") == "Productivity")
    }

    @Test("short tokens do not steal longer merchants")
    func shortTokenCollisions() {
        #expect(category("HBO Max") == "Entertainment")
        #expect(category("Intimissimi") == "Other")
        #expect(category("Taxi 99") == "Utilities")
    }

    @Test("north american merchants")
    func northAmericanMerchants() {
        #expect(category("DOORDASH*CHIPOTLE") == "Lifestyle")
        #expect(category("Tim Hortons") == "Lifestyle")
        #expect(category("Costco Wholesale") == "Lifestyle")
        #expect(category("LYFT   *RIDE") == "Utilities")
        #expect(category("CVS Pharmacy") == "Health")
        #expect(category("Shoppers Drug Mart") == "Health")
        #expect(category("Hulu") == "Entertainment")
        #expect(category("Taco Bell") == "Lifestyle")
        #expect(category("Bell Canada") == "Utilities")
    }

    @Test("unknown merchant falls back to Other")
    func unknownMerchant() {
        #expect(category("Obscure Local Shop") == "Other")
    }

    private func category(_ merchant: String) -> String {
        ApplePayCategorizer.categorize(merchant: merchant, availableCategories: categories)
    }
}
