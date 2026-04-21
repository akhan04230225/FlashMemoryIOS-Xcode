import Combine
import Foundation

@MainActor
class DeckStore: ObservableObject {
    @Published var decks: [Deck]

    init(decks: [Deck]? = nil) {
        self.decks = decks ?? Deck.sampleDecks
    }

    @discardableResult
    func addDeck(from draft: DeckDraft) -> Deck {
        let newDeck = draft.toDeck()

        decks.append(newDeck)
        return newDeck
    }

    @discardableResult
    func addDeck(_ deck: Deck) -> Deck {
        var newDeck = deck
        newDeck.updatedAt = Date()
        decks.append(newDeck)
        return newDeck
    }

    @discardableResult
    func updateDeck(_ deck: Deck) -> Bool {
        guard let deckIndex = indexForDeck(id: deck.id) else {
            return false
        }

        var updatedDeck = deck
        updatedDeck.updatedAt = Date()
        decks[deckIndex] = updatedDeck
        return true
    }

    @discardableResult
    func deleteDeck(id: UUID) -> Bool {
        guard let deckIndex = indexForDeck(id: id) else {
            return false
        }

        decks.remove(at: deckIndex)
        return true
    }

    @discardableResult
    func duplicateDeck(id: UUID) -> Deck? {
        guard let originalDeck = deck(with: id) else {
            return nil
        }

        let duplicatedDeck = Deck(
            title: "\(originalDeck.title) Copy",
            deckDescription: originalDeck.deckDescription,
            category: originalDeck.category,
            deckType: originalDeck.deckType,
            frontLanguage: originalDeck.frontLanguage,
            backLanguage: originalDeck.backLanguage,
            cards: duplicateCards(originalDeck.cards)
        )

        decks.append(duplicatedDeck)
        return duplicatedDeck
    }

    func deck(with id: UUID) -> Deck? {
        decks.first { $0.id == id }
    }

    @discardableResult
    func replaceDeckCards(deckId: UUID, cards: [Flashcard]) -> Bool {
        guard let deckIndex = indexForDeck(id: deckId) else {
            return false
        }

        decks[deckIndex].cards = cards
        decks[deckIndex].updatedAt = Date()
        return true
    }

    @discardableResult
    func addCard(to deckId: UUID, card: Flashcard) -> Bool {
        guard let deckIndex = indexForDeck(id: deckId) else {
            return false
        }

        decks[deckIndex].cards.append(card)
        decks[deckIndex].updatedAt = Date()
        return true
    }

    @discardableResult
    func updateCard(in deckId: UUID, card: Flashcard) -> Bool {
        guard let deckIndex = indexForDeck(id: deckId) else {
            return false
        }

        guard let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == card.id }) else {
            return false
        }

        decks[deckIndex].cards[cardIndex] = card
        decks[deckIndex].updatedAt = Date()
        return true
    }

    @discardableResult
    func deleteCard(from deckId: UUID, cardId: UUID) -> Bool {
        guard let deckIndex = indexForDeck(id: deckId) else {
            return false
        }

        guard let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == cardId }) else {
            return false
        }

        decks[deckIndex].cards.remove(at: cardIndex)
        decks[deckIndex].updatedAt = Date()
        return true
    }

    private func indexForDeck(id: UUID) -> Int? {
        decks.firstIndex { $0.id == id }
    }

    private func duplicateCards(_ cards: [Flashcard]) -> [Flashcard] {
        cards.map { card in
            Flashcard(
                frontText: card.frontText,
                backText: card.backText,
                frontLanguage: card.frontLanguage,
                backLanguage: card.backLanguage,
                transliteration: card.transliteration,
                category: card.category,
                hintText: card.hintText,
                fillBlankText: card.fillBlankText,
                notes: card.notes,
                imageName: card.imageName,
                frontImageName: card.frontImageName,
                backImageName: card.backImageName,
                matchPrompt: card.matchPrompt,
                matchAnswer: card.matchAnswer,
                sourceReference: card.sourceReference,
                lineOrder: card.lineOrder,
                memorizationChunks: card.memorizationChunks
            )
        }
    }
}
