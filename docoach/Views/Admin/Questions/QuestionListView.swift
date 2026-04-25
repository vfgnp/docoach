import SwiftUI
import SwiftData

struct QuestionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Question.createdAt, order: .reverse) private var questions: [Question]

    @State private var showForm = false
    @State private var selectedGrade: Int = 0  // 0 = 全学年
    @State private var showBatchConfirm = false
    @State private var batchResultMessage = ""
    @State private var showBatchResult = false

    private var filtered: [Question] {
        selectedGrade == 0
            ? questions
            : questions.filter { $0.grade == selectedGrade }
    }

    var body: some View {
        List {
            ForEach(filtered) { q in
                NavigationLink(destination: QuestionDetailView(question: q)) {
                    QuestionRow(question: q)
                }
            }
            .onDelete { offsets in
                offsets.map { filtered[$0] }.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
        }
        .navigationTitle("問題一覧 (\(filtered.count))")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showForm = true
                    } label: {
                        Label("問題を追加", systemImage: "plus")
                    }
                    Button {
                        showBatchConfirm = true
                    } label: {
                        Label("全問題にルビを付与", systemImage: "character.book.closed")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
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
        .sheet(isPresented: $showForm) {
            QuestionFormView(question: nil)
        }
        .confirmationDialog("全問題にルビを自動付与しますか？", isPresented: $showBatchConfirm, titleVisibility: .visible) {
            Button("付与する") { batchAnnotate() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("ルビのない問題の文章・設問に漢字の読み仮名を付与します。")
        }
        .alert("完了", isPresented: $showBatchResult) {
            Button("OK") {}
        } message: {
            Text(batchResultMessage)
        }
    }

    private func batchAnnotate() {
        var count = 0
        for q in questions {
            let newText = RubyAnnotatorService.annotate(q.text)
            let newQt   = RubyAnnotatorService.annotate(q.questionText)
            if newText != q.text || newQt != q.questionText {
                q.text = newText
                q.questionText = newQt
                count += 1
            }
        }
        try? modelContext.save()
        batchResultMessage = count > 0
            ? "\(count)件の問題にルビを付与しました。"
            : "付与対象の問題はありませんでした。"
        showBatchResult = true
    }
}

private struct QuestionRow: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("小学\(question.grade)年")
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                    .foregroundStyle(Color.accentColor)
                Text("難易度 \(question.difficulty)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(question.questionText)
                .font(.body)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
