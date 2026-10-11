---
title: "11年前の穴が今も開く！ Flax Typhoon と CISA KEV、携帯ゲーム機の Linux ドライバー、Drgn 0.3、AI パッチの洪水、Bitwarden の商用化（2026/10/12 Linux・OSSトレンド）"
date: 2026-10-12T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CISA", "脆弱性", "Linux カーネル", "ドライバー", "デバッグ", "Python", "AI", "ライセンス", "Bitwarden", "パスワードマネージャー"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

ソフトウェアは、作って終わりではありません。誰かが面倒を見続けて、はじめて安全で使いやすい状態が保たれます。では、その手入れの手間は誰が払っているのか。今回の5本は、この問いで並べました。

共通点の指摘は書き手の考察です。動画で一次情報と食い違った発言や裏付けの取れなかった発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "3jEOLXZ88BY" >}}

## 1. Flax Typhoon と CISA KEV — 11年前の穴が、いまも悪用されている

CISA は2026年10月8日、古い脆弱性5件を [KEV（悪用が確認された脆弱性のカタログ）に追加しました](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)。連邦機関の対応期限は5件とも10月11日で、追加からわずか3日です。期限の根拠は運用指令 [BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) で、対象は連邦文民行政機関です。民間企業に義務を課すものではありません。

5件は、ProFTPD（CVE-2015-3306）、ONLYOFFICE Docs（CVE-2021-3199）、Strapi（CVE-2023-22894）、Apache Struts（CVE-2016-3081）、ISC BIND（CVE-2015-5477）です。

一番古い ProFTPD の穴は、[NVD での公表が2015年5月18日](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2015-3306)で、約11年前のものです。ProFTPD 1.3.5 の mod_copy が、[認証なしで SITE CPFR / CPTO によるファイルの複製を許していた](https://raw.githubusercontent.com/proftpd/proftpd/1.3.5/NEWS)問題で、CVSS v3.1 は10.0（Critical）。修正版の 1.3.5a は2015年5月27日に出ています。直す方法は11年前からあったわけです。正直、FTP サーバーがいまも狙われていると聞いて、少し目を疑いました。

ほかの修正版は、Strapi が [4.8.0](https://github.com/advisories/GHSA-jjqf-j4w7-92w8)、BIND が [9.9.7-P2 と 9.10.2-P3](https://kb.isc.org/docs/aa-01272) です。BIND の穴は、細工したパケットで BIND が終了してしまうもので、ISC のアドバイザリの回避策欄は "None." です。

[共同勧告 AA26-281A](https://www.cisa.gov/news-events/cybersecurity-advisories/aa26-281a) は、攻撃者を Flax Typhoon、Ethereal Panda、Red Juliett などの名で知られる活動とし、それを支えた Integrity Technology Group を "a China-based company with links to the Chinese government" と説明しています。北京の企業だという点は、[The Hacker News（THN）の報道](https://thehackernews.com/2026/10/fbi-seizes-7-domains-disrupts-flax.html)です。勧告には米・英・豪・加・日・NZ・スペインの7か国の機関が名を連ね、日本からは警察庁と国家サイバー統括室が加わりました。攻撃側は、1,300本を超えるペネトレーションテスト用スクリプトを含む Python 製の Web アプリケーションで Web サイトを走査していた、と勧告は書いています。FBI が攻撃に使われたドメイン7件を押収したことも、[BleepingComputer](https://www.bleepingcomputer.com/news/security/fbi-disrupts-chinese-hacking-tools-used-to-breach-critical-infrastructure/) などが報じています。

被害の書き方は、報道で違います。THN は米国の電力会社や日本とポーランドの空港などを標的として挙げ、BleepingComputer は同じ電力会社と空港を走査の対象とし、侵害の有無を FBI は明らかにしていない、という趣旨です。

担当者のいないまま放置されたサーバーは、更新の対象にも入りません。書き手としては、ここが一番怖いところです。まずは手元の機器を、KEV の5製品と突き合わせてみてください。

動画の訂正です。

- 動画では「被害は、アメリカの電力会社や、日本とポーランドの空港、台湾の20を超える大学などで確認されています。」と紹介しましたが、「20を超える」と書いた報道は見つかりませんでした。台湾の大学の被害は、THN が20校、BleepingComputer が6校と伝えています。電力会社と空港も、報道は標的や走査の対象として挙げており、被害の確認までは書いていません。

## 2. 携帯ゲーム機とノート PC — 次の Linux に向けたドライバーの更新

ノート PC や携帯機の電源やファンなど、機種ごとの癖をカーネルに教えるのが x86 のプラットフォームドライバーです。今回の更新は、保守担当の Ilpo Järvinen 氏が[次のサイクル向けのブランチに適用した](https://ratatoskr.run/platform-driver-x86/2026/10/17695727)もので、順当にいけば 7.3 の次の 7.4 に向けた準備です。

大事な点として、話題の [oxpec](https://github.com/torvalds/linux/commits/master/drivers/platform/x86/oxpec.c) と [ayaneo-ec](https://github.com/torvalds/linux/commits/master/drivers/platform/x86/ayaneo-ec.c) は、すでにメインラインにあるドライバーです（履歴では oxpec が2025年4月、ayaneo-ec が2025年11月から）。今回は、そこへの機種の追加が中心です。

- OneXPlayer 3（Intel）: [パッチ](https://ratatoskr.run/platform-driver-x86/2026/09/17611807)によれば、バッテリーを通さない給電（"Battery bypass"）、充電の上限、ファンカーブ、ファンの回転数の読み取りなどが動作確認されています。
- AYANEO 2S: [AYANEO 2 と同じファンの仕組みに加えて、充電の制限にも対応します](https://ratatoskr.run/platform-driver-x86/2026/09/17611772)。ayaneo-ec の充電を止める設定は、[スリープからの復帰では保たれ、再起動するとリセットされます](https://lkml.iu.edu/2511.0/00865.html)。
- ROG Flow X13（2023年、GV302X）: [折りたたんでもデスクトップがタブレットモードに切り替わらない問題を直します](https://ratatoskr.run/platform-driver-x86/2026/09/17631295)。
- ASUS ProArt（H7606 シリーズ）: 通常の方法で dGPU を再び有効にできないため、[代替の WMI デバイス ID を試す処理が加わります](https://ratatoskr.run/platform-driver-x86/2026/09/17642989)。
- HP: [OMEN 17-ck1xxx でサーマルプロファイルが使えるようになり](https://ratatoskr.run/platform-driver-x86/2026/09/17644693)、[Victus 15-fb3xxx も既存の OMEN 向けの仕組みの対象に加わります](https://ratatoskr.run/platform-driver-x86/2026/09/17648483)。

書き手が好きなのは、バッテリーまわりの地味な改善です。携帯ゲーム機は、つなぎっぱなしで遊ぶ人が多いですからね。

誰が書いたのかは、一次では確定できませんでした。作者欄には個人名義のメールアドレスが並びますが、メーカーが関わっていないと書いた一次は見当たりません。使いたい人たちが手を動かしている、と書き手は読んでいますが、断定は避けます。そうだとすれば、その人たちがいなくなれば止まる、という危うさとも隣り合わせです。

新機能を受け付けるマージウィンドウは[約2週間](https://raw.githubusercontent.com/torvalds/linux/master/Documentation/process/2.Process.rst)で、7.3 の最終版のあとに開きます。ディストリビューションに届くのは、ローリングリリースなら早め、長期サポート版なら少し先、というのが書き手の見通しです。

動画の訂正です。

- 動画では「実は、AYANEO向けとOneXPlayer向けのドライバーは、メーカーが書いたものではないんです。」と紹介しましたが、メーカーが書いていないことを示す一次は確認できませんでした。確認できたのは、作者が個人名義で投稿していることまでです。

## 3. Drgn 0.3 — Python でカーネルを調べるデバッガーの新版

Drgn は、[公式ドキュメント](https://drgn.readthedocs.io/en/latest/)によれば Meta で Linux カーネルのデバッグのために開発されたデバッガーです。[README](https://github.com/osandov/drgn) は "drgn aims to make scripting as natural as possible so that debugging feels like coding." と、デバッグがコーディングのように感じられることを目標に掲げています。

0.3.0 は、[公式のリリースハイライト](https://drgn.readthedocs.io/en/latest/release_highlights/0.3.0.html)では10月9日のリリースです（GitHub と [PyPI](https://pypi.org/project/drgn/0.3.0/) への公開は UTC で10月10日）。pip で入り、Python 3.8 以降が必要です。動作中のカーネル、vmcore などのダンプ、C で書かれたユーザー空間のプログラムを調べられ、動作中のカーネルには [root 権限が必要です](https://drgn.readthedocs.io/en/latest/api_reference.html)。

[2021年12月の Meta のブログ](https://developers.facebook.com/blog/post/2021/12/09/drgn-how-linux-kernel-team-meta-debugs-kernel-scale/)によると、Meta のカーネルチームが、大規模に展開してはじめて見つかるまれなバグを調べるために作ったそうです。同じブログは、起動が GDB の5倍速いとも書いています。これは2021年時点の記述で、今回の版の測定値ではありません。

0.3.0 の主な変更です。

- QEMU 上のゲストのデバッグが速くなりました。[従来の QMP 経由の読み取りは "very slow"](https://drgn.readthedocs.io/en/latest/release_highlights/0.3.0.html) でしたが、条件がそろえば QEMU のプロセスから直接メモリを読みます。
- デバッグ情報やコアダンプを信頼できない入力として扱う堅牢化が入りました。[リリースノート](https://api.github.com/repos/osandov/drgn/releases/tags/v0.3.0)には、バッファオーバーフロー、範囲外アクセス、整数オーバーフローなどの修正が並びます。
- Linux 7.2 と 7.3 に対応し、LoongArch64 も認識されるようになりました。
- 対応できない操作と壊れたデータが、別々の新しい例外で上がるようになりました。前者は `ValueError` を継承しており、既存のコードは "should not break" とされています。

社内の必要から生まれた道具を、Meta が誰でも使える形で公開し、手入れを続けている。それを「Meta が自分たちのコストを払っている」と読むのは、書き手の感想です。

動画の訂正です。

- 動画では「リリースは、だいたい半年ごとのペースです。」と紹介しましたが、[GitHub のリリース](https://api.github.com/repos/osandov/drgn/releases?per_page=12)の公開日は 0.0.33 が2025年10月、0.1.0 が2026年2月、0.2.0 が4月、0.3.0 が10月で、間隔は約2か月から5か月半とまちまちでした。「前の0.2は今年の4月」は一次と一致します。

## 4. Linux ネットワークの保守と AI パッチ — 7.3-rc7 で50件を先送り

ネットワークの保守担当の1人、Jakub Kicinski 氏は、10月8日付の [7.3-rc7 向けのプルリクエスト](https://ratatoskr.run/lkml/2026/10/17710008)に "this is after we shaved off 50 fixes to net-next" と書きました。net-next は[次のリリース向けのコードを集めるツリー](https://docs.kernel.org/process/maintainer-netdev.html)なので、50件の修正が 7.4 向けに回った形です。

ただし、この rc7 のプルリクエストは先送りの理由を書いておらず、AI という語も出てきません。AI の話は、8月18日付の [7.3 のマージウィンドウのプルリクエスト](https://ratatoskr.run/lkml/2026/08/17431143/t)にあります。

- "We are completely overwhelmed, of course." と書いています。
- 大まかな数えでは、net（既存コードの修正用）が632件、net-next（新しいコード用）が648件で、ほぼ同数でした。
- net-next のパッチの3分の1から半分が、AI 駆動の低優先度の修正や整理に "seem"（見える）としています。

対策として "we secured sufficient LLM budget and access (thank you Meta!)" と書き、各パッチに複数の最先端モデルでレビューを走らせるとしています。一方で "the LLMs can only do so much." と、限界にも触れています。

古いコードの整理も進んでいます。4月の 7.1 のマージウィンドウでは、[net-deletions のマージ](https://github.com/torvalds/linux/commit/64edfa65062dc4509ba75978116b2f6d392346f5)で ISDN、アマチュア無線（AX.25）、ATM などが削除されました。削除は138,161行ですが、古い Ethernet ドライバーの分も含みます。理由は "Nobody stepped up to maintain the kernel code." でした。

パッチを作る手間は AI で下がりましたが、読む手間を払うのは今も少数の人間です（書き手の考察です）。AI で作ったパッチを送る前に「これは本当に今必要か」を自分で点検する。それが受け取る側への一番の気遣いだと思います。

動画の訂正です。

- 動画では「原因として挙げられているのが、AIで生成したパッチの大量流入です。」と紹介しましたが、rc7 と rc6 のプルリクエストには、先送りの理由として AI に触れた記述は見つかりませんでした。AI 駆動のパッチに触れているのは、8月の 7.3 のマージウィンドウのプルリクエストです。
- 動画では「実際に、問題のあるパッチの一部は、ここで食い止められている、と説明されています。」と紹介しましたが、プルリクエストにあるのは、複数のモデルでレビューを走らせることと "This eliminates some hallucinations." という一文までで、パッチを食い止めたという記述は確認できませんでした。

## 5. Bitwarden — ストア版と公式サイトの配布版が、商用ライセンスのビルドへ

10月9日（フォーラム表示の日付）、Bitwarden のスタッフが[公式フォーラム](https://community.bitwarden.com/t/published-version-update-in-app-stores/102750)で次のように説明しました。

- 次のリリースから、各ストアで配布するアプリは商用ライセンスのビルドになる。公式サイトからの直接ダウンロードも同じ
- GPLv3 の OSS 版は、引き続き GitHub で更新・公開される
- 現在の機能は両方の版で使え、無料プランも続く（"The free plan is here to stay permanently"）
- セルフホストに変更はなく、影響を受けるのは Bitwarden を再パッケージして転売する者だ

配布経路でライセンスを分ける、いわゆるデュアルライセンスに近い形です（この呼び方は書き手の整理です）。

気になるのは将来です。スタッフは "Some future components will be published under the commercial license and will exist only in that build." と書き、新機能ごとにライセンスを個別に判断するとしています。互換サーバーの Vaultwarden のようなサードパーティについては、"they can continue to choose which features to support and build out on their server." と答えています。

似た騒ぎは2024年10月にもありました。[デスクトップ版 2024.10.0 は「もはやフリーソフトウェアではない」とする Issue](https://github.com/bitwarden/clients/issues/11611) が10月17日に立ち、Bitwarden 側は "merely a bug" として解消を約束しました。10月24日の対応は、SDK のコードの構成とパッケージを調整し、GPL と OSI のライセンスだけでアプリをビルドできるようにするものでした。ライセンスの書き換えではなく、コードの置き場所の整理です。

[HashiCorp も2023年8月、今後のリリースのライセンスを MPL 2.0 から Business Source License に変えています](https://www.hashicorp.com/en/blog/hashicorp-adopts-business-source-license)。無料の便利さの裏で、開発の費用を誰がどう払うのか。その線の引き方が問われている、というのが書き手の見方です。

乗り換え先として名前が挙がる [KeePassXC](https://github.com/keepassxreboot/keepassxc) は、README でコードを "GPL-2 or GPL-3" としています。

動画の訂正です。

- 動画では「互換サーバーのVaultwardenも、自分たちへの影響はないとコミュニティで確認しています。」と紹介しましたが、今回の発表について Vaultwarden 側が確認した記述は見つかりませんでした。Vaultwarden のフォーラムで「影響なし」とした投稿は2024年の騒動のときのもので、投稿者が開発者かどうかも分かりません。
- 動画では「あのときBitwardenは、パッケージングのバグだったと謝って、数日のうちにGPLv3へ戻しました。」と紹介しましたが、一次が示すのは SDK の構成とパッケージの調整で、GPLv3 への再ライセンスではありませんでした。謝罪にあたる記述も見つからず、報告から対応の表明までは7日でした。
- 動画では「全体がGPLv3のKeePassXC」と紹介しましたが、KeePassXC のコードは GPL-2 または GPL-3 で、サードパーティのファイルには別のライセンスがあります。

## まとめ

古い穴を放置するか、ドライバーを誰が書くか、道具を誰が育てるか、AI パッチを誰が読むか、配布版のライセンスをどう分けるか。5つの話に共通するのは、手入れの手間が必ず誰かに乗る、という点です（書き手の考察です）。

すぐにできることは3つあります。担当者のいないサーバーを洗い出して KEV の5製品と突き合わせること、AI で作ったパッチを送る前に必要性を自分で点検すること、使っている OSS のライセンスと配布経路を確かめることです。皆さんの現場では、手入れの手間を、いま誰が払っていますか。

## 参考リンク

- [CISA: 共同勧告 AA26-281A](https://www.cisa.gov/news-events/cybersecurity-advisories/aa26-281a)
- [CISA: KEV の JSON フィード](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)
- [ratatoskr.run: platform-driver-x86 のパッチ（OneXPlayer 3）](https://ratatoskr.run/platform-driver-x86/2026/09/17611807)
- [Drgn 0.3.0 のリリースハイライト](https://drgn.readthedocs.io/en/latest/release_highlights/0.3.0.html)
- [LKML ミラー: Networking for v7.3-rc7](https://ratatoskr.run/lkml/2026/10/17710008)
- [Bitwarden 公式フォーラム: ストア版アプリのライセンス変更](https://community.bitwarden.com/t/published-version-update-in-app-stores/102750)
