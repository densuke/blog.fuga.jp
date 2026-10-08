---
title: "AIが見つけ、人が届ける！ IBM・Red Hat Lightwell の Java 400件超の修正、Fedora 45 の KMSCON、KDE This Week in Plasma、AMD Zen 6 の IBS Memory Profiler、X.Org Server・XWayland の12件（2026/10/8 Linux・OSSトレンド）"
date: 2026-10-08T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Java", "IBM", "Red Hat", "Fedora", "KMSCON", "KDE", "AMD", "Linux カーネル", "X.Org", "XWayland"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

AI や CPU が「見つける」速さは上がりました。では、見つかったものを直して届け、書き継いでいく人の手は追いついているのでしょうか。今日の5本は、この問いで並べました。

共通点の指摘は書き手の考察です。動画で一次情報と食い違った発言や裏付けの取れなかった発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "4Nkwyy3ub4U" >}}

## 1. IBM と Red Hat の Lightwell — Java ライブラリの未知の脆弱性 400件超を発見・修正

10月6日、IBM と Red Hat は、[Lightwell が広く使われている Java ライブラリで、これまで知られていなかった脆弱性を400件超、特定して修正した](https://newsroom.ibm.com/2026-10-06-ibm-and-red-hat-remediate-more-than-400-previously-unknown-open-source-vulnerabilities)と発表しました。CVE が400件という意味ではなく（発表は vulnerabilities とも bugs とも書いています）、ライブラリ名や内訳、深刻度も示されていません。

Lightwell は、[5月28日に発表された Project Lightwell](https://newsroom.ibm.com/2026-05-28-ibm-and-red-hat-commit-5-billion-to-redefine-the-future-of-open-source-in-the-ai-era) のことです。50億ドルの投資と2万人を超えるエンジニアの配置が表明されましたが、Lightwell 専用の予算や専任の人数とは書かれていません。

目を引くのは届け方です。修正は、いまも使われている古い版に当てられる形（バックポート）まで含めて出されました。

企業向けには2つのサービスがあります。

- Lightwell Network: 検証済みのパッチを既存のワークフローに取り込めます。[7月の発表](https://www.redhat.com/en/about/press-releases/ibm-and-red-hat-expand-lightwell-new-offerings-build-trust-infrastructure-ai-era-open-source)では、商用開始の時点で、修正済みの署名付き依存関係を Java や Python などで6,500件超提供するとしていました（10月時点の件数ではありません）。
- Lightwell Clearinghouse: 企業が特定の OSS の依存関係を出し、優先的なレビューと修正を依頼できる窓口です。10月6日に一般提供が始まりました（[Red Hat のページ](https://www.redhat.com/en/lightwell)では対象となる組織向け）。

発表からは、個々の CVE 番号との対応は確認できませんでした。番号が付けば Snyk や Dependabot の警告が増えるかもしれません（書き手の予想です）。今のうちに `mvn dependency:tree` や `gradle dependencies` で、間接的に入っているライブラリまで洗い出しておくと慌てずに済みます。Log4Shell（2021年末に見つかった Log4j の脆弱性）のときも、自分が何を使っているか分からない現場が多くありました。

動画の訂正です。

- 動画では「Red Hatのアドバイザリを通じて、CVE番号付きで公開されたものも一部あります」と紹介しましたが、裏付けは取れませんでした。動画の下調べで根拠にしたアドバイザリ（RHSA-2026:9689）は、2026年4月に出た java-21-openjdk の定例更新で、今回の400件とは無関係でした。
- 動画では「探し方は3段階あって」と紹介し、「OSS-Fuzzなどに、AIエージェントを組み込む形」と説明しましたが、IBM と Red Hat の発表資料にこの手法の記述は無く、確認できませんでした。発表が示すのは、AI を使った工程と人の技術の組み合わせまでです。

## 2. Fedora 45 — 仮想端末の既定を FBcon から KMSCON へ

Fedora 45 は10月6日にファイナルフリーズに入りました。[公式のスケジュール](https://fedorapeople.org/groups/schedule/f-45/f-45-key-tasks.html)では、リリース目標日は10月20日、予備日は10月27日と11月3日です。

[Change ページ](https://fedoraproject.org/wiki/Changes/UseKmsconVTConsole)によれば、今回の変更は、カーネル内のコンソール fbcon をユーザーランドの kmscon に置き換えるものです。仮想端末（Ctrl + Alt + ファンクションキーで切り替える文字だけの画面）に切り替えると、systemd のサービス kmsconvt が kmscon を起動します。同ページは、fbcon のクラッシュはカーネルパニックを起こし、kmscon なら systemd が再起動する、と比べています。Pango のフォント描画で全角文字との互換性もよくなり、テスト項目には Ctrl と + / - での拡大縮小や、Page Up / Page Down でさかのぼる操作が並びます。

さかのぼる操作には背景があります。fbcon のソフトウェアのスクロールバックは、[2020年9月7日のコミット](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/patch/?id=50145474f6ef4a9c19205b173da6264a644c7489)で、Linus Torvalds 氏本人の手で削除されました。CVE-2020-28097 は、同じ時期に見つかった [VGA コンソール（vgacon）のスクロールバックの境界外読み出し](https://nvd.nist.gov/vuln/detail/CVE-2020-28097)です。fbcon 側には、Red Hat の Bugzilla で [fbcon_redraw_softback の境界外書き込みとされる CVE-2020-14390](https://bugzilla.redhat.com/show_bug.cgi?id=1876788) がありました。ただ、削除のコミットメッセージに CVE 番号はなく、直接のきっかけとは断定できません。以降、スクロールバックは fbcon に戻っていません。

kmscon というプロジェクト自体は新しくありません。[GitHub 上の最初のコミット](https://github.com/kmscon/kmscon)は2011年11月19日で、2026年から数えると約15年になります。Fedora 44 を目標にしていた変更は、[Fedora の議論](https://discussion.fedoraproject.org/t/f45-change-proposal-usekmsconvtconsole-systemwide/172602)で2月に F45 への延期が告げられました。自動テスト（openQA）で問題が出続け、時期が遅くなったためだと説明されています。

不安な人向けの備えもあります。Change ページによると、kmscon が起動できなければ getty / fbcon へ戻ります。[FESCo の議論](https://pagure.io/fesco/issue/3513)では、Change のオーナーが、3回続けて起動に失敗すると systemd が戻す、と説明しています。fbcon 自体はカーネルに残り、変わるのは既定です。15年前からある仕組みでも、既定として届けるまでには確かめる時間が要りました。物理コンソールで運用するサーバーは、アップグレード前に一度試しておくと安心です。

動画の訂正です。

- 動画では「削除のきっかけになった脆弱性は、CVE-2020-28097として追跡されています」と紹介しましたが、CVE-2020-28097 は fbcon ではなく vgacon の脆弱性でした。fbcon 側の CVE は CVE-2020-14390 で、これが削除のきっかけだったとは断定できません。
- 動画では「始まったのは2012年です」「14年越しで」と紹介しましたが、kmscon の最初のコミットは2011年11月19日で、約15年でした。
- 動画では「ベータの段階で不具合が見つかって、1回見送られました」と紹介しましたが、延期の通知は2026年2月（Fedora 44 のベータ前）で、理由は openQA のテストで問題が出続けたことでした。
- 動画では「systemctlで設定を元に戻すコマンドが用意されていて」と紹介しましたが、Change ページにそのコマンドの記述は確認できませんでした。

## 3. KDE「This Week in Plasma」 — 8年続いた週報の、次の書き手を探す

KDE Plasma の変化を追うなら、Nate Graham 氏の週報 This Week in Plasma（TWiP）が定番です。[2025年12月28日の8周年の投稿](https://blogs.kde.org/2025/12/28/8-years-of-this-week-in-plasma/)によると、TWiP は2017年に KDE の開発報告として始まり、個人ブログから KDE の基盤に移りました。

同じ投稿で Graham 氏は、後継者が見つかるまで頻度を下げ、"Expect one every two weeks, or even every three or four weeks."（2週に1回、3〜4週に1回になるかもしれない）と予告しました。ただ、[ブログの一覧ページ](https://blogs.kde.org/categories/this-week-in-plasma/)を数えると、2026年は1月3日から10月3日まで39本あり、4月11日の1週を除いてほぼ毎週公開されています。

忙しさの理由も書かれています。[Techpaladin Software の創業告知](https://pointieststick.com/2025/03/10/personal-and-professional-updates-announcing-techpaladin-software/)によると、2025年3月、Graham 氏は David Edmundson 氏とともに、KDE ソフトウェアの仕事を請けるこの会社を共同所有する立場になり、Valve との契約を最初の顧客として引き継ぎました。8周年の投稿では共同オーナー兼 CEO を名乗り、12人を超える KDE 開発者を雇用しているとしています。ここ1年の質の低下にも触れ、"it's not a coincidence, and I apologize"（偶然ではなく、申し訳ない）と率直に書いています。

同じ投稿は、2026年に TWiP を引き継ぐ人かチームを積極的に探すと明言しています。必要な技術は "basic markdown and git"（Markdown と git の基本）までで、"teach, coach, or mentor"（教え、コーチし、メンターもする）とも約束しています。

引き継ぎは動き始めているようです。[9月26日の Akademy 特別号](https://blogs.kde.org/2026/09/26/this-week-in-plasma-akademy-special/)は Nate Graham 氏と John Veness 氏の連名で、約200人が Akademy に参加した週を伝え、加わりたい人は Matrix のルーム `#this-week-kde-apps:kde.org` で自己紹介を、と呼びかけています。

変更の記録は git に残ります。それを読める言葉にして届けるのは人です。

動画の訂正です。

- 動画では「更新のペースは、週に1回から、2週から4週に1回へと下がっています」と紹介しましたが、頻度を下げるのは2025年12月の投稿で示された予定で、2026年10月時点の公開実績はほぼ毎週でした。

## 4. AMD Zen 6 の IBS Memory Profiler — 熱いページを CPU が教える

AMD のエンジニア Bharata Bhasker Rao 氏は、Zen 6 に載る IBS（Instruction Based Sampling）Memory Profiler を、Linux カーネルのメモリ階層管理に使うパッチを投稿しています。[7月28日の v8](https://lkml.iu.edu/2607.3/07077.html)（題は "mm: Hot page tracking and promotion infrastructure"）では、IBS のドライバはシリーズの 7/8 と 8/8 で、IBS は [v7（5月4日）](https://patchew.org/linux/20260504060924.344313-1-bharata@amd.com/)から加わりました。10月5日には、Linux Plumbers Conference 2026 で[同氏による同じテーマの講演](https://lpc.events/event/20/contributions/2425/)が予定されていました。

IBS Memory Profiler は、メモリアクセスのプロファイル専用の、2つ目の軽量な IBS で、perf が主に使う既存の IBS とは独立しています（v7 のカバーレター）。

使い道は、DRAM と CXL のメモリが混在する階層メモリです。下の層にある熱いページを速い層へ移すことを昇格（promotion）と呼びます。pghot は、ヒントフォルト、ページテーブルの走査、ハードウェアのヒント（AMD IBS）をまとめる設計で、v8 に含まれるのはヒントフォルトと IBS です。講演概要は、ARM SPE や Intel PEBS なども想定した、情報源に依存しない設計だとしています。

v8 では、IBS Memory Profiler の割り込みを NMI から通常の割り込みに変えました。カバーレターによれば、メモリアクセスのプロファイルで取るのはユーザー空間のサンプルだけなので NMI は不要、という理由です。

効果は、作者が Graph500 などで改善を報告しています。ただしカバーレターの要約は、ヒントフォルト版はメインラインの NUMAB=2 と同等、HW ヒント（IBS）版も "matches it mostly"（おおむね同等）としており、IBS で劇的に速くなるわけではなさそうです。測定は1構成1回ずつのため、数値は挙げません。

10月8日時点で確認できた範囲では、torvalds/linux の master にドライバのファイルはなく、メインラインには未マージでレビューが続いています。熱いページを見つけるのは CPU でも、どこへいつ動かすかの仕組みは人が議論して作ります。

動画の訂正です。

- 動画では「ドライバの本体は308行」と紹介しましたが、308行は一つ前の第7版の数字でした。第8版では 7/8 のパッチで363行、ランタイム制御を足した v8 全体で704行です。

## 5. X.Org Server 21.1.25・XWayland 24.1.14 — 12件の脆弱性を修正

X.Org は10月7日、[X.Org Server と XWayland の12件のセキュリティ修正](https://lists.x.org/archives/xorg-announce/2026-October/003747.html)を公表しました。修正版は xorg-server 21.1.25 と xwayland 24.1.14 です。まとまった修正は xorg-announce で数えて今年4回目で、ほかは[4月14日](https://lists.x.org/archives/xorg-announce/2026-April/003677.html)、[6月2日](https://lists.x.org/archives/xorg-announce/2026-June/003702.html)、[7月8日](https://lists.x.org/archives/xorg-announce/2026-July/003716.html)です。

[Help Net Security の整理](https://www.helpnetsecurity.com/2026/10/07/x-org-server-fixed-vulnerabilities/)によると、12件のうち9件は任意のコード実行のおそれがあり、残る3件はクラッシュか情報漏えいです。種類は、バッファオーバーフローや境界外書き込みが7件、解放後の参照が3件、二重解放と境界外読み出しが1件ずつ。11件は X サーバーと XWayland の両方に影響し、Wayland のセッションでも XWayland が動いていれば無関係ではありません。

例えば CVE-2026-88812 は、XKB の SetGeometry の処理で、エラー時に解放したポインタを NULL に戻さず、後始末でもう一度解放する二重解放です。ヒープ破壊から、任意コード実行やクラッシュにつながるおそれがあります。

過去の修正の取りこぼしも2件ありました。CVE-2026-93520 は、XKB の以前の修正が不完全だったものです。CVE-2026-93521 は RandR の処理で、同じ種類の修正が別の経路に適用されていなかったものです。

アドバイザリでは、12件すべてのクレジットに TrendAI Zero Day Initiative の名がありますが、発見の手段には触れていません。AI を使う発見手法の例として、[Thinkst Citation の講演概要](https://citation.thinkst.com/talk/101304)は FENRIR を、静的解析での絞り込み、LLM による2段階の検証、確信度に応じた人への振り分け、と説明しています。今回の12件との結びつきは確認できませんでした。

Glamor の CVE-2026-93522 は、XWayland だけに影響します。アドバイザリは、glamor（GPU アクセラレーション）を使うシステムで、認証済みの X クライアントが深度の異なる描画対象の間で CopyArea を行うと起こせる、と書いています。

12件のうち10件は、認証済みの X クライアント、つまりサーバーがすでに接続を受け付けているプログラムが攻撃の前提です。CVE-2026-93524 と CVE-2026-93536 の2件には、その条件の記述がありません。

やることは単純です。xorg-server は21.1.25 以上、XWayland は24.1.14 以上に更新してください。XWayland のパッケージ名はディストリビューションで異なるので、手元の名前で版を確かめてください。穴は、ふさいで手元で更新して初めて意味があります。

動画の訂正です。

- 動画では「以前直したはずのXKBの不具合で、修正が不完全だったものが2件あった」と紹介しましたが、アドバイザリでは、XKB の修正不完全は1件（CVE-2026-93520）で、もう1件（CVE-2026-93521）は RandR の別の処理に同じ種類の修正が適用されていなかったものでした。
- 動画では「ソフトウェアで描画している環境は対象外です」と紹介しましたが、アドバイザリにこの記述は見当たらず、確認できませんでした。アドバイザリが条件に挙げているのは、glamor（GPU アクセラレーション）を使うシステムです。
- 動画では「FENRIRというAI支援のツールを持つチームです」と紹介しましたが、今回の12件の発見に FENRIR が使われたことは、アドバイザリなどの一次情報から確認できませんでした。

## まとめ

古い版まで修正を届ける Lightwell、確かめてから既定にした Fedora、書き手を探す KDE の週報、熱いページを教える CPU、更新して初めて意味を持つ X.Org の12件。「見つける」速さが上がるほど「直して届ける」側の手が問われる、という見立てで並べました。

今日できることは、Java の依存ツリーを一度出すことと、xorg-server・XWayland の版を確かめることです。皆さんの現場では、AI が見つけた脆弱性の修正を、どれくらいの速さで当てられていますか。

## 参考リンク

- [IBM: 400件超の未知の脆弱性を修正（2026年10月6日）](https://newsroom.ibm.com/2026-10-06-ibm-and-red-hat-remediate-more-than-400-previously-unknown-open-source-vulnerabilities)
- [KDE: 8 years of This Week in Plasma](https://blogs.kde.org/2025/12/28/8-years-of-this-week-in-plasma/)
- [LKML ミラー: pghot v8 のカバーレター](https://lkml.iu.edu/2607.3/07077.html)
- [xorg-announce: 2026年10月7日のセキュリティアドバイザリ](https://lists.x.org/archives/xorg-announce/2026-October/003747.html)
