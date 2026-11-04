---
title: "WordPress コアの CVE-2026-119977 は KEV 入りで連邦機関の期限は11月6日、openSUSE Leap 16.1 は Immutable Mode を統合、GIMP 3.2.8 は画像プラグインの整数オーバーフローを修正、KDE Linux の NTSYNC はカーネル 6.14 と Wine 11.0 で使える、Android の CVE-2026-58868 は Critical（2026/11/05 Linux・OSSトレンド）"
date: 2026-11-05T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "WordPress", "openSUSE", "GIMP", "KDE", "Android"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

修正が公開されても、手元で適用されるまでには時間があります。動画はこの「途中」を5つの話題で追いました。WordPress では、コア更新の最中のごく短い時間が穴になりました。openSUSE Leap 16.1 は、失敗しても戻せる不変の方式を、選べるモードとして本体に取り込みました。GIMP 3.2.8 には、古い画像プラグインへの修正が入っています。KDE Linux の NTSYNC では、カーネル、Wine、ディストリビューションと部品が揃ってきました。Android の11月の Bulletin の修正は、メーカーや通信事業者を通じて端末に届きます。

「途中」でくくるのは書き手の考察で、一次情報がそう述べているわけではありません。動画の発言で一次情報と合わなかったものと、出典をたどれなかったものは、節ごとに「動画の訂正」として挙げました。

確認は2026年11月5日 7:50〜8:00（日本時間）に行いました。NVD の状態や配布状況のように動くものは、その箇所にも時刻を添えています。

{{< youtube "XBWlgbcnPCI" >}}

## 1. WordPress コアの CVE-2026-119977 — 更新の最中に未認証でコードを実行されるおそれ

CVE-2026-119977 は、WordPress のコアの更新処理にある穴です。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-119977) は、フルパッケージによるコア更新で使われる、予測できて Web から届く展開先（"predictable, web-accessible staging paths"）が原因で、未認証の攻撃者が更新の間にサーバー上でコードを実行できる、と書いています。対象は4.7から7.1.3までで、修正版はブランチごとに違います。

[9月29日の記事](https://blog.fuga.jp/posts/2026-09-29-linux-oss-trend/)の第1節の CVE-2026-87902 も WordPress コアの穴でしたが、別の欠陥です。[10月14日の記事](https://blog.fuga.jp/posts/2026-10-14-linux-oss-trend/)の第1節の Bricksforge は、プラグインの穴でした。今回の CVE について、NVD、CVE.org、KEV の記述にプラグインやテーマへの言及はありません。

### KEV と期限

CISA の KEV（悪用が確認された脆弱性のカタログ）に、この CVE が載りました。[KEV の JSON](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)（catalogVersion 2026.11.04）の `dateAdded` は 2026-11-03（火。日付のみで時刻はなし）、`dueDate` は 2026-11-06（金）です。`requiredAction` は CISA の BOD 26-04 に触れており、`forensicTriage` は Yes です。

BOD 26-04 の期限は、連邦文民行政部門（FCEB）の機関に対するもので、民間の事業者や個人の期限ではありません（[10月26日の記事](https://blog.fuga.jp/posts/2026-10-26-linux-oss-trend/)の第1節）。同じ節の訂正と同じ数え方で確認時点の JSON を数えると、BOD 26-04 が出た2026年6月10日以降に追加された151件のうち120件が、追加から3日の期限です。`forensicTriage` が Yes の97件は、すべて3日です。

### 評価は割れている

- WordPress 自身のリポジトリの[勧告](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-4w3m-c66w-69mg)（GHSA-4w3m-c66w-69mg）は、深刻度を low としています。CVE 番号も CVSS の値も載っておらず、low とした理由も書かれていません
- NVD には、CVSS v3.1 の 8.1（High）が載っています。攻撃の複雑さは High です。採点者は Wordfence で種別は Secondary、NVD 自身（Primary）の採点はありません。状態は Analyzed です（11月5日 7:49 時点）。[CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-119977) の CNA も Wordfence です。弱点の種別は、NVD と KEV によれば CWE-367（TOCTOU、確認から使用までの競合状態）です
- GitHub の Advisory Database には、WordPress の勧告とは別の記録（[GHSA-p6jj-qrp3-7m4g](https://github.com/advisories/GHSA-p6jj-qrp3-7m4g)）があります。深刻度は High ですが、未レビュー（unreviewed）の記録で、8.1 は NVD 由来です
- NVD に載る CISA の SSVC（2026年11月3日付）は、exploitation が active、automatable が no です

### 悪用の観測

Wordfence の原文は取得できませんでした。[Rescana](https://www.rescana.com/post/wordpress-core-7-1-4-upgrade-staging-race-rce) が引く Wordfence の記述によれば、最初の21時間に、展開先に置かれた setup-config.php の経路を狙うリクエストを18,500件超記録しています。これはリクエストの数で、成功の数ではありません。すべてが同じ経路でもありません。同じく Rescana が引く Wordfence の記述によれば、展開先は通常、数秒しか残りませんでした。こちらは同社の実験環境での観察です。

### 修正版と確認

- 修正版は、7.1系が [7.1.4](https://wordpress.org/documentation/wordpress-version/version-7-1-4/)（10月28日（水）公開）、7.0系が 7.0.8 です。それより古いブランチにも 6.9.11、6.8.12 のように修正版があり、最も古いのは 4.7系の 4.7.39 です。ブランチごとの版は、上記の勧告と 7.1.4 の文書にあります。7.1.4 の文書は、修正を22件と数え、4.6以前はセキュリティ更新を受けないとしています。確認時点の最新は 7.1.4 です
- 自動更新は、wp-config.php の `WP_AUTO_UPDATE_CORE` で設定します（[wp-config.php の文書](https://developer.wordpress.org/advanced-administration/wordpress/wp-config/)）。既定は `'minor'` で、セキュリティ・保守リリースはこの既定でも対象です
- 更新の最中の展開先（wp-content/upgrade）への Web からのアクセスを遮断する案は、Rescana と [xhack.io](https://xhack.io/blog/cve-2026-119977-wordpress-core-upgrade-rce) が引く Patchstack の助言です。WordPress や NVD の文書にはありません。Rescana は、修正版への更新も古いコードで展開されるという自社の読みから、更新の前に遮断するよう書いています
- 更新のあとに、見覚えのない PHP ファイルが無いかを確かめるのは、書き手の補足です。一次情報の助言ではありません

動画の訂正です。

- 動画では、WordPress が世界の Web サイトの約43%で使われているとされている、と紹介しました。W3Techs の11月4日付の値は39.5%です（[W3Techs](https://w3techs.com/technologies/details/cm-wordpress)）。
- 動画では、更新のファイルを広げている「数秒から数十秒」の隙を突く、と紹介しました。確認できたのは、Wordfence の実験環境で「数秒」しか残らなかったという記述で、二次の引用です。「数十秒」の出典は確認できませんでした（[Rescana](https://www.rescana.com/post/wordpress-core-7-1-4-upgrade-staging-race-rce)）。
- 動画では、書き込みの遅い格安ホスティングや NFS の共有サーバーで、この隙が長引きやすいと報告されている、と紹介しました。この報告の出典は確認できませんでした。

## 2. openSUSE Leap 16.1 — Leap Micro を統合した Immutable Mode

openSUSE Leap 16.1 は、11月3日（火）に公開されました（Roadmap では UTC 12:00、日本時間 21:00）。[告知](https://news.opensuse.org/2026/11/03/leap-unites-traditional-and-immutable)は、Immutable Mode の Leap 16.1 が Leap Micro に代わり、Leap Micro 6.3 も 7.0 も出ない、と書いています。

### Immutable Mode

読み取り専用のルートファイルシステムに、transactional-update で更新を入れる方式です。告知によれば、更新のたびに新しいスナップショットができ、問題があればコマンド1つで戻せます。[RC の告知](https://news.opensuse.org/2026/09/28/leap-161-rc/)の手順では、更新を新しいスナップショットに入れ、再起動してそれを使い、戻すときは `rollback` です。選ぶには、通常の Leap 16.1 のインストールイメージを起動して、Agama（版は24）で Immutable Mode を選びます。インストールモードは、あとから変えられません（[リリースノート](https://doc.opensuse.org/release-notes/x86_64/openSUSE/Leap/16.1/release-notes-leap-161.txt)）。

[ダウンロードページ](https://get.opensuse.org/leap/16.1/)には、UEFI の aarch64 の欄に Immutable Self-install Image があります。個別の機種への対応は確認していません。

### 移行

- Leap Micro 6.2 の利用者は、openSUSE の移行ツールで Leap 16.1 の Immutable Mode へ移れます。告知は、この経路をまだ実験的とし、先にバックアップを取るよう書いています
- 通常版（Traditional）の Leap 16.0 から 16.1 へは、[公式の手順書](https://en.opensuse.org/SDB:System_upgrade)に、`zypper --releasever 16.1 dup` と `opensuse-migration-tool` の両方が案内されています。公式の手順書は、非公式のリポジトリを先に無効にするよう書いています

### 同じ日に出たのか

告知の本文は、Leap 16.1 は企業向けの SLES と同じ日に出荷される初めての Leap だ、と書いています。ところが告知の冒頭には訂正があり、Leap 16.1 は SUSE Linux Enterprise Server 16.1 と同じ日には出荷されず、SLES 16.1 は今月に出荷される見込みだ、と書かれています。確認時点（11月5日 7:54）も、告知は訂正が付いたままで、SLES 16.1 の出荷は確認できていません。Roadmap の記述は、SLES 16.1 に揃える（"aligned with SLES 16.1 FCS"）のままです。

告知は、保守更新が公開後に途切れないよう、SLES 16.1 に合わせた、と書いています。サポートは各版24か月で、[Lifetime のページ](https://en.opensuse.org/Lifetime)によれば Leap 16.0 から同じです。年1回の更新は、2031年の Leap 16.6 まで続く見込み（"expected"）です。

同梱の版は、告知によれば、Linux 6.12、Plasma 6.6、GNOME 48、LibreOffice 26.2、systemd 257 です。

動画の訂正です。

- 動画では、その場のアップグレードでは切り替えられないので、不変の方式へは再インストールか移行ツールになる、と紹介しました。切り替えられない点と再インストールの点は、リリースノートに沿っています。ただし、通常版から Immutable Mode へ移す手段として移行ツールを挙げた根拠は確認できませんでした。移行ツールの README は、通常版から Immutable への移行を "generally unsupported" と書いています。移行ツールで Immutable Mode へ移れるのは、Leap Micro 6.2 です（[移行ツール](https://github.com/openSUSE/opensuse-migration-tool)、[告知](https://news.opensuse.org/2026/11/03/leap-unites-traditional-and-immutable)）。

## 3. GIMP 3.2.8 — 古い画像プラグインの整数オーバーフロー

GIMP 3.2.8 の[公式の告知](https://www.gimp.org/news/2026/11/02/gimp-3-2-8-released/)は、11月2日付です。セキュリティの節で、"recent advances in software scanning and testing programs"（ソフトウェアのスキャンとテストの進歩）のために多くの報告を受け続けている、と書いています。告知に AI の語はありません。告知によれば、3.2.6 以降に82件の報告がクローズされ、300のコミットがあり、27名が貢献しました。

[Phoronix](https://www.phoronix.com/news/GIMP-3.2.8-Released) は、見出しに "Due To AI Reports" と書きました。Phoronix の本文は GIMP の告知を引くもので、AI が脆弱性を発見したとは書いていません。

告知によれば、最も多い報告は、古い画像プラグインとレガシーフィルターが、画像ファイルの示す大きさの情報を信用しすぎる、というものです。その情報を意図的に書き換えると、プラグインがクラッシュしうる（"the plug-in (not GIMP itself)"）、とあります。

### 確認できた例

3.2.8 の NEWS は、セキュリティを "Various security bugs fixed." の1行で済ませており、CVE を列挙していません。次の3件は、NVD と CVE.org で確認できた例です。

| 形式 | CVE | CVSS v3.1（採点者） | 修正が入った版 |
|---|---|---|---|
| FITS | CVE-2026-66758 | 7.8（Red Hat、Secondary） | 3.2.6 |
| ICO | CVE-2026-90948 | 7.8（Red Hat、Secondary） | 3.2.8 |
| GIF（書き出し） | CVE-2026-106064 | 6.3（Red Hat、Secondary） | 3.2.8 |

- NVD 自身の採点はありません。確認時点の NVD の状態は、FITS が Modified、ICO と GIF が Awaiting Analysis です。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-66758) の FITS の説明は、幅と高さを符号付き32ビット整数で計算し、積があふれて小さなバッファが確保され、ヒープの破壊につながる、というものです
- 任意コード実行の語があるのは、FITS と ICO の記述です。GIF の記述は、ヒープバッファオーバーフローまでです
- FITS の修正は3.2.6に入りました。ICO の修正は[コミット](https://gitlab.gnome.org/GNOME/gimp/-/commit/07c8d365873dc748a11a2df19e7a9eeab1c10667)の入った3.2.8です。GIF の CVE と3.2.8のコミットの紐付けは推定です。CVE にコミットへのリンクがなく、コミットにも CVE 番号がありません
- 3.2.6 の NEWS には、約35件の CVE が列挙されています。9月9日の記事（[第2節](https://blog.fuga.jp/posts/2026-09-09-linux-oss-trend/)）の GEGL の HDR パーサーの CVE-2026-18300 は、別の穴です

### 手元で見ること

3.2.8 の公式のビルドは、Linux（AppImage、Flatpak、Snap）、Windows、macOS にあります。確認時点（11月5日 7:50台）の [Debian のトラッカー](https://security-tracker.debian.org/tracker/source-package/gimp)では、FITS と ICO は bookworm が未修正で trixie 以降が修正済み、GIF は sid だけが修正済みです。

影響の見方として、知らない相手の画像を開く人、画像を自動で処理する仕組み、FITS を扱う天文データの3つに分けるのは、書き手の整理です。公式の区分ではありません。

動画の訂正です。

- 動画では、中身は保守リリースだがセキュリティ修正の多さが目立つ、と紹介しました。3.2.8 の NEWS は "Various security bugs fixed." の1行で、多さは一次情報で確かめられません。CVE を約35件列挙しているのは、3.2.6 の NEWS です（[3.2.8 の NEWS](https://gitlab.gnome.org/GNOME/gimp/-/raw/GIMP_3_2_8/NEWS)）。
- 動画では、あふれた分でヒープが壊れ、任意のコード実行につながるおそれがある、と3件に通じる説明として紹介しました。NVD の記述に任意コード実行の語があるのは FITS と ICO で、GIF にはありません（[GIF の NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-106064)）。
- 動画では、プラグインは別のプロセスとして動くので本体とは切り分けられる、と紹介しました。公式の告知にあるのは、クラッシュするのはプラグインで GIMP 本体ではない、という点までです。別のプロセスという説明は告知になく、番組の補足でした。直前の公式の説明の続きに聞こえるため、訂正します（[告知](https://www.gimp.org/news/2026/11/02/gimp-3-2-8-released/)）。

## 4. KDE Linux — NTSYNC を支える部品

KDE Linux が ntsync カーネルモジュールを既定で有効にした話は、[11月4日の記事](https://blog.fuga.jp/posts/2026-11-04-linux-oss-trend/)の第4節にあります。Beta に向けた進捗が85%のままである点、Beta の残りの作業の扱いも、そこに書いたとおりです。ここでは繰り返さず、NTSYNC の仕組みと、周辺の部品が揃ってきた経緯を書きます。

### NTSYNC とは

[kernel.org の文書](https://docs.kernel.org/userspace-api/ntsync.html)は、ntsync を、ユーザー空間の NT エミュレーターによる NT の同期プリミティブのエミュレーションを支えるドライバー（"a support driver for emulation of NT synchronization primitives by user-space NT emulators"）と説明しています。このドライバーが作るのが、キャラクターデバイス `/dev/ntsync` です。[OMG Ubuntu](https://www.omgubuntu.co.uk/2026/01/wine-11-0-released/amp) は、Wine が Windows NT の同期の仕組みを、ユーザー空間ではなくカーネルでエミュレートする、と説明しています。

効果について、KDE は Wine と Proton で遊ぶゲームの性能が上がる、と書くにとどまります。OMG Ubuntu は、マルチスレッドのアプリやゲームで性能が上がり、シングルスレッドのアプリは、効果があってもわずかだろう、と書いています。

### 揃ってきた部品

- Linux カーネル: [Phoronix](https://www.phoronix.com/news/Linux-6.10-char-misc) によれば、6.10 で初期のコードが入りましたが、"broken" の指定で未完成でした。[完成版は 6.14](https://www.phoronix.com/news/Linux-6.14-Char-Misc-NTSYNC) です。GamingOnLinux も、6.14（2025年3月）で入ったと書いています
- Wine: 2026年1月の Wine 11.0 は、Linux 6.14 以降で ntsync を使えます（OMG Ubuntu）。GamingOnLinux は、Wine 10.16 で ntsync への対応が加わったと書いています。安定版としては 11.0 です
- SteamOS: 3.7.20 Beta（2026年1月9日）の changelog に "Added ntsync driver." とあります（[GamingOnLinux](https://www.gamingonlinux.com/2026/01/steamos-3-7-20-adds-the-ntsync-driver-to-help-improve-some-game-performance)）
- Fedora: [Phoronix](https://www.phoronix.com/news/Fedora-44-Nicer-NTSYNC)（2025年12月）によれば、FESCo は Fedora 44 向けに、Wine や Steam などのパッケージを通じて ntsync を自動で読み込む案を承認しました。Fedora の公式の Change のページは確認していません

動画の訂正です。

- 動画では、Beta に向けた進捗が85%に届いたという月次の報告の中で、NTSYNC が目玉の変更として挙がった、と紹介しました。10月号の文面は "remains 85% of the way there" で、85%は9月号から変わっていません。11月4日の記事の訂正と同じ内容です（[10月号](https://blogs.kde.org/2026/11/01/october-2026-in-kde-linux/)、[11月4日の記事](https://blog.fuga.jp/posts/2026-11-04-linux-oss-trend/)）。
- 動画では、Beta の前に残っている項目が5つあり、swap、Discover、デュアルブート、Flatpak のクラッシュ、インフラの移行だ、と紹介しました。KDE の月次記事に、残りの作業の一覧はなく、「5つ」は確認できませんでした。インフラの移行は、10月に進めた作業です。Flatpak のクラッシュは確認できませんでした。swap、Discover、デュアルブートは、Beta のマイルストーンの [Issue](https://invent.kde.org/kde-linux/kde-linux/-/issues/552) にあります。

## 5. Android の CVE-2026-58868 — 11月の Bulletin の Critical

[2026年11月の Android Security Bulletin](https://source.android.com/docs/security/bulletin/2026/2026-11-01)（11月2日公開）の表を数えると、CVE は216件で、Critical が23件、High が193件です。[11月4日の記事](https://blog.fuga.jp/posts/2026-11-04-linux-oss-trend/)の第5節の CVE-2026-58882 と同じ Bulletin ですが、別の番号です。

CVE-2026-58868 は、Bulletin の Framework の節に載り、A-486464711、種類は RCE（リモートコード実行）、深刻度は Critical、対象は Android 14・15・16・16-qpr2・17です。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-58868) と [CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-58868) の説明は、FrameDecoder.cpp の onOutputReceived に、ヒープバッファオーバーフローによる範囲外書き込みがあり、追加の実行権限なしに遠隔でコードを実行できる可能性がある、とし、悪用に利用者の操作は要らない、と書いています。この操作不要は分類上の記述で、実際に攻撃が成り立つかを示したものではありません。経路について、Google は書いていません。

NVD は確認時点（11月5日 7:49）で Awaiting Analysis で、CVSS の値はありません。深刻度は、Bulletin によれば、プラットフォームとサービスの緩和策が無効か、回避された場合の影響の評価です。

### 悪用の有無

- [Security Affairs](https://securityaffairs.com/202414/mobile-2/cve-2026-58868-critical-android-bug-could-let-attackers-run-remote-code.html) は、"Google is now aware of active exploitation of the flaws in its November 2026 bulletin." と書いています。これは複数の脆弱性（"the flaws"）についての文で、CVE-2026-58868 を名指しした文ではありません
- Bulletin に、悪用に触れた記載はありません
- CISA の KEV の JSON（catalogVersion 2026.11.04）に、この CVE はありません
- NVD に載る CISA の SSVC は、exploitation が none です（11月2日時点）

以上を分けて見て、悪用は確認できていないものとして扱う、というのは書き手の整理です。「悪用されていない」と断定する材料はありません。

### パッチレベルと配布

58868 は、2026-11-01 の表の項目です。Bulletin は、パッチレベル 2026-11-01 以降でその区分のすべてが直り、2026-11-05 以降でこの Bulletin のすべてが直る、と書いています。11月4日の記事の記述と同じです。Google は、パートナーに、Bulletin の公開の少なくとも1か月前に通知する、と書いています。端末への配布は、Security Affairs によれば、メーカーと通信事業者によります。

Bulletin に緩和策の記載はありません。企業向けに、MDM でパッチレベルを報告させる案を挙げるのは [Rescana](https://www.rescana.com/post/android-security-bulletin-november-2026-cve-2026-58868-prepare-now) で、Google の文書ではありません。

動画が引き合いに出した2015年の Stagefright は、メディア処理ライブラリの名を取り、MMS で操作なしに届くとされた脆弱性でした（[Wikipedia](https://en.wikipedia.org/wiki/Stagefright_(bug))）。Google は、2016年に[メディア処理の隔離を強化した](https://android-developers.googleblog.com/2016/05/hardening-media-stack.html)と書いています。ただし、今回の穴との関係を示す出典は確認していません。

動画の訂正です。

- 動画では、緩和策として MMS の自動取得を切る方法が挙げられている、と紹介しました。誰が挙げた方法かを特定できませんでした。Bulletin に緩和策の記載はありません（[Bulletin](https://source.android.com/docs/security/bulletin/2026/2026-11-01)）。
- 動画では、詳しい人向けに、GrapheneOS のような別の OS へ移る選択肢も挙げられている、と紹介しました。この選択肢を挙げた出典は確認できませんでした。

## まとめ

WordPress の穴は、対象の版でコア更新を動かしている間に狙われるもので、修正版は 7.1.4 をはじめ各ブランチにあります。評価は、WordPress 自身の勧告が low、NVD に載る Wordfence の CVSS v3.1 が 8.1 で、CISA は KEV に載せました。openSUSE Leap 16.1 は Immutable Mode を統合し、同じ日に出たという告知の本文は、冒頭の訂正で撤回されています。GIMP 3.2.8 の公式の告知に AI の語はなく、AI に触れたのは Phoronix の見出しです。KDE Linux の NTSYNC は、カーネル、Wine、SteamOS と部品が揃い、Fedora は案の承認まで確認しています。Android の CVE-2026-58868 は、悪用の有無が出典ごとに分かれています。

手元で見ておくものは次のとおりです。

- WordPress: 管理画面などで版を確かめる。対象は4.7から7.1.3で、最新は 7.1.4、7.0系は 7.0.8。古いブランチにも 4.7.39 まで修正版がある。4.6以前は修正が出ない。`WP_AUTO_UPDATE_CORE` の設定も見る
- Android: セキュリティパッチレベルを確かめる。CVE-2026-58868 は 2026-11-01 以降、Bulletin のすべては 2026-11-05 以降で直る。Bulletin の表に載るのは14から17で、13以下が安全という意味ではない
- GIMP: インストールした版を確かめる。3.2.8 に上げる。FITS の修正は3.2.6に入っている
- openSUSE Leap Micro 6.2 の利用者: 移行ツールで Leap 16.1 の Immutable Mode へ移れるが、実験的。先にバックアップを取る。通常版から Immutable Mode へは、その場では切り替えられず、再インストールが要る

## 参考リンク

- [NVD: CVE-2026-119977](https://nvd.nist.gov/vuln/detail/CVE-2026-119977)
- [WordPress 7.1.4 のバージョン文書](https://wordpress.org/documentation/wordpress-version/version-7-1-4/)
- [openSUSE Leap 16.1 の告知](https://news.opensuse.org/2026/11/03/leap-unites-traditional-and-immutable)
- [GIMP 3.2.8 の告知](https://www.gimp.org/news/2026/11/02/gimp-3-2-8-released/)
- [kernel.org: ntsync](https://docs.kernel.org/userspace-api/ntsync.html)
- [KDE Linux: 2026年10月号](https://blogs.kde.org/2026/11/01/october-2026-in-kde-linux/)
- [Android Security Bulletin 2026年11月](https://source.android.com/docs/security/bulletin/2026/2026-11-01)

（2026/11/05 Linux・OSSトレンド）
