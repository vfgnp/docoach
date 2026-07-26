import Foundation

struct QuestionSelector {

    /// セッション用の問題を選ぶ（苦手60% / 通常40%）
    static func select(
        from allQuestions: [Question],
        grade: Int,
        weakTags: [Tag],
        recentLogs: [AnswerLog],
        count: Int = AppConstants.QuestionSelector.sessionSize
    ) -> [Question] {
        let gradePool = allQuestions.filter { $0.grade <= grade }

        // 一度でも解答済みの問題は除外
        let answeredIDs = Set(recentLogs.map { $0.question.id })
        let freshPool = gradePool.filter { !answeredIDs.contains($0.id) }

        let weakTagIDs = Set(weakTags.map(\.id))
        let weakPool = freshPool.filter { q in
            q.tags.contains { weakTagIDs.contains($0.id) }
        }
        let normalPool = freshPool.filter { q in
            !q.tags.contains { weakTagIDs.contains($0.id) }
        }

        let weakCount = Int((Double(count) * AppConstants.QuestionSelector.weakTagRatio).rounded())
        let normalCount = count - weakCount

        var selected: [Question] = []
        selected += weakPool.shuffled().prefix(weakCount)
        selected += normalPool.shuffled().prefix(normalCount)

        // 未解答プール内で補充
        if selected.count < count {
            let used = Set(selected.map(\.id))
            let remaining = freshPool.filter { !used.contains($0.id) }.shuffled()
            selected += remaining.prefix(count - selected.count)
        }

        // 未解答が尽きたら既解答から補充して、セッション長を保つ。
        // 優先1: 最新ログが不正解の問題（復習価値が高い）／優先2: 最終解答が古い順。
        if selected.count < count {
            let used = Set(selected.map(\.id))
            let latestLog = AnalysisService.latestLogPerQuestion(recentLogs)
            let reviewPool = gradePool
                .filter { answeredIDs.contains($0.id) && !used.contains($0.id) }
                .sorted { lhs, rhs in
                    let l = latestLog[lhs.id]
                    let r = latestLog[rhs.id]
                    let lWrong = l.map { !$0.isCorrect } ?? false
                    let rWrong = r.map { !$0.isCorrect } ?? false
                    if lWrong != rWrong { return lWrong }
                    return (l?.answeredAt ?? .distantPast) < (r?.answeredAt ?? .distantPast)
                }
            selected += reviewPool.prefix(count - selected.count)
        }

        return selected.shuffled()
    }

    /// まちがい練習用：最後の解答が不正解だった問題を返す
    static func selectMistakes(
        from allQuestions: [Question],
        grade: Int,
        allLogs: [AnswerLog],
        count: Int = AppConstants.QuestionSelector.sessionSize
    ) -> [Question] {
        let gradeLogs = allLogs.filter { $0.grade <= grade }
        let latestLog = AnalysisService.latestLogPerQuestion(gradeLogs)
        let mistakeIDs = Set(latestLog.values.filter { !$0.isCorrect }.map { $0.question.id })
        let pool = allQuestions.filter { $0.grade <= grade && mistakeIDs.contains($0.id) }.shuffled()
        return Array(pool.prefix(count))
    }
}
