import SwiftUI

struct StandardCardEntryFormView: View {
    @Binding var frontText: String
    @Binding var backText: String
    let frontLanguage: AppLanguage
    let backLanguage: AppLanguage

    @Binding var transliteration: String
    @Binding var category: String
    @Binding var hintText: String
    @Binding var fillBlankText: String
    @Binding var notes: String
    @Binding var matchPrompt: String
    @Binding var matchAnswer: String
    @Binding var imageName: String

    @Binding var frontImageName: String
    @Binding var backImageName: String
    @Binding var sourceReference: String
    @Binding var isAdvancedFieldsExpanded: Bool

    var frontFieldFocus: FocusState<Bool>.Binding?
    var showsFrontImageFields: Bool
    var showsSourceReferenceField: Bool

    init(
        frontText: Binding<String>,
        backText: Binding<String>,
        frontLanguage: AppLanguage,
        backLanguage: AppLanguage,
        transliteration: Binding<String>,
        category: Binding<String>,
        hintText: Binding<String>,
        fillBlankText: Binding<String>,
        notes: Binding<String>,
        matchPrompt: Binding<String>,
        matchAnswer: Binding<String>,
        imageName: Binding<String>,
        frontImageName: Binding<String> = .constant(""),
        backImageName: Binding<String> = .constant(""),
        sourceReference: Binding<String> = .constant(""),
        isAdvancedFieldsExpanded: Binding<Bool> = .constant(false),
        frontFieldFocus: FocusState<Bool>.Binding? = nil,
        showsFrontImageFields: Bool = false,
        showsSourceReferenceField: Bool = false
    ) {
        self._frontText = frontText
        self._backText = backText
        self.frontLanguage = frontLanguage
        self.backLanguage = backLanguage
        self._transliteration = transliteration
        self._category = category
        self._hintText = hintText
        self._fillBlankText = fillBlankText
        self._notes = notes
        self._matchPrompt = matchPrompt
        self._matchAnswer = matchAnswer
        self._imageName = imageName
        self._frontImageName = frontImageName
        self._backImageName = backImageName
        self._sourceReference = sourceReference
        self._isAdvancedFieldsExpanded = isAdvancedFieldsExpanded
        self.frontFieldFocus = frontFieldFocus
        self.showsFrontImageFields = showsFrontImageFields
        self.showsSourceReferenceField = showsSourceReferenceField
    }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text("Front")
                    .font(.headline)

                BuilderMultilineInputField(
                    "Front text",
                    text: $frontText,
                    language: frontLanguage,
                    focus: frontFieldFocus
                )
                .lineLimit(2...5)

                if showsFrontImageFields {
                    TextField("Front image name or reference", text: $frontImageName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Back")
                    .font(.headline)

                BuilderMultilineInputField(
                    "Back text",
                    text: $backText,
                    language: backLanguage
                )
                .lineLimit(2...5)

                if showsFrontImageFields {
                    TextField("Back image name or reference", text: $backImageName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            DisclosureGroup("Advanced Fields", isExpanded: $isAdvancedFieldsExpanded) {
                TextField("Transliteration", text: $transliteration)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                TextField("Category", text: $category)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                TextField("Hint", text: $hintText)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()

                BuilderMultilineInputField(
                    "Fill in the Blank",
                    text: $fillBlankText,
                    language: .english
                )
                .lineLimit(2...4)

                BuilderMultilineInputField(
                    "Notes",
                    text: $notes,
                    language: .english
                )
                .lineLimit(2...5)

                BuilderMultilineInputField(
                    "Match Prompt",
                    text: $matchPrompt,
                    language: .english
                )
                .lineLimit(2...4)

                BuilderMultilineInputField(
                    "Match Answer",
                    text: $matchAnswer,
                    language: .english
                )
                .lineLimit(2...4)

                if showsSourceReferenceField {
                    TextField("Source Reference", text: $sourceReference)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                TextField("Image Name", text: $imageName)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }
}

private struct BuilderMultilineInputField: View {
    let placeholder: String
    @Binding var text: String
    let language: AppLanguage
    var focus: FocusState<Bool>.Binding?
    var minHeight: CGFloat = 96

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
            .applyBuilderAutocapitalization(for: language)
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
    func applyBuilderAutocapitalization(for language: AppLanguage) -> some View {
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
