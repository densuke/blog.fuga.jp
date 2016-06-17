---
layout: post
title: Squidで帯域制限
date: '2016-06-08T20:00:00.000+09:00'
author: densuke
tags:
  - サーバー
  - squid
---
ちょっと職場で必要になったので帯域制限をかける方法をSquidのみで実現する必要が出てました。そんなわけで実装してみました。

## `delay_pools`

まず `delay_pools` という値を定義しておきます。内容は数値で、**いくつ帯域制限ルールを定義するか** というレベルになってます。

## `delay_class`

つづいて `delay_class` を定義します。プール番号(`delay_pools`の数に依存、poolsが3なら1,2,3)とプール内の分割レベルの指定を行います。 分割レベルがclassと呼ばれてます。
**厳密なことはマニュアル嫁** ということで、ここでは2つだけ使います。

### クラス1

総量規制です。ここに含まれたパケットは、一緒くたに帯域制限を喰らいます

### クラス3

総量+ネットワーク単位+IP個別になります。今回は総量で頭をおさえつつ、個別に制限をかけることにします。

この2つについて、こんな感じにしてます。

```
delay_pools 4
delay_class 1 1
delay_class 2 3
delay_class 3 3
delay_class 4 3
```

プール番号にあるのがclassになります。4つのプールを作成し、それぞれクラス1と3にしてます。


## `delay_parameters`

各プールの設定を行います。クラスに応じてあとに書くパラメーターが決まります。

* 単位はbyte/sで指定し、最大サイズ(m)と復活(r)に使える値をr/mという形で指定します
* 8000/16000であれば、16000byte/s(=16kbyte/s、96kbps)ということになります、16kbyteを1秒以内に使うと使いきります(オーバーしてマイナスになることもあります)、復元力の値が毎秒復活していきます。この場合、8kbyte/sずつ復活していきます

クラス1であれば総量規制ですから1つだけ、クラス3であれば総量規制とネットワーク単位、個別IPの3つを書きます、無制限の部分は-1で書けます。

```
delay_pools 4
# ルール1: 制限なし
delay_class 1 1
delay_parameters 1 -1/-1
# ルール2: ブラックリストいりしたホストへはすごく絞る
delay_class 2 3
delay_parameters 2 12800/512000 -1/-1 6400/12800
# ルール3; 授業時間中
delay_class 3 3
delay_parameters 3 1024000/20480000 -1/-1 512000/2048000
# ルール4: 総量 200m
delay_class 4 3
delay_parameters 4 12800000/204800000 -1/-1 1024000/4096000
```

## `delay_access`

こうやってプールの宣言とプールの内容を記述したら、ACL組み合わせてどのプールを適用するかを指定します。

* 申告済みの教員端末(teachers)には特別な範囲でIPを貸し出しているため、そこの人は無制限で → プール1
* 授業中(workingtime)にブラックリスト入りしてるドメイン(ニコ動とかようつべとか)についてはblackhostに入れているので、該当するものはすっごく絞られます → プール2
* 授業中でもホワイトリスト(whitehost)に入っているものはゆるめにしておきます → プール4
* ブラックでもホワイトでもないものは授業向けのほどほど設定にしてます → プール3
* 休み時間については、レベルを1つずつずらします(ブラックリストものは授業中並、その他は休み時間用のゆるめ設定) → プール3,4

```
# 教員は無制限
delay_access 1 allow teachers

# 学生、授業中は制限
delay_access 2 allow blackhost workingtime
delay_access 3 allow !whitehost workingtime
# ホワイトリストに入っているところは制限さらにゆるめ
delay_access 4 allow whitehost
# 学生、休み時間はゆるめ
delay_access 3 allow blackhost
delay_access 4 allow students
```

注意点として、利用されるプールが複数該当してる時は、プール番号の小さいものが優先して使われてるみたいです。その点を注意しておかないと、予想外の帯域制限になってしまうみたいですので、試行錯誤がいくらか必要でしょう。

今回のポイントはルール2で定義しているブラックリスト入りへのアクセスです。
要は授業中にそっちのけで変なページにいかないようにサイトを登録していってるわけですが、ここにアクセスすると、

* あっさり上限にひっかかる(12.8KB/s上限だし、すぐには復活しない)
* 総量制限もしっかりかかってる
* ということで、だれかがこの沼にハマると一瞬通るけどその後しばらく接続がすっごくおそくなる
* **拒否はしないが3秒ルールを遥かに超えた遅延でイラつかせる** もしくは **生かさず殺さず** の精神がポイント

去年までは別のアプリと組み合わせて拒否&制限をかけてましたが、ACLの中にtime(時刻)が使えることに気づいたらこれ一本で制御できることがわかり、大幅に簡素化されました。

## おわりに

Squidはけっこう複雑なツールなので、私みたいににわかにいじるような連中にはかなり沼が多く、ハマると管理者も大変です。隔離環境を用意してじっくり取り組むようにするべきでしょう。
それと、書籍が独立して存在してるかというとあまりありません(あるけど古い)、ノウハウについては勢いネット上で漁ることになるのでそれもまた厳しいです、ハイ。

<div class="amazlet-box" style="margin-bottom:0px;"><div class="amazlet-image" style="float:left;margin:0px 12px 1px 0px;"><a href="http://www.amazon.co.jp/exec/obidos/ASIN/B01B2DO82O/fugadiary-22/ref=nosim/" name="amazletlink" target="_blank"><img src="http://ecx.images-amazon.com/images/I/51NmLFwCwWL._SL160_.jpg" alt="CentOS 7で作る ネットワークサーバ構築ガイド" style="border: none;" /></a></div><div class="amazlet-info" style="line-height:120%; margin-bottom: 10px"><div class="amazlet-name" style="margin-bottom:10px;line-height:120%"><a href="http://www.amazon.co.jp/exec/obidos/ASIN/B01B2DO82O/fugadiary-22/ref=nosim/" name="amazletlink" target="_blank">CentOS 7で作る ネットワークサーバ構築ガイド</a><div class="amazlet-powered-date" style="font-size:80%;margin-top:5px;line-height:120%">posted with <a href="http://www.amazlet.com/" title="amazlet" target="_blank">amazlet</a> at 16.06.08</div></div><div class="amazlet-detail">秀和システム (2016-01-25)<br />売り上げランキング: 22,816<br /></div><div class="amazlet-sub-info" style="float: left;"><div class="amazlet-link" style="margin-top: 5px"><a href="http://www.amazon.co.jp/exec/obidos/ASIN/B01B2DO82O/fugadiary-22/ref=nosim/" name="amazletlink" target="_blank">Amazon.co.jpで詳細を見る</a></div></div></div><div class="amazlet-footer" style="clear: left"></div></div>
