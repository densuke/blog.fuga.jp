---
title: "数字が動く前に、もう起きていた — vCenter侵入・15年前のPC復活・macOS認証突破（2026/8/20 Linux・OSSトレンド）"
date: 2026-08-20T00:00:00+09:00
draft: false
tags: ["セキュリティ", "VMware", "vCenter", "ESXi", "Linux カーネル", "スケジューラ", "PHP", "macOS", "ランサムウェア", "CVE", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

公式のスコアが引き上げられたとき、公式の被害組織数が更新されたとき、公式のパッチが出たとき。私たちはついその日付を「事件が始まった日」として読んでしまいます。でも今回並べた5本を眺めていると、どれも数字が動くよりずっと前に、現場では事態が動き終わっていました。パッチ公開の直後から悪用が始まっていた仮想化基盤、スコアが2ポイント以上引き上げられる前から乗っ取られていた Mac、勧告が更新される前に静かに1.5倍を超えて広がっていた被害。公式の数字や発表が動くころには、現場はもう次の局面に進んでいる——そんな一日をお届けします。

{{< youtube "Ot-ilwp7UWM" >}}

## 1. 仮想化基盤、パッチ前から侵入されていた — vCenter の CVE-2026-59310

まずは今日いちばん重い話から。VMware vCenter の Syslog サーバコンポーネントにディレクトリトラバーサルの脆弱性（CVE-2026-59310）が見つかり、これを悪用した攻撃で、47カ国361拠点の ESXi ホストがランサムウェアに侵されました。CISA は 2026年8月18日にこの CVE を KEV（既知の悪用された脆弱性）カタログへ追加し、連邦行政機関の修正期限は 2026年8月21日、つまり明日です。

[NVD のエントリ](https://nvd.nist.gov/vuln/detail/CVE-2026-59310)によれば CVSS v3.1 スコアは 9.8 Critical、ベクトルは `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`。ネットワークから届けば権限もユーザー操作も要らずに任意コードが動く、いちばん条件の緩い部類です。分類は CWE-22（ディレクトリトラバーサル）、[GitHub Advisory Database の登録](https://github.com/advisories/GHSA-v2gp-49gj-2c9f)は GHSA-v2gp-49gj-2c9f で、公開日は 2026年7月30日。

ここで引っかかるのが日付の並びです。パッチが出たのは 2026年7月29日。ところがリリース直後から積極的な悪用が観測されています。パッチが出てから慌てて解析して攻撃コードを書いた、というテンポではありません。攻撃者はパッチ公開より前にこの穴を把握していた可能性が高い、と見られています。公式のアナウンスは、事件の始まりではなく途中経過の報告だったわけです。

攻撃の組み立ても入念でした。侵入の入口に使われたのは、実は今回の CVE ではなく別の認証バイパス脆弱性（[CVE-2026-59309](https://nvd.nist.gov/vuln/detail/CVE-2026-59309)）です。攻撃者はまずこれで vCenter に「adminuser」という管理者権限のバックドアアカウントを作り、そのうえで CVE-2026-59310 の Syslog パストラバーサルを使って「linuxFile」というバックドアをホスト上に書き込みます。あとは Cron ジョブで `reverse_ssh` バイナリを定期起動させ、外部の C2 サーバーへ接続を張り続ける。そこから vSphere API 経由で配下を偵察し、ESXi ホストへ Babuk 派生のランサムウェアを投下する、という流れです。暗号化されたファイルには `.babyk` という拡張子が付きます。

```
CVE-2026-59309（認証バイパス）
  └→ 管理者アカウント「adminuser」作成
CVE-2026-59310（Syslog ディレクトリトラバーサル）
  └→ バックドア「linuxFile」書き込み
       └→ Cron ジョブで reverse_ssh 起動
            └→ C2 サーバーへ接続
vSphere API 偵察
  └→ ESXi ホストへ Babuk 派生（.babyk）展開
```

いちばん薄ら寒いのは後始末の部分です。2026年8月14日、攻撃者が GitHub 上のリポジトリに「`/tmp` の中で24時間以上経過したファイルを自動削除するツール」を置いていたことが確認されました。フォレンジックの痕跡を消すための道具を、オープンソースのホスティングに置いて運用していたわけです。証拠隠滅のインフラとして OSS エコシステムが使われるというのは、据わりの悪い話です。

Babuk そのものは 2021年に病院や警察機関を標的にして悪名を馳せ、同じ年にソースコードがリークしたランサムウェアです。今回の攻撃で研究者が指摘しているのは、身代金による収益化よりも ESXi のログを暗号化して証拠を消すことのほうが主目的だった可能性がある、という点でした。リークされた既製のランサムウェアを、国家支援型のグループが帰属をぼかす煙幕として使う。ランサムウェアが「金を取る道具」から「足跡を消す道具」に転用されているという読み筋です。

攻撃者が中国系と見られている根拠としては、攻撃ツールやスクリプトに中国語の成果物が混ざっていたこと、活動時間帯が UTC+08:00 に集中していたこと、使用ツールが中国語圏の脅威グループと重複すること、そして被害国のリストに中国本土が含まれないことが挙げられています。[The Hacker News の解説記事](https://thehackernews.com/2026/08/suspected-china-nexus-actor-exploits.html)に詳しい経緯がまとまっています。

国別の内訳はドイツ55件、米国41件、トルコ38件、イラン26件、フランス25件と続きます。vCenter は仮想化基盤の制御室なので、1インスタンス取られると配下の数十〜数百の ESXi ホストが一括で握られます。データセンター事業者やクラウドプロバイダーにとっては、1件の侵害が多数の顧客インフラへ波及しうる構図です。

対応は明快で、まずパッチです。vCenter Server 9.0 系は 9.0.2.0100 以上、9.1 系は 9.1.0.0300 以上へ。8.0 系は NVD の記載上 8.0 Update 3k 以降が修正版です。VMware Cloud Foundation 5.x/9.x、vSphere Foundation 9.x、Telco Cloud Infrastructure/Platform なども影響を受けるので、Broadcom 公式アドバイザリのマトリクスで自分の構成を確認してください。すぐに上げられない場合の暫定措置は、Syslog サービスの無効化と管理インターフェースのアクセス元 IP 制限です。

そして、すでに侵入されていないかの確認も忘れずに。`adminuser` アカウントが存在しないか、Cron に `reverse_ssh` のエントリがないか、`.babyk` 拡張子のファイルが転がっていないか。パッチを当てた「後」から始まる作業のほうが、本当は重いのかもしれません。

## 2. 15年前のPCがゲームで生き返る — Linux 7.3 のスケジューラ改良

重い話が続いたので、ここで気持ちのいい話を。Linux 7.3 のマージウィンドウで、スケジューラに大きな改良がまとめて入りました。しかも効果がいちばん派手に出たのが、2011年製の CPU です。

中心にあるのは、Intel のカーネルエンジニア Peter Zijlstra 氏による cgroup の "Flatten the Pick" パッチです。従来の cgroup スケジューラは、次に走らせるタスクを選ぶときに cgroup の階層構造をたどりながら探す設計になっていました。cgroup のスケジューリングは以前から扱いにくく厄介な領域だと言われ続けてきた部分で、[Phoronix のまとめ](https://www.phoronix.com/news/Linux-7.3-Scheduler)でも「常に問題含みで苦痛だった」と表現されています。[LKML に投稿されたパッチシリーズ](https://lore.kernel.org/all/20260511113104.563854162@infradead.org/)による新実装は単一ランキュー（single runqueue）アーキテクチャへ移行し、タスクの選択を一度のフラットな走査で終わらせます。階層をたどる処理そのものを構造から外した、という変更です。

新たに4つの `cgroup_mode` パラメータも用意されました。

- `up`: 上位 cgroup の重みを優先
- `max`: 最大重みのタスクを優先
- `concur`: 最も正確だが計算コストが高い（デフォルト）
- `tasks`: タスク数比で配分

あわせて reniced タスクの誤った扱いも修正され、nice 値による優先度制御が正しく効くようになります。

さて、効果の話です。Zijlstra 氏は自身の Sandy Bridge 機（Core i7-2600K、2011年製）に Radeon RX 580 を挿し、「Shadows Awakening」を Lutris と GE-Proton10-34、Steam Runtime 3 の組み合わせで動かしました。そのうえで CPU を占有するスピナーを8本同時に走らせ、高負荷の状況をわざと作っています。結果がこちらです。

| 指標 | 改善前 | 改善後 | 変化 |
|---|---|---|---|
| 平均 FPS | 48.0 | 57.2 | **+19%** |
| 平均フレームタイム | 34.5 ms | 19.5 ms | **−43%** |
| 最大フレームタイム | 107.4 ms | 37.2 ms | **−65%** |

平均 FPS の +19% も立派ですが、個人的に効いていると思うのは最大フレームタイムの −65% のほうです。107ms のスパイクは、体感としては「一瞬固まった」とはっきり分かるレベルの引っかかりです。それが 37ms まで落ちれば、カクつきの正体そのものが消えます。本人の評価も、文句なしとまでは言えないが確実に遊べる水準にはなった、という控えめなものです。バックグラウンド負荷でまともに動かなかった状態からの変化としては、十分に大きな一歩でしょう。スライス幅を短くするチューニングと組み合わせたときに最大の効果が出たとのことで、カーネル側にも調整項目はあります。ただ、基本はカーネルを上げるだけで効くのがありがたいところです。

マージコミットは `e2457a6`（タグ `sched-core-2026-08-17`）で、33コミット・+952/−649行。主な変更ファイルは `kernel/sched/fair.c`、`deadline.c`、`psi.c`、`topology.c` です。

同じマージウィンドウには、Intel のハイブリッドコア向けの修正も入りました。Ricardo Neri 氏による、P コア / E コア / LPE コアが混在する環境でのクラスタ負荷分散の修正です。L2/L3 キャッシュを共有するコア群（クラスタ）の間で負荷を均等に配るロジックが、非対称な容量構成では正しく機能していませんでした。とくに Lunar Lake と Panther Lake は LPE コアのクラスタが L3 キャッシュに繋がっていないという非対称構成を持っていて、既存の均衡ロジックが条件判定で落ちていたそうです。修正後は、タスクが大型コアに偏ったときにきちんと再配置されるようになります。対象は Alder Lake / Lunar Lake / Panther Lake です。

もうひとつ、Vincent Guittot 氏による短いタスクのスケジューリングレイテンシ削減も入りました。`cyclictest` で非常に顕著な改善が確認されており、音楽制作や産業制御のようにリアルタイム性が要る用途で効果が期待されます。

背景を補足すると、2024〜2025年の Linux ゲーミングコミュニティでは cgroup スケジューラがゲーム性能に悪影響を与えるという話題が繰り返し出ていて、BORE（Burst-Oriented Response Enhancer）のような非公式パッチが流通していました。今回の "Flatten the Pick" は、それをメインラインで根本から解こうとした答えです。[Phoronix のパッチ解説記事](https://www.phoronix.com/news/Linux-Flatten-The-Pick)にベンチマークの詳細が載っています。

注意点として、Linux 7.3 はまだ RC フェーズに入ったばかりです。Arch Linux や Fedora Rawhide のような先進的なディストリが先行しますが、一般ユーザーの手元に届くのは段階的になります。基本の対応は `uname -r` が 7.3.0 以上になるまで待つ、で十分です。

ラックの隅や押し入れで眠っている 2011年前後のマシンに、もう一度電源を入れてみたくなる話ではあります。

## 3. 新バージョンが旧版に負けた謎 — PHP 8.6 の早期ベンチマーク

もう少し肩の力を抜ける話を。Phoronix が 2026年8月19日に、PHP 7.4 から 8.6dev（Git HEAD）までを横並びで測ったベンチマークを公開しました。環境は Fedora 44、Intel Xeon 678X（HP Z4 G6i）、コンパイラは GCC 16 です。

結果が、なかなか居心地の悪いものでした。[Phoronix のベンチマーク記事](https://www.phoronix.com/news/PHP-8.6-Early-Benchmarks)によれば、PHPbench では PHP 8.3 系が最速で、開発中の 8.6dev は 8.5 より若干退行していました。新しいほうが遅い、という素直に困る並びです。

ところが、Phoronix Test Suite 側の複数のサブテストでは逆に 8.6dev が最速を記録しています。同じ日の、同じマシンの、同じビルドで、ベンチマークの種類が変わると順位がひっくり返る。JIT を有効にした場合も、Phoronix の表現では「わずかに効いた」程度で、劇的な差がついたわけではありません。

ここで大事なのは、この数字をどう読むかです。まず PHP 8.6 はまだ Beta フェーズで、GA（正式リリース）は 2026年11月19日の予定。[PHP 公式の 8.6 TODO ページ](https://wiki.php.net/todo/php86)にスケジュールが出ています。RC1 は 9月24日予定なので、今回測られたのは GA の約3ヶ月前、開発途中のスナップショットです。退行がここから直る余地は十分にあります。

もうひとつ、8.4 で導入された IR（中間表現）ベースの新しい JIT フレームワークの性質もあります。[IR ベース JIT の RFC](https://wiki.php.net/rfc/jit-ir) は旧 JIT 比で 5〜10% 高速・生成コードが小さいと謳う一方で、Function JIT のコンパイル速度が最大4倍遅くなるというトレードオフを抱えています。ウォームアップにかかるコストが増えているわけで、短いベンチを何度も回す測り方だとこのコストが結果に乗りやすくなります。長時間動かし続ける本番環境とは、そもそも見ている景色が違います。

そもそも PHP の JIT は、2020年の 8.0 で入って以来、実際の Web アプリへの効果は限定的だと言われ続けてきました。理由もだいたい想像がつきます。典型的な Web アプリケーションは CPU で計算し続けるのではなく、データベースや外部 API の応答を待っている時間のほうが長いからです。JIT が速くするのは計算部分なので、待ち時間が支配的なアプリではそこを削っても全体はあまり変わりません。

なお、Phoronix は「7.4 より古いバージョンは GCC 16 でビルドすると実行時に segfault が出た」とも補足しています。比較の下限が 7.4 なのはそのためです。

PHP 8.6 で入っている性能まわりの変更自体は、地味ですが着実な顔ぶれです。

- Apple Silicon の ZTS（スレッドセーフ）ビルドでの JIT 再有効化
- ZTS 用スレッドローカルストレージの最適化（ネイティブ `__thread` ストレージへ移行）
- ストリームコピーの高速化（sendfile / splice 等のプラットフォーム固有プリミティブの活用）
- `array_intersect()` / `array_fill_keys()` などの配列関数の最適化
- `printf()` の `%s` / `%d` 専用最適化
- 部分関数適用（Partial Function Application）の foreach 展開最適化

現時点で本番環境に緊急の対応はありません。ただ、JIT を使っている方は一点だけ確認しておくとよさそうです。JIT には `opcache.jit=function`（安定・軽量）と `opcache.jit=tracing`（動的プロファイリングで高性能）の2モードがありますが、Tracing JIT については PHP 8.5 系で Segfault のバグが複数報告されています（[Issue #22084](https://github.com/php/php-src/issues/22084)、[Issue #22443](https://github.com/php/php-src/issues/22443)）。8.5.5 以下を使っているなら、修正を含む 8.5.8 への更新を検討してください。

## 4. 認証スルーで乗っ取られる画面共有 — macOS の CVE-2026-65400

さて、ここからまた引き締めます。macOS の画面共有（Screen Sharing）デーモンに認証不備が見つかりました。CVE-2026-65400、CVSS 9.8 Critical。ネットワークから到達できる攻撃者が、有効な資格情報を一切持たないまま root 権限のセッションを張れてしまいます。

この件で興味深いのは、スコアが動いた経緯そのものです。

| 日付 | 出来事 |
|---|---|
| 2026-08-06 | Apple がアウトオブバンドでパッチ公開（当初評価は 7点台） |
| 2026-08-12 | オランダ国家サイバーセキュリティセンター（NCSC-NL）が実際の悪用を確認・公表 |
| 2026-08-14 | CISA が CVSS スコアを 9.8 へ上方修正 |
| 2026-08-18 | CISA KEV カタログに追加 |
| 2026-08-21 | 連邦行政機関の修正期限（明日） |

Apple（CNA）の当初評価は 7点台でした。それが CISA（ADP）によって [NVD 上では 9.8](https://nvd.nist.gov/vuln/detail/CVE-2026-65400) へと引き上げられています。2ポイント以上の乖離です。開発元と政府機関が独立して採点する NVD の評価システムの構造が、そのまま数字の揺れになって出た格好です。

ここでも順番に注目してください。スコアが 9.8 に直ったのは 8月14日ですが、悪用が確認されたのはその2日前の 8月12日。そして Apple がパッチを出したのはさらに前の 8月6日。「9.8 の緊急脆弱性」として世に認識されたときには、現場ではもう root を取られた Mac が動いていたわけです。7点台という初期評価を見て「来週でいいか」と判断した管理者を、責められるでしょうか。

技術的な原因も、なかなか味わい深いものでした。Huntress のリサーチャーによれば、`screensharing` デーモンが実装する SRP（Secure Remote Password）認証フローの中で、フレーム長のバリデーターが古い成功ステータスを誤って返してしまうのが原因です。本来なら RSA-SRP の暗号的な鍵合意を完了しなければ認証は通りません。ところがバリデーターが前のセッションの成功ステータスを次のセッションに持ち越してしまう。レジで前のお客さんのレシートを次の客に渡してしまうような、ステートマシンの後始末漏れです。結果として認証検証がバイパスされ、セッションが平文のまま確立されます。[Huntress の技術分析](https://www.huntress.com/blog/macos-screen-sharing-rce-patched)に詳しい解析が載っています。

侵入後の動きも一通り記録されています。TCP/5900 に接続して root セッションを確立したあと、`SSFileCopySender` というヘルパープロセスが持つ強い権限を利用して任意のファイルへ読み書きし、SSH 公開鍵の設置、LaunchDaemon の作成、Packet Filter 設定の変更でアクセスを維持します。そのうえで暗号資産のマイニングソフトを `.config/sysmond` として隠し、プロセス名を macOS の正規プロセスに似せて発見を遅らせる。最後にシステム履歴とログを消して痕跡を落とす、という段取りです。

影響を受けるバージョンと修正版は次のとおりです。

| macOS バージョン | 修正版 |
|---|---|
| macOS Sonoma 14 系 | 14.8.9 |
| macOS Sequoia 15 系 | 15.7.9 |
| macOS Tahoe 26 系 | 26.6.1 |

[Apple のセキュリティコンテンツ（macOS Tahoe 26.6.1）](https://support.apple.com/en-us/148170)をはじめ、各バージョンのページで修正内容が確認できます。Intel Mac も Apple シリコン搭載機も、どちらも対象です。

パッチ公開前の時点でインターネットに TCP/5900 を公開していた macOS デバイスは、およそ4万台と報告されています。多くは大学や研究機関、商業組織の IP アドレスに集中していました。

対応の最優先は OS アップデートです（システム設定 → 一般 → ソフトウェアアップデート）。すぐに当てられない場合は、画面共有を無効化する（システム設定 → 一般 → 共有）、ファイアウォールで TCP/5900 を塞ぐ、特定 IP からのみ接続を許可する、といった手当てになります。

侵害の確認は次のあたりから。

```bash
# 画面共有デーモンのログに不審な認証タイプが残っていないか
log show --predicate 'process == "screensharing"' --last 14d | grep -i "authentication_type: SRP"

# 隠されたバイナリの有無
ls -la ~/.config/sysmond 2>/dev/null

# 身に覚えのない公開鍵が刺さっていないか
cat ~/.ssh/authorized_keys
```

もし侵害が疑われる場合、パッチを当てるだけでは足りません。OS のクリーンインストールと認証情報のローテーションまで踏み込むことが推奨されています。

## 5. 医療も蝕む、更新された脅威情報 — Medusa ランサムウェア

最後は、数字が更新されたときにはすでに手遅れだった、という話の決定版です。

FBI・CISA・米保健社会福祉省（HHS）が 2026年8月18日、Medusa ランサムウェアに関する合同勧告（#StopRansomware: Medusa Ransomware）を更新しました。[BleepingComputer の報道](https://www.bleepingcomputer.com/news/security/cisa-medusa-ransomware-hit-over-500-critical-infrastructure-orgs/)によれば、2021年以降に医療・政府・防衛産業などの重要インフラ500組織以上が侵害されたことが公表されています。2025年3月時点の勧告では300組織超でした。今回の500組織超は 2026年4月時点の集計なので、およそ1年で、確認されている被害だけで200組織近く積み上がったことになります。

Medusa は 2021年6月に初確認された、フランチャイズ型の RaaS（Ransomware-as-a-Service）です。コア開発者がペイロードとインフラとブランドを管理し、アフィリエイト（実行犯）に貸し出して、身代金収益の一定割合を報酬として支払う。さらにサイバー犯罪フォーラムで初期アクセスブローカーを募集し、被害者ネットワークへのアクセス権に対して100ドルから最大100万ドルの報酬を提示しています。本部がブランドを持ち、加盟店が現場を回し、成績の良い加盟店ほど仕事と報酬が増える。構造だけ取り出せば、どこかのフランチャイズチェーンの説明とほとんど区別がつきません。

侵入口として名指しされている脆弱性は、いずれも見覚えのある顔ぶれです。

- [CVE-2024-1709](https://nvd.nist.gov/vuln/detail/CVE-2024-1709): ConnectWise ScreenConnect の認証バイパス（CVSS 10.0）。23.9.7 以前が対象、修正版は 23.9.8
- [CVE-2023-48788](https://nvd.nist.gov/vuln/detail/CVE-2023-48788): Fortinet FortiClientEMS の未認証 SQL インジェクション（CVSS 9.8）
- [CVE-2026-1731](https://nvd.nist.gov/vuln/detail/CVE-2026-1731): BeyondTrust Remote Support / PRA の OS コマンドインジェクション（CVSS 9.8）

3つ目の CVE-2026-1731 が要注意です。公開から24時間以内に武器化されたことが記録されています。「週明けに検討します」では、もう間に合わない速度です。

侵入後は Living off the Land、つまり OS の標準機能を使い回す戦術に切り替わります。PowerShell や cmd.exe、WMI でペイロードを実行し、Mimikatz で認証情報をダンプし、RDP やソフトウェア展開ツールで横に広がる。AnyDesk・Atera・SimpleHelp・ConnectWise といった正規の RMM ツールを C2 通信に使い、正常なトラフィックに紛れ込みます。

とくに厄介なのが BYOVD（Bring Your Own Vulnerable Driver）です。脆弱なカーネルドライバをわざと持ち込み、それを踏み台に EDR をカーネルレベルで強制終了させます。高価な EDR を導入済みの組織でも、この手口の前では無力化されうる。データの持ち出しには rclone を使い、しかもそれを Windows Defender の除外リストの中に置いてから動かす、という念の入れようです。

暗号化フェーズの実行ファイルは `gaze.exe`、「凝視する」という意味の名前です。起動するとセキュリティサービスを止め、ボリュームシャドウコピーを削除し、データベースサービスを終了させたうえで、AES-256 で全ファイルを暗号化して `.medusa` 拡張子を付けます。バックアップから戻せないようにしてから鍵をかける、という順番です。

被害者には48時間以内の交渉開始を要求し、応じない場合はダークウェブのリークサイトで窃取データをオークションにかけます。ちなみにカウントダウンの延長は1日あたり1万ドルで販売されているそうです。身代金に課金体系が付いているあたり、ホテルのレイトチェックアウト料金のような発想で運用されているのが分かります。

医療分野の被害はとりわけ深刻です。ある事例では120万件を超える患者記録が流出しました。患者ケアを止められないためにパッチ適用が遅れやすいという構造的な事情と、24時間で武器化してくる相手の速度。この組み合わせが致命的に噛み合っています。HHS が今回の合同勧告に加わった背景には、この現実があります。[FBI/IC3 が公開している勧告 PDF](https://www.ic3.gov/CSA/2026/260818.pdf) と [CISA の #StopRansomware ページ](https://www.cisa.gov/news-events/cybersecurity-advisories/aa25-071a) に、対策の詳細がまとまっています。

地理的には米国が主要ターゲットですが、RaaS はアフィリエイトが地域を問わず標的を選ぶモデルです。日本の重要インフラ事業者も十分に射程内と考えたほうがいいでしょう。

対策としては、まず名指しされた3つの CVE を潰すこと。ScreenConnect は 23.9.8 以降、FortiClientEMS は修正済みバージョンへ、BeyondTrust RS は 25.3.2 以降、PRA は NVD の記載では 25.1 以降です。そのうえでネットワークのセグメンテーションと RDP への MFA 必須化、BYOVD 対策としての HVCI（Hypervisor-Protected Code Integrity）有効化、バックアップのイミュータブル化とオフライン保管、ウイルス対策の除外リストの定期審査、RMM ツールの全インスタンス把握と異常セッションのアラート化——といったあたりが柱になります。

最後の除外リストの審査は地味な作業ですが、そこに自分の道具を登録してから動かす相手がいる以上、あの一覧を「誰も見ていない設定」のまま放置するのはかなり危うい、ということでもあります。

## まとめ

5本を並べてみて、共通していたのは順番でした。

vCenter は、パッチが出た直後から悪用が始まっていました。macOS は、スコアが 9.8 に直る2日前にはもう悪用が確認されていました。Medusa は、勧告が更新されたときには被害が500組織を超えていました。どれも、公式の数字が動いたのは事件の途中経過にすぎません。

逆側の2本も同じ構図です。Linux 7.3 のスケジューラ改良は、5月に LKML へ投稿されたパッチが8月にマージされたもので、Phoronix が記事にする前から議論と検証は積み上がっていました。PHP 8.6 のベンチマーク結果も、GA の3ヶ月前という「まだ数字が確定していない」時点のスナップショットです。

私たちは公式発表を待ちがちですが、公式発表は現場の後を追いかけてくるものです。KEV に載ってから動くのでは遅く、スコアが直ってから慌てるのでは間に合わない。かといって全部を先読みするのは無理な相談で、だからこそ「セグメンテーション」「MFA」「イミュータブルなバックアップ」といった、特定の CVE に依存しない備えが効いてくるのだと思います。

今日はまず、vCenter と macOS の期限が明日だという1点だけ持ち帰ってください。それ以外は、週末にでも。

## 参考リンク

- CVE-2026-59310 NVD 詳細（VMware vCenter）: https://nvd.nist.gov/vuln/detail/CVE-2026-59310
- GHSA-v2gp-49gj-2c9f GitHub Advisory Database: https://github.com/advisories/GHSA-v2gp-49gj-2c9f
- CVE-2026-59309 NVD 詳細（連鎖に使われた認証バイパス）: https://nvd.nist.gov/vuln/detail/CVE-2026-59309
- CISA 既知の悪用された脆弱性（KEV）カタログ: https://www.cisa.gov/known-exploited-vulnerabilities-catalog
- The Hacker News: 中国系アクターによる vCenter 悪用の解説: https://thehackernews.com/2026/08/suspected-china-nexus-actor-exploits.html
- Peter Zijlstra による LKML パッチ投稿（sched: Flatten the pick）: https://lore.kernel.org/all/20260511113104.563854162@infradead.org/
- Phoronix: Linux 7.3 スケジューラ改良まとめ: https://www.phoronix.com/news/Linux-7.3-Scheduler
- Phoronix: "Flatten the Pick" パッチ詳細とベンチマーク: https://www.phoronix.com/news/Linux-Flatten-The-Pick
- Phoronix: Intel ハイブリッド CPU クラスタ修正の解説: https://www.phoronix.com/news/Linux-7.3-Better-Intel-Hybrid
- Phoronix: PHP 8.6 早期ベンチマーク（2026-08-19）: https://www.phoronix.com/news/PHP-8.6-Early-Benchmarks
- PHP 8.6 公式 TODO・リリーススケジュール: https://wiki.php.net/todo/php86
- PHP JIT IR フレームワーク RFC（8.4 導入）: https://wiki.php.net/rfc/jit-ir
- PHP Tracing JIT Segfault バグ Issue #22084: https://github.com/php/php-src/issues/22084
- PHP Tracing JIT SIGSEGV バグ Issue #22443: https://github.com/php/php-src/issues/22443
- CVE-2026-65400 NVD 詳細（macOS 画面共有）: https://nvd.nist.gov/vuln/detail/CVE-2026-65400
- Apple 公式: macOS Tahoe 26.6.1 セキュリティコンテンツ: https://support.apple.com/en-us/148170
- Apple 公式: macOS Sequoia 15.7.9 セキュリティコンテンツ: https://support.apple.com/en-us/148171
- Apple 公式: macOS Sonoma 14.8.9 セキュリティコンテンツ: https://support.apple.com/en-us/148172
- Huntress: macOS 画面共有脆弱性の技術分析: https://www.huntress.com/blog/macos-screen-sharing-rce-patched
- BleepingComputer: Medusa が重要インフラ500組織超を侵害: https://www.bleepingcomputer.com/news/security/cisa-medusa-ransomware-hit-over-500-critical-infrastructure-orgs/
- FBI/IC3 合同勧告 PDF（2026-08-18 付）: https://www.ic3.gov/CSA/2026/260818.pdf
- CISA #StopRansomware: Medusa Ransomware（aa25-071a）: https://www.cisa.gov/news-events/cybersecurity-advisories/aa25-071a
- CVE-2024-1709 NVD 詳細（ConnectWise ScreenConnect）: https://nvd.nist.gov/vuln/detail/CVE-2024-1709
- CVE-2023-48788 NVD 詳細（Fortinet FortiClientEMS）: https://nvd.nist.gov/vuln/detail/CVE-2023-48788
- CVE-2026-1731 NVD 詳細（BeyondTrust Remote Support / PRA）: https://nvd.nist.gov/vuln/detail/CVE-2026-1731
