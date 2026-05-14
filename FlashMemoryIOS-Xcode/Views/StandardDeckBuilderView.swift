import SwiftUI

struct StandardDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?
    private let initialDeckDraft: DeckDraft?
    private let template: DeckTemplate?
    private let onSaveComplete: () -> Void

    @State private var didPrepareViewModel = false
    @State private var isAdvancedCardInfoExpanded = false
    @State private var selectedEntryMode: CardEntryMode = .manual
    @State private var bulkPastedText = ""
    @State private var bulkParseResult: BulkCardParseResult?
    @State private var draftForReview: DeckDraft?
    @State private var successMessage: String?
    @FocusState private var isFrontFieldFocused: Bool

    init(
        existingDeck: Deck? = nil,
        initialDeckDraft: DeckDraft? = nil,
        template: DeckTemplate? = nil,
        onSaveComplete: @escaping () -> Void = {}
    ) {
        self.existingDeck = existingDeck
        self.initialDeckDraft = initialDeckDraft
        self.template = template
        self.onSaveComplete = onSaveComplete
    }

    init(initialDeckDraft: DeckDraft, onSaveComplete: @escaping () -> Void = {}) {
        self.init(existingDeck: nil, initialDeckDraft: initialDeckDraft, onSaveComplete: onSaveComplete)
    }

    init(template: DeckTemplate?, onSaveComplete: @escaping () -> Void = {}) {
        self.init(existingDeck: nil, template: template, onSaveComplete: onSaveComplete)
    }

    init(deck: Deck?) {
        self.init(existingDeck: deck)
    }

    var body: some View {
        Form {
            DeckCreationTipsView(deckType: .standard)
            deckDetailsSection
            languageSettingsSection
            entryModeSection
            cardEntrySection
            validationMessageSection
            currentCardsSection
            finalActionsSection
        }
        .navigationTitle(viewModel.isEditingExistingDeck ? "Edit Standard Deck" : "Standard Deck")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: prepareViewModel)
        .navigationDestination(isPresented: reviewNavigationBinding) {
            if let draftForReview {
                ReviewDeckView(deckDraft: draftForReview, onSaveComplete: onSaveComplete)
                    .environmentObject(deckStore)
            }
        }
        .navigationDestination(isPresented: bulkPreviewNavigationBinding) {
            if let bulkParseResult {
                BulkImportPreviewView(parseResult: bulkParseResult) { cards in
                    addBulkCards(cards)
                }
            }
        }
    }

    private var deckDetailsSection: some View {
        DeckMetadataFormView(
            title: $viewModel.deckDraft.title,
            description: $viewModel.deckDraft.deckDescription,
            category: deckCategoryBinding
        )
    }

    private var languageSettingsSection: some View {
        LanguageSelectionSectionView(
            frontLanguage: $viewModel.deckDraft.frontLanguage,
            backLanguage: $viewModel.deckDraft.backLanguage
        )
        .onChange(of: viewModel.deckDraft.frontLanguage) { _, newLanguage in
            viewModel.currentCardDraft.frontLanguage = newLanguage
        }
        .onChange(of: viewModel.deckDraft.backLanguage) { _, newLanguage in
            viewModel.currentCardDraft.backLanguage = newLanguage
        }
    }

    private var entryModeSection: some View {
        Section("Entry Mode") {
            Picker("Entry Mode", selection: $selectedEntryMode) {
                ForEach(CardEntryMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var cardEntrySection: some View {
        switch selectedEntryMode {
        case .manual:
            addCardSection
        case .bulkPaste:
            bulkPasteSection
        }
    }

    private var addCardSection: some View {
        Section("Add Card") {
            StandardCardEntryFormView(
                frontText: $viewModel.currentCardDraft.frontText,
                backText: $viewModel.currentCardDraft.backText,
                frontLanguage: viewModel.deckDraft.frontLanguage,
                backLanguage: viewModel.deckDraft.backLanguage,
                transliteration: cardTextBinding(\.transliteration),
                category: cardTextBinding(\.category),
                hintText: cardTextBinding(\.hintText),
                fillBlankText: cardTextBinding(\.fillBlankText),
                notes: cardTextBinding(\.notes),
                matchPrompt: cardTextBinding(\.matchPrompt),
                matchAnswer: cardTextBinding(\.matchAnswer),
                imageName: cardTextBinding(\.imageName),
                frontImageName: cardTextBinding(\.frontImageName),
                backImageName: cardTextBinding(\.backImageName),
                isAdvancedFieldsExpanded: $isAdvancedCardInfoExpanded,
                frontFieldFocus: $isFrontFieldFocused,
                showsFrontImageFields: true
            )

            Button("Add Front Image Later") {
                viewModel.currentCardDraft.frontImageName = viewModel.currentCardDraft.frontImageName ?? ""
            }
            .font(.footnote)

            Button("Add Back Image Later") {
                viewModel.currentCardDraft.backImageName = viewModel.currentCardDraft.backImageName ?? ""
            }
            .font(.footnote)

            Button("Add Card") {
                addCurrentCard(shouldRefocus: false)
            }

            Button("Add Card & Continue") {
                addCurrentCard(shouldRefocus: true)
            }

            Button("Clear Current Card", role: .cancel) {
                viewModel.resetCurrentCardDraft()
                viewModel.clearValidationMessage()
                successMessage = nil
            }
        }
    }

    private var bulkPasteSection: some View {
        BulkPasteCardEntryView(
            pastedText: $bulkPastedText,
            deckType: .standard,
            frontLanguage: viewModel.deckDraft.frontLanguage,
            backLanguage: viewModel.deckDraft.backLanguage
        ) { result in
            bulkParseResult = result
        }
    }

    @ViewBuilder
    private var validationMessageSection: some View {
        if let validationMessage = viewModel.validationMessage {
            Section("Needs Attention") {
                Label {
                    Text(validationMessage)
                        .font(.footnote)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } else if let successMessage {
            Section {
                Label {
                    Text(successMessage)
                        .font(.footnote)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
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
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.duplicateCard(id: cardDraft.id)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
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

    private var primaryActionTitle: String {
        viewModel.isEditingExistingDeck ? "Update Deck" : "Review Deck"
    }

    private var reviewNavigationBinding: Binding<Bool> {
        Binding(
            get: { draftForReview != nil },
            set: { isPresented in
                if !isPresented {
                    draftForReview = nil
                }
            }
        )
    }

    private var bulkPreviewNavigationBinding: Binding<Bool> {
        Binding(
            get: { bulkParseResult != nil },
            set: { isPresented in
                if !isPresented {
                    bulkParseResult = nil
                }
            }
        )
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
        } else if let template {
            viewModel.resetForTemplate(template)
            viewModel.updateDeckType(.standard)
        } else if let initialDeckDraft {
            viewModel.deckDraft = initialDeckDraft
            viewModel.updateDeckType(.standard)
            viewModel.resetCurrentCardDraft()
            viewModel.clearValidationMessage()
        } else {
            viewModel.resetForNewDeck(deckType: .standard)
        }

        didPrepareViewModel = true
    }

    private func addCurrentCard(shouldRefocus: Bool) {
        guard viewModel.addCurrentCard() else {
            successMessage = nil
            return
        }

        successMessage = "Card added."

        if shouldRefocus {
            focusFirstManualField()
        }
    }

    private func addBulkCards(_ cards: [Flashcard]) {
        viewModel.addBulkParsedCards(cards)

        if viewModel.validationMessage == nil {
            bulkPastedText = ""
            successMessage = "Card added."
        }
    }

    private func focusFirstManualField() {
        DispatchQueue.main.async {
            isFrontFieldFocused = true
        }
    }

    private func handlePrimaryAction() {
        if viewModel.isEditingExistingDeck {
            updateDeck()
        } else {
            reviewDeck()
        }
    }

    private func updateDeck() {
        guard viewModel.saveOrUpdateDeck(using: deckStore) else {
            return
        }

        dismiss()
    }

    private func reviewDeck() {
        guard viewModel.validateDeckForReview() else {
            return
        }

        draftForReview = viewModel.deckDraft
    }
}

private enum CardEntryMode: String, CaseIterable, Identifiable {
    case manual
    case bulkPaste

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .manual:
            return "Manual Entry"
        case .bulkPaste:
            return "Bulk Paste"
        }
    }
}

#Preview {
    NavigationStack {
        StandardDeckBuilderView()
            .environmentObject(DeckStore())
    }
}
