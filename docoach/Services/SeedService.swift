import Foundation
import SwiftData

struct SeedService {

    /// 「何問インポート済みか」を保持する UserDefaults キー。
    /// スキーマ非互換で SQLite を破棄するときは docoachApp 側でこのキーも消し、再シードを促す。
    static let seededCountKey = "seededQuestionCount"

    /// 起動のたびに呼び出す。初回はタグ＋全問題を投入。
    /// 以降はバンドルに増えた問題だけを差分追加する（履歴は削除しない）。
    static func seedIfNeeded(context: ModelContext) throws {
        let tagCount = try context.fetchCount(FetchDescriptor<Tag>())

        // タグが未投入なら初回セットアップ
        let tags: [Tag]
        if tagCount == 0 {
            tags = makeTags()
            tags.forEach { context.insert($0) }
            try context.save()
        } else {
            tags = try context.fetch(FetchDescriptor<Tag>())
        }

        // バンドルを読み込む
        let bundleQuestions = loadQuestionsFromBundle(tags: tags)

        // バンドルがない場合はサンプル問題（初回のみ）
        if bundleQuestions.isEmpty {
            if tagCount == 0 {
                makeSampleQuestions(tags: tags).forEach { context.insert($0) }
                try context.save()
            }
            return
        }

        // 何問インポート済みかを UserDefaults で管理
        var seededCount = UserDefaults.standard.integer(forKey: seededCountKey)

        // 移行処理: キーが未設定かつ既存データがある場合（旧バージョンからのアップデート）
        // → 現在のDB問題数を起点にして重複インポートを防ぐ
        if seededCount == 0 && tagCount > 0 {
            let dbCount = try context.fetchCount(FetchDescriptor<Question>())
            seededCount = min(dbCount, bundleQuestions.count)
            UserDefaults.standard.set(seededCount, forKey: seededCountKey)
        }

        // 差分だけ追加
        guard bundleQuestions.count > seededCount else { return }
        let newQuestions = Array(bundleQuestions[seededCount...])
        newQuestions.forEach { context.insert($0) }
        UserDefaults.standard.set(bundleQuestions.count, forKey: seededCountKey)
        try context.save()
    }

    // MARK: - JSON バンドルからの問題読み込み

    private struct QuestionJSON: Codable {
        let grade: Int
        let title: String?
        let author: String?
        let text: String
        let questionText: String
        let choices: [String]
        let correctIndex: Int
        let explanation: String
        let difficulty: Int
        let tags: [String]
    }

    private struct QuestionsBundle: Codable {
        let questions: [QuestionJSON]
    }

    private static func loadQuestionsFromBundle(tags: [Tag]) -> [Question] {
        guard let url = Bundle.main.url(forResource: "questions_bundle", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundle = try? JSONDecoder().decode(QuestionsBundle.self, from: data)
        else { return [] }

        func findTag(_ name: String) -> Tag? {
            tags.first { $0.name == name }
        }

        return bundle.questions.compactMap { q in
            guard q.choices.count == 4,
                  (0...3).contains(q.correctIndex),
                  (1...3).contains(q.difficulty),
                  (4...6).contains(q.grade)
            else { return nil }

            let matchedTags = q.tags.compactMap { findTag($0) }
            return Question(
                grade: q.grade,
                title: q.title ?? "",
                author: q.author ?? "",
                text: q.text,
                questionText: q.questionText,
                choices: q.choices,
                correctIndex: q.correctIndex,
                explanation: q.explanation,
                difficulty: q.difficulty,
                tags: matchedTags
            )
        }
    }

    // MARK: - タグ定義

    private static func makeTags() -> [Tag] {
        let definitions: [(category: String, name: String, priority: Int)] = [
            // 読解スキル
            ("skill", "主題把握",   1),
            ("skill", "要点抽出",   1),
            ("skill", "指示語",     2),
            ("skill", "心情理解",   1),
            ("skill", "場面理解",   3),
            // 思考レベル
            ("thinking", "推論",     1),
            ("thinking", "抽象理解", 1),
            ("thinking", "事実理解", 3),
            // 文構造
            ("structure", "因果関係",  1),
            ("structure", "具体⇄抽象", 1),
            ("structure", "対比",      2),
            ("structure", "時系列",    3),
            // 語彙・表現
            ("vocab", "抽象語", 2),
            ("vocab", "慣用句", 2),
            ("vocab", "多義語", 2),
        ]
        return definitions.map {
            Tag(category: $0.category, name: $0.name, priority: $0.priority)
        }
    }

    // MARK: - サンプル問題

    private static func makeSampleQuestions(tags: [Tag]) -> [Question] {
        func tag(_ name: String) -> Tag {
            tags.first { $0.name == name }!
        }

        return [
            // ---- 小学4年 ----
            Question(
                grade: 4,
                text: """
                　春になると、校庭の桜の木に花が咲きます。白やうすいピンクの花びらが風に揺れて、まるで雪が舞っているようです。
                　花見をする人たちが公園に集まり、シートを敷いてお弁当を広げます。子どもたちは桜の木の下で走り回り、お父さんやお母さんは空を見上げて話しています。
                　やがて風が吹くと、花びらはひらひらと舞い落ち、地面に白いじゅうたんを作ります。春は、みんなが外に出たくなる季節です。
                """,
                questionText: "この文章は、何について書かれていますか。",
                choices: [
                    "桜の花びらの色について",
                    "春に桜の花が咲く様子と人々の行動について",
                    "お弁当の作り方について",
                    "子どもの遊び方について"
                ],
                correctIndex: 1,
                explanation: "文章全体は、桜が咲く春の様子と、それを楽しむ人々の姿を説明しています。「主題把握」の問題です。",
                difficulty: 1,
                tags: [tag("主題把握"), tag("要点抽出")]
            ),
            Question(
                grade: 4,
                text: """
                　太郎くんは算数のテストが返ってきたとき、顔を真っ赤にしてうつむきました。隣の花子さんは「どうしたの？」と聞きましたが、太郎くんは何も言いませんでした。
                　帰り道、太郎くんは一人でゆっくり歩いていました。いつもは友達と話しながら帰るのに、その日は黙ったまま下を向いて歩き続けました。
                """,
                questionText: "太郎くんが黙って一人で帰った理由として、最もふさわしいものはどれですか。",
                choices: [
                    "友達とけんかをしたから",
                    "テストの点が悪くて落ち込んでいたから",
                    "走るのが疲れたから",
                    "花子さんが好きだから"
                ],
                correctIndex: 1,
                explanation: "「顔を真っ赤にしてうつむいた」「テストが返ってきたとき」という描写から、テストの結果に落ち込んでいることが読み取れます。「心情理解」の問題です。",
                difficulty: 2,
                tags: [tag("心情理解"), tag("推論")]
            ),

            // ---- 小学5年 ----
            Question(
                grade: 5,
                text: """
                　環境問題の中で、地球温暖化は特に深刻だといわれています。温暖化の原因の一つは、二酸化炭素などの温室効果ガスが大気中に増えることです。これらのガスは、工場や自動車から出る排気ガスに多く含まれています。
                　温暖化が進むと、海面が上昇して島が水没したり、異常気象が増えたりするといわれています。
                　そのため、世界中の国が協力して、二酸化炭素の排出量を減らす取り組みを進めています。
                """,
                questionText: "地球温暖化の原因として、この文章で述べられていることは何ですか。",
                choices: [
                    "海面が上昇していること",
                    "島が水没していること",
                    "温室効果ガスが大気中に増えること",
                    "世界中の国が協力していること"
                ],
                correctIndex: 2,
                explanation: "「温暖化の原因の一つは、二酸化炭素などの温室効果ガスが大気中に増えること」と直接書かれています。「因果関係」を正確に読み取る問題です。",
                difficulty: 2,
                tags: [tag("因果関係"), tag("要点抽出")]
            ),
            Question(
                grade: 5,
                text: """
                　「それ」を元の場所に戻してください、と先生は言いました。健太は先生の言葉を聞いて、机の上に出していた本を本棚にしまいました。
                """,
                questionText: "文中の「それ」が指しているものはどれですか。",
                choices: [
                    "机",
                    "本棚",
                    "本",
                    "元の場所"
                ],
                correctIndex: 2,
                explanation: "「それ」は前の文脈から「本」を指しています。指示語の問題では、直前に出てきた名詞に注目することが大切です。",
                difficulty: 1,
                tags: [tag("指示語")]
            ),

            // ---- 小学6年 ----
            Question(
                grade: 6,
                text: """
                　私たちが「当たり前」だと思っていることは、時代や場所によって大きく異なります。たとえば、現代の日本では電気や水道が当たり前のように使えますが、世界には今もそれらが使えない地域があります。また、100年前の日本では、今では普通のことが全く存在しなかったこともあります。
                　「当たり前」は、実は「自分が慣れ親しんでいること」にすぎないのかもしれません。そう考えると、異なる文化や習慣を持つ人々の生活を、自分の「当たり前」を基準に判断することには、注意が必要だといえるでしょう。
                """,
                questionText: "筆者がこの文章で最も伝えたいことはどれですか。",
                choices: [
                    "現代の日本では電気や水道が使えて便利だということ",
                    "100年前の日本は不便だったということ",
                    "「当たり前」は相対的なものであり、他の文化を自分の基準で判断することに注意すべきだということ",
                    "世界には電気や水道が使えない地域があるということ"
                ],
                correctIndex: 2,
                explanation: "筆者は具体例（電気・水道・100年前）を使って、「当たり前」の相対性を示し、最終的に「他者の文化を自分の基準で判断することへの注意」を主張しています。「主題把握」＋「具体⇄抽象」の問題です。",
                difficulty: 3,
                tags: [tag("主題把握"), tag("具体⇄抽象"), tag("抽象理解")]
            ),
            Question(
                grade: 6,
                text: """
                　AさんとBさんは正反対の性格です。Aさんは計画を立ててから行動するのが好きで、何でも準備を整えてから取りかかります。一方、Bさんはまず行動してみて、問題が起きたらその都度考えるタイプです。
                　先日の学校行事では、Aさんは事前にリストを作り、忘れ物なく準備しました。Bさんは出発直前に準備を始め、一部忘れてしまいましたが、現地でうまく工夫して乗り越えました。どちらのやり方が「正解」とは一概にはいえません。
                """,
                questionText: "この文章におけるAさんとBさんの違いとして正しいものはどれですか。",
                choices: [
                    "AさんはBさんより優秀だということ",
                    "Bさんは計画を立てるのが得意だということ",
                    "Aさんは事前準備派、Bさんは行動してから考える派だということ",
                    "AさんもBさんも同じ準備方法だということ"
                ],
                correctIndex: 2,
                explanation: "「正反対の性格」として、Aさんは「計画→行動」、Bさんは「行動→対処」と対比されています。「対比」を正確に読み取る問題です。",
                difficulty: 2,
                tags: [tag("対比"), tag("要点抽出")]
            ),
        ]
    }
}
