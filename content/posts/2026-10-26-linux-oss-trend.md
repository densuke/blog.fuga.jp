---
title: "Nextcloud の内蔵オフィスに KEV 入りの穴、systemd が Rust を受け入れ、OBS Studio 33.0 の CEF 更新、Wild 0.11 がカーネルモジュールをリンク、Node2Shell の修正版（2026/10/26 Linux・OSSトレンド）"
date: 2026-10-26T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Nextcloud", "systemd", "Rust", "OBS Studio", "リンカー", "Node.js"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

便利な「全部入り」の製品ほど、中に何が同梱されているかは見えにくくなります。今回の5本は、その同梱物を知っておく話として読めます。Nextcloud の内蔵オフィスの穴は、米国の連邦機関に課された対策の期限が10月26日（月）です。systemd は、何を入れないかを決めてから Rust を受け入れました。OBS Studio 33.0 はブラウザ部品の Chromium が 127 から 150 になり、Wild 0.11 は Linux カーネルモジュールをリンクできるようになりました。Node.js に同梱された Brotli には、Node2Shell と呼ばれる脆弱性の修正版が出ています。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "85Chr_kxMd8" >}}

## 1. Nextcloud の内蔵 CODE Server — CVE-2026-110447 が KEV 入り、連邦機関の期限は10月26日

Nextcloud 用のアプリ Collabora Online - Built-in CODE Server（パッケージ名 richdocumentscode）に、認証なしで OS コマンドを実行できる脆弱性が見つかりました。番号は [CVE-2026-110447](https://nvd.nist.gov/vuln/detail/CVE-2026-110447) です。

### 深刻度と KEV 入り

- CVSS v4.0 は 9.2（Critical）です。NVD に載っている採点は、CVE レコードの側（CNA は MITRE）で付けられたもので、NVD 自身の採点ではありません。Collabora 自身の[アドバイザリ](https://github.com/CollaboraOnline/online/security/advisories/GHSA-g3vx-3m76-fghh)にも、同じ CVSS v4.0 で 9.2 が書かれています
- アドバイザリの題名は "Unauthenticated OS command injection in the richdocumentscode proxy" で、認証は要りません。NVD の説明文は "as exploited in the wild in September and October 2026" と書いており、実際の攻撃がすでにあります
- CISA の [KEV カタログ（JSON）](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)には、`dateAdded` が 2026-10-23、`dueDate` が 2026-10-26 で載っています。10月23日は米国の日付で、カタログの更新は UTC 19:30、日本時間では10月24日 4:30 です
- 期限は、連邦文民行政部門（FCEB）の機関に対するものです。[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) は対象をそう定めており、民間の事業者や個人の期限ではありません

### 対象になるもの

NVD の説明文は、Collabora Online Built-in CODE Server の 26.4.303 より前の版を対象とし、"The vulnerability is not present in standalone Collabora Online servers" と書いています。Collabora Online を独立したサーバーとして立てている構成は対象外です。このアプリは、Nextcloud と同じマシンの上で変換サーバーを動かす仕組みで、アプリ自身の説明は "for local testing and non-production use"（ローカルでのテストと非本番用途）です。

### どこが突かれるか

入口は proxy.php です。NVD の説明文は "This is an OS command injection in proxy.php when the CODE server isn't running" と書いています。つまり、変換サーバーが動いていない間だけ成立します。アドバイザリによれば、停止が生まれるのはコンテナの再起動、アップグレード、クラッシュのときです。

26.4.303 の[差分](https://github.com/CollaboraOnline/richdocumentscode/compare/26.4.302...26.4.303)を見ると、変換サーバーを起動するコマンドの組み立てに escapeshellarg が使われるようになっています。攻撃は Web サーバーのユーザーの権限で実行されます。

### 攻撃の痕跡

GitHub の [issue #354](https://github.com/CollaboraOnline/richdocumentscode/issues/354) で、ある管理者が被害を報告しています。そこに貼られたサーバーのログで最も古い攻撃は、`10/Sep/2026:19:51:52 +0200` です。これは UTC+2 で書かれた時刻で、日本時間に直すと9月11日 2:51 にあたります。修正版 26.4.303 の[リリース](https://github.com/CollaboraOnline/richdocumentscode/releases/tag/26.4.303)は、UTC の9月11日 13:43（日本時間 22:43）です。この「最初の日」は、この issue の報告者のログの範囲での話です。

置かれていたのは Web シェルとみられる PHP ファイルで、報告された名前は shrf4645.php、shxa35d0.php など、`shx*.php` に限りません。同じ issue は、攻撃者が資格情報や暗号資産に関わるファイルを探すコマンドを実行したと書く一方、確認したリクエストの中に、ファイルを固めて外へ送り出すコマンドは見当たらなかったとも書いています。Censys は、2026年10月16日の時点で、このアプリを入れたホストを 19,454 件検出したと[書いています](https://censys.com/advisory/cve-2026-110447)。

### 対策

- Nextcloud 30 以上は、管理画面から richdocumentscode を 26.4.303 以上へ更新します。Nextcloud の[アプリストア](https://apps.nextcloud.com/apps/richdocumentscode)で、26.4.303 は Nextcloud 30 以上、35 以下に対応しています
- Nextcloud 29 以前（サポート切れ）は、アドバイザリによれば、Nextcloud を更新するか、このアプリを削除します。26.4.303 は Nextcloud 29 では動きません
- アプリを無効にするだけでは足りません。アドバイザリは "It is not sufficient to disable the app to avoid the problem, it must be upgraded to >= 26.4.303 or removed." と書いています。理由はアドバイザリにはありませんが、WZ-IT の[解説](https://wz-it.com/en/blog/nextcloud-built-in-code-server-cve-2026-110447-rce-webshell/)は、無効にしてもファイルが外から届く場所に残るためだと説明しています
- 侵害の確認は、Nextcloud の apps ディレクトリ（`apps_paths` の設定先）にある richdocumentscode の中に、見覚えのない PHP ファイルがないかを見ます。`shx*.php` 以外の名前もあります。Nextcloud 公式の[整合性チェック](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html)の `occ integrity:check-app richdocumentscode` も手がかりになります
- 見つかった場合、issue #354 の報告者は、Web サーバーのアカウントで読めるデータや秘密は、漏えいや改ざんの可能性があるものとして扱うよう書いています。書き手としても、データベースのパスワードなどの認証情報を入れ替えることを勧めます

動画の訂正です。

- 動画では、KEV の期限が追加から3日というのを「異例の短さです」と紹介しましたが、3日は現在の KEV では標準的な期限です。CISA の KEV カタログ（JSON）の `dateAdded` と `dueDate` から数えると、BOD 26-04 が出た2026年6月10日以降に追加された139件のうち113件が3日で、10月に追加された26件のうち23件が3日です。BOD 26-04 は forensic triage の対象に3日の期限を定めており、この CVE のエントリもその区分です。3日であること自体が、この CVE の攻撃の激しさを示すわけではありません（[KEV カタログ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)、[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)）。
- 動画では、Nextcloud 29 以前の場合を「アプリを完全にアンインストールするしかありません」と紹介しましたが、Collabora のアドバイザリは "Users of EOL Nextcloud <= 29 should upgrade their Nextcloud or remove this app." と書いており、Nextcloud 自体を更新する選択肢もあります（[アドバイザリ](https://github.com/CollaboraOnline/online/security/advisories/GHSA-g3vx-3m76-fghh)）。

## 2. systemd が Rust で書いたプログラムのビルドに対応 — PR #44324 が10月24日にマージ

systemd は、Rust で書いたプログラムをビルドできるようにする変更を、[PR #44324](https://github.com/systemd/systemd/pull/44324) で main に取り込みました。マージは UTC の10月24日 6:21（日本時間 15:21）で、題名は "rust: support programs written in Rust" です。Rust 対応は任意で、PR の説明によれば `-Drust=` の既定は auto です。この時点でマージされた Rust 製プログラムはまだありません。

### 5つの制約

PR の説明と、マージ時点の [CODING_STYLE.md](https://github.com/systemd/systemd/blob/021112961bd64aec54a1f1e6a6c8fda8b732b705/docs/CODING_STYLE.md) から、制約を5つ挙げます。

1. Cargo は使いません。PR の説明は "No cargo. Everything is built with meson." と書いています。Meson は、systemd が以前から使っているビルドシステムです
2. 外部のクレートは使いません。Rust のコードは `no_std` で、リポジトリの中にある `systemd_shared` クレートが共通の部品を提供します
3. 使ってよい標準のクレートも絞られています。PR の説明は "Only the core, alloc and libc crates." と書く一方、同じ説明が "like the kernel we don't use alloc either" とも書き、CODING_STYLE.md は "Only the `core` and `libc` crates are permitted. `std`, `alloc` and any other crate are not" と書いています。マージされた規則では alloc は禁止です
4. systemd の他の部分とは C リンケージだけでつなぎます
5. Rust を使うのは、他から依存されない新しい独立プログラム（leaf component）だけです。既存の C コードは、CODING_STYLE.md によれば当面は Rust に書き換えません

### 慎重な設計になった経緯

提案者は Christian Brauner 氏で、最初の提案は RFC の [PR #43551](https://github.com/systemd/systemd/pull/43551)（8月27日、UTC）でした。10月20日（UTC）に閉じられ、#44324 に出し直されています。PR #44324 の説明は、メンテナーが Berlin のハッカソンで合意した方針に沿って作り直したものだと書いています。

#43551 では、次の懸念が出ていました。

- Cargo と crates.io の依存関係をたどるサプライチェーンの問題と、ビルド時に任意のコードが走る build.rs の仕組みです。GitHub ハンドル bluca の[コメント](https://github.com/systemd/systemd/pull/43551#issuecomment-5445121831)にあります。crates.io は Cargo の既定のレジストリで、build.rs は Cargo がビルドの直前に実行するスクリプトです
- 共有ライブラリのサポートがないことです。GitHub ハンドル daandemeyer の[コメント](https://github.com/systemd/systemd/pull/43551#issuecomment-5449592164)は、これを大きな問題だと書いています。bluca は、標準ライブラリに安定した ABI がないことを挙げています
- Cargo の文化への懸念です。Lennart Poettering 氏は[コメント](https://github.com/systemd/systemd/pull/43551#issuecomment-5660679501)の冒頭で Rust の採用には概ね賛成の立場を示したうえで、"I am concerned about Cargo's ecosystem and culture" と書き、"I have serious issues with accepting that for systemd" と続けています。さらに、PR が Cargo を認めない形なら "I guess I could get behind that" とも書いています

同じ日の次のコメントで氏は、"no crates for now, as long as the culture is how it is"（文化が今のままの間はクレートを使わない）ことと、共有ライブラリの境界をすべて C にすることを提案しています。今回の制約は、この懸念を踏まえた形といえます。

### 安全面と大きさ

[HACKING.md](https://github.com/systemd/systemd/blob/021112961bd64aec54a1f1e6a6c8fda8b732b705/docs/HACKING.md) によれば、`systemd_shared` の `Box` と `Vec` は、メモリの確保に失敗するとエラーを返します。鍵やパスフレーズ用には、解放や移動の前にメモリを消去する Erasing アロケーターがあります。プログラムは `-C panic=abort` と、整数オーバーフローの検査を有効にしてビルドされます。

大きさは、出典によって数値が違います。PR の説明文では、ストリップ後の test-cli-rust が LTO ありで 32 KB、C 版が 20 KB です。同じ PR が追加した HACKING.md では、test-cli-rust が 29 KB（LTO ありで 24 KB）、C 版が 16 KB で、文書は "not much bigger" と説明しています。

### 第1号と、読者に関わる範囲

第1号の Rust 製プログラムとして予定されている systemd-keyring-setup は、[PR #44114](https://github.com/systemd/systemd/pull/44114) の説明によれば、起動時に X.509 証明書をカーネルのキーリングに登録します。2026年10月26日の確認時点で、この PR は未マージです。PR の説明は、このサービスを既定では有効にしないと書いています。v263 に入るかどうかは、一次資料では確認できませんでした。Rust 対応のビルド基盤そのものは、[NEWS](https://github.com/systemd/systemd/blob/main/NEWS) の "CHANGES WITH 263 in spe" に載っています。

一般のユーザーは、Rust 製のプログラムが出荷されて各ディストリビューションが対応するまで、変化はほぼありません。パッケージを作る側は注意が要ります。PR の説明は、Arch と openSUSE の OBS（Open Build Service）のビルドが、`--auto-features=enabled` でビルドしているのに rustc と bindgen を引き込まないため失敗すると書き、`-Drust=disabled` にするか、両方をビルド依存に加えるよう求めています。NEWS によれば、Rust 対応には rustc 1.85 以上と bindgen 0.71.1 以上が要ります。

動画の訂正です。

- 動画では、使える基本部品を「coreとallocとlibcの3つに絞る」と紹介し、画面にも「core / alloc / libc のみ」と出しましたが、マージされた CODING_STYLE.md は core と libc のみを許可し、alloc は禁止しています。PR の説明も、alloc は使わないと書いています（[CODING_STYLE.md](https://github.com/systemd/systemd/blob/021112961bd64aec54a1f1e6a6c8fda8b732b705/docs/CODING_STYLE.md)、[PR #44324](https://github.com/systemd/systemd/pull/44324)）。

## 3. OBS Studio 33.0 — ブラウザ部品 CEF が Chromium 127 から 150 へ

[OBS Studio 33.0.0](https://github.com/obsproject/obs-studio/releases/tag/33.0.0) の安定版は、GitHub の公開が UTC の10月23日 22:20、日本時間では10月24日 7:20 です。前の 32.2.0 は[7月23日の記事](https://blog.fuga.jp/posts/2026-07-23-linux-oss-trend/)で取り上げました。

### CEF の更新

ブラウザソースを描画しているのは、Chromium を他のアプリに組み込むための CEF（Chromium Embedded Framework）です。リリースノートは "Updated CEF from 127/6533 to 150/7871" と書いています（[PR #13900](https://github.com/obsproject/obs-studio/pull/13900)、UTC の2026年9月18日にマージ）。

Chromium 127 の安定版は[2024年7月23日](https://chromiumdash.appspot.com/fetch_milestone_schedule?mstone=127)、Chromium 150 の安定版は[2026年6月30日](https://chromiumdash.appspot.com/fetch_milestone_schedule?mstone=150)で、約1年11か月の差です。リリースノートは "from the July 2024 release to September 2026" と書いていますが、これは OBS に取り込まれた時期まで含めた言い方です。

更新が滞っていた理由は、OBS の [Discussion #3853](https://github.com/obsproject/obs-studio/discussions/3853) に説明があります。OBS 31（2024年12月）は Chromium 127 でした。CEF 128 で Chromium runtime が既定になり、従来の Alloy runtime が完全に削除されたため、OBS は Chrome Runtime への対応が必要でした。同じ場所で、WizardCM 氏は "Thanks to fantastic work by @reitowo and others" と書き、共有テクスチャの実装などの貢献に触れています。[obs-browser PR #523](https://github.com/obsproject/obs-browser/pull/523) は、CEF/Chrome の 128 から 150 までに完全に対応したと書いています。

リリースノートは、これを "a massive update to the underlying framework used for browser sources and docks" と呼び、"All of this work is on the backend and should be invisible to users" と書いたうえで、"Please be sure to report any new weirdness or problems you run into with browser sources!" と呼びかけています。リリース候補は3回で、rc1 が UTC の10月9日、rc2 が10月16日、rc3 が10月20日です。新しい JavaScript・CSS・WebRTC の機能が使えるようになる、という説明はリリースノートにはありません。Chromium が更新される以上、ブラウザソースで使える Web 技術も新しくなる、というのは書き手の説明です。

大事な配信の前は、手元でオーバーレイの表示を確かめてから更新するのが無難です。戻す場合の候補は、直前の安定版の 32.2.2（UTC の8月14日公開）です。これは公式の推奨ではなく、書き手の助言です。設定のバックアップも忘れずに取ります。

### ARM64 Windows の NVENC

リリースノートは "Enabled NVENC on Arm64" と書いています（[PR #13827](https://github.com/obsproject/obs-studio/pull/13827)）。PR の作者が動作を確かめたのは Windows on Arm です。32.2.2 の時点では、ビルドの設定で NVENC が x64 に限られていました。NVENC のプラグインには H.264・HEVC・AV1 の項目がありますが、使えるコーデックは GPU によって変わります。GPU のエンコーダーに任せられるようになるのは、ARM 版 Windows に NVIDIA の GPU がある場合です。

### プラグインの置き場所

リリースノートは、プラグイン読み込みの全面的な見直しとして、公式のプラグインを core という新しいフォルダに置き、他者製のプラグインは配置場所とフォルダ構成が変わると書いています。[Knowledge Base](https://obsproject.com/kb/legacy-plugin-locations) によれば、Windows の新しい配置は `C:\ProgramData\obs-studio\plugins\example-plugin\example-plugin.dll` で、旧来の配置は `bin\64bit\` の下に置く形です。旧来の場所のプラグインは、リリースノートによれば OBS Studio 34.0 になるまで（"until OBS Studio 34.0"）読み込まれ、プラグインマネージャーに Legacy と表示されます。KB は macOS の配置は変わらず、Linux は "Details coming soon" と書いています。なお KB の冒頭には、現時点では KB へのリンクを控えてほしいという注意書きがあります。

開発者向けには、libnsgif が 1.0.0 になり、gs_image_file を使うプラグインに修正が必要な破壊的変更が入っています。Linux では、"Removed support for Ubuntu 24.04" とあり、33.0.0 の公式の Ubuntu 向け .deb は 26.04 用だけです。

動画の訂正です。

- 動画では、Chromium の更新を「2024年7月ごろから2026年9月ごろまで、約2年3か月分」と紹介し、画面にも「2024年7月 → 2026年9月 相当」と出しましたが、Chromium 127 の安定版は2024年7月23日、Chromium 150 の安定版は2026年6月30日で、間は約1年11か月です。OBS のリリースノートの "July 2024 release to September 2026" は、OBS が Chromium 150 を取り込んだ時期まで含めた言い方です（[Chromium 127](https://chromiumdash.appspot.com/fetch_milestone_schedule?mstone=127)、[Chromium 150](https://chromiumdash.appspot.com/fetch_milestone_schedule?mstone=150)、[PR #13900](https://github.com/obsproject/obs-studio/pull/13900)）。

## 4. Rust 製リンカー Wild 0.11 — カーネルモジュールのリンク、Wasm 標準有効、スレッド上限 32

リンカーは、部品ごとに機械語へ翻訳されたものを、実行できる1つのファイルにまとめる道具です。[Wild 0.11.0](https://github.com/wild-linker/wild/releases/tag/0.11.0) は、UTC の10月24日 4:21（日本時間 13:21）に公開されました。

### 速さの目安

Wild の 0.3.0 の [README](https://github.com/wild-linker/wild/blob/0.3.0/README.md) には、2024年11月30日時点の Wild の測定が載っていました。rustc-driver のリンクが、Wild で 486 ms、mold 2.34.1 で 946 ms、lld 18.1.8 で 1601 ms、GNU ld 2.38 で 20774 ms でした。4コア8スレッドのノート PC で、`--strip-debug` を付けた条件です。この表は、0.11.0 の README にはありません。0.11 の速さではなく、2024年11月の時点の数値です。

この数値で1日に200回リンクすると、GNU ld との差は (20.774 − 0.486) 秒 × 200 回 ≒ 4058 秒、約1.1時間です。これは書き手の試算で、毎回 rustc-driver 級のリンクをする、という前提を置いています。

### 0.11 の変更

- カーネルモジュール。リリースノートは "Wild now supports enough of the linker script syntax that it can link Linux kernel modules and is close to being able to link the Linux kernel itself." と書いています。カーネルのビルドは、[対応表](https://github.com/wild-linker/wild/blob/0.11.0/LINKER_SCRIPT_SUPPORT.md)によれば、リンカースクリプトの豊富な機能を使います。リリースノートには、PHDRS 表の中の FILEHDR / PHDRS（#2314）や、式の中の ASSERT の解析（#2402）などが並びます。カーネル本体は、リリースノートの言葉で "close to being able to link" の段階です
- Wasm。リリースノートは "The Wasm feature is now enabled by default" と書き、デバッグ情報はまだ未対応だと注記しています
- スレッド数。リリースノートは、上書きしない限り 32 に制限し、Linux の inode ごとのロックの競合による性能低下を避けると書いています。[PR #2670](https://github.com/wild-linker/wild/pull/2670) の作者は、64コア128スレッドの EPYC で、32スレッドを超えると改善せず、約40を超えると大きく悪化したと書いています。ロックの種類の記述は、リリースノート（per-inode mutex）と PR（per-inode page cache spinlock）で違います

### プロジェクトの現在地

Wild は、Rust Foundation の告知（[2026年6月30日付](https://rustfoundation.org/media/welcoming-wild-to-the-rust-innovation-lab/)）によれば Rust Innovation Lab に加わり、David Lattimore 氏がリードメンテナーです。開発は AWS が財政面で支えています。0.11.0 のリリースノートは、Rust Innovation Lab 経由の支援者として AWS と OpenAI を挙げています。

GCC は、16.1（2026年4月30日リリース）の[マニュアル](https://gcc.gnu.org/onlinedocs/gcc-16.1.0/gcc/Link-Options.html)に `-fuse-ld=wild` があります。Gentoo と Alpine には Wild のパッケージがありますが、確認した時点の収録版は 0.8.0 でした。

### 誰に向く道具か

Wild の README は冒頭で "a linker with the goal of being very fast for iterative development" と書き、Rust Foundation の告知も、主な目標は開発中の反復の速さだと書いています。手元の開発ループを速くする道具として試すのが向いています。使い方は [USAGE.md](https://github.com/wild-linker/wild/blob/0.11.0/USAGE.md) にあります。

動画の訂正です。

- 動画では、リンカースクリプトに「今回追加された命令には、プログラムヘッダーの配置を指示するPHDRSや、条件を確かめるASSERTなどがあります」と紹介しましたが、PHDRS コマンドも ASSERT 文も 0.10.0 の時点で対応済みです。0.11.0 で加わったのは、PHDRS 表の中の FILEHDR / PHDRS キーワード（#2314）と、式の中の ASSERT の解析（#2402）です（[0.10.0 の対応表](https://github.com/wild-linker/wild/blob/0.10.0/LINKER_SCRIPT_SUPPORT.md)、[0.11.0 のリリースノート](https://github.com/wild-linker/wild/releases/tag/0.11.0)）。
- 動画では「GCC側でもWildに対応するパッチが提案されていて」と紹介しましたが、GCC 16.1（2026年4月30日リリース）のマニュアルにはすでに `-fuse-ld=wild` が載っています。提案段階の話ではなく、取り込み済みです（[GCC 16.1 のマニュアル](https://gcc.gnu.org/onlinedocs/gcc-16.1.0/gcc/Link-Options.html)、[Wild の USAGE.md](https://github.com/wild-linker/wild/blob/0.11.0/USAGE.md)）。
- 動画では「本番のビルドには従来のリンカーを使うよう推奨されています」と紹介しましたが、この趣旨の文言は 0.5.0 の README にあったもので、2025年9月26日のコミットで削除されています。0.11.0 の README、FAQ、USAGE.md に同趣旨の推奨はありません（[0.5.0 の README](https://github.com/wild-linker/wild/blob/0.5.0/README.md)、[0.11.0 の README](https://github.com/wild-linker/wild/blob/0.11.0/README.md)）。

## 5. Node2Shell — Node.js 同梱の Brotli、CVE-2026-111497 の修正版は10月21日

Node.js に同梱された Brotli デコーダーに、範囲外書き込みの脆弱性が見つかりました。番号は [CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497) です。Node.js の[セキュリティリリース](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)は、"A flaw in the Brotli decoder bundled with Node.js allows malformed compressed input to write past the end of an internal decoder buffer." と書き、node:zlib で展開する Brotli データを攻撃者が渡せれば、クラッシュ、プロセスのメモリの漏えい、リモートコード実行につながりうると説明しています。

### 深刻度

NVD の CVSS v4.0 は 9.2（Critical）で、採点者は CVE の発行元の Google（cve-coordination@google.com）です。NVD 自身の分析は、2026年10月26日時点で "Awaiting Analysis" です。Node.js の公式は、重大度を High と書いています。数値と重大度の尺度が違うだけで、矛盾ではありません。この CVSS v4.0 の 9.2 は、1本目の CVE-2026-110447 とは別の採点です。

Node2Shell は、セキュリティ企業 Imperva のレッドチームが付けた名前です。Imperva の[ブログ](https://www.imperva.com/blog/node2shell-from-brotli-data-to-remote-code-execution/)によれば、公式の Node.js 24.22.0 の Linux arm64 イメージで、細工した Brotli データを渡すと、アプリがそのデータの中のコードを実行しました。毎回成功したわけではなく、同じ入力は 24.22.1 では拒否されました。結果はこの環境でのもので、すべてのビルドやアプリを試したわけではないとも書いています。

### 原因

Node.js のセキュリティリリースは、無効なブロックの切り替えが、恒久的なフォーマットエラーではなく、一時的な「入力が足りない」として報告されたため、ストリーミングデコーダーが8バイトの内部バッファへ入力を追記し続けた、と説明しています。修正は、上流の[google/brotli のコミット 0ed4268](https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b) です。DecodeBlockTypeAndLength が、ブロックの種類が1つなのに切り替えが要求されたとき、`BROTLI_FALSE`（入力待ちと同じ戻り値）を返していた箇所を、`BROTLI_DECODER_ERROR_FORMAT_BLOCK_SWITCH` を返すように直しています。

このコミットは2026年2月27日付で、メッセージは "Detect and report invalid stream earlier." だけです。CVE やセキュリティの語は含まれません。上流の修正版 1.0.10・1.1.1・1.2.1 の公開は、UTC の10月21日（日本時間 10月22日 4:27 前後）です。NVD によれば、影響は Brotli の 1.0.3 から 1.2.0 までです。

### 経路

経路ごとに、帰属を分けて整理します。

1. 自分のコードが直接展開する場合。Node.js のセキュリティリリースが挙げる経路で、node:zlib で信頼できない入力を展開していれば対象です
2. リクエスト本文。Imperva が検証したのは、Express 5.0.0〜5.3.0、body-parser 2.0.0〜2.3.0 です。ただし Imperva は、"The vulnerable code is in Node.js" と書き、この範囲は検証した時点の最新までです。body-parser が Brotli に対応したのは[2.0.0](https://github.com/expressjs/body-parser/blob/master/HISTORY.md)で、10月22日公開の 2.4.0 にも Brotli を展開する処理が残っています。Express 4 系と body-parser 1 系の標準のパーサーは Brotli を展開しないため、この経路の対象外です。脆弱なのは Node.js 側で、Express や body-parser はその入口になりうる、という位置づけです
3. fetch のレスポンス。Node.js 24.22.1 に同梱された undici のソースは、HTTPS の URL では `accept-encoding` に `br, gzip, deflate` を付けます。接続先のサーバーが悪意のある Brotli データを返す場合に限り、対象になります。乗っ取られた API や悪意のあるサイトにつなぐ可能性があるかどうかが、判断の目安です

レスポンス側について、Vercel の[アドバイザリ](https://vercel.com/kb/bulletin/node-js-security-advisory)は、同社の WAF の対象は同社のネットワークを通る通信で、関数が他のサーバーから取得するレスポンスは対象外だと説明しています。

### 対策

- 修正版は、10月21日に出た 26.12.1、24.22.1、22.23.4 です。Node.js のブログは、この脆弱性が 26.x、24.x、22.x に影響すると書き、修正を出したのもこの3系列です
- Node.js プロジェクトからの修正が出ないのは、20系以前だけではありません。21・23・25 系も同じです。リリーススケジュール（[schedule.json](https://github.com/nodejs/Release/blob/main/schedule.json)）では、20系は2026年4月30日、21系は2024年6月1日、23系は2025年6月1日、25系は2026年6月1日でサポートが終了しています。Node.js のブログは "End-of-Life versions are always affected when a security release occurs" と書いています。ディストリビューションや商用サポートの提供元が別に修正を出す場合はあるので、使っている提供元の案内も確認します
- npm の brotli パッケージは、"A port of the Brotli compression algorithm as used in WOFF2" と説明される別の実装で、今回の同梱ライブラリとは別物です。Imperva は "Complete remediation requires updating Node.js." と書いています
- コンテナは、Imperva の助言に沿って、各イメージやホストの中の Node.js のバージョンを確かめ、ベースイメージを更新して作り直します
- すぐに更新できない場合、Imperva は、信頼できない Brotli のトラフィックを一時的に制限するよう助言しています。リバースプロキシで Brotli のリクエストを拒否するのは、その具体例の1つで、書き手の助言です。Node.js のブログには回避策の記載がなく、この方法は fetch で受け取るレスポンスを防げないため、部分的です
- 確かめるには、`node -p process.version` で、動かしている Node.js のバージョンを見ます

### 周辺の情報

Python の Brotli パッケージも、GitHub の[アドバイザリ](https://github.com/advisories/GHSA-9v8h-qqgm-4m35)では影響を受け、brotli は 1.2.1、brotlicffi は 1.2.1.0 で修正されたと書かれています。Bun は、自身のリポジトリの [issue #46352](https://github.com/oven-sh/bun/issues/46352) で、この CVE の修正が入っていないと認め、[PR #46392](https://github.com/oven-sh/bun/pull/46392) で Brotli を更新しました。[Bun 1.4.4](https://bun.com/blog/bun-v1.4.4) は、UTC の10月22日の公開です。

2026年10月26日に確認した CISA の KEV カタログ（catalogVersion 2026.10.23）には、CVE-2026-111497 は載っていません。NVD の記録にある CISA の SSVC 評価（10月23日付）は、悪用を "none" としています。

動画の訂正はありません。

## まとめ

Nextcloud の内蔵 CODE Server は、26.4.303 以上への更新か削除が必要です。無効にするだけでは足りません。連邦機関の期限が10月26日でも、民間の事業者や個人の期限ではありません。systemd は、Cargo を使わず、外部クレートも使わず、新しい独立プログラムだけに Rust を使う形で、ビルドに対応しました。OBS Studio 33.0 は、大事な配信の前に手元で確かめてから更新するのが安全です。Wild 0.11 は、カーネルモジュールをリンクできるところまで来ましたが、開発中の反復を速くする道具という位置づけです。Node.js は、22.23.4、24.22.1、26.12.1 以降への更新が必要で、修正の出ない系列は 20 以前だけではありません。

5本に共通する「同梱された部品を知っておく」という見方は、書き手の考察です。

まず確かめることを挙げます。

- Nextcloud の richdocumentscode が入っているかを確かめ、26.4.303 以上へ更新するか削除し、apps ディレクトリの中の不審な PHP ファイルを探す
- 動いている Node.js のバージョンを `node -p process.version` で確かめ、22.23.4、24.22.1、26.12.1 以降に更新する。20系以前と 21・23・25 系は、移行先を考える
- OBS Studio を 33.0 に上げる前に、オーバーレイの表示を手元で確かめる。旧来の場所に置いたプラグインがあれば、新しい配置に対応しているかを確かめる
- systemd のパッケージを作る側は、`--auto-features=enabled` でビルドしているなら、Rust の道具を揃えるか `-Drust=disabled` で明示する

## 参考リンク

- [NVD: CVE-2026-110447](https://nvd.nist.gov/vuln/detail/CVE-2026-110447)
- [Collabora のアドバイザリ（GHSA-g3vx-3m76-fghh）](https://github.com/CollaboraOnline/online/security/advisories/GHSA-g3vx-3m76-fghh)
- [richdocumentscode の issue #354](https://github.com/CollaboraOnline/richdocumentscode/issues/354)
- [CISA の KEV カタログ（JSON）](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)
- [systemd の PR #44324](https://github.com/systemd/systemd/pull/44324)
- [OBS Studio 33.0.0 のリリースノート](https://github.com/obsproject/obs-studio/releases/tag/33.0.0)
- [Wild 0.11.0 のリリースノート](https://github.com/wild-linker/wild/releases/tag/0.11.0)
- [Node.js のセキュリティリリース（2026年10月21日）](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)
- [Imperva の Node2Shell の解説](https://www.imperva.com/blog/node2shell-from-brotli-data-to-remote-code-execution/)

（2026/10/26 Linux・OSSトレンド）
