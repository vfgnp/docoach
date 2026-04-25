import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var allLogs: [AnswerLog]

    private var gradeLogs: [AnswerLog] {
        allLogs.filter { $0.grade == appState.selectedGrade }
    }

    private var tagScores: [TagScore] {
        AnalysisService.computeTagScores(logs: allLogs, grade: appState.selectedGrade)
    }

    private var mistakeCount: Int {
        var latestLog: [UUID: AnswerLog] = [:]
        for log in gradeLogs {
            let qid = log.question.id
            if let existing = latestLog[qid], existing.answeredAt >= log.answeredAt { continue }
            latestLog[qid] = log
        }
        return latestLog.values.filter { !$0.isCorrect }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryCards
                    StudyHistoryView(logs: gradeLogs)
                    WeakTagChartView(scores: tagScores)
                    ProgressTimelineView(logs: gradeLogs)
                }
                .padding()
            }
            .navigationTitle("きろく")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "総解答数",
                value: "\(gradeLogs.count)",
                unit: "問",
                color: .blue
            )
            SummaryCard(
                title: "正答率",
                value: gradeLogs.isEmpty
                    ? "—"
                    : "\(Int(Double(gradeLogs.filter(\.isCorrect).count) / Double(gradeLogs.count) * 100))",
                unit: gradeLogs.isEmpty ? "" : "%",
                color: .green
            )
            SummaryCard(
                title: "苦手タグ数",
                value: "\(tagScores.filter { $0.weakScore > 0.5 }.count)",
                unit: "個",
                color: .orange
            )
            SummaryCard(
                title: "まちがい問題",
                value: "\(mistakeCount)",
                unit: "問",
                color: .red
            )
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
