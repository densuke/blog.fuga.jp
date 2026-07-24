---
title: "1行の穴が1640万台を揺らす日 — XFS競合・GitHub Actions悪用・オープンなDLSSまで（2026/7/24 Linux動向）"
date: 2026-07-24T00:00:00+09:00
draft: false
tags: ["セキュリティ", "XFS", "GitHub Actions", "LLVM", "snapd", "NVK", "DLSS", "Linux"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

同じ一日のうちに、「守りを固めたはずの仕組み」が立て続けに新しい穴を開けていました。9年潜んでいたXFSの競合、GitHub Actionsを乗っ取った攻撃キャンペーン、権限を絞った結果生まれたsnap-confineの隙——今日はそんな「引き締めたつもりが緩んだ」一日を、最後はちょっと前向きなオチで締めくくります。

{{< youtube "jnC1_haoR80" >}}

## 1. CVE-2026-64600「RefluXFS」— たった1行の穴が1,640万台を揺らした

いちばん衝撃だったのがこれです。[NVDに登録された](https://nvd.nist.gov/vuln/detail/CVE-2026-64600)CVE-2026-64600、通称「RefluXFS」。XFSファイルシステムのCopy-on-Writeパスにある `xfs_reflink_fill_cow_hole()` 関数で、iノードのロック(ILOCK)を一度解放してから再取得するまでのわずかな隙に、別スレッドが同じファイルのブロック割り当てを済ませてしまうと、古いマッピング情報のまま「このブロックは自分専用」と誤判定し、実は他人と共有しているブロックへ直接書き込んでしまう——という競合状態です。任意ファイルの改ざんからrootを奪えます。

条件はreflink（RHEL 8以降・Fedora 31以降でデフォルト有効）を使っていること。この機能が入ったLinux 4.11（2017年）から数えると、実に約9年もこの穴は誰にも気づかれていませんでした。[Qualysの推定では](https://blog.qualys.com/vulnerabilities-threat-research/2026/07/22/refluxfs-a-linux-kernel-local-privilege-escalation-to-root-in-xfs-cve-2026-64600)全世界で約1,640万システムが対象になるといいます。修正はコミット2f4acd0、ILOCK再取得後にマッピングを読み直す(resample)というたった1行。正直、去年別件でreflinkの恩恵を受けていた身としては、9年分ゾッとする話でした。なおCVSSはNVD上でまだ未評価(N/A)のままです。数値が出ていない以上、ここで勝手に深刻度を作るのはやめておきます。

## 2. cPanel + GitHub Actions悪用キャンペーン — CI/CDが攻撃基地になった

2つ目は、脆弱性そのものより「悪用のされ方」が新しい事案です。発端は[CVE-2026-41940](https://nvd.nist.gov/vuln/detail/CVE-2026-41940)、cPanel/WHMのCRLFインジェクションによる認証バイパス（CVSS v3.1=9.8、v4.0=9.3）。影響はcPanel 11.40以降の広範なバージョンに及びますが、各系列にパッチ適用済みのバージョンがすでに存在しており、「全部が今も危ない」わけではありません。

問題は攻撃者がここからさらに一歩踏み込んだところです。Packagist上の正規PHPパッケージ10本のdev版に悪意あるGitHub Actionsワークフローを注入し、GitHub Hosted ランナーそのものを攻撃インフラに転用していました。認証バイパスの[技術的な詳細はRapid7が解析しています](https://www.rapid7.com/blog/post/etr-cve-2026-41940-cpanel-whm-authentication-bypass/)。規模も相当で、キャンペーン固有のドメインが約6,100件のワークフローファイルに埋め込まれ(GitHubコード検索)、関与したユニークIPは44,000(Shadowserver)、公開状態のcPanelサーバーは約150万台(Shodan)にのぼると報じられています。CISAのKEV(既知の悪用済み脆弱性)カタログにも入っています。開発者が疑うことなく使っているCI基盤が、攻撃者にとっては無料の分散インフラになってしまう——という構図に、少し寒気がします。

## 3. LLVM 23.1-rc1 — AMD Zen 6とAVX-512 BMMが来た

ここでいったん一息。緊急対応が要る話ではありませんが、地味に長生きしそうなニュースです。2026年7月23日、LLVM 23系初のリリース候補23.1.0-rc1が公開され、[LLVM Discussion Forumsのアナウンスによれば](https://discourse.llvm.org/t/llvm-23-1-0-rc1-released/91369)AMD Zen 6(znver6)向けAVX-512 BMM命令(VBITREVB・VBMACOR・VBMACXOR)が正式に組み込まれました。ほかにもx86 LFI(軽量フォルト隔離)、NVIDIA Rigelコアの初期サポート、Arm C1-Ultraのスケジューリング、C++26への部分対応と盛りだくさんです。

正直ここは玄人向けのニッチな話題ですが（コンパイラの中身の話でテンション上がる人、絶対少数派ですよね）、VBMACOR/VBMACXORのビット行列積は1bit/2bit量子化LLM推論と相性がよく、「軽量LLMをローカルで回す時代」に向けたハードとコンパイラの足並みそろえという見方もできます。[Phoronixの記事によると](https://www.phoronix.com/news/LLVM-23.1-rc1)rc1では公式バイナリ未提供、rc2は7月28日予定、安定版は8月末目処とのことです。

## 4. CVE-2026-8933 snap-confine — 権限を絞ったら別の隙間が空いた

セキュリティに話を戻します。[NVDに記載された](https://nvd.nist.gov/vuln/detail/CVE-2026-8933)CVE-2026-8933(CVSS 7.8 High)は、Ubuntuのsnap-confineがsetuid-rootモデルからset-capabilitiesモデルへ移行した「強化」が、皮肉にも新しい競合を生んだ事例です。最小権限を目指した設計変更により、一時ディレクトリの所有権がrootに移るまでの短い窓で非特権ユーザーが所有者になる瞬間ができてしまい、そこをFUSEマウント・シンボリックリンク・udevルールの悪用で突かれるとrootまで到達します。

デフォルトインストールで影響を受けるのは **Ubuntu 24.04 LTS・25.10・26.04** です。22.04 LTSは最新のsnapdに更新済みの場合のみ対象になる、という条件つきなので、両者を同列に並べないよう注意が必要です。修正は[USN-8579-1で提供されています](https://ubuntu.com/security/notices/USN-8579-1)。権限を絞ったはずなのに別の隙間が空くと知ったときは、思わず「うわ、そっちか……」と声が出ました。守りを薄く精密にしようとした反動で、時間軸方向に新しい穴ができる——という構図は、1つ目のRefluXFSともどこか似ています。

## 5. Mesa 26.2.0 RC2 + NVK — オープンソースのVulkanドライバが実験的にDLSSを動かした

締めは前向きな話です。2026年7月22日公開のMesa 26.2.0 RC2で、オープンソースのNVIDIA Vulkanドライバ NVK が実験的にDLSSを動かし始めました。[Mesa公式のNVKドキュメントによれば](https://docs.mesa3d.org/drivers/nvk.html)、`VK_NVX_binary_import` でNVIDIAのプリコンパイル済みCUDAバイナリ(CuBIN)を直接インポートし、`VK_NVX_image_view_handle` でテクスチャハンドルをやり取りする仕組みです。NVKにはまだPTXからNIRへの変換パスが無いため、動的コンパイルの代わりにビルド済みバイナリをそのまま持ち込む——という回避策なのですが、これがけっこう力業で好きです。有効化は環境変数 `NVK_EXPERIMENTAL=dlss` のみ。対象はTuring世代(RTX 2000〜)以降です。

このPRを提出したのは Autumn Ashton。[Phoronixの記事では](https://www.phoronix.com/news/Mesa-NVK-Vulkan-Does-DLSS)PR提出者としてこの名前が明記されていますが、所属についてはここでは断定しません。Valveがゲーミング向けLinuxオープンスタックに継続的に投資してきたのは事実としても、それとAshton個人の所属は別の話です。安定版は8月初旬の見込み。プロプライエタリに独占されがちだった機能が、力業でもオープン実装に降りてくる瞬間は、単純に応援したくなります。

## まとめ

XFS・cPanel・snap-confineの3件は「守りを固めたはずが別の隙間を生んだ」話でしたが、LLVMとNVKは前向きな進歩でした。皆さんは、境界を薄く精密にする強化と、多少不格好でも後方互換を保つやり方、どちらを支持しますか？

## 参考リンク

- NVD CVE-2026-64600 https://nvd.nist.gov/vuln/detail/CVE-2026-64600
- Qualys TRU「RefluXFS」開示ブログ https://blog.qualys.com/vulnerabilities-threat-research/2026/07/22/refluxfs-a-linux-kernel-local-privilege-escalation-to-root-in-xfs-cve-2026-64600
- NVD CVE-2026-41940 https://nvd.nist.gov/vuln/detail/CVE-2026-41940
- Rapid7 ETR「CVE-2026-41940 cPanel/WHM Authentication Bypass」 https://www.rapid7.com/blog/post/etr-cve-2026-41940-cpanel-whm-authentication-bypass/
- LLVM Discussion Forums「LLVM 23.1.0-rc1 Released」 https://discourse.llvm.org/t/llvm-23-1-0-rc1-released/91369
- NVD CVE-2026-8933 / Ubuntu USN-8579-1 https://nvd.nist.gov/vuln/detail/CVE-2026-8933 / https://ubuntu.com/security/notices/USN-8579-1
- Mesa公式 NVKドキュメント https://docs.mesa3d.org/drivers/nvk.html
