import SwiftUI

struct BulkImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let parseResult: BulkCardParseResult
    let onConfirm: ([Flashcard]) -> Void

    var body: some View {
        List {
            summarySection
            parsedCardsSection
            skippedLinesSection
            actionSection
        }
        .navigationTitle("Preview Imported Cards")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summarySection: some View {
        Section {
            LabeledContent("Parsed Cards", value: "\(parseResult.parsedCards.count)")
        }
    }

    private var parsedCardsSection: some View {
        Section("Cards to Add") {
            if parseResult.parsedCards.isEmpty {
                Text("No cards were found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(parseResult.parsedCards) { card in
                    CardPreviewRowView(
                        card: card,
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: card.lineOrder != nil
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
    }

    @ViewBuilder
    private var skippedLinesSection: some View {
        if !parseResult.skippedLines.isEmpty {
            Section("Skipped Lines") {
                ForEach(parseResult.skippedLines, id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button("Add These Cards") {
                onConfirm(parseResult.parsedCards)
                dismiss()
            }
            .disabled(parseResult.parsedCards.isEmpty)

            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        BulkImportPreviewView(
            parseResult: BulkCardParseResult(
                parsedCards: [
                    Flashcard(
                        frontText: "apple",
                        backText: "سیب",
                        frontLanguage: .english,
                        backLanguage: .urdu
                    ),
                    Flashcard(
                        frontText: "book",
                        backText: "کتاب",
                        frontLanguage: .english,
                        backLanguage: .urdu
                    )
                ],
                skippedLines: ["not a card"],
                errorMessage: nil
            )
        ) { _ in }
    }
}
