import SwiftUI

struct DeckBuilderChatView: View {
    private let onDeckSaved: () -> Void

    @State private var userText = ""
    @State private var validationMessage: String?
    @State private var generatedDraft: DeckDraft?
    @State private var generatedIntent: DeckBuildIntent?
    @State private var skippedLines: [String] = []

    init(onDeckSaved: @escaping () -> Void = {}) {
        self.onDeckSaved = onDeckSaved
    }

    var body: some View {
        Form {
            introSection
            examplePromptsSection
            inputSection
            validationSection
            actionSection
        }
        .navigationTitle("AI Chat Builder")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: draftPreviewNavigationBinding) {
            if let generatedDraft, let generatedIntent {
                DeckDraftPreviewView(
                    deckDraft: generatedDraft,
                    intent: generatedIntent,
                    skippedLines: skippedLines,
                    onDeckSaved: onDeckSaved
                )
            }
        }
    }

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Chat Builder")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Paste or describe what you want to memorize. The assistant will create a draft deck.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    private var examplePromptsSection: some View {
        Section("Example Prompts") {
            examplePromptButton("Make an Urdu to English vocabulary deck")
            examplePromptButton("Turn this Quran passage into a line memorization deck")
            examplePromptButton("Create flashcards from these biology notes")
        }
    }

    private var inputSection: some View {
        Section("Your Content") {
            ZStack(alignment: .topLeading) {
                if userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Paste vocabulary, notes, a passage, or describe the deck you want.")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $userText)
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    @ViewBuilder
    private var validationSection: some View {
        if let validationMessage {
            Section {
                Label {
                    Text(validationMessage)
                        .font(.footnote)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button("Generate Deck Draft") {
                generateDeckDraft()
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Switch to Manual Builder") {
                DeckTypeSelectionView(onDeckSaved: onDeckSaved)
            }
        }
    }

    private func examplePromptButton(_ prompt: String) -> some View {
        Button {
            userText = prompt
            validationMessage = nil
        } label: {
            Text(prompt)
                .foregroundStyle(.primary)
        }
    }

    private var draftPreviewNavigationBinding: Binding<Bool> {
        Binding(
            get: {
                generatedDraft != nil && generatedIntent != nil
            },
            set: { isShowing in
                if !isShowing {
                    generatedDraft = nil
                    generatedIntent = nil
                    skippedLines = []
                }
            }
        )
    }

    private func generateDeckDraft() {
        let trimmedText = userText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            validationMessage = "Paste or type what you want to memorize first."
            return
        }

        let result = DeckChatAssistantService.generateDeckDraft(from: trimmedText)
        generatedDraft = result.draft
        generatedIntent = result.intent
        skippedLines = result.skippedLines
        validationMessage = nil
    }
}

#Preview {
    NavigationStack {
        DeckBuilderChatView()
    }
}
