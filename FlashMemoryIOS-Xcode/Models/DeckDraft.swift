import Foundation

struct DeckDraft: Hashable {
    var title: String
    var deckDescription: String
    var category: String?
    var deckType: DeckType
    var frontLanguage: AppLanguage
    var backLanguage: AppLanguage
    var cards: [FlashcardDraft]

    init(
        title: String = "",
        deckDescription: String = "",
        category: String? = nil,
        deckType: DeckType = .standard,
        frontLanguage: AppLanguage = .english,
        backLanguage: AppLanguage = .english,
        cards: [FlashcardDraft] = []
    ) {
        self.title = title
        self.deckDescription = deckDescription
        self.category = category
        self.deckType = deckType
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self.cards = cards
    }

    init(deck: Deck) {
        self.init(
            title: deck.title,
            deckDescription: deck.deckDescription,
            category: deck.category,
            deckType: deck.deckType,
            frontLanguage: deck.frontLanguage,
            backLanguage: deck.backLanguage,
            cards: deck.cards.map(FlashcardDraft.init(flashcard:))
        )
    }

    init(
        title: String = "",
        deckDescription: String = "",
        category: String? = nil,
        deckType: DeckType = .standard,
        frontLanguage: AppLanguage = .english,
        backLanguage: AppLanguage = .english,
        cards: [Flashcard]
    ) {
        self.init(
            title: title,
            deckDescription: deckDescription,
            category: category,
            deckType: deckType,
            frontLanguage: frontLanguage,
            backLanguage: backLanguage,
            cards: cards.map(FlashcardDraft.init(flashcard:))
        )
    }

    var cardCount: Int {
        cards.count
    }

    var isValidBasicInfo: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canBeSaved: Bool {
        isValidBasicInfo && cards.count >= 2
    }

    func toDeck(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Deck {
        Deck(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            deckDescription: deckDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category?.nilIfBlank,
            deckType: deckType,
            frontLanguage: frontLanguage,
            backLanguage: backLanguage,
            cards: cards.map { $0.toFlashcard() },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmedText = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}
