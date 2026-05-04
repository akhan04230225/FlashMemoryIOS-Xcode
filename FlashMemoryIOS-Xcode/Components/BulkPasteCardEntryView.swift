import SwiftUI

struct BulkPasteCardEntryView: View {
    @Binding var pastedText: String

    let deckType: DeckType
    let frontLanguage: AppLanguage
    let backLanguage: AppLanguage
    let onPreview: (BulkCardParseResult) -> Void

    var body: some View {
        Section("Bulk Add Cards") {
            TextEditor(text: $pastedText)
                .frame(minHeight: 140)
                .font(AppFont.font(for: frontLanguage, size: 16))
                .languageTextDirection(frontLanguage)
                .overlay(alignment: .topLeading) {
                    if pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Paste cards here")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            helperText

            Button("Preview Cards") {
                previewCards()
            }

            Button("Clear", role: .cancel) {
                pastedText = ""
            }
        }
    }

    private var helperText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Accepted formats:")
                .fontWeight(.medium)

            Text("Front | Back")
            Text("Front - Back")
            Text("Front : Back")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func previewCards() {
        let result: BulkCardParseResult

        if deckType == .lineMemorization {
            result = BulkCardParserService.parseLineMemorizationCards(
                from: pastedText,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            )
        } else {
            result = BulkCardParserService.parseStandardCards(
                from: pastedText,
                frontLanguage: frontLanguage,
                backLanguage: backLanguage
            )
        }

        onPreview(result)
    }
}

#Preview {
    Form {
        BulkPasteCardEntryView(
            pastedText: .constant("apple | سیب\nbook | کتاب"),
            deckType: .standard,
            frontLanguage: .english,
            backLanguage: .urdu
        ) { _ in }
    }
}
