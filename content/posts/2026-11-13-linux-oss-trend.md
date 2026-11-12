---
title: "N-central の HF2 は7件の CVE を修正（N-able の CVSSv4 で最大 9.3）、追加公開の2件は Legacy API が有効なら HF2 でも動くと研究者が主張、AMD の GC 13.x パッチ8本は12,643行追加、FreeBSD の開発者調査は回答140人のうち88%が方針を求める、RHSA-2026:98047 は RHEL 9.4 向けカーネル22件、Microsoft は GSocket の検出端末が3月基準で356.2%増と報告（2026/11/13 Linux・OSSトレンド）"
date: 2026-11-13T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "N-able", "N-central", "AMD", "RDNA 5", "Linux カーネル", "FreeBSD", "AI", "Red Hat", "RHEL", "Open vSwitch", "Microsoft", "GSocket"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

2026年11月13日（金）の動画のテーマは、修正版や点数が出たあとに、自分の環境で何を確かめるか、でした。修正版が出る、点数が付く、注意が呼びかけられる。どれも区切りに見えますが、手元で確かめる作業はそこから始まります。

N-able の N-central は、33件の脆弱性の公開を受けてホスト型を止め、修正版 HF2 で、リリースノートが挙げる7件の CVE を修正しました。その後に追加で公開された実証コード2件は HF2 の対象外とされ、研究者は Legacy API が有効な構成なら HF2 でも動くと述べています。AMD は、次世代 GPU 向けとみられるドライバのパッチを8本投稿しました。FreeBSD の状況報告には、開発者140人への AI 利用の調査結果が載りました。Red Hat は、RHEL 9.4 向けのカーネル更新で22件を直し、別の Open vSwitch の CVE には、登録元と Red Hat で9.8と7.0の採点が並びました。Microsoft は、Linux サーバに置かれる GSocket について、脆弱性を直しても残る仕掛けを調査記事にまとめました。

この5本を「修正や採点のあとの確認」という見方で並べたのは書き手で、取り上げた各社やプロジェクトがそう述べているわけではありません。動画の訂正は、1・3・5の節の末尾に置きました。内容は2026年11月13日の朝（日本時間）に確認したものです。時刻は、N-able の状況と N-central の CVE の NVD が6:57〜7:15、Red Hat のページと CVE-2026-68123 の NVD が7:02ごろ、kernel.org の現行版と amd-gfx のメーリングリストが6:50〜7:35、Microsoft のブログが6:40〜7:00です。N-central の追加公開と侵害の報告は、7:38〜7:45に確かめ直しました。時点で変わる値には、本文でも時刻を添えました。

{{< youtube "8xyJ7hNOh9I" >}}

## 1. N-able N-central — 33件の公開、ホスト型の停止、HF2 の7件

N-central は、管理代行の事業者（MSP）や IT 部門が使う、遠隔監視と管理（RMM）のプラットフォームです（[Huntress](https://www.huntress.com/blog/n-able-disables-cloud-services-following-disclosure-of-able2shell-exploit-chains) の説明）。管理先の端末を操作できる仕組みなので、サーバが侵害されれば、管理先に影響が及びうる、というのが一般的な構造です。

GitHub 上のアカウントで活動する研究者が、「Able2Shell」と題して33件を、Python の PoC つきで公開しました。[Tenable](https://www.tenable.com/blog/able2shell-frequently-asked-questions-for-reported-n-able-n-central-zero-day-vulnerabilities) によると、README の最初のコミットは2026年11月9日 04:14（UTC）で、日本時間では11月9日（月）の13:14です。33件は研究者が挙げた件数で、Tenable は「主張されている（alleged）」と表現しています。N-able は、自社の CVE と33件の対応を示していません。N-able は研究者の名前を出しておらず、この記事でも実名は出しません。

N-able は、11月9日（UTC）に、ホスト型の N-central をオフラインにしました（[Huntress](https://www.huntress.com/blog/n-able-disables-cloud-services-following-disclosure-of-able2shell-exploit-chains)）。N-able の公式ステータスのページは本文を取得できなかったため、停止の日付は Huntress の記述によります。

修正版の HF2 は、[N-able のリリースノート](https://status.n-able.com/2026/11/10/n-central-2026-4-hf2-release-notes/)の表記で11月10日の公開です。ビルドは 2026.4.1.26、投稿の時刻は UTC で11月10日 20:48、日本時間では11月11日（水）の朝5:48です。リリースノートが挙げる7件は、次のとおりです。

| CVE | リリースノートの題 | CVSSv4（採点者） |
|---|---|---|
| [CVE-2026-125883](https://nvd.nist.gov/vuln/detail/CVE-2026-125883) | 複数の XXE の脆弱性 | 9.3（N-able の CNA） |
| [CVE-2026-125881](https://nvd.nist.gov/vuln/detail/CVE-2026-125881) | サービスインポートのスキーマ検証を介した SSRF | 9.3（N-able の CNA） |
| [CVE-2026-125878](https://nvd.nist.gov/vuln/detail/CVE-2026-125878) | 複数の OGNL インジェクション | 8.7（N-able の CNA） |
| [CVE-2026-125879](https://nvd.nist.gov/vuln/detail/CVE-2026-125879) | syslog-ng の設定を介した root へのローカル権限昇格 | 8.6（N-able の CNA） |
| [CVE-2026-125882](https://nvd.nist.gov/vuln/detail/CVE-2026-125882) | ファイルリポジトリへのアップロードのパストラバーサルによる RCE | 8.6（N-able の CNA） |
| [CVE-2026-91000](https://nvd.nist.gov/vuln/detail/CVE-2026-91000) | 安全でない IPC チャネルによるローカル権限昇格 | 8.4（N-able の CNA） |
| [CVE-2026-125880](https://nvd.nist.gov/vuln/detail/CVE-2026-125880) | MMS3 のパッチのメタデータを介した格納型 XSS（管理者の文脈） | 8.3（N-able の CNA） |

7件とも、NVD の状態は分析前の Received で、NVD 自身の採点はありません。表の値は、NVD が Secondary として載せている N-able（CNA）の採点です。最大の9.3は、CVE-2026-125883 と CVE-2026-125881 の2件です。8月7日の記事で扱った [N-central の CVE-2026-18577](https://blog.fuga.jp/posts/2026-08-07-linux-oss-trend/) とは、別の脆弱性です。

[N-able の公式ブログ](https://www.n-able.com/blog/update-on-n-central-2026-4-hf2-and-ongoing-security-response)（11月11日のページ）は、「ログインなしで突ける問題は、すべて対処した」と書いています。残りは、ログイン済みのアカウント（しばしば高い権限）や、追加の条件が要る問題で、後続の修正版で対処する予定です。ホスト型は N-able がアップグレードして、復旧しています。エージェントとプローブは、ホスト型でもオンプレミスでも、利用者が更新します。リリースノートによると、順序はエージェントが先、プローブが後です。プローブだけを先に上げると、エージェントと通信できません。オンプレミスは、更新が済むまで、サーバをインターネットから遮断するよう案内されています。

同じブログは、PoC に関連するスキャン活動を観測する一方、ホスト型サーバに侵害の兆候は見ていないと書いています。この説明はホスト型サーバに限り、個々の顧客環境については、環境ごとの評価が要る、とも書いています。

[Previdian](https://blog.previdian.com/n-able-n-central-critical-vulnerabilities-what-we-know-so-far/) のおとり環境では、1つの IP アドレスから68件の記録がありました。最初の活動は、11月9日 22:08（UTC）ごろ、日本時間では11月10日の朝7時すぎで、README の公開から約18時間です。要求は一様ではなく、空のパラメータなどの探りと、外部エンティティの処理や機密ファイルへのアクセスの試みが混ざっています。Previdian は、68件を公開 PoC の68回の実行と表現すべきではなく、コマンド実行の成功も確認されていない、と書いています。確認の観点として、Huntress と Previdian は、見覚えのない管理者アカウントや、見知らぬ JSP ファイルを挙げます。Previdian は、これらを PoC から導いた確認で、おとり環境で観測した結果ではない、と断っています。

公開後に状況が動いています。以下は、11月13日 7:38〜7:45 の確認です。

[Huntress](https://www.huntress.com/blog/n-able-disables-cloud-services-following-disclosure-of-able2shell-exploit-chains) によると、同じ研究者は、米国東部時間の11月11日夜（UTC と日本時間では11月12日）に、実証コードを2件追加で公開しました。正確な公開時刻は取得できていません。研究者は、2件とも HF2（ビルド 2026.4.1.26）を当てたサーバに対して動作すると述べています。Huntress は、11月12日 6:30（米国東部時間。日本時間では11月12日の20:30）の更新で、研究者がリポジトリで、Legacy API を有効にした構成でのみ動くと確認した、と伝えています。2件のうち、Windows のエージェントやプローブとの通信に関わるほうが Legacy API に依存するかは、Huntress は確認できていないとしています。

[The Hacker News](https://thehackernews.com/2026/11/new-n-central-exploits-work-against.html)（THN）が引用する N-able の勧告は、サーバの問題が、Legacy API を有効にしてインターネットに公開している、既定ではない構成に依存すると説明し、Legacy API は既定で無効だと書いています。THN の要約では、N-able は、Legacy API をすぐに無効にするよう呼びかけ、ホスト型はこの問題の影響を受けないとしています。Huntress の要約では、N-able は N-central をオフラインにするよう勧めてはいません。

入口には、Apache Axis 1.x の [CVE-2026-90436](https://nvd.nist.gov/vuln/detail/CVE-2026-90436) が使われるとされます（BleepingComputer と、Previdian の話を伝える THN の記述）。NVD の状態は分析前の Awaiting Analysis で、NVD 自身の採点はありません。CNA の Apache は、数値の採点を付けていません。NVD に Secondary として載る9.8は、CISA-ADP の CVSS v3.1 の採点です。Apache の Axis のプロジェクトは、Axis 1.x の修正版を出す見込みはないとしています。

THN によると、Previdian は、実証コードの公開から数時間のうちに、N-central を狙った探りを観測しました。成功した悪用の証拠は、執筆時点で無いとしています。探りは要求の観測で、侵害の確認ではありません。

BleepingComputer は、ある調査会社の報告として、11月12日 12:50（UTC。日本時間では21:50）の時点で、マイナー（暗号資産の採掘プログラム）を動かしている N-central のサーバが少なくとも21台あり、うち19台が HF2 の版（2026.4.1.26）だったと伝えています。採掘プールの統計から数えた件数で、露出しているサーバ全体の数ではありません。報告した会社自身の文書は、確認できていません。同じ記事は、N-able が新しい問題による侵害の兆候は無いと述べた、とも書いています。Huntress は、11月12日 6:30（米国東部時間）の更新の時点で、自社の顧客の環境では悪用を観測していないと書いています。

N-able は、11月12日（米国時間）に、オンプレミスの N-central 2026.4.1 HF2 についての新たな公開を調べていると表明しました（THN）。BleepingComputer によると、N-able は、修正を進める間、N-central の一部の機能と連携を制限しており、予防措置として Intune との連携を無効にしたとされます。Intune の件は BleepingComputer の要約で、N-able の原文やほかの報道では確かめられていません。N-able の勧告の原文、インシデントのページ、Legacy API の無効化を案内する KB 記事は、いずれも本文を取得できず、確認できていません。

追加公開の2件に対する修正版は、11月13日 7:45 までの確認では、N-able のリリースノートの一覧に載っていません。11月11日の公式ブログは、この追加公開に触れていません。書き手の考察ですが、増やされたアカウントや置かれたファイルは、アップグレードだけでは消えません。

動画の訂正です。

- 動画では、研究者が「11月8日の深夜」に33件を公開したと紹介しました。11月8日の深夜は米国東部時間です。README の最初のコミットは、11月9日 04:14（UTC）で、日本時間では11月9日（月）の午後です（[Tenable](https://www.tenable.com/blog/able2shell-frequently-asked-questions-for-reported-n-able-n-central-zero-day-vulnerabilities)）。
- 動画では、公開から「数日」で、おとり環境に探りが入ったと紹介しました。最初の活動は、11月9日 22:08（UTC）ごろで、公開から約18時間です（[Previdian](https://blog.previdian.com/n-able-n-central-critical-vulnerabilities-what-we-know-so-far/)）。
- 動画では、観測された試行は「機密ファイルの読み出しが中心」と紹介しました。Previdian は、探りの要求と、外部エンティティの処理や機密ファイルへのアクセスの試みが混ざっていると書き、「中心」とは書いていません。コマンド実行の成功は確認されていません。

## 2. AMD の GC 13.x（GFX13）— amd-gfx に初期パッチ8本、12,643行

Alex Deucher 氏（AMDGPU のメンテナの一人）は、2026年11月9日 18:46（UTC）、日本時間では11月10日（火）3:46に、amd-gfx のメーリングリストへ[「[PATCH 0/8] GC 13.x support」](https://lists.freedesktop.org/archives/amd-gfx/2026-November/156995.html)を投稿しました。カバーレターは、"This series adds initial support for GC 13.x." と書いています。diffstat は、32ファイル、12,643行の追加、15行の削除です。この数字は、この8本だけのものです。

大きなファイルは、次の3つです。

- `gfx_v13_0.c`: 5,808行。描画と計算（GC = Graphics and Compute）を担うブロックの本体です
- `mes_v13_0.c`: 1,862行。MES（MicroEngine Scheduler）のコードです
- CWSR のトラップハンドラ（.asm）: 1,181行。計算の途中経過を退避して戻す仕組みで、GPU 向けのアセンブリで書かれています

追加した行の約95%は、新しく作られたファイルの分です。書き手の考察ですが、既存のコードを大きく書き換える変更ではなく、新しい世代の分を足す変更に見えます。

パッチの本文に、RDNA や UDNA の語はありません。RDNA 5 との結び付けは、[WccfTech](https://wccftech.com/amd-rdna-5-gpu-support-arrives-in-linux-with-over-12600-lines-of-gfx13-driver-code/) の報道の見立てで、同じ記事は、AMD が RDNA 5 として売ると公式に確認したわけではない、と書いています。製品名や発売日の AMD の発表は、確認できていません。

この8本は、GC 13.x の最初の投稿ではありません。同じ Deucher 氏が、11月6日（UTC）に、[GMC 13.x](https://lists.freedesktop.org/archives/amd-gfx/2026-November/156904.html) や [SDMA v8.x](https://lists.freedesktop.org/archives/amd-gfx/2026-November/156911.html) などの別のシリーズを、先に投稿しています。12,643行は、GC 13.x のコードの全体ではありません。

メインラインへの取り込みは、確認できていません。torvalds/linux の master（最新のコミットは、11月12日 20:26（UTC）、日本時間では11月13日の5:26）に、`gfx_v13_0.c` はありません。amd-staging-drm-next など、メンテナのツリーへの取り込みは、取得できず確認できていません。Linux 7.5 に入る可能性は、WccfTech が、Phoronix の報道として伝えています（Phoronix の原文は未確認）。確定はしていません。

7.5 の時期は、[kernel.org](https://www.kernel.org/releases.json) の周期からの、書き手の計算です。7.0（4月12日）から7.3（10月18日）までは、63日ごとでした。現行の 7.4-rc2 は11月9日（日本時間）で、同じ周期なら、7.4 の公開は12月20日、rc8 までなら12月27日です。[マージウィンドウ](https://docs.kernel.org/process/2.Process.html)は約2週間で、7.5 のものは、2026年12月下旬から2027年1月上旬になります。7.5 の公開は、2027年2月下旬から3月上旬の見込みです。製品の発売時期は、AMD の発表が見つからなかったため、書きません。

新しいカードを買ったあとは、カーネルの版とファームウェアの更新を確かめます。GFX13 の製品は未発売で、発売後の話です。GPU のファームウェアは、多くのディストリビューションで linux-firmware として配られますが、名前や分け方は違います。Arch は、amdgpu 用に別のパッケージを持っています。

動画の訂正はありません。

## 3. FreeBSD Q3 2026 状況報告 — 開発者140人への AI 利用の調査

[FreeBSD の2026年第3四半期の状況報告](https://www.freebsd.org/status/report-2026-07-2026-09/)の Core Team の項に、AI と LLM の利用についての開発者調査が載っています。bapt@ が調査を作り、結果を core@ に報告して、要約が開発者に共有されました。140人が回答しています。実施期間、招待した人数、回答率は、報告書にありません。以下の割合は、回答した140人の中のものです。

- 方針: 88%が、プロジェクトが方針を設けることを望みました。内訳は、成文の方針が49%、軽いガイダンスとベストプラクティスが39%です。AI は明示的に避けるべきが6%、既存の貢献のルールで足りるが3%でした
- 開示: 84%が、AI の利用の開示を望みました。常にが48%、関与が大きいときが36%です
- AI 支援のコード: 開示が必要が35%、人間のコードより厳しいレビューが必要が25%、ほかの貢献と同じ扱いが22%、拒否が16%です

88%は「方針が要る」という回答の割合で、AI への賛否の割合ではありません。開示とレビュー強化を合わせると60%ですが、これは書き手の足し算で、報告書が束ねた数字ではありません。

imp@（報告書の別の項に、Warner Losh 氏の連絡先とあります）は、多様な意見の人を集めた AI 作業部会を作りました。調査の結果を、AI と LLM の利用の方針への入力にします。報告書は、初会合を10月7日に開くと書いています。これは執筆時点の予定で、開催の記録は確認できていません。最終報告は第4四半期の見込みで、11月13日の時点で出たかは、確認できていません。

2025年第2四半期の[状況報告](https://www.freebsd.org/status/report-2025-04-2025-06/)で、Core Team は、LLM と AI の方針を検討中と書き、現時点では、ライセンス上の懸念から、コードの生成には使わない傾向がある（"We currently tend to not use it to generate code because of license concerns."）と書いていました。方針づくりは、今回の報告より前から続いており、今回新しいのは、調査の結果と作業部会の報告です。

報告書の別の項、NFS over RDMA に、AI が関わる事例があります。RDMA 対応の NIC にネットワーク転送の多くを任せ、高速な LAN での性能を上げる取り組みです。サーバ側のコードは生成 AI で作られました。報告書によると、FreeBSD プロジェクトは生成 AI による提出物の扱いの方針を作成中で、それまでの間、サーバ側のコードは、カーネルのロード可能モジュールをビルドする「非公式のポート」として提供される予定です。クライアント側は、数週間のうちに main へコミットされる予定で、stable/15 への MFC は2026年末の見込みです。

FreeBSD の AI の方針は、このブログでは初出です。7月30日の記事は、FreeBSD の別の回（Q2）の状況報告でした。書き手の考察ですが、[7月31日の記事](https://blog.fuga.jp/posts/2026-07-31-linux-oss-trend/)の GCC や Debian、[9月14日の記事](https://blog.fuga.jp/posts/2026-09-14-linux-oss-trend/)の Void Linux のように、他のプロジェクトでも方針をめぐる動きがあります。FreeBSD は、方針を決める前の、調査と作業部会の段階です。

動画の訂正です。

- 動画では、NFS over RDMA について、「採用していいかを判断するルールがまだ無いので、非公式の移植版として配る形」と紹介しました。報告書は、方針を作成中で、それまでの間は「非公式のポート」（"unofficial port"）として提供する予定、と書いています。「非公式のポート」は、カーネルのロード可能モジュールをビルドするもので、他の環境から移植した版ではありません。「判断するルールが無いので」という因果は書かれておらず、すでに配布しているとも書かれていません。生成 AI で作られたのは、サーバ側のコードです（[FreeBSD 状況報告](https://www.freebsd.org/status/report-2026-07-2026-09/)）。

## 4. Red Hat RHSA-2026:98047 — RHEL 9.4 向けカーネル22件と、9.8と7.0の乖離

[RHSA-2026:98047](https://access.redhat.com/errata/RHSA-2026:98047) は、2026年11月11日に出た、Red Hat の重大度が Important のカーネルの更新です。対象の製品は、RHEL 9.4 の Update Services for SAP Solutions、AUS、ARM 64 と IBM Z の "4 years of updates"、Extended Life Cycle です。RHEL 9.4 の長期サポート系、と書くのは書き手の要約で、Red Hat の語ではありません。修正する CVE は22件で、Red Hat の重大度は、Important が16件、Moderate が6件です。修正後のカーネルは 5.14.0-427.162.1.el9_4 で、適用には再起動が要ります。適用の手順は、Red Hat の[記事](https://access.redhat.com/articles/11258)にあります。Red Hat は、カーネルのエラータをすべてセキュリティに関係するものとして扱うよう勧め、更新を遅らせないよう強く求めています。

22件の1つ、[CVE-2026-52912](https://access.redhat.com/security/cve/CVE-2026-52912) は、netfilter の nf_queue で、キューに入ったブリッジのパケットが、解放済みのブリッジを保持したまま再投入され、解放済みメモリの使用（use-after-free）が起きるものです。Red Hat と CNA の kernel.org が、ともに CVSS v3.1 で 7.8 としています。

次の2件は、22件には含まれません。

- [CVE-2026-68398](https://access.redhat.com/security/cve/CVE-2026-68398)（PPP over L2TP）: Red Hat と CNA の kernel.org が、ともに CVSS v3.1 で 7.8 です。権限のないローカルのユーザーが、カーネルのメモリを壊して、ローカルの権限昇格やシステムの停止に至るおそれがあります。ネットワーク越しの認証なしの悪用はできない、と Red Hat は書いています。PPP over L2TP が不要なら、pppol2tp のモジュールを読み込まない回避策があります。手順とサービスへの影響は、Red Hat のページを見てください
- [CVE-2026-68123](https://access.redhat.com/security/cve/CVE-2026-68123)（Open vSwitch）: CNA の kernel.org が CVSS v3.1 で 9.8（ネットワーク越し・認証なし）、Red Hat が CVSS v3.1 で 7.0 です。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-68123) には、kernel.org の9.8が Secondary として載り、NVD 自身の採点はありません（状態は Received）。Red Hat は、確かめた攻撃経路がローカルで、攻撃条件が難しいと見ています。どちらも、Open vSwitch の特定のフロー設定が前提です。11月3日の記事の [CVE-2026-64531](https://blog.fuga.jp/posts/2026-11-03-linux-oss-trend/) とは別件です

CVSS v3.1 の区分は、[FIRST の仕様書](https://www.first.org/cvss/v3.1/specification-document)で、7.0〜8.9が High、9.0〜10.0が Critical です。Red Hat の Important は、Red Hat 自身の重大度の区分で、CVSS v3.1 の区分とは別の尺度です。自分の環境が、どちらの評価の条件に近いかは、Open vSwitch の使い方によって変わります。これは書き手の考察です。

CVE-2026-68123 について、Red Hat の Statement は、修正を進めている（"A fix is being pursued"）としています。回避策は、ない、または Red Hat の基準を満たさない、との記載です。一方、Red Hat の CVE ページ（11月13日 7:02ごろ）には、RHEL 8（[RHSA-2026:98099](https://access.redhat.com/errata/RHSA-2026:98099)、11月11日）、RHEL 9（[RHSA-2026:81552](https://access.redhat.com/errata/RHSA-2026:81552)、10月13日）、RHEL 10（[RHSA-2026:98608](https://access.redhat.com/errata/RHSA-2026:98608)、11月11日）の修正済みのエラータが載っています。RHEL 9.4 の長期サポート系の行は載っておらず、そこでの修正の有無は、確認できていません。

悪用の状況は、限られた根拠で書きます。3件とも、CISA の KEV（11月10日付の版）には載っていません。NVD に載る CISA の SSVC（10月16日時点）は、Exploitation が none です。悪用がないと断言できる根拠ではありません。

動画の訂正はありません。

## 5. Microsoft の GSocket の調査 — 脆弱性を直しても残る仕掛け

Microsoft は、[Security Blog](https://www.microsoft.com/en-us/security/blog/2026/11/11/global-socket-how-threat-actors-weaponizing-gsocket-stealthy-c2/) で、侵害した Linux サーバに GSocket が置かれた複数のインシデントを報告しました。公開は11月11日（米国時間）で、日本時間では11月12日（木）の4:49です。GSocket は、[hackerschoice/gsocket](https://github.com/hackerschoice/gsocket)（BSD-2-Clause のライセンス）の OSS で、NAT やファイアウォールの内側の2者を TCP でつなぎます。接続は、公開の中継網（Global Socket Relay Network）を通ります。

数字は、Microsoft Defender for Endpoint のテレメトリに基づいています。

- GSocket に関連する検出のあった端末は、3月を基準に、8月までで356.2%増えました。月ごとの伸びは一定ではなく、台数は示されていません
- 影響を受けた組織の割合は、教育・研究が30.7%、技術・通信が22.9%です。Microsoft は、これらの業種を狙ったわけではなく、露出の差のほうが要因として考えられる、と書いています。大学などは、中央の IT の外で運用される Web 資産が多く、棚卸しやパッチ適用が難しい、という説明です
- 原因が特定できたインシデントの87.1%が、Web アプリとホスティングでした。その中で、PHP アプリと cPanel が63.9%、Apache が24.3%です

分析した RCE 型の侵入では、公開された Web アプリが突破されています。リモートアクセスのサービスやクラウドのシェル経由の場合にも、Microsoft は触れています。どの脆弱性が使われたかは、挙げていません。

接続は外向きだけです。侵害したホストも操作する側も、中継網へ外向きに接続するため、待ち受けや公開 IP アドレスは要らず、入ってくる通信を見るファイアウォールには見えません。外向きの通信の制限と監視なら、この通信を捉えられる、と Microsoft は書いています。攻撃者専用の IP アドレスやドメインがないため、アドレスでの遮断は効きにくい一方、中継網への接続を絞ることはできます。

居座りの仕掛けも残ります。Microsoft は、GSocket が悪用されたアプリとは独立して動くため、脆弱性を直しても、中継のクライアントと居座りの仕掛けは消えない、と書いています。一部の侵入では、cron、systemd、シェルの起動ファイルなどが使われました。すべての侵入で確認されたわけではありません。プロセスをカーネルスレッドのような名前に見せかける例もあります。

ごく一部の侵入では、Web サービスのアカウントを得たあと、[CVE-2026-43284](https://nvd.nist.gov/vuln/detail/CVE-2026-43284)（Microsoft は Dirty Frag としても知られると書いています）で root への昇格が試みられました。Microsoft は、成功したとは書いていません。NVD に NVD 自身の採点はなく、CNA の kernel.org が CVSS v3.1 で 8.8、CISA-ADP と Red Hat が CVSS v3.1 で 7.8 です（いずれも Secondary）。10月27日の記事と同じく、NVD の説明文に Dirty Frag の名前はありません。

GSocket の悪用は、今回が初めてではありません。[Sansec](https://sansec.io/research/gsocket) は、2025年4月3日の記事で、通販サイト8万店を調べ、45店で動作中の GSocket の裏口を見つけた、と報告しています。9月8日・9日の記事で取り上げた Sansec の報告とは、別件です。

Microsoft の対策の項は、次のとおりです。

- cron、もっともらしい名前の systemd のユニット、シェルの起動ファイルを点検する。プロセスを止めただけでは、アクセスは消えない
- 一時領域やメモリ上の領域を、可能なら実行不可でマウントし、隠しパスや誰でも書けるパスからの実行を警告する
- 外向きの通信を既定で拒否し、必要な宛先だけを許可して、中継網への接続を監視する
- 公開された Web アプリを修正し、堅牢にする。アプリのパッチを、完了とみなさない

書き手の考察ですが、[9月8日の記事](https://blog.fuga.jp/posts/2026-09-08-linux-oss-trend/)の、パッチ適用済みと清潔であることは同じではない、という点と同じ構図です。

動画の訂正です。

- 動画では、「Microsoft は、メモリ上の一時領域に置かれた隠しディレクトリや、defunct という名前の不審なファイルの確認も勧めています」と紹介しました。Microsoft の対策の項に、その確認の項目はありません。これらは、Microsoft が観測した痕跡として挙げたものです。対策の項にあるのは、cron、systemd のユニット、シェルの起動ファイルの点検と、一時領域を実行不可にして隠しパスからの実行を警告することです（[Microsoft Security Blog](https://www.microsoft.com/en-us/security/blog/2026/11/11/global-socket-how-threat-actors-weaponizing-gsocket-stealthy-c2/)）。

## まとめ

N-central の HF2 は、リリースノートが挙げる7件を修正する版で、その後に追加公開された2件は対象外とされます（研究者の主張で、条件は Legacy API が有効なこと）。確認時点で N-able の原文を取得できておらず、追加公開への N-able の対応は、THN・BleepingComputer・Huntress の記述によります。AMD のパッチは、メインライン未取り込みで、7.5 は可能性にとどまります。FreeBSD の調査は、回答した140人の結果で、最終報告は第4四半期の見込みです。RHSA-2026:98047 は22件で、CVE-2026-68123 は、その外にあります。GSocket は、アプリのパッチだけでは片付きません。

手元で確かめておくものは次のとおりです。

- N-central: Legacy API の無効化。研究者の主張では、追加公開の2件は Legacy API が有効な構成なら HF2 を当てたサーバでも動くため、HF2 だけでは、この2件は防げない。無効化は、N-able の勧告として THN と Huntress が伝える対応で、N-able の原文は確認できていない。そのうえで HF2（ビルド 2026.4.1.26）を当て、エージェントを先、プローブを後に更新する。オンプレミスは、更新が済むまでインターネットから遮断する。見覚えのない管理者アカウントと、見知らぬ JSP ファイルを確かめる。2件に対する N-able の次の修正版を、リリースノートで確かめる
- AMD: 製品の発売後に、カーネルの版とファームウェアの更新を確かめる。7.5 への取り込みは、確定を待つ
- FreeBSD: 方針は、最終報告のあとに確かめる。NFS over RDMA のサーバ側は、方針が固まるまで「非公式のポート」として提供される予定であることを踏まえる
- RHEL: RHSA-2026:98047 を当て、再起動後に kernel-5.14.0-427.162.1.el9_4 を確かめる。CVE-2026-68123 は、自分の Open vSwitch のフロー設定と、使っている RHEL のストリームの修正状況を、Red Hat のページで確かめる。CVE-2026-68398 は、pppol2tp を使っているかを確かめる
- GSocket: Web アプリを直したあとに、Microsoft の対策の項に沿って、cron、systemd のユニット、シェルの起動ファイルを点検する。外向きの通信を、必要な宛先だけに絞る

## 参考リンク

- [N-able の公式ブログ（HF2 と対応の状況）](https://www.n-able.com/blog/update-on-n-central-2026-4-hf2-and-ongoing-security-response)
- [N-central 2026.4 HF2 のリリースノート](https://status.n-able.com/2026/11/10/n-central-2026-4-hf2-release-notes/)
- [Huntress の N-central の解説](https://www.huntress.com/blog/n-able-disables-cloud-services-following-disclosure-of-able2shell-exploit-chains)
- [The Hacker News（N-central の追加公開）](https://thehackernews.com/2026/11/new-n-central-exploits-work-against.html)
- [NVD の CVE-2026-90436](https://nvd.nist.gov/vuln/detail/CVE-2026-90436)
- [Tenable の Able2Shell の FAQ](https://www.tenable.com/blog/able2shell-frequently-asked-questions-for-reported-n-able-n-central-zero-day-vulnerabilities)
- [amd-gfx の「[PATCH 0/8] GC 13.x support」](https://lists.freedesktop.org/archives/amd-gfx/2026-November/156995.html)
- [FreeBSD の2026年第3四半期の状況報告](https://www.freebsd.org/status/report-2026-07-2026-09/)
- [RHSA-2026:98047](https://access.redhat.com/errata/RHSA-2026:98047)
- [Red Hat の CVE-2026-68123](https://access.redhat.com/security/cve/CVE-2026-68123)
- [Microsoft Security Blog（GSocket）](https://www.microsoft.com/en-us/security/blog/2026/11/11/global-socket-how-threat-actors-weaponizing-gsocket-stealthy-c2/)
- [Sansec の GSocket の調査](https://sansec.io/research/gsocket)

（2026/11/13 Linux・OSSトレンド）
