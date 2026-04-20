import SwiftUI

struct CardPreviewRowView: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.frontText)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.backText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if hasMetadata {
                VStack(alignment: .leading, spacing: 6) {
                    if let category = card.category, !category.isEmpty {
                        metadataText("Category: \(category)")
                    }

                    if let sourceReference = card.sourceReference, !sourceReference.isEmpty {
                        metadataText("Source: \(sourceReference)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var hasMetadata: Bool {
        hasText(card.category) || hasText(card.sourceReference)
    }

    private func hasText(_ text: String?) -> Bool {
        guard let text else {
            return false
        }

        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func metadataText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    CardPreviewRowView(
        card: Flashcard(
            frontText: "What is the powerhouse of the cell?",
            backText: "The mitochondria. This answer can wrap gracefully if it becomes longer in a real study deck.",
            category: "Biology",
            sourceReference: "Chapter 2"
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
