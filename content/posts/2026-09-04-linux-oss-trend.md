---
title: "疑わない場所ほど壊れている（2026/9/4 Linux・OSSトレンド）"
date: 2026-09-04T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "SonicWall", "Kestra", "Starlette", "FastAPI", "AIエージェント", "Git", "Bottles", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

今日の5本を並べて、共通しているものを探しました。出てきたのは「疑っていない場所」です。

社内ネットワークの入口に置いた VPN アプライアンス。ワークフローエンジンの認証フィルター。Web フレームワークが組み立ててくれるリクエスト URL。そして、リポジトリを開いた瞬間に走る `git status` 。どれも「そこは大丈夫だろう」と一度も点検しないまま通り過ぎている場所です。

今日はその全部が、順番に壊れました。しかも、こちらの操作を必要としない形で。クリックも、プロンプト入力も、ログインすら要らない。攻撃者が一度リクエストを投げるか、フォルダをひとつ渡すだけで成立してしまいます。

途中に1本だけ、平和なリリースの話を挟みます。息継ぎに使ってください。

{{< youtube "lJ6a4cOEnkU" >}}

## 1. SonicWall SMA1000 — 未認証のまま管理コンソールに届く経路

重い話から始めます。企業や公的機関がリモートアクセスの入口として使う SonicWall SMA1000 シリーズに、2件の脆弱性が同時に公開されました。しかも、すでに悪用されています。

1件目が [CVE-2026-83548](https://nvd.nist.gov/vuln/detail/CVE-2026-83548) 。NVD の確定値は CVSS v3.1 で **10.0（Critical）** 、ベクトルは `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` です。ネットワーク越し・低複雑度・権限不要・ユーザー操作不要が揃い、影響が自システムの外へ及ぶ（`S:C`）評価まで付いています。中身はサーバーサイドリクエストフォージェリ（SSRF）で、エンドユーザー向けの SSL-VPN ポータル「WorkPlace」に残っていた転送経路を突くと、本来は分離されているはずの管理コンソール「AMC（Appliance Management Console）」へリクエストが中継されてしまう、というものです。

2件目が [CVE-2026-83549](https://nvd.nist.gov/vuln/detail/CVE-2026-83549) 、AMC 側の OS コマンドインジェクションです。こちらは CVSS 7.8 で、ベクトルは `AV:L/AC:L/PR:L` 。単体では「管理者としてログインできる人が悪さをする」程度の位置づけで、正直それほど怖くありません。

怖いのは組み合わせです。[Rapid7 の解析](https://www.rapid7.com/blog/post/etr-critical-sonicwall-sma1000-vulnerabilities-cve-2026-83548-cve-2026-83549-exploited-in-the-wild/)はアドバイザリを引いて「SSRF の CVE-2026-83548 を利用することで、攻撃者は事前の認証なしに CVE-2026-83549 を悪用し、任意の OS コマンドを実行しうる」と書いています。1件目で認証の前提を外し、2件目で手を動かす。7.8 が「認証済み前提」でなくなった瞬間に、10.0 と同じ重さになるという構図です。なお「root 権限で」と書いている記事も見かけますが、一次情報で確認できるのは「任意の OS コマンド実行」までなので、ここでは踏み込みません。

影響を受けるのは SMA 6210 / 7210 / 8200v と CMS で、Rapid7 の整理によれば脆弱なのは 12.4.3-03453 以下と 12.5.0-02835 以下、修正版は 12.4.3-03526 および 12.5.0-02952 です。SMA 100 シリーズやファイアウォール製品は対象外です。

そして日付の話をします。CISA の[既知悪用脆弱性（KEV）カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)を引くと、両 CVE とも追加日は2026年9月2日、連邦政府機関の対応期限は **2026年9月5日** 。この記事を書いている翌日です。KEV の期限は通常もっと長く取られるので、3日というのは「いま進行中」という判断が透けて見えます。[SonicWall の製品ノーティス](https://www.sonicwall.com/support/notices/product-notice-sma-1000-series-affected-by-multiple-vulnerabilities/kA1VN000001nv6D0AQ)も、ホットフィックス適用に加えてフォレンジック調査を求め、侵害の痕跡が見つかった場合はハードウェアの再イメージング（仮想アプライアンスなら再デプロイ）、全ユーザー・管理者のパスワード変更、TOTP トークンのリセットまで指示しています。「パッチを当てて終わり」ではない、という前提で動く必要があります。

## 2. Kestra OSS — `endsWith` 一語で CVSS 10.0

次はワークフローエンジンの Kestra です。こちらは「コードの一行がそのまま満点の脆弱性になる」という、教材のような事例でした。

[CVE-2026-49869](https://nvd.nist.gov/vuln/detail/CVE-2026-49869) の NVD 確定値は CVSS v3.1 で 10.0、ベクトルは `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` 。原因の説明が身も蓋もなくて、[脆弱性データベースに記載された原文](https://vulnerability.circl.lu/vuln/CVE-2026-49869)はこう書いています。「Kestra OSS の AuthenticationFilter は、公開設定エンドポイントを Basic 認証から除外するために `request.getPath().endsWith("/configs")` を使っている。このチェックが完全一致ではなく末尾一致であるため、最後のセグメントが configs である API パスはすべて認証を完全にバイパスできる」。

設定用のエンドポイントだけ認証を免除したかった。そこまでは分かります。ただ判定を「末尾が `/configs` かどうか」にしてしまったため、`/api/v1/{tenant}/flows/{namespace}/configs` のような、末尾さえ合っていれば何でも通るようになりました。テナント名もネームスペースも攻撃者が自由に決められるので、バイパス経路は事実上無限に作れます。

ワークフローエンジンでこれが起きるのが最悪です。Kestra はスクリプト実行系のプラグインを標準で備えているので、認証を抜けた先にあるのは「任意のワークフローを作って、実行する」機能そのもの。認証バイパスがそのままリモートコード実行になります。影響バージョンは 1.0.45 未満、および 1.1.0 以上 1.3.21 未満で、修正版は 1.0.45 と 1.3.21 です。

実際の被害も観測されています。[Microsoft のセキュリティブログ](https://www.microsoft.com/en-us/security/blog/2026/08/26/when-ai-infrastructure-becomes-target-securing-gateways-control-points/)は、未認証の攻撃者がログイン機構を迂回して悪意あるワークフローを定義し、Kestra ワーカーからシェルセッションを起こし、マウントされていた Docker ソケット経由でコンテナのメタデータへ触り、最終的に「RandomX の MSR チューニング付きで XMRig v6.26.0 を Monero のマイニングプールへ向けて起動した」ところまで記録しています。データパイプラインのハブが、そのまま他人のマイニング基盤として使われたわけです。CISA も KEV に追加していて、こちらの対応期限も9月5日です。

「一行の修正で塞がる」ことと「一行のミスで開く」ことは、当然ながら同じことなのですよね。

## 3. Bottles 67.1 — 壊して、2日で直す

ここで一息。Linux 上で Windows アプリを管理する Bottles が、[バージョン 67.1 をリリースしました](https://github.com/bottlesdevs/Bottles/releases/tag/67.1)。公式のリリースノートは実にあっさりしていて、「UMU ランタイムと cpak のナビゲーションを修復」の一行だけです。

これは前バージョンの後始末です。[67.0 は2026年8月31日のリリース](https://github.com/bottlesdevs/Bottles/releases/tag/67.0)で、ProtoSoda 向けの Adaptive Launch 有効化やライブラリ操作の改善が入っていたのですが、同時に追加されたサンドボックスが UMU の起動を壊してしまいました。それを2日で修正したのが 67.1、という流れになります。「壊してすぐ直す」が回っているのは、健全な兆候だと思います。

性能面の目玉は 67.0 から続く Adaptive Launch です。[Linuxiac の解説](https://linuxiac.com/bottles-67-1-improves-windows-app-startup-performance-on-linux/)によれば、この機能は「プログラムが起動のあいだに何を必要とするかを記憶し、Wine が要求する前にそれらのファイルを準備しておく」もの。効果の数字も同記事にあります。「プロジェクトのリリース計測によると、コールドスタート時間の中央値が 3.38% 改善し、メジャーページフォルトの中央値は 16 から 1 に減少した」。

この2つの数字、並べると印象が食い違います。ページフォルト 94% 減はいかにも効いていそうなのに、体感に近いコールドスタート時間は 3.38% 短縮。どちらも同じ計測の話です。なお、これらの数値は GitHub のリリースノートには載っておらず、Linuxiac がプロジェクト側の計測として紹介している形なので、その前提で受け取るのがよさそうです。実際の効果はアプリと搭載ハードウェアに左右される、という但し書きも同記事に付いています。

同記事は他にも、サンドボックス化された UMU ゲームが既定でネットワークなしに起動するようになったこと、UMU 初回起動時に Steam Runtime 4 を自動ダウンロードできるようになったこと、そして 64bit Windows の OpenXR アプリを「SteamVR を必要とせずに」WiVRn や Monado といった Linux 側の OpenXR ランタイムへ直接つなげられるようになったことを挙げています。VR 周りは「Steam が要らなくなった」ではなく「SteamVR を経由しなくてよくなった」なので、そこは区別しておきます。

## 4. Starlette「BadHost」— たった1文字で認証をすり抜ける

平和な話はここまでです。4本目は Python の非同期 Web フレームワーク Starlette、つまり FastAPI の土台にある層の話になります。

[GitHub Security Advisory GHSA-86qp-5c8j-p5mr](https://github.com/advisories/GHSA-86qp-5c8j-p5mr) は、この問題（[CVE-2026-48710](https://nvd.nist.gov/vuln/detail/CVE-2026-48710) 、通称 BadHost）を「Host ヘッダーの検証欠如により `request.url.path` が汚染され、パスベースのセキュリティチェックがバイパスされる」と要約しています。深刻度は Moderate、CVSS は 6.5。脆弱なのは 1.0.0 以下で、修正版は 1.0.1 です。

仕組みは拍子抜けするほど単純です。Starlette はリクエスト URL を組み立てるとき、`Host:` ヘッダーの値を検証せずに使います。そこで攻撃者が `Host: api.example.com/health?x=` のように、ホスト名の後ろに1文字余計なものを足したうえで `/admin` にリクエストを送ると、再構成された URL は `https://api.example.com/health?x=/admin` になり、`request.url.path` は `/health` を返します。認証ミドルウェアが「`/health` は認証不要」というホワイトリストで判定していれば、そこを素通り。一方、実際にリクエストを配送する ASGI ルーターは生のパス、つまり `/admin` を見ます。チェックする側と配送する側が別の値を見ている、という食い違いが本質です。

CVSS 6.5 は控えめに見えます。ただ、Starlette は FastAPI をはじめ、LLM 推論サーバーやエージェント基盤、MCP サーバーの実装まで広く土台に使われている層です。公式の開示サイト [badhost.org](https://badhost.org/) は、MCP の仕様が OAuth のディスカバリーエンドポイントを認証なしで公開するよう定めていることに触れ、攻撃者にとって信頼できる悪用経路になると指摘しています。認証不要パスが仕様として保証されている場所に、認証不要パスを詐称できる欠陥が重なるわけです。

CISA の判断もスコアより実害を見ています。KEV カタログでは9月2日に追加され、対応期限は9月16日。同じ日に AI ゲートウェイの LiteLLM（CVE-2026-59822）も同じ期限で並んでいます。ここは Kestra や SonicWall の9月5日とは別枠なので、混同しないよう注意してください。

対応は `starlette` を 1.0.1 以上へ上げること。加えて、パスで認証可否を判断するミドルウェアを自作している場合は、参照先を `request.url.path` から生パスの `request.scope["path"]` に変えておくのが確実です。

## 5. GitSpawn — フォルダを開いた瞬間に、エージェントが撃つ

最後は、この記事を読んでいる人ほど当事者になりやすい話です。

Manifold Security が公開した [GitSpawn](https://www.manifold.security/blog/ai-coding-agents-git-hijack) は、悪意ある `.git/config` を仕込んだリポジトリを AI コーディングエージェントで開くだけで、任意のコマンドが実行されてしまう脆弱性クラスです。使われるのは Git の `core.fsmonitor` 、大規模リポジトリ向けにヘルパープログラムを指定できる性能最適化の設定で、Git はこの値をリポジトリ自身の `.git/config` から読みます。つまり、リポジトリのほうが「このコマンドを実行してね」と指定できてしまう。

そこに、エージェント側の親切さが噛み合います。Manifold の表現を借りると「Claude Code でフォルダを開くと、あなたが何かを打ち込む前に `git status` が走る。ワークスペースの信頼確認プロンプトより前に」。文脈を把握するための先回りが、そのまま発火装置になります。同社は Grok Build が最初のキー入力時に、Qwen Code が認証完了前に、Hermes Agent が最初のメッセージ送信時に、goose が `goose review` の実行時に発火することを確認しています。プロンプトの内容は関係ありません。

救いは配送経路です。Manifold は「敵対的な URL をクローンしても何も起きないし、fetch や pull でも起きない」と明記しています。`git clone` ではローカルの `.git/config` が生成し直されるためです。危ないのは「クローンではなくディレクトリごと移動してくる」経路、つまり ZIP アーカイブ、USB メモリ、共有ドライブ、同期フォルダです。コードレビューを頼まれてフォルダを受け取る、有償テンプレートを展開する——そういう日常の動線が該当します。

修正状況は製品によってまちまちです。Claude Code は `core.fsmonitor` 経由の問題を 2.1.196 で修正済みですが、別コードパス（`/ultrareview`）については 2.1.252 時点でも未修正だと報告されています。GitHub Copilot CLI は [GHSA-9ccr-r5hg-74gf](https://github.com/advisories/GHSA-9ccr-r5hg-74gf)（CVE-2026-45033、CVSS v4.0 で 8.5）として 1.0.43 で修正、goose は [CVE-2026-72718](https://nvd.nist.gov/vuln/detail/CVE-2026-72718)（CVSS v4.0 で 7.0）として 1.44.0 で修正されています。一方、公開時点で未修正のまま残っているのが Qwen Code・Grok Build・Claude Code の当該パス・Hermes Agent の4件。Hermes Agent については「5つのチャネルで6回連絡したが、非公開のアドバイザリはトリアージすらされなかった」と Manifold は書いており、最終的に CVE-2026-71963 を採番したうえで公表に踏み切っています。

いま個人でできる対策は3つです。ZIP や共有ドライブで受け取ったリポジトリは、エージェントで開く前に `.git/config` を目で見る。信頼できない配布物は、可能なら自分で `git clone` し直す。そして使っているエージェントを最新版に上げる。ベンダー向けには、Manifold が「コンテキスト収集で走らせる git 呼び出しの設定を無害化する。たとえば `git -c core.fsmonitor=false status` のように」と推奨しています。

## まとめ

5本を振り返ると、壊れた場所はどれも「わざわざ疑う理由がなかった場所」でした。

VPN アプライアンスの内部経路は分離されている前提でした。認証フィルターは通っている前提でした。フレームワークが組み立てた URL は正しい前提でした。エージェントが走らせる `git status` は、ただの情報収集の前提でした。前提はどれも合理的で、疑わなかったことを責める気にはなりません。

それでも今日の5本は、共通してひとつのことを言っています。「誰も見ていない前提」は、時間が経つと勝手に腐る。SonicWall は同じ製品で似たパターンを繰り返し、Claude Code は一度直した挙動が別のパスで再発しました。一度点検した場所も、実装が入れ替われば前提ごと入れ替わります。

さしあたって今日やる価値があるのは、たぶん2つです。KEV の期限が明日に迫っている SMA1000 と Kestra を使っているなら、今すぐバージョンを確認すること。そして次に誰かから ZIP でリポジトリを受け取ったとき、エージェントに渡す前に `.git/config` をのぞく癖をつけること。

あなたの環境で「そこは大丈夫」と思って一度も開いていない設定ファイルは、どれでしょうか。

## 参考リンク

- [CVE-2026-83548 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-83548) / [CVE-2026-83549 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-83549)
- [Rapid7 — SonicWall SMA1000 の脆弱性解析](https://www.rapid7.com/blog/post/etr-critical-sonicwall-sma1000-vulnerabilities-cve-2026-83548-cve-2026-83549-exploited-in-the-wild/)
- [CISA — Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [CVE-2026-49869 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-49869) / [Microsoft Security Blog — When AI infrastructure becomes the target](https://www.microsoft.com/en-us/security/blog/2026/08/26/when-ai-infrastructure-becomes-target-securing-gateways-control-points/)
- [Bottles 67.1 リリースノート](https://github.com/bottlesdevs/Bottles/releases/tag/67.1) / [Linuxiac の解説記事](https://linuxiac.com/bottles-67-1-improves-windows-app-startup-performance-on-linux/)
- [GHSA-86qp-5c8j-p5mr — Starlette](https://github.com/advisories/GHSA-86qp-5c8j-p5mr) / [badhost.org](https://badhost.org/)
- [Manifold Security — GitSpawn](https://www.manifold.security/blog/ai-coding-agents-git-hijack) / [GHSA-9ccr-r5hg-74gf — GitHub Copilot CLI](https://github.com/advisories/GHSA-9ccr-r5hg-74gf)
