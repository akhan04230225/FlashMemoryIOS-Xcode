import SwiftUI

func isRTL(_ language: AppLanguage) -> Bool {
    switch language {
    case .arabic, .urdu:
        return true
    case .english, .mixed, .custom:
        return false
    }
}

func textAlignment(for language: AppLanguage) -> TextAlignment {
    isRTL(language) ? .trailing : .leading
}

func horizontalAlignment(for language: AppLanguage) -> HorizontalAlignment {
    isRTL(language) ? .trailing : .leading
}

func frameAlignment(for language: AppLanguage) -> Alignment {
    isRTL(language) ? .trailing : .leading
}

struct LanguageTextDirectionModifier: ViewModifier {
    let language: AppLanguage

    func body(content: Content) -> some View {
        content.multilineTextAlignment(textAlignment(for: language))
    }
}

extension View {
    func languageTextDirection(_ language: AppLanguage) -> some View {
        modifier(LanguageTextDirectionModifier(language: language))
    }
}
