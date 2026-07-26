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
        VStack(alignment: .leading, spacing: 14) {
            Text("📅 がくしゅうきろく")
                .font(Kids.font(18, .black))
                .foregroundStyle(Kids.textDark)

            if records.isEmpty {
                Text("まだきろくがないよ。")
                    .font(Kids.font(15, .bold))
                    .foregroundStyle(Kids.textMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(records) { rec in
                        HStack {
                            Text(dateLabel(rec.date))
                                .font(Kids.font(16, .bold))
                                .foregroundStyle(Color(hex: 0x6B5E52))
                            Spacer()
                            Text("\(rec.correctCount)問せいかい")
                                .font(Kids.font(16, .black))
                                .foregroundStyle(Kids.blue)
                        }
                        .padding(.vertical, 11)
                        if rec.id != records.last?.id {
                            Rectangle()
                                .fill(Kids.track)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidsCard(radius: 22, depth: 5)
    }

    private func dateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return "\(m)月\(d)日（\(weekdayName(date))）"
    }

    private func weekdayName(_ date: Date) -> String {
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        let idx = Calendar.current.component(.weekday, from: date) - 1
        return symbols[idx]
    }
}
