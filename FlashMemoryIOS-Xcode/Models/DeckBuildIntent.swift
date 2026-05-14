import Foundation

struct DeckBuildIntent: Hashable {
    var detectedDeckType: DeckType
    var frontLanguage: AppLanguage
    var backLanguage: AppLanguage
    var confidence: Double
    var explanation: String
    var suggestedTitle: String

    init(
        detectedDeckType: DeckType,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage,
        confidence: Double,
        explanation: String,
        suggestedTitle: String
    ) {
        self.detectedDeckType = detectedDeckType
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self.confidence = confidence
        self.explanation = explanation
        self.suggestedTitle = suggestedTitle
    }
}
