import Foundation

struct LanguageDetectionService {
    static func detectPrimaryLanguage(from text: String) -> AppLanguage {
        if containsUrduLikelyCharacters(text) {
            return .urdu
        }

        if containsArabicScript(text) {
            return .arabic
        }

        if containsEnglishLikelyText(text) {
            return .english
        }

        return .mixed
    }

    static func containsArabicScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isArabicScriptScalar(scalar)
        }
    }

    static func containsUrduLikelyCharacters(_ text: String) -> Bool {
        let urduSpecificCharacters: Set<Character> = [
            "ں", "گ", "چ", "پ", "ژ", "ڈ", "ڑ"
        ]

        return text.contains { character in
            urduSpecificCharacters.contains(character)
        }
    }

    static func containsEnglishLikelyText(_ text: String) -> Bool {
        let letterScalars = text.unicodeScalars.filter { scalar in
            CharacterSet.letters.contains(scalar)
        }

        guard !letterScalars.isEmpty else {
            return false
        }

        let latinLetterCount = letterScalars.filter { scalar in
            isLatinLetterScalar(scalar)
        }.count

        return Double(latinLetterCount) / Double(letterScalars.count) >= 0.6
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

    private static func isLatinLetterScalar(_ scalar: UnicodeScalar) -> Bool {
        (0x0041...0x005A).contains(scalar.value)
            || (0x0061...0x007A).contains(scalar.value)
    }
}
