import SwiftUI
import SwiftData

struct StudyHistoryView: View {
    let logs: [AnswerLog]

    private struct DayRecord: Identifiable {
        let id: Date
        let date: Date
        let count: Int
        let correctCount: Int
    }

    private var records: [DayRecord] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: logs) {
            cal.startOfDay(for: $0.answeredAt)
        }
        return grouped
            .map { DayRecord(
                id: $0.key,
                date: $0.key,
                count: $0.value.count,
                correctCount: $0.value.filter(\.isCorrect).count
            ) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("がくしゅうきろく")
                .font(.headline)

            if records.isEmpty {
                Text("まだきろくがありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(records) { rec in
                        HStack {
                            Text(rec.date, format: .dateTime.month().day())
                            + Text("（\(weekdayName(rec.date))）")
                            Spacer()
                            Text("\(rec.count)問（\(Int(Double(rec.correctCount) / Double(rec.count) * 100))%正解）")
                                .bold()
                        }
                        .font(.body)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        if rec.id != records.last?.id {
                            Divider().padding(.horizontal)
                        }
                    }
                }
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func weekdayName(_ date: Date) -> String {
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        let idx = Calendar.current.component(.weekday, from: date) - 1
        return symbols[idx]
    }
}
