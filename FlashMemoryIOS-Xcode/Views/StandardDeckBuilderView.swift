import SwiftUI

struct StandardDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let deckToEdit: Deck?

    @State private var didPrepareViewModel = false
    @State private var isAdvancedCardInfoExpanded = false
    @State private var isShowingReviewDeck = false
    @State private var draftForReview: DeckDraft?

    init(deck: Deck? = nil) {
        self.deckToEdit = deck
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
            TextField("Description", text: $viewModel.deckDraft.deckDescription, axis: .vertical)
                .lineLimit(3...5)
            TextField("Category", text: deckCategoryBinding)
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
            TextField("Front Text", text: $viewModel.currentCardDraft.frontText, axis: .vertical)
                .lineLimit(2...5)

            TextField("Back Text", text: $viewModel.currentCardDraft.backText, axis: .vertical)
                .lineLimit(2...5)

            DisclosureGroup("Advanced Fields", isExpanded: $isAdvancedCardInfoExpanded) {
                TextField("Transliteration", text: cardTextBinding(\.transliteration))
                TextField("Category", text: cardTextBinding(\.category))
                TextField("Hint", text: cardTextBinding(\.hintText))
                TextField("Fill in the Blank", text: cardTextBinding(\.fillBlankText), axis: .vertical)
                    .lineLimit(2...4)
                TextField("Notes", text: cardTextBinding(\.notes), axis: .vertical)
                    .lineLimit(2...5)
                TextField("Match Prompt", text: cardTextBinding(\.matchPrompt), axis: .vertical)
                    .lineLimit(2...4)
                TextField("Match Answer", text: cardTextBinding(\.matchAnswer), axis: .vertical)
                    .lineLimit(2...4)
                TextField("Image Name", text: cardTextBinding(\.imageName))
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
            Button("Review Deck") {
                reviewDeck()
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

        if let deckToEdit {
            viewModel.loadDeckForEditing(deckToEdit)
            viewModel.updateDeckType(.standard)
        } else {
            viewModel.resetForNewDeck(deckType: .standard)
        }

        didPrepareViewModel = true
    }

    private func addCurrentCard() {
        viewModel.validationMessage = DeckValidationService.validateCard(
            frontText: viewModel.currentCardDraft.frontText,
            backText: viewModel.currentCardDraft.backText,
            deckType: .standard
        )

        guard viewModel.validationMessage == nil else {
            return
        }

        viewModel.addCurrentCard()
    }

    private func reviewDeck() {
        viewModel.validationMessage = DeckValidationService.validateDeckCanSave(
            title: viewModel.deckDraft.title,
            cardCount: viewModel.deckDraft.cardCount
        )

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
