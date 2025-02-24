---
layout: post
title:  "Docker Hubがしんどいかもしれない問題"
date:   2025-02-24 05:20:01 +0900
categories: [docker]
---

昨日飛び込んできた話題ですが、Docker Hubがなかなかしんどい状況になりそうです。
いや、使う分にはいいかもしれないのですが…いや違う、つかうだけでも大変だ。

※ 発表した側も反響というか苦情を意識してか、少し変更したみたいです。また変更あるかもしれないので、あくまで2025/2/25朝時点の話として見てください。

ソースは[Docker Hub usage and limits](https://docs.docker.com/docker-hub/usage/)となります

- 2025/4/1から実施
- 非認証ユーザー(ログインしてない状態)ではプル数10回/時間に変更
- 認証ユーザー(ログインしている状態)ではプル数100回/時間に変更

リポジトリ数に関しての上限は特に変更ないかな。

授業でリポジトリ操作をする関係上、このリミット問題は無視できません。
Dockerを教えるときの学生には『ログインした状態で』操作させないと、10回/時のリミットはかかりそうです。

一方で、単に道具として使う非ログインのケースもあるが、これが"10 per IPv4 address or IPv6 /64 subnet"のため、学校や職場などでNATによる上流へのアクセスをしているところは一瞬でアウトになります。ということで、以前から気になっていたのでghcrへ移行していた分を加速することになります。


<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17808933%2F%3Frafcid%3Dwsc_b_bs_1051722217600006323" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/2199/9784065352199_1_2.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17808933%2F%3Frafcid%3Dwsc_b_bs_1051722217600006323" target="_blank" >ゼロから学ぶGit／GitHub　現代的なソフトウェア開発のために</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">渡辺 宙志 講談社 2024年04月11日頃    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F17808933%2F%3Frafcid%3Dwsc_b_bs_1051722217600006323" target="_blank" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkrakukobo" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fbooks.rakuten.co.jp%2Frk%2F39c21f3d27de336fad44bb8947f80c88%2F%3Frafcid%3Dwsc_k_eb_1051722217600006323" target="_blank" >楽天kobo</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F4065352193" target="_blank" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E3%2582%25BC%25E3%2583%25AD%25E3%2581%258B%25E3%2582%2589%25E5%25AD%25A6%25E3%2581%25B6Git%25EF%25BC%258FGitHub%25E3%2580%2580%25E7%258F%25BE%25E4%25BB%25A3%25E7%259A%2584%25E3%2581%25AA%25E3%2582%25BD%25E3%2583%2595%25E3%2583%2588%25E3%2582%25A6%25E3%2582%25A7%25E3%2582%25A2%25E9%2596%258B%25E7%2599%25BA%25E3%2581%25AE%25E3%2581%259F%25E3%2582%2581%25E3%2581%25AB%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>
