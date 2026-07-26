//
//  docoachTests.swift
//  docoachTests
//
//  Created by 渡邊公三 on 2026/02/15.
//

import Testing
import Foundation
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

    // MARK: - QuestionSelector

    /// 未解答が足りなくてもセッション長は保たれ、既解答から補充される。
    /// 補充は「最新ログが不正解の問題」が優先。
    @Test func selectFillsFromAnsweredWhenFreshPoolIsShort() throws {
        let ctx = try makeContext()
        let questions = (0..<6).map { i in makeQuestion(grade: 5, text: "Q\(i)") }
        questions.forEach { ctx.insert($0) }

        // 0..3 を解答済みにする（0,1 は不正解 / 2,3 は正解）
        let logs = (0..<4).map { i in
            AnswerLog(question: questions[i], isCorrect: i >= 2, timeSec: 10)
        }
        logs.forEach { ctx.insert($0) }
        try ctx.save()

        let selected = QuestionSelector.select(
            from: questions,
            grade: 5,
            weakTags: [],
            recentLogs: logs,
            count: 5
        )

        #expect(selected.count == 5)
        // 重複しない
        #expect(Set(selected.map(\.id)).count == 5)
        // 未解答の 2 問は必ず含まれる
        let selectedIDs = Set(selected.map(\.id))
        #expect(selectedIDs.contains(questions[4].id))
        #expect(selectedIDs.contains(questions[5].id))
        // 補充は不正解だった 0,1 が優先され、正解済みの 2,3 は片方しか入らない
        #expect(selectedIDs.contains(questions[0].id))
        #expect(selectedIDs.contains(questions[1].id))
        let correctlyAnsweredIncluded = [questions[2], questions[3]]
            .filter { selectedIDs.contains($0.id) }
        #expect(correctlyAnsweredIncluded.count == 1)
    }

    /// 全問解答済みでもセッションは成立する（従来は 0 問になっていた）。
    @Test func selectStillReturnsFullSessionWhenAllAnswered() throws {
        let ctx = try makeContext()
        let questions = (0..<8).map { i in makeQuestion(grade: 4, text: "Q\(i)") }
        questions.forEach { ctx.insert($0) }
        let logs = questions.map { AnswerLog(question: $0, isCorrect: true, timeSec: 10) }
        logs.forEach { ctx.insert($0) }
        try ctx.save()

        let selected = QuestionSelector.select(
            from: questions,
            grade: 4,
            weakTags: [],
            recentLogs: logs,
            count: 5
        )

        #expect(selected.count == 5)
        #expect(Set(selected.map(\.id)).count == 5)
    }

    /// 問題総数が count に満たないときは、それ以上は返せない。
    @Test func selectReturnsWhatExistsWhenPoolSmallerThanCount() throws {
        let ctx = try makeContext()
        let questions = (0..<3).map { i in makeQuestion(grade: 4, text: "Q\(i)") }
        questions.forEach { ctx.insert($0) }
        try ctx.save()

        let selected = QuestionSelector.select(
            from: questions,
            grade: 4,
            weakTags: [],
            recentLogs: [],
            count: 5
        )

        #expect(selected.count == 3)
    }

    // MARK: - 1日の上限（正解数ベース）

    /// 上限判定は正解ログだけを数える。誤答・やり直しの試行は消費しない。
    @Test func correctCountIgnoresWrongAnswersAndOtherDays() throws {
        let ctx = try makeContext()
        let q = makeQuestion(grade: 5, text: "Q")
        ctx.insert(q)

        let today = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let logs = [
            AnswerLog(question: q, isCorrect: true,  timeSec: 10, answeredAt: today),
            AnswerLog(question: q, isCorrect: false, timeSec: 10, answeredAt: today),
            AnswerLog(question: q, isCorrect: false, timeSec: 10, answeredAt: today),
            AnswerLog(question: q, isCorrect: true,  timeSec: 10, answeredAt: today),
            AnswerLog(question: q, isCorrect: true,  timeSec: 10, answeredAt: yesterday),
        ]
        logs.forEach { ctx.insert($0) }
        try ctx.save()

        #expect(AnalysisService.correctCount(in: logs, on: today) == 2)
        #expect(AnalysisService.correctCount(in: logs, on: yesterday) == 1)
    }

    // MARK: - 子供向け画面のサマリー

    /// 連続日数は「正解した日」だけを数え、当日まだ解いていなくても前日までの連続は途切れない。
    @Test func streakCountsConsecutiveCorrectDays() throws {
        let ctx = try makeContext()
        let q = makeQuestion(grade: 5, text: "Q")
        ctx.insert(q)

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: today)! }

        // 今日・昨日・一昨日は正解、3日前は誤答のみ
        let logs = [
            AnswerLog(question: q, isCorrect: true, timeSec: 5, answeredAt: day(0)),
            AnswerLog(question: q, isCorrect: true, timeSec: 5, answeredAt: day(-1)),
            AnswerLog(question: q, isCorrect: true, timeSec: 5, answeredAt: day(-2)),
            AnswerLog(question: q, isCorrect: false, timeSec: 5, answeredAt: day(-3)),
        ]
        logs.forEach { ctx.insert($0) }
        try ctx.save()

        #expect(AnalysisService.streak(in: logs, today: today) == 3)

        // 今日ぶんが無くても、昨日までの連続は保たれる
        let withoutToday = Array(logs.dropFirst())
        #expect(AnalysisService.streak(in: withoutToday, today: today) == 2)

        // 2日以上あいたら 0
        let stale = [AnswerLog(question: q, isCorrect: true, timeSec: 5, answeredAt: day(-5))]
        #expect(AnalysisService.streak(in: stale, today: today) == 0)
    }

    /// まちがい数は「最新ログが不正解のまま」の問題数。やり直して正解したら減る。
    @Test func summaryCountsLatestMistakesOnly() throws {
        let ctx = try makeContext()
        let a = makeQuestion(grade: 4, text: "A")
        let b = makeQuestion(grade: 4, text: "B")
        [a, b].forEach { ctx.insert($0) }

        let base = Date.now
        let logs = [
            AnswerLog(question: a, isCorrect: false, timeSec: 5, answeredAt: base),
            // A はやり直して正解 → まちがいから外れる
            AnswerLog(question: a, isCorrect: true, timeSec: 5, answeredAt: base.addingTimeInterval(60)),
            AnswerLog(question: b, isCorrect: false, timeSec: 5, answeredAt: base),
        ]
        logs.forEach { ctx.insert($0) }
        try ctx.save()

        let s = AnalysisService.summary(logs: logs, grade: 4, tagScores: [])
        #expect(s.correctCount == 1)
        #expect(s.mistakeCount == 1)
        #expect(abs(s.accuracy - 1.0 / 3.0) < 0.0001)
    }

    /// 週の進捗は7日ぶん返り、正解した日だけ done になる。
    @Test func weekProgressMarksCorrectDays() throws {
        let ctx = try makeContext()
        let q = makeQuestion(grade: 4, text: "Q")
        ctx.insert(q)
        let today = Calendar.current.startOfDay(for: .now)
        let logs = [AnswerLog(question: q, isCorrect: true, timeSec: 5, answeredAt: today)]
        logs.forEach { ctx.insert($0) }
        try ctx.save()

        let week = AnalysisService.weekProgress(in: logs, today: today)
        #expect(week.count == 7)
        #expect(week.filter(\.done).count == 1)
        #expect(week.contains { $0.date == today && $0.done })
    }

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let schema = Schema([docoach.Tag.self, Question.self, AnswerLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private func makeQuestion(grade: Int, text: String) -> Question {
        Question(
            grade: grade,
            text: text,
            questionText: "設問",
            choices: ["A", "B", "C", "D"],
            correctIndex: 0,
            explanation: "解説",
            difficulty: 2
        )
    }
}
