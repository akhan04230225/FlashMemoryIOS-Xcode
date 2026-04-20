import SwiftUI

struct DeckSummaryCardView: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
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
            }

            if let category = deck.category, !category.isEmpty {
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    DeckSummaryCardView(deck: Deck.sampleDecks[0])
        .padding()
        .background(Color(.systemGroupedBackground))
}
