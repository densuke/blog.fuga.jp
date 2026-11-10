---
title: "SonicWall の CVE-2026-19868 は SAML 方式の MFA も迂回しうる、Linux 7.4-rc2 の FAT32「162倍」は作者が QEMU/KVM 上で測った値、BenchUp は旧 KetchUp の Rust 製木工3Dモデラー、Node.js は 27 から年1回・すべて LTS の体制へ、Plex2Shell の影響版は 1.43.3.10861 未満で QNAP が注意喚起（2026/11/10 Linux・OSSトレンド）"
date: 2026-11-10T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "SonicWall", "Linux カーネル", "Linux 7.4", "Rust", "Node.js", "Plex", "QNAP"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「設定済み」「162倍」「最高でも7.2」。看板の言葉や数字と実際の中身は、別物かもしれません。2026年11月10日の動画は、このテーマで次の5本を取り上げました。SonicWall の SSL-VPN では、SAML で強制した MFA が迂回されうる脆弱性が KEV に載りました。Linux 7.4-rc2 では、FAT32 が162倍速くなったという見出しの条件を読みます。BenchUp は、自らを vibe-coded と称する木工向けの3Dモデラーです。Node.js は、奇数の版が LTS にならない慣習をやめ、年1回の体制に移ります。Plex2Shell は、CVSS v3.1（CNA の CISA の採点）の個別の値が最高 7.2 の脆弱性4件をつなぐ攻撃で、QNAP には NAS の侵害の報告が届いています。

この5本を「看板と中身」で括ったのは書き手の考察で、各社の主張ではありません。動画の内容に誤りや裏付けの取れないものがあった場合は、各節の末尾に訂正を載せました。

確認は2026年11月10日の朝（日本時間）に行いました。版の番号や集計値のように変わりうるものには、本文で確認した時刻や時点を添えています。

{{< youtube "wA-l2f3NkbY" >}}

## 1. SonicWall CVE-2026-19868 — SAML を使う SSL-VPN で、SAML 方式の MFA も迂回されうる

[NVD の説明](https://nvd.nist.gov/vuln/detail/CVE-2026-19868)は、SonicOS の SSL-VPN サービスの認証の強制に関する脆弱性で、SAML 以外の認証方式の有効な資格情報を持つユーザーが、SAML の認証制御を迂回できる可能性がある、としています。成功すると、SAML で強制した MFA も迂回しうる、とも書いています。いずれも "may" の書き方で、必ず迂回されるとは書いていません。NVD の公開は11月6日（金）19:17（UTC。日本時間では11月7日 4:17）です。

DEV Community の個人の[解説記事](https://dev.to/damiano_builds/your-mfa-didnt-fail-it-was-never-asked-the-sonicwall-saml-bypass-1dfl)は、題で "Your MFA Didn't Fail. It Was Never Asked"（あなたの MFA は失敗していない。そもそも尋ねられなかった）と表現しています。

### SonicWall の勧告の本文を確認できていない点

SonicWall の[勧告 SNWLID-2026-0014](https://psirt.global.sonicwall.com/vuln-detail/SNWLID-2026-0014)は、ページが JavaScript で描画され、この記事の確認では本文を取得できませんでした。以下の 7.1、影響版、修正版、「回避策なし」は、[BleepingComputer](https://www.bleepingcomputer.com/news/security/sonicwall-warns-of-new-ssl-vpn-mfa-bypass-flaw-exploited-in-attacks/) の記事と、NVD の CNA（SonicWall）項目のどちらかに帰属して書きます。

### 影響版と修正版

- 修正版: Gen7 は 7.3.4-7013、Gen8 は 8.2.3-8015 です（NVD の CNA 項目、BleepingComputer）。Gen8 は下の境界の読み方に関わらず、8.2.3-8015 以降にすれば該当しません
- 影響を受ける版: SonicOS Gen7 は 7.3.3-7015 以前、Gen8 は 8.2.2-8015 以前と、NVD の CNA 項目と BleepingComputer は書いています。Gen8 の境界は資料が割れていて、カナダ政府のサイバーセキュリティセンターの[注意喚起](https://cyber.gc.ca/en/alerts-advisories/sonicwall-security-advisory-av26-1133)は "prior to 8.2.2-8015" と書き、NVD の CPE 構成も 8.2.2-8015 を含まない範囲です
- 回避策: BleepingComputer によれば、SonicWall は回避策はないとしています。ファームウェアの更新が対策です
- 条件: BleepingComputer によれば、影響するのは SAML 認証を使うよう設定した SSL-VPN サービスです。NVD の説明は SAML 限定とは書いていないので、SAML を使っていなければ対象外と言い切るのは避けます

SonicWall が悪用の詳細を共有していない、とも BleepingComputer は書いています。

### 目にする深刻度の数字は3つ

- 7.1: BleepingComputer の記事が伝える CVSS スコアです（採点者と版は同記事に記載がありません）。動画は SonicWall 自身の評価と紹介しましたが、勧告の本文を確認できていないので、ここでは確かめられていません
- 7.5: NVD に載る CVSS v3.1 の値で、採点者は CISA-ADP（Secondary）です。NVD 自身の採点はありません
- 8.8: 同じ勧告にある別の CVE、[CVE-2026-107154](https://nvd.nist.gov/vuln/detail/CVE-2026-107154) と [CVE-2026-107155](https://nvd.nist.gov/vuln/detail/CVE-2026-107155) の値です。どちらも管理インターフェースの問題で、CISA-ADP の CVSS v3.1 です。CVE-2026-19868 の値ではありません

### KEV の追加と期限

CISA の[KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-19868)への追加は11月6日、連邦機関の期限は11月20日（金）で、14日後です（フィードの版は日本時間11月10日 4:54）。KEV の `requiredAction` は、ベンダーの指示に沿った緩和、BOD 26-04 への準拠、クラウドサービスは BOD の指針に従うか、緩和策がなければ製品の使用を停止する、という文面です。この文面は BOD 26-04 に基づく定型文で、9月2日に KEV に入った SMA1000 の2件（[9月4日の記事](https://blog.fuga.jp/posts/2026-09-04-linux-oss-trend/)）の項目にも同じ文が載っています。

### 書き手の補足

DEV Community の記事は、SSL-VPN が実際に受け付けている認証方式を洗い出し、使っていないものを無効にすること、ふだん使われていない非 SAML の方式で認証されたセッションを VPN のログで探すことを挙げています。勧告の本文を確認できていないため、公式の助言かどうかは分かりません。

次の3つは出所を確認できず、書き手が整理した補足です。公式の手順ではありません。

- 更新の前に、設定のバックアップを取っておく
- 認証基盤側の SAML の成功記録と、VPN のセッション記録を時系列で並べ、対応する SAML の記録がない VPN セッションを探す
- 不審なアカウントやセッションを見つけたら、パスワードを変更し、セッションを切断する

動画の訂正です。

- 動画では、今回の KEV で CISA が指令に沿った対応を求め、緩和策を実施できない場合は製品の使用停止まで要求している、と紹介しました。正しくは、この文面は BOD 26-04 に基づく KEV の定型文で、9月2日追加の SMA1000 の2件と同じです。「使用停止」も、緩和策が使えない場合の条件つきです（[CISA の KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-19868)）。
- 動画では、SonicWall は10月にも別の製品で最大スコアの欠陥が悪用されている、と紹介しました。製品は SMA1000 で、[CVE-2026-102255](https://nvd.nist.gov/vuln/detail/CVE-2026-102255) のことです。BleepingComputer は攻撃者が悪用していると報じましたが、根拠はハニーポットでの観測で、成功したかは確認されていません。同社の記事によれば、SonicWall の10月の勧告は悪用中としていません。CISA の KEV にも載っていません（日本時間11月10日 4:54 のフィードの版）。最大スコアの 10.0 は CISA-ADP の CVSS v3.1 の採点で、NVD は未解析です（[BleepingComputer](https://www.bleepingcomputer.com/news/security/max-severity-sonicwall-sma1000-flaw-now-exploited-in-attacks/)）。

## 2. Linux 7.4-rc2 — FAT32「162倍」の条件

Linux 7.4-rc2 の[タグ](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tag/?h=v7.4-rc2)は、米国時間11月8日（日）16:22（太平洋標準時。日本時間では11月9日（月）9:22）に打たれ、[Torvalds 氏のアナウンス](https://lkml.iu.edu/2611.1/01530.html)は日本時間の11月9日 9:47 です。

### 162倍の条件

「162倍」は、[Phoronix の記事](https://www.phoronix.com/news/Linux-7.4-rc2-FAT32)の見出しにある数字（"As Much As 162x"）です。値は、パッチ作者の Matheus Alves de Almeida 氏が、[コミット 4bdfe8dd2342](https://github.com/torvalds/linux/commit/4bdfe8dd2342f9c2bdc3b788699164ebe21d9126) の本文に載せた測定結果で、QEMU/KVM の virtio-blk 上（cache=none）で測っています。Phoronix は報じただけです。

- 162.15倍は、512バイトクラスタ、1MiB の `ftruncate`、同期ありの条件の値です（58.66秒から0.362秒に短縮）
- 対象はファイルを広げるときの領域の事前確保です。書き込み全般が速くなる、という意味ではありません
- 同期でないマウントでも、作者の測定では 1.13〜1.79倍です。コミットは、効果が最大なのは、クラスタが小さいファイルシステムと同期マウントだ、と書いています
- 4096バイトクラスタでも、同期ありなら 79〜84倍の結果が表にあります

仕組みは、新しい `fat_preallocate()` が、`fat_cont_expand()` と `fat_fallocate(FALLOC_FL_KEEP_SIZE)` で使われ、小さいクラスタの確保を何度も繰り返す経路を減らすものです。このコミットは rc1 より後で、rc2 に入りました。rc1 に入った、Phoronix が10月29日に「最大265倍」と報じた FAT32 の変更とは別のものです。

### 「史上最大」は誰の言葉か

Torvalds 氏が rc2 のアナウンスに書いたのは "a big -rc2 to go with the largest ever -rc1"（過去最大の rc1 に見合う大きな rc2）です。rc1 のアナウンスの "almost 20k commits vs the more common ~15k" は、[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)で扱いました。「史上最大のマージウィンドウ」という言い方は [Phoronix の記事](https://www.phoronix.com/news/Linux-7.4-Massive-Window)の見出しです。Phoronix の集計は Linux 3.1 以降のマージウィンドウを比べたもので、7.4 を rc1 直前の時点で19,671件としています。

### rc2 の差分

- 差分の中身: rc2 のアナウンスによれば、差分の見かけは "fairly benign"（穏当）で、大半は coccinelle による自動更新です。マージウィンドウで受け取ったものの、旅行中で扱いたくなかったので rc2 に回した、と Torvalds 氏は書いています。更新は1行・2行の変更が中心で "very straightforward"（ごく素直）だ、とも続けています
- AI に関する発言: "I'm *much* happier with the flood of AI triggered work going into the merge window than it showing up mainly as extra fixes during the -rc period"（AI がきっかけの作業が、主に -rc の期間の追加修正として現れるより、マージウィンドウに入るほうがずっとうれしい）は、rc2 ではなく、11月1日の rc1 のアナウンスの文です（[rc1 のアナウンス](https://lkml.iu.edu/2611.0/00796.html)）
- NVMe: [コミット b1d1f6b1ee03](https://github.com/torvalds/linux/commit/b1d1f6b1ee03) は、NVMe over TCP のコントローラ生成が失敗する経路での use-after-free の修正です。rc1 から rc2 までには約990のコミットがあり、これは一例です

安定版の時期について、Torvalds 氏のアナウンスに日付はありません。[Phoronix](https://www.phoronix.com/news/Linux-7.4-rc2-Released) は12月末ごろを狙うと書いています（rc1 の記事では、予定どおりなら12月20日ごろとしていました）。確定した予定ではありません。

動画の訂正です。

- 動画では、普通のマウントなら変化はない、と紹介しました。正しくは、作者のベンチでは、同期でないマウントでも 1.13〜1.79倍の改善が出ています（[コミット 4bdfe8dd2342](https://github.com/torvalds/linux/commit/4bdfe8dd2342f9c2bdc3b788699164ebe21d9126)）。
- 動画では、恩恵を受けるのは同期書き込みを使う組み込み機器や Raspberry Pi、SD カードや USB メモリだ、と紹介しました。こうした機器や媒体の例は、コミットにも Phoronix の記事にも Torvalds 氏のアナウンスにもありません。測定は QEMU 上の仮想ディスクです（同コミット）。
- 動画では、162倍は Phoronix のベンチマークの数字だ、と紹介しました。正しくは、パッチ作者の Matheus Alves de Almeida 氏が QEMU/KVM 上で測った値で、コミットの本文にあります。Phoronix は報じただけです（同コミット）。
- 動画では、AI のタグが付いたコミットは前のサイクルの2.4倍だ、と紹介しました。確認できた出所は集約サイトの AI Weekly だけで、同サイトが出典とする The Register の記事に数字はありません。

## 3. BenchUp — 旧 KetchUp の、Rust 製の木工向け3Dモデラー

BenchUp は、木工と家具設計向けの無料のオープンソースの3Dモデリングアプリです。[README](https://github.com/BenchUp3D/editor) は "written in Rust" と書き、[LICENSE](https://github.com/BenchUp3D/editor/blob/main/LICENSE) は MIT です。

### 動かし方

- 同じエディタが、Windows、macOS、Linux のネイティブアプリとして、また WebAssembly を使うデスクトップのブラウザで動きます。ブラウザは WebGPU を優先し、WebGL2 に切り替えます（README）
- ビルドには Rust 1.95 以上（[Cargo.toml](https://github.com/BenchUp3D/editor/blob/main/Cargo.toml) の `rust-version`）が要ります。ブラウザ向けには Trunk を使います（README）
- 構成は、`benchup-core`（ジオメトリ、選択、カメラ、履歴など。GUI にも GPU にも依存しない）と、`benchup-app`（egui の UI と wgpu の描画）です（README）

### 機能

README は、ほぞ継ぎ、相欠き、さね継ぎ、相じゃくり、蟻継ぎ、フィンガージョイントを、斜めの接続を含めて作れ、寸法とクリアランスをプレビューしながら調整できる、と書いています。木目の向きの設定と、切断計画と時間・コストの見積もりの PDF 出力もあります。[v0.6.6 のリリースノート](https://github.com/BenchUp3D/editor/releases/tag/v0.6.6)は、体の衝突、段差、傾斜、しゃがみ、ジャンプ、着座に対応し、目線の高さでモデルの中を歩けるモードを挙げています（11月10日 6:45の時点で、最新版は v0.6.6）。

### 改名

v0.6.6 のリリースノートは "KetchUp is now BenchUp, with updated branding and .bup project files" と書き、既存のプロジェクトは `.k3d` と `.ketchup` のまま読める、としています。リリースノートの日付は11月8日（日）で、GitHub のリリースの公開は日本時間の11月9日 13:38です。リポジトリは `Ketchup3D/app` から `BenchUp3D/editor` へ移されました。改名の理由は、README にもリリースノートにも書かれていません。

### 自己紹介の文

GitHub のリポジトリ説明欄は、"Free, open-source 3D woodworking and modeling software and SketchUp alternative. Built with Rust, WebAssembly and WebGPU. Runs in your browser or on desktop. 100% vibe-coded, only the finest slop, with great emphase on rendering speed and UI/UX." です（"emphase" は原文のまま）。README には vibe や slop の語はありません。

### 取り込みと保存の注意

[公式の機能一覧](https://benchup3d.github.io/editor/llms.txt)によれば、SketchUp の `.skp` のジオメトリを取り込めますが、テクスチャ、シーン、一部の機能は非対応です。[docs](https://github.com/BenchUp3D/editor/blob/main/docs/projects.md)は、穴、単色の材質の色などは保たれるとしており、v0.6.6 のリリースノートもグループや位置を保つと書いています。ブラウザ版の自動保存は、ブラウザのデータを消すと消えることがあるので、プロジェクトはダウンロードしてバックアップを取るよう、一覧は書いています。保存は File → Save As で、既定は `.bup` です。

動画の訂正です。

- 動画では、案の定、商標が危ないと指摘され、それで11月8日の v0.6.6 で BenchUp に変えた、と紹介しました。一次は改名の理由を述べておらず、商標の指摘は SNS 上のコメント由来で、因果は確認できません。リリースノートの日付は11月8日で、GitHub での公開は日本時間の11月9日 13:38です（[v0.6.6 のリリース](https://github.com/BenchUp3D/editor/releases/tag/v0.6.6)）。

## 4. Node.js 27 Alpha — 年1回、すべてのメジャーが LTS に

Node.js 27 の最初の Alpha は、[リリースノート](https://nodejs.org/en/blog/release/v27.0.0-alpha.0.0.0)の日付が10月29日（木）で、GitHub の公開は日本時間の10月30日（金）3:36です。版は 27.0.0-alpha.0.0.0 で、Alpha は本番用ではありません（Release README は、ライブラリの作者と CI 向けで、本番用ではないと書いています）。

### リリース体制

[告知](https://nodejs.org/en/blog/announcements/evolving-the-nodejs-release-schedule)によれば、27.x から、メジャーは年2回から年1回（4月）になり、10月に LTS へ昇格します。すべてのリリースが LTS になり、偶数と奇数の区別はなくなります。版の番号は、最初の Current の暦年に合わせるので、27.0.0 は2027年です。26 までは従来の体制です。

[スケジュール表](https://github.com/nodejs/Release/blob/main/README.md)の予定は、Current が2027年4月22日、LTS が2027年10月20日、EOL が2030年4月30日です。表も告知も、日付は変わりうる、としています。Node.js は、ライブラリの作者に、Alpha をできるだけ早く CI に入れるよう呼びかけています。LTS だけで試すと、利用者に影響が出る前にバグを報告できないためです。

### 27.0.0-alpha.0.0.0 の内容

- V8 は 15.6 です（Node.js 26 は 14.6）。`Math.sumPrecise()` と `Iterator.zip()` が既定で有効です。手元で Alpha のバイナリ（公式の darwin-arm64、SHASUMS256.txt と SHA-256 が一致）を動かすと、`Math.sumPrecise([1e20, 0.1, -1e20])` は 0.1、`Math.sumPrecise([0.1, 0.2])` は 0.30000000000000004 でした。`1e20 + 0.1 - 1e20` は 0 です。`Math.sumPrecise` は [TC39 の提案](https://tc39.es/proposal-math-sum/)で、Stage 2.7 の段階です
- `Iterator.zip()` は、手元では、既定は短いほうに合わせて止まり、strict は長さが違うと TypeError、longest は足りない分を null で埋めました
- `node:net/promises` が実験的に入りました（Stability 1。[net.md](https://github.com/nodejs/node/blob/v27.0.0-alpha.0.0.0/doc/api/net.md)、PR #63965）
- `--allow-env`（PR #66132）は、`--permission` と併用すると、許可しない環境変数を起動時に削除します。Stability は 1.1 で、`PATH`、`HOME`、`NODE_OPTIONS` など Node.js 自身が使う変数は残ります（[cli.md](https://github.com/nodejs/node/blob/v27.0.0-alpha.0.0.0/doc/api/cli.md)）。[権限モデルの文書](https://github.com/nodejs/node/blob/v27.0.0-alpha.0.0.0/doc/api/permissions.md)は、悪意あるコードに対する保証はないと明記しています

### 破壊的変更

- `req.headers` が null プロトタイプになりました（[PR #62900](https://github.com/nodejs/node/pull/62900)）。手元では `req.headers.hasOwnProperty('x')` が TypeError で、`Object.hasOwn(req.headers, 'x')` は動きました。コミットの説明は、`__proto__` のようなヘッダーがプロトタイプの操作と解釈される懸念を解消する、としています（[コミット](https://github.com/nodejs/node/commit/21436f0405)）
- `keepAliveTimeout` の既定が5秒から65秒になりました（[PR #62782](https://github.com/nodejs/node/pull/62782)）。手元の既定値は 65000 でした
- `v8.serialize()`、`structuredClone()`、`postMessage()` は新しい形式で、古い Node.js は読めません。手元でも、27 が書いたものは 26.13.0 で読めず、逆は読めました
- ヒープ上限の既定は、物理メモリの半分で、256MB から 4GB の間です。`Buffer` と `ArrayBuffer` のメモリも上限に数えます。8GB のメモリなら4GB です（半分の定義からの計算）。以前の既定に頼っていたら、`--max-old-space-size` を明示するよう、リリースノートは求めています
- OpenSSL のエンジンのサポートが終わり、`crypto.setEngine()` などが削除されました。TLS と HTTPS の `clientCertEngine`、`privateKeyEngine`、`privateKeyIdentifier` に非 null の値を渡すと `ERR_CRYPTO_CUSTOM_ENGINE_NOT_SUPPORTED` になります（[PR #64777](https://github.com/nodejs/node/pull/64777)）

動画の訂正はありません。

## 5. QNAP の注意喚起と Plex2Shell — 影響版は 1.43.3.10861 未満

Plex Media Server の4件の脆弱性をつなぐ攻撃（Plex2Shell）は、[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)で扱いました。今回の新しい情報は、QNAP が11月6日（金）に出した注意喚起と、対処の FAQ です。

### QNAP の注意喚起

QNAP の[コミュニティの FAQ](https://community.qnap.com/t/plex2shell-check-and-remediation-faq-for-qnap-nas-users/7471)は、11月6日 9:58（UTC。日本時間では18:58）の作成です。QNAP のセキュリティノーティス本体は本文を取得できなかったので、FAQ と BleepingComputer の記事に帰属します。[BleepingComputer](https://www.bleepingcomputer.com/news/security/qnap-says-hackers-breaching-nas-devices-in-plex2shell-attacks/) によれば、QNAP は、一部のユーザーから NAS の Plex Media Server が侵害されたようだとの報告を受けている、としています。FAQ は、1.43.2 以前（FAQ の表記。実際の境界は次の項）の Plex がインターネットから到達できた場合は、NAS が侵害された可能性があるものとして扱うよう求めています。QTS や QuTS hero など、QNAP の OS 自体は影響を受けない、としています。

### 影響版の境界 — 1.43.3.10828 も該当する

Plex の[告知](https://forums.plex.tv/t/important-security-update-for-plex-media-server-v1-43-2-and-earlier/942319/3)は、1.43.3.10861 より古いサーバーで、インターネットから到達できるなら、侵害された可能性を前提にするよう書いています。NVD の CNA 項目、[Censys](https://censys.com/advisory/cve-2026-96652-cve-2026-96654-cve-2026-96655-cve-2026-96656/) も、境界を 1.43.3.10861 未満としています。1.43.3.10861 は、ベータが8月3日（月）、全員向けが8月4日（火、UTC。日本時間では8月5日 1:09）で、1.43.3.10828 は、7月14日に全員向けに[公開](https://forums.plex.tv/t/plex-media-server/30447/711)されています。1.43.2 より新しくても、1.43.3.10861 より古い版は影響を受けます。

Plex の告知スレッドの題名と、QNAP の FAQ は「1.43.2 以前」と書いています。この言い方だと、1.43.3.10828 は該当しないと読めてしまいます。QNAP の FAQ は修正版を「1.43.3（build 1.43.3.10861 以降）」と書く一方、確認と再インストールの手順では「1.43.3 以降」とだけ書いています。表示が 1.43.3 だけの場合は、ビルド番号まで 1.43.3.10861 以降かを確かめてください（この確かめ方は書き手の補足です）。

### 深刻度の値

NVD の4件（CVE-2026-96652、-96654、-96655、-96656）の CVSS は、CNA の CISA（`cisa-cg`）の採点が、NVD で Secondary として載っています。NVD 自身の採点はありません。v3.1 は 4.3、6.5、4.3、7.2 で、最高は CVE-2026-96656 の 7.2 です。v4.0 は 5.3、6.9、5.3、8.6 で、最高は同じ CVE-2026-96656 の 8.6 です。研究者の Zach Main 氏は、連鎖全体に CVSS v3.1 で 9.8 を付けています。これは公式の値ではありません。

Plex の告知は、連鎖させると、認証なしのリモートの攻撃者が Plex Media Server のプロセスの権限でコードを実行できる、としています。この記事では、連鎖の手順には触れません。

### 経過と台数

Plex の告知によれば、攻撃コードの公開は10月16日（金）で、修正版の全員向けの公開から約10週間後です。Plex は9月1日（火、UTC。日本時間では9月2日 3:30）に更新を呼びかけましたが、告知には CVE の番号も詳細もありませんでした。CVE の詳細は、10月19日（月）20:17（UTC。日本時間では10月20日 5:17）に告知に追記され、10月20日に Plex の4件が KEV に追加されました。

Censys の集計は、Plex Media Server を動かすホストが約32万4000台、そのうち約3割が脆弱な版、としています。Censys のページに、この2つの数字の集計日の記載はありません。10月22日の記事の Shadowserver の台数とは指標が違います。

### 確認と対処

- 侵害の兆候: Plex の告知は、侵害されたサーバーで、暗号資産のマイナーとプロキシのソフトウェアが動いていたとしています。Plex が挙げる見覚えのないプロセス名の例は、myawesomeproxy、mylovelyminer、x12345 です。Plex の Codecs フォルダの見覚えのない .so や .dll も確認します。QNAP の FAQ は、Malware Remover の検出（検出コード MR2104 など）も挙げています
- Plex の更新: 1.43.3.10861 以降にします
- インターネットから到達できた場合の手順（QNAP の FAQ）: 調査を頼むなら、削除の前に Plex の Logs フォルダを別の場所へ退避します。Plex を削除し、古いデータのフォルダは再利用せず、最低でも Codecs フォルダの中身をすべて消して、Preferences.xml に自分で設定していないトランスコーダー関連の項目がないか確かめます。App Center から修正版（build 1.43.3.10861 以降）を入れ直し、以前の Codecs の中身は戻しません。到達できなかった場合は、更新で足りる、と QNAP は書いています
- パスワード: Plex は、アカウント設定から全デバイスをサインアウトし、Plex のパスワードを変更するよう書いています。QNAP は、NAS の管理者と利用者のパスワードの変更、2段階認証、NAS 上のほかのサービスが保存するパスワードやキーの更新を挙げています
- 公開の見直し: Plex は、Remote Access が不要なら無効にし、ポート 32400 の直接の転送は必要でなければ避けるよう書いています。QNAP は、ルーターの 32400 の転送ルールの削除と UPnP の無効化、外から使うなら VPN（例: QVPN Service）を挙げています。QNAP の FAQ によれば、ルーターが 32400 を転送していたり、UPnP と Remote Access が有効で Plex が自動でポートを開いていたりすると、外から到達できます

動画の訂正です。

- 動画では、影響するのは Plex Media Server が 1.43.2 以前の場合だ、と紹介しました。正しくは、1.43.3.10861 未満の版です（[NVD CVE-2026-96656](https://nvd.nist.gov/vuln/detail/CVE-2026-96656)、[Plex の告知](https://forums.plex.tv/t/important-security-update-for-plex-media-server-v1-43-2-and-earlier/942319/3)）。1.43.3.10828 は7月14日に[全員向けに公開](https://forums.plex.tv/t/plex-media-server/30447/711)された版で、放送のままだと、この版を使っている人が該当しないと受け取ってしまいます。Plex の告知スレッドの題名と QNAP の FAQ も「1.43.2 以前」と書いていますが、1.43.3.10828 のように 1.43.2 より新しくても 1.43.3.10861 より古い版は影響を受けます。お使いの版が 1.43.3.10861 以降かを、ビルド番号まで確かめてください。
- 動画では、マイナー、プロキシ、バックドアの3種類が観測されている、と紹介しました。Plex の告知が書くのは、暗号資産のマイナーとプロキシのソフトウェアまでです。バックドアは、一次で確認できませんでした（[Plex の告知](https://forums.plex.tv/t/important-security-update-for-plex-media-server-v1-43-2-and-earlier/942319/3)）。

## まとめ

SonicWall の CVE-2026-19868 は、SAML を使う SSL-VPN で、SAML 方式の MFA も迂回されうるもので、KEV の期限は11月20日です。FAT32 の162倍は、512バイトクラスタ、同期あり、作者の QEMU/KVM 上の測定の値で、同期でなくても 1.13〜1.79倍でした。BenchUp は、一次の範囲では、MIT の Rust 製の木工3Dモデラーで、改名の理由は書かれていません。Node.js 27 は、年1回、すべて LTS の体制の最初の Alpha です。Plex2Shell は、影響版が 1.43.3.10861 未満で、QNAP の NAS で侵害の報告が出ています。

手元で確かめておくものは次のとおりです。

- SonicWall: SonicOS の版が、Gen7 は 7.3.4-7013 以降、Gen8 は 8.2.3-8015 以降か確かめる。SAML を使う SSL-VPN か、受け付けている認証方式は何かを洗い出す。更新の前に設定のバックアップを取る
- Plex と QNAP: Plex Media Server の版が 1.43.3.10861 以降か確かめる。ポート 32400 の転送と UPnP を見直し、Remote Access が不要なら無効にする。見覚えのないプロセスと Codecs フォルダも確認する
- Node.js: 27 の Alpha を CI に足して、`req.headers` の使い方、`keepAliveTimeout`、ヒープ上限、`v8.serialize` の形式、OpenSSL のエンジンを確認する
- FAT32: 162倍は同期マウントかつ小さいクラスタの条件の値で、同期でないマウントでは 1.13〜1.79倍にとどまる。対象はファイルを広げるときの事前確保で、書き込み全般の高速化とは読まない

## 参考リンク

- [NVD: CVE-2026-19868](https://nvd.nist.gov/vuln/detail/CVE-2026-19868)
- [CISA KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-19868)
- [Linux 7.4-rc2 の Torvalds 氏のアナウンス](https://lkml.iu.edu/2611.1/01530.html)
- [FAT の事前確保のコミット 4bdfe8dd2342](https://github.com/torvalds/linux/commit/4bdfe8dd2342f9c2bdc3b788699164ebe21d9126)
- [BenchUp の GitHub](https://github.com/BenchUp3D/editor)
- [Node.js 27.0.0-alpha.0.0.0 のリリースノート](https://nodejs.org/en/blog/release/v27.0.0-alpha.0.0.0)
- [Node.js のリリース体制の告知](https://nodejs.org/en/blog/announcements/evolving-the-nodejs-release-schedule)
- [Plex の告知スレッド](https://forums.plex.tv/t/important-security-update-for-plex-media-server-v1-43-2-and-earlier/942319)
- [QNAP コミュニティの FAQ](https://community.qnap.com/t/plex2shell-check-and-remediation-faq-for-qnap-nas-users/7471)

（2026/11/10 Linux・OSSトレンド）
