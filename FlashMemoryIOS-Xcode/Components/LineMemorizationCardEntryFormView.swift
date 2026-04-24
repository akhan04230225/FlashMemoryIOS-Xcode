import SwiftUI

struct LineMemorizationCardEntryFormView: View {
    @Binding var frontText: String
    @Binding var backText: String
    let frontLanguage: AppLanguage
    let backLanguage: AppLanguage

    @Binding var transliteration: String
    @Binding var sourceReference: String
    @Binding var notes: String
    @Binding var lineOrder: String
    @Binding var memorizationChunksText: String

    var body: some View {
        Group {
            LineMemorizationMultilineInputField(
                "Front text",
                text: $frontText,
                language: frontLanguage,
                minHeight: 120
            )

            LineMemorizationMultilineInputField(
                "Back text",
                text: $backText,
                language: backLanguage,
                minHeight: 120
            )

            TextField("Transliteration", text: $transliteration)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Source Reference", text: $sourceReference)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            LineMemorizationMultilineInputField(
                "Notes",
                text: $notes,
                language: .english,
                minHeight: 96
            )

            TextField("Line Order", text: $lineOrder)
                .keyboardType(.numberPad)

            LineMemorizationMultilineInputField(
                "Memorization Chunks (one per line)",
                text: $memorizationChunksText,
                language: frontLanguage,
                minHeight: 110
            )
        }
    }
}

private struct LineMemorizationMultilineInputField: View {
    let placeholder: String
    @Binding var text: String
    let language: AppLanguage
    let minHeight: CGFloat

    init(
        _ placeholder: String,
        text: Binding<String>,
        language: AppLanguage,
        minHeight: CGFloat = 96
    ) {
        self.placeholder = placeholder
        self._text = text
        self.language = language
        self.minHeight = minHeight
    }

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(AppFont.font(for: language, size: 17))
            .frame(minHeight: minHeight, alignment: .topLeading)
            .languageTextDirection(language)
            .keyboardType(language.usesASCIICapableKeyboard ? .asciiCapable : .default)
            .applyLineMemorizationAutocapitalization(for: language)
            .autocorrectionDisabled()
    }
}

private extension View {
    @ViewBuilder
    func applyLineMemorizationAutocapitalization(for language: AppLanguage) -> some View {
        switch language {
        case .english:
            textInputAutocapitalization(.words)
        case .urdu, .arabic, .mixed, .custom:
            textInputAutocapitalization(.never)
        }
    }
}

private extension AppLanguage {
    var usesASCIICapableKeyboard: Bool {
        switch self {
        case .english:
            return true
        case .urdu, .arabic, .mixed, .custom:
            return false
        }
    }
}
