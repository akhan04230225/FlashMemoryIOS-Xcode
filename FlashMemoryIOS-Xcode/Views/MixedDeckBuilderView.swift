import SwiftUI

struct MixedDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?

    @State private var didPrepareViewModel = false
    @State private var isAdvancedFieldsExpanded = false
    @State private var isShowingReviewDeck = false
    @State private var draftForReview: DeckDraft?

    init(existingDeck: Deck? = nil) {
        self.existingDeck = existingDeck
    }

    init(deck: Deck?) {
        self.init(existingDeck: deck)
    }

    var body: some View {
        Form {
            deckDetailsSection
            languageSettingsSection
            addCardSection
            currentCardsSection
            finalActionsSection
        }
        .navigationTitle(viewModel.isEditingExistingDeck ? "Edit Mixed Deck" : "Mixed Deck")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prepareViewModel)
        .navigationDestination(isPresented: $isShowingReviewDeck) {
            if let draftForReview {
                ReviewDeckView(deckDraft: draftForReview)
                    .environmentObject(deckStore)
            }
        }
    }

    private var deckDetailsSection: some View {
        Section("Deck Details") {
            TextField("Title", text: $viewModel.deckDraft.title)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            MixedMultilineInputField(
                "Description",
                text: $viewModel.deckDraft.deckDescription,
                language: .english
            )
                .lineLimit(3...5)

            TextField("Category", text: deckCategoryBinding)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
    }

    private var languageSettingsSection: some View {
        Section("Language Settings") {
            Picker("Front Language", selection: $viewModel.deckDraft.frontLanguage) {
                ForEach(availableLanguages, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }

            Picker("Back Language", selection: $viewModel.deckDraft.backLanguage) {
                ForEach(availableLanguages, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
        }
        .onChange(of: viewModel.deckDraft.frontLanguage) { _, newLanguage in
            viewModel.currentCardDraft.frontLanguage = newLanguage
        }
        .onChange(of: viewModel.deckDraft.backLanguage) { _, newLanguage in
            viewModel.currentCardDraft.backLanguage = newLanguage
        }
    }

    private var addCardSection: some View {
        Section("Add Card") {
            MixedMultilineInputField(
                "Front text",
                text: $viewModel.currentCardDraft.frontText,
                language: viewModel.deckDraft.frontLanguage
            )
                .lineLimit(2...5)

            MixedMultilineInputField(
                "Back text",
                text: $viewModel.currentCardDraft.backText,
                language: viewModel.deckDraft.backLanguage
            )
                .lineLimit(2...5)

            DisclosureGroup("Advanced Fields", isExpanded: $isAdvancedFieldsExpanded) {
                TextField("Transliteration", text: cardTextBinding(\.transliteration))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                TextField("Category", text: cardTextBinding(\.category))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                TextField("Hint", text: cardTextBinding(\.hintText))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()

                MixedMultilineInputField(
                    "Fill in the Blank",
                    text: cardTextBinding(\.fillBlankText),
                    language: .english
                )
                    .lineLimit(2...4)

                MixedMultilineInputField(
                    "Notes",
                    text: cardTextBinding(\.notes),
                    language: .english
                )
                    .lineLimit(2...5)

                MixedMultilineInputField(
                    "Match Prompt",
                    text: cardTextBinding(\.matchPrompt),
                    language: .english
                )
                    .lineLimit(2...4)

                MixedMultilineInputField(
                    "Match Answer",
                    text: cardTextBinding(\.matchAnswer),
                    language: .english
                )
                    .lineLimit(2...4)

                TextField("Source Reference", text: cardTextBinding(\.sourceReference))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                TextField("Image Name", text: cardTextBinding(\.imageName))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("Add Card") {
                addCurrentCard()
            }

            Button("Clear Current Card", role: .cancel) {
                viewModel.resetCurrentCardDraft()
            }
        }
    }

    private var currentCardsSection: some View {
        Section {
            if viewModel.deckDraft.cards.isEmpty {
                Text("No cards added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.deckDraft.cards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: false
                    )
                }
                .onDelete(perform: viewModel.removeCard)
            }
        } header: {
            HStack {
                Text("Current Cards")
                Spacer()
                Text("\(viewModel.deckDraft.cardCount) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Add at least 2 cards before reviewing your deck.")
        }
    }

    private var finalActionsSection: some View {
        Section("Final Actions") {
            Button(primaryActionTitle) {
                handlePrimaryAction()
            }

            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
    }

    private var availableLanguages: [AppLanguage] {
        [
            .english,
            .urdu,
            .arabic,
            .mixed,
            .custom
        ]
    }

    private var primaryActionTitle: String {
        viewModel.isEditingExistingDeck ? "Update Deck" : "Review Deck"
    }

    private var deckCategoryBinding: Binding<String> {
        Binding(
            get: { viewModel.deckDraft.category ?? "" },
            set: { viewModel.deckDraft.category = $0 }
        )
    }

    private func cardTextBinding(_ keyPath: WritableKeyPath<FlashcardDraft, String?>) -> Binding<String> {
        Binding(
            get: { viewModel.currentCardDraft[keyPath: keyPath] ?? "" },
            set: { viewModel.currentCardDraft[keyPath: keyPath] = $0 }
        )
    }

    private func prepareViewModel() {
        guard !didPrepareViewModel else {
            return
        }

        if let existingDeck {
            viewModel.loadDeckForEditing(existingDeck)
            viewModel.updateDeckType(.mixed)
        } else {
            viewModel.resetForNewDeck(deckType: .mixed)
        }

        didPrepareViewModel = true
    }

    private func addCurrentCard() {
        viewModel.validationMessage = DeckValidationService.validateCard(
            frontText: viewModel.currentCardDraft.frontText,
            frontImageName: viewModel.currentCardDraft.frontImageName,
            backText: viewModel.currentCardDraft.backText,
            backImageName: viewModel.currentCardDraft.backImageName,
            deckType: .mixed
        )

        guard viewModel.validationMessage == nil else {
            return
        }

        viewModel.addCurrentCard()
    }

    private func handlePrimaryAction() {
        if viewModel.isEditingExistingDeck {
            updateDeck()
        } else {
            reviewDeck()
        }
    }

    private func updateDeck() {
        viewModel.validationMessage = viewModel.validateDeckForSave()

        guard viewModel.validationMessage == nil else {
            return
        }

        guard viewModel.saveOrUpdateDeck(using: deckStore) else {
            return
        }

        dismiss()
    }

    private func reviewDeck() {
        viewModel.validationMessage = viewModel.validateDeckForSave()

        guard viewModel.validationMessage == nil else {
            return
        }

        draftForReview = viewModel.deckDraft
        isShowingReviewDeck = true
    }
}

private struct MixedMultilineInputField: View {
    let placeholder: String
    @Binding var text: String
    let language: AppLanguage

    init(_ placeholder: String, text: Binding<String>, language: AppLanguage) {
        self.placeholder = placeholder
        self._text = text
        self.language = language
    }

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .frame(minHeight: 96, alignment: .topLeading)
            .multilineTextAlignment(language.isRightToLeft ? .trailing : .leading)
            .keyboardType(language.usesASCIICapableKeyboard ? .asciiCapable : .default)
            .applyMixedMultilineAutocapitalization(for: language)
            .autocorrectionDisabled()
    }
}

private extension View {
    @ViewBuilder
    func applyMixedMultilineAutocapitalization(for language: AppLanguage) -> some View {
        switch language {
        case .english:
            self.textInputAutocapitalization(.words)
        case .urdu, .arabic, .mixed, .custom:
            self.textInputAutocapitalization(.never)
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

#Preview {
    NavigationStack {
        MixedDeckBuilderView()
            .environmentObject(DeckStore())
    }
}
