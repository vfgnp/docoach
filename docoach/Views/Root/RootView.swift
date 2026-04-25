import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("もんだい", systemImage: "book.fill")
                }

            DashboardView()
                .tabItem {
                    Label("きろく", systemImage: "chart.bar.fill")
                }

            AdminRootView()
                .tabItem {
                    Label("管理", systemImage: "gearshape.fill")
                }
        }
        .task {
            try? SeedService.seedIfNeeded(context: modelContext)
        }
    }
}
