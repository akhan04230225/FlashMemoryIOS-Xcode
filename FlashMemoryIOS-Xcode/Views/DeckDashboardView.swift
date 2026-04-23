import SwiftUI

struct DeckDashboardView: View {
    @EnvironmentObject var deckStore: DeckStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                deckListSection
                    .frame(maxHeight: .infinity)

                createDeckSection
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Decks")
        }
    }

    private var deckListSection: some View {
        ScrollView {
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
                                DeckDetailView(deck: deck)
                            } label: {
                                DeckSummaryCardView(
                                    deck: deck,
                                    showsDisclosureIndicator: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
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
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    DeckDashboardView()
        .environmentObject(DeckStore())
}
