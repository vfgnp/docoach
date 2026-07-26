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
        ZStack {
            Kids.screenBackground.ignoresSafeArea()

            switch phase {
            case .quiz, .retry:
                if let q = current {
                    AnswerView(
                        question: q,
                        grade: appState.selectedGrade,
                        index: currentIndex,
                        total: currentQuestions.count,
                        onClose: { dismiss() }
                    ) { chosen in
                        submitAnswer(question: q, chosen: chosen)
                    }
                    .id("\(phase)-\(currentIndex)")
                } else {
                    Color.clear.onAppear { onPhaseComplete() }
                }

            case .mistakeReview:
                MistakeReviewView(wrongCount: wrongQuestions.count, onRetry: startRetry)

            case .complete:
                CompleteView(
                    correctCount: sessionLogs.filter(\.isCorrect).count,
                    streak: AnalysisService.streak(in: sessionLogs),
                    onDismiss: { dismiss() }
                )
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
            wrongQuestions = answeredWrong
            if wrongQuestions.isEmpty {
                phase = .complete
            } else {
                phase = .mistakeReview
            }

        case .retry:
            phase = .complete

        case .mistakeReview, .complete:
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

// MARK: - ぜんぶできたよ！

struct CompleteView: View {
    let correctCount: Int
    let streak: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            ConfettiView()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Text("⭐").font(.system(size: 44))
                    Text("⭐").font(.system(size: 60))
                    Text("⭐").font(.system(size: 44))
                }
                .scaleEffect(appeared ? 1 : 0.4)
                .opacity(appeared ? 1 : 0)

                MascotView(height: 200)
                    .padding(.top, 8)

                Text("ぜんぶできたよ！")
                    .font(Kids.font(38, .black))
                    .foregroundStyle(Kids.blue)
                    .padding(.top, 18)

                Text("よくがんばったね！")
                    .font(Kids.font(19, .bold))
                    .foregroundStyle(Kids.textMuted2)
                    .padding(.top, 6)

                HStack(spacing: 14) {
                    statChip(title: "せいかい", value: "\(correctCount)問", color: Kids.blue)
                    if streak > 0 {
                        statChip(title: "れんぞく", value: "\(streak)日 🔥", color: Kids.orange)
                    }
                }
                .padding(.top, 22)

                Spacer(minLength: 0)

                KidsBigButton(title: "おわる", palette: .blue, fontSize: 24, action: onDismiss)
                    .frame(maxWidth: 340)
                    .padding(.bottom, 34)
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) { appeared = true }
        }
    }

    private func statChip(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(Kids.font(13, .bold))
                .foregroundStyle(Kids.textMuted)
            Text(value)
                .font(Kids.font(26, .black))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .kidsCard(radius: 18, depth: 5)
    }
}

/// 上から降ってくる紙吹雪
private struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: Double        // 0...1
        let color: Color
        let circle: Bool
        let size: CGFloat
        let duration: Double
        let delay: Double
    }

    private let pieces: [Piece] = [
        .init(x: 0.12, color: Color(hex: 0xFF6B6B), circle: false, size: 14, duration: 2.6, delay: 0),
        .init(x: 0.28, color: Color(hex: 0xFFD23F), circle: true, size: 12, duration: 2.9, delay: 0.4),
        .init(x: 0.44, color: Color(hex: 0x46D39A), circle: false, size: 16, duration: 2.4, delay: 0.2),
        .init(x: 0.62, color: Color(hex: 0x5CB0FF), circle: true, size: 12, duration: 3.1, delay: 0.6),
        .init(x: 0.78, color: Color(hex: 0x9B7BF0), circle: false, size: 14, duration: 2.7, delay: 0.1),
        .init(x: 0.90, color: Color(hex: 0xFF9E3C), circle: true, size: 12, duration: 2.5, delay: 0.5),
    ]

    @State private var falling = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ForEach(pieces) { piece in
                    Group {
                        if piece.circle {
                            Circle().fill(piece.color)
                        } else {
                            RoundedRectangle(cornerRadius: 3).fill(piece.color)
                        }
                    }
                    .frame(width: piece.size, height: piece.size)
                    .position(x: piece.x * geo.size.width, y: falling ? geo.size.height + 40 : -30)
                    .rotationEffect(.degrees(falling ? 560 : 0))
                    .animation(
                        .linear(duration: piece.duration).repeatForever(autoreverses: false).delay(piece.delay),
                        value: falling
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { falling = true }
    }
}

// MARK: - おしかったね！

struct MistakeReviewView: View {
    let wrongCount: Int
    let onRetry: () -> Void

    @State private var chase = false

    var body: some View {
        VStack(spacing: 0) {
            // 追いかけっこ
            GeometryReader { geo in
                let span = geo.size.width + 140
                ZStack(alignment: .leading) {
                    Text("🐾").font(.system(size: 40))
                        .offset(x: chase ? span : -70)
                    Text("🐭").font(.system(size: 34))
                        .offset(x: chase ? span + 60 : -10)
                }
                .animation(.linear(duration: 2.6).repeatForever(autoreverses: false), value: chase)
            }
            .frame(height: 64)
            .clipped()
            .padding(.top, 36)

            MascotView(height: 180).padding(.top, 14)

            VStack(spacing: 8) {
                Text("おしかったね！")
                    .font(Kids.font(24, .black))
                    .foregroundStyle(Kids.orange)
                Text("\(wrongCount)問、いっしょに\nもう一度やってみよう！")
                    .font(Kids.font(19, .bold))
                    .foregroundStyle(Color(hex: 0x6B5E52))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .frame(maxWidth: 420)
            .kidsCard(radius: 24, depth: 7)
            .overlay(alignment: .top) {
                Triangle()
                    .fill(Kids.card)
                    .frame(width: 24, height: 16)
                    .offset(y: -14)
            }
            .padding(.top, 22)

            Spacer(minLength: 0)

            KidsBigButton(title: "といなおす！", palette: .blue, fontSize: 26, action: onRetry)
                .frame(maxWidth: 420)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
        .onAppear { chase = true }
    }
}

/// 吹き出しのしっぽ
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
