import SwiftUI

struct SettingsView: View {
    @State private var isSoundEnabled = true
    @State private var isShuffleEnabled = false

    var body: some View {
        Form {
            Toggle("Enable Sound", isOn: $isSoundEnabled)
            Toggle("Shuffle Cards", isOn: $isShuffleEnabled)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
