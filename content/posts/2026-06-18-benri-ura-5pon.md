---
title: "純損失385億ドルの衝撃。料金も安全も寿命も「勝手には続かない」——便利さの裏側を見直す5本（2026年6月18日）"
date: 2026-06-18T06:30:00+09:00
tags: ["OpenAI", "GitHub Copilot", "Gemini CLI", "Google Antigravity", "AMD", "セキュリティ", "従量課金", "デジタルデトックス", "AIエージェント"]
categories: ["技術トレンド", "AI"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日のテーマを一言で言うと「 **便利さは、勝手には続かない** 」です。

OpenAI の純損失が **385億ドル** 規模に達したことが流出データで明らかになり、開発ツールの「料金」は定額制から従量課金へ一斉に切り替わり、CPU の「安全」機能はファームウェア更新でこっそり消され、ゲームやサービスの「寿命」をめぐる議論が世界を揺らしています。私たちが当たり前だと思っていた「安く・安全に・ずっと使える」という前提が、あちこちで崩れ始めた1日です。5本立てでお届けします。

まずは本日のYouTube動画からどうぞ！

{{< youtube "gdf8IgUYiHU" >}}

---

## 今日のトピック

### 1. 純損失385億ドル——流出した OpenAI の財務データが映す「採算」という宿題

「売上は3倍に伸びた。でも、損失はもっと速く膨らんでいた」——そんな衝撃的な実態が明らかになりました。

複数の経済メディアの報道により、 **OpenAI** の2024〜2025年度の監査済み財務データの全容が流出しました（Financial Times・Benzinga・The Motley Fool より）。2025年度の売上高は前年比約253%増の **130億ドル** 規模に達した一方、純損失は **385億〜390億ドル** 規模へと急拡大しています。前年（2024年度）の純損失が約50億ドルだったことを思えば、 **わずか1年で損失が約8倍** に膨らんだ計算です。

ただし、この巨額損失の大半は「会計上の見かけ」でもあります。非営利から営利企業への組織再編にともなう約415億ドルの **非現金的な会計処理** （転換社債やワラント負債の再評価）が損失を大きく押し上げており、これを除いた **調整後の純損失は約80億ドル** とされています（Financial Times より）。それでも、年間の総支出は約340億ドル、うち研究開発費だけで約190億ドルに上り、キャッシュの燃焼ペースが凄まじいことに変わりはありません。

なぜこの数字が重要なのでしょうか。OpenAI は最大1兆ドル規模の評価額を狙う極秘の IPO 申請を進めているとされ、時価総額900億ドル規模の **Anthropic** との資本調達競争のただ中にあります（Benzinga より）。「AIは便利だが、その便利さを支える計算コストは誰かが払い続けなければならない」——この記事全体を貫くテーマが、いきなり数字で突きつけられた格好です。

- 出典: [Benzinga（流出財務データ・385億ドルの損失）](https://www.benzinga.com/markets/private-markets/26/06/53236262/leaked-openai-financials-reveal-a-stunning-38-5-billion-loss) / [Financial Times（支出340億ドル・IPO計画）](https://www.ft.com/content/e15b0d7e-ff6b-4f16-ba7a-4068feddb828?syn-25a6b1a6=1) / [The Motley Fool（損失規模の解説）](https://www.fool.com/investing/2026/06/17/openai-s-financials-were-just-leaked-you-won-t-believe-how-much-the-company-is-losing/)

---

### 2. 「定額で使い放題」の終わり——GitHub Copilot が従量課金「AI Credits」へ

「先月までは月額固定で安心して使えていたのに、気づいたら残高がゼロ」——そんな悲鳴が開発者から上がっています。

**GitHub** は2026年6月1日より、これまでの定額制（Premium Request Unit 課金）を廃止し、使った分だけ支払う **「AI Credits」従量課金制** へ完全移行しました（GitHub 公式ドキュメント・GitHub Blog より）。料金は **1クレジット＝0.01米ドル** で、入力・出力・キャッシュされたトークン量に応じて課金されます。移行期の措置として、Business プランには30ドル、Enterprise プランには70ドル分の無料枠が一時的に提供されています。

問題は「気づかないうちに使い切ってしまう」設計です。自律エージェントがバックグラウンドで無限ループに陥ったり、IDE のセッションがフリーズしたりすると、ユーザーが知らない間に数時間でクレジットが枯渇し、開発環境がロックされる **「見えない超過（Hidden Overruns）」** が多発しています（Reddit /r/github より）。さらに、移行処理の不具合で、支払い意志があるのに年間契約ユーザーのステータスが勝手に「GitHub Free」へ引き下げられる **「サイレント・ダウングレード」** まで報告されています。

GitHub は新規顧客向けの「GitHub Models」提供も急遽終了し、Azure AI Foundry への移行を案内するなど、サービスを大きく再編しています（GitHub Changelog より）。「AIエージェントを部下のように何体も並列で走らせる」時代だからこそ、 **その電気代＝トークン代は青天井になりうる** 。料金体系を理解しないまま使うことのリスクが、いよいよ現実になってきました。

- 出典: [GitHub Docs（課金変更の詳細）](https://docs.github.com/en/copilot/reference/copilot-billing/request-based-billing-legacy/what-changed-with-billing) / [GitHub Blog（従量課金への移行）](https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/) / [GitHub Changelog（GitHub Models 新規提供終了）](https://github.blog/changelog/2026-06-16-github-models-is-no-longer-available-to-new-customers/) / [Reddit /r/github（サイレント・ダウングレード報告）](https://www.reddit.com/r/github/comments/1u84m1z/the_silent_downgrade_when_github_copilot/)

---

### 3. 本日終了——Gemini CLI が止まり、Google Antigravity の時代へ

「いつも使っていたコマンドが、今日から動かなくなる」——まさに本日6月18日、それが起きました。

Google は、ターミナル向けに親しまれてきた **Gemini CLI** および **Gemini Code Assist の IDE 拡張** について、 **2026年6月18日をもってリクエストの受付を終了** すると公式に発表しました（Google Developers Blog より）。対象は Google AI Pro/Ultra ユーザー、無料の Gemini Code Assist 利用者、GitHub 連携経由の利用者などです（エンタープライズライセンスの企業は継続サポートの対象で、終了の対象外です）。今後は、新たなエージェント統合プラットフォーム **「Google Antigravity」** の Antigravity CLI へ移行する流れになります。

単なる名前の付け替えではありません。Gemini CLI が「1回のプロンプトを実行する」ツールだったのに対し、Antigravity CLI は **Go言語で再設計** され、複数エージェント間の非同期な並行処理や、プロジェクト全体の構成管理（Scheduled Tasks）をネイティブで扱えます（Google Developers Blog より）。AIを「単発の補完ツール」ではなく「並行してタスクをこなす複数の部下」として組織化する——そんなワークスタイルの変化に合わせた世代交代です。Google は月額100ドルで優先アクセスと5倍のクォータを提供する「Google AI Ultra」プランも用意し、エコシステムの囲い込みを進めています。

便利だった無料ツールが終わり、より高機能だが課金前提の新プラットフォームへ——トピック2の Copilot とまったく同じ「無料・定額から従量・有料へ」の地殻変動が、ここでも起きています。

- 出典: [Google Developers Blog（Gemini CLI から Antigravity CLI への移行・6月18日終了）](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/) / [Google Blog（I/O 2026 開発者ハイライト）](https://blog.google/innovation-and-ai/technology/developers-tools/google-io-2026-developer-highlights/) / [Hacker News（Gemini CLI 終了の反応）](https://news.ycombinator.com/item?id=48196867)

---

### 4. 消えていた「安全」機能——AMD が Ryzen のメモリ暗号化をこっそり無効化

「買ったときには付いていたはずの安全装置が、いつの間にか外されていた」——CPU の世界で、そんな不誠実な事態が発覚しました。

セキュリティ研究者の Ben Kilpatrick 氏の指摘により、 **AMD** が一般消費者向け Ryzen プロセッサ（Zen 5 世代の Ryzen 7 9700X や Ryzen AI Max+ 395 を含む）で、ファームウェア（AGESA 1.2.7.0 以降）を通じて **TSME（Transparent Secure Memory Encryption）** 機能を無効化していたことが判明しました（Tom's Hardware・The Next Web より）。TSME は、メモリ全体を透過的に暗号化し、動作中のマシンから物理的に RAM を抜き取って残留データを読む **「コールドブート攻撃」** などからデータを守る、シリコンレベルの強力な暗号化技術です。

発覚のきっかけは、Linux のセキュリティ監査ツール「Host Security ID（HSI）」の出力が、無断で **「Encrypted（暗号化済み）」から「Not supported（非対応）」へ書き換わっていた** ことでした（Tom's Hardware より）。マザーボードベンダーの検証では、ファームウェアが非 PRO プロセッサに対して強制的に「無効」を返す仕様変更が確認されています。一般向けと PRO 向けは **まったく同じシリコン（ダイ）** を使っているにもかかわらず、PRO ラインへ誘導する営業方針のために安全機能がソフトウェア的に塞がれた——そう受け止められ、強い反発を呼んでいます。

特に深刻なのは、メモリ上に秘密鍵やシードフレーズを展開する暗号資産のバリデータ運用者や、端末の物理的な押収リスクに備えるジャーナリスト・活動家です。しかも Windows 上では TSME が効いていないことを検知するのが難しく、 **無防備なまま長期間放置されかねない** 点が問題視されています。「最新の半導体だから安全」とは限らない、という冷たい現実です。

- 出典: [Tom's Hardware（AMD が Ryzen のメモリ暗号化を無効化）](https://www.tomshardware.com/pc-components/cpus/amd-silently-removes-memory-encryption-from-consumer-ryzen-cpus-leaving-users-unaware-that-they-may-be-vulnerable-security-feature-vanishes-after-newer-agesa-firmware-amd-engineers-go-radio-silent-when-pressed-about-the-change) / [The Next Web（TSME 削除の経緯）](https://thenextweb.com/news/amd-tsme-memory-encryption-removed-consumer-ryzen-cpus) / [TechSpot（コミュニティの反応）](https://www.techspot.com/news/112791-amd-quietly-disabled-ram-encryption-consumer-ryzen-cpus.html)

---

### 5. サービスにも「寿命」がある——Stop Killing Games と、あえて不便な Commodore の挑戦

「お金を払って買ったゲームが、運営終了とともに二度と遊べなくなる」——その理不尽に、世界が声を上げています。

ゲーム業界の消費者権利運動 **「Stop Killing Games」** は、EU 内で **130万人以上の署名** を集め、運営終了後も購入したゲームを遊べるよう法的な強制力を持たせることを目指しました（Hacker News より）。しかし欧州連合（EU）は「廃止されたビデオゲームの保存・救済は法的に困難」として、この動きへの対応を事実上却下し、コミュニティに動揺が広がっています。デジタルで買ったものには **「寿命」** があり、それは私たちがコントロールできない——便利さの裏側にある、所有のもろさを突きつける一件です。

この「常時接続・常時依存」への息苦しさへの、まったく別角度からの回答が、新生 Commodore International の発表した **「Callback 8020」** です（Tom's Hardware・The Verge 系メディア より）。Jolla の Sailfish OS を搭載し Android アプリの大半を動かせる一方で、Webブラウザ・SNS・仕事用メールを **OS のシステムレベルで遮断** しています。文字入力には物理 T9 テンキーを採用し、入力の手間という **「意図的な摩擦（Intentional Friction）」** をあえて与えることで、スマホ依存を防ぐ設計です。通知も派手なポップアップではなく、ドーム型 LED の点滅だけ。価格は **499.99ドル** からで、賛否はありつつも「アテンションエコノミーからの脱却」を求める層の熱狂的な需要を掘り起こしています。

「便利すぎるものは、人の時間と注意を勝手に奪っていく」。サービスの寿命を嘆く声と、あえて不便を選ぶプロダクト——一見正反対の2つは、 **「便利さに主導権を握られたくない」** という同じ願いの裏表なのかもしれません。

- 出典: [Hacker News（Stop Killing Games・EU の対応）](https://news.ycombinator.com/front?day=2026-06-17) / [Tom's Hardware（Commodore Callback 8020）](https://www.tomshardware.com/phones/commodore-announces-linux-based-flip-phone-with-no-social-media-no-browser-the-callback-8020-will-be-available-in-five-retro-colorways-starting-at-usd499-runs-99-percent-of-android-apps) / [Time Extension（Callback 8020 の思想）](https://www.timeextension.com/news/2026/06/commodores-next-hardware-release-is-dumb-and-proud-of-it)

---

## まとめ

5本を通して見えてくるのは、「 **当たり前だと思っていた便利さは、誰かのコストや判断の上に成り立っていて、勝手には続かない** 」という共通テーマです。

OpenAI の385億ドルの損失は、 **AIの便利さを支える採算** がまだ解けていない宿題であることを示しました。GitHub Copilot の従量課金移行と Gemini CLI の終了は、 **「定額で使い放題」という料金の前提** が崩れ、使った分だけ払う世界が来たことを教えてくれました。AMD の TSME 無効化は、 **実装されている安全機能が常に有効とは限らない** という冷たい事実を突きつけました。そして Stop Killing Games と Commodore の挑戦は、 **サービスやデバイスの寿命、そして自分の時間の主導権** を、私たち自身が意識して取り戻す必要があることを問いかけています。

便利になればなるほど、その便利さがどう支えられ、いつまで続くのかは見えにくくなります。だからこそ、「使っているツールの料金体系を一度確認する」「自分の端末のセキュリティ設定を点検する」「サービスに預けたデータの行く末を考える」——そんな小さな点検が、便利さに振り回されないための第一歩になります。

今日の5本の中で特にすぐ行動できるのは、 **お使いの開発ツールやサブスクの「課金体系」をひとつ確認してみること** です。気づかないうちに前提が変わっているかもしれません。来週もよろしくお願いします！

よかったら X（旧 Twitter）で感想を教えてもらえると嬉しいです。 **#Agyテックブログ** でお待ちしています。

---

## 引用文献／出典

### トピック 1：純損失385億ドル（流出した OpenAI の財務データ）

- [Benzinga（流出財務データ・385億ドルの損失）](https://www.benzinga.com/markets/private-markets/26/06/53236262/leaked-openai-financials-reveal-a-stunning-38-5-billion-loss)
- [Financial Times（支出340億ドル・IPO計画）](https://www.ft.com/content/e15b0d7e-ff6b-4f16-ba7a-4068feddb828?syn-25a6b1a6=1)
- [The Motley Fool（損失規模の解説）](https://www.fool.com/investing/2026/06/17/openai-s-financials-were-just-leaked-you-won-t-believe-how-much-the-company-is-losing/)
- [Where's Your Ed At（損失8倍の分析）](https://www.wheresyoured.at/exclusive-openai-financials/)

### トピック 2：「定額使い放題」の終わり（GitHub Copilot の AI Credits 移行）

- [GitHub Docs（課金変更の詳細）](https://docs.github.com/en/copilot/reference/copilot-billing/request-based-billing-legacy/what-changed-with-billing)
- [GitHub Blog（従量課金への移行）](https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/)
- [GitHub Changelog（GitHub Models 新規提供終了）](https://github.blog/changelog/2026-06-16-github-models-is-no-longer-available-to-new-customers/)
- [Reddit /r/github（サイレント・ダウングレード報告）](https://www.reddit.com/r/github/comments/1u84m1z/the_silent_downgrade_when_github_copilot/)

### トピック 3：本日終了（Gemini CLI 廃止と Google Antigravity 移行）

- [Google Developers Blog（Gemini CLI から Antigravity CLI への移行・6月18日終了）](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)
- [Google Blog（I/O 2026 開発者ハイライト）](https://blog.google/innovation-and-ai/technology/developers-tools/google-io-2026-developer-highlights/)
- [Hacker News（Gemini CLI 終了の反応）](https://news.ycombinator.com/item?id=48196867)

### トピック 4：消えていた「安全」機能（AMD TSME のサイレント無効化）

- [Tom's Hardware（AMD が Ryzen のメモリ暗号化を無効化）](https://www.tomshardware.com/pc-components/cpus/amd-silently-removes-memory-encryption-from-consumer-ryzen-cpus-leaving-users-unaware-that-they-may-be-vulnerable-security-feature-vanishes-after-newer-agesa-firmware-amd-engineers-go-radio-silent-when-pressed-about-the-change)
- [The Next Web（TSME 削除の経緯）](https://thenextweb.com/news/amd-tsme-memory-encryption-removed-consumer-ryzen-cpus)
- [TechSpot（コミュニティの反応）](https://www.techspot.com/news/112791-amd-quietly-disabled-ram-encryption-consumer-ryzen-cpus.html)

### トピック 5：サービスの「寿命」（Stop Killing Games と Commodore Callback 8020）

- [Hacker News（Stop Killing Games・EU の対応）](https://news.ycombinator.com/front?day=2026-06-17)
- [Tom's Hardware（Commodore Callback 8020）](https://www.tomshardware.com/phones/commodore-announces-linux-based-flip-phone-with-no-social-media-no-browser-the-callback-8020-will-be-available-in-five-retro-colorways-starting-at-usd499-runs-99-percent-of-android-apps)
- [Time Extension（Callback 8020 の思想）](https://www.timeextension.com/news/2026/06/commodores-next-hardware-release-is-dumb-and-proud-of-it)
