import Foundation

struct Deck: Identifiable {
    let id = UUID()
    let title: String
    let cardCount: Int
}
