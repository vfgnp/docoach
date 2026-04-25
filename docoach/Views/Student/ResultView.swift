import SwiftUI

struct ResultView: View {
    let question: Question
    let selectedIndex: Int
    let onNext: () -> Void

    private var isCorrect: Bool { selectedIndex == question.correctIndex }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 正誤バナー
                HStack(spacing: 16) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(isCorrect ? .green : .red)
                    Text(isCorrect ? "せいかい！" : "まちがい")
                        .font(.largeTitle.bold())
                        .foregroundStyle(isCorrect ? .green : .red)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )

                // 正解表示（不正解時のみ）
                if !isCorrect {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("正解")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(question.correctChoice)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                // 解説
                VStack(alignment: .leading, spacing: 8) {
                    Text("解説")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(question.explanation)
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }

                // タグ
                if !question.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("この問題のポイント")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(question.tags) { tag in
                                TagBadgeView(tag: tag)
                            }
                        }
                    }
                }

                Button(action: onNext) {
                    Text("次の問題へ")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}
