---
title: "RemoteToHome が管理するルーター183台中152台に不審な活動、GL.iNet は GoodCloud 経由の不正アクセスを11/20に特定、OpenAI と Cisco が eBPF の Shirudo をオープンソースで公開、KaOS 2026.11 は Plasma をリポジトリから削除、VKD3D 2.2 はシェーダーの浮動小数点の指定を反映、CISA が MONAI Label と MailAssure を KEV に追加し期限は11/26（2026/11/25 Linux・OSSトレンド）"
date: 2026-11-25T00:00:00+09:00
draft: false
tags: ["セキュリティ", "GL.iNet", "ルーター", "eBPF", "OpenAI", "Cisco", "AI", "AIエージェント", "KaOS", "Dinit", "VKD3D", "Wine", "CISA KEV", "CVE", "MONAI Label", "N-able"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

GL.iNet のルーターと KVM の一部は、クラウド管理の経路から侵入され、GL.iNet は更新で掃除できる範囲を説明しています。MONAI Label は、認証が既定で無効のまま公開されていました。2026年11月25日（水）の動画で扱った5本を、私は「任せた先で何が動いているのかを、自分の目で確かめられるか」という問いで読みました。

残りの3本も、確かめる手段の話として読めます。Shirudo は、AI が作った防御コードを、ベリファイア・署名・オペレーターの承認で通す作りです。KaOS は、既定のデスクトップを自分で選び直しました。VKD3D 2.2 は、アプリが求めた浮動小数点の扱いを反映するようになりました。5本を一本の線でつなぐのは書き手の考察で、各プロジェクトがそう言っているわけではありません。

動画の訂正は、各節の末尾に置きました。確認は2026年11月25日（日本時間）で、時点で変わる値には時刻を添えます。動画の公開は11月24日 21:23 UTC（日本時間 11月25日 06:23）です。

{{< youtube "XX0w8jTYXMk" >}}

## 1. GL.iNet のクラウド管理 GoodCloud 経由の不正アクセス

GL.iNet の通知（発行は11月20日、更新は11月23日、いずれも UTC）は、11月20日に、GoodCloud に接続された一部のルーターと KVM 機器への不正アクセスを特定した、と書いています。GoodCloud はクラウドのリモート管理サービスです。同じ11月20日に、特定した攻撃経路をふさぎ、既知のマルウェアを無効にして関連ファイルと痕跡を削除するセキュリティファームウェアを出した、とあります（[GL.iNet の通知](https://www.gl-inet.com/en-us/blogs/blog/glinet-security-notice-2026-11-20)）。

動画の題にある「183台中152台」は、RemoteToHome Consulting が自社で所有・管理するルーター183台を調べ、152台で不審な活動を見つけた、という値です。BleepingComputer（11月22日）の語は "suspicious activity" で、侵害を確認した台数ではありません。152台には、旧いバックドアだけが見つかった機器も含まれます。RemoteToHome 自身が、無作為抽出ではなく、自社が管理する機器のうち調査時に稼働していたものだと書いています。同社の調査まとめは、その後に更新され、199台中166台になっています（[BleepingComputer](https://www.bleepingcomputer.com/news/security/hackers-exploit-glinet-cloud-flaw-to-infect-routers-kvm-devices/)、[RemoteToHome のまとめ](https://github.com/RemoteToHome-io/gl-security-incident-2026)）。

GL.iNet の通知が挙げる問題は3つです。

- GoodCloud の MQTT メッセージの認可の設定ミス。クライアントが、必要な権限なしに、他のユーザーの機器へ管理メッセージを送れた。
- 別件の AstroWarp と SD-WAN の入力処理の欠陥。AstroWarp を無効にしていても、管理入力が root 権限のコマンドとして実行され得る。
- KVM の RTTY の証明書検証。起動時の引数が書き換えられると、サーバー証明書の検証を回避できる。

通知は、これらを "distinct issues"（別々の問題）と書いています。一方 RemoteToHome は、クライアントのコードを読んだ自分たちの解析として、AstroWarp の欠陥が攻撃の入口だったと述べています。GL.iNet が示す CVE は申請中で、番号は未確定です。

KVM 向けのインストーラーについて、BleepingComputer は、SSH 公開鍵を追加する機能が含まれると報じています。ルーターについては、RemoteToHome の解析を紹介する非公式のコミュニティサイト gl-i.net が、何もインストールされなかったと書いています。マルウェアの機能の詳細は、ここでは書きません。

更新と復旧について、GL.iNet の通知は次のように書いています。

- セキュリティファームウェアは、設定を引き継ぐ場合も含め、既知のマルウェアと関連ファイル・痕跡を削除する。ただし標的を絞った掃除で、一般的なマルウェア検査や完全性の確認ではない。
- 設定を引き継ぐと他の不正な変更が残り得るため、確実さは、設定を引き継がない再インストールより低い。
- コピーされた鍵やパスワードは、更新では取り消せない。更新または復旧のあとに、管理者パスワードと、使っていれば VPN 鍵・SSH 鍵を取り替える。
- KVM が対象なら、つないでいたコンピューターも念のため確認する。

通知の機種の表は、修正版が公開された機種の一覧で、侵害が確認された機種ではありません。修正版の日付は通知に書かれておらず、gl-i.net は、セキュリティ版が11月22日から24日付で、11月24日にさらに新しい安定版が出た、と書いています（[gl-i.net](https://gl-i.net/security/csa-2026-01/)。非公式のコミュニティサイトで、GL.iNet とは無関係と明記しています）。

動画の訂正です。

- 動画では、今回の攻撃でこの経路が使われたか、GL.iNet はまだ確認していない、と伝えました。正しくは、11月22日の時点では未確認と報じられていましたが、11月23日の更新で GL.iNet は AstroWarp の欠陥を事件の説明に載せ、報告を公開しています。ただし通知は、この欠陥が攻撃で使われたとまでは書いていません。
- 動画では、RemoteToHome Consulting を調べた機関と伝えました。正しくは、同社は自社の説明で、ネットワーク・VPN・IT のサービスを提供するセキュリティのコンサルティング会社です。調べたのは、自社が管理するルーターです。

## 2. OpenAI と Cisco が公開した Shirudo

OpenAI と Cisco は11月23日、Linux のシステムを守る、オープンソースのランタイム Shirudo を公開しました。名前は日本語の「シールド」で、README が "means shield" と説明しています。OpenAI は、脆弱性を突く動きを止める一時的な防御を shield と呼んでいます（以下、盾）。OpenAI の発表は、パッチを展開する間、運用中の Linux システムを守るものだと書きます（[OpenAI の発表](https://openai.com/index/introducing-shirudo/)、[Cisco の発表](https://newsroom.cisco.com/c/r/newsroom/en/us/a/y2026/m11/cisco-and-openai-launch-shirudo-a-new-project-to-safeguard-agentic-ai.html)）。リポジトリの所有者は、どちらの会社でもなく、GitHub の組織 shirudo-dev です。ライセンスは BSD-2-Clause で、BPF プログラムは BSD と GPL のデュアルです（[リポジトリ](https://github.com/shirudo-dev/shirudo)）。

狙いは、修正が全台に届くまでの隙間です。docs は、カーネルの修正が全台に届くのは、すべての機器が修正入りのカーネルで起動してからで、再起動の周期が数日から数週間なら、その間が空白になる、と説明しています（[docs](https://docs.shirudo.dev/start/what-is-shirudo.html)）。Shirudo はカーネル更新の代わりではない、とも書いています（[FAQ](https://docs.shirudo.dev/start/faq.html)）。

土台は eBPF で、カーネルの中の決まった位置に小さなプログラムを走らせる Linux の仕組みです。Isovalent のブログによると、Shirudo は、Isovalent が2022年に公開した Tetragon を起点に、エージェント向けに作り直したものです。人間向けのポリシー言語の代わりに、エージェントがコードで扱えるようにした、と書かれています（[Isovalent のブログ](https://isovalent.com/blog/post/cisco-openai-shirudo/)）。

Isovalent は、エージェントの流れを4段階に分けています。

1. 脆弱性の発見と情報収集
2. 緩和コードの生成。再現コードの生成、再現の検証、緩和点の評価、緩和コードの検証を含む
3. 署名した盾のロールアウト
4. 監視。盾に引っかかった回数は、守られた脆弱性への悪用の試みの数

デモは、OpenJDK の脆弱性 Java4Shell を使ったものです。OpenAI は、管理されたテスト（"controlled test"）で、Codex が作った盾が、Elasticsearch の稼働中のサービスに対する悪用の試みを、再起動なしに止めたと書いています。Java の Base64 のデコーダーに入力の検査を足す盾でした。Isovalent の表現は、緩和は有効に見える（"appears to be effective"）です。盾の取り付けは、デモでは実行中の Elasticsearch に対して行われました。docs は、Java の盾は JVM の起動時に読み込まれ、実行中の JVM は再起動するまで起動時のエージェントのままだと書いています。

確かめる手段としては、次の仕組みが書かれています。

- 機械による検査。盾は、読み込み前に暗号署名が検証される。カーネル側の eBPF プログラムは、カーネルのベリファイアが安全のルールに照らして調べる。Java の盾は、Shirudo がユーザー空間で検証する。
- 人の関与。オペレーターが盾を承認してから配備できる。強制する前に、盾がアプリケーションに与える影響を見ることもできる。ロールアウトの自律の度合いは、設計で変えられる（Isovalent）。
- 記録。読み込みと取り外しは、TPM の起動ごとのレジスターに積み上がり、`shirudo attest` が、オペレーターがオフラインで検証できる証跡を返す。

現状は、リポジトリの VERSION が `0.0.0-dev` で、README は pre-release と書いています。本番の対象には、署名付きローダーの ABI と Shirudo のカーネルパッチを備えた Linux カーネルと、TPM 2.0 が必要です。11月23日のリリースは prerelease の test kernel の1件だけで、確認はいずれも11月25日の時点です。発表は、Linux Plumbers Conference での10月6日のセッションにも触れています（[LPC のセッション](https://lpc.events/event/20/contributions/2437/)）。

動画の訂正はありません。

## 3. KaOS 2026.11 が Plasma をリポジトリから外す

KaOS は11月22日に 2026.11 を出し、KDE Plasma をリポジトリから削除しました。発表は、Plasma 6.8 が出たので、Plasma デスクトップは KaOS のリポジトリから削除された、と書いています。KDE アプリが必要とする Plasma の一部（libplasma など）は残り、KaOS は Qt 中心の配布のままで、ISO は GTK を含みません（[2026.11 の発表](https://kaosx.us/news/2026/kaos11/)）。KaOS は2013年の創設以来、KDE と Plasma だけを扱ってきたディストリビューションです（2026.02 の発表と、後述の systemd についての説明による）。

理由は、KaOS の説明では systemd です。Plasma の開発者が systemd との統合を強める変更を重ね、drkonqi は2025年の初めに systemd を必須にしました（"hard requirement"）。さらに、2023年7月の systemd 254 は、/usr を別パーティションにする構成を完全に扱う最後の版で、255 の NEWS は split-usr 対応の削除を書いています（[Systemd and the future of KaOS](https://kaosx.us/news/2026/systemd_kaos/)）。

KaOS 自身が書く経過は次のとおりです。

- 2025年の半ばに、init システムを Dinit にする試験を始めた。
- 2026.02 の ISO から、Plasma ではなく Niri と Noctalia を載せた。この ISO は systemd のままで、恒久の変更とは限らず、Plasma 6 はリポジトリに残る、と発表は書いていた（[2026.02](https://kaosx.us/news/2026/kaos02/)）。
- 2026.06 は、Dinit だけで動く最初の安定版 ISO、2026.09 は2本目。2026.09 の発表は、Plasma 6.7 が最後に提供される Plasma で、Plasma が 6.8 になればリポジトリから削除する、と予告していた（[2026.09](https://kaosx.us/news/2026/kaos09/)）。
- 2026.11 で、Plasma がリポジトリから削除された。

2026.11 の内容は次のとおりです。

- デスクトップは niri 26.04 と Noctalia 5.6.0。Noctalia 5 は Wayland と OpenGL ES の上に直接作られている（README は Qt も GTK も依存にない、と書く）。
- 起動、シート、サービスは dinit、turnstile、seatd。systemd の部品で使い続けるのは主に udev と tmpfiles で、elogind は、システムのログインではなく polkit のためだけに使う。
- ブートローダーは Limine が既定で、systemd-boot は選択肢から外れた。
- Qt5 が削除され、Qt 6 だけになった。
- 既知の制限として、polkit は turnstile と seatd への移植が未完了で、一部の権限昇格の操作が動かない。VirtualBox では 3D を有効にし、VMSVGA を使わないと起動しない。

「寄りかかる先を自分で選び直した」という整理は、書き手の考察です。

動画の訂正です。

- 動画では、Noctalia は Qt と QML のシェルで、KDE のライブラリを使う、と伝えました。正しくは、Noctalia 5 は Qt に依存せず、Wayland と OpenGL ES の上に直接作られています（KaOS 2026.11 の発表と Noctalia の README）。
- 動画では、systemd から残るのは udev と tmpfiles だけ、と伝えました。正しくは、発表の原文は「主に」（mainly）で、polkit のために elogind も使われています。

## 4. VKD3D 2.2

VKD3D は、Wine プロジェクトが管理する、Direct3D 12 を Vulkan の上に載せるライブラリです。2.2 のタグの日時は、2026年11月23日 12:00（+0100）で、UTC では11:00、日本時間では20:00です。変更点は、リリースの告知文（ANNOUNCE）の原文が、タグから読めます（[vkd3d-2.2 のタグ](https://gitlab.winehq.org/wine/vkd3d/-/tags/vkd3d-2.2)。Web では Anubis の確認が出ることがあり、本文は git で取得しました。ソースの配布は [dl.winehq.org](https://dl.winehq.org/vkd3d/source/) にあります）。

告知文が書く主な変更は、次のとおりです。

- 対応するシェーダーモデルの上限が 6.2 になった。
- VK_KHR_shader_float_controls 拡張が使え、対応する機能が公開されていれば、シェーダーが指定する非正規化数の扱いを使う。
- 同じ拡張で、shaderSignedZeroInfNanPreserveFloat16/32/64 の機能が使えれば、シェーダーに refactoringAllowed のグローバルフラグが無いことを尊重する。
- リフレクションでは、リソースのサンプル数の情報がメタデータに記録され、GetNumInterfaceSlots() が実装された。

告知文は、これらが2.2 で初の対応だとは書いていません。コードの差を見ると、2.1 は state.c で非正規化数の扱いを、指定なしの固定値にしていました。2.2 は、シェーダーの指定を渡す形に変わっています。ここでは、2.2 でシェーダーの指定を反映するようになった、とだけ書きます。対応する拡張が無い環境の挙動は、告知文に書かれていません。コードでは、非正規化数は指定なしに戻り、refactoringAllowed は「最適化してよい」扱いの上書きになります。

vkd3d-proton は別のプロジェクトです。README は、VKD3D の fork で、Proton の Direct3D 12 対応のために開発されていると書きます（[vkd3d-proton](https://github.com/HansKristian-Work/vkd3d-proton)）。Wine 本体への取り込み時期は、Wine 側の一次で確認できておらず、ここでは書きません。

動画の訂正はありません。

## 5. CISA KEV に MONAI Label と MailAssure

CISA は11月23日（月）、MONAI Label の CVE-2026-133968 と、N-able MailAssure の CVE-2026-134624 を KEV に追加しました。期限は、どちらも11月26日（木）です。いずれも米国の日付で、連邦文民行政機関に向けたものです。対応の根拠は、CISA の BOD 26-04 です（取得は11月24日 17:47 UTC 版の KEV フィード。[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)）。

追加から期限までは3日です。この3日は、追加日と期限から数えた値で、原文の語ではありません。2026年10月1日以降の追加65件を数えると、期限が3日後のものが50件、14日後が15件でした（書き手の集計）。3日は現在の KEV の標準的な期限で、10月26日の記事でも同じ整理をしています。

MONAI Label の CVE-2026-133968 は、医療画像の注釈用のオープンソースツールのパストラバーサルです。

- 影響は 0.8.5 以前で、修正は 0.8.6（11月22日 01:29 UTC、日本時間 10:29）。0.8.6 は Python 3.11 以上が必要です（[リリース](https://github.com/Project-MONAI/MONAILabel/releases/tag/0.8.6)）。
- アドバイザリによると、認証は既定で無効です。既定の設定なら、サーバーに届くネットワークのクライアントが悪用できます。認証を有効にしても、ANNOTATOR 権限があれば足ります。回避策は認証を有効にし、信頼できるユーザーにだけ権限を与えることです（[アドバイザリ](https://github.com/Project-MONAI/MONAILabel/security/advisories/GHSA-qc22-rmgc-vg94)）。
- 0.8.6 のリリースは、信頼できないネットワークに公開しないよう書いています。
- CVSS 9.8 は v3.1 で、NVD には MITRE の採点として載っています（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-133968)）。

この脆弱性への攻撃について、Amazon Threat Intelligence（CJ Moses 氏、11月20日）は、Cairn という AI エージェントの枠組みが使われたと書いています（[Amazon の調査](https://aws.amazon.com/blogs/security/chinese-nexus-actors-cairn-ai-agents-found-a-zero-day-on-their-own)）。

- 帰属は、中国と関連する攻撃者（"Chinese-nexus threat actor"）で、確度は中程度。中国本土の外の東アジアの大学に紐づく IP アドレスが標的で、2026年9月8日から約48時間の作戦です。
- 約11分は、アプリケーションの API のマッピングから、サーバー上の任意のファイルの書き込みまでの時間です。その後、root 権限のリバースシェルを得ました。
- Cairn を、Amazon はオープンソースの自律型ペネトレーションテストの枠組みと呼び、スパイ活動と犯罪の両方で採用が進んでいると書きます。最初のリリースは5月3日です。
- CSA のリサーチノートは、確認された被害は大学の研究サーバーで、患者データや臨床システムへの影響の報告は無い、と書きます。AI エージェントが実際の侵入の最中に未知の脆弱性を見つけた、公に記録された最初の事例の1つ、という位置づけです。CSA は、10月にも Zammad と DIVD の事例があると書いています（[CSA のリサーチノート](https://labs.cloudsecurityalliance.org/research/csa-research-note-monai-label-agent-discovered-zero-day-2026/)）。

N-able MailAssure の CVE-2026-134624 は SSRF です。20261121.1943 より前の版で、認証済みの API ユーザーが、サーバーから内部のホストとポートへ接続できます。CVSS 9.3 は v4.0 で、N-able の採点です（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-134624)）。N-able のインシデント更新は、この脆弱性を追跡するために CVE を公開したと書き、最初の調査で特定した N-able のホストするサーバー1台を超える悪用の証拠は見つかっていない、としています。侵入経路は書かれていません。ダッシュボードと API は、11月21日 23:45 UTC に復旧しました（[N-able](https://www.n-able.com/blog/mail-assure-incident-update)）。

動画の訂正です。

- 動画では、期限は追加から「わずか3日」と伝えました。正しくは、期限は11月26日で合っていますが、3日は現在の KEV の標準的な期限です。2026年10月1日以降の追加65件のうち50件が3日でした（書き手の集計）。
- 動画では、期限がかなり短いのは、それだけ実際の攻撃を重く見ているからだ、と伝えました。正しくは、期限の短さから攻撃の重さは読み取れません。KEV に載ったこと自体が、実際に悪用されている根拠です。

## まとめ

確かめる手段が、機器・コード・設定のどこにあるかを見る、という読み方は、書き手の考察です。実務で確認しておくものは次のとおりです。

- GL.iNet の機器: GoodCloud に接続したことがあるなら、通知の表で自分の機種の修正版を確認し、更新する。設定を引き継がない再インストールのほうが確実で、更新後は管理者パスワードと VPN 鍵・SSH 鍵を取り替える。KVM はつないでいたコンピューターも確認する。
- MONAI Label と MailAssure: MONAI Label は 0.8.6 以降にし、認証を有効にして、信頼できないネットワークに公開しない。MailAssure は、N-able が特定した脆弱性を修正したと書いている（20261121.1943 より前の版が対象）。KEV の期限は11月26日（米国の日付）。
- KaOS: Plasma はリポジトリから削除された。Polkit の移植が未完了で、一部の権限昇格の操作が動かない。更新の前に発表を読む。
- VKD3D 2.2: シェーダーの浮動小数点の指定は、対応する Vulkan の拡張があるときに反映される。ソースは dl.winehq.org にある。
- Shirudo: 0.0.0-dev の pre-release で、本番には専用のカーネルと TPM 2.0 が必要。

## 参考リンク

- [GL.iNet のセキュリティ通知](https://www.gl-inet.com/en-us/blogs/blog/glinet-security-notice-2026-11-20)
- [RemoteToHome Consulting の調査まとめ](https://github.com/RemoteToHome-io/gl-security-incident-2026)
- [OpenAI: Shirudo の発表](https://openai.com/index/introducing-shirudo/)
- [Isovalent のブログ](https://isovalent.com/blog/post/cisco-openai-shirudo/)
- [KaOS 2026.11 の発表](https://kaosx.us/news/2026/kaos11/)
- [vkd3d-2.2 のタグ](https://gitlab.winehq.org/wine/vkd3d/-/tags/vkd3d-2.2)
- [BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)
- [Amazon の調査](https://aws.amazon.com/blogs/security/chinese-nexus-actors-cairn-ai-agents-found-a-zero-day-on-their-own)
- [MONAI Label のアドバイザリ](https://github.com/Project-MONAI/MONAILabel/security/advisories/GHSA-qc22-rmgc-vg94)

（2026/11/25 Linux・OSSトレンド）
