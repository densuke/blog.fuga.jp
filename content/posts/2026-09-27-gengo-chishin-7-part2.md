---
title: "参照透過性はどこから来たか——Quineから1829年まで、通説のほうが揺らぐ〈言語知新(7)後編〉"
date: 2026-09-27T00:00:00+09:00
draft: false
tags: ["参照透過性", "関数型プログラミング", "コンピュータの歴史", "数学史", "Haskell", "Rust", "React", "ALGOL 60", "LISP", "言語知新"]
categories: ["言語知新"]
---

こんにちは！Agy無限会社のコンテンツ制作部です。

前編では「参照透過性」を、置換テスト——式を変数に括り出しても答えが変わらないか——という手を動かして確かめられる道具として扱いました。後編では逆に、手を止めて資料を読みます。「参照透過性」という語そのものを一次資料まで遡り、どの分野からどの分野へ運ばれてきたのかを確かめる回です。テーマは一言でいうと、 **同じ語が出てくることと、同じ概念であることは別である** 、ということ。これから見ていく5つの章は、すべてこの一点の実例です。

この回は前編の「置換テスト」（式を変数に括り出しても意味が変わらないか）を前提に進みます。まだの方は、先に[前編の記事](/posts/2026-09-20-gengo-chishin-7-referential-transparency/)か[前編の動画](https://www.youtube.com/watch?v=r1wVTl6Lb6c)をご覧ください。

---

{{< youtube "3E6TQTkWa9g" >}}

---

先に結論の一部を出しておきます。調べてみると、通説は次の3点で揺らぎます。「参照透過性を提唱した」とされる Backus の講演に、その語は出てきません。「denotative」という語を使った Landin の定義は、参照透過性とは似ていますが別物です。そして「Dirichlet が関数概念を刷新した」という物語の主役であるはずの Dirichlet 自身は、その功績を Fourier に帰しています。この3つのねじれを、本文で1つずつ確かめていきます。

## 1. Rust は参照透過ではない——現代の地図

まず現代の地平を見渡します。[Haskell 2010 Language Report](https://www.haskell.org/onlinereport/haskell2010/haskellch1.html) は冒頭で、Haskell を汎用の "purely functional programming language" であると規定しています。実装の慣習ではなく、仕様書に書かれた宣言です。ただし「純粋関数型」と書いてあることと「副作用が数学的に不可能」であることは別で、Haskell には `IO` 型に加えて `unsafePerformIO` という脱出ハッチが標準ライブラリに存在します。仕様が保証しているのは、通常の型付き言語機能の範囲では副作用が型に現れない形で起こせない、というところまでです。

Rust はここで対照的な位置にあります。[The Rust Programming Language](https://doc.rust-lang.org/book/ch03-01-variables-and-mutability.html)（公式book）は、変数が既定で不変であり `mut` を付けたときだけ書き換え可能になると明記しています。しかしこれは束縛の話であって、式の話ではありません。Rust の標準ライブラリには `Cell` / `RefCell` の[公式ドキュメント](https://doc.rust-lang.org/std/cell/)が説明するとおり、共有参照 `&T` 越しでも中身を書き換えられる「内部可変性」の仕組みが正規に用意されています。

```rust
use std::cell::Cell;

fn f(c: &Cell<i32>) -> i32 {
    c.set(c.get() + 1);   // 共有参照越しに中身を書き換えている
    c.get()
}
// f(&c) を「その値」に置き換えると意味が変わる。呼ぶたびに違う値になる（実行結果はここでは示さない）。
```

`f(&c)` という式を評価結果に置き換えることはできません。呼ぶたびに違う値を返すからです。つまり **Rust は参照透過ではありません。** Rust の不変性は「参照透過性の保証」ではなく、エイリアシング（同じものへの複数の名前）と変更が同時に起きることを型で制御する仕組みだと理解するのが正確です。

もう一つ、React も見ておきます。React の公式ドキュメントは、コンポーネントとフックについて「厳密な純粋性」ではなく[「冪等性」](https://react.dev/reference/rules/components-and-hooks-must-be-pure)を求めていると明記しています。同じ入力に対して常に同じ結果を返すこと、という要求です。そして[レンダー中に新規に作った値へのローカルな変更](https://react.dev/learn/keeping-components-pure)は許容されるとも書かれています。React がイミュータブルな更新を勧めるのは、変更検知が参照の浅い比較（`Object.is`）で行われるからであって、純粋性という理念そのものが目的ではありません。

ここまでで見えてくるのは、Haskell の「純粋関数型」と React の「純粋であれ」が、字面は同じでも指しているものが違うという事実です。前者は仕様に書かれた式の性質、後者はライブラリが変更検知のために課す規約です。この「同じ語で別のものを指す」という現象こそが、この後編全体で追いかけていく主題そのものです。

## 2. その講演に語は出てこない——Backus 1977

「参照透過性を提唱した」としてしばしば名前が挙がるのが、John Backus です。しかし一次資料を読むと、この帰属は崩れます。

Backus は1977年10月17日、シアトルのACM年次大会で1977年のチューリング賞を受けました。講演を論文化したものが、Communications of the ACM 21巻8号（1978年8月号）pp.613–641に[掲載されています](https://hendrix-cs.github.io/csci410/docs/backus.pdf)。講演と論文掲載のあいだに1年のずれがある点は、記事内でも分けて書いておきます。

この論文で Backus が論じた点を、一次資料に即して整理します。まず、CPUと記憶装置をつなぐ経路を指して、彼自身が名付けを行っています。原文は "I propose to call this tube the von Neumann bottleneck." です。次に、代入文がプログラミング言語版のこのボトルネックであり、我々を「一語ずつ」の思考に縛りつけていると論じます。さらに、代入文の右辺は代数的性質を持つ整然とした「式の世界」だが、左辺以降を含む「文の世界」はそうではなく、この分断が言語を肥大化させていると診断します。式の世界の代数的性質は「しばしば副作用によって破壊される」とも書かれています。

Backus が具体案として示したのが FP という言語です。内積の定義は次の形をしています。

```
Def IP ≡ (/+)∘(α×)∘trans
```

対応する命令型のプログラムとして、論文には次の形が挙げられています。

```
c := 0
for i := 1 step 1 until n do
    c := c + a[i] × b[i]
```

FP 版には状態を持つ変数がありません。Backus はこの形の利点として、引数だけに作用し隠れた状態や複雑な遷移規則がないこと、繰り返しがないことなどを列挙しています。そして FP は、ラムダ式や、変数・置換規則を意図的に使わない設計だと述べています。ここで注意が必要なのは、これは「代入」という一語で丸めてしまうと不正確になる点です。原文が捨てたと述べているのは、ラムダ計算の変数や置換規則であって、命令型言語の代入文そのものではありません。

論文後半には、状態を持つ Applicative State Transition（AST）システムの提案もあります。つまり **Backus は「状態を全廃せよ」とは言っていません。** 彼が問題にしたのは、状態遷移との結合の粒度です。

そして本題です。この論文の全文を検索した限り、"referential transparency" という語も、その表記の揺れも見当たりません。Backus が使う語彙は「代入」「エイリアシング」「状態への密結合」であり、「参照透過性」という術語ではないのです。用語としての参照透過性は、次の章で見る Strachey の系統から来ています。Landin の論文についても、全文を検索した限り "referential transparency" という語は出てきません。

もう一つ、確実な接続もあります。Backus は自身の FP を、Church のラムダ計算、Curry のコンビネータ体系、純粋 Lisp と同じ「適用的モデル」に分類し、これらを参照文献として明示しています。つまり Backus から見て **後ろ向き** の接続——Church・Curry・純粋 Lisp への参照——ははっきり引けます。一方、現代のコレクション API に見られる `map` / `filter` / `reduce` の連鎖は、Backus の FP と同じ発想の別系統と見るのが妥当で、後継として直接つながるとまでは言えません。

## 3. 語は哲学から輸入された——Quine と Strachey、そして Landin

「参照透過性」という語がプログラミング言語論に持ち込まれたのは、Christopher Strachey が1967年8月、コペンハーゲンの International Summer School in Computer Programming のために書いた講義録 *Fundamental Concepts in Programming Languages* です。この講義録は、Higher-Order and Symbolic Computation 13巻 pp.11–49（2000年）に[再録されています](https://reed.cs.depaul.edu/jriely/447/assets/articles/strachey-fundamental-concepts-in-programming-languages.pdf)。

Strachey はこの性質を、Quine が呼んだものとして明示的に引用したうえで説明しています。原文には次のようにあります。

> "referential transparency. In essence this means that if we wish to find the value of an expression which contains a sub-expression, the only thing we need to know about the sub-expression is its value. Any other features of the sub-expression, such as its internal structure, the number and nature of its components, the order in which they are evaluated or the colour of the ink in which they are written, are irrelevant to the value of the main expression."

「インクの色」まで持ち出して「値だけが効く」ことを強調しているのが分かります。Strachey は続けて、L-value（アドレス的な値）と R-value（内容的な値）を区別し、代入がある言語でも L-value については参照透過性が保たれると論じています。彼は「参照透過性のためには代入を捨てよ」とは言っていません。 **代入のある言語の中で、参照透過な部分をどう確保するかを問題にしている** のです。原文では次のように、良い実践として推奨されるべきだと述べられています。

> "I suggest that as a matter of good programming practice it should always be done."

番組ではこの性質を、ALGOL 60 の `bump` という手続きで再現しています。グローバル変数を1増やして返す手続きで、`bump + bump` と `2 * bump` を比べると値が一致しません。

```algol
integer procedure bump;
begin
  n := n + 1;
  bump := n
end;
```

Strachey 自身の講義録を通読した限り、この `bump` そのものと同型の例は見当たりませんでした。近い一般論として、代入がある場合には `x = x` が常に真であるとは言えなくなる、という記述はあります。したがって `bump` は、 **Strachey が問題にした性質を、番組が ALGOL 60 で再現した例** として扱います。

同じ1967年より1年前、Peter Landin は "The Next 700 Programming Languages"（CACM 9巻3号, 1966年）で、[ISWIM という言語族](https://archive.alvb.in/msc/11_infomtpt/papers/the-next-700_Landin_dk.pdf)を提案しています。この論文を全文検索した限り、"referential transparency" という語は出てきません。Landin が使ったのは "denotative"（表示的）という語で、ジャンプと代入を使わずに ISWIM へ写せることだと定義されています。原文は "can be mapped into Iswim without using jumping or assignment" です。同じ論文には日常語としての "transparent" も出てきますが、これは「見通しがよい」という意味で、術語としての参照透過性ではありません。同じ語が出てくるからといって同じ概念とはみなせない、という好例です。もう一点、ISWIM は純粋言語ではありません。論文は "purely functional" な部分体系を含む、という言い方をしています。

なお、Quine が『Word and Object』(1960) の§30で referentially transparent を定義しているとされていますが、この点については番組でも本記事でも一次資料の該当箇所を確認できていません。断定は避け、Strachey が引いた形での紹介にとどめます。

## 4. 純粋な言語を作った系統——Church から Haskell、そして合流

参照透過性という語の輸入元とは別に、「実際に純粋な言語を作る」という系統もあります。その理論的な原型は Alonzo Church のラムダ計算です。ラムダ計算には代入も記憶域もなく、計算は β 簡約という項の書き換えとして進みます。ここでの「代入」は数学の代入（substitution）であって、記憶域を書き換えるプログラミングの代入（assignment）ではありません。前編で確認した2つの「代入」の区別が、ここでも効いています。

Landin はこの考え方を、既存の命令型言語の意味を説明する道具として使いました。"A correspondence between ALGOL 60 and Church's lambda-notation"（1965年）で、ALGOL 60 とラムダ記法の対応を示しています。参照透過性という概念が意味を持つのは、プログラムが式として読めるときだけで、Landin の仕事はその土台を作ったと言えます。

LISP についても、通説には修正が必要です。「純粋 Lisp」という部分体系は確かにあり、Backus も1978年の論文でこれを適用的モデルの一例として挙げています。しかし LISP という処理系そのものは、当初から代入を持ち、LISP 1.5では `rplaca` / `rplacd` という、リストのセルを破壊的に書き換えるプリミティブを備えていました。番組ではこの違いを、`cons` と `rplaca` の対比で確認しています。

```lisp
(setq b (cons 0 a))   ; b は a を共有する新しいセルを1つ作る。コピーではない
(rplaca a 99)         ; a の先頭セルを書き換える。b からもその変化が見える
```

これは番組の検証環境（GNU CLISP）での実行で確認したものです。LISP 1.5 そのものではなく、同名同義のプリミティブを今も持つ CLISP 上での確認です。`cons` が非破壊的なのは「コピーするから」ではなく、元のリストを共有する新しいセルを1つ作るからで、これが構造共有の原型になります。

David Turner の SASL・KRC・Miranda という系列は、遅延評価・純粋関数型・パターンマッチという組み合わせを実用的な処理系として提供しました。[Haskell 2010 Report の序文](https://www.haskell.org/onlinereport/haskell2010/haskellli2.html)によれば、1987年9月にオレゴン州ポートランドで開かれた FPCA '87 で会合が持たれ、当時十数個（"more than a dozen"）存在していた非正格・純粋関数型言語を統合する共通言語を作るために委員会が設けられました。最初の報告書（Version 1.0）が1990年に出たとよく紹介されますが、この序文のページからはその年を確認できませんでした。ここで重要なのは、 **Haskell は純粋性の発明者ではなく、既存の純粋関数型言語群を統合する形で生まれた** という点です。

純粋関数型言語には長らく実務的な弱点がありました。入出力です。ここに解を与えたのが、圏論のモナドを計算の構造として使う一連の仕事です。Eugenio Moggi は計算の概念をモナドで捉える枠組みを示し（Information and Computation 93巻1号, 1991年）、Philip Wadler は Simon Peyton Jones との共著（POPL '93）で、Haskell の I/O をモナドで扱う設計を示しました。この2本の書誌は二次資料でしか確認できていないため、内容の引用はせず書誌の紹介にとどめます。「モナドが副作用を可能にした」という説明は不正確で、モナドは副作用を型で追跡可能にしたのであって、副作用そのものを生み出す仕組みではありません。

永続データ構造は、もう一つの合流点です。Driscoll, Sarnak, Sleator, Tarjan の "Making Data Structures Persistent" は、STOC '86とJournal of Computer and System Sciences 38巻1号（1989年）に発表されました。この論文自体は関数型プログラミングの論文ではなく、著者たちの動機は計算幾何のアルゴリズム設計にあり、実装は命令型です。この書誌も二次資料での確認にとどまるため、内容の引用は避けます。純粋関数型言語では更新が新しい値を作るので、旧版が残るのは副産物として最初から自動的でした。両者を明示的に結びつけたのが、Chris Okasaki の[博士論文](https://www.cs.cmu.edu/~rwh/students/okasaki.pdf)（CMU-CS-96-177、1996年9月）です。遅延評価と償却解析を組み合わせることで、永続データ構造でも計算量の保証を回復する手法を体系化しました。その実用速度を JVM 上で示したのが、2007年に Rich Hickey が公開した Clojure です。[Clojure 公式の解説](https://clojure.org/about/state)は、値は不変であり、識別子は状態を持つ、値の計算は純粋関数的であるという設計を説明しています。

## 5. 1829年に置かれた反例——Dirichlet と関数の定義

ここから先は、影響関係ではなく理論的な前提の話になります。参照透過性の核心は「式の値はその値だけで決まる」ことですが、これは関数を外延的（入力と出力の対応そのもの）に捉えるという数学的な立場そのものです。18世紀の標準的な関数観は、関数を変数と定数からなる解析的な式とみなすものでした。この立場では、式で書けないものは関数ではありません。当時の解析学は弦の振動や熱伝導という応用からの圧力を受けており、初期条件としてどこまで勝手な形を関数として許すかが論争になっていました。

Joseph Fourier の1822年の著作は、熱伝導方程式の解として三角級数を用い、任意の関数を三角級数で表せると主張しました。ここで確かめておきたいのが、Peter Gustav Lejeune Dirichlet の論文（Journal für die reine und angewandte Mathematik 誌 第4巻 pp.157–169, 1829年）です。この論文の[全文転写](https://arxiv.org/abs/0806.1294)を見ると、冒頭でDirichletは、任意関数を表現する方法の導入を、名前は出さないものの著名な幾何学者としてFourierを指して述べ、まだ誰もその一般的な証明を与えていないと書いています。つまり、この方法を導入した功績を Dirichlet 自身が Fourier に帰しているのです。この論文全体は、その一般的な証明を与える試みとして位置づけられています。

そして、この論文の末尾近く、本文の地の文には、次の関数の例が置かれています。

> "φ(x) égale à une constante déterminée c lorsque la variable x obtient une valeur rationnelle, et égale à une autre constante d, lorsque cette variable est irrationnelle"

変数 x が有理数のときは定数 c、無理数のときは別の定数 d をとる関数です。原文は「c」「d」という2つの定数であり、現代の説明でよく見る「1と0」という書き方は、後年の慣例による書き換えです。Dirichlet はこの関数について、任意の x に対して有限で確定した値を持つにもかかわらず、級数に代入することはできないと述べています。積分が意味を失うためです。この例が置かれた目的は、新しい関数概念の宣言ではありません。自分が示した収束定理が及ぶ範囲の限界を示す、積分不能の反例としてです。

この例が重要なのは、Dirichlet の意図とは独立に、「値の対応としては完全に確定しているが、式では表せない対象」の具体例として、以後の数学に居座り続けたからです。ここに、外延的な関数観と計算のあいだの溝が現れます。集合論的には、関数とは順序対の集合であり、この関数もその意味では立派な関数です。計算論的には、関数とは有限の手続きで値を出せるものであり、この関数は実数を引数とする限りそれを満たしません。プログラミング言語における「純粋関数」は、この2つの中間にいます。外延的関数のように入力だけで出力が決まることを要求しつつ、計算可能なものだけを扱うのです。数学の関数は計算可能である必要がなく、プログラムの関数は停止しないことがある、という違いがあります。

この事例を、参照透過性が前提とする外延的な関数観が数学の中で確立していく過程の、確認できる事例のひとつと見るのが妥当でしょう。ここから先が数学史研究の慎重さが要る領域で、同種の定義がこの論文以前にも見られたという指摘や、実際の数学的実践はもっと狭いクラスを扱っていたという指摘があります。この論文からプログラミング言語論への直接の影響を示す資料は、番組でも本記事でも見つかっていません。Backus も Strachey も Landin も Quine も、この論文を引用していません。

## 系譜を1枚にまとめる

実線は資料で確認できた影響関係、破線は影響関係ではなく理論的な前提を示します。

```
【論理学系統：語と判定基準】
  Quine 1960（referentially transparent の定義とされる）
      │ Strachey が明示的に引用
  Strachey 1967（プログラミング言語論への輸入）
      │
  現代の「参照透過性」（意味は徐々にずれる）

【計算系統：純粋な言語を作る流れ】
  Church のラムダ計算
      │
  Landin（SECD／ALGOL60対応／ISWIM／"denotative"）
      │
  Turner の SASL・KRC・Miranda ほか十数個の純粋関数型言語
      │
  Haskell → モナドI/O → 現代の純粋関数型言語

【並行して走った、Backus の系統】
  Church／Curry／純粋Lisp（Backus が参照文献として明記）
      │
  Backus の FP（変数を持たない関数の代数）
      ⇢ 関数型プログラミングへの関心の高まり

【アルゴリズム側からの合流】
  Driscoll-Sarnak-Sleator-Tarjan（永続データ構造）
      ⇢ Okasaki → Clojure ほかの永続コレクション

【数学側の理論的前提（影響関係ではない）】
  18世紀の「関数＝式」という立場
      ⇢ 弦の振動と熱伝導の応用 ／ Fourier（任意関数の表現）
  Dirichlet 1829（値としては確定するが式で表せない関数の例）
      ⇢ 外延的な関数観が確立していく過程の一事例
```

「Backus と Dirichlet」を並べて語る言い方は、この図の右端と左端をつないだものであり、一本の系譜ではありません。両者は、100年以上離れた別の分野で「関数とは何か」という同じ問いに答えた例です。

## まとめ

テーマに戻ります。 **同じ語が出てくることと、同じ概念であることは別です。** Haskell の「純粋関数型」という仕様上の宣言と、React が求める「冪等性」は、どちらも「純粋」という言葉で語られますが指しているものが違います。Landin の "transparent" という日常語と、Quine から輸入された術語としての参照透過性も、字面は似ていますが別物です。「代入」という一語も、数学の置き換え（substitution）と記憶域の書き換え（assignment）という別の2つを覆っています。

手元でできることとして、議論の中で概念語が出てきたら、どの定義で言っていますかと一度聞き直す、というのを持ち帰りとしたいです。それだけで、通説の物語がどこまで一次資料に支えられているかが見えてきます。

前編・後編を通した「よく言われること／原典では」の一覧を、後編分だけ表にしておきます。

| よく言われること | 原典・一次資料では |
|---|---|
| Backus が参照透過性を提唱した | 論文にその語は現れない。用語はStracheyがQuineから輸入した |
| Backus は状態をなくせと言った | 同じ論文の後半で、状態を持つASTシステムを提案している |
| Landin が参照透過性を言った | 彼の語は"denotative"。ISWIMへ写せるかという別の定義 |
| LISPは純粋関数型言語だった | 純粋Lispという部分体系はあるが、処理系は当初から代入を持つ |
| Haskellが純粋関数型を始めた | 既に十数個あった純粋関数型言語を統合するために作られた |
| Dirichletが任意の関数という概念を導入した | Dirichlet本人がその功績をFourierに帰している |
| Rustは参照透過だから安全 | Rustは参照透過ではない。安全性の源はアフィン型と借用検査 |
| Reactはイミュータブルで純粋だから関数型 | React公式は厳密な純粋性ではなく冪等性を求めると明記している |

前編では「参照透過性とはどういう性質か」を手を動かして確かめました。後編では「その言葉がどこから来たか」を一次資料まで遡って確かめました。同じテーマを2つの方向から見たことで、この語がどれだけ多くの分野を渡ってきたかが見えたのではないかと思います。

言語知新シリーズは次回もまた別の語を掘っていく予定です。前回（第6回・パイプ）の記事は[こちら](/posts/2026-09-06-gengo-chishin-6-pipe/)からどうぞ。

## 参考リンク

- [John Backus, "Can Programming Be Liberated from the von Neumann Style?" 全文PDF](https://hendrix-cs.github.io/csci410/docs/backus.pdf)
- [Christopher Strachey, "Fundamental Concepts in Programming Languages" 全文PDF](https://reed.cs.depaul.edu/jriely/447/assets/articles/strachey-fundamental-concepts-in-programming-languages.pdf)
- [Peter Landin, "The Next 700 Programming Languages" 全文PDF](https://archive.alvb.in/msc/11_infomtpt/papers/the-next-700_Landin_dk.pdf)
- [Dirichlet, 1829年論文の全文転写（arXiv:0806.1294）](https://arxiv.org/abs/0806.1294)
- [Haskell 2010 Language Report 序文](https://www.haskell.org/onlinereport/haskell2010/haskellli2.html)
- [React 公式ドキュメント "Components and Hooks must be pure"](https://react.dev/reference/rules/components-and-hooks-must-be-pure)
