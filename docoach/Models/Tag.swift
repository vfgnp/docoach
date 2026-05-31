import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var category: String  // "skill" | "thinking" | "structure" | "vocab"
    var name: String
    var priority: Int     // 1 が最重要
    var createdAt: Date
    // Question.tags との双方向 many-to-many。inverse を明示しないと
    // SwiftData が 2 つの独立した関係として扱い、付与したタグが永続化されない。
    @Relationship(inverse: \Question.tags) var questions: [Question]

    init(
        id: UUID = UUID(),
        category: String,
        name: String,
        priority: Int = 1,
        createdAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.priority = priority
        self.createdAt = createdAt
        self.questions = []
    }
}

extension Tag {
    enum Category: String, CaseIterable {
        case skill, thinking, structure, vocab

        var displayName: String {
            switch self {
            case .skill:     return "読解スキル"
            case .thinking:  return "思考レベル"
            case .structure: return "文構造"
            case .vocab:     return "語彙・表現"
            }
        }
    }
}
