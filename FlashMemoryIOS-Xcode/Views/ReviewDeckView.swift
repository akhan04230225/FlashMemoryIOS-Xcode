import SwiftUI

struct ReviewDeckView: View {
    @EnvironmentObject var deckStore: DeckStore
    @Environment(\.dismiss) private var dismiss

    let deckDraft: DeckDraft
    private let previewDeck: Deck
    private let onSaveComplete: () -> Void

    @State private var validationMessage: String?

    init(deckDraft: DeckDraft, onSaveComplete: @escaping () -> Void = {}) {
        self.deckDraft = deckDraft
        self.previewDeck = deckDraft.toDeck()
        self.onSaveComplete = onSaveComplete
    }

    var body: some View {
        Form {
            deckSummarySection
            cardPreviewSection
            validationMessageSection
            actionSection
        }
        .navigationTitle("Review Deck")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deckSummarySection: some View {
        Section("Deck Summary") {
            DeckSummaryCardView(
                deck: previewDeck,
                displayStyle: .detailed
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            reviewRow(label: "Front Language", value: deckDraft.frontLanguage.displayName)
            reviewRow(label: "Back Language", value: deckDraft.backLanguage.displayName)
            reviewRow(label: "Total Cards", value: "\(deckDraft.cardCount)")
        }
    }

    private var cardPreviewSection: some View {
        Section("Card Preview") {
            if deckDraft.cards.isEmpty {
                Text("No cards added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(deckDraft.cards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: deckDraft.deckType == .lineMemorization
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    @ViewBuilder
    private var validationMessageSection: some View {
        if let validationMessage {
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

    private var actionSection: some View {
        Section("Actions") {
            Button("Edit Deck") {
                dismiss()
            }

            Button("Save Deck to Library") {
                saveDeckAndReturnToDashboard()
            }
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func saveDeckAndReturnToDashboard() {
        if let saveError = DeckValidationService.validateDeckCanSave(
            title: deckDraft.title,
            cardCount: deckDraft.cardCount
        ) {
            validationMessage = friendlySaveErrorText(for: saveError)
            return
        }

        deckStore.addDeck(from: deckDraft)
        validationMessage = nil
        onSaveComplete()
    }

    private func friendlySaveErrorText(for error: String) -> String {
        if error == "Deck title is required." {
            return "Give your deck a title before saving it."
        }

        if error == "Add at least 2 cards before saving the deck." {
            return "Add at least 2 \(cardItemName) before saving your deck."
        }

        return error
    }

    private var cardItemName: String {
        deckDraft.deckType == .lineMemorization ? "lines" : "cards"
    }
}

#Preview {
    NavigationStack {
        ReviewDeckView(
            deckDraft: DeckDraft(
                title: "Arabic Phrases",
                deckDescription: "Useful lines for daily memorization and review.",
                category: "Language",
                deckType: .lineMemorization,
                frontLanguage: .arabic,
                backLanguage: .english,
                cards: [
                    FlashcardDraft(
                        frontText: "السلام عليكم",
                        backText: "Peace be upon you",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        transliteration: "As-salamu alaykum",
                        lineOrder: 1,
                        memorizationChunks: ["السلام", "عليكم"]
                    ),
                    FlashcardDraft(
                        frontText: "كيف حالك؟",
                        backText: "How are you?",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        lineOrder: 2
                    )
                ]
            )
        )
        .environmentObject(DeckStore())
    }
}
