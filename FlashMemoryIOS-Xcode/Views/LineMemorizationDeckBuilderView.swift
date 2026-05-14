import SwiftUI

struct LineMemorizationDeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckStore: DeckStore
    @StateObject var viewModel = DeckBuilderViewModel()

    private let existingDeck: Deck?
    private let initialDeckDraft: DeckDraft?
    private let template: DeckTemplate?
    private let onSaveComplete: () -> Void

    @State private var didPrepareViewModel = false
    @State private var draftForReview: DeckDraft?
    @State private var selectedEntryMode: LineEntryMode = .manual
    @State private var bulkPastedText = ""
    @State private var bulkParseResult: BulkCardParseResult?
    @State private var selectedSplitMethod: LineMemorizationSplitMethod = .lineBreak
    @State private var customDelimiter = ""
    @State private var memorizationChunksText = ""
    @State private var manualLineOrder = ""
    @State private var successMessage: String?
    @FocusState private var isFrontFieldFocused: Bool

    init(
        existingDeck: Deck? = nil,
        initialDeckDraft: DeckDraft? = nil,
        template: DeckTemplate? = nil,
        onSaveComplete: @escaping () -> Void = {}
    ) {
        self.existingDeck = existingDeck
        self.initialDeckDraft = initialDeckDraft
        self.template = template
        self.onSaveComplete = onSaveComplete
    }

    init(initialDeckDraft: DeckDraft, onSaveComplete: @escaping () -> Void = {}) {
        self.init(existingDeck: nil, initialDeckDraft: initialDeckDraft, onSaveComplete: onSaveComplete)
    }

    init(template: DeckTemplate?, onSaveComplete: @escaping () -> Void = {}) {
        self.init(existingDeck: nil, template: template, onSaveComplete: onSaveComplete)
    }

    init(deck: Deck?) {
        self.init(existingDeck: deck)
    }

    var body: some View {
        Form {
            DeckCreationTipsView(deckType: .lineMemorization)
            deckDetailsSection
            languageSettingsSection
            entryModeSection
            lineEntrySection
            validationMessageSection
            currentLinesSection
            finalActionsSection
        }
        .navigationTitle(viewModel.isEditingExistingDeck ? "Edit Lines" : "Line Memorization")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.deckDraft.cards.isEmpty {
                    EditButton()
                }
            }
        }
        .onAppear(perform: prepareViewModel)
        .navigationDestination(isPresented: reviewNavigationBinding) {
            if let draftForReview {
                ReviewDeckView(deckDraft: draftForReview, onSaveComplete: onSaveComplete)
                    .environmentObject(deckStore)
            }
        }
        .navigationDestination(isPresented: bulkPreviewNavigationBinding) {
            if let bulkParseResult {
                BulkImportPreviewView(parseResult: bulkParseResult) { cards in
                    addBulkLines(cards)
                }
            }
        }
    }

    private var deckDetailsSection: some View {
        DeckMetadataFormView(
            title: $viewModel.deckDraft.title,
            description: $viewModel.deckDraft.deckDescription,
            category: deckCategoryBinding
        )
    }

    private var languageSettingsSection: some View {
        LanguageSelectionSectionView(
            frontLanguage: $viewModel.deckDraft.frontLanguage,
            backLanguage: $viewModel.deckDraft.backLanguage
        )
        .onChange(of: viewModel.deckDraft.frontLanguage) { _, newLanguage in
            viewModel.currentCardDraft.frontLanguage = newLanguage
        }
        .onChange(of: viewModel.deckDraft.backLanguage) { _, newLanguage in
            viewModel.currentCardDraft.backLanguage = newLanguage
        }
    }

    private var entryModeSection: some View {
        Section("Entry Mode") {
            Picker("Entry Mode", selection: $selectedEntryMode) {
                ForEach(LineEntryMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var lineEntrySection: some View {
        switch selectedEntryMode {
        case .manual:
            addLineSection
        case .bulkPaste:
            bulkPasteSection
        }
    }

    private var addLineSection: some View {
        Section("Add Line / Card") {
            LineMemorizationCardEntryFormView(
                frontText: $viewModel.currentCardDraft.frontText,
                backText: $viewModel.currentCardDraft.backText,
                frontLanguage: viewModel.deckDraft.frontLanguage,
                backLanguage: viewModel.deckDraft.backLanguage,
                transliteration: cardTextBinding(\.transliteration),
                sourceReference: cardTextBinding(\.sourceReference),
                notes: cardTextBinding(\.notes),
                lineOrder: $manualLineOrder,
                memorizationChunksText: $memorizationChunksText,
                frontFieldFocus: $isFrontFieldFocused
            )

            Button("Add Line") {
                addCurrentLine(shouldRefocus: false)
            }

            Button("Add Line & Continue") {
                addCurrentLine(shouldRefocus: true)
            }

            Button("Clear Current Line", role: .cancel) {
                clearCurrentLine()
            }
        }
    }

    private var bulkPasteSection: some View {
        Section("Bulk Add Lines") {
            Picker("Split Method", selection: $selectedSplitMethod) {
                ForEach(LineMemorizationSplitMethod.allCases) { splitMethod in
                    Text(splitMethod.displayName)
                        .tag(splitMethod)
                }
            }

            if selectedSplitMethod == .customDelimiter {
                TextField("Custom delimiter", text: $customDelimiter)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            TextEditor(text: $bulkPastedText)
                .frame(minHeight: 150)
                .font(AppFont.font(for: viewModel.deckDraft.frontLanguage, size: 16))
                .languageTextDirection(viewModel.deckDraft.frontLanguage)
                .overlay(alignment: .topLeading) {
                    if bulkPastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Paste memorization text here")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

            splitMethodHelpText

            Button("Preview Lines") {
                previewBulkLines()
            }

            Button("Clear", role: .cancel) {
                bulkPastedText = ""
                customDelimiter = ""
            }
        }
    }

    private var splitMethodHelpText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Split options:")
                .fontWeight(.medium)

            Text("Line Break: each non-empty line becomes one card.")
            Text("Sentence: sentence endings create cards.")
            Text("Custom Delimiter: your delimiter separates cards.")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var validationMessageSection: some View {
        if let validationMessage = viewModel.validationMessage {
            Section("Needs Attention") {
                Label {
                    Text(validationMessage)
                        .font(.footnote)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } else if let successMessage {
            Section {
                Label {
                    Text(successMessage)
                        .font(.footnote)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var currentLinesSection: some View {
        Section {
            if orderedCards.isEmpty {
                Text("No lines added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(orderedCards) { cardDraft in
                    CardPreviewRowView(
                        card: cardDraft.toFlashcard(),
                        displayStyle: .detailed,
                        showsLanguages: true,
                        showsMetadata: true,
                        showsLineOrder: true
                    )
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.duplicateCard(id: cardDraft.id)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete(perform: viewModel.removeCard)
                .onMove(perform: viewModel.moveCard)
            }
        } header: {
            HStack {
                Text("Current Lines")
                Spacer()
                Text("\(viewModel.deckDraft.cardCount) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Add at least 2 lines before reviewing. Use Edit to reorder lines manually.")
        }
    }

    private var finalActionsSection: some View {
        Section("Final Actions") {
            Button(primaryActionTitle) {
                handlePrimaryAction()
            }

            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
    }

    private var primaryActionTitle: String {
        viewModel.isEditingExistingDeck ? "Update Deck" : "Review Deck"
    }

    private var reviewNavigationBinding: Binding<Bool> {
        Binding(
            get: { draftForReview != nil },
            set: { isPresented in
                if !isPresented {
                    draftForReview = nil
                }
            }
        )
    }

    private var bulkPreviewNavigationBinding: Binding<Bool> {
        Binding(
            get: { bulkParseResult != nil },
            set: { isPresented in
                if !isPresented {
                    bulkParseResult = nil
                }
            }
        )
    }

    private var orderedCards: [FlashcardDraft] {
        viewModel.deckDraft.cards
    }

    private var deckCategoryBinding: Binding<String> {
        Binding(
            get: { viewModel.deckDraft.category ?? "" },
            set: { viewModel.deckDraft.category = $0 }
        )
    }

    private func cardTextBinding(_ keyPath: WritableKeyPath<FlashcardDraft, String?>) -> Binding<String> {
        Binding(
            get: { viewModel.currentCardDraft[keyPath: keyPath] ?? "" },
            set: { viewModel.currentCardDraft[keyPath: keyPath] = $0 }
        )
    }

    private func prepareViewModel() {
        guard !didPrepareViewModel else {
            return
        }

        if let existingDeck {
            viewModel.loadDeckForEditing(existingDeck)
            viewModel.updateDeckType(.lineMemorization)
        } else if let template {
            viewModel.resetForTemplate(template)
            viewModel.updateDeckType(.lineMemorization)
        } else if let initialDeckDraft {
            viewModel.deckDraft = initialDeckDraft
            viewModel.updateDeckType(.lineMemorization)
            viewModel.resetCurrentCardDraft()
            viewModel.clearValidationMessage()
        } else {
            viewModel.resetForNewDeck(deckType: .lineMemorization)
        }

        syncAuxiliaryFieldsFromCurrentCard()
        didPrepareViewModel = true
    }

    private func addCurrentLine(shouldRefocus: Bool) {
        applyAuxiliaryFieldsToCurrentCard()

        if viewModel.addCurrentCard() {
            successMessage = "Line added."
            syncAuxiliaryFieldsFromCurrentCard()

            if shouldRefocus {
                focusFirstManualField()
            }
        } else {
            successMessage = nil
        }
    }

    private func addBulkLines(_ cards: [Flashcard]) {
        viewModel.addBulkParsedCards(cards)

        if viewModel.validationMessage == nil {
            bulkPastedText = ""
            successMessage = "Line added."
        }
    }

    private func previewBulkLines() {
        bulkParseResult = BulkCardParserService.parseLineMemorizationCards(
            from: bulkPastedText,
            frontLanguage: viewModel.deckDraft.frontLanguage,
            backLanguage: viewModel.deckDraft.backLanguage,
            splitMethod: selectedSplitMethod,
            customDelimiter: customDelimiter
        )
    }

    private func clearCurrentLine() {
        viewModel.resetCurrentCardDraft()
        viewModel.clearValidationMessage()
        successMessage = nil
        syncAuxiliaryFieldsFromCurrentCard()
    }

    private func focusFirstManualField() {
        DispatchQueue.main.async {
            isFrontFieldFocused = true
        }
    }

    private func handlePrimaryAction() {
        if viewModel.isEditingExistingDeck {
            updateDeck()
        } else {
            reviewDeck()
        }
    }

    private func updateDeck() {
        guard viewModel.saveOrUpdateDeck(using: deckStore) else {
            return
        }

        dismiss()
    }

    private func reviewDeck() {
        guard viewModel.validateDeckForReview() else {
            return
        }

        draftForReview = viewModel.deckDraft
    }

    private func syncAuxiliaryFieldsFromCurrentCard() {
        manualLineOrder = viewModel.currentCardDraft.lineOrder.map(String.init) ?? ""
        memorizationChunksText = viewModel.currentCardDraft.memorizationChunks.joined(separator: "\n")
    }

    private func applyAuxiliaryFieldsToCurrentCard() {
        let trimmedLineOrder = manualLineOrder.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.currentCardDraft.lineOrder = Int(trimmedLineOrder)

        viewModel.currentCardDraft.memorizationChunks = memorizationChunksText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private enum LineEntryMode: String, CaseIterable, Identifiable {
    case manual
    case bulkPaste

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .manual:
            return "Manual Line Entry"
        case .bulkPaste:
            return "Bulk Paste Lines"
        }
    }
}

#Preview {
    NavigationStack {
        LineMemorizationDeckBuilderView()
            .environmentObject(DeckStore())
    }
}
