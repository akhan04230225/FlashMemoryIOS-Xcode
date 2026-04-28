import SwiftUI

struct LineMemorizationDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?

    @State private var didPrepareViewModel = false
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
            validationMessageSection
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
        .navigationDestination(isPresented: reviewNavigationBinding) {
            if let draftForReview {
                ReviewDeckView(deckDraft: draftForReview)
                    .environmentObject(deckStore)
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

    private var addLineSection: some View {
        Section("Add Line / Card") {
            LineMemorizationCardEntryFormView(
                frontText: $viewModel.currentCardDraft.frontText,
                backText: $viewModel.currentCardDraft.backText,
                frontLanguage: viewModel.deckDraft.frontLanguage,
                backLanguage: viewModel.deckDraft.backLanguage,
                transliteration: cardTextBinding(\.transliteration),
                sourceReference: cardTextBinding(\.sourceReference),
                notes: cardTextBinding(\.notes),
                lineOrder: $manualLineOrder,
                memorizationChunksText: $memorizationChunksText
            )

            Button("Add Line") {
                addCurrentLine()
            }

            Button("Clear Current Line", role: .cancel) {
                clearCurrentLine()
            }
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

        if viewModel.addCurrentCard() {
            syncAuxiliaryFieldsFromCurrentCard()
        }
    }

    private func clearCurrentLine() {
        viewModel.resetCurrentCardDraft()
        viewModel.clearValidationMessage()
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

#Preview {
    NavigationStack {
        LineMemorizationDeckBuilderView()
            .environmentObject(DeckStore())
    }
}
