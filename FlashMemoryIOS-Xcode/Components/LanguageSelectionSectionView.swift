import SwiftUI

struct LanguageSelectionSectionView: View {
    @Binding var frontLanguage: AppLanguage
    @Binding var backLanguage: AppLanguage

    var availableLanguages: [AppLanguage] = [
        .english,
        .urdu,
        .arabic,
        .mixed,
        .custom
    ]

    var body: some View {
        Section("Language Settings") {
            Picker("Front Language", selection: $frontLanguage) {
                ForEach(availableLanguages, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }

            Picker("Back Language", selection: $backLanguage) {
                ForEach(availableLanguages, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
        }
    }
}
