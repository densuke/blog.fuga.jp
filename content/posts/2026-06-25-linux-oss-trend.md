---
title: "あなたのCI/CDは今日も乗っ取られているかもしれない――Cordyceps攻撃・fwupd 250件・ML-DSA実装・Cisco緊急対応"
date: 2026-06-25T09:00:00+09:00
draft: false
tags: ["Linux", "セキュリティ", "GitHub Actions", "CI/CD", "GCC", "fwupd", "ポスト量子暗号", "Cisco", "脆弱性"]
categories: ["週刊OSS動向", "セキュリティ"]
---

こんにちは、コンテンツ制作部のライターです。

今日の記事を書くにあたって、最初に「あ、これやばいな」と思ったのが「Cordyceps（コルジセプス）」というキーワードでした。ご存知でしょうか、冬虫夏草という寄生性のキノコ。昆虫の体を乗っ取って、思い通りに動かしてしまうやつです。今回発見されたGitHub Actionsの攻撃クラスが、まさにそれと同じことをCI/CDパイプラインに対してやる、という話で、なんとMicrosoftやGoogleのOSSプロジェクトまで影響を受けていたという……。

今週のテーマを一言で言うなら **「信頼している土台ほど疑うべき理由」** です。CI/CDのパイプライン、GCCのコンパイル設定、ファームウェア更新ツール、IP電話の基盤、どれも「安全なはずのもの」として普段あまり疑わずに使っているものばかりです。でも、今週はその「安全なはず」が次々と揺さぶられた週でした。

{{< youtube "ijAwwEKNvr4" >}}

---

## 1. Cordyceps：GitHub Actionsが「冬虫夏草」に乗っ取られる

セキュリティ企業Novee Securityが「Cordyceps（コルジセプス）」と命名したGitHub ActionsのCI/CD設定ミスを突く攻撃クラスが発見されました。約3万件のGitHubリポジトリをスキャンした結果、 **300以上が「完全に悪用可能」** な状態と確認されています（ [The Hacker News](https://thehackernews.com/2026/06/cordyceps-cicd-flaws-expose-300-github.html) ）。

影響を受けたのは、Apache・Cloudflare・Python Software Foundation、そしてなんとMicrosoftとGoogleのプロジェクトまで含まれています。「大手が使っているから安全」ではない、を地で行く事例です。

### 問題の核心は `pull_request_target` の誤用

根本原因は、GitHub Actionsのイベントトリガー `pull_request_target` の使い方にあります。このイベントは **フォーク元（ベース）リポジトリのコンテキストで動く** ように設計されています。つまり、外部から送られてきたプルリクエストのコードをそのまま `actions/checkout` でチェックアウトして実行すると、攻撃者が制御するコードが、リポジトリのシークレットや `GITHUB_TOKEN` にフルアクセスできる高い権限で走ってしまうんです。

この攻撃パターンは業界では「Pwn Request（PwnedなPR）」と呼ばれていて、Cordycepsの主要な攻撃ベクターです。典型的な手口はこうです。

1. 攻撃者が無料アカウントで悪意あるPRを送る
2. `pull_request_target` イベントで特権ワークフローが起動
3. `package.json` の `postinstall` スクリプトなどに仕込んだコードが走る
4. AWSやGCPの認証情報が流出、クラウドインフラにオーナー権限でアクセスされる

特に怖いのが「攻撃の各ステップが単独では無害に見える」点です。普通のコードレビューではなかなか気づけない。

Microsoft Azure Sentinelではコメント経由で非失効のGitHub App鍵が取れる状態だったそうで、Google AI Agent Development Kitでは「PRひとつ送るだけでGoogleクラウドプロジェクトへのオーナーレベルアクセスが取得できる」攻撃チェーンが成立していました。

もうひとつ見逃せない指摘があります。AIコーディングツールがYAMLを自動生成するとき、学習データに含まれる **既存の脆弱なパターンをそのまま再現する** という悪循環が起きているそうです。「AIに聞いて書いてもらったGitHub Actionsの設定」が実は危ない、というのは、耳が痛い話です。

### GitHubの対策と今できること

GitHubは2026年6月18日に `actions/checkout` v7を公開し、`pull_request_target` でフォークのSHAを直接指定するパターンをデフォルトでブロックするようになりました（ [GitHub Changelog](https://github.blog/changelog/2026-06-18-safer-pull_request_target-defaults-for-github-actions-checkout/) ）。あえて許可したい場合は `allow-unsafe-pr-checkout: true` フラグを明示することになります。この名前、意図的に「コードレビューで目立つ名前」にしたそうで、なかなかスマートな対策です。

今すぐできる確認はシンプルです。

```
grep -r "pull_request_target" .github/workflows/
```

自分のリポジトリで引っかかったら、 `actions/checkout@v7` に更新するのを優先しましょう。根本的な解決策は「信頼されないコードを実行するワークフローと、シークレットを扱うワークフローを分ける」設計への変更ですが、まずはアップデートから。

皆さんのリポジトリでも `pull_request_target` を使っている設定、心当たりはありませんか？

---

## 2. GCC 1行パッチで+12%：Pentium Pro時代の定数が今も生きていた

少し毛色の違う話を。Intel のエンジニアが `gcc/config/i386/x86-tune-costs.h` というファイルを **1行変更しただけ** で、最新CPUのベンチマーク性能が約12%向上したという話です（ [Phoronix](https://www.phoronix.com/news/GCC-x86-Generic-Mispredict) ）。

変わったのは「分岐予測が外れたときのペナルティコスト」を表す定数値。`COSTS_N_INSNS(2)` から `COSTS_N_INSNS(2) + 3` という、数値にして37.5%増の修正です。

### なぜこれで12%も変わるのか

GCCの最適化には **if-conversion（if変換）** という処理があります。`if/else` 分岐を `cmov`（条件実行命令）に置き換えて、分岐予測ミスによるパイプラインのフラッシュを防ぐ最適化です。

この「if変換をするべきかどうか」の判断に、分岐予測ミスのペナルティコストが使われています。そのコストの定数が **Pentium Pro時代の浅いパイプラインCPU向けの値のまま** 20〜30年放置されていたんです。

カーナビが昔の一般道の速度制限をもとにルート計算し続けていたようなものです。高速道路が整備されていても、そのスピードを考慮できていなかった。Intel Granite RapidsやAMD Zen 5は20段超のパイプラインを持っているので、予測ミスのペナルティが昔とは桁違いに大きくなっています。定数が実態より低いせいで、GCCが「if変換しないで分岐のままにしても安い」と誤判断してパイプラインフラッシュを量産していた、というわけです。

Intel Granite Rapidsで+12.7%、AMD Zen 5で+12.1%の改善（SPEC CPU 2017の544.nab_r、バイオインフォマティクス計算）という結果は、「ソフトウェアの積み重なった層の深さ」を体感させてくれます。最新のハードウェアの上で、数十年前に設定されたパラメータが動いていた、というのは少し怖くもあり、面白くもあります。

ただし副作用も報告されています。AMDでの検証で、特定のベンチマーク（Hint）において `-O2` + generic チューニングの組み合わせで約 **30%の性能退行** が観測されており、GCC Bugzilla #125970 で追跡中です。

この変更はGCC 17開発ブランチに入っているので、一般ユーザーへの影響は来年以降になります。当面の最大化には `-march=native` を使うのが現実的です。

---

## 3. fwupd 2.0.21：ファームウェアを安全に更新するツール自体に250件の問題

Linuxのファームウェア更新ツール **fwupd** の安定版 2.0.21 が2026年6月23日にリリースされました。何が注目かというと、過去3ヶ月間にAnthropicのAIセキュリティスキャナ「Project Glasswing（Claude Mythos Preview）」が発見した **250件超の脆弱性** が一括バックポートされたことです（ [fwupd 2.0.21リリースノート](https://github.com/fwupd/fwupd/releases/tag/2.0.21) ）。

「ファームウェアを安全に更新するためのツール」自体に多数の脆弱性が潜んでいた、という構図の皮肉はさておき、内容は洒落にならないものが多いです。ヒープバッファオーバーフロー、パストラバーサル、SSRF（ModifyRemote D-Busメソッド経由で攻撃者が制御するファームウェアサーバへの誘導）など、fwupdのC言語で書かれたバイナリパーサー群に機械的なメモリ操作ミスが多数あったことがわかりました。

### AIスキャナの「速さ」と「量」

Project GlasswingはCyberGym脆弱性再現ベンチマークで83.1%を達成しており（前世代のClaude Opus 4.6は66.6%）、AWS・Apple・Google・Microsoftなど12の主要パートナーが参加する横断的なセキュリティプロジェクトです（ [Anthropic公式](https://www.anthropic.com/glasswing) ）。2026年5月時点で50以上の参加組織が1,000以上のOSSプロジェクトをスキャンし、推定6,202件の高・深刻度脆弱性を発見しています。Mozillaでは従来手法の10倍以上、271件をFirefox 150内で発見したそうです。

ただ、著名なセキュリティ研究者のブルース・シュナイアーは冷静な指摘をしています。「23,000件超の発見に対してパッチ適用済みは75件」という数字を挙げ、「AIが見つけるスピードに人間のパッチ適用が追いつけるのか？」と問題提起しています（ [Schneier on Security](https://www.schneier.com/blog/archives/2026/06/anthropics-project-glasswing-update.html) ）。

スキャン速度は上がった。でも修正を適用する人手は増えていない。このギャップは、今後のOSSセキュリティの大きな課題になりそうです。

### 対応方法

Ubuntu、Fedora、Debian、Arch Linuxなど主要ディストリビューションにはfwupdが標準搭載されています。影響を受けるのは2.0.21未満の2.0.x系列です。

```
sudo apt update && sudo apt upgrade fwupd   # Debian/Ubuntu系
sudo dnf upgrade fwupd                      # Fedora/RHEL系
```

---

## 4. Linux 7.2にML-DSAが入った：「2030年問題」への備えが始まった

Linux 7.2のintegrityサブシステムに、NISTが2024年8月に正式標準化した **ポスト量子署名方式 ML-DSA** （旧CRYSTALS-Dilithium、FIPS 204）によるIMA/EVMシグネチャ検証機能が追加されました（ [Phoronix](https://www.phoronix.com/news/Linux-7.2-Integrity) ）。

正直、「ポスト量子暗号」という言葉を見るたびに「まだ量子コンピュータって実用化されてないよね？」と思う方もいるでしょう。私も最初はそう思っていました。でも少し調べると、背景には「Harvest Now, Decrypt Later（今収集して後で解読する）」という攻撃戦略があることがわかります。今のRSAや楕円曲線暗号で保護されたデータを今のうちに大量収集しておき、将来の量子コンピュータで解読する、という手口です。

NSAのCNSA 2.0は **2030年をデッドライン** として量子耐性暗号への移行を義務付けています。4年後です。

### ML-DSAって何が違うの？

ML-DSAは格子ベースの署名方式で、量子コンピュータでも解けない数学的問題に依存しています。驚くのは鍵と署名のサイズです。ECDSAは公開鍵64バイト、署名64バイトのコンパクトさですが、ML-DSAは公開鍵が **2,592バイト、署名が3,309バイト** と約40倍になります。その代わり署名生成速度は0.65ミリ秒と実用的なレベルを確保しています。

Linuxカーネルへの統合はLinux 6.19でのカーネルモジュール署名サポートに続く動きで、今回はIMA（Integrity Measurement Architecture）とEVM（Extended Verification Module）まで拡張されました。IMAはファイルが開かれるたびにハッシュを計算して改ざんを検出し、EVMはファイルの拡張属性への不正な書き換えを防ぎます。これらの整合性チェックが量子耐性を持つ、ということです。

医療機器・産業制御・金融インフラなど、10年以上の長期運用を前提とするシステムを管理している人は、今から移行計画を考え始めておく必要があります。「2030年になってから慌てる」では遅いですし、鍵・証明書の配布インフラの整備には時間がかかります。

---

## 5. Cisco Unified CM CVE-2026-20230：パッチ→PoC→実攻撃まで「数週間」

締めは今週いちばん「今すぐ動いてほしい」ネタです。

Cisco Unified Communications Manager（企業のIP電話基盤）のWebDialerコンポーネントに、SSRF（Server-Side Request Forgery）脆弱性 **CVE-2026-20230** が発見されました。CVSS v3.1スコアは8.6（High）ですが、Cisco自身が公式の深刻度評価を **Critical** に格上げしています。

認証不要、ネットワーク到達性があればゼロクリックで攻撃が完結する、という性質です（ [Cisco公式アドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-cucm-ssrf-cXPnHcW) ）。

### 攻撃チェーンの怖さ

攻撃は3段階で進みます。

まず、WebDialerのURL処理の不備を利用してシステムの **内部ホスト名を取得** します。次に、そのホスト名を使って `file://` URIを含む細工済みリクエストを送り、OSファイルシステムへの **任意ファイル書き込み** を実現します。最後に、cronジョブや設定ファイルのパスへ書き込むことで **rootへの権限昇格** を達成する、という流れです。

実際の攻撃観測では `/tmp/cve-2026-20230-test.txt` というファイルの書き込みが試みられており、脆弱なシステムをフィンガープリントする偵察フェーズとみられています（ [BleepingComputer](https://www.bleepingcomputer.com/news/security/cisco-unified-cm-sme-flaw-cve-2026-20230-now-exploited-in-attacks/) ）。

### パッチ公開から実攻撃まで「数週間」

タイムラインが現代のセキュリティ対応のリアルを示しています。

- **2026年6月3日**：Ciscoがパッチ（Unified CM 14SU6）を公開。「悪意のある利用は確認していない」と表明
- **直後**：SSD Secure DisclosureがPoCコードを公開
- **6月下旬**：脅威インテリジェンス企業Defusedのハニーポットが実攻撃を検知

PoCが世に出てからハニーポットにヒットするまで、かなりのスピードです。「パッチが出た、いつか対応しよう」が通用しない時代になっています。EPSSスコア（悪用の蓋然性）は20.442%で **97パーセンタイル** 、つまり全CVEの上位3%に入る高さです（ [GitHub Advisory](https://github.com/advisories/GHSA-fcv7-pchj-75c2) ）。

### 今すぐできる対応

WebDialerが有効化されているかどうかが攻撃の前提条件です。デフォルトでは無効ですが、エンタープライズ環境では「クリック・トゥ・コール」機能として有効化されているケースが多いです。

**パッチを当てる**: リリーストレイン14の場合は14SU6が提供済みです。トレイン15は15SU5（2026年9月予定）まで暫定COPパッチで対応します。

**WebDialerを無効化する**: 業務上不要なら「Cisco Unified Serviceability」→「Control Center - Feature Services」→「CTI Services」でサービスを停止するのが最も確実な緩和策です。

侵害の痕跡（IoC）確認として、`/tmp/cve-2026-20230-test.txt` のようなファイルが生成されていないかをチェックするのも有効です。

---

## まとめ：「安全なはずのもの」ほど定期的に疑ってみる

今週の5本に共通するテーマを振り返ると、全部「普段は安全だと思って疑わずに使っているもの」が揺さぶられた話でした。

CI/CDパイプライン、コンパイラのチューニング定数、ファームウェア更新ツール、量子コンピュータへの備え、IP電話の基盤。どれも「インフラ」として目立たず、でも動き続けているものです。

Cordycepsが示したのは「設定を書いたときは正しかったつもり」が10年後にリスクになる可能性です。GCCのパッチが示したのは「30年前のパラメータが今も影響している」という事実です。fwupdが示したのは「守る側のツール自体が穴を持ちうる」という皮肉な現実です。

「信頼しているものほど、たまに手で確認してみる」という習慣が、これからますます大事になると思います。次に見直すのは、あなたのリポジトリのGitHub Actionsかもしれないし、今月当たったパッチの適用状況かもしれません。

それでは、また次回。皆さんの環境が穏やかでありますように。

---

## 参考文献

- Cordyceps CI/CD攻撃（The Hacker News）: https://thehackernews.com/2026/06/cordyceps-cicd-flaws-expose-300-github.html
- actions/checkout v7リリース（GitHub Changelog）: https://github.blog/changelog/2026-06-18-safer-pull_request_target-defaults-for-github-actions-checkout/
- pull_request_target 安全な使用方法（GitHub Docs）: https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target
- GCC x86 Mispredict コスト修正（Phoronix）: https://www.phoronix.com/news/GCC-x86-Generic-Mispredict
- fwupd 2.0.21リリースノート: https://github.com/fwupd/fwupd/releases/tag/2.0.21
- Project Glasswing（Anthropic）: https://www.anthropic.com/glasswing
- Schneier on Glasswing: https://www.schneier.com/blog/archives/2026/06/anthropics-project-glasswing-update.html
- Linux 7.2 IMA/EVM ML-DSA対応（Phoronix）: https://www.phoronix.com/news/Linux-7.2-Integrity
- Cisco CVE-2026-20230 公式アドバイザリ: https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-cucm-ssrf-cXPnHcW
- Cisco Unified CM実攻撃報道（BleepingComputer）: https://www.bleepingcomputer.com/news/security/cisco-unified-cm-sme-flaw-cve-2026-20230-now-exploited-in-attacks/
- 動画: https://www.youtube.com/watch?v=ijAwwEKNvr4
