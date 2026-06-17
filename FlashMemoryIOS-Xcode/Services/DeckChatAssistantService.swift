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
        let finalLanguages = deckLanguages(
            initialLanguages: languages,
            parseResult: parseResult,
            deckType: detectedDeckType
        )
        let suggestedTitle = suggestedTitle(from: userText)

        let draft = DeckDraft(
            title: suggestedTitle,
            deckDescription: "Created from chat builder input.",
            deckType: detectedDeckType,
            frontLanguage: finalLanguages.front,
            backLanguage: finalLanguages.back,
            cards: parseResult.parsedCards
        )

        let intent = DeckBuildIntent(
            detectedDeckType: detectedDeckType,
            frontLanguage: finalLanguages.front,
            backLanguage: finalLanguages.back,
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
        let requestedLanguage = requestedStudyLanguage(from: text)

        if deckType == .standard || deckType == .mixed {
            let samples = standardCardTextSamples(from: text)

            if !samples.frontText.isEmpty || !samples.backText.isEmpty {
                let detectedFrontLanguage = LanguageDetectionService.detectPrimaryLanguage(
                    from: samples.frontText
                )
                let detectedBackLanguage = LanguageDetectionService.detectPrimaryLanguage(
                    from: samples.backText
                )

                return languagesWithPromptHint(
                    front: detectedFrontLanguage,
                    back: detectedBackLanguage,
                    requestedLanguage: requestedLanguage
                )
            }
        }

        let detectedLanguage = LanguageDetectionService.detectPrimaryLanguage(from: text)

        if deckType == .lineMemorization {
            if let requestedLanguage {
                return (front: requestedLanguage, back: requestedLanguage)
            }

            return (front: detectedLanguage, back: detectedLanguage)
        }

        if let requestedLanguage {
            return (front: requestedLanguage, back: .english)
        }

        return (front: detectedLanguage, back: .english)
    }

    private static func languagesWithPromptHint(
        front: AppLanguage,
        back: AppLanguage,
        requestedLanguage: AppLanguage?
    ) -> (front: AppLanguage, back: AppLanguage) {
        guard let requestedLanguage else {
            return (front: front, back: back)
        }

        if front == .english && back != .english {
            return (front: front, back: requestedLanguage)
        }

        if back == .english && front != .english {
            return (front: requestedLanguage, back: back)
        }

        if front == .mixed || front == .custom {
            return (front: requestedLanguage, back: back)
        }

        if back == .mixed || back == .custom {
            return (front: front, back: requestedLanguage)
        }

        return (front: front, back: back)
    }

    private static func deckLanguages(
        initialLanguages: (front: AppLanguage, back: AppLanguage),
        parseResult: BulkCardParseResult,
        deckType: DeckType
    ) -> (front: AppLanguage, back: AppLanguage) {
        guard deckType == .lineMemorization else {
            return initialLanguages
        }

        let detectedCardLanguages = parseResult.parsedCards.map(\.frontLanguage)
        let frontLanguage = mostCommonLanguage(
            in: detectedCardLanguages,
            fallbackLanguage: initialLanguages.front
        )

        return (front: frontLanguage, back: frontLanguage)
    }

    private static func mostCommonLanguage(
        in languages: [AppLanguage],
        fallbackLanguage: AppLanguage
    ) -> AppLanguage {
        guard !languages.isEmpty else {
            return fallbackLanguage
        }

        let counts = Dictionary(grouping: languages, by: { $0 })
            .mapValues(\.count)

        let sortedLanguages = counts.sorted { first, second in
            if first.value == second.value {
                return first.key.displayName < second.key.displayName
            }

            return first.value > second.value
        }

        guard let mostCommon = sortedLanguages.first else {
            return fallbackLanguage
        }

        return mostCommon.value == 1 && counts.count > 1 ? .mixed : mostCommon.key
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

    private static func requestedStudyLanguage(from text: String) -> AppLanguage? {
        let lowercasedText = text.lowercased()

        if lowercasedText.contains("urdu") {
            return .urdu
        }

        if lowercasedText.contains("farsi") || lowercasedText.contains("persian") {
            return .persian
        }

        if lowercasedText.contains("arabic") || lowercasedText.contains("quran") {
            return .arabic
        }

        if lowercasedText.contains("turkish") {
            return .turkish
        }

        if lowercasedText.contains("hindi") {
            return .hindi
        }

        if lowercasedText.contains("chinese") || lowercasedText.contains("mandarin") {
            return .chinese
        }

        if lowercasedText.contains("korean") {
            return .korean
        }

        if lowercasedText.contains("japanese") {
            return .japanese
        }

        return nil
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
