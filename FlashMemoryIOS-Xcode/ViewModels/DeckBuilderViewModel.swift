import Combine
import Foundation
import SwiftUI

class DeckBuilderViewModel: ObservableObject {
    @Published var deckDraft: DeckDraft
    @Published var currentCardDraft: FlashcardDraft {
        didSet {
            hasUnsavedCardDraft = currentCardDraft.hasContent
        }
    }
    @Published var validationMessage: String?
    @Published var hasUnsavedCardDraft: Bool
    @Published private(set) var editingDeckId: UUID?

    private var editingDeckCreatedAt: Date?

    var isEditingExistingDeck: Bool {
        editingDeckId != nil
    }

    init(
        deckDraft: DeckDraft = DeckDraft(),
        currentCardDraft: FlashcardDraft = FlashcardDraft(),
        validationMessage: String? = nil,
        hasUnsavedCardDraft: Bool? = nil,
        editingDeckId: UUID? = nil
    ) {
        self.deckDraft = deckDraft
        self.currentCardDraft = currentCardDraft
        self.validationMessage = validationMessage
        self.hasUnsavedCardDraft = hasUnsavedCardDraft ?? currentCardDraft.hasContent
        self.editingDeckId = editingDeckId
        self.editingDeckCreatedAt = nil
    }

    func resetForNewDeck(deckType: DeckType) {
        deckDraft = DeckDraft(deckType: deckType)
        editingDeckId = nil
        editingDeckCreatedAt = nil
        validationMessage = nil
        resetCurrentCardDraft()
    }

    func updateDeckType(_ type: DeckType) {
        deckDraft.deckType = type

        if type == .lineMemorization {
            updateLineOrderForCards()
        }

        validationMessage = nil
    }

    func addCurrentCard() {
        if let cardError = validateCurrentCardDraft() {
            validationMessage = cardError
            return
        }

        var card = currentCardDraft.toFlashcard()

        if deckDraft.deckType == .lineMemorization {
            card.lineOrder = card.lineOrder ?? deckDraft.cards.count + 1
            insertLineMemorizationCard(card)
            updateLineOrderForCards()
        } else {
            deckDraft.cards.append(card)
        }

        validationMessage = nil
        resetCurrentCardDraft()
    }

    func removeCard(at offsets: IndexSet) {
        deckDraft.cards.remove(atOffsets: offsets)
        updateLineOrderForCards()
    }

    func deleteCard(id: UUID) {
        deckDraft.cards.removeAll { $0.id == id }
        updateLineOrderForCards()
    }

    func moveCard(from source: IndexSet, to destination: Int) {
        deckDraft.cards.move(fromOffsets: source, toOffset: destination)
        updateLineOrderForCards()
    }

    func resetCurrentCardDraft() {
        currentCardDraft = FlashcardDraft(
            frontLanguage: deckDraft.frontLanguage,
            backLanguage: deckDraft.backLanguage
        )
        hasUnsavedCardDraft = false
    }

    func loadDeckForEditing(_ deck: Deck) {
        deckDraft = DeckDraft(
            title: deck.title,
            deckDescription: deck.deckDescription,
            category: deck.category ?? "",
            deckType: deck.deckType,
            frontLanguage: deck.frontLanguage,
            backLanguage: deck.backLanguage,
            cards: cardsForEditing(deck.cards, deckType: deck.deckType)
        )

        editingDeckId = deck.id
        editingDeckCreatedAt = deck.createdAt
        validationMessage = nil
        resetCurrentCardDraft()
        updateLineOrderForCards()
    }

    func buildDeck() -> Deck? {
        buildDeck(id: editingDeckId)
    }

    func buildDeck(id: UUID?) -> Deck? {
        if let saveError = DeckValidationService.validateDeckCanSave(
            title: deckDraft.title,
            cardCount: deckDraft.cards.count
        ) {
            validationMessage = saveError
            return nil
        }

        validationMessage = nil

        return Deck(
            id: id ?? UUID(),
            title: deckDraft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            deckDescription: deckDraft.deckDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: deckDraft.category.nilIfBlank,
            deckType: deckDraft.deckType,
            frontLanguage: deckDraft.frontLanguage,
            backLanguage: deckDraft.backLanguage,
            cards: orderedCardsForSaving(),
            createdAt: createdAtForBuiltDeck(id: id),
            updatedAt: Date()
        )
    }

    func canSaveDeck() -> Bool {
        DeckValidationService.validateDeckCanSave(
            title: deckDraft.title,
            cardCount: deckDraft.cards.count
        ) == nil
    }

    @discardableResult
    func saveDeck(using store: DeckStore) -> Bool {
        guard canSaveDeck() else {
            validationMessage = DeckValidationService.validateDeckCanSave(
                title: deckDraft.title,
                cardCount: deckDraft.cards.count
            )
            return false
        }

        store.addDeck(from: deckDraftForSaving())
        validationMessage = nil
        editingDeckId = nil
        return true
    }

    @discardableResult
    func updateExistingDeck(using store: DeckStore, originalDeckId: UUID) -> Bool {
        guard canSaveDeck() else {
            validationMessage = DeckValidationService.validateDeckCanSave(
                title: deckDraft.title,
                cardCount: deckDraft.cards.count
            )
            return false
        }

        let originalDeck = store.deck(with: originalDeckId)

        let updatedDeck = Deck(
            id: originalDeckId,
            title: deckDraft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            deckDescription: deckDraft.deckDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: deckDraft.category.nilIfBlank,
            deckType: deckDraft.deckType,
            frontLanguage: deckDraft.frontLanguage,
            backLanguage: deckDraft.backLanguage,
            cards: orderedCardsForSaving(),
            createdAt: originalDeck?.createdAt ?? Date(),
            updatedAt: Date()
        )

        store.updateDeck(updatedDeck)
        validationMessage = nil
        editingDeckId = originalDeckId
        return true
    }

    @discardableResult
    func saveOrUpdateDeck(using store: DeckStore) -> Bool {
        if let editingDeckId {
            return updateExistingDeck(using: store, originalDeckId: editingDeckId)
        }

        return saveDeck(using: store)
    }

    private func validateCurrentCardDraft() -> String? {
        let frontText = currentCardDraft.frontText.trimmingCharacters(in: .whitespacesAndNewlines)
        let backText = currentCardDraft.backText.trimmingCharacters(in: .whitespacesAndNewlines)

        return DeckValidationService.validateCard(
            frontText: frontText,
            backText: backText,
            deckType: deckDraft.deckType
        )
    }

    private func insertLineMemorizationCard(_ card: Flashcard) {
        guard let lineOrder = card.lineOrder else {
            deckDraft.cards.append(card)
            return
        }

        let insertIndex = max(0, min(lineOrder - 1, deckDraft.cards.count))
        deckDraft.cards.insert(card, at: insertIndex)
    }

    private func updateLineOrderForCards() {
        guard deckDraft.deckType == .lineMemorization else {
            return
        }

        for cardIndex in deckDraft.cards.indices {
            deckDraft.cards[cardIndex].lineOrder = cardIndex + 1
        }
    }

    private func orderedCardsForSaving() -> [Flashcard] {
        if deckDraft.deckType == .lineMemorization {
            return deckDraft.cards.enumerated().map { index, card in
                var updatedCard = card
                updatedCard.lineOrder = index + 1
                return updatedCard
            }
        }

        return deckDraft.cards
    }

    private func deckDraftForSaving() -> DeckDraft {
        DeckDraft(
            title: deckDraft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            deckDescription: deckDraft.deckDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: deckDraft.category.trimmingCharacters(in: .whitespacesAndNewlines),
            deckType: deckDraft.deckType,
            frontLanguage: deckDraft.frontLanguage,
            backLanguage: deckDraft.backLanguage,
            cards: orderedCardsForSaving()
        )
    }

    private func cardsForEditing(_ cards: [Flashcard], deckType: DeckType) -> [Flashcard] {
        guard deckType == .lineMemorization else {
            return cards
        }

        return cards.sorted { firstCard, secondCard in
            let firstOrder = firstCard.lineOrder ?? Int.max
            let secondOrder = secondCard.lineOrder ?? Int.max
            return firstOrder < secondOrder
        }
    }

    private func createdAtForBuiltDeck(id: UUID?) -> Date {
        if id == editingDeckId, let editingDeckCreatedAt {
            return editingDeckCreatedAt
        }

        return Date()
    }
}

private extension FlashcardDraft {
    var hasContent: Bool {
        [
            frontText,
            backText,
            transliteration,
            category,
            hintText,
            fillBlankText,
            notes,
            imageName,
            matchPrompt,
            matchAnswer,
            sourceReference,
            lineOrder,
            memorizationChunksText
        ].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmedText = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}
