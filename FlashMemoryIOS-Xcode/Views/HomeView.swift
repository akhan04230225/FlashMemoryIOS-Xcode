import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome to FlashMemory")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Study your flashcards one deck at a time.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Start Studying") {
                // Placeholder action
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
