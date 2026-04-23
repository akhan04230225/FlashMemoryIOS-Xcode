import SwiftUI

struct StandardDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?

    @State private var didPrepareViewModel = false
    @State private var isAdvancedCardInfoExpanded = false
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
        .navigationTitle(viewModel.isEditingExistingDeck ? "Edit Standard Deck" : "Standard Deck")
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

            MultilineInputField(
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Front")
                    .font(.headline)

                MultilineInputField(
                    "Front text",
                    text: $viewModel.currentCardDraft.frontText,
                    language: viewModel.deckDraft.frontLanguage
                )
                    .lineLimit(2...5)

                TextField("Front image name or reference", text: cardTextBinding(\.frontImageName))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Add Front Image Later") {
                    viewModel.currentCardDraft.frontImageName = viewModel.currentCardDraft.frontImageName ?? ""
                }
                .font(.footnote)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Back")
                    .font(.headline)

                MultilineInputField(
                    "Back text",
                    text: $viewModel.currentCardDraft.backText,
                    language: viewModel.deckDraft.backLanguage
                )
                    .lineLimit(2...5)

                TextField("Back image name or reference", text: cardTextBinding(\.backImageName))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Add Back Image Later") {
                    viewModel.currentCardDraft.backImageName = viewModel.currentCardDraft.backImageName ?? ""
                }
                .font(.footnote)
            }

            DisclosureGroup("Advanced Fields", isExpanded: $isAdvancedCardInfoExpanded) {
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

                MultilineInputField(
                    "Fill in the Blank",
                    text: cardTextBinding(\.fillBlankText),
                    language: .english
                )
                    .lineLimit(2...4)

                MultilineInputField(
                    "Notes",
                    text: cardTextBinding(\.notes),
                    language: .english
                )
                    .lineLimit(2...5)

                MultilineInputField(
                    "Match Prompt",
                    text: cardTextBinding(\.matchPrompt),
                    language: .english
                )
                    .lineLimit(2...4)

                MultilineInputField(
                    "Match Answer",
                    text: cardTextBinding(\.matchAnswer),
                    language: .english
                )
                    .lineLimit(2...4)

                TextField("General Image Name", text: cardTextBinding(\.imageName))
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
            viewModel.updateDeckType(.standard)
        } else {
            viewModel.resetForNewDeck(deckType: .standard)
        }

        didPrepareViewModel = true
    }

    private func addCurrentCard() {
        viewModel.validationMessage = DeckValidationService.validateCard(
            frontText: viewModel.currentCardDraft.frontText,
            frontImageName: viewModel.currentCardDraft.frontImageName,
            backText: viewModel.currentCardDraft.backText,
            backImageName: viewModel.currentCardDraft.backImageName,
            deckType: .standard
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

struct ReviewDeckView: View {
    @EnvironmentObject private var deckStore: DeckStore
    @Environment(\.dismiss) private var dismiss

    let deckDraft: DeckDraft

    var body: some View {
        Form {
            Section("Deck") {
                Text(deckDraft.title)

                if !deckDraft.deckDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(deckDraft.deckDescription)
                        .foregroundStyle(.secondary)
                }

                if let category = deckDraft.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
                    Text("Category: \(category)")
                }

                Text("\(deckDraft.cardCount) cards")
            }

            Section("Languages") {
                Text("Front: \(deckDraft.frontLanguage.displayName)")
                Text("Back: \(deckDraft.backLanguage.displayName)")
            }

            Section("Cards") {
                ForEach(deckDraft.cards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: false
                    )
                }
            }

            Section {
                Button("Save Deck") {
                    deckStore.addDeck(from: deckDraft)
                    dismiss()
                }
            }
        }
        .navigationTitle("Review Deck")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StandardDeckBuilderView()
            .environmentObject(DeckStore())
    }
}

private struct MultilineInputField: View {
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
            .applyMultilineAutocapitalization(for: language)
            .autocorrectionDisabled()
    }
}

private extension View {
    @ViewBuilder
    func applyMultilineAutocapitalization(for language: AppLanguage) -> some View {
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
