import SwiftUI

struct StandardDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?

    @State private var didPrepareViewModel = false
    @State private var isAdvancedCardInfoExpanded = false
    @State private var selectedEntryMode: CardEntryMode = .manual
    @State private var bulkPastedText = ""
    @State private var bulkParseResult: BulkCardParseResult?
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
                ReviewDeckView(deckDraft: draftForReview)
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
                addCurrentCard()
            }

            Button("Clear Current Card", role: .cancel) {
                viewModel.resetCurrentCardDraft()
                viewModel.clearValidationMessage()
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
        } else {
            viewModel.resetForNewDeck(deckType: .standard)
        }

        didPrepareViewModel = true
    }

    private func addCurrentCard() {
        _ = viewModel.addCurrentCard()
    }

    private func addBulkCards(_ cards: [Flashcard]) {
        viewModel.addBulkParsedCards(cards)

        if viewModel.validationMessage == nil {
            bulkPastedText = ""
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
