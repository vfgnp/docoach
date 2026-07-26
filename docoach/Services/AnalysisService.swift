import Foundation
import SwiftData

struct TagScore: Identifiable {
    var id: UUID { tag.id }
    let tag: Tag
    var errorRate: Double       // 誤答率
    var avgTimeSec: Double      // 平均解答時間
    var timeExceedRate: Double  // 基準時間超過率
    var weakScore: Double       // 苦手度スコア
}

struct AnalysisService {

    /// タグ別の苦手度スコアを計算して返す（weakScore 降順）
    static func computeTagScores(logs: [AnswerLog], grade: Int) -> [TagScore] {
        let gradeLogs = logs.filter { $0.grade <= grade }
        guard !gradeLogs.isEmpty else { return [] }

        var tagMap: [UUID: (tag: Tag, logs: [AnswerLog])] = [:]
        for log in gradeLogs {
            for tag in log.question.tags {
                tagMap[tag.id, default: (tag, [])].logs.append(log)
            }
        }

        return tagMap.values.compactMap { entry -> TagScore? in
            let tagLogs = entry.logs
            let total = Double(tagLogs.count)
            guard total > 0 else { return nil }

            let wrong = Double(tagLogs.filter { !$0.isCorrect }.count)
            let errorRate = wrong / total

            let avgTime = tagLogs.map { Double($0.timeSec) }.reduce(0, +) / total

            let medianDiff = tagLogs.map { $0.question.difficulty }.sorted().middle ?? 2
            let baseline = AppConstants.Analysis.baselineSec[medianDiff] ?? 60.0
            let exceeds = Double(tagLogs.filter { Double($0.timeSec) > baseline }.count)
            let timeExceedRate = exceeds / total

            let weakScore = (errorRate * AppConstants.Analysis.weakScoreWeight)
                          + (timeExceedRate * AppConstants.Analysis.slowScoreWeight)

            return TagScore(
                tag: entry.tag,
                errorRate: errorRate,
                avgTimeSec: avgTime,
                timeExceedRate: timeExceedRate,
                weakScore: weakScore
            )
        }
        .sorted { $0.weakScore > $1.weakScore }
    }

    /// 苦手タグ上位 N 件を返す
    static func weakTags(from scores: [TagScore], limit: Int = 3) -> [Tag] {
        scores.prefix(limit).map(\.tag)
    }

    /// 問題ごとの最新ログを返す
    static func latestLogPerQuestion(_ logs: [AnswerLog]) -> [UUID: AnswerLog] {
        var result: [UUID: AnswerLog] = [:]
        for log in logs {
            let qid = log.question.id
            if let existing = result[qid], existing.answeredAt >= log.answeredAt { continue }
            result[qid] = log
        }
        return result
    }

    /// 指定日に「正解した」ログの件数。1日の上限判定に使う。
    /// 誤答・やり直しの試行は数えない（解答試行回数ではなく正解数で数える方針）。
    static func correctCount(in logs: [AnswerLog], on date: Date) -> Int {
        let cal = Calendar.current
        return logs.filter { $0.isCorrect && cal.isDate($0.answeredAt, inSameDayAs: date) }.count
    }

    // MARK: - 子供向け画面のサマリー（すべて AnswerLog から導出。新しい永続データは持たない）

    /// 1問でも正解した日の集合（暦日の開始時刻）
    static func correctDays(in logs: [AnswerLog]) -> Set<Date> {
        let cal = Calendar.current
        return Set(logs.filter(\.isCorrect).map { cal.startOfDay(for: $0.answeredAt) })
    }

    /// 連続で正解した日数。`today` を含まない場合は前日までの連続を数える
    /// （その日まだ解いていないだけで記録が途切れて見えるのを防ぐ）。
    static func streak(in logs: [AnswerLog], today: Date = .now) -> Int {
        let cal = Calendar.current
        let days = correctDays(in: logs)
        guard !days.isEmpty else { return 0 }

        let todayStart = cal.startOfDay(for: today)
        var cursor: Date
        if days.contains(todayStart) {
            cursor = todayStart
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: todayStart), days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    /// 今週（暦の週初めから7日分）の「正解した日」フラグ。れんぞくログイン表示用。
    static func weekProgress(in logs: [AnswerLog], today: Date = .now) -> [(date: Date, done: Bool)] {
        let cal = Calendar.current
        let days = correctDays(in: logs)
        let todayStart = cal.startOfDay(for: today)
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: todayStart)?.start else { return [] }
        return (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            return (day, days.contains(day))
        }
    }

    /// きろく画面のサマリー数値
    struct Summary {
        var correctCount: Int
        var mistakeCount: Int
        var accuracy: Double   // 0...1
        var weakTagCount: Int
    }

    /// `grade` 以下のログから集計する（grade-as-ceiling）。
    /// 「まちがい」は最新ログが不正解のままの問題数（やり直して正解したものは含めない）。
    static func summary(logs: [AnswerLog], grade: Int, tagScores: [TagScore]) -> Summary {
        let gradeLogs = logs.filter { $0.grade <= grade }
        let correct = gradeLogs.filter(\.isCorrect).count
        let latest = latestLogPerQuestion(gradeLogs)
        let mistakes = latest.values.filter { !$0.isCorrect }.count
        let accuracy = gradeLogs.isEmpty ? 0 : Double(correct) / Double(gradeLogs.count)
        let weak = tagScores.filter { $0.weakScore > 0.5 }.count
        return Summary(correctCount: correct, mistakeCount: mistakes, accuracy: accuracy, weakTagCount: weak)
    }
}

private extension Array where Element == Int {
    var middle: Element? {
        guard !isEmpty else { return nil }
        return sorted()[count / 2]
    }
}
