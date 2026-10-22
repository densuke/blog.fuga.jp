---
title: "PHP2Shell の緊急修正とサポート切れ系列への最小限のバックポート、Linux 7.4 に向けて送られた AMD の HDMI 2.1 標準有効化、Podman Desktop の Kubernetes 拡張、eMudhra の秘密鍵「4」、Plex2Shell の KEV 入り（2026/10/22 Linux・OSSトレンド）"
date: 2026-10-22T00:00:00+09:00
draft: false
tags: ["セキュリティ", "PHP", "CVE", "Linux カーネル", "Linux 7.4", "AMD", "Podman", "Kubernetes", "PKI", "Plex", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

修正が「出た」ことと、自分の手元に「届いた」ことは別です。今回の5本は、その距離を測る話として読めます。PHP のコアには10月21日に緊急の修正版が出ましたが、サポートが切れた系列には扱いが分かれます。AMD の HDMI 2.1 は、Linux 7.4 に向けて標準有効化のコードが動いています。eMudhra の中間 CA 証明書は、ブラウザでは10月17日にブロックされましたが、ブラウザ以外のプログラムは更新が必要です。Plex の修正版は8月に出ていたのに、10月に攻撃コードが出回りました。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "u6iFXB_0Wgs" >}}

## 1. PHP2Shell — CVE-2026-109618 と CVE-2026-109619 の緊急修正

PHP のコアで、認証なしで遠隔からコードを実行できる脆弱性が2件見つかりました。[GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w) が CVE-2026-109618、[GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp) が CVE-2026-109619 です。Tenable の FAQ によれば、攻撃の実演動画は php2shell と呼ばれています。

### 2件の中身

- CVE-2026-109618 の題名は "RCE via OOM corruption" です。GHSA によれば、PHP はメモリ不足の際に longjmp() で処理を打ち切ります。リクエスト用のメモリが初期化の途中で到達可能な状態にあるとき、その途中で確保に失敗すると、PHP は早期終了を正しく扱わず、メモリが不正な状態のまま残ります
- CVE-2026-109619 の題名は "RCE via stale global state" です。ワーカーが保持するグローバル状態が、前のリクエストのメモリを指したまま残り、次のリクエストが初期化の前にそれを参照すると Use-After-Free になります。成立には、状態を作るリクエストと、それを使うリクエストの両方が、同じワーカーに届く必要があります
- 確認された影響は、GHSA によれば、Web ワーカーのアカウント権限での、認証なしの遠隔コード実行です。GHSA-w8hw-w9fx-j79w は、mod_php に対して HTTP 越しに完全なコード実行を確認したと書いています

CVSS v4.0 は、2件とも 9.2 です。ベクトルは `CVSS:4.0/AV:N/AC:H/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N` で、ネットワーク越し、認証不要、ただし攻撃の難しさは高めという内容です。NVD の登録は10月21日 14:17 UTC で、値は PHP 側が提供したものです。

### 公開までの経緯

Huntress のブログによれば、10月20日の朝に Hacker News へ、公開前の2件の脆弱性についての投稿があり、削除されたものの画面の写しが出回りました。同じブログは、watchTowr が "we were all supposed to wait until Thursday at 11am ET" と書いたと伝えています。この木曜日は10月22日で、ET 11:00 は日本時間の10月23日 0:00 にあたります。Tenable は、PHP Foundation の話として、リリースは当初10月22日の予定で、CVE 番号が漏れたため1日前倒しになったと書いています。

予告は、PHP Foundation が10月20日（米国時間）に出した「10月21日 14:00 UTC」で、日本時間では23:00です。実際の GHSA の公開は13:34 UTC（日本時間 22:34）で、php.net の告知の日付は10月21日です。

Tenable が引いた Cloudflare の CTO、Dane Knecht 氏の10月21日の投稿は、"We are seeing early attacks emerging" と書いています。一方 Huntress は、同日の米国東部時間16:30の時点で、自社のパートナー環境では悪用を観測していないと発表しています。観測者によって見えている範囲が違うため、攻撃の時期はここでは断定しません。

### 修正版と、サポート切れの系列

修正版は、8.2.35、8.3.36、8.4.27、8.5.12 の4つです。php.net の告知は、[8.1 以下はもう PHP プロジェクトから更新を受けられない](https://www.php.net/archive/2026.php)と書いています。ただし深刻度を踏まえ、PHP セキュリティチームは 7.4、8.0、8.1 向けに、ソースからビルドする人のための最小限のバックポートを提供しました。Tenable は、5.4 から 7.3 までは寿命が切れており、PHP プロジェクトからの修正はないと整理しています。

つまり、8.1 以下には、パッケージで入れられる公式の修正版は出ていません。7.4、8.0、8.1 には、ソースビルド向けのバックポートがあります。5系と 7.3 以前には、修正が出ていません。

台数の話があります。phoenix.security は、ある Shodan ベースの調査を引いて、PHP の X-Powered-By ヘッダを出しているホスト約223万台のうち、バージョンが分かる約150万台では、883,717台が修正の出ない系列、うち5系と7系だけで 697,928台だと書いています。この数字は単一の出典で、同社自身が参考値と注記しています。バックポートが出た 7.4 から 8.1 を含み、バージョンを隠しているホストは含みません。修正が当たらない台数ではありません。

### 対策

- php.net は、完全な緩和策はなく、更新だけが安全な選択だと書いています。設定の変更に頼らず、更新を優先します
- 8.2 以上は、ディストリビューションの提供状況を確かめて更新します。php.net によれば、ディストリビューションと LTS ベンダーには事前にパッチが渡されています。8.2 のセキュリティサポートは、php.net の一覧で2026年12月31日までです
- ボランティア運営の rpms.remirepo.net を使っている場合、php.net は、ディストリビューションのパッケージかソースビルドへの切り替えを勧めています。同リポジトリには、告知の時点で更新がありませんでした
- 7.4、8.0、8.1 は、ソースからビルドしているなら、公式のバックポートが選択肢になります。パッケージで使っているなら、ディストリビューションや LTS ベンダーの提供状況を確かめます
- すぐに更新できない場合、Tenable によれば CERT-EU は、修正を適用して確認するまで、インターネットに面したアプリケーションを公開ネットワークから隔離することを勧めています。WAF は、Cloudflare 自身が "STOPGAP only" と書いたように、暫定策にとどまります
- 共有レンタルサーバーやコントロールパネルに同梱された PHP、ベンダーのアプライアンスに同梱された PHP は、見落としやすい場所です。Huntress は、php.exe や php-cgi.exe を同梱するベンダーのソフトウェアやコントロールパネルを、棚卸しの対象に挙げています。事業者の対応状況の案内を確認します
- 自分のサーバーの版は `php -v` で確かめます

動画の訂正です。

- 動画では、8.1 や 8.0、7系、5系といったサポートが終わった系列には「公式のパッチが出ません」と紹介しましたが、PHP セキュリティチームは、7.4、8.0、8.1 向けに、ソースからビルドする人のための最小限のバックポートを提供しました。8.1 以下には通常の修正版は出ませんが、5系と 7.3 以前には修正が出ていません（[php.net の告知](https://www.php.net/archive/2026.php)）。

## 2. Linux 7.4 に向けて送られた、AMDGPU の HDMI 2.1 標準有効化

AMD のオープンソースドライバ AMDGPU の HDMI 2.1 対応を、標準で有効にする変更です。7.3 は10月18日（米国時間）にリリースされ、7.4 のマージウィンドウが開いています。マージウィンドウの動きは[10月20日の記事](https://blog.fuga.jp/posts/2026-10-20-linux-oss-trend/)にもあります。

### 取り込みの状況

[Phoronix の9月11日付の記事](https://www.phoronix.com/news/Linux-7.4-AMDGPU-HDMI-2.1-Go)は、HDMI 2.1 の FreeSync、ALLM、VRR を含む AMDGPU の機能の pull request が、Linux 7.4 向けに DRM-Next へ送られ、あわせて HDMI の FRL を標準で有効にする、と書いています。つまり、Linux 7.4 に向けて DRM の開発ツリー（drm-next）へ送られており、7.4 で標準有効になる見込みです。

10月21日 20:45 UTC 時点の torvalds/linux の master では、まだ変わっていません。ドライバのコードには、FRL を使うための定義 `DC_FRL_MASK` が `(0x400) disabled by default` のまま残っています。Linus Torvalds 氏宛ての pull request は、一次では確認できていません。

### ここまでの経緯

- HDMI Forum は、AMD の提案を断りました。Phoronix の2024年2月28日付の記事が引く AMD の Alex Deucher 氏の説明では、HDMI Forum の要件に反せずにオープンソースの HDMI 2.1 を実装することは、そのときは不可能でした
- Phoronix によれば、2026年のはじめに何かが変わり、広く推測されているのは Valve の関与で、AMDGPU に HDMI 2.1 のパッチが現れ始めました。確定した事実としては書きません
- 2026年2月には、個人の開発者が書いた実験的なコードが、GamingOnLinux の記事で紹介されています。5月には、AMD が FRL のパッチを投稿しました
- FRL は Linux 7.2 で入りましたが、標準では無効でした。Phoronix は、可変リフレッシュレート（VRR）の機能が揃うまで、ユーザー体験を損ねないためだったと書いています。7.2 の頃の話は[7月1日の記事](https://blog.fuga.jp/posts/2026-07-01-npm-v12-git-rust-linux72-strncpy/)にあります
- VRR と ALLM のパッチは、7.3 のマージウィンドウに間に合わず、7.4 へ持ち越されました

### 何が使えるようになるのか

HDMI 2.1 の最大帯域は、hdmi.org によれば 48Gbps です。今回の機能は3つです。

- VRR は、hdmi.org によれば、ゲームの遅れ、カクつき、ティアリングを減らします
- ALLM は、hdmi.org によれば、最適な遅延の設定を自動で選びます
- FreeSync は、Phoronix によれば、HDMI 2.1 の FreeSync 対応として同じ pull request に含まれます

対象は、HDMI 2.1 端子を持つ Radeon と、HDMI 2.1 対応のテレビやモニターの組み合わせです。DisplayPort 接続や NVIDIA の GPU は、AMDGPU の HDMI 2.1 の変更の対象ではありません。

### いつ手元に届くか

Phoronix の10月18日付の見どころ記事は、7.4 の安定版が12月の終わりごろに出るはずだと書いています。9月11日付の記事は、年末にぎりぎり間に合うか、1月の初めになる可能性にも触れています。どのディストリビューションにいつ入るかは、各ディストリビューションの案内で確かめます。

動画の訂正です。

- 動画では、FreeSync は「これまでは DisplayPort でつないだときにしか使えなかった」、今回「HDMI 接続でも利用可能に」なると紹介しましたが、AMD は、FreeSync は登場当初から HDMI に対応していたと書いています。Linux の amdgpu にも、HDMI 経由の FreeSync 対応（コミット "Add Freesync HDMI support to DM"）が以前から入っています。7.4 に向けて送られているのは、HDMI 2.1 規格の VRR（HDMI Forum が定めた方式）と ALLM などの対応です（[AMD の FreeSync のページ](https://www.amd.com/en/products/graphics/technologies/freesync.html)）。
- 動画では、AMD は2021年の時点で、すでにオープンソースの実装を作っていたと紹介しましたが、2021年の時点で実装があったことを示す資料は確認できませんでした。確認できたのは、AMD が HDMI 2.1 対応のオープンソース実装を開発し、2023年2月から法務部門と確認を進めていたことです（[ComputerBase](https://www.computerbase.de/2024-03/keine-freigabe-amds-open-source-kampf-fuer-hdmi-2-1-unter-linux-ist-verloren/)）。2021年は、HDMI Forum が仕様の一般公開をやめたことが報じられた年です（[Phoronix](https://www.phoronix.com/news/HDMI-2.1-OSS-Rejected)）。

## 3. Podman Desktop の Kubernetes Extension Pack と、本体の Kubernetes 機能の行方

Podman Desktop は、公式ブログで10月20日に、[Kubernetes Extension Pack のリリース](https://podman-desktop.io/blog/podman-desktop-kubernetes-extension-pack-release-2026-10)を公表しました。中身は Kubernetes Dashboard v0.6.0、Kubernetes Contexts v0.3.0、Kreate v0.4.0 の3つです。GitHub のタグは、いずれも9月付けです。

### 本体の機能はどうなるか

公式ブログは、Kubernetes のダッシュボードとコンテキストの管理を、本体から拡張へ移していると書いています。本体の機能について、原文は "will not evolve and will be removed in a future release" です。新しい機能は加わらず、将来のリリースで削除される予定です。版や時期は書かれていません。

Dashboard か Contexts の拡張を入れると、対応する本体の機能が無効になります。拡張を外したときに本体の機能がどうなるかは、公式ブログには書かれていません。

### Dashboard v0.6.0 で増えたもの

- YAML の適用ページです。ブログによれば、ディスクの .yaml ファイルを選ぶか、エディタで書いて適用します。既存のリソースが標準の Kubernetes API のものなら、strategic merge patch で更新されます。この方式は CustomResourceDefinition の API では使えないため、既存のカスタムリソースは更新されません
- Deployment のレプリカ数の変更と、停止したコンテナのログの参照です
- DaemonSet、StatefulSet、ReplicaSet などの表示です
- 監視の遅延ロードです。Pod、Deployment、Service などは接続時から監視し、それ以外の種類は、そのページを開いたときに監視を始めます
- 公開の Extension API です。他の拡張が、Dashboard の既存の監視から、リソースの情報、コンテキストの状態、権限を購読できます。利用には npm パッケージ `@podman-desktop/kubernetes-dashboard-extension-api` が必要です

Kreate は、ブログによれば、クラスターが Discovery API で公開しているリソースの種類を、導入済みのオペレーターのカスタムリソースも含めて選べます。要件は、Dashboard 拡張とパックについて、Podman Desktop 1.26.0 以上と、有効な kubeconfig です。

### 自分の環境の確認

本体の Kubernetes 機能を前提にした手順書やスクリプトがあれば、今のうちに洗い出します。削除の時期は未発表ですが、新しい機能は拡張にしか入りません。

動画の訂正です。

- 動画では、Contexts も Kreate も、公開 API を使って Dashboard の監視の仕組みを再利用していると紹介しましたが、公式ブログが Dashboard の API で監視を再利用していると書いているのは Contexts です。Kreate については、クラスターの Discovery API を使ってリソースの種類を取得すると説明されており、公開されている Kreate v0.4.0 のコードにも、Dashboard の拡張 API への依存は見当たりませんでした（[公式ブログ](https://podman-desktop.io/blog/podman-desktop-kubernetes-extension-pack-release-2026-10)、[Kreate のリポジトリ](https://github.com/podman-desktop/extension-kreate)）。

## 4. eMudhra の中間 CA 証明書8件の秘密鍵

インドの認証局 eMudhra が発行した中間 CA 証明書8件の秘密鍵が、公開鍵から復元できる弱いものでした。Mozilla の [Bugzilla #2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449) で扱われています。復元されたのは、鍵が公開されたからではなく、鍵そのものが小さな整数だったからです。

### 何が起きていたか

- Bugzilla の Comment 5 で Dennis Jackson 氏は、影響を受けた8件の鍵はすべて 256 未満の整数を使っていたと書いています。鍵は、最後の1バイトを除いてゼロです
- Scott Helme 氏のブログは、8件のうち1件の鍵は、数字の「4」そのものだったと書いています
- 鍵は P-384 の楕円曲線のものです。公開鍵は、秘密鍵の整数に基準点を掛けて作るので、4 のような小さい値でも、計算の上では有効な鍵になります
- Helme 氏は、自分のノート PC で、公開鍵から8件すべてを1秒未満で復元したと書いています。Frank Chu 氏の dev.to の記事は、最も遅かった鍵でも11ミリ秒だったと書いています
- Bugzilla によれば、用途は、TLS 用の中間 CA が6件、コード署名用が2件です。コード署名用は、Microsoft だけが信頼していました
- 原因について、Bugzilla の Comment 5 は、8件の鍵が2025年4月30日に作られた24件の中間 CA の一部だと書いています。eMudhra の Comment 11 は、RSA 方式の発行 CA は別の経路を通ったため影響を受けないと評価しています

### ブラウザの対応

Bugzilla によれば、Mozilla が最初の報告を受けたのは10月17日 20:06 UTC で、OneCRL による失効は22:59 UTC に完了しました。BleepingComputer によれば、Chrome も同じ日に、TLS 用の6件をブロックしました。Apple は10月19日に保護を加えました。ここでの日付は UTC で、日本時間では10月18日の朝にあたる時刻を含みます。

Chrome Root Program は Bugzilla のコメントで、emSign ECC Root CA – G3 の削除を、米国太平洋時間の10月27日の朝に Stable へ入れる見込みだと書いています。

### ブラウザ以外のプログラム

ブラウザは10月17日に動きましたが、サーバーの中のプログラムは、更新するまで古い信頼の一覧を持ち続けます。BleepingComputer の修正版の一覧と、各プロジェクトの案内から整理します。

- Go は、1.27.3 と 1.26.10（どちらも2026年10月19日リリース）以降へ更新します。リリースノートには crypto/x509 のセキュリティ修正とあり、eMudhra の名前はありません。対応であることは BleepingComputer と The Register で確認しました
- Python の certifi は、2026.10.19 以降へ更新します。PyPI では、2026.10.19 は10月20日に公開されました
- Linux の ca-certificates は、ディストリビューションの更新を適用します。版はディストリビューションごとに違います
- Rust の webpki-roots は、1.0.10 以降です
- 手元の版は、`go version` と `python3 -m pip show certifi` で確かめます

Bugzilla の Comment 19 によれば、移行が必要な証明書は約3万件で、約97%は ACME 経由で発行されたものです。ACME なら自動更新で移行しやすいと考えられますが、書き手の見方です。

動画の訂正です。

- 動画では、certifi の「2026.10.19以前」が問題の証明書を信頼したままで、要更新だと紹介しましたが、2026.10.19 は対応を含む版です。2026.10.19 以降に更新します。2026.10.19 は PyPI で10月20日に公開されました（[BleepingComputer](https://www.bleepingcomputer.com/news/security/mozilla-google-apple-block-compromised-emudhra-ca-certificates/)、[PyPI の履歴](https://pypi.org/project/certifi/#history)）。

## 5. Plex2Shell — 修正版は8月に出ていた、KEV 入りは10月20日

Plex Media Server の4件の脆弱性をつなげる攻撃が、Plex2Shell と呼ばれています。研究者の GitHub ハンドルは code-zm で、[技術解説](https://zmain.info/blog/plex2shell)は10月16日付の投稿です。[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/10/20/cisa-adds-six-known-exploited-vulnerabilities-catalog)によれば、10月20日の KEV カタログへの追加は6件で、そのうち4件が Plex Media Server の次の脆弱性です。

- CVE-2026-96652 は SSRF です
- CVE-2026-96654 は、Web ページ内のエンコードされた URI スキームの不適切な無害化です
- CVE-2026-96655 は SSRF です
- CVE-2026-96656 は、ファイル名またはパスの外部制御です

### 深刻度

NVD の値は、版ごとに違います。CVSS v4.0 / v3.1 の順で、CVE-2026-96652 は 5.3 / 4.3、CVE-2026-96654 は 6.9 / 6.5、CVE-2026-96655 は 5.3 / 4.3、CVE-2026-96656 は 8.6 / 7.2 です。個別の最高は、CVSS v4.0 で 8.6（[CVE-2026-96656](https://nvd.nist.gov/vuln/detail/CVE-2026-96656)）です。NVD の公開は4件とも2026年9月23日です。

### 修正版はいつ出ていたか

研究者の README は、<= 1.43.3.10828 が対象で、1.43.3.10861 で修正されたと書いています。Plex のフォーラムでは、1.43.3.10861 は、[8月3日に Plex Pass 向けのベータとして](https://forums.plex.tv/t/plex-media-server/30447/712)公開され、[全員向けの公開は8月4日（UTC）](https://forums.plex.tv/t/plex-media-server/30447/713)でした。8月4日は、Gizmodo によれば、Plex が報告を受け入れて報奨金を払った日でもあります。

ベータのリリースノートには "(Security)" の項目が2つありました。CompanionProxy の脆弱性の可能性への対処と、トランスコーダー関連の設定がネットワーク越しに変更できなくなったことです。9月1日に Plex は、いくつかのセキュリティ問題に対処した 1.43.3 を公開したとして、サーバーの管理者に更新を呼びかけました。個別の CVE や攻撃の方法は、その時点では伏せられていました。

### 攻撃の流れ

code-zm の解説と NVD の記述から整理します。CVE 番号と段の対応は、一次の間で食い違うため、結び付けません。

1. 入口では、任意の値の認証トークンを付けて、Plex サーバーに攻撃者の選んだ宛先へ通信させられます
2. その仕組みで、サーバーの持ち主の管理用トークンを盗みます
3. トランスコーダーの設定を使い、コーデックのフォルダに悪意あるファイルを書き込みます
4. コーデックのフォルダのファイルは、トランスコーダーの起動時に、署名などの確認なしに読み込まれます。code-zm の解説によれば、2回目のトランスコードを起こして実行します

研究者の解説は10月16日付で、Plex の告知も、攻撃コードの公開を10月16日としています。boredhackerblog は、10月17日の朝に実際の攻撃を観測したと書いています。公開日の細部は、資料の間で揃っていません。

### 乗っ取られたサーバーで起きたこと

Plex の告知は、侵害されたサーバーで、暗号通貨のマイナーと、他人の通信を被害者の回線経由で中継するプロキシのソフトウェアが動いていたと書いています。boredhackerblog は、XMRig ベースのマイナーと、myawesomeproxy というプロセスを観測しました。Gizmodo は、攻撃者が機器を住宅プロキシにしていたと書いています。住宅プロキシの用途について、boredhackerblog は、企業の VPN やメールに入るための踏み台にされるだろうという見立てを書いています。

台数は、日付を分けて読みます。Shadowserver は2026年9月4日から、1.43.2 以前の更新されていない Plex を毎日報告しており、BleepingComputer の9月9日の記事は、3万6000台超が更新されていないと伝えました。Gizmodo は10月19日の記事で、Shadowserver のデータにある、10月17日の時点で約4万9000台が、まだ公開されていると伝えています。

### 確認と対策

- Plex は、1.43.3.10861 より古く、インターネットから到達できるサーバーは、侵害されている可能性を前提にするよう書いています
- Plex の告知が挙げる確認項目は、proxystream.st への外向きの通信や、再生していないのに続く高い CPU 使用、myawesomeproxy、mylovelyminer、x12345 といった見覚えのないプロセス、Codecs フォルダの見覚えのない .so や .dll です
- 疑わしい場合、Plex は、古いデータのフォルダを使い回さず、クリーンな再インストールで作り直すよう書いています。最低限、Codecs フォルダの中身を消し、Preferences.xml に自分で設定していないトランスコーダーのオプションがないかを確かめます
- リモートアクセスが要らなければ、Settings → Remote Access で切ります。32400番ポートの直接のポート転送は、必要でなければ避けます
- NAS では、パッケージマネージャーの更新が遅れることがあります。Plex は、手動でパッケージを入れられると案内しています

動画の訂正です。

- 動画では、修正版 1.43.3.10861 は「8月3日に出ていた」と紹介しましたが、8月3日は Plex Pass 向けのベータの公開日で、全員向けの一般公開は8月4日（UTC）です。2か月以上前に直っていたこと自体は、動画のとおりです（[ベータの告知](https://forums.plex.tv/t/plex-media-server/30447/712)、[一般公開の告知](https://forums.plex.tv/t/plex-media-server/30447/713)）。
- 動画では、Plex は起動のたびに、そのフォルダのファイルを署名も確かめずに読み込み、再起動したときに仕込まれたファイルが実行されると紹介しましたが、署名を確かめずに読み込む点は動画のとおりです。誤りは「再起動」の部分で、code-zm の技術解説によれば、読み込まれるのはトランスコーダーの起動時、つまり次に動画の変換が行われるときで、サーバーの再起動は要りません。Gizmodo も、次に Plex が動画をトランスコードするときに実行されると書いています（[code-zm の技術解説](https://zmain.info/blog/plex2shell)、[Gizmodo](https://gizmodo.com/your-plex-server-could-be-mining-crypto-for-hackers-if-you-havent-updated-it-2000827461)）。
- 動画では、Plex には更新を強制する仕組みがないと紹介しましたが、言い切りは正確ではありませんでした。Plex は2025年9月、別の脆弱性で、影響する版を動かしているサーバーに共有ユーザーが接続できないようにする措置を取りました。利用規約にも、更新を求めることができ、断るとアクセスが止まりうる旨の定めがあると Gizmodo は書いています。Windows と macOS 版には自動更新の設定があります。Gizmodo によれば、今回の Plex2Shell では、10月19日の時点でこうした措置は取られていません（[2025年の Plex の投稿](https://forums.plex.tv/t/plex-media-server-security-update/928341)、[Gizmodo](https://gizmodo.com/your-plex-server-could-be-mining-crypto-for-hackers-if-you-havent-updated-it-2000827461)）。

## まとめ

PHP は、2件の緊急の修正版が出ました。8.2 以上は修正版へ更新し、8.1 以下はソースビルドなら公式のバックポート、パッケージならベンダーの提供状況を確かめます。AMD の HDMI 2.1 は、Linux 7.4 に向けて drm-next へ送られており、7.4 の安定版は年末から年始の見込みです。Podman Desktop の本体の Kubernetes 機能は、新しい機能が加わらず、将来のリリースで削除される予定です。eMudhra の8件の鍵は、ブラウザでは10月17日（UTC）にブロックされましたが、Go、certifi、ca-certificates、webpki-roots などの更新が要ります。Plex の修正版は8月に出ていましたが、全員が当てていたわけではありません。

この共通点は書き手の考察です。確かめることを挙げます。

- `php -v` で版を見て、サポート中の系列の修正版か、8.1 以下ならバックポートかベンダーの対応かを確かめる
- HDMI 2.1 のテレビで AMD の GPU を使うなら、使っているディストリビューションのカーネルが 7.4 になるまで待つ
- Podman Desktop の本体の Kubernetes 機能を前提にした手順があれば、Dashboard か Contexts の拡張での代替を試す
- Go、Python の certifi、ca-certificates、webpki-roots を使うプログラムは、版を確かめて更新する
- Plex Media Server は 1.43.3.10861 以降に更新し、古い版でインターネットに公開していた場合は、Codecs フォルダと不審なプロセスを確かめる

## 参考リンク

- [GHSA-w8hw-w9fx-j79w（CVE-2026-109618）](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)
- [GHSA-6wmf-4rv5-p3rp（CVE-2026-109619）](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)
- [php.net のセキュリティ告知（2026年10月21日）](https://www.php.net/archive/2026.php)
- [Phoronix の Linux 7.4 の AMDGPU HDMI 2.1 の記事](https://www.phoronix.com/news/Linux-7.4-AMDGPU-HDMI-2.1-Go)
- [Podman Desktop の Kubernetes Extension Pack の公式ブログ](https://podman-desktop.io/blog/podman-desktop-kubernetes-extension-pack-release-2026-10)
- [Mozilla Bugzilla #2083449（eMudhra）](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)
- [BleepingComputer の eMudhra の記事](https://www.bleepingcomputer.com/news/security/mozilla-google-apple-block-compromised-emudhra-ca-certificates/)
- [CISA の KEV 追加アラート（2026年10月20日）](https://www.cisa.gov/news-events/alerts/2026/10/20/cisa-adds-six-known-exploited-vulnerabilities-catalog)
- [code-zm の Plex2Shell の技術解説](https://zmain.info/blog/plex2shell)
- [Plex の更新の告知（1.43.3.10861 の一般公開）](https://forums.plex.tv/t/plex-media-server/30447/713)

（2026/10/22 Linux・OSSトレンド）
