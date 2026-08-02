---
title: "68件修正の速さと91本の空席 — 動かし続ける人は誰か（2026/8/3 Linux動向）"
date: 2026-08-03T00:00:00+09:00
draft: false
tags: ["Debian", "Linux カーネル", "Arch Linux", "AUR", "NetBSD", "RISC-V", "Adobe Campaign Classic", "CVE", "サプライチェーン", "セキュリティ"]
categories: ["Linux・OSSトレンド"]
---

今日の糸は2本あります。ひとつは「直す速さ」。Debianはわずか10日前の更新から一転、カーネルで **68件** のCVEを一括修正しました。一方でAdobe Campaign Classicは、同じ認可不備のクラスで **3度目** のCVSS 10.0を出しています。修正の速さと、繰り返される穴の深さが同じ週に並びました。もうひとつは「動かし続ける人」。Arch Linuxを10年支えたFoxboronが去り、91本のパッケージが引き継ぎ先を探しています。同じArchではAURの孤児パッケージが攻撃者の入口にもなりました。退任と乗っ取り、両側から「誰が動かし続けているのか」が見えてきた一週間です。

{{< youtube "p8CB2eZ1CA0" >}}

## 1. Debian 13 "Trixie" カーネルセキュリティアップデート — 68件のCVEを一括修正

Debianプロジェクトは2026年7月31日、Debian 13 "Trixie" 向けセキュリティアドバイザリ **DSA-6405-1** を発行し、`linux` パッケージを 6.12.96-1 から 6.12.100-1 へ更新しました。[Debian Security Tracker](https://security-tracker.debian.org/tracker/DSA-6405-1) を確認したところ、公式アナウンス準拠の修正件数は **68件** ですが、トラッカー上に個別エントリとして並んでいるCVEは約61件でした。差は NVD への登録待ち（RESERVED状態）のCVEが含まれるためです。わずか10日前の [DSA-6393-1](https://lists.debian.org/debian-security-announce/2026/msg00316.html)（12件修正）から一転した件数の多さですが、これは煽り文句というより、Debianが上流カーネルの複数の stable 更新（6.12.97〜6.12.100の4回分）をまとめて取り込んだ結果と捉えるのが妥当です。

注目度が高いCVEとして、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-64000) に掲載されている CVE-2026-64000（CVSS 9.8 Critical、`net/hsr/hsr_forward.c` のHSR冗長化プロトコル実装の欠陥）や、CVE-2026-53359（CVSS 8.8 High / CWE-416、KVMシャドウページングのUse-After-Free）があります。ただし今回、[Debian Security Tracker](https://security-tracker.debian.org/tracker/DSA-6405-1) を実際に確認したところ、この2件はDSA-6405-1のCVEリストには含まれていませんでした。したがってこの2件は「DSA-6405-1で修正された」とは書かず、 **同時期の6.12.100系で修正された注目CVE** という位置づけで紹介します。

もうひとつ話題になったのがCVE-2026-64560（CVSS 7.8 High）です。`kernel/time/posix-cpu-timers.c` など、タイマー削除処理とスレッドの `exec()` 呼び出しが競合するUAFで、根本原因はカーネル初期からの設計に潜んでいたとされます。「16年潜伏」という表現が出回っていますが、これは **2010年に入った回避策以降の期間** を指すものであり、バグ自体が2010年に混入したという意味ではありません。NVDのaffected定義もLinux 5.7以降となっています。また、このCVEについて **PoCの公開や実環境での悪用は確認されていません** 。過去の記事で見かけた「PoCが公開・悪用されている」という記述は、別のCVE（CVE-2025-38352）との取り違えでした。

対処はいつも通りシンプルで、`sudo apt update && sudo apt full-upgrade && sudo reboot` を実行し、`uname -r` で `6.12.100-*` になっているか確認するだけです。HSRを使っていない環境では、`rmmod hsr` による一時的な緩和も有効です。なお、Debian 12 "Bookworm" は別系統のカーネル（5.10系）を使っているため、今回のDSA-6405-1の直接対象外です。10日で68件を仕上げるDebianの運用体制には、素直に感心してしまいます。

## 2. Arch Linux 2026.08.01 ISO — Linux 7.1.5搭載、AUR不正乗っ取り第3波の渦中で

Arch Linuxの8月定期ISO `archlinux-2026.08.01-x86_64.iso` が公開されました。搭載カーネルは **Linux 7.1.5** （前月は7.0.14）で、KDE Plasma 6.7.3・Archinstall 4.4・glibc 2.44・Binutils 2.47・systemd 261.2、収録パッケージ約16,031という構成です。[Arch Linux公式ダウンロードページ](https://archlinux.org/download/)によれば、これは毎月恒例の定期スナップショットであり、特別なイベントではありません。ただし、AUR（Arch User Repository）で第3波となる不正adoption（孤児化したパッケージを別の人が引き受ける仕組み）キャンペーンの報道は7月31日、ISO公開は8月1日と、厳密には1日ずれています。「同じ日」ではなく「同じ週」の出来事として捉えるのが正確です。

AURの不正adoptionは6月12日の第1波が発端で、[Arch Linux公式ニュース](https://archlinux.org/news/active-aur-malicious-packages-incident/)がインシデントを初報しました。当初400以上のパッケージが改ざんされ、最終的な影響は1,500超に達したとされています（旧報道にあった「1,900以上を削除」という数字は出典が確認できず使いません）。第3波の特徴は2段構えのペイロードです。Stage 1のローダーは `dbus-daemon` に偽装してTor経由でC2と通信し、Stage 2ではRust製のインフォスティーラーが展開され、root権限取得後はeBPFでプロセスやファイル活動を隠蔽するという、かなり手の込んだ作りになっています。

対応として、DevOpsのRobin Candauが7月30〜31日にadoption機能そのものを緊急停止しました。第1波を報告したのはDevOpsのCampbell Jonesです。プロジェクトリーダーのanthraxx（Levente Polyák）は2026年6月に無投票で再選されたばかりですが、これを「再選直後最大の危機」と呼ぶのはあくまで編集上の評価であり、断定はしません。影響を受けうるのは `yay`・`paru`・`makepkg` などでAURパッケージをビルドしているArchユーザー全般です。Manjaro・EndeavourOSなど派生ディストリビューションも上流を取り込んでいるため間接的に影響しうると言えますが、「すべての派生ユーザーが影響」と断定できるだけの根拠はありません。安全のためには、ビルド前に **PKGBUILD** をよく確認することが基本です。[Arch公式ニュース](https://archlinux.org/news/active-aur-malicious-packages-incident/)も "review all PKGBUILD and install script changes" と呼びかけており、インストール後はユーザー単位のsystemdサービスに不審なものが増えていないか確認しておくと安心です。

## 3. Arch Linux開発者Foxboron（Morten Linderud）が10年の活動を経て退任

Arch Linuxのデベロッパー・セキュリティチーム・AURメンテナを兼任してきたMorten Linderud（通称Foxboron）が、2026年8月1日付で退任を[arch-dev-publicメーリングリスト](https://lists.archlinux.org/archives/list/arch-dev-public@lists.archlinux.org/message/2AX2BCJ3EQX7G3YXSDX73BR4NCAWXXBZ/)に表明しました。約10年の活動でした。退任メールの書き出しは「It's been almost a decade since I met Jelle, Chris, Levente and Remi at 33C3 to be (peacefully) coerced into joining the security team」という一文です。33C3は2016年12月にハンブルクで開催された第33回Chaos Communication Congressで、そこでanthraxx（Levente Polyák）らに「穏やかに強制された」形でセキュリティチームに誘われたのが始まりだったそうです。

退任メールに添付されたパッケージリストは、 **単独メンテナー不在が52本、共同メンテナー不足が39本、合計91本** という規模でした（メーリングリスト原文を機械カウントして確定した数字で、旧版にあった「70件超」という表現はもう使いません）。単独メンテナー不在の主なものは `mkinitcpio`（initramfs生成スクリプト）・`arch-install-scripts`・`wpa_supplicant`・`fsverity-utils`・`pesign`・`tpm2-*` 系です。共同メンテナー不足には、Arch の核心パッケージマネージャーである `pacman` や `archlinux-keyring`、そしてLinderud自身がGoで開発したSecure Bootキーマネージャー `sbctl` が含まれます。

Linderudの引退の弁で使える一文は「It's time to let go.」（潮時だ）です。似た表現で「a good time to let go」という言い回しが出回ることがありますが、これは原文には存在しない付加であり誤りです。ML上ではCampbell Jones・Leonidas Spyropoulos・Robin Candauらが「May your roads lead to warm sands（道が温かい砂地に続くように）」といった言葉で謝意を伝えています。コミュニティ全体の反応としては、孤児化への懸念と、本人の今後を前向きに見る声が混在していたようです。退任後も `sbctl`・`ssh-tpm-agent`・`attezt` などのOSS開発は継続する予定で、Linderud自身も「Archは卒業するが業界は卒業しない」というスタンスを示しています。

## 4. NetBSD 11.0リリース — 64ビットRISC-V初の安定対応、Snapdragon X1 Elite初期サポート

2026年8月1日、NetBSDプロジェクトが19番目のメジャーリリース「NetBSD 11.0」を公開しました。前回のNetBSD 10.0（2024年3月）から約2年ぶりのメジャーアップデートです。[NetBSD公式リリースアナウンス](https://www.netbsd.org/releases/formal-11/NetBSD-11.0.html)によれば、最大のハイライトは **プロジェクト史上初めて64ビットRISC-Vを安定版に収録した** ことで、StarFive JH7110ベースのVisionFive 2・PINE64 STAR64、Allwinner D1ベースのMangoPi MQ Pro、QEMUが対応プラットフォームとして挙げられています。

AArch64側では、Qualcomm Snapdragon X1 Elite（Oryonコア）への **初期サポート** も加わりました。ドライバ類は主にOpenBSDからの移植で構成されており、バッテリー・充電センサ、GPIO、I2Cコントローラなどが対応しています。「初期サポート」段階であるため、全ペリフェラルの動作が保証されているわけではない点は押さえておきたいところです。

amd64・i386向けには専用のMICROVMカーネルが導入されました。[公式リリースアナウンス](https://www.netbsd.org/releases/formal-11/NetBSD-11.0.html)の記述は「2020年代のx86 CPUで約10ミリ秒で起動できる」というものにとどまり、LinuxのVMやDockerとの具体的な比較数値は公式には示されていません。同じmicroVMカテゴリで軸を揃えるなら、AWS Firecrackerの公称値（InstanceStart APIから `/sbin/init` までで約125ミリ秒）が比較材料になりますが、コンテナとの比較は計測境界が異なるため断定は避けます。

このほか `compat_linux` に `epoll`・`inotify`・`clone3`・`statx` などが追加され、Linuxバイナリを動かせる範囲が広がりました。jemalloc-5.3.0への全面移行、POSIX.1-2024／C23準拠の強化、NPFのL2フィルタリング対応、そしてセキュリティ上の理由によるOpenSSHのDSA鍵サポート廃止も行われています。開発サイクルはRCを7本重ねた末のリリースで、公式ブログも「ようやく（finally）」という言葉を使っています。遅延の一因として、AIツールによる誤検知を含むセキュリティ問題報告の増加が挙げられていました。「pkgsrcの鮮度はArchやGentoo並み」という声もあるようですが、これはコミュニティの個人的な感想として受け止めておくのがよさそうです。

## 5. CVE-2026-48449 — Adobe Campaign ClassicにCVSS 10.0の認証不要RCE

Adobe Campaign Classic（ACC）オンプレミス版v7（7.4.3 build 9397以前）に、認可不備（CWE-863: Incorrect Authorization）を原因とするCVSS v3.1スコア **10.0** の最大深刻度脆弱性CVE-2026-48449が発見されました。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-48449) によれば、CVSSベクターは `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` で、8つの指標すべてが攻撃者に最有利な値を取るという組み合わせです。Adobeは2026年7月29日にアドバイザリ [APSB26-114](https://helpx.adobe.com/security/products/campaign/apsb26-114.html) として協調開示し、修正版build 9398を同時公開しました。NVDへの登録は翌7月30日で、「同日にNVDに登録された」という表現は正確ではありません。野生での悪用は確認されていませんが、Adobeは最高緊急度のPriority Rating 1を付与しており、これは悪用リスクを高く見積もっているサインと言えそうです。過去のACC類似CVEで「公開後数時間で悪用された」という話も見かけますが、これは同時期に公開されたAdobe ColdFusionのCVE（CVE-2026-48282）の事例との取り違えであり、正確ではありません。

同アドバイザリでは、CVSS 8.6・CWE-89（SQLインジェクション）のCVE-2026-48448も同時公開されています。認証不要でサーバー上の任意ファイルを読み取れる脆弱性で、CVE-2026-48449のRCEと組み合わせると設定ファイルや認証情報の奪取からサーバー完全乗っ取りまでの攻撃チェーンが成立しえます。ACCでは2026年に入り、認可不備を根本原因とするCVSS 10.0の脆弱性が **3件連続** で報告されています（CVE-2026-48303・CVE-2026-48286・そして今回のCVE-2026-48449）。同じ認可不備クラスが繰り返されているという事実は、アクセス制御実装に体系的な弱点がある可能性を示唆しています。

Adobe Campaign Classicの導入社数や市場シェアについては、参照した情報源同士で桁が大きく食い違い検証できなかったため、本記事では具体的な数字を書きません。言えるのは「大企業・金融機関・小売業者に普及したエンタープライズ製品」という程度です。Adobeがホストするクラウド版（SaaS）は保護済みで、ハイブリッド構成ではオンプレミス側のコンポーネントのみが影響を受けます。対応の最優先事項はbuild 9398へのアップデートで、パッチ適用前の緩和策として、管理インターフェースやSOAPルーターへのアクセスをVPN経由に限定することが推奨されています（これはあくまで推奨事項であり、Adobeの公式な指示という位置づけではありません）。

## まとめ

Debianが10日で68件のCVEを仕上げられたのは、それだけの人手が回っているからこそ成立する話です。ところがArchでは、Foxboronというたった1人が抜けただけで91本のパッケージが空席になりました。「直す速さ」は「動かし続ける人」がいて初めて成り立つ、という当たり前のようで見落としがちな事実が、今週は両側から浮かび上がってきたように思います。AURの乗っ取りも、孤児化したパッケージという「誰も見ていない場所」を攻撃者が突いた結果でした。皆さんが日常的に使っているパッケージやライブラリは、いったい誰がどれくらいの熱量で支えているでしょうか。たまには依存関係の向こう側に思いを馳せてみるのも悪くないかもしれません。

## 参考リンク

- Debian Security Tracker DSA-6405-1（CVEリスト・影響バージョン） https://security-tracker.debian.org/tracker/DSA-6405-1
- Debian公式セキュリティアドバイザリ DSA-6405-1（メーリングリスト原文） https://lists.debian.org/debian-security-announce/2026/msg00316.html
- NVD: CVE-2026-64000（CVSS 9.8 Critical） https://nvd.nist.gov/vuln/detail/CVE-2026-64000
- NVD: CVE-2026-53359（CVSS 8.8 High / CWE-416） https://nvd.nist.gov/vuln/detail/CVE-2026-53359
- NVD: CVE-2026-64560（CVSS 7.8 High） https://nvd.nist.gov/vuln/detail/CVE-2026-64560
- Arch Linux公式ダウンロードページ https://archlinux.org/download/
- Arch Linux公式ニュース: AURインシデント初報 https://archlinux.org/news/active-aur-malicious-packages-incident/
- 退任表明メール全文（arch-dev-public ML） https://lists.archlinux.org/archives/list/arch-dev-public@lists.archlinux.org/message/2AX2BCJ3EQX7G3YXSDX73BR4NCAWXXBZ/
- sbctl公式リポジトリ（Secure Bootキーマネージャー） https://github.com/Foxboron/sbctl
- NetBSD 11.0公式リリースアナウンス https://www.netbsd.org/releases/formal-11/NetBSD-11.0.html
- NetBSD 10.0→11.0公式変更点リスト https://www.netbsd.org/changes/changes-11.0.html
- NVD: CVE-2026-48449（CVSS 10.0・CWE-863） https://nvd.nist.gov/vuln/detail/CVE-2026-48449
- Adobe公式セキュリティアドバイザリ APSB26-114 https://helpx.adobe.com/security/products/campaign/apsb26-114.html
