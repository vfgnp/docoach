import Foundation
import SwiftData

@Model
final class Question {
    @Attribute(.unique) var id: UUID
    var grade: Int           // 4, 5, 6
    var title: String        // 作品タイトル（任意）
    var author: String       // 著者名（任意）
    var text: String         // 文章本文
    var questionText: String // 設問
    var choices: [String]    // 4択
    var correctIndex: Int    // 0〜3
    var explanation: String
    var difficulty: Int      // 1(易)〜3(難)
    var createdAt: Date
    var tags: [Tag]

    var correctChoice: String { choices[correctIndex] }

    init(
        id: UUID = UUID(),
        grade: Int,
        title: String = "",
        author: String = "",
        text: String,
        questionText: String,
        choices: [String],
        correctIndex: Int,
        explanation: String,
        difficulty: Int = 2,
        createdAt: Date = .now,
        tags: [Tag] = []
    ) {
        self.id = id
        self.grade = grade
        self.title = title
        self.author = author
        self.text = text
        self.questionText = questionText
        self.choices = choices
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.tags = tags
    }
}
