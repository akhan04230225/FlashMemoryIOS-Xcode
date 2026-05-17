import Foundation

struct DeckChatAssistantService {
    static func generateDeckDraft(
        from userText: String
    ) -> (draft: DeckDraft, intent: DeckBuildIntent, skippedLines: [String]) {
        let detectedDeckType = DeckTypeDetectionService.detectDeckType(from: userText)
        let languages = detectLanguages(from: userText, deckType: detectedDeckType)
        let parseResult = parseCards(
            from: userText,
            deckType: detectedDeckType,
            frontLanguage: languages.front,
            backLanguage: languages.back
        )
        let suggestedTitle = suggestedTitle(from: userText)

        let draft = DeckDraft(
            title: suggestedTitle,
            deckDescription: "Created from chat builder input.",
            deckType: detectedDeckType,
            frontLanguage: languages.front,
            backLanguage: languages.back,
            cards: parseResult.parsedCards
        )

        let intent = DeckBuildIntent(
            detectedDeckType: detectedDeckType,
            frontLanguage: languages.front,
            backLanguage: languages.back,
            confidence: DeckTypeDetectionService.confidence(
                for: userText,
                detectedType: detectedDeckType
            ),
            explanation: DeckTypeDetectionService.explanation(for: detectedDeckType),
            suggestedTitle: suggestedTitle
        )

        return (
            draft: draft,
            intent: intent,
            skippedLines: parseResult.skippedLines
        )
    }

    private static func parseCards(
        from text: String,
        deckType: DeckType,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage
    ) -> BulkCardParseResult {
        switch deckType {
        case .standard:
            return BulkCardParserService.parseStandardCards(
                from: text,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            )

        case .lineMemorization:
            return BulkCardParserService.parseLineMemorizationCards(
                from: text,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            )

        case .mixed:
            let standardResult = BulkCardParserService.parseStandardCards(
                from: text,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            )

            if !standardResult.parsedCards.isEmpty {
                return standardResult
            }

            return BulkCardParserService.parseLineMemorizationCards(
                from: text,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            )
        }
    }

    private static func detectLanguages(
        from text: String,
        deckType: DeckType
    ) -> (front: AppLanguage, back: AppLanguage) {
        if deckType == .standard || deckType == .mixed {
            let samples = standardCardTextSamples(from: text)

            if !samples.frontText.isEmpty || !samples.backText.isEmpty {
                return (
                    front: LanguageDetectionService.detectPrimaryLanguage(from: samples.frontText),
                    back: LanguageDetectionService.detectPrimaryLanguage(from: samples.backText)
                )
            }
        }

        let detectedLanguage = LanguageDetectionService.detectPrimaryLanguage(from: text)
        return (front: detectedLanguage, back: .english)
    }

    private static func standardCardTextSamples(
        from text: String
    ) -> (frontText: String, backText: String) {
        var frontSamples: [String] = []
        var backSamples: [String] = []

        for line in nonEmptyLines(from: text) {
            guard let parts = splitStandardCardLine(line) else {
                continue
            }

            frontSamples.append(parts.front)
            backSamples.append(parts.back)
        }

        return (
            frontText: frontSamples.joined(separator: "\n"),
            backText: backSamples.joined(separator: "\n")
        )
    }

    private static func splitStandardCardLine(_ line: String) -> (front: String, back: String)? {
        let separators = ["|", "=", " - ", ":"]

        for separator in separators {
            guard let range = line.range(of: separator) else {
                continue
            }

            let frontText = String(line[..<range.lowerBound]).trimmed
            let backText = String(line[range.upperBound...]).trimmed

            if !frontText.isEmpty && !backText.isEmpty {
                return (frontText, backText)
            }
        }

        return nil
    }

    private static func suggestedTitle(from text: String) -> String {
        let lowercasedText = text.lowercased()

        if lowercasedText.contains("urdu") {
            return "Urdu Vocabulary Deck"
        }

        if lowercasedText.contains("quran")
            || lowercasedText.contains("surah")
            || lowercasedText.contains("ayah") {
            return "Line Memorization Deck"
        }

        if lowercasedText.contains("biology") {
            return "Biology Review Deck"
        }

        return "New Memory Deck"
    }

    private static func nonEmptyLines(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmed }
            .filter { !$0.isEmpty }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
