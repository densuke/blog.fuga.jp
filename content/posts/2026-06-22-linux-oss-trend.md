---
title: "メモリの境界を守れ——NGINX・Linux・npmで同時進行する「土台の作り直し」（2026年6月22日）"
date: 2026-06-22T07:30:00+09:00
tags: ["Linux", "セキュリティ", "OSS", "NGINX", "KDE", "Wayland", "npm", "サプライチェーン攻撃", "Rust"]
categories: ["技術トレンド"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日のテーマを一言で言うと「 **私たちの足元の土台は、いま「メモリの安全」と「信頼の連鎖」を守るために作り直されている** 」です。

一見バラバラに見える6月20日〜22日の5つのニュースが、実は1本の糸でつながっています。世界の約3割のWebサーバーを握るNGINXに見つかったクリティカルな脆弱性、21年越しの夢を新参者がかなえたKDE Plasma 6.7、6年がかりで危険な関数をカーネルから根絶したLinux、Perforceの独占に挑むEpic Games製のRust製バージョン管理ツール、そして88分で144パッケージを汚染したnpmサプライチェーン攻撃。攻める側も守る側も、結局は「メモリの境界」と「信頼の連鎖」を巡る攻防に収束していく——そんな密度の濃い3日間を、5本立てでお届けします。

まずは本日のYouTube動画からどうぞ！

{{< youtube "DvqW6f5MSfw" >}}

---

## 今日のトピック

### 1. 世界の3割を握るNGINXに緊急パッチ——HTTP/3のメモリバグCVE-2026-42530

まずは緊急度で言えばこの3日間の最重要ニュースから。世界のWebサーバー市場で約 **31.9%** （2026年6月21日時点のW3Techs調査）を握るNGINXに、HTTP/3 QUIC実装を起点とするクリティカルな脆弱性 **CVE-2026-42530** が見つかり、開発元のF5が6月17日にアウトオブバンド（定例外）の緊急パッチ、NGINX 1.31.2をリリースしました。CVSS v4.0で **9.2（Critical）** という、放置できないスコアです。

中身を噛み砕くと、HTTP/3のヘッダ圧縮（QPACK）の処理に潜む「 **use-after-free** （解放済みメモリの再利用）」のバグです。攻撃者が細工したHTTP/3セッションで、すでに存在するエンコーダストリームを途中で「再オープン」しようとすると、解放されたはずの管理用メモリがまだ参照されたまま使われてしまう。未認証のリモート攻撃者がワーカープロセスをクラッシュさせ（サービス妨害）、条件が揃えばリモートコード実行（RCE）にまで発展しうる、というのが核心です。「未認証」「リモート」という2語が並ぶ時点で、防御側は身構える必要があります。

救いもあります。HTTP/3 QUICはNGINXのデフォルトでは無効で、設定ファイルに明示的に `listen 443 quic;` と `http3 on;` を書いた環境だけが対象です。脆弱なのもOpen Sourceでは **1.31.0と1.31.1の2バージョンのみ** で、本番でよく使われる安定板1.30.x系は影響を受けません。ただし同日公開のもう1つの脆弱性 **CVE-2026-42055** （HTTP/2・gRPCプロキシのヒープバッファオーバーフロー、CVSS 7.3）は1.13.10〜1.31.1という極めて広いレンジに及びます。「うちはHTTP/3を使っていないから無関係」と早合点せず、こちらも合わせてパッチを当てるのが正解です。なお、調査時点でF5は「野生での悪用は確認されていない」としています。

- 出典: [F5 issues out-of-band patches for critical NGINX vulnerabilities - BleepingComputer](https://www.bleepingcomputer.com/news/security/f5-issues-out-of-band-patches-for-critical-nginx-vulnerabilities/) / [CVE-2026-42530 - IONIX](https://www.ionix.io/threat-center/cve-2026-42530/)

---

### 2. 21年越しの夢を「PHPエンジニア」がかなえた——KDE Plasma 6.7とX11最後の砦

緊張感のあるセキュリティの話から、少し空気を変えて。2026年6月16日にリリースされた **KDE Plasma 6.7** は、2つの歴史的な意味を持つバージョンです。1つは2005年から **21年間** も未解決だった「画面ごとに独立した仮想デスクトップ」をWayland限定でついに実装したこと。もう1つは、これがX11セッションを正式に提供する **最後のKDE Plasma** になると位置づけられたことです。

目玉のper-screen仮想デスクトップは、複数モニター環境で各画面ごとに独立して仮想デスクトップを切り替えられる機能。「サブモニターには資料を固定したまま、メインだけ作業空間を切り替えたい」という長年の願いをかなえます。この要望がバグトラッカーに登録されたのは2005年6月12日。以後 **18件の重複バグと117名のCC登録者** を集めながら、誰も解決できずに放置されてきました。

それを解決したのが、意外な人物でした。本業はC++とほぼ無縁の **フルタイムPHPエンジニア** で、QtもCMakeも未経験。古いノートにPlasmaを入れてわずか数か月後にマージリクエストを開いた、完全な新参者です。動機は「Waylandの小数スケーリングを使いたいのに、この機能がないことがブロッカーだった」という実用的なもの。「自分が欲しいから作った」が、結果的にコミュニティ20年越しの宿願を成就させたわけです。

そしてもう1つの節目、X11の終わり。次の6.8（2026年10月14日リリース予定）からはX11セッション固有のコードが削除され、ログイン画面はWaylandのみになります。判断の根拠は移行率の数字で、Plasma 6.6ユーザーのすでに **95%以上** がWaylandを使っています。とはいえ全員が納得したわけではなく、X11存続を望む有志は **SonicDE** というフォークを立ち上げました。なお「X11セッションの終わり」と「X11アプリの終わり」は別物で、互換レイヤーのXWaylandは引き続きサポートされるので、古いアプリも動き続けます。

- 出典: [Plasma 6.7 - KDE Community](https://kde.org/announcements/plasma/6/6.7.0/) / [A PHP Dev Just Solved a 20+ Year-Old KDE Plasma Problem - It's FOSS](https://itsfoss.com/news/kde-plasma-per-screen-virtual-desktops/)

---

### 3. 6年・362コミットの地味で偉大な旅——Linux 7.2が危険な関数strncpyを根絶

ここで、派手さはないけれど長い目で見れば今日のどのニュースよりも大きいかもしれない話を。Linuxカーネル7.2のマージウィンドウで、2026年6月20日、危険なC文字列関数 **`strncpy()`** の全使用箇所がカーネルから完全に除去されました。2020年8月に起票されたKSPP Issue #90を起点に、 **70名のコントリビューターによる362コミット** が約 **6年** かけて積み重なった末の、ひとつの「バグクラスの根絶」です。

`strncpy()` の何が危険なのか。最大の問題は **NUL終端を保証しないこと** です。コピー元が長いと、文字列の終わりを示すゼロバイトを書かずに終わってしまう。そのバッファを後で読むコードは、割り当て領域を超えてゼロが現れるまでメモリを読み続けてしまいます。カーネルメモリにはパスワードや暗号鍵が散在しているので、これはそのまま情報漏洩に直結する——トピック1のNGINXで起きた「メモリ境界を越えて読む」use-after-freeと、根は同じ問題なのです。

面白いのは、この作業が単純な一括置換で済まなかった点。呼び出し箇所ごとに「NUL終端が必要」「固定幅の非終端フィールドが必要」「既知長データのバイトコピーで十分」と意図がバラバラで、機械的に置換すると誤った関数を選んでしまう。だからこそ、コードレビューを伴う手作業が6年分も必要でした。筆頭はGoogleのJustin Stitt氏で、なんと全体の **58%にあたる211コミット** を一人で書き分けています。1人のエンジニアの粘り強さが、メモリ安全という防御の正体なのだと教えてくれます。バグを検出するのではなく、バグを書く手段そのものを消す。この発想は、後で出てくるEpicのLoreやMastra事件への対策とも、根底でつながっています。

- 出典: [Linux Finally Eliminates The strncpy API After Six Years - Phoronix](https://www.phoronix.com/news/Linux-7.2-Drops-strncpy) / [Remove all strncpy() uses · Issue #90 - KSPP/linux](https://github.com/KSPP/linux/issues/90)

---

### 4. Perforceの数十年の独占に挑む——Epic GamesがRust製VCS「Lore」を公開

開発ワークフローの世界からも大きな一手が出ました。Epic Gamesが6月17日、Unreal Engine 5.8の発表と同時に、新しいバージョン管理システム（VCS） **「Lore」** をオープンソース公開したのです。 **Rust** で実装され **MITライセンス** で提供されるLoreは、ギガバイト級のバイナリアセットを扱うゲーム開発の現場で、長く有料独占が続いてきたPerforceに正面から挑みます。GitHubリポジトリは公開数時間で **2,850件以上のスター** を集め、コミュニティの反応は「新しいVCSが出た」という驚きよりも「ようやく誰かが本気で取り組んだ」という安堵感が支配的だったと報じられています。

なぜ既存ツールでは不十分なのか。GitとGit LFSはバイナリファイルを「二級市民」として扱い、フラグメント単位の重複排除ができません。一方Perforce Helix Coreはバイナリ管理に実績があるものの、1ユーザーあたり約 **39ドル/月** のパーシート課金は大規模チームには重く、100人のスタジオなら年間1万ドル超に。さらに独占的なプロトコルはサードパーティ製ツールの実装を事実上不可能にしています。

Loreはこの双方の欠点を埋めます。ハッシュには高速で並列処理に強い **BLAKE3** を採用し、リポジトリ状態をMerkleツリーで表現。重複排除はファイル全体ではなく **フラグメント（チャンク）単位** で行うため、4GBのテクスチャを5%変更しても、変わったチャンクだけを再アップロードすれば済みます。スパースcheckoutは「オプション」ではなく構造的な前提として設計され、コミットやブランチ操作はオフラインで完結。プロトコルは公開仕様なので、誰でも独自のクライアントやサーバーを実装できます——Perforceの独占への直接的なアンチテーゼですね。ただし正直な注意点も。バージョンは0.8.3で、Epic自身が「プロダクション前のプレステーブル版で、フォーマットやAPIは変わりうる」と明言しています。本格採用はこれからの段階です。

- 出典: [EpicGames/lore - GitHub](https://github.com/EpicGames/lore) / [Git good with Epic Games' new open source VCS, Lore - The Register](https://www.theregister.com/devops/2026/06/17/git-good-with-epic-games-new-open-source-vcs-lore/5257978)

---

### 5. 88分で144パッケージを汚染——Mastra npmサプライチェーン攻撃

最後は、規模と身近さの両面で衝撃が大きいサプライチェーン攻撃の話で締めます。2026年6月17日、北朝鮮の国家ハッカーグループ **Sapphire Sleet** が、AIエージェント構築フレームワーク **Mastra** のnpmスコープを乗っ取り、わずか **88分間** の全自動攻撃で **144パッケージ** に悪意ある依存を注入しました。影響を受けたのは週次合計 **110万回超** のダウンロード。狙いは166種類の仮想通貨ウォレット拡張機能と、開発者のLLM APIキーやCI/CDシークレットでした。

手口は恐ろしいほど巧妙でした。攻撃者はまず、正規の日付ライブラリ `dayjs` を完全コピーした `easy-day-js` を「良性のおとり」として1日間公開し、npmのレビューを突破。頃合いを見て悪意あるコード（`postinstall` フック）を仕込んだ版を出し、依存指定にキャレット（`^`）を使うことで、lockfileを持たない環境では自動的に最新の悪意版が引き込まれるよう仕込みました。

侵害の起点は **「忘れられた貢献者アカウント」** です。Mastraの元貢献者のアカウントが **16か月以上** 非アクティブのまま、スコープ全体へのpublish権限を保持し続けていた。npmには休眠アカウントの権限を自動で剥奪する仕組みがないため、乗っ取られた認証情報がそのまま140超のパッケージへの「鍵」になってしまったのです。さらに恐ろしいのは、`postinstall` フックの性質上、対象を `import` しなくても **`npm install` を実行しただけで感染** する点。開発機やCI/CDパイプラインがまるごと侵害されます。

では、どう守るか。即時対応としては該当期間に `@mastra/*` を入れた全マシンを侵害済みとして扱い、各種シークレットを即ローテーション。予防策は、 `npm config set ignore-scripts true` でライフサイクルスクリプトをデフォルト無効化、CIでは `npm ci` を使ってlockfileを必ずコミット、キャレット依存を避けてバージョンを固定、`npm audit signatures` でプロバナンス（来歴）を検証——と具体的です。トピック3のカーネルが「危険な関数をそもそも使えなくする」発想だったのと同じく、ここでも「postinstallを最初から動かさない」という、危険な機構を無効化しておく方向こそが構造的な解になります。

- 出典: [Inside the Mastra npm supply chain compromise by Sapphire Sleet - Microsoft Security Blog](https://www.microsoft.com/en-us/security/blog/2026/06/17/postinstall-payload-inside-mastra-npm-supply-chain-compromise/) / [A forgotten contributor account compromised the entire Mastra npm package scope - Snyk](https://snyk.io/blog/a-forgotten-contributor-account-compromised-the-entire-mastra-npm-package-scope/)

---

## まとめ

今週の5本を貫いていたのは、 **「メモリ安全」** と **「信頼の連鎖」** という2本の軸でした。NGINXのCVE-2026-42530は、メモリ境界を越えるバグがエッジサーバーで現実の脅威になることを見せつけ（第1話）、対するLinuxカーネルは同じ種類のバグを6年がかりで根絶した（第3話）。攻撃される側と、攻撃される手段そのものを消す側——対照的な2つの局面です。KDEのWayland移行（第2話）とEpicのRust製Lore（第4話）は、いずれも「より安全な基盤へ」という同じ方向への前進でした。

そしてもう1本の軸が信頼の連鎖。LoreがBLAKE3で「バイト列の同一性」を暗号学的に保証しようとしたのに対し、Mastra攻撃（第5話）はまさにその信頼を、休眠アカウントとおとりパッケージで悪用しました。`npm install` という何気ない1コマンドの裏で、私たちは無数の見知らぬ依存を信頼しています。その連鎖のどこか1点が乗っ取られれば、88分で144パッケージが汚染される。

だからこそ、Loreの「公開プロトコルと検証可能なハッシュ」も、カーネルの「危険な関数を使えなくする」発想も、Mastra対策の「postinstallをデフォルトで動かさない」も、すべて同じ結論に向かっています——信頼は前提にするのではなく、構造で検証し、危険な機構は最初から無効化しておくもの。エッジのサーバーから足元のツールチェーン、デスクトップまで、防御の思想が一本につながった3日間でした。次に何気なくサーバーを立てたり `npm install` を叩いたりするとき、その下で働く土台の作り直しに、少しだけ思いを馳せてみてください。それではまた次回！

---

## 参考文献

### トピック 1：NGINX CVE-2026-42530

- [nginx security advisories - nginx.org](https://nginx.org/en/security_advisories.html)
- [NGINX vulnerability CVE-2026-42530 (K000161616) - F5](https://my.f5.com/manage/s/article/K000161616)
- [F5 issues out-of-band patches for critical NGINX vulnerabilities - BleepingComputer](https://www.bleepingcomputer.com/news/security/f5-issues-out-of-band-patches-for-critical-nginx-vulnerabilities/)
- [CVE-2026-42530 – Use-After-Free leading to DoS and potential RCE - IONIX](https://www.ionix.io/threat-center/cve-2026-42530/)

### トピック 2：KDE Plasma 6.7

- [Plasma 6.7 - KDE Community](https://kde.org/announcements/plasma/6/6.7.0/)
- [Bug #107302: Per-screen virtual desktops - KDE Bugzilla](https://bugs.kde.org/show_bug.cgi?id=107302)
- [KDE Merges Per-Screen Virtual Desktops After 21 Years - Phoronix](https://www.phoronix.com/news/KDE-Per-Screen-Virt-Desktops)
- [SonicDE Launches as a KDE-Based Desktop for X11 Holdouts - Linuxiac](https://linuxiac.com/sonicde-launches-as-a-kde-based-desktop-for-x11-holdouts/)

### トピック 3：Linux 7.2 strncpy根絶

- [Linux Finally Eliminates The strncpy API After Six Years - Phoronix](https://www.phoronix.com/news/Linux-7.2-Drops-strncpy)
- [Remove all strncpy() uses · Issue #90 - KSPP/linux](https://github.com/KSPP/linux/issues/90)
- [Better string handling for the kernel - LWN.net](https://lwn.net/Articles/948408/)

### トピック 4：Epic Games Lore VCS

- [EpicGames/lore - GitHub](https://github.com/EpicGames/lore)
- [The Lore Version Control System - Lore Developer Documentation](https://epicgames.github.io/lore/explanation/system-design/)
- [Git good with Epic Games' new open source VCS, Lore - The Register](https://www.theregister.com/devops/2026/06/17/git-good-with-epic-games-new-open-source-vcs-lore/5257978)

### トピック 5：Mastra npmサプライチェーン攻撃

- [Inside the Mastra npm supply chain compromise by Sapphire Sleet - Microsoft Security Blog](https://www.microsoft.com/en-us/security/blog/2026/06/17/postinstall-payload-inside-mastra-npm-supply-chain-compromise/)
- [A forgotten contributor account compromised the entire Mastra npm package scope - Snyk](https://snyk.io/blog/a-forgotten-contributor-account-compromised-the-entire-mastra-npm-package-scope/)
- [Mastra npm Supply Chain Attack: 140+ Packages Backdoored - StepSecurity](https://www.stepsecurity.io/blog/mastra-npm-packages-compromised-using-easy-day-js)
- [Microsoft links Mastra AI supply chain attack to North Korean hackers - BleepingComputer](https://www.bleepingcomputer.com/news/security/microsoft-links-mastra-ai-supply-chain-attack-to-north-korean-hackers/)
