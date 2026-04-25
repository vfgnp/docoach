import Foundation
import SwiftData

@Model
final class AnswerLog {
    @Attribute(.unique) var id: UUID
    var question: Question
    var isCorrect: Bool
    var timeSec: Int
    var answeredAt: Date
    var grade: Int  // 非正規化コピー（分析クエリ高速化）

    init(
        id: UUID = UUID(),
        question: Question,
        isCorrect: Bool,
        timeSec: Int,
        answeredAt: Date = .now
    ) {
        self.id = id
        self.question = question
        self.isCorrect = isCorrect
        self.timeSec = timeSec
        self.answeredAt = answeredAt
        self.grade = question.grade
    }
}
