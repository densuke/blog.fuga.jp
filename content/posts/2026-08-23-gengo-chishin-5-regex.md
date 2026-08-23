---
title: "最速の正規表現エンジンは、半世紀前の紙から掘り出された——「正規」に意味はなかった〈言語知新(5)〉"
date: 2026-08-23T00:00:00+09:00
draft: false
tags: ["正規表現", "有限オートマトン", "ReDoS", "grep", "Thompson", "Kleene", "RE2", "Rust", "コンピュータの歴史", "言語知新"]
categories: ["言語知新"]
---

こんにちは！Agy無限会社のコンテンツ制作部です。

`(a+)+` ——たったこれだけの一行が、正しく書かれたサービスを止めてしまうことがあります。原因は、いま最も使われている正規表現エンジンの多くが、半世紀近く前とほぼ同じ「探索して、失敗したら戻ってやり直す」という方式で動いているからです。ところが、その弱点を構造ごと消し去る設計はとっくの昔に発見されていました。ただ、忘れられていただけです。

今回の言語知新は特別編です。通常回のように独立した5つのトピックを並べるのではなく、 **いま最速とされる正規表現エンジンの設計を起点に、半世紀以上前の源流へと掘り下げていく** 構成にしました。表層には現代のサービスを落とす一行のバグがあり、その下には「39年前に書かれていた答え」を掘り当てた2007年の記事があり、さらに下には`grep`というコマンド名の由来があり、最深部には1968年の論文と1951年の一枚の紙、そしてその名付け親自身が納得していなかった「regular」という語が眠っています。掘り進めながら確かめていきましょう。

---

{{< youtube "0PAAMEVJ-r0" >}}

---

## 1. その一行が、サービスを止める

正規表現には大きく分けて2つの流儀があります。 **オートマトン系（非バックトラッキング）** と **バックトラッキング系** です。この対立が、今回の記事全体を貫く軸になります。オートマトン系は正規表現を有限オートマトン（状態と遷移からなる計算モデル）に変換し、入力を一度だけ走査します。バックトラッキング系は正規表現を再帰的に探索し、失敗したら別の選択肢を試す方式で、後方参照や先読みといった豊かな機能を実装できる代わりに、特定のパターンで爆発的に遅くなることがあります。

その弱点を突く攻撃が ReDoS（Regular Expression Denial of Service）です。`(a+)+` のようにネストした量化子（繰り返しを表す `+` や `*` などの記号）に、意図的にマッチしない入力を与えると、バックトラッキング型のエンジンは指数関数的な数の分割パターンを試みてしまい、事実上処理が終わらなくなります。この種の弱点を「アルゴリズム的複雑性攻撃」として体系立てて示したのが、Crosby と Wallach の [USENIX Security 2003 論文](https://www.usenix.org/conference/12th-usenix-security-symposium/denial-service-algorithmic-complexity-attacks)「Denial of Service via Algorithmic Complexity Attacks」です。ただしこの論文自体は正規表現に限らずハッシュテーブルなども含むアルゴリズム的複雑性攻撃全般を扱ったもので、正規表現を狙う攻撃として広く知られるようになったのは同時期の関連する報告を経てのことでした。

対策はいくつかあります。 **原子グループ** （`(?>...)`、一度マッチした範囲へのバックトラッキングを禁止する記法）や **possessive quantifier** （`a++` のようにバックトラックしない量化子）は、Python では [3.11 で追加](https://docs.python.org/3/library/re.html) されました。それ以前はサードパーティの `regex` モジュールが必要でした。ここで注意したいのは、 **Python の `re` モジュール自体はいまもバックトラッキング型のまま** だということです。「Python 3.11 で ReDoS がなくなった」わけではなく、あくまで危険なパターンを回避する手段が標準ライブラリに追加された、というのが正確な理解です。

そしてもう一つの対策が、そもそもバックトラッキングしないエンジンを使うことです。次の章で見ていくように、この設計は実は目新しいものではありません。

## 2. 最速の答えは39年前にあった

2007年1月、Russ Cox は自身のウェブサイトに [「Regular Expression Matching Can Be Simple And Fast」](https://swtch.com/~rsc/regexp/regexp1.html) という記事を投稿しました。そこで示されたのは衝撃的な数字です。`a?ⁿaⁿ` という形の正規表現に `aⁿ` をマッチさせるテストで、当時主流だった Perl 系のバックトラッキング実装は29文字で60秒以上かかったのに対し、Thompson 方式の NFA（非決定性有限オートマトン）シミュレーションはわずか20マイクロ秒で終わったのです。Cox が指摘したのは、Perl・Python・PHP・Ruby といった主流言語がバックトラッキングを採用する一方で、その30年以上前に書かれていた解法の方が速いという皮肉な状況でした。

その「30年以上前」というのが Ken Thompson の1968年の論文です。1968年から2007年まで、実に **39年** もの間、この線形時間の解法は主流の言語からは顧みられていませんでした。RE2 の作者自身が「再発見」と呼ぶこの経緯こそ、今回のテーマの核心です。

Cox はこの知見を実装に落とし込みます。Google 内で開発された **RE2** は2010年3月にオープンソース化されました。[Cox 自身の解説](https://swtch.com/~rsc/regexp/regexp3.html)によれば、Google Code Search が外部ユーザから任意の正規表現を受け付けるという文脈で、バックトラッキング型の PCRE を使うと「容易にサービス拒否攻撃にさらされる」ことが動機だったといいます。RE2 は DFA と NFA を組み合わせ、線形時間実行と固定スタックフットプリントを保証します。

この設計思想は Rust の `regex` クレートにも受け継がれました。[公式リポジトリ](https://github.com/rust-lang/regex)は「この実装は有限オートマトンを用い、すべての入力に対して線形時間マッチングを保証する」と明記しています。作者の Andrew Gallant（BurntSushi）は自身のブログで、この設計が Russ Cox の RE2 に「強く影響を受けた」ものだと直接述べており、これは思想的な類似ではなく明確な直接影響です。後方参照や先読みが使えない理由についても [Gallant 自身の解説](https://burntsushi.net/regex-internals/) は明快で、「効率的に実装する方法が知られていない」からだと述べています。機能が少ないのではなく、線形時間保証という目標のための意図的な選択なのです。

同じ流れは Go の標準ライブラリ `regexp`（Russ Cox 自身が実装）にも受け継がれ、Go は言語標準ライブラリとして非バックトラッキングエンジンを採用した数少ない主要言語になりました。.NET も **.NET 7** で記号的微分（後の章で触れます）に基づく `RegexOptions.NonBacktracking` を追加しています。ただし注意したいのは、これは **既定のエンジンではなく、開発者が明示的に選択するオプション** だという点です。「.NET 7 で正規表現マッチングが既定で線形時間になった」わけではありません。

もっとも、非バックトラッキング方式であらゆる性能問題が消えるわけでもありません。Turoňová らは USENIX Security 2022 の論文「Counting in Regexes Considered Harmful」で、カウント付きの正規表現が非バックトラッキング照合器にも脆弱性を生じうることを示しています。「RE2 や Rust regex を使えば安全」と単純に言い切ることはできません。

## 3. grepはコマンドの綴りだった

現代の私たちが日常的に打つ `grep` というコマンド名は、実は略語や造語ではありません。UNIX の行指向エディタ `ed` には、正規表現にマッチする行すべてに対しコマンドを実行する `g/re/p`（global / regular expression / print）という操作がありました。 **この `g/re/p` そのものが `grep` の名前の由来** です。

grep の誕生をめぐっては、2つの逸話が伝えられています。Doug McIlroy の『[A Research UNIX Reader](https://www.cs.dartmouth.edu/~doug/reader.pdf)』は「エディタで扱うには大きすぎるファイルの中でパターンを探す方法を Ken Thompson が問われたときに生まれた」と記しています。一方で Thompson 自身は、grep はもともと自分用の「私的なコマンド」であり、それを1時間ほど手直ししたものだと語っています。どちらか一方だけを正史とするのは適切ではなく、両方の証言が並立していると理解すべきでしょう。grep のマニュアルページには「GREP(I) 24 v4 3/3/73」という日付があり、Version 4 Unix（1973年）で登場したことがわかっています。

ここで見落としてはいけないのが、 **当時の grep は BRE（Basic Regular Expression）だった** ということです。`+`・`?`・`|` はただの文字として扱われ、特殊な意味を持ちませんでした。これらを使うには、Alfred Aho による拡張版 `egrep`（1975年頃、UNIX v7 に収録）が必要でした。「grep は最初から Perl のような豊かな正規表現を持っていた」というのは誤りで、機能は段階的に拡張されていったのです。ed から派生した `grep`・`egrep`・`sed`・`awk`・`lex` が UNIX の風景の重要な特徴になっていったのが、1970年代というこの時代でした。

正規表現の文法もまた一枚岩ではありません。POSIX（IEEE Std 1003.2）は BRE と ERE の二形式を規定し、[The Open Group の仕様](https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap09.html)は「各部分式は左から右へ、可能な限り最長の文字列にマッチしなければならない」という **leftmost-longest（最左最長）** 規則を定めています。これは後に主流になる **leftmost-first（最左最先、最初に成功した分岐を採る）** の Perl 流の意味論とは非互換です。同じ正規表現でもエンジンによって結果が変わりうる、という事実は今も意外と知られていません。

こうした豊かな記法の系譜の先頭に立つのが Perl です。Larry Wall による Perl 1 は1987年12月18日にリリースされました。ただし、Perl の正規表現機能拡張の年代には注意が必要です。[公式ドキュメント perlre](https://perldoc.perl.org/perlre) は「`\g` と `\k` 記法は Perl 5.10.0 で導入された」と明記しています。つまり **名前付きキャプチャは Perl 5.10.0（2007年）で導入されたもの** であり、「Perl は最初から名前付きキャプチャを持っていた」というのは誤りです。1986年1月19日には Henry Spencer が正規表現ライブラリを Usenet の mod.sources に投稿していますが、Spencer 自身は「Bell V8 の regexp(3) に触発されたが、ライセンスされたソフトウェアからの派生ではない」と明記しており、 **AT&T のコードを流用したものではありません** 。なお、この1986年版（通称「book regex」）と、後に書かれた 4.4BSD 向けの POSIX.2 準拠版は別物である点にも注意が必要です。

## 4. 147KBの機械

`grep` を生んだ Ken Thompson は、1968年に「Programming Techniques: Regular Expression Search Algorithm」という論文を CACM（Communications of the ACM）11巻6号に発表しました（[DOI: 10.1145/363347.363387](https://dl.acm.org/doi/10.1145/363347.363387)）。抄録には「コンパイラは正規表現を原始言語として受け取り、IBM 7094 プログラムを目的言語として生成する」とあります。つまりこの論文は、 **正規表現を機械語に直接コンパイルする** という発想を示していたのです。

Thompson がこの手法を組み込んだのは、テキストエディタ QED でした。Dennis Ritchie の一次記録「[An incomplete history of the QED Text Editor](https://www.bell-labs.com/usr/dmr/www/qed.html)」によれば、オリジナルの QED は Butler Lampson と Peter Deutsch が Berkeley の SDS 940 向けに書いたもので、そこに正規表現はありませんでした。Thompson が Bell Labs に来る前に Berkeley でこの QED を使い、来所後に MIT の CTSS システム向けに新版を書いた際、文字列を指定する手段として正規表現を導入したのです。これが実装面での正規表現の最初期の実装のひとつになりました。

Thompson が対象とした IBM 7094 は、主記憶が36ビットワード×32,768語という構成のマシンでした。[Russ Cox の IBM 7094 解説](https://swtch.com/~rsc/regexp/ibm7094.html)によれば、これは今日の単位でおよそ **147キロバイト相当** だといいます。ただしこれはあくまで換算による相当値であり、厳密なバイト数として断定的に扱うべきではありません。それでも、今日のスマートフォンの数十万分の一というこの極端な制約の下で、正規表現をその場で機械語にコンパイルして実行するという手法は、現代の JIT（Just-In-Time）コンパイルの先駆と見ることができます。もっとも「JIT」という語自体は当時存在しておらず、これはあくまで思想的な類似として位置づけるべきものです。

理論を機械に落とし込む過程には、いくつもの重要な変換技法が積み重なっています。 **Thompson 構成法** は正規表現を再帰的に部分 NFA へ変換する手法で、現代の RE2・Rust regex の基礎になっています。 **部分集合構成** （Rabin と Scott が [1959年の論文](https://dl.acm.org/doi/10.1147/rd.32.0114)「Finite Automata and Their Decision Problems」で示した、NFA から DFA への変換手法）は、DFA の各状態を「現在ありうる NFA 状態の集合」として構成するもので、この業績で両者は1976年にチューリング賞を受賞しています。n 状態の NFA から最悪 2ⁿ 状態の DFA が生じうる「状態爆発」を避けるため、実用エンジンでは必要な状態だけを遅延生成する lazy DFA が使われます。もう一つ重要なのが Brzozowski が1964年に導入した「微分」という概念で、正規表現 E と文字 a に対し「a を先頭から取り除いた残りにマッチする正規表現」を定めることで、DFA を直接構成できます。この技法は長らく忘れられていましたが、Owens・Reppy・Turon による [2009年の論文](https://www.khoury.northeastern.edu/home/turon/re-deriv.pdf)「Regular-expression derivatives re-examined」が「時の砂に埋もれ、それを知る計算機科学者はほとんどいなかった」と述べつつ、現代の関数型実装で蘇らせました。.NET 7 の NonBacktracking エンジンは、この微分の考え方を記号的に一般化したものです。

## 5. 名付けた本人が納得していない

ここまで実装の系譜（QED → ed → grep → RE2 → Rust regex）を追ってきましたが、実はこれとは別の系統として、理論の系譜があります。 **理論の源流と実装の源流を一つの物語に融合させてはいけません** 。ここが本記事でもっとも慎重に扱いたい箇所です。

理論的な起点として確実に遡れるのは、1943年の McCulloch と Pitts による [「A Logical Calculus of the Ideas Immanent in Nervous Activity」](https://link.springer.com/article/10.1007/BF02478259) です。彼らは神経の「全か無か」の発火を命題論理の真偽に対応させ、神経ネットが計算する対象を形式的に扱う道を開きました。ただし彼ら自身は「正規表現」も「正則事象」も定義していません。

決定的な一歩を踏み出したのは Stephen Cole Kleene です。1951年夏、RAND 研究所で行った仕事の要旨は「McCulloch-Pitts の神経ネットはどんな種類の事象に発火で応答できるか」と問うところから始まります（[RAND Research Memorandum RM-704](https://www.rand.org/pubs/research_memoranda/RM704.html)、Automata Studies 所収は1956年）。Kleene はここで「 **正則事象（regular events）** 」という概念と、0回以上の反復を表すスター演算を導入しました。これが今日「Kleene スター」「Kleene 閉包」と呼ばれるものの起源ですが、この呼称自体は後世につけられたもので、Kleene 自身がそう名付けたわけではありません。

面白いのは、Kleene 自身がこの「regular」という語にあまり確信を持っていなかったらしいことです。この一節はしばしば「より記述的な用語の提案があれば歓迎する」という英語の引用として紹介されますが、本記事ではこの verbatim（一語一句）の逐語引用を確定的に掲げることは避けます。というのも、一次資料の PDF 上で当該の一文そのものを頁付きで確認しきれていないためです。ただし RM-704 の6頁付近には、同趣旨の「本稿は作業論文にすぎないので、用語の改善に関する提案を歓迎する」という一文が実在することは確認できています。つまり、 **Kleene は「regular」という語を暫定的なものと考え、より良い代替を募っていた** という趣旨は裏付けられる一方、その正確な逐語引用の出典頁までは確定できていない、というのが正確な位置づけです。名付けた本人が、自分でつけた名前にどこか納得していなかった——それがこの語の出発点だったのです。

理論の系譜はここでは終わりません。McCulloch-Pitts のニューロンモデルという「最深部」から出発し、Kleene の正則事象を経て、Rabin と Scott の部分集合構成、Brzozowski の微分へとつながっていきます。そして、正規表現の等式的な性質を代数として公理化する試みも続きました。「Kleene algebra」という語自体の初出は Conway による1971年の著作とされ、Kleene 自身が名付けたものではありません。Dexter Kozen が1994年にその健全かつ完全な公理化を与え、1997年には Kleene Algebra with Tests（KAT）へと発展させています。

一方、実装の系譜は先ほど見た通り、Thompson の QED（CTSS 版、1960年代半ば）に始まります。 **理論の源流（Kleene）と実装の源流（QED/ed）が交差したのは、Thompson の1968年の CACM 論文においてでした。** どちらが「唯一絶対の最古」かという問いには慎重であるべきです。正則言語に近いアイデアは、Moore・Mealy・Huffman らの逐次回路理論など複数の系統で並行して現れており、Kleene の仕事もその文脈の一部だったからです。

## まとめ

現代に戻ってきましょう。「正規表現は正則言語しか表せない」という命題は、理論的な意味での正規表現には正しい主張です。しかし現代の実用正規表現、とりわけ後方参照 `\1` を持つ PCRE や Perl 系の記法には、この命題は当てはまりません。後方参照は「同じ部分列の反復」という、有限の状態では記憶しきれない情報を要求するため、正則言語の枠を超えています。後方参照付きマッチングは一般に NP困難だとされており、Russ Cox が明快に述べるように、理論的な用語としては「後方参照を持つ正規表現はもはや正規表現ではない」のです。なお先読み・後読み（lookaround）は、正則言語が交差・補集合で閉じているという性質のおかげで、実は正則言語の範囲を超えません。正則を超えるのは、あくまで後方参照の方なのです。

それでも、後方参照を採用する設計には合理性があります。同じ引用符の対応や重複語の検出など、後方参照でしか簡潔に書けないタスクは実務に存在します。ユーザ入力を受け付けない、開発者自身が書く一回限りのスクリプトのような文脈では、表現力の高さが安全性の懸念より勝ることもあります。設計判断は「誰が正規表現を書くか」に依存するのです。RE2 が後方参照を捨てたのは、Google Code Search が外部ユーザから任意の正規表現を受け取るという特殊な文脈だったからで、機能の欠落ではなく意図的な選択でした。

正規表現の理論はさらに別の方向へも展開しています。Kleene 代数と KAT は、正規表現を「プログラムの等式的推論」の道具へと押し上げました。NetKAT（POPL 2014）はこれをネットワーク構成の検証に応用し、到達可能性やループの不在といった性質を等式論理で判定します。マッチングのための道具として生まれた記法が、証明のための代数へと姿を変えている——この広がりもまた、Kleene が1951年に一枚の紙の上で始めたことの延長線上にあります。

いま最速とされる正規表現エンジンは、新しく発明されたものではありませんでした。半世紀近く前に書かれ、一度は忘れられていた紙——1968年の Thompson の論文と、1951年の Kleene の RM-704——を、2007年に誰かが掘り返して作られたものです。次に `grep` や正規表現のリテラルを書くとき、その一行の奥に眠る地層のことを、少しだけ思い出してもらえたら嬉しいです。

## 参考リンク

- [Regular Expression Matching Can Be Simple And Fast (Russ Cox, 2007)](https://swtch.com/~rsc/regexp/regexp1.html)
- [Regular Expression Matching in the Wild (Russ Cox, RE2解説)](https://swtch.com/~rsc/regexp/regexp3.html)
- [IBM 7094 Cheat Sheet (Russ Cox)](https://swtch.com/~rsc/regexp/ibm7094.html)
- [GitHub - rust-lang/regex](https://github.com/rust-lang/regex)
- [Regex engine internals as a library (Andrew Gallant)](https://burntsushi.net/regex-internals/)
- [Denial of Service via Algorithmic Complexity Attacks (Crosby & Wallach, USENIX Security 2003)](https://www.usenix.org/conference/12th-usenix-security-symposium/denial-service-algorithmic-complexity-attacks)
- [re — Regular expression operations (Python公式)](https://docs.python.org/3/library/re.html)
- [perlre - Perl regular expressions (Perldoc)](https://perldoc.perl.org/perlre)
- [Regular Expressions (The Open Group, POSIX)](https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap09.html)
- [A Research UNIX Reader (Doug McIlroy)](https://www.cs.dartmouth.edu/~doug/reader.pdf)
- [regexp(3) 投稿 (Henry Spencer, mod.sources, 1986)](https://groups.google.com/g/mod.sources/c/OqVZYQNSmDs)
- [Programming Techniques: Regular Expression Search Algorithm (Ken Thompson, CACM 1968)](https://dl.acm.org/doi/10.1145/363347.363387)
- [An incomplete history of the QED Text Editor (Dennis Ritchie)](https://www.bell-labs.com/usr/dmr/www/qed.html)
- [Finite Automata and Their Decision Problems (Rabin & Scott, 1959)](https://dl.acm.org/doi/10.1147/rd.32.0114)
- [Regular-expression derivatives re-examined (Owens, Reppy, Turon, 2009)](https://www.khoury.northeastern.edu/home/turon/re-deriv.pdf)
- [Representation of Events in Nerve Nets and Finite Automata (Kleene, RAND RM-704, 1951)](https://www.rand.org/pubs/research_memoranda/RM704.html)
- [A Logical Calculus of the Ideas Immanent in Nervous Activity (McCulloch & Pitts, 1943)](https://link.springer.com/article/10.1007/BF02478259)
