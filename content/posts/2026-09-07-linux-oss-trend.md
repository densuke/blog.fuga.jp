---
title: "主導権は待ってくれない（2026/9/7 Linux・OSSトレンド）"
date: 2026-09-07T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Chrome", "V8", "Grml", "Zenwalk", "Slackware", "NVIDIA", "Hugging Face", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

今日の5本を並べたとき、頭に浮かんだのは「主導権」という言葉でした。

自分が使っているブラウザを、いつ、どのバージョンに上げるか。手元のレスキュー USB を、どのファイルシステムで焼くか。ディストリビューションが、どの時点で新しいツールチェーンに乗り換えるか。そして——自分が毎日 `import` しているライブラリのホスト先が、誰の持ち物であり続けるのか。

前の3つは、こちらが決められます。最後のひとつは、決められませんでした。

今日はその落差の話です。ページを開いただけで乗っ取られる Chrome のゼロデイから始めて、地道に更新を積み重ねる3つのディストロを挟み、最後に「AI の共有地」が一社に買われた話で終わります。更新を止めた瞬間に主導権が誰かの手に渡る、という一点で、5本は同じ方向を向いていました。

{{< youtube "DTFaWk1_tag" >}}

## 1. Chrome V8 のゼロデイ CVE-2026-85046 — ページを開くだけで成立する

今年6本目です。

Google Chrome の JavaScript エンジン V8 に、型混乱（Type Confusion）の脆弱性 [CVE-2026-85046](https://nvd.nist.gov/vuln/detail/CVE-2026-85046) が見つかりました。CVSS v3.1 で 8.8（High）、CWE-843。深刻なのはスコアそのものより、成立条件の軽さです。攻撃者が細工した HTML ページを開く——それだけで、Chrome のレンダラープロセス内で任意コードが実行されます。追加のクリックも、ファイルのダウンロードも要りません。

技術的な中身は、V8 の高速化の仕組みそのものを裏返したものです。V8 は配列の要素型を ElementsKind という分類で管理していて、たとえば小整数だけが詰まった配列（`PACKED_SMI_ELEMENTS`）には、ポインタのタグ処理を省いた最速の経路を割り当てます。今回の欠陥では、実際にはオブジェクトポインタを保持している `PACKED_ELEMENTS` の配列が、誤って `PACKED_SMI_ELEMENTS` のマップを受け取ってしまう。JIT コンパイラは「ここには整数しか入っていない」という前提で機械語を吐くので、ポインタが置かれているメモリを生の整数として読み書きできてしまいます。ここからヒープ上の任意読み書きへ、さらに WebAssembly のコード領域を書き換えてのシェルコード実行へと発展します。

Google は緊急アップデートを公開し、修正版は Windows / macOS が 152.0.7977.82 または .83、Linux が 152.0.7977.82 です。このリリースには計 12 件のセキュリティ修正が含まれ、報告者は Salvatore Gulizia 氏（ハンドル名 Serotav）だと [BleepingComputer が報じています](https://www.bleepingcomputer.com/news/security/google-warns-of-new-chrome-zero-day-flaw-exploited-in-attacks/)。Google 自身も「CVE-2026-85046 のエクスプロイトが野外に存在することを認識している」と明言しました。

反応の速さも目を引きます。CISA はパッチ公開の翌日にあたる 2026 年 9 月 4 日、本件を [Known Exploited Vulnerabilities カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)へ登録し、連邦機関に 9 月 18 日までの適用を義務づけました。カタログ上の製品名は「Google Chromium V8」で、Chrome 単体ではなく Chromium エコシステム全体を名指ししています。Edge・Opera・Vivaldi・Brave といった Chromium ベースのブラウザも同じ V8 を共有している以上、各ベンダのパッチ提供を待つ必要があります。

なお、CVSS ベクタのスコープは `S:U`（変化しない）なので、サンドボックスの外へ出るには別の権限昇格と連鎖させる必要があります。ただしレンダラープロセスを取られた時点で、セッション Cookie の窃取や保存パスワードの読み出しは成立します。「サンドボックス内だから軽い」とは、まったく言えません。

対策は更新です。V8 の JIT を無効化するといった緩和策も議論されてはいますが、常用環境で現実的な選択肢は、まずバージョンを上げることだと考えています。

## 2. Grml 2026.09 — exFAT の USB から、そのまま起動できる

ここからは息継ぎです。

システム管理者向けのレスキュー Linux「Grml」が 2026.09（コードネーム "Hättiwaritätti"）をリリースしました。ベースは Debian Testing の "Forky"（将来の Debian 14）、カーネルは Linux 7.1.8。x86_64 と AArch64 それぞれに Full 版（約 1.1GB）と Small 版（約 640MB）を用意した計4イメージ構成です。

今回いちばん実用に効くのは、initramfs への exFAT サポート追加でしょう。[公式リリースノート](https://grml.org/changelogs/README-grml-2026.09/)には「exfat support is now available in the initramfs, for booting from exfat-formatted USB devices」と記されています。従来は FAT32 や NTFS の USB からは起動できても、exFAT はブート最初期に読み込まれる initramfs に `exfat` モジュールが入っていなかったため対象外でした。ここが埋まったことで、macOS で初期化した USB や、Windows でそのまま使っていた exFAT の USB を、フォーマットし直さずに Grml の起動メディアにできます。

地味に聞こえるかもしれませんが、レスキューが必要な場面というのは、たいてい手元に都合のいいメディアがない場面です。「借りた USB を消さずに使える」の一点で、この機能は現場の体感を変えると思います。

一方で、移行時に引っかかりそうな変更もいくつか入りました。GNU Screen が 4.9 系から 5.0.1 へ上がり、リリースノートは設定変更に後方互換性がないと明記しています。カスタムイメージ作成ツール `grml-live` は Linux のユーザー名前空間をビルド環境に要求するようになり、32ビット i386 のサポートは完全に削除されました。

そしてもうひとつ、正直に書かれているのが面白いところです。この user namespace 対応が必要になった影響で、Grml の日次自動イメージ生成は **2026 年 6 月 10 日から 9 月 2 日までの 84 日間、停止していました** 。開発チームはそれを隠さず記録し、パイプラインを直して日次ビルドを再開したうえで今回のリリースを出しています。今サイクルでは 19 件の Issue が解決され、144 件の Pull Request がマージされました。

USB へ書き込む際は `grml2usb` のバージョン 0.20.14 以降が必要です。Docker や Podman の中でビルドしている場合は、ユーザー名前空間が有効なホストで実行する必要がある点にも注意してください。

## 3. Zenwalk Current Milestone 2026 — Slackware 系に Flatpak が乗る

谷の底です。ニッチな話ですが、意味は小さくありません。

Slackware 系の長寿ディストリビューション Zenwalk が「Current Milestone 2026」（識別子 Current-260905）をリリースしました。[Linuxiac の解説](https://linuxiac.com/slackware-based-zenwalk-current-milestone-2026-released-with-linux-7-1/)によれば、カーネルは BORE パッチを当てた Linux 7.1.7、デスクトップは Xfce 4.20 です。

BORE（Burst-Oriented Response Enhancer）は短時間のインタラクティブな CPU バーストを優先するスケジューラ改良で、Linuxiac は「負荷が高い状況でもデスクトップアプリケーションと UI 全体の応答性を保つことを狙ったもの」と説明しています。Zenwalk はこのパッチを試験的に採用してきた経緯があり、今回のマイルストーンで標準構成に組み込まれた形です。

そして今回の目玉が Flatpak の統合です。インストール済み・設定済みの状態で提供され、Flathub がアプリソースとして最初から有効になっています。グラフィカルなソフトウェアストアから Flatpak アプリをそのまま導入できる一方、システム本体は従来どおり Slackware 形式のパッケージが担う——という二層構造です。

ここは慎重に書いておきたいところで、「Slackware 系で初めて Flatpak に対応した」わけではありません。Salix OS など、先行して同様のアプローチを採ってきた派生があります。Zenwalk がやったのは、それを標準構成として最初から有効な状態で配ったことです。一次情報を確認する限り、Linuxiac の記事にも「Slackware 系初」という主張はありませんでした。

私がこのニュースを面白いと思ったのは、パッケージ哲学を変えずに間口だけを広げた点です。Slackware 本体がパッケージ互換性を厳格に守り続ける傍らで、その派生が現代的なサンドボックスアプリ層を後付けできると実証した。老舗の蕎麦屋が、味を変えないままデリバリーに対応したような話です。ディストロ自体のユーザー規模は小さくても、「できる」という前例が積まれることには価値があります。

なお、GUI のシステム管理ツール群も全面的に書き直され、Window Maker にインスパイアされたレイアウトのオプションも用意されています。本リリースに起因するセキュリティ脆弱性の報告はなく、急いで適用すべき類のものではありません。

## 4. Slackware 16 Alpha 1 — 4年半ぶりに、トンネルの先の光

同じ Slackware 一族から、もっと大きな話が出ました。

2026 年 9 月 6 日、Patrick Volkerding 氏が Slackware 16 Alpha 1 を公開しました。[Phoronix が報じた](https://www.phoronix.com/news/Slackware-16-Alpha) ChangeLog の記述はこうです。

> Upgraded to binutils-2.47, gcc-16.2.0, and glibc-2.44, and compiled everything with them. There might be a light at the end of the tunnel, eh?

Binutils 2.47、GCC 16.2.0、glibc 2.44。GNU ツールチェーンの三本柱を同時に入れ替え、その新しいツールチェーンで全パッケージを再コンパイルした、という宣言です。Slackware 15.0 のリリースから約4年半。30年以上ひとりでメンテナンスを続けてきた開発者が書く「トンネルの先に光が見えるかもしれない、な？」という一文には、正直、重みを感じました。

これが単なるバージョン番号の更新でない理由は、GCC 16 の側にあります。[GCC 16 の公式変更点](https://gcc.gnu.org/gcc-16/changes.html)は「GCC 16 changes the default language version for C++ compilation from `-std=gnu++17` to `-std=gnu++20`」と明記していて、C++ のデフォルト規格が C++17 から C++20 へ引き上げられました。つまり全パッケージの再ビルドは、ビルドシステム全体の整合性を確認し直す大工事になります。GCC 16 はほかにも HTML / SARIF 形式での診断出力、AMD Zen6・Intel Nova Lake・Apple M4/M5 などの新世代 CPU 対応を取り込んでいます。

glibc 2.44 側も見どころがあります。[公式リリースアナウンス](https://sourceware.org/pipermail/libc-alpha/2026-July/179159.html)によれば 2026 年 7 月 25 日のリリースで、`/etc/tunables.conf` と `ldconfig` によるシステム全体のチューナブル設定が導入されました。環境変数 `GLIBC_TUNABLES` に頼らず設定ファイルで永続化できるようになった形です。読み取り専用セグメントを Transparent Huge Pages でマップする `glibc.elf.thp` チューナブル、CORE-MATH 由来の正確丸め版 `cosh` / `sinh` / `tanh` も入り、セキュリティ面では CVE-2026-4437、CVE-2026-4438（`gethostbyaddr` 系の DNS 応答処理）と CVE-2026-4046（`iconv` のクラッシュ）の3件が修正されています。

カーネルは Linux 6.18 LTS を採用し、ブートローダには依然として LILO が残っているとのこと。新しいツールチェーンに乗りながら、外側の設計思想は変えない。いかにも Slackware です。

ただし Alpha 1 は明確にテスト向けです。本番環境への適用は控えるべきですし、SlackBuilds.org でパッケージを提供しているメンテナは、C++20 デフォルト化でビルドが落ちるケースに備える必要があります。古いコードで困ったときは `CXXFLAGS="-std=gnu++17"` を明示すれば従来の挙動に戻せます。

## 5. NVIDIA が Hugging Face を約129億ドルで買収 — 共有地は誰のものか

そして、こちらが決められなかった話です。

NVIDIA が Hugging Face を買収することで合意しました。[SEC に提出された Form 8-K](https://www.sec.gov/Archives/edgar/data/0001045810/000104581026000078/nvda-20260902.htm) によれば、株主への対価が約 119 億ドル、従業員向けに最大約 10 億ドルの株式ベースのリテンションプログラムが加わり、総額はおよそ 129 億ドル。クロージングは 2027 年上半期の予定で、規制当局の承認を含む慣例的な条件が付いています。

規模を確認しておきます。[NVIDIA 公式ブログ](https://blogs.nvidia.com/blog/nvidia-to-acquire-hugging-face/)が挙げているのは、300 万件のモデル、50 万件のデータセット、100 万件のアプリケーション、1,800 万人の開発者・研究者・クリエイター、そして 20 万社以上の企業ユーザーという数字です（これらの統計は公式ブログに記載されているもので、SEC 8-K には定量データの記載はありません）。

数字以上に効いているのは位置です。`transformers`、`diffusers`、`datasets` といった Python ライブラリは、AI/ML の学習・推論スクリプトの冒頭にほぼ必ず並びます。モデルを取ってくるとき、何も考えずに `from_pretrained()` を書く——その「デフォルトの経路」に座っているのが Hugging Face でした。AI 界における GitHub であり、npm であり、Maven Central でもある。それをチップの最大手が持つことになります。

NVIDIA 側は公約を示しています。公式ブログには「NVIDIA compute will not be required to build on or deploy through Hugging Face.」——NVIDIA のコンピュートは Hugging Face 上でのビルドやデプロイに必須とはならない、と明記されました。マルチクラウド・マルチアクセラレータ対応の継続も、法人としてのコミットメントの形で述べられています（Jensen Huang 氏個人の発言としてではありません）。

それでも構造的な懸念は残ります。これらは声明であって、ガバナンスを分離する仕組みではないからです。AMD ROCm や Intel GPU、独自 ASIC を使っている側から見れば、最適化やドキュメント整備の優先順位が下がるリスクは自然に想定されます。実質的な担保になるのは、規制当局がこの公約をどう評価し、どんな条件を付けるかでしょう。

金額の見え方も付け加えておきます。[TechCrunch の報道](https://techcrunch.com/2026/09/03/nvidia-confirms-it-will-buy-hugging-face-for-12-9-billion/)によれば Hugging Face の年換算収益は約 1 億 5,000 万ドルとされ、129 億ドルはその 86 倍規模になります。同記事は Financial Times の報道として、同社が昨年 NVIDIA からの 5 億ドル規模の提案を断っていたことにも触れています。収益倍率で説明できる取引ではなく、「共有地の位置」に対して払われた金額だと読むほうが自然です。

では手元で何ができるか。脆弱性と違って適用すべきパッチはないので、対応は戦略的なものになります。ライセンスが許す範囲で重要なモデルアーティファクトをローカルにミラーしておくこと。`from_pretrained()` で最新を追い続けるのではなく、バージョンをピン留めしておくこと。Hub 経由でしか到達できない設計を避け、モデル提供元への直接のフォールバックを用意しておくこと。そして、2027 年上半期に向けた規制審査の行方を追い続けること。

## まとめ

5本を通して見えたのは、更新の主導権をどこまで自分の手に残せるか、という線引きでした。

Chrome のゼロデイは、こちらが更新を先送りした日数がそのまま攻撃可能な窓になります。Grml の exFAT 対応も、Slackware のツールチェーン刷新も、Zenwalk の Flatpak 統合も、誰かが地道に更新を積み重ねた結果として手元に届いたものです。ここまでは、自分の側にレバーがあります。

最後の1本だけが違いました。Hugging Face をどこが持つかは、利用者が投票して決められることではありません。決まったあとで、自分の依存の形を変えられるかどうかだけが手元に残ります。ミラーを持っておくか、バージョンをピン留めしておくか——それは買収が発表されてから始める作業ではなく、平常時にやっておく作業です。

主導権は待ってくれない、というのはそういう意味だと思っています。奪われてから慌てるのではなく、奪われる前に、自分の手で更新し続けておく。

あなたの環境で「そこは誰かが面倒を見てくれている」と思い込んでいる依存先は、どれでしょうか。

## 参考リンク

- [CVE-2026-85046 - NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-85046)
- [CISA Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [Grml 2026.09 リリースノート](https://grml.org/changelogs/README-grml-2026.09/)
- [Grml 公式ブログ: new stable release 2026.09 available](https://blog.grml.org/archives/426-Grml-new-stable-release-2026.09-available.html)
- [Linuxiac: Zenwalk Current Milestone 2026](https://linuxiac.com/slackware-based-zenwalk-current-milestone-2026-released-with-linux-7-1/)
- [Phoronix: Slackware 16 Alpha 1](https://www.phoronix.com/news/Slackware-16-Alpha)
- [GCC 16 Release Series — Changes](https://gcc.gnu.org/gcc-16/changes.html)
- [glibc 2.44 リリースアナウンス](https://sourceware.org/pipermail/libc-alpha/2026-July/179159.html)
- [NVIDIA 公式ブログ: NVIDIA to Acquire Hugging Face](https://blogs.nvidia.com/blog/nvidia-to-acquire-hugging-face/)
- [SEC Form 8-K (NVIDIA, 2026-09-02)](https://www.sec.gov/Archives/edgar/data/0001045810/000104581026000078/nvda-20260902.htm)
