---
layout: post
title: "安全にマイニングを行うために"
date: "2016-10-04 07:31:34 +0900"
tags:
  - minergate
  - 仮想通貨
---
さてさて、
[MinerGate](https://minergate.com/a/1a1f28ccb912cd314b657388)を用いたCPUマイニングの話。
マイニング(採掘)をCPUで行わせると、常にCPUを酷使する状況になるため、負荷がかかりすぎてCPUが傷む危険性というものがあります。
もちろんサーバー用途であればそういうのもありえる設計なのでまだマシでしょうが、個人持ちのクライアント仕様であれば、やはり危ないところです。
そこで、CPUをある程度使い、ちょこちょこ休ませる方式を検討してスクリプトに起こしてみました。
動作環境は、Ubuntuの14.04と16.04です。

```bash
#!/bin/bash

USER=densuke-web-minergate@fuga.jp
#MAX=4 #CPUコア数(最大)
MAX=$[$( cat /proc/cpuinfo  | grep ^processor | wc -l)-1] #CPUコアを自動算出
WORKTIME=3600 #活動時間(CPU時間)
STOP=300 #お休み時間
PROG=/PATH/TO/minergate-cli

while true; do
  # 今回のコア数を算出
  C=$[$RANDOM % $MAX + 1]
        WAIT=$[$STOP / ($MAX-$C+1)]
        (
          ulimit -t ${WORKTIME};
          echo "CPU数: $C";
                echo "採掘時間: $WORKTIME 休憩時間: ${WAIT}"
                exec ${PROG} -user ${USER} -xmr ${C}
        )
        echo -n "お休み中..."
        sleep ${WAIT}
        echo "OK"
done
```

CPUの数はとりあえず `/proc/cpuinfo` から取得しておきます。
フルにCPU使うと表のタスクに影響が出かねないので1つだけ残してます。4コアなら3コア使うということになります。

そしてulimitを使ってCPU使用時間による強制停止をリミッターとして設定します。

1. 今回使うCPU数をランダムに決定する
2. `ulimit`の引数に設定する

これでminergate-cliを動かしても、コア数が多ければ仕様数に準じた形で使用時間が増えるので、同じ`WORKTIME`でも、早くリミッターに達して停止します。

その上で、利用したCPU数に応じた休み時間(多く使うと長めに、少ないと短めに)をとった後、次のループに入っていきます。

採掘は細く長くですよ♪
