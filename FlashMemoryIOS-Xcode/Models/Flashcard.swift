import Foundation

struct Flashcard: Identifiable, Codable, Hashable {
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

    init(
        id: UUID = UUID(),
        frontText: String,
        backText: String,
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
}
