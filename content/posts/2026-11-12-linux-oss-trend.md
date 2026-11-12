---
title: "KEV に追加の6件は Barracuda の2件が期限11月13日・ほかは11月24日、Rust 1.100 は Cargo の cooldown と never 型が入る11月12日の予定、KDE Plasma 6.8.3 はマルチ GPU の修正、Intel マイクロコード 20261110 は機能修正のみの記載、KubeCon NA 2026 は OpenShell と kagent 1.0（2026/11/12 Linux・OSSトレンド）"
date: 2026-11-12T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Barracuda", "Microsoft", "Cisco", "Rust", "Cargo", "KDE", "Intel", "マイクロコード", "Kubernetes", "CNCF", "KubeCon", "NVIDIA"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

連邦機関に3日での修正が求められた脆弱性と、公開から日がたつまで新しい版をあえて使わない仕組み。2026年11月12日の動画は、「すぐ塞ぐべき穴と、あえて待つべき新版」を並べ、急ぐものと待つものの見分け方を5本の話題で追いました。

CISA の KEV に追加された6件は、期限が11月13日と11月24日に分かれました。Rust 1.100 は、Cargo の dependency cooldown と never 型の安定化を含む版で、11月12日に公開される予定です。KDE Plasma 6.8.3 は、GPU を2つ積む環境の描画まわりを直しました。Intel のマイクロコード 20261110 のリリースノートは、機能上の不具合の更新とだけ書いています。KubeCon NA 2026 では、OpenShell の CNCF Sandbox 入りと kagent 1.0 が紹介されました。

5本を「急ぐか待つか」でくくったのは書き手の見方で、各社や各プロジェクトの主張ではありません。動画で誤っていた点は、各節の終わりに訂正としてまとめました。確認は2026年11月12日の朝（日本時間）に行い、Rust の公開状況、KEV の期限、ディストリビューションの配布状況など、時点で変わるものには確認した時刻を本文に添えています。

{{< youtube "_1j9_dOTj5A" >}}

## 1. CISA KEV に6件が追加 — Barracuda の2件は期限11月13日

[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/11/10/cisa-adds-six-known-exploited-vulnerabilities-catalog)は、6件を、悪用の証拠に基づいて KEV に追加したと書いています。[KEV の JSON](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)（catalogVersion 2026.11.10）では、6件とも追加は11月10日（火）です。期限は、Barracuda の2件が11月13日（金）、残りの4件が11月24日（火）です。期限を課す BOD 26-04 の対象は連邦文民行政機関ですが、CISA は、すべての組織に KEV の修正を優先するよう呼びかけています。

| CVE | 製品 | 期限 | 採点（版・採点者） |
|---|---|---|---|
| CVE-2026-116606 | Barracuda Email Security Gateway（ESG） | 11月13日 | v4.0 で 9.3（Mandiant の CNA） |
| CVE-2026-111560 | Barracuda の複数製品 | 11月13日 | v4.0 で 8.6（Mandiant の CNA） |
| CVE-2026-124194 | Microsoft Outlook（Office） | 11月24日 | v3.1 で 6.5（Microsoft） |
| CVE-2026-20320 | Cisco BroadWorks | 11月24日 | v3.1 で 7.5（Cisco） |
| CVE-2026-111793 | Openwave Webtop Media Transcoder | 11月24日 | v3.1 で 4.3（MITRE の CNA） |
| CVE-2026-125350 | Google Chromium | 11月24日 | v3.1 で 8.8（CISA-ADP） |

6件とも、NVD 自身の採点はありません。表の値は、NVD が Secondary として載せている CNA や CISA-ADP の採点です。Barracuda の2件は、取得時点（11月12日 6:48、日本時間）で NVD の状態が分析中です。6件目の Chrome は、[11月11日の記事](https://blog.fuga.jp/posts/2026-11-11-linux-oss-trend/)で扱いました。Chrome の採点は、同じ記事で11月11日 7:49（日本時間）に確認した値です。

期限が分かれる理由は、[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) の Table 1 の区分です。期限は、公開資産であるか、KEV にあるか、自動化できるか、技術的影響は何か、で決まります。"& forensic triage" の付く区分は、期限（3日）までに修正または緩和をして、機器が侵害されていないかの調査（forensic triage）も行うものです。NVD の CISA-ADP の SSVC では、Barracuda の2件は技術的影響が total で、KEV の forensicTriage も Yes です。Outlook と Openwave は、技術的影響が partial で自動化できない区分で、期限は14日です。BroadWorks が14日になった理由は、書き手には確かめられません。11月10日の記事の SonicWall も、期限は14日後でした。

Barracuda の2件は、1本の[勧告](https://trust.barracuda.com/security/pre-authentication-authorization-bypass-command-injection)にまとまっています。CVE-2026-116606 は、NVD によると、認証なしの攻撃者が、設定のインポート機能を通じて、装置全体の設定を不正に変更できるというものです。Barracuda は、認証は不要だが、攻撃者が管理画面に到達できることが条件だと書いています。CVE-2026-111560 は、管理者権限が必要で、OS コマンドが root 権限で実行されるものです。ESG のほか、ロードバランサー、メッセージアーカイバ、Web アプリケーションファイアウォールなど、6つの製品が影響を受けます。KEV は、両者が連鎖しうると書き、Barracuda は、組み合わせると、認可の制御を迂回して root 権限に至りうる、としています。

悪用について、Barracuda は11月9日（米国東部時間）の更新で、少数の組織で悪用の活動を確認したと追記しました。対策として、管理画面へのアクセスを、信頼できる内部ネットワークに限るよう勧めています。ESG の影響版は、NVD と Mandiant が、9.4.0.030 未満としています。Barracuda の勧告は、版ではなくパッチ ID（BNSF-40425 は 9.4.017 以降、BNSF-40430 は 9.4.017 未満）で示しているため、9.4.0.030 以上なら安全、とは言い切れません。

Outlook の CVE-2026-124194 は、NVD の説明では、警告が出ないまま危険な動作が進み、ネットワーク越しのなりすましにつながるものです。Microsoft のデータ（CVRF）では、悪用あり・事前の公開なしとされ、11月10日（米国時間）の月例更新で修正されました。対象は Microsoft 365 Apps と Office LTSC 2021・2024 で、Microsoft が示す修正ビルドは、LTSC 2021 が 16.0.14334.21048、LTSC 2024 が 16.0.17932.21140 です。Microsoft 365 Apps のビルドは、取得できていません。

BroadWorks の CVE-2026-20320 は、細工した XML で、ファイルシステムの機密ファイルを読まれうるものです。[Cisco の勧告](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-bworks-xxe-uwUd7CEt)は8月19日の初版（v1.0）のままで、最初の修正版は RI.2026.07、回避策はありません。勧告は、悪用を把握していないと書いたままです。悪用の根拠は、11月10日の KEV への追加です。

Openwave の CVE-2026-111793 は、管理者が決めたファイル種別の制限を、認証済みのユーザーが迂回できうるものです。[Openwave の勧告](https://github.com/GISOpenwave/security-advisories-public/blob/main/CAN-2026-2032674.md)では、1.1.22.0 より前が対象です。採点は6件で最も低いものの、CISA は悪用の証拠に基づいて KEV に追加しています。

動画の訂正です。

- 動画では、2件の脆弱性の両方がそろうから、期限が3日になる、と紹介しました。期限は連鎖が理由ではなく、BOD 26-04 の Table 1 の区分で決まります。Barracuda の2件は、技術的影響が total とされ、「3日と forensic triage」の区分に当たります。また動画では、2件をどの順に使うかも説明しましたが、一次は「組み合わせられる」「組み合わせると root 権限に至りうる」と書くところまでで、順序の説明はありません（[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)、[Barracuda の勧告](https://trust.barracuda.com/security/pre-authentication-authorization-bypass-command-injection)）。

## 2. Rust 1.100.0 — Cargo の dependency cooldown と never 型

確認した11月12日 6:49（日本時間）の時点で、Rust 1.100.0 は公開されていません。stable は 1.99.1 のままで、公式ブログの告知の URL は404です。一方、[RELEASES.md](https://github.com/rust-lang/rust/blob/main/RELEASES.md) には `Version 1.100.0 (2026-11-12)` の項目があり、1.100.0 は11月12日の予定です。公開日時は、断定しません。1.99 の次なので、マイナー版で初めて3桁になります。

Cargo には、dependency cooldown が入ります。RELEASES.md は、"Introduced minimum publish age configurations, also known as dependency cooldowns." と書いています。設定すると、リゾルバは、公開からの経過が設定した期間に満たない版を、`Cargo.lock` にすでにある場合を除いて無視します。[RFC 3923](https://rust-lang.github.io/rfcs/3923-cargo-min-publish-age.html) の動機は、公開直後の版を自動スキャナーが調べる時間を稼ぐことと、認証情報が盗まれて偽の版が出たとき、本来の開発者が気づいて取り下げる（yank する）時間を稼ぐことです。RFC は、NPM のエコシステムでの最近のサプライチェーン攻撃にも触れています。

設定キーは、`registry.global-min-publish-age`（全体）と `registries.<name>.min-publish-age`（レジストリ別）です。既定は無効（`"0"`）で、何もしなければ従来どおりです。14日は、RFC の設定例の値で、既定ではありません。条件に合う版が1つもないときは、エラーで止まります。`CARGO_RESOLVER_INCOMPATIBLE_PUBLISH_AGE=allow` で解除できます。git や path の依存には適用されず、公開日時を持たないレジストリにも適用されません。Cargo のドキュメントの値は、取得時点で stable に記載がなかったため、nightly 版から確認しました。1.100 の公開後に、stable で再確認が必要です。

RFC は、この機能について、"should not be relied upon for security by itself"（セキュリティをこれだけに頼るべきではない）と書いています。待つことで防げるのは、一部の種類のサプライチェーン攻撃に限られます。[6月9日の記事](https://blog.fuga.jp/posts/2026-06-09-linux-oss-trend/)の VS Code の cooldown は、拡張機能の自動更新を保留する別の仕組みです。

never 型（`!`）は、RELEASES.md の Language に "Stabilize never type" とあり、安定化されます。互換性の注意として、never 型のフォールバックが、全エディションで `!` に変わります。`Infallible` は、`!` の型エイリアスになります。[RFC 1216](https://github.com/rust-lang/rfcs/blob/master/text/1216-bang-type.md) の開始日は2015年7月19日で、11月12日に公開されれば、約11年4か月かかったことになります。安定化の PR は、[rust-lang/rust#155499](https://github.com/rust-lang/rust/pull/155499) で、8月24日（UTC）にマージされました。PR は、フォールバックの変更を破壊的変更（breaking change）と明記しています。書き手としては、版を上げる前に、手元でビルドを試しておくのが無難だと考えます。

動画の訂正はありません。

## 3. KDE Plasma 6.8.3

[Plasma 6.8.3 の告知](https://kde.org/announcements/plasma/6/6.8.3/)の日付は、11月10日（火）です。告知は、2週間分の翻訳と修正を加えたバグ修正版と位置づけています。6.8.1（10月20日）、6.8.2（10月27日）に続く版です。6.8.2 は[10月29日の記事](https://blog.fuga.jp/posts/2026-10-29-linux-oss-trend/)で扱い、そのときもマルチ GPU の修正が入っていました。主な修正は、[changelog](https://kde.org/announcements/changelogs/plasma/6/6.8.2-6.8.3/) と各コミットのメッセージに沿って紹介します。

- マルチ GPU: KWin の multigpuswapchain で、NVIDIA 向けの回避策は、コミットのメッセージによると、条件が反転していました。AMD（amdgpu）向けの回避策は、「書かれたとおりには動いていなかった」とあり、実装が直っています。AMD の件は、バグを閉じる修正ではありません
- レンダーループ: トリプルバッファリングと commit timing を使うと、フレームの予定が、必要より先に入ることがありました。計算が直っています
- 画面共有・録画: PipeWire のストリームへ渡すカーソルのメタデータで、カーソルがギザギザに見える問題が直りました
- パネル: レイアウトの間隔が0のとき、パネルが固まる不具合が直りました
- ランチャー: ショートカットでランチャーを開くと、クラッシュする不具合が直りました
- 明るさ: 明るさの制御が効かなくなったあと、画面が暗いままになる不具合が直りました
- ツールチップ: Qt 6.12 で、デスクトップのツールチップが Plasma のスタイルを継承しない不具合が直りました

KWin には、メインスレッドの固まりを検出する仕組みも入りました。コミットのメッセージによると、環境変数 `KWIN_HANG_DETECTION_TIMEOUT` を0より大きい値に設定したときだけ動き、固まりを警告として出力します。常に動くわけではなく、この変更で固まりそのものが直ったわけではありません。

更新は、ディストリビューション経由で届きます。告知も、すべてのディストリビューションで、告知の時点にパッケージが揃っているとは限らない、と書いています。11月12日 6:50（日本時間）の時点で、Arch の extra の plasma-desktop は 6.8.2-1 のままでした。

次の予定は、[Frameworks のスケジュール](https://community.kde.org/Schedules/Frameworks)で、KDE Frameworks 6.32 が11月13日（金）の公開予定です（表記は expected）。確認時点で、公式の 6.32.0 の告知は公開されていません。

動画の訂正です。

- 動画では、Plasma 6.8.3 に続いて、KDE Gear 26.11 も近く出る予定、と紹介しました。26.11 という版はありません。次の KDE Gear は 26.12 で、リリースは12月10日（木）の予定です。11月13日（金）の予定は、ベータの 26.11.80 です（[KDE Gear 26.12 のスケジュール](https://community.kde.org/Schedules/KDE_Gear_26.12_Schedule)）。

## 4. Intel CPU マイクロコード 20261110

[microcode-20261110](https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/releases/tag/microcode-20261110) の公開は、UTC で2026年11月10日 17:00:14、日本時間では11月11日の午前2時です。リリースノートの目的欄は、9項目とも "Update for functional issues. Refer to ... Specification Update for details." です。INTEL-SA の記載はありません。書けるのは、リリースノートにセキュリティの記載がない、というところまでです。Intel が脆弱性は0件だと保証しているわけではありません。直近の microcode-20260925 も、機能上の不具合の更新のみでした。

更新の対象は、リリースの表では次のとおりです。

- パソコン向け: 第13世代の Raptor Lake（RPL-H/P/PX、RPL-U）、Wildcat Lake（Core Series 3）、Panther Lake（Core Ultra Series 3）
- サーバー向け: Sapphire Rapids、Emerald Rapids、Granite Rapids、Sierra Forest など
- 新規の対象: Clearwater Forest（Xeon 6900E+ Series）が、このリリースの New Platforms に載りました

どの不具合を直したかは、リリースノートに書かれておらず、CPU ごとの Specification Update を参照する形です。Panther Lake の[Specification Update](https://cdrdv2.intel.com/v1/dl/getContent/869992)（文書番号 869992、Revision 009）には、性能カウンターの数え間違いに関する erratum が複数あります。その状態は、"No Fix" です。Intel の凡例では、"There are no plans to fix this erratum" とされています。今回の更新で、これらのカウンターが直ったとは、確かめられません。性能分析をしている場合は、自分の CPU の Specification Update で、該当の erratum の状態を確認してください。

配布の状況は、時点つきです。Arch の intel-ucode は、20261110-1 が extra に入り、11月10日（UTC）に更新されています。Debian の追跡ページは、11月12日 6:49（日本時間）の確認時点で、testing と unstable が 3.20260925.1 のままです。

動画の訂正です。

- 動画では、性能カウンターの数え間違いが直ったという前提で、性能分析をしている人は早めに入れて、これまでの測定結果を見直す価値がある、と紹介しました。リリースノートは「機能上の不具合の更新」とだけ書き、カウンターの誤りが直ったとは明記していません。Panther Lake の Specification Update では、これらのカウンターの erratum は No Fix（修正予定なし）です。今回の更新でカウンターが直ったとは確かめられず、測定結果を見直す前提も確かではありません（[Panther Lake の Specification Update](https://cdrdv2.intel.com/v1/dl/getContent/869992)）。

## 5. KubeCon NA 2026 — OpenShell と kagent 1.0

KubeCon + CloudNativeCon North America 2026 は、[Linux Foundation のイベントページ](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)によると、ソルトレイクシティで11月9日から12日の会期です。ページには、9,000人以上の参加者の表示があります（集計の時点の記載はありません）。

NVIDIA は、DSX AI Factory Platform の3つのオープンソースの部品として、NVKE、NVKR、Snapshot を発表しました。[Cloud Native Now が伝えた NVIDIA の発表](https://cloudnativenow.com/kubecon-cloudnativecon-north-america-2026/nvidia-adds-kubernetes-engine-recipes-and-snapshot-to-dsx-ai-factory-platform/)によると、NVKE（NVIDIA Kubernetes Engine）と NVKR は公開プレビューで、GPU 基盤上でマネージド Kubernetes サービスを提供するための部品です。Kubernetes そのものではありません。Snapshot は、チェックポイントしたレプリカを、モデルの再読み込みなしで秒単位に復元するものです。設計パートナーの Crusoe は、GLM-5.3 を Crusoe Cloud で試し、ワークロードが ready になるまでの時間を、約8分から31秒に縮めたと伝えられています。これは1件の測定です。NVIDIA 自身の告知は、取得できていません。

OpenShell は、[CNCF の告知](https://www.cncf.io/announcements/2026/11/10/cncf-hits-major-milestones-with-global-community-growth-record-industry-investment-and-a-new-generation-of-projects-to-build-ai-systems-in-production/)によると、CNCF の Sandbox プロジェクトとして参加します。告知は、NVIDIA が主導し、エージェントを取り巻くインフラでポリシーを強制する、と説明しています。受け入れは、[CNCF のプロジェクトページ](https://www.cncf.io/projects/openshell/)で、2026年9月26日（Sandbox）です。TOC の投票は、[cncf/sandbox の Issue #522](https://github.com/cncf/sandbox/issues/522) で、9月26日（UTC）に賛成8、反対0、棄権1、未投票2で可決されました。11月10日の告知は、KubeCon の場での紹介です。オンボーディングの Issue #535 は、確認時点で open です。CNCF のサイトは、Sandbox を、"Experimental projects not yet widely tested in production"（試験的で、本番での検証がまだ広くないプロジェクト）と説明しています。

kagent 1.0 は、GitHub の [v1.0.0](https://github.com/kagent-dev/kagent/releases/tag/v1.0.0) が11月9日 18:43（UTC、日本時間は11月10日 3:43）の公開です。Solo.io は、11月10日に、Agent Substrate と kagent のエンタープライズ版の一般提供を[告知](https://www.solo.io/press-releases/announcing-kagent-1-0-ga)しました（告知の題は「Solo.io Brings Agent Substrate to Enterprise Production」）。kagent は2025年5月22日から CNCF の Sandbox で、今回入ったわけではありません。Solo.io のブログは、0.x から 1.0 は新しい API と新しいランタイムなので、新規インストールを前提にするよう書いています。

Mirantis は、[Mirantis Agent Platform の一般提供](https://cloudnativenow.com/kubecon-cloudnativecon-north-america-2026/mirantis-launches-agent-platform-for-governed-ai-agents-on-kubernetes/)を発表しました。Cloud Native Now が載せた配信文によると、利用者が自分の環境で動かすセルフホスト型で、エージェントごとの隔離、予算の上限、全エージェントのネットワークを一度に切る操作、人が承認する修復が含まれます。

動画の訂正はありません。

## まとめ

KEV の6件は、Barracuda の2件が11月13日、Outlook・BroadWorks・Openwave・Chromium が11月24日の期限です。Rust 1.100 は、確認時点で未公開で、11月12日の予定です。Plasma 6.8.3 は、確認時点で Arch の extra に届いていません。マイクロコード 20261110 は、リリースノートにセキュリティの記載がありません。OpenShell は、CNCF の Sandbox に9月26日に受け入れられました。

手元で確かめておくものは次のとおりです。

- KEV の6件: Barracuda の ESG と関連製品は、パッチ ID（BNSF-40425、BNSF-40430）を確かめ、管理画面を内部ネットワークに限り、侵害の痕跡も調べる。期限は11月13日。Outlook は LTSC 2021 が 16.0.14334.21048、LTSC 2024 が 16.0.17932.21140 以上か確かめる。BroadWorks は RI.2026.07 以降か確かめる。Openwave は 1.1.22.0 以降か確かめる。期限は11月24日
- Rust 1.100: 公開後に、版を上げる前にビルドを試す。cooldown は、設定しなければ従来どおりで、使うなら設定キーと値を決める。RFC のとおり、これだけにセキュリティを頼らない
- Plasma 6.8.3: ディストリビューションの配布を待つ。症状がなければ、通常の更新で足りる
- Intel マイクロコード: 通常の更新で入れ、性能カウンターを使う分析をするなら、自分の CPU の Specification Update を確かめる
- KubeCon の発表物: NVKE と NVKR は公開プレビュー、OpenShell は Sandbox。成熟度を前提に、検証用の環境から試す。kagent を 0.x から上げるなら、Solo.io のブログのとおり新規インストールを前提にする

## 参考リンク

- [CISA のアラート（KEV 6件）](https://www.cisa.gov/news-events/alerts/2026/11/10/cisa-adds-six-known-exploited-vulnerabilities-catalog)
- [BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)
- [Barracuda の勧告](https://trust.barracuda.com/security/pre-authentication-authorization-bypass-command-injection)
- [Cisco の勧告（BroadWorks）](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-bworks-xxe-uwUd7CEt)
- [Rust の RELEASES.md](https://github.com/rust-lang/rust/blob/main/RELEASES.md)
- [RFC 3923](https://rust-lang.github.io/rfcs/3923-cargo-min-publish-age.html)
- [KDE Plasma 6.8.3 の告知](https://kde.org/announcements/plasma/6/6.8.3/)
- [microcode-20261110](https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files/releases/tag/microcode-20261110)
- [CNCF の告知（KubeCon NA 2026）](https://www.cncf.io/announcements/2026/11/10/cncf-hits-major-milestones-with-global-community-growth-record-industry-investment-and-a-new-generation-of-projects-to-build-ai-systems-in-production/)

（2026/11/12 Linux・OSSトレンド）
