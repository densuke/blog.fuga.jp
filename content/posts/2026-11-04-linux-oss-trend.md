---
title: "SMS of Death（CVE-2026-58882）は11月の Android Bulletin で Critical、CVE-2026-98432 は Ubuntu では 26.10 だけ配布済みで MPTCP で届くサーバーは約210万台、FreeRDP 3.33 は WebAssembly に対応、Arch の ISO は約323MB 縮小、KDE Linux は NTSYNC を既定に（2026/11/04 Linux・OSSトレンド）"
date: 2026-11-04T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Android", "Linux カーネル", "Ubuntu", "FreeRDP", "Arch Linux", "KDE", "AI"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

細工した8バイトのメッセージ1通で、受け取った電話の通話が切れる。動画の題になった CVE-2026-58882 について、研究者はそう書いています。送る側に要るのは相手の電話番号だけで、受ける側は端末の更新を待つことになります。CVE-2026-98432 と FreeRDP 3.33.0 にも、似た差が見えます。スキャンはインターネット全体へ一度に向けられますが、修正カーネルはディストリビューションごとに検証して配られます。FreeRDP の開発側は、プルリクエストと報告の流入を "huge" と書き、残りを修正リリースで片付けると予告しました。一方、Arch Linux の ISO の縮小と KDE Linux の NTSYNC の既定有効は、受け取る側の手間が減る話です。

送る側と受ける側の差という見立ては書き手のもので、一次情報が述べていることではありません。動画の発言のうち一次情報と合わなかったものは、各節の末尾に「動画の訂正」として書いています。

確認は2026年11月4日 7:50〜8:00（日本時間）です。配布状況や版のように変わりやすいものは、本文に確認の時刻を書きました。

{{< youtube "vzmIXYatLjo" >}}

## 1. CVE-2026-98432 — Ubuntu の修正カーネル、スキャンの報告、MPTCP で届く台数

この CVE の欠陥の仕組み、RHEL・Debian の修正、Go 1.24 と `go.mod`、`ss -H -lMn` は、[10月30日の記事](https://blog.fuga.jp/posts/2026-10-30-linux-oss-trend/)の第2節と[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)の第1節にあります。ここでは繰り返さず、その後に分かった3点を書きます。

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-98432) の記録は、確認時点（11月4日 7:52）も Received のままです。CVSS v3.1 の 9.8（Critical）は、kernel.org の CNA の採点（Secondary）で、NVD 自身の採点はありません。

### Ubuntu の修正カーネル

[Ubuntu の公式ブログ](https://ubuntu.com/blog/fixes-available-in-proposed-pocket-for-cve-2026-98432)（11月2日付）と [Launchpad の公開記録](https://api.launchpad.net/devel/ubuntu/+archive/primary/+sourcepub/18904673)によれば、確認時点（11月4日 7:52）の状況は次のとおりです。

- 22.04（5.15.0-203.213）、24.04（6.8.0-149.149）、26.04（7.0.0-43.43）: -proposed のままで、-updates への昇格はまだです
- 26.10（7.3.0-10.10）: UTC の10月28日 22:19（日本時間 10月29日 7:19）に -updates へ、UTC の11月2日 12:22（日本時間 21:22）に -security へ公開済みです。公式ブログの表も "Fixed in 7.3.0-10.10" です

[Ubuntu の CVE ページ](https://ubuntu.com/security/CVE-2026-98432)は、確認時点も 26.10 を "Vulnerable work in progress in 7.3.0-10.10" のままにしており、公開記録と食い違います。[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)は、この CVE ページに沿って 26.10 も未配布と書きましたが、公開記録では、その時点ですでに -updates に出ていました。

16.04・18.04・20.04 は、公式ブログの表で "Fix pending" です。Ubuntu は、20.04 以前は Ubuntu Pro で最大15年の保守が受けられ（16.04 は Legacy add-on も必要）、[Ubuntu Pro](https://ubuntu.com/pro) は個人利用なら5台まで無料と書いています。Canonical は、2,000台を超える認定サーバー・機器でのテストのあとに -updates へ出すとし、自前で受け入れテストを行う人は -proposed の修正を適用できる、と書いています。

### スキャンの報告

セキュリティ研究者の Marcus Hutchins 氏の [X の投稿](https://x.com/MalwareTechBlog/status/2117508092321747077)によれば、同氏のチームは、11月2日の時点で、複数のレジデンシャルプロキシと VPN が、MPTCP（Multipath TCP）を有効にした接続で、ポート443をインターネット全体に向けてスキャンしているのを検出しました。一般のスキャナーは既定で MPTCP を交渉しないこと、443番の HTTP サーバーにデータが送られていないことから、同氏は、CVE-2026-98432 を狙ったスキャンだと強く疑っています（"strongly suspect"）。送り元にレジデンシャルプロキシとロシアを拠点とする（"RU-based"）VPN サーバーが使われていることから、セキュリティ研究者ではなく攻撃者のスキャンの可能性が高い、とも書いています。

これはスキャンの観測で、侵入や被害の報告ではありません。AWS の[セキュリティ情報](https://aws.amazon.com/security/security-bulletins/2026-160-aws/)も、確認時点で、この問題が攻撃に使われた証拠はない、と書いています。同氏は、攻撃コードの作成は困難だと報告されているが、国家支援の攻撃者の中には成功に必要なリソースを持つ可能性が高い者がいる、とも書いています。

### MPTCP で届く台数

同じ投稿は、10月30日の予備スキャンで、MPTCP の接続でポート443に届くサーバーが約210万台（2,102,043）あったと書いています。TLS のネゴシエーションまで試すスキャンでは、約76万3000台（762,774）でした。同氏は、どちらも未修正のカーネルとは確認できず、露出している総数だと断っています。

### 暫定策と各社の配布

IP オプション付きの TCP パケットを落とす暫定策は、[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)の第1節に書きました。Ubuntu の CVE ページは、副作用として、IPv4 のオプションに依存する接続に影響が出る、と書いています。`net.mptcp.enabled=0` は、Hutchins 氏の投稿によれば既存のソケットには効かないのでアプリの再起動が要り、AWS は、これでは問題の解決にならない、と書いています。

11月2日の記事で一次を確認できなかった Oracle と Amazon の配布は、確かめられました。[Oracle UEK の ELSA-2026-500399](https://linux.oracle.com/errata/ELSA-2026-500399.html)（10月16日）と、[Amazon Linux 2023 の ALAS2023-2026-3365](https://alas.aws.amazon.com/AL2023/ALAS2023-2026-3365.html)（10月30日。この CVE を含む告知は、10月24日の ALAS2023-2026-3251 からあります）です。同じ記事で日付を確かめられなかった Debian 12 の告知は、[DLA-4841-1](https://www.debian.org/lts/security/2026/dla-4841)（10月17日）です。

CISA の KEV（悪用が確認された脆弱性のカタログ）は、確認時点（11月4日 7:52）の版（catalogVersion 2026.11.03）に、この CVE を載せていません。

動画の訂正です。

- 動画では、Hutchins 氏自身も、攻撃コードの開発は非常に困難だと言っている、と紹介しました。投稿は、困難だと「報告されている」（"is reported to be extremely difficult"）と書いており、同氏自身の評価ではありません（[投稿](https://x.com/MalwareTechBlog/status/2117508092321747077)）。
- 動画では、約48分なら現実的ではないという楽観論に対し、Hutchins 氏が、国家支援の攻撃者なら時間をかけられると反論した、と紹介しました。投稿に、48分への言及も、楽観論への反論という形もありません。書いているのは、国家支援の攻撃者の中には必要なリソースを持つ可能性が高い者がいる、という点だけです（[投稿](https://x.com/MalwareTechBlog/status/2117508092321747077)）。
- 動画では、Ubuntu は22.04・24.04・26.04・26.10向けの修正カーネルが -proposed に入った段階だ、と紹介しました。26.10 は、放送の前の10月28日（UTC）に -updates、11月2日（UTC）に -security へ公開済みでした（[Launchpad の公開記録](https://api.launchpad.net/devel/ubuntu/+archive/primary/+sourcepub/18904673)、[Ubuntu の公式ブログ](https://ubuntu.com/blog/fixes-available-in-proposed-pocket-for-cve-2026-98432)）。
- 動画では、IP オプションを落とす暫定策が、VPN や CDN の一部を壊すおそれがある、と紹介しました。VPN や CDN を挙げる一次は確認できませんでした。一次が書く副作用は、IPv4 のオプションに依存する接続への影響です（[Ubuntu の CVE ページ](https://ubuntu.com/security/CVE-2026-98432)）。

## 2. FreeRDP 3.33.0 — ブラウザで動く WebAssembly 対応、"huge" の流入、13件の修正

オープンソースの RDP クライアント FreeRDP の 3.33.0 は、11月2日（月）に公開されました（GitHub のリリースは UTC の 10:57、日本時間 19:57）。[告知](https://www.freerdp.com/2026/11/02/3_33_0-release)は、WebAssembly 対応（"webassembly support, now can run from within your browser"）を最初の機能に挙げています。

### WebAssembly 対応の中身

告知と、マージ済みの PR で確かめられたものは次のとおりです。

- 映像: WebCodecs による H.264 の[デコード](https://github.com/FreeRDP/FreeRDP/pull/13812)と、AV1 の[デコード](https://github.com/FreeRDP/FreeRDP/pull/13731)
- 音声: Web Audio による[再生（rdpsnd）](https://github.com/FreeRDP/FreeRDP/pull/13732)と[マイク入力（audin）](https://github.com/FreeRDP/FreeRDP/pull/13811)
- [クリップボード](https://github.com/FreeRDP/FreeRDP/pull/13733)（テキストと画像）
- [WebAssembly SIMD](https://github.com/FreeRDP/FreeRDP/pull/13893)（SSE 向けの処理を流用）
- [MessageChannel](https://github.com/FreeRDP/FreeRDP/pull/13864) でブラウザに制御を返す仕組み

ブラウザから RDP サーバーへつなぐ側については、ブラウザ版の [freerdp-web](https://github.com/congzhangzh/freerdp-web)（FreeRDP 本体とは別のリポジトリ）の README が、ブラウザは TCP 接続を開けないので、ページは WebSocket のゲートウェイ経由で RDP サーバーに話す、と書いています（インストールして使う Isolated Web App 版は直接 TCP を使います）。同じ README は、趣味のプロジェクトで、セキュリティの専門家が書いたものではなく、サーバーを安全に保つのは自己責任だ、とも書き、RDP をインターネットに出さないよう注意しています。

### "huge" の流入と、Phoronix の解釈

告知は、プルリクエストと不具合・リグレッションの報告の流入が "huge" で、積み残した細かい修正を含む修正リリースを近く出す、と書いています。告知にも GitHub のリリース本文にも、AI や LLM の語はありません。

[Phoronix](https://www.phoronix.com/news/FreeRDP-3.33) は、見出しで「AI による活動の大幅な流入」と書き、本文でも、AI/LLM の活動の大量流入の影響を受けた、と書いています。これは Phoronix の解釈で、FreeRDP の公式の記述ではなく、この記事も AI が原因だとは書きません。[GitHub のリリースノート](https://github.com/FreeRDP/FreeRDP/releases/tag/3.33.0)の新規コントリビューターは20名ですが、AI との関係を示す記述は、確認した範囲で見当たりません。

確認時点（11月4日 7:58）の最新版は、3.33.0 のままです。告知が予告した修正リリースは、まだ出ていません。

### そのほか

- 13件の GitHub Security Advisory が、告知の CVE 節に載っています。確認時点では各ページを取得できず、CVE 番号と内容は確かめていません
- 実験的な UDP 接続（RD ゲートウェイを介さない）、macOS の FUSE なしのファイルクリップボード

### Mesa の RADV の方針

[Phoronix](https://www.phoronix.com/news/RADV-Adopts-LLM-Policy)によれば、Mesa の RADV は、11月2日（現地時間）に LLM に関する独自の方針を取り込みました。引用された方針は、LLM の支援を受けたマージリクエストはコードベースへの十分な理解が要り、レビューには実際のコストがかかるので、メンテナーの裁量で閉じることがある、LLM が書いた Issue は冗長で読みにくいので勧められない、というものです。コードへの AI の関与の申告を（例外を除いて）必須とするのは、Mesa 全体の[投稿の方針](https://docs.mesa3d.org/submittingpatches.html)です。FreeRDP の側は、README・PR テンプレート・SECURITY.md・コミットメッセージの文書を確かめた範囲で、AI や LLM に触れた方針は見当たりません。

動画の訂正です。

- 動画では、ブラウザ側の制約として、WebSocket 経由の接続や WebTransport 対応サーバーとの組み合わせが必要になりそうだ、と紹介しました。WebTransport は確認できませんでした。freerdp-web が使うのは、WebSocket のゲートウェイです（[freerdp-web](https://github.com/congzhangzh/freerdp-web)）。
- 動画では、freerdp-web について、セキュリティ専門家のレビューが終わっておらず、本番投入は勧められていない、と紹介しました。README の文面は、趣味のプロジェクトで、セキュリティの専門家が書いたものではない、というものです。「レビュー未了」「本番投入は勧めない」という文面は、確認できませんでした（[freerdp-web の README](https://github.com/congzhangzh/freerdp-web)）。
- 動画では、RADV の方針を、AI が生成したコードは明示的に申告してもらうものだ、と紹介しました。RADV の方針は、申告の要求ではありません。申告を必須とするのは Mesa 全体の方針です（[Phoronix](https://www.phoronix.com/news/RADV-Adopts-LLM-Policy)、[Mesa の文書](https://docs.mesa3d.org/submittingpatches.html)）。

## 3. Arch Linux 2026.11.01 — ISO が約323MB 小さくなった理由

[Arch Linux の公式のリリースページ](https://archlinux.org/releng/releases/2026.11.01/)は、2026.11.01 の公開日を11月1日（日）、カーネル 7.2.11、ファイルサイズを 1.2 GB としています。10月版の[ページ](https://archlinux.org/releng/releases/2026.10.01/)は 1.5 GB です。[ミラー](https://geo.mirror.pkgbuild.com/iso/2026.11.01/)の実測（Content-Length）は、10月版が 1,640,497,152 バイト、11月版が 1,317,568,512 バイトで、差は約323MB（19.7%）です。10進の単位で書けば、1.64GB から 1.32GB です。

### 縮んだ理由

理由は、archiso 92 の変更として一次に書かれています。[CHANGELOG](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/CHANGELOG.rst)（2026-10-31）は、mkinitcpio の `kms` フックを外した（"Remove kms mkinitcpio hook"）と書いています。[マージリクエスト](https://gitlab.archlinux.org/archlinux/archiso/-/merge_requests/479)の作者は、インストールメディアに早期 KMS を入れる理由は見当たらず、特に NVIDIA の GSP ファームウェアのせいで initramfs が大きくなっていた、と書いています。ISO には、レガシー BIOS で起動するために initramfs の写しがもう1つ入るので、効果は2回分です。実測では、`arch/boot/x86_64/initramfs-linux.img` が、10月版の 249,467,488 バイトから、11月版の 86,549,384 バイトに縮んでいます。

11月版が archiso 92 で作られた、という点は推定です。archiso 92 の公開日（10月31日）と ISO の作成日（11月1日）、initramfs の実測から、そう読めます。

### ISO の中身とリポジトリの版

ISO の[パッケージ一覧](https://geo.mirror.pkgbuild.com/iso/2026.11.01/arch/pkglist.x86_64.txt)で確かめた版は、linux 7.2.11、systemd 262.1、btrfs-progs 7.3、xfsprogs 7.2.1、archinstall 4.5 です。10月版は、linux 7.2.7、systemd 262、btrfs-progs 7.1、xfsprogs 7.2.0 でした。Mesa と NVIDIA のドライバーは、一覧にありません。NVIDIA 関連は、ファームウェアの `linux-firmware-nvidia` だけです。

リポジトリの版は別です。確認時点（11月4日 7:52）の `linux` は 7.2.14.arch1-1（ビルドは10月30日）で、Out of Date の印が11月3日に付いています。kernel.org には 7.2.15（11月1日）と 7.3.1（10月30日）が出ています。[11月3日の記事](https://blog.fuga.jp/posts/2026-11-03-linux-oss-trend/)の第3節は、7.2 系は 7.2.15 が最後と書きました。Arch のリポジトリに、その版はまだ反映されていません。

動画の訂正です。

- 動画では、サイズが縮んだ理由を、はっきり確認できておらず、圧縮方式の見直しか不要なライブラリの除去あたりが主因と考えられる、と紹介しました。理由は、確認できていなかったのではなく、一次に書かれていました。archiso 92 の `kms` フックの除去です（[マージリクエスト](https://gitlab.archlinux.org/archlinux/archiso/-/merge_requests/479)）。
- 動画では、Mesa が 26.2.6（前月は 26.2.3）で、この ISO に入っている、と紹介しました。Mesa は ISO に入っていません。26.2.6 は、確認時点のリポジトリ（extra）の版です。前月の 26.2.3 は、出どころを確認できませんでした（[パッケージ一覧](https://geo.mirror.pkgbuild.com/iso/2026.11.01/arch/pkglist.x86_64.txt)、[Arch のパッケージ検索](https://archlinux.org/packages/extra/x86_64/mesa/)）。
- 動画では、systemd 262.1 を、262 からのリグレッション修正が主な内容で、sd-boot の更新の流れや unit ファイルの移行処理が直った版、と紹介しました。この中身の説明は、出典を確認できませんでした。262.1 の[リリース](https://github.com/systemd/systemd/releases/tag/v262.1)の本文は、変更履歴へのリンクだけです。
- 動画では、NVIDIA のプロプライエタリドライバーが 615.78.08 に上がった、と紹介しました。ISO に NVIDIA のドライバーは入っておらず、あるのはファームウェアだけです。615.78.08 は、リポジトリの `nvidia-open`・`nvidia-open-dkms` の版で、「上がった」という前の版の根拠は確認できませんでした（[パッケージ一覧](https://geo.mirror.pkgbuild.com/iso/2026.11.01/arch/pkglist.x86_64.txt)、[nvidia-open-dkms](https://archlinux.org/packages/extra/x86_64/nvidia-open-dkms/)）。
- 動画では、確認すべきパッケージを `nvidia-dkms` と紹介しました。Arch は2025年12月に、`nvidia-dkms` を `nvidia-open-dkms` に置き換えています。Pascal 以前の GPU 向けには、AUR の `nvidia-580xx-dkms` があります（[Arch のニュース](https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/)）。

## 4. KDE Linux — NTSYNC が既定に、S3 への移行、OpenQA の移設

KDE の[10月号](https://blogs.kde.org/2026/11/01/october-2026-in-kde-linux/)（11月1日付、Nate Graham 氏）は、KDE Linux は Beta のマイルストーンに向けて進んでおり、そこまでの85%に留まっている（"remains 85% of the way there"）と書いています。[9月号](https://blogs.kde.org/2026/10/01/this-month-in-kde-linux-september-2026/)も "remains 85%" で、10月の前進ではありません。KDE は、何の達成度かを定義していません。

### 10月号の新しい点

- NTSYNC: Tabitha Moon 氏が、ntsync カーネルモジュールを既定で有効にしました。Wine と Proton で遊ぶゲームの性能が上がる、と KDE は書いています。[Linuxiac](https://linuxiac.com/kde-linux-enables-ntsync-by-default-for-better-wine-and-proton-gaming/) によれば、これまでは利用者がモジュールを手動で設定する必要がありました。NTSYNC は、[7月30日の記事](https://blog.fuga.jp/posts/2026-07-30-linux-oss-trend/)の第3節（FreeBSD の実装）でも触れました
- S3 互換のストレージ: OS イメージの保管と更新の仕組みを、KDE の新しい S3 ベースのファイル保管サーバーへ移しています
- OpenQA: KDE Linux の OpenQA を、Harald Sitter 氏の個人サーバーから、KDE のインフラの専用サーバーへ移しています

KDE Linux の設計の説明は、[8月4日の記事](https://blog.fuga.jp/posts/2026-08-04-linux-oss-trend/)の第3節にあります。

ログインマネージャーの plasma-login-manager への切り替え（開発は主に David Edmundson 氏と Oliver Beard 氏）と、デルタ更新の有効化は、10月ではなく2026年2月の変更です（[2月6日の Nate Graham 氏のブログ](https://pointieststick.com/2026/02/06/busy-months-in-kde-linux/)）。

### 残りの作業と試す方法

Beta のマイルストーンの未完了の Issue には、swap の扱い（"Our swap situation isn't ideal"）、Discover での更新の改善、別の Linux ディストリビューションとのデュアルブートなどがあります（[KDE Linux の Issue](https://invent.kde.org/kde-linux/kde-linux/-/issues/552)）。KDE の月次記事が、残りの作業として挙げたものではありません。Beta の日付は、Linuxiac によれば、発表されていません。

KDE の[公式の文書](https://linux.kde.org/docs/install-vm/)に、仮想マシンへのインストールの手順があり、UEFI ファームウェアが必要です。手動のパーティション設定は、[Linuxiac](https://linuxiac.com/kde-linux-reaches-62-percentage-toward-beta-release/) が2月時点で壊れていると警告しており、10月時点の状態は確認できていません。

動画の訂正です。

- 動画では、Beta に向けた作業が85%まで進んだ、と紹介しました。10月号の文面は、85%に「留まっている」というもので、9月号と同じです。62% が2月の値である点は、放送のとおりです（[2月6日のブログ](https://pointieststick.com/2026/02/06/busy-months-in-kde-linux/)、[10月号](https://blogs.kde.org/2026/11/01/october-2026-in-kde-linux/)、[9月号](https://blogs.kde.org/2026/10/01/this-month-in-kde-linux-september-2026/)）。
- 動画では、ログインマネージャーが SDDM から Plasma ログインマネージャーに切り替わった、と10月の更新として紹介しました。切り替えは2026年2月です（[2月6日のブログ](https://pointieststick.com/2026/02/06/busy-months-in-kde-linux/)）。
- 動画では、デルタ更新が既定になり、約7GB だった更新が、今では1〜2GB 程度で済む、と紹介しました。既定になったのは2026年2月です。7GB から1〜2GB は、毎日更新する場合の見込みで、間隔が空くと差分は大きくなります（[2月6日のブログ](https://pointieststick.com/2026/02/06/busy-months-in-kde-linux/)）。
- 動画では、仮想マシンでの動作は今はサポート外で、Testing のイメージは実機の USB から試す形になる、と紹介しました。公式の文書に、仮想マシンへのインストール手順があります。UEFI が必須です（[KDE Linux のインストール（仮想マシン）](https://linux.kde.org/docs/install-vm/)）。

## 5. CVE-2026-58882（SMS of Death）— 8バイトのメッセージで通話が切れるという DoS

通称の「SMS of Death」は、研究者の Mark Blaszczyk 氏の呼び名です。研究者の解説サイトは、攻撃のコードと実証用のアプリへ直接誘導しているので、この記事ではリンクしません。攻撃を再現できる細部も書きません。

### 公式の記録

[CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-58882) の記録（CNA は Google の Android、UTC の11月2日 19:54＝日本時間 11月3日 4:54 に公開）の説明は、WapPushOverSms.java の decodeWapPdu に、整数オーバーフローによる範囲外読み取り（out of bounds read）があり、追加の権限なしにリモートからのサービス拒否（DoS）につながる、というものです。悪用に利用者の操作は要らない、とも書いています。

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-58882) は、確認時点（11月4日 7:54）で分析待ち（Awaiting Analysis）で、CVSS v3.1 などの採点はありません。CNA の Google も CVSS を載せていません。

[2026年11月の Android Security Bulletin](https://source.android.com/docs/security/bulletin/2026/2026-11-01)（11月2日公開）は、A-517376969、種類は DoS、深刻度は Critical、対象は Android 14・15・16・16-qpr2・17としています。2026-11-01 のパッチレベルに含まれます（Bulletin の全項目が直るのは 2026-11-05 以降）。深刻度は、緩和策が無効か、回避された場合の影響の評価です。[10月の Bulletin](https://source.android.com/docs/security/bulletin/2026/2026-10-01)に、この CVE はありません。

### 研究者の記述

次は、研究者の記述で、Google や第三者の検証は取れていません。CyberKendra も伝えています。

- 細工した8バイトのメッセージを送るだけで、受け取る側の操作は要りません。メッセージは SMS アプリに届かず、通知も出ません
- 進行中の通話が切れます。緊急通報も切れる、と研究者は書いています
- 不正なメッセージがキューに残り、起動のたびに再発することがあります。CyberKendra は、多数を短時間に受けた場合、と条件を添えています
- RescueParty が約90秒ごとに端末を復旧画面へ入れる、という報告は、研究者のサイトが、第三者（GitHub の貢献者）の Android 12 での報告として載せたものです

原因について、CVE の記述は整数オーバーフローによる範囲外読み取りです。研究者と、AOSP の[修正コミット](https://android.googlesource.com/platform/frameworks/opt/telephony/+/735d9672603fa206c4b43cb668c1aa273db70b97)（735d967、件名は "Fix remote DoS in decodeWapPdu (b/517376969)"）は、不正なメッセージの処理中に例外が起き、クラッシュのループが続く、という形で説明しています。

復旧の手順は、ここでは書きません。端末が再起動を繰り返す場合は、メーカーや通信事業者のサポートに相談してください。CyberKendra は、初期化でも、通信事業者が未配信のメッセージを再送すると、再発しうる、と書いています。

### 経緯

次の日付は、研究者のサイト、CyberKendra、AOSP のコミット、GrapheneOS の公開情報によります。

- 5月5日（火）: 研究者が Google の Android & Devices VRP に報告しました
- 6月15日（月、米国太平洋時間。日本時間では6月16日）: AOSP の修正コミットの author の日付です
- 6月20日: CyberKendra によれば、報告は "Won't Fix (Infeasible)" で終了しました
- 7月29日（水）: GrapheneOS の 2026072901（security preview release）が、「追加で修正した CVE」の Critical の欄に CVE-2026-58882 を載せています。通常版ではなく、プレビュー版です
- 8月5日（水、米国太平洋時間。日本時間では8月6日）: 公開されている AOSP のコミットの committer の日付です
- 10月29日（木）: CyberKendra によれば、Google が、深刻度のしきい値に達しない（"does not meet the severity threshold"）として報告を非セキュリティで終了し、研究者が詳細と実証コードを公開しました
- 11月2日（月、UTC）: CVE と11月の Bulletin の公開

GrapheneOS の[公式アカウントの投稿](https://grapheneos.social/@GrapheneOS/117525460785264691)は、Google は報告の扱いを誤った、内部の連絡ミスの可能性が高い、という趣旨を述べています。GrapheneOS の対象機種は、[releases ページ](https://grapheneos.org/releases)によれば Pixel 6 以降です。

### 対象の版

公式の対象は、14・15・16・16-qpr2・17です。研究者は、Android 12 から 16 で再現した、と書いています（12 は第三者の報告）。12 と 13 は、同じコードがあるが修正は届かない、というのも研究者の記述です。Bulletin の対象に 12・13 はありませんが、Google 自身が出さないと明言した文書は、確認できていません。

研究者のサイトは、14〜17 は10月の更新で直ったと書いています。一次の Bulletin では、この CVE は11月（2026-11-01 のパッチレベル）です。

動画の訂正です。

- 動画では、復旧の手順として、ADB で電話サービスのデータを消去するコマンドを実行する、と紹介しました。このコマンドは、確認できた復旧手順に載っていません。また、ADB は USB デバッグが有効なことが前提です（[Android の ADB の文書](https://developer.android.com/tools/adb)）。
- 動画では、最終手段として初期化も選択肢になる、と紹介しました。初期化でも、通信事業者が未配信のメッセージを再送すると、再発しうる、と CyberKendra は書いています。
- 動画では、研究者が、開示の期限が来て、10月29日に再現コードを公開した、と紹介しました。CyberKendra の報道によれば、研究者は、90日の開示期限を過ぎても詳細を保留しており、10月29日に Google が報告を非セキュリティとして終了したあとに公開しました。
- 動画では、Google は方針を変えて修正した、6月15日に修正コードを作り、8月5日に内部のブランチへコミットした、と紹介しました。修正コードの作成（6月15日）は、Won't Fix（6月20日）より前です。CyberKendra によれば、10月29日の最終判断も非セキュリティです。「内部のブランチ」は確認できませんでした。8月5日は、公開されているコミットの committer の日付です（[AOSP のコミット](https://android.googlesource.com/platform/frameworks/opt/telephony/+/735d9672603fa206c4b43cb668c1aa273db70b97)）。

## まとめ

CVE-2026-58882 は、11月の Bulletin で Critical の DoS です。通話が切れるといった被害の詳細は研究者の記述で、Google や第三者の検証は取れていません。CVE-2026-98432 は、Ubuntu では 26.10 が公開済みで、22.04・24.04・26.04 は確認時点も -proposed です。Hutchins 氏は、MPTCP を使うスキャンを観測したと報告しています。FreeRDP 3.33.0 は WebAssembly に対応し、修正リリースの予告があります。Arch の ISO の縮小は `kms` フックの除去で説明でき、KDE Linux の10月号の新しい点は、NTSYNC の既定有効、S3 への移行、OpenQA の移設です。

メッセージやスキャンを送る手間に比べて、受ける側の検証と更新は重い。5本を読んで、書き手はそう受け取りました。ただ、Arch と KDE Linux のように、受け取る側の手間を減らす変更もあります。

手元で見ておくものは次のとおりです。

- Linux カーネル: `uname -r` で版を確かめ、各ディストリビューションの告知と照合する。Ubuntu は、確認時点で 26.10 だけが公開済み。MPTCP の待ち受けは、`ss -H -lMn` で見られる
- FreeRDP: 使っている版を確かめる。確認時点の最新は 3.33.0 で、修正リリースは未公開
- Android: セキュリティパッチレベルが、11月の Bulletin の 2026-11-01 以降（Bulletin の全項目が直るのは 2026-11-05 以降）かを確かめる。12・13 は Bulletin の対象外
- Arch: NVIDIA のドライバーを DKMS で使うなら、パッケージは `nvidia-open-dkms`

## 参考リンク

- [Android Security Bulletin 2026年11月](https://source.android.com/docs/security/bulletin/2026/2026-11-01)
- [AOSP の修正コミット](https://android.googlesource.com/platform/frameworks/opt/telephony/+/735d9672603fa206c4b43cb668c1aa273db70b97)
- [Ubuntu: CVE-2026-98432 の修正カーネル（公式ブログ）](https://ubuntu.com/blog/fixes-available-in-proposed-pocket-for-cve-2026-98432)
- [Hutchins 氏の X の投稿](https://x.com/MalwareTechBlog/status/2117508092321747077)
- [FreeRDP 3.33.0 の告知](https://www.freerdp.com/2026/11/02/3_33_0-release)
- [Arch Linux 2026.11.01 のリリースページ](https://archlinux.org/releng/releases/2026.11.01/)
- [KDE Linux: 2026年10月号](https://blogs.kde.org/2026/11/01/october-2026-in-kde-linux/)

（2026/11/04 Linux・OSSトレンド）
