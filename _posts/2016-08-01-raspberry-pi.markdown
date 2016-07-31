---
layout: post
title: "Raspberry Piとストレージ負荷の問題"
date: "2016-08-01 05:58:35 +0900"
tags:
  - RaspberryPi
---
すらどやその他諸々でお世話になってる(?)ずけらんさんがRaspberryPiについてこんな形で記事をあげられてました。

* [Raspberry Pi を Network boot (with LANDISK NFS) | ず’s](http://www.zukeran.org/shin/d/2016/07/29/raspberry-pi-network-boot/)

<table align="right" border="0" cellpadding="0" cellspacing="0"><tr><td><div style="border:1px solid #000000;background-color:#FFFFFF;width:250px;margin:0px;padding-top:6px;text-align:center;overflow:auto;"><a href="http://hb.afl.rakuten.co.jp/hgc/02164ccd.7dcbe6c6.03dc0c55.8ee179dc/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Fbook%2F14107515&m=http%3A%2F%2Fm.rakuten.co.jp%2Fbook%2Fi%2F17913296%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIyNDB4MjQwIiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImRvd24iLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  ><img src="http://hbb.afl.rakuten.co.jp/hgb/02164ccd.7dcbe6c6.03dc0c55.8ee179dc/?me_id=1213310&item_id=17913296&m=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Fbook%2Fcabinet%2F7652%2F9784873117652.jpg%3F_ex%3D80x80&pc=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Fbook%2Fcabinet%2F7652%2F9784873117652.jpg%3F_ex%3D240x240&s=240x240&t=picttext" border="0" style="margin:2px" alt="商品価格に関しましては、リンクが作成された時点と現時点で情報が変更されている場合がございます。お買い物される際には、必ず商品ページの情報を確認いただきますようお願いいたします。また商品ページが削除された場合は、「最新の情報が表示できませんでした」と表示されます。" title="商品価格に関しましては、リンクが作成された時点と現時点で情報が変更されている場合がございます。お買い物される際には、必ず商品ページの情報を確認いただきますようお願いいたします。また商品ページが削除された場合は、「最新の情報が表示できませんでした」と表示されます。"></a><p style="font-size:12px;line-height:1.4em;text-align:left;margin:0px;padding:2px 6px;word-wrap:break-word"><a href="http://hb.afl.rakuten.co.jp/hgc/02164ccd.7dcbe6c6.03dc0c55.8ee179dc/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Fbook%2F14107515&m=http%3A%2F%2Fm.rakuten.co.jp%2Fbook%2Fi%2F17913296%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIyNDB4MjQwIiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImRvd24iLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  >初めてのAnsible [ ローリン・ホッホスタイン ]</a><br><span >価格：3456円（税込、送料無料)</span> <span style="color:#BBB">(2016/8/1時点)</span></p></div><br><p style="font-size:12px;line-height:1.4em;margin:5px;word-wrap:break-word"></p></td></tr></table>
たしかに別途NASを持っている場合はそれで悪く無いと思います。
私は逆にしました。「どうせこわれるし」という判断から、SDカードのデータはできるだけ固有データを保有しない方針。
今後gitlabを移行させる予定ですが、その際は毎日Googleのクラウドにバックアップを送信するようにします。

設定はAnsibleで流し込むだけにして、再インストールしても、Ubuntu MATE+Ansibleですべて再構成可能なようにしました。
これでSDカードが死んでも、それなりの時間で再構成可能になります。SDカードは比較的安いのでこれで十分でしょうきっと。

ま、どうしてもというのであればDRBDとかもあるんだろうけど、使ってもないのに疲弊させるだけのような気がしますw
