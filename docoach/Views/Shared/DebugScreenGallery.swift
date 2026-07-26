#if DEBUG
import SwiftUI

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

            case .mascot:
                VStack(spacing: 28) {
                    MascotView(height: 80, bobbing: false)
                    MascotView(height: 160, bobbing: false)
                    MascotView(height: 220, bobbing: false)
                }
            }
        }
    }
}
#endif
