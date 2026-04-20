import SwiftUI

struct DeckDashboardView: View {
    @EnvironmentObject var deckStore: DeckStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    deckListSection
                    createDeckSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Decks")
        }
    }

    private var deckListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Decks")
                .font(.largeTitle)
                .fontWeight(.bold)

            if deckStore.decks.isEmpty {
                emptyDeckState
            } else {
                VStack(spacing: 12) {
                    ForEach(deckStore.decks) { deck in
                        NavigationLink {
                            DeckDetailEditView(deck: deck)
                        } label: {
                            DeckDashboardRow(deck: deck)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyDeckState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No decks yet")
                .font(.headline)

            Text("Start a new deck when you are ready. Your saved decks will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var createDeckSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create a New Deck")
                .font(.title2)
                .fontWeight(.semibold)

            NavigationLink {
                DeckTypeSelectionView()
            } label: {
                Text("Start New Deck")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct DeckDashboardRow: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(deck.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(deck.deckType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(deck.cardCount)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(deck.cardCount == 1 ? "card" : "cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct DeckDetailEditView: View {
    let deck: Deck

    var body: some View {
        List {
            Section("Deck") {
                LabeledContent("Title", value: deck.title)
                LabeledContent("Type", value: deck.deckType.displayName)
                LabeledContent("Cards", value: "\(deck.cardCount)")
            }

            Section("Description") {
                Text(deck.deckDescription.isEmpty ? "No description yet." : deck.deckDescription)
                    .foregroundStyle(deck.deckDescription.isEmpty ? .secondary : .primary)
            }

            Section("Cards") {
                if deck.cards.isEmpty {
                    Text("No cards in this deck yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(deck.cards) { card in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.frontText)
                                .font(.headline)

                            Text(card.backText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(deck.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DeckDashboardView()
        .environmentObject(DeckStore())
}
