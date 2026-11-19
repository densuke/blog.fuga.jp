---
title: "Java4Shell（CVE-2026-114938）の影響は CPU にも左右され、AlmaLinux 10.3 のカーネルは RHEL 10.3 にない CVE 36件を修正、Redict は廃止で Valkey へ、安定版カーネル 7.3.5 など3本、Puppet の CVE-2026-115731 が KEV 入り（2026/11/19 Linux・OSSトレンド）"
date: 2026-11-19T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Java", "AlmaLinux", "Podman", "Valkey", "Linuxカーネル", "CISA KEV", "Puppet"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

版の番号やディストリの名前がそろっていても、入っている修正までそろっているとは限りません。2026年11月19日（木）の動画では、この食い違いが運用に響く例を5本扱いました。

Java4Shell は、OpenJDK の Base64 デコードにある CVE-2026-114938 で、影響は Java の版に加えて CPU の命令にも左右されます。AlmaLinux 10.3 のカーネルには、同じ 10.3 の RHEL のカーネルにない CVE 36件の修正が入っています。Redict は廃止を宣言し、移行先に Valkey を挙げました。安定版カーネルは 7.3.5、6.18.64、6.12.118 の3本が同時に出ています。Puppet Enterprise の CVE-2026-115731 は、CISA の KEV に追加されました。

この5本に共通点を見るのは書き手の考察で、各社や報告者がそう言っているわけではありません。動画の訂正は、5本とも各節の末尾に書いています。確認は2026年11月19日（日本時間）の昼で、時点で変わる値には時刻を添えます。たとえば Valkey 9.1.4 の公開（11月18日 20:29 UTC。日本時間では19日 05:29）は、動画の公開（日本時間 09:36）より前です。Eclipse Temurin の修正版の公開は11月18日 20:39 UTC です。

{{< youtube "bYp_JL7ZxgE" >}}

## 1. Java4Shell（CVE-2026-114938）

11月17日（火）、発見者の Calif が [Java4Shell の分析](https://calif.io/java4shell)を公開しました。OpenJDK のアドバイザリと Oracle の修正は、Calif によると米国太平洋時間の11月17日 13:00（日本時間では18日 06:00）です。[OpenJDK のアドバイザリ](https://openjdk.org/groups/vulnerability/advisories/2026-11-17)では hotspot/compiler の問題で、CVSS v3.1 の 8.1 です。この 8.1 は Oracle の採点で、NVD 自身の採点はなく、確認時点で分析中です（[NVD](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-114938)）。

欠陥は、java.util.Base64 の基本・URL 向けデコーダー（MIME 向けは通らない）を、JIT が AVX-512 向けの命令に差し替える経路にあります。Calif は、末尾のパディングを持つ入力で書き込み範囲のマスクの計算を誤り、出力配列の外へ書き込む、と説明しています。Equixly の記事では、はみ出す量は62バイトか63バイトで、そのあと例外が投げられます。

Calif は、認証より前に Base64 のデコードが走る製品で、資格情報なしにコード実行まで至ると主張し、Keycloak、Jira、Confluence、JFrog Artifactory、Jenkins、PingFederate を挙げています。Equixly の[記事](https://equixly.com/blog/2026/11/17/cve-2026-114938-pre-auth-heap-overflow-in-java-17-21-and-25/)は、HTTP の Basic 認証のヘッダーがパスワードの確認より前にデコードされると書きます。[Element Security の分析](https://element.security/java4shell-pre-auth-rce-in-openjdk-base64-cve-2026-114938/)は、Calif の手法の説明に加え、Keycloak の SAML の経路が2021年からこのコードを通っていたと述べています。Element 自身がラボで再現したのは、メモリ破壊の部分とクラッシュの痕跡で、コード実行の再現とは書いていません。

悪用の報告は、11月17日の時点でありません（Equixly。NVD に載る CISA の SSVC の評価も「悪用なし」）。CISA の KEV にも、確認時点で最新の11月18日 19:17 UTC 版のフィードまで載っていません。

影響を受ける条件は2つ重なる場合です。

- Java の版: OpenJDK の 17.0.6 以降の17系、21、25、27の修正前。OpenJDK 8 と 11 は対象外です。Oracle の CSPU は、商用の Java 8 の性能向けビルド（8u511b33-perf）も対象に挙げています（[Oracle の CSPU](https://www.oracle.com/security-alerts/cspunov2026.html)）。
- CPU: AVX-512 の VBMI と BW を持つ x86-64 です。Calif は Intel の Xeon（Ice Lake 以降）と、AMD の EPYC と Ryzen（Zen 4 以降）を挙げ、ARM64 は対象外と書きます。Equixly は、AVX-512 を無効にして出荷される Alder Lake 以降の Intel デスクトップを対象外としています。

修正版は、Oracle が11月17日に 17.0.21.1、21.0.13.1、25.0.5.1、27.0.1.1 を出しました（[17.0.21.1 のリリースノート](https://www.oracle.com/java/technologies/javase/17-0-21-1-relnotes.html)）。Amazon Corretto は 17.0.21.1.2 で修正しています（11月17日 20:05 UTC。[CHANGELOG](https://github.com/corretto/corretto-17/blob/develop/CHANGELOG.md)）。Eclipse Temurin は、Element Security によると11月18日の日中は脆弱な10月版のままでしたが、[17.0.21.1+2](https://github.com/adoptium/temurin17-binaries/releases/tag/jdk-17.0.21.1%2B2) が11月18日 20:39 UTC（日本時間では19日 05:39）に公開されています。OpenJDK の配布元ごとに版の付け方は違います。

Equixly は、`java -version` は PATH の先頭の Java しか示さず、多くのアプリは自前の JDK を同梱するので、実行中のプロセスには `jcmd <PID> VM.version` を使うよう案内しています。更新できない場合の回避策として Calif は、起動オプション `-XX:-UseBASE64Intrinsics`（Base64 の高速化をエンコードとデコードの両方で止める）と、x86-64 だけで使う `-XX:UseAVX=2` を挙げます。Equixly は、どちらも標準の HotSpot のオプションだが、今回の CVE について配布元の確認はないので、試してから展開するよう書いています。

動画の訂正です。

- 動画では、Java4Shell は Log4Shell などになぞらえてコミュニティが付けた通称だと伝えました。正しくは、Java4Shell は発見者の Calif が公開時に付けた名前で、Log4Shell などになぞらえたという記述は一次にありません（[Calif](https://calif.io/java4shell)）。
- 動画では、Equixly は RCE は未証明と異を唱え、確認できているのはクラッシュまで、と伝えました。正しくは、Equixly の記事は Calif が RCE を報告していると紹介し、最悪の場合はコード実行と書いています（[Equixly](https://equixly.com/blog/2026/11/17/cve-2026-114938-pre-auth-heap-overflow-in-java-17-21-and-25/)）。
- 動画では、コンシューマー向けの Intel のデスクトップは影響を受けない、と伝えました。正しくは、Equixly が対象外とするのは AVX-512 が無効な Alder Lake 以降の Intel デスクトップで、Calif は AMD の Zen 4 以降の Ryzen も対象に挙げています（[Calif](https://calif.io/java4shell)）。
- 動画では、10月版と11月の修正版で版の文字列が同じビルドがある、と伝えました。正しくは、確認できた範囲では Oracle・Corretto・Temurin とも文字列が異なります（例: Corretto は 17.0.21.0.11 から 17.0.21.1.2）。同じ文字列のビルドがあるという記述は Element Security だけで、どの配布元かは特定できませんでした。実行中のビルドの番号を配布元の告知と照らすのは変わらず有効です（[Oracle のリリースノート](https://www.oracle.com/java/technologies/javase/17-0-21-1-relnotes.html)）。

## 2. AlmaLinux 10.3 のカーネルと移行の注意

AlmaLinux 10.3 "Mauve Lion" は、11月16日（月）に 9.9 と同時に公開されました。[AlmaLinux のブログ](https://almalinux.org/blog/2026-11-16-almalinux_103_and_99_stable/)によると、カーネルは RHEL 10.3 と同じ 6.12.0-264.16.1.el10_3 で、リリース時点で RHEL 10.3 のカーネルでは直っていない CVE 36件の修正を含みます。内訳は、RHEL 10.2 の最後のカーネルにあって 10.3 から抜けていた30件を戻したものと、コミュニティの要望で入れた、RHEL 10 では一度も直されていない6件です。RHEL 側で抜けた理由は AlmaLinux も分からないと書いています。

[リリースノート](https://wiki.almalinux.org/release-notes/10.3.html)は、表の CVSS は Red Hat の採点だと明記しています。戻した30件のうち最も高いのは、Red Hat の CVSS v3.1 で 8.8 の3件です。

- CVE-2026-53360（KVM SEV）: ゲストが GHCB の入力を悪用してホストのカーネルのヒープを壊せる、と Red Hat は説明しています。対象は SEV-SNP のゲストで、RHEL 9・10 では Technology Preview（本番利用は非サポート）です。
- CVE-2026-89932（KVM nVMX）: 仮想プロセッサー ID の再利用時に TLB が消されない問題です。Red Hat は、入れ子の Intel 仮想化を使う環境に限ると書いています。
- CVE-2026-74744（ipvlan）: ipvlan が下位デバイスの headroom と tailroom（ヘッダー・トレーラー用の領域）を継承しない不具合です。Red Hat は、メモリ破壊からサービス拒否になりうると説明しています。

RHEL 10.3 のカーネルの状態は、AlmaLinux の記述（リリース時点）以外に確認できていません。Red Hat の記録は、これらを 10.2 のカーネルで修正済みと載せています。

カーネル以外では、次の変更が移行に響きます。

- Podman 6: CNI は削除され Netavark だけになり、BoltDB は廃止されて SQLite を使い、cgroups v1 は非対応です。rootless のネットワークは slirp4netns から pasta になりました（[Podman 6.0.0](https://github.com/containers/podman/releases/tag/v6.0.0)）。10.3 の同梱は Podman 6.1.1 です。
- ModSecurity: 10.0 から 10.2 には入っていませんでしたが、10.3 で 2.9.14 と OWASP CRS 4.22.0 が戻りました。9 は CRS 3.3.5 で、リリースノートは、CRS 3.3 系から持ち越したルールと調整は見直しが要ると書いています。
- authselect: グループの統合が既定では行われなくなりました。ローカルのファイルと SSSD などでグループを統合している環境では、更新後に `authselect enable-feature with-group-merging` で戻します。10.3 と 9.9 の両方に当てはまります。

動画の訂正です。

- 動画では、ipvlan の件を「バッファオーバーフロー」と伝えました。正しくは、ipvlan が下位デバイスの headroom・tailroom（ヘッダー・トレーラー用の領域）を継承しない不具合で、Red Hat はメモリ破壊からサービス拒否になりうると説明しています（[リリースノート](https://wiki.almalinux.org/release-notes/10.3.html)）。
- 動画では、KVM のホストを RHEL 10.3 で動かすと AlmaLinux 10.3 より危ない状態になりうる、と伝えました。正しくは、AlmaLinux は「リリース時点で RHEL 10.3 のカーネルに修正が無い」と書きますが、Red Hat 側の 10.3 の状態は確認できませんでした。また Red Hat によると、CVE-2026-53360 は SEV-SNP のゲスト（RHEL 9・10 では Technology Preview）、CVE-2026-89932 は入れ子の Intel 仮想化を使う環境が対象で、KVM のホスト一般の話ではありません（[リリースノート](https://wiki.almalinux.org/release-notes/10.3.html)）。

## 3. Redict の廃止宣言と Valkey

11月17日（火）、Redict を始めた Drew DeVault 氏が、[廃止の投稿](https://redict.io/posts/2026-11-17-redict-deprecated/)で Redict は正式に廃止されると述べ、7.3.6 が最終リリースだと書きました。7.3.6 のリリースは2025年10月8日のもので、以後の修正は出ません。移行の期限は投稿に書かれていません。

Redis は2024年3月20日（水）、7.4 から RSALv2 と SSPLv1 のデュアルライセンスに移ると[発表](https://redis.io/blog/redis-adopts-dual-source-available-licensing/)しました。Redict はこれを受けて Redis OSS 7.2.4 から分かれたフォークです。変更は LGPL-3.0-only で公開する方針でした（[立ち上げの投稿](https://redict.io/posts/2024-03-22-redict-is-an-independent-fork/)）。

DeVault 氏は、"Redict was not able to build a sustainable community"（持続可能なコミュニティを作れなかった）と書き、その背景に Valkey の成功と "Redis's return to a copyleft license"（Redis がコピーレフトのライセンスに戻ったこと）を挙げています。後者は DeVault 氏の言い方です。Redis 自身は、2025年5月1日（木）の[発表](https://redis.io/blog/agplv3/)で、Redis 8 から OSI 承認の AGPLv3 を追加のライセンスの選択肢にしたと書いています。Redis に戻ることは勧めないとし、理由は、Redis が貢献者ライセンス契約（CLA）を使っており、Redis が業績の悪い四半期を迎えたときに再び "rug-pull"（梯子外し）を起こしやすくするから、というのが DeVault 氏の見立てです。長期の見通しは Valkey のほうが良い、とも書いています。

Codeberg のリポジトリは11月17日（17:09 JST）にアーカイブされました。最後のコミットは2025年10月8日で、Valkey から取り込んだ Lua まわりの脆弱性の修正4件（CVE-2025-49844、CVE-2025-46817、CVE-2025-46818、CVE-2025-46819）です。

Valkey は Linux Foundation が支援し、BSD ライセンスで公開されています。[ダウンロードのページ](https://valkey.io/download/)の確認時点の最新版は 9.1.4（11月18日公開）で、[リリースノート](https://github.com/valkey-io/valkey/releases/tag/9.1.4)はセキュリティ修正（CVE-2026-130822。maxmemory-clients が有効なときのクライアント退避での解放後使用によるクラッシュ）を含むと書いています。移行について DeVault 氏は、パッケージマネージャーで入れた場合は Valkey を入れて設定ファイルを移すだけ、コンテナなら Valkey のコンテナを使い、設定ファイルを合わせればよい、と書きます。Valkey の[クライアントのページ](https://valkey.io/clients/)は、Redis 7.2 のワイヤープロトコルを話すものは Valkey 7.2 以降で動くので、ほとんどの既存のクライアントは変更なしで移行できる、としています。Python には redis-py のフォークの valkey-py もあります。

バックアップを取り、検証用の環境で起動と接続を確かめてから切り替える、というのは書き手の助言です。

動画の訂正です。

- 動画では、Valkey の最新の安定版は 9.1.3 だと伝えました。正しくは、動画の公開より前の11月18日 20:29 UTC（日本時間 11月19日 05:29）に 9.1.4 が出ており、セキュリティ修正（CVE-2026-130822）を含みます（[Valkey 9.1.4](https://github.com/valkey-io/valkey/releases/tag/9.1.4)）。

## 4. 安定版カーネル 7.3.5・6.18.64・6.12.118

11月17日（火）、Greg Kroah-Hartman 氏が 7.3.5、6.18.64、6.12.118 の3本の安定版を出しました（[LWN](https://lwn.net/Articles/1108142/)）。FOSS Linux の[記事](https://www.fosslinux.com/164263/linux-7-3-5-three-tree-stable-update.htm)は、レビューのメールのパッチ数を 507、686、670、合計 1,863 と数えています。同じ修正が複数のブランチに入るので延べの数です。FOSS Linux は今回を "This batch is maintenance"（今回の束はメンテナンス）と位置づけ、ksmbd などの修正についても "I would not sell them as an emergency"（緊急扱いはしない）と書いています。

中身には、素通りしにくい修正があります。

- assoc_array: [7.3.5 の ChangeLog](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.3.5)には、題が `assoc_array:` で始まる9件があり、すべて Linus Torvalds 氏が書いたコミットで、mainline から安定版に取り込まれたものです。うちバグ修正は4件で、メモリ確保に失敗したときの後片付けが使用中のツリーに及ぶ問題や、ショートカットの分割でオブジェクトを見失う問題を含みます。6.18.64 と 6.12.118 にも同じ9件が入っています。
- メモリ管理: mremap と UFFDIO_MOVE のロックの順序によるデッドロックの修正（7.3.5）と、MADV_FREE が KSM のページのデータを失わせうる問題の修正（3本とも）があります。
- ksmbd（カーネル内の SMB3 サーバー）: 閉じたら削除する指定で開くときに DELETE 権限を要求する修正（3本とも）と、アクセス制御のエントリが無いとき所有者が DACL を読み書きできない問題の修正（7.3.5 のみ）です。

ChangeLog には、今回の修正に CVE 番号は付いていません。カーネルの CVE は、修正が安定版のツリーに入ったあとに割り当てられ、linux-cve-announce のメーリングリストで公表されます（[カーネルの CVE の文書](https://docs.kernel.org/process/cve.html)）。リリース時点の変更履歴や CVE の一覧だけで更新の優先度を決めると、こうした修正を見落としうる、というのは書き手の考察です。

6.12.118 には、AppArmor の境界チェックの修正（ChangeLog の移植の注記では、上流の一部の場合は対象外）と、cfg80211 のファームウェア読み込みでの範囲外の読み取りの修正も入っています。6.12 系は Debian 13 が採用しています（[Debian のニュース](https://www.debian.org/News/2025/20250809)）。

動画の訂正です。

- 動画では、6.12.117 で Debian の利用者が報告したリグレッションが今回で解消した、と伝えました。正しくは、LWN・FOSS Linux・ChangeLog のいずれにもその記述は無く、確認できませんでした（[ChangeLog-6.12.118](https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.12.118)）。

## 5. Puppet の CVE-2026-115731

CISA は11月17日（火）、Perforce Puppet Enterprise の CVE-2026-115731 を KEV に追加しました。悪用の証拠に基づくもので、期限は12月1日（火）です。この期限は連邦文民行政機関（FCEB）向けで、CISA は全組織に優先的な対応を勧めています（[CISA の告知](https://www.cisa.gov/news-events/alerts/2026/11/17/cisa-adds-one-known-exploited-vulnerability-catalog)）。修正の公開は11月3日（UTC。日本時間では4日）です。

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-115731) によると、Puppet のレポート処理コードで、細工した rich-data 型を含むレポートを PUT で受け取ると、信頼できないデータのデシリアライズにより、Puppet Server のサービスアカウントの権限で任意のコードが実行されます。CVSS は、CNA の Perforce が v4.0 で 9.4、NVD 自身が v3.1 で 9.9 です。

成立条件は、DEV Community の[整理](https://dev.to/anoymask/puppet-cve-2026-115731-remote-code-execution-on-puppet-server-via-insecure-deserialization-of-158m)では4つです。影響する版が動いていること、レポートの受け口に届くこと、CA が署名したエージェントの証明書を持つこと、細工したレポートが受理されることです。NVD は、証明書について、強い検証なしに自動署名（autosign）する CA では、認証のないネットワーク上の攻撃者も取得できると書いています。[SecurityWeek](https://www.securityweek.com/critical-perforce-puppet-rce-exploited-in-attacks/) は、OpenVox を狙う PoC が修正の直後に公開されたと報じています。

同時に修正された [CVE-2026-115732](https://nvd.nist.gov/vuln/detail/CVE-2026-115732) は、証明書の名前の照合の不備です。認可済みのホスト名を延ばした、または縮めた名前の証明書が、そのホストとして認可されます。CNA の記録は、他のノードへのなりすましと、Puppet Enterprise では CA の管理操作や管理下のノードでのコマンド実行に至りうると書いています。CVSS は v4.0 で 9.0（Perforce、CNA の採点）で、NVD は分析待ちです。報告者は Neodyme の Alain 氏で、OpenVox は2件とも謝辞を述べています。CA の署名鍵が取られてなりすましに使われうる点は、Neodyme の分析として報じられています（[DEV Community の記事](https://dev.to/randomchaos/cisa-flags-exploited-puppet-bug-enabling-ca-key-theft-3l9i)を経由した孫引きで、原文は未確認です）。

Puppet Enterprise の修正版は、使っている系列に応じて 2026.0.1、2025.12.1、2023.8.13 です。これらは Puppet Core 9.1.3 と 8.22.2（puppet-agent）を同梱し、CVE の記録は、上げたあとに puppet server を再起動して修正を読み込ませるよう案内しています。OpenVox はサーバーが 9.2.0 と 8.18.0、エージェントが 9.3.0 と 8.32.0 で、Puppet の各実装が影響を受けると書きます（[Vox Pupuli のブログ](https://voxpupuli.org/blog/2026/11/03/critical-cve-updates/)）。更新できない間の緩和策として確認できたのは、autosign の無効化または絞り込みと、サーバーに届くネットワークを必要な範囲に絞ることです。

動画の訂正です。

- 動画では、CVE-2026-115731 と CVE-2026-115732 の2つを組み合わせると、権限の強いノードへ横に広がるとされている、と伝えました。正しくは、組み合わせた連鎖を書いた出典は確認できませんでした。CNA の CVE 記録は CVE-2026-115732 単独で、他ノードへのなりすましと、Puppet Enterprise では CA の管理操作や管理下ノードでのコマンド実行に至りうると書いています（[NVD の CVE-2026-115732](https://nvd.nist.gov/vuln/detail/CVE-2026-115732)）。
- 動画では、エージェント側の Puppet Core は 9.1.3 と 8.22.2 だと伝えました。正しくは、版は合っていますが、これは Puppet Enterprise に同梱される puppet-agent の版で、修正はサーバー側に効きます。CVE 記録は、これを同梱した Puppet Enterprise に上げて puppet server を再起動するよう案内しています（[NVD の CVE-2026-115731](https://nvd.nist.gov/vuln/detail/CVE-2026-115731)）。
- 動画では、緩和策は3つ（autosign の無効化、8140番を既知の管理ノードに絞る、受け口への異常なリクエストの監視）だと伝えました。正しくは、Perforce のアドバイザリは取得できず、この3つの組と8140番の名指しは確認できませんでした。確認できたのは、OpenVox などが挙げる autosign の無効化または絞り込みと、サーバーへのアクセス元の絞り込みです（[Vox Pupuli のブログ](https://voxpupuli.org/blog/2026/11/03/critical-cve-updates/)）。

## まとめ

実務で確かめておくものは次のとおりです。

- Java: 実行中のプロセスの版とビルド番号を、`jcmd <PID> VM.version` などで配布元の告知と照らす。CPU が AVX-512 の VBMI と BW を持つかも確認する。当てはまれば修正版へ更新し、できない間は回避策を、動作を確かめてから使う。
- AlmaLinux 10.3: 上げる前に、Podman 6 の変更（CNI、BoltDB、cgroups v1、rootless のネットワーク）、ModSecurity の CRS 4 へのルールの見直し、authselect のグループ統合を確認する。
- Redict: 使っているなら、Valkey への移行を計画する。バックアップと検証環境での確認を先にし、使っているクライアントも確かめる。
- 安定版カーネル: ディストリが取り込んだ更新を、CVE 番号の有無にかかわらず当てる。
- Puppet: 修正版に上げて puppet server を再起動し、autosign の設定を見直し、サーバーへのアクセス元を絞る。OpenVox を使っているなら OpenVox の修正版へ上げる。

## 参考リンク

- [Calif: Java4Shell](https://calif.io/java4shell)
- [OpenJDK のアドバイザリ（2026-11-17）](https://openjdk.org/groups/vulnerability/advisories/2026-11-17)
- [AlmaLinux 10.3 と 9.9 のブログ](https://almalinux.org/blog/2026-11-16-almalinux_103_and_99_stable/)
- [AlmaLinux 10.3 のリリースノート](https://wiki.almalinux.org/release-notes/10.3.html)
- [Redict の廃止の投稿](https://redict.io/posts/2026-11-17-redict-deprecated/)
- [Valkey 9.1.4](https://github.com/valkey-io/valkey/releases/tag/9.1.4)
- [Linux 7.3.5 の ChangeLog](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.3.5)
- [CISA の告知（KEV への追加）](https://www.cisa.gov/news-events/alerts/2026/11/17/cisa-adds-one-known-exploited-vulnerability-catalog)
- [Vox Pupuli: OpenVox の重大な CVE の更新](https://voxpupuli.org/blog/2026/11/03/critical-cve-updates/)

（2026/11/19 Linux・OSSトレンド）
