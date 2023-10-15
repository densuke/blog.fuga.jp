---
layout: post
title:  "便利かどうか微妙だけど: TouchIDとsudo"
date:   2023-10-16 04:05:46 +0900
categories: Tech
tags: [macOS, sudo, セキュリティ]
---
macOS sonomaも含め、現代のmacOSには`sudo`が含まれています。
Linux程ではないのですが、macOSでも`sudo`による権限昇格の必要性はあるので、必要な時に使うこととなりますが、
実は昇格時に必要となるパスワード入力をTouchIDで代用するという機能が実装されていたのでした。

<div class="kaerebalink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="kaerebalink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fitem.rakuten.co.jp%2Fchanet%2F300769%2F" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/chanet/cabinet/3009/300769-1.jpg?_ex=128x128" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"></div><div class="kaerebalink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="kaerebalink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fitem.rakuten.co.jp%2Fchanet%2F300769%2F" target="_blank" >スドー　サクサク王国　とうふキューブ　10g　3袋セット　関東当日便</a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"><div class="kaerebalink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://kaereba.com" rel="nofollow" target="_blank">カエレバ</a></div></div><div class="kaerebalink-detail" style="margin-bottom:5px;"></div><div class="kaerebalink-link1" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920706&p_id=54&pc_id=54&pl_id=616&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fsearch.rakuten.co.jp%2Fsearch%2Fmall%2Fsudo%2F-%2Ff.1-p.1-s.1-sf.0-st.A-v.2%3Fx%3D0" target="_blank" >楽天市場</a><img src="//i.moshimo.com/af/i/impression?a_id=920706&p_id=54&pc_id=54&pl_id=616" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3Dsudo%26__mk_ja_JP%3D%25E3%2582%25AB%25E3%2582%25BF%25E3%2582%25AB%25E3%2583%258A" target="_blank" >Amazon</a><img src="//i.moshimo.com/af/i/impression?a_id=920708&p_id=170&pc_id=185&pl_id=4062" width="1" height="1" style="border:none;"></div><div class="shoplinkdocomo" style="display:inline;margin-right:5px"><a href="https://prf.hn/click/camref:1100lq2Ps/destination:https%3A%2F%2Fshopping.dmkt-sp.jp%2Fproducts_search%3Fkeyword%3Dsudo" target="_blank" >dショッピング</a></div></div></div><div class="booklink-footer" style="clear: left"></div></div>

やり方はかなり簡単で、pam(pluggable authentication module)にて「認証時にTouchIDを使う」ためのモジュール`pam_tid`を使わせるようにすればいいのでした。
設定自体は、ファイル `/etc/pam.d/sudo_local.template` にコメントアウトした状態でおいてくれてるので、コメントを外して有効化して`sudo_local`にすればOKです。
よってこんなコマンドラインでいかがでしょうか。

```bash
$ cd /etc/pam.d
$ sed -e 's/#auth/auth/' ./sudo_local.template # コメントが外されることを確認
$ sed -e 's/#auth/auth/' ./sudo_local.template | sudo tee sudo_local
```

これで以降の`sudo`実行時にTouchIDが有効化されます。

```bash
$ sudo -k # 認証キャッシュを消す
$ sudo pwd
```

これでTouchIDが出ればOKです。同様に認証キャッシュは行われます。

![TouchID使用時](/images/sudo-touchid.png)
