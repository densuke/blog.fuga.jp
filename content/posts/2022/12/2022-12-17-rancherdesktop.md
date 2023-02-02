---
layout: post
title:  "Rancher Desktopを使ってみた"
date:   2022-12-17 05:26:17 +0900
categories: Develop
tags: [Docker, Rancher, RancherDesktop]
---

Docker Desktopは機能面では特段困らないのですが、ライセンス回りが(教職員学生はともかく)面倒な感じなので(※)、
試しにRancher Desktopにしてみようという感じになって手持ちのmacで入れ替えて見ました。
K8sも有効にしてみたのですが、コンテナの外側ポートに80/tcpを考えてみたら、なぜか失敗する。

こりゃ誰か握ってるなと思って確認したのですが、

```bash
$ sudo lsof -i:80
COMMAND  PID    USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
limactl 4390 densuke   20u  IPv4 0x84dcfd87d00a72ed      0t0  TCP *:http (LISTEN)

$ ps 4390
  PID   TT  STAT      TIME COMMAND
 4390   ??  S      0:09.62 /Applications/Rancher Desktop.app/Contents/Resources/resources/darwin/lima/bin/limactl
```

ちょw **Rancherに入ってるlima(仮想マシン作るヤツ)が握ってるじゃないか**

もしかしてなにかのコンテナが?
と思ったら、先に立ち上げてたコンテナだったのでした。
なにやってるんだか…

ということで思い出したのは、

- `lsof` 使うと、**ポートを握ってるプロセスを調べられる**ゾイ

ということなのでした。物忘れしちゃってるから恐い恐い。

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16580202%2F" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/2745/9784839972745.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16580202%2F" target="_blank" >仕組みと使い方がわかる Docker＆Kubernetesのきほんのきほん</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">小笠原種高 マイナビ出版 2021年02月01日頃    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16580202%2F" target="_blank" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkrakukobo" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fbooks.rakuten.co.jp%2Frk%2F13d0d289fdb23187ae4f495b3eb8078e%2F" target="_blank" >楽天kobo</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F4839972745" target="_blank" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E4%25BB%2595%25E7%25B5%2584%25E3%2581%25BF%25E3%2581%25A8%25E4%25BD%25BF%25E3%2581%2584%25E6%2596%25B9%25E3%2581%258C%25E3%2582%258F%25E3%2581%258B%25E3%2582%258B%2520Docker%25EF%25BC%2586Kubernetes%25E3%2581%25AE%25E3%2581%258D%25E3%2581%25BB%25E3%2582%2593%25E3%2581%25AE%25E3%2581%258D%25E3%2581%25BB%25E3%2582%2593%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>
