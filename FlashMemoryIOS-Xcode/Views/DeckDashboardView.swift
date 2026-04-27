import SwiftUI

struct DeckDashboardView: View {
    @EnvironmentObject var deckStore: DeckStore
    @State private var searchText = ""
    @State private var selectedDeckTypeFilter: DeckTypeFilter = .all

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

                searchField
                deckTypeFilterPicker

                if filteredDecks.isEmpty {
                    emptyDeckState
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredDecks) { deck in
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

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search decks by title", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var deckTypeFilterPicker: some View {
        Picker("Deck Type", selection: $selectedDeckTypeFilter) {
            ForEach(DeckTypeFilter.allCases, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var filteredDecks: [Deck] {
        deckStore.decks.filter { deck in
            matchesSelectedDeckType(deck) && matchesSearchText(deck)
        }
    }

    private func matchesSelectedDeckType(_ deck: Deck) -> Bool {
        switch selectedDeckTypeFilter {
        case .all:
            return true
        case .standard:
            return deck.deckType == .standard
        case .mixed:
            return deck.deckType == .mixed
        case .lineMemorization:
            return deck.deckType == .lineMemorization
        }
    }

    private func matchesSearchText(_ deck: Deck) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return true
        }

        return deck.title.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) != nil
    }

    private var emptyDeckState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emptyStateTitle)
                .font(.headline)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var emptyStateTitle: String {
        if deckStore.decks.isEmpty {
            return "No decks yet"
        }

        return "No matching decks"
    }

    private var emptyStateMessage: String {
        if deckStore.decks.isEmpty {
            return "Start a new deck when you are ready. Your saved decks will appear here."
        }

        return "Try a different title search or deck type filter."
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

private enum DeckTypeFilter: CaseIterable {
    case all
    case standard
    case mixed
    case lineMemorization

    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .standard:
            return "Standard"
        case .mixed:
            return "Mixed"
        case .lineMemorization:
            return "Lines"
        }
    }
}

#Preview {
    DeckDashboardView()
        .environmentObject(DeckStore())
}
