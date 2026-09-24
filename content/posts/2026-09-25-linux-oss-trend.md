---
title: "「出た」と「使える」のあいだ（2026/9/25 Linux・OSSトレンド）"
date: 2026-09-25T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "JFrog", "Artifactory", "Git", "Rust", "Qualcomm", "Adreno", "gccrs", "Arista", "VeloCloud", "SD-WAN"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

パッチもコードも、「出た」瞬間と「使える」瞬間のあいだには、まだ距離があります。今日はその距離を測る5本です。

パッチは公開されても、発行済みのトークンまでは失効させてくれません。ロードマップは決まっても、必須化はまだ先の予定です。カーネルパッチは投稿されても、画面には何も映りません。コンパイラは進捗しても、まだ実用の入り口です。そして脆弱性は塞がれても、一部のトレインにはパッチそのものがまだ届いていません。動画タイトルの言葉を借りれば、「前進と後始末の一日」です。

{{< youtube "07v7ia9H4H4" >}}

## 1. JFrog Artifactory の3連鎖CVE — パッチを当てても、盗まれたトークンは生き続ける

[JFrog Artifactory](https://docs.jfrog.com/releases/docs/jfrog-security-advisories)に、単独でも連鎖でも管理者権限に届く3つの脆弱性が見つかりました。[CVE-2026-42018](https://docs.jfrog.com/releases/docs/jfrog-security-advisories)（CVSS 7.5、匿名トークンの発行）と[CVE-2026-42016](https://docs.jfrog.com/releases/docs/jfrog-security-advisories)（CVSS 8.1、スコープ昇格）を組み合わせると、`POST /access/api/v1/aws/token/` で匿名のJWTを取得し、それを `POST /access/api/v1/tokens` に提示して[スコープをadminに要求するだけで](https://www.wiz.io/blog/artifactory-under-attack-in-the-wild-exploitation-of-cve-2026-42016-cve-2026-4201)、わずか2リクエストの連鎖で管理者権限のトークンが手に入ります。さらに[CVE-2026-82329](https://docs.jfrog.com/releases/docs/jfrog-security-advisories)（CVSS 9.8）は、デフォルトで空文字列のままになっているクラスタ参加キーを悪用し、[SHA-256("")から導出できる固定値で署名したJWTを認証不要のエンドポイントへ送るだけで](https://bishopfox.com/blog/cve-2026-82329-unauthenticated-administrative-access-in-jfrog-artifactory-via-an-empty-cluster-join-key)、単独で管理者権限に到達できます。

実際の悪用は2026年8月15日から9月8日にかけて観測されており、[Wiz Researchはこの期間にC2機能を備えたRust製のカスタムバックドアが投下されたと報告しています](https://www.wiz.io/blog/artifactory-under-attack-in-the-wild-exploitation-of-cve-2026-42016-cve-2026-4201)。CVE-2026-42016は開示（7月27日）時点で67%のインスタンスが脆弱で、6週間後でも59%が未修正のままでした。そして本題の「後始末」がここにあります。管理者権限を取られれば、保管されている成果物を書き換えられる立場に立たれてしまいますし、[パッチを適用しても、すでに窃取された署名キーや発行済みのトークンは無効化されず、攻撃者はホストに戻らなくても有効なトークンを鋳造し続けられます](https://www.wiz.io/blog/artifactory-under-attack-in-the-wild-exploitation-of-cve-2026-42016-cve-2026-4201)。パッチは修正の始まりであって、終わりではありません。

CISAはCVE-2026-42016 / 42018を[9月11日にKEVカタログへ追加し、連邦機関の修正期限は本日9月25日](https://www.cisa.gov/news-events/alerts/2026/09/11/cisa-adds-three-known-exploited-vulnerabilities-catalog)。CVE-2026-82329は[9月2日に追加され、期限は9月5日でした](https://www.cisa.gov/news-events/alerts/2026/09/02/cisa-adds-seven-known-exploited-vulnerabilities-catalog)。修正版はCVEごとに系統が異なるため、稼働ブランチに応じてJFrog公式アドバイザリで確認するのが確実です。JFrog Cloud（SaaS）はすでに全て適用済みで対応不要とされています。

## 2. Git 2.56とGit 3.0ロードマップ — Rustは「既定で有効」から「必須」へ、ただしまだ先

[Git 2.56がリリース候補フェーズを終えようとしています](https://lwn.net/SubscriberLink/1094575/2385e98583715c2b/)。700を超える非マージコミットを含み、Swiftのuserdiffパターン追加や、`git status` のpull提案改善、`git refs` のcreate/delete/update/renameサブコマンドなど、細かな改善が並びます。実験的な新機能として`git history drop <commit>`も追加されました。`--dry-run` や `--update-refs`、`--empty=(drop|keep|abort)` といったオプションを備え、対象がHEADの場合は作業ツリーも自動更新される一方、マージコミットとルートコミットの削除は拒否する設計です。

本題は少し先、[Git 3.0のロードマップです](https://github.com/git/git/blob/master/Documentation/BreakingChanges.adoc)。2.56ではRustサポートは既定で有効になったものの、まだ任意です。それが **Git 3.0では必須になる予定** です。[LWNの記事は「Rustコンパイラの無いプラットフォームは、Git 3.0へ上げられなくなる」と書いています](https://lwn.net/SubscriberLink/1094575/2385e98583715c2b/)。同時に、新規リポジトリのデフォルトのハッシュ関数がSHA-1からSHA-256へ切り替わることや、参照ストレージのデフォルトがreftableへ変わることも[Git公式のBreaking Changes文書に明記されています](https://github.com/git/git/blob/master/Documentation/BreakingChanges.adoc)。reftableはAndroidのように80万件を超える参照を持つ大規模リポジトリが例として挙げられており、既存のSHA-1リポジトリを廃止する計画は今のところありません。

ただし、Git 3.0の時期について注意が必要です。LWNの記事は「2.98が2026年12月、2.99 LTSと3.0が2027年4月に同時リリース」というメーリングリスト上の計画を報じていますが、[Git公式のBreaking Changes文書自身は、この記事の確認時点で「まだ確定した公開日は無い」と明記しています](https://github.com/git/git/blob/master/Documentation/BreakingChanges.adoc)。コードは前進していても、必須化という「使える」の境界線はまだ確定していません。

## 3. Qualcomm Adreno 850 — SoC発表の翌日にパッチ、でも画面にはまだ何も映らない

[Snapdragon 8 Elite Extreme Gen 6の発表翌日にあたる2026年9月23日、Qualcommのオープンソースチームからカーネルメーリングリスト linux-arm-msm 宛てに、新GPU対応パッチが投稿されました](https://ratatoskr.run/linux-arm-msm/2026/09/17627860)。送信者は Akhil P Oommen 氏（`akhilpo@oss.qualcomm.com`）、件名は「drm/msm: Support for Hawi & Maili GPU」です。HawiとMailiはGPU自体のコードネームではなく、SoC（プラットフォーム）側の名前で、HawiにAdreno 850が、MailiにAdreno 845がそれぞれ搭載されます。

パッチシリーズ全体は15本からなり、[中核となるのはAdreno 850・845それぞれのドライバ登録やTHINMEM設定、dt-bindingsを含む5本です](https://www.phoronix.com/news/Qualcomm-Adreno-850-Open-Source)。技術的には、Adreno 850はAdreno 840と同じADRENO_8XX_GEN2ファミリー・スライスアーキテクチャを継承し、新規のBxレールとMxGレールが制御するGDSCからGMUへ給電される構成です。行列演算コア「MALU」はAdreno 850のみに搭載され、Adreno 845には無く、こちらのLinuxサポートはMesa連携とあわせて別途投稿される予定です。

ただし、ここが「使える」までの距離です。[ディスプレイドライバ・Mesa（Turnip Vulkan）・ファームウェアバイナリはいずれもまだ未対応で、試験はディスプレイ非対応のためオフスクリーンでのレンダリングに限られています](https://www.phoronix.com/news/Qualcomm-Adreno-850-Open-Source)。パッチもまだメインラインカーネルにはマージされていません。それでもオランダのLinux Magazineは、発表からほぼ1日で最初のカーネルパッチが出たと書いており、Qualcommのオープンソースチームの動きの速さそのものは伝わってきます。

## 4. gccrs — Rust for Linuxマイルストーンは進捗35%、実用コンパイラはまだ途中

GCCのRustフロントエンド「gccrs」が、Linuxカーネルのコンパイルに向けて着実に前進しています。[gccrs公式ブログの月次レポートによれば、Rust for Linuxマイルストーンの進捗は2026年2月時点の16%から、5月時点で35%まで伸びました](https://rust-gcc.github.io/2026/06/02/2026-05-monthly-report.html)。3月には開発ロードマップを「組み込みRustコンパイラ」「Rust for Linuxコンパイラ」「汎用コンパイラ」の3段階マイルストーンへ再編し、名前解決の設計上の課題（パス解決は、どの名前空間を解決しようとしているかに関係なく、まず型の名前空間で行う必要がある、という気づき）への対応も進みました。5月には`core`クレート内の複雑なインポート・エクスポート構造が正しく解決・挿入されるようになっています。

開発チームの Arthur Cohen 氏と Pierre-Emmanuel Patry 氏（所属: Open Source Security, Inc.）は、「Compiling the Linux kernel with gccrs」と題した発表でRustConf 2026（モントリオール）に登壇し、[翌週のKangrejosでも続報を発表しました](https://rust-gcc.github.io/2026/06/02/2026-05-monthly-report.html)。この発表の様子は、[LWNが2026年9月22日付の記事「Compiling the kernel with gccrs」として紹介しています](https://noise.getoto.net/2026/09/22/compiling-the-kernel-with-gccrs/)。GSoC 2026では2名の学生が加わり、Janet Chien氏がDropインフラ（デストラクタの自動実行）を、Enes Çevik氏がallocクレート対応を担当しています。

もっとも、カーネルのRustコードは現状rustc（LLVM）でしかビルドできず、gccrsで一般的なRustプログラムをコンパイルできる段階にはまだ入っていません。進捗35%という数字が示すとおり、「コードは前に進んでいる」ことと「手元で使える」ことのあいだには、まだ距離があります。

## 5. Arista VeloCloud Orchestrator CVE-2026-93952 — CVSS 10.0、一部トレインにはまだパッチが無い

[Arista VeloCloud Orchestrator（VCO）に、CVSS v3.1で10.0という最高評価の脆弱性CVE-2026-93952が見つかりました](https://www.arista.com/en/support/advisories-notices/security-advisory/24765-security-advisory-0183)。証明書ベース認証が有効な環境で、Edge証明書の公開部分を入手し、VCOのWebインターフェースへ到達できれば、[VCOのテナント／オペレータの認証情報なしに特権機能へ届いてしまう](https://www.arista.com/en/support/advisories-notices/security-advisory/24765-security-advisory-0183)脆弱性です（CVSS v4.0では攻撃条件がより厳しく評価され9.5）。Aristaは外部から発見され、実際に悪用されていることを確認しています。

侵害の痕跡として、`/usr/local/sbin/.vcnode.js`、`/usr/local/sbin/vc-sysmond`（MD5: `dc78e206eaeadec59fc5801fe4556bd0`）、`/etc/systemd/system/vc-sysmon.service` といったファイルパスや、悪意のIPアドレス、nginxログの `x-vc-opt` ヘッダーが[Aristaのアドバイザリに列挙されています](https://www.arista.com/en/support/advisories-notices/security-advisory/24765-security-advisory-0183)。

CISAは[9月22日にKEVカタログへ追加し、BOD 26-04に基づいて連邦機関に9月25日という修正期限を課しました](https://www.cisa.gov/news-events/alerts/2026/09/22/cisa-adds-four-known-exploited-vulnerabilities-catalog)。修正版はバージョン系統ごとに状況が異なります。5.2.x系は5.2.3.15以下が対象で5.2.3.16で修正、6.4.x系は6.4.2.7以下が対象で6.4.2.8で修正されていますが、[6.1.x系（6.1.3.7以下）と7.0.x系（7.0.0.2以下）は、2026年9月25日時点でまだ修正版が提供されていません](https://www.arista.com/en/support/advisories-notices/security-advisory/24765-security-advisory-0183)。Hosted版・Dedicated版はArista側で既に修正が適用済みです。CVSS 10.0という最高評価の脆弱性であっても、パッチそのものがまだ全トレインに届いていない、という後始末が残っています。

## まとめ

JFrogはパッチを当てても発行済みトークンが生き続け、Aristaは一部トレインにパッチそのものがまだありません。Gitは必須化の予定こそ立ちましたが日程は未確定、Qualcommのパッチはまだ画面に何も映さず、gccrsの進捗は35%です。「出た」ものが「使える」ようになるまでには、それぞれ違う理由でまだ距離が残っています。動画タイトルの「前進と後始末の一日」は、今日という日を言い当てているように思います。

## 参考リンク

- [JFrog セキュリティアドバイザリ一覧](https://docs.jfrog.com/releases/docs/jfrog-security-advisories)
- [Wiz Research — Artifactory 悪用の調査レポート](https://www.wiz.io/blog/artifactory-under-attack-in-the-wild-exploitation-of-cve-2026-42016-cve-2026-4201)
- [LWN — Looking forward to Git 2.56 — and 3.0](https://lwn.net/SubscriberLink/1094575/2385e98583715c2b/)
- [Git BreakingChanges.adoc（Git 3.0ロードマップ）](https://github.com/git/git/blob/master/Documentation/BreakingChanges.adoc)
- [linux-arm-msm メーリングリスト — Adreno 850/845 GPUパッチ](https://ratatoskr.run/linux-arm-msm/2026/09/17627860)
- [gccrs 公式ブログ — 2026年5月 Monthly Report](https://rust-gcc.github.io/2026/06/02/2026-05-monthly-report.html)
- [Arista セキュリティアドバイザリ 0183 — CVE-2026-93952](https://www.arista.com/en/support/advisories-notices/security-advisory/24765-security-advisory-0183)
- [CISA Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
