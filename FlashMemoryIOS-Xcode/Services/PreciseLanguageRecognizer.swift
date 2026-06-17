import Foundation
import NaturalLanguage

extension NLLanguageRecognizer {
    /// Detects language with extra care for Perso-Arabic languages whose scripts overlap.
    ///
    /// `NLLanguageRecognizer` is usually good with full sentences, but short words and
    /// mixed regional scripts can make `.persian`, `.urdu`, and `.arabic` difficult to
    /// separate. This helper keeps Apple's statistical model as the first pass, then
    /// uses Unicode evidence only when the model is ambiguous.
    static func determinePreciseLanguage(
        for text: String,
        constraints: [NLLanguage]? = nil
    ) -> NLLanguage? {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else {
            return nil
        }

        let recognizer = NLLanguageRecognizer()

        if let constraints, !constraints.isEmpty {
            recognizer.languageConstraints = constraints
        }

        recognizer.processString(cleanedText)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        let dominantLanguage = recognizer.dominantLanguage
        let fallbackLanguage = languageFromPersoArabicCharacters(in: cleanedText)
        let isShortText = cleanedText.count < 15

        if let persianScore = hypotheses[.persian],
           let urduScore = hypotheses[.urdu] {
            let scoreDifference = abs(persianScore - urduScore)

            // When Persian and Urdu are statistically close, script-specific
            // characters are more reliable than a tiny score difference.
            if scoreDifference <= 0.12, let fallbackLanguage {
                return fallbackLanguage
            }

            return persianScore > urduScore ? .persian : .urdu
        }

        if dominantLanguage == .urdu,
           constraints?.contains(.persian) == true,
           constraints?.contains(.urdu) == true,
           hasPersianLikelyMarkers(in: cleanedText),
           !hasStrongUrduEvidence(in: cleanedText) {
            return .persian
        }

        if isShortText,
           (dominantLanguage == nil || dominantLanguage == .arabic),
           let fallbackLanguage {
            return fallbackLanguage
        }

        return dominantLanguage ?? fallbackLanguage
    }

    /// Uses only character-level evidence for Persian-vs-Urdu tie-breaking.
    ///
    /// Urdu has distinctive retroflex and aspirated letters such as `ٹ`, `ڈ`,
    /// `ڑ`, `ھ`, `ۂ`, and final `ے`. If any of those are present, we strongly
    /// prefer Urdu.
    ///
    /// Persian and Urdu both commonly use Persian Kaf `ک` and Persian Ye `ی`,
    /// while Arabic uses `ك` and `ي`. Those characters prove the text is
    /// Perso-Arabic rather than Arabic, but by themselves they do not guarantee
    /// Urdu. In that weaker case we bias to Persian unless Urdu-specific
    /// characters are also present.
    private static func languageFromPersoArabicCharacters(in text: String) -> NLLanguage? {
        if hasStrongUrduEvidence(in: text) {
            return .urdu
        }

        if hasPersianLikelyMarkers(in: text) {
            return .persian
        }

        let persianVariantCharacters: Set<Character> = [
            "ک",
            "ی"
        ]

        if text.contains(where: { persianVariantCharacters.contains($0) }) {
            return .persian
        }

        return nil
    }

    private static func hasStrongUrduEvidence(in text: String) -> Bool {
        let urduStrongCharacters: Set<Character> = [
            "ٹ",
            "ڈ",
            "ڑ",
            "ھ",
            "ۂ",
            "ے",
            "ں"
        ]

        return text.contains(where: { urduStrongCharacters.contains($0) })
    }

    private static func hasPersianLikelyMarkers(in text: String) -> Bool {
        // Persian commonly uses a zero-width non-joiner in verbs such as
        // `می‌رود`. Seeing it is a strong signal for Farsi/Persian text.
        if text.unicodeScalars.contains(where: { $0.value == 0x200C }) {
            return true
        }

        let normalizedWords = text
            .replacingOccurrences(of: "\u{200C}", with: " ")
            .split { character in
                character.isWhitespace || character.isPunctuation || character.isNumber
            }

        let persianLikelyWords: Set<String> = [
            "از",
            "به",
            "در",
            "را",
            "که",
            "می",
            "نمی",
            "است",
            "هست",
            "این",
            "آن",
            "برای",
            "خدا",
            "دل"
        ]

        return normalizedWords.contains { word in
            persianLikelyWords.contains(String(word))
        }
    }
}
