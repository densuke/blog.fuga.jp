---
title: "Fragnesia が KEV 入り（連邦機関の期限は10月31日）、Anthropic の研究モデルが見つけた脆弱性、Fedora 45 は RC-1.4 で GO、eMudhra の件と GKE の速報 GCP-2026-071、低い評価の ESXi の穴がゼロデイで悪用（2026/10/30 Linux・OSSトレンド）"
date: 2026-10-30T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Linux カーネル", "AI", "Fedora", "GKE", "PKI", "VMware", "ESXi"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

脆弱性の重さは、点数だけでは決まりません。攻撃の流れの中で、どの役を担うかでも変わります。今回の軸はこれです。CISA は10月28日に、Linux カーネルの Fragnesia と、VMware ESXi の CVE-2026-41709 を、同時に KEV へ追加しました。前者の NVD の CVSS v3.1 は 7.8、後者の Broadcom の CVSS v3.1 は 2.7 です。残る3本は、Anthropic の研究モデルが見つけた脆弱性、Fedora 45 の判定会議、eMudhra の件に続く GKE の速報です。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

この記事の確認時点は、2026年10月30日の朝（日本時間）です。NVD の状態、各社の修正状況、ブラウザの実施状況など、あとから変わりうる情報には、その旨を添えました。

{{< youtube "iQ8E6wtxRDE" >}}

## 1. Fragnesia（CVE-2026-46300）— KEV 入り、連邦機関の期限は10月31日

Fragnesia は、本ブログでは初出です。10月27日の記事の第2節で扱った ZDI-CAN-33367 とは別の件で、仕組みの近い Dirty Frag（CVE-2026-43284）とも別の CVE です。PHP2Shell の第一報は[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)、その後の観測は[10月27日の記事](https://blog.fuga.jp/posts/2026-10-27-linux-oss-trend/)の第5節にあります。ここでは仕組みを繰り返しません。

### KEV の記録

- 追加と期限: [CISA の KEV のデータ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)では、`dateAdded` が 2026-10-28、`dueDate` が 2026-10-31（土）です。日付のみで時刻はありません。追加から3日後という短い期限です。KEV の名前は "Linux Kernel Missing Initialization of a Variable Vulnerability" で、Fragnesia ではありません。ランサムウェア攻撃での利用を示す欄（knownRansomwareCampaignUse）は "Unknown" です
- 追加の理由: CISA の[アラート](https://www.cisa.gov/news-events/alerts/2026/10/28/cisa-adds-two-known-exploited-vulnerabilities-catalog)は、"based on evidence of active exploitation"（悪用の証拠にもとづく）と書いています。KEV の説明は、CVE-2026-109618 と CVE-2026-109619 と連鎖させると、PHP の Web シェルを仕込み、root としてコマンドを実行できる、としています
- 期限の対象: KEV の `requiredAction` は BOD 26-04 を挙げています。CISA のアラートによれば、BOD 26-04 が適用されるのは連邦民間行政機関（FCEB）だけで、FCEB 以外の組織にも、リスクにもとづく脆弱性管理と KEV の優先対応を勧めています

### 採点と修正の時期

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-46300) 自身（Primary）の CVSS v3.1 は 7.8（High）で、ベクターは `AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` です。kernel.org（CNA）ともう1者の採点も、同じ 7.8 でした。ローカルの低い権限を前提にした採点です。

修正は、[コミット f84eca5](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=f84eca5817390257cef78013d0112481c503b4a3)（題 "net: skbuff: preserve shared-frag marker during coalescing"）です。作者は William Bowling 氏で、作者の日時は UTC の2026年5月13日、取り込み（committer の日時）は米国太平洋時間の5月14日です。CVE.org と NVD の公開は5月23日でした。つまり、5月に修正が出ていた穴が、10月に悪用の確認を受けて KEV に入ったことになります。

### Dream Security が報告した攻撃

[Dream Security の報告](https://dreamgroup.com/blog/chained-php2shell-exploit-roots-25-servers)によれば、入口は Palo Alto Networks の PAN-OS の管理用ウェブサーバー（appweb）です。PHP2Shell（CVE-2026-109618 と CVE-2026-109619 の両方）で足場を作り、続けて Fragnesia で root になりました。PHP2Shell は PHP の欠陥で、それが管理用ウェブサーバーの PHP にあった、という関係です。[Unit 42](https://unit42.paloaltonetworks.com/cve-2026-109618-cve-2026-109619/) も、PHP2Shell がインターネットに公開された PAN-OS の管理インターフェースへの攻撃で悪用されていると書いています。

数字は Dream の報告のものです。FOFA（中国のインターネット資産検索エンジン）で、攻撃者は約1万9000台の PAN-OS のファイアウォールを洗い出し、応答のあった約5000台から、最終的な標的リストを240台に絞りました。root になったのは、24台のファイアウォールと、内部の管理サーバー1台を加えた計25台です。Dream は、認証なしの HTTPS 接続から永続的な root の Web シェルまで、全体で15分未満だったとし、最初に得た権限は nobody ユーザーだったと書いています。25台のうち1台は米国の政府関連組織の環境でした。

### 仕組みと影響範囲

NVD の説明とコミットメッセージによれば、IPsec の ESP-in-TCP の受信処理が、共有されたページをその場で復号してよいかを、目印（shared-frag）で判断しています。TCP の受信時のまとめ処理でこの目印が落ちると、ページキャッシュを裏に持つデータの上で、その場の復号が行われます。Red Hat は、権限の低いローカルの攻撃者が、読み取り専用のファイルを含むページキャッシュに任意のバイトを書け、root を得られると書いています。

[Tenable](https://www.tenable.com/blog/fragnesia-cve-2026-46300-faq-about-new-linux-kernel-xfrm-esp-in-tcp-priv-esc)（二次の情報）は、公開された PoC では、ディスク上のファイルは変わらず、再起動かキャッシュの破棄で元に戻ると書いています。

Dirty Frag との関係は、[Ubuntu のセキュリティ情報](https://ubuntu.com/security/CVE-2026-46300)の注記が分かりやすいです。Dirty Frag の修正（CVE-2026-43284）は、目印を復号時に確かめる側の修正です。注記が挙げる2つのコミット（f84eca5 を含む）は、その目印が途中で失われないようにする修正です。Ubuntu は "Shipping 43284 without these two leaves the exploit window open." と書いています。Red Hat は、Fragnesia を Dirty Frag の変種と呼んでいます。Dirty Frag の NVD の公開は2026年5月8日です。

Ubuntu は、PoC の実行に espintcp カーネルモジュールが要ると書いています。影響を受けるのは、Ubuntu の 22.04・24.04・26.04（LTS）、RHEL 8・9・10、Debian です。Ubuntu の 20.04 以前は "Not affected" です。

### 修正版

- アップストリーム: [CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-46300) の kernel.org（CNA）の記録で、修正済みとして載る版は、5.10.257、5.15.208、6.1.174、6.6.141、6.12.91、6.18.33、7.0.10、7.1 です。台本が挙げた5系列は、この一覧に含まれます
- Ubuntu: 26.04 が 7.0.0-22.22、24.04 が 6.8.0-124.124、22.04 が 5.15.0-181.191 で修正されています
- Debian: [トラッカー](https://security-tracker.debian.org/tracker/CVE-2026-46300)で、bookworm（security）が 6.1.190-1、trixie（security）が 6.12.113-1 です
- Red Hat: [RHSB-2026-003](https://access.redhat.com/security/vulnerabilities/RHSB-2026-003)は、影響を受ける製品の修正を公開済みと書いています
- Amazon Linux: [ALAS](https://explore.alas.aws.amazon.com/CVE-2026-46300.html)は、Amazon Linux 2 と 2023 のカーネルを、この CVE の修正済みとして載せています
- GKE: 速報 GCP-2026-033 が、Fragnesia の速報です（2026-05-14 公開、2026-07-16 更新）。Ubuntu ノードの GKE Standard が影響を受け、Container-Optimized OS のノードと Autopilot は影響を受けない、と書いています。トピック4の GCP-2026-071 とは別の速報です

### 暫定策と、確かめること

暫定策は、Ubuntu の[記事](https://ubuntu.com/blog/dirty-frag-linux-vulnerability-fixes-available)が esp4、esp6、rxrpc のモジュールを読み込ませないことを挙げています。AFS や RxRPC を使う環境では機能に影響し、更新後は不要だとも書いています。Red Hat の RHSB-2026-003 は、挙げているのが esp4 と esp6 の2つで、止めると IPsec が動かなくなると警告しています。rxrpc は Dirty Frag の別の CVE（CVE-2026-43500）の話で、Red Hat の製品は対象外だと書いています。つまり rxrpc が並ぶのは、暫定策が Dirty Frag の3件に共通だからです。設定の手順は、各社の告知に従ってください。

- `uname -r` で動かしているカーネルの版を確かめ、各ディストリビューションの告知の修正版と照合します
- IPsec を使っている環境は、モジュールを止める暫定策の前に、更新で対応できるかを確かめます
- PAN-OS の管理インターフェースを、インターネットに公開しません。Unit 42 は、公開されている場合は直ちに外し、信頼できる内部の IP アドレスに限定するよう勧めています

動画の訂正です。

- 動画では、Amazon Linux のように該当のモジュール自体を同梱していないディストリビューションは影響を受けない、という情報もあると紹介し、画面にも「Amazon Linux は該当モジュールなし」と出しました。この内容は Tenable のブログにありますが、Amazon 自身の ALAS は、Amazon Linux 2 と 2023 のカーネルをこの CVE の修正済みとして載せています。影響なしとは書かれていません（[ALAS](https://explore.alas.aws.amazon.com/CVE-2026-46300.html)、[Tenable](https://www.tenable.com/blog/fragnesia-cve-2026-46300-faq-about-new-linux-kernel-xfrm-esp-in-tcp-priv-esc)）。

## 2. Anthropic の研究モデルが見つけた脆弱性 — 5つの連鎖

先に範囲を書きます。[Anthropic のブログ](https://www.anthropic.com/research/discovering-vulnerabilities-with-claude)は、Frontier Red Team の投稿で、日付は Oct 27, 2026（時刻とタイムゾーンの記載はありません）です。ブログが詳しく書いた5つの連鎖は、いずれも修正済みと書かれています。悪用された事例の報告ではありません。ブログは、各ベンダーへ協調的な開示で報告し、開発者に90日の修正の猶予を与え、公開済みの告知を超える詳細を語るのはさらに45日後、という方針だと書いています。

モデルの名前は、ブログに書かれていません。原文は "an unreleased, internal research model"（未公開の社内研究モデル）です。ブログは、モデルが脆弱性を見つけ、つなぎ、"with little human involvement"（人の関与はわずか）で、誰でも実行して確かめられる動く攻撃コードを作れる、と書いています。連鎖の例では "After initial prompting"（最初に人が指示を与えたあと）とも書いており、人の関与がゼロだったとは書いていません。

### 5つの連鎖

- Chrome（macOS）: macOS の既定の構成の Chrome で、ページを開くだけでアプリが起動する PoC です。V8 の欠陥から始まる4つの欠陥の連鎖で、ブラウザのサンドボックスの外でコードを実行できます。ブログによれば、Google に報告した発見の全体で62件の CVE が採番され、Chrome 156 までに修正済みで、すべて深刻度が critical か high、うち13件がサンドボックス脱出、21件はレンダラーの侵害に使えたとされています。62件は連鎖の件数ではなく、報告全体の件数です。Chrome 156 の Stable は、[Chrome Releases ブログ](https://chromereleases.googleblog.com/)では10月20日（火）の更新です
- Safari: コードの実行に頼らず、ブラウザのプロセスのメモリの読み書きで、セキュリティの旗、オブジェクトの大きさ、URL を書き換える連鎖です。Safari の履歴や Cookie などを読み、他のドメインへ認証付きのリクエストを送って応答を読めた、とブログは書きます。ブログによれば、弱点のいくつかは単体では脆弱性ではなく、意図どおりの振る舞いで、組み合わせたときに悪用できるものでした。Apple は報告を送った当日に受領を知らせ、修正は利用者に提供済みとブログは書きますが、ブログに修正版の版数はありません
- Android: Pixel 9 の実機で、盗まれた端末のロックを解除せずに、USB 経由で写真などの個人情報を取り出せた連鎖です。ブログは "This issue has been addressed by Google." と書いています。ブログに CVE 番号はありません
- Windows: HTTP/3 を Windows の標準の実装で処理するマシンを、遠隔から落とせた連鎖です。[MSRC](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2026-33096) の CVE-2026-33096 は、公開が2026年4月14日（太平洋時間の7:00）です。題は "HTTP.sys Denial of Service Vulnerability"、CVSS v3.1 は 7.5（Microsoft の採点）、深刻度は Important です。緩和策に HTTP/3 の無効化が載っています。NVD 上は Microsoft（secure@microsoft.com）の Secondary の採点で、NVD 自身の採点はありません
- Linux: ブログは、multipath TCP の listener を持つ Linux サーバーに、認証もユーザーの操作もなく、root でコマンドを実行できる攻撃だと書いています。番号は CVE-2026-98432 です。詳しくは次の項に書きます

### Linux の CVE-2026-98432

ブログは、欠陥を "a race condition-induced UAF bug in the kernel networking stack" と書き、multipath TCP の listener への攻撃と説明しています。一方、kernel.org（CNA）の記録と[修正コミット](https://git.kernel.org/linus/e3f33b0a1d89d738e2b913dab519226eaf76e15b)の題は "ipv4: free inet_opt and ireq_opt after an RCU grace period" で、IPv4 の TCP のソケット（`tcp_v4_syn_recv_sock()`）の欠陥として書かれ、multipath TCP の語はありません。影響範囲は 4.4 以降です。2つの一次の記述は食い違っており、どちらが実態に近いかは、ここでは決められません。

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-98432) の CVSS v3.1 は 9.8（Critical）で、採点は kernel.org の CNA、NVD の分析は未了（Received）です。公開は10月15日です。CVE.org の記録で、修正済みとして載る版は、5.10.272、5.15.223、6.1.190、6.6.159、6.12.113、6.18.56、7.2.10、7.3 です。Debian は bookworm が 6.1.190-1、trixie が 6.12.113-1 です。ブログは、アップストリームで直され、保守中のすべての安定版ブランチへバックポートされたと書いています。

自分の環境で確かめるには、カーネルの版を、ディストリビューションの告知や上の版と照合します。multipath TCP を使っているかどうかを確かめる手順は、一次で確かめられていないので書きません。

### 修正の時期

修正の時期は、連鎖ごとに違います。Windows は4月14日、Linux の CVE は10月15日の公開、Chrome 156 は10月20日です。ブログの公表は10月27日で、Windows の修正は、その約6か月前でした。

動画の訂正です。

- 動画では、multipath TCP について、最近のディストリビューションでは既定で無効だと紹介し、画面にも「既定は無効 (データセンターは要注意)」と出しました。ブログに「既定で無効」の記述はありません。カーネルの sysctl の `net.mptcp.enabled` の既定値は 1（有効）です（[カーネルの文書](https://docs.kernel.org/networking/mptcp-sysctl.html)）。アプリが multipath TCP のソケットを開いたときだけ使われる、という一般論はありますが、ディストリビューションの既定とは別の話です。また、CVE-2026-98432 は、ブログが multipath TCP と書く一方、kernel.org の記録は IPv4 の TCP 全般の欠陥として書いており、一次の間で食い違っています（[ブログ](https://www.anthropic.com/research/discovering-vulnerabilities-with-claude)、[CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-98432)）。

## 3. Fedora 45 — RC-1.4 で GO、出荷は11月3日

二度目の NO-GO と ca-certificates の経緯は、[10月29日の記事](https://blog.fuga.jp/posts/2026-10-29-linux-oss-trend/)の第3節で扱いました。そこで結果が出ていないと書いた判定会議が、その後に開かれ、GO になりました。

### 10月29日の判定会議

[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-29/f45-final-go-no-go-meeting.2026-10-29-18.02.html)によれば、会議は UTC の10月29日 18:02:25 に始まり、19:28:19 に終わりました（日本時間では10月30日の 3:02 から 4:28）。10月28日の[リマインダー](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03865.html)と [fedocal](https://calendar.fedoraproject.org/meeting/11450/) は 18:00 UTC と書いていて、実際の開始はその直後でした。"AGREED: F45 Final is GO"（19:22:17 UTC）と、"Fedora Linux 45 Final is GO and will release on the current target date of 2026-11-03 with RC-1.4" の記録があります。

[GO の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)は、米国太平洋時間の10月29日 14:50:06（UTC の 21:50、日本時間では10月30日 6:50）の送信で、"The Fedora Linux 45 Final RC 1.4 compose is GO and will be shipped live on Tuesday, 3 November 2026." と書いています。当初の目標日は10月20日でした（[10月8日の記事](https://blog.fuga.jp/posts/2026-10-08-linux-oss-trend/)のスケジュール）。判定会議は、10月15日、10月22日、10月29日の3回で、前の2回が NO-GO でした。

### RC-1.4

[RC-1.4](https://www.mail-archive.com/test-announce@lists.fedoraproject.org/msg03325.html) の案内は、QA の返信が引用する日時で、UTC の10月28日 21:36（日本時間では10月29日 6:36）です。10月29日の記事が書いた「10月28日」は UTC で、日本時間では29日になります。RC-1.3 は UTC の10月28日 7:46 でした。RC-1.4 は RC-1.3 の代替で、違いは2点です。1つは stratisd のパッチの追加、もう1つは RC-1.2 にあった Cosmic の修正が RC-1.3 で抜けていたのを戻したことです。議事録は、RC-1.3 と RC-1.4 の両方を F45 Final の候補として検討できる（18:12 UTC）と合意し、"All blockers have been addressed. RC-1.4 is the compose that will be reviewed for F45 Final"（18:33 UTC）と記録しています。

### ブロッカーの状態

10月22日の NO-GO のあと、ブロッカーは次のように解決しました。出典は [blockerbugs](https://qa.fedoraproject.org/blockerbugs/milestone/45/final/buglist) と Red Hat Bugzilla です。

- ca-certificates（[2556376](https://bugzilla.redhat.com/show_bug.cgi?id=2556376)）: -2 を F43・F44・F45 に出し、F45 では UTC の10月23日 4:38 に stable、バグは同日 16:09 に CLOSED（ERRATA）です。RC-1.3 の変更点に、eMudhra の証明書をもう1本外す更新が載っています
- AArch64 Server の netinst イメージ（[2544671](https://bugzilla.redhat.com/show_bug.cgi?id=2544671)）: RC-1.1 と RC-1.2 のイメージは 1,436,338,176 バイトで、上限の 1,400,000,000 バイトを超えていました。10月22日の会議で、上限を上げることに原則合意し、[docs の PR #115](https://forge.fedoraproject.org/operations/docs/pulls/115)（上限を 1.5G に）が UTC の 18:44:08 にマージされ、バグは 21:55:13 に CLOSED（WORKSFORME）になりました。イメージを小さくしたのではなく、上限を変えて解消しています
- LUKS の上の LVM（[2555274](https://bugzilla.redhat.com/show_bug.cgi?id=2555274)）: 10月22日に VERIFIED、10月23日に lvm2-2.03.43-2.fc45 が stable になって閉じました。10月29日の記事と同じ内容です
- Discover（[2480694](https://bugzilla.redhat.com/show_bug.cgi?id=2480694)）: Fedora 44 のリポジトリの古い版のパッケージが入る問題です。バグの原文は、最新ではなく古い版がインストールされ、直後に更新を促される、という症状を書いています。plasma-discover-6.7.5-2 が10月23日に stable になり、閉じました
- Stratis（[2543511](https://bugzilla.redhat.com/show_bug.cgi?id=2543511)）: 10月22日に AcceptedBlocker になり、10月29日の会議では VERIFIED でした。議事録は、RC-1.3 で 80% 修正、RC-1.4 で 100% 修正と記録しています
- oo7（[2560819](https://bugzilla.redhat.com/show_bug.cgi?id=2560819)）: 10月29日の会議で、ON_QA の Accepted Blocker でした。議事録によれば、記述どおりの修正の再現と確認はできなかったものの、影響を受けたアカウントを削除して作り直すと動くことを確認し、リリースには十分な解決とみなしました

会議のあと UTC の22:00 に同期された blockerbugs では、Accepted Blocker は Stratis（VERIFIED）と oo7（ON_QA）の2件でした。動画が挙げた eMudhra、AArch64、LUKS と LVM、Discover の4つは、いずれも一度は Accepted Blocker に受理され、この時点では解決済みでした。

### 証明書の更新を出した各ディストリビューション

- Debian: ca-certificates の 20260816+nmu1（UTC の10月20日）の changelog に、emSign ECC Root CA - G3 と Comodo AAA Services の root を blacklist する記述があります。確認したのは unstable の版で、stable と oldstable への反映は確かめていません
- Ubuntu: [USN-8944-1](https://ubuntu.com/security/notices/USN-8944-1)（10月20日）が、中間 CA 証明書の侵害を理由に、emSign ECC Root CA - G3 を外すと書いています
- Red Hat: [CVE-2026-114406](https://access.redhat.com/security/cve/CVE-2026-114406) は、eMudhra の中間 CA 証明書を信頼しない更新で、Red Hat の採番です。Go の CVE-2026-111943 とは別の番号です。RHEL 10 は RHSA-2026:88455（10月22日）です

### 確かめること

Fedora の利用者は、`rpm -q ca-certificates` で -2 以降が入っているかを確かめます。出荷は11月3日（火）の予定です。

動画の訂正です。

- 動画では、Go/No-Go 会議が日本時間の10月31日の午前2時に開かれると紹介し、画面にも「日本時間 10/31 2:00」と出しました。また、会議で GO が出れば予定どおり正式リリースだと紹介しました。会議は、UTC の10月29日 18:02 に始まり 19:28 に終わっており（日本時間では10月30日の 3:02 から 4:28）、動画の公開より前に終わっていました。結果は GO で、出荷は11月3日、RC-1.4 です（[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-29/f45-final-go-no-go-meeting.2026-10-29-18.02.html)、[GO の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)）。
- 動画では、AArch64 Server のイメージが、容量の上限を約6.8MB 超えていると紹介し、実際のイメージは約14億680万バイトだったと話しました。約6.8MB は、8月17日の検証（Branched compose）の値です。RC-1.1 と RC-1.2 のイメージは 1,436,338,176 バイトで、上限を約36MB 超えていました（[Bugzilla 2544671](https://bugzilla.redhat.com/show_bug.cgi?id=2544671)）。
- 動画では、AArch64 の問題は RC-1.4 でもまだ未解決だと紹介し、画面にも「RC-1.4 でも未解決」と出しました。10月22日の会議で、リリースにとって addressed とみなされ、上限を 1.4GB から 1.5GB に上げる docs の PR が UTC の10月22日 18:44 にマージされ、バグは同日 21:55 に CLOSED（WORKSFORME）になっています（[議事録（10月22日）](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-22/f45-final-go-no-go-meeting.2026-10-22-17.00.html)、[docs の PR #115](https://forge.fedoraproject.org/operations/docs/pulls/115)）。

## 4. eMudhra の件と、GKE の速報 GCP-2026-071

eMudhra の件の経緯、つまり鍵の値と復元の方法、ブラウザの最初の対応は、[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)の第4節にあります。Go の CVE の番号と Fedora の ca-certificates は、[10月29日の記事](https://blog.fuga.jp/posts/2026-10-29-linux-oss-trend/)の第3節です。ここでは、GKE の速報が何を直したかと、eMudhra の撤退の発表を書きます。

### GKE の速報

[GKE のセキュリティ速報](https://docs.cloud.google.com/kubernetes-engine/security-bulletins)の GCP-2026-071 は、公開が2026-10-23、更新が2026-10-27、参照する CVE は CVE-2026-111943、重大度は High（Google の判定）です。GCP-2026-033（Fragnesia）の速報とは別です。速報は、侵害された eMudhra の下位 CA の秘密鍵を信頼する、更新されていない TLS クライアントとコンテナランタイムは、外部への TLS 接続で、通信の途中に入られる攻撃（MitM）を受けうると書いています。

- 対象: Container-Optimized OS か Ubuntu のノードイメージで動く、サポート中のすべての GKE Standard と Autopilot の版です。ノードイメージと GKE のシステムコンテナ（修正済みの Go ランタイムでコンパイル）は、侵害された CA を信頼しないよう更新中、と書いています
- 影響しうる通信: containerd が外部のレジストリからイメージを取得する、といったノード上のデーモンの外部への TLS 接続と、コントロールプレーンの kube-apiserver が `caBundle` なしで外部の HTTPS Webhook を呼ぶ場合です。ただし速報は、これらの接続の大半は Google Cloud 上のレジストリやエンドポイントへの暗号化された経路で、MitM の危険は小さいとも書いています
- 影響しない通信: クラスターのコントロールプレーンとノードの間の相互 TLS は、クラスターごとの独立した専用の PKI を使うため影響を受けません
- 状態: Ubuntu 向けの 1.33、1.36、1.37 の修正版は、確認時点で検証中と書かれています。10月27日の更新で、Ubuntu と、COS 上の GKE 1.37 の修正版が追加されました。確認時点で、これ以降の更新はありません。修正版の一覧は、速報を見てください

### アプリのコンテナと、Go・Python

速報は、"Customer application containers do not inherit the host node's root CA store and must be updated independently." と書き、ノードを更新しても、アプリのコンテナは直らないとして、パッチ済みのベースイメージで作り直すよう勧めています。ブラウザやノードが対応しても、アプリのコンテナは別に更新が要る、ということです。

ここから先は、速報ではなく書き手の説明です。Go のアプリは、10月19日に出た Go 1.26.10 か 1.27.3 以降でビルドし直します。crypto/x509 に、信頼できなくなった中間証明書の拒否リストが入った版です（[Go の issue](https://github.com/golang/go/issues/82345)）。CVE-2026-111943 は、Go プロジェクトが採番した番号で、NVD に採点はありません。Python は、certifi を 2026.10.19 以降に上げます。PyPI で10月20日（UTC）に公開された版で、確認時点の最新は 2026.10.23 でした。

パッチを当てられない場合の緩和策として、速報は、Pod の仕様でイメージのダイジェスト（`@sha256:...`）を指定するか、Binary Authorization を使うことを挙げています。唯一の手段とは書いていません。Webhook の `caBundle` の確認も挙げています。

速報は、悪用の有無には触れていません。確認時点の CISA の KEV（UTC の10月29日 19:09 に公開された版）に、CVE-2026-111943 は載っていません。

### 鍵の原因と、ブラウザの対応

鍵が作られたのは2025年4月30日の鍵生成の儀式です。8件の鍵は、Mozilla の確認で256未満の整数でした。原因の説明は、一次の間で割れています。Google の[ブログ](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)は "generated with insufficient randomness"（乱数の不足）と書きます。eMudhra の[状況ページ](https://emudhra.com/en/post/certificate-security-incident)は、"A script error resulted in issuing CA's with weak keys"（スクリプトの誤りで弱い鍵ができた）、鍵のラップとアンラップの手順で強い鍵とは別に弱い鍵の組ができた、と説明し、"We have not yet confirmed the exact root cause"（正確な原因はまだ確認できていない）と書いています。

研究者が各社へ報告したのは10月17日で、Chrome Root Program は UTC の18:05、Mozilla は 20:06 に受け取りました。公開された最初の記録は、10月18日（UTC の 12:06）に作られた [Bugzilla #2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449) です。

中間 CA のブロックは、Chrome の CRLSet が UTC の10月17日 19:45、Mozilla の OneCRL が同日 22:59 に完了し、Apple は10月19日から12件をブロックしています。ルート（emSign ECC Root CA - G3）の扱いは別です。Mozilla は10月20日にルートの緊急削除を決め、Apple は10月23日にこのルートのブロックを始めました。Google は、Chrome Root Store からの削除を、米国太平洋時間の10月27日の朝に出す予定と書いています。Chromium のソースでは、10月20日のコミットで一覧から外れています。ただし、これは利用者への配信の日時ではありません。配信の実施を確かめられる一次は見つかりませんでした。外れるのは G3 のルートだけで、emSign Root CA - G1 は Chrome と Mozilla に残ります。

### eMudhra の撤退の発表

eMudhra の[プレスリリース](https://emudhra.com/en/press-release/emudhra-to-exit-global-ssl-tls-certificate-business)（2026年10月22日）は、取締役会が、グローバルな SSL/TLS 証明書事業から自主的に撤退すると決めたと書いています。G1（RSA）のルートは、移行が終わるまで顧客に使われ続けます。

動画の訂正です。

- 動画では、2025年4月の鍵生成で作られた鍵に欠陥があり、10月17日に研究者が公表したと紹介しました。10月17日は、研究者が Apple、Google、Microsoft、Mozilla、eMudhra へ報告した日です。公開された最初の記録は、10月18日の Bugzilla です。2025年4月の鍵生成は一次と合っています（[Bugzilla #2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)、[Google のブログ](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)）。
- 動画では、原因は鍵を作るときの乱数の弱さだと紹介し、画面にも「原因: 鍵生成時の乱数の弱さ」と出しました。Google は乱数の不足と書きますが、eMudhra 自身はスクリプトの誤りと説明し、正確な原因は未確認としています。乱数の弱さと言い切れる状態ではありません（[eMudhra の状況ページ](https://emudhra.com/en/post/certificate-security-incident)）。
- 動画では、10月27日前後には主要なブラウザの信頼リストから外されたと紹介し、画面にも「主要ブラウザは信頼リストから除外」と出しました。Chrome の削除は、Google が10月27日の朝（太平洋時間）に出す予定と書いたもので、実施は一次で確かめられていません。Apple のルートのブロックは10月23日、Mozilla の緊急削除の決定は10月20日です。外れるのは G3 のルートだけで、G1 は残ります（[Google のブログ](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)、[Apple](https://support.apple.com/en-us/149555)）。
- 動画では、GKE の速報の更新時点では悪用は確認されていないとされていると紹介し、画面にも「悪用は未確認 (10/27時点)」と出しました。GCP-2026-071 の本文に、悪用の有無についての記述はありません。CISA の KEV に CVE-2026-111943 が載っていないのは事実です（[GKE のセキュリティ速報](https://docs.cloud.google.com/kubernetes-engine/security-bulletins)）。

## 5. ESXi の CVE-2026-41709 — Low の評価で、ゼロデイとして悪用

先に、影響を受ける条件を書きます。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-41709) の説明は、"A malicious administrator could exploit this issue to perform certain operations without them being logged."（悪意のある管理者が、特定の操作をログに残さずに実行できる）です。管理者権限が前提で、CWE-778（ログ記録の不足）です。対象は、Broadcom の[アドバイザリ VMSA-2026-0006](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/38017) の記録で、ESX 8.0、9.0.x.x、9.1.x.x と、Cloud Foundation、vSphere Foundation、Telco Cloud Platform の修正前の版です。

### 採点と KEV

- 採点: Broadcom は、重大度を Low、CVSS v3.1 の最大の基本スコアを 2.7 と評価しています。ベクターは `AV:N/AC:L/PR:H/UI:N/S:U/C:N/I:L/A:N` です。NVD 上は Broadcom（security@vmware.com）の Secondary の採点で、NVD 自身の採点はありません。CISA の SSVC は、exploitation が active、automatable が no、technical impact が partial です
- KEV: [CISA の KEV のデータ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)では、`dateAdded` が 2026-10-28、`dueDate` が 2026-11-11（水）で、追加の14日後です。`requiredAction` は BOD 26-04 を挙げ、ランサムウェア攻撃での利用を示す欄は "Unknown" です。同時に追加された Fragnesia は、`dueDate` が3日後の 2026-10-31 でした。KEV の項目の `forensicTriage` は、Fragnesia が Yes、CVE-2026-41709 が No で、期限は3日と14日です。両者の因果は、ここでは書きません

### 悪用の経緯

[CrowdStrike の発表](https://www.crowdstrike.com/en-us/blog/crowdstrike-2026-legal-threat-landscape-report/)（10月28日付）は、"In several of these cases, and as late as early 2026, the adversary exploited ESXi command logging bypass vulnerability CVE-2026-41709 as a zero-day." と書いています。遅くとも2026年の初めまで、ゼロデイとして悪用したということです。攻撃者は Warp Panda で、CrowdStrike は、2025年12月の[紹介記事](https://www.crowdstrike.com/en-us/blog/warp-panda-cloud-threats/)の題で、中国と関係のある攻撃者（China-nexus）と呼んでいます。今回のブログは、米国の組織への複数の侵入に、法務分野の標的が含まれていたと書きます。Warp Panda のプロフィールは、BRICKSTORM、Junction、GuestConduit などのマルウェアを挙げています。

[SecurityWeek](https://www.securityweek.com/chinese-hackers-quietly-used-low-severity-esxi-logging-flaw-as-zero-day/)（二次の情報）は、マルウェアの展開は2025年を通じて、CVE の悪用は遅くとも2026年の初めまで、と区別して書いています。CVE の悪用が2025年に始まったとは、一次に書かれていません。また、Broadcom も CrowdStrike も、どの操作が記録されないのか、その仕組みを公表していません。

Broadcom のアドバイザリの初版は2026年7月29日で、KEV 入りの10月28日まで91日、約3か月です。アドバイザリは、発見者として CrowdStrike の Ian Barton 氏に謝意を示しています。ただし、KEV 入りのきっかけが CrowdStrike の分析だと、CISA が書いたものはありません。CrowdStrike の発表と KEV の追加が同じ日だった、という事実までです。

### 同じアドバイザリの5件

VMSA-2026-0006 は、CVE を5件含みます。CVE-2026-59309（vCenter の認証回避）、CVE-2026-59310（vCenter のディレクトリトラバーサル）、CVE-2026-47876（ESX の VMXNET3 の範囲外書き込み。Broadcom の Q&A は VM escape と認めています）、CVE-2026-41703（ESX・Workstation・Fusion の範囲外読み取り）、そして CVE-2026-41709 です。NVD の CVSS v3.1 は、CVE-2026-59309 と CVE-2026-59310 が 9.8、CVE-2026-47876 が 9.3、CVE-2026-41703 が 7.6 で、採点者はいずれも Broadcom（Secondary）です。CVE-2026-59310 が KEV 入りした経緯は、[8月20日の記事](https://blog.fuga.jp/posts/2026-08-20-linux-oss-trend/)で扱いました。同じアドバイザリから KEV に入るのは、今回が初めてではありません。

Workstation と Fusion は、CVE-2026-41709 の対象ではありません。ただし、同じアドバイザリの CVE-2026-41703 の対象で、26H1 で修正されています。

### 対策

Broadcom のアドバイザリの回避策は "None" で、修正ビルドへの更新が対策です。Response Matrix の修正版は、9.1.x.x が ESXi-9.1.0.0-25370933、9.0.x.x が ESXi-9.0.2.0100-25595025、8.0 が ESXi80U3j-25429389 です。

パッチを当てる前の期間は、管理操作の記録が欠けている可能性があります。その期間は、vCenter のイベントログ、ネットワークの通信記録、ID プロバイダーのサインイン記録などと突き合わせて確かめるのがよいと考えます。どちらも書き手の見方で、一次の推奨としては確認できませんでした。

動画の訂正です。

- 動画では、侵入後は、クラウドのセッショントークンを盗んだり、多要素認証の端末を勝手に登録したりして、居座りを続けたとされていると紹介し、画面にも「トークン窃取・認証端末の不正登録 (とされる)」と出しました。この話の出典は、CrowdStrike の2025年12月4日のブログ（Warp Panda の紹介）で、CVE-2026-41709 の悪用とは別の侵入の話です。10月28日の CrowdStrike のブログには、セッショントークンも多要素認証の記述もありません（[2025年12月のブログ](https://www.crowdstrike.com/en-us/blog/warp-panda-cloud-threats/)、[10月28日のブログ](https://www.crowdstrike.com/en-us/blog/crowdstrike-2026-legal-threat-landscape-report/)）。

## まとめ

Fragnesia は KEV に入り、連邦機関の期限は10月31日です。Anthropic の研究モデルが見つけた脆弱性は、ブログが詳しく書いた5つの連鎖がいずれも修正済みで、Linux の CVE-2026-98432 は欠陥の場所の記述が一次の間で食い違っています。Fedora 45 は、10月29日の会議で RC-1.4 が GO になり、出荷は11月3日です。GKE の速報は、ノードとアプリのコンテナが別の更新だと示しています。ESXi の CVE-2026-41709 は、Broadcom の CVSS v3.1 が 2.7 でも、KEV に入りました。

1本目と5本目を、役割で並べ直してみます。これは書き手の考察です。Fragnesia は、足場を root に変える役でした。CVE-2026-41709 は、侵入後に痕跡を残さない役でした。どちらの役も、1つの CVE の点数には現れず、攻撃の流れの中でだけ見えます。点数に加えて、自分の環境で、その穴が攻撃の流れのどこに置かれるかを考える、という見方です。

まず確かめることを挙げます。

- Linux のカーネルは、`uname -r` で版を確かめ、各ディストリビューションの告知の修正版と照合する。Fragnesia と CVE-2026-98432 の両方を見る
- PAN-OS を使っているなら、管理インターフェースをインターネットに公開しない
- Fedora を使っているなら、`rpm -q ca-certificates` で -2 以降が入っているかを確かめる
- GKE を使っているなら、ノードの更新に加えて、アプリのコンテナを、Go は新しい版でビルドし直し、Python は certifi を 2026.10.19 以降に上げる
- ESXi を使っているなら、Broadcom のアドバイザリの修正ビルドに上げ、パッチ前の期間の管理操作は、別の記録と突き合わせる

## 参考リンク

- [CISA: KEV のデータ（JSON）](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)
- [CISA: 2026年10月28日の KEV 追加のアラート](https://www.cisa.gov/news-events/alerts/2026/10/28/cisa-adds-two-known-exploited-vulnerabilities-catalog)
- [Fragnesia の修正コミット f84eca5](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=f84eca5817390257cef78013d0112481c503b4a3)
- [Dream Security: PHP2Shell と Fragnesia の連鎖](https://dreamgroup.com/blog/chained-php2shell-exploit-roots-25-servers)
- [Ubuntu: CVE-2026-46300](https://ubuntu.com/security/CVE-2026-46300)
- [Red Hat: RHSB-2026-003](https://access.redhat.com/security/vulnerabilities/RHSB-2026-003)
- [Anthropic: 脆弱性の発見に関するブログ](https://www.anthropic.com/research/discovering-vulnerabilities-with-claude)
- [Fedora 45 Final の判定会議の議事録（10月29日）](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-29/f45-final-go-no-go-meeting.2026-10-29-18.02.html)
- [Fedora 45 Final の GO の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)
- [GKE のセキュリティ速報](https://docs.cloud.google.com/kubernetes-engine/security-bulletins)
- [Mozilla Bugzilla #2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)
- [Broadcom: VMSA-2026-0006](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/38017)
- [CrowdStrike: 2026 Legal Threat Landscape Report](https://www.crowdstrike.com/en-us/blog/crowdstrike-2026-legal-threat-landscape-report/)

（2026/10/30 Linux・OSSトレンド）
