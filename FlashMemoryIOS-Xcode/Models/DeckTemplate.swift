import Foundation

struct DeckTemplate: Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var deckType: DeckType
    var suggestedFrontLanguage: AppLanguage
    var suggestedBackLanguage: AppLanguage
    var suggestedCategory: String?
    var exampleCards: [Flashcard]

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        deckType: DeckType,
        suggestedFrontLanguage: AppLanguage,
        suggestedBackLanguage: AppLanguage,
        suggestedCategory: String? = nil,
        exampleCards: [Flashcard] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.deckType = deckType
        self.suggestedFrontLanguage = suggestedFrontLanguage
        self.suggestedBackLanguage = suggestedBackLanguage
        self.suggestedCategory = suggestedCategory
        self.exampleCards = exampleCards
    }
}
