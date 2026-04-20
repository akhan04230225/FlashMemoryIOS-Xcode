import Foundation

struct DeckValidationService {
    static func validateDeckBasicInfo(title: String) -> String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Deck title is required."
        }

        return nil
    }

    static func validateCard(frontText: String, backText: String) -> String? {
        validateCard(frontText: frontText, backText: backText, deckType: .standard)
    }

    static func validateCard(frontText: String, backText: String, deckType: DeckType) -> String? {
        if frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Card front text is required."
        }

        if deckType.requiresBackText && backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Card back text is required."
        }

        return nil
    }

    static func validateDeckCanSave(title: String, cardCount: Int) -> String? {
        if let basicInfoError = validateDeckBasicInfo(title: title) {
            return basicInfoError
        }

        if cardCount < 2 {
            return "Add at least 2 cards before saving the deck."
        }

        return nil
    }
}

private extension DeckType {
    var requiresBackText: Bool {
        switch self {
        case .standard, .mixed:
            return true
        case .lineMemorization:
            return false
        }
    }
}
