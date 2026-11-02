---
title: "CVE-2026-98432 は Red Hat が修正を出し Ubuntu は未配布、Fedora 45 は11月3日に出荷予定、Assisted-by タグの廃止、Linux 7.4-rc1 と Apple M4、Ivanti の連鎖は KEV の期限へ（2026/11/02 Linux・OSSトレンド）"
date: 2026-11-02T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Linux カーネル", "Fedora", "AI", "Linux 7.4", "Ivanti"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

開発元で直った、決まったと聞いても、自分の環境に届くまでには間があります。今回の5本で、その間がどれくらいあるのかを確かめます。Linux カーネルの CVE-2026-98432 は、Debian には上流の修正から約11日で届きましたが、RHEL に届いたのは約4週間後で、Ubuntu には確認時点でまだ届いていません。Fedora 45 は判定会議を通りましたが、出荷は11月3日の予定です。Assisted-by タグの廃止は、決まってから mainline に入り、7.4-rc1 に含まれるまでに約3週間半かかりました。Ivanti は、3段目の欠陥の修正が出ても、すでに侵害された機器は直りません。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

この記事の確認時点は、2026年11月2日の朝8時前後（日本時間）です。配布状況、出荷状況、NVD の記録など、あとから変わりうる情報には、確認の日時を添えました。

{{< youtube "hnfkIL_RQTg" >}}

## 1. CVE-2026-98432 — RHEL に修正が出て、Ubuntu は未配布

この CVE は、10月30日の記事の[第2節](https://blog.fuga.jp/posts/2026-10-30-linux-oss-trend/)で扱いました。Anthropic の研究の全体像はそちらにあり、ここでは繰り返しません。今回の主題は、修正がどのディストリビューションに届いたかです。

### 配布状況（11月2日 7:54〜8:00 JST の確認）

- Red Hat: 確認時点の [VEX](https://security.access.redhat.com/data/csaf/v2/vex/2026/cve-2026-98432.json)（CSAF 形式の脆弱性情報。11月2日 7:55 JST に取得、更新日時は UTC の11月1日 22:35:59）に、RHSA が4件載っています。RHEL 8 の kernel-rt の [RHSA-2026:93415](https://access.redhat.com/errata/RHSA-2026:93415)、RHEL 8 の kernel の [RHSA-2026:93414](https://access.redhat.com/errata/RHSA-2026:93414)、RHEL 9 の [RHSA-2026:93412](https://access.redhat.com/errata/RHSA-2026:93412)、RHEL 10 の [RHSA-2026:93413](https://access.redhat.com/errata/RHSA-2026:93413) です。VEX の修正の記録の日時は、UTC の11月1日 20:52、21:39、22:09、22:16（日本時間では11月2日の 5:52、6:39、7:09、7:16）です。動画の公開は UTC の11月1日 21:35 なので、1件目は公開の約43分前、残りは公開の後でした。RHSA のページ自体は日付（11月1日）までで、時刻はありません
- Red Hat の食い違い: Red Hat の hydra API（機械可読の脆弱性データ）は、同じ時刻に RHEL 8・9・10 を "Affected" のままにしていました。VEX が新しく、hydra が遅れているように見えますが、理由は確かめていません。VEX にも、RHEL 9 の kernel-rt 系や OpenShift など、未修正のまま残る製品があります。「RHEL の全製品が修正済み」とは読めません
- Ubuntu: [Ubuntu の CVE ページ](https://ubuntu.com/security/CVE-2026-98432)は、"Last updated 30 October 2026" で、22.04（jammy）、24.04（noble）、26.04（resolute）、26.10（stonking）をすべて "Vulnerable work in progress"、つまり未配布と書いています。優先度は High です
- Debian: [DSA-6568-1](https://www.debian.org/security/2026/dsa-6568) は10月16日（UTC）の発行で、[トラッカー](https://security-tracker.debian.org/tracker/CVE-2026-98432)は trixie が 6.12.113-1、bookworm が 6.1.190-1 で修正済みと書いています。bookworm の告知の日付は確かめられませんでした
- AlmaLinux: [ブログ](https://almalinux.org/blog/2026-10-30-cve-2026-98432/)の見出しは、修正済みカーネルが testing で使える、という内容です（10月30日付）。Oracle・Amazon・SUSE・Rocky は、一次を確認できていないので書きません

動画は、RHEL 8・9・10 と Ubuntu 22.04〜26.10 に、修正カーネルがまだ届いていないと説明しました。動画は「直近の確認で」と時点を断っており、台本を作った11月2日 4:30 頃（日本時間）の時点では、そのとおりでした。RHEL の修正は動画の公開の前後に出ており、Ubuntu は確認時点でも未配布です。

### 欠陥と修正

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-98432) の CVSS v3.1 は 9.8（Critical）で、採点は kernel.org の CNA（Secondary）です。NVD 自身の採点はなく、状態は Received のままです（11月2日 7:59 JST の取得）。

NVD の説明によれば、再送された SYN を別の CPU が処理し、`tcp_check_req()` から SYNACK を送る間に、`ip_options_build()` で解放済みメモリを読む use-after-free が起きます。kernel.org の CNA の記録（[CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-98432)）は、認証のない相手が、IPv4 の Record Route か Timestamp のバイトを付けた TCP の SYN を送る、という筋書きを書いています。IPv6 は、最初の問題の影響を受けません。コミットメッセージによれば、別の経路の問題が IPv6 にも残りますが、設定が限られ、別のパッチで直すとされています。

原因のコードは、2015年10月のコミットで入り、Linux 4.4（2016年1月リリース）から影響を受けます。[修正コミット e3f33b0a](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=e3f33b0a1d89d738e2b913dab519226eaf76e15b) の作者は Eric Dumazet 氏で、2ファイル、2行の追加と2行の削除です。`inet_sock_destruct()` と `tcp_v4_reqsk_destructor()` の `kfree` を `kfree_rcu` に変えています。コミットの作者の日時は UTC の10月1日、取り込みは10月5日です。v7.3-rc7 に含まれ、v7.3 は10月18日に出ました。

### Red Hat の評価の推移

Red Hat の CVE ページは、[UTC の10月29日 17:05 時点の保存](http://web.archive.org/web/20261029170544/https://access.redhat.com/security/cve/cve-2026-98432)で、すでに CVSS v3.1 の 8.1 でした（攻撃の複雑さが High で、暫定の値と注記があります）。[RHSB-2026-016](https://access.redhat.com/security/vulnerabilities/RHSB-2026-016)（10月30日 16:03 公開）は、深刻度を Critical とし、UTC の10月31日 20:57 の保存では、CVE ページの値も CVSS v3.1 の 9.8 になっています。それ以前の段階については、一次で確認できていません。[TuxCare](https://tuxcare.com/blog/cve-2026-98432-linux-tcp-remote-root/)（二次の情報）は、最初は Moderate の 5.9、のちに Important の 8.1 だったと書いています。

### 悪用の状況

TuxCare の10月30日の記事は、悪用の報告も、第三者による再現の報告もなく、攻撃コードは非公開だと書いています。[KEV のデータ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)は、11月2日の確認時点（`catalogVersion` は 2026.10.30）で、この CVE を載せていません。

### MPTCP と Go 1.24

Anthropic の[ブログ](https://www.anthropic.com/research/discovering-vulnerabilities-with-claude)は、対象を、multipath TCP（MPTCP）で待ち受ける（listener を持つ）Linux サーバーと書いています。

- Go: [Go 1.24 のリリースノート](https://go.dev/doc/go1.24)は、`ListenConfig` が、対応するシステム（現時点では Linux のみ）で MPTCP を既定で使う、と書いています。[GODEBUG の文書](https://go.dev/doc/godebug)によれば、既定値は `go.mod` の `go` 行の版に追従します。動画の「Go 1.24 以降で作ったプログラム」は、正確には `go` 行が 1.24 以上のプログラムです
- RHEL: Red Hat の RHEL 9 の[文書](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_networking/getting-started-with-multipath-tcp_configuring-and-managing-networking)に、"By default the MPTCP support is disabled in RHEL." とあり、RHEL 8 の同じ章も同じ文です。RHEL 10 の文書には同じ文が見つからず、有効にする手順が書かれているだけです。AlmaLinux と Rocky が同じ既定かは確認していません。カーネルの sysctl の既定は、上流では 1（有効）で、10月30日の記事の訂正と矛盾しません
- 範囲: Go のセキュリティチームは、golang-announce の[告知](https://groups.google.com/d/msgid/golang-announce/0c2926bc-e90f-4cdb-97c3-300fff6d8885n%40googlegroups.com)で、実証された攻撃には MPTCP の待ち受けが要るが、欠陥そのものは MPTCP に限らず、待ち受けがないシステムでも似た攻撃を受ける可能性がある、と書いています

### 確かめることと、暫定策

- 動かしているカーネルの版を `uname -r` で確かめ、Red Hat や Debian の告知の修正版と照合します。Ubuntu は、確認時点で未配布です
- MPTCP の待ち受けは、`ss -H -lMn` で見られます。`ss` の man によれば、`-M` は MPTCP のソケット、`-l` は待ち受け中のもの、`-H` は見出し行の省略、`-n` はサービス名を解決しない、という意味です。古い iproute2 では `-M` が通らない可能性があります（TuxCare）
- 暫定策として、RHSB-2026-016 は、IP オプションを含む IPv4 の TCP パケットを落とす nftables のテーブルを載せています。形は RHSB の原文のとおりに使ってください。同じ文書は、これで露出は減るが完全には防げないこと、必要な業務を止める可能性があること、そして修正の代わりにならないことを書いています。本番に入れる前に、検証環境で試すよう、警告もあります

動画の訂正はありません。

## 2. Fedora 45 — 出荷は11月3日（火）の予定

確認時点（11月2日 8:03 JST）で、Fedora 45 Final は出荷されていません。[dl.fedoraproject.org の releases の一覧](https://dl.fedoraproject.org/pub/fedora/linux/releases/)は 44 までで、[releases.json](https://fedoraproject.org/releases.json) の最大は "45 Beta" です。確定している事実は、10月29日（UTC）の GO と、[告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)の "will be shipped live on Tuesday, 3 November 2026" だけで、出荷の時刻は書かれていません。判定会議の経緯は、[10月30日の記事](https://blog.fuga.jp/posts/2026-10-30-linux-oss-trend/)の第3節にあります。

### 2回の延期

1回目は、10月20日が目標でした。10月15日（米国太平洋時間）の[告知](https://www.mail-archive.com/devel@lists.fedoraproject.org/msg215769.html)は、"no suitable release candidate (rc) was available"（適切なリリース候補がなかった）と書いています。[10月19日の記事](https://blog.fuga.jp/posts/2026-10-19-linux-oss-trend/)も同じ内容です。2回目は、10月27日が目標で、10月22日の[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-22/f45-final-go-no-go-meeting.2026-10-22-17.00.html)が、ca-certificates と Stratis の2つを理由にしています。経緯は[10月29日の記事](https://blog.fuga.jp/posts/2026-10-29-linux-oss-trend/)にあります。

### 中身

RC-1.4 のコンポーズ（Fedora-45-20261028.1）の[パッケージ一覧](https://kojipkgs.fedoraproject.org/compose/45/Fedora-45-20261028.1/compose/metadata/rpms.json)に、gnome-shell 51.0 と kernel 7.2.11 があります。確認したのは Everything の変種で、Workstation のイメージそのものの中身ではありません。

- DRM Panic: [Change のページ](https://fedoraproject.org/wiki/Changes/DrmPanicFrontend)は、カーネルパニックの画面に QR コードでエラーの記録を出す仕組みに、Fedora 専用のウェブページを組み合わせる提案です。Change ページの説明では、そのページが、何が起きたかを分かりやすく説明し、Bugzilla への報告にも対応します。実際のページ（drm-panic.fedoraproject.org）は JavaScript のアプリで、文面は確かめられませんでした。F45 のカーネル設定にこの URL が入っていますが、F43・F44 のブランチの設定にも同じ URL があり、F45 だけの新機能とは言えません
- kmscon: [Change のページ](https://fedoraproject.org/wiki/Changes/UseKmsconVTConsole)によれば、すべての仮想コンソールを、カーネルの fbcon から、ユーザー空間の kmscon に替えます。Unicode の対応とスクロールがよくなり、kmscon が起動しないときは getty と fbcon に戻ります。インストールや起動の処理は変わりません

### 更新の前に確かめる3点

- RPM の署名: [Change のページ](https://fedoraproject.org/wiki/Changes/Enforcing_signature_checking_by_default)で、`%_pkgverify_level` の既定が digest から all に変わります。署名のないパッケージは、`--nosignature` などで明示的に上書きしない限り、rpm が拒否します。公式や外部のリポジトリのパッケージだけを使うシステムには影響しない、と Change のページは書いています。影響が出るのは、`rpm` での直接のインストールや、ローカルのビルドの流れです。社内で作った RPM に署名していない場合は、ここで確かめます
- Podman 6: F45 に入る Podman は 6.1.3 で、F44 は 5.8.9 のままです（[Bodhi の更新](https://bodhi.fedoraproject.org/updates/FEDORA-2026-c30886e9ec)）。[Podman 6.0.0 のリリースノート](https://github.com/containers/podman/releases/tag/v6.0.0)は、cgroups v1、iptables、slirp4netns、BoltDB のサポートの削除を書いています。slirp4netns を使っていた rootless コンテナは、Pasta への移行が必要です。BoltDB は、リリースノートが SQLite への自動移行を試みると書き、[Fedora の Change ページ](https://fedoraproject.org/wiki/Changes/Podman6)は、移行していないと更新後にコンテナの状態が使えなくなると書いて、先に 5.8 へ上げて再起動するよう案内しています。両方の記述を読んでから更新します
- oo7: [Change のページ](https://fedoraproject.org/wiki/Changes/oo7_Secrets_Service_Provider)は、GNOME Keyring を使うデスクトップの既定の Secrets Service を oo7 に替え、既存のデータは自動で移行する、と書いています。10月29日の会議で、oo7 のバグ（GNOME Keyring から移したオンラインアカウントの置き換えの失敗）は、アカウントを削除して作り直せば動く、という確認で解決とされました。詳しくは10月30日の記事の第3節です

### dnf system-upgrade

[Fedora Docs の手順](https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/)は、確認時点で F44 向けの記述のままです。`sudo dnf system-upgrade download --releasever=<番号>` の番号を替えるよう書いています。45 を指定するのは、出荷の後です。

動画の訂正です。

- 動画では、1回目の NO-GO は、リリース候補のビルドが期限までに完成しなかったためだと紹介し、画面にも「RC候補のビルドが間に合わず」と出しました。10月15日の告知は、適切なリリース候補がなかったので、既定で NO-GO だとだけ書いています。ビルドが完成しなかったという説明は、告知にありません。RC-1.1 は10月17日に出ています（[告知](https://www.mail-archive.com/devel@lists.fedoraproject.org/msg215769.html)、[RC-1.1 の案内](https://www.mail-archive.com/test-announce@lists.fedoraproject.org/msg03313.html)）。
- 動画では、2回目の理由に、証明書や LVM の問題などを挙げ、画面にも「証明書・LVMなど」と出しました。10月22日の議事録で、NO-GO の理由として扱われたのは、ca-certificates と Stratis の2つです。LVM は Accepted Blocker でしたが、修正（lvm2-2.03.43-2.fc45）は RC-1.2 に入っており、バグは10月22日 9:06（UTC）に VERIFIED で、議事録にも出てきません（[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-22/f45-final-go-no-go-meeting.2026-10-22-17.00.html)、[Bugzilla 2555274](https://bugzilla.redhat.com/show_bug.cgi?id=2555274)）。

## 3. Assisted-by タグの廃止 — 変わるのはタグで、責任のルールは変わらない

[LWN の報告](https://lwn.net/Articles/1099594/)（10月12日付、Jonathan Corbet 氏）によれば、10月8日にプラハで開かれた Maintainers Summit（招待制、約30名のカーネル開発者の1日の集まり）で、Assisted-by タグの要求を外せる、という強い合意がありました。廃止パッチを書いた Sasha Levin 氏の changelog（変更の説明）は "a strong, though not unanimous, consensus"（強い、ただし全会一致ではない合意）と書いています。

### 経緯（確認時点 11月2日 8:00 JST）

- 導入: Levin 氏自身が2025年12月23日に投稿した AI Coding Assistants の文書が、2026年1月6日に docs ツリーに入り、LWN によれば Linux 7.0 に載りました。LLM の助けを借りたパッチに Assisted-by タグを付ける、という内容です。その後、タグは "Assisted-by: LLM" に簡素化されました
- 最初の廃止案: Jeff Layton 氏が7月2日（米国東部時間）に、[LLM の申告の要求を外す](https://lkml.iu.edu/2607.0/04228.html)パッチを出しました。この案は7月にいったん見送られた、と Levin 氏の changelog は書いています
- サミットの翌日の10月9日に、Levin 氏が廃止の v1 を出し、10月13日に v2 を[投稿](https://lkml.iu.edu/2610.1/11683.html)しました。docs-next へは10月14日に Corbet 氏が「適用した」と[返信](https://lkml.iu.edu/2610.1/15868.html)しています。Linus Torvalds 氏は UTC の10月21日 0:38 に、docs-7.4 のプルをマージしました。マージのメッセージに、サミットで結論が出た Assisted-by の要求の削除、とあります。この変更は v7.4-rc1 に含まれ、関連する3つの文書で `Assisted-by` を書いた行は0行です

### 数字の出典

LWN は、7.3 の -rc7 までのマージを除く変更が 18,533 件で（記録的な数、と LWN は書きます）、そのうち 1,884 件（essentially 10%）に Assisted-by タグがあると書いています。Levin 氏の changelog にも 18,533 件はあり、タグ付きは "Roughly 10%" としか書いていません。1,884 件は LWN だけの数字で、Git で数え直してはいません。LWN は、実際に LLM を使ったパッチの数は、はるかに多いはずだとも書いています。

Levin 氏の changelog は、タグが本来果たすはずだった目印にならない理由を、次のように書いています。ルールを知らない人がいる、わざと付けない人がいる、聞く保守担当者も少ない。タグがなくてもパッチの作り方は分からず、これらのツールをほとんどの作業に使う開発者の場合は、タグがあってもほとんど何も分からない、と続きます。

### Layton 氏の3つの理由

Layton 氏のパッチは、理由を番号つきで挙げています。1つ目は "It's not universally followed"（普遍的には守られていない）で、善意で LLM を申告する人は多いが、全員ではない、と続きます。2つ目は、事実上、プロプライエタリな LLM 企業の無償の宣伝になること、3つ目は、そもそもなぜこの情報を集めたいのかが明確でないことです。

### 異論と、Torvalds 氏の返信

[Laurent Pinchart 氏](https://lkml.iu.edu/2610.1/11715.html)は10月13日に、開示を求める別の仕組みを加えないまま外すことに "I'm not happy"（賛成できない）と書きました。サミットではカバーレターに書くことも議論したが、支持した人は少なかった、とも書いています。

[Torvalds 氏の返信](https://lkml.iu.edu/2610.1/13255.html)（同日）は、"We're not going to make stupid rules that say "you can't use tools for X""（ツールごとに使用を禁じるような馬鹿げたルールは作らない）と書きました。自分が期待するのは、各自が最善を尽くし、自分のしていることを理解していることで、その理解はどのツールを使うかとほとんど関係がない、と続きます。

### 変わらないもの

- 責任: [docs.kernel.org の文書](https://docs.kernel.org/process/coding-assistants.html)に、"AI agents MUST NOT add Signed-off-by tags." とあります。DCO を法的に証明できるのは人間だけで、提出者が提出した内容の責任を負います。Levin 氏の changelog も、DCO と提出者の責任のルールは変わらない、と書きます
- 開示: AI 利用の開示が不要になった、という話ではありません。[generated-content の文書](https://docs.kernel.org/process/generated-content.html)は、カバーレターと changelog で、内容の出どころを明らかにするよう求めたまま残っています。Levin 氏の changelog は、保守担当者はパッチの作り方を今も知りたがっており、それは changelog ではなくカバーレターに書くのがよい、というサミットの見方を書いています。LWN も同じ趣旨です。義務とも、任意とも、書かれてはいません

LWN の記事で Corbet 氏は、7.3 だけで初めての貢献者が800人近くに上り、コミュニティがパッチに埋もれかけている、とも述べています。

動画の訂正はありません。

## 4. Linux 7.4-rc1 — 約2万件のコミットと Apple M4

[v7.4-rc1 のタグ](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tag/?h=v7.4-rc1)は、UTC の11月1日 21:26:31（日本時間では11月2日 6:26:31）に打たれました。[Torvalds 氏のアナウンス](https://lore.kernel.org/all/CAHk-=whOCnAwXz-FMRdQEDJQ+9b2YXh9M=GHgRay0o4cxSmPVg@mail.gmail.com/)は UTC の22:08:46 です。7.3 は10月18日（米国時間）でした。

### 数字

- コミット数: Torvalds 氏は "almost 20k commits vs the more common ~15k"（2万件近く。通常は約1万5000件）と書いています。`git rev-list --count v7.3..v7.4-rc1` の実測（11月2日の確認）は 19,780 件で、マージ 1,189 件を含み、マージを除くと 18,591 件です。[Phoronix](https://www.phoronix.com/news/Linux-7.4-Merge-Window) の集計は、rc1 の直前の時点で 19,671 件で、マージを含みます。Phoronix は、Git のコミット数で見て記録上最も忙しいマージウィンドウだったと書いています
- ソースツリーの総行数: Phoronix の集計では、rc1 の前の11月1日朝（米国東部時間）の時点で 41,605,120 行です。空行 5,193,578 とコメント 4,993,604 を含み、コードだけなら 31,417,938 行です。Linux のリポジトリでは再計測していません

アナウンスに、安定版の日付は書かれていません。[Phoronix](https://www.phoronix.com/news/Linux-7.4-rc1) は、12月の終わり前に出る見込みで、予定どおりなら12月20日ごろと書いています。これは Phoronix の見方で、確定した予定ではありません。rc1 は、新機能を入れる時期が終わり、安定化に入る合図です（[カーネルの文書](https://docs.kernel.org/process/2.Process.html)）。本番で使う段階ではない、と考えてください。

### Apple M4 と A18 Pro

[Sven Peter 氏の PR](https://lore.kernel.org/all/20261002190232.6449-1-sven@kernel.org/)（10月2日、"Apple SoC DTS changes for v7.4"）が、SoC ツリーに10月15日に適用されました。M4 のデバイスツリーのパッチの作者は Yureka Lilian 氏で、Peter 氏は PR を送った人です。

rc1 には、M4 を載せたデバイス（MacBook Pro 14インチ、iMac 24インチ、MacBook Air 13・15インチ、Mac mini）と、A18 Pro の MacBook Neo のデバイスツリーが入っています。機種名は、デバイスツリーの `model` の表記です。

- 入ったもの: デバイスツリーに、CPU コア、割り込みコントローラー、ウォッチドッグ、ピンコントローラー、I2C、起動時のフレームバッファーのノードがあります。PR の本文は "enough to boot with all cores to a serial console but future work will be required to make these useful for users"（全コアでシリアルコンソールまで起動できるが、利用者の役に立つには今後の作業が要る）と書いています。ただし[Lilian 氏のカバーレター](https://lore.kernel.org/all/20260811-apple-m4-initial-devicetrees-v3-0-6bf32d45ad0b@cyberchaos.dev/)は、SMP の起動は不安定なままだ、と書いています
- 未対応: [Asahi Linux の feature support](https://asahilinux.org/docs/platform/feature-support/m4/) の M4 の列では、GPU、USB、Wi-Fi、Bluetooth などが TBA で、インストーラーは未対応（no）です。M4 Pro と M4 Max は、今回の PR の範囲に含まれません。カバーレターによれば、M3 の初期サポートの流れを踏襲しています

### memblock と Core MM ツリー

memblock の二分探索は、10月28日の[記事](https://blog.fuga.jp/posts/2026-10-28-linux-oss-trend/)で扱いました。[採用されたコミット](https://github.com/torvalds/linux/commit/7933ad3f669670ca5f5f13de2b5cb0f92b91abf5)は、KHO（Kexec HandOver）でのメモリの取得が、約268秒から約50ミリ秒になる、と書いています。393k ページの条件での、作者の測定です。Rapoport 氏の PR を、Torvalds 氏が UTC の10月26日 3:27 にマージしました。

新しい Core MM ツリーからの最初の[プルリクエスト](https://lore.kernel.org/all/20261023172100.49643-1-david@kernel.org/)は、David Hildenbrand 氏（署名は "David Hildenbrand (Arm)"）が10月23日に送りました。内容は、メモリのホットプラグ（MEMHP）と GUP（Get User Pages）の更新です。本文は、Maintainer Summit で議論された、新しいツリーからの最初の PR だと書くだけで、目的は書いていません。[Phoronix](https://www.phoronix.com/news/Linux-Core-MM-Tree) は、Morton 氏の MM ツリーの負荷を減らすための新ツリーだと書いています。PR の本文によれば、7.4 では MM の更新が slab、memblock、Andrew Morton 氏の MM、Core MM の4つのツリーから届きます。7.5 では Morton 氏のツリーを通すパッチを減らし、コンポーネントごとのツリーの統合を始める計画で、最終的には単一の MM 統合ツリーを目標にする、と書いています。

### そのほかの変更

- HDMI 2.1: amdgpu の HDMI FRL が、既定で有効になりました。[コミット 5fd3b60d9b80](https://github.com/torvalds/linux/commit/5fd3b60d9b80) の説明によれば、FRL は HDMI 2.1 の高帯域のモードに必要で、これまでは明示的に有効にしない限り無効でした。[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)の時点（10月21日の master）では、既定は無効でした
- AMD Zen 6: amd-pstate に、Zen 6 の `epp_soc_zen6_client` が加わりました
- Snapdragon X2: rc1 に、ASUS Zenbook A14（UX3407NA）や HP EliteBook X G2q 14 AI などのデバイスツリーがあります。[Phoronix](https://www.phoronix.com/news/ASUS-UX3407NA-Linux-7.4) は、Zenbook A14 のこの機種を、18コアの X2 Elite を積む Glymur プラットフォームの機種だと書いています

動画の訂正です。

- 動画では、memblock の二分探索について、パッチの説明によると、最悪のケースで O(N log N) まで下がる、と紹介し、画面にも「最悪ケースでO(N log N)」と出しました。mainline に採用されたコミットは、候補領域の探索の計算量が O(N) から O(log N) に下がる、と書いています。O(N log N) は、10月28日の記事が書いた初版から3版までの文言で、採用された4版で書き直されました。約268秒が約50ミリ秒になる点は、採用された版にもあり、訂正はありません（[採用されたコミット](https://github.com/torvalds/linux/commit/7933ad3f669670ca5f5f13de2b5cb0f92b91abf5)、[初版](https://lore.kernel.org/all/20260903155907.1065681-1-tarunsahu@google.com/)）。

## 5. Ivanti Connect Secure — KEV の期限、3段目の修正、侵害の確認

仕組みの説明、Integrity Checker Tool（ICT）の限界、22.8 系のサポート終了は、[10月16日の記事](https://blog.fuga.jp/posts/2026-10-16-linux-oss-trend/)の第1節にあります。ここでは、その後に動いたことを書きます。10月16日の記事は、3段目の修正版が出たら、それも当てるよう書きました。その修正版が、10月29日に出ました。

### KEV の期限

[KEV のデータ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)では、次の3件が Ivanti Connect Secure の連鎖の CVE です。

| CVE | 追加日 | 期限 |
|---|---|---|
| CVE-2026-104935 | 10月13日 | 10月16日（金） |
| CVE-2026-111357 | 10月30日 | 11月2日（月） |
| CVE-2026-118527 | 10月30日 | 11月13日（金） |

日付は米国のものです。KEV のデータの公開は UTC の10月30日 17:02 で、日本時間では10月31日の 2:02 です。期限の11月2日も米国の日付で、動画の公開（UTC の11月1日 21:35）の時点では、米国東部はまだ11月1日の午後でした。

CISA の[アラート](https://www.cisa.gov/news-events/alerts/2026/10/30/cisa-adds-two-known-exploited-vulnerabilities-catalog)は、2件の追加が、悪用の証拠にもとづくと書いています。期限の根拠の BOD 26-04 が適用されるのは連邦民間行政機関（FCEB）だけで、CISA は他の組織にも、リスクにもとづく脆弱性管理を勧めています。同じ指令は、パッチの前に侵害されていないかを機関が確かめる場面についても定めています。KEV の `forensicTriage` の欄は、CVE-2026-104935 と CVE-2026-111357 が Yes、CVE-2026-118527 が No です。ランサムウェア攻撃での利用の欄は、3件とも "Unknown" です。

### 3件の記録

- CVE-2026-104935: [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-104935) 上は、CNA の Ivanti による CVSS v3.1 の 8.6（High）です（Secondary。NVD 自身の採点はありません）
- CVE-2026-111357: [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-111357) の説明は、22.8R2.4 で、dsinvoked の broker が DSCache の設定データを信頼する扱いを誤り、root への権限昇格に至る、というものです。CVSS v3.1 は 7.0（High）で、採点者は MITRE の CNA（Secondary）、ベクターは `AV:L/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:H` です。Ivanti の採点ではありません
- CVE-2026-118527: 11月2日 7:54 JST の確認で、NVD の API は該当なしを返し、CVE.org の API も記録なしを返しました。NVD と CVE.org では、CVSS も説明文も確かめられません。KEV の説明は、予測可能な数や識別子の生成の欠陥で、認証済みの遠隔の攻撃者が、内容を指定したファイルを既知の場所に置ける、と書き、CVE-2026-104935 と CVE-2026-111357 とつなげられる、と続きます

[Volexity のブログ](https://www.volexity.com/blog/2026/10/13/a-series-of-unauthenticated-events-chained-exploitation-of-ivanti-connect-secure-zero-days/)は、連鎖を、認証回避、リモートコード実行、権限昇格の組み合わせで、未認証のまま root に至る、と書きます。ZIP の検証より先にファイルを書く動作を含むコード実行の部分は、CVE-2026-104935 に含めて書かれ、CVE-2026-118527 の番号には触れていません。KEV の説明は、この動作と内容が合うように読めますが、CVE-2026-118527 が連鎖の2段目に当たると書いた一次は確認できていません。段への割り当ては、ここでは断定しません。

### 修正の時系列

- 10月13日: CVE-2026-104935 の修正が公開されました（[CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-104935) の公開は UTC の10月13日 15:31、Volexity も同日と書きます）
- 10月29日: Volexity の更新注記は、この日に Ivanti が CVE-2026-111357 を直すパッチを公開した、と書いています
- 修正版の番号: 政府機関の書き方が割れています。CISA の[アラート](https://www.cisa.gov/news-events/alerts/2026/10/13/cisa-urges-patching-newly-exploited-vulnerability-ivanti-connect-secure)（10月30日の改訂後）は、影響を受ける版を 25.1.1.2 以前、25.1.2.2 以前、22.8R2.5 以前と書きます。カナダの Cyber Centre の[AV26-1035](https://cyber.gc.ca/en/alerts-advisories/ivanti-security-advisory-av26-1035)は、25.1.1.3 未満、25.1.3.1 未満、22.8R2.6 未満と書きます。Ivanti のアドバイザリの本文は、こちらでは取得できませんでした。自分の版が対象かは、[Ivanti のアドバイザリ](https://hub.ivanti.com/s/article/Security-Advisory-Ivanti-Connect-Secure-CVE-2026-104935)で確かめてください

### パッチだけでは足りない

Volexity によれば、UTA0576 は、10月3日から連鎖を繰り返し悪用しました。調査の開始は10月5日です。侵害された機器は、当時の最新版の 22.8R2.4 で、パッチ済みでした。Volexity は、メモリ上で動き、設定を元に戻すため、ICT は変更を検出しない、と書きます。CISA も、ICT が検出できない可能性を書いています。ICT の新しい版で検出できるかは、確認できていません。Volexity は、悪用の証拠を見つけるにはフォレンジック調査が必要だと書き、ネットワークとメモリの調査を勧めています。

CISA は、侵害を疑う場合の手順を挙げています。設定のバックアップを取り、工場出荷状態に戻して最新版へ上げ、バックアップから設定を戻します。そのあと、すべてのアカウントのパスワードをリセットし、保存された証明書を失効させて再発行し、API キーとライセンスサーバーの認証情報もリセットします。クラウドや仮想環境は、インスタンスを作り直します。

Volexity と CISA は、一時的な回避策に触れておらず、修正版への更新を求めています。回避策の有無は、Ivanti のアドバイザリで確かめてください。22.8 系のサポート終了は2027年1月31日です（CISA）。[BleepingComputer](https://www.bleepingcomputer.com/news/security/ivanti-warns-of-connect-secure-zero-day-exploited-in-attacks/) によれば、Shadowserver は10月13日の時点で、外から見える機器を 5,500 台超追跡していました。これは脆弱な台数ではありません。

動画の訂正はありません。

## まとめ

CVE-2026-98432 は、Red Hat が11月1日（UTC）に RHEL 8・9・10 の修正を出し、Ubuntu は確認時点で未配布です。Fedora 45 は、判定会議で GO が出ても、出荷は11月3日（火）の予定です。Assisted-by タグの廃止は、mainline に入り、7.4-rc1 に含まれましたが、責任のルールと開示の求めは残っています。Linux 7.4-rc1 は約2万件のコミットで、Apple M4 の初期サポートは、起動の足がかりの段階です。Ivanti は、3段目の修正が出ても、侵害の確認と復旧が残ります。

5本を、この間の長さで並べ直してみます。これは書き手の考察です。上流の修正と配布の間、会議の GO と出荷の間、決定と mainline の間、パッチの公開と侵害の確認の間に、それぞれ日数があります。はじめの3つは、一次の記録を見れば測れます。最後の1つは、自分で調べないと分かりません。そのうえで、自分の環境がどの位置にあるかを確かめる、という見方です。

まず確かめることを挙げます。

- Linux のカーネルは、`uname -r` で版を確かめ、各ディストリビューションの告知と照合する。CVE-2026-98432 は、Red Hat と Debian に修正があり、Ubuntu は確認時点で未配布。MPTCP の待ち受けは、`ss -H -lMn` で見られる
- Fedora を使っているなら、出荷の後に更新する。更新の前に、RPM の署名、Podman 6、oo7 の3点を確かめる
- Ivanti Connect Secure を使っているなら、Ivanti のアドバイザリで自分の版が対象かを確かめ、修正版に上げる。パッチを当てる前に入られていないかを、ネットワークとメモリの調査で確かめる

## 参考リンク

- [Red Hat: CVE-2026-98432 の VEX](https://security.access.redhat.com/data/csaf/v2/vex/2026/cve-2026-98432.json)
- [Red Hat: RHSB-2026-016](https://access.redhat.com/security/vulnerabilities/RHSB-2026-016)
- [Ubuntu: CVE-2026-98432](https://ubuntu.com/security/CVE-2026-98432)
- [NVD: CVE-2026-98432](https://nvd.nist.gov/vuln/detail/CVE-2026-98432)
- [CVE-2026-98432 の修正コミット e3f33b0a](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=e3f33b0a1d89d738e2b913dab519226eaf76e15b)
- [Go セキュリティチームの告知（golang-announce）](https://groups.google.com/d/msgid/golang-announce/0c2926bc-e90f-4cdb-97c3-300fff6d8885n%40googlegroups.com)
- [Fedora 45 Final の GO の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)
- [Fedora Change: RPM の署名検証の既定](https://fedoraproject.org/wiki/Changes/Enforcing_signature_checking_by_default)
- [Fedora Change: Podman 6](https://fedoraproject.org/wiki/Changes/Podman6)
- [LWN: Maintainers Summit の報告](https://lwn.net/Articles/1099594/)
- [Levin 氏の Assisted-by 廃止パッチ（v2）](https://lkml.iu.edu/2610.1/11683.html)
- [docs.kernel.org: coding-assistants](https://docs.kernel.org/process/coding-assistants.html)
- [Torvalds 氏の v7.4-rc1 のアナウンス](https://lore.kernel.org/all/CAHk-=whOCnAwXz-FMRdQEDJQ+9b2YXh9M=GHgRay0o4cxSmPVg@mail.gmail.com/)
- [Asahi Linux: M4 の feature support](https://asahilinux.org/docs/platform/feature-support/m4/)
- [CISA: KEV の追加のアラート（10月30日）](https://www.cisa.gov/news-events/alerts/2026/10/30/cisa-adds-two-known-exploited-vulnerabilities-catalog)
- [Volexity: Ivanti Connect Secure の連鎖](https://www.volexity.com/blog/2026/10/13/a-series-of-unauthenticated-events-chained-exploitation-of-ivanti-connect-secure-zero-days/)

（2026/11/02 Linux・OSSトレンド）
