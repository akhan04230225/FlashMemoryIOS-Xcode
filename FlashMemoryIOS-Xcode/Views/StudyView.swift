import SwiftUI

struct StudyView: View {
    var body: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.12))
                .frame(height: 220)
                .overlay(
                    Text("Flashcard Placeholder")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                )

            Text("Study mode coming soon")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Study")
    }
}

#Preview {
    NavigationStack {
        StudyView()
    }
}
