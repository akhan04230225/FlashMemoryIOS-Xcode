import SwiftUI

struct DeckCreationChoiceView: View {
    let onDeckSaved: () -> Void

    init(onDeckSaved: @escaping () -> Void = {}) {
        self.onDeckSaved = onDeckSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                VStack(spacing: 14) {
                    NavigationLink {
                        DeckBuilderChatView()
                    } label: {
                        creationChoiceCard(
                            title: "AI Chat Builder",
                            description: "Paste or describe what you want to memorize, and the assistant will create a draft deck.",
                            systemImage: "sparkles"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        DeckTypeSelectionView(onDeckSaved: onDeckSaved)
                    } label: {
                        creationChoiceCard(
                            title: "Manual Builder",
                            description: "Choose a deck type and customize everything yourself.",
                            systemImage: "slider.horizontal.3"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Create New Deck")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create New Deck")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Choose how you want to build your deck.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func creationChoiceCard(
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DeckBuilderChatView: View {
    var body: some View {
        ContentUnavailableView(
            "AI Chat Builder",
            systemImage: "sparkles",
            description: Text("The AI chat builder screen is ready to be connected.")
        )
        .navigationTitle("AI Chat Builder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DeckCreationChoiceView()
    }
}
