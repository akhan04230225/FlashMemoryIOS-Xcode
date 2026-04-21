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
        validateCard(
            frontText: frontText,
            frontImageName: nil,
            backText: backText,
            backImageName: nil,
            deckType: deckType
        )
    }

    static func validateCard(
        frontText: String,
        frontImageName: String?,
        backText: String,
        backImageName: String?,
        deckType: DeckType
    ) -> String? {
        let hasFrontText = !frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasFrontImage = !(frontImageName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasBackText = !backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasBackImage = !(backImageName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !hasFrontText && !hasFrontImage {
            return "Add front text or a front image."
        }

        if deckType.requiresBackContent && !hasBackText && !hasBackImage {
            return "Add back text or a back image."
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
    var requiresBackContent: Bool {
        switch self {
        case .standard, .mixed:
            return true
        case .lineMemorization:
            return false
        }
    }
}
