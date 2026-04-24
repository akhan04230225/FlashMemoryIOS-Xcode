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
