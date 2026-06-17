import Foundation

enum AppLanguage: String, Codable, Hashable {
    case english
    case urdu
    case persian
    case arabic
    case spanish
    case french
    case german
    case italian
    case portuguese
    case turkish
    case hindi
    case chinese
    case korean
    case japanese
    case mixed
    case custom

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .urdu:
            return "Urdu"
        case .persian:
            return "Farsi"
        case .arabic:
            return "Arabic"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .german:
            return "German"
        case .italian:
            return "Italian"
        case .portuguese:
            return "Portuguese"
        case .turkish:
            return "Turkish"
        case .hindi:
            return "Hindi"
        case .chinese:
            return "Chinese"
        case .korean:
            return "Korean"
        case .japanese:
            return "Japanese"
        case .mixed:
            return "Mixed"
        case .custom:
            return "Other Language"
        }
    }

    var isRightToLeft: Bool {
        switch self {
        case .urdu, .persian, .arabic:
            return true
        case .english,
             .spanish,
             .french,
             .german,
             .italian,
             .portuguese,
             .turkish,
             .hindi,
             .chinese,
             .korean,
             .japanese,
             .mixed,
             .custom:
            return false
        }
    }
}
