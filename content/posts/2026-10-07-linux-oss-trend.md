---
title: "共有の部品は、壊れるときも一緒？ Atlassian CVE-2026-21589・Linux ZRAM の作り直し・Linux Plumbers Conference 2026・mold 3.0（Rust）・Linux 35周年（2026/10/7 Linux・OSSトレンド）"
date: 2026-10-07T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Atlassian", "Linux カーネル", "ZRAM", "Linux Plumbers Conference", "Rust", "mold", "Open Source Summit", "Linux Foundation"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

みんなで共有する部品は便利です。そのかわり、壊れるときも一緒に壊れます。だからこそ、分けて、直して、次へ渡す人たちがいます。今日の5本は、そんな見立てで並べました。

共通点の指摘は書き手の考察です。動画には一次情報と食い違った発言や、裏付けの取れなかった発言があったため、確かめ直した結果を各節末の「動画の訂正」にまとめました。

{{< youtube "w0EPlwCgpg4" >}}

## 1. Atlassian CVE-2026-21589 — Data Center 版 8製品に、認証なしで読める穴

Atlassian は10月5日、[CVE-2026-21589 のセキュリティアドバイザリ](https://confluence.atlassian.com/security/cve-2026-21589-arbitrary-file-access-vulnerability-impacts-multiple-products-1870495748.html)を公開しました。題は "Arbitrary File Access"（任意ファイルへのアクセス）です。対象は Bitbucket Data Center、Confluence Data Center、Jira Service Management Data Center、Jira Software Data Center、Bamboo Data Center、Crowd Data Center、Crucible、Fisheye の8製品で、修正版より前のすべてのバージョンが影響を受けます。Cloud 版はベンダー側で修正済みで、利用者の作業は要りません。

攻撃者は認証なしで、Web アプリケーションのルートディレクトリ内の特定のファイルにアクセスできます。ただし、対象ファイルの正確な名前とパスを事前に知っている必要があり、ファイルの一覧は取れません。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-21589) の弱点分類は CWE-552 です。動画で使った「パストラバーサル」という語は、アドバイザリにも NVD にも出てきません。

スコアは CVSS v4.0 で 9.3（Critical）です。ベクタは AV:N/AC:L/AT:N/PR:N/UI:N（ネットワーク越し、特別な条件なし、認証なし、操作なし）です。直接の影響は機密性（VC:H）だけですが、後続のシステムへの影響（SC・SI・SA）は3つとも High です。

動画で挙げた修正版は、アドバイザリの表と一致しました。

- Confluence Data Center: 9.2.26 と 10.2.19
- Crowd Data Center: 4系列で 6.3.7、7.0.3、7.1.7、7.2.4
- Crucible と Fisheye: 4.9.15

すぐに更新できないときの一時しのぎとして、アドバイザリは、可能であればインスタンスをインターネットから外すこと（"if possible" 付き）、WAF での遮断、Tomcat の RewriteValve による遮断、Bitbucket だけは urlrewrite.xml で404を返す設定、を挙げています。旧 Server 版は対象一覧に載っていませんが、載っていないことは安全を意味しません。

「悪用の証拠なし」は範囲に注意が要ります。アドバイザリが書いているのは、影響を受けた Cloud 製品は修正済みで、調査では悪用の証拠が見つかっていない、という Cloud についての声明です。Data Center 全体で悪用がないとは言っていません。

8製品が同時に穴を持った理由を、アドバイザリは説明していません。共通の Web サーバー部品が背景にあるのでは、という見方は推測にとどまります。読まれて困るファイルについても、アドバイザリは、設定によっては機密性の高いファイルがありリスクが上がりうる、と書くだけです。web.xml などの設定ファイルは筆者の例示です。

動画の訂正です。

- 動画では「カナダのサイバーセンターも注意喚起を出しています」と紹介しましたが、本件に関する同センターの告知は確認できませんでした。

## 2. Linux ZRAM の作り直し — 書き込みと読み込みを分け、再圧縮は1つを共用に

ZRAM は、メモリの一部を圧縮して swap のように使う Linux カーネルの仕組みです。10月5日、Sergey Senozhatsky 氏が、これを作り直す10本のパッチシリーズを chromium.org のメールアドレスで投稿しました。内容は [linux-mm の PR #5148](https://github.com/linux-mm/linux-mm/pull/5148) で読めます。確認できる範囲では、メインラインへの取り込みはまだです。

動機は優先度逆転です。パッチの説明によると、従来は CPU ごとに1つの圧縮ストリームを、書き込み（圧縮）と読み込み（解凍）が mutex で取り合っていました。優先度の低い書き込み側が mutex を持ったまま、同じ CPU 上で優先度の高い読み込み側に割り込まれると、読み込み側は書き込み側が再び走って mutex を手放すまで待たされます。同じ CPU に実行可能なタスクが他にあると、待ちは長引きます。動画ではこれを銀行の窓口に例えました。

作り直しでは、ストリームの構造体を圧縮用（zcomp_cstrm）と解凍用（zcomp_dstrm）に分け、生成と破棄の処理も別々にしました。読み込みが書き込みの mutex を待つ場面は、構造のうえで無くなります。

もう一つの変更は、再圧縮用の扱いです。再圧縮は dev_lock の下で直列に動くため、同時に使われるのは1つだけです。そこで、CPU ごとに確保していた再圧縮用の圧縮ストリームをやめ、デバイスごとに1つ（recomp_cstream）だけ持つ形にしました。

ベンチマークは、作者がパッチに載せた fio での測定です。条件は CPU1つ、preempt=full、zstd level 12。nice 19 の書き込み4本と nice 0 の CPU 占有1本が走るなかで、nice -19 の読み込み1本を測っています。この条件で、読み取りの IOPS は 1,278 から約 43,300 へ（約34倍）、平均遅延は約 762μs から約 10μs へ縮みました。24CPU の別条件では IOPS が 354k から 997k で、約2.8倍です。人工的に負荷を組んだ測定で、実運用の体感とは別物です。

メモリの節約量は、再圧縮に使う方式で幅があります。パッチの例（8CPU の x86_64、4K ページ）では、zstd level 3 で約 700KB（1CPU あたり約 100KB）、level 12〜22 で約 1.91MB（約 280KB）、辞書つき zstd では約 5.33MB（約 780KB）です。

共有していた作業場を、使われ方に合わせて分ける。同時に使わないものは、逆に1つにまとめる。今日のテーマの、一番素直な実例だと思います。

## 3. Linux Plumbers Conference 2026 — プラハで開かれる、配管の点検会

[Linux Plumbers Conference（LPC）2026](https://lpc.events/event/20/) は、10月5日（月）から7日（水）まで、プラハの Prague Congress Centre でハイブリッド形式で開かれ、今日が最終日です。LPC は2008年にポートランドで始まった年次会議で、[Linux.com の2008年の記事](https://www.linux.com/news/linux-plumbers-conference-2008-keynote)が第1回を伝えています。

主催者は今年、[公式ブログ](https://lpc.events/blog/current/?p=1260)で、ウィーンでの参加者数（800人）に合わせてプラハの会場を広げると告知していました。それでも8月15日には、[完売（SOLD OUT）が告知](https://lpc.events/blog/current/?p=1350)されています。完売後のキャンセル待ちは優先順位つきで、採択された発表がある人、投稿したが採択されなかった人、それ以外、の順に、各層の中では先着順で扱われます。

日付ごとに見ると、次のとおりです。

- 5日: セッション "[GCC Rust support for Linux](https://lpc.events/event/20/contributions/2449/)" に、David Edelsohn 氏（NVIDIA）と Philip Herron 氏（Embecosm）が登壇しました。gccrs は GCC の Rust フロントエンドで、rustc とは別に GCC 側で実装されている Rust コンパイラです。LWN の [Compiling the kernel with gccrs](https://lwn.net/Articles/1095553/)（9月22日）は、カーネルはまだ gccrs でコンパイルできない段階だと伝えています。
- 6日: RISC-V のマイクロカンファレンス。[セッションページ](https://lpc.events/event/20/sessions/268/)には、ACPI 対応で残る課題、QoS と resctrl、IOMMU などが提案議題として並んでいます。
- 7日: sched_ext のマイクロカンファレンスが15時から。[セッションページ](https://lpc.events/event/20/sessions/270/)には、ゲームや低遅延向けのスケジューリング戦略、組み合わせて使えるスケジューラ（composable schedulers）などが議題に挙がっています。sched_ext は [Linux 6.12](https://kernelnewbies.org/Linux_6.12) で取り込まれました。同じ日には、コンテナと checkpoint/restore のマイクロカンファレンスもあり、その[募集要項](https://groups.google.com/a/lists.linuxcontainers.org/g/lxc-devel/c/l185Yw5iJk8)には "Checkpoint/restore support for GPUs and similar accelerators" がテーマとして入っています。採択された個別の発表までは確認できていません。

並んでいるのは議題であって、決定事項ではありません。

動画の訂正です。

- 動画では「チケット800枚が早々に売り切れ」と紹介しましたが、800はプラハの会場規模の目安にしたウィーン大会の参加者数で、チケットの枚数としては一次に出てきませんでした。
- 動画では「キャンセル待ちが150人を超えた」と紹介しましたが、公式ブログの完売告知でキャンセル待ちの人数は確認できませんでした。
- 動画では RISC-V のマイクロカンファレンスの議題が「話し合われます」と紹介しましたが、このマイクロカンファレンスは10月6日に開かれ、今日の時点では終わっています。

## 4. mold 3.0 — C++ から Rust へ、drop-in replacement で全面書き直し

高速リンカー mold が10月5日、[3.0.0](https://github.com/rui314/mold/releases/tag/v3.0.0) を公開しました。リリースノートによれば、C++ から Rust に書き直した最初のリリースです。ビルドは CMake から Cargo に変わり、CMake のオプションは廃止されました。ソースからのビルドには Rust 1.95 以上と C コンパイラが要り、oneTBB への依存は無くなりました。

鍵は "mold 3.0 is meant to be a drop-in replacement for 2.42.1."（2.42.1 をそのまま置き換えられることを意図している）の一文です。オプションも対象アーキテクチャも同じで、出力もノートに挙がる修正分を除いて同じ、とされています。互換性は、対応する全ターゲットでのテストスイート、実際のワークロードでの出力比較、Gentoo の全パッケージのビルドで確かめ、回帰は見つからなかったと書かれています。リンク性能は 2.42.1 と同等というのが開発元の記述で、第三者の測定ではありません。

安全面では、壊れた入力ファイルに対し、C++ 版は範囲外のメモリを読んでセグメンテーション違反でクラッシュしうるのに対し、3.0 では読み取りが範囲チェックされ、問題の箇所でパニックとして止まる、と書かれています。Rust にしたから全部安全、という話ではありません。

書き直しの理由は、[2.42.1 のリリースノート](https://github.com/rui314/mold/releases/tag/v2.42.1)にあります。mold のようなツールは何十年も使われる前提で開発すべきこと、2026年には Rust がシステムソフトウェアの実用的な選択肢になったこと、C++ に並ぶ性能でメモリ安全性などの強い安全性が得られること、の3点です。このノートは 2.42.1 を「追加の修正版が必要にならない限り、おそらく最後の C++ 版」としており、3.0.0 のノートでは、2.42.1 が最後の C++ 版だと確定形で書かれました。

3.0.0 のノートは、3.x の目標を、GNU ld との互換性の隙間、特にリンカースクリプトの対応を埋めること、そして mold が Linux ディストリビューションのデフォルトリンカーとして採用される道を整えること、としています。

作者は LLVM の lld の元開発者でもある Rui Ueyama 氏（植山類氏）で、mold は2020年に開発が始まり、最初のタグは2021年5月でした。形を保ったまま中身を次の世代へ渡す、今日のテーマにぴったりの例です。

動画の訂正です。

- 動画では「もう1つの理由が、リンカースクリプトへの完全な対応です」「どうせなら Rust への移行と同時に整理しよう、と判断したそうです」と紹介しましたが、リリースノートに書かれた書き直しの理由は、長く使われる前提でメモリ安全性を重視したことなどです。リンカースクリプトへの完全対応は、書き直しの理由ではなく、3.x の目標（ディストリビューションのデフォルトリンカーに向けた課題）として挙げられています。

## 5. Open Source Summit + Embedded Linux Conference Europe 2026 — 開幕、そして Linux は35歳

Open Source Summit + Embedded Linux Conference Europe 2026 は、今日10月7日から9日までの3日間、プラハで開かれます。[Linux Foundation のプレスリリース](https://www.linuxfoundation.org/press/open-source-summit-embedded-linux-conference-europe-2026-schedule-champions-open-source-innovation-and-marks-35-years-of-linux)は、AI、安全クリティカルなソフトウェア、クラウドネイティブ、組み込み Linux などのトラックを挙げています。公開されている予定表によれば、今日の開会式には Linux Foundation の CEO、Jim Zemlin 氏らが登壇します。LPC の最終日と、この初日が同じプラハで重なります。

プレスリリースは、今年を Linux が「コードベースとして35年」を迎える年と位置づけています。見どころは、最終日10月9日（金）の対談です。Linus Torvalds 氏と、Ericsson Software Technology の責任者である Dirk Hohndel 氏が、"the future of vendor-neutral collaboration, developer knowledge sharing, and the latest technological innovations driving the open source ecosystem" を語る予定です。ベンダー中立な協力の未来、開発者どうしの知識共有、オープンソースを牽引する新技術、という意味です。同じ9日には、Buildroot の25周年を振り返るセッションも予定されています。

35年前の出発点は、1991年8月25日の comp.os.minix ニュースグループへの投稿でした。当時21歳のフィンランドの学生だった Torvalds 氏は、"just a hobby, won't be big and professional like gnu" と書きました。趣味であり、GNU のように大きく本格的にはならない、という意味です（[Wikipedia の Linux の歴史](https://en.wikipedia.org/wiki/History_of_Linux)）。[ITWire](https://itwire.com/business-it-news/open-source/three-dates,-not-one,-to-mark-creation-of-linux-torvalds) によれば、v0.01 のコードは9月17日に、最初の告知に関心を示した人へ非公開で知らされました。最初のリリースの規模は、Wikipedia が引く Linux Foundation の資料で約1万行です。

いまの規模は、プレスリリースの言葉で「4000万行を超えるコード」です（行数は数え方によって変わります）。スーパーコンピュータの性能ランキング TOP500 については、[OMG! Ubuntu の2017年の記事](https://www.omgubuntu.co.uk/2017/11/linux-now-powers-100-worlds-top-500-supercomputers/amp)が、2017年11月のリストで全500台が Linux になったと伝えています。直近の2026年6月リストの内訳は確認できていません。

動画では、趣味の小屋が摩天楼になった、と例えました。35年で変わったのは、共有の部品を分けて、直して、次へ渡す人たちの輪の大きさだと思います。

## まとめ

8製品に同じ穴が出た Atlassian、作業場を分け直した ZRAM、配管を点検する LPC、中身を Rust へ渡した mold、そして1人の趣味から世界の共有基盤になって35年の Linux。共有の便利さと怖さ、そしてそれを支える手入れの話でした。

今日できることは一つです。自分の環境で、みんなが同じ部品に頼っている場所を、1つ確かめてください。Jira や Confluence などの Data Center 版を自社で運用しているなら、動いている版が修正版以降かどうか、アドバイザリと見比べてください。皆さんの現場で、同じ部品に頼っているのはどこでしょうか。

## 参考リンク

- [Atlassian: CVE-2026-21589 のアドバイザリ](https://confluence.atlassian.com/security/cve-2026-21589-arbitrary-file-access-vulnerability-impacts-multiple-products-1870495748.html)
- [NVD: CVE-2026-21589](https://nvd.nist.gov/vuln/detail/CVE-2026-21589)
- [linux-mm PR #5148（ZRAM 作り直しのパッチ）](https://github.com/linux-mm/linux-mm/pull/5148)
- [Linux Plumbers Conference 2026](https://lpc.events/event/20/)
- [LWN: Compiling the kernel with gccrs](https://lwn.net/Articles/1095553/)
- [mold v3.0.0 リリースノート](https://github.com/rui314/mold/releases/tag/v3.0.0)
- [mold v2.42.1 リリースノート](https://github.com/rui314/mold/releases/tag/v2.42.1)
- [Linux Foundation: Open Source Summit + ELC Europe 2026 のプレスリリース](https://www.linuxfoundation.org/press/open-source-summit-embedded-linux-conference-europe-2026-schedule-champions-open-source-innovation-and-marks-35-years-of-linux)
