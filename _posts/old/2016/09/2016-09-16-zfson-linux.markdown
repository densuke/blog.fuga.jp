---
layout: post
title: "ちょっとまてzfs(on linux)"
date: "2016-09-16 05:44:08 +0900"
tags:
  - linux
  - zfs
---
さっき気づいたのですが、ZFS on Linuxのバージョンがほんのり上がっているのですが…

* [v0.6.5.8のChangeLog](https://github.com/zfsonlinux/zfs/releases/tag/zfs-0.6.5.8)

> Compatible with 2.6.32 - 4.8 Linux kernels.

ちょw ここにきて2.6.xでのビルドが可能になったのか。
相当に古い環境でも使えることになりそうですが、そんな機種ではメモリ資源とかがあまり期待できないような。売り物であろうdedupとかつらすぎるぞ…
