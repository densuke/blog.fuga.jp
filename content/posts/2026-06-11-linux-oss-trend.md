---
title: "たった1文字がrootへの裏口に：nf_tables特権昇格、npmワーム「Miasma」、Debian 12 LTS移行、OpenSharing始動（2026年6月11日）"
date: 2026-06-11T06:00:00+09:00
tags: ["Linux", "Security", "nftables", "npm", "Debian", "Linux Foundation", "Mesa", "AI"]
categories: ["技術トレンド", "セキュリティ"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

梅雨入りして、なんだか足元のジメジメが気になる季節になりましたね。じつは今日のトレンド、まさにその「足元」がテーマなんです。

先日、知り合いのインフラ担当の方が「うちのコンテナ基盤、ホストのカーネルは共有だけど、名前空間でちゃんと分離されてるから安心」と話していました。気持ちはとてもよくわかります。私たちは普段、土台（カーネルやベースイメージ、依存パッケージ）が「当たり前に安全であること」を前提に、その上で仕事をしていますよね。でも今日お届けするニュースは、その当たり前の土台に **たった1文字** のヒビが入るだけで、root権限への裏口がぽっかり開いてしまう——そんなヒヤリとする話から始まります。

というわけで本日のトレンドレポートは、 **Linuxカーネル nf_tables の1文字バグ（CVE-2026-23111）** を筆頭に、わずか2時間で猛威を振るった **npmワーム「Miasma / Hades」** 、本日節目を迎えた **Debian 12 "Bookworm" のLTS移行** 、Linux Foundationが立ち上げた **OpenSharing Project** 、そして温故知新な **AIによるレガシーGPUドライバの延命** まで、たっぷり5本立てでお届けします。

まずは、本日のYouTube動画をこちらからご覧ください！

{{< youtube "mckC2ALmQ_4" >}}

---

## 注目のOSSトレンド Top 5

### 1. たった1文字のバグがrootへの裏口に──nf_tables の特権昇格・コンテナエスケープ（CVE-2026-23111）

トップバッターは、いまセキュリティリサーチャーとカーネルコミュニティが最も警戒しているお話です。Linuxカーネルのパケットフィルタリングを担う **nf_tables（nftables）** に、Use-After-Free（解放後メモリ使用）の脆弱性 **CVE-2026-23111** が見つかりました。CVSS v3スコアは **7.8（High）** 。数字だけ見ると「最高ランクではない」と感じるかもしれませんが、コンテナを多用する現代のクラウド基盤においては、スコア以上に深刻なインパクトを持っています。

なにより衝撃的なのが、その原因です。なんと **カーネルコード内のたった1文字、論理チェックの反転（誤った否定演算子）** という、ごくごく些細な人為ミスなんです。トランザクションが失敗してロールバック（アボート）する際、本来カーネルは要素を元の状態に戻そうとします。ところがこの1文字の誤りで復元ロジックが壊れ、 `chain->use` という参照カウンタが正しく増えず、ひたすら減り続けるという危うい状態に陥ってしまいます。

その結果、まだチェインを参照している要素が残っているのに参照カウンタがゼロに達してしまい、カーネルがそのメモリ領域を早すぎるタイミングで解放してしまう。攻撃者はその「解放済みの隙間」に別のデータを滑り込ませてカーネルメモリを破壊し、最終的には制御を奪ってroot権限を握る——という流れです。

そして本当に怖いのが、 **非特権ユーザー名前空間（unprivileged user namespaces）** と組み合わさったとき。通常、nf_tablesの操作には高い権限が必要ですが、非特権ユーザーでも自前のユーザー名前空間とネットワーク名前空間を `unshare` で作ってしまえば、脆弱なカーネルコードパスに手が届いてしまうんです。2026年6月8日にはExodus Intelligenceから、それに先立つ4月にはFuzzingLabsから完全なエクスプロイトの技術詳細が公開されました。そこでは Debian Bookworm / Trixie、Ubuntu 22.04 / 24.04 LTS といった主要環境で、非特権コンテナの内側からホストのroot権限を奪い、コンテナを脱出する手順までしっかり示されています。

| 項目 | 内容 |
| :---- | :---- |
| **影響コンポーネント** | Linux Kernel（nf_tables サブシステム） |
| **脆弱性識別子** | CVE-2026-23111 |
| **CVSS v3 スコア** | 7.8（High） |
| **攻撃の前提条件** | 非特権ユーザーへのローカルアクセス、非特権ユーザー名前空間の有効化 |
| **最終的な影響** | ローカル特権昇格（LPE）、カーネルコード実行、コンテナエスケープ |
| **一次パッチ適用日** | 2026年2月5日（アップストリームカーネル） |

アップストリームでは2026年2月5日に「余分な否定演算子を削除する」1文字のパッチがすでにマージ済みです。ただ、各ディストリビューションへのバックポートや本番システムへの適用にはどうしてもタイムラグがあり、いまだパッチ未適用のまま動いているシステムは少なくないと見られます。

対策としては、 **ホストカーネルのアップデートと再起動** が最優先。どうしてもすぐに再起動できない場合は、 `kernel.unprivileged_userns_clone=0` のSysctlで非特権ユーザーによる名前空間作成を制限したり、AppArmorやSeccompのプロファイルを見直してネットワーク名前空間の操作をブロックしたり、といった一時的な緩和策が強く推奨されます。たった1文字のタイポが現代のクラウド基盤全体を危険にさらす——この事実は、コードレビューだけに頼ることの限界と、 **Rust for Linux** のように言語仕様レベルでメモリ安全性を担保するアプローチの重要性を、改めて私たちに突きつけていますね。

### 2. わずか2時間で57パッケージ汚染──npmワーム「Miasma / Hades」と新隠蔽手法「Phantom Gyp」

続いては、JavaScript / Node.jsエコシステムを震撼させた、自己増殖型のサプライチェーン攻撃です。2026年6月3日から観測された **「Miasma」ワーム** の最新亜種（脅威インテリジェンスでは **「Hades」キャンペーン** とも呼ばれます）は、 **わずか2時間足らずで57以上のnpmパッケージ、286以上のバージョン** を汚染しました。標的には、月間40万ダウンロード超の `@vapi-ai/server-sdk` や、Red Hatが管理する `@redhat-cloud-services` 名前空間、さらには6月5日にはMicrosoft Azureの `durabletask` リポジトリまで含まれ、エンタープライズ開発環境に甚大な被害が出ています。

この攻撃の最大の特徴であり、業界に衝撃を与えたのが **「Phantom Gyp（ファントム・ジップ）」** という新しい隠蔽手法です。従来の悪意あるnpmパッケージは、 `package.json` の `preinstall` / `postinstall` といったライフサイクルスクリプトでマルウェアを起動するのが定番でした。ところが今回のワームは、 `package.json` に **インストールスクリプトを一切書きません** 。そのため、スクリプトを監視するタイプの静的解析ツールは、これを「正常なパッケージ」と誤認してしまうんです。

ではどこに罠を仕掛けるのか。攻撃者はパッケージのルートに、わずか **157バイトの `binding.gyp`** という構成ファイルを置きます。npmはインストール中にこのファイルを見つけると「ネイティブC/C++アドオンのビルドが必要だ」と判断し、裏で `node-gyp rebuild` を起動します。攻撃者はこの仕様を逆手に取り、GYPのコマンド置換構文 `<!(...)` を使ってビルド定義の中にOSコマンドを埋め込みました。具体的には `"sources": ["<!(node index.js > /dev/null 2>&1 && echo stub.c)"]` のように書くことで、表向きはダミーのCソースファイル名を返しつつ、裏で肥大化した悪意ある `index.js` をこっそり実行させる、という巧妙さです。

| 攻撃フェーズ | 実行内容と技術的手法 |
| :---- | :---- |
| **初期侵入** | 侵害したメンテナのトークンで公式パッケージ（`@vapi-ai/server-sdk` 等）に不正バージョンを公開 |
| **実行トリガー** | `package.json` を使わず、`binding.gyp` のコマンド置換構文 `<!(...)` を悪用（Phantom Gyp手法） |
| **ペイロード展開** | `node index.js` を裏で起動し、Bunランタイムを動的ダウンロードして実行 |
| **情報窃取** | `/proc/<pid>/mem` を走査し、GitHub Runnerプロセスから平文のシークレットやクラウド認証情報を窃取 |
| **自己増殖** | 盗んだ `NPM_TOKEN` で被害者の他リポジトリへマルウェアを自動公開し、ワーム的に拡散 |

起動したペイロードは、監視をかいくぐるためにGitHub Releasesから軽量な **Bunランタイム** をダウンロードし、ランダムな一時ファイル名で二次ペイロードを展開。そのうえでGitHub Actionsの `Runner.Worker` プロセスのメモリ（ `/proc/<pid>/mem` ）を直接スクレイピングして、マスクされる前の生のシークレットを抜き取ります。AWS・GCP・AzureのクレデンシャルやKubernetesのコンフィグ、開発者のSSH秘密鍵、npmトークンまで根こそぎ。そして盗んだnpmトークンで、その開発者が権限を持つ別パッケージへ自動的に改ざんバージョンを公開し、 **ワームのように増殖** していくのです。

AIインフラやSDKが狙われている背景には、AI開発の現場で高権限のAPIキーやクラウドアクセス権が環境変数として飛び交いがち、という事情があります。攻撃者にとっては宝の山なんですね。対策としては、静的解析だけに頼るサプライチェーン保護からの脱却が急務です。インストール時のネットワーク送信（エグレス）を厳格にブロックする、 `Harden-Runner` のような **ランタイム保護** で異常なメモリ読み取りを検知する、といった「ゼロトラスト・パッケージインストール」への発想転換が求められています。

### 3. 本日が節目──Debian 12 "Bookworm" 標準サポート終了とLTSへの移行

3つ目は、世界中のサーバー・コンテナイメージ・組み込み機器の土台になっている **Debian** の、大切なライフサイクルの節目のお話です。2023年6月10日にリリースされた **Debian 12（コードネーム：Bookworm）** は、ちょうど3年が経った本日 **2026年6月11日** をもって、Debianセキュリティチームによる標準サポートを終え、運用保守が **Debian LTS（Long Term Support）チーム** へと引き継がれます。

この移行は、単なる担当チームの交代にとどまりません。LTSによるサポートはここから約2年間、 **2028年6月30日まで** 提供されます。ただし標準サポート期間中はメインリポジトリのほぼ全パッケージ・全アーキテクチャが対象だったのに対し、LTSフェーズではコミュニティのリソース都合で **サポート対象パッケージが絞り込まれる** 傾向があります。アーキテクチャも、過去の傾向から amd64 / i386 / arm64 / armhf といった利用者の多い主要プラットフォームに限定されるのが一般的です。

さらに見逃せないのが、その先のロードマップ。2028年6月30日にDebian公式のLTSが終わったあとも、商用サポートを手がける **Freexian社** 主導の **Extended LTS（ELTS）** にシームレスに移行し、 **最長2033年6月30日まで** セキュリティパッチが提供される予定です。これは「一度入れたら長く動かし続けたい」エンタープライズや、容易にOSを入れ替えられない産業用IoT・組み込み機器の要請に、OSSコミュニティと商用スポンサーがしっかり手を組んで応えている、成熟したエコシステムの姿だと言えますね。

| リリース | 標準サポート終了 | LTSフェーズ | ELTSフェーズ（Freexian） |
| :---- | :---- | :---- | :---- |
| **Debian 11（Bullseye）** | 2024年8月14日 終了 | 2024年8月15日 〜 2026年8月31日 | 2026年9月1日以降（予定） |
| **Debian 12（Bookworm）** | 2026年6月10日 終了 | **2026年6月11日 〜 2028年6月30日** | 2028年7月1日 〜 2033年6月30日 |
| **Debian 13（Trixie）** | 未定 | 2028年8月9日 〜 2030年6月30日 | 未定 |

Debian 12を基盤やベースイメージに使っている方は、いまが現状把握と戦略判断のタイミングです。やっておきたいのは大きく3つ。まず、稼働中のDebian 12サーバー群を洗い出し、2028年のLTS終了までに次期安定版 **Debian 13 "Trixie"** への移行検証・マイグレーション計画を立て始めること。次に、自分たちが使っている固有パッケージやマイナーなライブラリがLTSで継続保守されるか確認すること（ `debian-security-support` のチェッカーツールでEOLコンポーネントを定期監査する自動化がおすすめです）。そして「5年以上OSを入れ替えられない」制約のある環境を設計しているアーキテクトの方は、 **ELTSの利用** を視野に入れた予算確保を早めに検討しておくこと。技術的負債を安全にコントロールする鍵になりますよ。

### 4. データとAI資産をまたいで共有──Linux Foundation「OpenSharing Project」始動

4つ目は、ぐっと前向きで未来志向なニュースです。エンタープライズへのAI導入が爆発的に進むなか、長年の壁だった「データのサイロ化」と「プラットフォームの分断」を打ち破るプロジェクトが動き出しました。 **Linux Foundation** は2026年6月10日、AI資産とデータの共有プロトコルを標準化するオープンプロトコル **「OpenSharing Project」** の立ち上げを正式発表しました。

このプロジェクトの核になっているのは、データウェアハウス／AI基盤の雄 **Databricks社** からLinux Foundationへ寄贈された技術です。系譜としては、すでに数千社に採用されているオープンソースのデータ共有プロトコル **「Delta Sharing」** を大きく進化させたもの。これまでのDelta Sharingが主に構造化データ（テーブルなど）の組織間共有に焦点を当てていたのに対し、OpenSharingは急成長する **「エージェンティックAI（Agentic AI）時代」** の要請に合わせて再設計されています。

具体的には、 **非構造化データ（テキストコーパス・画像・動画）** 、 **学習済みAIモデル（LLMの重みなど）** 、そして自律型エージェントの能力を定義する **「Agent Skills」** までを、まったく異なるプラットフォーム間でセキュアかつ統一的に交換できるフレームワークを提供します。さらに技術的に嬉しいのが **Apache Iceberg IRCクライアント** のサポート追加。これにより、オンプレに置いた巨大データセットを、パブリッククラウドの分析基盤へコピー・エクスポートすることなく **「ゼロコピー」のまま直接連携** できるようになります。

| 観点 | 従来のP2P API連携 | OpenSharing プロトコル |
| :---- | :---- | :---- |
| **データ連携の方式** | 物理コピー・ETL転送が必要 | ストレージ層を抽象化し、ゼロコピーでアクセス |
| **共有可能なアセット** | 主に構造化データ、限定的なファイル | 構造化・非構造化データ、AIモデル、Agent Skills に包括対応 |
| **プラットフォーム依存性** | ベンダー独自仕様、強いロックイン | ベンダーニュートラルなOSS、マルチクラウド対応 |
| **主な用途** | DB間同期、バッチ処理 | Apache Iceberg連携、自律型エージェント間のリアルタイム協調 |

今後のAIアーキテクチャは、単一の巨大LLMにプロンプトを投げるシンプルな形から、専門化した複数の自律エージェントが協調する **オーケストレーションモデル** へと移っていきます。OpenSharingでエージェントの「スキル」を標準プロトコルとして受け渡しできるようになれば、マルチベンダー環境での自律型AIエコシステム構築が一気に容易になります。そして何より、特定クラウドのプロプライエタリなマーケットプレイスに縛られる **ベンダーロックイン** から解放され、AWS・GCP・Azureとオンプレをまたいだ堅牢なデータ基盤を、オープンソースベースで設計できるようになる。データ転送コストを抑えつつガバナンスを効かせたい——そんなデータエンジニアにとって、OpenSharingは今後数年のインフラ設計のデファクトになる可能性を秘めています。

### 5. 18年前のGPUをAIで延命──Copilotが支えるレガシードライバ「R600g」のリファクタリング

最後は、技術の温かみを感じる「温故知新」なお話で締めくくりましょう。最先端のAIコーディングアシスタントは、新しいものを作るだけでなく、 **忘れられかけた過去のレガシーを救い延命させる** ツールとしても機能し始めています。Linuxデスクトップのグラフィックスを支えるオープンソースドライバスタック **Mesa** の次期バージョン26.2のリポジトリに、AMDの非常に古いGPU向けドライバ **「R600 Gallium3D（R600g）」** に対する、 **59件もの大規模リファクタリングコミット** が一挙にマージされました。

このR600gドライバが面倒を見ているのは、2007年登場のRadeon HD 2000シリーズから2010年代初頭のHD 6000シリーズまで。いまの基準ではすっかり **ヴィンテージ** な世代のハードウェアです。AMDによる公式サポートはとうに終わっており、この膨大で複雑なコードベースを保守しているのは、Mesaコミュニティのごく少数の有志（今回コミットを行ったGert Wollny氏など）だけ、という過酷な状況が続いていました。

コミュニティの注目を集めたのは、Wollny氏が `sfn`（シェーダコンパイラ）という非常に難解なC言語コードを整理するにあたり、 **「GitHub Copilot（自動モード）」を全面的に活用した** ことを、マージリクエストや個々のコミットメッセージで **明確に宣言した** 点です。これはAIを定型文生成や新機能追加に使ったのではなく、人間が保守を諦めかけていた数十年前の複雑なレガシーコードの文脈を読み解き、安全に構造を整理する **「強力なペアプログラマ」** として使った、とても実践的な事例なんです。

| GPUシリーズ | 発売年 | アーキテクチャ | Mesaにおけるドライバ保守の現状 |
| :---- | :---- | :---- | :---- |
| **Radeon HD 2000 〜 6000** | 2007年〜 | TeraScale（R600） | **R600g** ：メーカーサポート終了。OSS有志＋AI支援で保守 |
| **Radeon HD 7000 以降** | 2011年〜 | GCN | **RadeonSI** ：OSSコミュニティで安定稼働 |
| **Radeon RX 5000 以降** | 2019年〜 | RDNA | **RADV / RadeonSI** ：AMD・Valve等による強力な公式／OSS並行サポート |

この出来事は、OSSが長年抱えてきた **「ソフトウェアの腐敗（Software Rot）」** と **「メンテナ不足」** という慢性的な課題に、ひとつの希望を示しています。商用価値を失ったレガシーハードでも、AI支援で保守・学習コストを下げられれば、Linuxで使える期間をさらに数年単位で延ばせる。これは古いPCをテスト用やレトロゲーミングに再利用するコミュニティを助け、深刻化する **電子廃棄物（e-waste）の削減** にもつながる、とても良い動きです。

そしてもうひとつ大切なのが、 **「AI生成コードの受容と透明性」** へのポジティブな影響です。LKMLをはじめOSSの現場では、AI生成コードの著作権問題やハルシネーションによるバグ混入への警戒感が根強く、利用ルールの議論が続いています。そんななかWollny氏が、Copilotの利用をコミット履歴に正確にタグ付けして透明性を確保し、 **人間による十分なレビューとテストを経てマージ** したプロセスは、今後のOSS開発における「AIとの適切な協働の作法」のお手本になりそうです。エンジニアの役割は、誰も触りたがらないレガシーコードの書き換えをAIに委ね、人間はアーキテクチャの妥当性評価やエッジケースのテストに注力する——そんな、より高度なメンテナの姿へとシフトしていくのかもしれませんね。

---

## 今日の豆知識（今日は何の日 3選）

難解なコードのデバッグやサーバー運用で疲れた頭の息抜きに、今日（6月11日）が日本でどんな記念日なのか、エンジニア視点も少し交えて3つご紹介しますね。

1. **傘の日** 1989（平成元）年に日本洋傘振興協議会（JUPA）が制定した記念日です。暦の上で「入梅（梅雨入り）」にあたる時期であることが由来で、傘の販売促進や雨の日の過ごし方を提案する日とされています。インフラの世界で「傘」といえば、突発的なDDoSトラフィックを逸らすスクラビングセンターや、障害に備えるフェイルオーバーのスタンバイ環境を思い浮かべます。急な雨（障害やアクセススパイク）が降ってから慌てて傘を探すのではなく、晴れている平時のうちにしっかり傘（BCP対策やキャパシティプランニング）を準備して、定期的に開閉テスト（障害復旧訓練）をしておく。それが頼れるエンジニアの条件ですね。

2. **雨漏り点検の日** こちらも梅雨にちなんだ記念日。本格的な梅雨や台風シーズンの前に屋根や外壁の雨漏りを点検し、被害を未然に防ごうという目的で全国雨漏検査協会が制定しました。ITに置き換えるなら、さしずめ「メモリリーク点検の日」や「脆弱性の穴点検の日」でしょうか。今日トップで取り上げた nf_tables の脆弱性（CVE-2026-23111）のように、 **たった1文字の論理バグという小さなヒビ** から、特権昇格やコンテナエスケープという甚大な「雨漏り」が起きてシステム全体が水浸しになる——それがソフトウェアの怖いところです。脆弱性スキャナを回したり、依存パッケージのアップデート漏れがないか、今日はぜひシステムの「雨漏り点検」をしてみてくださいね。

3. **トヨタ自動車創業者・豊田喜一郎の誕生日（1894年）** 1894（明治27）年の6月11日は、トヨタ自動車の創業者・豊田喜一郎氏が誕生した日です。豊田自動織機製作所の創業者・豊田佐吉氏の長男として生まれ、米国フォード工場で流れ作業による大量生産を見学したことをきっかけに、日本の乗用車製造の礎を築きました。彼が情熱を注いだ生産プロセス、そして後に体系化された **「ジャスト・イン・タイム」や「カンバン方式」** といった無駄を省く思想は、海を越えて現代のソフトウェア開発にも輸入されています。私たちが当たり前に実践している **アジャイル開発・DevOps・CI/CD** の根底には、彼らが築いたモノづくりの哲学が息づいているんです。日本の製造業のレジェンドの誕生日が、現代のソフトウェアエンジニアリングの歴史にも深くつながっている——なんだか感慨深いですね。

---

## まとめ

今日は、2026年6月10日から11日にかけての、とても濃密で変化の激しいトレンドをお届けしました。

カーネルの **たった1文字** のバグが引き起こすコンテナ環境の崩壊（nf_tables CVE-2026-23111）、ビルドシステムの盲点を突いて静的解析をすり抜ける新次元のサプライチェーン攻撃（Phantom Gyp）、 **Debian 12** のLTS移行というインフラライフサイクルの節目、そしてLinux Foundationが主導するエージェンティックAI時代のデータ共有標準化（OpenSharing）。OSの深層からAIの最前線まで、パラダイムが急速に動いていることが伝わってきますね。その一方で、最新のAI（Copilot）を駆使して打ち捨てられかけた **古いGPUドライバを力強く延命** させるという、オープンソースならではの温かいトピックもありました。

インフラの安全確保と次世代技術のキャッチアップを両立させるのは、決して簡単な道のりではありません。でも、 **日々の小さなログの点検** と **コミュニティの動向を追い続ける学習** こそが、どんな攻撃や技術革新にも耐える堅牢なシステムを作る第一歩です。梅雨入りのこの時期、あなたの足元の土台、ぜひ一度しっかり点検してみてくださいね。このレポートが、明日のシステム運用や中長期のアーキテクチャ設計の、確かな指針になれば嬉しいです。

それでは、引き続き運用も開発も楽しんでいきましょう！

---

#### 引用文献

1. One-Character Linux Kernel Flaw Enables Local Root Access, Exploits Now Public - The Hacker News, 6月 11, 2026にアクセス、 https://thehackernews.com/2026/06/one-character-linux-kernel-flaw-enables.html
2. CVE-2026-23111: Public Linux Kernel nf_tables Exploit – Patch Now - Infosec.ge, 6月 11, 2026にアクセス、 https://infosec.ge/blog/cve-2026-23111-linux-kernel-nftables-container-escape/
3. Linux Kernel Bug Caused by Single Character Opens Path to Root Access - Security Boulevard, 6月 11, 2026にアクセス、 https://securityboulevard.com/2026/06/linux-kernel-bug-caused-by-single-character-opens-path-to-root-access/
4. CVE-2026-23111, the nf_tables Bug Behind a One-Character Root Privesc - Penligent, 6月 11, 2026にアクセス、 https://www.penligent.ai/hackinglabs/cve-2026-23111/
5. Off By !: Exploiting a Use-after-Free in the Linux Kernel - Exodus Intelligence, 6月 11, 2026にアクセス、 https://blog.exodusintel.com/2026/06/08/off-by-exploiting-a-use-after-free-in-the-linux-kernel/
6. CVE-2026-23111: Linux nf_tables Flaw Enables Root Exploits - Security Affairs, 6月 11, 2026にアクセス、 https://securityaffairs.com/193352/hacking/cve-2026-23111-linux-nf_tables-flaw-enables-root-exploits.html
7. Miasma npm Supply Chain Attack: Self-Spreading Worm via binding.gyp - StepSecurity, 6月 11, 2026にアクセス、 https://www.stepsecurity.io/blog/binding-gyp-npm-supply-chain-attack-spreads-like-worm
8. Miasma Worm Hits Microsoft Again: Azure Functions Action and 72 Other Repositories Disabled - StepSecurity, 6月 11, 2026にアクセス、 https://www.stepsecurity.io/blog/miasma-worm-hits-microsoft-again-azure-functions-action-and-72-other-repositories-disabled-after-supply-chain-attack-targeting-ai-coding-agents
9. Preinstall to persistence: Inside the Red Hat npm Miasma credential-stealing campaign - Microsoft Security Blog, 6月 11, 2026にアクセス、 https://www.microsoft.com/en-us/security/blog/2026/06/02/preinstall-persistence-inside-red-hat-npm-miasma-credential-stealing-campaign/
10. About Debian 12 Bookworm - Freexian, 6月 11, 2026にアクセス、 https://www.freexian.com/lts/extended/docs/debian-12-support/
11. LTS - Debian Wiki, 6月 11, 2026にアクセス、 https://wiki.debian.org/LTS
12. Debian 12 to Debian 13 Upgrade Guide (Bookworm to Trixie) - IT-Connect, 6月 11, 2026にアクセス、 https://www.it-connect.tech/how-to-upgrade-debian-12-to-debian-13-trixie/
13. When will the support time of Debian 12 end? - Reddit, 6月 11, 2026にアクセス、 https://www.reddit.com/r/debian/comments/1j9gqio/when_will_the_support_time_of_debian_12_end/
14. Linux Foundation Announces OpenSharing Project to Standardize AI Asset and Data Exchange - The Linux Foundation, 6月 11, 2026にアクセス、 https://www.linuxfoundation.org/press/linux-foundation-announces-opensharing-project-to-standardize-ai-asset-and-data-exchange
15. Linux Foundation Announces OpenSharing Project - PR Newswire, 6月 11, 2026にアクセス、 https://www.prnewswire.com/news-releases/linux-foundation-announces-opensharing-project-to-standardize-ai-asset-and-data-exchange-302796802.html
16. Databricks Announces OpenSharing, a New Open Standard for Sharing of Data and AI Assets - Databricks, 6月 11, 2026にアクセス、 https://www.databricks.com/company/newsroom/press-releases/databricks-announces-opensharing
17. CORRECTION — The Linux Foundation - Morningstar/PR Newswire, 6月 11, 2026にアクセス、 https://www.morningstar.com/news/pr-newswire/20260610dc80227/c-o-r-r-e-c-t-i-o-n-the-linux-foundation
18. Linux Developers Use Copilot to Revive R600 Driver - Let's Data Science, 6月 11, 2026にアクセス、 https://letsdatascience.com/news/linux-developers-use-copilot-to-revive-r600-driver-026547f6
19. AI helps keep vintage AMD Radeon Linux driver alive - VideoCardz.com, 6月 11, 2026にアクセス、 https://videocardz.com/newz/ai-helps-keep-vintage-amd-radeon-linux-driver-alive
20. 6月11日は「傘の日」 - YOUTH TIME JAPAN project web, 6月 11, 2026にアクセス、 https://www.ytjp.jp/2019/06/11/kyouhanannohi
21. 6月11日は何の日 - 今日は何の日 - Yahoo!きっず, 6月 11, 2026にアクセス、 https://kids.yahoo.co.jp/today/0611
22. 6月11日は何の日？（記念日、誕生日、出来事）- kinendar（キネンダー）, 6月 11, 2026にアクセス、 https://kinendar.com/anniversary/date/june/11.html
23. 今日は何の日：6月11日 - nippon.com, 6月 11, 2026にアクセス、 https://www.nippon.com/ja/japan-topics/today0611/
