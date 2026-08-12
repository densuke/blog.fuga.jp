---
title: "半世紀前の「授業用言語」が、いまのC#やTypeScriptにつながっている話 — Pascal"
date: 2026-08-13T00:00:00+09:00
draft: true
tags: ["Pascal", "Niklaus Wirth", "Turbo Pascal", "Delphi", "Free Pascal", "プログラミング言語の歴史"]
categories: ["小ネタ・Tips"]
---

# 半世紀前の「授業用言語」が、いまのC#やTypeScriptにつながっている話 — Pascal

## 導入 (Introduction)

「名前は聞いたことがあるけど、触ったことはない」。そんな言語ってありませんか。Pascal はまさにその代表格かもしれません。1970年に生まれた、大学の授業のための言語。なのに、その血筋をたどると、いま多くの人が毎日使っている C# や TypeScript にまでつながっています。今日はそんな Pascal を、ショート動画の紹介をきっかけに少し掘り下げてみます。

{{< youtube "lzEUxYzBAM0" >}}

## 本論 (Body)

## 1. 「きちんと書けば、きちんと動く」を教えるための言語

Pascal を作ったのは、スイスの[ニクラウス・ヴィルト](https://inf.ethz.ch/department/history/people.html)。1968年から1999年までチューリッヒ工科大学（ETH Zurich）の教授を務めた人物です。ETH Zurich の公式ページによれば、ヴィルトは ALGOL W という言語を拡張する形で Pascal を設計し、[「Pascal は1970年に発表され、今日に至るまで国際的に認知され使われ続けている」](https://inf.ethz.ch/department/history/people.html)と紹介されています。

名前の由来は、動画でも触れられていたとおり、17世紀に機械式計算機「パスカリーヌ」を作ったブレーズ・パスカルです。ヴィルトが Pascal に込めた目的は明快で、構造化プログラミングというアイデアを、学生にきちんと教えられる形にすることでした。この功績により、ヴィルトは1984年に[ACMチューリング賞](https://computerhistory.org/profile/niklaus-wirth/)を受賞しています。

「行儀よく書けば、コンパイラがちゃんと守ってくれる」。型に厳しく、構文があいまいさを許さない Pascal のこの性質は、初学者に「プログラムは書き方次第で信頼できるものになる」という感覚を植え付けるための、いわば教材としての設計思想でした。

## 2. 関数名に代入する、ピリオドで終わる — 動画で紹介されたコードの意味

動画の概要欄には、実際に動くコード例が載っていました。

```pascal
program Demo;
function Fib(n: Integer): Integer;
begin
  if n < 2 then Fib := n
  else Fib := Fib(n-1) + Fib(n-2);
end;
begin
  WriteLn('Hello, World!');
  WriteLn(Fib(10));
end.
```

C言語や多くの現代的な言語に慣れていると、2箇所で戸惑うはずです。ひとつは、`return` ではなく関数名そのものに値を代入して戻り値にすること。もうひとつは、プログラム全体の末尾が `;`（セミコロン）ではなく `.`（ピリオド）で終わること。

これは奇をてらった仕様ではなく、[プログラム全体を締めくくる `end` の直後にピリオドを置くことで、コンパイラにファイルの終端を伝える](https://www.getlazarus.org/learn/courseware/101/day2/)という、Pascal の言語仕様そのものです。英語の文章がピリオドで終わるように、Pascal のプログラムもピリオドで締めくくられる。正直、最初にこの仕様を知ったときは「そこまでやるか」と思いましたが、慣れてくると「プログラムという文章がちゃんと終わった」感じがして、地味に気持ちがいいです。動画内でも「英語の文章みたいで読みやすい」というやり取りがありましたが、これは偶然ではなく、ヴィルトが読みやすさを言語仕様のレベルで狙っていたことの現れです。

## 3. 教育用から現場へ — UCSD Pascal と、ポータブルという発想

Pascal はもともと教育目的で設計されましたが、1970年代後半には現場の言語としても広がり始めます。そのきっかけの一つが、[UCSD Pascal](https://en.wikipedia.org/wiki/UCSD_Pascal) です。カリフォルニア大学サンディエゴ校の Kenneth Bowles が1974年ごろから開発し、1977年8月に公開したこのシステムは、「p-code」と呼ばれる中間コードにコンパイルすることで、異なる機種のマイコンや DEC PDP-11 でも同じプログラムを動かせるようにした、当時としては先進的な「移植性」の実装でした。

このUCSD Pascalは、Apple II 向けに[ライセンスされて Apple Pascal となりました](https://en.wikipedia.org/wiki/UCSD_Pascal)。「一度書けばどこでも動く」というp-codeの発想は、後の Java や Ada にも引き継がれていくことになります。教育用に生まれた言語が、実際の製品開発の現場にまで染み出していった最初の一歩でした。

## 4. Turbo Pascal から Delphi、そして C# と TypeScript へ

動画でも触れられていた Anders Hejlsberg の名前は、Pascal の系譜を語る上で欠かせません。彼は自作の Pascal コンパイラを CP/M・MS-DOS 向けに書き直し、最初は「Compas Pascal」、続いて[「PolyPascal」という名前で販売していました](https://en.wikipedia.org/wiki/Anders_Hejlsberg)。これをライセンスした Borland 社が[1983年11月に発売したのが Turbo Pascal](https://blogs.embarcadero.com/turbo-pascal-turns-40/) です。競合コンパイラが500ドル前後した時代に49.95ドルという価格で、多くの独学プログラマの入り口になったと言われています。

Hejlsberg はその後 [Borland で Delphi 開発チームのチーフアーキテクトを務め](https://en.wikipedia.org/wiki/Anders_Hejlsberg)、1996年に Microsoft へ移籍。[2000年から C# の主任アーキテクト](https://en.wikipedia.org/wiki/Anders_Hejlsberg)を務め、[2012年には TypeScript を発表しました](https://en.wikipedia.org/wiki/Anders_Hejlsberg)。Turbo Pascal を書いた本人が、40年以上経ったいまも第一線で言語設計に携わっているというのは、なかなか他に類を見ない話です。半世紀前に「授業のための言語」として生まれた設計思想が、形を変えながら現代の主要言語にまで流れ込んでいるわけです。

## 5. いまも動かせる — Free Pascal と Lazarus

Pascal は歴史上の存在ではありません。動画の説明欄にもあったとおり、[Free Pascal](https://www.freepascal.org/) というオープンソースの処理系が今も開発が続いており、`brew install fpc`（macOS）や `apt install fpc`（Linux）で手元にすぐ入れられます。GUIアプリケーションを組みたい場合は、統合開発環境の [Lazarus](https://www.lazarus-ide.org/) が便利です。商用処理系としては [Embarcadero Delphi](https://www.embarcadero.com/products/delphi) が現在も開発・販売されています。

半世紀前に「きちんと書けば、きちんと動く」ことを教えるために作られた言語が、令和のいまも `brew install` の一行で試せる。これは地味に驚くべきことだと思います。

## まとめ (Conclusion)

Pascal は、教育のために生まれ、UCSD Pascal を経て現場に広がり、Turbo Pascal・Delphi を経由して、C# や TypeScript という現代の主力言語にまでその設計思想を伝えています。「名前は知っているけど触ったことがない」という方は、Free Pascal を一つ入れて、動画のコードを実際に動かしてみるところから始めてみてはどうでしょうか。`fpc demo.pas && ./demo` の一行で、半世紀前の言語がいまも現役で動く様子を体感できます。

みなさんは「関数名に代入して戻り値にする」派と「`return` で明示的に返す」派、どちらがしっくりきますか。半世紀の時を経ても、この手の好みは意外と分かれる気がしています。

---

## 参考リンク
- [Free Pascal 公式サイト](https://www.freepascal.org/)
- [Lazarus 公式サイト](https://www.lazarus-ide.org/)
- [Embarcadero Delphi 公式サイト](https://www.embarcadero.com/products/delphi)
- [ETH Zurich: People who shaped the department（Niklaus Wirth）](https://inf.ethz.ch/department/history/people.html)
- [Computer History Museum: Niklaus Wirth](https://computerhistory.org/profile/niklaus-wirth/)
- [UCSD Pascal - Wikipedia](https://en.wikipedia.org/wiki/UCSD_Pascal)
