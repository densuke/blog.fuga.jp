---
title: "192コアの椅子取りも、永遠の11月も——足元の土台は「賢さ」と「責任」の両輪で動いている（2026年6月19日）"
date: 2026-06-19T07:30:00+09:00
tags: ["Linux", "Rust", "Firefox", "Mastodon", "FOSS", "Wayland", "AMD EPYC", "Intel", "AIコーディング"]
categories: ["技術トレンド"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日のテーマを一言で言うと「 **当たり前に使っている土台は、賢い工夫と誰かの責任の両輪で支えられている** 」です。

192コアの巨大CPUが抱える「キャッシュの取り合い」をスケジューラの工夫だけで解決する話に始まり、Rust製ライブラリが速すぎてIntel CPUの隠れたバグを叩き起こしてしまった事件、画面の色を正しく出すための地味で大切な土台づくり、SNSを外の世界へつなぐMastodonのニュースレター、そして最後はAIコーディング時代のFOSS文化をどう守るかという「永遠の11月」の問いまで。ハードウェアの奥深くから、私たち開発者の倫理まで、5本立てでお届けします。

まずは本日のYouTube動画からどうぞ！

{{< youtube "Decwb0P-qgw" >}}

---

## 今日のトピック

### 1. 192コアの「キャッシュの取り合い」をスケジューラが仲裁する——Linux 7.2 Cache Aware Scheduling

192人が働く巨大なオフィスを想像してください。机の島（チームごとの作業エリア）がいくつも分かれているのに、同じプロジェクトの仲間がなぜかバラバラの島に散らばって座っている。共有の資料を見るたびに部屋の反対側まで歩く——これが、いまの高コア数サーバーCPUの中で実際に起きている「キャッシュの取り合い」です。6月14日にLinux 7.1がリリースされた翌日、Linus Torvaldsのアナウンスで開幕したLinux 7.2の最大の目玉が、この問題に正面から挑む **Cache Aware Scheduling（CAS）** です。

現代の高コア数サーバーCPUは、巨大なキャッシュをみんなで共有するのではなく、複数の「Last Level Cache（LLC、いわゆるL3キャッシュ）」のドメインに分かれた設計が当たり前です。AMDのEPYCはチップレットごとに独立したL3キャッシュを持ち、最大で **192コア** という規模になります。ここで、同じプロセスのスレッド（＝同じ仕事仲間）が別々のLLCドメインに割り振られると、共有データが複数のLLCを行き来する「キャッシュバウンシング」が起き、処理量も応答速度も悪化してしまうのです。

CASがやることは驚くほど直感的で、「このスレッドは最近どのLLCドメインに居着いているか」を観測し、同じプロセスのスレッドをなるべく同じLLCドメインにまとめて配置する。散らばったメンバーを同じ机の島に座り直させてあげる、というわけです。`CONFIG_SCHED_CACHE` で有効化でき、過負荷・不均衡を判定するしきい値も用意され、DebugFS経由でランタイムにオン・オフできる現実的な配慮もあります。

効果は目を見張ります。AMD EPYC GenoaでChaCha20という暗号化処理を回したベンチマークでは、実行時間が50,868ミリ秒から28,349ミリ秒へ短縮——実行時間にして **約44%の短縮** （スループット換算で **約79%の向上** ）を記録しました。Intelの第4世代Xeon、Sapphire Rapidsでも、スレッドが起こされてから動き出すまでの遅延（wakeup latency）が **最大30%改善** しています。ハードウェアを一切いじらず、スケジューラがスレッドの置き場所を賢くするだけで、ここまでの差が出る。これがソフトウェアの面白いところです。ただしストリーム処理やネットワーク集約型では改善が限定的とのことで、万能薬ではなく「共有データの局所性が効くタイプの処理」に強い性質です。

開発を主導したのはIntelのTim Chen、schedulerメンテナのPeter Zijlstra、AMDのK. Prateek Nayakという顔ぶれ。レビューでは「小規模なLLC構成では精度がブレうる」という設計上のトレードオフも率直に議論されました。CAS以外にも、7.2にはx86のCPUID処理の集約や、約37年越しとなる「i486時代」の化石コードの削除、Apple M3 Macへの初期ブートサポートなどが盛り込まれており、RC1は **2026年6月28日** に予定されています。

- 出典: [Linux 7.2 Cache Aware Scheduling - Phoronix](https://www.phoronix.com/news/Linux-7.2-Scheduler) / [LWN.net article on Linux 7.2](https://lwn.net/Articles/1041668/)

---

### 2. 最大32.5倍速いのにCPUを巻き込んでクラッシュ——Firefox 151とRust製zlib-rsの2年戦争

「2年かけてやっと入れた新ライブラリが、リリース直後にIntelの一部CPUでクラッシュ祭りを引き起こした」——失敗談に聞こえますが、その実態は、メモリ安全なRustコードがハードウェアの隠れたバグを暴き出した、技術的にはむしろ誇るべき事件でした。Firefox 151が、長年使ってきたC言語のデータ圧縮ライブラリ「zlib」を、Rust製の「zlib-rs」へ置き換えたのです。

まず圧倒的な数字から。x86_64環境での **解凍** ベンチマークでは、1KBで最大5.66倍、64KBで最大 **32.50倍** 、10MBで最大20.16倍の高速化を記録しています。一方 **圧縮** 側では、すでに高速で知られるzlib-ngと比べて圧縮レベル9で約 **13.64%** 速いという結果。解凍と圧縮は別指標なので、「解凍は最大32倍、圧縮はzlib-ng比で約14%」と分けて覚えるのがポイントです。「Rustは安全だが遅い」という偏見を正面から打ち砕く数字ですね。

このzlib-rsは、Let's Encryptで知られるISRG傘下のメモリ安全推進プロジェクト「Prossimo」が戦略を立て、2023年12月にオランダのソフトウェア会社 **Tweede golf** へ開発を委託したもの。現在は非営利のTrifecta Tech Foundationへ移管されています。ただしFirefoxへの統合は約2年がかりの長丁場でした。zlib-rsは既存のzlibを差し替えられる「ドロップイン代替品」として設計されたものの、吐き出すバイト列がオリジナルとわずかに異なり、「ビット単位で同一」を期待するテストが軒並み引っかかってしまったのです。

そしてクライマックスがIntel Raptor Lake CPUバグ問題。Firefox 151のリリース直後、Intelの第13・14世代CPUでクラッシュが頻発しました。原因は驚くべきもので、Huffman符号化（データ圧縮の中核処理）の最中にコンパイラのLLVM 22が生成した「CHレジスタへの書き込み命令」が、Raptor Lakeの既知のハードウェアバグ（識別子 **RPL050** および **RPL060** ）によって誤った場所へ書き込まれ、値が壊れてクラッシュした——つまりzlib-rsのコードは正しく、 **CPUのほうが間違って実行していた** わけです。決着も象徴的で、新しい **LLVM 23** がたまたま問題の命令を生成しなくなったことで自然と回避されました。安全なコードを書いても、それを動かす土台（CPU・コンパイラ）が揺らげば足をすくわれる。逆に言えば、メモリ安全な実装だったからこそ、ハードの不具合をきれいに浮かび上がらせることができたのです。

- 出典: [zlib-rs in Firefox - Trifecta Tech Foundation](https://trifectatech.org/blog/zlib-rs-in-firefox/) / [Mozilla Firefox zlib-rs Usage - Phoronix](https://www.phoronix.com/news/Mozilla-Firefox-zlib-rs-Usage)

---

### 3. 画面の「黒背景」をGPUに肩代わりさせる——Weston 16.0 AlphaのHDRとカラーマネジメント

ここで少し、谷の底にあたる地味だけれど大切な土台の話を。私たちが見ている画面の色が「正しく」表示される裏には、こういう縁の下の力持ちがいます。2026年6月16日、CollaboraのMarius Vladが、Waylandの **参照実装** コンポジタ「Weston」の次期版、Weston 16.0 Alpha 1（バージョン番号は15.91.0）を発表しました。WestonはX11に代わる新プロトコルWaylandの「お手本」となる実装で、日常使いはGNOMEやKDEが中心ですが、新機能を真っ先に試す実験場として重要です。

今回のハイライトのひとつが、Linux 7.1で導入されたばかりの「BACKGROUND_COLOR CRTCプロパティ」の活用。画面の単色背景（真っ黒な余白など）を、レンダリング処理を介さずGPU/CRTCに直接「肩代わり」させる仕組みで、消費電力やレイテンシに効く賢い最適化です。あわせてRGBやYUVといった色の表現形式を明示指定できる「color format」コネクタ対応や、アクセシビリティ向けのグレースケール出力も追加されました。もうひとつの柱が低レベル高効率なグラフィックスAPI「Vulkan」レンダラーの安定化で、ティアリング（画面の裂け）を防ぐ明示的同期や非軸方向回転に対応しています。さらにfullscreen-shellや古いxdg-shell-v6などを思い切って削除し、コードベースをスリムに保つ「ダイエット」も実施。地味ですが、ここで磨かれた機能がやがてGNOMEやKDEへ降りてきます。安定版は2026年7月頃の予定です。

- 出典: [Wayland Weston 16 Alpha - Phoronix](https://www.phoronix.com/news/Wayland-Weston-16-Alpha) / [LWN.net article on Weston 16](https://lwn.net/Articles/1060715/)

---

### 4. ニュースレターで「オープンな社会的ウェブ」を蘇らせる——Mastodon 4.6

谷の底を抜けて、ふたたび身近な話へ。2026年6月17日、分散型SNS「Mastodon」のバージョン4.6がリリースされました。今回は技術的な新機能だけでなく、「オープンな社会的ウェブをどう持続させるか」という生々しい経営判断がにじみ出ています。

まず現状を数字で。月間アクティブユーザーは **約73.5万人** （TechCrunch報道。見方によっては100万人前後ともされ、出典で振れがあります）。ピークだった2022年11月のTwitter買収騒動時の **260万人** からは落ち着いた数字ですが、登録アカウント総数は **1,050万件以上** 、アクティブなサーバー数は **10,475インスタンス** にのぼります。一極集中ではなく無数の小さなサーバーが連合する、という分散の思想がよく表れていますね。

目玉機能のひとつが「Collections（コレクション）」。最大25アカウントまでをまとめられる、本人の同意のもとで加わるオプトイン型の機能です。そしてもっとも経営判断が色濃いのがメールニュースレター。メールの大量送信はサーバーコストを押し上げるため、サーバー管理者が個別に許可する仕組みを採用し、購読者はメールアドレスのみで匿名登録でき、なんと **Mastodonアカウントすら不要** です。つまり「Mastodonを使っていない人にもクリエイターのニュースレターを届ける」窓口を開いた——これが「オープンな社会的ウェブを蘇らせる」という言葉の実体です。

技術面ではAPIがバージョン10になり、画像処理ライブラリはImageMagickからメモリ効率に優れた **libvips** へ移行、Ruby 3.3・Node.js 22・FFmpeg 5.1が必要になりました。特筆すべきは、アクセシビリティ強化のスポンサーが **オランダ政府** であること。公共機関がオープンソースSNSのアクセシビリティに資金を出すのは、「誰もが使えるオープンな社会基盤」を政府レベルで後押しする象徴的な事例です。

- 出典: [Mastodon 4.6 - Mastodon Blog](https://blog.joinmastodon.org/2026/06/mastodon-4.6/) / [Mastodon looks to newsletters - TechCrunch](https://techcrunch.com/2026/06/17/mastodon-looks-to-newsletters-to-help-revive-the-open-social-web/)

---

### 5. 「永遠の11月」が来た——SFCがLLMでのFOSS貢献に14の推奨事項

最後は、いま画面の前にいる私たち開発者一人ひとりに、いちばん深く刺さるテーマで締めくくります。あなたがClaude CodeやCopilot CLIでコードを書いてオープンソースに貢献するとき、そのコードのライセンスはどうなるのか? 誰もが薄々気にしていたこの問いに、 **Software Freedom Conservancy（SFC）** が「FOSS貢献のためにLLM搭載の生成AIシステムを使う際の推奨事項」、 **14項目** の本格的な指針を公開しました。

この指針には印象的な前段があります。SFCは2022年にGitHub Copilotが登場したのを受けて委員会を設置し、約4年にわたって政策研究を続けてきました。そして2026年4月15日、Denver Gingerichが「 **Eternal November（永遠の11月）** 」と題したブログで強烈な問題提起をします。彼は、Opus 4.5がリリースされた **2025年11月** を、AIコーディングツールが実用性で大きく飛躍した転換点と位置づけたのです。

この命名は、1993年にAOL経由で一般ユーザーがUsenetに殺到しネット文化が永遠に変わってしまった「Eternal September（永遠の9月）」になぞらえたもの。AIツールの劇的な進化でFOSS文化を知らない新規開発者が大量に流入し始めたことに、同じ危機感を表明しているわけです。便利になったのは結構。でも、コピーレフト（成果物を同じ自由なライセンスで再配布させる仕組み）やライセンス遵守の作法を知らないまま貢献が始まれば、コミュニティの根幹が揺らぐのではないか——と。

14項目の中身を少しだけ。推奨5「完全開示」は、使ったLLMとそのバージョン、使い方を機械可読な形で記録・開示すること。推奨7はプロンプトやAIとのやり取り履歴の保存。推奨9はコピーレフトのプロジェクトなら自分の変更も同じライセンスにすること。そして推奨10では「Copyleft Everything（すべてをコピーレフトに）が依然として最も安全なアプローチだ」と力強く宣言しています。同時にSFCは「我々はプロプライエタリなツールを使うことを嫌悪する」と明言しつつ、現実にツールが使われている以上「戦術的妥協」として許容し、正しい使い方へ誘導する——という現実的な路線をとります。ここに、より厳格な「懐疑・阻止」寄りのFSF（Free Software Foundation）との立場の違いが浮かび上がります。主要起草者のBradley M. KühnとDenver Gingerichが4年かけて練り上げたこの14項目は、AIと共に歩むこれからのFOSSコミュニティにとって、避けて通れない議論の出発点になるはずです。

- 出典: [LLM-backed Generative AI Recommendations - SFC](https://sfconservancy.org/llm-gen-ai/llm-backed-generative-ai-recommendations.html) / [Eternal November - SFC Blog](https://sfconservancy.org/blog/2026/apr/15/eternal-november-generative-ai-llm/)

---

## まとめ

今週の5本を貫いていたのは、「賢さ（工夫）」と「責任（維持し続ける誰か・守るべき倫理）」の両輪というテーマでした。スケジューラの賢い工夫が192コアCPUの限界をこじ開け（第1話）、メモリ安全なRustの賢さがCPUの隠れたバグまで暴き出し（第2話）、画面の色を正しく出すための地味な土台が黙々と磨かれ（第3話）、SNSを外の世界へつなぐ判断が下され（第4話）、そしてAI時代のFOSSをどう守るかという責任の議論が始まりました（第5話）。

ちょっとした横串トリビアを最後にひとつ。今週は **オランダ勢** が目立ちました。第2話のzlib-rs開発を担ったTweede golfはオランダの会社、第4話のMastodonアクセシビリティのスポンサーはオランダ政府。賢い工夫も、それを支える責任ある資金も、いろいろな国と人の手で回っているのだと実感します。

私たちが当たり前に使っている足元の土台は、誰かの賢い工夫と、誰かの地道な責任の両輪で、今日も静かに動いています。次に何気なくブラウザを開いたりサーバーを立てたりするとき、その下で働く無数の歯車に、少しだけ思いを馳せてみてください。それではまた次回！

---

## 参考文献

### トピック 1：Linux 7.2 Cache Aware Scheduling

- [Linux 7.2 Cache Aware Scheduling - Phoronix](https://www.phoronix.com/news/Linux-7.2-Scheduler)
- [Linux 7.2 x86/cpu changes - Phoronix](https://www.phoronix.com/news/Linux-7.2-x86)
- [LWN.net article on Linux 7.2](https://lwn.net/Articles/1041668/)

### トピック 2：Firefox 151とRust製zlib-rs

- [zlib-rs in Firefox - Trifecta Tech Foundation](https://trifectatech.org/blog/zlib-rs-in-firefox/)
- [Mozilla Firefox zlib-rs Usage - Phoronix](https://www.phoronix.com/news/Mozilla-Firefox-zlib-rs-Usage)
- [zlib to Trifecta Tech - Memory Safety](https://www.memorysafety.org/blog/zlib-to-trifecta-tech/)

### トピック 3：Weston 16.0 AlphaのHDRとカラーマネジメント

- [Wayland Weston 16 Alpha - Phoronix](https://www.phoronix.com/news/Wayland-Weston-16-Alpha)
- [LWN.net article on Weston 16](https://lwn.net/Articles/1060715/)

### トピック 4：Mastodon 4.6

- [Mastodon 4.6 - Mastodon Blog](https://blog.joinmastodon.org/2026/06/mastodon-4.6/)
- [Mastodon 4.6 for devs - Mastodon Blog](https://blog.joinmastodon.org/2026/06/mastodon-4-6-for-devs/)
- [Mastodon looks to newsletters - TechCrunch](https://techcrunch.com/2026/06/17/mastodon-looks-to-newsletters-to-help-revive-the-open-social-web/)

### トピック 5：SFCのLLMでのFOSS貢献14推奨事項

- [LLM-backed Generative AI Recommendations - Software Freedom Conservancy](https://sfconservancy.org/llm-gen-ai/llm-backed-generative-ai-recommendations.html)
- [Eternal November - Software Freedom Conservancy Blog](https://sfconservancy.org/blog/2026/apr/15/eternal-november-generative-ai-llm/)
- [Free Software Foundation urges AI - The Register](https://www.theregister.com/2026/03/16/free_software_foundation_urges_ai/)
