import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var allLogs: [AnswerLog]
    @Query private var allQuestions: [Question]

    @State private var showGradePicker = false
    @State private var quizSession: QuizSession? = nil

    private var tagScores: [TagScore] {
        AnalysisService.computeTagScores(logs: allLogs, grade: appState.selectedGrade)
    }

    private var gradeQuestions: [Question] {
        allQuestions.filter { $0.grade <= appState.selectedGrade }
    }

    private var unsolvedQuestions: [Question] {
        let answeredIDs = Set(allLogs.map { $0.question.id })
        return allQuestions.filter {
            $0.grade <= appState.selectedGrade && !answeredIDs.contains($0.id)
        }
    }

    private var todayAnsweredCount: Int {
        let cal = Calendar.current
        return allLogs.filter { cal.isDateInToday($0.answeredAt) }.count
    }

    private var isLimitReached: Bool {
        guard let limit = appState.dailyLimit else { return false }
        return todayAnsweredCount >= limit
    }

    private var mistakePool: [Question] {
        QuestionSelector.selectMistakes(
            from: Array(allQuestions),
            grade: appState.selectedGrade,
            allLogs: Array(allLogs),
            count: .max
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    gradeHeader
                    weakTagSection
                    startButton
                    mistakeButton
                }
                .padding()
            }
            .navigationTitle("どこーち")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGradePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                            Text("学年変更")
                        }
                    }
                }
            }
            .sheet(isPresented: $showGradePicker) {
                GradePickerView(isPresented: $showGradePicker)
            }
            .fullScreenCover(item: $quizSession) { session in
                QuizSessionView(questions: session.questions)
            }
        }
    }

    private var gradeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appState.gradeName)
                .font(.title.bold())
            if unsolvedQuestions.isEmpty && !gradeQuestions.isEmpty {
                Text("ぜんぶといたよ！まちがいをれんしゅうしよう")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else {
                Text("のこり \(unsolvedQuestions.count) 問 / 全 \(gradeQuestions.count) 問（〜\(appState.selectedGrade)年生）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let limit = appState.dailyLimit {
                Text("今日あと \(max(0, limit - todayAnsweredCount)) 問")
                    .font(.subheadline)
                    .foregroundStyle(isLimitReached ? .red : .secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private var weakTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("にがてなところ")
                .font(.headline)

            if tagScores.isEmpty {
                Text("まだデータがありません。問題を解いてみよう！")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(tagScores.prefix(3)) { score in
                        WeakTagRow(score: score)
                    }
                }
            }
        }
    }

    private var startButton: some View {
        Button {
            let weak = AnalysisService.weakTags(from: tagScores)
            let questions = QuestionSelector.select(
                from: Array(allQuestions),
                grade: appState.selectedGrade,
                weakTags: weak,
                recentLogs: Array(allLogs)
            )
            quizSession = QuizSession(questions: questions)
        } label: {
            Text("もんだいをはじめる")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(
                    (unsolvedQuestions.isEmpty || isLimitReached)
                    ? Color(.systemGray4)
                    : Color.accentColor,
                    in: RoundedRectangle(cornerRadius: 16)
                )
        }
        .disabled(unsolvedQuestions.isEmpty || isLimitReached)
    }

    private var mistakeButton: some View {
        let hasMistakes = !mistakePool.isEmpty
        return Button {
            let questions = QuestionSelector.selectMistakes(
                from: Array(allQuestions),
                grade: appState.selectedGrade,
                allLogs: Array(allLogs),
                count: 5
            )
            quizSession = QuizSession(questions: questions)
        } label: {
            HStack {
                Text("まちがいをれんしゅうする")
                    .font(.title2.bold())
                Spacer()
                if hasMistakes {
                    Text("\(mistakePool.count)問")
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
                hasMistakes ? Color.orange : Color(.systemGray4),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .disabled(!hasMistakes)
        .overlay(alignment: .trailing) {
            if !hasMistakes {
                Text("まちがいはありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing)
            }
        }
    }
}

private struct QuizSession: Identifiable {
    let id = UUID()
    let questions: [Question]
}

private struct WeakTagRow: View {
    let score: TagScore

    private var barColor: Color {
        score.weakScore > 0.6 ? .red : score.weakScore > 0.3 ? .orange : .green
    }

    var body: some View {
        HStack {
            TagBadgeView(tag: score.tag)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * score.weakScore)
                }
            }
            .frame(width: 100, height: 8)
            Text("\(Int(score.weakScore * 100))%")
                .font(.caption.bold())
                .foregroundStyle(barColor)
                .frame(width: 36, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}
