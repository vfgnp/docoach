//
//  docoachApp.swift
//  docoach
//
//  Created by 渡邊公三 on 2026/02/15.
//

import SwiftUI
import SwiftData

@main
struct docoachApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Tag.self,
            Question.self,
            AnswerLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // スキーマ変更で既存ストアと非互換になった場合、削除して再生成
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            // ストアを破棄したらシード進捗もリセットし、再生成後に全問題を再シードさせる
            UserDefaults.standard.removeObject(forKey: SeedService.seededCountKey)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    @State private var appState = AppState()

    init() {
        // バンドルした M PLUS Rounded 1c を CoreText に登録する。
        // GENERATE_INFOPLIST_FILE = YES のため Info.plist の UIAppFonts 配列は使えない。
        Kids.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let screen = DebugScreen.fromLaunchArguments {
                    DebugScreenGallery(screen: screen)
                } else {
                    RootView()
                }
                #else
                RootView()
                #endif
            }
            .environment(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}
