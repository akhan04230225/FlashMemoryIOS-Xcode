import Combine
import SwiftUI

struct DeckDashboardView: View {
    @EnvironmentObject var deckStore: DeckStore
    @StateObject private var viewModel = DeckDashboardViewModel()
    @State private var isShowingDeckCreationChoice = false
    @State private var isSelectingDecks = false
    @State private var selectedDeckIDs: Set<UUID> = []
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            deckListSection
                .frame(maxHeight: .infinity)

            createDeckSection
        }
        .onAppear {
            let text1 = "apple book house"
            let text2 = "استقلال مبالغہ"
            let text3 = "الحمد لله رب العالمين"
            let text4 = "hola como estas"
            let text5 = "apple سیب"

            print("Text1:", LanguageDetectionService.detectPrimaryLanguage(from: text1))
            print("Text2:", LanguageDetectionService.detectPrimaryLanguage(from: text2))
            print("Text3:", LanguageDetectionService.detectPrimaryLanguage(from: text3))
            print("Text4:", LanguageDetectionService.detectPrimaryLanguage(from: text4))
            print("Text5:", LanguageDetectionService.detectPrimaryLanguage(from: text5))
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Decks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                selectionModeButton
            }
        }
        .navigationDestination(isPresented: $isShowingDeckCreationChoice) {
            DeckCreationChoiceView {
                returnToDashboardAfterSavingDeck()
            }
        }
        .confirmationDialog(
            "Delete selected decks?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(deleteConfirmationButtonTitle, role: .destructive) {
                deleteSelectedDecks()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
        .onAppear {
            viewModel.updateVisibleDecks(from: deckStore.decks)
        }
        .onChange(of: deckStore.decks) { _, newDecks in
            viewModel.updateVisibleDecks(from: newDecks)
            removeSelectionsForDeletedDecks(from: newDecks)
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.updateVisibleDecks(from: deckStore.decks)
        }
        .onChange(of: viewModel.selectedDeckTypeFilter) { _, _ in
            viewModel.updateVisibleDecks(from: deckStore.decks)
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
                selectionStatusSection

                if viewModel.visibleDecks.isEmpty {
                    emptyDeckState
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.visibleDecks) { deck in
                            deckRow(for: deck)
                        }
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var selectionModeButton: some View {
        if deckStore.decks.isEmpty {
            EmptyView()
        } else if isSelectingDecks {
            Button("Done") {
                endSelectionMode()
            }
        } else {
            Button("Select") {
                isSelectingDecks = true
            }
        }
    }

    @ViewBuilder
    private var selectionStatusSection: some View {
        if isSelectingDecks {
            HStack(spacing: 12) {
                Text(selectionStatusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") {
                    selectedDeckIDs.removeAll()
                }
                .disabled(selectedDeckIDs.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func deckRow(for deck: Deck) -> some View {
        if isSelectingDecks {
            Button {
                toggleDeckSelection(deck.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedDeckIDs.contains(deck.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedDeckIDs.contains(deck.id) ? Color.accentColor : .secondary)

                    DeckSummaryCardView(deck: deck)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selectionAccessibilityLabel(for: deck))
        } else {
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

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search decks by title", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
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
        Picker("Deck Type", selection: $viewModel.selectedDeckTypeFilter) {
            ForEach(DeckTypeFilter.allCases, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
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

            Button {
                isShowingDeckCreationChoice = true
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

            if isSelectingDecks {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Text(deleteSelectedButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedDeckIDs.isEmpty ? Color.gray.opacity(0.25) : Color.red)
                        .foregroundStyle(selectedDeckIDs.isEmpty ? Color.secondary : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(selectedDeckIDs.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private func returnToDashboardAfterSavingDeck() {
        isShowingDeckCreationChoice = false
    }

    private var selectionStatusText: String {
        if selectedDeckIDs.isEmpty {
            return "Select decks to delete."
        }

        return "\(selectedDeckIDs.count) selected"
    }

    private var deleteSelectedButtonTitle: String {
        if selectedDeckIDs.count == 1 {
            return "Delete Selected Deck"
        }

        return "Delete Selected Decks"
    }

    private var deleteConfirmationButtonTitle: String {
        if selectedDeckIDs.count == 1 {
            return "Delete 1 Deck"
        }

        return "Delete \(selectedDeckIDs.count) Decks"
    }

    private var deleteConfirmationMessage: String {
        if selectedDeckIDs.count == 1 {
            return "This deck and its cards will be permanently deleted."
        }

        return "These decks and their cards will be permanently deleted."
    }

    private func toggleDeckSelection(_ deckID: UUID) {
        if selectedDeckIDs.contains(deckID) {
            selectedDeckIDs.remove(deckID)
        } else {
            selectedDeckIDs.insert(deckID)
        }
    }

    private func endSelectionMode() {
        isSelectingDecks = false
        selectedDeckIDs.removeAll()
    }

    private func deleteSelectedDecks() {
        deckStore.deleteDecks(ids: selectedDeckIDs)
        endSelectionMode()
    }

    private func removeSelectionsForDeletedDecks(from decks: [Deck]) {
        let existingDeckIDs = Set(decks.map(\.id))
        selectedDeckIDs = selectedDeckIDs.intersection(existingDeckIDs)

        if decks.isEmpty {
            endSelectionMode()
        }
    }

    private func selectionAccessibilityLabel(for deck: Deck) -> String {
        if selectedDeckIDs.contains(deck.id) {
            return "\(deck.title), selected"
        }

        return "\(deck.title), not selected"
    }
}

@MainActor
private final class DeckDashboardViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedDeckTypeFilter: DeckTypeFilter = .all
    @Published private(set) var visibleDecks: [Deck] = []

    func updateVisibleDecks(from decks: [Deck]) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        visibleDecks = decks.filter { deck in
            matchesSelectedDeckType(deck) && matchesSearchText(deck, query: query)
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

    private func matchesSearchText(_ deck: Deck, query: String) -> Bool {
        guard !query.isEmpty else {
            return true
        }

        return deck.title.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) != nil
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
