import Foundation

struct QuestionSelector {

    /// セッション用の問題を選ぶ（苦手60% / 通常40%）
    static func select(
        from allQuestions: [Question],
        grade: Int,
        weakTags: [Tag],
        recentLogs: [AnswerLog],
        count: Int = 5
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

        let weakCount = Int((Double(count) * 0.6).rounded())
        let normalCount = count - weakCount

        var selected: [Question] = []
        selected += weakPool.shuffled().prefix(weakCount)
        selected += normalPool.shuffled().prefix(normalCount)

        // プールが足りない場合は補充
        if selected.count < count {
            let used = Set(selected.map(\.id))
            let remaining = freshPool.filter { !used.contains($0.id) }.shuffled()
            selected += remaining.prefix(count - selected.count)
        }

        return selected.shuffled()
    }

    /// まちがい練習用：最後の解答が不正解だった問題を返す
    static func selectMistakes(
        from allQuestions: [Question],
        grade: Int,
        allLogs: [AnswerLog],
        count: Int = 5
    ) -> [Question] {
        let gradeLogs = allLogs.filter { $0.grade <= grade }
        var latestLog: [UUID: AnswerLog] = [:]
        for log in gradeLogs {
            let qid = log.question.id
            if let existing = latestLog[qid], existing.answeredAt >= log.answeredAt { continue }
            latestLog[qid] = log
        }
        let mistakeIDs = Set(latestLog.values.filter { !$0.isCorrect }.map { $0.question.id })
        let pool = allQuestions.filter { $0.grade <= grade && mistakeIDs.contains($0.id) }.shuffled()
        return Array(pool.prefix(count))
    }
}
