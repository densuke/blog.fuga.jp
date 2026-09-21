---
title: "COBOL を手元で動かす — 0.1 + 0.2 が正確に 0.3 になる十進演算を GnuCOBOL で確かめる（古今東西プログラミング言語紹介 実践編）"
date: 2026-09-22T00:00:00+09:00
draft: false
tags: ["古今東西プログラミング言語紹介", "COBOL", "GnuCOBOL", "十進演算", "実践編"]
categories: ["小ネタ・Tips"]
---

{{< youtube "APSv_t7tR_Q" >}}

この記事は、動画の書き起こしではなく、動画の元になった実験環境を軸にした実践編です。読み終えると、コンテナ1つで GnuCOBOL 3.2.0 の環境に入り、COBOL の Hello World、金額の桁編集、そして「同じ 0.1 + 0.2 が十進と二進で違う答えになる」対比までを、手元のコマンド数本で再現できるようになります。

## はじめに

COBOL は名前を聞いたことがあっても、実際にコンパイルして動かした人は多くないはずです。古い言語だから資料館で眺めるもの、という扱いになりがちですが、いまは [GnuCOBOL](https://gnucobol.sourceforge.io/) という自由なコンパイラがあり、Debian の `apt` で入るので、試すこと自体は難しくありません。

この記事の結論を先に置きます。COBOL の面白さは構文の古さではなく、 **金額を扱うための機能が言語の側に入っている** ことです。桁を型として書く `PIC` 句と、十進で計算する演算がその中心にあり、後者は二進浮動小数点との対比を1本のプログラムで見られます。

## 1. 環境を用意する

実験環境は [lang-playground リポジトリの 20260922-COBOL ディレクトリ](https://github.com/densuke/lang-playground/tree/main/20260922-COBOL) にまとまっています。処理系は **GnuCOBOL 3.2.0** で、Debian trixie の `apt` で入ります。Dockerfile は `debian:trixie-slim` を土台に `gnucobol` パッケージを入れるだけの構成です。

```text
$ ./run.sh cobc --version
cobc (GnuCOBOL) 3.2.0
Copyright (C) 2023 Free Software Foundation, Inc.
```

ライセンスは、コンパイラ本体が GPLv3、ランタイムライブラリが LGPLv3 です。公式サイトは `gnucobol.sourceforge.io` にあります。

リポジトリの中身は小さく、読むべきファイルは次の4種類に絞れます。

| ファイル | 内容 |
|---|---|
| `Dockerfile` | `debian:trixie-slim` に `gnucobol` を入れるだけの環境定義 |
| `run.sh` | コンテナランタイムを探してイメージをビルドし、コンテナを起動する入口 |
| `demo/*.cob` | この記事で動かす3本のプログラム（`basics` / `decimal` / `freeform`） |
| `demo/demo.sh` / `demo/demo-feature.sh` | 動画で流した手順を並べた補助スクリプト |

1コマンドで環境に入る入口が `run.sh` です。`container`（macOS 26 の Apple container）、`docker`、`podman` のいずれかがあれば動きます。引数なしで実行するとコンテナ内のシェルに入り、リポジトリの `demo` ディレクトリがコンテナの `/work` にマウントされます。

```text
$ ./run.sh
```

`run.sh` は実行のたびにイメージをビルドしますが、成功したときはログを出さず、失敗したときだけ標準エラーへ出力します。以降の実行結果はすべて、この節の環境（GnuCOBOL 3.2.0 / Debian trixie）で得られたものとして、リポジトリの README に記録されている出力をそのまま載せています。

## 2. まず動かす

最初の1本は `demo/basics.cob` です。Hello World に、金額の計算と表示を足した構成になっています。

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BASICS.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PRICE    PIC 9(5)V99 VALUE 1980.50.
       01  WS-QTY      PIC 9(3)    VALUE 3.
       01  WS-TOTAL    PIC 9(7)V99 VALUE ZERO.
       01  WS-PRINT    PIC ZZZ,ZZZ.99.
       PROCEDURE DIVISION.
           DISPLAY "Hello, World!".
           COMPUTE WS-TOTAL = WS-PRICE * WS-QTY.
           DISPLAY "RAW   : " WS-TOTAL.
           MOVE WS-TOTAL TO WS-PRINT.
           DISPLAY "GOKEI : " WS-PRINT.
           STOP RUN.
```

再現手順は次の1行です。`cobc -x` が実行ファイルを作り、それを `/work` の中で実行します。

```text
$ ./run.sh bash -c 'cobc -x /work/basics.cob && cd /work && ./basics'
Hello, World!
RAW   : 0005941.50
GOKEI :   5,941.50
```

対応関係を書いておきます。`DISPLAY "Hello, World!"` が1行目、`WS-TOTAL`（`PIC 9(7)V99`）をそのまま表示したのが `RAW` の行、それを表示用の `WS-PRINT`（`PIC ZZZ,ZZZ.99`）に `MOVE` してから表示したのが `GOKEI` の行です。1980.50 × 3 = 5941.50 が、生の値では先頭ゼロ付きのまま、表示用ではカンマ付きで出ています。

コードを1行ずつ読むと、次のようになります。

- `WS-PRICE` は `PIC 9(5)V99` で、初期値は `VALUE 1980.50` です。整数5桁と小数2桁を持ちます
- `WS-QTY` は `PIC 9(3)` で、初期値は `VALUE 3` です
- `WS-TOTAL` は `PIC 9(7)V99` で、初期値は `VALUE ZERO` です。計算結果を受ける入れ物です
- `WS-PRINT` は `PIC ZZZ,ZZZ.99` で、値を持たない表示専用の編集項目です
- `COMPUTE WS-TOTAL = WS-PRICE * WS-QTY.` が計算、`STOP RUN.` がプログラムの終了です

文の終わりにはピリオドが付きます。COBOL では、データを宣言する DATA DIVISION と、処理を書く PROCEDURE DIVISION が分かれているので、「何を入れる箱か」と「何をするか」を別々に読めます。

動画の前半で流した順序を、そのまま追うこともできます。`demo/demo.sh` は次の4ステップを順に実行するスクリプトです。

```text
$ ./run.sh bash /work/demo.sh
```

中身は `cobc --version | head -2`、`sed -n '5,8p' basics.cob`（`PIC` 句の並んだ5〜8行目を表示）、`cobc -x basics.cob`、`./basics` の順です。各ステップの前後には待ち時間が入っているので、動画向けに間を取ったスクリプトだと考えてください。

処理系のコンパイル方法は [GnuCOBOL の公式ドキュメント](https://gnucobol.sourceforge.io/doc/gnucobol.html) にまとまっています。この記事で使うのは、実行ファイルを作る `cobc -x` と、後の章で使う `-free` の2つだけです。

## 3. 言語の骨格

`basics.cob` を上から見ると、COBOL はプログラムを **DIVISION（部）** に分けて書く言語だと分かります。役割は次のとおりです。

| DIVISION | 役割 | basics.cob での有無 |
|---|---|---|
| IDENTIFICATION | プログラム名などの識別情報 | あり（`PROGRAM-ID. BASICS.`） |
| ENVIRONMENT | 動かす計算機やファイルの環境 | 使っていない |
| DATA | 使うデータの定義 | あり（`WORKING-STORAGE SECTION.` 以下） |
| PROCEDURE | 実際の処理 | あり（`DISPLAY` `COMPUTE` `MOVE` `STOP RUN`） |

この記事のプログラムは、どれも ENVIRONMENT DIVISION を省いた3部構成です。各 DIVISION の詳しい書き方は、GnuCOBOL の[公式ドキュメント](https://gnucobol.sourceforge.io/doc/gnucobol.html)を参照してください。

データの定義は `PIC` 句で桁を型として書きます。`PIC 9(5)V99` は整数5桁と小数2桁で、`V` は小数点の位置を示す記号です。`PIC ZZZ,ZZZ.99` は表示用の編集項目で、桁区切りのカンマが自動で入り、先頭のゼロが空白になります。`01` で始まる行はデータ項目の宣言で、`WORKING-STORAGE SECTION.` の下に並びます。`basics.cob` の4つの項目は、どれも `01` の階層番号を持っています。

もう1つ、目に見える作法が **桁位置** です。`basics.cob` の各行は、行頭に空白が並んでいます。COBOL は 80 桁のパンチカードが出発点で、何桁目に何を書くかが決まっています。1-6 桁目が通し番号、7 桁目が標識、8-11 桁目が Area A、12-72 桁目が Area B です。`IDENTIFICATION DIVISION.` や `01` が 8 桁目から始まり、`DISPLAY` などの文が 12 桁目から始まっているのは、この桁割りに従っているためです。GnuCOBOL の既定はこの固定形式なので、コードをコピーするときはインデントを崩さないようにしてください。

桁を気にせず書ける形式が別にあり、それは第5章で試します。

## 4. 見せ場 — 十進演算と二進浮動小数点の対比

この記事でいちばん見てほしい場所です。`demo/decimal.cob` は、同じ 0.1 + 0.2 を2通りの方法で計算します。

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DECIMAL-TEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-A    PIC 9V9(18) VALUE 0.1.
       01  WS-B    PIC 9V9(18) VALUE 0.2.
       01  WS-SUM  PIC 9V9(18) VALUE ZERO.
       01  WS-FA   USAGE COMP-2 VALUE 0.1.
       01  WS-FB   USAGE COMP-2 VALUE 0.2.
       01  WS-FSUM USAGE COMP-2 VALUE ZERO.
       01  WS-SHOW PIC 9V9(18).
       PROCEDURE DIVISION.
           COMPUTE WS-SUM = WS-A + WS-B.
           DISPLAY "COBOL 10進 : " WS-SUM.
           COMPUTE WS-FSUM = WS-FA + WS-FB.
           MOVE WS-FSUM TO WS-SHOW.
           DISPLAY "2進浮動小数: " WS-SHOW.
           STOP RUN.
```

`PIC 9V9(18)` は整数1桁・小数18桁の十進の項目で、`WS-A` `WS-B` `WS-SUM` がこれです。`USAGE COMP-2` は二進倍精度で、`WS-FA` `WS-FB` `WS-FSUM` がこれです。前半の `COMPUTE WS-SUM = WS-A + WS-B` が十進の足し算、後半の `COMPUTE WS-FSUM = WS-FA + WS-FB` が二進の足し算で、二進の結果は18桁の表示用項目 `WS-SHOW` に `MOVE` してから表示しています。

7つの項目を整理しておきます。

| 項目 | 型 | 役割 |
|---|---|---|
| `WS-A` / `WS-B` | `PIC 9V9(18)`（十進） | 0.1 と 0.2 |
| `WS-SUM` | `PIC 9V9(18)`（十進） | 十進の足し算の結果 |
| `WS-FA` / `WS-FB` | `USAGE COMP-2`（二進倍精度） | 0.1 と 0.2 |
| `WS-FSUM` | `USAGE COMP-2`（二進倍精度） | 二進の足し算の結果 |
| `WS-SHOW` | `PIC 9V9(18)` | 二進の結果を18桁で表示するための項目 |

比較が公平になるように、どちらも `VALUE 0.1` と `VALUE 0.2` という同じ初期値から始めています。違うのは型だけです。

再現手順と結果は次のとおりです。

```text
$ ./run.sh bash -c 'cobc -x /work/decimal.cob && cd /work && ./decimal'
COBOL 10進 : 0.300000000000000000
2進浮動小数: 0.299999999999999933
```

1行目が `PIC 9V9(18)` の十進、2行目が `USAGE COMP-2` の二進倍精度の結果です。同じプログラムの中で同じ 0.1 + 0.2 を計算させて、GnuCOBOL 3.2.0 では **十進は正確に 0.3 になり** 、二進は 0.299999999999999933 と表示されました。

動画の後半で流した手順も、`demo/demo-feature.sh` として残っています。`grep -n 'WS-A \|WS-FA ' decimal.cob` で十進と二進の宣言を並べて見せ、`cobc -x decimal.cob` でコンパイルし、`grep -n 'COMPUTE' decimal.cob` で2つの計算式を見せてから `./decimal` を実行する、という順序です。

```text
$ ./run.sh bash /work/demo-feature.sh
```

なぜこうなるのか。二進浮動小数点では、多くの十進の分数を正確に表すことができず、近似値が格納されます。これは COBOL に固有の事情ではなく、二進浮動小数点を使う言語に共通の性質で、Python 公式チュートリアルの[Floating-Point Arithmetic: Issues and Limitations](https://docs.python.org/3/tutorial/floatingpoint.html) でも同じことが説明されています。0.1 も 0.2 も十進では有限の桁数ですが、二進では有限の桁で表せないため、二進浮動小数点の型を選んだ時点で近似値になります。金額を扱う用途では、十進のまま計算できることがそのまま利点になります。

ここで注意したいのは、この記事が示しているのは「GnuCOBOL 3.2.0 でこの2つの項目を使ったとき」の結果だという点です。二進側の 0.299999999999999933 は、リポジトリの README が記録している実行環境で得られた出力です。`COMPUTE` で足した結果を `PIC 9V9(18)` の `WS-SHOW` に `MOVE` して表示したものでもあるため、末尾の桁がこの値になる原因をここで断定することはしません。ここで確かめられるのは、`PIC` 句の十進側と `USAGE COMP-2` の二進側とで結果が食い違う、という事実までです。COBOL の側に「金額の計算を十進で行う型」が用意されている、というのがこの対比の意味です。

## 5. もう一歩 — 自由形式と 88 レベル

第3章の桁位置は、`-free` オプションで外せます。`demo/freeform.cob` は、行頭から書き始められる自由形式で書かれています。

```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. FREEFORM.
DATA DIVISION.
WORKING-STORAGE SECTION.
01 WS-AGE PIC 9(3) VALUE 20.
   88 ADULT VALUE 18 THRU 199.
   88 CHILD VALUE 0 THRU 17.
PROCEDURE DIVISION.
    IF ADULT THEN DISPLAY "ADULT" END-IF.
    MOVE 10 TO WS-AGE.
    IF CHILD THEN DISPLAY "CHILD" END-IF.
    STOP RUN.
```

`cobc` の `-free` オプションは、GnuCOBOL の[公式ドキュメント](https://gnucobol.sourceforge.io/doc/gnucobol.html)にある自由形式の指定です。固定形式のときとの違いは、`IDENTIFICATION DIVISION.` も `01 WS-AGE` も行頭から書けることです。

コンパイルのときだけ `-free` を足します。

```text
$ ./run.sh bash -c 'cobc -x -free /work/freeform.cob && cd /work && ./freeform'
ADULT
CHILD
```

`WS-AGE` の値は最初 20 で、`88 ADULT VALUE 18 THRU 199` の範囲に入るので `IF ADULT` が真になり、1行目の `ADULT` が出ます。その後 `MOVE 10 TO WS-AGE` で 10 に書き換えると、今度は `88 CHILD VALUE 0 THRU 17` の範囲に入るので `IF CHILD` が真になり、2行目の `CHILD` が出ます。

`88` で始まる行は **条件名** です。`IF ADULT` のように、値の範囲に名前を付けて条件式として書けます。条件名は値を格納するための項目ではなく、親の項目 `WS-AGE` の値を見て真偽が決まります。`IF WS-AGE >= 18` と書く代わりに `ADULT` と書ける、というのは、読みやすさを優先した設計に見えます。

固定形式と自由形式の切り替えは、`cobc` のオプション1つです。同じ処理系のなかで両方の書き方が試せるので、桁位置の作法を確かめたいときは `basics.cob` と `freeform.cob` を見比べるのが早いです。自由形式がいつ規格に入ったかは、次の章で触れます。

## 6. 背景と現在地

ここまでは実行結果で裏が取れる話でした。この章にはそうでない話、つまり由来と規格をまとめます。

COBOL は **CO**mmon **B**usiness-**O**riented **L**anguage の頭字語で、事務処理向けの共通言語という用途がそのまま名前になっています（[Wikipedia の COBOL の項](https://en.wikipedia.org/wiki/COBOL) による）。1959年5月28日から29日にかけて、そうした共通言語を作るための会合がペンタゴンで開かれ、この活動はのちに CODASYL（Committee on Data Systems Languages）と名付けられたとされます。仕様は1960年1月8日に執行委員会で承認され、COBOL 60 として印刷されたと伝えられています。

仕様を設計したのは CODASYL の短期委員会で、[Jean Sammet](https://en.wikipedia.org/wiki/Jean_E._Sammet) らが初期仕様を共同設計した、とされます。Grace Hopper は、その土台の一つになったとされる [FLOW-MATIC](https://en.wikipedia.org/wiki/FLOW-MATIC) を作った人で、COBOL の開発には技術顧問として関わりました。仕様そのものの作者ではありません。COBOL を作った当事者の講演録が [Computer History Museum に公開](https://archive.computerhistory.org/resources/access/text/2017/10/102639620-05-01-acc.pdf) されており、そこには、Hopper が Bob Bemer とともに委員会へ助言した2人のアドバイザーの1人だったという証言や、決定の遅さに苛立った委員が「COBOL」と彫った墓石をペンタゴンへ送りつけた話が語られています。

規格の更新はいまも続いていて、最新は [ISO/IEC 1989:2023](https://webstore.iec.ch/en/publication/82522)（2023年1月31日発行）です。第5章で試した自由形式は、COBOL 2002 の規格から入ったとされます。

適用分野は、銀行・保険・行政の基幹業務だとされます。後の言語への影響としては、`01` や `05` の階層番号でデータを構造化する考え方が構造体やレコード型に通じ、十進演算を使う設計が decimal 型に通じるとされます。ただし、これは系譜としてそう語られているという範囲の話で、実行結果のように確かめたわけではありません。

## まとめ

コンテナ1つで GnuCOBOL 3.2.0 に入り、`cobc -x` で3本のプログラムを動かしました。`PIC` 句による桁の定義と編集項目、十進と二進で同じ 0.1 + 0.2 が違う答えになる対比、そして固定形式と自由形式、条件名の 88 レベルです。COBOL は古いからではなく、金額を扱うための機能が言語に入っていることで、いまも試す価値があります。

次に読むなら、[GnuCOBOL の公式ドキュメント](https://gnucobol.sourceforge.io/doc/gnucobol.html) が入口です。コードは `lang-playground` の `20260922-COBOL` にあるので、`decimal.cob` の桁数や型を変えて、結果がどう動くか試してみてください。

## 参考リンク

- [GnuCOBOL 公式サイト](https://gnucobol.sourceforge.io/)
- [実験環境（lang-playground 20260922-COBOL）](https://github.com/densuke/lang-playground/tree/main/20260922-COBOL)
- [ISO/IEC 1989:2023](https://webstore.iec.ch/en/publication/82522)
- [Computer History Museum 講演録（PDF）](https://archive.computerhistory.org/resources/access/text/2017/10/102639620-05-01-acc.pdf)
