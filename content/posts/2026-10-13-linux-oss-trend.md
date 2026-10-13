---
title: "GitLab 緊急パッチ CVSS 10.0、Deno ランタイム12か月で廃止、KDE Plasma 6.8 と X11、Envoy 共有メモリの横移動、CISA KEV の古い CVE（2026/10/13 Linux・OSSトレンド）"
date: 2026-10-13T00:00:00+09:00
draft: false
tags: ["セキュリティ", "脆弱性", "GitLab", "CI/CD", "Deno", "Cloudflare", "JavaScript", "KDE", "Wayland", "Kubernetes", "Envoy", "CISA"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

パッチ済み、移行済み、分離済み。チェックリストに丸を付けた瞬間に、安心して見なくなる場所はないでしょうか。今回の5本は、この「済み」の札の裏側を、自分の手元で確かめるという切り口で並べました。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言や、裏付けの取れなかった発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "iFIMhAYJCRA" >}}

## 1. GitLab 緊急パッチ — 9月に直したばかりの正規表現エンジンに、CVSS 10.0

GitLab は2026年10月12日、自己管理版の CE と EE 向けに[パッチリリースを公開しました](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-2-released/)。修正版は 19.4.2、19.3.5、19.2.8 の3つです。

注目は CVE-2026-97229 です。公式のパッチノートは、CI/CD 設定の正規表現コンパイラにある整数オーバーフローとし、CVSS を 10.0 としています。ノートによれば、特定の条件のもとで、認証されていないユーザーが細工した正規表現でサーバー上の任意のコードを実行できた可能性があります。条件の中身は書かれていません。NVD への登録状況は、一次情報では確認できませんでした。

影響版は、公式によれば 19.2 から 19.4.1 までの自己管理版です。19.3 系は 19.3.4 に別の不具合（Ona 連携を有効にしたときのマージリクエスト画面の問題）があり、19.3.5 で直っています。GitLab.com と GitLab Dedicated は対策済みで、影響を受けないとされています。

9月23日のパッチでも、同じ正規表現エンジンの脆弱性が CVSS 9.9 で2件直っています（[19.4.1 のパッチノート](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-1-released/)）。9月の2件はログイン済みのユーザーが細工する前提でした。9月の修正版に上げただけでは、今回の穴は塞がっていません。

暫定策として、外部からの入口を遮断して VPN 経由に絞る、といった方法が考えられますが、公式のパッチノートに暫定策の記載は見当たりませんでした。基本はパッチの適用です。攻撃経路として CI Lint が疑われているという話もありますが、出典は確認できておらず、推測の段階です。詳細は、公式のノートによれば修正リリースの90日後に公開される方針です。

パッチを当てたあとは、CI/CD 変数、デプロイキー、SSH 鍵の入れ替えと、アクセスログの遡り確認までを対応に含めたいところです（書き手の考えです）。今回のリリースには全部で24件の修正が並び、マージリクエストのページのキャッシュ汚染（CVE-2026-100755）なども含まれます。

動画の訂正です。

- 動画では「CI/CD変数が漏れうるキャッシュ汚染の問題も含まれています」と紹介しましたが、パッチノートの CVE-2026-100755 は、特定のデプロイ構成でマージリクエストのキャッシュ済みページが汚染される問題で、CI/CD 変数の漏えいとは書かれていません。

## 2. Cloudflare が Deno Land を買収 — ランタイムは12か月、Deploy は6か月

[Cloudflare は10月9日、Deno Land の買収を発表しました](https://blog.cloudflare.com/deno-joins-cloudflare/)。Ryan Dahl 氏を含むチームが Cloudflare に合流します。同じ日に出た[Deno 側のブログ](https://deno.com/blog/cloudflare)によると、ランタイムはこの先12か月、バグ修正とセキュリティパッチだけを出したうえで廃止されます。Deno Deploy は6か月で終了し、JSR は続きます。ソースコードはオープンソースとして残ります。有料ユーザーには Cloudflare Workers への移行支援があります。

Cloudflare のブログは、Deno チームが8月に公開した celld を、workerd と統合するとしています。celld は Rust 製の1本のバイナリで、外部サービスへの依存はオブジェクトストレージだけ、と[公式の説明](https://github.com/denoland/celld)にあります。従来の workerd では Durable Objects が単一インスタンスでしか動かず、スケールできませんでした。celld では Durable Object ごとに SQLite のデータベースを持ち、S3 互換などのストレージに状態を置いて、複数台で動かせます。

Cloudflare は2026年1月に [Astro](https://secure.businesswire.com/news/home/20260116386991/en/Cloudflare-Acquires-Astro-to-Accelerate-the-Future-of-High-Performance-Web-Development)、6月に [VoidZero（Vite、Rolldown など）](https://www.marketscreener.com/news/cloudflare-acquires-voidzero-and-its-vite-ecosystem-ce7f5ddcd088f020)も買収しています。Cloudflare のブログは、Deno チームが加わる理由を、Workers のプログラミングモデルをサーバーを作る主流の方法にするため、と説明しています。

[Simon Willison 氏の記事](https://simonwillison.net/2026/Oct/9/deno-is-joining-cloudflare/)によれば、Ryan Dahl 氏は Hacker News への書き込みで "It has been sucked into the gravity well of node compatibility, which forces it to behave exactly as Node does." と書いています（Node 互換という重力に引き込まれ、Node とまったく同じ動きを強いられている、という趣旨）。公式ブログの発言ではなく、本人のコメントです。同じ記事で Willison 氏は、Deno の権限システムをお気に入りの機能に挙げ、ファイルやネットワークホスト単位で制限できる一方、Node.js は特定のホストを許可リストにできない、と書いています。

書き手が勧めたい最初の一手は、Deno.serve や Deno.env のような Deno 固有の機能を、どこで使っているか棚卸しすることです。移行先は各自で見極めることになります。本番だけでなく、ローカル開発や CI に残った Deno も忘れずに。「移行済み」と書いたあとに残る小さな依存が、1年後に効いてきます。

動画の訂正はありません。

## 3. KDE Plasma 6.8 — X11 セッションとの別れ（10月14日リリース予定）

KDE Plasma 6.8 は、[公開されているスケジュール](https://community.kde.org/Schedules/Plasma_6)で10月14日のリリース予定です。この記事の日付の時点では、まだリリースされていません。

最大の変更は、ログイン画面から X11 セッションがなくなり、Plasma が Wayland のみで動くことです。KDE の[ブログ](https://blogs.kde.org/2025/11/26/going-all-in-on-a-wayland-future/)は、Plasma の X11 セッションが含まれなくなると書いています。なくなるのは X11 の上で Plasma 全体を動かすセッションで、一般的な X11 アプリは XWayland で引き続き動きます。画面共有や録画のような一部のツールは、調整が要る場合があります。

理由として、KDE の開発者は今年6月、Plasma 6.6 の利用者の95%以上がすでに Wayland を使っているという計測値を示しました。X11 側の制約が新機能の足かせになっていたことも、理由に挙がっています。まだ X11 が必要な人には、Plasma 6.7 の X11 セッションが、2027年の初めまでサポートされる、と KDE は書いています。追加のバグ修正リリースを出す可能性も検討中としており、動画で触れた「別の枝で保守される」という点は確認できませんでした。

機能面では、[6.7.90 のベータ版のアナウンス](https://kde.org/announcements/plasma/6/6.7.90/)に、Dolphin や Kate など QtWidgets アプリに Union テーマが適用されること（公開技術プレビューの後半）と、バックアップのスケジューラー Kup が載っています。アナウンスからリンクされる変更履歴には、NVIDIA で再びトリプルバッファリングを許可する変更と、システム音声やマイクを録音する Spectacle のオプションもあります。正式版の内容は、リリース後に公式アナウンスで確認してください。

10月14日は、KDE が生まれて30年の日でもあります（[30周年のページ](https://kde.org/anniversaries/30/)）。1996年の Matthias Ettrich 氏の投稿から始まった計画です。昨年11月から Wayland 専用化を予告し、X11 側の保守期間まで用意した今回の別れ方は、「済み」の札の付け方のお手本だと書き手は思っています。

動画の訂正はありません。

## 4. X41 の報告 — 同じ Pod の共有メモリと Envoy のホットリスタート

10月9日、セキュリティ企業の X41 D-Sec が、Kubernetes の Pod 内のコンテナ間で[横移動ができる事例を報告しました](https://x41-dsec.de/news/2026/10/09/envoy-on-k8s-shm/)。舞台は、アプリの隣に置かれる Envoy のサイドカーです。

標準の設定では、同じ Pod のコンテナは /dev/shm を共有します。Envoy には、接続を切らずに入れ替えるホットリスタートの機能があり、X41 によれば、新旧のプロセスは /dev/shm 上のファイルを使った共有メモリで連絡を取り合います（Envoy 公式のドキュメントは、プロセス間の連絡は UNIX ドメインソケットのみと書いており、記述が食い違っています）。そのファイルに、Envoy のメモリ番地とロック用構造体のリストのポインタが書かれている点が問題でした。X41 が示した攻撃は3段階です。

1. ファイルを読むだけで番地が分かり、ASLR が意味を失う
2. ロックの状態を書き換えて Envoy を待たせ続け、通信を止める
3. リストのポインタを書き換え、glibc のつなぎ替えを悪用して任意の番地へ書き込む

ただし前提条件があります。同じ Pod の別コンテナがすでに侵害されていて、しかも root か Envoy と同じユーザー ID で動いている必要があります。

Envoy のメンテナーは、ファイルは Envoy のユーザーしか読み書きできないとして、セキュリティ問題ではないと判断しました。X41 はこれに対し、Pod は同居と資源共有の単位であって安全の境界ではない、と結論づけています。これは X41 の結論であり、Envoy 側の言葉ではありません。

対象は、Envoy をサイドカーに使い、ホットリスタートが有効な構成です。X41 が挙げる対策は、envoy の起動オプション --disable-hot-restart でホットリスタートを無効にすることと、コンテナごとにメモリ上の emptyDir を /dev/shm にマウントして共有をやめることです。書き手からの宿題は、設計図で「分離済み」の札がどの壁を指しているか、一度確かめることです。

動画の訂正です。

- 動画では「Envoyをroot以外の専用ユーザーで動かして、アプリから触れないようにすることです」と紹介しましたが、X41 の対策に専用ユーザーは含まれていません。X41 は、Pod 内で UID を共有していると権限の確認が働かない、と指摘しています。

## 5. CISA KEV の古い CVE — なぜ残るのか、手元でどう確かめるのか

前日の回で取り上げた KEV への追加の続報です。KEV の5件の詳細は[前日の記事](https://blog.fuga.jp/posts/2026-10-12-linux-oss-trend/)に譲り、ここでは「なぜ残るか」と「どう確かめるか」に絞ります。連邦機関の修正期限は10月11日に過ぎましたが、期限が縛るのは連邦政府の機関だけです。民間の会社や家庭の機器には届きません。

ProFTPD 1.3.5 の mod_copy は、リモートの攻撃者に任意のファイルの読み書きを許す問題でした（[CVE-2015-3306](https://nvd.nist.gov/vuln/detail/CVE-2015-3306)）。Apache Struts 2.3 系の [CVE-2016-3081](https://nvd.nist.gov/vuln/detail/CVE-2016-3081) と、ISC BIND の [CVE-2015-5477](https://nvd.nist.gov/vuln/detail/CVE-2015-5477) も、同じ KEV の追加に含まれています。修正版は、BIND が [9.9.7-P2 と 9.10.2-P3](https://kb.isc.org/docs/aa-01272)、Struts が [Apache のアドバイザリ S2-032](https://cwiki.apache.org/confluence/display/WW/S2-032) によれば 2.3.20.3、2.3.24.3、2.3.28.1 です。ProFTPD は、前日の記事のとおり 1.3.5a（2015年5月27日）から直っています。

なぜ残るのかは、一次では確認できませんでした。ここからは書き手の推測ですが、更新の通知が届かない機器や、依存関係の奥に埋もれた部品は、担当者の目に入らないまま残ってしまうのだと思います。期限が民間に届かない以上、手元の機器は自分で確かめるしかありません。

狙う側としては、中国と関連するとされる Flax Typhoon が[報じられています](https://thehackernews.com/2026/10/flax-typhoon-exploits-five-flaws-as.html)。2024年の FBI の作戦は、[26万台を超える IoT 機器にかかわるボットネットを妨害したと報じられました](https://www.cybersecuritydive.com/news/vulnerabilities-flax-typhoon-botnet/727886/)。

手元で確かめる方法は4つです。

1. FTP の21番ポートが外から見えていないか確認し、要らなければ閉じる
2. 物置の NAS やルーターに、いまも更新が届いているかを見る
3. 会社のシステムなら、ソフトウェア構成分析のツールで依存関係の奥の古い部品を洗い出す
4. KEV への追加を購読し、すぐ動ける手順を用意しておく

パッチが出ても、全員が当てたとは限りません。当てた人がいても、全部の機器が更新されたとは限りません。「済み」の日付より、いまその機器に届く更新の経路があるかを確かめたいところです。

動画の訂正です。

- 動画では「ネットにつながった機器を調べるサービスでは、今も数千から数万台が、FTPの21番ポートを開けているとされます」と紹介しましたが、この台数の出典は確認できませんでした。
- 動画では「それが再建されたとみられているんです」と紹介しましたが、再建を報じた出典は確認できませんでした。
- 動画では「修正版は、前回と同じでいいんだよね。はい。ProFTPDは1.3.6以降、Strutsは2.3.29以降」と紹介しましたが、前日の記事は ProFTPD の修正版を 1.3.5a としており、「前回と同じ」ではありません。Struts の公式アドバイザリ S2-032 に 2.3.29 の記載はなく、修正版は 2.3.20.3、2.3.24.3、2.3.28.1 です。

## まとめ

GitLab では、先月当てたパッチのすぐ隣に、もっと深刻な穴が見つかりました。Deno と KDE は、長く使われたものとの別れ方が対照的です。Envoy のサイドカーと10年前の脆弱性は、「済み」と思った場所にまだ道が残っている例でした。どれも「済み」と書いた日付ではなく、いま確かめる手段があるかが問われます（書き手の考察です）。

今日できることは、GitLab の版の確認と鍵の入れ替え、CI に残った Deno の棚卸し、Pod 内のサイドカーとホットリスタートの設定確認、物置の NAS やルーターの更新確認です。ひとつだけでも見てみてください。

## 参考リンク

- [GitLab: 19.4.2 のパッチリリース](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-2-released/)
- [Cloudflare: Deno joins Cloudflare](https://blog.cloudflare.com/deno-joins-cloudflare/)
- [Simon Willison: Deno is joining Cloudflare](https://simonwillison.net/2026/Oct/9/deno-is-joining-cloudflare/)
- [KDE: Plasma 6.7.90 のアナウンス](https://kde.org/announcements/plasma/6/6.7.90/)
- [X41 D-Sec: Envoy on K8s shm](https://x41-dsec.de/news/2026/10/09/envoy-on-k8s-shm/)
- [The Hacker News: Flax Typhoon](https://thehackernews.com/2026/10/flax-typhoon-exploits-five-flaws-as.html)
