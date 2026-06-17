---
title: "触れずに乗っ取られるスマホの恐怖。AI爆発の裏で、米国が最強AIを隠した理由（2026年6月17日）"
date: 2026-06-17T07:30:00+09:00
tags: ["Security", "AI覇権", "情報漏洩", "パッチチューズデー", "Android", "ゼロクリック", "クラウド", "データセンター", "バンキングトロジャン"]
categories: ["技術トレンド", "セキュリティ"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日の記事のテーマを一言で表すなら「 **触れずに乗っ取られるスマホ、そして米国が最強AIを封じた理由** 」です。

AIが世界規模でインフラを逼迫させ、米政府が自国最強のAIモデルへのアクセスを自ら止め、日本では豆腐屋さんと大学病院から個人情報が漏れ、6月のWindowsパッチは直すほど止まり、スマホはユーザーが何もしなくても乗っ取られる——盛りだくさんな1日です。5本立てでお届けします。

まずは本日のYouTube動画からどうぞ！

{{< youtube "VMdj4PAEFDU" >}}

---

## 今日のトピック

### 1. 米国が自ら封じた最強AI——Anthropic の Fable 5・Mythos 5 アクセス停止指令と揺らぐ覇権の地図

「世界最強のAIを作ったのに、自分たちで使えなくする」——こんな逆説的な事態が起きました。

米政府が **Anthropic** に対し、外国籍ユーザーへの **Fable 5** および **Mythos 5** へのアクセスを停止するよう指令を出したことが明らかになりました（Anthropic 公式声明・The Hacker News より）。アクセス停止の対象は外国籍ユーザーで、Anthropic はこれに従いアクセスを制限しています。

なぜ米政府はそんな判断をしたのでしょうか。背景には、AIの性能そのものではなく「 **誰に供給できるか** 」が覇権の物差しになっているという地政学的計算があります。最高性能のモデルを世界中に提供することで技術的リーダーシップを示す路線と、軍事・安全保障上の懸念から外国へのアクセスを制限する路線——この2つの論理が激突しているわけです（Business Today より）。

一方、世論はどう見ているか。世界11カ国・約18,000人を対象にした世論調査では、AI覇権について「中国が覇者」と答える割合が高く、ドイツでは「米国が覇者」と答えた割合は **23%** にとどまりました（宮野宏樹 note より）。「最高性能を持つ」と「覇者と見なされる」の間に、すでにギャップが生じているということです。

業界への影響も無視できません。これまで Anthropic モデルを使ってきたセキュリティチームや開発者が、突然アクセスできなくなる状況に置かれました（Snyk・CISO Series より）。「複数モデルへの自動切り替え」「空白を埋める競合への移行」——こうした備えが実際に必要になるシナリオが現実のものとなっています。

- 出典: [Anthropic 公式声明（Fable 5・Mythos 5 アクセス停止指令について）](https://www.anthropic.com/news/fable-mythos-access) / [The Hacker News（米政府が外国籍ユーザーへのアクセス停止を指令）](https://thehackernews.com/2026/06/us-orders-anthropic-to-suspend-fable-5.html) / [Business Today（停止の背景解説）](https://www.businesstoday.in/technology/artificial-intelligence/story/anthropic-claude-fable-5-ban-explained-why-us-government-restricted-access-for-new-ai-models-536843-2026-06-15) / [宮野宏樹 note（世論調査・地政学の論点）](https://note.com/hirokimiyano/n/n91df2a3ef478)

---

### 2. 豆腐店と病院、漏れた信頼——佐嘉平川屋と藤田医科大学病院の情報流出2件

「業種も手口も違う2件だけれど、根っこにある教訓は同じ」——そう感じるニュースです。

まず1件目。佐賀県の老舗豆腐・なまこ製品メーカー **佐嘉平川屋** の通販サイトが不正アクセスを受け、 **カード情報 5,783名分** と **会員情報 30,170名分** が漏えいした可能性があることが発表されました（佐嘉平川屋 公式お詫びとご報告・公式PDF より）。手口は **ウェブスキミング** 。決済入力欄に不正なスクリプトが仕込まれ、入力されたカード情報が見えない経路で外部へ送出される攻撃です。

続いて2件目。 **藤田医科大学病院** では、看護師が業務上知り得た患者情報を私物PCに持ち出し、その後 **サポート詐欺** の被害にあって遠隔操作される事態が発生しました。漏えいした可能性のある **患者情報は1,365名分** です（ITmedia NEWS より）。

2件の手口はまったく異なります。佐嘉平川屋は「外から侵入してくる」古典的なウェブスキミング。藤田医科大学病院は「内から外に持ち出して、外で乗っ取られる」というパターンです。しかし共通しているのは、「境界防御だけでは止められなかった」という点です。いくら入口を守っても、データが外に出てしまえば守りは無力——その原則を、2件が同日に示してくれました。

一般ユーザーへの実践的なアドバイスとしては、「通販サイトで使うカードは使い捨て式のバーチャルカードに限定する」「明細通知をオンにして身に覚えのない決済をすぐ検知する」、企業・医療機関の担当者には「私物デバイスへの業務データ持ち出しを技術的にブロックするか、MDM等で管理する」ことが重要です。

- 出典: [佐嘉平川屋 公式お詫びとご報告](https://www.saga-hirakawaya.jp/security-notice/) / [佐嘉平川屋 公式PDF（2026年6月15日付）](https://www.saga-hirakawaya.jp/documents/pdf/202606-public-notice.pdf) / [ITmedia NEWS（藤田医科大学病院の患者情報流出）](https://www.itmedia.co.jp/news/articles/2606/04/news111.html)

---

### 3. 直すほど止まる6月の更新——2026年6月 Patch Tuesday の混迷

「パッチを当てないと危ない。でもパッチを当てると止まる」——システム管理者にとって最も頭が痛いジレンマが、6月の更新で現実になりました。

2026年6月の Patch Tuesday（定例パッチ配信日）では、 **198件の欠陥** が修正されました。その中には認証不要でリモートコード実行が可能（RCE）な深刻度 **9.8** の脆弱性が含まれており、未修正のままでは組織全体の掌握につながりかねない危険な綻びが **3件** 残されています（r/sysadmin Patch Tuesday Megathread より）。

問題は、パッチを当てた後に別の問題が起きることです。今月報告されている副作用として、パッチ適用後に **回復キーのループで起動できなくなる** 事例と、 **仮想マシンが停止する** 事例が確認されています（The Hacker News より）。

「侵害リスクを取るか、可用性を取るか」——どちらも捨てられない問いですが、現実的な対応としては **段階適用と事前検証** が鉄則です。テスト環境へ先行展開してから本番に展開する、影響の大きいシステムは週末前ではなく週明けに適用してロールバック猶予を設ける、といった運用上の工夫で多くのリスクは吸収できます。「パッチを当てる」という判断そのものは変えずに、「どう当てるか」のプロセスを丁寧に設計することが重要です。

- 出典: [r/sysadmin: Patch Tuesday Megathread (2026-06-09)](https://www.reddit.com/r/sysadmin/comments/1u15uc7/patch_tuesday_megathread_june_09_2026/) / [The Hacker News（最新の脆弱性情勢）](https://thehackernews.com/)

---

### 4. 無操作で奪われるスマホ——Android のゼロクリック脆弱性とバンキングトロジャン Rokarolla

「スマホを触っていないのに乗っ取られる」——SFの話ではなく、今月の現実です。

2026年6月の Android Security Bulletin では、 **Android 14〜16** を対象とするゼロクリック脆弱性が公開されました（Android Security Bulletin 2026年6月 より）。ゼロクリックとは、ユーザーが何もしなくても——リンクをタップせず、アプリを起動せず——脆弱性が悪用される攻撃です。スマートフォンの土台にあたるフレームワーク層に綻びがあると、その上に乗るすべてのアプリに波及する可能性があります。

同時期に猛威を振るっているのが、バンキングトロジャン **「Rokarolla」** です（The Hacker News より）。このマルウェアは **217種類** の金融・決済アプリを標的にし、 **137種類** の遠隔コマンドを持ち、二要素認証を回避して自動送金を行います。感染経路は公式ストア外からのアプリインストールが中心です。

さらに FortiSandbox でも複数の脆弱性（ **CVE-2026-39813** ・ **CVE-2026-39808** ・ **CVE-2026-25089** ）が悪用されており、CISAは既知の悪用脆弱性カタログに追加しました（Help Net Security・CISA より）。

持ち帰りの対策を3点に絞ります。まず「 **6月のAndroidアップデートを即適用する** 」。次に「 **公式ストア以外からアプリをインストールしない** 」。そして「 **過剰な権限要求（SMS・通話・アクセシビリティ）を許可しない** 」。この3点を今日中に確認してください。

- 出典: [Android Security Bulletin（2026年6月）](https://source.android.com/docs/security/bulletin/2026/2026-06-01) / [The Hacker News（Rokarolla・FortiSandbox 等の脅威情勢）](https://thehackernews.com/) / [Help Net Security（FortiSandbox の悪用）](https://www.helpnetsecurity.com/2026/06/16/fortisandbox-vulnerabilities-cve-2026-39813-cve-2026-39808-cve-2026-25089/) / [CISA（既知の悪用脆弱性カタログ追加）](https://www.cisa.gov/news-events/alerts/2026/06/15/cisa-adds-two-known-exploited-vulnerabilities-catalog)

---

### 5. AI爆発が枯らすクラウド——GitHub が AWS に頼る日、1,900億ドル規模の設備投資競争

「自社のクラウドが、自社のAIの需要に追いつかない」——皮肉が過ぎるような話ですが、これが現実として起きています。

Microsoft 傘下の **GitHub** が、AIによるコード生成の急増で自社クラウド容量が限界に達し、ライバルの **AWS（Amazon Web Services）** に処理を逃がしていることが報告されました（WindowsForum・TechRadar より）。

その規模感を数字で見てみましょう。AIエージェントが大量のコードを生み出すようになった結果、GitHub 上のコミット数は **10億件から140億件** へ（約14倍）、テスト実行時間は **5億分/週から21億分/週** へ（約4.2倍）に跳ね上がりました（Times of India より）。インフラという「配管」から水があふれそうになっているわけです。

業界全体でも設備投資競争が激化しています。Hacker News ではMeta CTOの発言や大規模データセンター新設の話題が連日トレンド入りしており、 **1,900億ドル規模** の設備投資が動いているとされます（Hacker News front より）。しかし「建設速度 < AI需要の伸び」という構図は簡単には変わらず、今後もクラウドキャパシティは綱渡りが続くと見られています。

さらに興味深いのは **コストの逆転** です。AIエージェントが大量のコードを書くコスト（生成コスト）は安くなった一方、そのコードをレビュー・テスト・検証するコストが急上昇しており、「書くのは安い・確かめるのは高い」という逆転現象が起きています（Hacker News front より）。

「インフラを持つ者が勝つ」時代はずっと続いてきましたが、今は「需要の伸びにインフラが追いつけるかどうか」が焦点になっています。この容量問題は短期間では解決しないため、クラウドコストや可用性に影響を与え続けるでしょう。

- 出典: [WindowsForum（GitHub の負荷と AWS 利用に関する報告）](https://windowsforum.com/threads/ai-coding-surges-strain-github-microsoft-reports-using-aws-for-capacity.426915/latest) / [TechRadar](https://www.techradar.com/pro/microsoft-forced-to-turn-to-aws-to-boost-github-cloud-capacity-following-ai-demand-surge) / [Times of India（コミット14倍・Actions 4.2倍の数値）](https://timesofindia.indiatimes.com/technology/tech-news/microsoft-is-seeking-its-biggest-rival-amazons-help-to-solve-githubs-growing-/articleshow/131759174.cms) / [Hacker News front（Meta CTO の告白・CapEx・Amazon DC 新設・レビューコスト逆転）](https://news.ycombinator.com/front?day=2026-06-16)

---

## まとめ

5本を通じて見えてくるのは、「スケールが上がると、今まで安全だったものが安全でなくなる」という共通テーマです。

米国が自ら封じた最強AIは、 **AIの性能競争がそのまま覇権競争になりきれない** 現実を示しました。豆腐屋さんと病院の情報流出は、 **業種規模を問わず誰でも標的になる** という事実を改めて突きつけました。6月のパッチは、 **修正が副作用を生む複雑な依存関係** の深刻さを見せてくれました。ゼロクリック攻撃とバンキングトロジャンは、 **触れていないのに乗っ取られる** という新しい脅威の現実を教えてくれました。そしてクラウドの容量危機は、 **AIが食い荒らすインフラの限界** という物理的な制約が実は一番手ごわいことを示しています。

技術が速く進めば進むほど、守る仕組みの更新が追いつかなくなる。でもだからこそ、一人ひとりが「自分のスマホのアップデートを当てる」「怪しい権限要求を断る」「明細通知をオンにしておく」といった小さな行動の積み重ねが、大きな被害を防ぐ最前線になります。

今日の5本の中で特に今すぐ行動できることは、Androidのセキュリティアップデートの確認です。ぜひ今日中にアップデート画面を開いてみてください。来週もよろしくお願いします！

よかったら X（旧 Twitter）で感想を教えてもらえると嬉しいです。 **#Agyテックブログ** でお待ちしています。

---

## 引用文献／出典

### トピック 1：米国が自ら封じた最強AI（Fable 5・Mythos 5 アクセス停止指令）

- [Anthropic 公式声明（Fable 5・Mythos 5 へのアクセス停止指令について）](https://www.anthropic.com/news/fable-mythos-access)
- [The Hacker News（米政府が外国籍ユーザーへのアクセス停止を指令）](https://thehackernews.com/2026/06/us-orders-anthropic-to-suspend-fable-5.html)
- [Business Today（停止の背景解説）](https://www.businesstoday.in/technology/artificial-intelligence/story/anthropic-claude-fable-5-ban-explained-why-us-government-restricted-access-for-new-ai-models-536843-2026-06-15)
- [宮野宏樹 note（世論調査・地政学の論点）](https://note.com/hirokimiyano/n/n91df2a3ef478)
- [Snyk（停止がセキュリティチームに与える示唆）](https://snyk.io/blog/fable-mythos-suspension-security-takeaways/)
- [CISO Series（業界の反発・Anthropic モデル擁護）](https://cisoseries.com/cybersecurity-news-anthropic-models-defended-massive-phishing-service-shuttered-1password-acquires-apono/)

### トピック 2：豆腐店と病院、漏れた信頼（日本国内の情報流出2件）

- [佐嘉平川屋 公式お詫びとご報告](https://www.saga-hirakawaya.jp/security-notice/)
- [佐嘉平川屋 公式PDF（2026年6月15日付）](https://www.saga-hirakawaya.jp/documents/pdf/202606-public-notice.pdf)
- [ITmedia NEWS（藤田医科大学病院の患者情報流出）](https://www.itmedia.co.jp/news/articles/2606/04/news111.html)

### トピック 3：直すほど止まる6月の更新（2026年6月 Patch Tuesday の混迷）

- [r/sysadmin: Patch Tuesday Megathread (2026-06-09)](https://www.reddit.com/r/sysadmin/comments/1u15uc7/patch_tuesday_megathread_june_09_2026/)
- [The Hacker News（最新の脆弱性情勢）](https://thehackernews.com/)

### トピック 4：無操作で奪われるスマホ（Android ゼロクリック脆弱性とバンキングトロジャン Rokarolla）

- [Android Security Bulletin（2026年6月）](https://source.android.com/docs/security/bulletin/2026/2026-06-01)
- [The Hacker News（Rokarolla・FortiSandbox 等の脅威情勢）](https://thehackernews.com/)
- [Help Net Security（FortiSandbox の悪用）](https://www.helpnetsecurity.com/2026/06/16/fortisandbox-vulnerabilities-cve-2026-39813-cve-2026-39808-cve-2026-25089/)
- [CISA（既知の悪用脆弱性カタログ追加）](https://www.cisa.gov/news-events/alerts/2026/06/15/cisa-adds-two-known-exploited-vulnerabilities-catalog)

### トピック 5：AI爆発が枯らすクラウド（インフラ容量危機と設備投資競争）

- [WindowsForum（GitHub の負荷と AWS 利用に関する報告）](https://windowsforum.com/threads/ai-coding-surges-strain-github-microsoft-reports-using-aws-for-capacity.426915/latest)
- [TechRadar](https://www.techradar.com/pro/microsoft-forced-to-turn-to-aws-to-boost-github-cloud-capacity-following-ai-demand-surge)
- [Times of India（コミット14倍・Actions 4.2倍の数値）](https://timesofindia.indiatimes.com/technology/tech-news/microsoft-is-seeking-its-biggest-rival-amazons-help-to-solve-githubs-growing-/articleshow/131759174.cms)
- [Business Insider](https://www.businessinsider.com/microsoft-github-amazon-ai-cloud-capacity-2026-6)
- [Hacker News front（Meta CTO の告白・CapEx・Amazon DC 新設・レビューコスト逆転）](https://news.ycombinator.com/front?day=2026-06-16)
