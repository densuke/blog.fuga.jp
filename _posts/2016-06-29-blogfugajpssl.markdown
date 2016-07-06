---
layout: post
title: "blog.fuga.jpのSSL化"
date: "2016-06-29 05:30:32 +0900"
tag:
  - サーバー
  - SSL
---
以前試したけど、現状では使ってないものとして、"[Let's Encrypt](https://letsencrypt.org/)"があったりします。
無料で通常利用に十分なSSL証明書を入手できるサービスで、今使ってるSSL証明書が切れたところでこっちに乗り換えようと思っており、いまのところあまり触ってません(テストはしてます、機能することも確認してます)。

<table align="right" border="0" cellpadding="0" cellspacing="0"><tr><td><div style="border:1px solid #000000;background-color:#FFFFFF;width:138px;margin:0px;padding-top:6px;text-align:center;overflow:auto;"><a href="http://hb.afl.rakuten.co.jp/hgc/02164ccd.7dcbe6c6.03dc0c55.8ee179dc/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Fbook%2F1619761&m=http%3A%2F%2Fm.rakuten.co.jp%2Fbook%2Fi%2F11214469%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIxMjh4MTI4IiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImRvd24iLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  ><img src="http://hbb.afl.rakuten.co.jp/hgb/02164ccd.7dcbe6c6.03dc0c55.8ee179dc/?me_id=1213310&item_id=11214469&m=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Fbook%2Fcabinet%2F2740%2F27406542.jpg%3F_ex%3D80x80&pc=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Fbook%2Fcabinet%2F2740%2F27406542.jpg%3F_ex%3D128x128&s=128x128&t=picttext" border="0" style="margin:2px"></a><p style="font-size:12px;line-height:1.4em;text-align:left;margin:0px;padding:2px 6px;word-wrap:break-word"><a href="http://hb.afl.rakuten.co.jp/hgc/02164ccd.7dcbe6c6.03dc0c55.8ee179dc/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Fbook%2F1619761&m=http%3A%2F%2Fm.rakuten.co.jp%2Fbook%2Fi%2F11214469%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIxMjh4MTI4IiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImRvd24iLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  >マスタリングTCP／IP（SSL／TLS編） [ エリック・レスコラ ]</a><br><span >価格：4860円（税込、送料無料)</span></p></div><br><p style="font-size:12px;line-height:1.4em;margin:5px;word-wrap:break-word"></p></td></tr></table>
で、このブログは(2016/6/29)現在、GitHub Pagesを使ってGitHubのサーバー上で公開しています。実はここだとSSL対応ができないという制限がついていたりします。
といってもGitHubがまったくSSL対応対応しないかというとそういうわけではなく、カスタムドメイン状態にたいして提供できない(username.github.io/... は対応してます)とう状態です。
もちろん、SSL対応する以上、ドメイン管理者が持つSSL証明書の秘密鍵をGitHubに差し出す必要が有ることも原因なのでしょう。CloudFlareを経由する方法で強引にサポートする方法もあるようです(→[参考資料](http://qiita.com/superbrothers/items/95e5723e9bd320094537))。

この状況に対し、[gistによる請願](https://gist.github.com/coolaj86/e07d42f5961c68fc1fc8)なんてのも出てる状況ですが、2年たってもこの件が進まないということはやらないということでしょう。
でも、Let's Encryptによる常時SSLも夢ではない(+http/2というのもありますし)ので、そろそろ動いてほしいな、とも思うところ。

さて、そんなLet's Encryptについてですが、[OSDN](https://osdn.jp/)が[けっこうしっかりした記事](https://osdn.jp/magazine/16/06/28/090000)を出してくださいました。
しばりがない環境であれば、ためしてみるのもいいかと思います。
