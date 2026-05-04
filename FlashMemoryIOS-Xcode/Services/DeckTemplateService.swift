import Foundation

struct DeckTemplateService {
    static var templates: [DeckTemplate] {
        [
            DeckTemplate(
                title: "Urdu Vocabulary",
                description: "Practice common English words with Urdu meanings.",
                deckType: .standard,
                suggestedFrontLanguage: .english,
                suggestedBackLanguage: .urdu,
                suggestedCategory: "Language",
                exampleCards: [
                    Flashcard(
                        frontText: "apple",
                        backText: "سیب",
                        frontLanguage: .english,
                        backLanguage: .urdu,
                        transliteration: "saib",
                        category: "Vocabulary"
                    ),
                    Flashcard(
                        frontText: "book",
                        backText: "کتاب",
                        frontLanguage: .english,
                        backLanguage: .urdu,
                        transliteration: "kitaab",
                        category: "Vocabulary"
                    ),
                    Flashcard(
                        frontText: "mercy",
                        backText: "رحمت",
                        frontLanguage: .english,
                        backLanguage: .urdu,
                        transliteration: "rahmat",
                        category: "Vocabulary"
                    )
                ]
            ),
            DeckTemplate(
                title: "Arabic to English",
                description: "Build a vocabulary deck from Arabic words and English meanings.",
                deckType: .standard,
                suggestedFrontLanguage: .arabic,
                suggestedBackLanguage: .english,
                suggestedCategory: "Language",
                exampleCards: [
                    Flashcard(
                        frontText: "سلام",
                        backText: "Peace",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        transliteration: "salaam",
                        category: "Vocabulary"
                    ),
                    Flashcard(
                        frontText: "كتاب",
                        backText: "Book",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        transliteration: "kitaab",
                        category: "Vocabulary"
                    ),
                    Flashcard(
                        frontText: "علم",
                        backText: "Knowledge",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        transliteration: "ilm",
                        category: "Vocabulary"
                    )
                ]
            ),
            DeckTemplate(
                title: "English Definitions",
                description: "Create cards for terms, definitions, and quick study notes.",
                deckType: .standard,
                suggestedFrontLanguage: .english,
                suggestedBackLanguage: .english,
                suggestedCategory: "Study",
                exampleCards: [
                    Flashcard(
                        frontText: "Photosynthesis",
                        backText: "The process by which plants make food using light.",
                        frontLanguage: .english,
                        backLanguage: .english,
                        category: "Definitions",
                        hintText: "Plants use sunlight for this process."
                    ),
                    Flashcard(
                        frontText: "Democracy",
                        backText: "A system of government where people choose their leaders.",
                        frontLanguage: .english,
                        backLanguage: .english,
                        category: "Definitions"
                    ),
                    Flashcard(
                        frontText: "Gravity",
                        backText: "The force that pulls objects toward each other.",
                        frontLanguage: .english,
                        backLanguage: .english,
                        category: "Definitions"
                    )
                ]
            ),
            DeckTemplate(
                title: "Quran Line Memorization",
                description: "Practice memorizing Quran lines in order.",
                deckType: .lineMemorization,
                suggestedFrontLanguage: .arabic,
                suggestedBackLanguage: .english,
                suggestedCategory: "Memorization",
                exampleCards: [
                    Flashcard(
                        frontText: "الحمد لله رب العالمين",
                        backText: "All praise is for Allah, Lord of all worlds.",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        sourceReference: "Al-Fatihah 1:2",
                        lineOrder: 1,
                        memorizationChunks: ["الحمد لله", "رب العالمين"]
                    ),
                    Flashcard(
                        frontText: "الرحمن الرحيم",
                        backText: "The Most Compassionate, Most Merciful.",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        sourceReference: "Al-Fatihah 1:3",
                        lineOrder: 2,
                        memorizationChunks: ["الرحمن", "الرحيم"]
                    ),
                    Flashcard(
                        frontText: "مالك يوم الدين",
                        backText: "Master of the Day of Judgment.",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        sourceReference: "Al-Fatihah 1:4",
                        lineOrder: 3,
                        memorizationChunks: ["مالك", "يوم الدين"]
                    )
                ]
            ),
            DeckTemplate(
                title: "Mixed Exam Review",
                description: "Combine definitions, prompts, and memory checks in one deck.",
                deckType: .mixed,
                suggestedFrontLanguage: .english,
                suggestedBackLanguage: .english,
                suggestedCategory: "Exam Review",
                exampleCards: [
                    Flashcard(
                        frontText: "What is the main idea of a paragraph?",
                        backText: "The central point the paragraph is making.",
                        frontLanguage: .english,
                        backLanguage: .english,
                        category: "Writing",
                        hintText: "Look for what every sentence supports."
                    ),
                    Flashcard(
                        frontText: "justice",
                        backText: "Fair treatment and moral rightness.",
                        frontLanguage: .english,
                        backLanguage: .english,
                        category: "Vocabulary",
                        matchPrompt: "justice",
                        matchAnswer: "fairness"
                    ),
                    Flashcard(
                        frontText: "Step 1: Read the question carefully.",
                        backText: "",
                        frontLanguage: .english,
                        backLanguage: .english,
                        category: "Test Strategy",
                        lineOrder: 1,
                        memorizationChunks: ["Read", "the question", "carefully"]
                    )
                ]
            )
        ]
    }
}
