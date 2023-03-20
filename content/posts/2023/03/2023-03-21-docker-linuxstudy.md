---
layout: post
title:  "普通っぽいLinux環境をDockerで作る"
date:   2023-03-21 07:18:42 +0900
categories: Docker
tags: [Linux, Docker, ssh, Ubuntu]
---
授業で使うLinuxの環境は、これまでVirtualBoxをベースに構築していましたが、昨今の環境の変化に対応できてない感じもあるので、Docker上でそれができないかと検証していたら案外簡単に動く話だったので移行中です。
ということで今回はやってみたら案外楽だった作業のまとめ。

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17365463%2F" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/5895/9784295015895_1_2.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17365463%2F" target="_blank" >Docker実践ガイド 第3版</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">古賀 政純 インプレス 2023年02月21日頃    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17365463%2F" target="_blank" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkrakukobo" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fbooks.rakuten.co.jp%2Frk%2Fd87c39bd2c71344db34ff4bf9af7cacb%2F" target="_blank" >楽天kobo</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F429501589X" target="_blank" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3DDocker%25E5%25AE%259F%25E8%25B7%25B5%25E3%2582%25AC%25E3%2582%25A4%25E3%2583%2589%2520%25E7%25AC%25AC3%25E7%2589%2588%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>

もともと授業用に仮想マシンを構築していましたが、[Oracle VM VirtualBox](https://virtualbox.org/)がM1/M2 macに対応準備中(現時点でPreview)ということや、なにより手持ちがIntelのみなので構築ができないということで(お金ほちい)ちょっと問題になっております。
そこで、

* Intel/M1両対応のDocker(Desktop)
* Ubuntu 22.04ベース
* Systemdあり
* sshあり

というイメージを作れればと思っていたのでした。

結局こうなりました。

```Dockerfile
# 骨子のみです
FROM ubuntu:22.04
ARG USER=linux
ARG PASSWORD
ENV TZ Asia/Tokyo
ENV LC_ALL ja_JP.UTF-8
ENV LANG ${LC_ALL}
ARG DEBCONF_FRONTEND=noninteractive
ARG DEBIAN_FRONTEND=${DEBCONF_FRONTEND}
# タイムゾーン周辺
RUN apt-get update; \
    apt-get install -y tzdata
# ロケール設定
RUN apt-get update; \
    apt-get install -y locales; \
    locale-gen ja_JP.UTF-8
# 足下回り
RUN apt-get update; \
    apt-get install -y init openssh-server sudo
# ssh使えるようにポートを通知
EXPOSE 22
# ユーザー作成(linux)
RUN useradd -s /bin/bash ${USER}; usermod -m -a -G sudo ${USER}; \
    echo "${USER}:${PASSWORD}" | chpasswd; \
    cat /etc/passwd
# apt使用時のキャッシュデータクリア(Dockerビルド向け)を外す
RUN rm -f /etc/apt/apt.conf.d/docker-clean
ENTRYPOINT ["/sbin/init"]
```

やってることは
* タイムゾーンとロケールを日本仕様にして置く
* OpenSSHが使えるように調整
* ユーザーを作成
    * パスワードを`Dockerfile`に入れておくのはよろしくなさげなので`--build-arg`で渡せ方式
* Systemd(init)をいれて`ENTRYPOINT`で呼び出す

Systemdが入るので、このイメージからのコンテナ生成では `--privileged` オプションが必要になります。
とはいえ実行対象がWindows/macOS上のDocker Desktopである以上VM内のSystemdを間借りする感じになるので影響はなさそうです。

おまけのテクニックとして、ホームディレクトリをボリュームに分けてコンテナリセット時でもホームを保持できるようにできないかということもありますが、
こういうとき向けの方法として、 `pam_mkhomedir` を使うというテクニックが有用となりますね。

```Dockerfile
# ユーザー作成(linux) → -m を外す
RUN useradd -s /bin/bash ${USER}; usermod -m -a -G sudo ${USER}; \
    echo "${USER}:${PASSWORD}" | chpasswd; \
    cat /etc/passwd
RUN echo 'session     required      pam_mkhomedir.so skel=/etc/skel umask=0022' >> /etc/pam.d/common-session
```

このpamモジュールを使うと、ユーザーがログインしたときにホームディレクトリがないときに自動的に作成してくれます。
これで起動時にボリュームで/homeを覆ったときでも大丈夫となります。

で、こうやって作ったイメージを起動してあげましょう。
繰り返し使うことを念頭に置いて、ここではcreate→start方式にしておくと良いでしょう。

```bash
$ docker volume create linux-home
$ docker container create --name=ubuntu -p 2022:22 -v linux-home:/home --privileged IMAGENAME
```

として準備して、

```bash
$ docker start ubuntu
# 5秒ぐらい落ち着いて待つ
$ ssh -p 2022 linux@127.0.0.1
```

これで普通にログインできます。
なお、`docker exec`を使っても強引には入れますが、`HOME`変数がきちんと設定できないため接続後のディレクトリがちょっとアレになってしまいます。

終了は、コンテナをstopするだけです。

```bash
$ docker stop ubuntu
# 10秒ほどすると終了します
```

なお、コンテナ内(ssh中)に`poweroff`してもうまく行きます。
こうなるとほとんど普通のLinux鯖です。

---

ARM版(M1/M2)イメージを作るためには、buildkitを使います。

```bash
$ docker buildx create --use mybuilder
$ docker buildx build -t USER/IMAGE --push --platform linux/amd64,linux/arm64 .
```

という感じで作ってpushして配置しておけばOKです。
