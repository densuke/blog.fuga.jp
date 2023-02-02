---
layout: post
title:  "DevContainerがちょっと使えるようになってきた"
date:   2023-01-22 20:22:48 +0900
categories: container
tags: [開発, コンテナ, DevContainer]
---
最近、環境をなるべく壊さずに開発環境を保持できるDevContainerの立ち上げが少しずつ早くなってきました。
Docker(Desktop)を入れてれば(ここポイント)、準備しておいた開発環境を持ち込めるというものです。

※ Rancher Desktopを試して酷い目に遭いました、この部分はDDの方が一日の長あり。

基本的に私は、普通のDockerイメージを用意した上での『ちょい足し』をベースにやってます。

# ベースの環境

例えば一例として、Jekyllによるブログ環境(書いてる環境)で対応してみるとすると、ざっくりこうなります。

```Dockerfile
FROM ruby:3

ARG USER=worker
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update; apt-get install -y  sudo git
RUN groupadd -g ${USER_GID} ${USER}; \
    useradd -m -s /bin/bash -g ${USER_GID} -u ${USER_UID} -G sudo ${USER}
RUN echo "${USER} ALL = (ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}; \
    chmod 400  /etc/sudoers.d/${USER}
RUN mkdir /workspace; chown ${USER}:${USER} /workspace
WORKDIR /workspace
USER ${USER}
EXPOSE 4000
```

ポイントがちょっとあります。

- 作業用ユーザーは準備しておく(間違ってもrootで作業とかNG)
- 作業用ユーザーは`sudo` は使えるようにしておく
    - `sudo` のインストール
    - `NOPASSWD:ALL` で`sudo`が動かせるようにしておく

この辺の原則を守っておくと概ねOKみたいです。
ここを崩さずに必要になるアプリ環境の準備をすれば概ねOKです。

コンテナ軌道をお手軽化するために、`docker-compose.yml`もあわせて準備します。

```yaml
version: '3'

services:
  blog:
    build:
      context: .devcontainer
    volumes:
      - .:/workspace
    ports:
      - 4000
```

`Dockerfile`はDevContainerの管理ディレクトリ(`.devcontainer`)においているため、`context`で場所を切り替えてますが、それ以外はシンプルな構成だと思います。

# DevContainer対応

設定ファイル(`.devcontainer/devcontainer.json`)では、さしあたり『ちょい足し』設定を突っ込むことになります。

```json
{
    "dockerComposeFile": [
        "../docker-compose.yml",
        "custom.yml"
    ],
    "service": "blog",
    "workspaceFolder": "/workspace"
}
```

`docker-compose.yml`は追加設定(`custom.yml`)による重ね技を持ち込むようにしています。といってもこれだけ…

```yaml
version: '3'

services:
  blog:
    command: sleep infinity
```

無限sleepを使ってコンテナが落ちないようにキープさせてるだけです。
なんなら`jekyll serve`を走らせてもOKです(この部分は`Makefile`に書いてます。

これで、ブログ用のディレクトリを開いたら、"Reopen in Container"で切り替えできます。
さらにCodespacesを使って開かせることもできるので(検出して環境構築をしてくれる)、パソコンにてブラウザだけ(GitHubにログインできれば)で執筆可能です。
なんとまぁ便利な世の中に…

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16024527%2F" target="_blank" rel="nofollow" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/1616/9784865941616.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16024527%2F" target="_blank" rel="nofollow" >15Stepで習得 Dockerから入るKubernetes 　コンテナ開発からK8s本番運用まで</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">高良 真穂 リックテレコム 2019年09月23日頃    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16024527%2F" target="_blank" rel="nofollow" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F4865941614" target="_blank" rel="nofollow" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D15Step%25E3%2581%25A7%25E7%25BF%2592%25E5%25BE%2597%2520Docker%25E3%2581%258B%25E3%2582%2589%25E5%2585%25A5%25E3%2582%258BKubernetes%2520%25E3%2580%2580%25E3%2582%25B3%25E3%2583%25B3%25E3%2583%2586%25E3%2583%258A%25E9%2596%258B%25E7%2599%25BA%25E3%2581%258B%25E3%2582%2589K8s%25E6%259C%25AC%25E7%2595%25AA%25E9%2581%258B%25E7%2594%25A8%25E3%2581%25BE%25E3%2581%25A7%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" rel="nofollow" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>
