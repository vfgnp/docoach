import SwiftUI
import SwiftData

private enum SessionPhase {
    case quiz
    case mistakeReview
    case retry
    case complete
}

struct QuizSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    let initialQuestions: [Question]

    @State private var phase: SessionPhase = .quiz
    @State private var currentQuestions: [Question]
    @State private var currentIndex: Int = 0
    @State private var startTime: Date = .now
    @State private var sessionLogs: [AnswerLog] = []
    @State private var wrongQuestions: [Question] = []

    init(questions: [Question]) {
        self.initialQuestions = questions
        self._currentQuestions = State(initialValue: questions)
    }

    private var current: Question? {
        guard currentIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .quiz, .retry:
                    if let q = current {
                        AnswerView(question: q, grade: appState.selectedGrade) { chosen in
                            submitAnswer(question: q, chosen: chosen)
                        }
                        .id("\(phase)-\(currentIndex)")
                    } else {
                        Color.clear.onAppear { onPhaseComplete() }
                    }

                case .mistakeReview:
                    MistakeReviewView(
                        wrongCount: wrongQuestions.count,
                        onRetry: startRetry
                    )

                case .complete:
                    CompleteView(onDismiss: { dismiss() })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("終了") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    if current != nil {
                        Text("\(currentIndex + 1) / \(currentQuestions.count)")
                            .font(.headline)
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private func submitAnswer(question: Question, chosen: Int) {
        let elapsed = Int(Date.now.timeIntervalSince(startTime))
        let correct = chosen == question.correctIndex
        let log = AnswerLog(
            question: question,
            isCorrect: correct,
            timeSec: max(1, elapsed)
        )
        modelContext.insert(log)
        try? modelContext.save()
        sessionLogs.append(log)

        if !correct && phase == .retry {
            currentQuestions.append(question)
        }

        currentIndex += 1
        startTime = .now
    }

    private func onPhaseComplete() {
        switch phase {
        case .quiz:
            // 初期問題の中で不正解だったものを特定
            let answeredWrong = sessionLogs
                .filter { !$0.isCorrect }
                .compactMap { $0.question }
            // 重複を除く（同じ問題が複数ログにある場合はなし、quizフェーズでは1問1回）
            wrongQuestions = answeredWrong
            if wrongQuestions.isEmpty {
                dismiss()
            } else {
                phase = .mistakeReview
            }

        case .retry:
            phase = .complete

        case .mistakeReview:
            break

        case .complete:
            break
        }
    }

    private func startRetry() {
        currentQuestions = wrongQuestions
        currentIndex = 0
        startTime = .now
        phase = .retry
    }
}

private struct CompleteView: View {
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("🎉")
                .font(.system(size: 96))
                .scaleEffect(scale)
                .opacity(opacity)

            VStack(spacing: 12) {
                Text("ぜんぶできたよ！")
                    .font(.largeTitle.bold())
                Text("よくがんばったね！")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacity)

            Spacer()

            Button(action: onDismiss) {
                Text("おわる")
                    .font(.title3.bold())
                    .frame(maxWidth: 300)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

private struct MistakeReviewView: View {
    let wrongCount: Int
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 追いかけっこアニメーション
            ChaseView()
                .padding(.top, 32)

            Spacer()

            // 猫キャラクター＋吹き出し
            HStack(alignment: .top, spacing: 0) {
                Text("🐱")
                    .font(.system(size: 72))
                    .padding(.top, 4)

                // 吹き出し（左向きポインター付き）
                VStack(alignment: .leading, spacing: 8) {
                    Text("おしかったね！")
                        .font(.title3.bold())
                    Text("\(wrongCount)問、いっしょに\nもう一度やってみよう！")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(18)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .topLeading) {
                    LeftBubblePointer()
                        .fill(Color(.systemGray5))
                        .frame(width: 16, height: 22)
                        .offset(x: -14, y: 14)
                }
                .padding(.leading, 18)
            }
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onRetry) {
                Text("といなおす")
                    .font(.title3.bold())
                    .frame(maxWidth: 300)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 48)
        }
    }
}

// 猫がネズミを追いかけるアニメーション
private struct ChaseView: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let span = geo.size.width + 220
            let catX  = span * progress - 160
            let mouseX = catX + 72

            ZStack(alignment: .leading) {
                Text("🐭")
                    .font(.system(size: 36))
                    .offset(x: mouseX)
                Text("🐱")
                    .font(.system(size: 48))
                    .offset(x: catX)
            }
        }
        .frame(height: 56)
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                progress = 1
            }
        }
    }
}

// 左向き吹き出しポインター
private struct LeftBubblePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
