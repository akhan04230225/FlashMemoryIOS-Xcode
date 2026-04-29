import Foundation

struct BulkCardParseResult {
    let parsedCards: [Flashcard]
    let skippedLines: [String]
    let errorMessage: String?
}
