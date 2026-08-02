---
title: "道具は入れ替わった、要求は変わらない——git commitに眠る50年の地層を掘る〈言語知新(4)〉"
date: 2026-08-02T00:00:00+09:00
draft: false
tags: ["Git", "バージョン管理", "SCCS", "RCS", "CVS", "Subversion", "Mercurial", "BitKeeper", "コンピュータの歴史", "言語知新"]
categories: ["言語知新"]
---

こんにちは！Agy無限会社のコンテンツ制作部です。

今日もどこかで、誰かが `git commit` と打ったはずです。この何気ない一行、実は半世紀分の試行錯誤が積み重なった地層の上に立っています。「誰が・いつ・何を・なぜ変えたのか」を記録し、複数人が同時に同じコードを触っても壊れないようにする——この一見あたりまえの要求は、ハードウェアの制約や組織の事情、そして数学的な難問が絡み合った、ずっと難しい問題であり続けてきました。

今回の言語知新は特別編です。通常回のように独立した5つのトピックを並べるのではなく、 **バージョン管理システムという単一のテーマを、現代のGitから半世紀前の源流へと掘り下げていく** 構成にしました。表層には内容ハッシュとMerkle DAGという現代的な設計があり、その下には分散モデルをめぐる2005年の分岐点、さらに下にはロックを捨てた1990年前後の転換、その奥に差分の向きをめぐる1985年の判断があり、最深部には1975年のSCCSと、それより前のパンチカードの時代が眠っています。道具は完全に入れ替わりましたが、要求されていることは変わっていない——それを地層を掘りながら確かめていきましょう。

---

{{< youtube "0Eb9AJmE2Cw" >}}

---

## 1. Gitは差分を保存していない

バージョン管理システムについて最も広く共有されている誤解が、「Gitは差分（デルタ）を保存している」というものです。論理モデルとしてこれは誤りで、Gitの各コミットは **プロジェクト全体の完全なスナップショット** を指しています。ただし誤解しないでほしいのは、差分圧縮そのものが存在しないわけではないという点です。packfileという仕組みによる差分圧縮は、ディスク使用量を抑えるための物理的な格納最適化として実在します。「論理モデルでは差分を使わない」のと「物理層で差分圧縮が行われる」のは別のレイヤの話です。

Gitの核心は **内容アドレス指定オブジェクトストア** （ファイルの中身から計算したハッシュ値を、そのファイルの名前として使う保存方式）です。blob（ファイル内容）、tree（ディレクトリ構造）、commit（スナップショットとメタデータ）、tag（名前付きポインタ）という4種類のオブジェクトがあり、すべてが内容のハッシュを名前として `.git/objects/` に格納されます。名前が内容から一意に決まるので、同じ内容は自動的に一度しか保存されません。

commitオブジェクトは親コミットのハッシュを含みます。したがって履歴は木構造ではなく **Merkle DAG** （各ノードが子のハッシュを含む有向非巡回グラフ）を成します。マージコミットが親を2つ以上持てるのは、この構造のおかげで枝が合流できるからです。この設計が同時に3つの性質——重複排除・完全性（1バイトでも壊れればハッシュが一致せず検出できる）・分散（2つのリポジトリが同じ履歴を持つかどうかをハッシュ1個の突き合わせで判定できる）——をもたらします。とりわけ3番目の性質が、分散バージョン管理を現実的な速度で成立させました。

ハッシュ関数の話にも触れておきます。Gitは長らくSHA-1を使ってきましたが、2017年にGoogleが実用的な衝突（SHAttered）を実証したことを受け、SHA-256への移行仕様が策定されました。ただし [Git公式のhash-function-transition](https://git-scm.com/docs/hash-function-transition) によれば、Gitはすでに素のSHA-1ではなく衝突検知を組み込んだHardened-SHA-1を使っており、SHAtteredに対する緩和策はすでに導入済みです。「SHA-1が破られたのでGitは危険」という言い方は正確ではありません。SHA-256サポートは **Git 2.29（2020年10月）で実験的に導入され、Git 2.42（2023年8月）で実験扱いが外れました** 。ただし、これは全エコシステムでの移行が完了したという意味ではなく、あくまで実験フラグが外れた段階です。

Gitより後発の試みとして、Jujutsu（jj）にも触れておきましょう。[Jujutsu (jj) のREADME](https://github.com/jj-vcs/jj) によれば、GoogleのMartin von Zweigbergkによる個人プロジェクトで、Gitのデータモデル、Mercurial/Saplingのanonymous branchとrevset、Pijul/Darcsのfirst-class conflicts（衝突そのものを第一級オブジェクトとして扱う設計）を組み合わせ、既定でGitリポジトリをストレージバックエンドに使います。作業コピー自体を1つのコミットとして扱う点が最大の特徴です。これはまとめの章でもう一度取り上げます。

## 2. 2005年4月、2週間の分岐

一段掘り下げると、2005年4月の激動にたどり着きます。Gitは、Linuxカーネル開発で使っていた商用分散VCS「BitKeeper」の無償利用打ち切りを直接の契機に、Linus Torvaldsが書き始めたものです。開発開始は **2005年4月3日** 、 **4月7日** には最初のコミット（コミットメッセージは "Initial revision of 'git', the information manager from hell"）で自己ホスティングに達しています。同じショックに対して、Matt Mackallが **4月19日** にMercurial（hg）を発表しました。両者はほぼ同時、しかし独立に、分散モデルという同じ結論にたどり着いています。

「分散バージョン管理はGitの発明」という理解はよくある誤解です。Gitが登場した時点で、分散モデルを実装した先行例はすでに複数ありました。BitKeeper（Larry McVoy率いるBitMover社の商用分散VCS）の製品初版はおおむね2000年、Linuxカーネルでの採用は2002年です。技術的に興味深いのは、BitKeeperが内部でSCCS由来のweave（織り込み差分）を使っていたことです。この基盤"BitSCCS"について、[BitMover公式](http://www.bitmover.com/bitsccs/) は「Marc RochkindがAT&T Bell Labsで1970年代に書いたSCCSの再実装」と述べています。ただしMcVoyの証言では、このSCCS-weave基盤は **bk 5.0以前** のもので、性能上の理由から **bk 6.0で新形式に置き換えられました** 。「BitKeeperは最後までSCCSのweaveで動いていた」わけではありません。BitKeeper自身は **2016年5月9日** にApache 2.0でオープンソース化されています。

Torvaldsが発想源として繰り返し挙げるのは、Graydon Hoareが2001年頃に始めたmonotoneです。[2005年4月のLKML投稿](https://lkml.iu.edu/hypermail/linux/kernel/0504.0/2022.html) では、Chris Wedgwoodが「モノトーンをいじっているが、見た目は派手な機能が山ほどあるものの、うんざりするほど遅い」と評したのに対し、Torvaldsは「Yes.」と同意しつつ、根本の発想自体は間違っていなさそうだと述べています。彼は2007年のGoogle Tech Talkでも「monotoneは好きなアイデアが多かったが性能が絶望的に悪く、既存の何より良いものが2週間で書けると判断した」と述べています。「Gitはmonotoneのフォーク」ではなく、あくまで発想源であって実装の派生ではありません。

ほかにもDarcs（David Roundy）があります。C++版のあとHaskell版が2002年秋に書かれ、2003年4月に公開されました。「リポジトリとは順序を問わないパッチの集合である」という発想に立つpatch理論を実装しています。GNU arch（tla、Tom Lord）は2003年にGNUプロジェクトの一部になりましたが、これはGitの直接の技術的祖先ではなく、分散VCS黎明期に理論的議論を活性化させた触媒という位置づけです。実際、[Darcsのpatch理論文書](https://darcs.net/Theory/MergersDocumentation) は「この理論はTom Lordとの一連のメール議論の結果として生まれた」と明記しており、直接の思想的つながりがここにはあります。分散モデルは複数の独立解決と直接影響が混在するかたちで受け継がれ、Gitはそれを速度と内容アドレス指定というエンジニアリング判断で実用化した、というのが最も正確な整理です。

## 3. ロックを捨てた日

分散モデルより前に、もっと根本的な転換がありました。 **ロックをやめる** という決断です。

それ以前のバージョン管理は「lock-modify-unlock（悲観ロック）」が基本でした。誰かがファイルを編集したいときはまずロックを取り、編集し、戻してロックを解放する。他の人はその間そのファイルを触れません。SCCSの `get -e` 、RCSの `co -l` がまさにこれで、開発は直列化されます。

CVSがこれを捨てました。 **copy-modify-merge（楽観的並行制御）** です。ロックを取らずに各自がコピーして編集し、あとでマージします。Brian Berlinerの [1990年USENIX Winter論文 "CVS II: Parallelizing Software Development"](https://docs-archive.freebsd.org/44doc/psd/28.cvs/paper.pdf) は、「開発者はロックせずオブジェクトをコピーし、編集し、元とマージする」と説明しており、論文タイトルの "Parallelizing" がまさにこの転換を指しています。

CVSの起源は、Dick Gruneが **1986年頃** にRCSの上に載せる複数開発者協調用のシェルスクリプト群として書いた前身にあります。Brian Berlinerが **1989年** にC言語で書き直し、翌1990年の論文で発表しました。ここで見落としてはいけないのは、 **CVSは内部でRCSの `,v` ファイルをそのまま使っていた** ことです。CVSは新しい保存形式を発明したのではなく、既存のRCS基盤の上に協調のレイヤを載せたにすぎません。ただしファイル単位で動くという弱点があり、ディレクトリ全体をatomicにコミットできず、リネームやコピーも扱えませんでした。

これをCollabNet社が補修します。Karl Fogel、Jim Blandy（Subversionという名称とデータストアの基本設計を考案）、Ben Collins-Sussmanらが2000年初頭に設計を始め、 **2001年8月31日に自己ホスティング化、2004年2月に1.0リリース** に至りました。ディレクトリの版管理、真のatomicコミット、ファイル・ディレクトリのコピーとリネームをサポートしています。とはいえ **集中型が劣っているわけではありません** 。中央が単一の真実源であることは、監査・権限管理・巨大アセットの扱いでむしろ有利に働きます。

ロックを捨てた瞬間、マージが必須になりました。ここから理論的な難問が立ち上がります。共通祖先を加えた3点を比較するthree-way mergeの古典的実装がdiff3です。ところが [Khanna・Kunal・Pierceの論文 "A Formal Investigation of Diff3"（FSTTCS 2007）](https://www.cis.upenn.edu/~bcpierce/papers/diff3-short.pdf) は、「よく離れた領域への編集は決して衝突しない」という直観が一般には成り立たないことを形式的に示しました。これは「diff3にバグがある」という話ではなく、 **毎日使う道具の基本性質が2007年になるまで深く研究されてこなかった** という指摘です。

## 4. 最新版を保存し、過去を逆算する

さらに下の地層に降りると、そもそも「複数の版をどう保存するか」という問題そのものに突き当たります。ディスクが高価だった時代、全バージョンを丸ごと保存する選択肢はありませんでした。ここに3つの答えがあります。SCCSが採用したinterleaved delta（weave、織り込み差分）は、全リビジョンの全行を1つのブロックに織り込む方式で、どの版でも取り出す時間が一定になる代わりに、版が増えるほど全体を舐める必要があります。SCCSの実運用形態であるforward deltaは最古の版を保存しそこに差分を積み上げる方式、そしてRCSが選んだreverse deltaは **最新版を丸ごと保存し、古い版を逆向きの差分で表す** 方式です。

RCSはWalter F. Tichyが **1982年にPurdue大学で開発** し、 **1985年** に [RCS — A System for Version Control（Software: Practice and Experience 15(7):637–654）](https://www.gnu.org/software/rcs/tichy-paper.pdf) として発表しました。reverse deltaという選択の根拠は明快な観察に基づいています。人が最も頻繁に取り出すのは最新版である、ならば最新版へのアクセスを最速にすべきだ、という発想です。Tichyの論文は実測に基づき、「適用するdeltaの平均は **1.2未満** 」「SCCSは **10回のdelta適用まではRCSより速い** が、reverse deltaが明らかに選ぶべき方法だ」と論じています。数値はここでも丸めずそのまま覚えておく価値があります。

RCSは依然として悲観ロックを採ります。`co -l` の `-l` がロックです。興味深いのは、他人のロックを破る操作自体は可能だったことで、破ると自動でロック保持者にメールが飛び記録が残りました。 **技術的な禁止ではなく社会的な抑止** で運用されていたわけです。

差分の計算そのものにも系譜があります。[Hunt & McIlroyの1976年の技術報告](https://www.cs.dartmouth.edu/~doug/diff.pdf)（Bell Laboratories Computing Science Technical Report #41、1976年7月）はUNIXの `diff` の基礎になったアルゴリズムで、McIlroy本人は約4か月の開発を "a desperate effort"（必死の努力）と述懐しています。続いて **1986年** 、Eugene W. Myersが [“An O(ND) Difference Algorithm and Its Variations”](http://www.xmailserver.org/diff2.pdf)（Algorithmica 1(2):251–266）で、LCS（最長共通部分列）と最短編集スクリプトを編集グラフ上の最短経路探索として統一し、 **O(ND)** アルゴリズム（Nは両列長の和、Dは最小編集スクリプト長）を与えました。

マージ理論は現代にも続いています。Darcsのpatch理論は **1.x** で、ある種の衝突に対し指数時間かかりうる問題を抱えていました。 **Darcs 2で頻度は減りましたが完全には解消されていません** 。Darcsは2.10以降、patience diffを既定採用しています。Pijulはこの問題に別角度から答えました。[Samuel MimramとCinzia Di Giustoの論文 "A Categorical Theory of Patches"（2013）](https://www.lix.polytechnique.fr/Labo/Samuel.Mimram/docs/mimram_ctp.pdf) を理論的基盤とし、ファイルを対象、パッチを射とする圏を考え、マージを **押し出し（pushout）** として定義します。[Pijul公式のモデル解説](https://pijul.org/model/) は「マージ操作がwell-definedで期待される性質を全て持つ」と述べていますが、これはあくまで **設計者側の主張** であり、大規模実運用での検証はエコシステムの発展途上にあります。中立の事実として断定するのは避けるべきでしょう。

## 5. その源流は、線だったかもしれない

最深部にあるのがSCCS（Source Code Control System）です。Marc J. RochkindがBell Laboratories（Murray Hill）で **1972年後半** に開発を始め、 **1975年** に [The Source Code Control System（IEEE Transactions on Software Engineering, SE-1(4):364–370, 1975年12月）](https://dl.acm.org/doi/10.1109/TSE.1975.6312866) として発表しました。論文要旨は「全バージョンの格納・更新・取得、更新権限の制御、そして各変更を誰が・いつ・どこで・なぜ行ったかの記録を提供する」と述べており、50年前の要約が現代のVCSの機能一覧とほぼ一致しています。最初の実装はIBM System/370（OS/360 MVT）上で、SNOBOL4という文字列処理言語で書かれた **とされています** （これは伝聞であり断定はできません）。コマンド仕様はのちにPOSIX（IEEE Std 1003.1）に含まれ標準化されました。

「最古」と言えるでしょうか。Rochkind本人による [2025年の回顧論文 "A Retrospective on the Source Code Control System"（IEEE TSE）](https://www.computer.org/csdl/journal/ts/2025/03/10821013/23d1xvEsT6M) には「当時、比較できるバージョン管理システムは知られていなかった」とありますが、記事としては **「学術記録に残る最初期の汎用ソースコード版管理ツールとみなすのが妥当」** という表現に留めます。「すべての源流」「世界初」と断定するのは正確ではありません。SCCSは無から生まれたのではなく、先行する構成管理技法を背景に持っているからです。

その前史がパンチカードの時代です。1960年代、ソースは主に80カラムのパンチカードに保持されました。IBMのIEBUPDTEユーティリティは制御カードによって既存のソースライブラリにカード（行）を挿入・削除・置換しており、[IBM公式ドキュメントのIEBUPDTE解説](https://www.ibm.com/docs/en/zos-basic-skills?topic=dsu-iebupdte-utility-update-data-sets-fixed-length-records) が示すこの発想は、UNIXの `patch` の遠い先祖と見ることができます。80カラムカードの **73〜80カラム** は慣習的にシーケンス番号に予約されていました。[Columbia大学の計算機史資料](https://www.columbia.edu/cu/computinghistory/sorters.html) によれば、これはIBM 704/709/7090/7094のカードリーダがrow-binaryで72カラム（2×36ビット）しか読まなかったことに由来し、FortranやCOBOLがソースを先頭72カラムに制限したのもこの名残です。

ここが本記事でもっとも慎重に扱いたい箇所です。当時の現場では、 **デッキ側面に斜めの線を一本引く** という非公式な工夫が広く行われたと伝えられています。先に断っておくと、これはメーカーのマニュアルや標準仕様に定められたものではない、あくまで現場発の慣習です。デッキを輪ゴムで留めた状態で側面に斜線を引いておくと、1枚でも抜けたり順序が入れ替わったりした際に線がずれ、目視で異常を検出できたといいます。この実在自体は大学の計算機史ページ・当事者の回想・技術系メディアなど複数の二次資料が一致して伝えていますが、 **当時の一次資料（メーカーのマニュアル、当時の教科書、社内標準文書）での裏付けは取れておらず、起源・考案者・普及度は断定できません** 。

シーケンス番号との役割の違いは本質的です。連番は機械可読で、カードソータにかければ正しい順序へ **復元** できる高解像度・厳密な索引です。対して斜線は人間の目にしか読めない低解像度・近似の索引で、「順序が壊れたことに **気づける** 」だけで「正しく **復元する** 」力を持ちません。誤り検出符号と誤り訂正符号の違いに近い、という言い方もできますが、これは **比喩であって理論的な対応関係を主張するものではありません** 。

系譜上の位置づけには特に慎重さが要ります。斜線は「ソース本体には含まれない冗長な順序・整合性メタデータを外側に持たせる」という発想であり、現代の内容ハッシュによる完全性検証と **同じ問題領域に属します** 。しかし **直接の影響関係を示す資料はなく、あくまで思想的な類似にとどまります** 。斜線をSCCSやRCSの祖先、ましてやGitの内容ハッシュの直接の源流と位置づけてはいけません。似た問題意識を持った現場の知恵が、時代を超えて似た形に落ち着いた——そう理解するのが最も誠実な整理です。

なお、この時代には他にも商用ソースライブラリ管理製品としてThe Librarian（Applied Data Research、1960年代末〜）とPanvalet（Pansophic Systems、1970年）があり、両者で市場をほぼ二分したと証言されています。テープ時代には日次・週次・月次でバックアップを回転させる世代管理（grandfather-father-son）の慣習もありましたが、考案者・考案年を特定できる信頼できる出典は見つかっておらず、特定人物に帰属させることなく「テープ時代の長年の慣習」と表現するのが妥当です。背景には、[1968年10月にガルミッシュで開かれたNATOソフトウェア工学会議](https://archive.org/details/softwareengineer0000unse)（議長F. L. Bauer、報告編者Peter NaurとBrian Randell、1969年1月刊）で広く知られるようになった「ソフトウェア危機」があります。SCCS論文との関係は直接の引用関係ではなく、あくまで時代的な文脈として捉えるべきでしょう。

## まとめ

遡行を終えて現代に戻ってくると、Gitが解決したことと、していないことが見えてきます。オフラインで完全な履歴を持てること、ブランチが安価であること、分散協調ができること、内容ハッシュによって完全性を検証できること——これらは明快な便益です。一方で、巨大リポジトリと巨大バイナリの扱い、リネームの追跡（Gitはリネームを明示的に追跡せずヒューリスティックで検出します）、そして学習コストは今も苦手なままです。

巨大バイナリの領域では、[Christopher Seiwaldが1995年にAlamedaで創業したPerforce](https://www.perforce.com/blog/vcs/introducing-the-p4-platform) の集中型排他ロックに今も合理性があります。マージ不能なアセットを扱うゲーム業界やCAD業界では、悲観ロックがむしろ事故を防ぐのです。 **「Gitが常に最適」というわけではありません。**

その先に目を向けると、作業コピー自体を1つのコミットとして扱うJujutsu（jj）、Meta由来で巨大モノレポ向けのsparse機能を持つSapling、圏論的な押し出しでマージを定義しようとするPijul、そして [lore.kernel.org](https://lore.kernel.org/) に象徴される、GitHubのPull Requestという中央集権的ワークフローとは対照的な、メーリングリストにパッチを流す方式の生存——バージョン管理の外側にあるワークフローのレイヤも、独自の進化を続けています。

現代のGitユーザーが `git commit` と打つとき、その裏では内容ハッシュが計算され、Merkle DAGにノードが1つ足されます。そして50年前、Bell Labsの端末の前で `delta s.file` と打った誰かは、コメントの入力を求められていました。「なぜこの変更をしたのか」を書け、と。道具は完全に入れ替わりましたが、要求されていることは変わっていません。

## 参考リンク

- [hash-function-transition Documentation (Git公式)](https://git-scm.com/docs/hash-function-transition)
- [Jujutsu (jj) README](https://github.com/jj-vcs/jj)
- [Re: Kernel SCM saga.. (Linus Torvalds, LKML, 2005-04-07)](https://lkml.iu.edu/hypermail/linux/kernel/0504.0/2022.html)
- [BitSCCS (BitMover公式)](http://www.bitmover.com/bitsccs/)
- [Darcs Theory / Theory of Patches (David Roundy)](https://darcs.net/Theory/MergersDocumentation)
- [CVS II: Parallelizing Software Development (Brian Berliner, USENIX Winter 1990)](https://docs-archive.freebsd.org/44doc/psd/28.cvs/paper.pdf)
- [A Formal Investigation of Diff3 (Khanna, Kunal, Pierce, FSTTCS 2007)](https://www.cis.upenn.edu/~bcpierce/papers/diff3-short.pdf)
- [RCS — A System for Version Control (Walter F. Tichy, SP&E 15(7), 1985)](https://www.gnu.org/software/rcs/tichy-paper.pdf)
- [An Algorithm for Differential File Comparison (Hunt & McIlroy, Bell Labs CSTR #41, 1976)](https://www.cs.dartmouth.edu/~doug/diff.pdf)
- [An O(ND) Difference Algorithm and Its Variations (Eugene W. Myers, Algorithmica 1(2), 1986)](http://www.xmailserver.org/diff2.pdf)
- [A Categorical Theory of Patches (Samuel Mimram, Cinzia Di Giusto, 2013)](https://www.lix.polytechnique.fr/Labo/Samuel.Mimram/docs/mimram_ctp.pdf)
- [Pijul Model (Pijul公式)](https://pijul.org/model/)
- [The Source Code Control System (Marc J. Rochkind, IEEE TSE SE-1(4), 1975)](https://dl.acm.org/doi/10.1109/TSE.1975.6312866)
- [A Retrospective on the Source Code Control System (Marc J. Rochkind, IEEE TSE, 2025)](https://www.computer.org/csdl/journal/ts/2025/03/10821013/23d1xvEsT6M)
- [The IEBUPDTE utility (IBM Documentation)](https://www.ibm.com/docs/en/zos-basic-skills?topic=dsu-iebupdte-utility-update-data-sets-fixed-length-records)
- [IBM Punch Cards / IBM Card Sorters (Frank da Cruz, Columbia University)](https://www.columbia.edu/cu/computinghistory/sorters.html)
- [Software Engineering: Report on a conference sponsored by the NATO Science Committee, Garmisch 1968 (Naur & Randell eds., 1969)](https://archive.org/details/softwareengineer0000unse)
- [Re-Introducing P4 (Perforce Software)](https://www.perforce.com/blog/vcs/introducing-the-p4-platform)
- [lore.kernel.org (Linux kernel public inbox)](https://lore.kernel.org/)
