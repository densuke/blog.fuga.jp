---
layout: post
title:  "VScodeとGitHub Copilot"
date:   2024-04-17 19:15:17 +0900
categories: [vscode, github copilot, macOS]
---
DevContainerを使うとどうもGitHub Copilotが堕ちるような感じがする…
ということで少し調査してみたのですが、原因がOS寄りという事に少し困惑した。
<!--more-->

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17808933%2F" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/2199/9784065352199_1_2.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17808933%2F" target="_blank" >ゼロから学ぶGit／GitHub　現代的なソフトウェア開発のために</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">渡辺 宙志 講談社 2024年04月11日頃    </div><div class="booklink-link2" style="margin-top:10px;opacity: .80;filter: alpha(opacity=80);-ms-filter: "alpha(opacity=80)";-khtml-opacity: .80;-moz-opacity: .80;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17808933%2F" target="_blank" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F4065352193" target="_blank" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E3%2582%25BC%25E3%2583%25AD%25E3%2581%258B%25E3%2582%2589%25E5%25AD%25A6%25E3%2581%25B6Git%25EF%25BC%258FGitHub%25E3%2580%2580%25E7%258F%25BE%25E4%25BB%25A3%25E7%259A%2584%25E3%2581%25AA%25E3%2582%25BD%25E3%2583%2595%25E3%2583%2588%25E3%2582%25A6%25E3%2582%25A7%25E3%2582%25A2%25E9%2596%258B%25E7%2599%25BA%25E3%2581%25AE%25E3%2581%259F%25E3%2582%2581%25E3%2581%25AB%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" >Kindle</a></div><div class="shoplinkseven" style="display:inline;margin-right:5px"><a href="//ck.jp.ap.valuecommerce.com/servlet/referral?sid=3301980&pid=890465082&vc_url=http%3A%2F%2F7net.omni7.jp%2Fsearch%2F%3FsearchKeywordFlg%3D1%26keyword%3D9784065352199&vcptn=kaereba" target="_blank" >7net<img src="//ad.jp.ap.valuecommerce.com/servlet/atq/gifbanner?sid=3301980&pid=890465082" height="1" width="1" border="0"></a></div>            	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>

この問題が解決するまでは、以下の手順が必要なようです。

1. Docker Desktopのダッシュボードを開く
2. Settings(歯車アイコン) > General
3. "Use Virtualization framework" をオフにする(+Docker再起動)

![](/images/disable-virtualization-framework.png)

同様の問題の参考になれば幸い。

※ 出典 → [Remote Extension host terminated - Github Copilot Extension
#194458](https://github.com/microsoft/vscode/issues/194458#issuecomment-1912849373)
