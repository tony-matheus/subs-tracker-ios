import Testing

@testable import LinguicaSubTracker

private let categories = [
    "Entertainment", "Productivity", "Lifestyle", "Utilities",
    "Finance", "Health", "Gaming", "Other",
]

@Suite("VoiceExpenseParser regex fallback")
struct VoiceExpenseParserTests {

    @Test("digits with preposition")
    func digitsOnMerchant() {
        let items = VoiceExpenseParser.regexParse("50 dollars on Safeway", categories: categories)
        #expect(items.count == 1)
        #expect(items.first?.name == "Safeway")
        #expect(items.first?.amount == 50)
        #expect(items.first?.daysAgo == 0)
    }

    @Test("number words")
    func numberWords() {
        let items = VoiceExpenseParser.regexParse("fifty dollars on Safeway", categories: categories)
        #expect(items.first?.amount == 50)
        #expect(items.first?.name == "Safeway")
    }

    @Test("compound number words")
    func compoundNumberWords() {
        let items = VoiceExpenseParser.regexParse(
            "one hundred twenty five at Costco", categories: categories)
        #expect(items.first?.amount == 125)
        #expect(items.first?.name == "Costco")
    }

    @Test("yesterday date offset")
    func yesterday() {
        let items = VoiceExpenseParser.regexParse(
            "yesterday I spent 20 on groceries", categories: categories)
        #expect(items.first?.amount == 20)
        #expect(items.first?.daysAgo == 1)
        #expect(items.first?.name == "Groceries")
    }

    @Test("multiple expenses in one utterance")
    func multipleSegments() {
        let items = VoiceExpenseParser.regexParse(
            "50 on Safeway and 12.50 at Starbucks", categories: categories)
        #expect(items.count == 2)
        #expect(items.last?.amount == 12.5)
        #expect(items.last?.name == "Starbucks")
    }

    @Test("decimal amount with currency symbol")
    func decimalWithSymbol() {
        let items = VoiceExpenseParser.regexParse("$9.99 for lunch", categories: categories)
        #expect(items.first?.amount == 9.99)
        #expect(items.first?.name == "Lunch")
    }

    @Test("no amount yields nothing")
    func noAmount() {
        #expect(VoiceExpenseParser.regexParse("I went to the store", categories: categories).isEmpty)
    }

    @Test("category snapping")
    func snapping() {
        #expect(VoiceExpenseParser.snapCategory("gaming", to: categories) == "Gaming")
        #expect(VoiceExpenseParser.snapCategory("health insurance", to: categories) == "Health")
        #expect(VoiceExpenseParser.snapCategory("banana", to: categories) == "Other")
        #expect(VoiceExpenseParser.snapCategory(nil, to: categories) == "Other")
    }
}
