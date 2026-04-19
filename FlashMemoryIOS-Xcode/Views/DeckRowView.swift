import SwiftUI

struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deck.title)
                .font(.headline)

            Text("\(deck.cardCount) cards")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        DeckRowView(deck: Deck.sampleDecks[0])
    }
}
