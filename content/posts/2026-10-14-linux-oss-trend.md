---
title: "HAProxy Data Plane API の TLS 設定で認証が消える CVE-2026-109575、WordPress Bricksforge の無認証アップロード、Ubuntu 26.10 の Rust 化、KDE Plasma 6.8、Chrome 155（2026/10/14 Linux・OSSトレンド）"
date: 2026-10-14T00:00:00+09:00
draft: false
tags: ["セキュリティ", "脆弱性", "WordPress", "Ubuntu", "Rust", "KDE", "Wayland", "Chrome", "HAProxy", "TLS"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

守りのつもりで足した一手が穴を開け、古い仕組みを手放す一手は、確かめてから打つ。今回の5本は、この「その一手が何に効くのか」という切り口で並べました。足した一手の例が HAProxy と WordPress の Bricksforge、手放す一手の例が Ubuntu 26.10 と KDE Plasma 6.8、守る壁の手入れの例が Chrome です。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言や、裏付けの取れなかった発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "jEYta1no8x8" >}}

## 1. Bricksforge CVE-2026-85097 — 合言葉を配る窓口から始まる4段階の攻撃

WordPress の Bricks Builder の拡張プラグイン Bricksforge に、認証なしで任意のファイルをアップロードできる脆弱性 CVE-2026-85097 が見つかりました。[Patchstack のデータベース](https://patchstack.com/database/WordPress/Plugin/bricksforge/vulnerability/wordpress-bricksforge-plugin-3-1-8-9-unauthenticated-arbitrary-file-upload-via-temporaryfileuploads-parameter-vulnerability)によれば、影響を受けるのは 3.1.8.9 以前で、3.1.8.10 で修正されています。コードの経路は Pro Forms の配下にあります。

CVSS は出所を分けて読む必要があります。Patchstack は 10.0 としています。9.8 は、CVE の採番元（CNA）である Wordfence の値で、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-85097) には Secondary の評価として載っています。NVD 自身が採点した値ではありません。

[Patchstack の記事](https://patchstack.com/articles/critical-unauthenticated-arbitrary-file-upload-vulnerability-exploited-in-bricksforge-plugin/)が書く攻撃の流れは、次の4段階です。

1. 認証なしで呼べる AJAX エンドポイント（bricksforge_regenerate_nonce）から、有効な nonce を受け取る
2. 画像としても有効で PHP コードも含む GIF/PHP ポリグロットをアップロードする。アップロード時の MIME 検証は通る
3. フォーム送信時にクライアントが送るメタデータが信頼されるため、url を PHP 拡張子にして送る
4. PHP として置かれたファイルをリクエストすると、サーバーが埋め込まれたコードを実行する

守るための合言葉が、誰でも呼べる窓口で配られていた、という構図です。

攻撃はすでに観測されています。Patchstack は、2026年10月7日 21:47（UTC）、日本時間では10月8日の朝6時台に最初の攻撃を観測し、63のユニークな送信元 IP を記録しました。うち44の IP は、数秒以内に同一のペイロードで合計56件のリクエストを送っています。拡張子も .php5、.phtml、大文字の .PHP など、書き方を変えて試されていました。

対策は3つです。

- 3.1.8.10 以降へ更新する。[Bricksforge の changelog](https://bricksforge.io/version-changelog/) には 4.0.x 系の版も載っており、確認した時点の最新は 4.0.2（10月13日公開）でした。4.0.1 の項には、Pro Forms のファイルアップロードに関する別のセキュリティ修正も書かれています
- すでに入られていないか確認する。Patchstack の記事によれば、ペイロードの多くは /wp-content/uploads/bricksforge/tmp/ を参照していました。この一時フォルダに不審な PHP ファイルがないかを見ます
- 侵入されると、Web シェルの設置、サイト内容の改ざん、機密データの読み取り、持続的なアクセスの確立が可能になる、と Patchstack は書いています

アップロード先で PHP を実行させない設定は、今回に限らず効く多層防御の基本です（書き手の考えで、一次情報の推奨ではありません）。まずはプラグイン一覧で、Bricksforge を使っているかと版を確認してください。

動画の訂正です。

- 動画では「できれば最新の4.0.1」と紹介しましたが、[changelog](https://bricksforge.io/version-changelog/) によれば 4.0.2 が2026年10月13日に出ており、放送日（10月14日）の時点の最新は 4.0.2 でした。

## 2. Ubuntu 26.10 — cp・mv・rm を手放す前に、外部監査を2回入れた

Ubuntu 26.10 "Stonking Stingray" は、[公式のスケジュール](https://documentation.ubuntu.com/release-notes/26.10/schedule/)で10月15日リリース予定です。この記事の日付の時点では、まだリリースされていません。

目玉は、coreutils の最後の3コマンド cp・mv・rm が Rust 製の uutils に置き換わることです。[It's FOSS](https://itsfoss.com/news/ubuntu-rustification-coreutils-migration/)によれば、残りのコマンドは以前のリリースで移行済みで、cp・mv・rm は uutils 版の欠陥のため 26.04 LTS では見送られていました。遅れの理由は TOCTOU（確認した時点と使う時点の隙を突かれる問題）です。

そこで Canonical は、セキュリティ監査会社の Zellic に2025年12月から2026年3月にかけて2回の監査を依頼しました。2回の合計で113件の問題が見つかり、うち44件に CVE が割り当てられています。大半は解決済みと Canonical は説明しています。既定の構成では GNU 版は外れますが、coreutils-from-gnu パッケージで GNU 版を引き続き入れることができます。

互換性については、uutils は GNU ツールのドロップイン置き換えを目指していますが、一部のオプションが無い、または挙動が違う場合があると It's FOSS は指摘しています。GNU 独自のオプションをスクリプトで使っているなら、CI で動作を確認しておくと安心です。

もう1つの変更が Sequoia PGP です。[OMG! Ubuntu!](https://www.omgubuntu.co.uk/2026/10/ubuntu-rust-pgp-sq) によれば、rust-sequoia-sq パッケージが main リポジトリに移り、標準の GNU 版と並んで最初から使えます。It's FOSS によれば、sq は暗号化・復号・署名・鍵管理を、sqv は署名の検証を担当します。Sequoia は、GnuPG に関わっていた3人が2017年に始めたプロジェクトです（[NGI のインタビュー](https://assure.ngi.eu/?p=468)）。2024年改訂の OpenPGP 規格 RFC 9580 に対応し、GnuPG は LibrePGP を追っています。26.10 でも gpg は引き続き GnuPG を呼び、Sequoia は選べる代わりの道具という位置づけです。

ほかに、[Ubuntu Discourse のロードマップ](https://discourse.ubuntu.com/t/ubuntu-desktop-26-10-stonking-stingray-roadmap-building-toward-ubuntu-28-04-lts/83751)は GNOME 51 の搭載と、dbus-daemon から dbus-broker への移行完了を挙げています。x86-64-v3 向けに最適化した版は、AVX2 などの命令を持たない古い CPU では動きません（[OMG! Ubuntu!](https://www.omgubuntu.co.uk/2026/09/ubuntu-amd64v3-iso-downloads)）。標準の amd64 版は別にあります。

26.10 は中間リリースなので、更新は9か月だけです（[Ubuntu のリリースサイクル](https://ubuntu.com/about/release-cycle)）。サーバーは 26.04 LTS のままが無難でしょう。試すなら、cp・mv・rm を使うスクリプトの動作を CI で確かめてからにしてください。

動画の訂正はありません。

## 3. KDE Plasma 6.8 — 95%のデータと、X11 が必要な人の行き先

KDE Plasma 6.8 は、KDE の[公開スケジュール](https://community.kde.org/Schedules/Plasma_6)で10月14日のリリース予定です。スケジュールには「Coincides with the 30th anniversary of KDE's inception」と書かれています。記事の執筆時点では、KDE の正式なリリースアナウンスはまだ確認できていません。30周年や Union、Kup といった新機能の詳細は、[前日の記事](https://blog.fuga.jp/posts/2026-10-13-linux-oss-trend/)にまとめました。ここでは、手放す前に何を確かめたかに絞ります。

Plasma 6.8 では、ログイン画面に X11 セッションがなくなり、Wayland のみになります。[KDE のブログ](https://blogs.kde.org/2025/11/26/going-all-in-on-a-wayland-future/)がその方針を示しています。範囲にも注意が必要です。[David Edmundson 氏の記事](https://planet.kde.org/david-edmundson-2026-06-02-ex-11-prepping-for-plasmas-last-x11-supported-release/)によれば、削除されるのは Plasma Shell、システム設定、デバイス設定にある X11 専用のコードです。一般の X11 アプリは、まれな例外を除いて XWayland で動くと KDE のブログは書いています。

手放す判断の根拠は、利用者のデータでした。同じ Edmundson 氏の記事（2026年6月）は、KDE 内部の集計で Plasma 6.6 の利用者の95%以上が Wayland を使っていると述べています。対象は 6.6 の利用者です。

では X11 が必要な人はどうするか。同じ記事は「Plasma 6.7 is the last release that will include an X11 session」と書いています。KDE のブログは X11 セッションのサポートを2027年初めまでとしており、[スケジュール](https://community.kde.org/Schedules/Plasma_6)では、2027年1月19日の 6.7.7 が X11 のウィンドウマネージャーのサポートを終えるリリースです。6.6 は LTS で、同じスケジュールによれば約2029年2月までサポートされます。KDE のブログは、X11 を必要とする人には古い版の Plasma を載せた LTS ディストリビューションが向く、とも書いています。

まだ 6.8 に上げない人は、いま使っている版の X11 セッションがいつまで保守されるかを、先に調べておくといいでしょう。X11 前提のリモートデスクトップなどの設定は、この機会に見直しておく価値があります。

動画の訂正です。

- 動画では「X11が必要な人には、Plasma 6.6のLTSが残っていて、そちらでX11のセッションを使い続けられます」と紹介しましたが、KDE の一次情報で確認できたのは、X11 セッションを含む最後の版が 6.7 で、X11 のサポートは2027年初め（スケジュールでは 6.7.7、2027年1月19日）まで、という点です。6.6 は LTS ですが、LTS で X11 セッションを使い続けられるとする記述は確認できませんでした。

## 4. Chrome 155 — サイト分離をすり抜ける CVE-2026-106237、点数と実際の危なさは別

10月6日に公開された Chrome 155 で、セキュリティ修正がまとめて入りました。[HKCERT（香港のセキュリティインシデント対応機関）の速報](https://www.hkcert.org/security-bulletin/google-chrome-multiple-vulnerabilities_20261007)には、Chrome の CVE が多数並んでいます。動画で取り上げたのは、このうち NVD で CVSS が9を超える次の3件です。登録はいずれも10月6日で、修正版は 155.0.8059.39 以降です。

- [CVE-2026-106237](https://nvd.nist.gov/vuln/detail/CVE-2026-106237): サイト分離のすり抜け。CVSS v3.1 は 9.6
- [CVE-2026-106195](https://nvd.nist.gov/vuln/detail/CVE-2026-106195): Chrome Remote Desktop（内部名 Chromoting）の認可の不備。9.1
- [CVE-2026-106294](https://nvd.nist.gov/vuln/detail/CVE-2026-106294): 同じく Chromoting の不完全なクリーンアップ。9.1

106237 の NVD の記述は、Permissions の情報漏えいにより、リモートの攻撃者が細工した HTML ページでサイト分離を回避できた、というものです。ベクターは UI:R で、利用者がそのページを開く操作が前提です。NVD は OS を限定しておらず、HKCERT は Linux、Mac、Windows の版を挙げています。

点数と実際の危なさは別、という点が今回のポイントです。106237 の NVD の記述には「Chromium security severity: Low」と添えられています。悪用される見込みを示す EPSS も低く、FIRST の API では2026年10月13日付で 0.00246（約0.25%）でした。この値は日々変わります。ただし評価が低くても、直っているなら更新しない理由はありません。

残る2件は、NVD の記述では Mac 版の Chrome が対象です。ベクターは AV:N、PR:N、UI:N で、ネットワーク越しに認証も利用者の操作も要らない評価になっています。なお 106294 の 9.1 は Chrome 側（CNA）の評価で、NIST の評価は付いていません。実際に悪用されたという記載は、NVD の記述にはありません。

Chromium ベースのブラウザを使っている場合は、それぞれの配布元の更新状況を確認してください。Chrome の版が 155.0.8059.39 以降になっているかを確かめ、更新が来たら早めの再起動を習慣にしたいところです。

動画の訂正です。

- 動画では「258件もの脆弱性がまとめて直されています」（画面の表示は「258件 を修正」）と紹介しましたが、HKCERT の速報に並ぶ CVE は247件でした。この247件は速報ページに並ぶ CVE を書き手が数えた値で、Chrome 155 全体の修正総数を示すとは限りません。

## 5. HAProxy Data Plane API CVE-2026-109575 — TLS を足したら、ほかの入口の認証が消えた

HAProxy の管理用 API「Data Plane API」で、CVE-2026-109575（CVSS 9.8）が見つかりました。[GitHub のアドバイザリ](https://github.com/advisories/GHSA-7jqw-rhp8-c8vf)の題名によれば、影響は 2.2.0 から 3.4.3 までです（対応する Enterprise Edition も含む）。CVE の公開は10月12日です。

仕組みは皮肉です。アドバイザリによれば、tls_ca（CA 証明書）と tls_port（TLS のポート）を設定すると、アプリケーションは共有の内部リクエストハンドラで Basic 認証を全体として無効にします。mTLS のクライアント証明書の検証は HTTPS の経路だけで行われます。ところがそのハンドラは HTTP、HTTPS、UNIX ドメインソケットの各リスナーで共有されているため、mTLS でない他のリスナーは認証なしで開いてしまいます。

つまり、認証が消えるのは、TLS（CA 証明書と TLS ポート）を設定し、かつ HTTP か UNIX ドメインソケットの入口も開いている構成です。TLS を設定しただけで常に消える、という話ではありません。アドバイザリの英語の原文では、到達できる未認証の攻撃者が、HTTP か UNIX の管理エンドポイントで認証を完全に回避できる、と書かれています。

攻撃が成立すると、平文のままの HAProxy の設定内容を読んだり、raw configuration エンドポイント経由で管理対象の設定を丸ごと置き換えたりできます。設定を置き換えられるなら振り分け先なども書き換えられる、というのは書き手の推論です。

修正は、接続ごとに TLS の状態を検証する方式への変更です。[コミット](https://github.com/haproxytech/dataplaneapi/commit/c3ae4e3)の説明は、CA に対して検証されたクライアント証明書を持つ接続のときだけ Basic 認証を省略し、平文の HTTP と UNIX のリクエストでは常に認証情報を要求する、というものです。変更は本体3ファイルとテスト1ファイル（124行追加）の計4ファイルです。

修正版は 3.4.4、3.3.9、3.2.17、3.0.25、2.9.29 で、5つとも2026年10月9日に公開されています（[v3.4.4 のリリース](https://github.com/haproxytech/dataplaneapi/releases/tag/v3.4.4)ほか）。v3.4.4 には、CSRF 対策、秘密情報を含むファイルを所有者だけが扱える権限で書き出す修正も入っています。

更新できない場合の緩和策として、脆弱性データベース dbugs は、不要な HTTP と UNIX ソケットのリスナーを無効にすることと、管理用インターフェースを信頼できるネットワークに限ることを挙げています。HAProxy 公式の推奨ではない点に注意してください。

確認すべきは、設定ファイルで TLS と HTTP・UNIX ソケットの入口が同居していないかです。同居していたら、修正版へ上げてください。

動画の訂正はありません。

## まとめ

Bricksforge は合言葉を配る窓口が、HAProxy は足した TLS 設定が、それぞれ穴になりました。Ubuntu は外部監査を2回入れてから、KDE は利用者の集計を示してから、古い仕組みを手放しています。Chrome は、点数と実際の危なさが別でも、直っているなら更新する、という壁の手入れでした。どれも、その一手が何に効くかを確かめる話です（書き手の考察です）。

今日できることは、WordPress のプラグイン一覧で Bricksforge の有無と版を確認すること、Chrome と Chromium 系ブラウザの版を確認して再起動すること、Data Plane API の設定で TLS と HTTP・UNIX ソケットの入口が同居していないかを見て修正版へ上げること、そして Ubuntu 26.10 を試すなら CI でスクリプトの動作を確認することです。ひとつだけでも見てみてください。

## 参考リンク

- [Patchstack: Bricksforge の無認証ファイルアップロード](https://patchstack.com/articles/critical-unauthenticated-arbitrary-file-upload-vulnerability-exploited-in-bricksforge-plugin/)
- [NVD: CVE-2026-85097](https://nvd.nist.gov/vuln/detail/CVE-2026-85097)
- [Ubuntu 26.10 のリリーススケジュール](https://documentation.ubuntu.com/release-notes/26.10/schedule/)
- [It's FOSS: Ubuntu の coreutils 移行](https://itsfoss.com/news/ubuntu-rustification-coreutils-migration/)
- [KDE: Plasma 6 のスケジュール](https://community.kde.org/Schedules/Plasma_6)
- [David Edmundson: Plasma の最後の X11 版に向けて](https://planet.kde.org/david-edmundson-2026-06-02-ex-11-prepping-for-plasmas-last-x11-supported-release/)
- [HKCERT: Chrome の複数の脆弱性](https://www.hkcert.org/security-bulletin/google-chrome-multiple-vulnerabilities_20261007)
- [NVD: CVE-2026-106237](https://nvd.nist.gov/vuln/detail/CVE-2026-106237)
- [GitHub: HAProxy Data Plane API のアドバイザリ GHSA-7jqw-rhp8-c8vf](https://github.com/advisories/GHSA-7jqw-rhp8-c8vf)
- [GitHub: Data Plane API v3.4.4 のリリース](https://github.com/haproxytech/dataplaneapi/releases/tag/v3.4.4)

（2026/10/14 Linux・OSSトレンド）
