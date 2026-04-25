import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            Form {
                Section("1日の出題数") {
                    Picker("上限", selection: $state.dailyLimit) {
                        Text("無限").tag(Optional<Int>.none)
                        ForEach(1...5, id: \.self) { n in
                            Text("\(n)問").tag(Optional(n))
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("設定")
        }
    }
}
