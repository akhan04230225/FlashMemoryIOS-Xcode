import Combine
import Foundation

class DeckStore: ObservableObject {
    @Published var decks: [Deck]

    init(decks: [Deck] = Deck.sampleDecks) {
        self.decks = decks
    }

    func addDeck(from draft: DeckDraft) {
        let newDeck = Deck(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            deckDescription: draft.deckDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category.nilIfBlank,
            deckType: draft.deckType,
            frontLanguage: draft.frontLanguage,
            backLanguage: draft.backLanguage,
            cards: draft.cards
        )

        decks.append(newDeck)
    }

    func updateDeck(_ deck: Deck) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deck.id }) else {
            return
        }

        var updatedDeck = deck
        updatedDeck.updatedAt = Date()
        decks[deckIndex] = updatedDeck
    }

    func deleteDeck(id: UUID) {
        decks.removeAll { $0.id == id }
    }

    func deck(with id: UUID) -> Deck? {
        decks.first { $0.id == id }
    }

    func replaceDeckCards(deckId: UUID, cards: [Flashcard]) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }) else {
            return
        }

        decks[deckIndex].cards = cards
        decks[deckIndex].updatedAt = Date()
    }

    func addCard(to deckId: UUID, card: Flashcard) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }) else {
            return
        }

        decks[deckIndex].cards.append(card)
        decks[deckIndex].updatedAt = Date()
    }

    func updateCard(in deckId: UUID, card: Flashcard) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }) else {
            return
        }

        guard let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == card.id }) else {
            return
        }

        decks[deckIndex].cards[cardIndex] = card
        decks[deckIndex].updatedAt = Date()
    }

    func deleteCard(from deckId: UUID, cardId: UUID) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }) else {
            return
        }

        decks[deckIndex].cards.removeAll { $0.id == cardId }
        decks[deckIndex].updatedAt = Date()
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmedText = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}
