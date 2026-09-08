---
title: "パッチを当てた、そのあとに何が残るか — 12万台のSSH露出、86CVEの一斉配信、掃除されない店（2026/9/9 Linux・OSSトレンド）"
date: 2026-09-09T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "MikroTik", "RouterOS", "GIMP", "GEGL", "SAP", "Magento", "Adobe Commerce", "Asahi Linux", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「パッチ、当てました」で終わる話と、終わらない話があります。

今日並んだ5本は、その分かれ目がやけにくっきり出た一日でした。修正版ファームウェアはとっくに出ているのに攻撃が止まらないルーター。同じ日に6つのディストリビューションが数十から数百のCVEを一斉に片付けた話。バグではなく地道な移植の積み重ねが実った話。そして、パッチを当てた **あとに** やることを公式が明示的にリスト化した2件。

パッチは「これ以上入られない」ようにする作業です。すでに入られた痕跡を消す作業ではありません。この違いを意識しながら読むと、今日の5本はひとつの線でつながります。

{{< youtube "8TRv_oKiPZU" >}}

## 1. MikroTrick — RouterOSのSSH認証バイパスと権限昇格、修正版が出た後も攻撃は続いている

最初は今日いちばん重い話です。ネットワーク機器ベンダー MikroTik のルーターOS「RouterOS」に、SSHの認証まわりの脆弱性が複数見つかりました。ポーランドのCERTである CERT Polska が **2026年9月5日** に[公式アドバイザリ](https://cert.pl/en/posts/2026/09/mikrotik-routeros-cve/)を公開しています。

中心になるのは2本です。ひとつ目の **CVE-2026-67276** （[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-67276)でCVSS 9.2）は、公開鍵認証の実装ミスです。CERT Polskaの表現を借りると、RouterOSはSSHの認証要求を登録済みの鍵と突き合わせるとき、 **RSA公開鍵の全体を比較していませんでした** 。鍵種別とモジュラス（n）は見るのに、指数（e）の比較を省いていたのです。

これがなぜ致命傷になるのか。RSAの検証は「署名値 s を e 乗して n で割った余り」を計算する操作です。もし e が 1 なら、この計算は「s をそのまま返す」だけになります。つまり攻撃者は、狙ったユーザーの **ユーザー名と公開鍵のモジュラスさえ手に入れば** 、指数を 1 に差し替えた細工済みの鍵を持ち込んで、秘密鍵なしで検証を通せてしまいます。公開鍵は名前のとおり公開されている値ですから、秘密の情報は何ひとつ必要ありません。

ふたつ目の **CVE-2026-86060** （[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-86060)でCVSS 9.2）は権限昇格です。SSHログイン経路の引数の扱いに不備があり、禁止されているはずの文字で始まるユーザー名を受け付けてしまう。CERT Polskaはこれを「信頼されたRouterOSポリシーマスク（trusted RouterOS policy mask）が変更され、権限昇格につながる」と説明しています。

この2本を連鎖させると、認証なしでログインし、そのまま管理者権限を取れる。MikroTikは[自社のセキュリティアドバイザリ](https://mikrotik.com/supportsec/september-2026-vulnerability/)でこの一連の問題に「MikroTrick」というコードネームを付けています。

**ここからが今日の主題に関わる部分です。** MikroTikは修正済みファームウェアを2026年9月3日にすでに公開しており、修正版は **6.49.21** 、 **7.23.4** 、 **7.24.2** （およびベータ系の 7.25beta3）です。にもかかわらず、Help Net Security が伝えた [Shadowserver Foundation のスキャン結果](https://www.helpnetsecurity.com/2026/09/07/mikrotik-routeros-ssh-vulnerabilities-exploited/)では、2026年9月5日の24時間スキャンで **SSHがインターネットから到達可能なMikroTik機器が12万2500台以上** 検出されています。

数字の読み方には注意が必要です。これは「SSHがインターネットに露出している台数」であって、侵害された台数でも、脆弱と確認された台数でもありません。Shadowserver自身も脆弱性の判定は行っていないと明記しています。ただし、この母数のうち未更新の機器はそのまま危険域に残る、という構図は変わりません。そして実際の悪用は **少なくとも9月2日から** 観測されています。

侵害の痕跡（IoC）ははっきりしています。ログに `login failure for user -2` や `added by ssh:-2` というパターンが出ていないか、そして身に覚えのない高権限アカウント `ops` が増えていないか。攻撃元IPとしては 82.192.72.4 と 103.102.31.18 が報告されています。RouterOS上では次のコマンドで確認できます。

```
/log print where message~"login failure for user -2"
/log print where message~"added by ssh:-2"
```

ファームウェアをすぐに上げられないなら、まずSSHポートをインターネットから遮断してVPN経由に限定すること。そのうえで、上のログ確認は必ず通してください。 **更新は「これから入られない」ための作業で、すでに入られていないかの確認は別作業です。**

## 2. 主要6ディストリビューションが同日に一斉パッチ — GIMPのHDRパーサーにRCE

9月7日、Debian・Fedora・SUSE・Ubuntu・Rocky Linux・Slackware が揃ってセキュリティ更新を配信しました。[Linux Security Roundup のまとめ](https://www.linuxcompatible.org/story/linux-security-roundup-suse-ubuntu-and-debian-ship-major-cve-patches)によれば、SUSEは12本のアドバイザリで合計86 CVE、Ubuntuは5.15・6.8・7.0系にまたがって100件を超えるカーネル脆弱性を処理しています。数字だけ見ると壮観ですが、こういう「まとめて大量」の日は個別の中身が埋もれがちです。今回、埋もれさせるには惜しいものが混ざっていました。

**GEGL / GIMP の HDR パーサー（CVE-2026-18300）** です。GEGLはGIMPが画像処理に使っているバックエンドライブラリで、[NVDの記載](https://nvd.nist.gov/vuln/detail/CVE-2026-18300)では「HDRファイルのパース処理でユーザー入力の検証が不足し、メモリ確保の前に整数オーバーフローが起きる」ものとされています。CWE-190、CVSSは **7.8** 。攻撃には利用者の操作（悪意あるファイルを開く、あるいは悪意あるページを訪れる）が必要なのでスコアは最高値ではありませんが、 **細工されたHDR画像を開くだけで任意コードが走る** という筋道は、条件としてかなり現実的です。

HDRファイルというのは、写真のRAW現像や3Dレンダリング、フォトグラメトリのワークフローでは日常的に第三者からやり取りするものです。「知らない人からもらった実行ファイルは開かない」という常識は広く共有されていますが、「知らない人からもらった画像は開かない」という警戒感を持っている人はずっと少ない。そこが狙われるタイプの脆弱性でした。

修正はRed Hat側でも同日に降りていて、RHEL 8向けが [RHSA-2026:62420](https://access.redhat.com/errata/RHSA-2026:62420)、RHEL 9向けが RHSA-2026:62170 として `gegl04` パッケージを更新しています。手元での対応はディストリビューションによって次のとおりです。

- Fedora: `sudo dnf update gegl`
- RHEL / AlmaLinux / Rocky 8・9: `sudo dnf update gegl04`

同じ日の配信には他にも見どころがあります。UPnPデーモンの **miniupnpd（CVE-2026-5720）** は、SOAPActionヘッダーのパース処理に整数アンダーフローがあり、シングルクォートを含む不正なヘッダーを送るだけで長さの計算が破綻して、[HTTPリクエストバッファをはるかに超えた領域をmemchrが走査してしまう](https://nvd.nist.gov/vuln/detail/CVE-2026-5720)というものです。クラッシュ（DoS）だけでなく、メモリ内容の漏洩につながります。Ubuntuは [USN-8731-1](https://ubuntu.com/security/notices/USN-8731-1) として16.04から26.04までのLTS向けに配信しました。ホームルーターやNAS、ソフトウェアルーターが広く使うコンポーネントなので、WAN側に露出している構成では影響が実害に直結します。

ボクセルゲームエンジンの **Luanti（旧Minetest）** も **CVE-2026-41196** を修正しています。悪意あるModがLuaのサンドボックスから脱出して任意コードを実行し、ファイルシステムに完全アクセスできるというもので、[NVDによれば](https://nvd.nist.gov/vuln/detail/CVE-2026-41196)バージョン5.0.0から5.15.2未満まで影響し、サーバー側Mod・非同期環境・マップ生成環境・クライアントサイドスクリプトのすべてが対象、ただしLuaJIT使用時に限り再現します。修正版は5.15.2。Ubuntuは [USN-8732-1](https://ubuntu.com/security/notices/USN-8732-1) で配信しました。

Rocky Linux は RLSA-2026:63128（Rocky 10）と RLSA-2026:63129（Rocky 9）でカーネルを更新しており、こちらは再起動に加えてサードパーティのカーネルモジュール（NVIDIAドライバなど）の再ビルドが必要になります。Slackwareはlibpcapを1.10.7に上げて7件のCVEを処理、DebianとFedoraはChromium（各12 CVE）とThunderbird（Debianで14 CVE）も同日に更新しています。

## 3. Asahi Linux、Apple M3ファミリーを公式サポート — ただし「眠らない」

ここで少し空気を変えます。今日唯一の、脆弱性ではない話題です。

Apple Silicon上でLinuxを動かす Asahi Linux プロジェクトが、 **2026年9月6日** に Apple M3・M3 Pro・M3 Max の公式サポートをインストーラーに統合しました。発表は公式ブログの[「M2: Episode 1 (or, Asahi Linux on M3)」](https://asahilinux.org/2026/09/m2-episode-1/)です。このタイトルが技術的な内容をそのまま言い当てていて、M3はアーキテクチャ的にはM2の延長線上にある設計で、M1→M2の移植で積み上げた知見がかなりそのまま効いた、ということを示しています。

動くものは、公式発表によれば「M1・M2で動くもののほぼすべて」です。ウェブカム、内蔵マイク、USB（ハードウェア上限の USB 3.0 / 10 Gb/s まで）、AV1を含むハードウェア動画デコード、Wi-Fi、Bluetooth。ここまで揃っていれば、開発マシンとしては十分実用圏に見えます。

ただし **動かないものの一覧も、同じ公式ブログにきちんと書かれています。** GPUの3Dアクセラレーションは「今の時点で高性能または省電力な3Dアクセラレーションを期待しないでほしい」と明記されています。スリープはファームウェア提供のフレームバッファの制約により動作しません。M3 Pro / M3 Max 搭載MacBook ProのHDMIポートも、DCP（Display Co-Processor）への完全対応が済んでいないため現時点では無効化されています。そしてM3 Ultraを積んだMac Studioは対象外です。

導入は現在Expertモード限定で、macOSのターミナルから次を実行します。

```bash
curl -L https://alx.sh/ | EXPERT=1 sh
```

このExpert要求は、数週間後に予定されている Fedora Linux 45 ベータのリリースまでに外す計画だと公式ブログは述べています。

なお、これは公式が案内している手順そのままですが、`curl` で取得したスクリプトをその場で `sh` に流し込む形である点は意識しておいてください。気になる場合は、いったんファイルに保存して中身を確認してから実行するほうが安全です。

3Dアクセラなし・スリープなしという条件は、「Macを買ってLinuxを常用機にする」用途にはまだ厳しい。ですがこれは、Appleが仕様書を出していないハードウェアを、寄付ベースで運営されるプロジェクトがリバースエンジニアリングで解析して到達した地点です。何が動いて何が動かないかを、期待をあおらずに列挙して出してくるところに、このプロジェクトの誠実さが出ていると思います。

## 4. SAP 9月パッチデー — CVSS 10.0の満点脆弱性がExtended Passportに

9月8日はSAPのパッチデーでした。[報道によれば](https://cybersecuritynews.com/sap-security-updates-september-2026/)、新規19本と既存1本の更新、合計20本のセキュリティノートが公開されています。

最上位が **CVE-2026-44756** 、CVSSは **10.0** です。[NVDの記載](https://nvd.nist.gov/vuln/detail/CVE-2026-44756)によると、Extended Passport Protocol（EPP）の処理ライブラリにメモリ安全性の脆弱性があり、 **認証されていない攻撃者が細工したEPPヘッダーを含むネットワークリクエストを送ることで** 、未定義動作と異常終了を引き起こしうる。機密性・完全性・可用性のいずれにも高い影響が出るとされています。CWEは **CWE-120** 、ベクタは `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` で、ネットワーク越し・条件なし・認証不要・ユーザー操作不要・スコープ変化という、上げられる項目がすべて上がった構成です。SAP Note番号は 3747649 。

EPPというのはSAPシステム間の通信で認証情報を運ぶためにSAPが独自に定義した仕組みで、NetWeaverやWeb Dispatcher、各種カーネルコンポーネントが処理します。 **ABAPシステム間では既定で有効** になっているため、「うちは使っていないから関係ない」とはなりにくい。影響を受けるカーネルは 7.22 から 9.20 まで広く、10年以上前の7.22系が対象に入っている一方で、最新の9.20系も含まれています。バージョンを上げていれば安全、という話ではありません。

同じ日のHotNewsには他にも、NetWeaver Message Serverの認証欠如である **CVE-2026-58240** （CVSS 9.8）、SAP Cloud Application Programming Modelのマルチテナント環境での認証情報漏洩 **CVE-2026-76969** （CVSS 9.4）、SAP GUI for Javaの不適切なアクセス制御 **CVE-2026-66768** （CVSS 9.0）が並んでいます。

なお、公開時点で野生での悪用は報告されていません。ただしCVSS 10.0で攻撃条件が緩い以上、PoCが出回れば状況は一気に変わりえます。SAPカーネルの更新はシステム再起動を伴うため、メンテナンスウィンドウの確保が必要です。すぐに当てられない場合は、Web DispatcherやNetWeaverインスタンスへのネットワークアクセスを信頼できるIPに限定する暫定措置を先に打っておくのが現実的でしょう。

## 5. StyleSmuggler続報 — 当てたあとに、公式が8項目のローテーションを求めている

最後は、昨日この枠で扱った Magento / Adobe Commerce のゼロデイ **CVE-2026-75650** （StyleSmuggler）の続きです。脆弱性そのものの解説は繰り返しません。今日取り上げたいのは、 **パッチを当てたあとの手順** として公式が何を要求しているか、という一点です。

Adobeの[パッチ適用手順のドキュメント](https://experienceleague.adobe.com/en/docs/commerce-knowledge-base/kb/announcements/commerce-apsb26-146)には、ホットフィックス適用後にローテーションすべき認証情報が明示的に列挙されています。暗号化キー、管理パネルの全ユーザーパスワード、REST / SOAP / GraphQL の統合トークン、サードパーティアプリのOAuthクライアントシークレット、決済ゲートウェイのAPI認証情報、データベース認証情報、SSH・デプロイキーおよびサービスアカウント認証情報、配送・税計算・連携拡張機能のAPIキー。 **8項目です。**

そしてドキュメントには、なぜそこまでやる必要があるのかもはっきり書かれています。「暗号化キーは統合トークン・決済ゲートウェイ認証情報・システム権限を持つ自動化トークンの暗号化に使われている。暗号化キーをローテーションするだけでは、すでに漏洩した可能性のある認証情報を無効化できない」。つまり、鍵を替えても、その鍵で守られていた中身がすでに持ち出されていたなら意味がない、ということです。

対象は Adobe Commerce と Magento Open Source が 2.4.4 から 2.4.9 まで（2026年8月リリース以前の全サブバージョン）、Adobe Commerce B2B が 1.3.3 から 1.5.3 までです。

**この事案がとりわけ嫌なのは、最初の被害店舗の状態です。** Sansecの[一次アドバイザリ](https://sansec.io/research/stylesmuggler-0day)によると、最初の被害者は 2.4.6-p15 に2026年7月と8月のセキュリティパッチを適用済みで、`security:patch-status` もクリーンな状態でした。当時知られていた範囲では、その店は完璧に「対応済み」だったのです。

設置されるバックドアも厄介です。同じアドバイザリによれば、Rust製のLinuxバイナリが `[kworker/u:8:0]` や `fc-cache`、`chronyd` といった正規プロセスの名前に化けて常駐します。C2は `99.84.67.186:443` へのTLS上のWebSocketが主系で、fc-cache版は `ntp.timesync.to` の123番ポートに向けて60秒ごとに48バイトのUDPパケットを送る、NTPを装った通信を使います。送っている中身はエージェントID・ホスト名・ユーザー名・OSバージョン・メモリとディスクの使用量・稼働状態、そしてroot権限かどうかの指標です。永続化はcronで、fc-cache版が `13,43 * * * *` 、chronyd版が `57,27 * * * *` 。潜伏先は `~/.cache/fontconfig/fc-cache` 、`/tmp/.chrony-<8hex>/chronyd` 、`~/.local/share/.gvfsd/gvfsd-user` などです。

なお、Sansecは **侵害された店舗の総数を公表していません。** Magentoの稼働店舗数として数十万という数字が流通していますが、それは母数であって被害数ではありません。ここは混同しないでおきたいところです。

## まとめ

今日の5本を、パッチとの距離で並べ直すとこうなります。

MikroTikは、 **修正版がとっくに出ているのに攻撃が止まっていない** 。12万2500台という数字はSSHが露出している母数であって侵害数ではありませんが、そのうち未更新の機器が残り続ける限り攻撃側の狩り場も残ります。更新に加えて、`login failure for user -2` と `ops` アカウントの確認まで行って、はじめて対応が閉じます。

6ディストロの一斉配信は、 **当てれば済む** タイプの日でした。ただし86 CVEや100件超といった数字の裏で、HDR画像を開くだけで刺さるGIMPのRCEのような、個別に知っておく価値のあるものが埋もれています。

Asahi LinuxのM3対応は、 **何が動かないかを自分で明示している** という点で今日の中では異質でした。「対応した」の範囲を最初に狭く宣言しておくのは、実は一番信頼できる態度だと思います。

SAPのCVSS 10.0は、 **まだ当てる前** の段階です。悪用は確認されていない。だからこそ、メンテナンスウィンドウを取る余裕がある今のうちに動けます。

そしてStyleSmugglerは、 **当てたあとの作業が8項目残る** 。7月と8月のパッチを全部当てて `security:patch-status` がクリーンだった店が最初の被害者になった、という事実が示しているのは、パッチ適用は「その時点で知られている穴」への対処でしかないということです。

パッチを当てるのは、これ以上入られないようにする作業です。すでに入られていないかを確かめ、持ち出されたかもしれない鍵を差し替えるのは、その次にある別の作業です。今日のうち2件は、後者を公式が明文で要求していました。

あなたの管理下のシステムで、直近に「対応済み」と報告したもののうち、 **入られていないかの確認まで済ませたものはどれくらいあるでしょうか。** 一度、棚卸ししてみる価値はありそうです。

## 参考リンク

- [CERT Polska: MikroTik RouterOS vulnerabilities](https://cert.pl/en/posts/2026/09/mikrotik-routeros-cve/)
- [MikroTik 公式セキュリティアドバイザリ（2026年9月）](https://mikrotik.com/supportsec/september-2026-vulnerability/)
- [Help Net Security: MikroTik RouterOS SSH vulnerabilities exploited](https://www.helpnetsecurity.com/2026/09/07/mikrotik-routeros-ssh-vulnerabilities-exploited/)
- [Linux Security Roundup（2026年9月7日の一斉配信）](https://www.linuxcompatible.org/story/linux-security-roundup-suse-ubuntu-and-debian-ship-major-cve-patches)
- [RHSA-2026:62420（RHEL 8 gegl04、CVE-2026-18300）](https://access.redhat.com/errata/RHSA-2026:62420)
- [Asahi Linux: M2: Episode 1 (or, Asahi Linux on M3)](https://asahilinux.org/2026/09/m2-episode-1/)
- [NVD: CVE-2026-44756（SAP Extended Passport）](https://nvd.nist.gov/vuln/detail/CVE-2026-44756)
- [Sansec: StyleSmuggler 0-day](https://sansec.io/research/stylesmuggler-0day)
- [Adobe Commerce APSB26-146 適用手順と認証情報ローテーション要件](https://experienceleague.adobe.com/en/docs/commerce-knowledge-base/kb/announcements/commerce-apsb26-146)
