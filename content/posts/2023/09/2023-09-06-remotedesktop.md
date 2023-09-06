---
layout: post
title:  "Chrome Remote Desktopとディスプレイ表示"
date:   2023-09-06 07:27:05 +0900
categories: Work
tags: [Chrome RemoteDesktop, Windows, ディスプレイ]
---
リモートデスクトップを使うのですが、macOSからWindowsホストへ繋ぐときに使う方法として大きく2つが手軽に使える選択肢となっています。

- Windowsの持っているRemote Desktop機能(RD)
- Googleが提供するChrome RemoteDesktop(CRD)

このうちRDは対象となるマシン(ノートパソコン)の蓋を閉じていても特に問題無く機能していいのですが、接続が(標準の範囲では)外からは繋がりませんし、
接続のためにホットスポット機能などを使うことになるため、周囲の電波に支障をきたす可能性もあったりします。

一方でCRDは地味に宜しいのですが、画面の更新がなぜか起きないという謎の挙動に悩まされていました。
横にWindowsマシンを置いて確認してみたところ、蓋を閉じる(スリープはしない設定)と画面更新が起きないということが判明しました。

これを基に調べてみたら **蓋を閉じている状態では更新が起きない** ということが他の方からも出ていました。

- [カバーを閉じた状態のWindowsノートPCにChromeリモートデスクトップで接続すると画面が更新されない時の対処法](https://lil.la/archives/3983)

やはりそうなのか! で対処方法として上がっていたのが **外部ディスプレイを繋ぐ** (状態にする)ということでした。
ダミーのHDMIなんてアダプタが存在するのですね。価格もたかがしれてるし、Amazonのポイントでサクッと入手することにします。

<!-- START MoshimoAffiliateEasyLink -->
<script type="text/javascript">
(function(b,c,f,g,a,d,e){b.MoshimoAffiliateObject=a;
b[a]=b[a]||function(){arguments.currentScript=c.currentScript
||c.scripts[c.scripts.length-2];(b[a].q=b[a].q||[]).push(arguments)};
c.getElementById(a)||(d=c.createElement(f),d.src=g,
d.id=a,e=c.getElementsByTagName("body")[0],e.appendChild(d))})
(window,document,"script","//dn.msmstatic.com/site/cardlink/bundle.js?20220329","msmaflink");
msmaflink({"n":"Rongdeson 1 pc HDMI ダミープラグ HDMI バーチャルディスプレイ 4K @ 60Hz DDC EDID エミュレータコネクタ、1920x1080 から 4096x2160 に対応","b":"Rongdeson","t":"","d":"https:\/\/m.media-amazon.com","c_p":"\/images\/I","p":["\/31ouTpNrT6L._SL500_.jpg","\/41pRXplKBWL._SL500_.jpg","\/515mkT+D9oL._SL500_.jpg","\/31qR4arYaPL._SL500_.jpg"],"u":{"u":"https:\/\/www.amazon.co.jp\/dp\/B09ST5VCYN","t":"amazon","r_v":""},"v":"2.1","b_l":[{"id":2,"u_tx":"楽天市場で見る","u_bc":"#f76956","u_url":"https:\/\/search.rakuten.co.jp\/search\/mall\/Rongdeson%201%20pc%20HDMI%20%E3%83%80%E3%83%9F%E3%83%BC%E3%83%97%E3%83%A9%E3%82%B0%20HDMI%20%E3%83%90%E3%83%BC%E3%83%81%E3%83%A3%E3%83%AB%E3%83%87%E3%82%A3%E3%82%B9%E3%83%97%E3%83%AC%E3%82%A4%204K%20%40%2060Hz%20DDC%20EDID%20%E3%82%A8%E3%83%9F%E3%83%A5%E3%83%AC%E3%83%BC%E3%82%BF%E3%82%B3%E3%83%8D%E3%82%AF%E3%82%BF%E3%80%811920x1080%20%E3%81%8B%E3%82%89%204096x2160%20%E3%81%AB%E5%AF%BE%E5%BF%9C\/","a_id":920706,"p_id":54,"pl_id":27059,"pc_id":54,"s_n":"rakuten","u_so":1},{"id":1,"u_tx":"Amazonで見る","u_bc":"#f79256","u_url":"https:\/\/www.amazon.co.jp\/dp\/B09ST5VCYN","a_id":920708,"p_id":170,"pl_id":27060,"pc_id":185,"s_n":"amazon","u_so":2}],"eid":"72jHw","s":"s"});
</script>
<div id="msmaflink-72jHw">リンク</div>
<!-- MoshimoAffiliateEasyLink END -->
