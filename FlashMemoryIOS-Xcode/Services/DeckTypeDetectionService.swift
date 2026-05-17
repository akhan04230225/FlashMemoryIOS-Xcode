import Foundation

struct DeckTypeDetectionService {
    static func detectDeckType(from text: String) -> DeckType {
        let normalizedText = text.lowercased()
        let lines = nonEmptyLines(from: text)

        if mentionsMixedReview(in: normalizedText) {
            return .mixed
        }

        if mentionsLineMemorization(in: normalizedText) {
            return .lineMemorization
        }

        if hasManyFrontBackLines(lines) {
            return .standard
        }

        if hasManyLongLinesWithoutSeparators(lines) {
            return .lineMemorization
        }

        return .standard
    }

    static func confidence(for text: String, detectedType: DeckType) -> Double {
        let normalizedText = text.lowercased()
        let lines = nonEmptyLines(from: text)

        switch detectedType {
        case .standard:
            if hasManyFrontBackLines(lines) {
                return 0.9
            }

            return 0.6

        case .lineMemorization:
            if mentionsLineMemorization(in: normalizedText) && hasManyLongLinesWithoutSeparators(lines) {
                return 0.95
            }

            if mentionsLineMemorization(in: normalizedText) || hasManyLongLinesWithoutSeparators(lines) {
                return 0.8
            }

            return 0.6

        case .mixed:
            if mentionsMixedReview(in: normalizedText) {
                return 0.85
            }

            return 0.6
        }
    }

    static func explanation(for detectedType: DeckType) -> String {
        switch detectedType {
        case .standard:
            return "This looks like a standard flashcard deck with front and back prompts."
        case .lineMemorization:
            return "This looks like ordered text that would work well for line memorization."
        case .mixed:
            return "This looks like a mixed review deck with multiple categories or subjects."
        }
    }

    private static func nonEmptyLines(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func hasManyFrontBackLines(_ lines: [String]) -> Bool {
        guard lines.count >= 2 else {
            return false
        }

        let matchingLineCount = lines.filter { line in
            looksLikeFrontBackLine(line)
        }.count

        return Double(matchingLineCount) / Double(lines.count) >= 0.5
    }

    private static func looksLikeFrontBackLine(_ line: String) -> Bool {
        let separators = ["=", "|", " - ", ":"]

        return separators.contains { separator in
            guard let range = line.range(of: separator) else {
                return false
            }

            let frontText = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let backText = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

            return !frontText.isEmpty && !backText.isEmpty
        }
    }

    private static func mentionsLineMemorization(in text: String) -> Bool {
        let keywords = [
            "quran",
            "surah",
            "ayah",
            "verse",
            "poem",
            "poetry",
            "dua",
            "speech",
            "memorize lines",
            "line memorization"
        ]

        return keywords.contains { keyword in
            text.contains(keyword)
        }
    }

    private static func hasManyLongLinesWithoutSeparators(_ lines: [String]) -> Bool {
        guard lines.count >= 3 else {
            return false
        }

        let longLineCount = lines.filter { line in
            line.count >= 30 && !looksLikeFrontBackLine(line)
        }.count

        return Double(longLineCount) / Double(lines.count) >= 0.6
    }

    private static func mentionsMixedReview(in text: String) -> Bool {
        let mixedKeywords = [
            "categories",
            "category",
            "mixed",
            "exam review",
            "multiple subjects"
        ]

        if mixedKeywords.contains(where: { text.contains($0) }) {
            return true
        }

        let subjectKeywords = [
            "biology",
            "chemistry",
            "history"
        ]

        let matchedSubjectCount = subjectKeywords.filter { subject in
            text.contains(subject)
        }.count

        return matchedSubjectCount >= 2
    }
}
