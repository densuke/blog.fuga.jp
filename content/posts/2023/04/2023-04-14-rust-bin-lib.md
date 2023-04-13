---
layout: post
title:  "Rustでクレートを混ぜ込む話"
date:   2023-04-14 05:53:05 +0900
categories: Develop
tags: [Rust, クレート, お勉強]
---
RustとTauriでGUI付きDockerのステータスを表示したりするアプリを作ってみてる件、ちまちまと検証しながら進めているのですが、
`main.rs` が膨らんでくるとやっぱり「あぁDocker関連のコードを分離したい」となってきます。
そういう時にどうすればいいのか、ちょっとやってみてました。キットもっと楽な方法があるはずなのですが、今の私の知見です。

# 単純に切り出す

* 切り出す
* `mod` 指示でインポートする

例えば元コードがこんな感じ。

```Rust
fn hoge() -> String {
    "hogehoge".to_string()
}

fn main() {
    println!("{}", hoge());
}
```

ここから `hoge()` を切り出したければ、まずは単純に切り出してみます。
`hoge.rs`を作成してお引っ越し

```file:hoge.rs
// hoge.rs
fn hoge() -> String {
    "hogehoge".to_string()
}
```

これを`main.rs`から読み込ませてみるのは、 `mod` キーワードでファイル名を渡してモジュールとして認識させることができます。

```file:main.rs
mod hoge; // hoge.rsを取り込む(モジュールとして)

fn main() {
    println!("{}", hoge::hoge());
}
```

でもこれはエラーになります。

```
❯ cargo check
    Checking libkiridashi v0.1.0 (/private/tmp/libkiridashi)
error[E0603]: function `hoge` is private
 --> src/main.rs:5:26
  |
5 |     println!("{}", hoge::hoge());
  |                          ^^^^ private function
  |
note: the function `hoge` is defined here
 --> src/hoge.rs:1:1
  |
1 | fn hoge() -> String {
  | ^^^^^^^^^^^^^^^^^^^

For more information about this error, try `rustc --explain E0603`.
```

さすがRust、エラーの詳しさが光ってます。

<img align="right" width="120px" src="https://i-ogp.pximg.net/c/540x540_70/img-master/img/2010/01/19/14/10/21/8272671_p0_square1200.jpg">
実はRustのモジュールやライブラリなど、切り出した場合の共有度合いはプライベート(private)だったりします。
「見せられないよ!」です。

ということで、晒してかまわない子は`pub`で見せてあげましょう。

```file:hoge.rs
// hoge.rs
pub fn hoge() -> String { // pub付けて公開
    "hogehoge".to_string()
}
```

これで動きます。
この方法でやるのが単一アプリの中での切り出しとしてはやりやすいですね。

# ライブラリクレート

バイナリクレートではなくライブラリクレートとして切り出すことで、より分離度が増して良い感じになると思います。
ただこうなると再利用性とかまで考慮しないといけなくなるのでいくぶん面倒かもしれません。

バイナリクレートではありますが、トップディレクトリでライブラリクレートを作って入れ子にしちゃいます。

```zsh
% cd /tmp/libkiridashi # 酷い名前だ
% ls -l
total 16
-rw-r--r--@ 1 densuke  wheel  156  4 14 06:13 Cargo.lock
-rw-r--r--@ 1 densuke  wheel  182  4 14 06:13 Cargo.toml
drwxr-xr-x@ 4 densuke  wheel  128  4 14 05:55 src
```

こんな所ですが作ってしまいます。

```zsh
% cargo new --lib kiri
     Created library `kiri` package
% ls -l # トップディレクトリ
total 16
-rw-r--r--@ 1 densuke  wheel  156  4 14 06:13 Cargo.lock
-rw-r--r--@ 1 densuke  wheel  182  4 14 06:13 Cargo.toml
drwxr-xr-x@ 4 densuke  wheel  128  4 14 06:14 kiri
drwxr-xr-x@ 4 densuke  wheel  128  4 14 05:55 src
% ls -l kiri # kiri(lib)クレート内
total 8
-rw-r--r--@ 1 densuke  wheel  173  4 14 06:14 Cargo.toml
drwxr-xr-x@ 3 densuke  wheel   96  4 14 06:14 src
```

で、トップ側の`Cargo.toml`にkiriを足します。

```toml
[dependencies]
kiri = { path = "./kiri" }
```

これぐらい検出して自動的に入れてくれて良いんじゃない? と思ったりもします。
自動はないみたいですが、`cargo add`はできるみたい。

```zsh
% cargo add kiri --path ./kiri
      Adding kiri (local) to dependencies.
```

あとは `kiri/src/lib.rs` にごりごりっと書いていきます。

```file:kiri/src/lib.rs
pub fn rev(text: &str) -> String { // 先の知見でpub必要だよね
    text.chars().rev().collect()
}
```

`&str`な文字列を受け取って分解し、反転して`String`にするという良くあるようなコードです。
こちらは依存関係に書き込んでいるので、 `use` で対応しちゃいましょう、と思いましたが、別に書かなくても、裏で勝手に`use`宣言相当をしてくれるので書かなくてもOKみたいです。

```file:src/main.rs
mod hoge;


fn main() {
    println!("{}", hoge::hoge());
    println!("{}", kiri::rev("ふがほげ"));
}
```

これで両方とも動いてくれます。

```zsh
% cargo run
   Compiling kiri v0.1.0 (/private/tmp/libkiridashi/kiri)
   Compiling libkiridashi v0.1.0 (/private/tmp/libkiridashi)
    Finished dev [unoptimized + debuginfo] target(s) in 1.29s
     Running `target/debug/libkiridashi`
hogehoge
げほがふ
```

これで少しはコードの分離性が確保できそうです、わーい。
