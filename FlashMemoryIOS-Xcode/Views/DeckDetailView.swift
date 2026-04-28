import SwiftUI

struct DeckDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore

    let deck: Deck

    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingEditDeck = false

    private var currentDeck: Deck {
        deckStore.deck(with: deck.id) ?? deck
    }

    var body: some View {
        List {
            Section {
                DeckSummaryCardView(
                    deck: currentDeck,
                    displayStyle: .detailed
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            deckSummarySection
            cardsPreviewSection
            actionsSection
        }
        .navigationTitle(currentDeck.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingEditDeck) {
            editDestinationView(for: currentDeck)
                .environmentObject(deckStore)
        }
        .alert("Delete Deck", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteDeck()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove this deck from your saved decks.")
        }
    }

    private var deckSummarySection: some View {
        Section("Deck Summary") {
            LabeledContent("Title", value: currentDeck.title)
            LabeledContent("Deck Type", value: currentDeck.deckType.displayName)

            if currentDeck.deckDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                LabeledContent("Description", value: "No description")
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(currentDeck.deckDescription)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }

            LabeledContent("Category", value: currentDeck.categoryDisplayValue)
            LabeledContent("Front Language", value: currentDeck.frontLanguage.displayName)
            LabeledContent("Back Language", value: currentDeck.backLanguage.displayName)
            LabeledContent("Total Cards", value: "\(currentDeck.cardCount)")
        }
    }

    private var cardsPreviewSection: some View {
        Section("Cards Preview") {
            if currentDeck.cards.isEmpty {
                Text("No cards in this deck yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(currentDeck.cards) { card in
                    CardPreviewRowView(
                        card: card,
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: currentDeck.deckType == .lineMemorization
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button("Edit Deck") {
                isShowingEditDeck = true
            }

            Button("Duplicate Deck") {
                duplicateDeck()
            }

            Button("Delete Deck", role: .destructive) {
                isShowingDeleteConfirmation = true
            }
        }
    }

    @ViewBuilder
    private func editDestinationView(for deck: Deck) -> some View {
        switch deck.deckType {
        case .standard:
            StandardDeckBuilderView(deck: deck)
        case .lineMemorization:
            LineMemorizationDeckBuilderView(deck: deck)
        case .mixed:
            MixedDeckBuilderView(deck: deck)
        }
    }

    private func deleteDeck() {
        _ = deckStore.deleteDeck(id: currentDeck.id)
        dismiss()
    }

    private func duplicateDeck() {
        _ = deckStore.duplicateDeck(id: currentDeck.id)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck.sampleDecks[0])
            .environmentObject(DeckStore())
    }
}

private extension Deck {
    var categoryDisplayValue: String {
        guard let category, !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "None"
        }

        return category
    }
}
