import Foundation
import NaturalLanguage

struct LanguageDetectionService {
    static func detectPrimaryLanguage(from text: String) -> AppLanguage {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else {
            return .mixed
        }

        // If the text clearly contains more than one script or likely language,
        // treat it as a multilingual deck input.
        if hasStrongMixedLanguageSignal(cleanedText) {
            return .mixed
        }

        // NaturalLanguage gives the best global coverage for languages such as
        // Spanish, French, Turkish, Arabic, Urdu, and many others.
        if let languageCode = detectDominantLanguageCode(from: cleanedText) {
            switch languageCode {
            case "en":
                return .english
            case "ar":
                return .arabic
            case "ur":
                return .urdu
            default:
                return .custom
            }
        }

        return fallbackLanguage(for: cleanedText)
    }

    static func detectDominantLanguageCode(from text: String) -> String? {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else {
            return nil
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(cleanedText)

        guard let dominantLanguage = recognizer.dominantLanguage else {
            return nil
        }

        return dominantLanguage.rawValue
    }

    static func containsArabicScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isArabicScriptScalar(scalar)
        }
    }

    static func containsUrduSpecificCharacters(_ text: String) -> Bool {
        let urduSpecificCharacters: Set<Character> = [
            "ں", "گ", "چ", "پ", "ژ", "ڈ", "ڑ"
        ]

        return text.contains { character in
            urduSpecificCharacters.contains(character)
        }
    }

    static func isMostlyLatinScript(_ text: String) -> Bool {
        let letterScalars = text.unicodeScalars.filter { scalar in
            CharacterSet.letters.contains(scalar)
        }

        guard !letterScalars.isEmpty else {
            return false
        }

        let latinLetterCount = letterScalars.filter { scalar in
            isLatinScriptScalar(scalar)
        }.count

        return Double(latinLetterCount) / Double(letterScalars.count) >= 0.6
    }

    private static func fallbackLanguage(for text: String) -> AppLanguage {
        // Arabic and Urdu share Arabic script, so Urdu-specific letters get
        // checked before falling back to Arabic.
        if containsArabicScript(text) {
            if containsUrduSpecificCharacters(text) {
                return .urdu
            }

            return .arabic
        }

        if isMostlyLatinScript(text) {
            return .english
        }

        return .mixed
    }

    private static func hasStrongMixedLanguageSignal(_ text: String) -> Bool {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        // NLLanguageRecognizer can return multiple hypotheses. Two strong
        // candidates usually means the pasted text is mixed.
        let strongLanguages = recognizer.languageHypotheses(withMaximum: 3)
            .filter { _, confidence in
                confidence >= 0.25
            }

        if strongLanguages.count >= 2 {
            return true
        }

        let hasArabicOrUrduScript = containsArabicScript(text)
        let hasLatinScript = isMostlyLatinScript(text) || containsAnyLatinScript(text)

        // This catches common deck inputs like "apple | سیب" or
        // English explanations beside Arabic verses.
        return hasArabicOrUrduScript && hasLatinScript
    }

    private static func containsAnyLatinScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isLatinScriptScalar(scalar)
        }
    }

    private static func isArabicScriptScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0600...0x06FF,
             0x0750...0x077F,
             0x08A0...0x08FF,
             0xFB50...0xFDFF,
             0xFE70...0xFEFF:
            return true
        default:
            return false
        }
    }

    private static func isLatinScriptScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0041...0x005A,
             0x0061...0x007A,
             0x00C0...0x00FF,
             0x0100...0x017F,
             0x0180...0x024F:
            return true
        default:
            return false
        }
    }
}
