---
title: "Debian APT の CVE-2026-109518 は非ゼロの再試行設定が前提、Go の encoding/json/v2 は約6年で標準ライブラリへ、Affinity は Linux 版を開発中と X で表明、Linux Mint は Sleep Modes でハイバネーションを予定、OpenSSH 10.6p2 は musl・PAM なしの環境の認証回避に対処（2026/11/06 Linux・OSSトレンド）"
date: 2026-11-06T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Debian", "Go", "Affinity", "Linux Mint", "OpenSSH"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

ソフトウェアの初期値は、誰かがある場面を想定して決めたものです。動画は、その値が自分の環境でも合っているかを、5つの話題で確かめました。apt の再試行回数の既定値は、ダウンロードの失敗を助けるはずが、穴の前提条件になりました。Go の `encoding/json` は、約6年かけて見直した新しい API を標準ライブラリに入れました。Affinity は、Linux 版を開発中だと X で答えました。Linux Mint は、既定では使えなかったハイバネーションを、設定ページ付きで戻す予定です。OpenSSH 10.6p2 は、特定の構成の Linux でパスワード認証が通ってしまう問題への回避策を入れました。

5本を「初期設定を疑う」でまとめたのは書き手で、一次情報の主張ではありません。放送の内容が一次情報と食い違った点と、出典が見つからなかった点は、各節の終わりの「動画の訂正」に並べています。

記事の事実は、2026年11月6日 6:50〜7:00（日本時間）に確かめました。NVD の状態や CVE 番号の割り当てなど、あとで変わりうるものには、確認した時刻も書いています。

{{< youtube "g4htFdCUjWU" >}}

## 1. Debian APT の CVE-2026-109518 — 検証のあとにパッケージを差し替えられるおそれ

Debian の勧告 [DSA-6607-1](https://lists.debian.org/debian-security-announce/2026/msg00526.html)（11月4日（水）公開）は、APT は HTTP のリダイレクトで同じ URI になった2つのダウンロードを結合しうると書いています。HTTP のダウンロードを再開するときのファイルの扱いに問題があり、通信に割り込む中間者攻撃者が、検証のあとにパッケージを差し替えて、root として任意のコードを実行させられる、という説明です。NVD は原因を、ハードリンクの再利用と書いています。root でのコード実行は、開発者のアナウンスでも "potential"（可能性）、Ubuntu の勧告でも "possibly"（おそらく）と、留保が付いています。

### 前提条件

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-109518) の説明が挙げる前提は3つです。

- 攻撃者が、APT クライアントとアーカイブサーバーの間の HTTP の通信を操作できること。悪意あるミラーやプロキシを含みます
- クライアントがリダイレクトに従うこと
- 非ゼロの `Acquire::Retries` が設定されていること

`Acquire::Retries` の既定値は、[apt の changelog](https://salsa.debian.org/apt-team/apt/-/raw/main/debian/changelog) によれば、2.3.2（2021年4月23日付、experimental）で、失敗したダウンロードを3回再試行する設定として既定で有効になりました。以前の既定値は0です。NVD は、3が既定なのは Debian 12（bookworm）と Ubuntu 22.04 LTS からで、それより古いリリースは既定の設定では影響を受けない、と書いています。ただし、開発者の[アナウンス](https://lists.debian.org/deity/2026/11/msg00005.html)は、古いリリースでもユーザーのスクリプトが設定しているかもしれない、と注意しています。

### 評価と日付

CVSS は、NVD API の確認時点（11月6日 6:51）で、v4.0 の 7.7（High）です。採点者は Ubuntu の CNA（security@ubuntu.com）で、種別は Secondary です。NVD 自身（Primary）の採点はなく、状態は Received です。開発者のアナウンスは、この問題を "critical" と呼んでいます。これは深刻度を表す語で、スコアではありません。CISA の KEV には、この時点で載っていません。

修正コミットの日付は10月12日（月）、勧告の公表は11月4日（水）です。CVE.org の公開は日本時間の11月5日（木）0:49 になります。

報告者は Max Justicz 氏です。同氏は2019年にも、apt の HTTP リダイレクトの処理について CVE-2019-3462 を報告しています（[DSA-4371-1](https://www.debian.org/security/2019/dsa-4371)）。今回の報告メールのアドレスは、2019年の本人のブログと同じドメインですが、同一人物だと確認できる文面はありません。2019年の穴は、リダイレクトの処理が、通信で受け取ったフィールドを適切に整えていなかったもので、今回とは別の問題です。

### 修正版と確認

- Debian 13（trixie）は 3.0.4、Debian 12（bookworm）は 2.6.2 で直りました。bookworm は LTS の勧告（[DLA-4880-1](https://lists.debian.org/debian-lts-announce/2026/11/msg00004.html)）です。確認時点で、Debian 11（bullseye）向けの勧告は見つかっていません。版の表は [Debian セキュリティトラッカー](https://security-tracker.debian.org/tracker/CVE-2026-109518)にあります
- Ubuntu は [USN-8996-1](https://ubuntu.com/security/notices/USN-8996-1)（11月4日）で、14.04 から 26.10 までを1本で扱っています。20.04 以前の修正は Ubuntu Pro が必要です。USN は、通常のシステム更新で必要な変更がすべて入る、と書いています
- すぐ更新できないときの手として、oss-security の Jan Schaumann 氏が、`apt.conf` に `Acquire::Retries 0;` を入れると、更新するまで緩和できるかもしれない（"may mitigate"）と[投稿](http://www.openwall.com/lists/oss-security/2026/11/04/12)しました。Debian と Ubuntu の勧告に、暫定策の記載はありません。更新の前に入れるべきか、という順序についても、勧告は何も書いていません
- 取得先を HTTP から HTTPS に変える案は、勧告にも NVD にもありません。前提が HTTP の経路上の操作なので、経路上の攻撃者には効きうる、というのは書き手の補足です。悪意あるミラーが前提に含まれる点は、HTTPS では変わりません

署名検証そのものの実装の話は、[10月5日の記事](https://blog.fuga.jp/posts/2026-10-05-linux-oss-trend/)の第3節にあります。今回は、検証のあとの差し替えで、別の問題です。

動画の訂正です。

- 動画では、ここでいう一時エラーは HTTP の500番台の応答だ、と紹介しました。apt 2.6.1 のソースで再試行の対象になるのは、408、429、500、502、503、504、599 です。500番台のすべてではありません（[apt 2.6.1 の basehttp.cc](https://sources.debian.org/data/main/a/apt/2.6.1/methods/basehttp.cc)）。
- 動画では、取得先を http から https へ変えることを、3つ目の対応として紹介しました。この助言を述べた一次の文書は確認できませんでした。Debian、Ubuntu、NVD の文書に記載はありません（[開発者のアナウンス](https://lists.debian.org/deity/2026/11/msg00005.html)）。

## 2. Go の encoding/json/v2 — 約6年かけた新しい JSON API

Go 公式ブログの「A new API for JSON」が、11月4日（水）に公開されました。著者は Joe Tsai 氏、Daniel Martí 氏ら Go チームの7名の連名です。[ブログ](https://go.dev/blog/jsonv2)は、`encoding/json/v2` と `encoding/json/jsontext` が Go 1.27 で安定版として使える、と書いています。Go 1.27 の公開は8月19日です。Go 1.25 のリリースノートには、`GOEXPERIMENT=jsonv2` で有効にできる実験として載っていました（[Go 1.25 のリリースノート](https://go.dev/doc/go1.25)）。Go 1.27 は、この環境変数なしで使えます。

[8月21日の記事](https://blog.fuga.jp/posts/2026-08-21-linux-oss-trend/)の第2節でも、Go 1.27 の `encoding/json/v2` に触れました。ここでは、ブログの内容を足します。

### 約6年と2層の構成

ブログは、2020年末に Martí 氏が v2 の構想を書き始め、ここまで約6年かかった、と書いています。Go 1 の互換性の約束の中では直せない問題が、既存の API に内在していたためです。v1 は v2 の上に実装されており、新旧は混ぜて使えます。構文を扱う `jsontext` と、意味を扱う `v2` の2層になっています。

### v1 と v2 の違い

ブログが挙げる、既定の挙動の違いのうち、動画が取り上げたのは次の5点です。

- 不正な UTF-8: v1 は受け入れ、v2 はエラーにします
- 重複した名前: v2 は JSON オブジェクト内の重複をエラーにします
- nil のスライスとマップ: v2 は空の配列、空のオブジェクトにします
- フィールド名の照合: v2 は大文字小文字を区別します
- `omitempty`: v2 は、JSON としての値が null、空文字列、空のオブジェクト、空の配列になるときに省略します。0 や false は省略しません

重複した名前について、ブログは、攻撃者に悪用されうるもので、過去にも悪用された例がある、と CVE-2017-12635 を挙げています。NVD によれば、Apache CouchDB で、解析器の違いを突き、管理者権限を得られる問題でした。NVD 自身（Primary、nvd@nist.gov）の CVSS は v3.0 の 9.8 です（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2017-12635)）。

厳格な既定は v2 の既定で、既存の `encoding/json`（v1）の挙動は保たれます。[Go 1.27 のリリースノート](https://go.dev/doc/go1.27)は、"Marshaling and unmarshaling behavior is preserved, but the exact text of error messages may differ"（エラーメッセージの文面は変わりうる）と書いています。v1 を使うアプリケーションは、移行する必要がありません。

### 速度と今後

ブログによれば、Unmarshal は v1 に比べて最大10倍、Marshal は v1 と "roughly at parity"（ほぼ同等）です。Marshal は、少し遅くなる場合もあると、ブログ自身が書いています。Go の Issue には、Go 1.27 で構造体の配列の Marshal が旧実装より遅い、という[報告](https://github.com/golang/go/issues/81315)が上がっています（open）。ブログは、遅くなる場合への最適化を続けるとし、Go 1.28 でさらなる改善を見込める（"You can expect additional improvements in Go 1.28"）と書いています。

動画の訂正はありません。

## 3. Affinity の Linux 対応 — 開発中、時期は未定

Affinity の公式 X アカウント（@Affinity）が、11月3日（火）0:25（日本時間）に、Linux への対応を尋ねたユーザーへの返信で、次のように答えました（[投稿](https://x.com/Affinity/status/2117276850795790442)）。

> Affinity is coming to Linux, it's in active development, but we've got no ETA to spill just yet.

訳すと、「Affinity は Linux に来ます。開発は活発に進んでいますが、時期はまだお伝えできません」という意味です。公式アカウントである点は、[OMG! Ubuntu](https://www.omgubuntu.co.uk/2026/11/affinity-linux-release-confirmed) と [heise](https://www.heise.de/en/news/Affinity-is-coming-to-Linux-11509499.html) の報道によります。X の API の情報では、このアカウントは認証済みではありません。OMG! Ubuntu は、時期も、Linux 版の技術的な方法も示されていない、と書いています。heise は、ネイティブ版も Wine のラッパーもありうる、と書いています。

### 経緯

- Canva は、2024年3月26日に Affinity の買収を[発表](https://www.canva.com/newsroom/news/affinity/)しました
- 2025年10月30日（日本時間）に、Canva は新しい Affinity を[無料で提供](https://www.canva.com/newsroom/news/all-new-affinity/)すると発表しました。Mac と Windows 向けで、Canva のアカウントが必要です。Canva AI の機能は、Canva のプレミアム会員向けです。「完全に無料」ではありません
- Linux 版を求める[署名](https://www.change.org/p/bring-the-affinity-suite-to-linux-affinityonlinux)は、Change.org で、11月6日 6:52 時点で 1,026 件です。公式のフォーラムの要望ではありません

### 非公式な方法

公式の Linux 版が無い間は、コミュニティが Wine で動かしています。Wine は、Windows API の呼び出しを、Unix 側の相当する機能で実装するものです（[Wine の README](https://github.com/wine-mirror/wine/blob/master/README.md)）。これらは Canva とは無関係のプロジェクトです。OMG! Ubuntu が2026年1月に紹介した [AppImage](https://www.omgubuntu.co.uk/2026/01/run-affinity-linux-ubuntu-appimage) は、Wine の環境と一緒に Affinity 3.0.2 をまとめたものでした。2026年1月の OMG! Ubuntu は、Canva のアカウントからサインアウトすると再びサインインできない、と注意していました。11月3日の [heise](https://www.heise.de/en/news/Affinity-is-coming-to-Linux-11509499.html) は、Canva へのサインインはコミュニティのプラグインで動くようになった、と書いています。同じ日の OMG! Ubuntu は、Canva へのサインイン、ハードウェアアクセラレーション、UI のスケーリング、新しい版への更新に癖がある、と書いています。状態はプロジェクトと時期によって違います。

動画の訂正です。

- 動画では、Wine は Windows のシステムコールを変換して動かす、と紹介しました。Wine の README は、Windows API の呼び出しを Unix 側の相当する機能で実装する、と書いています（[Wine の README](https://github.com/wine-mirror/wine/blob/master/README.md)）。

## 4. Linux Mint のハイバネーション — Sleep Modes のプレビュー

Linux Mint の月次ニュース「Monthly News – October 2026」（10月31日付）が、ハイバネーションを戻すと書きました。[本文](https://blog.linuxmint.com/?p=5093)は、紹介している機能はプレビューで、作業中であり、次のバージョンに予定されている、と断っています。版名や日程は書かれておらず、代表の Clem 氏はコメント欄で、日程はまだ示せない、と答えています。

### 本文の内容

- 本文は、ハイバネーションは設定が難しく、初期状態では動かず、ディスク上に大きなスワップ領域が要る、と書いています。Ubuntu は利用できるスリープモードから外したため、Linux Mint でも通常は使えなかった、とあります。そのうえで "We're bringing it back."（戻します）と書いています
- システム管理ツールに、Sleep Modes のページが加わります。ハイバネーションを簡単に有効にし、正しく設定できる、とあります
- 通常のスリープは電池が切れると作業が失われます。ハイバネーションは、セッションをディスクに保存して電源を完全に切ります。電力は使いませんが、休止と復帰に再起動より長くかかることもあります
- 新たに加わるモードが2つあります。Hybrid Sleep は、スリープしつつセッションをディスクにも保存します。Suspend-then-Hibernate は、スリープから始め、電池の残量が危険な水準になるとハイバネーションに移ります

ACPI の S3 と S4 との対応は、Mint ではなく[カーネルの文書](https://docs.kernel.org/admin-guide/pm/sleep-states.html)の説明です。S3 は、メモリへの給電を続けるスリープに当たります。ハイバネーションは S4 に相当しますが、電源を切るだけの場合もある、とあります。

### コメント欄の Clem 氏の返信

条件に関する記述は、本文ではなくコメント欄にあります。Clem 氏は、Secure Boot が有効だと、ツールの「検出された問題」に出る、と返信しました。別の返信では、ツールは Secure Boot やスワップの不足など（"etc.." と続きます）の問題を検出し、直すのを手伝う、と書いています。設定は専用の systemd のファイルに書き込まれ、元に戻せる、とも答えています。Mint が「条件」と書いたものではなく、検出される問題の例です。

数値で条件を示す文面は、本文にもコメント欄にもありません。

動画の訂正です。

- 動画では、次のバージョンで取り戻す、と紹介しました。本文は、プレビューであり、作業中だと明記しています（[本文](https://blog.linuxmint.com/?p=5093)）。
- 動画では、条件が2つあり、大きなスワップ領域と Secure Boot だ、と紹介しました。Mint は「条件」とは書いていません。Clem 氏がコメント欄で、検出される問題の例として、Secure Boot とスワップの不足を "etc.." 付きで挙げたものです（[コメント欄](https://blog.linuxmint.com/?p=5093)）。
- 動画では、一部の古いハードウェアや特定のグラフィックドライバでは動かない場合もある、と紹介しました。この出典は確認できませんでした。
- 動画では、スワップの条件が難しいという懸念も出ている、と紹介しました。Mint のブログの本文とコメント欄に、この懸念は確認できませんでした。出所は SNS だけです。

## 5. OpenSSH 10.6p2 — パスワード認証が通る問題への回避策

OpenSSH 10.6p2 が、11月5日（木）に[公開](https://www.openssh.org/txt/release-10.6p2)されました。リリースノートは、musl libc を使い、PAM を無効にした Linux に影響する、重大なセキュリティ上の回避策（"a critical security workaround"）を含む、と書いています。原因は sshd の外にあると考えるが、sshd を経由して悪用でき、sshd 側で避けられる、という説明です。10.6 は10月6日の公開で、[10月9日の記事](https://blog.fuga.jp/posts/2026-10-09-linux-oss-trend/)の第2節で取り上げました。

### 影響を受ける条件

[Alpine の勧告](https://alpinelinux.org/posts/2026-11-05-openssh-password-authentication-bypass/)が挙げる条件は、次の5つがそろったときです。

- musl libc の Linux である
- sshd を PAM なしでビルドしている（Alpine では `openssh-server`。`openssh-server-pam` は PAM が有効なら対象外）
- パスワード認証が有効である（OpenSSH の既定）
- パスワード欄が `*` のアカウントがある
- `$5$` か `$6$` のハッシュを持つ別のアカウントが1つ以上ある

ロック済み（`!`）のアカウントは、パスワードでも鍵でもログインできないため対象外です。Alpine は例の1つです。Damien Miller 氏は、"Alpine Linux is one example"（Alpine Linux は一例）と書いています。Miller 氏は、この問題は、Linux 以外のシステム、Linux と glibc の組み合わせ、パスワード認証に PAM を使う Linux には存在しない、と書いています。

### 発言の出所

Miller 氏の発言は、本人の Mastodon（hachyderm.io）の[投稿](https://hachyderm.io/@damienmiller/117563026759098135)（UTC の11月5日 9:03、日本時間18:03）と、openssh-unix-dev メーリングリストの投稿が同文です。OpenBSD Journal の undeadly.org は、Mastodon の投稿の転載です。問題を知ったのは、前日の11月4日です。報告者は Özgün Kültekin 氏（Wakefield）です。

Miller 氏は、AI エージェントがバグを短時間で再発見する例を、最近複数見ており、時には数時間以内だった（"sometimes within hours"）と書いています。そのため、長い期間の非公開は、主に攻撃者を利する危険な慣行（"a dangerous practice that primarily benefits attackers"）だと考えているそうです。リリースノートは、当面（"for now"）はリリースの頻度を上げる、と書いています。

### CVE と評価

CVE-2026-123158 が割り当てられました。CVE.org の公開は11月5日 15:46（UTC、日本時間11月6日 0:46）で、CNA は MITRE です。Alpine の勧告の時点では、番号は割り当てられていませんでした。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-123158) の状態は Received です（11月6日 6:52 時点）。CVSS は、CNA（MITRE、cve@mitre.org、Secondary）の v3.1 が 8.1（High）です。NVD 自身の採点は、この時点でありません。

別件の CVE-2026-106553 は、GSSAPI の認証に失敗したあとも認証情報が残りうる問題で、10.6 で修正されました。10月9日の記事の第2節では、この件に触れていません。評価は割れています。CNA（MITRE）の CVSS v3.1 は 2.2（Low）、NVD 自身（Primary、nvd@nist.gov）の CVSS v3.1 は 7.5（High）で、状態は Analyzed です。GitHub の勧告（[GHSA-2xxv-m3rc-rvrm](https://github.com/advisories/GHSA-2xxv-m3rc-rvrm)）は 2.2（Low）です。

### 確認と対応

- 自分の環境が、上の5つの条件にあたるかを確かめる。確認は、sshd のビルドと PAM の有無、パスワード認証の設定で行う
- 更新できないときは、sshd の設定で `PasswordAuthentication no` にし、sshd を再起動する。Miller 氏は、設定するか、それらのシステムの SSH を直ちに止めるよう書いています。先に鍵でのログインが通ることを確かめ、確認が終わるまで今のセッションを開けておく、と Alpine は書いています
- 更新は、Alpine の勧告によれば `apk upgrade -U -a` です。パッケージを更新しても動作中の sshd は再起動されないので、あとで `rc-service sshd restart` を実行します。Alpine は、3.16 まで修正を遡って出すと[投稿](https://fosstodon.org/@alpinelinux/117563196640515820)しています。3.16 は修正の遡及先で、問題の起点ではありません

動画の訂正です。

- 動画では、CVE-2026-106553 の深刻度は CVSS 2.2 の Low だ、と紹介しました。2.2（Low）は CNA（MITRE）の v3.1 の採点です。NVD 自身は v3.1 で 7.5（High）を付けており、GitHub の勧告は 2.2（Low）です（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-106553)）。
- 動画では、CVE-2026-123158 は CVSS 8.1 の High という評価が NVD に付いている、と紹介しました。8.1（High）は CNA（MITRE）の v3.1 の採点です。NVD の状態は Received で、NVD 自身の採点は確認時点でありません（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-123158)）。

## まとめ

APT の穴は、HTTP の経路上の攻撃者、リダイレクト、非ゼロの再試行設定がそろったときの問題で、修正版は trixie が 3.0.4、bookworm が 2.6.2 です。Go の `encoding/json/v2` は、v1 の挙動を保ったまま、厳格な既定を v2 側に持たせました。Affinity は、Linux 版を開発中としつつ、時期を示していません。Linux Mint のハイバネーションは、プレビューの段階です。OpenSSH 10.6p2 の問題は、musl、PAM なし、パスワード認証など、複数の条件がそろったときに限られます。

手元で見ておくものは次のとおりです。

- apt: インストールされている版が、bookworm は 2.6.2 以降、trixie は 3.0.4 以降かを確かめる。`apt-config dump Acquire::Retries` で再試行の設定を見る。HTTP のミラーを使っていないかも見る。Ubuntu 20.04 以前は Ubuntu Pro が要る
- OpenSSH: ビルドの条件（musl、PAM の有無）と、パスワード認証の設定、パスワード欄が `*` のアカウントの有無を確かめる。10.6p2 以降か、ディストリビューションの修正パッケージに上げる。更新後は sshd を再起動する
- Go: `go version` で版を確かめる。`encoding/json`（v1）の挙動は保たれる。`encoding/json/v2` に移すときは、重複キーや UTF-8 の検査、nil のスライスの出力が変わる点を、テストで確かめる
- Linux Mint: プレビュー段階の機能で、日程はまだ示されていない。出たら、Sleep Modes のページが示す問題（Secure Boot やスワップの不足など）を見る

## 参考リンク

- [DSA-6607-1（APT）](https://lists.debian.org/debian-security-announce/2026/msg00526.html)
- [NVD: CVE-2026-109518](https://nvd.nist.gov/vuln/detail/CVE-2026-109518)
- [Go ブログ: A new API for JSON](https://go.dev/blog/jsonv2)
- [Affinity の X の投稿](https://x.com/Affinity/status/2117276850795790442)
- [Linux Mint: Monthly News – October 2026](https://blog.linuxmint.com/?p=5093)
- [OpenSSH 10.6p2 のリリースノート](https://www.openssh.org/txt/release-10.6p2)
- [Alpine Linux の勧告](https://alpinelinux.org/posts/2026-11-05-openssh-password-authentication-bypass/)

（2026/11/06 Linux・OSSトレンド）
