import SwiftUI

struct AppFont {
    static func font(for language: AppLanguage, size: CGFloat) -> Font {
        switch language {
        case .english:
            return .system(size: size)
        case .arabic:
            return .custom("NotoNaskhArabic-Regular", size: size)
        case .urdu:
            return .custom("NotoNastaliqUrdu-Regular", size: size)
        case .persian,
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
            return .system(size: size)
        }
    }
}
