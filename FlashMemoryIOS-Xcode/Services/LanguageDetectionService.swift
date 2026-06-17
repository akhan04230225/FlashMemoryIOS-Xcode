import Foundation
import NaturalLanguage

struct LanguageDetectionService {
    static func detectPrimaryLanguage(from text: String) -> AppLanguage {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedText.isEmpty else {
            return .mixed
        }

        if let cjkLanguage = detectCJKLanguage(from: cleanedText) {
            return cjkLanguage
        }

        // If the text clearly contains more than one script, treat it as a
        // multilingual deck input.
        if hasStrongMixedLanguageSignal(cleanedText) {
            return .mixed
        }

        if containsDevanagariScript(cleanedText) {
            return .hindi
        }

        if containsArabicScript(cleanedText) {
            if let preciseLanguage = detectRegionalArabicScriptLanguage(from: cleanedText) {
                return preciseLanguage
            }

            if shouldTreatArabicScriptTextAsUrdu(cleanedText) {
                return .urdu
            }

            return .arabic
        }

        if isLikelyTurkishText(cleanedText) {
            return .turkish
        }

        if let shortTextLanguage = detectShortLatinTextLanguage(from: cleanedText) {
            return shortTextLanguage
        }

        // NaturalLanguage gives the best global coverage for languages such as
        // Spanish, French, Turkish, Arabic, Urdu, and many others.
        if let languageCode = detectDominantLanguageCode(from: cleanedText) {
            return appLanguage(for: languageCode)
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
            "ں",
            "ڈ",
            "ڑ",
            "ٹ",
            "ھ",
            "ۂ",
            "ے"
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
        // Arabic, Urdu, and Farsi share related script forms, so use the
        // precise recognizer first and only fall back to character rules.
        if containsArabicScript(text) {
            if let preciseLanguage = detectRegionalArabicScriptLanguage(from: text) {
                return preciseLanguage
            }

            if shouldTreatArabicScriptTextAsUrdu(text) {
                return .urdu
            }

            return .arabic
        }

        if isMostlyLatinScript(text) {
            if isLikelyTurkishText(text) {
                return .turkish
            }

            return .english
        }

        if let cjkLanguage = detectCJKLanguage(from: text) {
            return cjkLanguage
        }

        return .mixed
    }

    private static func shouldTreatArabicScriptTextAsUrdu(_ text: String) -> Bool {
        if containsArabicSpecificCharacters(text) {
            return false
        }

        if containsUrduSpecificCharacters(text) {
            return true
        }

        // These letters are common in Urdu keyboard input, but they are not
        // strong enough by themselves if the text also has clear Arabic forms.
        return containsUrduKeyboardCharacters(text)
    }

    private static func containsArabicSpecificCharacters(_ text: String) -> Bool {
        let arabicSpecificCharacters: Set<Character> = [
            "ي",
            "ك",
            "ة",
            "ى",
            "أ",
            "إ",
            "آ",
            "ؤ",
            "ئ",
            "ء"
        ]

        if text.contains(where: { arabicSpecificCharacters.contains($0) }) {
            return true
        }

        return text.unicodeScalars.contains { scalar in
            isArabicDiacriticScalar(scalar)
        }
    }

    private static func containsUrduKeyboardCharacters(_ text: String) -> Bool {
        let urduKeyboardCharacters: Set<Character> = [
            "ے",
            "ہ",
            "ھ"
        ]

        return text.contains { character in
            urduKeyboardCharacters.contains(character)
        }
    }

    private static func detectShortLatinTextLanguage(from text: String) -> AppLanguage? {
        guard isShortLatinText(text) else {
            return nil
        }

        let normalizedWord = text
            .lowercased()
            .trimmingCharacters(in: CharacterSet.letters.inverted)

        if commonEnglishWords.contains(normalizedWord) {
            return .english
        }

        let hypotheses = languageHypotheses(from: text)
        let supportedHypotheses = hypotheses.compactMap { languageCode, confidence -> (AppLanguage, Double)? in
            let language = appLanguage(for: languageCode)
            return language == .custom ? nil : (language, confidence)
        }

        guard let bestSupported = supportedHypotheses.max(by: { $0.1 < $1.1 }) else {
            return .english
        }

        if bestSupported.1 >= 0.42 {
            return bestSupported.0
        }

        return .english
    }

    private static func hasStrongMixedLanguageSignal(_ text: String) -> Bool {
        let hasArabicScript = containsArabicScript(text)
        let hasDevanagariScript = containsDevanagariScript(text)
        let hasLatinScript = containsAnyLatinScript(text)
        let hasCJKScript = containsAnyCJKScript(text)
        let scriptCount = [
            hasArabicScript,
            hasDevanagariScript,
            hasLatinScript,
            hasCJKScript
        ].filter { $0 }.count

        // This catches common deck inputs like "apple | سیب", English
        // explanations beside Arabic verses, Hindi beside English, or
        // Chinese/Japanese/Korean beside another script family.
        if scriptCount >= 2 {
            return true
        }

        // Short one-language text such as "Apple" or "Manzana" can produce
        // several NaturalLanguage guesses. Do not call that mixed unless the
        // text has a real multi-script signal.
        if isMostlyLatinScript(text) || hasArabicScript || hasDevanagariScript || hasCJKScript {
            return false
        }

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

        return false
    }

    private static func languageHypotheses(from text: String) -> [(languageCode: String, confidence: Double)] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        return recognizer.languageHypotheses(withMaximum: 5).map { language, confidence in
            (languageCode: language.rawValue, confidence: confidence)
        }
    }

    private static func appLanguage(for languageCode: String) -> AppLanguage {
        if languageCode.hasPrefix("zh") {
            return .chinese
        }

        switch languageCode {
        case "en":
            return .english
        case "ar":
            return .arabic
        case "ur":
            return .urdu
        case "fa", "prs":
            return .persian
        case "es":
            return .spanish
        case "fr":
            return .french
        case "de":
            return .german
        case "it":
            return .italian
        case "pt":
            return .portuguese
        case "tr":
            return .turkish
        case "hi":
            return .hindi
        case "ko":
            return .korean
        case "ja":
            return .japanese
        default:
            return .custom
        }
    }

    private static func detectRegionalArabicScriptLanguage(from text: String) -> AppLanguage? {
        if let scoredLanguage = scoredArabicScriptLanguage(from: text) {
            return scoredLanguage
        }

        let constraints: [NLLanguage]

        if containsArabicSpecificCharacters(text) {
            constraints = [.arabic, .persian, .urdu]
        } else {
            constraints = [.persian, .urdu]
        }

        guard let language = NLLanguageRecognizer.determinePreciseLanguage(
            for: text,
            constraints: constraints
        ) else {
            return nil
        }

        return appLanguage(for: language.rawValue)
    }

    private static func scoredArabicScriptLanguage(from text: String) -> AppLanguage? {
        let words = normalizedArabicScriptWords(from: text)
        var arabicScore = 0
        var urduScore = 0
        var persianScore = 0

        if containsUrduSpecificCharacters(text) {
            urduScore += 4
        }

        if containsArabicSpecificCharacters(text) {
            arabicScore += 3
        }

        if containsPersianLikelyMarkers(text) {
            persianScore += 4
        }

        if containsPersianVariantCharacters(text) {
            persianScore += 1
        }

        arabicScore += matchingWordCount(in: words, knownWords: arabicLikelyWords) * 2
        urduScore += matchingWordCount(in: words, knownWords: urduLikelyWords) * 2
        persianScore += matchingWordCount(in: words, knownWords: persianLikelyWords) * 2

        if words.contains(where: { $0.hasPrefix("ال") && $0.count >= 4 }) {
            arabicScore += 2
        }

        let scores: [(language: AppLanguage, score: Int)] = [
            (.arabic, arabicScore),
            (.urdu, urduScore),
            (.persian, persianScore)
        ].sorted { first, second in
            first.score > second.score
        }

        guard let best = scores.first, best.score > 0 else {
            return nil
        }

        let runnerUpScore = scores.dropFirst().first?.score ?? 0

        if best.score >= runnerUpScore + 2 {
            return best.language
        }

        return nil
    }

    private static func normalizedArabicScriptWords(from text: String) -> [String] {
        text
            .replacingOccurrences(of: "\u{200C}", with: " ")
            .split { character in
                character.isWhitespace || character.isPunctuation || character.isNumber
            }
            .map { String($0) }
    }

    private static func matchingWordCount(in words: [String], knownWords: Set<String>) -> Int {
        words.filter { knownWords.contains($0) }.count
    }

    private static func containsPersianLikelyMarkers(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            scalar.value == 0x200C
        }
    }

    private static func containsPersianVariantCharacters(_ text: String) -> Bool {
        let persianVariantCharacters: Set<Character> = [
            "ک",
            "ی"
        ]

        return text.contains { character in
            persianVariantCharacters.contains(character)
        }
    }

    private static func isShortLatinText(_ text: String) -> Bool {
        guard isMostlyLatinScript(text) else {
            return false
        }

        let words = text
            .split { character in
                character.isWhitespace || character.isPunctuation || character.isSymbol || character.isNumber
            }

        return words.count <= 2 && text.count <= 24
    }

    private static func containsAnyLatinScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isLatinScriptScalar(scalar)
        }
    }

    private static func containsDevanagariScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isDevanagariScriptScalar(scalar)
        }
    }

    private static func detectCJKLanguage(from text: String) -> AppLanguage? {
        guard containsAnyCJKScript(text) else {
            return nil
        }

        // If this CJK text is mixed with another script family, let the
        // mixed-language check handle it.
        if containsArabicScript(text) || containsDevanagariScript(text) || containsAnyLatinScript(text) {
            return nil
        }

        if containsHangulScript(text) {
            return .korean
        }

        if containsJapaneseKanaScript(text) {
            return .japanese
        }

        if containsHanScript(text) {
            if let languageCode = detectDominantLanguageCode(from: text) {
                let language = appLanguage(for: languageCode)

                if language == .chinese || language == .japanese || language == .korean {
                    return language
                }
            }

            return .chinese
        }

        return nil
    }

    private static func containsAnyCJKScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isHanScriptScalar(scalar)
                || isJapaneseKanaScriptScalar(scalar)
                || isHangulScriptScalar(scalar)
        }
    }

    private static func containsHanScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isHanScriptScalar(scalar)
        }
    }

    private static func containsJapaneseKanaScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isJapaneseKanaScriptScalar(scalar)
        }
    }

    private static func containsHangulScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            isHangulScriptScalar(scalar)
        }
    }

    private static func isLikelyTurkishText(_ text: String) -> Bool {
        let lowercasedText = text.lowercased(with: Locale(identifier: "tr_TR"))
        let turkishSpecificCharacters: Set<Character> = [
            "ç",
            "ğ",
            "ı",
            "ö",
            "ş",
            "ü"
        ]

        if lowercasedText.contains(where: { turkishSpecificCharacters.contains($0) }) {
            return true
        }

        let words = lowercasedText
            .split { character in
                character.isWhitespace || character.isPunctuation || character.isNumber
            }
            .map { String($0) }

        let matches = words.filter { turkishLikelyWords.contains($0) }.count
        return matches >= 2
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

    private static func isArabicDiacriticScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670,
             0x06D6...0x06ED:
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

    private static func isDevanagariScriptScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0900...0x097F,
             0xA8E0...0xA8FF:
            return true
        default:
            return false
        }
    }

    private static func isHanScriptScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF,
             0x4E00...0x9FFF,
             0xF900...0xFAFF,
             0x20000...0x2A6DF,
             0x2A700...0x2B73F,
             0x2B740...0x2B81F,
             0x2B820...0x2CEAF:
            return true
        default:
            return false
        }
    }

    private static func isJapaneseKanaScriptScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x3040...0x309F,
             0x30A0...0x30FF,
             0x31F0...0x31FF:
            return true
        default:
            return false
        }
    }

    private static func isHangulScriptScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x1100...0x11FF,
             0x3130...0x318F,
             0xA960...0xA97F,
             0xAC00...0xD7AF,
             0xD7B0...0xD7FF:
            return true
        default:
            return false
        }
    }

    private static let arabicLikelyWords: Set<String> = [
        "الله",
        "الرحمن",
        "الرحيم",
        "الحمد",
        "العالمين",
        "رب",
        "هذا",
        "هذه",
        "ذلك",
        "الذي",
        "التي",
        "من",
        "في",
        "على",
        "إلى",
        "الى",
        "أن",
        "إن",
        "قال",
        "كان",
        "كتاب",
        "النور",
        "السلام"
    ]

    private static let urduLikelyWords: Set<String> = [
        "ہے",
        "ہیں",
        "میں",
        "نہیں",
        "اور",
        "کا",
        "کی",
        "کے",
        "یہ",
        "وہ",
        "آپ",
        "ہم",
        "سے",
        "کو",
        "پر",
        "ایک",
        "کتاب",
        "سیب",
        "انصاف",
        "رحمت"
    ]

    private static let persianLikelyWords: Set<String> = [
        "از",
        "به",
        "در",
        "را",
        "که",
        "می",
        "نمی",
        "است",
        "هست",
        "نیست",
        "این",
        "آن",
        "برای",
        "خدا",
        "دل",
        "بود",
        "شد",
        "کرد",
        "من",
        "تو",
        "ما"
    ]

    private static let turkishLikelyWords: Set<String> = [
        "ve",
        "bir",
        "bu",
        "şu",
        "ile",
        "için",
        "değil",
        "ben",
        "sen",
        "biz",
        "kitap",
        "elma",
        "adalet",
        "merhamet"
    ]

    private static let commonEnglishWords: Set<String> = [
        "a",
        "about",
        "above",
        "after",
        "again",
        "air",
        "all",
        "also",
        "and",
        "animal",
        "answer",
        "apple",
        "area",
        "ask",
        "back",
        "be",
        "because",
        "bed",
        "before",
        "big",
        "bird",
        "book",
        "boy",
        "bread",
        "bring",
        "brother",
        "build",
        "but",
        "buy",
        "call",
        "can",
        "car",
        "card",
        "cat",
        "city",
        "come",
        "day",
        "dog",
        "door",
        "down",
        "drink",
        "earth",
        "eat",
        "end",
        "family",
        "father",
        "find",
        "fire",
        "fish",
        "food",
        "friend",
        "from",
        "girl",
        "give",
        "go",
        "good",
        "great",
        "hand",
        "happy",
        "have",
        "he",
        "help",
        "here",
        "home",
        "house",
        "how",
        "i",
        "in",
        "is",
        "it",
        "justice",
        "know",
        "learn",
        "light",
        "line",
        "live",
        "love",
        "make",
        "man",
        "many",
        "me",
        "mercy",
        "mother",
        "name",
        "new",
        "night",
        "no",
        "not",
        "now",
        "of",
        "on",
        "one",
        "open",
        "or",
        "people",
        "question",
        "read",
        "right",
        "school",
        "see",
        "she",
        "small",
        "study",
        "sun",
        "take",
        "teacher",
        "text",
        "the",
        "they",
        "thing",
        "time",
        "to",
        "tree",
        "up",
        "use",
        "water",
        "we",
        "what",
        "when",
        "where",
        "who",
        "why",
        "with",
        "word",
        "work",
        "world",
        "write",
        "yes",
        "you"
    ]
}
