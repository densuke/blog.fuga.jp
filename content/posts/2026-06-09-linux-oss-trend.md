---
title: 'セキュリティとAIの激動：rsync 3.4.4緊急リリース、VS Code 2時間遅延、nftables特権昇格、Firefox Vulkan Video、RISC-V Summit Europe（2026年6月9日）'
date: 2026-06-09T06:00:00+09:00
tags: ["Linux", "rsync", "VS Code", "nftables", "Firefox", "RISC-V", "Security"]
categories: ["技術トレンド", "セキュリティ"]
draft: false
---

こんにちは！コンテンツ制作部のライターです。

今日もやらかしてしまいました。先週、インクリメンタルバックアップを rsync で走らせていたら、いつも出ないはずの「failed verification -- update discarded」というメッセージが大量に出てきて、「ハードディスクが壊れた？」と真っ青になったんです。あちこちチェックしても原因がわからず、結局30分後にようやく「rsync の新しいバージョンにリグレッションがあった」とわかったときの脱力感……。
いや、ツールのバージョンアップは自動化しておくものだと思っていましたが、自動化が仇になるとは。「便利なはずの仕組みが足を引っ張る」という体験は毎回こたえますね。

というわけで今日のトレンドレポートは、まさにそのバックアップ騒動の続報である **rsync 3.4.4** を筆頭に、 **VS Code 1.123** のサプライチェーン防衛策、 **Linux カーネル nftables の深刻な特権昇格脆弱性（CVE-2026-23111）** 、 **Firefox の Vulkan Video Decoding 統合** 、そして **RISC-V Summit Europe 2026** で語られた「Open Physical AI」まで、盛り沢山でお届けします！

---

## 注目のOSSトレンド Top 5

### 1. rsync 3.4.4 緊急リリース！　AI支援コードをめぐるバックラッシュとメンテナの反論

ファイル同期の老舗インフラ **rsync** が久々に大きな騒動に巻き込まれました。2026年5月20日にリリースされた **rsync 3.4.3** は、6件の CVE を修正する重要なセキュリティアップデートだったのですが、本番環境に致命的な影響を与えるリグレッションが2件潜んでいたことが判明し、急遽 **rsync 3.4.4** が緊急リリースされるという事態になりました。

今回修正の目玉だったのが **CVE-2026-29518** です。デーモンモードで `use chroot = no` が設定されている環境下で発生する、TOCTOU（Time-of-Check to Time-of-Use）のシンボリックリンク競合脆弱性。ローカルの攻撃者が権限昇格や任意ファイルの上書きを行えてしまう危険なものでした。この修正のために、`secure_relative_open()` 関数の適用範囲をデーモンモードにも拡大するという大規模な改修が加えられた……のですが、これが裏目に出ました。

リグレッションの内容は2つ。 **Issue #924** として報告されたのが「Linux カーネル 5.6 未満の環境で `openat2()` システムコールが存在しないためビルドが完全に失敗する」問題。そして **Issue #928** として報告されたのが「SSH 経由で `--link-dest` を使った差分バックアップが、検証に失敗してアップデートが破棄されてしまう」問題です。冒頭のやらかしはまさにこれです……。

コミュニティがリグレッションの原因を探ってコミット履歴を掘り返したところ、「 `Co-Authored-By: Claude` 」という署名が大量に含まれていることが発見されました。「AI が生成した雑なコード（AI Slop）がコアインフラに混入してバグを招いた」という激しいバックラッシュが燃え上がったのは言うまでもありません。

これに対して rsync のメンテナであり、Samba の生みの親でもある **Andrew Tridgell** 氏が詳細な反論を公開しています。氏によれば、Claude を利用したのは「テストスイートのシェルスクリプトから Python への移行」という単純なコーディング作業（Grunt work）だけであり、アーキテクチャの設計は氏自身が厳密に行っていた。さらに Codex や Gemini でクロスチェックもしている。rsync のコアロジックや今回リグレッションを起こした箇所には AI は一切関与していないというのが事実です。

AI の使用自体がコミュニティの感情的な拒絶反応を呼び起こすという、透明性が逆にパラドックスを生む構図はなんとも皮肉ですね。なお、緊急リリースされた 3.4.4 でリグレッションはすべて修正済み。次期メジャー 3.5.0 に向けて **rsync-security メーリングリスト** も設立され、クローズドな環境でのセキュリティテスト体制が強化される方針です。3.4.3 を使っている方は今すぐ 3.4.4 に更新してください！

| rsync 3.4.3 における主要な変更とリグレッション概要 | 詳細と影響 |
| :---- | :---- |
| **セキュリティ修正（CVE-2026-29518）** | `use chroot = no` 設定時の TOCTOU 脆弱性を修正。`secure_relative_open()` の適用範囲を拡大。 |
| **リグレッション 1：ビルド失敗（Issue #924）** | カーネル 5.6 未満で `openat2()` が存在しない環境においてコンパイルが停止する不具合。 |
| **リグレッション 2：バックアップ破棄（Issue #928）** | `--link-dest` を伴う SSH 経由の差分バックアップで検証失敗・アップデートが破棄される問題。 |
| **テストスイートの刷新** | シェルスクリプトから Python へ移行。この工程で Claude 等の AI が補助的に利用された。 |


### 2. VS Code 1.123 の拡張機能「2時間遅延」でサプライチェーン攻撃を封じる

2026年6月3日にリリースされた **Visual Studio Code 1.123** で、拡張機能の自動更新に根本的な変更が加わりました。新しいバージョンが公開されてから最低 **120分（Cooldown period）** は自動インストールを保留するという仕組みです。

背景は深刻なサプライチェーン攻撃の増加です。拡張機能メンテナのアカウントがフィッシングやトークン流出で侵害され、マルウェアを仕込んだアップデートが数百万台の開発者端末に一斉配信されるというキルチェーンが現実になっています。2時間のバッファがあれば、侵害されたメンテナやコミュニティのリサーチャーが異常に気づき、配信を止める「猶予時間」として機能します。VS Code の UI でも、アップデートが保留されている理由と自動更新の実行予定時刻が明記されるため、ユーザー体験への配慮もしっかりされています。

ただし、ユーザーが手動で「Update」ボタンを押した場合は即時更新が可能です。緊急のバグフィックスを適用したい場合でもブロックされません。

一方で話題を呼んでいるのが **Trusted Publishers（信頼できるパブリッシャー）** の例外規定。「Microsoft」「GitHub」「OpenAI」はホワイトリスト化されており、2時間の遅延が免除されます。「大手組織でもサプライチェーン攻撃は起きうるのだから、全パブリッシャーに等しくルールを適用すべきでは」という声も上がっており、プラットフォーマーとしての利便性追求とセキュリティの哲学的対立が露わになっています。

この「一定時間のインストール保留」アプローチは、今やパッケージマネージャー全体のトレンドになっています。

| エコシステム・ツール | 導入された遅延機能・パラメータ名 | 導入バージョン |
| :---- | :---- | :---- |
| **VS Code** | 自動アップデートの 2 時間保留（Cooldown period） | v1.123 以降 |
| **npm** | `min-release-age` | v11.10.0 以降 |
| **Bun** | `minimumReleaseAge` | 1.3 以降 |
| **pnpm** | `minimumReleaseAge` | 10.16 以降 |
| **Yarn (Berry)** | `npmMinimalAgeGate` | 4.10.0 以降 |

CI/CD パイプラインや自動化スクリプトで「常に最新の拡張機能」を要求している方は、このクールダウンの存在を念頭に置いておく必要があります。セキュリティのために「意図的な遅延」をシステム設計に組み込む時代へのシフト、改めて実感します。


### 3. Linuxカーネル nftables に深刻な特権昇格脆弱性（CVE-2026-23111）

インフラ管理者の皆さん、急いでカーネルを更新してください。2026年6月8日、 **Exodus Intelligence** の **Oliver Sieber** 氏が、Linux カーネルの `nftables` に存在する深刻な特権昇格脆弱性 **CVE-2026-23111** の詳細なエクスプロイト手法を公開しました。ローカルの非特権ユーザーが root 権限を奪取できてしまうというものです。

問題の根本原因は `nft_map_catchall_activate()` 関数に潜んでいたわずか **1文字の論理エラー** です。`!`（NOT）が誤って付与されていました。

nftables はテーブル・チェーン・ルール・セット・マップといった階層構造でトラフィックを制御するフレームワークです。トランザクションが失敗した際には「アボート処理」が走り、システムの状態を元に戻します。この復元処理で、catchall 要素のアクティブ化関数が呼ばれず、特に NFT_GOTO 判定を持つ要素が保持している対象チェーンの参照カウント（`chain->use`）が正しく復元されない状態になります。

攻撃者はこのアボート処理を意図的に繰り返すことで参照カウントをひたすらデクリメントし続け、最終的にゼロに到達させます。カーネルは DELCHAIN 操作を成功と見なしてチェーンのメモリを解放してしまいますが、実際にはまだ catchall 要素がそのチェーンをポインタで参照しています。これが典型的な **Use-After-Free（解放後メモリ使用）** 状態を作り出し、任意コード実行・特権昇格が可能になるという巧妙なエクスプロイトチェーンです。

| nftables アボート処理における論理比較 | コードの挙動と影響 |
| :---- | :---- |
| **正常な関数** （`nft_mapelem_activate`） | `if (nft_set_elem_active(ext, iter->genmask)) return 0;` ― アクティブならスキップ。参照カウントが正しく復元される。 |
| **脆弱な関数** （`nft_map_catchall_activate`） | `if (!nft_set_elem_active(ext, genmask)) continue;` ― 条件が逆転。参照カウントが復元されない。 |
| **最終的な影響（Use-After-Free）** | 参照カウントが 0 に偽装されメモリが解放。後続のアクセスで特権昇格を許す。 |

この脆弱性が特に厄介なのは、 **ユーザー名前空間（User Namespaces）** が有効な環境、つまり **`CONFIG_USER_NS`** が有効な **Ubuntu 22.04 LTS / 24.04 LTS、Debian** などのデフォルト設定では、非特権ユーザーでも悪用できてしまう点です。コンテナを前提としたモダンなディストリビューションがそのまま攻撃の対象になります。

Sieber 氏の検証によれば、高負荷時でも成功率は **約80%** 、アイドル状態では **99%以上** という極めて高い安定性です。

対策はアップストリームのパッチ **コミット f41c5d1** が適用されたカーネルへの即時更新です。即時対応が難しい場合の緩和策として、`sysctl -w kernel.unprivileged_userns_clone=0` で非特権ユーザーによるユーザー名前空間の作成を無効化することが強く推奨されます。コンテナ技術に不可欠な利便性（名前空間）が同時に広大な攻撃対象領域を開いてしまうという、現代 Linux セキュリティの構造的なジレンマを改めて突きつける事例ですね。


### 4. FirefoxにVulkan Video Decoding が統合！　Linuxマルチメディアの長年の鬼門がついに解消へ

Linux デスクトップ環境における「動画再生のハードウェアアクセラレーション」は、長年エンジニアの頭を悩ませてきた鬼門でした。その状況を変える重要なコミットが Mozilla Firefox にマージされました。 **Linux 向け Firefox に Vulkan Video Decoding の初期サポートが統合** されたのです。

これまで Linux 上での Firefox の動画デコードは主に **VA-API** （Video Acceleration API）や **VDPAU** （Video Decode and Presentation API for Unix）に依存してきました。しかし Intel・AMD 向けのオープンソースドライバーでは VA-API が比較的うまく動くものの、プロプライエタリな NVIDIA ドライバー環境では完全な互換性を確保するのが極めて難しく、非公式なラッパーを介して無理やり動かすというハックが常態化していました。

この断片化を打破するために **Khronos Group** が策定したのが「 **Vulkan Video** 」拡張機能です。低オーバーヘッドな次世代グラフィックス API である Vulkan のコア機能の中に、 **H.264 / H.265（HEVC）/ AV1** のハードウェアデコード・エンコード命令を直接統合した完全なクロスプラットフォーム仕様です。

今回のマージが実現した背景には、エコシステム全体の準備が整ったことがあります。Mesa（Intel/AMD 向けオープンソースドライバー群）や NVIDIA 公式ドライバーが Vulkan Video の実装を進め、マルチメディアフレームワークのデファクトスタンダードである **FFmpeg 6.1** が Vulkan Video のデコード・エンコードサポートを本格導入したことで、ブラウザが利用する土台が完成しました。

| Linux ビデオアクセラレーション API の比較 | 特徴と現在の状況 |
| :---- | :---- |
| **VA-API** | Intel 主導で開発。オープンソースドライバーで広く使われるが NVIDIA 環境では難あり。 |
| **VDPAU** | NVIDIA 主導で開発された古い規格。現在はメンテナンスが滞りがち。 |
| **Vulkan Video** | Khronos 策定。GPU ベンダーを問わないクロスプラットフォームな単一コードパス。 |

最大の恩恵は「マルチメディアスタックの単一化」です。ブラウザベンダーは Windows の DXVA、macOS の VideoToolbox、Linux の VA-API といった OS 固有の複雑な API 群の保守から解放され、Vulkan という単一コードパスであらゆるプラットフォームのハードウェアデコードをカバーできるようになります。エンドユーザーにとっても CPU ソフトウェアデコードを回避でき、消費電力の低下とバッテリー駆動時間の延長という直接的な恩恵があります。

今後は NVK（オープンソース NVIDIA ドライバー）との相乗効果も期待されます。ただし、一部のハードウェア（例：Raspberry Pi 5）では VP9 コーデックのハードウェアデコード回路が搭載されておらず **HEVC のみ対応** という物理的な制約も残っています。Linuxグラフィックススタックの歴史的な転換点として、今後の動向を引き続き追いかけていきたいですね。


### 5. RISC-V Summit Europe 2026 が開幕！　「Open Physical AI」がエッジコンピューティングを変える

プロセッサ業界においてオープンソース ISA（命令セットアーキテクチャ）として急速に存在感を高めている **RISC-V** 。そのエコシステムの最前線を集めたカンファレンス「 **RISC-V Summit Europe 2026** 」が、2026年 **6月8日〜12日** の会期で **イタリア・ボローニャ** にて開催されています。欧州は RISC-V グローバルコミュニティの実に **3分の1** を占める重要なハブです。

今年のサミットで最も注目を集めているテーマが **「Open Physical AI」** という概念です。ETH チューリッヒとボローニャ大学でデジタル回路システムを率い、オープンソースの超低消費電力 RISC-V プロセッサプロジェクト **PULP（Parallel Ultra-Low-Power）** を主導する **Luca Benini** 教授が、基調講演「 **Enabling Open Physical AI** 」に登壇しました。

「Physical AI（物理 AI）」とは、クラウド上でテキストや画像を生成するソフトウェアベースの生成 AI とは明確に異なります。センサーを通じて現実の物理世界を認識し、推論を実行し、ロボット・自動車・スマートグラス・人工衛星などのアクチュエータを通じて物理的にインタラクトする AI システムのことです。ミリワット単位の極端な電力制約、リアルタイム性、そして高い安全性が求められる領域です。

また、このドメイン特化型の可能性を実証するユニークな事例として、 **サンパウロ大学** の研究チームによる **「Internet of Trees（木々のインターネット）」** プロジェクトも発表されました。熱帯雨林全体に超低電力のカスタム RISC-V プロセッサ搭載のセンサーネットワークを配備し、チェーンソーの音響データをリアルタイムのオンデバイス ML で検知して違法伐採を即座に特定するというものです。すごくロマンがある……！

| RISC-V Summit Europe 2026 における主要な技術テーマ | 詳細と今後の展望 |
| :---- | :---- |
| **Open Physical AI** | 現実世界と対話するエッジ AI。PULP プラットフォームによる超低電力アーキテクチャの実証。 |
| **Matrix Extensions（行列演算拡張）** | AI ワークロード（Transformer など）に不可欠な行列演算の標準化（IME / VME）。コンパイラ統合が進展中。 |
| **Internet of Trees** | 環境モニタリングに最適化されたカスタム RISC-V チップの展開。違法伐採の音響検知。 |
| **RISC-V Isolation Toolbox** | マイクロコントローラレベルでの物理メモリ保護やコンフィデンシャルコンピューティングのアーキテクチャ強化。 |

ソフトウェアエンジニアや組み込みアーキテクトにとって、このエコシステムの成熟は「ハードウェアとソフトウェアの境界線の融解」を意味します。オープンソースのツールチェーンで Transformer の推論タスクに必要な行列演算アクセラレータ（Matrix Extensions）をプラグイン感覚で組み込んだカスタムシリコンを設計し、その上のソフトウェアと協調設計（Co-design）するアプローチが現実的な選択肢になる時代、いよいよ目前に迫っています。Linux がクラウドを変革したように、RISC-V がエッジデバイスの世界を覆す歴史的転換点を目撃しているのかもしれません。

---

## 今日の豆知識（今日は何の日 3選）

### 1. 我が家のカギを見直す「ロックの日」

「6（ロ）9（ク）」の語呂合わせにちなんで、日本ロックセキュリティ協同組合が **2001年** に正式制定した記念日です。空き巣や自転車の盗難の多くが「無施錠」を狙った犯罪というデータを背景に、年に一度この日を契機に玄関や窓の鍵を点検しようという呼びかけです。

IT エンジニア的には「鍵」といえば IAM（ID・アクセス管理）や暗号化キー（Key Management）を思い浮かべますよね。物理的な南京錠もサイバーの PKI も、「鍵の管理が甘いとやられる」という本質は同じ。ローテーションされていない API キー、使われていない SSH 鍵……今日この機会に棚卸ししてみてはいかがでしょう。

### 2. 世界認定の日（World Accreditation Day）

**IAF（国際認定機関フォーラム）** と **ILAC（国際試験所認定協力機構）** が合同で立ち上げた世界規模のイニシアチブによる記念日です。「認定（Accreditation）」とは、製品・サービス・マネジメントシステムが国際規格に基づいて正しく・公平に評価されていることを、信頼できる第三者機関が保証するプロセスのことです。

IT 業界では ISMS（情報セキュリティマネジメントシステム）やクラウドセキュリティの各種認証、ハードウェアのコンプライアンス試験などが「認定」の枠組みの上に成り立っています。今回の nftables 脆弱性も、CVE の採番・公開プロセス自体がこうした国際的な「認定」インフラに支えられていると思うと、縁を感じますね。

### 3. ピョートル1世、ジョニー・デップ、ナタリー・ポートマンの誕生日

歴史を振り返ると、6月9日は社会や文化に大きなインパクトを与えた人物たちが生まれた日です。

**1672年** には、遅れていたロシアを劇的に近代化・西欧化した **ピョートル1世（大帝）** が誕生しています。既存の古いシステムを根本から解体して最新のアーキテクチャを果敢に導入したその姿勢、究極のシステムアーキテクト感がありますね。一方で現代エンターテインメント界からは、カメレオンのような演技で世界中を魅了する俳優 **ジョニー・デップ** （ **1963年** 生まれ）と、知性と表現力でアカデミー賞を受賞した **ナタリー・ポートマン** （ **1981年** 生まれ）の誕生日でもあります。高い専門性と豊かな表現力を武器に世界を牽引するクリエイターたちに思いを馳せながら、日々のコードにも創造性のスパイスを忘れずにいきたいですね。

---

## まとめ：「信頼・プロセス・開放性」をめぐる一日

今日のトピックを振り返ると、通底するテーマが浮かび上がります。それは **「技術の進化に対する、人間（コミュニティ）とプロセスの適応」** です。

rsync の AI 支援コード騒動は、AIの使用という事実そのものが感情的な拒絶を引き起こすパラドックスを証明しました。一方で VS Code の 2 時間遅延は、「継続的デリバリーの即時反映」というベストプラクティスを見直し、セキュリティのための意図的な摩擦をシステムに組み込む時代へのシフトを示しています。

nftables の CVE-2026-23111 は、コンテナ技術に不可欠な利便性（ユーザー名前空間）が同時に致命的な刃となってしまうジレンマを突きつけました。その一方で Firefox の Vulkan Video 統合と RISC-V Summit の Open Physical AI は、抽象化レイヤーの無駄を取り除きハードウェアリソースを極限まで効率的に使う「オープンソースの力強い潮流」を確認させてくれました。

どれも一筋縄ではいきませんが、技術の表層だけでなく、その背後にあるアーキテクチャの変化とコミュニティの力学を読み解く「見立ての力」が問われているのは間違いないですね。

（皆さんのサーバー、nftables のパッチは当たってますか？ CVE-2026-23111 への対応状況や、VS Code の 2 時間遅延でハマったこと・逆に助かったことなど、ぜひ X（旧 Twitter）で「 `#Agyテックブログ` 」のハッシュタグを添えて教えてください！　思わぬ事例が集まると嬉しいです。）

それでは、また次回の記事でお会いしましょう！

---

#### 引用文献

1. rsync - Samba.org, 6月 9, 2026にアクセス、 https://www.samba.org/rsync/
2. NEWS for rsync 3.4.3 (20 May 2026) - Samba.org, 6月 9, 2026にアクセス、 https://download.samba.org/pub/rsync/NEWS
3. rsync 3.4.3 and later won't build for Linux < 5.6 out of the box due to openat2() #924 - GitHub, 6月 9, 2026にアクセス、 https://github.com/RsyncProject/rsync/issues/924
4. rsync over ssh with relative basis --link-dest=../snap.1 can fail with "failed verification -- update discarded" in 3.4.3 · Issue #928 · RsyncProject/rsync - GitHub, 6月 9, 2026にアクセス、 https://github.com/RsyncProject/rsync/issues/928
5. Rsync GitHub Outrage Over Claude AI Use and Buggy Update, 6月 9, 2026にアクセス、 https://www.it-connect.tech/github-backlash-erupts-over-rsync-and-claude-ai-use/
6. Remove all LLM generated commits before people get hurt by this nonsense. · Issue #934 · RsyncProject/rsync - GitHub, 6月 9, 2026にアクセス、 https://github.com/RsyncProject/rsync/issues/934
7. Rsync 3.4.3 might break incremental backups for you - Reddit, 6月 9, 2026にアクセス、 https://www.reddit.com/r/sysadmin/comments/1tqvkxz/rsync_343_might_break_incremental_backups_for_you/
8. Rsync 3.4.3 Regressions Trigger Debate Over AI-Assisted Code - Linuxiac, 6月 9, 2026にアクセス、 https://linuxiac.com/rsync-3-4-3-regressions-trigger-debate-over-ai-assisted-code/
9. rsync and outrage - Medium, 6月 9, 2026にアクセス、 https://medium.com/@tridge60/rsync-and-outrage-d9849599e5a0
10. rsync 3.4.4 released, regression fixes - oss-sec - Seclists.org, 6月 9, 2026にアクセス、 https://seclists.org/oss-sec/2026/q2/830
11. VS Code Adds 2-Hour Delay for Extension Updates - IT-Connect, 6月 9, 2026にアクセス、 https://www.it-connect.tech/vs-code-adds-a-2-hour-delay-to-extension-updates-to-help-block-attacks/
12. VS Code adds 2-hour delay for extension updates to combat supply chain threats - SC World, 6月 9, 2026にアクセス、 https://www.scworld.com/brief/vs-code-adds-two-hour-delay-for-extension-updates-to-combat-supply-chain-threats
13. VS Code 1.123 Adds Two-Hour Extension Auto-Update Delay - AI Weekly, 6月 9, 2026にアクセス、 https://aiweekly.co/alerts/vs-code-1123-adds-two-hour-extension-auto-update-delay
14. VS Code Adds 2-Hour Extension Auto-Update Delay to Limit Supply Chain Attacks - The Hacker News, 6月 9, 2026にアクセス、 https://thehackernews.com/2026/06/vs-code-adds-2-hour-extension-auto.html
15. Off By !: Exploiting a Use-after-Free in the Linux Kernel - Exodus Intelligence, 6月 9, 2026にアクセス、 https://blog.exodusintel.com/2026/06/08/off-by-exploiting-a-use-after-free-in-the-linux-kernel/
16. CVE-2026-23111 Common Vulnerabilities and Exposures - SUSE, 6月 9, 2026にアクセス、 https://www.suse.com/security/cve/CVE-2026-23111.html
17. CVE-2026-23111 Detail - NVD, 6月 9, 2026にアクセス、 https://nvd.nist.gov/vuln/detail/CVE-2026-23111
18. CVE-2026-23111 - Red Hat Customer Portal, 6月 9, 2026にアクセス、 https://access.redhat.com/security/cve/cve-2026-23111
19. New Linux Kernel Vulnerability Lets Attackers Escalate Privileges to Root - Cybersecurity News, 6月 9, 2026にアクセス、 https://cybersecuritynews.com/linux-kernel-nftables-vulnerability/
20. CVE-2026-23111: Linux Kernel Privilege Escalation Flaw - SentinelOne, 6月 9, 2026にアクセス、 https://www.sentinelone.com/vulnerability-database/cve-2026-23111/
21. Firefox Merges Support For Vulkan Video Decoding - Slashdot, 6月 9, 2026にアクセス、 https://news.slashdot.org/story/26/06/08/1630210/firefox-merges-support-for-vulkan-video-decoding
22. 1753129 - Using Vulkan Video Decode API to hardware decoding - Bugzilla@Mozilla, 6月 9, 2026にアクセス、 https://bugzilla.mozilla.org/show_bug.cgi?id=1753129
23. Mesa 26.0.0 Release Notes - Mesa3D, 6月 9, 2026にアクセス、 https://docs.mesa3d.org/relnotes/26.0.0.html
24. It looks like Vulkan video decode has finally merged for Firefox 153 - Reddit, 6月 9, 2026にアクセス、 https://www.reddit.com/r/linux/comments/1tz1o0p/it_looks_like_vulkan_video_decode_has_finally/
25. Firefox Merges Support for Vulkan Video Decoding - Hacker News, 6月 9, 2026にアクセス、 https://news.ycombinator.com/item?id=48439348
26. RISC-V Summit Europe 2026 - Welcome, 6月 9, 2026にアクセス、 https://riscv-europe.org/summit/2026/
27. RISC-V Summit Europe 2026: Industry and Academia Unite in Bologna - EE Times, 6月 9, 2026にアクセス、 https://www.eetimes.com/risc-v-summit-europe-2026-industry-and-academia-unite-in-bologna-to-advance-open-hardware/
28. RISC-V Summit Europe 2026 - Presentations, 6月 9, 2026にアクセス、 https://riscv-europe.org/summit/2026/presentations
29. HyperCroc: End-to-End Open-Source RISC-V MCU with a Plug-In Interface for Domain-Specific Accelerators - arXiv, 6月 9, 2026にアクセス、 https://arxiv.org/abs/2603.12308
30. ロックの日 - 雑学ネタ帳, 6月 9, 2026にアクセス、 https://zatsuneta.com/archives/106091.html
31. ６月９日はロックの日！！ - 愛知県蟹江町公式ホームページ, 6月 9, 2026にアクセス、 https://www.town.kanie.aichi.jp/soshiki/5/rokkunohi.html
32. IAF/ILAC 2011年「世界認定の日」について, 6月 9, 2026にアクセス、 https://isms.jp/iaf/WAD/index.html
33. 6月9日は何の日？記念日、出来事、誕生日などのまとめ雑学 - ダレトク雑学トリビア, 6月 9, 2026にアクセス、 https://netlab.click/todayis/0609
