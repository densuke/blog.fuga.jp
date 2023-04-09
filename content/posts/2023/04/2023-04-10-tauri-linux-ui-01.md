---
layout: post
title:  "Tauriで実用?アプリを試してみてます(不定期ネタ)"
date:   2023-04-10 05:39:26 +0900
categories: develop
tags: [Rust, Tauri, アプリ, 開発]
---
授業のVMをVirtualBoxからDockerベースに変更したのですが、学生にとって本当にVM(的なもの)が動いているのかというのが不安になってしまうこともあるかと思います。
本当は`docker`系のコマンドを教えたいところですが、それを話す学年ではない(そういう主戦場の学年はもうひとつ上)ので、稼働状態と最低限の制御のできるUIができないかなと思っていたら… あるではありませんか? **Tauri** ですよ。

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17149713%2F" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/9163/9784297129163_1_4.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17149713%2F" target="_blank" >TypeScriptとReact/Next.jsでつくる実践Webアプリケーション開発</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">手島 拓也/吉田 健人 技術評論社 2022年07月25日頃    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17149713%2F" target="_blank" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F4297129167" target="_blank" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3DTypeScript%25E3%2581%25A8React%252FNext.js%25E3%2581%25A7%25E3%2581%25A4%25E3%2581%258F%25E3%2582%258B%25E5%25AE%259F%25E8%25B7%25B5Web%25E3%2582%25A2%25E3%2583%2597%25E3%2583%25AA%25E3%2582%25B1%25E3%2583%25BC%25E3%2582%25B7%25E3%2583%25A7%25E3%2583%25B3%25E9%2596%258B%25E7%2599%25BA%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>


- [Build smaller, faster, and more secure desktop applications with a web frontend | Tauri Apps](https://tauri.app/)

![](/images/2023-04-10-tauri.png)

実のところReactのUI設計とかは一切やったことなくかなり難儀してますが、その裏でこの春休み期間(学生のね)にRustにおけるbollardでちょっとだけdocker状態の取得とか操作を練習していたのでした。

とりあえず最初は状態の確認ができるようなUIのみにして、その後起動・終了を行えるようにボタンを付けるつもりです。現状はこんな感じ(スタブのみです)。

![](/images/2023-04-10-linuxvm-ui-now.png)

---

どんな感じ作っているのかですが… とっかかりはそれほど難しくありません。

```zsh
% create-tauri-app
```

で、TypeScriptベース、React使用という感じで雛形を作り、 `src/App.tsx` で表示に使っているところをゴリゴリ書き換えていきました。
なお、状態表示に関しては事前に調査をしていて、とりあえず`useEffect`とタイマーで書き換えるようにしています。

```tsx
  const [dockerState, setDockerState] = useState(""); // Docker環境の状態を持つ
  const [vmState, setVmState] = useState(""); // VMの状態を持つ
// ...
  useEffect(() => {
    // Dockerの状態を取得、更新
    setInterval(() => {
      getDockerState()
    }, 2000)
    setInterval(() => {
      getVmState()
    }, 2000)
  })
//...
  return (
    <div className="container">
      <h1>授業用LinuxVM管理</h1>
        <p>Docker: {dockerState}</p>
        <p>VM状態: {vmState}</p>
    </div>
  );
//..
  async function getDockerState(){
    await setDockerState("ここでDockerの状態を表示");
  }

  async function getVmState(){
    await setVmState("ここでVMの状態を表示");
  }

```

このコードに、とりあえずDocker状態とVMの稼働状態を記載しておけばそれなりに参照できるようになるかと思います。
まず第一弾はここまで。
