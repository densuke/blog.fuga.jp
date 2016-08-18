---
layout: post
title: "Windows Subsystem for Linux(WSL)の目指すもの"
date: "2016-08-10 05:45:41 +0900"
tags:
  - Windows10
  - Linux
---
実は私のところにはまだ配信されてないAnniversary Updateなのですが、この中の目玉として個人的に注目してるのがWSL(Windows Subsystem for Linux)です。
実体はUbuntuの環境で、それなりにまともに動く端末とbashなどの基本ツール、足りない部分はapt-getで入れるというシステムコールラッパーのような存在だったりします。
評価はいろいろですが、何分手元に届いてない(メディア作成をすれば手動で入れられるが、都合により今のところそこまでしていれることもありません)ので感想はまだかけません。
このWSL、単にAPI(というかシステムコール)のラッパーでお茶を濁す(とはいえ、本物のsshが使えればVagrantと組み合わせてどんだけ実習環境を楽にできるか)こともできるんだろうけど、
個人的にはもう少し先へ進むような気がするのです、それは **Wayland** の存在。

----

<table align="right" border="0" cellpadding="0" cellspacing="0"><tr><td><div style="border:1px solid #000000;background-color:#FFFFFF;width:250px;margin:0px;padding-top:6px;text-align:center;overflow:auto;"><a href="http://hb.afl.rakuten.co.jp/hgc/14bb6c76.ea80aa6b.14bb6c77.1c87a777/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Fbiccamera%2F4549576041469&m=http%3A%2F%2Fm.rakuten.co.jp%2Fbiccamera%2Fi%2F11141698%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIyNDB4MjQwIiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImRvd24iLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  ><img src="http://hbb.afl.rakuten.co.jp/hgb/14bb6c76.ea80aa6b.14bb6c77.1c87a777/?me_id=1269553&item_id=11141698&m=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Fbiccamera%2Fcabinet%2Fproduct%2F1918%2F00000003282271_a01.jpg%3F_ex%3D80x80&pc=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Fbiccamera%2Fcabinet%2Fproduct%2F1918%2F00000003282271_a01.jpg%3F_ex%3D240x240&s=240x240&t=picttext" border="0" style="margin:2px" alt="商品価格に関しましては、リンクが作成された時点と現時点で情報が変更されている場合がございます。お買い物される際には、必ず商品ページの情報を確認いただきますようお願いいたします。また商品ページが削除された場合は、「最新の情報が表示できませんでした」と表示されます。" title="商品価格に関しましては、リンクが作成された時点と現時点で情報が変更されている場合がございます。お買い物される際には、必ず商品ページの情報を確認いただきますようお願いいたします。また商品ページが削除された場合は、「最新の情報が表示できませんでした」と表示されます。"></a><p style="font-size:12px;line-height:1.4em;text-align:left;margin:0px;padding:2px 6px;word-wrap:break-word"><a href="http://hb.afl.rakuten.co.jp/hgc/14bb6c76.ea80aa6b.14bb6c77.1c87a777/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Fbiccamera%2F4549576041469&m=http%3A%2F%2Fm.rakuten.co.jp%2Fbiccamera%2Fi%2F11141698%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIyNDB4MjQwIiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImRvd24iLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  >【送料無料】 マイクロソフト 【USBメモリ】〔パッケージ版：新規インストール〕 Windows 10 Home</a><br><span >価格：15500円（税込、送料無料)</span> <span style="color:#BBB">(2016/8/10時点)</span></p></div><br><p style="font-size:12px;line-height:1.4em;margin:5px;word-wrap:break-word"></p></td></tr></table>
[Wayland](https://wayland.freedesktop.org/)は、従来LinuxやUNIX系システムで広く使われている(いた)X Window System(X)の置き換えという目的を含むGUI部分を指すプロジェクトであり成果物です。
Xは、クライアント/サーバー構成で動く少し変わった構造になってます。「変わった」というのは、従来の間隔とクライアントとサーバーの関係が逆になっていることです。

* Xのサーバー: 手元で動き、GUIとしての画面描画やキーボード・マウスなどの入力をクライアントに反映させるもの
* Xのクライアント: 手元でもリモートでも動き、アプリケーションとしての描画命令や入出力をサーバーと通信するもの

この仕組みにより、Xのクライアントが一般的なアプリケーションに該当しますが、ローカルで動いている必要はなく、ネットワーク的につながってればどこで動いててもかまいません。
結果、処理性能の高いマシン上でクライアントを走らせ、ローカルのXサーバーに表示をさせるという動きが取れるようになってます。
ちなみにこの時に使われてるのが **Xプロトコル** というもので、OSを問わずに使えます。昔のように、中央に処理性能の高いマシンがあるような環境においてはこの考え方が有効でしたし、今でも学生のマシンのアクティビティモニターをローカルに引っ張ってくることも可能だったりでそれなりに便利です。
昔は(今もある?)Windows向けXサーバーというものが市販されてて、学生の分際ではかなり高くて使えるシロモノではありませんでした(7万ぐらい)。

ただこのXプロトコルとクライアント・サーバー環境は現状においてはかなり陳腐化していると同時に、リモート呼び出しというものも頻繁に行わなくなりました。

* ローカルの性能が十分に高い
* リモートに演算させてローカルで描画させるスタイルはアプリやブラウザ表示で一般化しちゃってる

あたりが理由でしょうかね。
その一方で、現在の環境に追いつけなくなってるというのもあります。マルチタッチ環境の充実や、マウスの多重化(USB接続マウスとタッチパネルなど)の処理をどうするかとかで結構悩むことになるのです。

そういった諸々を踏まえ、もう少し薄いGUIレイヤーとして考えられているのがWaylandというプロジェクトであり成果物です。
今はまだ一般利用には難しいところがありますが、デスクトップ向けLinuxディストリビューションでは、機能的に含まれており、差し替えて実験的に使うことも可能になってます。
もしこの部分にWSLが入り込んだらどうなるか… そう、Wayland通信レイヤーをWSLでフックできるようになったらです。
これができればLinux上で動いてるGUIアプリがある程度Windowsデスクトップでシームレスに走る可能性があります。
最近のLinuxデスクトップ向けアプリは、直接Xと通信するのではなく、GUIレイヤーへのラッパーを経由するようになっています(Wayland対応のためというのがたぶん狙い)。
ということで、ヘタすると **Linux環境をインストールしなくてもWindows上でLinux環境が構築できてしまう** (カーネル以外) なんてことになっちゃうのかもしれません

職業柄Linuxを教える身としては、コマンドの練習などを行わせる際にいかに学生のマシン上でLinux環境を作らせるかがすごく問題です。
今はVirtualBox+Ubuntu+PuTTYという状況ですが、もしかすると来年・再来年あたりになったらWin10の1607(今回のAnniversary版以降)で対応できちゃうかもしれませんね。

ただし学生のパソコンがそこまで細心に追いついているかが別の意味で問題になりそうですが。
