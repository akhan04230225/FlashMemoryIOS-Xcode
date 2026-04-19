import Foundation

struct DeckDraft {
    var title: String
    var deckDescription: String
    var category: String
    var deckType: DeckType
    var frontLanguage: AppLanguage
    var backLanguage: AppLanguage
    var cards: [Flashcard]

    init(
        title: String = "",
        deckDescription: String = "",
        category: String = "",
        deckType: DeckType = .standard,
        frontLanguage: AppLanguage = .english,
        backLanguage: AppLanguage = .english,
        cards: [Flashcard] = []
    ) {
        self.title = title
        self.deckDescription = deckDescription
        self.category = category
        self.deckType = deckType
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self.cards = cards
    }

    var isValidBasicInfo: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canBeSaved: Bool {
        isValidBasicInfo && cards.count >= 2
    }
}
