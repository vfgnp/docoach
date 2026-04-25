import SwiftUI

struct ReadingView: View {
    let question: Question
    let onReady: () -> Void

    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                RubyTextView(text: question.text, grade: appState.selectedGrade)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }

            Divider()

            Button(action: onReady) {
                Text("問いを見る")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
            }
            .background(Color.accentColor)
        }
    }
}
