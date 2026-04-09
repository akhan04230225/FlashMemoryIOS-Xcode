import SwiftUI

struct DeckListView: View {
    let sampleDecks = [
        Deck(title: "Biology", cardCount: 12),
        Deck(title: "Arabic Vocabulary", cardCount: 18),
        Deck(title: "Chemistry", cardCount: 10)
    ]

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
