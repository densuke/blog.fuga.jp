---
title: "塞いだつもりの扉ほど、裏から開けられる（2026/9/28 Linux・OSSトレンド）"
date: 2026-09-28T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Citrix", "NetScaler", "GitHub Actions", "サプライチェーン攻撃", "XDC", "Vulkan", "Wayland", "Linuxカーネル", "Oracle", "PeopleSoft", "WAF"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「もう塞いだ」と思った場所ほど、攻撃者と時間は裏からこじ開けに来ます。動画タイトルの「閉じたはずの扉が開いていた」という言葉どおり、今日はパッチが出たあとも、無効化されたあとも、WAFで守ったつもりのあとも、なぜか扉が開いていた5つの出来事を追いかけます。

{{< youtube "Ijdz1B2-pyc" >}}

## 1. Citrix NetScaler のゼロデイ2件 — 夏の修正版も対象、修正より先に攻撃が来た

[The Hacker News は、フォレンジック調査の中でCitrix NetScalerの未パッチの欠陥2件が見つかったと報じました](https://thehackernews.com/2026/09/warning-two-unpatched-citrix-netscaler.html)。同記事によれば、当初Citrixはこの欠陥を確認も修正もしておらず、[一部の管理者は自分たちの組織でも機器をオフラインにしたとスレッドで語っています](https://thehackernews.com/2026/09/warning-two-unpatched-citrix-netscaler.html)。

その後、[Citrixは9月27日付のセキュリティ速報CTX697096で、CVE-2026-88771とCVE-2026-88772という2件のCVEを採番しました](https://support.citrix.com/external/article/CTX697096)。CVE-2026-88771は既定構成のまま追加機能なしで認証不要の任意コマンド実行につながる入力検証の不備、CVE-2026-88772はDTLS構成が有効な場合のメモリオーバーフローでRCEまたはサービス拒否に至るというもので、いずれもCVSS v4.0で9.5です。速報には「CVE-2026-88771とCVE-2026-88772を狙った、緩和策未適用のNetScaler環境への悪用が確認されている」との記述があり、[Citrix自身が悪用を確認しています](https://support.citrix.com/external/article/CTX697096)。修正版は14.1-73.37以降・13.1-64.23以降で、[夏に出た修正版14.1-73.32/13.1-63.21もこれより前のビルドとして影響を受けます](https://support.citrix.com/external/article/CTX697096)。つまり、今年の夏に一度パッチを当てて安心していた環境も、扉が開いていたことになります。

NetScalerでは、これが今年初めての穴ではありません。8月には、SAMLの処理でヒープをオーバーフローさせて隣接領域を書き換え、関数ポインタの書き換えを経由して認証前にコードを実行する手口を使うCVE-2026-8452が公開されており、[watchTowr Labsはこの攻撃チェーンの詳細と、Webシェルが置かれた事例を報告しています](https://labs.watchtowr.com/youre-back-in-the-room-citrix-netscaler-pre-auth-rce-cve-2026-8452/)（配置先は`/var/vpn/theme/x.php`）。同社は別の脆弱性(CVE-2026-8451)を取り上げた記事で、この種の欠陥がNetScalerに「エンデミック(風土病)のように」根付いていると評しています。[認証バイパスのCVE-2026-19490もCVSS v4.0で9.3という高い評価を受けています](https://www.rapid7.com/blog/post/etr-cve-2026-19490-critical-vulnerability-affecting-citrix-netscaler-adc-and-netscaler-gateway/)。

対応としてできることは地味です。修正版へのアップデートを進め、更新の前にログを保全して不審なファイルが置かれていないかを確かめる。詳しい手順はCTX697096を確認するのが確実です。VPNの入口になっている機器なので、侵害されれば社内への足場になりうるという一般的なリスクは、今回も変わりません。

## 2. 封印したはずのActionが9日間動いた — タグは書き換えられる

5月、GitHub Actionsの`actions-cool/issues-helper`と`actions-cool/maintain-one-comment`のすべてのタグが、なりすましコミットを指す状態に書き換えられました。[StepSecurityの調査では、issues-helperの53個のタグが約3分16秒、maintain-one-commentの15個のタグは39秒以内という短時間で書き換えられたことが確認されています](https://www.stepsecurity.io/blog/actions-cool-issues-helper-github-action-compromised-all-tags-point-to-imposter-commit-that-exfiltrates-ci-cd-credentials)。

一度無効化されたはずのこの2つのActionは、[Socketの記事によれば9月16日に再び使える状態になり、9月25日に再度無効化されるまでの9日間、悪性のペイロードが動き続けました](https://socket.dev/blog/mini-shai-hulud-actions)。誰が、なぜ再有効化したのかについて、Socketは「特定できていない。正規のメンテナからの申請という可能性もあるが確認できていない」と明記しており、この記事では主体を断定しません。この間、[SafeDepは、6つのリポジトリが9月20日から24日にかけてフックファイルを受け取ったと報告しています](https://safedep.io/mini-shai-hulud-reinfection-github-repositories/)（`jd-opensource/micro-app`・`MaaXYZ/MaaFramework`・`ant-design/pro-components`などを含む）。

ペイロードの動きも生々しいものです。[StepSecurityによれば、まずBunランタイムをランナーにダウンロードし、sudoでpython3を起動してRunner.Workerプロセスのメモリを直接読み取り、シークレットを示す値を抜き出してC2サーバーへ送っていました](https://www.stepsecurity.io/blog/actions-cool-issues-helper-github-action-compromised-all-tags-point-to-imposter-commit-that-exfiltrates-ci-cd-credentials)（読み取り先は`/proc/<PID>/mem`、抽出条件は`"isSecret":true`、送信先は`t.m-kosche.com`）。[BleepingComputerによれば、GitHubの依存関係グラフ上でissues-helperに依存しているリポジトリは約1万5000あり、これはすべてが侵害されたことを意味するわけではありません](https://www.bleepingcomputer.com/news/security/github-actions-re-enabled-with-mini-shai-hulud-payload-still-active/)。

[Socketは、5月18日より前の完全なコミットSHAでこの2つのActionをピン留めしていたワークフローは影響を受けないとし、9月16日以降にタグ参照でこれらのActionを実行したワークフローについては、アクセスできたシークレットをすべてローテーションするよう勧めています](https://socket.dev/blog/mini-shai-hulud-actions)。無効化されたActionを「もう終わった話」として扱わず、タグではなくSHAで固定する運用に切り替えることが、この件の一番地味で確実な教訓です。

## 3. XDC 2026開幕 — Vulkanにも Gallium を、はまだ問いかけの段階

セキュリティの話が続いたところで、少し空気を変えます。[X.Org Developers Conference 2026は、9月28日から30日までカナダ・トロントのDaniels Spectrum(585 Dundas Street East)で開催されます。参加費は無料で、事前登録が推奨されています](https://www.collabora.com/news-and-blog/news-and-events/panfrost-kraid-tyr-and-more-at-xdc-2026.html)。

初日の目玉はFaith Ekstrand氏によるセッションで、[Indicoに登録された正式な題は「Is it time for Vulkan Gallium?」、つまり「Vulkan版のGalliumを作る時が来たのか」という問いかけです](https://indico.freedesktop.org/event/12/)。要旨には「2026年、Vulkan 1.4と数百本の拡張がある今、話はそう単純ではない。誰かが解決しなければならない遺産のようなコードや、複数バージョンで重複するenum、あちこちに重複するエントリポイントとクエリが残っている」とあり、まだ答えの出ていない議論として位置づけられています。

同じくIndicoに登録されている題として、[Intel所属のNaveen Kumar氏が9月30日のライトニングトークで発表する「Introducing the Wayland Content Frame Rate Protocol」があります](https://indico.freedesktop.org/event/12/)。こちらもまだ提案段階のプロトコルで、コンポジターとアプリケーションの双方が対応してはじめて効果が出るものです。もう一つ、[Karol Herbst氏の講演「nocl: OpenCL on CUDA」は、rusticl向けにCUDA上でOpenCLを実装するGalliumドライバとして紹介されています](https://indico.freedesktop.org/event/12/)。

Rustで書かれたGPUカーネルドライバの話も出てきます。[Deborah Brouwer氏による「Upstreaming Tyr: a DRM GPU kernel driver in Rust」は、Collabora・Arm・Googleの共同作業として進められているTyrドライバのアップストリーム化を報告するセッションです](https://rust-for-linux.com/tyr-gpu-driver)。同じCollaboraのブログでは、Lorenzo Rossi氏とFaith Ekstrand氏によるPanfrost向けの新コンパイラ「Kraid」の紹介もあります。トピック1・2が「塞いだはずの扉」だったのに対し、XDCは「そもそも扉の作り方を見直そう」という議論の場です。

## 4. カーネルCVE4件 — 2011年から潜んでいた競合が、いま可視化された

[NVDによれば、bnxt_enドライバとRDSプロトコルに関する4件のCVE(CVE-2026-97570・97573・98069・98070)は、いずれもCVSS v3.1で8.1、公開日は2026年9月25日です](https://nvd.nist.gov/vuln/detail/CVE-2026-97570)。9月27日という日付が出回っていますが、これはNVD自体の公開日ではありません。

CVE-2026-97570はbnxt_enドライバのTPA(集約処理)に関する不具合で、[NVDの記述では検証済みのBroadcom 57608 NICで32のTPAが同時に有効になっている構成が影響対象とされています](https://nvd.nist.gov/vuln/detail/CVE-2026-97570)。CVE-2026-97573も同じドライバの不具合で、TPAを再有効化できない場合にグローバルリセットへフォールバックする修正が入っています。RDS側のCVE-2026-98069とCVE-2026-98070はいずれも、NVDの記述によれば「弱い順序付けを持つアーキテクチャでは、あるビットがクリアされているのを見ることと、実際にそのビットを持っていることは同じではない」という、いわゆるストアバッファリングに類する競合です。CVE-2026-98069は[Linux 2.6.37以降のバージョンが影響を受けるとされています](https://nvd.nist.gov/vuln/detail/CVE-2026-98069)。このリリースは2011年に出ており(複数の技術メディアの記録による)、10年以上前から潜んでいた競合が、ようやく修正されることになります。

件数そのものにも触れておきます。[LinuxCVETrackerの集計では、2026年はこれまでに7,178件のCVEが公開されており、2025年通年の5,681件を26%上回っています](https://linuxcvetracker.com/cve-statistics/2026/)。この件数増加について、[linuxiacは2026年7月の記事で、Greg Kroah-Hartman氏が「『我々は2位だ』と話していたトークの内容を変えなければならない、もうそれは事実ではないから」と述べたと報じています](https://linuxiac.com/linux-tops-2026-cve-charts/)。件数が増えているのは事実ですが、それが直ちに「セキュリティが悪化した」ことを意味するとは、今回確認できた一次資料からは言えません。

[Ubuntuのセキュリティページでは、2026年9月28日時点でこれら4件のCVEの優先度はMedium、主要なリリースは「Needs evaluation(評価待ち)」のままです](https://ubuntu.com/security/CVE-2026-97570)。悪用が確認されているという情報は今のところありません。ディストリビューションのカーネル更新を待って適用するのが、現時点でできる対応です。

## 5. `%50`の1文字でWAFをすり抜けたPeopleSoft攻撃

セキュリティ話に戻って、今日の最後は「パッチが出たのに、また開いた」という話です。Oracle PeopleSoftのCVE-2026-35273はCVSS v3.1で9.8という高い評価を受けている脆弱性で、Oracleは2026年6月10日に定例外のセキュリティアラートを公開したと報じられています。

[Google Cloud傘下のMandiantは、攻撃グループShinyHunters(Mandiant内部の呼称はUNC6240)が2026年5月27日から6月9日にかけてこの欠陥をゼロデイとして悪用していたと報告しています](https://cloud.google.com/blog/topics/threat-intelligence/shinyhunters-renewed-mass-exploitation-campaign-targeting-oracle-peoplesoft)。パッチが出たあとも話は終わりませんでした。[Mandiantによれば、9月に入って攻撃者はURLエンコードしたパスでこの脆弱性のあるサーブレットへ到達する手口を確立しました。多くのWAFやリバースプロキシはデコード前の文字列でパスを照合する一方、PeopleSoft側はデコードしたあとにこのサーブレットへリクエストを回してしまうため、WAFの目をすり抜けてしまいます](https://cloud.google.com/blog/topics/threat-intelligence/shinyhunters-renewed-mass-exploitation-campaign-targeting-oracle-peoplesoft)（該当パスは`/%50SEMHUB/`。`%50`はアルファベットの「P」をURLエンコードした表記）。

[Mandiantは、侵害されたインスタンス全体で見ると、攻撃者が実行したコマンドの4分の1がrootまたはNT Authority\SYSTEM権限で実行されていたと報告しています](https://cloud.google.com/blog/topics/threat-intelligence/shinyhunters-renewed-mass-exploitation-campaign-targeting-oracle-peoplesoft)。これは侵害された組織の割合ではなく、実行されたコマンドの割合です。攻撃では`x.jsp`(コマンド実行用のWebシェル)・`u.jsp`(ファイルアップロードと実行のためのステージャー)・`tunnel.jsp`(SOCKS5トンネル)といった[Webシェルが、世界の数十のシステムに配置されました。対象は高等教育・テクノロジー・ITサービス・医療・農業・運輸・政府など複数の分野にわたります](https://cloud.google.com/blog/topics/threat-intelligence/shinyhunters-renewed-mass-exploitation-campaign-targeting-oracle-peoplesoft)。また、VMProtect 3で保護された多段階の実行チェーンを持つバックドア「SIDEEYE」(`Ple64.exe`)や、正規のリモート管理ツールMeshAgentの悪用、Microsoftのサービスに似せたドメイン(`azurenetfiles.net`・`microsoft-entra.net`)の使用も確認されています。

Mandiantは今回のキャンペーンについて、[「WAFのルールとパスの遮断は、パッチ適用の代わりにはならない」と明言しています。実際、パッチを適用せずにWAFルールだけで対応していた組織が今回の標的になっていたことも報告されています](https://cloud.google.com/blog/topics/threat-intelligence/shinyhunters-renewed-mass-exploitation-campaign-targeting-oracle-peoplesoft)。推奨される対処は、WAFのルールをデコード後の正規化されたパスに対して適用すること、WebLogicのアクセスログで`/PSEMHUB/`のエンコードされた変種を検索すること、そして`psappsrv.cfg`のデータベース接続文字列やIntegration Broker、Web層からアクセスできるクラウド認証情報をローテーションすることです。

## まとめ

今日の5本は、それぞれ違う形の「開いていた扉」でした。NetScalerは夏に塞いだはずの扉が新しいゼロデイで再び開き、GitHub Actionsは無効化した扉が9日間開いたままでした。PeopleSoftはパッチという扉自体は塞いだのに、WAFという別の扉の1文字の隙間から入られました。カーネルのRDSの競合は、2011年からずっと開いていたことに、いま気づいたという話です。XDCだけは毛色が違い、扉をどう作るかという議論そのものを見直そうとしている場でした。

タグ参照で固定していないか、WAFのルールに頼りきりになっていないか、機器の版数が最新かどうか。こうした点検と、そもそもの作り方を見直す議論の両方がそろって、ようやく扉は本当に閉じるのだと思います。

## 参考リンク

- [Citrix セキュリティ速報 CTX697096](https://support.citrix.com/external/article/CTX697096)
- [Socket — Mini Shai-Hulud actions の再稼働](https://socket.dev/blog/mini-shai-hulud-actions)
- [StepSecurity — actions-cool/issues-helper 侵害の調査](https://www.stepsecurity.io/blog/actions-cool-issues-helper-github-action-compromised-all-tags-point-to-imposter-commit-that-exfiltrates-ci-cd-credentials)
- [X.Org Developers Conference 2026（Indico）](https://indico.freedesktop.org/event/12/)
- [NVD — CVE-2026-97570](https://nvd.nist.gov/vuln/detail/CVE-2026-97570)
- [Google Cloud（Mandiant） — ShinyHunters による Oracle PeopleSoft 攻撃キャンペーン](https://cloud.google.com/blog/topics/threat-intelligence/shinyhunters-renewed-mass-exploitation-campaign-targeting-oracle-peoplesoft)
