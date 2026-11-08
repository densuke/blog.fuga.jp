---
title: "GPT-6 Cyber が Firefox の高深刻度の脆弱性81件を発見と OpenAI が自己申告、Nspawn 3.0 は Docker Engine API 互換のソケットを追加、Asahi Linux は進捗報告で M3 の一般提供を発表、GitHub Actions のワークフロー依存ロックファイルは GA、Claude Code の許可リストに残る秘密を Apiiro が調査（2026/11/09 Linux・OSSトレンド）"
date: 2026-11-09T00:00:00+09:00
draft: false
tags: ["セキュリティ", "AI", "Firefox", "コンテナ", "Asahi Linux", "GitHub Actions", "Claude Code"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

一度出した OK は、いつまで有効なのか。動画はこの問いを、5つの話題に沿って追いました。OpenAI は、広範な検査を経ていた Firefox から GPT-6 Cyber が高深刻度の脆弱性を81件見つけたと発表しました。Nspawn 3.0 は Docker Engine API 互換のソケットを足し、その権限を polkit で渡します。Asahi Linux は、M3 搭載機の一般提供とライセンスの移行を進捗報告で伝えました。GitHub Actions では、依存の解決結果を固定するロックファイルが一般提供になりました。Claude Code については、承認したコマンドが許可リストのファイルに残り、そこに秘密が含まれていた事例を Apiiro が調査しています。

「承認の賞味期限」という括りは書き手によるもので、各社がそう述べているわけではありません。放送の誤りや裏付けの取れなかった発言は、節ごとの「動画の訂正」で直しています。

確認は2026年11月9日 7:50〜8:00（日本時間）です。最新版や配布状況、Issue の状態のように動くものは、この時点の情報で、本文にも時点を添えました。

{{< youtube "DIkPD8QD0ts" >}}

## 1. OpenAI GPT-6 Cyber — Firefox の高深刻度81件は OpenAI の自己申告

OpenAI は11月5日（木）に、サイバーセキュリティ向けのモデル [GPT-6 Cyber](https://openai.com/index/introducing-gpt-6-cyber/) を発表しました。提供は、まず Daybreak Red の承認済み顧客の一部に API と Codex 経由で行い、全 Daybreak Red 顧客へ順次広げる予定としています。Help Net Security は、GPT-6 Astra をもとに、脆弱性の発見、悪用の検証、修正の支援向けに訓練したモデルと[説明](https://www.helpnetsecurity.com/2026/11/06/openai-gpt-6-cyber-released/)しています。

### OpenAI が示した数値

以下の数値は、すべて OpenAI の発表にある自己申告です。

- Firefox から、フロンティアモデルで広範に検査されていたにもかかわらず未知だった高深刻度の脆弱性を81件見つけ、Mozilla が high severity と分類した、としています
- Linux カーネルの脆弱性1,724件を再現し、948件で動作するエクスプロイトを作成した。同じ研究用ハーネスで GPT-5.6 Sol が作った166件の5倍を超える、とあります
- ExploitGym では GPT-6 Cyber が 48.5%、GPT-5.6 Cyber が 32.1% です
- 範囲外のサービスを悪用しなかった割合は、デプロイ用プロンプトなしで 99.93%、ありで 100% です。GPT-5.6 Cyber は 94.49% でした
- Preparedness Framework では、サイバー分野で Critical に分類しました。GPT-5.6 Cyber は High でした

Dragos の Chief AI Officer である Rob T. Lee 氏（11月4日に SANS から移籍）の談話も、OpenAI の発表に載っています。模擬発電プラントの検証で、エンジニアリング用ソフトウェアのゼロデイを2件見つけた、という内容です。ゼロデイの中身は、この記事では扱いません。

### Firefox 159 のアドバイザリ

OpenAI は、Mozilla が多くの修正を出したと述べ、根拠として [MFSA 2026-118](https://www.mozilla.org/en-US/security/advisories/mfsa2026-118/)（Firefox 159、10月27日（火））にリンクしています。Mozilla 自身のブログ2本は、81件にも Firefox 159 にも触れていません。

MFSA 2026-118 は、CVE を1件ずつ載せています。合計167件で、そのうち OpenAI 側が報告者として記された CVE は41件（いずれも impact は high）です。41件が OpenAI の言う81件の部分集合かどうかは、確認できません。Firefox 158 の [MFSA 2026-106](https://www.mozilla.org/en-US/security/advisories/mfsa2026-106/)（10月13日（火））にも、OpenAI 側が報告者の CVE が9件あります。確認した範囲で公開されていないのは、81件と CVE の対応表です。

読者がすることは変わりません。Firefox を159以降の最新版にします。159.0.1（MFSA 2026-123、11月3日（火））も出ています。

### 過去の Mozilla の AI 検査

Mozilla の[ブログ](https://blog.mozilla.org/en/firefox/ai-security-zero-day-vulnerabilities/)（4月21日）は、Claude Opus 4.6 での検査が Firefox 148 の22件の security-sensitive bugs の修正につながり、Claude Mythos Preview の初期評価で見つかった271件の脆弱性の修正が Firefox 150 に入った、としています。22件は security-sensitive bugs、271件は vulnerabilities と、語が違います。10月29日の[ブログ](https://blog.mozilla.org/en/firefox/privacy-security/defending-patch-gap/)には、2月から Anthropic と OpenAI のフロンティアモデルの早期アクセスで検査を進めてきた、とあります。

OpenAI は GPT-6 Cyber を使う側に、高リスクの作業ではサンドボックス、行動の確認、人の監督を勧めています。一般の利用者の備えとしては、ブラウザとカーネルを更新し、権限を絞ることが挙げられます。こちらは書き手の整理です。

動画の訂正です。

- 動画では、ほかの AI では見つからなかった脆弱性を81件掘り出した、と紹介しました。OpenAI の表現は、広範なフロンティアモデルの検査にもかかわらず未知だった、です。ほかの AI が見つけられなかったとは書いていません（[OpenAI の発表](https://openai.com/index/introducing-gpt-6-cyber/)）。
- 動画では、Mozilla はその多くを Firefox 159 で修正済みとしている、と紹介しました。「多くの修正を出した」と書いたのは OpenAI の発表で、Mozilla は81件にも Firefox 159 にも触れていません（[MFSA 2026-118](https://www.mozilla.org/en-US/security/advisories/mfsa2026-118/)）。
- 動画では、個別の CVE 番号は公開情報に載っていない、と紹介しました。正しくは、[MFSA 2026-118](https://www.mozilla.org/en-US/security/advisories/mfsa2026-118/) に CVE が1件ずつ載っています。確認した範囲で公開されていないのは、81件との対応です。
- 動画では、Mozilla は春から AI を使った検査を進めていた、と紹介しました。Mozilla は2月から、と書いています（[Mozilla のブログ](https://blog.mozilla.org/en/firefox/privacy-security/defending-patch-gap/)）。
- 動画では、OpenAI が11月12日にライブ配信を予定している、と紹介しました。OpenAI の発表と主要な報道で、この予定は確認できませんでした。

## 2. Nspawn 3.0 — Docker Engine API 互換のソケットと、その権限

Nspawn の 3.0.0 は、11月7日（土）11:55（日本時間）に[公開](https://github.com/nspawn/nspawn/releases/tag/3.0.0)されました。ブログ記事の著者は Eduard Tolosa 氏です。[ブログ](https://blog.nspawn.org/posts/nspawn-3-0-a-docker-compatible-engine-api-for-systemd-nspawn-containers/)によれば、ホストのソケットは `/run/nspawn/api.sock` で、主な目的は互換性です。Docker の API を通じてコンテナを管理するツール、たとえば GitLab Runner の docker executor が、Nspawn のマシンを使えます。3.0.0 から約16時間のうちに 3.1.0 と 3.2.0 も出て、確認時点（11月9日）では 3.2.1（11月8日 14:24、日本時間）が最新です。

### 使い方と範囲

- パッケージを入れた直後は、ソケットは無効です。`systemctl enable --now nspawn-api.socket` で有効にし、`DOCKER_HOST` をソケットに向けると、docker コマンドが Nspawn に話しかけます
- 通るのは `docker exec` や `docker cp` などです。ブログによれば、build、load、import、tag、push、commit、名前の変更、export、swarm、plugins は 501 を返します。`docker build` は動かず、`nspawn build` を使います
- 応答は API 1.51 の形式で、クライアントが要求する 1.24 までの版にも答えます。ブログは、Docker では動くのに Nspawn では失敗するクライアントがあれば Issue を開いてほしい、と結んでいます
- Compose については、`nspawn compose` が docker compose のファイルをそのまま読みます。属性ごとの対応は [COMPOSE.md](https://github.com/nspawn/nspawn/blob/3.2.1/docs/COMPOSE.md) に、yes・partly・no で整理されています。`docker compose` をこのソケットに向けて使えるとは、確認した範囲では書かれていません
- `/run/docker.sock` だけを見るツール向けには、drop-in でシンボリックリンクを作れます。ブログは、そのパスを他が使っていないホストで、と限定しています

### 権限: org.nspawn.manage はホストの root 相当

root 以外のユーザーが使うには、polkit のルールが要ります。パッケージには例として `nspawn-wheel.rules` が付いています。ブログによれば、読み取りと待機には `org.nspawn.inspect`、ログの取得と変更には `org.nspawn.manage` が要ります。そのうえで、docker グループと同じく、`org.nspawn.manage` を持つユーザーは "root on the host"（ホストの root）だと書いています。マシンは root でコマンドを実行し、ホストの任意のパスをマウントできるためです。[USAGE.md](https://github.com/nspawn/nspawn/blob/3.2.1/docs/USAGE.md) も、group に渡すとその group がホストの管理者になる、としています。

つまり、root 以外のユーザーで動く GitLab Runner にジョブを流させるなら、そのユーザーにホストの root 相当を渡すことになります。環境変数1つで動く、という手軽さの裏にこの前提があることは、動画ではつながっていませんでした。

### コンテナの中からソケットを使う場合

3.0 の Breaking changes によれば、2.0.0 ではコンテナ内のソケットは読み取り専用でした。3.0 では、`/var/run/docker.sock`、`/run/docker.sock`、`/run/nspawn/api.sock` を `:ro` なしでマウントしたマシンは、コンテナの作成、起動、exec、削除、イメージの pull と削除、ボリュームとネットワークの作成ができます。`:ro` を付けると、読み取り、ログの追跡、kill だけで、ほかは 403 になります。ソケットに接続できるのは、マシン内の root だけです。読むだけのプロキシやダッシュボードは `:ro` でマウントすべきだ、というのがブログの注意です。ソケットごとのクライアントの接続数や exec などには上限があり、root 以外のユーザーにはその割り当てがあります。

3.1.0 は、動作中に現れたり消えたりするデバイス（USB の書き込み機器の例）向けに、`--device-cgroup-rule` を加えました。

動画の訂正です。

- 動画では、Docker Compose のファイルも一部の制限つきでほぼ流用できる、と紹介しました。一次の範囲で確認できるのは、`nspawn compose` が compose ファイルを読むことです。`docker compose` をソケットに向けて使えるとは書かれていません（[COMPOSE.md](https://github.com/nspawn/nspawn/blob/3.2.1/docs/COMPOSE.md)）。
- 動画では、すでに 3.2.0 まで出ていて、最新は 3.2.0 だ、と紹介しました。放送時点の最新は 3.2.1 です（[GitHub Releases](https://github.com/nspawn/nspawn/releases/tag/3.2.1)）。

## 3. Asahi Linux — M3 の一般提供と、MIT から GPL への移行

Asahi Linux の[進捗報告](https://asahilinux.org/2026/11/progress-report-7-3/)（11月7日、James Calligeros 氏）の内容です。以下は、特に断らない限り、Asahi の自己申告です。

### 7.3 の進捗

- メーリングリストに、2本の大きなドライバが載りました。macaudio と AVD で、ドライバと Devicetree の変更の量は、それぞれ約3,100行と約13,000行です。AVD は、チーム側のツリーに入って約3か月でリストに載り、主要な SoC 部品としては最短だったそうです
- M3 のサポートは、インストーラーの EXPERT フラグなしで一般提供になりました。早期採用者からの不具合の報告はほとんどなかった、とあります。[11月3日の記事](https://blog.fuga.jp/posts/2026-11-03-linux-oss-trend/)で触れた Fedora Asahi Remix 45 Beta の初期サポートの、その後の動きです。進捗報告によれば、Fedora Asahi Remix を Fedora と同じ日に出せたのは今回が最初です
- DCP を M3 で有効にできるようになり、スリープも有効にできるようになりました。m1n1 とカーネルの更新は数日以内に出る、としています。ノッチ周辺も使える状態になります。Fedora Magazine の [Fedora Asahi Remix 45 の告知](https://fedoramagazine.org/fedora-asahi-remix-45-is-now-available/)によれば、M3 で性能の出る 3D アクセラレーションを担う GPU ドライバは、まだ含まれていません
- Thunderbolt の初期サポートのパッチがリストに載り、ダウンストリームのカーネルに入れて配布も始まりました。対応は USB3、XDomain、Thunderbolt ネットワーキングです。PCIe と DisplayPort トンネリングは未対応で、どちらも多くの Thunderbolt ドックに必要だ、とあります。進捗報告は、2024年1月に年内の対応を約束したのは過ちだった、と振り返っています。2024年1月12日の[Asahi の記事](https://asahilinux.org/2024/01/fedora-asahi-new/)の文面は "should come sometime in 2024" でした
- FEX と WINE（ARM64EC）でゲームを動かす構成では、4 KiB のメモリページを見せる薄い VM の muvm による性能低下が、作業内容によって約20%あります。そこで Google の Android カーネルの P3S（プロセスごとのページサイズ）を Asahi のツリーに載せ、muvm なしで試すと、M2 Max の Mac Studio で Wolfenstein: The New Order が 144 FPS 以上で動きました。P3S は上流に入っておらず、チームはこのままダウンストリームで配布するつもりはなく、Google に質問中です
- M4 Pro・M4 Max・M5 の初期 Devicetree が、リストに投稿されました。TTY まで起動できる段階です。[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)の Linux 7.4-rc1 の M4 とは別の話です。あわせて、M4 と M5 のシリーズで macOS を仮想化してリバースエンジニアリングできるようになりました。解析のための仕組みで、利用者向けの機能ではありません

### ライセンスの移行

進捗報告は、すべてのリポジトリを GNU General Public License v2 以降へ移すプロセスを始める、としています。m1n1 は、2026年9月30日に再ライセンスされ、v2.0.0 から GPL です（[README](https://github.com/AsahiLinux/m1n1#license) は "version 2 (or later)" と書きます）。v1.9.9 までの MIT のコードは、MIT のまま使えます。確認時点で、asahi-installer など多くのリポジトリは MIT のままです。

理由として進捗報告が挙げるのは、寛容なライセンスを悪用して Asahi の成果を乗っ取り、プロジェクトを置き換えて Apple Silicon 上の Linux を積極的に収益化しようとする試みが複数あったことです。MIT はそれを明示的に許している、とも述べています。極端な例では、開発中の機能のコードが個人のフォークから持ち出され、帰属表示なしで公開されたり、出所を隠すために LLM で雑に書き換えられたりした、とあります。

動画の訂正です。

- 動画では、ライセンスを MIT から GPL v2 以降へ変更すると発表した、と紹介しました。書かれているのは、すべてのリポジトリを移すプロセスを始める、という段階です。m1n1 は v2.0.0 から GPL で、v1.9.9 までの MIT のコードは MIT のままです（[m1n1 の README](https://github.com/AsahiLinux/m1n1#license)）。
- 動画では、Asahi のコードを無断で流用した後継プロジェクトの存在を理由に挙げた、と紹介しました。進捗報告が挙げるのは、帰属表示なしの取り込みや、プロジェクトを乗っ取ろうとする試みが複数あったことです。MIT はそれを許している、とも述べています（[進捗報告](https://asahilinux.org/2026/11/progress-report-7-3/)）。
- 動画では、反応は賛否両論だ、と紹介しました。進捗報告にこの反応は書かれていません。確認できた出所は SNS だけです。

## 4. GitHub Actions のワークフロー依存ロックファイル — 一般提供

GitHub の [Changelog](https://github.blog/changelog/2026-10-28-github-actions-workflow-lockfiles-are-generally-available) は、10月28日 15:30（UTC。日本時間では10月29日（木）0:30）に、ワークフローの依存ロックファイルの一般提供を発表しました。同じ Changelog は、対象を GitHub Enterprise Cloud、data residency 付きの GitHub Enterprise Cloud、Team、Free の各プランとしています。[パブリックプレビュー](https://github.blog/changelog/2026-10-14-github-actions-workflow-lockfiles-in-public-preview)の発表は10月14日（水）でした。リポジトリの README からプレビューの注記を消す変更は、10月27日（UTC）に main に入り、v0.4.1（日本時間11月3日 3:53）のリリースに含まれました。

### 仕組みと導入

[docs](https://docs.github.com/en/actions/concepts/security/workflow-dependency-lockfiles) によれば、ロックファイルは `.github/workflows/actions.lock` にあり、`gh actions-lock` という GitHub CLI の拡張が生成します。手で編集してはいけません。参照が解決した正確なコミット、参照そのもの、ソースのリポジトリの数値 ID（`owner_id` と `repo_id`）を記録し、実行時に、その名前の先のリポジトリがロックしたものかを確かめます。docs は導入の理由として、タグは動かせるので、配布元のアカウントが侵害されてタグが付け替えられると、リポジトリが悪意あるコードを実行しうる点を挙げています。推移的な依存も固定します。

導入は `gh extension install github/gh-actions-lock` で拡張を入れ、`gh actions-lock` を実行します。[how-to](https://docs.github.com/en/actions/how-tos/secure-your-work/lock-workflow-dependencies) は、拡張がロックファイル以外も変更するので、差分全体を確認してからコミットするよう書いています。workflow の `uses` も、解決した版（たとえば `@v3` が `@v3.1.0`）に書き換わります。CI での検証は `--verify`、ネットワークなしで網羅だけを見るのは `--verify-local`、動いた参照を進めるのは、上流の履歴を確かめたうえで `--relock` です。

### 許可リストの注意

how-to によれば、ワークフローをロックファイルの管理下に入れたあと、許可リストはタグではなくロックされたコミットの SHA で照合されます。`actions/checkout@v6` のようなタグでの指定は、一致しなくなります。代わりにワイルドカードか、完全なコミット SHA を使います。導入前に、組織やリポジトリの許可リストを確認する必要があります。

### 限界と留意点

- `owner_id` や `repo_id` が変わるのはまれで、変わったときはマージする前に調べるよう docs は求めています。CLI の検証には、`owner_id` を書き換えても検証が失敗しないという報告の [Issue #211](https://github.com/github/gh-actions-lock/issues/211) があり、修正の PR #228 とともに確認時点で open です。`--verify` が必ず検出する、とは言えません
- Changelog は、ロックは依存そのものの安全性を判断しないので、ロックする前に依存を確かめるよう書いています。README は、浮動参照を履歴の古いコミットへ戻すロックファイルの変更は検出されないので、差分を見るか、完全なタグで固定するよう書いています
- Dependabot は、バージョン更新の PR で、対応するロックファイルの項目も再生成します。対象は、すでにロックファイルの管理下にある workflow に限ります
- 対象外が4つあります。ほかのリポジトリの再利用可能ワークフロー（[Issue #179](https://github.com/github/gh-actions-lock/issues/179) が open。確認時点）、ローカルアクション（他のリモートアクションを使うなら、`--migrate-local-actions` か `--ignore-local-actions` を指定するまでエラー）、コンテナイメージ（ダイジェストなしは警告）、GitHub Enterprise Server です

docs は、ロックファイルを採用したリポジトリでは workflow 内の SHA ピンは不要になる、としています。[9月28日の記事](https://blog.fuga.jp/posts/2026-09-28-linux-oss-trend/)で取り上げた完全なコミット SHA での固定は、ロックファイルが覆う範囲に限って書かずに済む、ということです。再利用可能ワークフローは、docs によれば、引き続き完全なコミット SHA で参照します。

動画の訂正です。

- 動画では、夏ごろからパブリックプレビューで、11月2日の 0.4.1 で README のプレビューの注記が消え、事実上の正式リリースになった、と紹介しました。GitHub は、10月28日（UTC。日本時間10月29日 0:30）に Changelog で一般提供（GA）を発表しています。注記の削除は10月27日（UTC）に main へ入り、0.4.1 に含まれました（[Changelog](https://github.blog/changelog/2026-10-28-github-actions-workflow-lockfiles-are-generally-available)）。
- 動画では、GitHub Enterprise Cloud で利用できる、と紹介しました。Changelog が挙げる対象は、GitHub Enterprise Cloud、data residency 付きの GitHub Enterprise Cloud、Team、Free です（[Changelog](https://github.blog/changelog/2026-10-28-github-actions-workflow-lockfiles-are-generally-available)）。
- 動画では、再利用可能ワークフローと Enterprise Server の制限については Issue が開いたままだ、と紹介しました。再利用可能ワークフローは [Issue #179](https://github.com/github/gh-actions-lock/issues/179) が open です。Enterprise Server の Issue は確認できませんでした。

## 5. Claude Code の許可リスト — 承認したコマンドが残るファイル

この節は、書き手が日常的に使っている製品の話です。擁護も煽りもせず、調査、公式ドキュメント、製品の当事者の発言を並べます。

Apiiro の[調査](https://apiiro.com/blog/coding-agents-leaking-secrets-github-dont-ask-again)は、11月5日に公開され、11月8日に更新されました。Apiiro はコードとリポジトリのセキュリティを扱う企業で、この調査は自社の領域に関わるものです。

### Apiiro の観察

以下は Apiiro の数値です。2026年11月1日から3日に、公開データを読み取り専用で集めたものです。

- 公開の GitHub に、`.claude/settings.local.json` が104,185個あり、1,122個（1.1%）に "real secret" が含まれていました。"real secret" は、既知の形式の鍵、または公開ホストの隣にあるパスワードやトークンを指し、有効かどうかは試していません。資格情報は使っておらず、ホストへの接続もしていない、と書いています
- 秘密が含まれ、追跡できた1,105のリポジトリのうち539で、Claude が共著者のコミットがそのファイルを変更していました
- 影響を受けた組織は63です
- gitleaks と TruffleHog を検証なしで走らせると、1,122個のうち前者は564個、後者は643個を検出し、215個はどちらにも検出されませんでした
- 16種類のコーディングエージェントを文書で比べ、承認した完全なコマンドを既定でプロジェクトのファイルに書くと確認できたのは Claude Code だけだった、としています。これは文書の比較で、"confirmed" の範囲です。Opus 5.5 と Fable 5.1 でも再現した、ともあります

Apiiro によれば、「今後は確認しない」を選ぶと、秘密を含む完全なコマンドが、プロジェクトの `.claude/settings.local.json` に保存されます。保存されたルールは、誰かが消すまで残ります。

### 公式ドキュメント

Claude Code の[設定のドキュメント](https://code.claude.com/docs/en/settings)は、Bash コマンドの許可を求められて "Yes, and don't ask again" を選ぶと、その承認が `.claude/settings.local.json` に `allow` ルールとして保存される、と書いています。そのファイルを無視していない git リポジトリで Claude Code が最初に書き込むとき、グローバルの git excludes に `**/.claude/settings.local.json` を足す、ともあります。手で作ったファイルで、Claude Code がまだ書き込んでいないものは対象外で、自分で `.gitignore` に追加するよう求めています。[権限のドキュメント](https://code.claude.com/docs/en/permissions)には、複合コマンドは部分コマンドごとに別のルールを保存し、プロンプトから保存したルールは選択肢の名指した範囲だけを覆う、とあります。コマンドの全文が保存されるという点は、Apiiro の観察です。

Apiiro は、グローバルの git excludes が覆わない場合として、後からリポジトリになったフォルダ、別のマシン、すでにコミットされたファイルを挙げています。リポジトリ自身の `.gitignore` には入らないので、プロジェクトと一緒に運ばれる保護はない、という指摘です。

### Claude Code チームの見解

[Hacker News のコメント](https://news.ycombinator.com/item?id=50408126)で、Claude Code チームの Boris Cherny 氏（Apiiro の表記では Anthropic の head of Claude Code）が答えました。時刻は2026年11月7日 21:13（UTC）、日本時間では11月8日 6:13 です。HN での自己紹介は "from the Claude Code team" です。要点は次のとおりです。

- これまで Claude Code は秘密の除去をしてこなかったが、防ぐために何ができるかを検討している
- `.claude/settings.local.json` はローカルに置くもので、Claude がファイルを作るときは自動で gitignore する。今回の公開ファイルは、手で作られてコミットされたものだ、という見方
- 許可ルールは古いやり方で、auto mode を使うほうが安全だ
- どのエージェントを使っていても、シークレットスキャンを有効にしておくべきだ

一方、Apiiro は、539のリポジトリで Claude が共著者のコミットがファイルを変更していたと報告しています。どちらが正しいかは、ここでは判定しません。

過去の報告として、anthropics/claude-code には、資格情報が保存される [#5544](https://github.com/anthropics/claude-code/issues/5544)（2025年8月11日）、`.gitignore` に入らない [#11982](https://github.com/anthropics/claude-code/issues/11982) と [#13106](https://github.com/anthropics/claude-code/issues/13106)、VS Code 拡張が追跡される settings.json に書く [#91270](https://github.com/anthropics/claude-code/issues/91270) があります。Apiiro によれば、3件が非アクティブか重複で自動クローズされました。確認時点（11月9日 7:55）では、4件とも bot が閉じています。4件に Anthropic からの返信は確認できませんでした。Apiiro は、公開前に Anthropic へ調査を共有したとしています。

### Apiiro の助言

対処は、Apiiro の順序では、先に鍵を無効化し、あとで片付けます。

1. ファイルがこれまでに保持した資格情報をすべて無効化し、再発行する。ファイルを消しても、git の履歴、フォーク、クローンには残ります
2. コミットしていなくても、ファイルを開いて、秘密を含むルールを消す
3. リポジトリで追跡されているなら、`git rm --cached` で追跡から外し、リポジトリ自身の `.gitignore` に追加する
4. 予防として、秘密をコマンドに直接書かず `$VAR` で参照し、`Bash(npm run:*)` のようなパターンで承認する

Apiiro はセキュリティチーム向けに、`.claude/`、`.cursor/`、`.gemini/` などのエージェントのフォルダを、ノート PC でもリポジトリでも `.env` と同じ機密として扱うよう書いています。

動画の訂正です。

- 動画では、データベースのパスワードが379件で最多だ、と紹介しました。Apiiro の図では、最多は Service API tokens の398件で、データベースのパスワードの379件は2番目です（[Apiiro の調査](https://apiiro.com/blog/coding-agents-leaking-secrets-github-dont-ask-again)）。

## まとめ

GPT-6 Cyber の数値は OpenAI の自己申告で、81件と CVE の対応は確認した範囲では公開されていません。Nspawn 3.0 のソケットは、`org.nspawn.manage` を渡す設定がホストの root 相当を渡すことと同じです。Asahi Linux は M3 の一般提供を伝え、ライセンスの移行は始まった段階です。GitHub Actions のロックファイルは GA で、許可リストの書き方に影響します。Claude Code の許可リストには、承認した内容が残り、その扱いについて調査と製品側の見解が分かれています。書き手は、これらを「承認の賞味期限」でまとめました。

手元で確かめておくものは次のとおりです。

- Claude Code: プロジェクトの `.claude/settings.local.json` を開き、秘密を含むルールがないか確かめる。コミットしていなくても確かめる。git の履歴にも残っていないか調べ、見つけたら先に鍵を無効化して再発行する
- Firefox: 159 以降の最新版か確かめる
- GitHub Actions: ロックファイルを導入する前に、許可リストにタグ指定（`actions/checkout@v6` など）がないか確かめ、ワイルドカードか完全な SHA にする。導入の差分は全体を確認する
- Nspawn: `org.nspawn.manage` を polkit で誰に付与しているか確かめる。コンテナにソケットをマウントするなら、読むだけのものは `:ro` にする

## 参考リンク

- [OpenAI: GPT-6 Cyber](https://openai.com/index/introducing-gpt-6-cyber/)
- [Mozilla MFSA 2026-118（Firefox 159）](https://www.mozilla.org/en-US/security/advisories/mfsa2026-118/)
- [Nspawn 3.0 のブログ](https://blog.nspawn.org/posts/nspawn-3-0-a-docker-compatible-engine-api-for-systemd-nspawn-containers/)
- [Asahi Linux 進捗報告 7.3](https://asahilinux.org/2026/11/progress-report-7-3/)
- [GitHub Changelog: ワークフロー依存ロックファイルの一般提供](https://github.blog/changelog/2026-10-28-github-actions-workflow-lockfiles-are-generally-available)
- [Apiiro の調査](https://apiiro.com/blog/coding-agents-leaking-secrets-github-dont-ask-again)

（2026/11/09 Linux・OSSトレンド）
