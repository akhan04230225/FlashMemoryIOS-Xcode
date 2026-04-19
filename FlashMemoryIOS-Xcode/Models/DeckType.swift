import Foundation

enum DeckType: String, Codable, Hashable {
    case standard
    case lineMemorization
    case mixed

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .lineMemorization:
            return "Line Memorization"
        case .mixed:
            return "Mixed"
        }
    }

    var shortDescription: String {
        switch self {
        case .standard:
            return "Question and answer flashcards."
        case .lineMemorization:
            return "Cards for memorizing ordered lines or passages."
        case .mixed:
            return "A deck with both standard and memorization cards."
        }
    }
}
