#if DEBUG
import SwiftUI
import SwiftData

/// スクリーンショット検証用の入口。製品ビルドには入らない。
///
///     xcrun simctl launch <UDID> NYN.docoach -uiScreen complete
///
/// で目的の画面を直接開けるので、タップ操作なしで全画面を撮って
/// デザイン（`DoCoach-Kids.dc.html`）と見比べられる。
enum DebugScreen: String {
    case grade, answer, answerSubmitted, mistake, complete, mascot, dashboard

    static var fromLaunchArguments: DebugScreen? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-uiScreen"), i + 1 < args.count else { return nil }
        return DebugScreen(rawValue: args[i + 1])
    }
}

struct DebugScreenGallery: View {
    let screen: DebugScreen
    @State private var isPresented = true
    @Environment(\.modelContext) private var modelContext
    @Query private var existingLogs: [AnswerLog]

    private var sampleQuestion: Question {
        Question(
            grade: 5,
            title: "たんぽぽ",
            author: "",
            text: "たんぽぽの綿毛は、風にのって遠くまで飛んでいきます。ふわふわと空をわたり、やがて知らない土地の上にそっと下りるのです。そこで芽を出したたんぽぽは、次の春、あざやかな黄色い花をさかせます。",
            questionText: "たんぽぽは、どのようにしてなかまを広げていますか。",
            choices: [
                "自分で歩いて、遠くへ移動する。",
                "綿毛が風に飛ばされて、遠くの土地に落ちる。",
                "動物に食べられ、体の中で運ばれる。",
                "川の水に流されて、下流へ運ばれる。",
            ],
            correctIndex: 1,
            explanation: "綿毛が風に飛ばされて広がる。",
            difficulty: 2
        )
    }

    var body: some View {
        ZStack {
            Kids.screenBackground.ignoresSafeArea()

            switch screen {
            case .grade:
                GradePickerView(isPresented: $isPresented)

            case .answer, .answerSubmitted:
                AnswerView(
                    question: sampleQuestion,
                    grade: 5,
                    index: 0,
                    total: 5,
                    onClose: {}
                ) { _ in }

            case .mistake:
                MistakeReviewView(wrongCount: 2, onRetry: {})

            case .complete:
                CompleteView(correctCount: 5, streak: 7, onDismiss: {})

            case .dashboard:
                DashboardView()
                    .onAppear(perform: seedSampleLogsIfNeeded)

            case .mascot:
                VStack(spacing: 28) {
                    MascotView(height: 80, bobbing: false)
                    MascotView(height: 160, bobbing: false)
                    MascotView(height: 220, bobbing: false)
                }
            }
        }
    }

    /// dashboard 画面のスクリーンショット用に、空の状態ではなく数字が入った状態を見せる。
    /// ログが1件もない（撮影用にまっさらなシミュレーターの）ときだけ実データを流し込む。
    private func seedSampleLogsIfNeeded() {
        guard existingLogs.isEmpty else { return }
        // DebugScreenGallery は RootView（普段 SeedService.seedIfNeeded を呼ぶ場所）を経由しないので、
        // dashboard 用のダミーログを入れる前に自分でタグ・問題を投入する。
        try? SeedService.seedIfNeeded(context: modelContext)
        var descriptor = FetchDescriptor<Question>(predicate: #Predicate { $0.grade <= 4 })
        descriptor.fetchLimit = 40
        guard let pool = try? modelContext.fetch(descriptor), pool.count >= 10 else { return }

        let calendar = Calendar.current
        let now = Date.now
        var qIndex = 0

        for dayOffset in stride(from: 6, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let answersToday = Int.random(in: 3...5)
            for a in 0..<answersToday {
                let question = pool[qIndex % pool.count]
                let isLastOfDay = a == answersToday - 1
                let isWeakGroup = qIndex % 3 == 0
                let isCorrect = isLastOfDay ? true : (isWeakGroup ? Double.random(in: 0...1) < 0.35 : Double.random(in: 0...1) < 0.9)
                let hour = min(15 + a, 20)
                let answeredAt = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: day) ?? day
                modelContext.insert(AnswerLog(question: question, isCorrect: isCorrect, timeSec: Int.random(in: 18...55), answeredAt: answeredAt))
                qIndex += 1
            }
        }
        try? modelContext.save()
    }
}
#endif
