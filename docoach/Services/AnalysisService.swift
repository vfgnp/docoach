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

    /// 難易度別の基準秒数
    static let baselineSec: [Int: Double] = [1: 30, 2: 60, 3: 90]

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
            let baseline = baselineSec[medianDiff] ?? 60.0
            let exceeds = Double(tagLogs.filter { Double($0.timeSec) > baseline }.count)
            let timeExceedRate = exceeds / total

            let weakScore = (errorRate * 0.7) + (timeExceedRate * 0.3)

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
}

private extension Array where Element == Int {
    var middle: Element? {
        guard !isEmpty else { return nil }
        return sorted()[count / 2]
    }
}
