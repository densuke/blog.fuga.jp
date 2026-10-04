---
title: "AI の足元に古典的な穴? GitLab AI Gateway CVE-2026-90970・Zammad・Zig 0.17・Ubuntu 26.10 Sequoia PGP・Arm TLBI Domains（2026/10/5 Linux・OSSトレンド）"
date: 2026-10-05T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "GitLab", "AI", "Zig", "Ubuntu", "OpenPGP", "Rust", "Arm", "Linux カーネル", "Zammad", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

AI や新機能が主役に見える時代でも、守りの勝ち負けを分けるのは、足回りにある昔ながらの部品の手入れではないか。今日の5本は、そんな見立てで並べました。AI の中継役に見つかったテンプレート展開の穴、ビルドの段取りの作り直し、署名確認の道具の世代交代、コアへの「知らせ方」の見直し、そして AI と見られる攻撃が突いた古いセッションの穴です。

共通点の指摘は書き手の考察です。動画には裏付けの取れなかった発言や数字があったため、確認し直した結果を各節末の「動画の訂正」にまとめました。

{{< youtube "bgzd77g3_0k" >}}

## 1. GitLab AI Gateway CVE-2026-90970 — CVSS 9.9、セルフホストの Duo で任意コマンド実行

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-90970)によれば、CVE-2026-90970 は CVSS 3.1 で 9.9（Critical）、ベクタは `AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H`、分類は CWE-1336（テンプレートエンジンで使われる特殊要素の不適切な無害化）です。Duo Agent Platform の権限を持つ認証済みユーザーが、細工したフロー設定でプロンプトテンプレートのサンドボックスを抜け、AI Gateway 上で任意のコマンドを実行できる、という内容です。

AI Gateway は、GitLab の AI 機能を自前の環境で動かす Duo Self-Hosted で使う部品です。影響を受けるのは GitLab 本体ではなく、AI Gateway の版です。[GitLab のパッチリリース告知](https://docs.gitlab.com/releases/patches/other-patches/patch-release-gitlab-ai-gateway-19-4-1-released/)によれば、対象は 18.1.6 以上 19.2.4 未満、19.3 系は 19.3.2 未満、19.4 系は 19.4.1 未満で、修正版は 19.2.4、19.3.2、19.4.1 です。GitLab.com、GitLab Dedicated、GitLab がホストする AI Gateway につないだセルフマネージド環境では、利用者の対応は不要とされています。

報告者は HackerOne 経由の外部研究者 invisiblemeerkat 氏で、CVE の公開と修正版の告知は10月2日です。

仕組みについては、[Rescana の解説](https://www.rescana.com/post/cve-2026-90970-critical-gitlab-ai-gateway-vulnerability-enables-command-execution-on-self-hosted-deployments)が、Jinja2 風の二重波括弧の記法でユーザー由来の値をプロンプトに差し込む仕組みだと説明しています。GitLab の公式な説明ではありません。GitLab も NVD も「SSTI」とは呼んでいませんが、Web アプリで昔から知られるテンプレートインジェクションと同じ型と捉えるとつかみやすいでしょう。

[The Hacker News](https://thehackernews.com/2026/10/gitlab-patches-critical-self-hosted-ai.html)は、セルフホストの AI Gateway が JWT の署名鍵を保持しており、機密として扱うべきだと指摘しています。[Security Affairs](https://securityaffairs.com/200283/hacking/cve-2026-90970-critical-gitlab-ai-gateway-flaw-fixed.html)は、鍵が環境変数で渡されており、コマンド実行に至れば認証基盤や AI リクエストのデータに届きうると説明しています。

悪用については、The Hacker News が CISA の評価で既知の悪用はないと報じ、Security Affairs も公開 PoC は無いと書いています。執筆時点で悪用は確認されていません。

2月にも同じ AI Gateway で CVSS 9.9 の CVE-2026-1868 が出ています。[GitLab の告知](https://docs.gitlab.com/releases/patches/other-patches/patch-release-gitlab-ai-gateway-18-8-1-released/)によれば、2026年2月6日に 18.6.2、18.7.1、18.8.1 で修正されました。こちらもカスタムフロー定義のテンプレート展開が原因で、The Hacker News は同種の脅威と位置づけています。同じコード経路かどうかは確認できていません。

暫定策は GitLab の告知には無く、Rescana がパッチ適用まで Duo Agent Platform の利用者を信頼できる人に絞り、カスタムフローの作成・変更権限を見直すよう勧めています。

動画の訂正です。動画で暫定策として紹介した「AI Gateway へのアクセスを VPN 経由に限る」は、確認した出典のどれにもありませんでした。

## 2. Zig 0.17.0 — ビルドを Configurer と Maker に分割

次はプログラミング言語 Zig の 0.17.0 です。[リリースノート](https://ziglang.org/download/0.17.0/release-notes.html)によれば、206人の貢献者による925コミット、約5か月の開発でした。当初は短いサイクルになる見込みだった、とも書かれています。

最大の変更は、ビルドの仕組みの分割です。`build.zig` を実行して段取りを作る Configurer と、その段取りどおりにビルドグラフを実行する Maker に分かれました。Maker は最適化を有効にしてビルドされ、`build.zig` を編集しても変わらないため、Zig をインストールしたあと1回ビルドすれば済みます。構成の結果はバイナリ形式でキャッシュされてファイルサイズが約25%小さくなり、キャッシュの挙動を上書きする `--cache-poison` オプションも加わりました。

速さを示す数字は、Andrew Kelley 氏による Zig の[開発ログ（5月26日の項）](https://ziglang.org/devlog/2026/)にあります。`zig build -h` の実行時間が 150ms ± 5.52ms から 14.3ms ± 744us に縮んだという計測です。比較はリリース前の開発版どうしで、測っているのは `zig build -h` だけです。実際のプロジェクトのビルド全体が約10分の1になる、という意味ではありません。

利用者に影響する変更を、リリースノートで確認できたものに絞って挙げます。

- `b.args` が廃止され、`addPassthruArgs()` に移りました。Configurer が実行時の引数を直接見られなくなったためです。
- 型リフレクションで、構造体とユニオンの情報が struct-of-arrays 形式で返るようになりました。リリースノートのコード例には `info.field_names` と `info.field_types` を並べて回す書き方があります。
- `@bitCast` で、`extern struct` や `extern union` が絡む変換は許されなくなりました。
- `@backingInt` と `@fromBackingInt` が追加され、`@intFromEnum` は非推奨になりました。単純な改名ではありません。

分離の影響で ZLS などのツール連携は一時的に不十分になっており、両チームが改善を続けているとリリースノートにあります。0.17 へ上げる前に、エディタ支援の追随を確かめたいところです。

動画の訂正です。

- リリース日を10月2日と紹介しましたが、日付を断定できる一次情報はありませんでした。配布情報の [download/index.json](https://ziglang.org/download/index.json) 上は10月1日で、記事では「10月初め」としておきます。
- Configurer をデバッグモードでビルドすると紹介しましたが、リリースノートでは `-Osafe` です。
- 「ビルドの待ち時間がおよそ10分の1」は、上記のとおり `zig build -h` だけの計測です。解説記事の byteiota も同じ数値を引いていますが、元は開発ログです。
- `std.meta.fields` の廃止でコンパイルエラーになる、という話はリリースノートで確認できませんでした。

## 3. Ubuntu 26.10 — Rust 製 OpenPGP の Sequoia PGP が main に

[26.10 のリリースノート](https://documentation.ubuntu.com/release-notes/26.10/)（コードネーム Stonking Stingray）によれば、Rust 製の OpenPGP 実装 Sequoia PGP が main に入り、`sq` と `sqv` が従来の `gpg` と `gpgv` に相当するコマンドとして提供されます。`gpg` と `gpgv` も引き続き main に残り、置き換えではなく併存です。原文は "The goal is for Sequoia PGP to become Ubuntu's default OpenPGP toolchain" で、標準にするのは将来の目標です。

[sqv のパッケージページ](https://packages.ubuntu.com/stonking/amd64/sqv)では、版は 1.4.0-1ubuntu2、依存は libc6、libgcc-s1、libssl4 の3つ、インストールサイズは amd64 で約2.2MBです。[sq](https://packages.ubuntu.com/stonking/sq) は 1.4.0-0ubuntu2 で、amd64 では約21.6MB と sqv よりずっと大きくなります。

sqv を入れた目的は、[Launchpad の MIR（Bug 2089690）](https://bugs.launchpad.net/ubuntu/+source/rust-sequoia-sqv/+bug/2089690)に、APT の署名検証で gpgv の代わりに使うため、と書かれています。リリースノートにはない記述です。MIR は2024年11月26日に起票され、2026年8月4日に main へ昇格しました。リリースノートへの追記（[PR #266](https://github.com/ubuntu/ubuntu-release-notes/pull/266)）は10月1日にマージされています。

Sequoia は2024年7月公開の RFC 9580 に対応し、旧 RFC 4880 も扱えます。一方、GnuPG 側は RFC 9580 ではなく LibrePGP を推しており、標準の足並みはそろっていません。

他のディストリビューションでは、[RHEL 10 のリリースノート](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/10.0_release_notes/overview)が、GnuPG を補う形で Sequoia PGP の `sq` と `sqv` を導入したと書いています。Debian も APT 3.0（Debian 13）から署名検証に sqv を使っていると linuxiac などが報じています（Debian の一次では未確認）。

26.10 ではほかにも、残っていた cp、mv、rm を含め coreutils が uutils（Rust 実装）に完全移行した、とリリースノートにあります。こうした流れに対し、Tux Machines のニュースまとめには "Rust Obsession Breaking Ubuntu"（Rust への執着が Ubuntu を壊している）という見出しも付いています。Sequoia 専用の批判ではなく、受け止め方の一例です。

Rust 製なのでメモリの扱いのミスは起きにくくなりますが、MIR のセキュリティ審査では脆弱なバンドル依存が2件指摘されています。gpg を使うスクリプトは今のまま動くので、慌てず `sq` と `sqv` を試してみる、くらいの距離感でよさそうです。

動画の訂正です。

- sqv のインストールサイズを2.3MBと紹介しましたが、amd64 では約2.2MBです。
- coreutils の Rust 化を「大半」と紹介しましたが、リリースノートでは完全移行です。
- sudo-rs も「すでに採用」と紹介しましたが、26.10 のリリースノートに記述は無く、「25.10 から既定」という報道があるだけです。

## 4. Arm FEAT_TLBID — TLB 無効化を「必要なコアだけ」に絞る

[Phoronix の記事](https://www.phoronix.com/news/ARM64-Linux-TLBI-Domains)によれば、Arm が TLBI Domains（TLBID）対応の初期パッチ群を Linux カーネルに送りました。記事の公開は10月3日ですが、パッチ自体の投稿日は確認できていないため「10月初め」としておきます。Phoronix が示すメーリングリストへのリンクから、投稿者は Arm の Kristina Martsenko 氏とみられます。

一般的な仕組みから説明します。ページテーブルを書き換えると、各コアの TLB（アドレス変換の結果を覚えておくキャッシュ）の古い内容を無効化しなければなりません。Arm では TLBI 命令にブロードキャストを意味する IS を付けて全コアに知らせ、DSB 命令で完了を待ちます。たとえば128コアのうち8コアでしか動いていないプロセスでも全コアに知らせるので、残りのコアへの通知は無駄になります。

パッチは、プロセスが動いていたコアなど一部のコアにだけ TLB 無効化を送るものだと Phoronix は説明しています。パッチ本体は読めておらず、内部の設計は確認できていません。

仕様面では、[LLVM の PR #163156](https://github.com/llvm/llvm-project/pull/163156)が FEAT_TLBID を Armv9.7-A の拡張として扱い、ALL* や VMALL* などの TLBI 命令に省略可能なレジスタオペランドを付けられるようにしています。この PR（TableGen に `OptionalReg` を導入）は2025年10月にマージ済みです。binutils にも[2026年1月に `+tlbid` が入っています](https://gnu.googlesource.com/binutils-gdb/+/1d0e527aa62583706b296db0e3583a2ce6c67340)。道具立ては先に整っていたわけです。Phoronix によれば、使うには LLVM 23 以降か GNU Binutils 2.46 以降が必要です。

一方で Phoronix は、性能の数値は共有されていないと明記しています。また、この機能はまだ Arm アーキテクチャリファレンスマニュアルに入っておらず、対応するシリコンが出るのはまだ先になりそうだ、とも書いています。パッチは初期のもので、マージもされていません。記事でも性能向上の数値は挙げません。

対象は Arm だけで、x86 には関係しません。効きそうなのは100コア前後の多コア Arm サーバーのような環境だろう、というのが書き手の見立てです。

動画の訂正です。動画では AWS Graviton4 のコア数などを挙げましたが、公式な裏付けが取れなかったため、記事では機種名を挙げません。

## 5. Zammad CVE-2026-102489 / 102490 — セッション固定から root へ、DIVD は AI の攻撃と見る

CISA は[10月2日のアラート](https://www.cisa.gov/news-events/alerts/2026/10/02/cisa-adds-two-known-exploited-vulnerabilities-catalog)で、Zammad の脆弱性2件を KEV（既知の悪用された脆弱性のカタログ）に追加しました。登録名は、CVE-2026-102489 が "Session Fixation Vulnerability"（セッション固定）、CVE-2026-102490 が "Improper Privilege Management Vulnerability"（不適切な権限管理）です。

CVSS は NVD で2件それぞれ確認しました。[CVE-2026-102489](https://nvd.nist.gov/vuln/detail/CVE-2026-102489) と [CVE-2026-102490](https://nvd.nist.gov/vuln/detail/CVE-2026-102490) は、どちらも CVSS v4.0 で 9.4、v3.1 で 9.8（いずれも Critical）です。DIVD や Sysdig は単独で8点台という値も載せており、数字は割れています。

NVD によれば、102489 は 6.3.0 から 6.5.4 が直接悪用可能です。7.0.0 から 7.1.3 にも欠陥はありますが、環境条件のため悪用できないとされています。102490 は 1.5.0 以降の全版（7.1.0-alpha まで）が対象です。

[DIVD の侵害事案ページ](https://csirt.divd.nl/cases/DIVD-2026-00014/)による時系列です。

- 9月21日: 攻撃者が DIVD のシステムに初期侵入した。
- 9月22日: 不審な動きを検知してデータセンターへのアクセスを遮断し、Merlon Security と調査を始めた。
- 9月24日: Zammad に報告した。
- 9月26日: CVE-2026-102489 と 102490 を限定的に開示した。
- 9月29日から30日: 詳細を公開した。
- 10月2日: CISA が KEV に追加した。

DIVD は、自律的に動く AI エージェントによる攻撃だったと見ています。[Sysdig の解説](https://www.sysdig.com/blog/ai-agent-exploits-zammad-zero-days-in-divd-breach-what-we-know-and-how-to-detect-it)は、攻撃者のスクリプトに自分の行動の理由を説明するコメントが残っていた点を挙げています。[Security Affairs](https://securityaffairs.com/200248/security/u-s-cisa-adds-zammad-gmbh-zammad-flaws-to-its-known-exploited-vulnerabilities-catalog.html)は "went from the initial access to root privileges in just seconds" と、人間の操作者を待たずに進んだと報じています。公開情報だけでは断定できないため、あくまで DIVD の見立てです。

攻撃は、セッションの乗っ取りを起点に zammad ユーザーでコマンドが実行され、102490 で root に昇格する、という連鎖です。セッション固定からコマンド実行に至る経路は、確認した資料に説明が無いため補いません。

修正版は、10月5日時点で確定できません。Zammad 公式のアドバイザリにも GitHub の Security Advisory にもこの2件の記載は無く、CVE の記録上、102490 に修正版は示されていません。DIVD は、[脆弱性のケースページ](https://csirt.divd.nl/cases/DIVD-2026-00015/)で「バージョン 7 へ更新するか、オフラインにする」よう案内しています。ただし 102490 は 7 系でも影響が残るとされ、7 系に上げれば全部解決、とは言えません。

暫定策として、Sysdig はヘルプデスクのシステムからのアクセスを制限するネットワーク分離と、外向き通信の既定拒否を勧めています。事後の確認としては、`/var/log/zammad` と `/var/log/nginx` で setuid の呼び出しや root 所有の子プロセスを探すことを挙げています。

DIVD の被害はボランティアのメールアドレスなどの流出で、ネットワーク分離により深部への侵入は阻止されたと報告されています。

動画の訂正です。

- 「9月29日に調査結果と脆弱性の番号を公開」と紹介しましたが、番号の開示は9月26日でした。
- 「6系なら 6.5.5 以降で修正」「SaaS 版は修正済み」は、どちらも裏付けが取れませんでした。GitHub のタグに 6.5.5 は存在せず、SaaS 版の状態を述べた資料も見つかりませんでした。
- 暫定策の「VPN 越しにする」と、事後確認の「cron の確認」は、確認した出典に記述がありませんでした。

## まとめ

GitLab では AI の中継役に昔ながらのテンプレート展開の穴が見つかり、Zammad では AI と見られる攻撃が古くからあるセッションの穴を突きました。Zig はビルドの段取りという昔からの部分を作り直し、Ubuntu は署名確認の道具を世代交代させようとしており、Arm はコアへの「知らせ方」を見直しています。派手な新機能の下で動く古い部品の手入れが結局は効いてくる、というのが書き手の見立てです。

普段は意識しない部品、たとえば AI 関連の中継サービスやヘルプデスク、署名確認の道具の版を、一度一覧にして眺めてみてはいかがでしょうか。

## 参考リンク

- [NVD: CVE-2026-90970](https://nvd.nist.gov/vuln/detail/CVE-2026-90970)
- [GitLab: AI Gateway パッチリリース 19.4.1](https://docs.gitlab.com/releases/patches/other-patches/patch-release-gitlab-ai-gateway-19-4-1-released/)
- [The Hacker News: GitLab の AI Gateway の修正](https://thehackernews.com/2026/10/gitlab-patches-critical-self-hosted-ai.html)
- [Zig 0.17.0 リリースノート](https://ziglang.org/download/0.17.0/release-notes.html)
- [Ubuntu 26.10 リリースノート](https://documentation.ubuntu.com/release-notes/26.10/)
- [Phoronix: Arm の TLBI Domains パッチ](https://www.phoronix.com/news/ARM64-Linux-TLBI-Domains)
- [CISA: KEV に Zammad の2件を追加](https://www.cisa.gov/news-events/alerts/2026/10/02/cisa-adds-two-known-exploited-vulnerabilities-catalog)
- [DIVD: 侵害事案 DIVD-2026-00014](https://csirt.divd.nl/cases/DIVD-2026-00014/)
- [Sysdig: Zammad の0デイと DIVD の侵害](https://www.sysdig.com/blog/ai-agent-exploits-zammad-zero-days-in-divd-breach-what-we-know-and-how-to-detect-it)
