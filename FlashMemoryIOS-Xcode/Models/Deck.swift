import Foundation

struct Deck: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var deckDescription: String
    var category: String?
    var deckType: DeckType
    var frontLanguage: AppLanguage
    var backLanguage: AppLanguage
    var cards: [Flashcard]
    var createdAt: Date
    var updatedAt: Date

    var cardCount: Int {
        cards.count
    }

    init(
        id: UUID = UUID(),
        title: String,
        deckDescription: String,
        category: String? = nil,
        deckType: DeckType = .standard,
        frontLanguage: AppLanguage = .english,
        backLanguage: AppLanguage = .english,
        cards: [Flashcard] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.deckDescription = deckDescription
        self.category = category
        self.deckType = deckType
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self.cards = cards
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static let sampleDecks: [Deck] = [
        Deck(
            title: "Biology Basics",
            deckDescription: "Starter cards for reviewing biology terms.",
            category: "Science",
            deckType: .standard,
            frontLanguage: .english,
            backLanguage: .english,
            cards: [
                Flashcard(
                    frontText: "What is the powerhouse of the cell?",
                    backText: "The mitochondria.",
                    category: "Cells",
                    hintText: "It helps create energy.",
                    notes: "Common introductory biology question.",
                ),
                Flashcard(
                    frontText: "What does DNA store?",
                    backText: "Genetic information.",
                    category: "Genetics",
                )
            ]
        ),
        Deck(
            title: "Arabic Vocabulary",
            deckDescription: "Simple Arabic words with English meanings.",
            category: "Language",
            deckType: .standard,
            frontLanguage: .arabic,
            backLanguage: .english,
            cards: [
                Flashcard(
                    frontText: "سلام",
                    backText: "Peace",
                    frontLanguage: .arabic,
                    backLanguage: .english,
                    transliteration: "salaam",
                    category: "Common Words"
                ),
                Flashcard(
                    frontText: "كتاب",
                    backText: "Book",
                    frontLanguage: .arabic,
                    backLanguage: .english,
                    transliteration: "kitaab",
                    category: "Common Words"
                )
            ]
        ),
        Deck(
            title: "Poem Lines",
            deckDescription: "Practice a short passage one line at a time.",
            category: "Memorization",
            deckType: .lineMemorization,
            frontLanguage: .english,
            backLanguage: .english,
            cards: [
                Flashcard(
                    frontText: "Line 1",
                    backText: "The first line to memorize.",
                    category: "Poetry",
                    hintText: "Start at the beginning.",
                    fillBlankText: "The first line to ____.",
                    sourceReference: "Sample passage",
                    lineOrder: 1,
                    memorizationChunks: ["The first", "line to", "memorize."]
                )
            ]
        )
    ]
}
