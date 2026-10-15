---
title: "Ivanti のゼロデイが ICT をすり抜ける、Cisco SEG と Langflow の穴、Defender の Linux デスクトップ対応、Blender の OpenGL 引退案（2026/10/16 Linux・OSSトレンド）"
date: 2026-10-16T00:00:00+09:00
draft: false
tags: ["セキュリティ", "脆弱性", "Ivanti", "Cisco", "Langflow", "MCP", "Microsoft Defender", "Blender", "Vulkan", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

VPN、メールゲートウェイ、AI ツールの開発基盤、そして Linux デスクトップの防御ソフト。今回の5本は、どれも「異常なし」と表示してくれる道具や、その土台に関わる話です。表示を鵜呑みにせず、自分の環境で中身を確かめる。この切り口で並べました。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "Ge7M7oqw2iU" >}}

## 1. Ivanti Connect Secure CVE-2026-104935 — 3段のチェーンと、点検ツールの先

Ivanti Connect Secure に、認証なしで root まで到達できる攻撃チェーンが見つかりました。[Volexity の解析](https://www.volexity.com/blog/2026/10/13/a-series-of-unauthenticated-events-chained-exploitation-of-ivanti-connect-secure-zero-days/)によれば、チェーンは認証のバイパス、リモートコード実行（RCE）、権限昇格の3段です。CVE-2026-104935 が指すのは、このうち認証バイパスと RCE の2つで、3段目の権限昇格に CVE 番号はありません。深刻度は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-104935) に載る CNA の評価で CVSS 3.1 の 8.6（High）です。

Volexity によれば、同社が UTA0576 と名付けた攻撃者は、2026年10月3日からこの脆弱性を繰り返し悪用していました。修正版が出たのは10月13日なので、少なくともパッチの約10日前から悪用されていたことになります。

### 各段の中身

- 1段目: リクエストの URL と、転送先を決めるヘッダーのパスが食い違うことを突き、ログインが必要な CGI スクリプトを認証なしで呼び出します
- 2段目: アップロードされたファイルを、ZIP として有効かどうかを確かめる前にディスクへ書き込みます。検証に失敗して削除されるまでの短い間に、実行のリクエストを割り込ませます
- 3段目: 動いている cgi-server プロセスのメモリ上にある Ivanti のライブラリ（libdsplibs.so）の写しを書き換え、既存の保守タスクが Perl を起動するように設定を変えて、root の権限を得ます

マルウェアやウェブシェルのような常駐の足場は確認されず、攻撃者はコマンドを実行するたびに悪用を繰り返した、と Volexity は書いています。攻撃コードは、悪用に関するログも消していました。

Ivanti は、ディスク上の想定外の変更を見つける Integrity Checker Tool（ICT）を公開しています。Volexity によれば、この攻撃はライブラリをメモリ上でだけ書き換え、設定の保存データも元に戻すため、ICT は変更を検知しません。[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/10/13/cisa-urges-patching-newly-exploited-vulnerability-ivanti-connect-secure)も、ICT が悪用の痕跡を検出できない可能性があるとし、侵害の有無を確かめるにはネットワークとメモリのフォレンジックが必要だとしています。

### 3段目のパッチと、いまの状況

3段目の権限昇格の修正版は、2026年10月16日 06:00（日本時間）の確認時点で、まだ提供されていません。Volexity は、修正が今後数週間（coming weeks）のうちにリリースに含まれる、と書いています。CVE-2026-104935 に対するパッチは、1段目と2段目を塞ぐものです。

### 影響範囲と対応

CISA は、影響を受ける版を 22.8R2.4 以前、25.1.1.1 以前、25.1.2.2 以前としています。修正版は、[Rapid7 が転記した Ivanti の表](https://www.rapid7.com/blog/post/etr-ivanti-connect-secure-zero-day-exploited-in-the-wild-cve-2026-104935/)によれば 22.8R2.5、25.1.1.2、25.1.3.0 か 25.1.3.1 です。22.7 系以下は影響を受けません。22.8 系は2027年1月31日にサポートが終わります（CISA）。

CISA は CVE-2026-104935 を既知の悪用された脆弱性（KEV）に10月13日に追加し、連邦機関の対応期限は10月16日です。インターネットから見える Connect Secure は、Shadowserver の計測で5,500台以上です（[BleepingComputer](https://www.bleepingcomputer.com/news/security/ivanti-warns-of-connect-secure-zero-day-exploited-in-attacks/)、10月13日）。これは外から見える台数で、脆弱な台数ではありません。

侵害が疑われる場合、CISA は Ivanti の復旧手順に沿って、工場出荷状態へのリセットと最新版への更新を勧めています。Volexity は調査用の YARA ルールと IOC を[GitHub で公開](https://github.com/volexity/threat-intel/tree/main/2026/2026-10-13%20Ivanti)しています。

動画の訂正です。

- 動画では「Active Directoryの認証情報や、LAPSのパスワード、BitLockerの回復キーまで抜かれていました」と紹介しましたが、Volexity の原文は、攻撃者が LAPS のパスワードや BitLocker の回復キーを狙って Active Directory を検索した、というところまでです。これらが取得されたとは書かれていません。
- 動画では、パッチの次の手順として「工場出荷状態へ戻して作り直し、パスワードや証明書を全部入れ替える」と紹介しましたが、CISA がこれを勧めているのは、侵害が疑われる場合の手順です。

## 2. Microsoft Defender for Endpoint の Linux デスクトップ対応 — プレビューの条件を読む

Microsoft Defender for Endpoint が、Linux デスクトップにパブリックプレビューで対応しました。[What's New のページ](https://learn.microsoft.com/en-us/defender-endpoint/linux-whatsnew)には、2026年9月の表に "Microsoft Defender support for Linux Desktops" が Preview として載っています。[Phoronix](https://www.phoronix.com/news/Microsoft-Defender-For-Linux-D)は、米東部時間の10月15日にこれを報じました。

[前提条件のページ](https://learn.microsoft.com/en-us/defender-endpoint/mde-linux-prerequisites)に、確かめておきたい点がまとまっています。

- サーバーと共通: "Deployment packages, methods and security capabilities remain the same across both Linux servers and desktops." とあり、デスクトップ専用のエージェントは用意されていません
- 判別: OS の情報などの手がかりを決まった順で評価し、デスクトップ（Workstation）と断定できなければ、既定でサーバー（Server）として分類します。設計上の挙動だと書かれています
- 要件: カーネルは 3.10.0-327 以降、ディスクは 2 GB 以上で、systemd が入っていること。対応ディストリビューションには RHEL、Ubuntu、Debian、Fedora、Rocky Linux、Alma Linux などが並びます。版の条件は表で確かめてください
- 隔離機能: デバイスの隔離には iptables と ip6tables（または iptables-nft と ip6tables-nft）が必要です
- 展開: Defender Deployment Tool for Linux の使用が推奨されています。このツールは、[What's New](https://learn.microsoft.com/en-us/defender-endpoint/linux-whatsnew)の2026年7月の表で正式版（GA）になっています
- ライセンス: デスクトップの登録には Defender for Endpoint P2 が必要です。Microsoft 365 E5 と、2026年3月に[発表された E7](https://blogs.microsoft.com/blog/2026/03/09/introducing-the-first-frontier-suite-built-on-intelligence-trust/)にも含まれます。P2 は[単体のライセンスとしても買えます](https://learn.microsoft.com/en-us/office365/servicedescriptions/microsoft-365-service-descriptions/microsoft-365-tenantlevel-services-licensing-guidance/microsoft-defender-service-description)

併用できるかどうかも、導入前に確かめる項目です。前提条件のページによれば、fanotify を使う他のセキュリティ製品との併用はサポート外で、システムのハングなど予期しない動作につながることがあります。ただし、ウイルス対策をパッシブモードにすれば併用できます。RHEL と Fedora の FAPolicyD は例外で、mdatp health が healthy を報告している間は、アクティブモードでもサポートされます。

動画の訂正です。

- 動画では「CrowdStrike Falconのような製品とは、原則として共存できない」と紹介しましたが、Microsoft の前提条件のページに CrowdStrike Falcon の名前はありません。非サポートと書かれているのは fanotify を使う他製品との併用で、ウイルス対策をパッシブモードにして併用する選択肢もあります。

## 3. Blender 6.0 で OpenGL を削除する案 — 提案段階の話

Blender の開発者が、6.0 で OpenGL のサポートを削除する案を出しています。10月5日の[Viewport & EEVEE モジュール会議のノート](https://devtalk.blender.org/t/2026-10-05-viewport-eevee-module-meeting/45885)に、"Internal proposal to remove OpenGL support in Blender 6.0 (November 2027). It hasn't been decided yet as virtual texturing would be a blocker for this." とあります。内部の提案で、まだ決まっておらず、バーチャルテクスチャリングがブロッカーとして挙がっています。6.0 の時期は、この会議ノートでは2027年11月の予定です。

[Phoronix](https://www.phoronix.com/news/Blender-6.0-May-Remove-OpenGL)によれば、5.5 は LTS なので、OpenGL にしか対応しない古い環境の人が Blender を使い続けられる最後の機会になります。

背景として、[5.3 のリリースノート](https://developer.blender.org/docs/release_notes/5.3/eevee/)には次の変更が載っています。

- Windows（ARM 版を除く）と Linux で、Vulkan が既定のバックエンドになる
- Vulkan の最低要件が 1.2 から 1.1 に下がり、一部の GPU やドライバーの機能が任意になる
- 同じテストシーン（blender291-autumn）の比較で、5.3 の OpenGL が 192.686 fps、Vulkan が 282.065 fps。計測環境は AMD Ryzen 7950X と NVIDIA RTX 6000 (Ada) を積んだ Linux で、値は3回の平均です

5.3 は、[リリースノート](https://developer.blender.org/docs/release_notes/5.3/)によれば2026年11月4日までベータです。OpenGL は、[Wikipedia](https://en.wikipedia.org/wiki/OpenGL)によれば SGI が開発し、1992年6月に公開されました。Vulkan 1.0 は、[2016年2月に Khronos が発表](https://cgw.com/Press-Center/News/2016/Khronos-Releases-Vulkan-1-0-Specification.aspx)しています。古い GPU を使っている人は、5.3 が出たら Vulkan で動くかを試し、[フィードバック用のスレッド](https://devtalk.blender.org/t/vulkan-feedback-and-testing/39900)に報告するのが、いまできる備えだと考えます。

動画の訂正はありません。

## 4. Langflow CVE-2026-105740 — MCP の Stdio 設定から OS コマンドへ

Langflow は、AI のワークフローを作るオープンソースのツールで、GitHub のスターは2026年10月16日時点で15万5千を超えています。ここに、認証済みのユーザーがサーバー上でコマンドを実行できる脆弱性 CVE-2026-105740 が見つかりました。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-105740) の CVSS 3.1 は 9.9（Critical）で、これは GitHub が付けた値です。弱点の種類は CWE-78（OS コマンドインジェクション）です。

MCP（Model Context Protocol）は、[Anthropic が2024年11月に公開](https://www.anthropic.com/news/model-context-protocol)した仕様です。NVD の説明によれば、Langflow は MCP サーバーの追加で "Stdio" を選ぶと、ユーザーが入力したコマンドを、検証も許可リストもサンドボックスもなしに bash -c "exec {command}" へ渡します。コマンドは、サーバーの一覧を取得した時点で実行されます。環境変数の欄からも、LD_PRELOAD や PATH の上書きのような任意の環境変数を入れられます。必要なのは、認証済みの Langflow ユーザーの権限です。

影響を受けるのは 1.9.0 より前で、1.9.0 で修正されました（NVD）。

### 1.9.0 だけでは足りないかもしれない

MCP の Stdio に関わる CVE-2026-105697 も、同じ10月5日に公開されています。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-105697) によれば、既定の LANGFLOW_AUTO_LOGIN=true のとき、/api/v1/auto_login が認証情報なしでトークンを渡すため、既定の設定で公開されたインスタンスはアカウントなしで到達できます。[GitHub のアドバイザリ GHSA-w794-rj3p-xv45](https://github.com/advisories/GHSA-w794-rj3p-xv45)によれば、修正は2段階で、1.9.0 の修正は MCPServerConfig を経由する経路を塞ぎ、完全な修正は 1.10.3 です。回避策は、LANGFLOW_AUTO_LOGIN=false にすることと、信頼できないネットワークへ直接公開しないことです。

1.9.0 の変更は、起動できるコマンドの許可リスト、引数のシェルメタ文字のブロック、危険な環境変数のブロック、Docker の隔離チェックです（同アドバイザリと[修正 PR #12290](https://github.com/langflow-ai/langflow/pull/12290)）。Langflow を使っているなら、1.10.3 以上へ更新するのが目安です。

Langflow の別の脆弱性は、[8月6日の記事](https://blog.fuga.jp/posts/2026-08-06-linux-oss-trend/)と[9月3日の記事](https://blog.fuga.jp/posts/2026-09-03-linux-oss-trend/)でも扱いました。それぞれ別の CVE です。

動画の訂正です。

- 動画では、1.9.0 の変更として「MCPの設定を管理者だけに絞る変更が入っています」と紹介しましたが、1.9.0 の変更は上記の4点で、管理者に限定する変更は含まれていません。
- 動画では対策として「1.9.0以上へ」と紹介しました。CVE-2026-105740 の修正は 1.9.0 ですが、関連する CVE-2026-105697 は 1.10.3 で完全に修正されています。

## 5. Cisco Secure Email Gateway CVE-2026-76519 — 添付ファイルの扱いから root へ

Cisco Secure Email Gateway（SEG）の CVE-2026-76519 は、Advanced Malware Protection（AMP）の機能の脆弱性です。[Cisco のアドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-esa-afw-zqYJkjxp)は、認証のないリモートの攻撃者が、任意のファイルを書き込み、基盤の OS で root 権限のコマンドを実行できる可能性があるとしています。原因は、File Reputation サービスが有効なときの、メールの添付ファイルの不適切な処理です。CVSS 3.1 は 9.8（Critical）で、Cisco が付けた値です。ユーザー操作は不要（UI:N）とされています。

対象は、脆弱な AsyncOS を動かしていて、次の2つを両方満たす機器です。

1. File Reputation サービスが有効で、メールポリシーに割り当てられている
2. Content Scanner Tools の版が 25.3.0.5525 より前

アドバイザリには、2026年10月に Cisco の PSIRT が悪用を認識したこと、内部のセキュリティスキャンで見つかったことが書かれています。回避策はありません。修正は Content Scanner Tools の 25.3.0.5525 以降に入っています。更新にソフトウェアのアップグレードや製品の再起動は要らず、手動で更新するには contentscannerupdate、版の確認には CLI の contentscannerstatus を使います。AsyncOS 本体の修正版は、15.5 系が 15.5.5-014、16.5 系が 16.5.0-780 です。

[SecurityWeek](https://www.securityweek.com/cisco-warns-of-exploited-secure-email-gateway-vulnerability/)によれば、これらの修正版の出荷は9月14日で、アドバイザリの公開は10月14日です。同記事によれば、Cisco は、侵害の可能性を示す痕跡が見つかった Cisco Secure Email Cloud の顧客に直接連絡しました。攻撃者が昇格した権限で悪用の証拠を消したり隠したりするおそれがある、とも警告しています。アドバイザリは、root を取られた機器では SSH の秘密鍵にアクセスされうるとも書いています。

[CISA の KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)への追加は10月14日で、連邦機関の期限は10月17日です。ランサムウェアでの利用は、CISA が「不明」としています。SecurityWeek は、同製品で9月中旬以降に悪用された2件目だと書いています。1件目は CVE-2026-76461 で、[9月16日の記事](https://blog.fuga.jp/posts/2026-09-16-linux-oss-trend/)で扱いました。こちらとは別の脆弱性です。

動画の訂正です。

- 動画では「圧縮ファイルの中のファイル名に細工があると、検査係が本来の作業場所の外側にファイルを書き出してしまう」と紹介しましたが、アドバイザリは、添付ファイルの不適切な処理としか書いておらず、圧縮ファイルについての記述は確認できませんでした。
- 動画では「起動時に動く設定などを書き換えられて、root権限でコマンドを実行されてしまう」と紹介しましたが、アドバイザリにあるのは、任意のファイルの書き込みと root 権限でのコマンド実行までで、起動時の設定の書き換えは確認できませんでした。
- 動画では、版の確認方法を「管理コンソールのSecurity Servicesから、Advanced Malware Protectionの項目でバージョンを確認できます」と紹介しましたが、一次情報で確認できたのは、CLI の contentscannerstatus での確認方法です。管理画面の場所は確認できませんでした。

## まとめ

Ivanti は点検ツールの結果、Cisco は部品の版番号、Langflow は修正版の番号、Defender は「デスクトップ」という分類、Blender は「Vulkan で足りるか」。どれも、画面や一覧が示す「いつもどおり」を、自分の環境の実際の中身と突き合わせる話でした。この共通点は書き手の考察です。

確かめることを挙げます。

- Ivanti Connect Secure を使っているなら、版を確認して更新し、侵害の確認は ICT だけに頼らずネットワークとメモリの調査も含める。3段目の修正版が出たら、それも当てる
- Cisco SEG を使っているなら、File Reputation の有効状態と、contentscannerstatus での Content Scanner Tools の版を確認する
- Langflow を使っているなら 1.10.3 以上へ更新し、LANGFLOW_AUTO_LOGIN を false にして、公開範囲を見直す
- Linux に Defender を入れる予定があるなら、サーバーとして分類されないか、既存のセキュリティ製品との併用、ライセンスを先に確かめる
- Blender で古い GPU を使っているなら、5.3 で Vulkan が動くかを試す

## 参考リンク

- [Volexity: Ivanti Connect Secure のゼロデイ連鎖](https://www.volexity.com/blog/2026/10/13/a-series-of-unauthenticated-events-chained-exploitation-of-ivanti-connect-secure-zero-days/)
- [CISA: Ivanti Connect Secure の悪用された脆弱性](https://www.cisa.gov/news-events/alerts/2026/10/13/cisa-urges-patching-newly-exploited-vulnerability-ivanti-connect-secure)
- [Microsoft: Defender for Endpoint on Linux の前提条件](https://learn.microsoft.com/en-us/defender-endpoint/mde-linux-prerequisites)
- [Blender: 2026-10-05 Viewport & EEVEE モジュール会議](https://devtalk.blender.org/t/2026-10-05-viewport-eevee-module-meeting/45885)
- [NVD: CVE-2026-105740（Langflow）](https://nvd.nist.gov/vuln/detail/CVE-2026-105740)
- [GitHub Advisory: GHSA-w794-rj3p-xv45（Langflow）](https://github.com/advisories/GHSA-w794-rj3p-xv45)
- [Cisco: Secure Email Gateway のアドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-esa-afw-zqYJkjxp)
- [2026年9月16日の Linux・OSSトレンド（Cisco SEG の別の脆弱性）](https://blog.fuga.jp/posts/2026-09-16-linux-oss-trend/)

（2026/10/16 Linux・OSSトレンド）
