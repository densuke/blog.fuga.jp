---
title: "Mesa の LLVMpipe に 512 ビット幅の対応が入る（既定は 256 ビットのまま）、Linux 7.4-rc4 は告知の shortlog を数えるとマージを除き 908 コミット、AMD が DCN6 の更新を 7.5 向けの pull に含める、CachyOS 11月版に Btrfs スナップショットから戻せる cachyos-recovery、EAC Linux v2 向けの linux-cachyos-eac を追加（2026/11/24 Linux・OSSトレンド）"
date: 2026-11-24T00:00:00+09:00
draft: false
tags: ["Mesa", "LLVMpipe", "AVX-512", "Linux 7.4", "Linux カーネル", "AMD", "GPU", "CachyOS", "Easy Anti-Cheat", "Secure Boot"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

使う場面がそろうのを待たずに、受け入れる側のコードや道具が先に入る。2026年11月24日（火）の動画で扱った5本は、どれもその途中にあります。

LLVMpipe の 512 ビット幅は、コードは入りましたが既定では無効です。Linux 7.4 は、rc4 の段階でも大量の修正を受け入れています。AMD の DCN6 は、製品名の書かれていないパッチの更新が続き、製品との結び付けは二次の見立てにとどまります。CachyOS の cachyos-recovery は、壊れる前に入れておく道具です。EAC Linux v2 では、CachyOS が専用の起動項目を用意し、Epic は Fortnite での試験運用を予告しています。5本を「準備が先」という線でつなぐのは書き手の読み方で、各プロジェクトがそう言っているわけではありません。

動画の訂正は、各節の末尾に置きました。確認は2026年11月24日（日本時間）で、時点で変わる値には時刻を添えます。動画の公開は11月23日 20:32 UTC（日本時間 11月24日 05:32）です。

{{< youtube "y-rYfb9WUrA" >}}

## 1. Mesa の LLVMpipe に 512 ビット幅の対応

LLVMpipe は Mesa の CPU だけで描画するソフトウェアラスタライザーです。Mesa の文書は、LLVM で実行時にコードを生成するもので、Mesa で最速のソフトウェアラスタライザーだと説明しています（[llvmpipe の文書](https://docs.mesa3d.org/drivers/llvmpipe.html)）。

フラグメントシェーダーで 512 ビット幅を扱えるようにする MR !45279 は、11月23日（月）02:02 UTC（日本時間 11:02）に、開発版の Mesa（VERSION は `27.0.0-devel`）の main へマージされました（[MR !45279](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/45279)）。作成は10月16日です。ベクトル幅は環境変数 `LP_NATIVE_VECTOR_WIDTH` で選べます。512 を指定すること自体は以前からでき、今回の MR は、ブレンドや深度の処理などフラグメントシェーダーの経路を 512 で動くようにしたものです。

既定は 256 ビットのままです。コードには "Default to 256 until we're confident llvmpipe with 512 is as correct and not slower than 256" とコメントがあり、取得した時点の main の既定値は `MIN2(util_get_cpu_caps()->max_vector_bits, 256)` です（[lp_bld_init_common.c](https://gitlab.freedesktop.org/mesa/mesa/-/blob/main/src/gallium/auxiliary/gallivm/lp_bld_init_common.c)）。AVX-512 の無い CPU でも 512 幅のコードは生成でき、その場合は LLVM が効率の悪いコードを出すだけだ、と David Airlie 氏はブログに書いています。

Airlie 氏の2026年10月15日のブログによると、出かけていた先から戻ると、Mike 氏が zink-video ブランチをリベースし、最後の部分を LLM の助けで直していました。そこで Airlie 氏は自分の古い 512 幅のブランチを引っ張り出し、最初は Opencode と GPT Terra Pro 5.6 に残りの穴を埋めさせました。トークンを多く使い時間もかかるので、Astra というモデルへ切り替えた、と書いています（[ブログ](https://airlied.blogspot.com/2026/10/jetlag-diversions-llvmpipe-512-wide.html)）。MR の説明文は "using GPT Terra and Astra finished off the last details" と書きます。Astra の提供元は、ブログにも MR にも書かれていません。

ブログと MR が挙げる成果は次のとおりです。

- 512 幅の framebuffer fetch を見ていた Astra が、1D framebuffer fetch の 128 幅側のバグを見つけた。
- piglit の fog テストで 128 と 256 の結果が食い違う変換経路を、Astra が特定した。
- geometry shader の間接ロードのバグは、Airlie 氏が LLM を使わずに直した。
- 512 幅のコードは "still all my code, I've just cleaned it up a lot" で、Airlie 氏自身のコードを整理したものだと書かれている。

速さについては、MR のコメントに計測の話があります。ajax 氏（10月22日）は "atm it's a bit of a mixed bag, and on balance a bit worse"、glmark2 では texture が勝ち shading が負け、と書き、"I'd keep it disabled for now" と続けました。Airlie 氏（10月26日）は "it's hit and miss right now" と書き、10月23日には "I'm not pushing to turn this on, I'd just like to have it functional for now" と書いています。

2022年の MR !17813 は、Yonggang Luo 氏による題 "llvmpipe: prepare to add avx512 support" の下準備で、2022年9月2日にマージされています（[MR !17813](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/17813)）。Vulkan 版の Lavapipe の AVX-512 は別の Issue #7284 で、確認時点では open です（[Issue #7284](https://gitlab.freedesktop.org/mesa/mesa/-/issues/7284)）。Mesa 27.0 の安定版の時期は、取得した release-calendar に 27.0 の行が無く、確認できていません（[release-calendar](https://docs.mesa3d.org/release-calendar.html)）。

動画の訂正です。

- 動画では、AVX-512 の実機を持たない人がマージし、速さの計測はまだ、と伝えました。正しくは、Airlie 氏のブログ（10月15日）は実機が無いと書きましたが、MR の説明文（確認時点）は "I've tested this on an avx512 machine and piglit shows no regressions on 256 or 512 modes" と書き、MR のコメントでは glxgears や glmark2 での結果が議論されています。
- 動画では、幅が倍になれば速さが期待できる、と伝えました。正しくは、MR のコメントは "hit and miss"、"on balance a bit worse" と書き、既定の幅は 256 ビットのままです。512 は環境変数で選びます。
- 動画では、Astra を Google DeepMind のモデルと伝えました。正しくは、ブログと MR は "Astra" とだけ書き、提供元の記載がありません。

## 2. Linux 7.4-rc4

Linus Torvalds 氏の rc4 の告知は、米国東部時間の11月22日（日）18:10（日本時間 11月23日 08:10）です。タグは太平洋時間 11月22日 14:57:40（日本時間 11月23日 07:57）でした。告知の本文は短く、次のとおりです（[告知](https://lkml.iu.edu/2611.2/21681.html)）。

> It's huge. What a surprise. Lots of little fixes all over, with drivers being pretty exactly half of it (gpu and networking showing up as usual, but there's usb, iio, nvme, sound.. you name it).

続けて Linus 氏は、残りが core kernel、mm、filesystems、networking、selftests、architecture updates にまたがると書き、"Would I have loved to see a smaller rc? Sure. But those days are behind us, particularly with this very large 7.4 release." と述べています。"Please do keep testing" で締めています。告知にコミット数や貢献者数の記載はありません。

数は、告知の [shortlog](https://marc.info/?l=linux-kernel&m=179539242644326&w=2) を数えると、マージを除いて908コミット、著者名で425人です（書き手の集計。メールアドレスでは428）。GitHub の compare（v7.4-rc3 から v7.4-rc4）でも、マージを除く908件で、マージを含めると997件です。GitHub の compare のマージを含む件数で、7.4 と直前の8版（6.16〜7.3）の rc3 から rc4 の間を比べると、7.4 が最も多くなりました（これも書き手の集計）。

個別の修正を、告知の shortlog にあるコミットの語で挙げます。

- NVMe は、ネームスペースの削除を並列にするコミットです。1つ外すごとに、ネームスペースとマルチパスの head の RCU の待ちが合わせて約 20 ms かかり、コントローラーの削除（fabrics の target からの切断など）にかかる時間がネームスペースの数に比例していました。コミットの計測は、同一ホスト上の target から tcp（127.0.0.1）と nvme-loop で切断する時間です。値は各起動で3回測った中央値で、2回の起動の分を並べています。64個の tcp は 1201 / 1308 ms から 533 / 550 ms、64個の nvme-loop は 1988 / 1913 ms から 1283 / 1200 ms です（[コミット](https://github.com/torvalds/linux/commit/fc991838ef25f1cab9ff34b55b39f16d95ed39b3)）。
- Landlock は、Mickaël Salaün 氏の13本です。CAP_SYS_RAWIO、CAP_SETPCAP、CAP_SYS_ADMIN を使う特定の場面の仲介のほか、PR_SET_SECUREBITS の確認、selftests、文書、名前空間の拒否の区別が入っています。Landlock は、特権のないプロセスも含めて、自分自身を制限するための仕組みです（[Landlock の文書](https://docs.kernel.org/userspace-api/landlock.html)）。
- GPU は、amdgpu、xe、vmwgfx に修正が入っています。vmwgfx には "close TOCTOU on guest_memory_bo in surface reference ioctl" があります。
- Rust は、`rust_binder` の修正と、Rust 1.101.0 向けの objtool の準備です。Rust の stable は 1.100.0、beta は 1.101.0-beta.3 です（11月23日 UTC の取得）。
- Intel は、Coral Rapids と Razor Lake の CPU モデルの追加です。コミット本文は "upcoming" と書き、ドライバ対応の時期には触れていません（[コミット](https://github.com/torvalds/linux/commit/e83cac046ded56962ad4d4eb6ebd7910d62c287b)）。

最多は Josef Bacik 氏の35本で、サブジェクトは thunderbolt、USB serial、iio、bpf sockmap などです。xfs のサブジェクトは別の作者で、計19件あります。

安定版の日付は告知に書かれていません。rc は通常 rc6 から rc9 まで進むと、カーネルの文書は書いています（[文書](https://docs.kernel.org/process/2.Process.html)）。いまの安定版は、確認した11月23日 21時50分台 UTC（日本時間 11月24日 6時50分台）の時点で 7.3.6（11月23日）で、7.3.5 は11月17日でした（[kernel.org](https://www.kernel.org/releases.json)）。

動画の訂正です。

- 動画では、861コミット・407人と伝えました。正しくは、861 と 407 は二次の記事の見出しの値で、Linus 氏の告知に総数の記載はありません。告知の shortlog を数えると、マージを除いて908コミット、著者名で425人です（書き手の集計。GitHub の compare でも同じ値）。
- 動画では、いまの安定版は 7.3.5 と伝えました。正しくは、動画の公開時点で 7.3.6（11月23日 UTC）が出ていました。
- 動画では、Linus も驚いた、と伝えました。正しくは、告知の原文は "It's huge. What a surprise." で、続けて "Would I have loved to see a smaller rc? Sure. But those days are behind us" と書いています。驚いたとは書いていません。

## 3. AMD の DCN6 の更新

DCN6 のレジスタヘッダなどは、2026年7月31日 21:12 UTC（日本時間 8月1日 06:12）の DC Patches で最初に投稿されています（[DC Patches July 31](https://lists.freedesktop.org/archives/amd-gfx/2026-July/149691.html)）。9月1日の記事のとおり、レジスタヘッダは Linux 7.3-rc1 で統合済みで、今回の話は追加の更新です。

Alex Deucher 氏は、太平洋時間 11月19日 11:58（日本時間 11月20日 04:58）の pull リクエストで、本文に "More new stuff for 7.5." と書き、概要に "DCN 6 updates" を入れました。タグは `amd-drm-next-7.5-2026-11-19` です（[pull](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg156520.html)）。変更は227ファイルで、追加が9365行、削除が20810行です。削除の大半は、DC を使わない旧表示コード（DCE6、DCE8、DCE10）の撤去で、コミット名に "drop non-DC DCE10 support" などがあります。

DCN6 に関するコミットは次のとおりです。

- "Update DCN6 Calcs" は、dcfclk の deep sleep の計算と、レジスタサイズ上限の扱いの更新です（[patch](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg155494.html)）。
- "Enable HDCP on DCN6" は、fused_io に対応していれば DMUB の outbox を有効にし、DTM TA v3 の対応を配線する変更です（[patch](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg155497.html)）。
- "Limit VRAM aperture retrieval to DCN6" は、alt channel pstate switch が DCN6 だけで対応のため、他の ASIC には aperture を返さない変更です（[patch](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg155501.html)）。
- "Read DCN6 SOP constraints from the idle row" は、SoC の動作点の表の idle の行から値を読む変更です（[patch](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg155490.html)）。

別に、11月17日（UTC。日本時間 11月18日）に James Lin 氏が33本のシリーズを投稿しています。Wayne Lin 氏の Reviewed-by（太平洋時間 11月20日）が引く概要は、DPMS-v2、RGBA8888 の surface pixel format、ファームウェア更新（"Release 0.1.85.0"）です（[Reviewed-by](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg156552.html)）。このシリーズのメールと Reviewed-by に、対象のカーネルの版は書かれていません。

版の番号について、ドライバの IP バージョンの一覧では、4.2.1 の次が 6.0.0 です。DC 側の列挙は `DCN_VERSION_4_2`、`DCN_VERSION_4_2B`、`DCN_VERSION_6_0` で、5.0 はありません（[amdgpu_discovery.c](https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/amd/amdgpu/amdgpu_discovery.c)）。ただし DCN5 の名前を持つファイルは hubp・dpp・hwss などに残っています。欠番の理由について、HWBusters は8月2日の記事で "Nobody outside AMD has said why." と書いています。

RDNA5 との対応は、パッチの原文にありません。本文に RDNA や UDNA の語が無いのは、11月13日の記事で扱った GFX13 の初期パッチと同じです。HWBusters は、複数のパッチが DCN6 を GC 13.0.1 と結び付けていると書き、GC 13.0.1 は GFX13 に対応し、GFX13 は広く RDNA5 と推定されている、と説明します。製品の時期は "RDNA5 parts aren't expected before 2027" と書いています（[HWBusters](https://hwbusters.com/news/amds-rdna5-dcn6-display-engine-surfaces-in-linux-dcn5-is-missing-entirely/)）。これは HWBusters の見立てで、AMD の発表は確認できていません。GFX13 本体の初期パッチは11月9日 UTC に投稿され、7.4-rc4 の amdgpu の Makefile に `gfx_v13_0.o` はありません。

動画の訂正です。

- 動画では、DCE6・DCE8・DCE10 を2010年から2012年ごろの Radeon HD 時代のものと伝えました。正しくは、カーネルの文書の表で DCE6 は HD 7800/7900 台、DCE8 は Bonaire・Hawaii（R9 200 など）、DCE10 は Tonga・Fiji（R9 380・Fury など）で、DCE8 と DCE10 は R9 の製品です（[文書](https://github.com/torvalds/linux/blob/master/Documentation/gpu/amdgpu/dgpu-asic-info-table.csv)）。

## 4. CachyOS 11月版とリカバリツール

CachyOS の11月版は、ブログの日付表示が11月22日です。ブログはこれを "our sixth release of the year" と書きます。このリリースのパッケージは、Linux 7.3.5（LTS は 6.18.64）、NVIDIA 620.73.04、Mesa 26.3.1、Limine 12.10.0 です（[ブログ](https://cachyos.org/blog/2611-november-release/)）。

新しい cachyos-recovery は、ブートローダーまたは UEFI から直接起動できる単体のイメージで、ブログは、壊れたシステムのロールバックに live USB は不要になった、と書いています。

- UEFI では UKI で、ESP に約 70 MB を使います。BIOS 向けは cachyos-recovery-legacy です。
- メニューから Btrfs のスナップショットを、書き込み可能なルートで起動して試せます。確定は、デスクトップの通知かリカバリのメニューからです。
- Snapper に依存せず、LUKS で暗号化した環境に対応します。ロールバックでは、カーネルと initramfs、ブートローダーの設定を作り直し、sbctl で Secure Boot を設定済みなら署名もします。
- 入れ方は `sudo pacman -S cachyos-recovery` で、BIOS では cachyos-recovery-legacy です。

ブログが書くのは Btrfs のスナップショットのロールバックです。前提となるスナップショットが事前にあるかどうかは、ブログに明記がなく、cachyos-recovery 専用の wiki は取得できていません。

cachyos-drm-awaiter は新しいパッケージで、ディスプレイマネージャーを起動する前に GPU ドライバが読み込まれるのを、NVIDIA に限らず待ちます。early KMS と nvidia-module-loader を置き換え、読み込みに失敗したときは QR コードを表示します。

動画の訂正です。

- 動画では、毎月の ISO と伝えました。正しくは、ブログは11月版を「今年6回目のリリース」と書いています。

## 5. EAC Linux v2 対応の linux-cachyos-eac

同じ11月版で、CachyOS は EAC 対応のカーネル linux-cachyos-eac を追加しました。CachyOS の鍵で署名したカーネルと、同じ鍵で署名した systemd-boot の組です。ブログは EAC の要件を次の1文で書いています（[ブログ](https://cachyos.org/blog/2611-november-release/)）。

> EAC only lets games start when it can verify how the system was booted: Secure Boot with a kernel signed by a key that Epic trusts, a TPM 2.0, an enabled IOMMU, and a kernel running in lockdown mode that only loads signed modules.

Epic の2026年10月14日の投稿は、ディストリビューションが署名鍵を well-known list に加えるには linux-gaming@epicgames.com に連絡するよう求めています（[Epic](https://onlineservices.epicgames.com/news/introducing-easy-anti-cheat-linux-v2)）。

PKGBUILD のコメントによると、EAC 用の起動項目はカーネルのコマンドラインに `lockdown=integrity`、`module.sig_enforce=1` などを設定し、EAC は測定されたコマンドラインを確かめます。ビルド時には、必要な設定が `=y` でないとビルドが失敗する検査があります。ハイバネーションも無効です（[PKGBUILD](https://github.com/CachyOS/linux-cachyos/blob/master/linux-cachyos-eac/PKGBUILD)。確認した master の版で、リリース時点の版ではありません）。起動項目の設定は、eac-setup が systemd-boot、Limine、rEFInd に対して行い（GRUB は experimental）、結果は eac-status で確認します。EAC カーネルには専用の起動項目があり、通常の起動項目は残ります。

注意点は wiki に書かれています（[wiki](https://wiki.cachyos.org/configuration/easy_anti_cheat/)）。

- Secure Boot の鍵が変わると TPM の測定対象が変わり、Windows とのデュアルブートの BitLocker は回復キーを求めることがあります。TPM に自分で結び付けた LUKS のディスクは、パスフレーズを求めます。回復キーを用意せずに始めると、データにアクセスできなくなるおそれがある、と wiki は書いています。ブログも、BitLocker や TPM でディスクを解錠している人は、先に wiki を読むよう求めています。
- DKMS で作ったモジュールは、EAC の起動項目では読み込まれません。NVIDIA（open と 580xx）、ZFS、r8125 のモジュールは、linux-cachyos-eac-* の署名済みパッケージで提供されます。

対応ゲームについては、[GamingOnLinux の記事](https://www.gamingonlinux.com/2026/11/cachyos-november-2026-release-brings-support-for-easy-anti-cheat-linux-v2/)のコメント欄で、著者の Liam Squires-Hand 氏が "Currently none as far as I am aware, as it's still being tested. I presume Fortnite will be the first." と書いています。著者の見立てで、留保が付いています。Epic の10月14日の投稿は "We are also planning to pilot EAC Linux v2 in Fortnite first" と書き、まず Fortnite で試験運用する予定を示しています（[Epic](https://onlineservices.epicgames.com/news/introducing-easy-anti-cheat-linux-v2)）。

動画の訂正です。

- 動画では、intel_iommu=on は Intel の CPU のときだけ必要、と伝えました。正しくは、ブログの変更点の1行は「eac-status が intel_iommu=on を要求するのは Intel の CPU のときだけ」で、起動オプションの一覧（wiki・PKGBUILD）には共通で入っています。

## まとめ

受け入れの準備が先に入っている、という見方は書き手の考察です。実務で確かめておくものは次のとおりです。

- LLVMpipe: 512 ビット幅は `LP_NATIVE_VECTOR_WIDTH` で選ぶもので、既定は 256 ビットのまま。MR のコメントは速さについて "hit and miss" と書く。Mesa 27.0 の安定版の時期は、release-calendar に行が無い。
- Linux 7.4: 告知に安定版の日付は無い。rc は通常 rc6 から rc9 まで進む。いまの安定版は、確認時点で 7.3.6。
- CachyOS のリカバリ: 一次が書くのは Btrfs のスナップショットのロールバック。UEFI は cachyos-recovery、BIOS は cachyos-recovery-legacy。スナップショットの前提は、ブログに明記が無い。
- EAC v2 のカーネル: Secure Boot、署名済みカーネル、TPM 2.0、IOMMU、Lockdown が要件。BitLocker や TPM を使う人は、始める前に wiki を読み、回復キーを用意する。DKMS のモジュールは EAC の起動項目では読み込まれない。

## 参考リンク

- [MR !45279: llvmpipe の 512 幅対応](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/45279)
- [Airlie 氏のブログ（2026年10月15日）](https://airlied.blogspot.com/2026/10/jetlag-diversions-llvmpipe-512-wide.html)
- [Linus 氏の 7.4-rc4 の告知](https://lkml.iu.edu/2611.2/21681.html)
- [Alex Deucher 氏の pull リクエスト](https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg156520.html)
- [CachyOS 11月版のブログ](https://cachyos.org/blog/2611-november-release/)
- [CachyOS wiki: Easy Anti-Cheat (Linux v2)](https://wiki.cachyos.org/configuration/easy_anti_cheat/)
- [Epic: EAC Linux v2](https://onlineservices.epicgames.com/news/introducing-easy-anti-cheat-linux-v2)

（2026/11/24 Linux・OSSトレンド）
