---
title: "Optimizely の配信網から178組織にスキマー、Docker 29.10.0 はループバックの扱いを変更、MATE 向け Wayland コンポジター Polo 1.0.0、Node.js は16件を修正、ScreenConnect の CVE-2026-84869 に待ち伏せ（2026/11/18 Linux・OSSトレンド）"
date: 2026-11-18T00:00:00+09:00
draft: false
tags: ["セキュリティ", "サプライチェーン攻撃", "CSP", "Docker", "Wayland", "MATE", "Node.js", "CVE", "ScreenConnect"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

正規の配信ルートや、いつもどおりの設定が、そのまま事故の通り道になる。2026年11月18日（水）の動画が取り上げたのは、そういう5本です。

Optimizely の配信網から、Zoom や BBC など178組織にカード情報を盗むスクリプトが届きました。Docker Engine 29.10.0 では、insecure-registries を自分で書いている環境で、ループバックのレジストリに繋がらなくなることがあります。MATE 向けの Wayland コンポジター Polo は 1.0.0 が公開されました。Node.js は11月のセキュリティリリースで16件を直しています。ScreenConnect の CVE-2026-84869 はテクニシャン側のクライアントの欠陥で、悪用を待ち伏せる動きを Huntress が観測しています。

5本を1つのテーマでつないだのは書き手の考察で、各社や報告者の主張ではありません。動画の訂正は、該当する節の末尾に置きました。確認は2026年11月18日（日本時間）の朝です。Optimizely の被害集計は Report URI の11月17日 09:17（UTC）の更新版、Polo の最新版（1.0.2）と Node.js の CVE の NVD の状態は、この朝の時点のものです。

{{< youtube "Lau36cqkZVo" >}}

## 1. Optimizely の配信網経由のスキマー

11月16日（月）、Optimizely Web の実験用プラットフォームを通じて、悪意のある JavaScript が178組織の訪問者に配られました。調べたのは Report URI の Scott Helme 氏で、[Report URI の分析](https://blog.report-uri.com/worlds-largest-brands-infected-with-malware-via-optimizely/)には Zoom、BBC、CNN、Salesforce、HSBC などが挙がっています。1,611本のスニペットを取得して188本が感染しており、実数はこれより多い可能性がある、と Report URI は書いています。各社自身のコードや基盤が侵害されたとは限らず、第三者の依存先を通じて汚染された、という説明です。

顧客が読み込むスニペットには、Optimizely のコード、顧客の実験、顧客が自分のコードを書き込める欄が入っています。攻撃者はその欄に自分のコードを書き込みました。多くは cdn.optimizely.com から、Optimizely の証明書で配られ、自社のドメインから配る顧客も影響を受けました。

入り口について、Optimizely が BleepingComputer に述べた声明では、Experimentation のアカウントのサインアップの流れにある脆弱性を未認可の第三者が悪用し、一部の顧客プロジェクトに悪意のある JavaScript を追加した、とされています（[BleepingComputer](https://www.bleepingcomputer.com/news/security/optimizely-supply-chain-attack-delivers-malware-to-cnn-fox-news-bbc-salesforce-sites/)）。一方で Report URI は、多数の無関係な顧客プロジェクトへの書き込み権をどう得たかは分からず、Optimizely が説明すること、と書いています。Optimizely の[ステータスページ](https://status.optimizely.com/incidents/ftw0fh9wx43z)は、脆弱性を修正し、影響を受けたプロジェクトから注入されたコードを削除した、と11月17日 01:02（UTC。日本時間では10:02）に投稿しました。感染していたファイルがすべて除染されたのを Report URI が観測したのは、11月16日 23:11（UTC）です。

Report URI は、呼び出し方を3通り確認しています。外部スクリプトを直接読み込む形、その URL を隠した形、外部が止められた場合の予備として中身を内蔵した形です。除染のあとに再び感染した例もあり、中身はその日のうちに26回作り直されました。

機能は4つです。暗号資産の書き換え（08:10 UTC）の後にカードのスキマー（13:43 UTC）が加わり、iPhone を狙うキットも追加されました。

- 暗号資産: 複数のチェーンのアドレスを、画面、クリップボード、通信の中身で差し替える。
- カード: カード番号（Luhn の検算つき）、有効期限、セキュリティコードを集める。ホスト型の決済フレーム（Stripe、Adyen など）の入力には届かず、サイト独自の入力欄は対象になった。
- Cookie とスクリーンショット: アドレスを差し替えたときに、JavaScript から読める Cookie とページの画像を送る。
- iPhone: iOS の版によって別の経路を使い分ける。

BBC での最初の注入は11月16日 04:21（UTC。日本時間 13:21）で、メインの攻撃ドメインの登録（05:23 UTC）より前でした。

CSP（Content Security Policy。読み込んでよいスクリプトや通信先をブラウザに指示する仕組み）の効果も Report URI が調べており、ペイロードを止めたのは24組織、CSP が無かったのは68組織、ペイロードと送信を許したのは50組織でした。Report URI によると、Optimizely のドキュメントは unsafe-eval を許可するよう案内しており、予備の内蔵版は外部が止められても eval を通して動きました（HSBC の例）。

暗号資産は、Report URI の集計で、11月16日 19:25（UTC。日本時間では17日 04:25）の時点で約7,040ドルが攻撃者のウォレットに入っていました。カードの件数や感染した iPhone の台数は、見る手段が無く分かっていません。運営者向けの確認は、Report URI の "What to do now" にあります（まとめに抜粋）。

動画の訂正です。

- 動画では、CSP を調べた256のホストのうち、攻撃を完全に止められていたのは24で、およそ15%だと伝えました。正しくは、Report URI の表で「ペイロードを止めた（Payload blocked）」のは24で、表では15%と書かれています。この15%は表の内訳の合計159に対する割合で、調べた256に対しては約9%になります。「完全に」は一次の語ではありません（[Report URI](https://blog.report-uri.com/worlds-largest-brands-infected-with-malware-via-optimizely/)）。
- 動画では、暗号資産で約7052ドルが攻撃者に渡ったと集計されている、と伝えました。正しくは、Report URI が11月16日 19:25（UTC）の時点で約7,040ドルと集計しています。BleepingComputer は約7,000ドルと書いています（[Report URI](https://blog.report-uri.com/worlds-largest-brands-infected-with-malware-via-optimizely/)）。

## 2. Docker Engine 29.10.0 のループバックの扱い

Docker Engine 29.10.0 は11月16日（月）の公開です（[リリースノート](https://docs.docker.com/engine/release-notes/29/)の日付）。リリースノートは "Potential breaking change"（破壊的変更の可能性）として、HTTP か信頼されない TLS 証明書のローカルのレジストリへの pull と push が失敗することがある、と書いています。

insecure-registries は、TLS を使わない（平文の HTTP）か、デーモンの知らない CA の証明書を使うレジストリを並べる設定です（[dockerd のリファレンス](https://docs.docker.com/reference/cli/dockerd/)）。これまでは、設定の中身にかかわらず、デーモンがループバックのアドレス（127.0.0.0/8 と ::1/128）を自動でこの一覧に足していました（[moby の PR #53868](https://github.com/moby/moby/pull/53868)）。29.10.0 では、`daemon.json` に insecure-registries を明示するか `--insecure-registry` を使うと、ループバックを自動では足しません。設定を省いていれば、これまでどおりです。社内のレジストリを1つ書いただけの環境でも、ローカルのレジストリに繋がらなくなることがあります。

リリースノートの案内は、信頼される証明書で TLS を構成するか、必要なローカルレジストリのアドレス（例: `localhost:5000`）だけを既存の insecure-registries に足すことです。`daemon.json` に `"insecure-registries": []` を置くと、既定の insecure なレジストリがすべて無効になります（フラグでは空にできません）。この設定は、dockerd のリファレンスによると、プロセスを再起動せずに読み直せます。

事例として、shakenfist/kerbside-patches の [Issue #2115](https://github.com/shakenfist/kerbside-patches/issues/2115) があります。起票者の mikalstill 氏は、自己署名証明書の TLS レジストリへの push が x509 の証明書エラーで失敗した、と報告しています。同じ Issue には、版を固定せずに docker-ce を入れる CI のジョブが、29.10.0 の公開後に6回中6回失敗したことも書かれています。ここからは書き手の考察ですが、ローカルのレジストリを使う CI では、ランナーの Docker の版が固定されているかを一度確かめておくと安心です。

あわせて、containerd がループバックなどで暗黙に HTTP へ切り替える動きを、Docker がセキュアと判断したレジストリでは上書きするようになりました。設定と実際の挙動を揃える方向の変更です。

もう1つ、Engine API の仕様は OpenAPI 3.2 が正本になり（[moby の PR #53630](https://github.com/moby/moby/pull/53630)）、API の版ごとの Swagger 2.0 ファイルは v1.57 の分が最後です。仕様からコードを生成している場合は、読み込むファイルを確認します。

動画の訂正です。

- 動画では、対処として、daemon.json にループバックの範囲を自分で書き足し、docker を reload すればよい、と伝えました。正しくは、リリースノートの案内は、信頼される証明書で TLS を構成するか、必要なアドレス（例: `localhost:5000`）だけを insecure-registries に足すことです。範囲全体を足せとは書かれていません（[リリースノート](https://docs.docker.com/engine/release-notes/29/)）。

## 3. Polo 1.0.0

MATE 向けの Wayland コンポジター Polo の 1.0.0 が、11月12日（木）に公開されました。作者は個人開発者の Kerem Söke 氏で、[Ubuntu Discourse の告知](https://discourse.ubuntu.com/t/introducing-polo-a-mate-wayland-compositor/91698)があります。Linuxiac は、MATE に公式に採用されたものではない独立したプロジェクトだと書いています。

MATE にはすでに、Wayfire を使う実験的な Wayland セッションがあります（[mate-wayland-session](https://github.com/mate-desktop/mate-wayland-session)）。Polo の README は、Wayfire は MATE などのデスクトップ向けに設計されていないのに、プラグインや回避策、妥協で合わせてきた、と書いています。Ubuntu MATE では、創設者の Martin Wimpress 氏が2026年3月に後継のメンテナーを募る投稿を出し（[Ubuntu Discourse](https://discourse.ubuntu.com/t/ubuntu-mate-seeking-maintainers/79264)。3月27日 UTC）、6月には新しい開発チームが引き継いだと Linuxiac が報じています。

告知によると、方針は、別のコンポジターに合わせてデスクトップを変えるのではなく、MATE をできるだけ X11 のときに近い振る舞いのまま保つことです。Marco の既存の設定、テーマ、ショートカットは引き続き動き、Polo 独自の設定は org.mate.polo の下にあります。作者は Polo を普段使い（daily driver）にしていますが、すべての環境は一人では試せないとして、テスターを求めています。

中身は C と Vala が中心で、パッチを当てた libweston 16.0.1 を専用に組み込んでいます（[v1.0.0 のリリース](https://github.com/KeremSoke/polo/releases/tag/v1.0.0)）。XWayland 用のウィンドウマネージャーも自前で持ちます。エフェクトは9種で、デスクトップキューブ、ウォブリーウィンドウ、Magic Lamp などです。`polo --session` は、mate-session-manager 1.28 の D-Bus API と互換のセッションマネージャーとして動き、LightDM には "MATE (Polo)" の項目が加わります。

入手はソースからで、確認時点で .deb や .rpm の配布は見つかりません。ビルド手順が用意されているのは、Fedora 44/45、Debian 14、Ubuntu 26.04/26.10 です。作者は11月15日（UTC）の返信で、パッケージ化は Debian と Ubuntu MATE の側の役割だとし、進まなければ .deb を置く自前のリポジトリも検討する（維持はしたくない）と述べています。

v1.0.0 のリリースノートは、1.0.1 まで拡大鏡を起動しないよう注意し、Fedora の mate-panel など多くの MATE のパッケージは X11 のみのビルドで、Wayland 対応のビルドが要る、とも書いています。

動画の訂正です。

- 動画では、拡大鏡でクラッシュする不具合があり、1.0.1 で直る予定だと伝えました。正しくは、1.0.1 は11月13日 18:01（UTC。日本時間では11月14日）に公開済みで、拡大鏡の修正を含みます。確認時点の最新は 1.0.2（11月17日 UTC）です（[Polo の 1.0.1](https://github.com/KeremSoke/polo/releases/tag/v1.0.1)）。

## 4. Node.js の11月のセキュリティリリース

Node.js は、11月11日（米国時間。日本時間では11月12日）に、22系、24系、26系のセキュリティリリースを出しました（[advisory](https://nodejs.org/en/blog/vulnerability/november-2026-security-releases)）。修正版は 22.23.5、24.22.3、26.13.1 です。advisory が挙げるのは16件で、深刻度は高7、中6、低3。HTTP/2 が7件、TLS・HTTPS が5件です（書き手の数え方）。

CNA の OpenJS Foundation による CVSS v3.0 では、最も高いのが CVE-2026-123863 の 8.2、CVE-2026-123864 と CVE-2026-123872 が 8.1 です。NVD は確認時点で CVE-2026-123864 を Awaiting Analysis としており、NVD 自身の採点はありません。

CVE-2026-123864 は、HTTPS の再入の欠陥です（[GHSA-m526-rv55-w6mr](https://github.com/advisories/GHSA-m526-rv55-w6mr)）。0バイトの TLS の書き込みが、HTTP パーサーの処理の途中で次の TLS レコードの復号を始め、パーサーに再び入ります。解放後のメモリの使用と範囲外のヒープの読み出しにつながり、ほかの接続の TLS 秘密鍵や他人のリクエストがレスポンスに混ざる、と advisory は説明しています。条件は、リクエストのボディが終わる前に `res.flushHeaders()` を呼び、あとで中身のあるチャンクを付けて `res.end()` を呼ぶハンドラーです。平文の node:http は影響を受けません。

advisory は、16件のうち5件の報告者を Chris Rohlf 氏 "in collaboration with Claude and Anthropic Research" としています。手法の詳細は書かれていません。

ほかに動画で挙がった CVE は次のとおりです。

- CVE-2026-123863: HTTP/2 のセッションの片付けで検査に引っかかり、認証のないクライアントがサーバーを止められる。CVE-2024-27983 の修正が及んでいなかった変種で、対象は24系と26系。
- CVE-2026-123865: GOAWAY で閉じている途中に相手がプロトコルエラーを起こすと、接続の状態がメモリに残り続ける。CVE-2026-48937 の不完全な修正。
- CVE-2026-123866: 書き込みが詰まっている間にストリームが片付けられ、解放済みのバッファーが相手に送られる。
- CVE-2026-123872: ホストごとに別のクライアント証明書の方針を使うサーバーで、TLS 1.2 の再ネゴシエーション中に servername を変えると、厳しい方針を回避できる。
- CVE-2026-123871: プロキシの URL の認証情報が、ERR_PROXY_INVALID_CONFIG のエラー文に平文で出る（中。CNA の CVSS v3.0 で 6.2）。

サポートが終わった版について、advisory は、End-of-Life の版はセキュリティリリースのたびに常に影響を受ける、と書き、最新の版を使うよう案内しています。暫定策の記載はありません。HTTP/2 を直接公開しているサーバーを先に更新する、というのは書き手の判断です。

動画の訂正です。

- 動画では、一番深刻なのは CVE-2026-123864 だと伝えました。正しくは、advisory は順位を付けていません。CNA（OpenJS Foundation）の CVSS v3.0 で最も高いのは CVE-2026-123863 の 8.2 で、CVE-2026-123864 は 8.1 です（CVE-2026-123872 も 8.1）（[advisory](https://nodejs.org/en/blog/vulnerability/november-2026-security-releases)）。
- 動画では、Nginx や Caddy を前に置いて HTTP/1.1 で中継する暫定策が挙げられている、と伝えました。正しくは、advisory に暫定策の記載はありません（[advisory](https://nodejs.org/en/blog/vulnerability/november-2026-security-releases)）。

## 5. ScreenConnect の CVE-2026-84869

ScreenConnect は、MSP が顧客の端末の支援に使うリモートサポートツールです。CVE-2026-84869 は、CNA の ConnectWise による CVSS v3.1 で 9.9 で、NVD 自身の採点はありません。ConnectWise が[セキュリティ公報](https://www.connectwise.com/company/trust/security-bulletins/2026-09-08-screenconnect-bulletin)を出したのは9月8日（火）、CISA の KEV に加わったのは9月11日（金）です。NVD の公開は9月8日 20:18（UTC。日本時間では9月9日）でした。8月20日の記事で取り上げた CVE-2024-1709 とは別の欠陥です。

欠陥は、サーバーではなくクライアントにあります。NVD の説明では、ある状況で、認可もホストの確認もなしに、ファイルが転送され実行されることがあります。サーバーは影響を受けません（"ScreenConnect servers are not impacted"）。弱点の分類は CWE-862（認可の欠如）と CWE-269（不適切な権限管理）です。

11月16日（月）に公開された Huntress の John Hammond 氏の[分析](https://www.huntress.com/blog/cve-2026-84869-screenconnect-technician-exploitation)によると、ゲストとして接続した側がテクニシャンの端末にファイルを送り、テクニシャンのクライアントに実行させます。確認の表示は出ません。10月20日から11月16日までに、42の MSP のサーバーへ29の送信元から、テクニシャンの参加を待つゲストの "run file" の要求が少なくとも68万8000回届き、最も多いサーバーでは3週間で7万414回でした。

11月12日（UTC。日本時間では11月13日）の1件の事例では、最初の実行から攻撃者の中継先に繋がるクライアントの起動まで、Huntress の記録で約8.4秒でした（Huntress の表現は "about 9 seconds"）。流れは次の4段階です。

- 見えないプロセスで起動し直す。
- 感染を通知し、OS の版や管理者権限の有無を調べる。
- 偽の更新を、インストールの記録が残らない形で展開する。
- 名前を変えた ScreenConnect のクライアントを起動し、攻撃者の中継先に接続する。

Huntress は、MSP のテクニシャンの端末には RMM のコンソール、保存された認証情報、顧客のすべてへのアクセスが典型的にあり、非常に魅力的な標的だと書き、テクニシャンが見られるものは攻撃者にも見えると想定して認証情報を入れ替えるよう求めています。なお、SCKit と呼ばれるマルウェアは、サーバー側のサードパーティ拡張を悪用しているように見え、CVE-2026-84869 を直接悪用してはいない、と Huntress は書いています。

修正は 26.6.5 です。ConnectWise の公報は、オンプレミスでは 26.6.5 へ更新し、そのあとホストクライアントを再インストールし、アクセスエージェントを更新するよう求めています。Huntress は、脆弱なコードはテクニシャンの端末で動くのでサーバーの更新だけでは直らないと書き、すべてのテクニシャンのホストクライアントを 26.6.5 以上にするよう求めています。クラウド版について、公報は "No action is required." と書き、同じ項でホストクライアントの再インストールとアクセスエージェントの更新にも触れています。暫定措置として各ロールから TransferFiles の権限を外す方法も公報にありますが、更新の代わりにはならない、とされています。

侵害の確認の手がかりも Huntress が挙げています。サーバーでは App_Data の Session.db（コピーで作業する）で、ゲストの接続から出た RanFiles と SentFiles のイベントを探します。テクニシャンの端末では、ローカルのアプリデータの wclient で始まるフォルダ、ホストクライアントが Temp から実行したスクリプト、見覚えのない Startup のファイル、自分のものではない中継先に繋がるクライアントを調べます。

動画の訂正です。

- 動画では、まだ1000台を超える環境が未対応のまま残っているとされている、と伝えました。正しくは、1,000超は BleepingComputer が9月16日に報じた Shadowserver の集計で、11月時点の数ではありません。数えているのは ScreenConnect のサーバー側で、欠陥のあるクライアント側の数ではありません（[BleepingComputer](https://www.bleepingcomputer.com/news/security/cisa-warns-of-hackers-exploiting-critical-screenconnect-flaw/)。要約経由の確認です）。

## まとめ

実務で確かめておくものは次のとおりです。

- Optimizely の利用者（Report URI の "What to do now" から）: コードを書き込める欄と実験のカスタムコードに、見覚えのないスクリプトや atob のような記述がないか調べる。書き込める人、API トークン、連携を点検して認証情報を入れ替える。11月16日に入力されたカードは漏れた可能性があるものとして扱い、HttpOnly でない Cookie の秘密は入れ替える。CSP は connect-src を絞り、unsafe-eval を避け、レポートを有効にする。
- Docker: insecure-registries を明示している環境で、ローカルのレジストリが使えるかを確かめる。必要なアドレスだけを足すか、信頼される証明書の TLS にする。CI のランナーの Docker の版も確かめる。
- Polo: 試すなら、拡大鏡の修正が入った 1.0.1 以降（最新は 1.0.2）にし、Wayland 対応の MATE のコンポーネントを用意する。
- Node.js: 22.23.5、24.22.3、26.13.1 のいずれかに上げる。サポートが終わった版は、更新先を探す。
- ScreenConnect: サーバーだけでなく、Huntress の案内どおりテクニシャンのホストクライアントと、ConnectWise が挙げるアクセスエージェントを 26.6.5 以上に更新する。更新までは TransferFiles の権限を外す暫定措置があるが、更新の代わりにはならない。Session.db と端末の手がかりで侵害を確認する。

## 参考リンク

- [Report URI: Optimizely 経由のマルウェア](https://blog.report-uri.com/worlds-largest-brands-infected-with-malware-via-optimizely/)
- [Optimizely ステータスページ](https://status.optimizely.com/incidents/ftw0fh9wx43z)
- [Docker Engine 29 リリースノート](https://docs.docker.com/engine/release-notes/29/)
- [Polo v1.0.0](https://github.com/KeremSoke/polo/releases/tag/v1.0.0)
- [Node.js 11月のセキュリティリリース](https://nodejs.org/en/blog/vulnerability/november-2026-security-releases)
- [ConnectWise: ScreenConnect の公報](https://www.connectwise.com/company/trust/security-bulletins/2026-09-08-screenconnect-bulletin)
- [Huntress: CVE-2026-84869 の分析](https://www.huntress.com/blog/cve-2026-84869-screenconnect-technician-exploitation)

（2026/11/18 Linux・OSSトレンド）
