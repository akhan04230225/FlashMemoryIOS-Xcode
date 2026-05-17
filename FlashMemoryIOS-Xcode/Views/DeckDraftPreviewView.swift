import SwiftUI

struct DeckDraftPreviewView: View {
    let deckDraft: DeckDraft
    let intent: DeckBuildIntent
    let skippedLines: [String]
    let onDeckSaved: () -> Void

    init(
        deckDraft: DeckDraft,
        intent: DeckBuildIntent,
        skippedLines: [String],
        onDeckSaved: @escaping () -> Void = {}
    ) {
        self.deckDraft = deckDraft
        self.intent = intent
        self.skippedLines = skippedLines
        self.onDeckSaved = onDeckSaved
    }

    var body: some View {
        Form {
            summarySection
            intentSection
            cardPreviewSection
            skippedLinesSection
            actionSection
        }
        .navigationTitle("Draft Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summarySection: some View {
        Section("Draft Deck") {
            reviewRow(label: "Title", value: deckDraft.title)
            reviewRow(label: "Type", value: deckDraft.deckType.displayName)
            reviewRow(label: "Front Language", value: deckDraft.frontLanguage.displayName)
            reviewRow(label: "Back Language", value: deckDraft.backLanguage.displayName)
            reviewRow(label: "Cards", value: "\(deckDraft.cardCount)")
        }
    }

    private var intentSection: some View {
        Section("Assistant Guess") {
            Text(intent.explanation)
                .foregroundStyle(.secondary)

            reviewRow(
                label: "Confidence",
                value: "\(Int(intent.confidence * 100))%"
            )
        }
    }

    private var cardPreviewSection: some View {
        Section("Generated Cards") {
            if deckDraft.cards.isEmpty {
                Text("No cards were created yet. You can go back and add more structured text.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(deckDraft.cards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .compact,
                        showsLanguages: true,
                        showsMetadata: false,
                        showsLineOrder: deckDraft.deckType == .lineMemorization
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    @ViewBuilder
    private var skippedLinesSection: some View {
        if !skippedLines.isEmpty {
            Section("Skipped Lines") {
                ForEach(skippedLines, id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            NavigationLink("Review Deck") {
                ReviewDeckView(
                    deckDraft: deckDraft,
                    onSaveComplete: onDeckSaved
                )
            }

            NavigationLink("Edit Draft Manually") {
                manualBuilderView
            }
        }
    }

    @ViewBuilder
    private var manualBuilderView: some View {
        switch deckDraft.deckType {
        case .standard:
            StandardDeckBuilderView(
                initialDeckDraft: deckDraft,
                onSaveComplete: onDeckSaved
            )
        case .lineMemorization:
            LineMemorizationDeckBuilderView(
                initialDeckDraft: deckDraft,
                onSaveComplete: onDeckSaved
            )
        case .mixed:
            MixedDeckBuilderView(
                initialDeckDraft: deckDraft,
                onSaveComplete: onDeckSaved
            )
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        DeckDraftPreviewView(
            deckDraft: DeckDraft(
                title: "Urdu Vocabulary Deck",
                deckType: .standard,
                frontLanguage: .english,
                backLanguage: .urdu,
                cards: [
                    Flashcard(frontText: "apple", backText: "سیب", backLanguage: .urdu),
                    Flashcard(frontText: "book", backText: "کتاب", backLanguage: .urdu)
                ]
            ),
            intent: DeckBuildIntent(
                detectedDeckType: .standard,
                frontLanguage: .english,
                backLanguage: .urdu,
                confidence: 0.9,
                explanation: "This looks like a standard flashcard deck with front and back prompts.",
                suggestedTitle: "Urdu Vocabulary Deck"
            ),
            skippedLines: []
        )
        .environmentObject(DeckStore())
    }
}
