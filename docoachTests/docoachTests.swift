//
//  docoachTests.swift
//  docoachTests
//
//  Created by 渡邊公三 on 2026/02/15.
//

import Testing
import SwiftData
@testable import docoach

struct docoachTests {

    /// Question.tags ↔ Tag.questions の many-to-many が永続化・双方向に成立することを確認する。
    /// inverse 未宣言だと SeedService が付与したタグが save 後に失われていた（回帰防止）。
    @Test func tagsPersistThroughManyToManyRelationship() throws {
        let schema = Schema([docoach.Tag.self, Question.self, AnswerLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // タグを投入
        let subject = docoach.Tag(category: "skill", name: "主題把握", priority: 1)
        let infer = docoach.Tag(category: "thinking", name: "推論", priority: 1)
        context.insert(subject)
        context.insert(infer)

        // SeedService と同じく init でタグをセットしてから insert
        let question = Question(
            grade: 5,
            text: "本文",
            questionText: "設問",
            choices: ["A", "B", "C", "D"],
            correctIndex: 1,
            explanation: "解説",
            difficulty: 2,
            tags: [subject, infer]
        )
        context.insert(question)
        try context.save()

        // 別コンテキストで再フェッチ → 永続化を確認
        let freshContext = ModelContext(container)
        let fetched = try freshContext.fetch(FetchDescriptor<Question>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.tags.count == 2)

        // 逆方向（Tag.questions）も成立しているか
        let fetchedTags = try freshContext.fetch(FetchDescriptor<docoach.Tag>())
        let subjectTag = fetchedTags.first { $0.name == "主題把握" }
        #expect(subjectTag?.questions.count == 1)
    }
}
