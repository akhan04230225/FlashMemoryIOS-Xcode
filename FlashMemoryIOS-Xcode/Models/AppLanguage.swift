import Foundation

enum AppLanguage: String, Codable, Hashable {
    case english
    case urdu
    case arabic
    case mixed
    case custom

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .urdu:
            return "Urdu"
        case .arabic:
            return "Arabic"
        case .mixed:
            return "Mixed"
        case .custom:
            return "Custom"
        }
    }

    var isRightToLeft: Bool {
        switch self {
        case .urdu, .arabic:
            return true
        case .english, .mixed, .custom:
            return false
        }
    }
}
