import SwiftUI

struct SessionSummaryView: View {
    let logs: [AnswerLog]
    let onDone: () -> Void

    private var correctCount: Int { logs.filter(\.isCorrect).count }
    private var totalSec: Int { logs.map(\.timeSec).reduce(0, +) }
    private var correctRate: Int {
        guard !logs.isEmpty else { return 0 }
        return Int(Double(correctCount) / Double(logs.count) * 100)
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: correctRate >= 80
                  ? "star.circle.fill"
                  : correctRate >= 50 ? "hand.thumbsup.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(correctRate >= 80 ? .yellow : correctRate >= 50 ? .blue : .orange)

            Text("セッション終了！")
                .font(.largeTitle.bold())

            VStack(spacing: 0) {
                StatRow(label: "正解", value: "\(correctCount) / \(logs.count) 問")
                Divider().padding(.horizontal)
                StatRow(label: "正答率", value: "\(correctRate)%")
                Divider().padding(.horizontal)
                StatRow(label: "合計時間", value: "\(totalSec) 秒")
            }
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Button(action: onDone) {
                Text("とじる")
                    .font(.title3.bold())
                    .frame(maxWidth: 300)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }

            Spacer()
        }
        .padding()
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3.bold())
        }
        .padding()
    }
}
