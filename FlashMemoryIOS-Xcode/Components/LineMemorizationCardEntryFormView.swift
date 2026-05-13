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
    var frontFieldFocus: FocusState<Bool>.Binding?

    init(
        frontText: Binding<String>,
        backText: Binding<String>,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage,
        transliteration: Binding<String>,
        sourceReference: Binding<String>,
        notes: Binding<String>,
        lineOrder: Binding<String>,
        memorizationChunksText: Binding<String>,
        frontFieldFocus: FocusState<Bool>.Binding? = nil
    ) {
        self._frontText = frontText
        self._backText = backText
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self._transliteration = transliteration
        self._sourceReference = sourceReference
        self._notes = notes
        self._lineOrder = lineOrder
        self._memorizationChunksText = memorizationChunksText
        self.frontFieldFocus = frontFieldFocus
    }

    var body: some View {
        Group {
            LineMemorizationMultilineInputField(
                "Front text",
                text: $frontText,
                language: frontLanguage,
                focus: frontFieldFocus,
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
    var focus: FocusState<Bool>.Binding?
    let minHeight: CGFloat

    init(
        _ placeholder: String,
        text: Binding<String>,
        language: AppLanguage,
        focus: FocusState<Bool>.Binding? = nil,
        minHeight: CGFloat = 96
    ) {
        self.placeholder = placeholder
        self._text = text
        self.language = language
        self.focus = focus
        self.minHeight = minHeight
    }

    var body: some View {
        let field = TextField(placeholder, text: $text, axis: .vertical)
            .font(AppFont.font(for: language, size: 17))
            .frame(minHeight: minHeight, alignment: .topLeading)
            .languageTextDirection(language)
            .keyboardType(language.usesASCIICapableKeyboard ? .asciiCapable : .default)
            .applyLineMemorizationAutocapitalization(for: language)
            .autocorrectionDisabled()

        if let focus {
            field.focused(focus)
        } else {
            field
        }
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
