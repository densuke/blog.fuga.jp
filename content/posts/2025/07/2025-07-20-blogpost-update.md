---
layout: post
title:  "ブログ投稿通知ツールの更新"
date:   2025-07-20 08:46:42+0900
categories: [ツール, 更新]
---
![](/images/2025-07-20/aigirl.png)

個人的に作っているブログの更新情報を確認して各SNSにポストするツールを地味に更新しています。
理由は『同一SNSの別アカウント』への投稿が目的です。
Mastodonのアカウントを複数持っているので、同じ投稿を別アカウントに投稿するためのものです。
というか、インスタンス違いへの対応も含んでいます。

このツール、gemini-cliとclaude-codeを使ってほぼバイブコーディングとなっています。
地味なツールですが、こうやって自分用に開発を行える環境が取れるのは助かります。

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F18145686%2F%3Frafcid%3Dwsc_b_bs_1051722217600006323" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/7442/9784296207442_1_27.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F18145686%2F%3Frafcid%3Dwsc_b_bs_1051722217600006323" target="_blank" >徹底入門！生成AI活用プログラミング</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">日経ソフトウエア 日経BP 2025年02月17日    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F18145686%2F%3Frafcid%3Dwsc_b_bs_1051722217600006323" target="_blank" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F429620744X" target="_blank" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E5%25BE%25B9%25E5%25BA%2595%25E5%2585%25A5%25E9%2596%2580%25EF%25BC%2581%25E7%2594%259F%25E6%2588%2590AI%25E6%25B4%25BB%25E7%2594%25A8%25E3%2583%2597%25E3%2583%25AD%25E3%2582%25B0%25E3%2583%25A9%25E3%2583%259F%25E3%2583%25B3%25E3%2582%25B0%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>
