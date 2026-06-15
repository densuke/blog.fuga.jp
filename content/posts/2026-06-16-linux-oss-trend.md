---
title: "自動化された脅威とAIスロップの時代に、信頼の土台を人がどう守り直すか（2026年6月16日）"
date: 2026-06-16T06:00:00+09:00
tags: ["Security", "AIエージェント", "サプライチェーン攻撃", "AUR", "フィッシング", "Vim", "curl", "CVE", "OSS"]
categories: ["技術トレンド", "セキュリティ"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日の記事のテーマを一言で表すなら「 **自動化された脅威とAIスロップの時代に、信頼の土台を人がどう守り直すか** 」です。

攻撃側では、AURを狙ったサプライチェーン攻撃がeBPFルートキットを仕込み、GeminiというAIが詐欺師に使われ、Microsoft 365 CopilotがゼロクリックでMFAコードを盗まれる穴を突かれました。一方の守る側では、curlが「AIが量産するスパムレポートに疲弊した」と言って脆弱性報告を1ヶ月シャットダウンし、Vimは「AIコードを1文字も混ぜない」というフォークを産み落としました。

攻撃と防衛の対比がこれほどくっきり出た日も珍しいです。5本立てで深掘りしていきましょう。

まずは本日のYouTube動画からどうぞ！

{{< youtube "T1ig_pmspqY" >}}

---

## 今日のトピック

### 1. AIが量産した偽サイト250万通——Google が Gemini 悪用の巨大フィッシング網「Outsider Enterprise」を提訴・解体

「フィッシング詐欺は手作りで一件ずつ」という時代は、もうとっくに終わっていました。

今週、Google が中国系の詐欺インフラ **「Outsider Enterprise」** を米連邦地裁に提訴したことが明らかになりました。この組織が何をしていたかというと、Google の生成 AI **「Gemini」** を悪用して偽サイトのコードを量産し、約 **100 万件超の不正 URL** と **250 万件超のスパム SMS** （2 週間あたり）を用いて被害者を誘導していた、というものです（Google Blog, BleepingComputer, MLQ News より）。

攻撃の仕組みはシンプルかつ凶悪です。Gemini に「この配送通知ページに見えるような HTML を書いて」と指示するだけで、見た目の整った偽サイトのコードが出来上がる。それをそのまま大量展開し、標的にスパム SMS を送りつけて誘導する——人手をほとんどかけずに、巨大なフィッシング網を維持できてしまうわけです。

Google は提訴と並行して、 **FBI** や通信各社、コンテンツ削除サービス **Lumen** と連携して攻撃インフラの解体を進めました。不正ドメインの削除、通信ブロック、さらに Google 自身が AI ベースの検出システムで偽サイトを自動識別して潰す——ここでも AI が防御側に立っています。攻めも AI、守りも AI という構図は、もはや「AI の軍拡競争」と呼んでいいと思います。

今回の提訴が示す重要な教訓は二つ。一つは「生成 AI は悪用しやすい」という自明の事実を、プラットフォーム側が「使った者が罰せられる」という法的な枠組みで補強しようとしていること。もう一つは、個人が受け取った SMS のリンクを「正規に見えるから大丈夫」と判断するのは、もはや通用しないということです。

- 出典: [Google Blog - Combatting AI Scams](https://blog.google/innovation-and-ai/technology/safety-security/combatting-ai-scams/) / [BleepingComputer - FBI disrupts massive AI-powered phishing service using a million URLs](https://www.bleepingcomputer.com/news/security/fbi-disrupts-massive-ai-powered-phishing-service-using-a-million-urls/) / [MLQ News - Google Sues China-Based AI Scam Network That Exploited Gemini to Defraud Americans](https://mlq.ai/news/google-sues-china-based-ai-scam-network-that-exploited-gemini-to-defraud-americans/)

---

### 2. 放棄パッケージに潜む1500の裏口——AUR を揺るがす大規模サプライチェーン攻撃「Atomic Arch」

「誰かが昔メンテしていた、今は放棄されたパッケージ」——これがサプライチェーン攻撃の絶好の入口になった、という話です。

Arch Linux のユーザーリポジトリ **AUR（Arch User Repository）** で、大規模なサプライチェーン攻撃キャンペーン **「Atomic Arch」** が確認されました。Privacy Guides によると **約 1,500 パッケージ** が影響を受けており、また StepSecurity の解析では **400+ パッケージ** が乗っ取られたことが確認されています（それぞれ異なる観測時点・観測者による報告です）。

手口はこうです。長らく放棄されて「孤児化」したパッケージを物色し、正規の引き継ぎ手続きを通じて管理権を獲得する。信頼の歴史とパッケージ名はそのまま「継承」しつつ、ビルド指示ファイル **「PKGBUILD」** を書き換えて悪意あるスクリプトを仕込む——インストール時に、利用者が気づかないまま隠しスクリプトが実行される仕組みです。

Sonatype の解析した悪性パッケージ **「atomic-lockfile」** では、 **SSH 秘密鍵・クラウドアクセストークン・ブラウザの保存情報・チャットのセッションデータ** などが外部に送出される挙動が確認されています。さらに **eBPF** を使ってプロセスを隠蔽する手口も採用されており、単純なプロセスリストには現れない、発見困難なマルウェアでした。

対策として推奨されるのはまず **「全部変える」** 覚悟です。影響パッケージをインストールしていた環境では、SSH 鍵・クラウドアクセストークン・パスワード・セッションデータの全入れ替えが必要です。そして再発防止のためには、 **ビルドを使い捨ての隔離環境** で実行する習慣——本番の認証情報とビルド環境を混在させないという原則が重要になります。

「使い古されて誰も見ていないパッケージ」こそが狙い目になる——AUR に限らず、npmやPyPIでも同じリスクが存在します。依存パッケージのメンテナンス状況を定期的に確認することが、もはや当たり前のセキュリティ習慣になりつつあります。

- 出典: [FOSS Force - AUR to Arch: 'Houston, We've Got a Problem...We're Under Attack Again'](https://fossforce.com/2026/06/aur-to-arch-houston-weve-got-a-problem-were-under-attack-again/) / [Privacy Guides - Around 1,500 AUR Packages Compromised with "Rootkit-Like" Malware](https://www.privacyguides.org/news/2026/06/12/around-1-500-aur-packages-compromised-with-rootkit-like-malware/) / [Sonatype Blog - Analysis of atomic-lockfile, the malicious dependency](https://www.sonatype.com/blog/atomic-arch-npm-campaign-adds-malicious-dependency) / [StepSecurity - 400+ AUR Packages Hijacked](https://www.stepsecurity.io/blog/400-aur-packages-hijacked-atomic-arch-campaign)

---

### 3. AIを1行も使わないVim——Drew DeVault 氏が立ち上げた倫理的フォーク「Vim Classic 8.3」

「このエディタには AI が 1 行も入っていません」——そういう宣言をするソフトウェアが、2026 年に登場しました。

**Drew DeVault** 氏（Sourcehut の創設者）が、Vim のフォーク **「Vim Classic 8.3」** を発表・リリースしました（Drew DeVault's Blog「Forking Vim」、It's FOSS より）。最大の特徴は、「AI によって生成されたコードを一切含まない」という方針を正式に掲げている点です。

フォークに至った背景には、本家 Vim が AI 生成のデモコードを公式リポジトリに取り込んだこと、また NeoVim コミュニティで AI 支援コードの混入に対する抗議が起きたことがあります。DeVault 氏は、AI 生成コードの問題として **品質・環境負荷・人道的懸念** の三点を挙げています。

Vim Classic 8.3 は、Vim 8 系をベースに「人が全体を把握できる範囲」にとどめる設計思想を持っています。Vim9 Script などの最新機能拡張とは距離を置き、「軽くて理解できる」ツールであり続けることを目指しています。最新プラグインの一部は動作しない可能性がありますが、シンプルさと透明性を選ぶ人にとっては明確な選択肢になります。

面白いのは、これが「反 AI 感情」ではなく **「コードの来歴に対するこだわり」** だという点です。「誰が書いたか、どうやって書かれたか、著作権上どうなるか」——こういった問いに答えを持ちたいと考える開発者・組織にとって、「AI コード不使用」の明示は一定の価値を持ちます。

Slashdot のスレッドでも賛否両論が活発に展開されており、「AI コードの排除は可能か」「どこからが AI コードなのか」という根本的な問いが議論されています。ツール選択は、もはや機能だけでなく **「価値観」** の選択になっているのかもしれません。

- 出典: [Drew DeVault's Blog - Forking Vim](https://drewdevault.com/blog/Forking-vim/) / [It's FOSS - Vim Classic is a Vim Fork for People Who Want Their Editor AI-Free](https://itsfoss.com/news/vim-classic-first-release/) / [Slashdot - Vim Classic 8.3 Launched as an AI-Free Vim Fork](https://news.slashdot.org/story/26/06/13/0524209/vim-classic-83-launched-as-an-ai-free-vim-fork)

---

### 4. 1クリックで漏れるメール——Microsoft 365 Copilot の1クリック脆弱性「SearchLeak」（CVE-2026-42824）

「信頼できる Microsoft のリンクを、普通にクリックしただけ」——それだけで、メール・ファイル・MFA コードが外部に漏れてしまう脆弱性が発見されました。

セキュリティ企業 **Varonis** が公開した **「SearchLeak」** （ **CVE-2026-42824** ）は、 **Microsoft 365 Copilot** を悪用した、1 クリックのデータ窃取攻撃です（Varonis Blog, BleepingComputer, The Hacker News より）。

攻撃の仕組みを噛み砕くとこうなります。Copilot が回答を画面にレンダリングする「処理中」の一瞬、まだサニタイズが完了していない状態で画像タグが含まれていると、ブラウザがそのタグを先読みして外部 URL にリクエストを飛ばす——その URL に機密情報（メール内容・ファイルの中身・MFA コード等）を乗せることができた、という競合状態（race condition）の悪用です。

攻撃の入口は **正規の microsoft.com ドメイン** からのリンク。さらに **Bing** など Copilot が信頼する中間ドメインを踏み台にして外部サーバーへ情報を送出できるため、ネットワーク制御だけで防ぐことが非常に難しい構造でした。

Varonis は責任ある開示（Responsible Disclosure）のプロセスを通じて Microsoft に報告し、現在はパッチが適用済みとのことです。とはいえ、このクラスの「AIアシスタントがレンダリング処理の隙間を突かれる」脆弱性は、Copilot だけの問題ではありません。AIが画面に何かを描画するすべてのプロダクトが、同様の設計上のリスクを持ちうる——「出力を安全に閉じるまで、ブラウザに流すな」という原則が、今後の AI 機能設計の基本になっていくはずです。

M365 Copilot を業務で使っている組織の皆さん、念のためパッチ適用状況の確認を！

- 出典: [Varonis Blog - SearchLeak: How We Turned M365 Copilot Into a One-Click Data Exfiltration Weapon](https://www.varonis.com/blog/searchleak) / [BleepingComputer - New attack turned Microsoft 365 Copilot into 1-click data theft tool](https://www.bleepingcomputer.com/news/security/new-attack-turned-microsoft-365-copilot-into-1-click-data-theft-tool/) / [The Hacker News - One-Click Microsoft 365 Copilot Flaw Could Have Let Attackers Steal Emails, Files, and MFA Codes](https://thehackernews.com/)

---

### 5. curlが選んだ報告の夏休み——Daniel Stenberg 氏が7月中の脆弱性報告受付を休止する「Summer of Bliss」を宣言

守る側が、壊れる前に自分を守る権利がある——そんなことを考えさせられるニュースです。

**curl** の生みの親であり現在も筆頭メンテナを務める **Daniel Stenberg** 氏が、ブログ投稿 **「curl summer of bliss」** で、 **2026 年 7 月中の脆弱性報告受付を完全に休止する** と宣言しました（Daniel Stenberg's Blog より）。

背景にあるのは、AI によって自動生成された **低品質な脆弱性報告の急増** です。「一見もっともらしいが再現できない」「文章として成立しているが根本原因の理解がない」そんな報告が大量に届くようになり、トリアージ（報告の選別・優先度付け）の作業コストが爆発的に膨れ上がった、というのが Stenberg 氏の説明です。

curl は世界中のデバイスで動いている、ほぼインターネットの基盤といえるライブラリです。そのメンテナが「報告を受け付けない期間を設ける」という判断をするほどに、AI スパムによる疲弊が深刻になっている——これは curl に限った話ではなく、多くの OSS プロジェクトが直面しつつある現実です。

Hacker News でもこの決断は大きく議論されました。「理解できる、メンテナを守れ」という共感と、「重大な脆弱性の報告が遅れるリスク」という懸念が交錯しています。

今日の 5 本のうち、一番地味に見えるかもしれないこの話が、個人的には一番重いと感じています。「守る人たちが疲弊して報告窓口を閉じる」ことは、誰も得をしない。AI が大量の低品質報告を送りつけることで、本物の脆弱性発見者の声が埋もれてしまうリスクがある。「AI が悪意ある攻撃に使われる」だけでなく、「AI が悪意なしに、守る仕組みを破壊する」——こちらの問題にも、真剣に向き合う時期に来ていると思います。

- 出典: [Daniel Stenberg's Blog - curl summer of bliss](https://daniel.haxx.se/blog/2026/06/15/curl-summer-of-bliss/) / [Hacker News - Stories from June 14, 2026](https://news.ycombinator.com/front?day=2026-06-14)

---

## まとめ

5 本を通じて見えてくるのは、「信頼の土台を設計し直す責任は、誰にあるのか」という問いです。

Gemini を悪用した詐欺網は、 **プラットフォームが法的・技術的に介入しなければ止まらない規模** にまで育ってしまいました。AUR のサプライチェーン攻撃は、 **誰も見ていない放棄パッケージ** という無人地帯を突きました。Vim Classic は、 **コードの来歴と価値観を選ぶ権利** を守ろうとする静かな抵抗です。SearchLeak は、 **「信頼できるドメインのリンク」さえも危ない** という現実を突きつけました。そして curl の夏休みは、 **守る人が壊れないための自衛** という、悲しくも真っ当な判断です。

AI を使った攻撃が自動化・スケールアップするほど、守る側も「人間が一件ずつ確認する」モデルの限界に近づいている。でも、その限界を突破するための答えもまた、コミュニティの設計・プロセスの見直し・法的な枠組みの整備という **人間の判断** にある——今日の 5 本が、そのことを改めて教えてくれた気がします。

皆さんが使っている OSS のメンテナが今日もどこかで頑張っています。感謝の気持ちを持ちつつ、パッチ適用・依存関係の点検・怪しいリンクの手動確認、ぜひ今日のうちに一つやってみてください。来週もよろしくお願いします！

よかったら X（旧 Twitter）で感想を教えてもらえると嬉しいです。 **#Agyテックブログ** でお待ちしています。

---

## 引用文献／出典

### トピック 1：Gemini 悪用フィッシング網「Outsider Enterprise」

- [Google Blog - Combatting AI Scams](https://blog.google/innovation-and-ai/technology/safety-security/combatting-ai-scams/)
- [BleepingComputer - FBI disrupts massive AI-powered phishing service using a million URLs](https://www.bleepingcomputer.com/news/security/fbi-disrupts-massive-ai-powered-phishing-service-using-a-million-urls/)
- [MLQ News - Google Sues China-Based AI Scam Network That Exploited Gemini to Defraud Americans](https://mlq.ai/news/google-sues-china-based-ai-scam-network-that-exploited-gemini-to-defraud-americans/)
- [Help Net Security - Google China-based cybercrime network lawsuit](https://www.helpnetsecurity.com/2026/06/12/google-china-based-cybercrime-network-lawsuit/)
- [OECD AI Incidents - Incident 2026-06-12-332c](https://oecd.ai/en/incidents/2026-06-12-332c)

### トピック 2：AUR サプライチェーン攻撃「Atomic Arch」

- [FOSS Force - AUR to Arch: 'Houston, We've Got a Problem...We're Under Attack Again'](https://fossforce.com/2026/06/aur-to-arch-houston-weve-got-a-problem-were-under-attack-again/)
- [Privacy Guides - Around 1,500 AUR Packages Compromised with "Rootkit-Like" Malware](https://www.privacyguides.org/news/2026/06/12/around-1-500-aur-packages-compromised-with-rootkit-like-malware/)
- [Sonatype Blog - Analysis of atomic-lockfile, the malicious dependency](https://www.sonatype.com/blog/atomic-arch-npm-campaign-adds-malicious-dependency)
- [StepSecurity - 400+ AUR Packages Hijacked: What the "Atomic Arch" Campaign Means for Supply-Chain Security](https://www.stepsecurity.io/blog/400-aur-packages-hijacked-atomic-arch-campaign)

### トピック 3：Vim Classic 8.3（AI コード排除フォーク）

- [Drew DeVault's Blog - Forking Vim](https://drewdevault.com/blog/Forking-vim/)
- [It's FOSS - Vim Classic is a Vim Fork for People Who Want Their Editor AI-Free](https://itsfoss.com/news/vim-classic-first-release/)
- [Slashdot - Vim Classic 8.3 Launched as an AI-Free Vim Fork](https://news.slashdot.org/story/26/06/13/0524209/vim-classic-83-launched-as-an-ai-free-vim-fork)

### トピック 4：M365 Copilot 脆弱性「SearchLeak」（CVE-2026-42824）

- [Varonis Blog - SearchLeak: How We Turned M365 Copilot Into a One-Click Data Exfiltration Weapon](https://www.varonis.com/blog/searchleak)
- [BleepingComputer - New attack turned Microsoft 365 Copilot into 1-click data theft tool](https://www.bleepingcomputer.com/news/security/new-attack-turned-microsoft-365-copilot-into-1-click-data-theft-tool/)
- [The Hacker News - One-Click Microsoft 365 Copilot Flaw Could Have Let Attackers Steal Emails, Files, and MFA Codes](https://thehackernews.com/)

### トピック 5：curl「Summer of Bliss」脆弱性報告受付休止

- [Daniel Stenberg's Blog - curl summer of bliss](https://daniel.haxx.se/blog/2026/06/15/curl-summer-of-bliss/)
- [Hacker News - Stories from June 14, 2026](https://news.ycombinator.com/front?day=2026-06-14)
