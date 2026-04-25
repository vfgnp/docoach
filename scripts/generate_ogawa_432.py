#!/usr/bin/env python3
"""
小川未明の童話テキストから読解問題を生成し、questions_bundle.json に追記するスクリプト。
index 432以降の143ファイルを対象に、各2問 = 計286問を追加する。
"""

import json
import os
import sys
import time
from pathlib import Path

import anthropic

# ---- 設定 ----
NOVEL_DIR = Path("/Users/watanabekouzou/Desktop/conyac/小川未明/output")
OUTPUT_PATH = Path("/Users/watanabekouzou/Desktop/docoach/docoach/questions_bundle.json")
MAX_FILE_CHARS = 10_000
MIN_FILE_CHARS = 600
QUESTIONS_PER_FILE = 2
START_INDEX = 432  # 全体リスト上のインデックス（0始まり）

TAG_SCHEDULE = [
    "主題把握",  "推論",
    "心情理解",  "指示語",
    "因果関係",  "要点抽出",
    "対比",      "抽象理解",
    "場面理解",  "具体⇄抽象",
    "抽象語",    "主題把握",
    "慣用句",    "推論",
    "時系列",    "心情理解",
    "多義語",    "因果関係",
    "要点抽出",  "事実理解",
    "抽象理解",  "具体⇄抽象",
]

ALL_TAG_NAMES = [
    "主題把握", "要点抽出", "指示語", "心情理解", "場面理解",
    "推論", "抽象理解", "事実理解",
    "因果関係", "具体⇄抽象", "対比", "時系列",
    "抽象語", "慣用句", "多義語",
]

SYSTEM_PROMPT = """あなたは小学生向け国語読解問題の作成専門家です。

【重要】このアプリの設計について：
このアプリは「タグ」を使って学習者の苦手スキルを分析します。
各タグは「読解のどのスキルが弱いか」を測定する軸です。
AnalysisService が「タグ別の誤答率 × 0.7 + 時間超過率 × 0.3」で苦手度を計算し、
苦手タグの問題を優先出題します。

【問題設計の方向】
- 「この文章にタグをつける」ではなく「指定されたスキルを測る問題を文章から作る」
- タグが示すスキルを学習者が発揮しないと解けない問題にする
- explanationは必ず「この問題は〇〇のスキルを問います」で始める

【タグの意味】
- 主題把握: 文章全体の中心テーマ・筆者の主張を把握する
- 要点抽出: 段落や文章の要点を正確に取り出す
- 指示語: こそあど言葉が何を指しているか特定する
- 心情理解: 登場人物の気持ち・感情を読み取る
- 場面理解: 場所・時間・状況を把握する
- 推論: 文章に書かれていないことを論理的に推測する
- 抽象理解: 抽象的な概念・表現の意味を理解する
- 事実理解: 文章に明示された事実を正確に読み取る
- 因果関係: 原因と結果の関係を読み取る
- 具体⇄抽象: 具体例と抽象的な主張を対応づける
- 対比: 二つの事柄の違い・対立を読み取る
- 時系列: 出来事の順序・時間の流れを把握する
- 抽象語: 抽象的な意味を持つ語の意味を問う
- 慣用句: 慣用句・ことわざの意味を問う
- 多義語: 文脈によって意味が変わる語を問う

【ルール】
- 対象学年: 小学4〜6年生
- 問題形式: 4択選択問題
- 必ず有効な JSON のみを返す（説明文・コードブロック不要）
- choices は必ず4要素
- correctIndex は 0〜3 の整数
- difficulty は 1（易）〜3（難）の整数
- tags には指定されたタグを必ず含める"""

USER_PROMPT_TEMPLATE = """次の小川未明の童話テキストから小学生向け読解問題を2問作成してください。

【文章】
{text}

【重要な指示】
- 問題1は「{tag1}」スキルを測る問題を作成してください
- 問題2は「{tag2}」スキルを測る問題を作成してください
- それぞれのexplanationは必ず「この問題は{tag1}（問題1）／{tag2}（問題2）のスキルを問います。」で始めること
- 問題1のtagsには必ず「{tag1}」を含める
- 問題2のtagsには必ず「{tag2}」を含める
- title フィールドに作品名を入れてください
- author フィールドは「小川未明」にしてください

【出力形式】（JSONのみ、説明不要）
{{
  "questions": [
    {{
      "grade": 5,
      "title": "作品名",
      "author": "小川未明",
      "text": "（文章から150〜300字の抜粋。文語は平易な現代語に直す。ルビ記号《》や｜は除く）",
      "questionText": "設問文（{tag1}スキルを問う内容）",
      "choices": ["選択肢A", "選択肢B", "選択肢C", "選択肢D"],
      "correctIndex": 1,
      "explanation": "この問題は{tag1}のスキルを問います。（理由の説明）",
      "difficulty": 2,
      "tags": ["{tag1}"]
    }},
    {{
      "grade": 5,
      "title": "作品名",
      "author": "小川未明",
      "text": "（文章から150〜300字の抜粋。文語は平易な現代語に直す。ルビ記号《》や｜は除く）",
      "questionText": "設問文（{tag2}スキルを問う内容）",
      "choices": ["選択肢A", "選択肢B", "選択肢C", "選択肢D"],
      "correctIndex": 0,
      "explanation": "この問題は{tag2}のスキルを問います。（理由の説明）",
      "difficulty": 2,
      "tags": ["{tag2}"]
    }}
  ]
}}

注意:
- grade は文章の難易度に応じて4/5/6を選んでください
- text は原文から抜粋し、難しい文語は平易な表現に直し、《》や｜などの青空文庫ルビ記号は除いてください
- choices の誤答は紛らわしいが明確に間違いのあるものにしてください
- tagsは指定タグ以外に最大1個まで追加可能（タグリスト: {all_tags}）
- correctIndex は問題ごとに均等にばらつかせてください（0〜3）
"""


def list_target_files() -> list[Path]:
    files = []
    for path in sorted(NOVEL_DIR.glob("*.txt")):
        try:
            text = path.read_text(encoding="utf-8")
            if MIN_FILE_CHARS <= len(text) <= MAX_FILE_CHARS:
                files.append(path)
        except Exception as e:
            print(f"  [WARN] {path.name}: 読み込み失敗 ({e})", file=sys.stderr)
    return files


def get_tags_for_global_index(global_index: int) -> tuple[str, str]:
    n = len(TAG_SCHEDULE)
    tag1 = TAG_SCHEDULE[(global_index * 2) % n]
    tag2 = TAG_SCHEDULE[(global_index * 2 + 1) % n]
    return tag1, tag2


def generate_questions_for_file(
    client: anthropic.Anthropic, path: Path, global_index: int
) -> list[dict]:
    text = path.read_text(encoding="utf-8")
    tag1, tag2 = get_tags_for_global_index(global_index)

    prompt = USER_PROMPT_TEMPLATE.format(
        text=text,
        tag1=tag1,
        tag2=tag2,
        all_tags="、".join(ALL_TAG_NAMES),
    )

    message = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=4096,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = message.content[0].text.strip()

    # コードブロック除去
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()

    data = json.loads(raw)
    questions = data.get("questions", [])

    validated = []
    required_tags = [tag1, tag2]
    for idx, q in enumerate(questions):
        required_tag = required_tags[idx] if idx < len(required_tags) else tag1
        q_tags = q.get("tags", [])
        if (
            isinstance(q.get("choices"), list)
            and len(q["choices"]) == 4
            and isinstance(q.get("correctIndex"), int)
            and 0 <= q["correctIndex"] <= 3
            and isinstance(q.get("difficulty"), int)
            and 1 <= q["difficulty"] <= 3
            and isinstance(q_tags, list)
            and len(q_tags) >= 1
        ):
            if required_tag not in q_tags:
                print(f"  [INFO] 問題{idx+1}: 指定タグ「{required_tag}」未含有 → 強制挿入", file=sys.stderr)
                q["tags"] = [required_tag] + [t for t in q_tags if t != required_tag][:1]
            # authorが未設定なら補完
            if "author" not in q:
                q["author"] = "小川未明"
            validated.append(q)
        else:
            print(f"  [WARN] バリデーション失敗: {q}", file=sys.stderr)

    return validated


def main():
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("エラー: ANTHROPIC_API_KEY 環境変数が設定されていません。", file=sys.stderr)
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    all_files = list_target_files()
    print(f"全有効ファイル数: {len(all_files)}")

    if len(all_files) <= START_INDEX:
        print(f"index {START_INDEX} 以降のファイルがありません。", file=sys.stderr)
        sys.exit(1)

    target_files = all_files[START_INDEX:]
    print(f"処理対象: index {START_INDEX}〜{len(all_files)-1}（{len(target_files)}ファイル）")
    print(f"生成予定問題数: {len(target_files) * QUESTIONS_PER_FILE}問\n")

    # 既存bundle読み込み
    if OUTPUT_PATH.exists():
        with OUTPUT_PATH.open(encoding="utf-8") as f:
            existing = json.load(f)
        all_questions = existing.get("questions", [])
        print(f"既存問題数: {len(all_questions)}問（追記モード）\n")
    else:
        all_questions = []

    generated_count = 0
    for local_i, path in enumerate(target_files):
        global_index = START_INDEX + local_i
        tag1, tag2 = get_tags_for_global_index(global_index)
        print(
            f"[{local_i+1}/{len(target_files)}] {path.name} (i={global_index}, {tag1}/{tag2}) 処理中...",
            end=" ", flush=True,
        )
        try:
            questions = generate_questions_for_file(client, path, global_index)
            all_questions.extend(questions)
            generated_count += len(questions)
            print(f"→ {len(questions)}問生成")
        except json.JSONDecodeError as e:
            print(f"→ JSON パースエラー: {e}", file=sys.stderr)
        except Exception as e:
            print(f"→ エラー: {e}", file=sys.stderr)

        # 10ファイルごとに中間保存
        if (local_i + 1) % 10 == 0:
            OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
            with OUTPUT_PATH.open("w", encoding="utf-8") as f:
                json.dump({"questions": all_questions}, f, ensure_ascii=False, indent=2)
            print(f"  [中間保存] 現在 {len(all_questions)}問")

        if local_i + 1 < len(target_files):
            time.sleep(0.5)

    # 最終保存
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump({"questions": all_questions}, f, ensure_ascii=False, indent=2)

    print(f"\n完了: 合計 {len(all_questions)}問を {OUTPUT_PATH} に出力しました。")
    print(f"今回追加: {generated_count}問")


if __name__ == "__main__":
    main()
