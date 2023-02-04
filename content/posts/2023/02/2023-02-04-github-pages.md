---
layout: post
title:  "GitHub Pagesへの移行(リベンジ)"
date:   2023-02-03 23:53:08 +0900
categories: 技術
tags: [GitHub pages, DNS]
---
Jekyll/Hugoに切り替えて静的ページにしたなら、別にサーバーで持つ必要も無くなったわけで、GitHub Pagesに移行しようと画策していたのですが、実はうまく行かずでちょっと苦労していたのでした。
でもなんとかできたみたいなので、メモを残しておきます。

0. (事前設定)リポジトリ名をホスト名にしておく(USERNAME/HOSTNAME)
1. サイトの情報を入れてるGitHubのページをブラウザで開く
2. "Pages > GitHub Pages"と進め、設定を確認する
3. Custom domainの項目に設定したいホスト名に設定する

これでPages向けに登録されてればOKです。今回はActionsでHugoのテンプレートを使うようにしたらほとんどすること無しでした(利用するHugoのバージョンを書き換えた程度)。
ところがこれがDNSチェックがうまく通らない。

実は事前にカスタムドメインの設定は準備が必要で、使いたいドメインが所有物かの確認が求められていたのでした。

- [GitHub Pagesのカスタムドメインの検証](https://docs.github.com/ja/pages/configuring-a-custom-domain-for-your-github-pages-site/verifying-your-custom-domain-for-github-pages)

1. アカウント設定(Settings)に入り、Pagesの項目を開く
2. 使いたいドメイン名を競って(追加)する
3. 管理してるDNSサーバーの方法に従い、確認用にレコードの一時追加を求められるので(TXTレコード)、追加する
4. 登録後チェックをかける

これで通れば、Pagesの設定でもカスタムドメインが通過できました。

今後はコミットすると1,2分でデプロイされて楽ちんです…

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16655117%2F" target="_blank" rel="nofollow" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/3430/9784863543430.jpg?_ex=200x200" style="border: none;" /></a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16655117%2F" target="_blank" rel="nofollow" >改訂2版 わかばちゃんと学ぶ Git使い方入門</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">湊川 あい シーアンドアール研究所 2021年06月14日頃    </div><div class="booklink-link2" style="margin-top:10px;"><div class="shoplinkrakuten" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=http%3A%2F%2Fbooks.rakuten.co.jp%2Frb%2F16655117%2F" target="_blank" rel="nofollow" >楽天ブックス</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkrakukobo" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=1175594&p_id=56&pc_id=56&pl_id=637&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fbooks.rakuten.co.jp%2Frk%2F506bbabe7e2a3117a2d07a9f60a1f77d%2F" target="_blank" rel="nofollow" >楽天kobo</a><img src="//i.moshimo.com/af/i/impression?a_id=1175594&p_id=56&pc_id=56&pl_id=637" width="1" height="1" style="border:none;"></div><div class="shoplinkamazon" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fexec%2Fobidos%2FASIN%2F4863543433" target="_blank" rel="nofollow" >Amazon</a></div><div class="shoplinkkindle" style="display:inline;margin-right:5px"><a href="//af.moshimo.com/af/c/click?a_id=920708&p_id=170&pc_id=185&pl_id=4062&s_v=b5Rz2P0601xu&url=https%3A%2F%2Fwww.amazon.co.jp%2Fgp%2Fsearch%3Fkeywords%3D%25E6%2594%25B9%25E8%25A8%25822%25E7%2589%2588%2520%25E3%2582%258F%25E3%2581%258B%25E3%2581%25B0%25E3%2581%25A1%25E3%2582%2583%25E3%2582%2593%25E3%2581%25A8%25E5%25AD%25A6%25E3%2581%25B6%2520Git%25E4%25BD%25BF%25E3%2581%2584%25E6%2596%25B9%25E5%2585%25A5%25E9%2596%2580%26__mk_ja_JP%3D%2583J%2583%255E%2583J%2583i%26url%3Dnode%253D2275256051" target="_blank" rel="nofollow" >Kindle</a></div>                              	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>
