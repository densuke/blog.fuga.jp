---
layout: post
title:  "Leptos+Tauriでデスクトップアプリは作れるのか? その2"
date:   2025-01-02 04:51:28 +0900
categories: [Rust, Leptos, Tauri]
---

Leptos+TauriでとりあえずのUIが展開できるようになったので、ソースツリーを眺めるわけですが、地味に辛い話として、LeptosのソースとTauriのソースがエディタ上で判別しにくいという罠があります。

![](/images/leptos-tauri-sourcetree.png)

これをvscode上で両方開くと… お察しの通りです。

![](/images/vscode-leptos-tauri.png)

一応ガイドは出ますけど、`main.rs`が被るのでちょっとな感…
幸いなのは、`main.rs`をいじる機会はさほど無いと言うことでしょうか。

---

さて、とりあえずUIはどこだろう、と思うとleptos側の`app.rs`にありますね。

```Rust
    view! {
        <main class="container">
            <h1>"Welcome to Tauri + Leptos"</h1>

            <div class="row">
                <a href="https://tauri.app" target="_blank">
                    <img src="public/tauri.svg" class="logo tauri" alt="Tauri logo"/>
                </a>
                <a href="https://docs.rs/leptos/" target="_blank">
                    <img src="public/leptos.svg" class="logo leptos" alt="Leptos logo"/>
                </a>
            </div>
            <p>"Click on the Tauri and Leptos logos to learn more."</p>

            <form class="row" on:submit=greet>
                <input
                    id="greet-input"
                    placeholder="Enter a name..."
                    on:input=update_name
                />
                <button type="submit">"Greet"</button>
            </form>
            <p>{ move || greet_msg.get() }</p>
        </main>
    }

```

- `#[component]`という注釈でleptos側でUIに使う情報を返すマクロを適用してくれるのでしょうね。
- `view!`マクロを使うことでUI部分を構成してくれる、と。

ということで、ちょっと`view!`内を書き換えてみましょうか。

```Rust
    view! {
        <main class="container">
            <h1>"Welcome to Tauri + Leptos"</h1>
// ↓
    view! {
        <main class="container">
            <h1>"Tauri + Leptosへようこそ"</h1>
```

このとき、`view!`マクロ内ではリテラルはクォートが必要なので注意という所でしょうか。
保存すると、ソースの変更を検出してリビルドをしてGUIも開きお直してくれてます。

![](/images/leptos-tauri-modified-h1.png)

ということで、とりあえず一枚であればこれでどうにかなりそうです。
