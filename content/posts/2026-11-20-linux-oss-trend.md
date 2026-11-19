---
title: "nginx の HTTP/2 の脆弱性 CVE-2026-123007 と CVE-2026-123633 に修正版 1.31.9・1.30.7、Gemini 4 Neon が登場、PyPI が V7 形式の tar などを拒否、PHP 8.6.0 と同日に17件のセキュリティ修正、Ruby の Regexp など7件に修正版 3.3.14・3.4.13・4.0.10（2026/11/20 Linux・OSSトレンド）"
date: 2026-11-20T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "NGINX", "HTTP/2", "Gemini", "AI", "PyPI", "Python", "サプライチェーン", "PHP", "Ruby"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

2026年11月20日（金）の動画は、nginx、PyPI、PHP、Ruby で修正や検査の強化が同じ週に重なった回です。もう1本、Gemini 4 Neon の発表も扱いました。修正版は出そろいましたが、手元が対象かどうかは、版と構成の条件を照らし合わせるまで分かりません。そこで各節では、一次の文書にある条件と修正版を先に書きます。この見方は書き手の考察で、各プロジェクトがそう述べているわけではありません。

動画の訂正は、各節の末尾に書いています。確認は2026年11月20日（日本時間）の朝で、時点で変わる値には時刻を添えます。動画の公開は11月19日 21:10 UTC（日本時間 11月20日 06:10）です。

{{< youtube "4I8_DBd1SPE" >}}

## 1. nginx の HTTP/2 の脆弱性2件

11月18日（水）、nginx の修正版 1.31.9（mainline）と 1.30.7（stable）が公開されました（[CHANGES](https://nginx.org/en/CHANGES)）。HTTP/2 まわりの CVE-2026-123007 と CVE-2026-123633 を含め、Security の項目は10件です。

2件は影響を受ける版も条件も別です（[nginx.org のセキュリティ情報](https://nginx.org/en/security_advisories.html)）。

- CVE-2026-123007: 1.9.5 から 1.31.8 までで、HTTP/2 を使う構成が対象です。HTTP/2 を導入した 1.9.5 の公開は2015年9月22日です。
- CVE-2026-123633: 1.19.7 から 1.31.8 までです。CNA の F5 によると、HTTP/2 でクライアントと接続し、バックエンドへリクエストを転送する構成で、ワーカーの worker_connections が足りなくなっているときに、細工したリクエストが use-after-free を起こします。静的ファイルを配信するだけの構成は、この条件に当たりません。

CVSS は2件とも、CVSS 4.0 で 9.2、3.1 で 8.1 です。いずれも CNA の F5 による採点で、NVD 独自の採点は、確認した11月19日 21:51 UTC ごろ（日本時間 11月20日 06:51）の時点ではありません（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-123007)）。nginx.org の深刻度の表示は、CVE-2026-123007 が major、CVE-2026-123633 が medium で、CVSS とは別の尺度です。

発見の経緯について、Wiz は、Wiz Research、Ikotas Labs、Metnir、Rapid7、Xint の5チームが独立に見つけたと書いています（[Wiz](https://www.wiz.io/blog/nginx-http2-rce-vulnerabilities)）。CHANGES の謝辞は別で、CVE-2026-123007 が Xint.io、CVE-2026-123633 が Albert of Vexera AI です。Wiz によると、CVE-2026-123633 は10月21日に報告したところ、F5 から別のチームが先に報告していたと伝えられました。

コード実行について、Wiz は、公式ビルドの 1.31.7 と 1.31.8 で、TLS 上の HTTP/2、64ビット環境、静的ファイルの配信という条件で、ASLR を回避したコード実行を確認したと書いています。Wiz は、悪用には高い技術が要ると述べつつ、意欲のある攻撃者は標的に合わせて作り込みうるとも書いています。攻撃コードは当面公開しないと明言しています。

すぐに上げられない場合、Wiz は HTTP/2 を一時的に止めることを挙げています。1.25.1 以降は server ブロックで `http2 off;` とし、listen の http2 パラメーターも外して設定を読み直し、古いワーカーが終了したことを確かめます（`http2` ディレクティブは 1.25.1 から。[ngx_http_v2_module](https://nginx.org/en/docs/http/ngx_http_v2_module.html)）。Xint によると、HTTP/2 を止めて防げるのはこの2件だけで、同じリリースの他の修正は防げません。

同じ10件のうち、HTTP/3、DNS の名前解決、メールプロキシの3件について、Wiz は CVSS 4.0 の 9.2 でコード実行の可能性があると表にまとめています。nginx.org の CHANGES は、これらを "might have potential other impact" と書き、コード実行とは書いていません。

動画の訂正です。

- 動画のパネルでは、同時に直った10件を「RCE 2件含む」と伝えました。正しくは、Wiz は HTTP/3・DNS の名前解決・メールプロキシの3件もコード実行の可能性ありとしていて、計5件です。nginx.org の CHANGES はコード実行とは書いていません（[Wiz](https://www.wiz.io/blog/nginx-http2-rce-vulnerabilities)、[CHANGES](https://nginx.org/en/CHANGES)）。

## 2. Gemini 4 Neon

Google は11月18日（米国時間の発表日表記）に Gemini 4 Neon を発表しました（[発表](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-neon/)）。位置づけについて Google は、Carbon が最も難しい長期の作業、Hydrogen が高速な日常の実行を担い、Neon は深さと効率のバランスを取ると書いています。ドキュメントには、確認時点（11月20日）で Gemini 4 Argon もあります。

[料金ページ](https://ai.google.dev/gemini-api/docs/pricing)によると、入力は100万トークンあたり3ドル、出力は15ドルで、有料プランのみです。キャッシュされた入力は0.15ドル（95%引き）ですが、キャッシュは暗黙的なものだけで、明示的なキャッシュには対応していません。文脈は100万トークン、思考の深さは low・medium・high・xhigh の4段階で、標準は high です（[思考レベル](https://ai.google.dev/gemini-api/docs/thinking)）。Google は、Android Studio からも使えると書いています。

ベンチマークの値は、いずれも Google の発表によるものです。

- Google は、標準の high で Artificial Analysis の Intelligence Index を高く保ちつつ、タスクあたりのコストは Carbon より32%低いと発表しました。Artificial Analysis によると Carbon は11月30日まで割引価格で、どちらの価格で比べるかによって差は変わります。
- Google は、Artificial Analysis の Coding Agent Index（58.6）で全体の1位と発表しました。一方、Artificial Analysis の[記事](https://artificialanalysis.ai/articles/gemini-4-neon-intelligence-gain)は、Neon（xhigh）を59とし、Claude Code で Claude Fable 5.2 を使った場合（58）や Claude Opus 5.5 の場合（58）と同水準と評価しています。「1位」とは書いていません。
- 評価中の不正について、Google は、Terminal-Bench 4.0 での不正の割合が Carbon と同じ0.0%、別のコーディングの不正の評価で近道を取った割合が2.45%（Gemini 4 の中で最低）と書いています。Gray Swan のベンチマークでは、リアルタイムの保護機構を併用し最深の思考設定で、攻撃成功率0.0%としています。いずれも Google の評価です。

防御向けの Neon for cyber は、適格な Fairwind Program のメンバーに数日のうちに順次提供される、と Google は書いています。

動画の訂正はありません。

## 3. PyPI の配布物の厳格チェック

PyPI は11月18日付のブログで、アップロードされる sdist と wheel への検査の追加を説明しました（[PyPI ブログ](https://blog.pypi.org/posts/2026-11-18-stricter-checks-for-uploaded-sdists/)）。目的は、同じファイルが読み取るツールごとに違って展開される、パーサー差分への耐性を上げることです。ブログは、利用者側（pip install や uv add で入れる側）への直接の影響はなく、すでに依存している配布物も使い続けられると書いています。影響しうるのは、配布物を手作業で作るメンテナーです。

ブログによると、ここ数週間で次を拒否し始めています。

- V7 形式の tar の sdist。V7 は古く仕様のほとんどない形式で、Python の tarfile は作りません。拒否する PR のマージは2026年10月27日 23:19 UTC（日本時間 10月28日 08:19）で、本番への反映日ではありません（[PR #20829](https://github.com/pypi/warehouse/pull/20829)）。
- ZIP の制御構造と誤読されうるアーカイブ・コメントを持つ wheel。

このほか PyPI の docs は、スパースメンバーを含む sdist を受け付けないと書いています（[Archive Formats](https://docs.pypi.org/archives/)）。

sdist は仕様上、pax 形式の tar である必要があります。GNU tar を使うときは `--format=pax` を付けるか、tar や zip で手作業で固めず Python のビルドバックエンドで作る、とブログは案内しています。uv は 0.13.0（10月9日 UTC 公開）以降、V7 形式の sdist を展開できません（[issue #22955](https://github.com/astral-sh/uv/issues/22955)）。

今後の予定として、ブログは GNU 形式の tar の全面拒否と ZIP コメントの全面拒否を「検討中」としています。GNU 形式などの扱いについては、issue #21012 に、pax 以外の形式が上位1万5000パッケージの約1割に残っているため長い警告と移行の期間が要る、という記述があります（[issue #21012](https://github.com/pypi/warehouse/issues/21012)）。今回の変更は、2025年8月に Seth Larson 氏が進めた ZIP の差分の低減の作業の上に積まれた、とブログは書いています。

動画の訂正です。

- 動画では、USENIX Security の論文が tar と ZIP のパーサー差分をまとめ、今回の対策の理論的な裏付けだと伝えました。正しくは、論文は ZIP パーサーだけを扱い（題名は "My ZIP isn't your ZIP"）、PyPI の docs は「さらに読む」として挙げているだけです（[USENIX](https://www.usenix.org/conference/usenixsecurity25/presentation/you)）。
- 動画では、wheel で拒否されるポイントは5つだと伝えました。正しくは、docs は wheel について7項目を挙げ、それも「いくつかの機能」と断っています（[Archive Formats](https://docs.pypi.org/archives/)）。

## 4. PHP 8.6.0 と同日のセキュリティ修正

PHP 8.6.0 は11月19日（木）に公開されました（[PHP 8.6 の新機能](https://www.php.net/releases/8.6/en.php)）。主な新機能は次のとおりです。

- 部分適用: 引数の一部だけを先に渡し、残りに `?` などを置くと、残りを後で渡すクロージャが返ります。
- Duration: ストップウォッチの経過時間を表すクラスで、ナノ秒の精度で250年を超える範囲を表せます。
- Io\Poll API: epoll や kqueue などをまとめた I/O 多重化の API で、ReactPHP や AMPHP のようなライブラリ向けです。
- Sodium: libsodium 1.0.22 の KEM API（X-Wing と ML-KEM768）に対応しました。
- session の既定値: use_strict_mode と cookie_httponly が有効、cookie_samesite が "Lax" になりました（[ChangeLog](https://www.php.net/ChangeLog-8.php)）。

同じ11月19日に、サポート中の全系列でセキュリティリリース（8.5.13、8.4.28、8.3.37、8.2.36）が出ています。php.net の告知は "This is a security release." とだけ書き、CVE 番号を載せていません。GitHub の Security Advisory では、同じ日に17件が公開され、分類は critical 7件、high 4件、medium 6件です。前日の予告では、最も高い深刻度は CRITICAL とされ、CRITICAL の問題は既定とは異なる設定か、一般的ではない構成が必要、と書かれています。個別の条件までは本記事では確かめていません。8.6.0 の ChangeLog にも、11月19日の修正が載っています。

これとは別に、10月21日には、認証なしのリモートコード実行につながりうる2件（CVE-2026-109618 と CVE-2026-109619）が、8.5.12、8.4.27、8.3.36、8.2.35 で直っています（[php.net の告知](https://www.php.net/archive/2026.php)）。CVSS は、PHP（security@php.net）の採点が 4.0 で 9.2、NVD の採点が 3.1 でそれぞれ 9.8 と 8.1 です（[GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)）。告知によると、CVE-2026-109618 は、メモリ不足の処理がリクエストの内部データの初期化の途中で割り込み、後片付けがその不完全なデータを有効なものとして扱う問題です。CVE-2026-109619 は、リクエストが持つ内部状態がメモリの解放後も残り、同じワーカーが後で処理するリクエストがそれを使ってしまう問題です。8.6.0 RC4 の告知は、この2件の修正を含むと書いています。

サポートについて、PHP 8.2 のセキュリティサポートは2026年12月31日までです（[サポート期間](https://www.php.net/supported-versions.php)）。8.1 以前は、PHP プロジェクトから更新を受け取れません。

動画の訂正です。

- 動画では、The Register も予告の段階から、出たらすぐ当てるよう呼びかけていた、と伝えました。正しくは、The Register の記事は PHP の予告の文言（"prepare to upgrade promptly once the releases become available"）を引用したもので、記事自身の呼びかけではありません（[The Register](https://www.theregister.com/patches/2026/11/18/another-critical-php-security-release-has-dropped/5310911)）。

## 5. Ruby の Regexp と String の大文字小文字変換の脆弱性

Ruby は11月18日付で、正規表現エンジンと文字列の大文字小文字変換にある7件の脆弱性を告知しました（[Ruby の告知](https://www.ruby-lang.org/en/news/2026/11/18/multiple-vulnerabilities-in-regexp-and-string/)。更新履歴の初出は11月19日 00:00 UTC で、日本時間では同日 09:00）。GitHub の Security Advisory の分類は、critical が3件、high が3件、medium が1件です。CVE は割り当て前で、GHSA 上の CVSS（3.x と 4.0）は7件とも未設定です。

影響を受けるのは、Ruby 3.3.13 以前、3.4.0 から 3.4.12、4.0.0 から 4.0.9 です。修正版は 3.3.14、3.4.13、4.0.10 で、3.2 以前はサポート期間が終わっていて、修正は出ません。告知は、回避策を示さず、更新を強く勧めています。

条件は件ごとに違います。

- 正規表現: 攻撃者が与えた文字列からパターンを作る（コンパイルする）アプリが対象です。
- 大文字小文字変換: 告知は、細工した文字列の変換でコード実行になりうると書きます。個別には、ISO-8859-1 や Windows-1252 などの1バイト系エンコーディングで出力バッファの1バイト先へ書く問題と、変換結果が 4 GiB を超えると長さがあふれる問題があります（[GHSA-34m4-m9fh-gqp5](https://github.com/ruby/ruby/security/advisories/GHSA-34m4-m9fh-gqp5)、[GHSA-87fm-7w84-j2px](https://github.com/ruby/ruby/security/advisories/GHSA-87fm-7w84-j2px)）。

告知は、一部がリモートコード実行に使えることを示す実証コードを把握している、とも書いています。

クレジットは、7件のうち4件が Stephan Lipp（Ada Logics）と Anthropic の連名です。残りの3件は別の報告者です。どの手順で見つけたかは、告知にも GHSA にも書かれていません。11月3日の記事で GitLab の件の下限として挙げた Ruby の版（3.3.13・3.4.12・4.0.9）は今回の影響範囲に入るため、下限は 3.3.14・3.4.13・4.0.10 に上がりました。

動画の訂正はありません。

## まとめ

実務で確かめておくものは次のとおりです。

- nginx: 版を確認し、1.31.9 または 1.30.7 へ上げる。HTTP/2 を使っているか、バックエンドへ転送するリバースプロキシ構成かを確かめる。すぐ上げられない場合の `http2 off;` は、同じリリースの他の修正を防がない。
- PyPI: 配布物は tar や zip を手作業で固めず、Python のビルドバックエンドで作る。GNU tar なら `--format=pax` を付ける。
- PHP: 使っている系列の修正版（8.5.13、8.4.28、8.3.37、8.2.36）か 8.6.0 へ上げる。8.2 のセキュリティサポートは2026年12月31日まで。
- Ruby: 手元の版が上の範囲に入るかを確かめ、3.3.14、3.4.13、4.0.10 のいずれかへ上げる。
- Gemini: 価格は暗黙的キャッシュのみの前提で、ベンチマークの値は発表した側の評価として読む。

## 参考リンク

- [nginx.org のセキュリティ情報](https://nginx.org/en/security_advisories.html)
- [Wiz: nginx の HTTP/2 の脆弱性](https://www.wiz.io/blog/nginx-http2-rce-vulnerabilities)
- [Google: Gemini 4 Neon の発表](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-neon/)
- [PyPI ブログ（2026-11-18）](https://blog.pypi.org/posts/2026-11-18-stricter-checks-for-uploaded-sdists/)
- [PHP 8.6 の新機能](https://www.php.net/releases/8.6/en.php)
- [Ruby の告知（Regexp と String）](https://www.ruby-lang.org/en/news/2026/11/18/multiple-vulnerabilities-in-regexp-and-string/)

（2026/11/20 Linux・OSSトレンド）
