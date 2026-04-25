# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

docoach は小学4〜6年生向けの文章読解問題アプリ（iPad mini）。Swift / SwiftUI / SwiftData でオフライン完結。タグ中心設計で「苦手の理由」を可視化するのが目的。

## Build & Run

Xcode でのみビルド可能。`/Desktop/Xcode.app` に Xcode がある場合は `DEVELOPER_DIR` が必要：

```bash
# ビルド（シミュレーター向け）
DEVELOPER_DIR=~/Desktop/Xcode.app/Contents/Developer \
  xcodebuild -project docoach.xcodeproj -scheme docoach \
  -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro)' build

# テスト実行
DEVELOPER_DIR=~/Desktop/Xcode.app/Contents/Developer \
  xcodebuild -project docoach.xcodeproj -scheme docoach \
  -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro)' test

# 単体テスト（特定クラス指定）
DEVELOPER_DIR=~/Desktop/Xcode.app/Contents/Developer \
  xcodebuild -project docoach.xcodeproj -scheme docoach \
  -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro)' test -only-testing:docoachTests/ClassName

# シミュレーターにインストール・起動
# iPad mini (A17 Pro) UDID: E9EBE364-86D1-4EB6-A28C-913C8F1D38F8
DEVELOPER_DIR=~/Desktop/Xcode.app/Contents/Developer \
  xcrun simctl install E9EBE364-86D1-4EB6-A28C-913C8F1D38F8 <app_path>
DEVELOPER_DIR=~/Desktop/Xcode.app/Contents/Developer \
  xcrun simctl launch E9EBE364-86D1-4EB6-A28C-913C8F1D38F8 NYN.docoach
```

## Architecture

### データ層（SwiftData）

- **`Tag`** — タグマスタ。`category`（skill/thinking/structure/vocab）と`name`を持つ。`priority`が低いほど苦手分析での重要度が高い。`questions`配列で Question と双方向 many-to-many。
- **`Question`** — 本文（`text`）+ 設問（`questionText`）+ 4択（`choices`）+ 正答インデックス（`correctIndex`）+ 解説（`explanation`）+ 難易度（`difficulty`: 1〜3）+ `grade`（4〜6）+ `title`/`author`（任意、空文字可）。`tags`配列。
- **`AnswerLog`** — 1解答＝1レコード。上書き禁止。`grade`を非正規化コピーして分析クエリを高速化。

### サービス層

- **`SeedService`** — 起動のたびに `seedIfNeeded()` を呼ぶ。Tag が 0 件なら初回セットアップ（タグ15件投入）。問題は `UserDefaults` の `seededQuestionCount` キーで「何問インポート済みか」を管理し、バンドルの問題数が増えていれば差分だけ追加する（回答履歴は削除不要）。旧バージョンからのアップデート時は現在のDB問題数を起点にして重複を防ぐ。
- **`AnalysisService`** — 全 AnswerLog からタグ別苦手度を計算。`weakScore = 誤答率×0.7 + 時間超過率×0.3`。難易度別基準時間：易=30秒, 普=60秒, 難=90秒。**grade-as-ceiling**: `grade <= selectedGrade` のログを統合して計算（タグスキルは学年横断）。
- **`QuestionSelector`** — セッション問題選択ロジック。苦手タグ問題60% / 通常40%。解答済み問題は除外。**grade-as-ceiling**: `grade <= selectedGrade` の問題プールを使用（4年生→grade 4のみ、5年生→grade 4+5、6年生→全問）。`selectMistakes()` は最後の解答が不正解だった問題を返す（まちがい練習用）。
- **`RubyAnnotatorService`** — CFStringTokenizer を使って日本語テキストの漢字に `{漢字|よみ}` 形式のルビを自動付与。既にルビが含まれる場合はスキップ。末尾ひらがなをトークンから分離して漢字部分だけにルビを付与（例: "帰って" → `{帰|かえ}って`）。`needsRuby(base:forGrade:)` で小学1〜6年配当漢字辞書（`kanjiGrade`、1026字）を参照し、習得済み漢字かを判定。

### アプリ状態

- **`AppState`** — `@Observable` マクロ。`selectedGrade`（4/5/6）と `dailyLimit`（1日の出題数上限、`nil` で無制限）を保持。`dailyLimit` は `UserDefaults` に永続化。`docoachApp` で `@State` 生成し `.environment(appState)` で注入。

### View 構成

**RootView** が TabView で3タブを束ねる：
1. **HomeView**（もんだい）— 学年・苦手タグを分析し `QuestionSelector` で問題セットを構築、`QuizSessionView` をシート表示。
2. **DashboardView**（きろく）— `WeakTagChartView`（苦手タグ棒グラフ）＋ `ProgressTimelineView`（日別正答率推移）＋ `StudyHistoryView`（日別解答数一覧）。
3. **AdminRootView**（管理）— `QuestionListView`/`QuestionFormView`/`QuestionDetailView`（問題CRUD）、`TagListView`/`TagFormView`（タグCRUD）、`AnswerLogListView`（ログ閲覧）、`SettingsView`（1日の出題数上限設定）。

**クイズフロー**（`QuizSessionView`内の`SessionPhase`ステートマシン）:
```
.quiz（初期N問、フィードバックなし）
  → 全問正解: dismiss()
  → 不正解あり: .mistakeReview（「X問まちがえたよ」画面）
      → 「といなおす」: .retry（不正解問題のみ、また間違えたら末尾追加して繰り返す）
          → 全問正解: dismiss()
```
- フィードバックは**一切表示しない**。答えたら即次の問題へ。
- 不正解問題は `.retry` フェーズで末尾 append して全問正解するまでループ。
- `MistakeReviewView`（`QuizSessionView.swift` 内 private struct）に「やめる」ボタンはなく、ナビバーの「終了」が唯一の離脱手段。🐱猫が🐭ネズミを追いかけるアニメーション（`ChaseView`）付き。
- `startTime` は問題ごとに `submitAnswer()` 内でリセットされる（`.now`）ため `timeSec` は1問あたりの所要時間。

**ルビ表示**: `RubyAnnotatorService.annotate()` でテキストに `{漢字|かんじ}` 形式のマークアップを付与し、`RubyTextView`（`UITextView` ラッパー）で CoreText のルビ注釈として描画する。`RubyTextView(text:grade:)` の `grade` に `appState.selectedGrade` を渡すと、その学年以下で習う漢字のルビを非表示にする（`grade: 0` = 全ルビ表示）。`ReadingView` は `grade` を渡しているが、`AnswerView` 内の `RubyTextView` は `grade` を渡していない（全ルビ表示）。

### scripts/

- **`gen_icon.py`** — Pillow を使ってアプリアイコン PNG（light/dark/tinted）を `AppIcon.appiconset/` に生成。`python3 scripts/gen_icon.py` で実行。
- **`generate_questions.py`** — Anthropic API（要 `ANTHROPIC_API_KEY`）を使って `questions_bundle.json` を生成。`--input-dir` で入力ディレクトリ、`--limit` でファイル数上限、`--append` で既存bundleへの追記が可能。APIキーがない場合はClaude Codeが直接問題を生成できる。

### questions_bundle.json（問題バンドル）

`docoach/questions_bundle.json` を Bundle に含めると、初回起動時に `SeedService` が自動投入する。**Xcode で追加する場合は必ず Copy Bundle Resources にターゲットを追加すること。**

JSON スキーマ：
```json
{
  "questions": [
    {
      "grade": 5,
      "title": "作品タイトル（省略可）",
      "author": "著者名（省略可）",
      "text": "本文（複数段落は \\n で区切る）",
      "questionText": "設問文",
      "choices": ["選択肢A", "選択肢B", "選択肢C", "選択肢D"],
      "correctIndex": 1,
      "explanation": "解説文",
      "difficulty": 2,
      "tags": ["主題把握", "推論"]
    }
  ]
}
```

制約：`choices` は必ず4要素、`correctIndex` は 0〜3、`difficulty` は 1〜3、`grade` は 4〜6、`tags` の名前は下記15件と完全一致。

### Tag カテゴリと有効なタグ名（15件）

`Tag.category` の有効値は `"skill"`, `"thinking"`, `"structure"`, `"vocab"`。

| category | name | priority |
|----------|------|----------|
| skill | 主題把握 | 1 |
| skill | 要点抽出 | 1 |
| skill | 指示語 | 2 |
| skill | 心情理解 | 1 |
| skill | 場面理解 | 3 |
| thinking | 推論 | 1 |
| thinking | 抽象理解 | 1 |
| thinking | 事実理解 | 3 |
| structure | 因果関係 | 1 |
| structure | 具体⇄抽象 | 1 |
| structure | 対比 | 2 |
| structure | 時系列 | 3 |
| vocab | 抽象語 | 2 |
| vocab | 慣用句 | 2 |
| vocab | 多義語 | 2 |

### SeedService とデータリセット

- **問題追加**は `questions_bundle.json` を更新してアプリをリリースするだけでよい。次回起動時に差分が自動追加され、回答履歴は保持される。
- **完全リセット**が必要な場合（タグ構造変更など）: シミュレーターの「Erase All Content」または Xcode の Product > Clean Build Folder + シミュレーターリセット。さらに `UserDefaults` の `seededQuestionCount` も消えるため再シードが走る。
- **現在の問題数**: `questions_bundle.json` に1286問（小川未明・新美南吉の童話から生成）。

## Key Conventions

- SwiftData モデルは `@Model` + `@Attribute(.unique)` で UUID を主キーとする。
- View が複雑になったら computed property や private struct（例: `ChoiceRow`, `TagToggleRow`, `QuestionRow`）に分割してコンパイラの型推論エラーを回避する。
- `.foregroundStyle(Color.accentColor)` を使う（`.foregroundStyle(.accentColor)` はコンパイルエラーになる場合がある）。
- `AnswerLog` を insert したら即 `try? modelContext.save()` でディスクに書き込む。
- `ModelContainer` のスキーマに新しい `@Model` を追加したら `docoachApp.swift` の `Schema([...])` にも追記する。
- `ContentView.swift` / `Item.swift` / `ResultView.swift` は使用していない（前者2つは Xcode テンプレート残骸、`ResultView` はフロー変更で不要になった）。
- テストは Swift Testing フレームワーク（`@Test`, `#expect`）を使う。XCTest ではない。`docoachTests` は現在プレースホルダーのみ。
