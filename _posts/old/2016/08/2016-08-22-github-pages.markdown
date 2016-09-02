---
layout: post
title: "github pagesのカスタムドメイン設定が少し変わった?"
date: "2016-08-22 08:24:20 +0900"
tags:
  - ブログ
  - github
---
しばらく前から、github pagesでこんな感じのメッセージが返されるようになってました。

    The page build completed successfully, but returned the following warning:

    Your site's DNS settings are using a custom subdomain, blog.fuga.jp, that's set up as an A record. We recommend you change this to a CNAME record pointing at example.github.io. For more information, see https://help.github.com/pages/.

    For information on troubleshooting Jekyll see:

      https://help.github.com/articles/troubleshooting-jekyll-builds

    If you have any questions you can contact us by replying to this email.

ページ生成自体はできてますから問題ないのですが、これは今後の仕様変更でいきなり見えなくなるようなことになりかねませんから、
指示通りにやってみることにしました。

## 従来との違い

従来は、カスタムドメインに関してはAレコードで指定された2箇所のIPアドレスを指すようにゾーンを書くようになっていました。

```
; blog(github pages)
blog  IN A 指定IPその1
      IN A 指定IPその2
```

これが、メッセージにあるように、ユーザーのgithubプロジェクトページヘCNAMEしろとなったわけです。


## 修正してみる

ということで

```
; blog(github pages)
blog  IN CNAME XXXXXXXX.github.io
```

と書き換えるのが指摘になっていたのですね。
自宅のローカルDNSでの設定はnsdを使っているため上記の修正でOK。

ちなみにgcloudのDNSを使っているので、ちょっと書式は異なりますが移植してきちんと動くことを確認しました。

```bash
$ host blog.fuga.jp 8.8.4.4
Using domain server:
Name: 8.8.4.4
Address: 8.8.4.4#53
Aliases:

blog.fuga.jp is an alias for densuke.github.com.
densuke.github.com is an alias for github.map.fastly.net.
github.map.fastly.net is an alias for prod.github.map.fastlylb.net.
prod.github.map.fastlylb.net has address 151.101.100.133
```

ちょっと変換が多い気もしますが、キャッシュで処理される範疇でしょうから大丈夫です。

<table border="0" cellpadding="0" cellspacing="0"><tr><td><p style="font-size:12px;line-height:1.4em;margin:5px;word-wrap:break-word"></p></td><td><div style="border:1px solid #000000;background-color:#FFFFFF;width:250px;margin:0px;padding-top:6px;text-align:center;overflow:auto;"><a href="http://hb.afl.rakuten.co.jp/hgc/12fe2014.3fbd01c6.12fe2015.40b745fb/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Frakutenkobo-ebooks%2F5689f3d5a7443a82b0e71c59a738501c&m=http%3A%2F%2Fm.rakuten.co.jp%2Frakutenkobo-ebooks%2Fi%2F15428592%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIyNDB4MjQwIiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImxlZnQiLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  ><img src="http://hbb.afl.rakuten.co.jp/hgb/12fe2014.3fbd01c6.12fe2015.40b745fb/?me_id=1278256&item_id=15428592&m=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Frakutenkobo-ebooks%2Fcabinet%2F6065%2F2000004146065.jpg%3F_ex%3D80x80&pc=https%3A%2F%2Fthumbnail.image.rakuten.co.jp%2F%400_mall%2Frakutenkobo-ebooks%2Fcabinet%2F6065%2F2000004146065.jpg%3F_ex%3D240x240&s=240x240&t=picttext" border="0" style="margin:2px" alt="商品価格に関しましては、リンクが作成された時点と現時点で情報が変更されている場合がございます。お買い物される際には、必ず商品ページの情報を確認いただきますようお願いいたします。また商品ページが削除された場合は、「最新の情報が表示できませんでした」と表示されます。" title="商品価格に関しましては、リンクが作成された時点と現時点で情報が変更されている場合がございます。お買い物される際には、必ず商品ページの情報を確認いただきますようお願いいたします。また商品ページが削除された場合は、「最新の情報が表示できませんでした」と表示されます。"></a><p style="font-size:12px;line-height:1.4em;text-align:left;margin:0px;padding:2px 6px;word-wrap:break-word"><a href="http://hb.afl.rakuten.co.jp/hgc/12fe2014.3fbd01c6.12fe2015.40b745fb/?pc=http%3A%2F%2Fitem.rakuten.co.jp%2Frakutenkobo-ebooks%2F5689f3d5a7443a82b0e71c59a738501c&m=http%3A%2F%2Fm.rakuten.co.jp%2Frakutenkobo-ebooks%2Fi%2F15428592%2F&scid=af_item_tbl&link_type=picttext&ut=eyJwYWdlIjoiaXRlbSIsInR5cGUiOiJwaWN0dGV4dCIsInNpemUiOiIyNDB4MjQwIiwibmFtIjoxLCJuYW1wIjoiZG93biIsImNvbSI6MSwiY29tcCI6ImxlZnQiLCJwcmljZSI6MSwiYm9yIjoxLCJjb2wiOjAsInRhciI6MX0%3D" target="_blank" style="word-wrap:break-word;"  >ドキュメント作成システム構築ガイド[GitHub、RedPen、Asciidoctor、CIによる モダンライティング]【電子書籍】[ 伊藤敬彦 ]</a><br><span >価格：2678円</span> <span style="color:#BBB">(2016/8/22時点)</span></p></div></td></tr></table>
