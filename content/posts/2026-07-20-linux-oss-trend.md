---
title: "5億サイトの急所、カーネルの隙間、2.8兆のAI——便利さの裏に潜む境界条件"
date: 2026-07-20T00:00:00+09:00
draft: false
tags: ["WordPress", "セキュリティ", "VS Code", "Blender", "Kimi K3", "Linux"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

WordPressコアを突く無認証チェーンRCEに、カーネル6.0以降に広く効く[境界外書き込み](https://nvd.nist.gov/vuln/detail/CVE-2026-53362)。今日はそんな物騒なニュースが2本も飛び出した、なかなかヘビーな一日でした。ただ、どちらも見出しだけが独り歩きしやすい案件なので、一次情報で「どこまでが確定していて、どこからが条件付きなのか」をきちんと切り分けながら、この一週間のLinux/OSSトピックを5本まとめます。

{{< youtube "zAiRFFe8hLY" >}}

## 1. WordPressコアに無認証チェーンRCE「wp2shell」——CVE-2026-63030＋CVE-2026-60137

2026年7月18日、[REST APIバッチルート混乱の脆弱性 CVE-2026-63030](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-ff9f-jf42-662q)が公開されました。報告したのは[Assetnote / Searchlight Cyber](https://slcyber.io/assetnote-security-research-center/)のAdam Kues氏で、この「バッチルート混乱」を[SQLインジェクション CVE-2026-60137](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-fpp7-x2x2-2mjf)と連鎖させると[リモートコード実行に至る](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-ff9f-jf42-662q)——というのが、公開PoC「wp2shell」の骨子です。公式アドバイザリは "a REST API batch-route confusion weakness, which combined with an SQL injection issue leads to Remote Code Execution" と明記しており、深刻度は**Critical**に分類されています。

ここは誤解されやすいので丁寧に書きます。連鎖の一方であるSQLインジェクション（CVE-2026-60137）は、Adam Kues氏とは**別のチーム（TF1T、dtro、haongo各氏）**が報告したもので、単体では深刻度**Moderate**です。原因は`WP_Query`の`author__not_in`パラメータで、[配列入力を前提とした整数正規化処理が文字列入力の場合にスキップされていた](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-fpp7-x2x2-2mjf)、という報告内容です。もう一方のバッチAPIエンドポイント側では、サブリクエストのエラー処理でインデックスがずれ、本来届くはずのないハンドラにリクエストが渡ってしまう。この2つが噛み合うと認証を回避して管理者相当の操作に踏み込める、という流れになります。

一点、見出しで踊りやすい「プラグインなしの素の環境に、匿名HTTPだけで無条件RCE」という表現には注意が必要です。公開PoC単体でのコード実行にはMySQLの設定条件などが絡むとの検証報告もあり（Flatt Securityによる検証）、いわゆる「デフォルト構成での無条件RCE」は同社の独自検証にもとづく指摘です。一次アドバイザリが断定しているのはあくまで「連鎖によるRCE成立」までで、そこは切り分けて受け止めてください。

この記事を書きながら、恥ずかしながら自分のブログ環境も慌てて確認しました。自動更新をオンにしていたので事なきを得ましたが、正直ヒヤッとしました。WordPressは異例の強制自動更新を対象バージョンへ即日プッシュし、修正版を配布しています。整理すると、連鎖成立のCritical（CVE-2026-63030）は[6.9.0–6.9.4／7.0.0–7.0.1が影響、6.9.5／7.0.2で修正](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-ff9f-jf42-662q)。SQLインジェクション単体（CVE-2026-60137）は[6.8.0以降が影響し、6.8.6／6.9.5／7.0.2で修正](https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-fpp7-x2x2-2mjf)——つまり6.8.6はSQLi単体（Moderate）への手当てで、連鎖Criticalが成立するのは6.9系以降という関係です。PoC公開後数時間で野生の悪用の兆候が観測されたとの報告（watchTowr）もあり、自動更新を無効化した大規模カスタマイズサイトが今もっとも危うい立場にあります。該当環境は即時アップデートを、難しい場合はWAFで`/wp-json/batch/v1`へのリクエストをブロックする対応を検討してください。

## 2. VS Code 1.129——Agent HostでAIエージェントをプロセス分離

[2026年7月15日リリースのVS Code 1.129](https://code.visualstudio.com/updates/v1_129)が、Copilot・Claude・Codexなどのエージェントを専用バックグラウンドプロセス「[Agent Host](https://code.visualstudio.com/updates/v1_129)」上で動かす新アーキテクチャを導入しました。公式は "a dedicated process that runs agent harnesses such as Copilot, Claude, and Codex" と説明しています。これまではエージェントセッションがエディタのメインウィンドウと密結合していたため、モデルのクラッシュや長時間推論のブロッキングがエディタ全体に波及していましたが、この分離でその問題が解消されます。

副産物として、セッションのライフサイクルが特定のウィンドウに縛られなくなり、[同一のエージェントセッションを複数のVS Codeウィンドウから接続・描画できる](https://code.visualstudio.com/updates/v1_129)ようになりました（"the same session can be connected to and rendered from multiple VS Code windows at once"）。フロントエンドとバックエンドを別ウィンドウで開いて作業するスタイルの開発者にはうれしい変更で、個人的にはこれがいちばん実務で助かりそうだなと思っています（AIが固まってエディタごと巻き込まれる、あの絶望感を知っている人には伝わるはず）。設定は`chat.agentHost.enabled`から[有効化するオプトイン方式](https://code.visualstudio.com/updates/v1_129)で、まだ段階的ロールアウト中の実験的機能です。組織ポリシー（organization level）で管理される場合があるため、環境によっては管理者の許可が要る点も押さえておきましょう。

## 3. Blender 5.2 LTSリリース——XPBDシミュレーションとテクスチャキャッシュ

ここで少し話題を変えます。[2026年7月14日、Blender 5.2 LTSがリリースされました](https://www.blender.org/download/releases/5-2/)。5.xシリーズ初のLTS版として、2028年7月まで2年間のバグフィックス・セキュリティパッチが保証されます。

目玉はGeometry Nodes上で動くXPBD（eXtended Position Based Dynamics）ソルバーによる実験的な布・髪シミュレーションで、HoudiniのVellumソルバーと同系統の手法です。もうひとつの注目は[Cyclesの新しいテクスチャキャッシュ](https://code.blender.org/2026/05/cycles-texture-cache/)で、画像ごとに`blender_tx/`フォルダへ最適化済みの`.tx`ファイルを生成し、レンダリングに必要なタイルと解像度だけを読み込む仕組みです。ここは数字が一人歩きしやすいので一次情報どおりに書くと、[削減効果はシーン依存](https://code.blender.org/2026/05/cycles-texture-cache/)（"The memory saving is highly scene-dependent"）で、[標準デモシーンでは最大80%の削減、最大の効果はBistroシーン](https://code.blender.org/2026/05/cycles-texture-cache/)——という上限値です。どんなシーンでも一律に効くわけではなく、[わずかな描画性能の低下とディスク使用量の増加を伴う](https://code.blender.org/2026/05/cycles-texture-cache/)（"a small rendering performance impact and increased disk space usage"）トレードオフがある点も、あわせて知っておきたいところ。4K/8K/16Kのような大解像度でタイルレンダリングに入ると、テクスチャキャッシュのメモリ使用量が解像度によらずほぼ一定に保たれる、という性質も面白いです。無料でここまでやってくるBlenderには毎回驚かされますが、今回のLTSはとくに気合が入っている印象で、長期プロジェクトを抱えるスタジオには格好の移行の節目になりそうです。

## 4. Kimi K3リリース——2.8兆パラメータのスパースMoE

中国Moonshot AIが2026年7月16日、大型言語モデル「[Kimi K3](https://www.kimi.com/blog/kimi-k3)」をAPIとWebアプリで即日公開しました。[総パラメータ数は2.8兆](https://www.kimi.com/blog/kimi-k3)に達するスパースMixture-of-Experts設計で、[896あるエキスパートのうち推論時に選ばれるのは16個だけ](https://www.kimi.com/blog/kimi-k3)という構成です（「活性化パラメータ約500億」という数字も出回っていますが、これは公式ブログには明記がなく、トークンあたり16/896という比率からの推計値なので、参考程度に）。性能面では、公式ブログは自らを "trails the most powerful proprietary models, Claude Fable 5 and GPT 5.6 Sol"（最上位のプロプライエタリモデルであるClaude Fable 5とGPT 5.6 Solには及ばない）と位置づけています。「Artificial Analysis社の評価でElo 1547を記録し世界3位相当」といった具体値は、第三者ベンチマークで報じられているもので公式一次には見当たらないため、順位の断定は避けておきます。

[フルモデルの重みは7月27日までにオープンウェイトとして公開予定](https://www.kimi.com/blog/kimi-k3)です。価格は前世代から引き上げられ、[100万トークンあたり入力がキャッシュミス$3.00／キャッシュヒット$0.30、出力$15.00](https://www.kimi.com/blog/kimi-k3)。「安価な中国AI」という従来のイメージからの転換が鮮明になっています。2.8兆パラメータという規模を考えると、個人が手元でフルモデルを動かすのは当面難しそうですが、コンテキスト100万トークンを活かしたコード全体の解析用途などでは早くも実用評価が始まっています。オープンウェイトなのに個人では動かせない、というこのねじれ、皆さんはどう感じますか。

## 5. Linux IPv4/IPv6 OOB書き込み——CVE-2026-53366/CVE-2026-53362

締めはカーネルの話です。LinuxカーネルのIPv4出力パス（`__ip_append_data()`／`net/ipv4/ip_output.c`）に[境界外書き込み CVE-2026-53366](https://nvd.nist.gov/vuln/detail/CVE-2026-53366)が見つかり、IPv6側（`__ip6_append_data()`／`net/ipv6/ip6_output.c`）にも[同じパターンのバグ CVE-2026-53362](https://nvd.nist.gov/vuln/detail/CVE-2026-53362)が存在することが分かりました。

原因は「fraggapの計算忘れ」です。前のソケットバッファから引き継ぐ断片の隙間データ（fraggap）を、確保する線形領域のサイズに加算し忘れていたため、後続のコピー処理がバッファの末端を越えてしまう。IPv6側のコミットには、非特権ユーザーが`MSG_MORE`と`MSG_SPLICE_PAGES`を同時指定して[UDPv6ソケットで発火できる](https://nvd.nist.gov/vuln/detail/CVE-2026-53362)と明記され（"An unprivileged user can trigger this via a UDPv6 socket using MSG_MORE together with MSG_SPLICE_PAGES"）、コピーが`skb->end`を越えて後続の`skb_shared_info`を[書き潰す](https://nvd.nist.gov/vuln/detail/CVE-2026-53362)（"the copy writes past skb->end into the trailing skb_shared_info"）と説明されています。

ここは大事な線引きをします。一次情報が示しているのは**この境界外書き込み（メモリ破壊）まで**で、「これを起点にコンテナエスケープしてホストのroot権限を取得した」といった実証は、一次情報（NVD／修正コミット）では確認できませんでした。深刻度についても、NVDは[両CVEともCVSS未評価（Awaiting Analysis）](https://nvd.nist.gov/vuln/detail/CVE-2026-53366)の段階で、採番元kernel.org(CNA)が暫定的にCVSS 3.1で7.8 HIGH（`AV:L`＝ローカル起点）を付けているのが現状です。検証済みの実用PoCも公開されていません。地味に見えて厄介ではありますが、「今日いちばん実務に響く」と煽るには材料がまだ足りない、というのが正直なところです。

修正済みバージョンは6.6.144／6.12.95／6.18.38／7.1.3系などです。ゼロコピー最適化のために追加された仕組みが、古くからあった別の処理パスとの組み合わせで見落とされていた——という構図で、機能を足した先に隙間が空く典型例だなと思いながら読みました。コンテナホストやマルチテナント環境の管理者は、深刻度の最終評価を待つよりも、素直にアップデートしておくのが無難でしょう。

## まとめ

WordPressのバッチAPIバグも、Linuxのfraggap計算忘れも、元をたどれば機能を豊かにするための実装変更から生まれたものでした。便利にしよう、速くしようとした先に、思わぬ隙間が空く。そして今日の5本は、どれも「見出しの派手さ」と「一次情報が保証する範囲」に温度差がある案件でもありました。煽りに流されず、確定と条件付きを切り分けて手を打つ——皆さんの手元の環境、カーネルとWordPressのバージョンは大丈夫でしょうか。

## 主要参照（一次情報）

- WordPress CVE-2026-63030（連鎖RCE・Critical）: https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-ff9f-jf42-662q
- WordPress CVE-2026-60137（SQLi・Moderate）: https://github.com/WordPress/wordpress-develop/security/advisories/GHSA-fpp7-x2x2-2mjf
- VS Code 1.129 リリースノート: https://code.visualstudio.com/updates/v1_129
- Blender 5.2 LTS / Cycles Texture Cache: https://www.blender.org/download/releases/5-2/ ／ https://code.blender.org/2026/05/cycles-texture-cache/
- Kimi K3（Moonshot AI公式）: https://www.kimi.com/blog/kimi-k3
- Linux CVE-2026-53366（IPv4）: https://nvd.nist.gov/vuln/detail/CVE-2026-53366
- Linux CVE-2026-53362（IPv6）: https://nvd.nist.gov/vuln/detail/CVE-2026-53362
