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
        VStack(alignment: .leading, spacing: 12) {
            Text("日別 正答率")
                .font(.headline)

            if dailyPoints.isEmpty {
                Text("データがまだありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                Chart(dailyPoints) { point in
                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("正答率", point.correctRate)
                    )
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("正答率", point.correctRate)
                    )
                    .annotation(position: .top) {
                        Text("\(Int(point.correctRate * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1.0]) { val in
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct DailyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let correctRate: Double
    let count: Int
}
