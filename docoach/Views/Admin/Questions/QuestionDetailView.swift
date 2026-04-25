import SwiftUI

struct QuestionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let question: Question

    @State private var showEditForm = false
    @State private var showRubyDoneAlert = false
    @State private var showAlreadyAnnotatedAlert = false

    private let letters = ["ア", "イ", "ウ", "エ"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 基本情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("小学\(question.grade)年", systemImage: "graduationcap")
                        Spacer()
                        Label("難易度 \(question.difficulty)", systemImage: "star")
                        Spacer()
                        Text(question.createdAt.formatted(.dateTime.year().month().day()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    if !question.title.isEmpty || !question.author.isEmpty {
                        Divider()
                        HStack(spacing: 8) {
                            if !question.title.isEmpty {
                                Text(question.title)
                                    .font(.subheadline.bold())
                            }
                            if !question.author.isEmpty {
                                Text(question.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                // 文章
                sectionBlock(title: "文章") {
                    Text(question.text)
                        .lineSpacing(6)
                }

                // 設問
                sectionBlock(title: "設問") {
                    Text(question.questionText)
                        .font(.headline)
                }

                // 選択肢
                sectionBlock(title: "選択肢") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(question.choices.indices, id: \.self) { idx in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: idx == question.correctIndex
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(idx == question.correctIndex ? .green : .secondary)
                                Text("\(letters[idx]). \(question.choices[idx])")
                                    .foregroundStyle(idx == question.correctIndex ? .green : .primary)
                            }
                        }
                    }
                }

                // 解説
                sectionBlock(title: "解説") {
                    Text(question.explanation)
                        .lineSpacing(6)
                }

                // タグ
                if !question.tags.isEmpty {
                    sectionBlock(title: "タグ") {
                        FlowLayout(spacing: 8) {
                            ForEach(question.tags) { tag in
                                TagBadgeView(tag: tag)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("問題詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("編集") { showEditForm = true }
                    Button("ルビを自動付与") { applyRuby() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            QuestionFormView(question: question)
        }
        .alert("ルビを付与しました", isPresented: $showRubyDoneAlert) {
            Button("OK") {}
        } message: {
            Text("文章と設問の漢字にルビを付与して保存しました。")
        }
        .alert("スキップ", isPresented: $showAlreadyAnnotatedAlert) {
            Button("OK") {}
        } message: {
            Text("既にルビが付与されています。")
        }
    }

    private func applyRuby() {
        let newText = RubyAnnotatorService.annotate(question.text)
        let newQuestionText = RubyAnnotatorService.annotate(question.questionText)
        let alreadyDone = newText == question.text && newQuestionText == question.questionText
        if alreadyDone {
            showAlreadyAnnotatedAlert = true
            return
        }
        question.text = newText
        question.questionText = newQuestionText
        try? modelContext.save()
        showRubyDoneAlert = true
    }

    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
