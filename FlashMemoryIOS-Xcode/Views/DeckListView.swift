import SwiftUI

struct DeckListView: View {
    let sampleDecks = Deck.sampleDecks

    var body: some View {
        List(sampleDecks) { deck in
            DeckRowView(deck: deck)
        }
        .navigationTitle("Decks")
    }
}

#Preview {
    NavigationStack {
        DeckListView()
    }
}
