import SwiftUI

struct LineMemorizationDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?

    @State private var didPrepareViewModel = false
    @State private var isShowingReviewDeck = false
    @State private var draftForReview: DeckDraft?
    @State private var memorizationChunksText = ""
    @State private var manualLineOrder = ""

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
            addLineSection
            currentLinesSection
            finalActionsSection
        }
        .navigationTitle(viewModel.isEditingExistingDeck ? "Edit Lines" : "Line Memorization")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.deckDraft.cards.isEmpty {
                    EditButton()
                }
            }
        }
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

            LineMemorizationTextEditor(
                "Description",
                text: $viewModel.deckDraft.deckDescription,
                language: .english,
                minHeight: 110
            )

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

    private var addLineSection: some View {
        Section("Add Line / Card") {
            LineMemorizationTextEditor(
                "Front text",
                text: $viewModel.currentCardDraft.frontText,
                language: viewModel.deckDraft.frontLanguage,
                minHeight: 120
            )

            LineMemorizationTextEditor(
                "Back text",
                text: $viewModel.currentCardDraft.backText,
                language: viewModel.deckDraft.backLanguage,
                minHeight: 120
            )

            TextField("Transliteration", text: cardTextBinding(\.transliteration))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Source Reference", text: cardTextBinding(\.sourceReference))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            LineMemorizationTextEditor(
                "Notes",
                text: cardTextBinding(\.notes),
                language: .english,
                minHeight: 96
            )

            TextField("Line Order", text: $manualLineOrder)
                .keyboardType(.numberPad)

            LineMemorizationTextEditor(
                "Memorization Chunks (one per line)",
                text: $memorizationChunksText,
                language: viewModel.deckDraft.frontLanguage,
                minHeight: 110
            )

            if let validationMessage = viewModel.validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("Add Line") {
                addCurrentLine()
            }

            Button("Clear Current Line", role: .cancel) {
                clearCurrentLine()
            }
        }
    }

    private var currentLinesSection: some View {
        Section {
            if orderedCards.isEmpty {
                Text("No lines added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(orderedCards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: true
                    )
                }
                .onDelete(perform: viewModel.removeCard)
                .onMove(perform: viewModel.moveCard)
            }
        } header: {
            HStack {
                Text("Current Lines")
                Spacer()
                Text("\(viewModel.deckDraft.cardCount) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Add at least 2 lines before reviewing. Use Edit to reorder lines manually.")
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

    private var orderedCards: [FlashcardDraft] {
        viewModel.deckDraft.cards.sorted { firstCard, secondCard in
            let firstOrder = firstCard.lineOrder ?? Int.max
            let secondOrder = secondCard.lineOrder ?? Int.max
            return firstOrder < secondOrder
        }
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
            viewModel.updateDeckType(.lineMemorization)
        } else {
            viewModel.resetForNewDeck(deckType: .lineMemorization)
        }

        syncAuxiliaryFieldsFromCurrentCard()
        didPrepareViewModel = true
    }

    private func addCurrentLine() {
        applyAuxiliaryFieldsToCurrentCard()

        viewModel.validationMessage = DeckValidationService.validateCard(
            frontText: viewModel.currentCardDraft.frontText,
            frontImageName: viewModel.currentCardDraft.frontImageName,
            backText: viewModel.currentCardDraft.backText,
            backImageName: viewModel.currentCardDraft.backImageName,
            deckType: .lineMemorization
        )

        guard viewModel.validationMessage == nil else {
            return
        }

        viewModel.addCurrentCard()
        syncAuxiliaryFieldsFromCurrentCard()
    }

    private func clearCurrentLine() {
        viewModel.resetCurrentCardDraft()
        syncAuxiliaryFieldsFromCurrentCard()
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

    private func syncAuxiliaryFieldsFromCurrentCard() {
        manualLineOrder = viewModel.currentCardDraft.lineOrder.map(String.init) ?? ""
        memorizationChunksText = viewModel.currentCardDraft.memorizationChunks.joined(separator: "\n")
    }

    private func applyAuxiliaryFieldsToCurrentCard() {
        let trimmedLineOrder = manualLineOrder.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.currentCardDraft.lineOrder = Int(trimmedLineOrder)

        viewModel.currentCardDraft.memorizationChunks = memorizationChunksText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct LineMemorizationTextEditor: View {
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
            .frame(minHeight: minHeight, alignment: .topLeading)
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

#Preview {
    NavigationStack {
        LineMemorizationDeckBuilderView()
            .environmentObject(DeckStore())
    }
}
