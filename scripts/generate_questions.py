#!/usr/bin/env python3
"""
novel/ ディレクトリの青空文庫テキストから Claude API で読解問題を自動生成し、
docoach/docoach/questions_bundle.json に出力するスクリプト。

使い方:
    pip install anthropic
    export ANTHROPIC_API_KEY=sk-...
    python scripts/generate_questions.py
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

import anthropic

# ---- 設定 ----
NOVEL_DIR = Path("/Users/watanabekouzou/Desktop/conyac/新美南吉/output")
OUTPUT_PATH = Path(__file__).parent.parent / "docoach" / "docoach" / "questions_bundle.json"
MAX_FILE_CHARS = 10_000
MIN_FILE_CHARS = 600  # 短すぎるファイルを除外
QUESTIONS_PER_FILE = 2

# ---- タグ配分スケジュール（priority 重みつき round-robin） ----
# priority=1 タグ（最重要）: 主題把握, 要点抽出, 心情理解, 推論, 抽象理解, 因果関係, 具体⇄抽象
# priority=2 タグ: 指示語, 対比, 抽象語, 慣用句, 多義語
# priority=3 タグ: 場面理解, 事実理解, 時系列
# → priority=1 を 2 倍の頻度で出現させる（22 スロット / サイクル）
TAG_SCHEDULE = [
    "主題把握",  "推論",      # p1, p1
    "心情理解",  "指示語",    # p1, p2
    "因果関係",  "要点抽出",  # p1, p1
    "対比",      "抽象理解",  # p2, p1
    "場面理解",  "具体⇄抽象", # p3, p1
    "抽象語",    "主題把握",  # p2, p1
    "慣用句",    "推論",      # p2, p1
    "時系列",    "心情理解",  # p3, p1
    "多義語",    "因果関係",  # p2, p1
    "要点抽出",  "事実理解",  # p1, p3
    "抽象理解",  "具体⇄抽象", # p1, p1
]
# → 22 スロット中 priority=1 が 14 回、priority=2/3 が 8 回

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

USER_PROMPT_TEMPLATE = """次の文章から小学生向け読解問題を{n}問作成してください。

【文章】
{text}

【重要な指示】
- 問題1は「{tag1}」スキルを測る問題を作成してください
- 問題2は「{tag2}」スキルを測る問題を作成してください
- それぞれのexplanationは必ず「この問題は{tag1}（問題1）／{tag2}（問題2）のスキルを問います。」で始めること
- 問題1のtagsには必ず「{tag1}」を含める
- 問題2のtagsには必ず「{tag2}」を含める

【出力形式】（JSONのみ、説明不要）
{{
  "questions": [
    {{
      "grade": 5,
      "text": "（文章から150〜300字の抜粋。文語は平易な現代語に直す）",
      "questionText": "設問文（{tag1}スキルを問う内容）",
      "choices": ["選択肢A", "選択肢B", "選択肢C", "選択肢D"],
      "correctIndex": 1,
      "explanation": "この問題は{tag1}のスキルを問います。（理由の説明）",
      "difficulty": 2,
      "tags": ["{tag1}"]
    }},
    {{
      "grade": 5,
      "text": "（文章から150〜300字の抜粋。文語は平易な現代語に直す）",
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
- text は原文から抜粋し、難しい文語は平易な表現に直してください
- choices の誤答は紛らわしいが明確に間違いのあるものにしてください
- tagsは指定タグ以外に最大1個まで追加可能（タグリスト: {all_tags}）
"""


def list_target_files(input_dir: Path | None = None) -> list[Path]:
    """MIN_FILE_CHARS以上MAX_FILE_CHARS以下のテキストファイルを列挙する"""
    target_dir = input_dir or NOVEL_DIR
    files = []
    for path in sorted(target_dir.glob("*.txt")):
        try:
            text = path.read_text(encoding="utf-8")
            if MIN_FILE_CHARS <= len(text) <= MAX_FILE_CHARS:
                files.append(path)
        except Exception as e:
            print(f"  [WARN] {path.name}: 読み込み失敗 ({e})", file=sys.stderr)
    return files


def get_tags_for_file(file_index: int) -> tuple[str, str]:
    """ファイルインデックスから担当タグ2個を返す（round-robin）"""
    n = len(TAG_SCHEDULE)
    tag1 = TAG_SCHEDULE[(file_index * 2) % n]
    tag2 = TAG_SCHEDULE[(file_index * 2 + 1) % n]
    return tag1, tag2


def generate_questions_for_file(
    client: anthropic.Anthropic, path: Path, file_index: int, n: int = QUESTIONS_PER_FILE
) -> list[dict]:
    """1ファイルから問題を生成して返す"""
    text = path.read_text(encoding="utf-8")
    tag1, tag2 = get_tags_for_file(file_index)

    if n == 1:
        # 1問のみ生成する簡略プロンプト
        prompt = f"""次の文章から小学生向け読解問題を1問作成してください。

【文章】
{text}

【重要な指示】
- 「{tag1}」スキルを測る問題を作成してください
- explanationは必ず「この問題は{tag1}のスキルを問います。」で始めること
- tagsには必ず「{tag1}」を含める

【出力形式】（JSONのみ、説明不要）
{{
  "questions": [
    {{
      "grade": 5,
      "text": "（文章から150〜300字の抜粋。文語は平易な現代語に直す）",
      "questionText": "設問文（{tag1}スキルを問う内容）",
      "choices": ["選択肢A", "選択肢B", "選択肢C", "選択肢D"],
      "correctIndex": 1,
      "explanation": "この問題は{tag1}のスキルを問います。（理由の説明）",
      "difficulty": 2,
      "tags": ["{tag1}"]
    }}
  ]
}}

注意:
- grade は文章の難易度に応じて4/5/6を選んでください
- text は原文から抜粋し、難しい文語は平易な表現に直してください
- choices の誤答は紛らわしいが明確に間違いのあるものにしてください
- tagsは指定タグ以外に最大1個まで追加可能（タグリスト: {"、".join(ALL_TAG_NAMES)}）
"""
    else:
        prompt = USER_PROMPT_TEMPLATE.format(
            n=n,
            text=text,
            tag1=tag1,
            tag2=tag2,
            all_tags="、".join(ALL_TAG_NAMES),
        )

    message = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=4096,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = message.content[0].text.strip()

    # コードブロック除去（モデルが ```json ... ``` で返す場合）
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()

    data = json.loads(raw)
    questions = data.get("questions", [])

    # 基本バリデーション + タグ検証
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
            # 指定タグが含まれているか確認（なければ強制挿入）
            if required_tag not in q_tags:
                print(
                    f"  [INFO] 問題{idx+1}: 指定タグ「{required_tag}」が未含有 → 強制挿入",
                    file=sys.stderr,
                )
                q["tags"] = [required_tag] + [t for t in q_tags if t != required_tag][:1]
            validated.append(q)
        else:
            print(f"  [WARN] バリデーション失敗: {q}", file=sys.stderr)

    return validated


def print_tag_distribution(all_questions: list[dict]) -> None:
    """生成された問題のタグ分布を表示"""
    from collections import Counter
    tag_counts: Counter = Counter()
    for q in all_questions:
        for t in q.get("tags", []):
            tag_counts[t] += 1

    print("\n=== タグ分布 ===")
    for tag, count in sorted(tag_counts.items(), key=lambda x: -x[1]):
        print(f"  {tag}: {count}問")


def main():
    parser = argparse.ArgumentParser(description="青空文庫テキストから読解問題を生成する")
    parser.add_argument(
        "--limit", type=int, default=None,
        help="処理するファイル数の上限（省略時は全件）"
    )
    parser.add_argument(
        "--n", type=int, default=QUESTIONS_PER_FILE,
        help=f"1ファイルあたりの生成問題数（省略時は{QUESTIONS_PER_FILE}）"
    )
    parser.add_argument(
        "--input-dir", type=Path, default=None,
        help="入力テキストファイルのディレクトリ（省略時は設定値）"
    )
    parser.add_argument(
        "--append", action="store_true",
        help="既存の questions_bundle.json に追記する（省略時は上書き）"
    )
    args = parser.parse_args()

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("エラー: ANTHROPIC_API_KEY 環境変数が設定されていません。", file=sys.stderr)
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)
    target_files = list_target_files(args.input_dir)

    if not target_files:
        print("対象ファイルが見つかりません。", file=sys.stderr)
        sys.exit(1)

    if args.limit:
        target_files = target_files[:args.limit]

    print(f"対象ファイル数: {len(target_files)}（1ファイルあたり{args.n}問）")
    print("タグ配分プレビュー（最初の10ファイル）:")
    for i, path in enumerate(target_files[:10]):
        t1, t2 = get_tags_for_file(i)
        tag_info = t1 if args.n == 1 else f"{t1} / {t2}"
        print(f"  [{i+1}] {path.name[:30]:30s} → {tag_info}")
    print()

    # --append: 既存の bundle を読み込んで追記
    if args.append and OUTPUT_PATH.exists():
        with OUTPUT_PATH.open(encoding="utf-8") as f:
            existing = json.load(f)
        all_questions = existing.get("questions", [])
        print(f"既存問題数: {len(all_questions)}問（追記モード）\n")
    else:
        all_questions = []

    for i, path in enumerate(target_files, 0):
        tag1, tag2 = get_tags_for_file(i)
        tag_info = tag1 if args.n == 1 else f"{tag1}/{tag2}"
        print(
            f"[{i+1}/{len(target_files)}] {path.name} ({tag_info}) を処理中...",
            end=" ",
            flush=True,
        )
        try:
            questions = generate_questions_for_file(client, path, i, n=args.n)
            all_questions.extend(questions)
            print(f"→ {len(questions)}問生成")
        except json.JSONDecodeError as e:
            print(f"→ JSON パースエラー: {e}", file=sys.stderr)
        except Exception as e:
            print(f"→ エラー: {e}", file=sys.stderr)

        # レート制限対策
        if i + 1 < len(target_files):
            time.sleep(1)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump({"questions": all_questions}, f, ensure_ascii=False, indent=2)

    print(f"\n完了: {len(all_questions)}問を {OUTPUT_PATH} に出力しました。")
    print_tag_distribution(all_questions)
    print("\n次のステップ:")
    print("  Xcode で questions_bundle.json を docoach ターゲットに追加してください。")


if __name__ == "__main__":
    main()
