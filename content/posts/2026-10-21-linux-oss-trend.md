---
title: "PAN-OS CVE-2026-0257 の悪用継続、Claude Code 製パッチの再設計 RFC、Linux-libre 7.3、EDAC ドライバの引退、Siemens Software Center の脆弱性悪用（2026/10/21 Linux・OSSトレンド）"
date: 2026-10-21T00:00:00+09:00
draft: false
tags: ["セキュリティ", "ランサムウェア", "Palo Alto Networks", "Linux カーネル", "Linux 7.4", "AI", "Claude Code", "Linux-libre", "ClickFix", "Siemens"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

パッチは書いて終わりではなく、確かめて届けるまでが修正です。今回の5本は、どれも「書いた後」の話として読めます。2026年5月に修正が出た穴は、修正を当てていない機器で攻撃され続けています。Linus Torvalds 氏が AI を使って書いたカーネルのパッチは、Kiryl Shutsemau 氏の手で18本の RFC に作り直されました。AI が生成する修正の増加は、古いドライバがメンテナ不在になる場面にも現れています。

5本に共通点を見るのは、あくまで書き手の考察です。Linux 7.3 は10月18日（米国時間）に正式リリースされ、7.4 のマージウィンドウが開いています。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "MhKuBNh5kMY" >}}

## 1. PAN-OS GlobalProtect の CVE-2026-0257 — 5月に修正が出た穴が、10月も狙われている

CVE-2026-0257 は、Palo Alto Networks の PAN-OS で GlobalProtect のポータルまたはゲートウェイを使っている環境の脆弱性です。[アドバイザリ](https://security.paloaltonetworks.com/CVE-2026-0257)の公開は2026年5月13日です。影響を受けるのは、認証オーバーライドクッキーが有効で、特定の証明書構成がある場合です。分類は CWE-565（Reliance on Cookies without Validation and Integrity Checking）です。Qilin による悪用は[7月22日の記事](https://blog.fuga.jp/posts/2026-07-22-linux-oss-trend/)で扱いました。

### Unit 42 の10月19日の更新

[Unit 42 のブリーフ](https://unit42.paloaltonetworks.com/active-exploitation-of-pan-os-cve-2026-0257/)は、10月19日（米国太平洋時間16時）に、ランサムウェアグループの活動を加えて更新されました。10月20日にも、確認と対策の案内を足す更新があります。10月19日の更新によれば、Unit 42 は Spikey Scorpius（別名 Qilin）と Tarnished Scorpius（別名 Inc）による悪用の試みを引き続き観測しています。Settra ランサムウェアを使う攻撃者による悪用は、Unit 42 自身の帰属ではなく、"public reporting" として別に紹介されています。

### 偽造の仕組みと深刻度

[Rapid7 のブログ](https://www.rapid7.com/blog/post/etr-rapid7-observed-exploitation-of-pan-os-globalprotect-authentication-bypass-vulnerability-cve-2026-0257/)によれば、クッキーの暗号化用の証明書をポータルやゲートウェイの HTTPS など他の機能と使い回していると、未認証の遠隔攻撃者が公開鍵を取得し、任意の認証オーバーライドクッキーを偽造して暗号化できます。Rapid7 の研究部門が作った PoC は5月29日に公開され、同日、CISA の Known Exploited Vulnerabilities カタログにも追加されています。

CVSS は版を分けて読む必要があります。

- Palo Alto のアドバイザリで 4.7（中）から 7.8（高）に変わったのは、CVSS v4.0 の脅威込みスコア（CVSS-BT）です。悪用状況を反映して、5月29日に更新されました。v4.0 の基本スコア（CVSS-B）は最初から 7.8 です
- CVSS v3.1 の 9.1（Critical）は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-0257) が付けた別のスコアです

### 侵入後の流れ

[Arctic Wolf のブログ](https://arcticwolf.com/resources/blog/exploitation-of-cve-2026-0257-leads-to-qilin-ransomware/)は、2026年6月に調べた複数の侵入で、CVE-2026-0257 が初期侵入の経路だったと書いています。LSASS のプロセスメモリからの認証情報の取得、ntdsutil.exe による Active Directory データベースの複製、PsExec と RDP による横展開、Windows イベントログの消去が挙がっています。Microsoft Defender のリアルタイム保護は、一部の事例で、ランサムウェアの展開前に無効化されていました。Arctic Wolf は、侵入後の手口は被害者ごとに異なったとも書いています。

Unit 42 のブリーフの冒頭には、VPN セッションが確立したのは調べた機器の一部で、横展開は確認されていない、という6月からの文が残っています。一方、10月19日の更新節は、RDP と SMB での横展開を挙げ、VPN ゲートウェイから vCenter の管理アプライアンスに移った事例も報告しています。

### 対象と対策

- 対象は PAN-OS の 10.2・11.1・11.2・12.1 の一部の版と、サポートが切れた旧版です。Panorama と Cloud NGFW は影響を受けません。Prisma Access は 10.2 と 11.2 の一部が対象で、アップグレードは Palo Alto の予定に沿って進められています
- 修正版は、アドバイザリによれば、12.1.7 以降、11.2.12 以降、11.1.15 以降、10.2.18-h6 以降などです。系列と現在の版ごとの修正版は、アドバイザリの Product Status の表で確認します
- 修正版にすると、認証オーバーライドクッキーは安全な方法で作り直されるため、GlobalProtect の利用者は一度だけ再認証が必要です
- すぐに上げられない場合の緩和策は2つあります。認証オーバーライドクッキー専用の証明書を新しく作る方法と、認証オーバーライドの設定を無効にする方法です。ポータルやゲートウェイの証明書を使い回してはいけません
- 確認には、Unit 42 の案内にあるように、GlobalProtect のログで、不審なホスト ID やデバイス名からの gateway-connected イベントを検索します

動画の訂正です。

- 動画では、10月の更新に「VPN セッションが確立したのは一部」「横展開は確認されていない」と書かれていると紹介しましたが、この2文は2026年6月9日版から残る冒頭の文です。10月19日の更新節は、RDP と SMB での横展開と vCenter への移動を報告しています（[Unit 42 のブリーフ](https://unit42.paloaltonetworks.com/active-exploitation-of-pan-os-cve-2026-0257/)）。

## 2. Linus Torvalds の Claude Code 製パッチを、Kiryl Shutsemau 氏が18本の RFC に — 取り込みはまだ先

Meta 所属の Kiryl Shutsemau 氏が、10月19日（UTC）に、ページキャッシュを folio の参照カウントなしで読む RFC を linux-mm に投稿しました。Meta という会社の取り組みではなく、同氏個人の RFC です。[カバーレター](https://lore.kernel.org/linux-mm/20261019154913.1765974-1-kas@kernel.org/)の件名は "[RFC PATCH 00/18] mm: read the page cache without folio references" です。

### 元になった Linus 氏のパッチ

Linus Torvalds 氏のブランチ noref-filemap-read-with-llm の[コミット](https://mirrors.hust.edu.cn/git/linux.git/commit/?h=noref-filemap-read-with-llm)は、2026年10月10日付です。本文の Tools 節に、コード、テストプログラム、レビュー、本文の最初の下書きは、同氏の指示のもとで LLM のコーディングアシスタント（Claude Code）が行ったと書かれています。10月13日には、10本のパッチ（ブランチ rcu-free-v3）が [LKML に投稿](https://lore.kernel.org/all/CAHk-=wjLjgfwgSZ1RDk4YdNFcV0ntosMO5AmBoHD76Zb3HFY7Q@mail.gmail.com/)されています。

### 何を直すのか

カバーレターによれば、多くの CPU が同じファイルを少しずつ読むと、どの CPU も同じ folio の参照カウントを増減し、その cache line を奪い合います。RFC は、読み手がコピーする可能性のある folio の解放を、RCU の猶予期間の後まで遅らせて、参照カウントを不要にします。

18本の内訳は、カバーレターの shortlog で、Linus 氏が作者のものが7本、Shutsemau 氏が作者のものが11本です。Linus 氏の側の草案は、ブランチによって8本（10月10日）または10本（10月13日）で、7本とは別の数え方です。Shutsemau 氏のパッチにも、Linus 氏のパッチにも、`Assisted-by: LLM` の trailer が付いています。

### 設計の要点

- フラグ PG_rcu_free は、読み込み時に、繰り返し読まれる（hot な）folio に立てます。ストリーミング読み込みなど、hot にならないデータは遅延の対象外です。フラグは 64 ビット環境だけで使えます
- 解放待ちのページが CPU あたり 4 MiB（4 KiB ページで 1024 ページ）を超え、さらにメモリが逼迫しているときに、猶予期間の短縮を要求して解放を急ぎます
- 待機中のページは、ゾーンごとのカウンタ NR_FREE_RCU_PAGES で数えます。OOM killer に処理を渡す前に待機分を解放して再試行する変更も含まれます
- 新しい読み方を止めるスイッチは、sysctl ではなく debugfs の lockless_page_cache_read で、RFC のパッチ18/18に含まれています。将来、削除される可能性があるとも書かれています
- tmpfs の読み込みにも同じ仕組みを使います

### 測定結果

測定は、64 vCPU の KVM ゲストを AMD Threadripper 7975WX で動かし、CPU の脆弱性対策を既定のまま有効にして、7.3-rc7 を基準に行われています。64 スレッドで 16 バイトの pread() を行った結果は、カバーレターの値で次のとおりです。

| ファイルシステム | 基準（M reads/s） | RFC（M reads/s） | 比 |
|---|---|---|---|
| EXT4 | 15.0-15.7 | 68.9-70.1 | 約4.5倍 |
| tmpfs | 1.6-1.7 | 71-72 | 40倍超 |
| XFS | 11.3-11.4 | 20.4-20.5 | 約1.8倍 |

1スレッドの読み込みは、ほぼ変わりません（1.6-1.9 が 1.7-2.0）。カバーレターの Open 節には、未解決の点が挙がっています。待機中の folio は、その間どの cgroup にも計上されません。メモリのコンパクションへの影響は、まだ測っていません。書き込み可能にマップされたファイルでは、flush_dcache_page() を実装するアーキテクチャは従来の遅い経路を通ります。

### 取り込み状況

10月21日の時点で、torvalds/linux の master にこのシリーズは入っていません。RFC として投稿された段階で、議論が続いています。

動画の訂正です。

- 動画では、フラグを「ページキャッシュから外れたページに」立てると紹介しましたが、RFC では、読み込み時に、繰り返し読まれる folio に立てます。フラグの付いた folio が外れるときに、解放を猶予期間の後まで待たせる、という結果は動画のとおりです（[カバーレターの 00/18](https://lore.kernel.org/linux-mm/20261019154913.1765974-1-kas@kernel.org/)）。

## 3. GNU Linux-libre 7.3 — 新しいドライバの blob 名を取り除く

GNU Linux-libre は、Linux カーネルから、ソースのない非自由なコンポーネントを取り除くプロジェクトです。[7.3-gnu のアナウンス](https://www.fsfla.org/pipermail/linux-libre/2026-October/003671.html)の日時は、10月19日 05:02:14 UTC です。Linux 7.3 のタグ（10月18日 23:14:58 UTC）の約6時間後にあたります。

### 今回の対象

アナウンスによれば、新しいドライバのうち、Tyr（Arm の Mali GPU 向け）、Morse Micro の mm81x（Wi-Fi）、NXP の Wi-Fi、Realtek の PHY で blob 名を掃除しました。Tyr は、[カーネルの Kconfig](https://github.com/torvalds/linux/blob/v7.3/drivers/gpu/drm/tyr/Kconfig) で Arm Mali CSF 系 GPU 向けの Rust DRM ドライバとされています。Morse Micro の mm81x が対象とする Wi-Fi HaLow は、Wikipedia によれば IEEE 802.11ah の愛称で、1GHz 未満の帯域を使います。

既存のドライバでは、nova-core、amdgpu、adreno、rtw89、mt76 などで、新しく増えた blob 名を掃除しました。今回初めて対象になったのは新しいドライバの4件で、既存のドライバは増えた分の洗い直しです。nova-core は、[カーネルの文書](https://docs.kernel.org/gpu/nova/index.html)によれば、GPU System Processor（GSP）を持つ NVIDIA GPU 向けのドライバです。

### 何をするプロジェクトか

アナウンスは、ソースコードに見せかけた、または別ファイルで配られる非自由なコンポーネントを取り除き、それらを実行時に要求する処理と、それを指す文書も無効にする、と説明しています。取り除いたものの自由な代替を用意することはしない、という方針も書いています。取り除きの作業は、[プロジェクトのページ](https://www.fsfla.org/ikiwiki/selibre/linux-libre/)によれば、スクリプト deblob-main が担い、残りの検査には deblob-check を使います。

### 使う方法

プロジェクトのページには、Debian 系向けの Freesh（.deb）、Fedora や RHEL 系向けの RPM Freedom（.rpm）、PREEMPT_RT 付きの libeRTy（.deb）が載っています。7.3 のアナウンス時点では、ビルド済みのリリースは "available shortly" とされていました。[FSF が推奨するディストリビューション](https://www.gnu.org/distros/free-distros.html)には、Parabola、PureOS、Trisquel などがあります。どの版に追従できるかは、使うディストリビューションの案内で確認してください。

### 歴史

アナウンスによれば、Linux-libre は gNewSense の中で始まり、後に Jeff Moe 氏が引き継いで名付けました。2008年に FSF Latin America が維持するプロジェクトになり、2012年に GNU プロジェクトの一部になっています。[Wikipedia](https://en.wikipedia.org/wiki/Linux-libre) は、Alexandre Oliva 氏をメンテナとしています。

動画の訂正はありません。

## 4. Linux 7.4 のマージウィンドウで、古い EDAC ドライバ4つがメンテナ不在に

Borislav Petkov 氏の EDAC の pull request が、Linus 氏に取り込まれました。[マージコミット](https://github.com/torvalds/linux/commit/ae171014b7988fabf1dbbc7cc4036c416a5b0230)の日時は、2026年10月20日 18:14:43 UTC です。7.3 の後のマージウィンドウで入ったもので、v7.4-rc1 のタグは10月21日の時点でまだありません。マージウィンドウのほかの動きは[10月20日の記事](https://blog.fuga.jp/posts/2026-10-20-linux-oss-trend/)にあります。

### 取り込まれた内容

マージコミットの本文によれば、i82975x、x38、xgene、i3200 の EDAC ドライバが、MAINTAINERS で Orphan（メンテナ不在）になりました。ドライバのソースは、削除されずに残っています。本文は、これらのドライバには通りすがりの更新（drive-by updates）しか届かず、実際に使っている形跡はメーリングリストにない、と書いています。

理由の核心は、次の一文です。"So, with the advent of AI-generated fixes frenzy, and because no one can really test fixes on those, it is time to sunset them ..." 実機で試せないドライバに AI が生成した修正が集まる状況を挙げ、引退させる時期だとしています。削除の時期や予定は、一次では確認できません。

対象のうち3つは2000年代半ばの Intel チップセットのドライバで、X-Gene は Applied Micro（APM）の Arm SoC 向けです。

7.3 の開発サイクルでは、ThunderX と MPC85XX の EDAC ドライバが、先に Orphan になっています。理由は AI ではなく、[pull request の本文](https://github.com/torvalds/linux/commit/786262be6048deab760f68c8acc2c85607165894)にある、ハードウェアにアクセスできないことです。

同じマージで、新しい EDAC ドライバも2つ入りました。1つは Intel のハードウェアで bitfix filter をリセットする intel-bff です。bitfix filter は、シリコンの経年劣化などで固着したビットを追跡する仕組みです。長く稼働すると一時的なエラーが溜まって詰まることがあるため、あふれたときにリセットします。もう1つは、ハードウェアがなくても EDAC のコアを VM 上で試せるダミードライバです。

### 7.1 の削除との関係

7.1 では、ISDN、AX.25（アマチュア無線）、ATM、CAIF などが削除されました。[net-deletions のマージ](https://github.com/torvalds/linux/commit/64edfa65062dc4509ba75978116b2f6d392346f5)は Jakub Kicinski 氏の pull request で、削除は138,161行です。本文は、syzbot が古いコードのバグを見つけ、新しい開発者が直そうとする状況を挙げ、"the LLM-pocalypse" を乗り越えるには専任のオーナーが必要で、いなければ削除する、と書いています。Andrew Lunn 氏の ISA と PCMCIA の Ethernet ドライバの[削除シリーズ](https://github.com/torvalds/linux/commit/0c22ed0fadcad620277a56c0ba2867d4850d053a)のカバーレターは、AI を使う新人と fuzzer が問題を見つけ、メンテナの仕事が増えている、と書いています。経緯は[10月12日の記事](https://blog.fuga.jp/posts/2026-10-12-linux-oss-trend/)にあります。

[The Register](https://www.theregister.com/os-platforms/2026/08/10/linus-torvalds-says-ai-has-made-huge-linux-kernel-updates-the-new-normal/5285268) の2026年8月10日付の記事によれば、Linus 氏は 7.2 の rc6 の大きさについて、修正の多くは AI ツールによるレビューから来ていると述べ、これを "the new normal" と呼びました。

### 自分の環境の確認

自分の環境が対象かは、`lsmod | grep -E 'i82975x_edac|x38_edac|i3200_edac|xgene_edac'` で目安がつきます。ドライバがカーネルに組み込まれている場合は、`lsmod` には出ません。EDAC のログは `dmesg | grep EDAC` で見られますが、ディストリビューションによっては権限が必要です。

動画の訂正です。

- 動画では、7.1 の約13万8000行の削除を提案したのは Andrew Lunn 氏だと紹介しましたが、[net-deletions の pull request](https://github.com/torvalds/linux/commit/64edfa65062dc4509ba75978116b2f6d392346f5) は Jakub Kicinski 氏のもので、ISDN、AX.25、ATM、CAIF の削除コミットの作者も Kicinski 氏です。Lunn 氏は、同じマージに含まれる ISA と PCMCIA の Ethernet ドライバ12件の削除（約1万6000行）を提案しました。

## 5. Siemens Software Center の CVE-2026-110936 と、偽カスタム GPT「Plus 5.6」の ClickFix

2つの話があります。1つは Siemens Software Center の脆弱性 CVE-2026-110936 が悪用されていること、もう1つは ChatGPT のカスタム GPT を入口にした ClickFix の攻撃が見つかったことです。2つが同じ攻撃者の一続きの連鎖だと、確認できた一次情報には書かれていません。以下は、別々の事実として整理します。

### Siemens Software Center の脆弱性

Siemens のアドバイザリ [SSA-580366](https://productcert.siemens.com/productcert/html/ssa-580366.html) によれば、Software Center は DLL を制御されていない検索パスから読み込みます。認証されたローカルの攻撃者が細工した DLL を置けば、アプリの権限で任意のコードを実行できます。分類は CWE-427 です。

- CVSS v4.0 は 8.4 で、ベクトルは AV:L、PR:H です。ローカルで、高い権限が前提です
- CVSS v3.1 は 6.7（Medium）です
- どちらも Siemens が付けた値で、NVD 自身の評価は、確認時点で "Undergoing Analysis" でした
- 対象は V4.0.9.8 未満のすべての版で、V4.0.9.8 以降に更新します

アドバイザリの改訂履歴は、V1.0（10月15日、公開）、V1.1（10月17日、Siemens Software Center の対策を追加）、V1.2（10月19日、悪用に関するブログ記事への参照を追加）です。Siemens ProductCERT の[10月19日のブログ](https://productcert.siemens.com/news/2026/10/19/active-exploitation-of-cve-2026-110936-in-siemens-software-center/)は、攻撃者が、有効な署名のある正規の Software Center を使い、その隣に自分のファイルを置いたと説明し、悪意あるファイルとして AllMyBasic.msi と archive.dll を挙げています。カナダのサイバーセキュリティセンターは、10月19日に[AV26-1063](https://cyber.gc.ca/en/alerts-advisories/siemens-security-advisory-av26-1063)で注意喚起を出しました。CISA の KEV には、10月20日に追加されています。

### Huntress が報告した偽カスタム GPT

[Huntress の記事](https://www.huntress.com/blog/chatgpt-custom-gpts-clickfix-rat)（9月28日公開）によれば、攻撃者は「Plus 5.6」という名前の偽のカスタム GPT を作り、Google Sites のページへ誘導しました。ページは Cloudflare の CAPTCHA 風の画面で、ClickFix の手口により、PowerShell で悪意ある MSI をダウンロードさせます。Huntress は、この Google Sites のドメインに由来する少なくとも40件のインシデントに対応し、そのうち2件がカスタム GPT 経由だと確認しました。

Huntress が OpenAI に連絡し、最初の偽 GPT は9月25日までに削除されました。9月27日に、Huntress が同じキャンペーンに結び付く新しいカスタム GPT を見つけています。Huntress の記事にある連鎖は、Canon の署名付きアプリ（COTFileReadApp.exe）や Stardock の DeElevate64.exe を使った DLL サイドローディングで、ローダーは NuGet パッケージや WAV ファイルに中身を隠していました。記事に Siemens や AllMyBasic.msi の語はありません。

CrowdStrike は、[ブログ](https://www.crowdstrike.com/en-us/blog/how-clickfix-attacks-work-and-how-to-stop-them/)で2026年版 Global Threat Report を引用し、偽 CAPTCHA を使った事案が2025年に563%増えたと書いています。

### Forescout が報告した ROMULUS

[Forescout の記事](https://www.forescout.com/blog/romulus-analysis-of-a-new-multi-payload-clickfix-delivery-platform/)（10月15日公開）は、ROMULUS という複数のペイロードを配る ClickFix の配信基盤を分析しています。同じ認証画面を出す6つの IP アドレスを特定し、LegionLoader の配布や、約881.7MBに水増しされた実行ファイルを報告しています。Help Net Security は、ROMULUS のサーバーの1つが、Siemens が AllMyBasic.msi の配布経路として挙げた IP アドレスと同じだと伝えています。ただし、Plus 5.6 経由の感染が Siemens Software Center を使うものだったとは、どの一次情報にも書かれていません。

### 読者がすること

- Siemens Software Center は V4.0.9.8 以降に更新し、公式の Siemens の配布元だけから入手する
- 見覚えのない MSI や DLL がないか、Siemens ProductCERT のブログにある検知の目安と照らして確認する
- ブラウザの画面から、PowerShell などのコマンドを実行するよう求められたら、実行せずに止める

動画の訂正です。

- 動画では、Huntress によると「40件を超える」インシデントが「1つの Google Sites のページ」につながっていたと紹介しましたが、Huntress の記事は「少なくとも40件」で、起点は特定の Google Sites のドメインです。この40件と Siemens の連鎖が同じだとも書かれていません（[Huntress](https://www.huntress.com/blog/chatgpt-custom-gpts-clickfix-rat)）。
- 動画では、OpenAI が9月25日に最初の偽 GPT を削除し、攻撃者が2日後に代わりの GPT を動かし始めたと紹介しましたが、Huntress の記事は、Huntress が OpenAI に連絡して9月25日までに削除されたこと、9月27日に Huntress が新しいカスタム GPT を見つけたことを書いています。攻撃者が稼働を始めた日とは書かれていません。

## まとめ

CVE-2026-0257 は、5月の修正が適用されない環境で、10月も狙われています。Linus 氏が AI を使って書いたパッチは、Shutsemau 氏の手で18本の RFC になり、取り込みの前に未解決の点が整理されました。Linux-libre は、リリースのたびに新しい blob 名を掃除します。EDAC の4ドライバは、実機で試せないまま AI 生成の修正が届く状況を理由に、メンテナ不在になりました。Siemens Software Center の脆弱性は、署名のある正規のソフトの隣に DLL を置く形で悪用されています。この共通点は書き手の考察です。

確かめることを挙げます。

- PAN-OS の GlobalProtect を使っているなら、版を修正版と照らし、認証オーバーライドクッキーの証明書を使い回していないか確認する
- ページキャッシュの RFC は、取り込まれたものと読まず、議論の経過を見る
- Linux-libre を使うなら、ディストリビューションの案内で、追従する版を確認する
- ECC メモリのサーバーや Arm SoC の古い機器を使っているなら、`lsmod` で EDAC ドライバの有無を確かめる
- Siemens Software Center を入れているなら、V4.0.9.8 以降に更新する

## 参考リンク

- [Palo Alto Networks のアドバイザリ CVE-2026-0257](https://security.paloaltonetworks.com/CVE-2026-0257)
- [Unit 42 のブリーフ](https://unit42.paloaltonetworks.com/active-exploitation-of-pan-os-cve-2026-0257/)
- [Shutsemau 氏の RFC カバーレター](https://lore.kernel.org/linux-mm/20261019154913.1765974-1-kas@kernel.org/)
- [GNU Linux-libre 7.3-gnu のアナウンス](https://www.fsfla.org/pipermail/linux-libre/2026-October/003671.html)
- [EDAC pull request のマージコミット](https://github.com/torvalds/linux/commit/ae171014b7988fabf1dbbc7cc4036c416a5b0230)
- [Siemens SSA-580366](https://productcert.siemens.com/productcert/html/ssa-580366.html)
- [Huntress の偽カスタム GPT の記事](https://www.huntress.com/blog/chatgpt-custom-gpts-clickfix-rat)
- [Forescout の ROMULUS の分析](https://www.forescout.com/blog/romulus-analysis-of-a-new-multi-payload-clickfix-delivery-platform/)

（2026/10/21 Linux・OSSトレンド）
