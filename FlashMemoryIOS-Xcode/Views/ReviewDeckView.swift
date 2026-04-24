import SwiftUI
import UIKit

struct ReviewDeckView: View {
    @EnvironmentObject var deckStore: DeckStore
    @Environment(\.dismiss) private var dismiss

    let deckDraft: DeckDraft

    var body: some View {
        Form {
            deckSummarySection
            cardPreviewSection
            actionSection
        }
        .navigationTitle("Review Deck")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deckSummarySection: some View {
        Section("Deck Summary") {
            DeckSummaryCardView(
                deck: previewDeck,
                displayStyle: .detailed
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            reviewRow(label: "Front Language", value: deckDraft.frontLanguage.displayName)
            reviewRow(label: "Back Language", value: deckDraft.backLanguage.displayName)
            reviewRow(label: "Total Cards", value: "\(deckDraft.cardCount)")
        }
    }

    private var cardPreviewSection: some View {
        Section("Card Preview") {
            if deckDraft.cards.isEmpty {
                Text("No cards added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(deckDraft.cards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: deckDraft.deckType == .lineMemorization
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var actionSection: some View {
        Section("Actions") {
            Button("Edit Deck") {
                dismiss()
            }

            Button("Save Deck to Library") {
                saveDeckAndReturnToDashboard()
            }
        }
    }

    private var previewDeck: Deck {
        deckDraft.toDeck()
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

    private func saveDeckAndReturnToDashboard() {
        deckStore.addDeck(from: deckDraft)
        popToDeckDashboard()
    }

    private func popToDeckDashboard() {
        guard let navigationController = topNavigationController() else {
            dismiss()
            return
        }

        navigationController.popToRootViewController(animated: true)
    }

    private func topNavigationController(
        from controller: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UINavigationController? {
        if let navigationController = controller as? UINavigationController {
            return navigationController
        }

        for child in controller?.children ?? [] {
            if let navigationController = topNavigationController(from: child) {
                return navigationController
            }
        }

        if let presentedViewController = controller?.presentedViewController {
            return topNavigationController(from: presentedViewController)
        }

        return nil
    }
}

#Preview {
    NavigationStack {
        ReviewDeckView(
            deckDraft: DeckDraft(
                title: "Arabic Phrases",
                deckDescription: "Useful lines for daily memorization and review.",
                category: "Language",
                deckType: .lineMemorization,
                frontLanguage: .arabic,
                backLanguage: .english,
                cards: [
                    FlashcardDraft(
                        frontText: "السلام عليكم",
                        backText: "Peace be upon you",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        transliteration: "As-salamu alaykum",
                        lineOrder: 1,
                        memorizationChunks: ["السلام", "عليكم"]
                    ),
                    FlashcardDraft(
                        frontText: "كيف حالك؟",
                        backText: "How are you?",
                        frontLanguage: .arabic,
                        backLanguage: .english,
                        lineOrder: 2
                    )
                ]
            )
        )
        .environmentObject(DeckStore())
    }
}
