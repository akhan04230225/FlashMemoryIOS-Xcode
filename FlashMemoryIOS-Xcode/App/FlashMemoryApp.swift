import SwiftUI

@main
struct FlashMemoryApp: App {
    @StateObject private var deckStore = DeckStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deckStore)
        }
    }
}
