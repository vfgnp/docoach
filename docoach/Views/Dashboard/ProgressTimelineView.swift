import SwiftUI
import Charts

struct ProgressTimelineView: View {
    let logs: [AnswerLog]

    private var dailyPoints: [DailyPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) {
            calendar.startOfDay(for: $0.answeredAt)
        }
        return grouped.map { date, dayLogs in
            let rate = Double(dayLogs.filter(\.isCorrect).count) / Double(dayLogs.count)
            return DailyPoint(date: date, correctRate: rate, count: dayLogs.count)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("📈 日べつ せいとう率")
                .font(Kids.font(18, .black))
                .foregroundStyle(Kids.textDark)

            if dailyPoints.isEmpty {
                Text("データがまだないよ。")
                    .font(Kids.font(15, .bold))
                    .foregroundStyle(Kids.textMuted)
            } else {
                Chart(dailyPoints) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("正答率", point.correctRate)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Kids.blue)
                    .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("正答率", point.correctRate)
                    )
                    .foregroundStyle(Kids.blue)
                    .symbolSize(120)
                    .annotation(position: .top) {
                        Text("\(Int(point.correctRate * 100))%")
                            .font(Kids.font(12, .black))
                            .foregroundStyle(Kids.textMuted)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1.0]) { val in
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text("\(Int(d * 100))%")
                                    .font(Kids.font(12, .bold))
                                    .foregroundStyle(Kids.textMuted)
                            }
                        }
                        AxisGridLine().foregroundStyle(Kids.track)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidsCard(radius: 22, depth: 5)
    }
}

private struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let correctRate: Double
    let count: Int
}
