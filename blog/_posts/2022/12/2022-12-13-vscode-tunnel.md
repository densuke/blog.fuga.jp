---
layout: post
title:  "Visual Studio Codeのトンネル機能"
date:   2022-12-13 04:24:47 +0900
categories: vscode
tags: vscode リモート
---

Visual Studio Codeもある意味Emacsの立ち位置となってきているわけですが、その中で求められる機能のひとつで、リモート接続があります。
もちろん MountainDuckなどでリモートのフォルダに見える形になってれば、ローカル環境で間接的に操作できますが、vscodeの場合だとリモート接続で対応できます。

- [remote ssh](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)

sshで繋がればリモートでnode.jsを起動してcodeサーバーといったものを準備してくれます。
でもこれはローカルにvscodeが入っている場合で、ローカルでvscodeが入ってない場合もあります。
そこで登場するのがもうひとつの方法で、GitHub経由でリモートで事前に起動していたvscodeにトンネルで接続するというものでした。

- [remote tunnels](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-server)

こちらは少しだけ手間がかかります。

1. 一度リモートにログインする
2. vscodeをインストールする(Ubuntuの場合、xdg-utilsが依存関係に出てきます)
3. `code tunnel` を実行し、指示に従って認証しておく

これでリモートでの接続先(URL)が出ます。これを控えておきましょう。
あとはブラウザにてこのアドレスを開くだけです。ブラウザ上でvscodeが開き、ようこそ画面からのスタートとなります。
codespacesを使ってれば感覚的には同じですね。
