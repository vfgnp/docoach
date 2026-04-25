import SwiftUI
import Charts

struct WeakTagChartView: View {
    let scores: [TagScore]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タグ別 苦手度")
                .font(.headline)

            if scores.isEmpty {
                Text("データがまだありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                Chart(scores.prefix(8)) { score in
                    BarMark(
                        x: .value("苦手度", score.weakScore),
                        y: .value("タグ", score.tag.name)
                    )
                    .foregroundStyle(
                        score.weakScore > 0.6 ? Color.red
                        : score.weakScore > 0.3 ? Color.orange
                        : Color.green
                    )
                    .annotation(position: .trailing) {
                        Text("\(Int(score.weakScore * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { val in
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text("\(Int(d * 100))%")
                                    .font(.caption)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: CGFloat(min(scores.count, 8)) * 44 + 20)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }
}
