---
title: "NoisyTCP は待ち受け中の Linux サーバーに認証なしで届くカーネルパニック、uBlock Origin の要素ピッカーに1クリックの UXSS、Debian 12 の 6.1.0-55 は ext4 でハング、Qwen4-Max の活性は 710億、FBI が ARTEX を警告（2026/11/17 Linux・OSSトレンド）"
date: 2026-11-17T00:00:00+09:00
draft: false
tags: ["セキュリティ", "Linux カーネル", "CVE", "Debian", "uBlock Origin", "ブラウザ拡張", "AI", "Qwen", "FBI"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

攻撃も修正も速くなった今、すぐ当てる速さと、すぐ戻せる備えを、どちらも持てているか。2026年11月17日（火）の動画は、これをテーマに5本を並べました。

Linux カーネルの TCP の欠陥 NoisyTCP は、待ち受けているサーバーに認証なしで届き、カーネルパニックを起こします。uBlock Origin の Firefox 版では、要素ピッカーを悪用した UXSS が報告されました。Debian 12 のカーネル更新 6.1.0-55 は、ext4 でシステムが固まる不具合が出て、修正版が公開されています。Alibaba の Qwen4-Max は、総パラメータ 2.4兆のうち 710億だけを使う設計です。FBI は、AI が侵入を自動で進めるフレームワーク ARTEX について FLASH を出しました。

5本に共通点を見るのは書き手の考察で、各社や報告者の主張ではありません。動画の訂正は、各節の末尾にまとめています。確認は2026年11月17日（日本時間）で、時点で変わる値には時刻を添えます。NoisyTCP の NVD・Debian・Red Hat は15:55〜16:10、Debian のバグは16:00〜16:20、FBI の FLASH は16:00〜16:10ごろの確認です。

{{< youtube "9HP-Vo0UUv8" >}}

## 1. NoisyTCP（CVE-2026-99288）

NVD の CVE-2026-99288 の記録は、11月10日（UTC）に公開されました。日本時間では11月11日（水）4:22です。研究者の Hyunwoo Kim 氏による詳報は、[oss-security](https://www.openwall.com/lists/oss-security/2026/11/15/2) の投稿で、11月16日（月）1:00（日本時間）です。題名は "NoisyTCP: Linux Kernel TCP Pre-auth Remote Corruption" です。

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-99288) の説明によると、確立済み接続の検索はロックを取らずに行われ、ソケットのメモリは再利用されます。古い接続を見ていたつもりの読み手が、同じ組の新しい接続の要求ソケットをつかむことがあります。この新しいソケットはまだ一覧に載っておらず、待ち受け側を指す情報が空（NULL）のため、NULL ポインタ参照でカーネルパニックになります。

条件は次のとおりです。Kim 氏は、"plain" TCP listener、つまり攻撃者のパケットが直接届く待ち受けのサーバーに、認証なしで遠隔から起こせると書きます。例として、既定の設定の Nginx、Apache、SSH のサーバーを挙げています。受信キューが2本以上あるか、RPS で複数の CPU に分けている環境が対象です。実測は、QEMU/KVM 上の仮想マシンで約5秒〜2分、受信キューが8本ある静かな物理サーバーの Nginx で約14時間でした。後者は、環境に合わせて調整した PoC を使っての値です。コンテナで動く Web サーバーに起こすと、アプリだけでなくホスト全体が止まる、とも書かれています。

問題のコードは、2015年のコミットで入りました。原因コミット 079096f103fa の commit date は2015年10月3日で、Linux 4.4（2016年1月）から含まれます。Kim 氏は、約11年潜んでいた、と書いています。修正は、本流に11月3日に取り込まれました。NVD に載る修正済みの版は 6.12.117、6.18.63、7.3.4 です。

CVSS は、NVD（状態は Received）にも CNA の kernel.org にも採点がありません。Red Hat は、暫定の CVSS v3.1 で 7.5（Important）としています。同じページに、このカーネルパニックの経路はデータの改変や任意コード実行を許さない、とも書かれています（[Red Hat](https://access.redhat.com/security/cve/cve-2026-99288)）。

Debian の配信状況は、[セキュリティトラッカー](https://security-tracker.debian.org/tracker/CVE-2026-99288)で確認できます。2026年11月17日の午後の時点で、trixie は DSA-6628-1（11月13日 UTC）の 6.12.117-1、bookworm は DLA-4906-1（11月15日 UTC）の 6.1.192-1 で配信されています。トラッカーでは bookworm (security) の 6.1.192-2、sid の 7.3.4-1 も fixed です。Debian 以外のディストリビューションの状況は、この記事では確認していません。

暫定策は、oss-security と Red Hat のページに2つ載っています。SYN cookie の無効化と、受信キューを1本にして RPS・RFS を止めることです。SYN cookie を無効にすると SYN flood への防御が下がり、設定はネットワーク名前空間ごとに適用が要る、と oss-security は書きます。値や手順は、一次のページを見てください。oss-security は、パッチの適用が優先、としています。

動画の訂正です。

- 動画では、研究者が、この不具合が将来、遠隔からのコード実行に発展する可能性にも触れている、と紹介し、パネルにも出しました。正しくは、研究者の oss-security の投稿に遠隔コード実行への言及はありません。別の経路で use-after-free（解放後のメモリの利用）を起こせるが、入れ子の競合が必要で、特別な手法なしには起こしにくい、と書かれています（[oss-security](https://www.openwall.com/lists/oss-security/2026/11/15/2)）。Red Hat は、このカーネルパニックの経路はデータの改変や任意コード実行を許さない、と書いています（[Red Hat](https://access.redhat.com/security/cve/cve-2026-99288)）。

## 2. uBlock Origin の要素ピッカーと UXSS

uBlock Origin の Firefox 版（MV2）には、Web ページが要素ピッカーを iframe に埋め込んで操作し、任意の信頼済みフィルタを追加できる問題がありました。GHSA の[勧告](https://github.com/gorhill/uBlock/security/advisories/GHSA-cmqw-9r2w-6wv2)の影響範囲は 1.75.2 以下、修正済みの版は 1.75.4 です。深刻度は High で、CVE 番号と CVSS 値は付いていません。

報告者の Smitty van Bodegom 氏は、[解説](https://iter.ca/post/ubo-uxss/)で、悪意のあるサイトが信頼済みフィルタを追加させ、別のサイトの文脈で任意の JavaScript を動かせる、1クリックの UXSS だと説明しています。ユーザーがページをクリックしたとき、と GHSA も書きます。クリックを誘う部分は、PoC には実装していない、と報告者は書いています。攻撃の段階の具体は、この記事では書きません。

発見の経緯は、報告者の語で次のとおりです。フィルタの注入から UXSS が起こせるのではないかと考え、GPT-5.6 Sol に調べさせたところ、問題が見つかりました。提案された問題は報告者自身が確かめ、PoC のコードの多くは Claude が書いた、とされています。

時系列は、GitHub の時刻が UTC のため、日本時間では日付がずれるものがあります。

- 11月1日: 報告（メール）
- 11月3日: 1.75.4。要素ピッカーの起動に確認済みの秘密のトークンを必須にした
- 11月8日（UTC）: 1.76.0。日本時間では11月9日 2:00。ピッカーが作ろうとするフィルタの検証が入った
- 11月15日（UTC）: 勧告の公開と 1.76.4。日本時間では11月16日の未明（勧告 1:27、リリース 2:24）。1.76.4 では、残りの報告済みのセキュリティ問題が直された

1.76.4 は、確認時点（11月17日）の最新の安定版です。修正済みの版は GHSA では 1.75.4 ですが、その後も修正が続いたため、1.76.4 以上になっているかの確認は書き手の判断です。報告者は、MV3 版の uBO Lite にも似た問題があったが、問題の度合いは小さい（"less problematic"）と書いています。

動画の訂正はありません。日付は UTC で、1.76.0 は日本時間11月9日、公開と 1.76.4 は日本時間11月16日未明です。

## 3. Debian 12 のカーネル 6.1.0-55 のハング

Debian 12（bookworm）のカーネル更新 6.1.0-55（6.1.192-1）で、更新後にシステムが固まる不具合が[バグ #1154101](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154101) に報告されました。重大度は critical です。報告者は、リモートからもローカルからも応答せず、電源の操作で復旧したと書いています。6.1.192-1 は、11月15日（UTC。日本時間では11月16日 4:17）に [DLA-4906-1](https://www.debian.org/lts/security/2026/dla-4906) として配信された版です。同じ症状の報告が重複としてまとめられ、2026年11月17日 16時の時点で12件が合流しています。

原因は、Debian の[マージリクエスト 2168](https://salsa.debian.org/kernel-team/linux/-/merge_requests/2168) のパッチ本文によると、ext4 の mballoc を新しいカーネルの形に直したバックポートにあります。新しい側の関数は失敗時にエラーを表すポインタを返し、6.1 では NULL を返します。ところが移した側は、元の IS_ERR() の判定のままで、NULL が素通りします。ブロック割り当ての管理用のページがキャッシュから追い出されたあと、次の割り当てで oops になります。修正は NULL を調べて -ENOMEM を返す形です。

発火の幅について、報告者の1人は、自分の5台で、起動から25秒〜約5時間で落ちたと書いています。仕様ではなく、その人の観測です。確実に再現する方法も報告されていますが、手順は書きません。

戻し方は、報告者の1人が、GRUB から前のカーネル 6.1.0-54 を選んで起動したと書いています。6.1.0-54（6.1.190-1）に戻すと安定したという報告があります。ComputingForGeeks（Mercy Kemei 氏、11月16日更新）は、[手順の記事](https://computingforgeeks.com/debian-kernel-6-1-0-55-freeze-fix/)で、linux-image-amd64 に hold をかけて 6.1.0-55 に戻らないようにし、修正版が出たら hold を外す方法と、前のカーネルを消してしまった場合に [snapshot.debian.org](https://snapshot.debian.org/) から取る方法を書いています。

修正版は、確認時点では公開済みです。バグは11月16日 20:53（UTC。日本時間では11月17日 5:53）に、6.1.192-2 で修正された状態になりました。security.debian.org の oldstable-security の Packages（11月17日 5:44 UTC 発行）では、メタパッケージ 6.1.192-2 が linux-image-6.1.0-56-amd64 に依存しています。つまり修正版のイメージは 6.1.0-56 です。hold をかけていた場合は、`apt-mark unhold` で外してから更新します。6.1.192-2 の LTS 勧告は、確認した範囲では見つかっていません。

2023年にも前例があります。2023年12月、Debian は 6.1.64-1 の ext4 のデータ破損を理由に、Debian 12.3 のイメージの公開を見合わせました（[debian-announce](https://www.debian.org/News/2023/2023120902.en.html)）。2件だけで傾向を言うのは書き手の考察の域を出ません。

動画の訂正です。

- 動画では、確実な再現手順の数を挙げました。放送で挙げたファイルの数は、バグ報告の投稿と一致していませんでした。確実に再現する方法が報告されている点は変わりません（[バグ #1154101](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154101)）。

## 4. Alibaba の Qwen4-Max

Alibaba は、11月16日（月）に Qwen4-Max の[発表](https://www.alibabacloud.com/blog/alibaba-unveils-qwen4-max-new-ai-teammate-for-work-creativity-and-discovery_603783)を出しました。ブログの dateline は "Hangzhou, China, November 16, 2026" で、時刻の記載はありません。総パラメータは 2.4兆で、1トークンあたり使うのは 710億です。同じ 2.4兆規模の前世代 Qwen3.8-Max より、活性パラメータが25%少ない、と Alibaba は説明します。前世代の活性は、Alibaba の[8月3日の発表](https://www.alibabagroup.com/document-2021044032125272064)では 950億です。コンテキストは100万トークンで、画像を直接扱えます。変更は、注意（attention）、残差接続、埋め込みの3か所です。専門家の数や振り分けの詳細は、Alibaba Cloud のブログには書かれていません。

Alibaba は、Code Arena で6位に入ったと説明しています。Code Arena 側のページは取得できず、確認できていません。Work360 は、Alibaba 独自の評価（721分野）です。Alibaba は、前世代より High effort の推論モードで35%少ないトークンで、タスクあたりの平均コストは約60%下がったとしています。いずれも自社評価です。

価格は、ブログに書かれているのは、キャッシュヒット時の入力が100万トークンあたり $0.075 という値です。通常の入力と出力の価格は、ブログには書かれていません。価格や提供範囲は、2026年11月17日時点のブログの記載です。TechNode は、11月11日に限定プレビューが始まったと報じています（[TechNode](https://technode.com/2026/11/16/alibaba-launches-qwen4-max-with-lower-api-prices-and-a-million-token-context-window/)）。

Qwen4-Max の重みの扱いは、ブログは API とアプリでの提供を書き、重みの公開には触れていません。Qwen4 シリーズの小型のオープンウェイトモデルは "will soon be released" とされ、サイズは明かしていません。日付もありません。

動画の訂正です。

- 動画では、9月の Apsara Conference で Qwen4-Max などの名前を発表した、と紹介しました（パネルは「9月 発表」）。正しくは、9月22日の Apsara Conference で Alibaba が明らかにしたのは、次世代モデルの Qwen 4 が学習中だということです。Qwen4-Max などの名前を公式に発表したとする一次は確認できません（[Alibaba のプレスリリース（TelecomTV の転載）](https://www.telecomtv.com/content/digital-platforms-services/alibaba-unveils-roadmap-on-full-stack-ai-strategy-from-chips-cloud-infrastructure-and-models-to-agents-56308/amp/)）。

## 5. FBI の FLASH と AI ハッキングフレームワーク ARTEX

FBI は、11月13日（金）付の FLASH（文書番号 FLASH-20261113-001）で、ARTEX を取り上げました（[FLASH](https://www.ic3.gov/CSA/2026/261113.pdf)）。ARTEX は Go で書かれた、自律型の複数エージェントのペンテスト用プラットフォームです。2026年7月に GitHub で公開され、FLASH は、少なくとも8月から複数の攻撃者が使っていると書きます。自前の AI モデルは持たず、Claude、GPT、DeepSeek、GLM、Grok、Kimi などの外部の LLM につないで動きます。自然言語の目標を、専門のエージェントが実行する命令に変え、最初の目標設定のあとは人の関与がほとんどなく、偵察からデータの持ち出しまでを機械の速さで進める、とされます。使い方や設定は、この記事では書きません。

FLASH は、技術の乏しい攻撃者でも、少人数で、これまで手の届かなかった規模の同時攻撃ができる、と書きます。侵入のなかには、最初の狙いから特権アクセスまで3時間未満のものがあります（FLASH の脚注は Microsoft）。FLASH の TTP の表には、エンドポイントのセンサーの導入状況を調べ、CrowdStrike Falcon の入っていない Windows 端末を探した、という記載もあります。

標的は、FLASH によると、ARTEX を使った攻撃全体で、金融、政府、技術、防衛、半導体、エネルギー、医療、製造、通信、法律の10分野です。韓国の金融機関への攻撃では、約6万7000人分の個人情報が持ち出されたとされます。

個別のグループは、出典を分けて書きます。BleepingComputer は、CrowdStrike の報告として、中国系とされる Vapor Panda が14か国の200超の組織を狙ったと報じています（[BleepingComputer](https://www.bleepingcomputer.com/news/security/fbi-warns-artex-ai-hacking-tool-is-powering-global-cyberattacks/)）。Microsoft は、10月21日の[ブログ](https://www.microsoft.com/en-us/security/blog/2026/10/21/storm-0940-uses-artex-agentic-ai-connectwise-supply-chain-compromise/)で、China-state aligned（中国の国家と足並みをそろえる）と説明する Storm-0940 が ARTEX を使ったと報告しました。ConnectWise Cloud Backup のサプライチェーンの侵害の件で、Microsoft は2,250超のテナントへのサインインの試行、FLASH は2,250超の下流テナントへのアクセスを可能にしたと書きます。

開発者は、悪用の報告を受けて、10月8日（木）にリポジトリを公開しなくなりました。それでも、コミュニティのフォーク、複製、商用版の ARTEX PRO で流通が続いている、と FLASH は書きます。入手先は書きません。FLASH は、2026年11月初めの時点で、インターネットから見える ARTEX のコンソールが1,600超あったとしています（脚注は Censys の11月5日の記事）。

FLASH が挙げる対策には、公開アプリの洗い出しと管理用のインターフェースを信頼できる経路に限ること、重要な業務 API への回数などの制限があります。LLM の API への外向き通信は、FLASH の指標の表（出典は Zscaler）にある項目で、ほかの不審な動きと合わせて調べる、という注記つきです。

動画の訂正はありません。

## まとめ

5本の共通点が、速さと戻しやすさにあるという見方は、書き手の考察です。実務で確かめておくものは次のとおりです。

- NoisyTCP: 自分のディストリビューションの修正版を確かめる。Debian は trixie が 6.12.117-1、bookworm が 6.1.192-1 以降で配信済み（11月17日午後の確認）。暫定策は oss-security と Red Hat のページに書かれた範囲で、本命はパッチ
- uBlock Origin: Firefox 版の版を確かめる。GHSA の修正済みは 1.75.4 で、1.76.4 以上かの確認は書き手の判断
- Debian 12: 6.1.0-55 で固まった場合は、6.1.0-54 に戻して様子を見る。修正版は 6.1.0-56（メタパッケージ 6.1.192-2）で、hold をかけたなら `apt-mark unhold` で外す
- Qwen4-Max: 乗り換えるなら、自分の用途で出力を確かめる。数値の多くは Alibaba の自社評価
- ARTEX: FLASH が挙げた対策から、公開アプリの洗い出しと管理用のインターフェースの制限を点検する

## 参考リンク

- [oss-security: NoisyTCP（Kim 氏）](https://www.openwall.com/lists/oss-security/2026/11/15/2)
- [NVD: CVE-2026-99288](https://nvd.nist.gov/vuln/detail/CVE-2026-99288)
- [Debian セキュリティトラッカー: CVE-2026-99288](https://security-tracker.debian.org/tracker/CVE-2026-99288)
- [Red Hat: CVE-2026-99288](https://access.redhat.com/security/cve/cve-2026-99288)
- [GHSA: uBlock Origin の要素ピッカー](https://github.com/gorhill/uBlock/security/advisories/GHSA-cmqw-9r2w-6wv2)
- [報告者の解説（iter.ca）](https://iter.ca/post/ubo-uxss/)
- [Debian バグ #1154101](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1154101)
- [DLA-4906-1](https://www.debian.org/lts/security/2026/dla-4906)
- [Alibaba Cloud: Qwen4-Max の発表](https://www.alibabacloud.com/blog/alibaba-unveils-qwen4-max-new-ai-teammate-for-work-creativity-and-discovery_603783)
- [FBI FLASH: ARTEX](https://www.ic3.gov/CSA/2026/261113.pdf)
- [Microsoft: Storm-0940 と ARTEX](https://www.microsoft.com/en-us/security/blog/2026/10/21/storm-0940-uses-artex-agentic-ai-connectwise-supply-chain-compromise/)

（2026/11/17 Linux・OSSトレンド）
