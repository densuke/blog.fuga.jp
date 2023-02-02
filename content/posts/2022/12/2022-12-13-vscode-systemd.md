---
layout: post
title:  "Systemd × vscode tunnel"
date:   2022-12-13 04:24:47 +0900
categories: vscode
tags: [vscode, リモート]
---

vscodeのトンネル機能を使うと、リモートの(事前に起動しておいた)vscodeにブラウザで接続できるため、場所を問わずに作業できるようになります。実に便利。

ですが事前に`code tunnel`を実行しておく必要があり、ちょっと面倒です。
そこで、リモートにログインしていれば、`code tunnel`がバックグラウンドで実行されるようにしておきましょう。

事前設定として、 `systemd` のユーザー利用を可能にしておく必要がありますが、
おそらく現行のUbuntuであれば、準備ができてると思います。

```file:/etc/pam.d/systemd-user
# This file is part of systemd.
#
# Used by systemd --user instances.

@include common-account

session  required pam_selinux.so close
session  required pam_selinux.so nottys open
session  required pam_loginuid.so
session  required pam_limits.so
@include common-session-noninteractive
session optional pam_systemd.so
```

あと、`code tunnel`を事前に実行して認証を通して(トンネルのリンクを取得できた状態)おいてください。

では設定です。

```bash
$ mkdir -pv ~/.config/systemd/{user,default.target.wants}
$ cd ~/.config/systemd/user
$ edit vscode.service
```

```file:~/.config/systemd/user/vscode.service
[Unit]
Description=Visual Studio code remote tunnel

[Service]
ExecStart=/usr/bin/code tunnel
Environment=SSH_AUTH_SOCK=%t/keyring/ssh
Restart=always

[Install]
WantedBy=default.target
```

ファイルをつくったら、systemdに認識させておきます。

```bash
$ systemctl daemon-reload --user
```

そして起動です。

```bash
$ systemctl start --user vscode # vscode.serverでもOK(.serviceは省略可)
$ systemctl tatus --user vscode # 状態取得
● vscode.service - Visual Studio code remote tunnel
     Loaded: loaded (/misc/usbroot/home/densuke/.config/systemd/user/vscode.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2022-12-13 04:17:45 JST; 24min ago
   Main PID: 1508838 (sh)
     CGroup: /user.slice/user-1001.slice/user@1001.service/vscode.service
...以下略
```

接続テストは、事前に取得しているトンネルURLにブラウザで接続するだけです。

うまく動くことを確認し、自動起動にしておきたければ、

```bash
$ systemctl enable --user vscode
```

としておいてください。
ただし、**ログインしないとトンネルサービスが起動しない**ので注意してください。
もしOS起動時に立ち上げておきたければ、 `/etc/systemd/system` に配置し直しての作業となりますが、
`vscode.service` に実行ユーザーを追加しておく必要があることでしょう。そこは未チェックです。

