import SwiftUI
import SwiftData

struct TagFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tag: Tag?  // nil = 新規作成

    @State private var category: String = Tag.Category.skill.rawValue
    @State private var name: String = ""
    @State private var priority: Int = 2

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(Tag.Category.allCases, id: \.rawValue) { cat in
                            Text(cat.displayName).tag(cat.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("タグ名") {
                    TextField("例：心情理解", text: $name)
                }

                Section("優先度（1=最重要）") {
                    Stepper("優先度: \(priority)", value: $priority, in: 1...5)
                }
            }
            .navigationTitle(tag == nil ? "タグを追加" : "タグを編集")
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

    private func populateIfEditing() {
        guard let t = tag else { return }
        category = t.category
        name = t.name
        priority = t.priority
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let t = tag {
            t.category = category
            t.name = trimmed
            t.priority = priority
        } else {
            let newTag = Tag(category: category, name: trimmed, priority: priority)
            modelContext.insert(newTag)
        }
        try? modelContext.save()
        dismiss()
    }
}
