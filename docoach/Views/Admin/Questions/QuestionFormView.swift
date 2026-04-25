import SwiftUI
import SwiftData

struct QuestionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.priority) private var allTags: [Tag]

    let question: Question?  // nil = 新規作成

    @State private var grade: Int = 4
    @State private var difficulty: Int = 2
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var text: String = ""
    @State private var questionText: String = ""
    @State private var choices: [String] = ["", "", "", ""]
    @State private var correctIndex: Int = 0
    @State private var explanation: String = ""
    @State private var selectedTagIDs: Set<UUID> = []

    private let letters = ["ア", "イ", "ウ", "エ"]

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty &&
        !questionText.trimmingCharacters(in: .whitespaces).isEmpty &&
        choices.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty } &&
        !explanation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                textSection
                questionTextSection
                choicesSection
                explanationSection
                tagsSection
            }
            .navigationTitle(question == nil ? "問題を追加" : "問題を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("基本情報") {
            Picker("学年", selection: $grade) {
                ForEach([4, 5, 6], id: \.self) { g in
                    Text("小学\(g)年").tag(g)
                }
            }
            Stepper("難易度: \(difficulty)", value: $difficulty, in: 1...3)
            TextField("タイトル（任意）", text: $title)
            TextField("著者名（任意）", text: $author)
        }
    }

    private var textSection: some View {
        Section {
            TextEditor(text: $text)
                .frame(minHeight: 160)
        } header: {
            Text("文章（本文）")
        } footer: {
            Text("ルビ記法: {漢字|かんじ} 例）{読書|どくしょ}が好きだ。")
                .font(.caption)
        }
    }

    private var questionTextSection: some View {
        Section {
            TextEditor(text: $questionText)
                .frame(minHeight: 80)
        } header: {
            Text("設問")
        } footer: {
            Text("ルビ記法: {漢字|かんじ}")
                .font(.caption)
        }
    }

    private var choicesSection: some View {
        Section {
            ForEach(choices.indices, id: \.self) { idx in
                ChoiceRow(
                    letter: letters[idx],
                    text: $choices[idx],
                    isCorrect: correctIndex == idx
                ) {
                    correctIndex = idx
                }
            }
        } header: {
            Text("選択肢（○をタップして正解を選択）")
        }
    }

    private var explanationSection: some View {
        Section("解説") {
            TextEditor(text: $explanation)
                .frame(minHeight: 100)
        }
    }

    private var tagsSection: some View {
        Section("タグ") {
            ForEach(allTags) { tag in
                TagToggleRow(
                    tag: tag,
                    isSelected: selectedTagIDs.contains(tag.id)
                ) {
                    if selectedTagIDs.contains(tag.id) {
                        selectedTagIDs.remove(tag.id)
                    } else {
                        selectedTagIDs.insert(tag.id)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func populateIfEditing() {
        guard let q = question else { return }
        grade = q.grade
        difficulty = q.difficulty
        title = q.title
        author = q.author
        text = q.text
        questionText = q.questionText
        choices = q.choices
        correctIndex = q.correctIndex
        explanation = q.explanation
        selectedTagIDs = Set(q.tags.map(\.id))
    }

    private func save() {
        let chosenTags = allTags.filter { selectedTagIDs.contains($0.id) }
        if let q = question {
            q.grade = grade
            q.difficulty = difficulty
            q.title = title
            q.author = author
            q.text = text
            q.questionText = questionText
            q.choices = choices
            q.correctIndex = correctIndex
            q.explanation = explanation
            q.tags = chosenTags
        } else {
            let newQ = Question(
                grade: grade,
                title: title,
                author: author,
                text: text,
                questionText: questionText,
                choices: choices,
                correctIndex: correctIndex,
                explanation: explanation,
                difficulty: difficulty,
                tags: chosenTags
            )
            modelContext.insert(newQ)
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Sub-views

private struct ChoiceRow: View {
    let letter: String
    @Binding var text: String
    let isCorrect: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onSelect) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCorrect ? Color.green : Color.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(letter)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextField("選択肢を入力", text: $text, axis: .vertical)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct TagToggleRow: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(Color.accentColor)
                Text(tag.name)
                    .foregroundStyle(.primary)
                Spacer()
                Text(Tag.Category(rawValue: tag.category)?.displayName ?? tag.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
