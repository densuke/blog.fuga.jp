---
title: "その既定値、いつから触っていませんか — メール1通で root を取られる Cisco と、3年潜んだ1行のカーネルバグ（2026/9/16 Linux・OSSトレンド）"
date: 2026-09-16T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Cisco", "KEV", "Python", "Rust", "GNOME", "Wayland", "Fedora", "Linuxカーネル", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

設定ファイルを開いて、何も書かれていない行について考えることはあまりありません。書かれていないということは、既定値で動いているということです。そして既定値は、何も考えなかった人にいちばん強く効きます。

今日の5本は、「たった1行の判断」と「既定値の置き方」が、データと安全のどちらに転ぶかという話でした。入力検証を1か所甘くしたせいで、セキュリティ製品が root まで明け渡してしまった話。ビルドに必須の依存を増やすかどうかを考え直した話。デスクトップの見た目の「共通のやり方」がようやくそろった話。ディストリビューションが安全側に既定値を倒した話。そして、3年近く前に書かれた1行のマスクが、今年の本番環境でデータを消していた話です。

{{< youtube "o1f9ZpipoNo" >}}

## 1. Cisco Secure Email Gateway CVE-2026-76461 — メールを受け取るだけで root、回避策なし

最初は、今日いちばん急ぐ話です。

迷惑メールやマルウェアを止めるためにメールサーバーの手前へ置くゲートウェイ製品、Cisco Secure Email Gateway に深刻な脆弱性が公開されました。[Cisco の公式アドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-esa-inj-2bLVGmhX) は、AsyncOS のメール解析部分の脆弱性によって「認証されていないリモートの攻撃者が、root 権限で任意のコマンドを実行できる可能性がある（could allow an unauthenticated, remote attacker to execute arbitrary commands with root privileges）」と説明しています。原因は "insufficient validation in the email parsing logic"、つまりメール解析ロジックでの検証不足です。

スコアは CVSS v3.1 で 9.8（Critical）、基本ベクタは `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` です。分類は [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-76461) でも CWE-89、SQL インジェクションです。ネットワーク越しに、特別な手順も権限も利用者の操作もなしに到達でき、影響は機密性・完全性・可用性のすべてで高い。入力検証の漏れという古典的な型が、商用のセキュリティ製品で root まで通ってしまったことになります。

対象は物理・仮想の両アプライアンスで、Cisco Secure Email and Web Manager と Cisco Secure Web Appliance は影響を受けないと明記されています。修正版は次の3系統です。

- 15.5 以前 → 15.5.5-0141
- 16.0 → 16.0.4-3021
- 16.5 → 16.5.0-780

そしてアドバイザリには "There are no workarounds that address this vulnerability." とあります。 **回避策はありません** 。メールを受け取ること自体が攻撃経路なので、止めればゲートウェイとしての役目も止まる。パッチを当てるしか道がないわけです。

急ぐ理由はもうひとつあります。Cisco はこの脆弱性の悪用を実際に認識しており、アドバイザリの公開は 2026年9月14日でした。同じ日に CISA が [既知悪用脆弱性（KEV）カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) へ登録し、カタログ上の対応期限は 9月17日です。この期限は米国の連邦文民行政府機関に課される義務で、一般企業のパッチ期限ではありません。とはいえ、登録から3日という短さは状況の切迫を物語っています。

発見の経緯も少し変わっています。アドバイザリには "This vulnerability was found during the resolution of a Cisco TAC support case." と書かれていて、外部の研究者ではなく、Cisco TAC のサポートケースを解決する過程で見つかったものでした。[BleepingComputer の報道](https://www.bleepingcomputer.com/news/security/new-cisco-secure-email-zero-day-exploited-to-execute-commands-as-root/) によれば、Shadowserver はインターネット上で 400 台を超える Cisco Secure Email Gateway を追跡しており、CISA は 2021年11月以降、Cisco の脆弱性 98 件を悪用確認済みとして扱ってきたとのことです。

アドバイザリには侵害の痕跡を探す手順も載っています。IronPort のテキスト形式メールログ（`mail_logs`）に対して `COPY.*TO PROGRAM` という文字列を `grep` するものです。PostgreSQL の `COPY ... TO PROGRAM` は、クエリからOSコマンドを起動できる構文です。パッチを当てたら終わりではなく、ログを確認し、疑わしければ装置に預けていた認証情報や鍵を入れ替える。そこまでをひと続きの作業として考えておきたいところです。

## 2. CPython と Rust — 「必須にする」はいったん取り下げ、任意の内部 API から

2本目は Python 本体、CPython の話です。

発端は2025年11月、Emma Smith 氏と Kirill Podoprigora 氏が [discuss.python.org に投稿した pre-PEP](https://discuss.python.org/t/pre-pep-rust-for-cpython/104906) でした。CPython に Rust を取り込み、最終的にはビルドに必須の依存にしていく、という構想です。当初案には「3.15 では Rust がなければ警告、3.16 では既定でビルド失敗（`--with-rust=no` で続行可）、3.17 では Rust が必要になるかもしれない（may require）」という段階的な計画が書かれていました。

ただし、この計画は早い段階で見直されています。[The Register の 9月14日の記事](https://www.theregister.com/devops/2026/09/14/cpython-eases-rust-requirements-as-assimilation-continues/5296010) は、「5月に Smith 氏が提案を修正し、Rust を CPython の必須依存にするという項目を外して、将来の提案に先送りした（drop the mandate to make Rust a required dependency for CPython, kicking that down the road for a future proposal）」と伝えています。いま進んでいるのは、CPython 内部の開発で使える **任意（optional）の Rust API** を作る作業です。

なお、動画では当初案の段階計画にも触れ、「2028年の必須化目標が無期限延期」という整理でお話ししました。記事にするにあたって一次情報を確認したところ、The Register の記事に「2028年」や「無期限延期」という表現はなく、当初案の段階計画がそのまま維持されているとも読み取れませんでした。ここでは原典の書き方に合わせて「必須化の項目を外し、将来の提案に先送り」と記述します。

では具体的に何が決まっているのか。Smith 氏による [2026年4月の進捗報告](https://blog.python.org/2026/04/rust-for-cpython-2026-04/) では、Rust コードを含む最初のバージョンを 3.15 ではなく 3.16 に置くとしています。The Register によれば、この API は 3.16（2027年10月予定）を目標にしていて、Rust で書かれた zlib 圧縮ライブラリがテスト用のクレートとして一緒に入る計画です。ビルドについては「開発フォークの CI で、試したすべてのプラットフォームで Rust 入りの CPython をビルドできている（our fork's CI on all tested platforms）」段階だと報告されています。

なぜ必須化は見送られたのでしょうか。pre-PEP の議論では、Rust が動かない環境の存在が繰り返し挙がっていました。CPython は HP PA-RISC や RISC OS のような古い、あるいは珍しい環境でも動いてきましたが、Rust はそこに対応していません。また pre-PEP 自身が、Rust のコンパイラのブートストラップに Python が要るため、CPython が Rust に依存するとブートストラップの問題が生じる、と認めています。

残る技術課題として The Register は、CPython が支える「ロングテール」の環境向けに Rust 側で GCC 対応が必要なこと、C と Rust の境界でメモリ状態を検査するサニタイザ、そして最も難しいものとして、Python オブジェクトの解放時に実行時の文脈を渡せるよう Rust の `Drop` トレイトを拡張する必要があることを挙げています。

Guido van Rossum 氏は pre-PEP のスレッドで「最初は重要度の低いコンポーネントから Rust を入れ、徐々により重要な部分を任せていくのは良い計画に思える」と、この段階的なやり方を支持していました。

わたしはこの件を、期限より「壊さない」を優先した判断だと受け取りました。ビルド必須の依存を1つ足すという1行の変更が、どこかの環境を丸ごと落としかねない。だから必須にするかどうかは、材料がそろってから別に議論する。地味ですが、健全な順序だと思います。

## 3. GNOME 51 "A Coruña" — 背景ぼかしが共通のやり方に

3本目は少し肩の力を抜いて、デスクトップの話です。

GNOME 51 "A Coruña" の安定版が、[予定どおり 9月16日にリリース](https://9to5linux.com/gnome-51-a-coruna-desktop-environment-scheduled-for-september-16th-2026) されるスケジュールで進んでいます。GitLab 上ではすでに gnome-shell の 51.0 タグが 9月14日付で打たれています。コードネームは、GUADEC 2026 の開催地であるスペインの都市ア・コルーニャにちなんだものです。

目玉は、Wayland での背景ぼかしです。半透明のターミナルの後ろがふんわりにじむ、あの効果ですね。GNOME のコンポジターである Mutter が、Wayland の拡張プロトコル `ext-background-effect-v1` に対応しました。[Mutter 51.beta のリリースノート](https://gitlab.gnome.org/GNOME/mutter/-/releases/51.beta) に "Add ext-background-effect-v1 blur support" と記載されています。該当するマージリクエスト（!5071）の説明には "Clients only request the effect for their own surfaces, and Mutter remains responsible for rendering and policy." とあり、アプリは自分のウィンドウに対して効果を要求するだけで、実際の描画と方針は Mutter が担います。アプリが要求しない限り効かないので、望まない人の画面が勝手にぼけることはありません。

ここで押さえておきたいのは、このプロトコルが GNOME 発のものではないという点です。もともとは KDE の開発者が提案し、wayland-protocols の staging に入ったもので、GNOME はそれを実装した側です。これまでデスクトップ環境ごとにばらばらだったやり方が、共通のプロトコルにそろってきた。アプリ開発者からすると、環境ごとに書き分けなくて済む方向に一歩進んだことになります。

土台の側では、ドキュメントモジュールの gnome-user-docs が [Autotools から Meson へ移行しました](https://discourse.gnome.org/t/the-gnome-user-documentation-module-has-switched-to-meson/35980)。告知には "As part of the initiative to sunset the use of Autotools" とあり、GNOME 全体で Autotools の利用を終わらせていく取り組みの一環という位置づけです。動画では「完全移行」と表現しましたが、告知から読み取れるのはこのモジュールの移行までで、GNOME 全体が移行を終えたとまでは言えません。

もうひとつ、古い GPU を使っている人は注意が必要です。[Phoronix の報道](https://www.phoronix.com/news/GNOME-51-Drops-EGLStreams) によると、GNOME 51 に向けて Mutter から EGLStreams / EGLDevice の対応が取り除かれました。これは NVIDIA が最初に Wayland 対応の手段として用意した経路で、現在の NVIDIA ドライバーは他と同じ DMA-BUF・GBM・KMS の経路を使っています。古い世代のカードを挿したまま使っている機械は、更新前に一度確認しておくと安心です。

GNOME 51 は Ubuntu 26.10 と Fedora 45 Workstation の既定のデスクトップになる予定です。次の話題の Fedora 45 Beta でも、すでにその姿を試せます。派手な新機能より、「みんなが同じやり方でできるようになった」という既定の統一のほうが、あとから効いてくるタイプのリリースだと感じました。

## 4. Fedora 45 Beta — コンパイラ・TLS・Python が同時に世代交代し、既定値は安全側へ

4本目は、9月15日に出荷された Fedora 45 Beta です。

[Linux Compatible の報道](https://www.linuxcompatible.org/story/fedora-linux-45-beta-ships-september-15-with-major-toolchain-and-security-upgrades) によると、9月10日に FESCo・リリースエンジニアリング・QA の3者が約40分の会議で Go/No-Go を判定し、提案されたブロッカーはゼロ。RC 1.3 がそのまま出荷されました。x86_64 と aarch64 の基本的な起動・インストール・ストレージのワークフローもきれいに通っています。

中身は、土台がまとめて入れ替わる Beta です。

まずコンパイラ。GCC 16.2 は GCC 16.1 から 102 件のバグ修正を含む安定化リリースですが、GCC 16 系でいちばん影響が大きいのは、[C++ の既定の言語バージョンが -std=gnu++17 から -std=gnu++20 に変わった](https://gcc.gnu.org/gcc-16/changes.html) ことです。C++17 の前提に依存しているコードは、`-std=gnu++17` を明示しないとビルドが通らなくなる可能性があります。自分は何も変えていないのに、既定値のほうが動く典型例です。C++26 の Reflection（`-std=c++26 -freflection` で有効）や Contracts も実験的に入りました。

次に Python 3.15。正式リリース前の版が入っています。[What's New](https://docs.python.org/3.15/whatsnew/3.15.html) を見ると、PEP 810 の遅延インポート（名前が最初に使われるまでモジュールの読み込みを遅らせる）、PEP 814 の組み込み `frozendict`、そして PEP 686 による UTF-8 の既定エンコーディング化が並んでいます。3.15.0 の正式版は 2026年10月1日の予定です。

3つ目が OpenSSL 4.0 です。[Fedora の変更提案](https://fedoraproject.org/wiki/Changes/OpenSSL40) には soname の変更（依存パッケージの再ビルドが必要）と ENGINE サポートの削除が挙がっていて、互換用に `openssl3` パッケージも用意されます。ENGINE は外部の暗号ハードウェアなどを差し込む仕組みで、後継は Provider です。HSM 連携のような環境は移行計画が必要になります。なお、Encrypted Client Hello（ECH）やポスト量子暗号系のアルゴリズム追加は OpenSSL 4.0 上流の新機能で、Fedora 独自のものではありません。

そして今日のテーマにいちばん近いのが、2つのセキュリティ既定値の変更です。

ひとつは ptrace の制限です。[Restrict ptrace by default](https://fedoraproject.org/wiki/Changes/Restrict_ptrace_by_default) により、`kernel.yama.ptrace_scope` の既定値が 1 になり、非特権ユーザーは自分の子プロセス以外にアタッチできなくなります。ptrace はデバッガの土台であると同時に、侵入者が他のプロセスから秘密情報を抜き出す道具にもなります。一方で gdb・strace・lldb などのパッケージには `yama-ptrace-enable` が Recommends として付き、デバッグツールを入れた環境では制限が外れる設計です。

もうひとつは RPM の署名検証です。[Enforcing signature checking by default](https://fedoraproject.org/wiki/Changes/Enforcing_signature_checking_by_default) で、`%_pkgverify_level` の既定値が `digest`（チェックサムのみ）から `all`（署名を含む）へ変わり、署名のないパッケージは `--nosignature` を明示しない限り入らなくなります。公式リポジトリだけを使っているなら体験は変わりませんが、自前のパッケージを署名なしで配っている現場は手当てが必要です。

既定では塞いでおき、必要な人だけが開ける。Fedora がそちら側に倒したことで、何も設定しない人ほど安全になる。既定値の置き方の、良いほうの例だと思います。安定版のリリースは、Beta 時点では今秋後半の予定です。

## 5. Linux カーネル — 3年近く潜んでいた1行が、書いたはずのデータを消していた

最後は、今日いちばん「静かに怖い」話です。

書き込んだはずのデータが、エラーもログも出さずに消える。そんなバグを修正する [コミット「x86/mm: Fix user-space data loss with MADV_FREE and THP」](https://github.com/torvalds/linux/commit/f7491d7c81db0e7c304a7bd757a76d2fbeaff80e) が、9月14日に Linus Torvalds のツリーへ取り込まれました。著者は Vernon Yang 氏、`Cc: stable@vger.kernel.org` が付いているので、安定版の系列にも展開される見込みです。

差分は、x86 の `arch/x86/include/asm/pgtable.h` にある `pmd_modify()` の1行だけです。

```c
-	val &= (_HPAGE_CHG_MASK & ~_PAGE_DIRTY);
+	val &= _HPAGE_CHG_MASK;
```

ページテーブルのエントリには「このページは書き換えられた」を示すダーティビットがあり、CPU が書き込みのたびに立てます。ところが `pmd_modify()` は、エントリを更新するときにこのビットを余計なマスクで落としていました。コミットメッセージは、通常ページ用の `pte_modify()` も 1GB ページ用の `pud_modify()` もダーティビットを保っているのに対し、"pmd_modify() is the odd one out"（`pmd_modify()` だけが仲間外れ）と書いています。PMD は 2MB 単位のまとまりを扱う段で、Transparent Hugepage（THP）がちょうどここを使います。

消える順番も、コミットメッセージに具体的に書かれています。

1. THP として割り当てられた領域に書き込む
2. `madvise(MADV_FREE)` で「もう要らないが、すぐ捨てなくてよい」とカーネルに返す
3. 同じ領域にもう一度書き込む（ここで CPU がダーティビットを立て直す）
4. `mprotect()` で読み取り専用に変える。この処理が `pmd_modify()` を通り、立て直したビットが消える
5. cgroup のメモリ圧迫などで回収が走り、ダーティビットのない lazyfree の領域として解放される
6. 次に読むと、中身はゼロのページになっている

`mprotect()` だけでなく NUMA のヒンティングでも同じ消失が起きうること、さらにファイルに紐づいた THP では書き戻しが漏れ、ディスク上のデータが古いまま残ることも記されています。

条件は重なりますが、珍しい組み合わせではありません。x86 系で THP が有効、コンテナや cgroup でメモリ上限をかけていて、アプリケーションが `MADV_FREE` を使う。jemalloc は既定でこれを使います。Kubernetes の Pod やメモリ制限のあるコンテナは、まさにこの条件に当てはまりえます。

原因となったのは、Intel CET のシャドウスタック対応で `_PAGE_SAVED_DIRTY` を実際に使い始めた [Rick Edgecombe 氏のコミット](https://github.com/torvalds/linux/commit/bb3aadf7d446) です。作成日は 2023年6月13日で、Linux 6.6（2023年10月末リリース）で初めてリリースに含まれました。戻り先アドレスを守るためのセキュリティ機能を足した変更が、別の場所でデータ消失の種を残していたことになります。ちなみに修正コミットのレビューには、Edgecombe 氏本人も名を連ねています。

見つけたのはカーネルの開発者ではありませんでした。8月31日、データフレームライブラリ Polars に [「Live DataFrames can change silently after collect() under memory pressure」という Issue](https://github.com/pola-rs/polars/issues/29061) が立ちます。jemalloc の `muzzy_decay_ms:0` を指定した対照実験では 45 回中 0 回しか再現しなかったことから `MADV_FREE` が絡んでいると絞り込まれ、Polars メンテナの Orson Peters 氏が最新のメインラインカーネルで再現してカーネルのメンテナへ報告しました。修正コミットの `Reported-by` にも同氏の名前があります。

なお動画では修正を「10文字の削除」と紹介しましたが、差分を数え直すと括弧を含めて変わった文字数はそれより多く、正確には「1行の変更」です。訂正しておきます。また、取り込まれたのは `x86_urgent_for_7.3-rc4` という名前のプルリクエストですが、記事執筆時点で v7.3-rc4 自体はまだ公開されていません。

修正を含むカーネルが届くまでの回避策として、Polars の Issue では `_RJEM_MALLOC_CONF=muzzy_decay_ms:0` を付けて実行するか、THP の `always` を無効にする方法が案内されています。前者は jemalloc に `MADV_FREE` を使わせない設定で、性能をいくらか犠牲にして安全側に倒すものです。

3年近く前に置かれた1行のマスクが、今年の本番環境でデータを消していた。書いた瞬間の小さな判断は、何年も先まで持ち越されます。

## まとめ

5本を並べると、向きの違う話が混ざっていました。

Cisco は、入力検証を1か所甘くした判断が、セキュリティ製品の root まで通ってしまった話でした。CPython は、ビルド必須の依存を1つ足すという判断を、材料がそろうまで保留した話。GNOME は、ばらばらだったやり方を共通のプロトコルにそろえた話。Fedora は、ptrace と署名検証の既定値を安全側に倒した話。そしてカーネルは、3年近く前の1行が、条件がそろった瞬間に静かにデータを消した話です。

共通しているのは、その影響をいちばんまともに受けるのが「触らなかった人」だということです。詳しい人は自分で設定を変えます。既定値は、何もしなかった人の環境にそのまま居座ります。だからこそ、良い既定値は多くの人を守り、悪い1行は多くの人を巻き込みます。

あなたの手元の環境で、入れたときのまま触っていない設定はいくつありますか。THP が有効なままコンテナを動かしていないか、メールゲートウェイのバージョンはいくつか。今日のうちに一度だけ、確かめてみてください。

## 参考リンク

- [Cisco Security Advisory: cisco-sa-esa-inj-2bLVGmhX（CVE-2026-76461）](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-esa-inj-2bLVGmhX)
- [CISA Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [The Register: CPython Eases Rust Requirements as Assimilation Continues](https://www.theregister.com/devops/2026/09/14/cpython-eases-rust-requirements-as-assimilation-continues/5296010)
- [Python Insider: Rust for CPython Progress Update April 2026](https://blog.python.org/2026/04/rust-for-cpython-2026-04/)
- [GNOME Mutter 51.beta リリースノート](https://gitlab.gnome.org/GNOME/mutter/-/releases/51.beta)
- [Fedora Changes: Restrict ptrace by default](https://fedoraproject.org/wiki/Changes/Restrict_ptrace_by_default)
- [Fedora Changes: Enforcing signature checking by default](https://fedoraproject.org/wiki/Changes/Enforcing_signature_checking_by_default)
- [torvalds/linux: x86/mm: Fix user-space data loss with MADV_FREE and THP](https://github.com/torvalds/linux/commit/f7491d7c81db0e7c304a7bd757a76d2fbeaff80e)
- [pola-rs/polars Issue #29061](https://github.com/pola-rs/polars/issues/29061)
