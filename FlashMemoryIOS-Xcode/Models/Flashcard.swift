import Foundation

struct Flashcard: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}
