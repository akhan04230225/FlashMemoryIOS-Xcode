import SwiftUI

struct DeckTypeSelectionView: View {
    private let deckTypes: [DeckType] = [
        .standard,
        .lineMemorization,
        .mixed
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose a deck type")
                    .font(.title2)
                    .fontWeight(.semibold)

                ForEach(deckTypes, id: \.self) { deckType in
                    NavigationLink {
                        destinationView(for: deckType)
                    } label: {
                        DeckTypeSelectionCard(deckType: deckType)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Deck")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func destinationView(for deckType: DeckType) -> some View {
        switch deckType {
        case .standard:
            StandardDeckBuilderView()
        case .lineMemorization:
            LineMemorizationDeckBuilderView()
        case .mixed:
            MixedDeckBuilderView()
        }
    }
}

private struct DeckTypeSelectionCard: View {
    let deckType: DeckType

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(deckType.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(deckType.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        DeckTypeSelectionView()
    }
}
