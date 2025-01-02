---
layout: post
title:  "Leptos+Tauriでデスクトップアプリは作れるのか? その1 ※逃避の可能性有り"
date:   2025-01-02 04:40:19 +0900
categories: [Rust, Leptos, Tauri]
---

Tauriってあるじゃないですか。Rustでデスクトップアプリ作るやつ。
あれがいくぶん前に2.0にリリースされたのですが、その際にUI側候補としてLeptosというものが出てきております。
こちら、RustでUIも書ける(といってもHTML,CSSを後ろで使いますが)ということなのですが、今のところ問題は**まともなチュートリアルが無い**ということです。

* [https://v2.tauri.app/start/](https://v2.tauri.app/start/)

でも、正直言うと興味はある技術なので、とりあえず触ってみることにしました。
事前の準備として、`cargo`にて、`create-tauri-app` はインストールしています。wasmのターゲットも導入済みです。

目標として

* まずとりあえずウィンドウが作れること
* 中身の書き換えを少ししてみること
* よくあるカウンターを作ってみる
* Dockerの状態でもバックエンドで確認できるようにしてUIに反映させたい

あたりでしょうか。まずはウィンドウを作ることが目標です。

プロジェクトを作ってみます。`create-tauri-app`を使います。
チュートリアルなどを見ると、対話的にやっていくことになるのですが、オプションをちょっと調べると面白いものがありました。

- `-t TEMPLATE`: UIテンプレートを指定できる
- `-y`: 対話項目は全てYes扱いとする

つまり

```bash
$ create-tauri-app -t leptos -y leptos-counter-app

Template created! To get started run:
  cd leptos-counter-app
  cargo tauri android init
  cargo tauri ios init

For Desktop development, run:
  cargo tauri dev

For Android development, run:
  cargo tauri android dev

For iOS development, run:
  cargo tauri ios dev

```

でとりあえずプロジェクト作成はできます。
できあがったプロジェクトはvscodeで開いておいて…

```bash
$ code leptos-counter-app
```

ターミナルを開いてからとりあえずアプリ起動に持ち込みましょうか。

```bash
# vscode内ターミナルにて
$ cargo tauri dev
```

かなりビルドするクレートが多いので、それなりに初回は時間がかかりますね。

![](/images/2024-12-26-leptos-tauri-app.png)

とりあえずウィンドウが出てきました。まずはここまでで一旦おしまい。

## おまけ

どれぐらい使えるのかよくわかりませんが、Tauriのvscode拡張というものがありました。
![Tauri拡張を入れたときのパレット](/images/tauri-ext.png)
