import Foundation

struct FlashcardDraft: Identifiable, Hashable {
    let id: UUID
    var frontText: String
    var backText: String
    var frontLanguage: AppLanguage
    var backLanguage: AppLanguage
    var transliteration: String?
    var category: String?
    var hintText: String?
    var fillBlankText: String?
    var notes: String?
    var imageName: String?
    var frontImageName: String?
    var backImageName: String?
    var matchPrompt: String?
    var matchAnswer: String?
    var sourceReference: String?
    var lineOrder: Int?
    var memorizationChunks: [String]

    nonisolated init(
        id: UUID = UUID(),
        frontText: String = "",
        backText: String = "",
        frontLanguage: AppLanguage = .english,
        backLanguage: AppLanguage = .english,
        transliteration: String? = nil,
        category: String? = nil,
        hintText: String? = nil,
        fillBlankText: String? = nil,
        notes: String? = nil,
        imageName: String? = nil,
        frontImageName: String? = nil,
        backImageName: String? = nil,
        matchPrompt: String? = nil,
        matchAnswer: String? = nil,
        sourceReference: String? = nil,
        lineOrder: Int? = nil,
        memorizationChunks: [String] = []
    ) {
        self.id = id
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
        self.frontImageName = frontImageName
        self.backImageName = backImageName
        self.matchPrompt = matchPrompt
        self.matchAnswer = matchAnswer
        self.sourceReference = sourceReference
        self.lineOrder = lineOrder
        self.memorizationChunks = memorizationChunks
    }

    nonisolated init(flashcard: Flashcard) {
        self.init(
            id: flashcard.id,
            frontText: flashcard.frontText,
            backText: flashcard.backText,
            frontLanguage: flashcard.frontLanguage,
            backLanguage: flashcard.backLanguage,
            transliteration: flashcard.transliteration,
            category: flashcard.category,
            hintText: flashcard.hintText,
            fillBlankText: flashcard.fillBlankText,
            notes: flashcard.notes,
            imageName: flashcard.imageName,
            frontImageName: flashcard.frontImageName,
            backImageName: flashcard.backImageName,
            matchPrompt: flashcard.matchPrompt,
            matchAnswer: flashcard.matchAnswer,
            sourceReference: flashcard.sourceReference,
            lineOrder: flashcard.lineOrder,
            memorizationChunks: flashcard.memorizationChunks
        )
    }

    var hasContent: Bool {
        [
            frontText,
            backText,
            transliteration ?? "",
            category ?? "",
            hintText ?? "",
            fillBlankText ?? "",
            notes ?? "",
            imageName ?? "",
            frontImageName ?? "",
            backImageName ?? "",
            matchPrompt ?? "",
            matchAnswer ?? "",
            sourceReference ?? "",
            lineOrder.map(String.init) ?? "",
            memorizationChunks.joined(separator: "\n")
        ].contains { !$0.trimmed.isEmpty }
    }

    func toFlashcard() -> Flashcard {
        Flashcard(
            id: id,
            frontText: frontText.trimmed,
            backText: backText.trimmed,
            frontLanguage: frontLanguage,
            backLanguage: backLanguage,
            transliteration: transliteration?.nilIfBlank,
            category: category?.nilIfBlank,
            hintText: hintText?.nilIfBlank,
            fillBlankText: fillBlankText?.nilIfBlank,
            notes: notes?.nilIfBlank,
            imageName: imageName?.nilIfBlank,
            frontImageName: frontImageName?.nilIfBlank,
            backImageName: backImageName?.nilIfBlank,
            matchPrompt: matchPrompt?.nilIfBlank,
            matchAnswer: matchAnswer?.nilIfBlank,
            sourceReference: sourceReference?.nilIfBlank,
            lineOrder: lineOrder,
            memorizationChunks: memorizationChunks
                .map { $0.trimmed }
                .filter { !$0.isEmpty }
        )
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
