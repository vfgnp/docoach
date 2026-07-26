import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allLogs: [AnswerLog]
    @Query private var allQuestions: [Question]

    @State private var showGradePicker = false
    @State private var quizSession: QuizSession? = nil
    // 「今日」の基準日。アプリ復帰のたびに更新し、日跨ぎでの再計算を促す。
    @State private var todayStart = Calendar.current.startOfDay(for: .now)

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

    /// 今日「正解した」問題数。誤答・やり直しの試行は数えない。
    /// todayStart を基準にすることで @State 依存を作り、日跨ぎ復帰時に再評価される。
    private var todayCorrectCount: Int {
        AnalysisService.correctCount(in: allLogs, on: todayStart)
    }

    private var isLimitReached: Bool {
        guard let limit = appState.dailyLimit else { return false }
        return todayCorrectCount >= limit
    }

    /// 未解答が尽きても QuestionSelector が既解答から補充する（復習）ので、
    /// 学年に問題が 1 問もない場合と 1日の上限到達時だけ止める。
    private var isStartDisabled: Bool {
        gradeQuestions.isEmpty || isLimitReached
    }

    private var streak: Int {
        AnalysisService.streak(in: allLogs, today: todayStart)
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
        ZStack {
            Kids.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard
                    statCards.padding(.top, 16)
                    weakTagSection.padding(.top, 24)
                    startButton.padding(.top, 22)
                    mistakeButton.padding(.top, 10)
                }
                .padding(.horizontal, 26)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showGradePicker) {
            GradePickerView(isPresented: $showGradePicker)
        }
        .fullScreenCover(item: $quizSession) { session in
            QuizSessionView(questions: session.questions)
        }
        .onChange(of: scenePhase) { _, phase in
            // バックグラウンド復帰時に当日基準を更新（日跨ぎで上限判定をリセット）
            if phase == .active {
                todayStart = Calendar.current.startOfDay(for: .now)
            }
        }
    }

    // MARK: - ヒーロー（あいさつ＋学年）

    private var heroCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                MascotView(height: 80)

                VStack(alignment: .leading, spacing: 2) {
                    Text("こんにちは！")
                        .font(Kids.font(15, .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(appState.gradeName)
                        .font(Kids.font(26, .black))
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 0)

                Button {
                    showGradePicker = true
                } label: {
                    Text("学年をかえる")
                        .font(Kids.font(14, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white.opacity(0.22))
                        )
                }
                .buttonStyle(.plain)
            }

            progressRow.padding(.top, 16)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Kids.heroCard)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 150, height: 150)
                        .offset(x: 20, y: -30)
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        )
        .hardShadow(radius: 30, depth: 10, color: Kids.blueDeep)
        .padding(.bottom, 10)
    }

    /// デザインの XP バーの位置に、実データ（といた問題の割合）を入れている。
    private var progressRow: some View {
        let total = gradeQuestions.count
        let solved = total - unsolvedQuestions.count
        let ratio = total == 0 ? 0 : Double(solved) / Double(total)

        return HStack(spacing: 12) {
            Text("といた")
                .font(Kids.font(15, .black))
                .foregroundStyle(Kids.yellowText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Kids.yellow))
                .hardShadow(radius: 12, depth: 4, color: Kids.yellowDeep)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.28))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFFE27A), Color(hex: 0xFFC93C)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: ratio * geo.size.width)
                }
            }
            .frame(height: 16)

            Text("\(solved)")
                .font(Kids.font(16, .black))
                .foregroundStyle(.white)
            + Text(" / \(total)問")
                .font(Kids.font(12, .bold))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    // MARK: - れんぞく／きょうのせいかい

    private var statCards: some View {
        HStack(spacing: 14) {
            streakCard
            todayCard
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            Text("🔥").font(.system(size: 34))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(streak)")
                    .font(Kids.font(26, .black))
                    .foregroundStyle(Kids.orange)
                + Text("日れんぞく")
                    .font(Kids.font(15, .bold))
                    .foregroundStyle(Kids.textMuted2)
                Text(streak > 0 ? "あしたもがんばろう！" : "きょうからはじめよう！")
                    .font(Kids.font(13, .bold))
                    .foregroundStyle(Kids.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidsCard(radius: 22, depth: 6)
    }

    private var todayCard: some View {
        VStack(spacing: 2) {
            Text("きょうのせいかい")
                .font(Kids.font(13, .bold))
                .foregroundStyle(Kids.textMuted)
            Text("\(todayCorrectCount)")
                .font(Kids.font(30, .black))
                .foregroundStyle(isLimitReached ? Kids.orange : Kids.blue)
            + Text(todayGoalSuffix)
                .font(Kids.font(15, .bold))
                .foregroundStyle(Color(hex: 0xB0A392))
        }
        .padding(16)
        .frame(width: 150)
        .kidsCard(radius: 22, depth: 6)
    }

    private var todayGoalSuffix: String {
        if let limit = appState.dailyLimit { return " / \(limit)問" }
        return "問"
    }

    // MARK: - にがてなところ

    private var weakTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            KidsSectionHeader(emoji: "🎯", title: "にがてなところ")

            if tagScores.isEmpty {
                Text("まだデータがないよ。もんだいをといてみよう！")
                    .font(Kids.font(15, .bold))
                    .foregroundStyle(Kids.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .kidsCard(radius: 18, depth: 5)
            } else {
                VStack(spacing: 10) {
                    ForEach(tagScores.prefix(3)) { score in
                        WeakTagRow(score: score)
                    }
                }
            }
        }
    }

    // MARK: - ボタン

    private var startButton: some View {
        KidsBigButton(title: "がくしゅうゴー！", subtitleIcon: "play.fill", palette: .blue) {
            let weak = AnalysisService.weakTags(from: tagScores)
            let questions = QuestionSelector.select(
                from: Array(allQuestions),
                grade: appState.selectedGrade,
                weakTags: weak,
                recentLogs: Array(allLogs)
            )
            quizSession = QuizSession(questions: questions)
        }
        .disabled(isStartDisabled)
        .opacity(isStartDisabled ? 0.5 : 1)
        .overlay(alignment: .bottom) {
            if isLimitReached {
                Text("きょうのぶんは おしまい！")
                    .font(Kids.font(14, .bold))
                    .foregroundStyle(Kids.orange)
                    .offset(y: 14)
            }
        }
    }

    private var mistakeButton: some View {
        let count = mistakePool.count
        return KidsBigButton(
            title: "やりなおしゴー！",
            palette: .orange,
            fontSize: 24,
            action: {
                let questions = QuestionSelector.selectMistakes(
                    from: Array(allQuestions),
                    grade: appState.selectedGrade,
                    allLogs: Array(allLogs),
                    count: AppConstants.QuestionSelector.sessionSize
                )
                quizSession = QuizSession(questions: questions)
            },
            trailing: {
                if count > 0 { KidsCountPill(text: "\(count)問") }
            }
        )
        .disabled(count == 0)
        .opacity(count == 0 ? 0.5 : 1)
    }
}

private struct QuizSession: Identifiable {
    let id = UUID()
    let questions: [Question]
}

private struct WeakTagRow: View {
    let score: TagScore

    private var warm: Bool {
        score.tag.category == "structure" || score.tag.category == "vocab"
    }

    var body: some View {
        HStack(spacing: 14) {
            KidsTagPill(name: score.tag.name, warm: warm)
            KidsMeterBar(value: score.weakScore)
            Text("\(Int(score.weakScore * 100))%")
                .font(Kids.font(16, .black))
                .foregroundStyle(KidsMeterBar.color(for: score.weakScore))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .kidsCard(radius: 18, depth: 5)
    }
}
