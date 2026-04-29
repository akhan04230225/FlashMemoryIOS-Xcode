import Foundation

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
        let lines = nonEmptyLines(from: text)

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
        let separators = ["|", " - ", ":"]

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
