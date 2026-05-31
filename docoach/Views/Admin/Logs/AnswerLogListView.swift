import SwiftUI
import SwiftData

struct AnswerLogListView: View {
    @Query(sort: \AnswerLog.answeredAt, order: .reverse) private var logs: [AnswerLog]

    @State private var selectedGrade: Int = 0

    private var filtered: [AnswerLog] {
        selectedGrade == 0
            ? logs
            : logs.filter { $0.grade == selectedGrade }
    }

    private var correctRate: String {
        guard !filtered.isEmpty else { return "—" }
        let rate = Int(Double(filtered.filter(\.isCorrect).count) / Double(filtered.count) * 100)
        return "\(rate)%"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("正答率").foregroundStyle(.secondary)
                    Spacer()
                    Text(correctRate).bold()
                }
                HStack {
                    Text("正解数").foregroundStyle(.secondary)
                    Spacer()
                    Text("\(filtered.filter(\.isCorrect).count) 問").bold()
                }
            } header: {
                Text("サマリー")
            }

            Section("解答履歴") {
                ForEach(filtered) { log in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: log.isCorrect
                              ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(log.isCorrect ? .green : .red)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.question.questionText)
                                .font(.body)
                                .lineLimit(2)
                            HStack {
                                Text(log.answeredAt.formatted(.dateTime.month().day().hour().minute()))
                                Text("·")
                                Text("\(log.timeSec)秒")
                                Text("·")
                                Text("小学\(log.grade)年")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("解答ログ")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Picker("学年", selection: $selectedGrade) {
                    Text("全").tag(0)
                    Text("4年").tag(4)
                    Text("5年").tag(5)
                    Text("6年").tag(6)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
    }
}
