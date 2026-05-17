import Foundation

enum LineMemorizationSplitMethod: String, CaseIterable, Identifiable {
    case lineBreak
    case sentence
    case customDelimiter

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .lineBreak:
            return "Line Break"
        case .sentence:
            return "Sentence"
        case .customDelimiter:
            return "Custom Delimiter"
        }
    }
}

struct BulkCardParserService {
    static func parseStandardCards(
        from text: String,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage
    ) -> BulkCardParseResult {
        let lines = nonEmptyLines(from: text)
        var parsedCards: [Flashcard] = []
        var skippedLines: [String] = []

        for line in lines {
            guard let card = parseStandardCard(
                from: line,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            ) else {
                skippedLines.append(line)
                continue
            }

            parsedCards.append(card)
        }

        return BulkCardParseResult(
            parsedCards: parsedCards,
            skippedLines: skippedLines,
            errorMessage: errorMessage(
                parsedCards: parsedCards,
                skippedLines: skippedLines
            )
        )
    }

    static func parseLineMemorizationCards(
        from text: String,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage
    ) -> BulkCardParseResult {
        parseLineMemorizationCards(
            from: text,
            frontLanguage: frontLanguage,
            backLanguage: backLanguage,
            splitMethod: .lineBreak,
            customDelimiter: ""
        )
    }

    static func parseLineMemorizationCards(
        from text: String,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage,
        splitMethod: LineMemorizationSplitMethod,
        customDelimiter: String = ""
    ) -> BulkCardParseResult {
        let lines: [String]

        switch splitMethod {
        case .lineBreak:
            lines = nonEmptyLines(from: text)
        case .sentence:
            lines = sentences(from: text)
        case .customDelimiter:
            let delimiter = customDelimiter.trimmed

            guard !delimiter.isEmpty else {
                return BulkCardParseResult(
                    parsedCards: [],
                    skippedLines: [],
                    errorMessage: "Enter a delimiter before previewing lines."
                )
            }

            lines = text
                .components(separatedBy: delimiter)
                .map { $0.trimmed }
                .filter { !$0.isEmpty }
        }

        let cards = lines.enumerated().map { index, line in
            Flashcard(
                frontText: line,
                backText: "",
                frontLanguage: frontLanguage,
                backLanguage: backLanguage,
                lineOrder: index + 1
            )
        }

        return BulkCardParseResult(
            parsedCards: cards,
            skippedLines: [],
            errorMessage: cards.isEmpty ? "Paste at least one line to create cards." : nil
        )
    }

    private static func parseStandardCard(
        from line: String,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage
    ) -> Flashcard? {
        guard let parts = splitStandardCardLine(line) else {
            return nil
        }

        return Flashcard(
            frontText: parts.front,
            backText: parts.back,
            frontLanguage: frontLanguage,
            backLanguage: backLanguage
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

    private static func nonEmptyLines(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmed }
            .filter { !$0.isEmpty }
    }

    private static func sentences(from text: String) -> [String] {
        var sentences: [String] = []
        var currentSentence = ""
        let sentenceEndings: Set<Character> = [".", "!", "?", "؟", "۔"]

        for character in text {
            currentSentence.append(character)

            if sentenceEndings.contains(character) {
                let sentence = currentSentence.trimmed

                if !sentence.isEmpty {
                    sentences.append(sentence)
                }

                currentSentence = ""
            }
        }

        let finalSentence = currentSentence.trimmed

        if !finalSentence.isEmpty {
            sentences.append(finalSentence)
        }

        return sentences
    }

    private static func errorMessage(parsedCards: [Flashcard], skippedLines: [String]) -> String? {
        if parsedCards.isEmpty {
            return "No cards could be created from this text."
        }

        if !skippedLines.isEmpty {
            return "Some lines could not be read and were skipped."
        }

        return nil
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
