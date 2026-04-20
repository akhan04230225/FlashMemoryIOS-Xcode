import SwiftUI

struct DeckSummaryCardView: View {
    enum DisplayStyle {
        case compact
        case detailed
    }

    let deck: Deck
    var displayStyle: DisplayStyle = .compact
    var showsDisclosureIndicator: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: displayStyle == .compact ? 10 : 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(displayStyle == .compact ? 2 : nil)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(deck.deckType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(deck.cardCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(deck.cardCount == 1 ? "card" : "cards")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    if showsDisclosureIndicator {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if displayStyle == .detailed, !deck.deckDescription.trimmed.isEmpty {
                Text(deck.deckDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let category = deck.category?.trimmed, !category.isEmpty {
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
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
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 16) {
        DeckSummaryCardView(
            deck: Deck.sampleDecks[0],
            showsDisclosureIndicator: true
        )

        DeckSummaryCardView(
            deck: Deck.sampleDecks[0],
            displayStyle: .detailed
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
