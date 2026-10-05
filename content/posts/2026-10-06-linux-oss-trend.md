---
title: "直したはずが、次の穴に？ Debian DSA-6528-1・Citrix NetScaler CVE-2026-88779・Wine 11.19・KDE Plasma 6.8・Ubuntu 26.10 uutils（2026/10/6 Linux・OSSトレンド）"
date: 2026-10-06T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Debian", "Linux カーネル", "Citrix", "CISA KEV", "Wine", "Wayland", "KDE", "Ubuntu", "Rust", "uutils"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

良かれと思って入れた改善が、次の穴の入口になる。直したはずのものが本当に直っているかは、あとで確かめるまで分からない。今日の5本は、そんな見立てで並べました。1,313件の CVE を並べた Debian のカーネル更新、別の脆弱性の修正を当てた装置でも影響が報じられた NetScaler、Wayland に追いつこうとする Wine、X11 を手放す KDE、そして cp・mv・rm を含む Rust 製コマンド一式に切り替わる Ubuntu です。

共通点の指摘は書き手の考察で、各出典の評価ではありません。動画では、裏付けの取れなかった発言や数字がいくつかありました。確認し直した結果は、各節の「動画の訂正」にまとめてあります。

{{< youtube "xptxqtEPhy0" >}}

## 1. Debian DSA-6528-1 — カーネル更新に 1,313 件の CVE、OVSwrap は別の更新で修正済み

9月29日、Debian は [DSA-6528-1](https://lists.debian.org/debian-security-announce/2026/msg00441.html) として linux カーネルの更新を公開しました。公開者は Salvatore Bonaccorso 氏です。本文の書き出しは "Several vulnerabilities have been discovered in the Linux kernel" と控えめですが、[Debian security tracker](https://security-tracker.debian.org/tracker/DSA-6528-1) に並ぶ CVE は重複を除いて1,313件でした。修正版は stable（trixie）の 6.12.111-1 です。この更新の対象は trixie だけで、ほかのスイートの版は本文に書かれていません。

件数の多さについて、Jan Schaumann 氏は [oss-security への投稿](https://www.openwall.com/lists/oss-security/2026/09/29/18)で、件名の "several" が実際には1,313件の CVE ID の一覧だと皮肉っています。背景として同氏は、カーネルチームがほぼすべての変更に CVE ID を付けることと、AI の支援で見つかる脆弱性が増えたことを、推測として挙げています。同氏によれば、個々の CVE を追う意味は薄い。かといって、頻繁に出る全更新を無審査で当てるのも、大規模な環境では選択肢になりません。変更が別の問題を生むからです。そのうえで同氏は、使っていないモジュールを無効にする、コンテナを信頼できる境界とみなさない、といった攻撃面の縮小を勧めています。

ここからが今日のテーマに近い話です。動画では CVE-2026-64530 と CVE-2026-64531 を DSA-6528-1 の目玉として紹介しましたが、正しくは、この2件は DSA-6528-1 に含まれていません。両方とも、先に配信されていた [DSA-6405-1](https://security-tracker.debian.org/tracker/DSA-6405-1) に収録されており、tracker 上の trixie の修正版は 6.12.100-1 です。1,313件の中の目玉、ではなかったわけです。

CVE-2026-64530 は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-64530) に載る CVSS v3.1 のスコアが 9.8（CNA 提供値）です。説明によれば、net/sched の cls_api で、断片化したパケットを act_ct が保持している間も RED qdisc が触り続けてしまう use-after-free です。再現例は、RED の qevent と act_ct を組み合わせた tc 設定でした。攻撃に必要な権限の細かい条件は、NVD の説明に書かれていないので、ここでは触れません。

CVE-2026-64531 は CVSS v3.1 で 7.8（これも CNA 提供値）です。[NVD の説明](https://nvd.nist.gov/vuln/detail/CVE-2026-64531)が、今日のテーマそのものでした。Open vSwitch のコミット a1e64addf3ff は、アクション列の合計が 64 KiB を超えられるようにしました。これ自体は正当な変更です。ところが同じコミットで、生成されたネストしたアクション属性が U16_MAX を超えるのを防ぐ最後の歯止めも外れてしまった、とあります。Open vSwitch は 2012 年にメインラインに入ったコードです。改善のつもりのコミットが、そこにあった安全装置まで一緒に外した、という構図です。

「OVSwrap」という呼称は、報告者の Asim Manizada 氏が [7月28日の oss-security](https://www.openwall.com/lists/oss-security/2026/07/28/8) で付けたものです。NVD や Debian の呼称ではありません。同氏は PoC と緩和策も公開しています。悪用の有無は、確認した範囲では分かりませんでした。報告者が挙げる条件は、OVS のカーネルデータパスで conntrack を使っていることと、非特権の user namespace か CAP_NET_ADMIN を持てることです。

動画の訂正です。

- 64530 と 64531 は DSA-6528-1 の一部として紹介しましたが、DSA-6405-1 の収録です。
- Bookworm の更新版を DSA-6528-1 の修正版のように紹介しましたが、この DSA の対象は trixie のみです。
- 「過去最大規模」と「Debian がまとめて確認してから公開する運用が背景」は、裏付けが取れませんでした。
- 64530 の攻撃条件、64531 の「2025年3月の改修」「32KiB の上限」「約800種の攻撃コード」「上流の修正版」も、確認できた一次情報の範囲を超えるため外しました。

## 2. Citrix NetScaler CVE-2026-88779 — SAML の脆弱性、開示の翌日に KEV 入り

Citrix は10月3日、[セキュリティ情報 CTX697174](https://support.citrix.com/external/article/CTX697174/citrix-netscaler-adc-and-citrix-netscale.html)を公開し、同じ日に修正版も出しました。NVD への登録は10月4日で、開示日は Citrix が3日、NVD が4日と1日ずれています。

対象は、NetScaler ADC または NetScaler Gateway を SAML の SP（認証結果を受け取ってサービスを提供する側）か IdP（身元を証明する側）として構成している装置です。設定に `add authentication samlAction` か `add authentication samlIdPProfile` があるかで確認できる、と Citrix は書いています。影響を受ける版は、14.1 系が 14.1-73.41 未満、13.1 系が 13.1-64.28 未満です。FIPS 版は別のビルド番号で、14.1-73.41 FIPS 未満と 13.1-37.282 未満（13.1-FIPS と NDcPP）です。修正版はそれぞれ、その番号以降になります。

脆弱性の分類は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-88779) で CWE-119（メモリバッファの境界制限の不備）です。CVSS は v4.0 で 8.7（High）、NVD の v3.1 では 7.5 です。Citrix は SAML 認証構成でのメモリオーバーフローによるサービス拒否（DoS）と説明しており、コード実行とは書いていません。NVD のベクタは、権限不要でネットワーク経由の攻撃となっています。Citrix によれば、Bishop Fox と watchTowr が開示で協力したとのことです。

[CISA の KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-88779)には、開示の翌日の10月4日に追加されました。連邦機関の対応期限は10月7日で、開示から4日後です。

気になるのは、パッチ済みの装置への攻撃という見出しです。[SecurityWeek](https://www.securityweek.com/exploitation-of-citrix-netscaler-zero-day-hits-appliances-patched-days-earlier/) によれば、研究者の Kevin Beaumont 氏が自身のハニーポットで、ダウンロードされたマルウェアのバイナリが動いているのを報告しました。また、直前の脆弱性である CVE-2026-88771 と CVE-2026-88772 に向けて最新へ更新した NetScaler が再起動を繰り返した、という報告も紹介されています。ここでいう「パッチ済み」は、88779 の修正版ではなく、その前の脆弱性の修正を当てた装置を指す可能性が高い、というのが筆者の読みです。88779 の修正版が破られた、という話ではありませんし、なぜその機器が狙われたかを、確認できた範囲の一次情報は説明していません。攻撃者の帰属も、報じられていません。

だからといって、手元の版の確認が不要になるわけではありません。直前の修正を当てたつもりでも、今回の版まで届いているかは別の話です。設定に SAML があるかを見て、あれば修正版かどうかを確かめる、という地味な手順が、今回は一番効きます。

動画の訂正です。

- 動画タイトルの「パッチ済みNetScalerへの攻撃」は、88779 の修正版が破られた、と読めてしまいます。実際は、直前の脆弱性の修正を適用した装置でも影響が報じられた、という話です。
- 「ログイン前の段階で攻撃できるのでパスワード不要」と紹介しましたが、確認できたのは NVD のベクタ上の「権限不要」までです。
- ノルウェーの機関によるコード実行の報告、ユーザー名欄へのコマンド投入の話、「今年6本目の KEV」、Global Deny List、暫定策としての SAML 停止などは、裏付けが取れなかったため外しました。
- 「修正が攻撃を止め切れていない可能性と、版番号の取り違えの可能性が両方ある」という説明も、確認できた出典にはありません。

## 3. Wine 11.19 — Wayland ドライバーが Vulkan の色空間向けのカラーマネジメントに対応

Wine 11.19 は、[Linuxiac](https://linuxiac.com/wine-11-19-adds-dns-caching-unicode-18-support-fixes-23-bugs/)によれば10月2日のリリースです。目玉は、[Phoronix](https://www.phoronix.com/news/Wine-11.19-Released) が "the Wine Wayland driver now implementing the color management protocol for the Vulkan color space" と伝えている、Wayland ドライバーのカラーマネジメント対応です。ゲームなどが Vulkan で色空間を指定したとき、その情報を Wayland のプロトコルを通して扱えるようになった、という内容です。

[GamingOnLinux](https://www.gamingonlinux.com/2026/10/wine-11-19-released-with-wayland-colour-management-unicode-upgrades-dns-query-cache/) は、同じ変更について "nice to see Wine Wayland continuing to mature as well"（Wine の Wayland が成熟し続けているのも嬉しい）と書いています。この言い回しは GamingOnLinux のもので、Phoronix のものではありません。Wayland のカラーマネジメントは長い時間をかけて標準化されたもので、Wine がそこに追いついた、と筆者は受け取っています。

もうひとつの変更は、DNS クエリのキャッシュです。Phoronix は "now supports caching of DNS queries" と書き、Linuxiac は、同じホスト名を繰り返し引くのを避けるための仕組みと説明しています。どの DLL に入ったのか、どんな期限でためるのかは、取得できた記事には書かれていませんでした。WineHQ の公式アナウンスは取得できず、実装の細部は確認できていません。

日本語のユーザーに関係しそうな変更もあります。Phoronix は GDIPlus の縦書き対応を伝え、Linuxiac は Unicode 18.0 への対応に触れています。既知のバグ修正は23件で、GamingOnLinux は修正対象として Zombie Army 4: Dead War、Euro Truck Simulator 2、Final Fantasy XI Online などを挙げています。

動画の訂正です。DNS キャッシュに関連して「2016年から残っていたバグ報告 40606 番が解消に向かった」と紹介しましたが、誤りでした。[Bug 40606](https://bugs.winehq.org/show_bug.cgi?id=40606) は2016年5月に報告されたものの、Wine 5.4 の時点でスタブが追加され、すでに CLOSED FIXED です。11.19 の DNS キャッシュとは結び付けられません。ほかに、有効期限の範囲でためる、Wayland に切り替える設定が要る、安定版の12.0は2027年初めごろ、という話も裏付けが取れなかったため外しました。

## 4. KDE Plasma 6.8 — X11 セッションを手放し、NVIDIA のトリプルバッファリングを戻す

[KDE 公式のスケジュール](https://community.kde.org/Schedules/Plasma_6)では、Plasma 6.8.0 のリリースは10月14日（水）の予定です。10月8日は tarball の日付で、リリース日ではありません。同じ表の注記には、KDE の設立30周年に重なる、とあります。9月24日には、6.8 の Beta 2（6.7.91）が出ています。

X11 セッションの廃止は、[GamingOnLinux](https://www.gamingonlinux.com/2026/06/kde-plasma-waves-goodbye-to-x11-for-plasma-6-8/)が引く説明によれば、"As of today, the Plasma X11 session you can log into has been officially removed, and we will start a mass cleanup of X11-specific code soon" というものです。つまり、ログインで選べる Plasma の X11 セッションがなくなり、X11 固有のコードの大掃除は今後始まります。X11 向けのアプリは XWayland で動き続けます。なお、Plasma Login Manager には、ほかのデスクトップの X11 セッションを起動する機能が残る、とも同記事にあります。消えるのは Plasma の X11 セッションで、ほかのデスクトップの X11 まで無くなるわけではありません。廃止そのものは、2025年に予告されていました。

今日のテーマに近いのは、NVIDIA GPU でのトリプルバッファリングです。[pbxscience](https://pbxscience.com/kde-plasma-6-8-to-re-enable-triple-buffering-for-nvidia-gpus-by-default/) によれば、この機能は6.1（2024年6月）で NVIDIA の Wayland に導入されたものの、描画の乱れの報告があり、6.2.1（2024年10月）で既定が無効になりました。[This Week in Plasma（6月27日）](https://blogs.kde.org/2026/06/27/this-week-in-plasma-post-6.7-bug-fixing/)には、Xaver Hugl 氏が NVIDIA GPU で既定を有効に戻したと書かれています。理由は、以前それを妨げていたバグが修正されたから、とのことです。一度引っ込め、直ってから戻す、というのは地味ですが、改善を前に進めるやり方だと思います。

見た目の面では、新しいテーマの仕組み Union が、[8月28日の This Week in Plasma](https://blogs.kde.org/2026/08/28/this-week-in-plasma-qtwidgets-apps-join-the-union/) で QtWidgets のアプリに初期対応したと伝えられています。技術プレビューの段階です。6.9.0 は、スケジュール上は2027年2月23日の予定です。

動画の訂正です。

- 「残りのバグが4件」「Wayland 専用の最初のメジャーアップデート」は、一次情報で確認できませんでした。
- 「2年近くかけて原因を直した」は、一次には期間の記述がありません。
- Union の対応アプリ名（Dolphin・Kate・KMail）、約9000行のコード、開発者名、「6.9 の主なテーマは Union の安定化」、「4か月ごとのリリース」も、確認できなかったため外しました。
- Beta 2 のアナウンスには、X11 の廃止やトリプルバッファリングの記述はありません。これらの根拠には使っていません。

## 5. Ubuntu 26.10 — cp・mv・rm を含む uutils 一式へ、見つかった穴の多くは「GNU との挙動の違い」

[OMG! Ubuntu](https://www.omgubuntu.co.uk/2026/09/ubuntu-2610-rust-coreutils-complete) によれば、Ubuntu 26.10 "Stonking Stingray" のリリースは10月15日の予定です。cp・mv・rm は、26.04 LTS では TOCTOU（確認した時点と使う時点のすき間を突く問題）が相次いだため GNU 版のまま据え置かれていました。26.10 では、ls・cat・chmod・du などを含む Rust 製コアユーティリティ一式に、この3つも加わります。GNU 版のコマンドが一つも残らないのかは、記事に書かれていません。そのため、ここでは「uutils 一式へ移行」とだけ書いておきます。

据え置きの背景には、セキュリティ監査があります。[It's FOSS](https://itsfoss.com/news/ubuntu-rustification-coreutils-migration/) によれば、Zellic の監査は2回にわたり、2025年12月から2026年3月に113件の指摘を出し、そのうち44件に CVE が割り当てられました。同記事は、cp・mv・rm の移行が、監査で見つかった TOCTOU のために26.04 LTS から延期されたと書いています。

今日のテーマの核は、[uutils 0.9.0 のリリースノート](https://github.com/uutils/coreutils/releases/tag/0.9.0)のこの一文です。"many of these CVEs are not memory-safety issues but differences in behavior from GNU coreutils"（これらの CVE の多くは、メモリ安全性の問題ではなく、GNU coreutils との挙動の違いである）。Rust にしたことで、メモリの扱いのミスは言語の仕組みとして起きにくくなりました。それでも、TOCTOU や挙動の違いは別の問題として残ったわけです。

個々の CVE を NVD で見てみます。[CVE-2026-35355](https://nvd.nist.gov/vuln/detail/CVE-2026-35355) は install のファイル配置時の TOCTOU で、CVSS v3.1 は 6.3、0.6.0 未満が対象です。[CVE-2026-35364](https://nvd.nist.gov/vuln/detail/CVE-2026-35364) は mv が別のデバイスをまたいで移動するときの TOCTOU で、こちらも 6.3 です。[CVE-2026-35362](https://nvd.nist.gov/vuln/detail/CVE-2026-35362) は、リンクのすり替え対策の safe_traversal モジュールが Linux 限定になっていて、macOS や FreeBSD では保護が効かなかった、というもので、CVSS v3.1 は 3.6（LOW）です。どれも、メモリ破壊の話ではありません。

0.9.0（5月30日公開）の対策は、リリースノートによれば、TOCTOU に強い safe_copy モジュールの新設、cp・mv・chmod の再帰処理の修正、rm の `.` や `..` を使ったパスへの防御です。

It's FOSS は、7月に uutils の cp が、ライブイメージのビルドを一時的に壊したが、すぐ直った、とも書いています。直したあとにも別の不具合が出る、という今日のテーマが、ここにも顔を出しています。不安なら、It's FOSS によれば `coreutils-from-gnu` パッケージで GNU 版に戻せます。

動画の訂正です。

- CVE-2026-35364 を「リンクのすり替えで任意のファイルを上書きされるおそれ」と紹介しましたが、NVD の説明は TOCTOU の記述にとどまります。
- 「7件がクリティカル」は、確認した出典にありませんでした。
- 「約100のコマンド」「大量のファイルの再帰処理は GNU 版と同等以上」「LTS では uutils-coreutils パッケージで先に試せる」「Linux Mint や Pop!_OS にも届く」も、裏付けが取れなかったため外しました。

## まとめ

Debian では、改善のコミットが最後の歯止めを巻き込んで外し、NetScaler では、直前の修正を当てた装置でも影響が報じられました。Wine は Wayland の新しい仕組みに追いつき、KDE は一度引っ込めた機能を、直ってから戻しています。Ubuntu では、Rust にしたあとに、GNU との挙動の違いという別の穴が見つかりました。

直したあとに、本当に直ったかを確かめる。明日からできることは二つです。まず、Debian のカーネルを更新して再起動し、`uname -r` で動いているカーネルを見て、入っている linux-image の版と突き合わせる。次に、NetScaler を使っているなら、SAML の設定の有無と版を Citrix の情報と見比べる。皆さんの現場なら、どれから手を付けますか。

## 参考リンク

- [Debian: DSA-6528-1](https://lists.debian.org/debian-security-announce/2026/msg00441.html)
- [Debian security tracker: DSA-6405-1](https://security-tracker.debian.org/tracker/DSA-6405-1)
- [NVD: CVE-2026-64531](https://nvd.nist.gov/vuln/detail/CVE-2026-64531)
- [Citrix: CTX697174](https://support.citrix.com/external/article/CTX697174/citrix-netscaler-adc-and-citrix-netscale.html)
- [SecurityWeek: NetScaler のゼロデイ悪用](https://www.securityweek.com/exploitation-of-citrix-netscaler-zero-day-hits-appliances-patched-days-earlier/)
- [Phoronix: Wine 11.19](https://www.phoronix.com/news/Wine-11.19-Released)
- [KDE: Plasma 6 のスケジュール](https://community.kde.org/Schedules/Plasma_6)
- [This Week in Plasma（6月27日）](https://blogs.kde.org/2026/06/27/this-week-in-plasma-post-6.7-bug-fixing/)
- [OMG! Ubuntu: Ubuntu 26.10 の Rust 製コアユーティリティ](https://www.omgubuntu.co.uk/2026/09/ubuntu-2610-rust-coreutils-complete)
- [uutils coreutils 0.9.0 リリースノート](https://github.com/uutils/coreutils/releases/tag/0.9.0)
