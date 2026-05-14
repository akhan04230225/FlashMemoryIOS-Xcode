import SwiftUI

struct DeckCreationTipsView: View {
    let deckType: DeckType

    @State private var isExpanded = false

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        Label {
                            Text(tip)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .padding(.top, 6)
            } label: {
                Label("Creation Tips", systemImage: "lightbulb")
                    .font(.headline)
            }
        }
    }

    private var tips: [String] {
        switch deckType {
        case .standard:
            return [
                "Use Front | Back in bulk paste to add cards quickly.",
                "Add transliteration for Urdu or Arabic decks."
            ]
        case .lineMemorization:
            return [
                "Paste multiple lines at once to create ordered memorization cards.",
                "Use chunks for difficult verses or long passages."
            ]
        case .mixed:
            return [
                "Use categories so interleaving can work better later.",
                "Bulk paste helps you create large review sets quickly."
            ]
        }
    }
}

#Preview {
    Form {
        DeckCreationTipsView(deckType: .standard)
        DeckCreationTipsView(deckType: .lineMemorization)
        DeckCreationTipsView(deckType: .mixed)
    }
}
