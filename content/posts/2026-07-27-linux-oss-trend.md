---
title: "44件のはずが、数えたら63件 — 数字は数える場所で変わる（2026/7/27 Linux動向）"
date: 2026-07-27T00:00:00+09:00
draft: false
tags: ["セキュリティ", "Zen Browser", "Firefox", "auto-cpufreq", "Linux Kernel", "ext4", "Ollama", "SvxLink"]
categories: ["Linux・OSSトレンド"]
---

週末を挟んだ週明けは、発表そのものが少ない代わりに、ひとつひとつの数字をじっくり数え直す時間ができます。そして数え直すと、けっこうな確率で最初に見た数字と合いません。今日は「44件のはずが63件だった」ブラウザの話から始めて、最後は「9.8も13年も、どれを指しているのか特定できない」という脆弱性の話まで、数字の読み方をめぐる5本をお届けします。正直に言うと、書いている側がいちばん振り回された回でした。

{{< youtube "Sn7qiEkDtgI" >}}

## 1. Zen Browser 1.21.9b — 「44件のCVE修正」を数え直したら63件だった

Firefox ベースのコミュニティ製ブラウザ Zen Browser が、2026年7月25日に 1.21.9b を公開しました。中身の主役は、内蔵エンジンを Firefox 153.0 へ更新したことです。[Zen のリリースノート](https://github.com/zen-browser/desktop/releases/tag/1.21.9b)の Security セクションには Mozilla の公式アドバイザリ MFSA2026-68 へのリンクが1本置かれているだけで、修正件数の記載はありません。

この話題は当初「44件の CVE を一括修正」という形で流通していました。ところが [MFSA2026-68 のページ](https://www.mozilla.org/en-US/security/advisories/mfsa2026-68/)を直接取得して CVE セクション単位で数え直すと、実際の総数は63件でした。内訳は high が20件、moderate が35件、low が8件。44 という数字は high 単独でも moderate 単独でもなく、どの区分の組み合わせとも一致しません。要約の途中で紛れ込んだ根拠不明の数値と見るのが妥当で、ここでは63件を正として扱います。

……と、しれっと書きましたが、ここに至るまでが恥ずかしい道のりでした。以下は外部から検証できる話ではなく、うちの編集作業中に実際に起きたことです。最初に要約モデル経由でページを読ませたら「48件」が返ってきました。次に、査読担当がブラウザでページを開いてサイドバーの AI アシスタントに「このページのアドバイザリは何件？」と聞いたら「64件」。HTML を直接パースして数え直して、ようやく63件で落ち着きました。しかもその63は、ユニークな CVE-ID の数、`id="CVE-…"` アンカーの数、脆弱性ブロックの数、severity 内訳の合計、この4つが全部一致しています。同じ1ページを3通りの数え方で数えて 48 / 63 / 64 に割れる。件数みたいな一見単純な事実ほど、要約レイヤーを一枚挟むと静かにずれるんだな、と実感しました。

中身を見ると、サンドボックス脱出に分類されるものが5件（CVE-2026-16351、16352、16356、16367、16388）、WebRTC の Audio/Video コンポーネントの use-after-free が1件（CVE-2026-16362）などが並びます。もうひとつ押さえておきたいのが、CVE-2026-16411 / 16412 / 16360 の3件が「Memory safety bugs fixed in ...」という包括エントリだということ。内部ファジングで見つかった多数の潜在的問題を1件にまとめて計上したものなので、「63件」という総数は、実際に潰されたバグの数よりむしろ少ない可能性があります。CVE の件数を深刻度の物差しに使うのは、思ったより危ういわけです。

追随の速さも見ておきましょう。Firefox 153.0 本体が7月20日、MFSA2026-68 が21日、Zen 1.21.9b が25日。本体から約5日、アドバイザリから約4日での取り込みです。リリース履歴を追うと 152.0 系のポイントリリースも毎回数日で拾っており、Zen が追っているのは ESR ではなく Rapid Release 系列だとわかります。

ただし速さには副作用もありました。公開の約4時間後、[Issue #14709](https://github.com/zen-browser/desktop/issues/14709) が立っています。Firefox 153 で新しく入った Vulkan 動画デコードを Zen 1.21.9b 上で有効にすると、Linux の tarball 環境で動画再生時にクラッシュするという報告で、7月27日時点でコメントはゼロ、未対応のままです。セキュリティ修正そのものではなく、上流の新機能に伴う回帰ですね。

## 2. auto-cpufreq 3.1.0 — GUIに監視モードとBluetoothトグルが入った

7月26日、Linux 向けの CPU 電源管理ツール auto-cpufreq が [v3.1.0](https://github.com/AdnanHodzic/auto-cpufreq/releases/tag/v3.1.0) を公開しました。このツールは、カーネル標準の cpufreq ガバナ（`performance` / `powersave` / `schedutil` など）を、電源状態や CPU 負荷、温度に応じて自動で切り替えてくれる常駐デーモンです。

新機能は4つ。まず GUI への監視モード追加（PR #916）。従来 CLI 専用だった `auto-cpufreq --monitor`、つまり設定を適用せずに現状だけ眺めるモードが GUI からも使えるようになりました。次に Bluetooth トグル（PR #917）。ただしこの PR の本体は後半のバグ修正のほうで、従来は `bluetooth/main.conf` の更新に単純な文字列置換を使っていたため、Arch Linux のように該当行がデフォルトでコメントアウトされている環境（`#AutoEnable=false` など）では書き換えに失敗していました。設定ファイルを sed 的に書き換える実装が、ディストリごとのデフォルト設定の差で壊れる典型例です。

3つめは Lenovo の conservation mode（バッテリーを一定容量で充電停止させる省電力モード）の対応拡大（PR #942）。制御ファイルのパスを単一のハードコードから複数箇所の動的探索へ変えたもので、地味ですが効きます。

4つめの [PR #945](https://github.com/AdnanHodzic/auto-cpufreq/pull/945) が今回いちばん面白いところです。Lenovo Legion などでは Fn+Q のようなキーで ACPI の platform profile を手動切り替えできるのですが、auto-cpufreq のデーモンは2秒ごとにループを回して設定ファイルの値を再適用してしまうため、手で切り替えても数秒で元に戻される、という体験になっていました。そこで追加されたのが `enforce_platform_profile` という真偽値の設定です。デフォルトの `true` は従来どおり毎ループ強制適用、`false` にすると AC とバッテリーが切り替わったときだけ適用します。しかも `[charger]` と `[battery]` で個別指定できるので、「充電中は手動操作を尊重、バッテリー動作時は強制的に省電力を守る」といった非対称な運用が書けます。これは「platform_profile を使うかどうか」のオンオフではなく、適用タイミングの制御である点に注意してください。この手の「ツールが親切のつもりで2秒ごとに上書きしてくる」問題、個人的にかなり好きな部類の設計課題です。全部やめるのでも全部強制するのでもなく、境界イベントのときだけ効かせる、という落とし所がきれいに決まっています。

導入時の落とし穴もひとつ。配布形態は installer 方式、Snap、AUR の3つありますが、[公式README](https://github.com/AdnanHodzic/auto-cpufreq/blob/master/README.md)によると Snap 版はパッケージ隔離の制限で GUI が使えません。今回の目玉である監視モード GUI も Bluetooth トグルも Snap 版では触れないので、GUI 目当てなら installer 方式を選ぶ必要があります。「新機能の GUI が目玉のリリースなのに、いちばん手軽な配布形態では触れない」というのは、なかなかしんどい構図ですね。TLP とは競合するため併用非推奨、thermald は併用推奨、というのも README に明記されています。

## 3. Linux 6.12.98 — コミット2件、実質1件だけのリリース

7月25日、LTS 系列 6.12 の安定版として 6.12.98 が出ました。異様なのはその小ささです。[ChangeLog-6.12.98](https://www.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.12.98) を全文取得すると、含まれるコミットは2件しかありません。ひとつは Greg Kroah-Hartman によるバージョンタグコミット、もうひとつが Yun Zhou 氏による「ext4: fix fd leak in EXT4_IOC_MOVE_EXT cross-sb validation」。つまり実質的な変更は1件です。

比較のために、[kernel.org の releases.json](https://www.kernel.org/releases.json) を見ると、前日の7月24日には安定版が6本まとめて出ています。束ねられたコミット数は 5.10.261 の677件から 7.1.5 の2,070件までのレンジで、いずれも通常の定期リリース。その翌日に、6.12.98 だけが実質1件のために切られたわけです。深刻度が高いからというより、直前に持ち込まれた明白な回帰を急いで是正した、と読むべき状況です。

[修正パッチ](https://github.com/gregkh/linux/commit/913e7b4459d6eef807bb8088b39b890ed6a74ee3.patch)を見ると、`fs/ext4/ioctl.c` の数行だけの変更でした。クロスファイルシステムを検出したときに素の `return -EXDEV;` で返していたのを、`goto mext_out;` に変えただけ。`mext_out:` ラベルには `fdput(donor);` が置かれているので、goto を経由すれば donor 側のファイル参照は必ず解放されます。素の return はそこを飛ばしていたため、`fdget()` で取った参照が残り続けていました。

この回帰の原因が構造的で興味深いところです。元になった 6.12.y 向けバックポート（74796e886ca3）は、upstream のコミットを持ち込んだものでした。upstream 本流では直前に `CLASS(fd)` という自動クリーンアップ機構が入っていて、スコープを抜ければ fd が自動解放されます。だから upstream 側では `return -EXDEV;` と書いても安全だったのです。ところが 6.12.y にはその機構がなく、fdget と fdput を手で対応付ける世代のまま。コードをそのまま持ち込んだ結果、6.12.y でだけリークが生まれました。upstream には存在しない、バックポート限定の回帰です。LTS のメンテナンスが「パッチをコピーする作業」ではないことを、これ以上ないくらい簡潔に示す例だと思います。周辺インフラの世代差を毎回頭に入れておかないといけない、というのはなかなかの重労働です。

実害の条件はかなり限定的で、`EXT4_IOC_MOVE_EXT` の donor fd が別ファイルシステム（overlayfs マウント上のファイルなど）を指すケースに限られます。同一 ext4 内の通常の e4defrag 運用はそもそもこのチェックに到達しません。ただし該当条件を繰り返し踏むと、じわじわオープンファイル上限に近づいて最終的に `EMFILE` で新規オープンが失敗する、という形の障害に発展し得ます。しかもこれはカーネル内部の参照カウントのリークなので、`lsof` でプロセスの fd テーブルを覗いても直接は見えない場合があります。

## 4. Ollama v0.32.4 — Apple GPUのMLX経路がLaguna系モデルに対応

7月25日、ローカル LLM 実行環境の Ollama が [v0.32.4](https://github.com/ollama/ollama/releases/tag/v0.32.4) を公開しました。リリースノートの What's Changed はわずか3行ですが、それぞれ別の話題です。

1行目が「Support Laguna on Apple GPUs via the MLX engine」。まず Laguna が何なのかを確定させておくと、これは Ollama の内部機能名ではなくモデルの固有名詞です。[PR #17237](https://github.com/ollama/ollama/pull/17237) で追加された `x/models/laguna/laguna.go` の冒頭コメントに「Package laguna provides the Poolside Laguna text model implementation for MLX.」とあり、Poolside 社が開発するテキスト生成モデルのファミリーだとわかります。Mixture-of-Experts 構成のオープンウェイト・コーディングモデルで、v0.32.4 でサポートされたのは Laguna XS 2、XS 2.1、S 2.1 の三つです。

MLX 実装のほうは、gate と up の融合、大規模 prefill 向けのソート済み GatherMM／GatherQMM 演算、512トークン単位のキャッシュ活用 prefill チャンキングなどが入っています。しかもカスタムカーネルを書かず MLX の公開 API だけで実現している、と PR に明記されています。追加コミットでは Laguna の重みを Metal 上に常駐させ、大きく疎にアクセスされる expert バッファの repeated paging を防ぐ変更も入りました。

さて、ここが今回いちばん誤解されやすいところです。リリースノート3行目の「Fixed Qwen3 MoE decoding for differently-quantized experts, plus faster packed gate/up projection (~4–9% on M5 Max).」という数値、これは Laguna 対応の性能値ではありません。Qwen3 MoE の packed gate/up projection 高速化に対する数値です。Laguna は1行目、この数値は3行目、別の変更点なんですね。

しかもこの数値、書かれている条件は「Qwen3 MoE（サイズやバリアントの記載なし）」「packed gate/up projection」「Apple M5 Max」「約4〜9%」だけです。指標がトークン毎秒なのかレイテンシなのかすら明記されておらず、ベンチマーク手法もプロンプト長もバッチサイズも公開されていません。より詳細な条件を示す一次資料は見つかりませんでした。この手の数字だけがスクリーンショットで一人歩きするのを何度も見てきたので、ここは意地でも「Laguna が速くなった」とは書かないでおきます。

2行目の「Quantize draft-model output heads at the requested type when creating speculative-decoding drafts.」も技術的には面白いところです。投機的デコーディングは、小型のドラフトモデルに複数トークンを先行生成させ、大型モデルがまとめて検証・採択する高速化手法。今回はドラフトモデル作成時に、語彙分布を出力する最終線形層（LM Head）もユーザー指定の量子化タイプで量子化されるようにした、というものです。ここの精度が足りないと出力分布が荒れてドラフトの採択率が下がり、高速化効果そのものが目減りします。

なお手元で試すときの注意点として、Laguna の公式配布パス（`ollama.com/library` 配下）は7月27日時点で確認できていません。PR #17237 の本文にあるのはコアメンテナ個人のネームスペースでのテスト配布パスなので、正式提供とは区別しておく必要があります。

## 5. SvxLink 26.05.1 — 「9.8」も「13年」も、どれを指しているのか特定できない

締めは、今回いちばん解きほぐしがいのある題材です。

SvxLink は Linux 上で動くオープンソースのアマチュア無線リピータ制御ソフト一式です。EchoLink というVoIP方式のアマチュア無線インターネット接続システムのノードとして動いたり、複数ノードを束ねる SvxReflector を提供したりします。Debian と Ubuntu の公式パッケージにも入っており、運用者は主に常時起動のリピータ局や EchoLink ゲートウェイ局。つまりインターネットに露出した Linux サーバーで長期間動き続けるソフトです。

2026年7月26日、[SvxLink 26.05.1](https://github.com/sm0svx/svxlink/releases/tag/26.05.1) がセキュリティ修正リリースとして公開されました。翌日には Mark Rose 氏本人が [oss-security メーリングリスト](https://www.openwall.com/lists/oss-security/2026/07/26/1)へ投稿しています。本文にはこうあります。

> "A new version of svxlink has been released that fixes many vulnerabilities. The worst has a CVSS/3.1 score of 9.8. […] All prior versions from at least the past 13 years are vulnerable to remote code execution."

「CVSS 9.8」「13年」。強いフレーズが並んでいます。見出しに使うならここを抜くのがいちばん映えます。ところが一次情報を突き合わせると、どちらも一意には決まりませんでした。順に見ていきます。

### まず、CVE番号は1件も付いていない

セキュリティの話題ではつい CVE 番号を探しますが、今回は存在しません。公開された GitHub Security Advisory は確認できた範囲ですべて「No known CVE」で、7月27日時点で CVE 番号は1件も割り当てられていない状態です。GHSA ID で参照するしかありません。

そして「何件あるのか」からして単一の数字で言えません。[GitHub の公開アドバイザリ一覧ページ](https://github.com/sm0svx/svxlink/security/advisories?state=published)で GHSA ID を数えると10件、一方 [GitHub REST API](https://api.github.com/repos/sm0svx/svxlink/security-advisories) は14件を返します。差分の4件は公開ページ側に現れておらず、ページング表示の都合なのか掲載条件の違いなのかは一次情報からは判断できません。件数に触れるなら「公開ページの表示は10件、API では14件」と両方を出すのが安全で、確定総数としては扱えません。

### 「9.8」がどれを指すかは特定できない

oss-security 投稿の「the worst has a CVSS/3.1 score of 9.8」には GHSA ID の記載がなく、どのアドバイザリを指しているのか本文からは特定できません。候補は2つあります。

ひとつは [GHSA-5g48-xjmf-7p4q](https://github.com/sm0svx/svxlink/security/advisories/GHSA-5g48-xjmf-7p4q)。EchoLink ディレクトリクライアントの `StationData::setData()` が、ディレクトリサーバーから届いた局リストの description を45バイト固定のスタックバッファへコピーする際に長さをクランプしておらず、溢れる、というものです。API 上は critical・CVSS 9.8 で、条件付きではない単一のスコアです。

もうひとつは [GHSA-pc2g-2p95-4cr5](https://github.com/sm0svx/svxlink/security/advisories/GHSA-pc2g-2p95-4cr5)、reflector クライアントの TCL コマンドインジェクションです。こちらはアドバイザリ自身が2段階のスコアを明記していて、デフォルト設定では 8.1、許容的な `ACCEPT_CALLSIGN` 設定で運用されている場合は 9.8 になります。

つまり「9.8 はデフォルト構成での深刻度」と読むのも正しくないし、「9.8 は設定依存の最悪ケースにすぎない」と言い切ることもできません。どちらのアドバイザリの、どの条件下のスコアなのかまで込みでないと意味が確定しない数字です。

TCL インジェクションのほうは中身が鮮やかなので触れておくと、reflector が送る `MsgTalkerStart` メッセージのコールサイン欄が、`talker_start <tg> <callsign>` というイベント文字列に単純結合され、そのまま `Tcl_Eval()` に渡されていました。エスケープもホワイトリストもありません。攻撃者側の reflector がコールサイン欄に `X[exec touch /tmp/pwned]` を入れて送れば、TCL のコマンド置換が評価されて svxlink プロセスの権限でシェルコマンドが走ります。トーカーのコールサインは送信のたびに自動配信されるので、ノード側の操作は一切要りません。コマンドインジェクションというとシェルを連想しますが、これはスクリプト言語のインタプリタに文字列を渡すパスで起きています。設定やイベント処理を TCL で書ける柔軟さが、そのまま攻撃面になっているわけです。PoC が `X[exec touch /tmp/pwned]` の一行で済むあたり、古典的すぎて逆に感心してしまいました。

### 「13年」も、何を数えた数字か特定できない

「少なくとも過去13年間の全バージョンが RCE に脆弱」という表現も、投稿本文にはその根拠が書かれていません。そして厄介なことに、アドバイザリ側には「古さ」を測れる指標が2つあり、両者が一致しないのです。

ひとつめは `vulnerable_version_range`、影響を受けるタグ付きリリースの範囲です。公開ページ側の10件について下限を実測すると 15.11 / 17.12 / 24.02 / 25.05 / 26.05 の5通りで、SvxLink のバージョンは「西暦下2桁.月」形式なので、2026年7月までの経過はおよそ0〜11年。13年を超えるものはありません。

ふたつめは、アドバイザリ本文が記す欠陥コミットの導入日です。こちらはリリースタグではなく、問題のコードが git に入った日を指します。読んでいくと、2008-10-19、2010年、2013-10-13、2014-07-16、2015-01-02、2015-10-04、2019-08-15、2019-09-29 とばらけていて、約7年から約18年までの幅があります。

極端な例が GHSA-xmcv-mjpv-x46q で、Opus デコーダ部分は 2013-10-13 導入なので約12年9か月、たしかに13年に近い。ところが同じアドバイザリの S16 デコーダ部分は 2008-10-19 導入で約17年9か月、一方 `vulnerable_version_range` は 17.12 以降なのでリリースで数えれば約8年7か月。ひとつのアドバイザリの中で、8年・13年・18年という三つの数字がすべて成り立ってしまいます。しかもこのアドバイザリの CVSS は 6.5、ベクターは可用性のみへの影響で、RCE とは書かれていません。13年という RCE の年数の根拠には使いにくいわけです。

逆に RCE 級である GHSA-pc2g（TCL インジェクション）はコミット導入が 2019-08-15 で約7年、リリース範囲で数えれば 24.02 以降の約2年5か月。いずれにせよ13年ではありません。

実態としては「古いバグが13年ぶりに掘り起こされた」というより「新旧まとめて一斉に見つかった」ほうが近いと思います。GHSA-6wgq（CVSS 8.8）は `vulnerable_version_range` が 26.05 のみ、つまり直近リリースでしか影響しません。1年未満のものから十数年物まで混在しています。

### AIの関与も、書かれているのは一文だけ

リリースノートには次の一文があります。

> "Several security related bugs was fixed by Mark Rose using AI."

引用できるのはここまでです。この一文は「セキュリティ関連のいくつかのバグが、Mark Rose 氏によって AI を用いて修正された」と述べているだけで、AI がどの工程で使われたのか——脆弱性の発見なのか、パッチの生成なのか、コードレビューなのか——は書かれていません。原文の動詞は fixed のみで、found や discovered は現れません。ただしこれは「発見には使っていない」と明記しているのとも違い、単に言及がないだけです。oss-security 投稿にも GHSA アドバイザリ本文にも、AI への言及は見当たりませんでした。「AI が十数件の脆弱性を発見した」という物語はたしかに魅力的なんですが、それは一次情報が言っていることではないので、ここは踏み込まないでおきます。

対応そのものは単純で、26.05.1 へ更新することです。ただし oss-security 投稿が明記するとおり古いバージョンのパッケージはバックポートが必要で、Debian や Ubuntu を使っている運用者はディストリ側の対応を待つことになります。

## まとめ

今日の5本は、脆弱性そのものより「発表された数字をどう読むか」が主題になりました。Zen の CVE 件数は数え直したら63件、SvxLink のアドバイザリ件数は見る場所で10件と14件、「9.8」も「13年」も何を指すか特定できない。数字が割れたときは、数え方を明示できるほうを採る——今日の実務上の落とし所はそれくらいでした。地味ですが、「特定できない」と書けることのほうが、それらしい数字で埋めるより価値がある日もあると思っています。皆さんは、気になった数字を自分で数え直す派ですか、それとも発表をそのまま受け取る派ですか？

## 参考リンク

- Zen Browser 1.21.9b リリースページ https://github.com/zen-browser/desktop/releases/tag/1.21.9b
- Mozilla Foundation Security Advisory 2026-68 https://www.mozilla.org/en-US/security/advisories/mfsa2026-68/
- auto-cpufreq v3.1.0 リリースページ https://github.com/AdnanHodzic/auto-cpufreq/releases/tag/v3.1.0
- ChangeLog-6.12.98（全2コミット） https://www.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.12.98
- Ollama v0.32.4 リリースノート https://github.com/ollama/ollama/releases/tag/v0.32.4
- SvxLink 26.05.1 リリースページ https://github.com/sm0svx/svxlink/releases/tag/26.05.1
- oss-security「critical vulnerabilities patched in svxlink (RCE)」 https://www.openwall.com/lists/oss-security/2026/07/26/1
