---
layout: post
title:  "VPSのテスト: 接続テスト編"
date:   2023-02-23 06:15:08 +0900
categories: FX
tags: [FX, VPS, お名前.com, 使えるねっと]
---
お名前.comのVPSに契約して繋がるようになったのですが、重要なのは応答性等です。
真に重要なのはこちらなのですよ。

- ブローカーのサーバーへの接続の速度はpingにて
- 約定に関わる処理時間部分はLatencyEAにて

それぞれ計測を試みてみます。

ということで、[Latency EA](https://tasfx.net/2016/05/12/post-6450/)を用意して実験してみました。

---

サーバーのスペックですが、どちらも大して変わりません。

- [使えるねっと](https://www.tsukaeru.net/?token=83ge6cdj8a): シルバープラン
    - CPU: 仮想CPUx3
    - メモリ: 2GB
    - ストレージ: SSD 100GB
    - OS: Windows Server 2012R2
- お名前.com: デスクトップクラウド(FX用)
    - CPU: 仮想CPUx3
    - メモリ: 2.5GB
    - ストレージ: SSD 150GB
    - OS: Windows Server 2019

OSが2012R2→2019というところは正直言うと魅力的、メモリとストレージは微妙な差です。
今回は考えないポイントですけど、OSとしてのWindows Server 2012R2って確かサポート終了間近(終了した?)だったと思うのですが、このあたりどう考えてるんでしょうかね、実は移行サポートがあったりする?

[確認したら10月](https://learn.microsoft.com/ja-jp/lifecycle/products/windows-server-2012-r2)ですね。このあたりどうするんでしょう、サポートに問い合わせてみますかね。

---

まずはAxioryで試してみます。

従来の「使えるねっと」の場合から見てみましょう。
まずはサーバーへのPing値から。

![](/images/ping-tn-axiory.png)

7.75〜9.33msとなりました。これが遅いかもと思ったから今回の件だったのですが…

そして実際の約定に関わる部分の測定となるLatencyEAの測定結果

![](/images/latency-tn-axiory.png)

109〜157ms、平均129msのようです。

続いて今回契約してみた「お名前.com」のデスクトップVPSの側ですね。

![](/images/ping-on-axiory.png)

…え、倍ぐらい遅い? 続いてLatencyEA

![](/images/latency-on-axiory.png)

156〜172ms、平均164msって… むしろ遅いのでした、がっかり。
ただ、デスクトップの反応ははっきりとこちらの方が良いという結果になりました。

---

続いて、国内口座であるOANDA Japanで検証してみました。
やってることは同じです。
残念ながらOANDA側ではLatencyEAがエラーになる(取引数量をミニマムである0.1に調整したのですが… 詳しい調査は今はしてません)のでpingのみです。

「使えるねっと」側

![](/images/ping-tn-oanda.png)

「お名前.com」側

![](/images/ping-on-oanda.png)

こちらもやはり倍ぐらいの差が出てますね。
ぐっすん、これではちょっと弱い。アノマリー系であればこちらでもたいした問題はなさそうですが、引っかかったときに即座にオーダーを調整することになる指標取引では、少しでも応答性の良いところになるので、やはりこのままだと「使えるねっと」継続ですね。

ちなみに自宅からやると「使えるねっと」比で3倍弱遅いです。

---

結局のところ、私の使い方であれば、[使えるねっと](https://www.tsukaeru.net/?token=83ge6cdj8a)の勝利っぽいです。
若干割高感はありますが、環境としては良かったのですね…

<a href="https://www.tsukaeru.net/?token=83ge6cdj8a&banner=78e3adda-56b1-4ce6-929f-a5617b75a88e&rdp=cloud-vps">
  <img src="https://banner.tsukaeru.net/storage/79fa3aef-7478-4cd9-aeb9-9bb095cb8904/banners/vps_234_60?token=__TOKEN__" alt="" />
</a>

3ヶ月買い殺すのもどうかと思うので、Windowsの検証環境として使わせてもらうことにしましょう。

