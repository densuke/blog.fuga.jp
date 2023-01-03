---
layout: post
title:  "Google App Scriptとリンクアクセスの設定について"
date:   2022-11-20 06:01:17 +0900
categories: GAS ファイル操作
---
GAS(Google App Script)で、共有アクセスしているファイルの権限操作で誤操作(指定時間内のアクセスを禁止にする)を減らせないかと言うことで調べていたのですが、なんとなくそれっぽいものが出てきました。

例えばこんなコード

```
function setPerm() {
  let file = DriveApp.getFileById(ID);
  // 誰でもアクセス→解除
  file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.NONE);
}
```

『リンクを知っている人』のアクセス権限を無くす(`NONE`)にしているわけですが、これもGoogleらしく疑似リアルタイムで同時アクセスしていた人にも反映されるんですよね。

![](/assets/images/gas-access-none.png)

この時間以降のアクセスができなくなるのであれば、閲覧時間はこの時間で切れるとみて良いのでしょうかね…
こいつは使えるかもしれません。

<div class="booklink-box" style="text-align:left;padding-bottom:20px;font-size:small;zoom: 1;overflow: hidden;"><div class="booklink-image" style="float:left;margin:0 15px 10px 0;"><a href="" target="_blank" ><img src="https://thumbnail.image.rakuten.co.jp/@0_mall/book/cabinet/1276/9784798061276.jpg?_ex=200x200" style="border: none;" /></a></div><div class="booklink-info" style="line-height:120%;zoom: 1;overflow: hidden;"><div class="booklink-name" style="margin-bottom:10px;line-height:120%"><a href="" target="_blank" >Google Apps Script実践プログラミング</a><div class="booklink-powered-date" style="font-size:8pt;margin-top:5px;font-family:verdana;line-height:120%">posted with <a href="https://yomereba.com" rel="nofollow" target="_blank">ヨメレバ</a></div></div><div class="booklink-detail" style="margin-bottom:5px;">今西航平 秀和システム 2020年04月28日頃    </div><div class="booklink-link2" style="margin-top:10px;">                                          	  	  	  	  	</div></div><div class="booklink-footer" style="clear: left"></div></div>


