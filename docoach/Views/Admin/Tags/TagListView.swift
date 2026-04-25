import SwiftUI
import SwiftData

struct TagListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.priority) private var tags: [Tag]

    @State private var showForm = false

    var body: some View {
        List {
            ForEach(Tag.Category.allCases, id: \.rawValue) { cat in
                let catTags = tags.filter { $0.category == cat.rawValue }
                if !catTags.isEmpty {
                    Section(cat.displayName) {
                        ForEach(catTags) { tag in
                            HStack {
                                TagBadgeView(tag: tag)
                                Spacer()
                                Text("優先度 \(tag.priority)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { catTags[$0] }.forEach { modelContext.delete($0) }
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
        .navigationTitle("タグ管理 (\(tags.count))")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showForm) {
            TagFormView(tag: nil)
        }
    }
}
