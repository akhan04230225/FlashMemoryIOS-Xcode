import SwiftUI

struct CardPreviewRowView: View {
    enum DisplayStyle {
        case compact
        case detailed
    }

    let card: Flashcard
    var displayStyle: DisplayStyle = .compact
    var showsLanguages: Bool = false
    var showsMetadata: Bool = true
    var showsLineOrder: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: displayStyle == .compact ? 10 : 14) {
            if showsLineOrder, let lineOrder = card.lineOrder {
                Text("Line \(lineOrder)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if !card.frontText.trimmed.isEmpty {
                cardText(
                    title: "Front",
                    text: card.frontText,
                    language: card.frontLanguage,
                    font: .headline,
                    color: .primary
                )
            }

            if hasText(card.frontImageName) {
                imageIndicator("Front Image Attached")
            }

            if !card.backText.trimmed.isEmpty {
                cardText(
                    title: "Back",
                    text: card.backText,
                    language: card.backLanguage,
                    font: .subheadline,
                    color: .secondary
                )
            }

            if hasText(card.backImageName) {
                imageIndicator("Back Image Attached")
            }

            if displayStyle == .detailed, let transliteration = card.transliteration?.trimmed, !transliteration.isEmpty {
                metadataText("Transliteration: \(transliteration)")
            }

            if showsMetadata, hasMetadata {
                metadataStack
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var hasMetadata: Bool {
        hasText(card.category)
            || hasText(card.sourceReference)
            || hasText(card.imageName)
            || (displayStyle == .detailed && detailedMetadataItems.isEmpty == false)
    }

    private var metadataStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let category = card.category?.trimmed, !category.isEmpty {
                metadataText("Category: \(category)")
            }

            if let sourceReference = card.sourceReference?.trimmed, !sourceReference.isEmpty {
                metadataText("Source: \(sourceReference)")
            }

            if let imageName = card.imageName?.trimmed, !imageName.isEmpty {
                metadataText("Image: \(imageName)")
            }

            if displayStyle == .detailed {
                ForEach(detailedMetadataItems, id: \.self) { item in
                    metadataText(item)
                }
            }
        }
    }

    private var detailedMetadataItems: [String] {
        var items: [String] = []

        if let hintText = card.hintText?.trimmed, !hintText.isEmpty {
            items.append("Hint: \(hintText)")
        }

        if let notes = card.notes?.trimmed, !notes.isEmpty {
            items.append("Notes: \(notes)")
        }

        if !card.memorizationChunks.isEmpty {
            items.append("\(card.memorizationChunks.count) memorization chunks")
        }

        return items
    }

    private func hasText(_ text: String?) -> Bool {
        guard let text else {
            return false
        }

        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func cardText(
        title: String,
        text: String,
        language: AppLanguage,
        font: Font,
        color: Color
    ) -> some View {
        VStack(alignment: language.isRightToLeft ? .trailing : .leading, spacing: 4) {
            if showsLanguages {
                Text("\(title) • \(language.displayName)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Text(text.trimmed)
                .font(font)
                .foregroundStyle(color)
                .multilineTextAlignment(language.isRightToLeft ? .trailing : .leading)
                .lineLimit(displayStyle == .compact ? 4 : nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: language.isRightToLeft ? .trailing : .leading)
    }

    private func metadataText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(displayStyle == .compact ? 2 : nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func imageIndicator(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 16) {
        CardPreviewRowView(
            card: Flashcard(
                frontText: "What is the powerhouse of the cell?",
                backText: "The mitochondria. This answer can wrap gracefully if it becomes longer in a real study deck.",
                category: "Biology",
                sourceReference: "Chapter 2"
            )
        )

        CardPreviewRowView(
            card: Flashcard(
                frontText: "السلام عليكم ورحمة الله وبركاته",
                backText: "Peace and mercy of Allah be upon you.",
                frontLanguage: .arabic,
                backLanguage: .english,
                transliteration: "As-salamu alaykum wa rahmatullahi wa barakatuh",
                category: "Arabic",
                hintText: "Common greeting",
                notes: "Used when greeting someone.",
                sourceReference: "Phrase list",
                lineOrder: 1,
                memorizationChunks: ["السلام عليكم", "ورحمة الله", "وبركاته"]
            ),
            displayStyle: .detailed,
            showsLanguages: true
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
