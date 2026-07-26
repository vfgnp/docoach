import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            Form {
                Section {
                    Picker("上限", selection: $state.dailyLimit) {
                        Text("無限").tag(Optional<Int>.none)
                        ForEach(1...5, id: \.self) { n in
                            Text("\(n)問").tag(Optional(n))
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("1日の正解数")
                } footer: {
                    Text("正解した問題だけを数えます。まちがえた分・やり直した分は数えません。")
                }
            }
            .navigationTitle("設定")
        }
    }
}
