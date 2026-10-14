---
title: "Xen の Zenbleed 対策が逆向きだった XSA-515、Nix の repair から root 奪取、Vghost CVE-2026-74580、Ubuntu 26.10 正式リリース、FreeType 2.15.0（2026/10/15 Linux・OSSトレンド）"
date: 2026-10-15T00:00:00+09:00
draft: false
tags: ["セキュリティ", "脆弱性", "Linux カーネル", "Ubuntu", "FreeType", "Nix", "Xen", "AMD", "仮想化"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

ひとつずつなら筋の通った変更や小さな不具合が、組み合わさった継ぎ目で穴になる。今回の5本は、この切り口で並べました。Vghost は2つの変更の重なり、FreeType は本家と同梱コピーの時間差、Nix は修理用の機能と別の穴の組み合わせ、Xen は作り直しのときに反転した条件です。

もう1本は続報です。[10月14日の記事](https://blog.fuga.jp/posts/2026-10-14-linux-oss-trend/)で10月15日リリース予定とお伝えした Ubuntu 26.10 が、予定どおり10月15日に正式リリースされました。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "HayDRItC7rA" >}}

## 1. Vghost CVE-2026-74580 — 速くするための仕組みに居残った古いメモ

Linux カーネルの vhost に、Vghost（CVE-2026-74580）と呼ばれる脆弱性が見つかりました。[oss-security の投稿](https://www.openwall.com/lists/oss-security/2026/10/14/2)は、vhost のフロントエンドに影響する "stale IOTLB metadata-cache" の脆弱性としています。Tencent Zhuque Lab が[10月12日に解説](https://matrix.tencent.com/en/2026/10/12/vghost-cve-2026-74580)を公開し、oss-security への投稿は10月14日です。

深刻度は、[NVD の API](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-74580) に載る CVSS 3.1 で 8.8（High）で、kernel.org の CNA も 8.8 です。[Red Hat](https://access.redhat.com/security/cve/cve-2026-74580) は 8.7 を付けています。攻撃は2通りあり、どちらにも条件があります。

- ホスト側の権限昇格: oss-security は "Local user with access to /dev/vhost-* -> arbitrary kernel read/write -> root." と書いています。Tencent によれば、複数のディストリビューションが /dev/vhost-vsock と /dev/vhost-net を 0666 で配っています。検証した Ubuntu では 0660 root:kvm で、kvm グループのユーザーから root を取っています
- 仮想マシンからの脱出: 仮想 IOMMU と iommu_platform と VIRTIO_F_RING_RESET が組み合わさったゲストが、QEMU のヒープ上書きと制御フローの乗っ取りに至ります（oss-security）。vhost が device-IOTLB モードで動くことも条件です（Tencent）

### 古いメモが消されない仕組み

vhost は、virtqueue のメタデータ領域を引き当てた結果を vq->meta_iotlb[] にキャッシュします。[CVE レコード](https://cveawg.mitre.org/api/cve/CVE-2026-74580)によると、このキャッシュは、アドレスを置き換える VHOST_SET_VRING_ADDR でも、領域の大きさを変える VHOST_SET_VRING_NUM でも破棄されません。iotlb_access_ok() はキャッシュに当たると早期に戻るので、範囲チェックが飛ばされます。Tencent によれば、競合状態に依存しない決定的な、任意のカーネルメモリの読み書きが得られます。KASLR も、IDT のゲート0からの読み出しで回避されます。

Tencent は、この穴を2つの変更の組み合わせと整理しています。

- 2017年（Linux 4.11、コミット f88949138058）: メタデータを引く速度を上げるキャッシュと、早期リターンが入った
- 2020年（Linux 5.9、コミット 0210a8db2aec）: アドレスの検証が、ioctl の時点から prefetch の時点へ移った

2020年のコミットの本文には "It is thus wrong to pass them down to access_ok() which only takes HVAs." とあります。IOTLB が有効なときのアドレスは GIOVA なのに、HVA 用の関数へ渡していた誤りの修正で、速くするための変更ではありませんでした。

### 影響範囲と修正版

影響を受けるのは Linux 4.11 以降で、7.2 で修正済みです（CVE レコード）。Tencent は "nearly a decade"、約9年分と書いています。修正が upstream に入ったのは2026年8月3日、CVE 番号の公表は8月21日です。

安定版の修正版は、5.10.265、5.15.216、6.1.183、6.6.152、6.12.104、6.18.45、7.1.9、7.2 です（Tencent、CVE レコード）。ベンダーのカーネルは古い版番号のまま修正だけを取り込むことがある（oss-security）ので、ディストリビューションの情報で確かめてください。Tencent が権限昇格を確かめたのは、Ubuntu 26.04、RHEL 9.8、Amazon Linux 2023、Azure Linux 3.0、Oracle Linux 10.2 です。

Tencent は、自社の Corvus AI がこの欠陥を2時間で特定したと述べています。修正コミットには "Assisted-by: tencentos-corvus-ai:kimi-k3" の行が付いています。

### 対策

修正入りのカーネルへ更新して再起動するのが基本です。更新できない間は、virtio のカーネル内高速化が不要な環境なら vhost モジュールを読み込ませない方法（install vhost /bin/true と modprobe -r）を Red Hat が示しています。vhost に依存する仮想マシンは起動しなくなることがあります。装置ファイルの権限を変えても、すでに開かれたファイル記述子は取り消されない点（oss-security）にも注意してください。

動画の訂正です。

- 動画では「そして2020年に、確かめるタイミングを、実際に使う瞬間まで遅らせる変更が入りました。これも速くするための変更です。」と紹介しましたが、2020年のコミットの理由は性能ではなく、上記の誤りの修正でした。

## 2. 【続報】Ubuntu 26.10 正式リリース — Linux 7.3 と GNOME 51 のログイン画面

[10月14日の記事](https://blog.fuga.jp/posts/2026-10-14-linux-oss-trend/)で予定とお伝えした Ubuntu 26.10 "Stonking Stingray" が、予定どおり10月15日に正式リリースされました（[Ubuntu のリリース告知](https://lists.ubuntu.com/archives/ubuntu-announce/2026-October/)、[releases.ubuntu.com/26.10](https://releases.ubuntu.com/26.10/)）。ベータ版と Linux 7.3 への切り替えは[10月2日の記事](https://blog.fuga.jp/posts/2026-10-02-linux-oss-trend/)で、Rust 化した cp・mv・rm と Zellic の監査、Sequoia PGP などは10月14日の記事で扱いました。ここでは、まだ取り上げていない中身を見ます。

カーネルは Linux 7.3 です。[リリースノート](https://documentation.ubuntu.com/release-notes/26.10/)に "Ubuntu 26.10 ships with the Linux kernel 7.3." とあります。ただしベータの時点では、[Ubuntu Discourse の告知](https://discourse.ubuntu.com/t/ubuntu-26-10-stonking-stingray-beta-released/88662)が "a current 7.3 (rc) kernel" と書いていました。正式版で RC から切り替わったかどうかは、執筆時点では確認できていません。7.3 の中身は10月2日の記事で扱いました。

[Ubuntu Discourse のロードマップ](https://discourse.ubuntu.com/t/ubuntu-desktop-26-10-stonking-stingray-roadmap-building-toward-ubuntu-28-04-lts/83751)には、"Ubuntu 26.10 will ship with GNOME 51, the latest stable release." とあります。[Help Net Security](https://www.helpnetsecurity.com/2026/09/17/gnome-51-new-features/) によれば、GNOME 51 ではログイン画面の GDM にスマートカード、パスキー、QR コードでのログインが加わり、アクセシビリティでは Reduced Motion への対応も広がりました。

[OMG! Ubuntu!](https://www.omgubuntu.co.uk/2026/10/ubuntu-2610-beta-released) は、ベータの時点で Mesa 26.2 の GPU ドライバーが載ると書いています。RISC-V については、リリースノートに "Ubuntu 26.10 introduces official support for multiple RVA23 RISC-V platforms:" とあり、[OMG! Ubuntu!](https://www.omgubuntu.co.uk/2026/10/ubuntu-desktop-riscv-iso) は公式のデスクトップイメージが作られ始めたと報じています。ただし同記事は、用意された2つのイメージを "experimental" としています。

26.04 LTS から上げるには、アップグレードの案内を LTS だけから新しい版すべてへ切り替えます。[Ubuntu の公式デスクトップ文書](https://ubuntu.com/desktop/docs/en/latest/how-to/switch-between-an-lts-and-interim-release/)によれば、/etc/update-manager/release-upgrades の Prompt を normal にするか、Software & Updates の Updates タブで新しい版すべてを選びます。26.10 は中間リリースで、[Ubuntu のリリースサイクル](https://ubuntu.com/about/release-cycle)によれば中間リリースの更新は9か月です。仕事のサーバーは 26.04 LTS のままにして、手元の PC や検証用のマシンで試すのが無難です。

動画の訂正はありません。

## 3. FreeType 2.15.0 — 3つの CVE と、同梱 zlib に修正が届くまで

FreeType が、2026年10月12日に 2.15.0 を出しました。[oss-security に転送された告知](https://www.openwall.com/lists/oss-security/2026/10/13/1)に "CHANGES BETWEEN 2.14.3 and 2.15.0 (2026-Oct-12)" とあります。CVE の付いた修正は3つで、CVSS の値は出所ごとに違います。

| CVE | 内容 | CVSS の値と出所 |
|---|---|---|
| CVE-2026-95512 | CID フォントの読み込み | NVD に載る Red Hat の評価で 5.5、Red Hat Bugzilla では 6.5 |
| CVE-2026-50811 | 可変フォントの範囲外読み取り | NVD に載る値で 6.5 |
| CVE-2026-27171 | 同梱 zlib の無限ループ | NVD の採点で 5.5、MITRE（CNA）の評価は 2.9（Low） |

値は2026年10月15日に[NVD の API](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-27171) などで確かめました。

CVE-2026-95512 は、NVD によれば、細工した CID フォントで "repeated allocations and decryptions of subroutine data across multiple font dictionaries" が起き、メモリと CPU を使い果たします。細工したフォントを含む内容をユーザーに開かせて悪用する、と NVD は書いています。見つけたのは Red Hat と組んだ AISLE で、[Red Hat の CVE ページ](https://access.redhat.com/security/cve/cve-2026-95512)に "Found by AISLE in partnership with Red Hat." とあります。[Bugzilla](https://bugzilla.redhat.com/show_bug.cgi?id=2462295) には "Impact: Important." と "AI_ONLY_REPORT" の印があります。

CVE-2026-50811 は、NVD によれば src/truetype/ttgxvar.c の TT_Get_Var_Design の範囲外読み取りで、CVSS の機密性への影響は Low です。

CVE-2026-27171 は、FreeType が同梱する zlib 1.3.1 のコピーの問題です。README.freetype に "Version: 1.3.1 + commit ba829a4 (for CVE-2026-27171)" とあり、2.15.0 で本家の修正がこのコピーに取り込まれました。NVD によれば、x2nmodp が終了条件のないループで右シフトを繰り返し、crc32_combine64 などで CPU を消費します。FreeType 経由で悪用できるかは確認できていません。GitHub の master では crc32_combine 系は #ifndef Z_FREETYPE の内側にあり、ftgzip.c からは呼ばれていません（2.15.0 のタグ時点で同じとは限りません）。

一般論として、FreeType を静的に組み込んだアプリは OS のパッケージ更新では直らず、アプリ側の更新が必要です。

Debian の[セキュリティトラッカー](https://security-tracker.debian.org/tracker/CVE-2026-95512)は、2026年10月15日の取得時点で、CVE-2026-95512 を bookworm と trixie で vulnerable としています。DSA は予定されていません（no-dsa。bookworm は postponed の "Minor issue"）。forky と sid は fixed です。状態は日々変わります。

動画の訂正です。

- 動画では「細工したフォント入りのWebページや文書を開くだけで、引き金になりうるので。」と紹介しましたが、NVD がそう記すのは CVE-2026-95512 だけです。CVE-2026-27171 は、上記のとおり FreeType 経由で悪用できるかを確認できませんでした。

## 4. Nix と Lix の5件の脆弱性 — repair 機能から root へ

Nix と Lix は、10月13日に5件の脆弱性を共同で公表しました（[oss-security](https://www.openwall.com/lists/oss-security/2026/10/13/11)、[NixOS Discourse](https://discourse.nixos.org/t/security-advisory-for-nix-and-lix-october-2026/80547)）。NVD への掲載は10月14日で、CVSS の採点元はいずれも MITRE（Secondary）です。

| CVE | 内容 | NVD の CVSS | 対象 |
|---|---|---|---|
| CVE-2026-110449 | リスト割り当ての整数オーバーフロー | 7.5 | Nix と Lix |
| CVE-2026-110450 | repair 操作での権限昇格 | 8.0 | Nix と Lix |
| CVE-2026-110451 | macOS の Seatbelt サンドボックス脱出 | 4.3 | Nix と Lix |
| CVE-2026-110452 | multi-user インストーラー | 4.0 | Nix のみ |
| CVE-2026-110453 | daemon の認可 | 4.3 | Nix のみ |

表のとおり、installer と daemon 認可の2件は Lix に影響しません。CVE-2026-110453 は、サンドボックスなし（unsandboxed）で動かしている macOS と FreeBSD で、ビルド用ユーザーからの接続を拒まない問題です（NVD）。macOS のサンドボックスの件は、sandbox を有効にしたときに条件次第でビルドが制限なしで動く問題です（Discourse。macOS の既定は無効）。

最も重いのは repair の CVE-2026-110450 で、NVD では 8.0、[GitHub のアドバイザリ](https://github.com/NixOS/nix/security/advisories/GHSA-jwvx-xq5j-gc56)では High の 8.4 です。GitHub のアドバイザリによれば、allowed-users に入り trusted-users に入っていないユーザーが、repair フラグを付けて既存のストアオブジェクトを任意のファイル群で上書きでき、ハッシュとサイズの確認は展開の後に行われます。そして "In multi-user setups where `nix-daemon` runs as root, allowed users can execute code as root." とあります。

連鎖について、公式の告知は、複数の問題を組み合わせると root まで権限昇格できる（"can be combined to achieve root privilege escalation"）と述べ、daemon の認可の問題は repair をより深刻にするとも書いています。どの CVE をどの順でつなぐかまでは、公式には書かれていません。

修正版は、Nix が 2.35.3、2.34.9、2.31.6、2.30.6、2.28.8、Lix が 2.95.4 と 2.94.3 で、Lix 2.96.0 は影響を受けません。2.29、2.32、2.33 の系列はサポートが終わっており、修正は出ません（Discourse）。公式の緩和策は更新だけで、GitHub のアドバイザリは回避策を挙げていません。[解説記事（DEV Community）](https://dev.to/techaiwire/nix-and-lix-patch-daemon-flaws-that-allow-local-root-3736)は、更新までは allowed-users をビルドが必要なアカウントに絞るよう勧めています。

動画の訂正です。

- 動画では「ところが、取り直した中身を確かめる前に、それをすり替えられる隙間がありました。」「確認と使用の間の隙、いわゆるTOCTOUだね。」と紹介しましたが、一次情報に TOCTOU（競合）の語はなく、GitHub のアドバイザリの分類は CWE-285（不適切な認可）です。一次情報の説明は、権限のないユーザーが repair 操作で正規のストアパスを壊して置き換えられ、ハッシュの確認が展開の後だった、というものです。
- 動画では「macOSやFreeBSDで、nix-daemonが本来通すべきでない相手からの接続を受け入れる問題などです。」と紹介しましたが、対象はサンドボックスなしで動かしている macOS と FreeBSD の Nix で、接続元はビルド用ユーザーです。

## 5. Xen XSA-515 — Zenbleed の回避策が逆向きに動いていた

Xen Project は、10月13日に XSA-514 から XSA-521 までの8件を公開しました（[XSA-515 の告知](https://xenbits.xen.org/xsa/advisory-515.html)の公開日時は "2026-10-13 12:00"）。XSA-519 が CVE を2つ持つため、CVE は9本です。中でも XSA-515（CVE-2026-79608）は "x86/AMD: ineffectual Zenbleed workaround" という題で、Zenbleed の回避策が効いていなかった問題です。

Zenbleed（CVE-2023-20593）は、Google の Tavis Ormandy 氏が[2023年7月に公表](https://lock.cmpxchg8b.com/zenbleed.html)した、AMD の Zen 2 世代の欠陥です。同じ物理コアで動く別のプロセスや仮想マシンのデータが読め、暗号鍵やパスワードを監視できるほど速いと Ormandy 氏は書いています。マイクロコードを当てられない場合の回避策は、DE_CFG[9] の chicken bit を立てることでした。

Xen では、XSA-433 として入れたこの回避策を、同じ MSR を扱うほかの処理と整合させるために作り直しました。XSA-515 は、そのときのことを "In this rework an inverted conditional was introduced, resulting in the workaround to not be applied when needed and vice versa." と書いています。必要なときに適用されず、不要なときに適用されていたわけです。発見は Sashiko + Opus 5.0、セキュリティ問題との診断は George Dunlap 氏だと Credits にあります。

advisory によれば、悪用できるのは次の3つがそろったときです。

1. Xen が 4.19.4 以降、4.20.3 以降、4.21.1 以降、または 4.22（4.18 などの古い版は影響なし）
2. AMD の Zen 2。Ormandy 氏の一覧には EPYC "Rome" が載っています
3. 古いマイクロコードで動いている。advisory には "Microcode fixing Zenbleed was published in late 2023." とあります

[Qubes OS の告知](https://www.qubes-os.org/news/2026/10/13/xsas-released-on-2026-10-13/)は、XSA-514〜521 のいずれも Qubes OS のセキュリティに影響しないと発表しています。NVD は2026年10月15日の取得時点で CVE-2026-79608 を未採点（Awaiting Analysis）とし、[FIRST の EPSS](https://api.first.org/data/v1/epss?cve=CVE-2026-79608) は2026年10月14日付で 0.16% です。値は日々変わります。

advisory の解決策は、添付のパッチを当てることです。AVX を無効にする回避策は、"is not recommended for anyone able to deploy the microcode or patch described below." とされています。マイクロコードの更新を止めている環境では、Xen の更新とマイクロコードの状態を確かめてください。

[XSA-517](https://xenbits.xen.org/xsa/advisory-517.html)（grant table の競合）は XSA-501 の後続です。4.0 以降のすべての Xen が脆弱ですが、悪用できるのは grant table version 2 の使用を許された x86 のマルチ vCPU のゲストです。回避策は、ハイパーバイザーの "gnttab=max-ver:1" か、ゲスト設定の "max_grant_version=1" です。

動画の訂正です。

- 動画では「x86版のXenなら、すべての版に関係します。」と紹介しましたが、上記のとおり、悪用できるのは grant table version 2 を使える x86 のマルチ vCPU のゲストに限られます。

## まとめ

4本とも、穴は個々の変更そのものより、その継ぎ目にありました。継ぎ目は、足すときにも作り直すときにも生まれます。この共通点は書き手の考察です。

今日できることを挙げます。

- vhost で仮想マシンを動かしているなら、ディストリビューションの情報で Vghost の修正を確かめ、更新して再起動する
- Nix や Lix を使っているなら版を確認し、2.29、2.32、2.33 の系列なら手入れされている系列へ移る
- Xen と Zen 2 世代の EPYC を使っているなら、Xen の更新とマイクロコードの確認をする
- FreeType を組み込んだアプリの更新も確認する
- 正式リリースされた Ubuntu 26.10 を試すなら、検証用のマシンで

## 参考リンク

- [oss-security: Vghost（CVE-2026-74580）](https://www.openwall.com/lists/oss-security/2026/10/14/2)
- [Tencent Zhuque Lab: Vghost の解説](https://matrix.tencent.com/en/2026/10/12/vghost-cve-2026-74580)
- [Ubuntu 26.10 のリリース告知](https://lists.ubuntu.com/archives/ubuntu-announce/2026-October/)
- [Ubuntu 26.10 のリリースノート](https://documentation.ubuntu.com/release-notes/26.10/)
- [oss-security: FreeType 2.15.0](https://www.openwall.com/lists/oss-security/2026/10/13/1)
- [NixOS Discourse: Nix と Lix のセキュリティ告知](https://discourse.nixos.org/t/security-advisory-for-nix-and-lix-october-2026/80547)
- [Xen XSA-515](https://xenbits.xen.org/xsa/advisory-515.html)
- [2026年10月14日の Linux・OSSトレンド（Ubuntu 26.10 の予定）](https://blog.fuga.jp/posts/2026-10-14-linux-oss-trend/)
- [2026年10月2日の Linux・OSSトレンド（Ubuntu 26.10 ベータと Linux 7.3）](https://blog.fuga.jp/posts/2026-10-02-linux-oss-trend/)

（2026/10/15 Linux・OSSトレンド）
