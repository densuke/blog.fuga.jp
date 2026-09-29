---
title: "パッチ当日に攻撃開始、8年塩漬けのLZ4に返済案 — 古いものは危険か資産か（2026/9/29 Linux・OSSトレンド）"
date: 2026-09-29T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "WordPress", "Kubernetes", "CRI-O", "コンテナ", "Linuxカーネル", "LZ4", "Intel Arc", "DXVK", "AI"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

古いコード、古いバージョン範囲、古い設定。今日の5本を並べてみると、「過去から持ち越したもの」がそれぞれ違う顔を見せています。WordPress では10年分のバージョン範囲がそのまま攻撃面になり、CRI-O では過去に取ったチェックポイントを戻すと、宛先で課したはずの制限がすり抜けられる。逆に LZ4 では8年放置したフォークを返済すれば性能が上がるという提案が出て、Intel の新しい拡張は2022年から続く因縁の続きでした。古いものは危険にも資産にもなる。今日はその両方の実例です。

{{< youtube "Ccvbgjh26yQ" >}}

## 1. WordPress のパストラバーサルRCE — パッチ当日に攻撃開始、CrowdSecは12万件超のシグナルを観測

最初は今日いちばん急ぐ話です。WordPress コア（影響バージョン 4.7.0〜7.1.1）の `get_page_template()` にパストラバーサル脆弱性が見つかり、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-87902) は CVSS v3.1 で **8.1（High）** と評価しています。ベクタは `AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H` です。

[Equixly の技術解析](https://equixly.com/blog/2026/09/24/cve-2026-87902-from-wordpress-path-traversal-to-rce-via-pear/)によると、未認証の攻撃者が二重エンコードしたパストラバーサル列を `pagename` パラメータに埋め込むと、初期のサニタイズをすり抜けます。WordPress はカスタムページテンプレートを `validate_file()` で検証しますが、`pagename` から作られる候補パスには同じ検証をかけていません。この非対称さが、テーマディレクトリ外の PHP ファイルを読み込ませる入り口になります。

このローカルファイルインクルージョン（LFI）が RCE に化けるには条件が要ります。Equixly は影響テーマとして Twenty Twelve・Twenty Fourteen・Neve・Hestia・Sydney を挙げています。[Patchstack の記事](https://patchstack.com/articles/cve-2026-87902-attackers-started-probing-wordpress-sites-hours-after-the-patch/)は、`register_argc_argv` が有効で、サーバ上の `pearcmd.php` に到達できることを条件として確認しています。攻撃は PEAR コマンドラインツールの `config-show` から `config-create` へ進む2段階のリクエストで、任意の PHP を書き込む形が観測されました。

怖いのは時系列です。Patchstack は最初の攻撃を **9月22日 11:49 UTC** に観測しており、"whoever built them was working from the diff rather than from an independent discovery"（攻撃者は独自に発見したのではなく、パッチの差分から攻撃コードを作った）と書いています。発見者 Robert Ressl の PoC リポジトリが GitHub に作られたのは、同じ日の **18:40 UTC** です。つまり最初の攻撃は PoC 公開より先で、パッチの差分そのものが攻撃者の手がかりになりました。

その後、[CISA が9月25日にKEVカタログへ追加](https://www.cisa.gov/news-events/alerts/2026/09/25/cisa-adds-one-known-exploited-vulnerability-catalog)し、連邦機関の修正期限は9月28日でした。[CrowdSec の追跡](https://www.crowdsec.net/vulntracking-report/cve-2026-87902-wordpress-vulnerability)では、攻撃シグナルは9月27日に124,154件でピークに達し、9月28日時点のユニークIPは30,813に上ります。

修正版は 7.1.2 / 7.0.6 / 6.9.9 / 6.8.10 など各ブランチの最新版です。すぐに上げられない環境では、`register_argc_argv` を Off にする、不要な `pearcmd.php` を削除・移動する、といった緩和策が有効です。

## 2. CRI-O のチェックポイント復元が権限境界を突破 — ただし修正版は既にリリース済み

2本目はコンテナランタイムです。CRI-O の CVE-2026-92574 は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-92574) の記述によれば「悪意あるチェックポイント済みコンテナから Pod を作成できるユーザーが、宛先の Kubernetes セキュリティコンテキストを回避できる」というものです。CVSS v3.1 は **8.8（High）** 、CWE-250。CRIU のチェックポイントから復元する際、宛先 Pod の seccomp や capabilities といった設定が強制されず、チェックポイント側の権限のまま動き得る、という設計上の穴です。影響製品は CRI-O 本体と Red Hat OpenShift Container Platform です。

同じ週に、containerd でも似た性質の問題が独立して開示されました。[containerd の Security Advisory](https://github.com/containerd/containerd/security/advisories/GHSA-p7v4-vr35-mj6f)（CVE-2026-95837）の題名は「Checkpoint restore bypasses destination security context」です。ただしこれは containerd 自身のアドバイザリで、影響範囲は `containerd/v2` の2.1.0〜2.2.7未満と2.3.0〜2.3.4未満。CRI-O とは別プロジェクトの別脆弱性です。

うれしいことに、修正版はもう出ています。[CRI-O の Releases](https://github.com/cri-o/cri-o/releases/tag/v1.34.14) によると、1.34.14 / 1.35.9 / 1.36.6 の3系列が9月21日にリリース済みです。リリースノートに CVE 番号の記載はありませんが、どれも「`checkpoint_restore.container_level_enabled` オプションを新設し、既定値を `checkpoint_only` にする」という同じ変更を含んでおり、本脆弱性への対応と見られます。緩和策がデフォルトの動作として入った形です。野生での悪用報告は、本稿執筆時点で確認できていません。

## 3. Linux カーネルの LZ4、8年ぶりの再同期はまだ提案段階 — 上流に積み上がった488コミット

3本目はセキュリティではなく、技術的負債の返済案件です。Samsung のエンジニア Michal Wilczynski 氏が、カーネル内の LZ4 実装を「フォークして個別に保守する」方式から「上流ソースをそのままベンダリングする」方式へ切り替える9パッチの [RFC シリーズを9月25日に投稿](https://lkml.rescloud.iu.edu/2609.3/03856.html)しました。件名は `[PATCH RFC 0/9] lib/lz4: stop forking upstream LZ4, vendor it instead` で、その名の通りまだ議論段階です。9月28日時点で Eric Biggers 氏は好意的なコメントを寄せつつも Ack はしておらず、Sergey Senozhatsky 氏はバイナリサイズが42%超増える点を指摘するなど、レビューが続いています。メインラインにはまだ入っていません。

カーネル内のコピーは2017〜2018年頃を最後に実質的な更新が止まっており、カバーレターによれば、その間に上流の `lib/` には **488件のコミット** が積み重なっていました。カーネル側にはそのどれも反映されていません（LZ4 v1.10.0 のリリースに統合された「600件超」とは別の集計です）。ベンダリング後は、既にカーネルに入っている `lib/zstd` と同じレイアウトを踏襲します。

性能面では、カバーレターのベンチマーク表で EROFS の4Kブロックが約11%、64Kブロックが約14%、ライブラリ単体の展開では16Kブロックで約21%の改善が示されています。細かい変更点も並べておきます。

- `LZ4HC_MEM_COMPRESS` が262,192バイトから262,200バイトへ8バイト増える
- HC レベル10以上は9に丸められる。拒否せずクランプすることで、既存の f2fs や zram の設定を壊さないための措置
- `LZ4_stream_t` / `LZ4_streamHC_t` は不完全型に変わる
- 5アーキテクチャ（arm・mips・parisc・s390・x86）のプリブートデコンプレッサに freestanding ヘッダを適用

圧縮出力は一部の入力で1〜2バイト変わる可能性がありますが、新旧の実装は互いのデータをデコードできるので、ディスク上の既存データの意味は変わりません。なお Wilczynski 氏は同じシリーズで自身を新規メンテナーに加えることも提案していますが、こちらも提案段階です。

ベンダリング元の[上流 LZ4 v1.10.0](https://github.com/lz4/lz4/releases/tag/v1.10.0)（通称 Multicores edition、2024年7月21日リリース）は、マルチスレッド対応・辞書圧縮の正式化・レベル2の追加などを含み、特定条件下ではレベル12で旧版の7倍以上の速度が報告されています。LZ4 の設計者は Yann Collet 氏です。

## 4. Linux 7.3-rc5 — 577コミットの「いつも通り」と、AIが掘り返す古いコード

4本目はカーネル本体の話です。[Torvalds 本人のrc5アナウンス](https://lwn.net/ml/all/CAHk-=wi-0ue4KWEGBfGFJTEkjh0-oMNpG=wNJ7pj4Ox1Eta67g@mail.gmail.com)は「ドライバは3分の1未満、4分の1はセルフテストにすぎない」と書き、diffstat について "admittedly a bit misleading" と注記しています。最大の単一パッチは arm64 KVM の ITS テーブルテストで、締めは "nothing looks particularly alarming...it's just the same old, same old"（特に警戒するようなものはなく、いつも通りだ）でした。

[Linux Compatible の集計](https://www.linuxcompatible.org/story/linux-kernel-73rc5-released-577-commits-unusual-diffstat-same-old-fixes)では577コミット・275人の貢献者で、うち184人（67%）が単独コミット、最多は XFS 作業で22コミットの Darrick J. Wong 氏でした。同記事はネットワーキング（mlx5e・bcmgenet・stmmac・ovpn など）や、arm64 のステージ2ページテーブル競合修正といった内訳も伝えています。個別のパッチでは、Intel Xe ドライバに Crescent Island 向けの電力ブレーキ（power brake）をスロットル理由として報告する仕組みが入りました。

背景にはAIによる脆弱性発見の急増があります。[TechSpot の報道](https://www.techspot.com/news/113716-ai-finds-1500-vulnerabilities-linux-kernel-linus-torvalds.html)によると、Torvalds は7.1-rc4の時点で、カーネルの非公開セキュリティメーリングリストが「ほぼ手に負えない（almost entirely unmanageable）」状態になったと発言しています。報告件数は週2〜3件から1日5〜10件へ増え、およそ10倍以上の増え方です。一方で同記事は「文書化されたCVEの大半は低優先度か、旧式ドライバや長年非推奨の機能に関するもの」とも指摘しています。中国のAI企業 Z.ai の LLM「GLM-5.3」が主要OSS全体で1,000件超の重大脆弱性の発見を助けた、という話も同記事にあります。さらに、多くのCVEを抱えていた古いドライバ群とともに ISDN サブシステム全体が整理されたとも伝えていますが、削除の直接の理由がAIの指摘だとまでは書かれていません。

AIとの距離感をよく表しているのが、Torvalds 自身の[7.3-rc2での発言](https://lwn.net/Articles/1092756/)です。"we'll obviously all blame it on AI, because whether that's really the cause or not, it's an easy thing to blame"（本当の原因かどうかはさておき、AIのせいにするのは簡単だ）。[7.3-rc3の報道](https://www.linuxcompatible.org/story/linux-kernel-73rc3-released-big-filesystem-footprint-and-aiassisted-patches)では、多くのコミットに `Assisted-by: Claude` や `Assisted-by: LLM` というトレーラーが付いていたとも伝えられています（rc5 で同じ傾向が続いているかは確認できていません）。ディストリビューション側では、Ubuntu 26.10（10月15日リリース予定）が7.3のプレリリース版を搭載する見込みで、7.3の安定版は10月18日前後になると報じられています。

## 5. Intel dxvk-igdext 公開 — Arc GPU 拡張、NVIDIA 向けと同じパターンを踏襲

最後は明るい話題です。Intel は [GameTechDev/dxvk-igdext](https://github.com/GameTechDev/dxvk-igdext) を MIT ライセンスで公開しました。README によれば、DXVK 環境でゲームが「Intel D3D11 Graphics Extensions」（UAV overlap・MultiDrawIndirect・depth bounds）を使えるようにする Linux/Wine 専用の実装です。38個のエクスポート関数を持ち、`_INTC_` プレフィックスの新API群と、それ以前の旧ABI（`D3D11CreateDeviceExtensionContext`）の2世代に対応しています。D3D12 向けのエントリは現状スタブ（何もしない実装）です。

[GamingOnLinux の報道](https://www.gamingonlinux.com/2026/09/intel-gpu-support-with-proton-should-get-better-with-dxvk-igdext/)は "Much like we have DXVK-NVAPI for NVIDIA but this one is for Intel"（NVIDIA向けのDXVK-NVAPIと同じように、これはIntel向けだ）と紹介しています。dxvk-igdext は既に Proton Experimental の bleeding-edge ビルドに統合済みです。Intel が独自の道を切り開いたというより、NVIDIA 向けで出来上がっていた形に乗ったと見るのが正確でしょう。

Intel と DXVK の縁は今回が最初ではありません。[GamingOnLinux の2022年12月の記事](https://www.gamingonlinux.com/2022/12/intel-using-dxvk-part-of-steam-proton-for-their-windows-arc-gpu-dx-9-drivers/)は、Windows 版 Arc ドライバの readme から、D3D9 の処理に DXVK が使われていることを見つけて報じていました。当時 Intel はこれを公式には公表しておらず、言及を消そうとした形跡もあったと同記事は指摘しています。

受け皿の側も整っています。[DXVK 3.1](https://github.com/doitsujin/dxvk/releases/tag/v3.1)（2026年8月28日 UTC 公開）では、Intel GPU 使用時に Intel 固有の拡張ライブラリをロードする仕組みが入り、AMDAGS や NVAPI の拡張と同様に動くと説明されています。対象の GPU 世代は README に明記がないので、ここでは Arc 世代向けとしておきます。

## まとめ

今日の5本は、「過去から持ち越したもの」の扱い方の違いで並んでいました。WordPress は10年分のバージョン範囲がそのまま攻撃面になり、パッチ公開当日に攻撃が始まりました。CRI-O はチェックポイントという過去の状態を戻す処理が権限境界を破りましたが、修正版は既に出ています。LZ4 は8年放置されたフォークをようやく返済しようとしている最中で、まだレビュー段階です。7.3-rc5 は AI による報告が急増するなかでも「いつも通り」と評され、dxvk-igdext は2022年からの縁が形になった公開でした。

古いものをそのまま置いておけば危険になり、手を入れれば資産になる。WordPress はパッチの差分から数時間で攻撃が組まれ、LZ4 は8年分の差をようやく詰めようとしています。気づいてから手を入れるまでの速さが、そのまま分かれ目になっているように見えます。手元の環境でも、更新を止めたまま動いているものがないか、棚卸ししてみる価値はありそうです。

## 参考リンク

- [NVD — CVE-2026-87902（WordPress）](https://nvd.nist.gov/vuln/detail/CVE-2026-87902)
- [NVD — CVE-2026-92574（CRI-O）](https://nvd.nist.gov/vuln/detail/CVE-2026-92574)
- [LZ4 ベンダリング RFC パッチシリーズ（LKMLミラー）](https://lkml.rescloud.iu.edu/2609.3/03856.html)
- [Linux 7.3-rc5 アナウンス（Torvalds、LWNミラー）](https://lwn.net/ml/all/CAHk-=wi-0ue4KWEGBfGFJTEkjh0-oMNpG=wNJ7pj4Ox1Eta67g@mail.gmail.com)
- [Intel dxvk-igdext リポジトリ](https://github.com/GameTechDev/dxvk-igdext)
