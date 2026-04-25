import SwiftUI

struct AdminRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                QuestionListView()
            }
            .tabItem { Label("問題", systemImage: "doc.text") }

            NavigationStack {
                TagListView()
            }
            .tabItem { Label("タグ", systemImage: "tag") }

            NavigationStack {
                AnswerLogListView()
            }
            .tabItem { Label("ログ", systemImage: "list.bullet.clipboard") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}
