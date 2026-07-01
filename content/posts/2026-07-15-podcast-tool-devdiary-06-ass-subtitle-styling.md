---
title: "podcast-tool 開発日記 #6 — ASS字幕と表現力"
date: 2026-07-15T05:05:00+09:00
tags:
  - podcast-tool
  - 開発日記
  - ASS字幕
  - FFmpeg
  - Python
  - TDD
categories:
  - 開発日記
draft: true
---

2025年9月23日から24日にかけて、字幕が「情報を伝えるテキスト」から「話者を区別する表現」に変わった。

前回（第5回）でSRT字幕の焼き込みが動いた。タイミングは合っている。BGMのオフセットも考慮できている。ただ、全話者のセリフが同じ白文字で表示される——ナレーターも、MCも、中の人も、見た目は区別がつかない。この状態を2日間で変えることになる。

## フォントサイズから始まった

字幕の色づけより先に、フォントサイズの問題に手がついていた。

SRTの段階では固定値（`font_size: 32`）をそのまま使っていた。短い台詞ならはみ出さないが、長いセリフは画面に収まらない。特に縦型（YouTube Shorts）の1080x1920フレームでは、横幅が狭いぶん余計に問題になる。

9月23日、`ef18651c`「動的フォントサイズ計算機能の実装」で新しいモジュール `subtitle_font_calculator.py`（154行）が生まれた。中心にある考え方はシンプルだ——「台本の中で最も長いセリフが画面幅の90%に収まるフォントサイズ」を計算する。

```python
def calculate_character_width(text: str, character_width_ratio: float = 0.6) -> float:
    """文字列の表示幅を計算

    全角文字=1.0、半角文字=character_width_ratioとして重み付け計算
    """
    width = 0.0
    for char in text:
        # 日本語文字（ひらがな、カタカナ、漢字）や全角記号は幅1.0
        if (ord(char) >= 0x3040 and ord(char) <= 0x309F) or \
           (ord(char) >= 0x30A0 and ord(char) <= 0x30FF) or \
           (ord(char) >= 0x4E00 and ord(char) <= 0x9FAF) or \
           (ord(char) >= 0xFF00 and ord(char) <= 0xFFEF):
            width += 1.0
        else:
            width += character_width_ratio
    return width
```

日本語の全角文字と英数字の半角文字では表示幅が違う。全角=1.0、半角=0.6として重み付けし、最長行の文字幅を求める。その値と画面幅・高さから逆算して「この幅なら何ピクセルのフォントが適切か」を導き出す仕組みだ。

```python
def calculate_dynamic_font_size(script, config, video_width=1920, video_height=1080) -> int:
    # 最長表示行を検出
    longest_line, max_character_width = find_longest_display_line(script)
    # 利用可能な画面領域
    available_width = video_width * (screen_width_percentage / 100.0)
    # フォント1文字あたりの概算ピクセル幅 = フォントサイズ * 0.7
    font_size_by_width = available_width / (max_character_width * 0.7)
    # 高さ制約（最大3行表示として計算）
    font_size_by_height = available_height / (max_lines * 1.2)
    # 制約の厳しい方を採用し、min/maxで丸める
    return int(max(min_font_size, min(max_font_size, min(font_size_by_width, font_size_by_height))))
```

「幅制約」と「高さ制約」のうち厳しいほうを採用し、設定した最小・最大フォントサイズの範囲に収める。動画の解像度が変わっても正しく追従する。

## ASS形式への昇格

動的フォントサイズの計算が動いたその日の夕方、`a8b5e8f5`「焼き込み字幕の色づけ（WIP）」というコミットが入った。SRTから ASS（Advanced SubStation Alpha）への移行の起点だ。

SRTは `HH:MM:SS,mmm --> HH:MM:SS,mmm` の行に続いてテキストを書くだけのシンプルな形式で、スタイリングの自由度がほぼない。一方、ASSは字幕に本格的なスタイル定義を持つ。ファイル内に `[V4+ Styles]` セクションがあり、話者ごとにフォント・文字色・縁取り色・配置を個別に設定できる。

既存の `video_audio_merger.py` には `_srt_to_ass()` という変換関数が既にあった——SRTを読み込んでASSに変換し、FFmpegで動画に焼き込む流れは作られていた。ただし全話者が同じ "Default" スタイルを使っていた。ここに話者ごとのスタイル定義を追加することが次の課題になった。

## 色変換の数学

ASSのスタイル定義で厄介なのは色の表現方式だ。HTML/CSSでは赤は `#FF0000`（RRGGBB順）だが、ASSは `0000FF`（BGR順＝BBGGRR）と逆並びになっている。

`speakers.json` の色設定は素直なHTML形式で書きたい。だから変換関数が必要になった。

```python
def _format_ass_color(html_color: str) -> str:
    """HTML色形式(RRGGBB)をASS BGR形式(BBGGRR)に変換"""
    color = html_color.lstrip('#')
    if len(color) != 6:
        raise ValueError(f"Invalid color format: {html_color}")
    r = color[0:2]
    g = color[2:4]
    b = color[4:6]
    return f"{b}{g}{r}".upper()
```

シンプルに見えるが、これを間違えると色が想定と全く違う見た目になる（赤が青になる）。後のテストで6パターンの変換ケースを網羅的に検証しているのはそのためだ。

## speakers.json に色が生えた

これまで `speakers.json` は話者名・VOICEVOXの話者ID・読み上げ速度を持つファイルだった。ここに `color`（文字色）と `outline_color`（縁取り色）が加わった。

```json
{
  "ナレーター": {
    "id": 24,
    "speed_scale": 1.2,
    "color": "FFFFFF",
    "outline_color": "FF0000"
  },
  "MC": {
    "id": 16,
    "speed_scale": 1.38,
    "color": "FFFF80",
    "outline_color": "00FF00"
  },
  "中の人": {
    "id": 3,
    "speed_scale": 1.15,
    "color": "C0FFC0",
    "outline_color": "0000FF"
  }
}
```

このファイルは音声合成の設定でもあり、字幕のデザイン定義でもある。話者の「声のプロファイル」に「見た目のプロファイル」が統合された形だ。

`_srt_to_ass()` の中でこのファイルを読み込み、`[V4+ Styles]` セクションに各話者のスタイル行を動的に生成する。

```python
if speakers:
    for speaker_name, speaker_config in speakers.items():
        if 'color' in speaker_config and 'outline_color' in speaker_config:
            primary_color_ass = _format_ass_color(speaker_config['color'])
            outline_color_ass = _format_ass_color(speaker_config['outline_color'])
            style_line = (
                f"Style: {speaker_name},{font_family},{font_size},"
                f"&H00{primary_color_ass},{secondary},"
                f"&H00{outline_color_ass},{back},"
                f"0,0,0,0,100,100,0,0,1,3,0,{alignment},20,20,{margin_v},1\n"
            )
            f.write(style_line)
```

各 `Dialogue:` 行には `Style` フィールドがあり、そこに話者名を入れることで対応するスタイルが適用される。

## 正規化キーという落とし穴

ここで一つ問題が出た。

台本の話者名は `"ナレーター: テキスト"` という形式で書かれており、処理中に小文字正規化されてキーとして扱われていた（`"ナレーター"` → `"ナレーター"`自体は日本語なので変化しないが、英字話者名の場合は `"MC"` → `"mc"` になる）。一方、スタイル定義には元の話者名（`"MC"`）を使わなければならない——ASSの `Style:` 行と `Dialogue:` 行の `Style` フィールドが一致しないとスタイルが適用されない。

`3975d4c8`「Task 1.1実装」で追加されたのが `_restore_original_speaker_name()` ヘルパー関数だ。正規化済みのキーから元の話者名を復元する。日本語文字の有無で判定したり、よく使われる英語話者名のパターンを持ったりする実装になっている。

```python
def _restore_original_speaker_name(normalized_key: str) -> str:
    """正規化されたspeaker keyから元の話者名を復元する"""
    # 日本語文字が含まれていれば大文字化不要
    # 英字のみのキーは一般的な形式に変換（mc -> MC など）
    ...
```

こういう「大文字小文字の往復」や「正規化と逆引きのミスマッチ」は、複数の処理段階を経るパイプラインで起きがちな問題だ。単体テストを書いて固めた理由はここにある。

## TDDで固める

9月24日、実装と並行してテストが書かれた。`tests/test_task_1_2_style_generation.py`（113行）が新規追加されている。

色変換の正確性確認（`_format_ass_color("FF0000") == "0000FF"` など6パターン）、speaker-specific styleが正しいASSフォーマットで生成されるかの確認、エラーハンドリングの確認——実際の出力ファイル `sample/output.auto.ass` での統合テストも含めて、全テストケースで動作確認済みとなったのが `96eae720`「ASS字幕話者別スタイリング機能の実装完了」だ。

コミットメッセージに「✅ sample/output.auto.assで実動作確認完了」と書いてある。最終的に生成されたASSファイルの `[V4+ Styles]` セクションに `MC` と `ナレーター` それぞれのスタイル行が現れ、各 `Dialogue:` 行のスタイルフィールドが正しく話者名を参照していることが確認された。

## 2日間で積み上がったもの

9月23〜24日に実装されたものを整理すると3点になる。

台本から最長セリフを検出して動画解像度に応じたフォントサイズを計算する**動的フォントサイズ計算**（`subtitle_font_calculator.py`、154行）。HTML色形式からASS BGR形式への色変換を含む、**話者別ASS V4+スタイルの動的生成**。そして正規化キーからの話者名復元を含む**スタイルルックアップの修正**。

`speakers.json` に2フィールド追加するだけで、話者ごとに色が変わる字幕が動画に入るようになった。視聴者がセリフを読まなくても「今画面の色からMCが話している」と分かる。字幕が単なる情報ではなく、演出になった瞬間だ。

## 次回予告

第7回は9月末から10月にかけての「近代化リファクタリング」へ進む。`ffmpeg_runner.py` によるFFmpeg実行の一元化、`core/models/audio/video/utils` パッケージへの分割、`ruff`・`mypy`・`pre-commit` の導入——第1回で「単一ファイル295行」だった `main.py` の面影がほぼ消えていく。

---

*この記事は `podcast-tool` のコミット履歴を一次資料として書いています。引用したコミットハッシュ・時刻・コード構成は当時のリポジトリ状態に基づきます。*
