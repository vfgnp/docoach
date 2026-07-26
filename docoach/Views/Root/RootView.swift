import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection = 0

    /// デザインのタブは「もんだい / きろく」の2つだが、管理画面への導線を消すと
    /// 問題・タグ・設定に一切たどり着けなくなるため、3つ目として残している。
    private let tabs: [(icon: String, label: String)] = [
        ("book.fill", "もんだい"),
        ("chart.bar.fill", "きろく"),
        ("gearshape.fill", "管理"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ZStack {
                switch selection {
                case 0: HomeView()
                case 1: DashboardView()
                default: AdminRootView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            KidsTabBar(selection: $selection, items: tabs)
        }
        .background(Kids.screenBackground.ignoresSafeArea())
        .task {
            try? SeedService.seedIfNeeded(context: modelContext)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "book.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Kids.blue)
            Text("Do")
                .font(Kids.font(26, .black))
                .foregroundStyle(Kids.blue)
            + Text("コーチ")
                .font(Kids.font(26, .black))
                .foregroundStyle(Kids.textDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
