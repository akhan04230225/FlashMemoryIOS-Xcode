import SwiftUI

struct DeckMetadataFormView: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var category: String

    var body: some View {
        Section("Deck Details") {
            TextField("Title", text: $title)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            TextField("Description", text: $description, axis: .vertical)
                .frame(minHeight: 96, alignment: .topLeading)
                .lineLimit(3...5)
                .multilineTextAlignment(.leading)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()

            TextField("Category", text: $category)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
    }
}
