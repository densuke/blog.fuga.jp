---
title: "純損失385億ドルの衝撃。料金も安全も寿命も「勝手には続かない」——便利さの裏側を見直す5本（2026年6月18日）"
date: 2026-06-18T06:30:00+09:00
tags: ["OpenAI", "GitHub Copilot", "Gemini CLI", "Google Antigravity", "AMD", "セキュリティ", "従量課金", "デジタルデトックス", "AIエージェント"]
categories: ["技術トレンド", "AI"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日のテーマを一言で言うと「 **便利さは、勝手には続かない** 」です。

OpenAI の純損失が **385億ドル** 規模に達したことが流出データで明らかになり、CPU の「安全」機能はファームウェア更新でこっそり消され、開発ツールの「料金」は定額制から従量課金へ一斉に切り替わり、そしてあえて「不便」を選ぶ携帯電話が登場しました。私たちが当たり前だと思っていた「安く・安全に・ずっと使える」という前提が、あちこちで崩れ始めた1日です。5本立てでお届けします。

まずは本日のYouTube動画からどうぞ！

{{< youtube "gdf8IgUYiHU" >}}

---

## 今日のトピック

### 1. 純損失385億ドル——流出した OpenAI の財務データが映す「採算」という宿題

売上は1年で3.5倍に伸びたのに、損失はそれを上回る速さで膨らんでいた——監査済みの財務データが流出し、そんな実態が明らかになりました。

複数の経済メディアの報道により、 **OpenAI** の2024〜2025年度の財務データが流出しました（Financial Times・Benzinga・The Motley Fool より）。売上高は2024年度の37億ドルから2025年度の **130億ドル** へ、1年で **3.5倍** （率にして+253%）に伸びています。ところが研究開発費だけで **192億ドル** 、販売・マーケティング費も **57億ドル** に達し、本業の赤字を示す営業損失は **209億ドル** に膨らみました。売上130億ドルに対して研究開発費が192億ドル——稼ぎ以上に未来へ投資して燃やしている状態です。そして最終的な純損失は **385億〜390億ドル** 規模と報じられています。

ただし、この純損失の大半は「会計上の見かけ」でもあります。非営利から営利企業への組織再編にともなう約 **415億5000万ドル** の非現金的な会計処理（転換社債やワラント負債の再評価）が損失を大きく押し上げており、これを除いた **調整後の純損失でも約80億ドル** とされています。出資はソフトバンクから8.67億ドル、Microsoft から3.3億ドルを受けている一方、学習基盤として Microsoft へ105億ドル超を支払っており、入ってくるより出ていくほうがずっと大きい構図です。なお2025年末時点での月間ランレートは20億ドル規模に達しているとされます。

なぜこの数字が重要なのでしょうか。OpenAI は最大1兆ドル規模の評価額を狙う IPO 申請を進めているとされ、約900億ドル規模の **Anthropic** との資金調達競争のただ中にあります（Benzinga より）。ChatGPT の利用者の伸びも頭打ちと言われ、動画生成「Sora」のようなコストのかさむ計画は一旦棚上げされています。比較として SpaceX の2025年の営業損失が26億ドルだったことを思えば、AIへの資金の燃やし方は際立っています。「AIは便利だが、その便利さを支える計算コストは誰かが払い続けなければならない」——いきなり数字で突きつけられた格好です。

- 出典: [Benzinga（流出財務データ・385億ドルの損失）](https://www.benzinga.com/markets/private-markets/26/06/53236262/leaked-openai-financials-reveal-a-stunning-38-5-billion-loss) / [Financial Times（支出340億ドル・IPO計画）](https://www.ft.com/content/e15b0d7e-ff6b-4f16-ba7a-4068feddb828?syn-25a6b1a6=1) / [The Motley Fool（損失規模の解説）](https://www.fool.com/investing/2026/06/17/openai-s-financials-were-just-leaked-you-won-t-believe-how-much-the-company-is-losing/) / [MLQ.ai（営業損失210億ドルの内訳）](https://mlq.ai/news/leaked-openai-financials-reveal-21b-operating-loss-on-13b-revenue-in-2025/)

---

### 2. 「定額で使い放題」の終わり——GitHub Copilot が従量課金「AI Credits」へ

「月額固定で安心して使えていたのに、気づいたら残高がゼロ」——そんな悲鳴が開発者から上がっています。

**GitHub** は2026年6月1日より、これまでの定額制（Premium Request Unit 課金）を廃止し、使った分だけ支払う **「AI Credits」従量課金制** へ完全移行しました（GitHub 公式ドキュメント・GitHub Blog より）。料金は **1クレジット＝0.01米ドル** で、入力・出力・途中の処理（キャッシュ分）のトークン量に応じて課金されます。電気やガスのような従量制ですが、便利な反面、使いすぎが見えにくいのが難点です。

実際、自動で動く AI が裏側で延々と処理を繰り返し、ユーザーが気づかないうちに数時間で枠を使い切ってしまう事故が報告されています（Reddit /r/github より）。さらに、支払いの意思があるのに、移行処理の不具合で勝手に無料プラン（GitHub Free）へ格下げされる事案まで起きています。移行期は企業向けに一時的な無料枠（Business プランに30ドル、Enterprise プランに70ドルの AI Credits）が配られていますが、個人や年間契約の利用者向けの救済は、今のところはっきり示されていません。

「AIエージェントを部下のように何体も並列で走らせる」時代だからこそ、 **その電気代＝トークン代は青天井になりうる** 。当たり前に続くと思っていた契約状態すら、自分で確かめないと崩れることがある——料金体系を理解しないまま使うことのリスクが、いよいよ現実になってきました。

- 出典: [GitHub Docs（課金変更の詳細）](https://docs.github.com/en/copilot/reference/copilot-billing/request-based-billing-legacy/what-changed-with-billing) / [GitHub Blog（従量課金への移行）](https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/) / [Reddit /r/github（無料プランへの格下げ報告）](https://www.reddit.com/r/github/comments/1u84m1z/the_silent_downgrade_when_github_copilot/)

---

### 3. 本日終了——Gemini CLI が止まり、Google Antigravity の時代へ

「いつも使っていたコマンドが、今日から動かなくなる」——まさに本日6月18日、それが起きました。

Google は、ターミナルから使えた **Gemini CLI** について、 **2026年6月18日をもって終了** すると発表しました（Google Developers Blog より）。今後は、新たな統合基盤 **「Google Antigravity」** へ移行する流れです。個人向けの支援機能や組織向けの連携も同時に終わるため、移行はほぼ避けられません。

単なる名前の付け替えではありません。Gemini CLI が「1つの命令を実行する」道具だったのに対し、後継の Antigravity CLI は Go 言語で再設計され、複数の AI が自律的に連携・並行作業することを前提に設計されています。AIを「単発の補完ツール」ではなく「並行して作業する複数の部下」として組織化する——そんな働き方の変化に合わせた世代交代です。Google は月額100ドルで優先利用と5倍の枠を提供する上位プラン「Google AI Ultra」も用意し、利用者を自社の仕組みに囲い込む狙いも見えます。

便利だった無料ツールが終わり、より高機能だが課金前提の新プラットフォームへ——トピック2の Copilot とまったく同じ「定額から従量へ」の地殻変動が、ここでも起きています。性能は魅力的ですが、料金体系もツールの寿命も提供側の都合で動く、ということです。

- 出典: [Google Developers Blog（Gemini CLI から Antigravity への移行・6月18日終了）](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)

---

### 4. 消えていた「安全」機能——AMD が Ryzen のメモリ暗号化をこっそり無効化

「買ったときには付いていたはずの安全装置が、いつの間にか外されていた」——CPU の世界で、そんな事態が発覚しました。

**AMD** が一般消費者向け Ryzen プロセッサ（Zen 5 アーキテクチャの **Ryzen 7 9700X** や新型の **Ryzen AI Max+ 395** を含む）で、ファームウェア（ **AGESA 1.2.7.0 以降** ）の更新を通じて **TSME（Transparent Secure Memory Encryption）** 機能を強制的に無効化していたことが判明しました（Tom's Hardware・The Next Web より）。TSME は、利用者が意識しなくてもメモリ上のデータを自動で暗号化する仕組みで、動作中のマシンから物理的に RAM を抜き取って残留データを読む **「コールドブート攻撃」** や、メモリ配線を電気的にのぞき見る攻撃からデータを守る、シリコンレベルの強力な技術です。普段は存在を感じないからこそ、消えていても気づきにくいのが厄介な点です。

発覚のきっかけは、Ben Kilpatrick 氏が Linux のセキュリティ監査ツール **「Host Security ID（HSI）」** の出力が、無断で **「暗号化済み（Encrypted）」から「非対応（Not supported）」へ書き換わっていた** ことに気づいたことでした（Tom's Hardware より）。マザーボードベンダー（**MSI** など）の検証では、ファームウェア内部の制御フラグが、非 PRO プロセッサに対して強制的に「FALSE」を返す仕様変更が確認されています。しかも一般向けと業務（PRO）向けは **同じチップ（同一のダイ）** を使っているとされ、PRO ラインへ誘導したい営業上の方針が背景にあるのでは、と批判されています。利用者への案内は無く、勝手にオフになった点が強い反発を呼んでいます。

特に影響を受けやすいのは、メモリ上に秘密鍵やシードフレーズを置く暗号資産のバリデータや、端末を物理的に押さえられるリスクと向き合う人たちです。守りが消えていることに気づきにくいのが、特に厳しい点だと言えます。「最新の半導体だから安全」とは限らない、という冷たい現実です。なお、こうしたメモリの危うさへの対抗として、NVIDIA Labs が安全でデータレースのない GPU カーネルを Rust で書ける OSS ライブラリ「cuTile Rust」を公開し、注目を集めています。

- 出典: [Tom's Hardware（AMD が Ryzen のメモリ暗号化を無効化）](https://www.tomshardware.com/pc-components/cpus/amd-silently-removes-memory-encryption-from-consumer-ryzen-cpus-leaving-users-unaware-that-they-may-be-vulnerable-security-feature-vanishes-after-newer-agesa-firmware-amd-engineers-go-radio-silent-when-pressed-about-the-change) / [The Next Web（TSME 削除の経緯）](https://thenextweb.com/news/amd-tsme-memory-encryption-removed-consumer-ryzen-cpus) / [TechSpot（コミュニティの反応）](https://www.techspot.com/news/112791-amd-quietly-disabled-ram-encryption-consumer-ryzen-cpus.html) / [PC Perspective（TSME 削除の検証）](https://pcper.com/2026/06/amd-seems-to-have-silently-cut-tsme-memory-encryption-from-consumer-chips/)

---

### 5. あえて「不便」を選ぶ——SNS を断つ携帯電話、Commodore Callback 8020

「ネットには繋ぐ、けれどウェブには繋がない」——便利さを足し続ける流れに、あえて引き算で逆らう製品が登場しました。

Christian Simpson 氏が率いる新生 Commodore（コモドール）が発表した **「Callback 8020」** は、Jolla の **Sailfish OS** を搭載し Android アプリとの高い互換性を保ちながらも、Webブラウザも SNS も仕事用メールも OS の土台（ブートローダー）の段階で遮断しています（Tom's Hardware・GSMArena より）。合言葉は「インターネットには繋ぐけれど、ウェブには繋がない」。常時つながる息苦しさから距離を置く、という思想です。文字入力には昔ながらの **物理T9テンキー** を採用し、入力にあえて手間（意図的な摩擦）をかけることで依存を防ぐ設計。通知も目を引くポップアップではなく、ドーム型 LED ランプの点滅パターンだけで知らせます。気を散らさない徹底ぶりです。

中身も個性的で、懐かしさと実用性を両立させています。**1,550mAh** の交換できるバッテリーに、8ビットの **SID 音源チップ** と FMラジオ、そして **48メガピクセル** のソニー製カメラを搭載。Commodore 64 の名作ゲームをいくつか入れた状態で出荷され、Android のアプリもほぼ動く互換性を保っています。価格は標準モデルが **499.99ドルから** 、24k金メッキの特別版が640ドルで、懐かしさを感じる5色のレトロな配色で展開されます。安くはありませんが、熱心な需要を掘り起こしています。

「便利さは無料で無限に続く」——その前提に、お金を払ってでも距離を置く人が現れている。守りを固めることと、そもそも繋がりすぎないこと。今日の他の4本とは毛色が違いますが、どちらも **「便利さに主導権を握られたくない」** という同じ方向を向いた話だと、私は受け止めました。

- 出典: [Tom's Hardware（Commodore Callback 8020）](https://www.tomshardware.com/phones/commodore-announces-linux-based-flip-phone-with-no-social-media-no-browser-the-callback-8020-will-be-available-in-five-retro-colorways-starting-at-usd499-runs-99-percent-of-android-apps) / [GSMArena（Callback 8020 の発表）](https://www.gsmarena.com/commodore_announces_callback_8020_the_mobile_phone_between_dumb_and_smart-news-73304.php)

---

## まとめ

5本を通して見えてくるのは、「 **当たり前だと思っていた便利さは、誰かのコストや判断の上に成り立っていて、勝手には続かない** 」という共通テーマです。

OpenAI の385億ドルの損失は、 **AIの便利さを支える採算** がまだ解けていない宿題であることを示しました。AMD の TSME 無効化は、 **実装されている安全機能が常に有効とは限らない** という冷たい事実を突きつけました。GitHub Copilot の従量課金移行と Gemini CLI の終了は、 **「定額で使い放題」という料金の前提** が崩れ、使った分だけ払う世界が来たことを教えてくれました。そして Commodore の挑戦は、 **そもそも繋がりすぎないという選択肢** と、自分の時間の主導権を取り戻す動きがあることを示してくれました。

便利になればなるほど、その便利さがどう支えられ、いつまで続くのかは見えにくくなります。だからこそ、「使っているツールの料金体系を一度確認する」「自分の端末のセキュリティ設定を点検する」「契約の状態が勝手に変わっていないか見る」——そんな小さな点検が、便利さに振り回されないための第一歩になります。

今日の5本の中で特にすぐ行動できるのは、 **お使いの開発ツールやサブスクの「課金体系」をひとつ確認してみること** です。気づかないうちに前提が変わっているかもしれません。来週もよろしくお願いします！

よかったら X（旧 Twitter）で感想を教えてもらえると嬉しいです。 **#Agyテックブログ** でお待ちしています。

---

## 引用文献／出典

### トピック 1：純損失385億ドル（流出した OpenAI の財務データ）

- [Financial Times（支出340億ドル・OpenAI の IPO 計画）](https://www.ft.com/content/e15b0d7e-ff6b-4f16-ba7a-4068feddb828?syn-25a6b1a6=1)
- [Benzinga（流出財務データ・385億ドルの損失）](https://www.benzinga.com/markets/private-markets/26/06/53236262/leaked-openai-financials-reveal-a-stunning-38-5-billion-loss)
- [The Motley Fool（損失規模の解説）](https://www.fool.com/investing/2026/06/17/openai-s-financials-were-just-leaked-you-won-t-believe-how-much-the-company-is-losing/)
- [MLQ.ai（営業損失210億ドル・売上130億ドルの内訳）](https://mlq.ai/news/leaked-openai-financials-reveal-21b-operating-loss-on-13b-revenue-in-2025/)

### トピック 2：「定額使い放題」の終わり（GitHub Copilot の AI Credits 移行）

- [GitHub Docs（課金変更の詳細）](https://docs.github.com/en/copilot/reference/copilot-billing/request-based-billing-legacy/what-changed-with-billing)
- [GitHub Blog（従量課金への移行）](https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/)
- [Reddit /r/github（無料プランへの格下げ報告）](https://www.reddit.com/r/github/comments/1u84m1z/the_silent_downgrade_when_github_copilot/)

### トピック 3：本日終了（Gemini CLI 廃止と Google Antigravity 移行）

- [Google Developers Blog（Gemini CLI から Antigravity への移行・6月18日終了）](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)
- [Google Antigravity Blog（I/O 2026・Antigravity の発表）](https://antigravity.google/blog/google-io-2026)

### トピック 4：消えていた「安全」機能（AMD TSME のサイレント無効化）

- [Tom's Hardware（AMD が Ryzen のメモリ暗号化を無効化）](https://www.tomshardware.com/pc-components/cpus/amd-silently-removes-memory-encryption-from-consumer-ryzen-cpus-leaving-users-unaware-that-they-may-be-vulnerable-security-feature-vanishes-after-newer-agesa-firmware-amd-engineers-go-radio-silent-when-pressed-about-the-change)
- [The Next Web（TSME 削除の経緯）](https://thenextweb.com/news/amd-tsme-memory-encryption-removed-consumer-ryzen-cpus)
- [TechSpot（コミュニティの反応）](https://www.techspot.com/news/112791-amd-quietly-disabled-ram-encryption-consumer-ryzen-cpus.html)
- [PC Perspective（TSME 削除の検証）](https://pcper.com/2026/06/amd-seems-to-have-silently-cut-tsme-memory-encryption-from-consumer-chips/)

### トピック 5：あえて「不便」を選ぶ（Commodore Callback 8020）

- [Tom's Hardware（Commodore Callback 8020）](https://www.tomshardware.com/phones/commodore-announces-linux-based-flip-phone-with-no-social-media-no-browser-the-callback-8020-will-be-available-in-five-retro-colorways-starting-at-usd499-runs-99-percent-of-android-apps)
- [GSMArena（Callback 8020 の発表）](https://www.gsmarena.com/commodore_announces_callback_8020_the_mobile_phone_between_dumb_and_smart-news-73304.php)
