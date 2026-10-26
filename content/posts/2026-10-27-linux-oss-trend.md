---
title: "Wasmtime のサンドボックス脱出、ZDI の未修正カーネル脆弱性が公開リストに届く、Linux 7.4 で C 版 Binder を削除、OpenSSL 4.1.0 は正式版の前に DTLS の穴を直した、PHP2Shell の攻防のその後（2026/10/27 Linux・OSSトレンド）"
date: 2026-10-27T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Wasmtime", "WebAssembly", "Rust", "Linux カーネル", "Linux 7.4", "Android", "OpenSSL", "PHP"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

安全装置は、付いていることと、本番で効いていることが別の話です。今回の5本は、その差を測る話として読めます。Wasmtime では、値の取り違えを確かめる検査がリリースビルドで動かない書き方になっていました。Linux カーネルでは、非公開で扱われるはずの未修正の報告が、公開のメーリングリストにも届いています。Binder は、守るべき約束を型で表す Rust 版に一本化されました。OpenSSL 4.1.0 は、DTLS の待ち受けでメモリを際限なく使わせられるという報告2件を、正式版の前に直しています。PHP2Shell は、修正版が出る前後の攻撃の観測が、一次の情報で見えてきました。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "BAGZ2p13qRM" >}}

## 1. Wasmtime の Cranelift — CVE-2026-115889 と CVE-2026-115893、サンドボックスを抜けられる恐れ

WebAssembly の実行環境 Wasmtime のコンパイラ部分 Cranelift に、サンドボックスを抜け出せる恐れのある脆弱性が2件公表されました。Bytecode Alliance の GitHub アドバイザリの公開は、UTC の10月19日 19:21 です。日本時間では10月20日 4:21 にあたります。

- CVE-2026-115889 は [GHSA-897f-g5gm-fmxm](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-897f-g5gm-fmxm)、RustSec では RUSTSEC-2026-0380 です
- CVE-2026-115893 は [GHSA-mghf-wjfp-p5xm](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-mghf-wjfp-p5xm)、RustSec では [RUSTSEC-2026-0379](https://rustsec.org/advisories/RUSTSEC-2026-0379.html) です

### 深刻度

GHSA は2件とも CVSS v3.1 で 9.9（Critical）としています。ベクターは `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` です。採点したのは GitHub で、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-115889) の上でも security-advisories@github.com の Secondary という扱いです。NVD（NIST）自身の採点はなく、v4.0 の値もありません。PR:L は、低い権限が必要という意味です。

### 1件目 — 値の番号を24ビットに詰めていた

GHSA によれば、Wasmtime v43 より前の Cranelift は、SSA 値の番号をビットに詰め込む方式を使っていました。リリースビルドでは、これが "silent overflow"（気づかれない桁あふれ）になりえます。修正を36系へ取り込んだ [PR #14818](https://github.com/bytecodealliance/wasmtime/pull/14818) の旧コードには、24ビットの枠が2つ並んでいます。2の24乗は 16,777,216 で、約1677万が上限です。

範囲を超えたときの確認は `debug_assert!` で書かれていました。Rust の[標準ドキュメント](https://doc.rust-lang.org/std/macro.debug_assert.html)は、最適化したビルドでは、`-C debug-assertions` を渡さない限り `debug_assert!` は実行されないと書いています。つまり、開発ビルドでしか効かない検査だったことになります。

細工した Wasm モジュールで、とても大きな関数本体や SSA 値を大量に使う関数を作ると、型の取り違えなどでサンドボックスを抜けられる、とアドバイザリは説明しています。影響は、既定の設定（Cranelift バックエンド）で、アーキテクチャを問いません。修正は v43 で入り、GHSA の言い方では、完全な u32 の番号を使い、上限を超えた場合のチェックを備えています。

### 2件目 — aarch64 の br_table

GHSA-mghf によれば、aarch64 向けの Cranelift は、1つの `br_table` 命令の行き先が約25万6千（~256k）を超えると、誤った条件分岐の行き先を生成します。NVD の説明も "approximately 256,000 targets" です。

[PR #14826](https://github.com/bytecodealliance/wasmtime/pull/14826) の説明によれば、原因は aarch64 の条件分岐の到達範囲が ±1MiB であることです。デフォルトの行き先への分岐と、32ビットのオフセット表が同じ命令にまとまっていたため、範囲外の行き先になっても、オフセットが気づかれずに巻き戻ります。アドバイザリによれば、aarch64 に対応した2020年の初版から影響を受けます。

36.0.19 のパッチは、`br_table` の行き先の数に実装上の上限（65,520）も設けました。コードのコメントによれば、V8 と SpiderMonkey の上限（2の16乗から16を引いた値）に合わせたものです。

### GitHub の脆弱性データベースの状況

1件目は10月23日 22:02 UTC に、GitHub Advisory Database へレビュー済みで登録されました。2件目の CVE-2026-115893 は、10月27日 8時（日本時間）の時点でも登録が見当たりません。`gh api` で CVE 番号を検索しても見つからず、GHSA の ID で引くと 404 でした。これは GitHub Advisory Database への登録の話で、CVE-2026-115893 が存在しないという意味ではありません。10月27日の確認時点で、[Wasmtime リポジトリのアドバイザリ](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-mghf-wjfp-p5xm)、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-115893)、[RustSec](https://rustsec.org/advisories/RUSTSEC-2026-0379.html) で確認できます。

GitHub の[ドキュメント](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts)は "Only advisories reviewed by GitHub trigger alerts." と書いています。登録されていない間は、Dependabot の警告が鳴らない恐れがあります。Rust のプロジェクトでは、[cargo-deny](https://github.com/EmbarkStudios/cargo-deny/blob/main/docs/src/checks/advisories/cfg.md) が既定で RustSec の DB を参照し、RUSTSEC-2026-0379 は登録済みです。

### 修正版と、修正が出ない版

- 36系（長期サポート版）は 36.0.19、最新系は [50.0.0](https://github.com/bytecodealliance/wasmtime/releases/tag/v50.0.0)（UTC の10月20日公開）以降で、2件ともふさがります
- 2件目の修正版は、RustSec によれば 36.0.19、48.0.7、49.0.4 です。1件目は、GHSA の範囲が 37.0.0 以上 43.0.0 未満と 36.0.19 未満なので、43 以降は対象外です。48 系と 49 系は、1件目の影響は受けず、2件目の影響だけを受けます
- 修正が出ていない系列は、サポート期間が終わったものです。Wasmtime の[方針](https://github.com/bytecodealliance/wasmtime/blob/main/docs/stability-release.md)は、12の倍数の版を LTS とし、24か月サポートすると書いています。例として "Wasmtime 24.0.0 is supported for 2 years." とあり、24.0.0 は2024年8月20日の公開なので、24系のサポートは2026年8月ごろに終わったとみられます。24系の最後は 24.0.13（2026年8月20日公開）です。43から47系も、47.0.4（2026年8月20日公開）が最後で、10月19日のパッチはありません。43から47系で aarch64 を使っているなら、48.0.7 以降へ上げます

### 組み込んでいる場合の確認

アドバイザリには、Wasmtime をライブラリ経由で組み込んだ場合の記述はありません。ただ、自分のアプリが Wasmtime を依存関係として持っているなら、上の版に当たるかは確かめる必要があります。アドバイザリに回避策の記載はありません。更新までのあいだ、外から持ち込まれた Wasm モジュールを動かさないという対応は、アドバイザリではなく書き手の助言です。

動画の訂正です。

- 動画では、br_table の行き先が「65,520個以上になると」誤ったジャンプになると紹介し、画面にも同じ数字を出しましたが、GHSA と NVD は約25万6千（~256k）を超えるとき、と書いています。65,520 は、修正版の 36.0.19 が加えた実装上の上限で、誤ジャンプが起きる件数ではありません（[GHSA-mghf-wjfp-p5xm](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-mghf-wjfp-p5xm)、[PR #14818](https://github.com/bytecodealliance/wasmtime/pull/14818)）。
- 動画では、すぐに更新できない場合に、翻訳せずに1命令ずつ解釈して動かす方式（解釈実行）へ切り替えると紹介しましたが、Wasmtime の公式ドキュメントでは、解釈実行（Pulley）も Cranelift のバックエンドで Wasm をバイトコードに翻訳しています。アドバイザリに回避策の記載はなく、解釈実行が回避になるという一次の根拠は見つかりませんでした（[プラットフォーム対応のドキュメント](https://github.com/bytecodealliance/wasmtime/blob/main/docs/stability-platform-support.md)、[Pulley のドキュメント](https://github.com/bytecodealliance/wasmtime/blob/main/docs/examples-pulley.md)）。
- 動画では、「24系の長期サポート版や、サポートが終わった版には修正が出ない」と紹介しましたが、「24系の長期サポート版」という言い方だと、いまもサポート中の LTS に修正が出ない、と聞こえます。Wasmtime の方針（24か月サポート）と公開日から計算すると、24系のサポートは2026年8月ごろに終わっているとみられ、修正が出ないのは「サポート期間が終わった版」だからです。公式の終了日そのものは確認できていません。最新のサポート状況は、Wasmtime の[リリース方針](https://github.com/bytecodealliance/wasmtime/blob/main/docs/stability-release.md)と[リリース一覧](https://github.com/bytecodealliance/wasmtime/releases/tag/v24.0.13)で確認してください。

## 2. ZDI の未修正カーネル脆弱性の報告が公開リストに届く — KSMBD と skb_zerocopy

Trend Micro 系の Zero Day Initiative（ZDI）が送った、未修正の脆弱性の報告6件が、公開のメーリングリストにも届きました。6件のうち5件はカーネルの問題で、1件はユーザー空間のネットワーク管理ツール ConnMan です。ConnMan の報告は、TuxCare によれば UTC の10月20日 0:17 の投稿です。カーネルの報告は、確認できた元メールの Date ヘッダーで UTC の10月21日 21:16 から 21:46 で、日本時間では10月22日の早朝（6:16 から 6:46）にあたります。

### 何が起きたか

元メールのヘッダーを見ると、ZDI-CAN-33774 の宛先は security@kernel.org で、Cc に linux-cifs と linux-kernel が入っています。ZDI-CAN-33367 の Cc には netdev と linux-kernel があります（[ZDI-CAN-33774](https://lists.openwall.net/linux-kernel/2026/10/21/2694)、[ZDI-CAN-33367](https://lists.openwall.net/netdev/2026/10/21/605)）。6件のうち3件には、TuxCare によれば、詳細な説明と PoC のソースが付いていました。

カーネルの[ドキュメント](https://docs.kernel.org/process/security-bugs.html)は、security@kernel.org を非公開のセキュリティ担当者の窓口とし、この段階で公開リストへ送らないよう求めています。

Phoronix は、"Seemingly as an accident"（事故とみられる）として[報じています](https://www.phoronix.com/news/LKML-New-Trend-Vulnerabilities)。誤って送ったという見方は、Phoronix の見立てです。ZDI 自身は netdev への[返信](https://lists.openwall.net/netdev/2026/10/22/455)で、"we will send the cases to you as we always have" と書き、誤りを認めてはいません。公開リストに Cc が付いたため、内容は公開アーカイブで誰でも読めます。

### KSMBD の2件

ZDI-CAN-33774 と ZDI-CAN-33549 は、KSMBD（カーネル内の SMB サーバー）の問題です。ZDI の評価で、どちらも CVSS 9.0 です。ベクターは `AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H` という v3 系の形式で、メールに版の記載はありません。

ZDI-CAN-33774 では、報告に "conn->ops is selected per-PDU at enqueue time but dereferenced at dequeue time." という原因が書かれています。ベクターは PR:N で、事前の認証なしに SMB のポートへ届けば攻撃できる、というのが ZDI の評価です。TuxCare によれば、試行ごとにカーネルのヒープから28バイトが漏れ、カーネルがクラッシュすることもあります。報告には、書き込みの経路もあるという分析（smb2_set_info から parse_sec_desc）があり、題名は Remote Code Execution です。ただし、書き込み経路の PoC はありません。

KSMBD は、有効にしていない環境が多くあります。TuxCare によれば、Debian と Ubuntu は ksmbd-tools を入れない限り動かず、AlmaLinux と CloudLinux のカーネルは ksmbd をビルドしていません。Red Hat は、[Red Hat の見解](https://access.redhat.com/solutions/6991749)で、このカーネルモジュールを Red Hat 製品には含めておらず、有効にもしていないと書いています。影響があるのは、KSMBD を使うように設定した環境です。

### skb_zerocopy の1件

ZDI-CAN-33367 は、skb_zerocopy() が共有フラグメントの目印 `SKBFL_SHARED_FRAG` を引き継がない問題です。ZDI の評価では CVSS 7.8、ベクターは `AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` で、ローカルの権限昇格です。

TuxCare は、これが5月に直された CVE-2026-43284（TuxCare は Dirty Frag と呼んでいます）の修正の守りをすり抜けると書いています。NVD に Dirty Frag の名前はなく、CVE-2026-43284 の NVD の公開は UTC の5月8日です。TuxCare によれば、問題の元は skb_zerocopy() を入れたカーネル 3.14 のコミットまでさかのぼります。TuxCare の検証では、AlmaLinux 8・9・10、CloudLinux 9・10、Debian 12・13、Ubuntu 24.04・26.04 で root を取れました。

netdev には、修正の[パッチ v2](https://lists.openwall.net/netdev/2026/10/22/204)が投稿され、Eric Dumazet 氏が Reviewed-by を付けています。diffstat は2行の追加ですが、うち1行は空行です。10月27日の確認時点で、torvalds/linux の mainline には見当たりませんでした。TuxCare によれば、10月23日時点で CVE も割り当てられていません。

Dumazet 氏は、netdev への[返信](https://lists.openwall.net/netdev/2026/10/22/64)で、ZDI の報告を切り詰めたと書き、"Way too long, I could not see a patch in it." と述べています。さらに、別の情報源から1週間前にパッチ付きの報告を受けていたといい、原文は "We were fortunate to receive a report with a patch from another source one week ago." です。

### 緩和と、日付つきの情報

- TuxCare は、ユーザー名前空間の無効化を主な緩和策に挙げています。設定は `/etc/sysctl.d/99-zdi-33367.conf` に `user.max_user_namespaces = 0` と書き、`sysctl --system` で反映します。ただし、rootless コンテナ、Flatpak、一部のブラウザのサンドボックスが壊れる恐れがあります。すべての経路をふさぐ保証もありません
- KSMBD のサービスが動いていて不要なら、TuxCare の記事にある `systemctl disable --now ksmbd` で止めます
- TuxCare は、有償の KernelCare 利用者向けに、AlmaLinux、CloudLinux、RHEL、Oracle Linux、Rocky Linux の各10系向けに、再起動不要のパッチを出しています。10月23日時点で、EL9 は審査中、EL8 は作業中で、Debian と Ubuntu は未着手です
- 同じ記事は、"No exploitation in the wild has been reported as of October 23." と書いています。10月23日時点の記述で、その後の状況は確認できていません

ZDI の[公開方針](https://www.zerodayinitiative.com/advisories/disclosure_policy/)は、通常、ベンダーに4か月（120日）の猶予を与え、期限後は軽減策つきの限定的なアドバイザリを公開すると書いています。ZDI は先の netdev への返信で "We will release the findings at rejection, or 120 days." とも書いています。ただ、今回は公開リストに Cc が付いたため、報告の中身は120日を待たずに公開アーカイブで読める状態です。

### 誰に影響があるか

KSMBD の2件は、KSMBD を有効にしている環境の話です。skb_zerocopy の1件は、ローカルのユーザーがいるシステムに関わります。サーバーや一般のデスクトップでは、まず ksmbd が動いているか、ユーザー名前空間を何が使っているかを確かめるところからです。

動画の訂正です。

- 動画では、ZDI が未修正の報告を公開のメーリングリストへ「誤送信」した、「送ってしまった」と紹介しました。元メールで確認できる事実は、宛先が security@kernel.org で、Cc にメンテナ個人と公開リストが入っていたことです。誤って送ったという見方は Phoronix のもので、ZDI は netdev への返信で "we will send the cases to you as we always have" と書き、誤りを認めてはいません。その後のやり取りは、元メールと ZDI の返信で確認してください（[ZDI-CAN-33774 の元メール](https://lists.openwall.net/linux-kernel/2026/10/21/2694)、[ZDI の返信](https://lists.openwall.net/netdev/2026/10/22/455)、[Phoronix の記事](https://www.phoronix.com/news/LKML-New-Trend-Vulnerabilities)）。
- 動画では、ZDI は普段120日の非公開期間を置くと紹介したうえで、「今回はその手順そのものが、送信の段階で飛ばされてしまいました」と話しました。ZDI は上の返信で "We will release the findings at rejection, or 120 days." と書いており、手順を飛ばしたとは述べていません。確認できるのは、公開リストに Cc が付いたため、報告の中身が120日を待たずに公開アーカイブで読める状態になった、という点です。ZDI の方針は[公開方針のページ](https://www.zerodayinitiative.com/advisories/disclosure_policy/)で確認できます。

## 3. Linux 7.4 のマージウィンドウで C 版 Binder を削除、Rust 版が唯一の実装に

Android のプロセス間通信を担う Binder ドライバについて、C 版を削除する変更が、Linux 7.4 のマージウィンドウ中に mainline へ取り込まれました。Linus Torvalds 氏による `Merge tag 'char-misc-7.4-rc1'` のコミット（[330517c63aa9](https://github.com/torvalds/linux/commit/330517c63aa9b48227b6ab45f01003effac77ae4)）は、UTC の10月25日 1:44（日本時間 10月25日(日) 10:44）です。7.4-rc1 はまだ出ておらず、「7.4 で出荷された」とはいえない段階です。

### 削除の中身

削除コミットは `binder: rm -f binder.c`（[fd2bc059ed46](https://github.com/torvalds/linux/commit/fd2bc059ed466bdd95347a4f7891d150d94e7de2)）で、作者は Google の Carlos Llamas 氏、Acked-by は Alice Ryhl 氏です。char-misc ツリーへのコミットは UTC の9月17日 9:22 です。変更は20ファイルで、削除が11,470行、追加が9行です。

コミット本文は、削除の理由を次のように書いています。"For 15+ years, the C driver has grown increasingly complex, making it incredibly painful to maintain and land new features without tripping over vulnerabilities." 同じ本文は、Rust 版が機能の同等性に達しただけでなく、C 版の性能に並び、しばしば上回ることも示した、とも書いています。mainline の git 履歴には、`binder: fix UAF in binder_free_transaction()`（2026年7月3日）や `binder: fix yet another UAF in binder_devices`（2025年5月25日）といった、解放後利用の修正が繰り返し入っています。

唯一の実装になったのは mainline の話です。Android 各社が持つ mainline 外のカーネルまでは、この記事では扱えません。

### Rust 版の経緯

Rust 版は、[追加コミット](https://github.com/torvalds/linux/commit/eafedbc7c050c44744fbdf80bdf3315e860b7513)が v6.18-rc1 に含まれており、[Rust for Linux のページ](https://rust-for-linux.com/android-binder-driver)も "The driver was merged into Linux kernel version v6.18-rc1." と書いています。同ページによれば、元の作者は Wedson Almeida Filho 氏で、いまは Alice Ryhl 氏がメンテナーです。

削除の計画は、2023年11月にさかのぼります。Alice Ryhl 氏が送った20本の RFC の最後が `binder: delete the C implementation` で、本文には "The ultimate goal of this project is to replace the C implementation." とあります（[LKML のミラー](https://lkml.rescloud.iu.edu/2311.0/00632.html)の写し）。

### 型で守るという設計

Rust 版の追加コミットは、型システムで構造体やポインタの所有権を表すことで、オブジェクトの寿命の管理をプログラマーの手から外し、"reducing the risk of use-after-frees and similar problems" と説明しています。たとえば、[ListArc](https://github.com/torvalds/linux/blob/master/rust/kernel/list/arc.rs) は、リストの `next` と `prev` を操作する権限を表す型で、"By ensuring that each object has only one `ListArc` reference, the owner of that reference is assured exclusive access to the `next`/`prev` pointers." と書かれています。守る手段は、型による制約と、実行時の追跡の組み合わせです。「リスクを減らす」であって、解放後利用が起きなくなるという保証ではありません。

1節の Wasmtime の `debug_assert!` と見比べると、書き手の見方としては、検査が本番のビルドでも残るかどうかが、安全装置の差になります。型の制約も、実行時のフラグによる追跡も、リリースビルドで消えません。

### 誰に影響があるか

Android カーネルをビルドする側は、Kconfig に注意が要ります。[Kconfig](https://github.com/torvalds/linux/blob/master/drivers/android/Kconfig) の現在のシンボルは `CONFIG_ANDROID_BINDER_IPC_RUST` で、`depends on RUST` と `default n` が付いています。削除コミットで一度 `ANDROID_BINDER_IPC` に統合され、同じ日の[後続コミット](https://github.com/torvalds/linux/commit/315860c4f912990c75ef228775ea8871fc5bcc9a)で `_RUST` に戻されました。C 版のファイルが無くなったので、それに当てていたメーカー独自のパッチは、そのままでは当たりません。

一般の Android 利用者は、操作は要りません。

動画の訂正はありません。

## 4. OpenSSL 4.1.0 — DTLS の待ち受けの穴2件を、正式版の前に直した

OpenSSL 4.1.0 の[正式版](https://github.com/openssl/openssl/releases/tag/openssl-4.1.0)は、GitHub の公開が UTC の10月23日 12:23（日本時間 21:23）です。リリースノートの新機能の先頭は、"Support for DTLS 1.3 ([RFC 9147])." で、RFC 9147 は2022年4月に出ています。RFC から正式版の対応まで、4年以上かかった計算です。

### 影響の範囲

今回の2件は、4.1 で追加された DTLS のリスナー（待ち受けの仕組み）の問題です。[Issue #33173](https://github.com/openssl/openssl/issues/33173) には、"It isn't in 4.0 or earlier because there's no DTLS listener there." とあり、4.0 以前は対象外です。影響を受けるのは、修正前の 4.1 系のテスト版（beta2 など）で、DTLS のリスナーを使う場合です。4.1.0 は修正済みです。2件とも、Issue の報告者は "I don't think this needs a CVE" と書いており、CVE は付いていません。

報告では、DTLS 1.2 でも 1.3 でも再現しました。DTLS 1.3 固有の穴ではありません。

### 順序 — 報告が先、beta2 はその後

10月9日の順序は、次のとおりです。Issue #33172 の作成が UTC の8:08（日本時間 17:08）、#33173 が 8:12 で、beta2 の GitHub Release の公開は 12:22（日本時間 21:22）です。openssl-project の[告知](https://groups.google.com/a/openssl.org/g/openssl-project/c/eUzMAeA_dqA)は、"We did not want to release 4.1.0 with known security issues in the new implementation." "For that reason, we have released 4.1.0-beta2 instead." と書いています。つまり、報告を受けて、4.1.0 の代わりに beta2 を出した流れです。

### 2件の中身

- [#33172](https://github.com/openssl/openssl/issues/33172) は、accept キューに上限がない問題です。`SSL_VALUE_DTLS_LISTENER_MAX_PENDING_CONNS`（既定 256）は、ハンドシェイク中の接続の表にしか掛かっておらず、cookie の検証を通った接続は、長さの検査なしで accept キューに入ります。30秒の `pending_timeout` も、この表しか見ません。報告者の実測では、上限を16にして DTLS 1.3 でキューが 568 から 643 件に達し、約 83 から 94MB が保持されました（ローカルの UDP で、サーバーが accept しない条件）。DTLS 1.2 は 245 件、約 31MB です
- [#33173](https://github.com/openssl/openssl/issues/33173) は、接続ごとの受信キューに、件数もバイト数も上限がない問題です。報告者は、1バイトのデータグラムごとに 2,126 バイトが残ると測り、約2000倍の増幅だと書いています。64バイトのデータグラムを約100万個、約 64MB 送ると、27秒で約 2.2GB のヒープが残りました（ループバックで、攻撃側の接続を読まず、別のクライアントで demux を動かし続ける構成）

### 10月14日の修正

10月14日（UTC、日本時間でも同日）に、master へ3つのコミットが入り、2件の Issue は同じ日に閉じました。報告から5日後です。

- [8628bb9f2136](https://github.com/openssl/openssl/commit/8628bb9f21365f3c448b3e08cef337992027587c) は、`SSL_VALUE_DTLS_LISTENER_MAX_PENDING_CONNS` を、待ち受けの2つの表（ハンドシェイク中と accept キュー）を合わせた単一の枠にしました
- [497bdda39a8b](https://github.com/openssl/openssl/commit/497bdda39a8bbd293d44f0454c0be620c11cc8c2) は、接続ごとの受信キューを、128データグラム（件数）で制限します。バイト数の上限ではありません
- [8a57e59db7b5](https://github.com/openssl/openssl/commit/8a57e59db7b51258e3c9fec8359c90b85b4d5f2c) は、demux のフリーリストに上限を設けました

コミット本文によれば、accept キューの項目は、引き続き期限切れにはなりません。バックポートは 4.1 ブランチにも入り、`openssl-4.1.0` に含まれます。

### 正式版にも残る既知の問題

4.1.0 のリリースノートは、"Known issues in 4.1.0" に4件を挙げており、いずれもセキュリティの記述はなく、10月27日朝の時点で未解決（open）です。

- #32878 は、DTLS 1.3 で KeyUpdate を受け取ると、再送バッファから他のハンドシェイク後のレコードが消える問題です
- #33242 は、サーバーの最初のフライトの一部を先に ACK すると、`unexpected_message` で中断する問題です
- #33277 は、DTLS のリスナーで永続的な受信失敗が `SSL_ERROR_WANT_READ` として報告されうる問題です。アプリケーションは、永続的な失敗のあとも待ち続けるかもしれません
- #33278 は、DTLS のリスナーから accept した非ブロッキングの接続で、再試行可能な書き込みの失敗が `SSL_ERROR_SYSCALL` として報告されうる問題です。アプリケーションがこれを致命的なものとして扱うと、使える接続を閉じてしまうことがあります

OpenSSL の[ロードマップ](https://openssl-library.org/roadmap/)によれば、4.1 は Non-LTS で、サポートは2027年11月23日までです。次の LTS は 4.2 で、2027年4月ごろの見込みです。ロードマップ自身が "Release dates are subject to change." と書いているので、日付は見込みのままです。beta2 を使っていた人は、4.1.0 へ上げます。なお、DTLS の実装の穴は、[10月1日の記事](https://blog.fuga.jp/posts/2026-10-01-linux-oss-trend/)でも、別の版（4.0.3）の話として取り上げました。

動画の訂正です。

- 動画では、「ベータ2が出たのは10月9日でした。その当日に、外部の研究者が、セキュリティの問題を2件報告した」と紹介し、画面にも「ベータ2 当日にセキュリティ問題 2件」と出しました。日付は同じ10月9日ですが、順序は、報告（UTC の8:08 と 8:12）が先で、beta2 の公開（12:22）が後です。openssl-project の告知も、既知のセキュリティ問題がある 4.1.0 の代わりに beta2 を出した、と書いています。放送の言い方だと beta2 のあとに報告があったように聞こえるため、順序を補います。詳しくは、[Issue #33172](https://github.com/openssl/openssl/issues/33172)、[Issue #33173](https://github.com/openssl/openssl/issues/33173)、[beta2 のリリース](https://github.com/openssl/openssl/releases/tag/openssl-4.1.0-beta2)で確認してください。

## 5. PHP2Shell のその後 — 攻撃の観測と、CYFIRMA・Unit 42 の報告

PHP2Shell の第一報は、[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)で扱いました。ここでは、その記事以降に一次の資料で確認できた点を書きます。CVE-2026-109618（[GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)）と CVE-2026-109619（[GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)）は、10月21日に出た 8.2.35、8.3.36、8.4.27、8.5.12 で修正されています。[php.net の告知](https://www.php.net/archive/2026.php)は、すべての PHP ユーザーに、すぐに更新するよう強く勧めています。

### 深刻度の整理

10月22日の記事は、CVSS v4.0 の 9.2 を書きました。NVD の API では、1件目の CVE-2026-109618 の CVSS v3.1 は NVD（NIST）の評価で 9.8（Critical）、2件目の CVE-2026-109619 は同じく NVD の評価で 8.1（High）です。v4.0 は、2件とも PHP 側（security@php.net）の評価で 9.2 です。

### 攻撃の入口

GHSA-w8hw によれば、1件目は、multipart の解析に問題があり、宣言された長さのない multipart リクエストや、1パートに無制限のヘッダー、空のファイル入力欄などで、見かけ上の PHP の制限を守ったまま OOM に到達しうるというものです。

セッションのアップロード進捗は、2件目の経路として GHSA-6wmf に書かれています。"Session upload progress is enabled by default, and no application call to `session_start()` is required." とあり、`session.upload_progress.enabled` の既定値は、[php.net のマニュアル](https://www.php.net/manual/en/session.configuration.php)で 1 です。watchTowr も、この機能を2件目の確認済みの経路の1つとしています。対象は、php.net によれば、Web のリクエストを処理するすべての PHP で、PHP-FPM、Apache の mod_php、php-cgi、FrankenPHP、LiteSpeed を含みます。コマンドラインだけで動かす PHP が対象外とは、一次では確認できませんでした。

Palo Alto Networks の [Unit 42](https://unit42.paloaltonetworks.com/cve-2026-109618-cve-2026-109619/) は、Cortex Xpanse が、公開されていて脆弱な可能性のあるインスタンスを 2,260万件以上確認したと書いています。原文は "potentially vulnerable" で、パッチ未適用の台数ではありません。

### 攻撃の時系列（一次の情報）

- 10月17日（土）。Amazon の[セキュリティブログ](https://aws.amazon.com/blogs/security/amazon-threat-intelligence-identifies-php2shell-exploitation-prior-to-public-disclosure-in-madpot/)（10月21日付）は、"Amazon Threat Intelligence identified a PHP2Shell exploitation attempt dating to Oct. 17, 2026" と書いています。同じ文書は、これらの試みが実環境で成功しえたかは "unclear" とも書いています。修正版が出る4日前の試みです
- 10月21日の UTC 3:02（日本時間 12:02）から、[Cloudflare](https://blog.cloudflare.com/php-vulnerabilities-waf-protection/) の WAF は、無料プランを含めて既定で保護を始めています。Cloudflare は、これが "about 9 hours ahead of public disclosure" だったと書いています。数字は Cloudflare の言い方のままです
- 10月21日に、[watchTowr](https://watchtowr.com/intelligence/php-remote-code-execution-php2shell/) のハニーポット網が、2件の CVE への実環境の悪用を観測したと書いています。投稿は UTC の14:19（日本時間 23:19）です

10月22日の記事は、Huntress が10月21日の米国東部時間16:30時点で、自社のパートナー環境では悪用を観測していないと書きました。観測した組織と範囲が違うので、矛盾ではありません。観測は「悪用の試み」や「悪用を観測」までで、被害の規模を示す資料ではありません。

### CYFIRMA の報告

[CYFIRMA](https://www.cyfirma.com/research/cyfirma-threat-advisory-suspected-dprk-campaign-staging-php2shell-targeting-against-global-php-infrastructure/) は、自社の文書で、"Korean-speaking operators have filtered a 216-host target set" と書いています。216台は、運営者側が絞り込んだ標的リストです。リストそのものについて CYFIRMA は、"has not been seen"（見ていない）と書いています。すでに手を付けていた（touched）のは、運営者側の見積もりで、約3分の1です。

確度は、文書の中で表現が分かれています。更新の要約は、北朝鮮の国家関連の行為者について HIGH と書いています。一方で、運営者が北朝鮮の国家支援の脅威とつながっているという評価は moderate（中程度）で、Lazarus 系との関連も moderate です。同じ文書は、"Language alone is not attribution" とも書き、韓国語を話す犯罪グループの可能性を排除していません。出典は、運営者側の閉じた I2P のチャンネルからの抜粋です。この記事では、攻撃の主を断定しません。CYFIRMA の文書の公開日は版によって異なり、216台は10月24日の版の内容です。

### Unit 42 の取り下げ

Unit 42 のページの更新履歴（米国太平洋時間）によれば、10月23日 12:30（日本時間 10月24日 4:30）に、攻撃後の活動の詳細を追加しました。そして10月25日 14:15（日本時間 10月26日 6:15）に、この追加を取り下げています。ページは、"We are unable to confirm that initial access is associated with the specific PHP2Shell CVEs." と書いています。取り下げられた内容は、この記事では書きません。

### WAF と 8.1 以下

Cloudflare は、WAF の保護があっても、PHP を更新するよう書いています。原文は "Customers should patch their PHP repos even with WAF protections providing an additional layer of defense-in-depth mitigation." です。Cloudflare によれば、`session.upload_progress.name` を変えている場合は、WAF のルールの対象外です。

追記です。10月22日の記事は、Cloudflare が WAF について "STOPGAP only" と書いた、と紹介しました。動画の作成時には確認できましたが、10月27日の確認時点では、[Cloudflare のブログ](https://blog.cloudflare.com/php-vulnerabilities-waf-protection/)に該当の記載が見当たりません。ページが書き換わったのか、別の場所に移ったのかは、こちらでは判断できていません。当時の記述は[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)にあり、Cloudflare の最新の記載は、上のページで確認してください。この記事の WAF の説明は、現在のページにある表現に沿っています。

なお、php.net も、更新だけが完全な解決策で、軽減策は特定の経路への露出を減らしても、環境を安全にはしないと書いています。

8.1 以下は、php.net によれば、PHP プロジェクトからの更新を受けられません。ただし、PHP セキュリティチームは、7.4、8.0、8.1 向けに、ソースからビルドする人のための最小限のバックポートを提供しています。修正が出ていないのは、5系と 7.3 以前です（10月22日の記事と同じ整理です）。パッケージで入れている場合は、ディストリビューションや LTS ベンダーの提供状況を確認します。

### php.net の10月23日の別の告知

php.net は10月23日に、別の告知（"Informational advisory: Session upload progress"）を出しました。CVE-2026-115560 についてで、"The issue can only occur under an unusual combination of configuration and application code." と書いています。アプリケーションが `session.serialize_handler` を `php_binary` か `php_serialize` に設定し、実行時に `ini_set()` で `php` に切り替えてから `session_start()` を呼ぶ、という条件です。php.net は、次の定期リリースまで `session.upload_progress.enabled=0` にするよう勧めています。Cloudflare は、8.5.12 を含む修正済みの版にも影響すると書いています。NVD には、10月27日の確認時点で、この CVE は未登録でした。

### まず確かめること

- `php -v` で版を確かめ、8.2.35、8.3.36、8.4.27、8.5.12 以降に更新します
- GHSA-6wmf は、セッション機能の経路について、`session.upload_progress.enabled=0` を設定し、すべてのワーカーを再起動するよう書いています。アップロードの進捗を使っていなければ、この設定を検討します

動画の訂正です。

- 動画では、「8.1以前は、サポートが終わっているので公式の修正は出ません」「公式の修正が出ない以上、移行の計画をとにかく前倒しするしかありません」と紹介し、画面にも同じ趣旨を出しました。8.1 以下に PHP プロジェクトから通常の修正版が出ないのは、そのとおりです。ただし PHP セキュリティチームは、7.4、8.0、8.1 向けに、ソースからビルドする人のための最小限のバックポートを提供しました。修正が出ていないのは、5系と 7.3 以前です（[php.net の告知](https://www.php.net/archive/2026.php)）。
- 動画では、1件目について「ファイルのアップロードの進み具合を伝える機能を使って、外から狙って作り出せる」と紹介し、その機能が最初から有効だと説明しましたが、GHSA に書かれたアップロード進捗の経路は、2件目の CVE-2026-109619 のものです。1件目の CVE-2026-109618 の誘発手段として GHSA が挙げるのは、multipart の解析の問題で、説明に upload_progress の語はありません（[GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)、[GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)）。
- 動画では、北朝鮮との関連が疑われるグループが「216台のサーバーを調べて回っていた」と紹介し、画面にも「216台スキャン」と出しましたが、216台は運営者側が絞り込んだ標的リストで、CYFIRMA 自身は一覧を見ていません。すでに手を付けていたのは、運営者の見積もりで約3分の1です（[CYFIRMA](https://www.cyfirma.com/research/cyfirma-threat-advisory-suspected-dprk-campaign-staging-php2shell-targeting-against-global-php-infrastructure/)）。
- 動画では、「CYFIRMA 自身が、確度は中程度としています」と紹介し、画面にも「確度は中程度」と出しましたが、CYFIRMA の文書は、評価ごとに確度を分けています。更新の要約は、北朝鮮の国家関連の行為者という評価を HIGH とし、運営者と北朝鮮の国家支援の脅威とのつながり、Lazarus 系との関連は moderate としています。同じ文書は "Language alone is not attribution" とも書いています。文書は版を重ねているため、最新の評価は CYFIRMA の文書で確認してください。

## まとめ

Wasmtime は、36.0.19、50.0.0 以降（aarch64 を使うなら 48.0.7、49.0.4 以降）へ更新します。アドバイザリに回避策の記載はありません。ZDI の6件は、KSMBD を有効にしている環境と、ローカルのユーザーがいるシステムで状況を確かめます。Binder の C 版は、mainline から消えました。OpenSSL 4.1.0 は、DTLS のリスナーの穴を正式版の前に直しましたが、既知の問題が4件残っています。PHP2Shell は、修正版への更新が基本で、WAF は追加の層にとどまります。

5本に共通する「安全装置が、どこで、どの条件で効いているか」という見方は、書き手の考察です。Wasmtime の検査はリリースビルドで消え、OpenSSL のリスナーには上限の掛からないキューが残っており、KSMBD は既定で動かないことが守りになっていました。Binder は、守る約束を型で表す方向へ変わり、PHP の WAF は、更新の代わりにはなりません。

まず確かめることを挙げます。

- PHP の版を `php -v` で確かめ、8.2.35、8.3.36、8.4.27、8.5.12 以降に更新する。8.1 以下は、ソースビルド向けのバックポートか、ディストリビューションの提供状況を確かめる
- 依存関係の中の Wasmtime の版を `Cargo.lock` などで確かめ、36.0.19、50.0.0 以降に更新する。aarch64 なら 48.0.7、49.0.4 以降も候補になる
- KSMBD を有効にしていないかを確かめ、不要なら止める。ユーザー名前空間を無効にする場合は、rootless コンテナや Flatpak への影響を確かめる
- Android カーネルをビルドする側は、Kconfig の `CONFIG_ANDROID_BINDER_IPC_RUST` と Rust のビルド環境を確かめる
- OpenSSL 4.1 の beta2 を使っていたなら、4.1.0 へ上げ、既知の問題4件を確かめる

## 参考リンク

- [Wasmtime の GHSA-897f-g5gm-fmxm（CVE-2026-115889）](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-897f-g5gm-fmxm)
- [Wasmtime の GHSA-mghf-wjfp-p5xm（CVE-2026-115893）](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-mghf-wjfp-p5xm)
- [ZDI-CAN-33774 の元メール（linux-kernel）](https://lists.openwall.net/linux-kernel/2026/10/21/2694)
- [ZDI-CAN-33367 の元メール（netdev）](https://lists.openwall.net/netdev/2026/10/21/605)
- [TuxCare の分析](https://tuxcare.com/blog/zdi-ksmbd-bugs-cve/)
- [Binder の C 版を削除したコミット](https://github.com/torvalds/linux/commit/fd2bc059ed466bdd95347a4f7891d150d94e7de2)
- [OpenSSL 4.1.0 のリリースノート](https://github.com/openssl/openssl/releases/tag/openssl-4.1.0)
- [php.net のセキュリティ告知](https://www.php.net/archive/2026.php)
- [Amazon のセキュリティブログ（PHP2Shell）](https://aws.amazon.com/blogs/security/amazon-threat-intelligence-identifies-php2shell-exploitation-prior-to-public-disclosure-in-madpot/)
- [Unit 42 の PHP2Shell の解説](https://unit42.paloaltonetworks.com/cve-2026-109618-cve-2026-109619/)

（2026/10/27 Linux・OSSトレンド）
