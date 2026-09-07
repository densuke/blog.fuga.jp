---
title: "縦棒「|」は後から来た——Unixパイプの考古学、最後は1964年の紙1枚へ〈言語知新(6)〉"
date: 2026-09-06T00:00:00+09:00
draft: false
tags: ["Unix", "パイプ", "シェル", "Linux", "McIlroy", "Ken Thompson", "CSP", "DTSS", "Multics", "コンピュータの歴史", "言語知新"]
categories: ["言語知新"]
---

こんにちは！Agy無限会社のコンテンツ制作部です。

`ls | wc -l` ——この真ん中にある縦棒1文字を、私たちは毎日のように打っています。あまりに当たり前すぎて、「Unix のパイプといえば `|`」だと思い込んでいる方がほとんどではないでしょうか。

ところが、そうではありませんでした。 **パイプという機構が Unix に入ったとき、`|` という記号はまだ存在していません。** 最初の記法はまったく別物で、しかもその後しばらく、`|` と同じ意味で使える「もう1つの記号」が公式マニュアルに載っていました。

今回の言語知新は特別編です。いつものように独立した5つのトピックを並べるのではなく、 **手元のシェルで打っている縦棒1文字を起点に、地層を1枚ずつ剥がして1964年の紙1枚まで掘り下げていく** 構成にしました。表層にはカーネルのリングバッファがあり、その下にはバイト列という極端な単純化があり、さらに下には記号が入れ替わっていく1970年代のマニュアル群があり、最深部には8年間実装されなかった1枚のメモが眠っています。掘り進めながら確かめていきましょう。

---

{{< youtube "UKwo8sjV6Hw" >}}

---

## 1. あの縦棒が実はやっていること

シェルに `ls | wc -l` と打ったとき、何が起きているのか。答えは意外とそっけなくて、 **`pipe` でパイプを作り、`fork` でプロセスを分け、`dup2` で標準入出力をパイプの端に差し替えて、`exec` する** 。それだけです。縦棒はこの一連の手続きを1文字に圧縮した記法にすぎません。

パイプの実体は、カーネルの中に確保されたリングバッファです。[pipe(7) の man ページ](https://man7.org/linux/man-pages/man7/pipe.7.html)によれば、Linux 2.6.11 以降のパイプ容量は16ページ、ページサイズ4096バイトの環境で **65,536バイト（64 KiB）** です。それ以前はシステムのページサイズ（i386 で4096バイト）と同じでした。Linux 2.6.35 以降は `fcntl(2)` の `F_GETPIPE_SZ` / `F_SETPIPE_SZ` で取得・設定でき、Linux 4.5 以降は `pipe-user-pages-soft` 制限を超えると既定容量が16ページより小さくなることがあります。

ここで、混同されやすい数字がもう1つあります。 `PIPE_BUF` です。POSIX.1 は `PIPE_BUF` バイト未満の書き込みがアトミック（複数の書き手がいても交錯しない）であることを要求しており、最低512バイトと規定しています。Linux では4096バイトです。

**この2つはまったく独立した値です。** 65,536は「ブロックせずに溜められる総量」、4096は「アトミック性が保証される単一書き込みの上限」。同じ「パイプのバッファサイズ」という言葉で語られがちですが、意味する対象が違います。

そしてもう1つ、パイプの挙動で誤解されやすいのが実行順序です。 **パイプラインの各段は並行に走ります。** 前段が全部終わってから後段が始まるのではなく、データが流れるにつれて同時に処理されます。だからこそ、後段が詰まると前段の `write` がブロックする——バックプレッシャーが、明示的な流量制御コードなしに自然に生じるわけです。

なお、この「書いた分をそのままコピーする」という素朴な絵も、現代の実装では正確ではありません。[splice(2) の man ページ](https://man7.org/linux/man-pages/man2/splice.2.html)は「Though we talk of copying, actual copies are generally avoided.（コピーと呼んではいるが、実際のコピーは概ね回避される）」と明記しています。`splice` / `tee` / `vmsplice` は、パイプバッファを参照カウント付きのカーネルページへのポインタ集合として扱い、実データの複写を避けます。

## 2. バイト列には構造がない

パイプの設計は、極端なまでに単純です。流れるのは **構造を持たないバイト列** 。区切りも型もメタデータもありません。10バイト書いた側と3バイトずつ読む側で、単位が一致する保証すらありません。

この単純さが合成可能性を生んだのですが、同時に限界も生みました。CSV や JSON といった構造は、パイプラインの各段が毎回自前でパースし直す必要があります。エラーの伝播も粗く、途中のコマンドが失敗してもパイプライン全体の終了ステータスには現れません（`set -o pipefail` が必要になる理由です）。パイプはシークできず、前に戻れません。無名パイプは一方向で、双方向にしたければ2本使うか `socketpair` を使うことになります。

この「テキスト指向の限界」への回答として、別の設計を選んだシェルもあります。PowerShell の `|` はテキストではなく .NET オブジェクトを流します。[about_Pipelines の公式ドキュメント](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipelines)は「the objects that Command-1 emits are sent to Command-2」と述べており、だからこそ `Get-Process | Where-Object {$_.CPU -gt 100}` のようにプロパティへ直接アクセスできます。ただし同じドキュメントは「stdin isn't connected to the PowerShell pipeline for input」とも注記しており、外部ネイティブコマンドとの統合には別の制約が生じます。Nushell がテーブルを流すのも同じ問題意識への別解です。

言語のライブラリ層にも、同じ「つなぐ」という語彙が広がっています。ただしここは注意が必要な場所で、名前が似ていても技術カテゴリが違うものが混ざっています。Node.js の Streams は `readable.pipe(writable)` でバックプレッシャーを自動制御しますが、[公式の Stream ドキュメント](https://nodejs.org/api/stream.html)は「if the Readable stream emits an error during processing, the Writable destination is not closed automatically（読み込み側がエラーを出しても書き込み先は自動的に閉じられない）」と警告し、代わりに `stream.pipeline()` を推奨しています。一方、Elixir や F#、OCaml、R の `|>` は **関数適用の糖衣構文** であって、OS のパイプとは無関係です。見た目の類似だけで系譜をつなげてはいけない、というのがこのシリーズの基本姿勢です。

そして、シェルの `|` にはもう1つ、記法そのものの制約があります。 **線形の鎖しか書けない** のです。パイプ機構自体は任意のトポロジを組めるのに、記法が枝分かれを許さない。この制約について、パイプの提唱者である Doug McIlroy 自身が[口述史](https://archive.computerhistory.org/resources/access/text/2019/11/102740539-05-01-acc.pdf)で振り返っています。「I was hacking away at my desk at some syntax that would allow you to pipe data one way down a pipeline. ... And in a certain lack of vision, I didn't have-- I didn't invent an operator for connecting these things.（ある種のビジョンの欠如で、これらをつなぐ演算子を発明しなかった）」と。

## 3. 縦棒は、後から来た記号

ここからが今回の掘削の本番です。 **`|` という記号は、パイプという機構より後から来ました。**

まず出発点。[Unix Version 1 の sh(1) マニュアル](https://www.tuhs.org/cgi-bin/utree.pl?file=V1/man/man1/sh.1)（1971年11月3日）には、こう書かれています。「There are three command delimiters: the new line, ";" , and "&".（コマンド区切りは3つ：改行、`;`、`&`）」。パイプはまだ存在しません。

次に Version 3（マニュアルのヘッダ日付は1973年1月15日）。ここでパイプが登場します。ところが[V3 の sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V3/man/man1/sh.1)の "Pipes and Filters" 節が示す記法は、こうです。

```
ls >pr>
```

現代の記法に直せば `ls | pr` です。当時は I/O リダイレクトの `>` を拡張してパイプを表現していました。より一般には `>f1>f2>...>` と書き、末尾にファイル名を置けば結果をファイルへ落とせます。対称的に `<f1<f2<...<` という入力側フィルタも存在しました。

このマニュアル原文には、後の証言と符合する記述が2つあります。1つは、フィルタ名が空白を含まない構文（blankless syntax）だと明記されていること。だから引数を渡すには `ls >"pr -h 'My directory'">` と二重にクォートする必要がありました。Dennis Ritchie が後に「最も鬱陶しかったのは字句上の問題だった」と書いた、その現物です。もう1つは、この時点で本文が `pipe(II)` システムコールを参照していること。つまり **「パイプという機構」と「`|` という記法」は、別々のタイミングで入った** ことが、当時のマニュアルそのものから読み取れます。

Ritchie は[「The Evolution of the Unix Time-sharing System」](https://www.cis.upenn.edu/~lee/07cis505/Papers/ritchie-bstj84.pdf)で、「The pipe notation using '<' and '>' survived only a couple of months; it was replaced by the present one that uses a unique operator（`<` と `>` を使うパイプ記法は数か月しかもたず、固有の演算子を使う現在のものに置き換えられた）」と述べています。

そして Version 4。[V4 の sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V4/usr/man/man1/sh.1)（ヘッダ日付 `4/18/73`）には、こうあります。

> One or more commands separated by `|' or `^' constitute a *pipeline*.

**1つ以上のコマンドを `|` または `^` で区切ったものがパイプラインを構成する。** ——縦棒だけではありません。サーカムフレックス `^` が、まったく同じ意味のパイプ演算子として公式マニュアルに載っているのです。

これは V4 限りの話ではありません。[V6 の sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V6/usr/man/man1/sh.1)（`5/15/74`）にも「One or more commands separated by `|' or `^' constitute a chain of *filters*.」とあり、記法は不変のまま用語だけが "pipeline" から "chain of filters" に変わっています。ソースコードを見れば、両者が同一であることはさらに明白です。V4・V5・V6 の `sh.c` はいずれも字句解析と構文解析の両方で `'|'` と `'^'` を同じ `case` として扱い、同じ `TFIL`（filter）ノードを作ります。 `a | b` と `a ^ b` は構文木レベルで完全に同じものでした。

ここからが、いちばん面白いところです。Version 7（1979年）で Stephen Bourne が書き直した Bourne shell が標準になります。[V7 の sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V7/usr/man/man1/sh.1)は「A pipeline is a sequence of one or more commands separated by `|`.」と、 **`|` しか書いていません。** `^` はマニュアルから消えました。

ところが、[V7 の cmd.c](https://www.tuhs.org/cgi-bin/utree.pl?file=V7/usr/src/cmd/sh/cmd.c)を開くと、文法コメントに `item |^ term` と書かれており、パーサ本体には次の判定が残っています。

```c
IF (t=item(TRUE)) ANDF (wdval=='^' ORF wdval=='|')
```

**実装は `^` を受理し続けていました。** 全面書き直しをしながら後方互換のために機能を残し、しかしドキュメントからは落とす——「機能は生きているが文書からは消えた」という状態が、1979年の時点で成立しています。同じコードは System III（1981年）にも残っています。なお、`^` が「非推奨」「削除」と公式に宣言された文書は見つかっておらず、マニュアルから記載が消えただけです。

では、なぜ2つの記法が併存したのか。 **ここは断定できません。** 当時のマニュアル原文に理由の説明は一切なく、設計者本人による説明も一次資料としては見つかっていません。よく語られる「大文字専用端末のため」という説の事実上の出所は、[Sven Mascheck による Bourne shell 系の解説](https://www.in-ulm.de/~mascheck/bourne/)ですが、その原文自体が「 **probably** for reasons of convenience on early upper-case-only terminals（おそらく初期の大文字専用端末での利便性のため）」と、推測であることを明示しています。

技術的な前提として整合する事実はあります。ASCII-1963 には縦棒 `|`（0x7C）が定義されておらず、0x5E は `^` ではなく `↑`（上向き矢印）でした。`|` と `^` が現在の姿で確定するのは ASCII-1967 です。Teletype Model 33 のような大文字専用端末と Model 37 のようなフル ASCII 端末が Bell Labs で混在していたのも事実です。ただし「だから `^` を用意した」という因果を述べた当時の記録は、確認できていません。

## 4. 「CSPの実装」という誤解

パイプの話をすると、しばしば理論の名前が持ち出されます。「Unix パイプは CSP（Communicating Sequential Processes）の実装だ」「Kahn Process Networks が源流だ」といった具合に。

**時系列が逆です。** Unix のパイプ実装は1972〜73年。Gilles Kahn の "The Semantics of a Simple Language for Parallel Programming" は1974年、C. A. R. Hoare の「Communicating Sequential Processes」は1978年です。どちらもパイプより後に出ています。

では Hoare の CSP 論文は Unix をどう扱っているのか。[Hoare 1978 の原文](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf)を全文検索すると、`UNIX` の出現は本文1回と参考文献1回だけ。しかも本文の1回は、イントロダクションの列挙のなかの括弧書きです（以下、原文の参考文献番号は省略しています）。

> Subroutines (Fortran), procedures (Algol 60), entries (PL/I), **coroutines (UNIX)**, classes (SIMULA 67), processes and monitors (Concurrent Pascal), clusters (CLU), forms (ALPHARD), actors (Hewitt).

Fortran や Algol 60 と並列に列挙されているだけで、Unix が特別扱いされてはいません。さらに言えば、この論文には **`pipe` / `pipeline` / `filter` という語が一度も出てきません。** 謝辞で Hoare が技術的インスピレーションとして挙げているのは Edsger W. Dijkstra であって、Unix ではありません。

ちなみに、「Hoare が Unix のフィルタ＆パイプライン方式の成功を称賛した」という一文が Hoare の言葉として引用されることがありますが、 **これは孫引きの誤りです。** その文は Russ Cox のウェブページの地の文であって、Hoare の論文には存在しません。

では Hoare 自身はパイプの起源をどこに見ていたのか。1985年の書籍版 CSP の §7.3.1 "Pipes"（p.218-219）に、はっきり書かれています。「 **The idea was first propounded by Conway** （このアイデアを最初に提唱したのは Conway だ）」。Melvin E. Conway が1963年に発表したコルーチンの論文のことです。同じ段落には「The pipe is also the standard method of communication in the UNIX operating system, where the notation '|' is used instead of '>>'.」と、Unix は実例として付記されているだけです。書籍の Select Bibliography 全12件を確認しても、Thompson・Ritchie・McIlroy の名前は1件もありません。

つまり、Unix パイプと CSP は「一方が他方を生んだ」関係ではありません。 **Conway 1963 という共通の上流から分かれた、2本の枝** です。そして興味深いことに、Hoare が CSP 論文の看板例に使った並行素数篩は、Unix パイプではなく McIlroy が1968年に書いた Bell Labs の内部メモに帰されています。この内部メモは一度も印刷されませんでした。

## 5. 1964年10月11日の紙1枚

いちばん深い層に到達しました。

Doug McIlroy が1964年10月11日付で Bell Labs の内部メモに書いた一節が、パイプの思想的起点として広く引用されます。Ritchie が自室の壁に磁石で貼っていたという、その紙です。[Ritchie による再録ページ](https://www.nokia.com/bell-labs/about/dennis-m-ritchie/mdmpipe.html)から、[原本スキャンの PDF](https://swtch.com/~rsc/thread/mdmpipe.pdf) にたどり着けます。

> We should have some ways of **coupling** programs like garden hose--screw in another segment when it becomes when it becomes necessary to massage data in another way.

（庭のホースのようにプログラムを連結する方法を持つべきだ——別の方法でデータを加工する必要が生じたら、もう一節ねじ込めるように。）

この引用については、逐語に注意が必要です。動詞は **`coupling`** であって `connecting` ではありません。広く参照される TUHS Wiki は `connecting` と再録していますが、これは二次資料側の言い換えです。また、"when it becomes when it becomes" の重複は翻刻ミスではなく **原本にあります** 。McIlroy 本人のタイプミスで、Ritchie も「歴史的に正確だ」と注記しています。

そして、この紙について今回いちばん申し上げたいのはここです。 **これは石版に刻まれた宣言文ではありません。**

原本にはページ番号 **10** が振られており、より長い文書の一部です。有名な一節は4項目のリストの「1.」にすぎず、残りの3項目はローダの機能要望、ライブラリの filing scheme、private system components の取得——という実務的な要望が並びます。誤植も複数あります（先ほどの "when" の重複に加え、4項目目には `system` を `sytem` と打ち間違えた箇所があります）。清書された宣言というより、社内に投げた要望リストの走り書きです。

その文書が何についてのものだったかも、本人が語っています。[Computer History Museum の口述史](https://archive.computerhistory.org/resources/access/text/2019/11/102740539-05-01-acc.pdf)で、McIlroy は「That was written down in the same document where I said that 'the stream is the thing,' **it was about doing I/O on Multics** 」と述べています。 **Multics の I/O についての文書** だったのです。Bell Labs が Multics プロジェクトに参加するのは1964年11月ですから、このメモはその直前ということになります。

さて、1964年のアイデアが実装されるのは1972年。 **8年かかっています。** この空白に何があったのか。

出発点は Conway のコルーチン概念でした。McIlroy は[素数篩についての文書](https://www.cs.dartmouth.edu/~doug/sieve/sieve.pdf)で「When Bob McClure introduced me to Melvin Conway's coroutine concept, I was intrigued」と書いています。伝達経路は論文と紹介者であって個人的な交流ではありません（McIlroy は口述史で Conway を「somebody I've never met」と述べています）。1967年に Oxford で PL/I にコルーチンを入れる草稿を書き（未刊行）、1968年春に Cambridge で講演し、同じ1968年に Bell Labs の内部メモ "Coroutines" を書き——これが一度も印刷されなかったものです——Multics 期には Sandy Fraser に GE-635 上での実装を打診して不発に終わっています。

Unix が動き始めてからは、Ken Thompson への直談判が始まります。McIlroy の回想が、その顛末を克明に伝えています。

> As a minimalist, though, he wanted every system feature to carry significant weight. Did direct writes between processes offer a really major advantage over writing to a temporary file in one process and then reading it in the other? Not until I made a specific proposal with a catchy name, 'pipe', and shell syntax to connect processes via pipes, did Ken finally exclaim, 'I'll do it!'

Thompson が拒み続けた理由は、技術的な困難ではありませんでした。「一時ファイルに書いて読むのと比べて、本当に大きな利点があるのか」という設計判断です。ミニマリストとして、すべての機能に相応の重みを求めた。

そして決定打になったのが、 **機構だけでなくシェル記法とセットで提案されたこと** でした。口述史で McIlroy はこう語っています。「'And after you put this in you could use it directly in the shell with a notation like this,' the notation was pretty ugly but it was clear enough. And once he saw the connection ... Ken said, 'I'll do it'」。そこから先は一晩です。Thompson はシステムコールを書き、シェルに組み込み、複数のユーティリティをフィルタとして使えるように改造しました。翌日には「Look what I can do with pipes（パイプでこんなことができるぞ）」の連呼が始まり、週の終わりには秘書たちが NROFF の出力をプリンタへパイプしていた、と McIlroy は述懐しています。

この「機構と記法はセットでなければならない」というテーマには、強力な対照実験があります。Dartmouth の DTSS が持っていた **communication files** です。[McIlroy 自身が2017年に書いた論文](https://www.cs.dartmouth.edu/~doug/DTSS/commfiles.pdf)によれば、設計は1967年、システムが稼働した1969年1月6日には実働していました。Unix のパイプより3年以上先行しています。しかも機能は上回っていました。双方向で、帯域外信号（DRIVE）を持ち、ランダムアクセスもでき、master プロセスがファイル API の振る舞いを自分で定義できました。McIlroy の評価は「Pipes could be simulated by communication files, but not vice versa（パイプは communication files でシミュレートできるが、逆はできない）」です。

それなのに、広まったのは Unix のパイプのほうでした。McIlroy はその理由をこう分析しています。「Unix's command-line combinator '|' fostered the habit; nothing in DTSS did. ... **Unix pipes and the pipe combinator were created as (almost) inseparable twins.** （Unix のパイプとパイプ結合子は、ほぼ切り離せない双子として生まれた）」。DTSS にはシェル演算子がなく、「機構と、パイプのような簡単な利用との間のポテンシャル障壁が高すぎた」というわけです。

なお、この2つが親子関係にないことも押さえておきたい点です。Ritchie は「Evolution」論文（1984年）で「we didn't know it at the time（当時それを知らなかった）」と書き、McIlroy は2017年に、1997年に Dartmouth へ移ってからも仕組みを知らず、DTSS の同窓会で実装者に会ってようやく理解した、と書いています。33年隔てた2つの証言が一致しており、独立発明と見るのが妥当です。

同様に、「Multics のストリーム I/O が Unix パイプの祖先」という通説も、Ritchie 本人が否定しています。先ほどの「Evolution」論文で、彼は「 **In fact I do not think this is true, or is true only in a weak sense.** 」と述べ、その理由を「Multics の spliceable IO モジュールはその用途にしか使えないよう特別にコーディングされている必要があった。Unix パイプラインの天才性は、まさに普段から単体で使っているのとまったく同じコマンドから構成される点にある」と説明しました。Multics が祖先なのは、`<` と `>` による I/O リダイレクトのほうです。こちらは Ritchie が「it was inspired by an idea from Multics」と明言しています。ちなみに Multics 側が Unix 風のパイプ `;|` を得るのは[1987年](https://web.mit.edu/multics-history/source/Multics/doc/info_segments/pipes.gi.info)で、影響の向きは完全に逆です。

最後にもう1つ、当事者自身の告白を紹介させてください。パイプの最大の価値——前段の完了を待たず、データが流れるにつれて処理が進むという性質——について、McIlroy はこう書いています。

> Ironically, neither Ken Thompson nor I had taken conscious note of this critical distinction between pipes and intermediate files; otherwise pipes might have made their debut in the first edition of the Unix manual rather than the third.

（皮肉なことに、ケン・トンプソンも私も、パイプと中間ファイルとのこの決定的な差を意識的に認識していなかった。認識していれば、パイプは第3版ではなく初版の Unix マニュアルでデビューしていたかもしれない。）

この差を指摘したのは、実装当日に居合わせた Robert Morris でした。`dc | cat` は対話できるが `dc >temp; cat <temp` では対話が止まる、と。Thompson が「一時ファイルでいいのでは」と抵抗し続けた理由も、この差が誰にも見えていなかったからだと考えれば筋が通ります。

## まとめ

掘り下げてきた地層を、上から並べ直してみます。

- 表層：`|` はカーネルのリングバッファと `pipe`→`fork`→`dup2` を1文字に圧縮した記法
- 第2層：流れるのは構造を持たないバイト列。合成可能性と引き換えの単純化
- 第3層：`|` は後から来た記号。V1 はパイプなし、V3 は `>f1>f2>`、V4〜V6 は `|` と `^` が同義、V7 で `^` は文書から消えたが実装には残った
- 第4層：CSP も KPN もパイプより後。Hoare 自身はパイプの起源を Conway に帰していた
- 最深部：1964年10月11日、Multics の I/O について書かれた社内メモの10ページ目、4項目リストの「1.」

そして全体を貫いていたのは、 **機構だけでは広まらない** という一点でした。より強力な機構（DTSS の communication files）が3年以上先に実在し、Multics にもストリームへ処理を差し込む仕組みがありました。それでも Unix のパイプだけが普及したのは、当事者の言葉を借りれば「パイプ結合子と双子として生まれたから」です。

道具は、書きやすい記法とセットになって初めて道具になる。次に `|` を打つとき、その1文字が8年越しの提案の決定打だったことを、少しだけ思い出してもらえたら嬉しいです。

## 参考リンク

- [pipe(7) - Linux manual page](https://man7.org/linux/man-pages/man7/pipe.7.html)
- [splice(2) - Linux manual page](https://man7.org/linux/man-pages/man2/splice.2.html)
- [Stream - Node.js Documentation](https://nodejs.org/api/stream.html)
- [about_Pipelines - PowerShell](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipelines)
- [Unix V1 sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V1/man/man1/sh.1) / [V3 sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V3/man/man1/sh.1) / [V4 sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V4/usr/man/man1/sh.1) / [V6 sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V6/usr/man/man1/sh.1) / [V7 sh(1)](https://www.tuhs.org/cgi-bin/utree.pl?file=V7/usr/man/man1/sh.1)
- [V7 sh/cmd.c（サーカムフレックスを受理し続けている実装）](https://www.tuhs.org/cgi-bin/utree.pl?file=V7/usr/src/cmd/sh/cmd.c)
- [traditional Bourne shell family（Sven Mascheck）](https://www.in-ulm.de/~mascheck/bourne/)
- [The Evolution of the Unix Time-sharing System（Dennis Ritchie, BSTJ 1984）](https://www.cis.upenn.edu/~lee/07cis505/Papers/ritchie-bstj84.pdf)
- [Prophetic Petroglyphs - Advice from Doug McIlroy（Ritchie による再録）](https://www.nokia.com/bell-labs/about/dennis-m-ritchie/mdmpipe.html)
- [McIlroy 1964年メモ 原本スキャン PDF](https://swtch.com/~rsc/thread/mdmpipe.pdf)
- [Oral History of Doug McIlroy, Part 2（Computer History Museum, 2019）](https://archive.computerhistory.org/resources/access/text/2019/11/102740539-05-01-acc.pdf)
- [Coroutine prime number sieve（Doug McIlroy）](https://www.cs.dartmouth.edu/~doug/sieve/sieve.pdf)
- [Communication Files: Interprocess IO before Pipes（Doug McIlroy, 2017）](https://www.cs.dartmouth.edu/~doug/DTSS/commfiles.pdf)
- [DTSS Programming Manual, Chapter 5 "Communication Files"（1971）](http://www.cs.dartmouth.edu/~doug/DTSS/DTSSchapter5.pdf)
- [Communicating Sequential Processes（C. A. R. Hoare, CACM 1978）](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf)
- [Communicating Sequential Processes 書籍版（1985）](https://www.cs.miami.edu/home/burt/learning/Csc521.121/docs/cspbook.pdf)
- [Multics info segment "pipes.gi.info"（1987）](https://web.mit.edu/multics-history/source/Multics/doc/info_segments/pipes.gi.info)
- [UNIX Time-Sharing System: Foreword（McIlroy, Pinson, Tague, BSTJ 1978）](https://archive.org/details/bstj57-6-1899)
- [Ken Thompson 口述史（Mahoney, 1989）](https://www.tuhs.org/Archive/Documentation/OralHistory/transcripts/thompson.htm)
- [Doug McIlroy 口述史（Mahoney, 1989）](https://www.tuhs.org/Archive/Documentation/OralHistory/transcripts/mcilroy.htm)
- [USENIX ;login: インタビュー（McIlroy, 2016春）](https://www.usenix.org/system/files/login/articles/login_spring16_05_mcilroy.pdf)
