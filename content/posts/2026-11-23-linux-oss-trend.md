---
title: "VMware vCenter の認証バイパス CVE-2026-123890 に修正版 9.1.1.0200・9.0.2.0200・8.0 U3m（7.0 系は修正版なし）、Debian 13.8 が GRUB の Secure Boot バイパス CVE-2026-97876 を修正、LLVM が Apache 2.0 への再ライセンスを完了としてまとめる、KDE の端末 Kwi 0.1 が公開、Apache Roller の CVE-2026-129448 が CISA KEV に追加（2026/11/23 Linux・OSSトレンド）"
date: 2026-11-23T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "VMware", "vCenter", "Debian", "LLVM", "ライセンス", "KDE", "ターミナル", "Apache", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「止めた」「直した」「終わった」は、報告の一言としては短くても、指す範囲は文書ごとに違います。2026年11月23日（月）の動画では、パッチの適用、設定画面でのオフ、作業の完了を扱う5つの話題を取り上げました。どれも、一次の文書が書いている範囲は、一言から受ける印象より狭いか、条件付きでした。5つに共通するこの見方は書き手の考察で、各プロジェクトが述べていることではありません。

動画の訂正は、各節の末尾に書いています。確認は2026年11月23日（日本時間）の朝で、時点で変わる値には時刻を添えます。動画の公開は11月22日 22:42 UTC（日本時間 11月23日 07:42）です。

{{< youtube "launmY-Z1rI" >}}

## 1. VMware vCenter の認証バイパス CVE-2026-123890

Broadcom は11月19日（木）に、vCenter などの更新を告げる [VMSA-2026-0009](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/39495) を公開しました。CVE-2026-123890 は、VMware Directory Service の認証バイパスで、vCenter にネットワークで到達できる者が認証を迂回して不正にアクセスできる、と書かれています。Google の GTIG（Google Threat Intelligence Group）のブログは、表示上の日付が11月20日（金）で、Broadcom の公開日とは分けて扱います。

CVSS は v3.1 で 9.8 です。採点者は Broadcom で、NVD 上は source が `security@vmware.com`、type が Secondary です。NVD 独自の採点は、確認した11月22日 23:30 UTC ごろ（日本時間 11月23日 08:30）の時点ではありません（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-123890)）。

修正版と対象は次のとおりです。

- 9.1 系は 9.1.1.0200、9.0 系は 9.0.2.0200、8.0 系は 8.0 U3m が修正版です。
- 7.0 系は、Response Matrix に修正版の記載がなく、延長サポート契約があれば Broadcom のサポートへ、とあります。Broadcom の Q&A によると、vSphere 7 は2025年10月2日に一般サポートが終了しています（[Q&A](https://github.com/vmware/vcf-security-and-compliance-guidelines/blob/main/security-advisories/vmsa-2026-0009/README.md)）。
- ワークアラウンドは "None" で、対処はパッチの適用です。

悪用について、GTIG は、2026年9月初旬にフォレンジックの証拠でゼロデイとしての悪用を確認した、と書いています。帰属は GTIG の言い方で "suspected PRC-nexus"（中国との関係が疑われる）の ARMORY CASTLE（旧 UNC5221）です（[GTIG](https://cloud.google.com/blog/topics/threat-intelligence/armory-castle-exploits-vsphere)）。GTIG が書くのは、9月初旬の悪用を確認したところまでです。発見の時期や、悪用がどれだけ続いたかは書かれていません。また GTIG は、vCenter のような制御基盤は、パッチによる事後の対応だけでは足りないと述べ、事前の設定強化を勧めています。

CISA の KEV には11月20日（米国基準）に追加され、期限は11月23日です。これは米連邦機関向けの期限です。

動画の訂正です。

- 動画では、最初の足がかりの BeyondTrust の脆弱性を「9月に使われた」と伝えました。正しくは、GTIG の BeyondTrust の記事は「2026年8月下旬からゼロデイとして悪用」と書いています（[GTIG](https://cloud.google.com/blog/topics/threat-intelligence/armory-castle-exploits-beyondtrust)）。
- 動画では、攻撃者がドメイン管理者の権限を持つ認証情報を偽造した、と伝えました。正しくは、GTIG が書くのは vCenter の管理者向けの SAML トークンの偽造と、ルートフォルダでの Global Administrator 権限の付与です。
- 動画では、侵害のおそれがあれば SAML の署名鍵の入れ替えも必要だと伝えました。正しくは、Broadcom の advisory にも GTIG の分析にも、署名鍵の入れ替えを対処とする記述は確認できませんでした。GTIG が書くのは、パッチだけでは足りない、というところまでです。

## 2. Debian 13.8

11月21日（土）、Debian 13（trixie）の8回目の更新となる 13.8 が告知されました（[告知](https://www.debian.org/News/2026/20261121)）。告知は、ポイントリリースは新しい版ではなく、一部のパッケージの更新だと説明しています。

「150件のセキュリティ更新、122件のバグ修正」という数は、告知の本文にある数ではありません。告知の表の行数です。セキュリティ更新の表は150行（異なる DSA の番号は139）、バグ修正の表は122行です。

GRUB には CVE-2026-97876 の修正が入りました。告知は "fix secure boot bypass" と書いています。Debian の security tracker によると、ローカルの攻撃者が GRUB の設定を操作できる場合に、Secure Boot の lockdown を回避して署名のない GRUB モジュールを読み込める問題です。影響は GRUB 2.12 以降で、bookworm は対象外とされています（[security tracker](https://security-tracker.debian.org/tracker/CVE-2026-97876)）。告知は、あわせて SBAT の版（revision）を上げたと書いています。SBAT は、世代番号で古いブートローダーを拒否する仕組みです（[SBAT.md](https://github.com/rhboot/shim/blob/main/SBAT.md)）。告知は、13.8 の適用で古い GRUB が起動しなくなるとは書いていません。

カーネルは、インストーラーが使う ABI が 6.12.117+deb13 に上がりました。Intel のマイクロコードは、12件の CVE に対応する新版です。NVD の説明の冒頭で内訳を見ると、権限昇格が8件、サービス拒否が1件、情報漏えいが3件で、投機的実行に触れるのは2件（CVE-2025-35979 と CVE-2026-20917）です（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2025-35979)）。確認したのは各説明の冒頭だけです。

更新後に再起動するまでは古いカーネルで動き続ける、という点は一般論です。告知は更新のコマンドも再起動も書いていません。

動画の訂正です。

- 動画では、Intel マイクロコードの12件を「投機的実行まわりが中心」と伝えました。正しくは、NVD の説明で見ると権限昇格が8件で、投機的実行に触れるのは2件です。

## 3. LLVM の再ライセンスの完了

LLVM は11月19日 13:08 UTC（日本時間 22:08）の Discourse の告知で、再ライセンスの作業を完了としてまとめました（[告知](https://discourse.llvm.org/t/wrapping-up-llvms-relicensing-effort/92906)）。過去の貢献者への依頼は2018年に始まり、2019年1月19日（土）以降の新しい貢献は、Apache-2.0 WITH LLVM-exception で受け付けています。1300人超の個人と約100の企業・団体が、過去の貢献を新しいライセンスで提供する同意書に署名しました。

告知によると、これまでに貢献された全コード行の99.5%超が、新ライセンスでカバーされているか、著作権が及ぶほどの量ではないか、すでにリポジトリに無いかのいずれかです。分母は「コードベース」ではなく、貢献された全コード行です。個々のコミットは、"covered by an agreement, not relevant to relicensing, or uncertain" の3つに分類されました。数えるときには、次の4つの仮定を置いています。

- 10行以下の貢献は、著作権が及ぶほどの量ではない。
- 削除されたバックエンドなど、すでにコードベースに無いコードは数えない。
- 会社のメールアドレスから送られたパッチは、その会社のものとする。
- 同意した会社に在籍していた期間の貢献は、その会社がカバーする。

告知は、100%には届かないので、最後のわずかな部分を追い続けず、ここで区切ると書いています。"We think that's a good moment to call the effort complete." という書き方です。

旧ライセンスは、全体にかかる UIUC/NCSA と、一部のランタイムライブラリにかかる MIT でした。2021年の LLVM のブログによると、旧ライセンスの本文に特許の条項はありませんが、開発者ポリシーに特許についての曖昧な文言があり、参加できない企業があったとされています（[2021年のブログ](https://blog.llvm.org/posts/2021-11-18-relicensing-update/)）。LLVM exception は、コンパイル生成物に埋め込まれた部分についてライセンスの第4条の (a)(b)(d) を免除するものと、GPLv2 のソフトウェアと組み合わせた場合に条項を放棄できる特例の2つです（[LICENSE.TXT](https://github.com/llvm/llvm-project/blob/main/LICENSE.TXT)）。

今後は、LLVM 24 のリリースブランチ作成（2027年1月初旬の見込み）のあとに、トップ・オブ・トランクで LICENSE や各種ドキュメントを更新し、LLVM 25 で出荷される予定です。取り込んである外部のコードは、それぞれのライセンスのままです。

動画の訂正です。

- 動画では、完了の基準を先に示してから完了を宣言した、と伝えました。正しくは、告知が示すのは被覆を数えるときの4つの「仮定」で、そのうえで「完了と呼ぶのによい時期」と述べています。基準を事前に示したとは書かれていません。
- 動画では、99.5%超を「コードベースの」割合と伝えました。正しくは、分母は「これまでに貢献された全コード行」です。

## 4. KDE の端末 Kwi 0.1

KDE の Eike Hein 氏は、新しい端末エミュレーター Kwi の最初のリリース 0.1.0 を11月20日（金）に公開しました。Kwi は KDE Review を通過し、公式の KDE プロジェクトになったとされています。Flathub から入手できます（[リリース記事](https://blogs.kde.org/2026/11/20/this-week-in-kwi-2026-w47/)）。

0.1 の変更には、Ctrl+Tab で最近使った順にタブを移動できること、Shift+上下キーで1行ずつスクロールできることが挙げられています。リンクを開くには、既定では Ctrl キーを押す必要があります。設定で変えることもでき、この項目には Matrix で寄せられたフィードバックへの言及が括弧書きで添えられています。翻訳作業は始まったばかりで、画面分割は作業の初期段階（early work）と書かれています。

11月1日（日）の導入記事によると、Kwi は Qt Scene Graph による Vulkan または OpenGL の描画を使い、端末の解析には Ghostty の libghostty-vt を使います。Konsole の QWidget は主に CPU で描画する、という説明もあります。KPart や QML モジュールとして他のアプリに組み込めること、Konsole の配色ファイルを読めることも書かれています（[導入記事](https://blogs.kde.org/2026/11/01/introducing-kwi/)）。

速さについて、公式の表明は "3x–35x faster overall performance, depending on the benchmark" です。DOOM-fire-zig というプログラムでの 870 fps 対 Konsole の 23 fps は、テスト用のシステムでの一例として挙げられています。最大の事例とは書かれていません。

導入記事は Kwi を「実験であり提案」と書き、KDE の将来の方向の発表と取り違えないでほしい、としています。リポジトリの言語比率は、C++ が約81%、QML が約16%です。

動画の訂正はありません。

## 5. Apache Roller の CVE-2026-129448

CVE-2026-129448 は、Apache Roller 4.0.0 から 6.1.4 までに影響する、認証なしのリモートコード実行につながる安全でないデシリアライズです。XML-RPC のエンドポイントが、ベンダー拡張型を認証の前にデシリアライズする、と NVD にあります（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-129448)）。CVSS は v3.1 で 9.8 で、採点者は CNA の Apache です。NVD 独自の採点は、確認した11月22日 23:48 UTC ごろ（日本時間 11月23日 08:48）の時点ではありません。説明には "This issue is being actively exploited." とあります。

CISA の KEV には11月20日（米国基準。公開は日本時間の11月21日 02:48 ごろ）に追加され、期限は11月23日です。期限は連邦文民行政機関向けで、要求される対応には、フォレンジックの初期調査（forensic triage）も含まれます（[CISA の BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)）。

NVD の記述によると、管理画面で XML-RPC を無効にするだけでは足りません。古い版は、その設定を確かめる前にリクエストをデシリアライズするためです。NVD は、6.1.6 以降へ更新するよう勧めています。6.1.6 は、拡張型を無効にし、XML-RPC が無効なときはリクエストを拒否します。すぐに更新できない場合の回避策は、一次に2つあります。web.xml で `enabledForExtensions` を `false` にする方法と、XML-RPC のサーブレットの割り当てを削除する方法で、どちらも Roller の再起動が要ります。

Apache のセキュリティページによると、6.1.6（2026年9月24日公開）が直した脆弱性は18件で、CVE-2026-82384 を含みます。CVE-2026-129448 は、6.1.5 だけが影響と書かれた CVE-2026-82384 と同じ脆弱性として、広い範囲で登録し直されたものです。6.1.7 は11月11日（水）に公開され、ダウンロードページは "best available" と表示しています（[セキュリティページ](https://roller.apache.org/security.html)）。

動画の訂正です。

- 動画では、6.1.6 が19件の CVE をまとめて直したと伝えました。正しくは18件です。
- 動画では、4系・5系には公式の修正版がなく、回避策だけが案内されていると伝えました。正しくは、Apache は旧版にはパッチを当てず、現行版への更新を修正としています。回避策は、すぐに更新できない人向けの暫定策です。

## まとめ

「止めた」「直した」「終わった」の範囲は、一次の文書で確かめるまで分かりません。実務で確かめておくものは次のとおりです。

- vCenter: 版を確認し、9.1.1.0200・9.0.2.0200・8.0 U3m のいずれかへ上げる。7.0 系は修正版がないので、延長サポート契約の有無を確認する。advisory はワークアラウンドなし、GTIG はパッチ以外に事前の設定強化も勧めている。
- Debian: 13.8 の更新を当てる。カーネルなどの更新後は、再起動するまで古いカーネルが動く（一般論）。GRUB の修正は、GRUB 2.12 以降が対象。
- Roller: 版を確認し、6.1.6 以降（11月23日の確認時点の最新は 6.1.7）へ上げる。上げられないときは、一次の2つの回避策のどちらかを使い、再起動する。管理画面の設定だけでは止まらない。

## 参考リンク

- [Broadcom: VMSA-2026-0009](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/39495)
- [GTIG: ARMORY CASTLE と vSphere](https://cloud.google.com/blog/topics/threat-intelligence/armory-castle-exploits-vsphere)
- [Debian 13.8 の告知](https://www.debian.org/News/2026/20261121)
- [LLVM: 再ライセンスの完了の告知](https://discourse.llvm.org/t/wrapping-up-llvms-relicensing-effort/92906)
- [KDE: Kwi の最初のリリース](https://blogs.kde.org/2026/11/20/this-week-in-kwi-2026-w47/)
- [NVD: CVE-2026-129448](https://nvd.nist.gov/vuln/detail/CVE-2026-129448)
- [Apache Roller のセキュリティページ](https://roller.apache.org/security.html)

（2026/11/23 Linux・OSSトレンド）
