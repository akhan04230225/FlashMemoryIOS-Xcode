import SwiftUI

struct DeckTypeSelectionView: View {
    private let deckTypes: [DeckType] = [
        .standard,
        .lineMemorization,
        .mixed
    ]
    private let templates = DeckTemplateService.templates
    private let onDeckSaved: () -> Void

    init(onDeckSaved: @escaping () -> Void = {}) {
        self.onDeckSaved = onDeckSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Choose a deck type")
                    .font(.title2)
                    .fontWeight(.semibold)

                scratchSection
                templateSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Deck")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scratchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start from Scratch")
                .font(.headline)

            ForEach(deckTypes, id: \.self) { deckType in
                NavigationLink {
                    destinationView(for: deckType)
                } label: {
                    DeckTypeSelectionCard(deckType: deckType)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start from a Template")
                .font(.headline)

            ForEach(templates) { template in
                NavigationLink {
                    destinationView(for: template)
                } label: {
                    DeckTemplateSelectionCard(template: template)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for deckType: DeckType) -> some View {
        switch deckType {
        case .standard:
            StandardDeckBuilderView(onSaveComplete: onDeckSaved)
        case .lineMemorization:
            LineMemorizationDeckBuilderView(onSaveComplete: onDeckSaved)
        case .mixed:
            MixedDeckBuilderView(onSaveComplete: onDeckSaved)
        }
    }

    @ViewBuilder
    private func destinationView(for template: DeckTemplate) -> some View {
        switch template.deckType {
        case .standard:
            StandardDeckBuilderView(template: template, onSaveComplete: onDeckSaved)
        case .lineMemorization:
            LineMemorizationDeckBuilderView(template: template, onSaveComplete: onDeckSaved)
        case .mixed:
            MixedDeckBuilderView(template: template, onSaveComplete: onDeckSaved)
        }
    }
}

private struct DeckTemplateSelectionCard: View {
    let template: DeckTemplate

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(template.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(template.deckType.displayName)
                    Text(languagePairText)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private var languagePairText: String {
        "\(template.suggestedFrontLanguage.displayName) -> \(template.suggestedBackLanguage.displayName)"
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
