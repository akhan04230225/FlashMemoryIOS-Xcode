import Foundation

struct FlashcardDraft {
    var frontText: String
    var backText: String
    var frontLanguage: AppLanguage
    var backLanguage: AppLanguage
    var transliteration: String
    var category: String
    var hintText: String
    var fillBlankText: String
    var notes: String
    var imageName: String
    var matchPrompt: String
    var matchAnswer: String
    var sourceReference: String
    var lineOrder: String
    var memorizationChunksText: String

    init(
        frontText: String = "",
        backText: String = "",
        frontLanguage: AppLanguage = .english,
        backLanguage: AppLanguage = .english,
        transliteration: String = "",
        category: String = "",
        hintText: String = "",
        fillBlankText: String = "",
        notes: String = "",
        imageName: String = "",
        matchPrompt: String = "",
        matchAnswer: String = "",
        sourceReference: String = "",
        lineOrder: String = "",
        memorizationChunksText: String = ""
    ) {
        self.frontText = frontText
        self.backText = backText
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self.transliteration = transliteration
        self.category = category
        self.hintText = hintText
        self.fillBlankText = fillBlankText
        self.notes = notes
        self.imageName = imageName
        self.matchPrompt = matchPrompt
        self.matchAnswer = matchAnswer
        self.sourceReference = sourceReference
        self.lineOrder = lineOrder
        self.memorizationChunksText = memorizationChunksText
    }

    func toFlashcard() -> Flashcard {
        Flashcard(
            frontText: frontText.trimmed,
            backText: backText.trimmed,
            frontLanguage: frontLanguage,
            backLanguage: backLanguage,
            transliteration: transliteration.nilIfBlank,
            category: category.nilIfBlank,
            hintText: hintText.nilIfBlank,
            fillBlankText: fillBlankText.nilIfBlank,
            notes: notes.nilIfBlank,
            imageName: imageName.nilIfBlank,
            matchPrompt: matchPrompt.nilIfBlank,
            matchAnswer: matchAnswer.nilIfBlank,
            sourceReference: sourceReference.nilIfBlank,
            lineOrder: Int(lineOrder.trimmed),
            memorizationChunks: memorizationChunks
        )
    }

    private var memorizationChunks: [String] {
        memorizationChunksText
            .components(separatedBy: .newlines)
            .map { $0.trimmed }
            .filter { !$0.isEmpty }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfBlank: String? {
        let trimmedText = trimmed
        return trimmedText.isEmpty ? nil : trimmedText
    }
}
