---
layout: post
title:  "n8nワークフローのリファクタリング"
date:   2025-08-05 05:00:55+0900
categories: [n8n, 自動化, リファクタリング]
---
n8nのワークフロー、あれは沼です。気をつけないと時間が溶けてしまいます。
考え出すとキリが無いため、いっそのこととClaudeとGeminiという下請けに相談すると「はいよろこんで」となりました。
ええのかそれで…

<!--more-->

<div class="kaerebalink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="kaerebalink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fitem.rakuten.co.jp%2Fgakufu-nets%2Ff0230577%2F%3Frafcid%3Dwsc_i_is_1087413314923222742" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/gakufu-nets/cabinet/score_images/230001-231000/f0230577.jpg?_ex=128x128" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"></div><div class="kaerebalink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="kaerebalink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fitem.rakuten.co.jp%2Fgakufu-nets%2Ff0230577%2F%3Frafcid%3Dwsc_i_is_1087413314923222742" target="_blank" >楽譜 WSJ-00102 はいよろこんで/こっちのけんと(吹奏楽J-POP/難易度:3/演奏時間:2分40秒)</a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"><div class="kaerebalink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://kaereba.com" rel="nofollow" target="_blank">カエレバ</a></div></div><div class="kaerebalink-detail" style="margin-bottom:5px;"></div><div class="kaerebalink-link1" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fsearch.rakuten.co.jp%2Fsearch%2Fmall%2F%25E3%2581%25AF%25E3%2581%2584%25E3%2582%2588%25E3%2582%258D%25E3%2581%2593%25E3%2582%2593%25E3%2581%25A7%2F-%2Ff.1-p.1-s.1-sf.0-st.A-v.2%3Fx%3D0" target="_blank" >楽天市場で探す</a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E3%2581%25AF%25E3%2581%2584%25E3%2582%2588%25E3%2582%258D%25E3%2581%2593%25E3%2582%2593%25E3%2581%25A7%26__mk_ja_JP%3D%25E3%2582%25AB%25E3%2582%25BF%25E3%2582%25AB%25E3%2583%258A" target="_blank" >Amazonで探す</a><img src="//i.moshimo.com/af/i/impression?a_id=920708&p_id=170&pc_id=185&pl_id=4062" width="1" height="1" style="border:none;"></div><div class="shoplinkyahoo" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=4986064&p_id=1225&pc_id=1925&pl_id=18502&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fsearch.shopping.yahoo.co.jp%2Fsearch%3Fp%3D%25E3%2581%25AF%25E3%2581%2584%25E3%2582%2588%25E3%2582%258D%25E3%2581%2593%25E3%2582%2593%25E3%2581%25A7" target="_blank" >Yahooショッピングで探す</a><img src="//i.moshimo.com/af/i/impression?a_id=4986064&p_id=1225&pc_id=1925&pl_id=18502" width="1" height="1" style="border:none;"></div></div></div><div class="booklink-footer" style="clear: left"></div></div>

実はn8nワークフローは内部的にJSONのコードで保持しており、普通にダウンロードできるので、これをClaudeやGeminiの見えるところにおいてから、それをClaudeに読み込ませました。その上でGoogleスプレッドシートを使っているので、それをスクショしてテーブル関係も理解してもらってから作業スタート。

- 一応設定していたクールタイム(記事取得後一定時間は取りに行かないようにする)はまだ機能してなかったのでどうしたら良いのか?
    - クールタイムチェックのフィルターノードを追加し、該当するサイトはフィード取得スキップすればいいじゃない
- 複数サイトから同内容のものが入ってくるようになってきたので、内容面での重複を排除したい
    - 一旦文字列類似度(Levenshtein距離など)を使って類似性をざっくりチェックして、類似度の高いものはまずスキップ
    - さらにAIで疑わしいもののを判定させる
と、それなりの提案を出してきたので採用、実装させたところ今のところスッキリしたみたいでよかったです。

ただ、これをやり出すと発生するのがCodeノードが増えて行きかねないこと。そしてこれ…

```json
 {
      "parameters": {
        "jsCode": "// 簡易類似度チェック - タイトルとキーワードベース\nconst currentItems = items;\nconst duplicates = [];\nconst unique = [];\n\nfor (let i = 0; i < currentItems.length; i++) {\n  const currentItem = currentItems[i];\n  const currentTitle = currentItem.json.output || '';\n  \n  let isDuplicate = false;\n  \n  // 同じバッチ内での重複チェック\n  for (let j = 0; j < i; j++) {\n    const compareItem = currentItems[j];\n    const compareTitle = compareItem.json.output || '';\n    \n    // タイトルの類似度チェック（簡易版）\n    const similarity = calculateSimilarity(currentTitle, compareTitle);\n    \n    if (similarity > 0.7) { // 70%以上類似\n      isDuplicate = true;\n      break;\n    }\n  }\n  \n  if (isDuplicate) {\n    duplicates.push(currentItem);\n  } else {\n    unique.push(currentItem);\n  }\n}\n\n// 文字列類似度計算（簡易版）\nfunction calculateSimilarity(str1, str2) {\n  if (!str1 || !str2) return 0;\n  \n  // 正規化\n  const s1 = str1.toLowerCase().replace(/[^\\w\\s]/g, '').trim();\n  const s2 = str2.toLowerCase().replace(/[^\\w\\s]/g, '').trim();\n  \n  if (s1 === s2) return 1;\n  \n  // 単語ベース類似度\n  const words1 = s1.split(/\\s+/);\n  const words2 = s2.split(/\\s+/);\n  \n  const commonWords = words1.filter(word => words2.includes(word));\n  const totalWords = Math.max(words1.length, words2.length);\n  \n  return totalWords > 0 ? commonWords.length / totalWords : 0;\n}\n\nreturn unique;"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        -384,
        -240
      ],
      "id": "simple-similarity-check",
      "name": "簡易類似度チェック"
    },
```

ノーコードでやるのが醍醐味だったろうに、どんどんコード化していく本末転倒状態w
まあ、これでかなり重複記事も減らせて満足です。

<div class="kaerebalink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="kaerebalink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fitem.rakuten.co.jp%2Fbook%2F16387424%2F%3Frafcid%3Dwsc_i_is_1087413314923222742" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/2487/9784802612487.jpg?_ex=128x128" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"></div><div class="kaerebalink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="kaerebalink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fitem.rakuten.co.jp%2Fbook%2F16387424%2F%3Frafcid%3Dwsc_i_is_1087413314923222742" target="_blank" >ITエンジニアがときめく自動化の魔法　～仕事を効率化したくなる自動化テクニック～ [ 増井敏克 ]</a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"><div class="kaerebalink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://kaereba.com" rel="nofollow" target="_blank">カエレバ</a></div></div><div class="kaerebalink-detail" style="margin-bottom:5px;"></div><div class="kaerebalink-link1" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fsearch.rakuten.co.jp%2Fsearch%2Fmall%2F%25E8%2587%25AA%25E5%258B%2595%25E5%258C%2596%2F-%2Ff.1-p.1-s.1-sf.0-st.A-v.2%3Fx%3D0" target="_blank" >楽天市場で探す</a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E8%2587%25AA%25E5%258B%2595%25E5%258C%2596%26__mk_ja_JP%3D%25E3%2582%25AB%25E3%2582%25BF%25E3%2582%25AB%25E3%2583%258A" target="_blank" >Amazonで探す</a><img src="//i.moshimo.com/af/i/impression?a_id=920708&p_id=170&pc_id=185&pl_id=4062" width="1" height="1" style="border:none;"></div><div class="shoplinkyahoo" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=4986064&p_id=1225&pc_id=1925&pl_id=18502&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fsearch.shopping.yahoo.co.jp%2Fsearch%3Fp%3D%25E8%2587%25AA%25E5%258B%2595%25E5%258C%2596" target="_blank" >Yahooショッピングで探す</a><img src="//i.moshimo.com/af/i/impression?a_id=4986064&p_id=1225&pc_id=1925&pl_id=18502" width="1" height="1" style="border:none;"></div></div></div><div class="booklink-footer" style="clear: left"></div></div>
