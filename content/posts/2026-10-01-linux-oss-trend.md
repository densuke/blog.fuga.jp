---
title: "CPUは消したコードを覚えていた? Spectre新種BTR、OpenSSL 14件、KDEのX11セッション終了、WSLコンテナ、GitLab CVSS 9.9（2026/10/1 Linux・OSSトレンド）"
date: 2026-10-01T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Spectre", "CPU", "OpenSSL", "KDE", "Wayland", "WSL", "コンテナ", "GitLab", "CI/CD"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

古いものが新しいものに引き継がれる「つなぎ目」には、危険も進化も宿ります。今日はその切り口で、Spectre の新種、OpenSSL、GitLab という危ない話3本と、KDE Plasma 6.8、WSL コンテナという前向きな話2本を並べました。

{{< youtube "ThBsD8v_TAY" >}}

## 1. Spectre BTR — 解放されたJIT領域に残る分岐予測の「記憶」

1本目は、オランダ・VU Amsterdam の VUSec グループとイタリアの Scuola Superiore Sant'Anna による研究 Branch Target Reuse（BTR）です。9月末に公開され、論文は ACM CCS 2026 に採択されています。[VUSec のプロジェクトページ](https://www.vusec.net/projects/btr/)によると、現代の CPU はコードの自己書き換えのあとにアーキテクチャ上の整合性は取るものの、古い間接分岐予測のエントリを必ずしも無効化しません。研究チームはこれを突く攻撃を "speculative execute-after-free primitive"（投機的な解放後実行）と呼んでいます。

JIT コンパイラは不要になったコードを捨て、同じメモリ領域に新しいコードを置き直します。ところが CPU の分岐予測には、前のコードが使っていたエントリが残っています。新しいコードが同じ住所に来ると、CPU は前の住人の癖で先回りして実行し、その痕跡がキャッシュに残ります。この痕跡を測ることで、読めないはずのカーネルのデータを推測できます。

影響範囲について、VUSec は "We confirmed this behavior on every CPU we tested, covering Intel, AMD and Arm." と述べています。あくまで「試したすべての CPU」であり、全世代を調べたわけではありません。[The Register](https://www.theregister.com/security/2026/09/30/spectre-bug-is-back-this-time-to-haunt-jit-engines/5299937) は、この攻撃が FineIBT など一部のソフトウェア防御を回避すると伝えています。cBPF の定数ブラインド（constant blinding）が有効でも成立しましたが、既存の対策がすべて無力になったという話ではありません。

前提として、攻撃者は対象マシン上でコードを実行できる必要があります（非特権でよい）。ネットワーク越しに誰でも突ける話ではありません。VUSec によれば、強力な eBPF JIT は特権ユーザー限定ですが、旧来の classic BPF（cBPF）は非特権プログラムにも開放されていて、Linux ではここが入口になります。実証では、Intel の Linux マシンで実行中の `su` プロセスから root のパスワードハッシュを取り出しました。[BleepingComputer](https://www.bleepingcomputer.com/news/security/new-spectre-v2-attack-variant-leaks-linux-root-password-hash-in-minutes/) は、毎秒8バイトの速度で、平均して Raptor Cove では約3分、Lion Cove では約5分で完了したと伝えています。VUSec 自身も "Our exploit leaks 8 bytes per second." と書いています。The Register の 5.7 KB/秒（Raptor Cove）・5.4 KB/秒（Lion Cove）は「期待される漏洩レート」で、実測値ではありません。

Linux 側の追跡は CVE-2026-64507 と CVE-2026-64508 です。VUSec のページによると、前者は BPF JIT の確保時に IBPB でフラッシュする x86 向けの修正、後者は JIT スプレー対策のハードニングに割り当てられています。cBPF プログラムが実行済みの領域を再利用する際に全コアで IBPB を発行する緩和が、upstream に入っています。[Red Hat の CVE-2026-64508 のページ](https://access.redhat.com/security/cve/cve-2026-64508)は、独自の評価として CVSS 7.0（High、ローカル攻撃・低権限が前提）を付けています。NVD の値は今回確認できていません。

VUSec によれば、ほかの JIT の扱いは分かれています。Oracle GraalVM は JIT コードキャッシュの配置をランダム化して領域の再利用を妨げています。Mozilla は IBPB ベースの緩和も検討したものの、現時点ではサイト分離（site isolation）の完成を優先しています。Firefox で示されたのは実現可能性までで、エンドツーエンドの実証は Linux の cBPF です。なお研究チームによれば、Lion Cove は彼らが見つけた中で競合状態を必要としない最初の Intel 世代でした。

対策は、ディストリビューションの手順でカーネルを更新して再起動することです。VUSec も "Update your OS and software as soon as vendor patches are available." と勧めています。

## 2. OpenSSL 4.0.3 — 再送時の読み出し位置を戻し忘れた DTLS の穴など14件

2本目は OpenSSL です。2026年9月29日付の[セキュリティアドバイザリ](https://openssl-library.org/news/secadv/20260929.txt)で、CVE 14件が公表されました。深刻度の内訳は High 1件、Moderate 1件、Low 12件です。修正版は 4.0.3・3.6.5・3.5.9・3.4.8 で、3.0・1.1.1・1.0.2 系の修正版は有償サポート契約者向けです。

筆頭は CVE-2026-84782 で、OpenSSL 自身の深刻度は High です。DTLS のハンドシェイクメッセージは複数のフラグメントに分けて書き出され、ネットワーク側が一時的にデータを受け付けられないと、途中で `WANT_WRITE` を返して中断することがあります。その間に再送タイマーが発火すると、再送メッセージが位置のずれたバッファから読み出されてしまいます。アドバイザリによれば、その結果、ヒープメモリが平文のハンドシェイクデータとして相手に漏れるか、マップされていない領域に達してクラッシュ（DoS）します。分類は CWE-125（境界外読み出し）です。修正は、再送前に読み出し位置をメッセージ先頭へ戻し、ハンドシェイクの書き込みが中断中なら再送をスキップするというものです。

点数は帰属を分けて見ます。CVSS 8.2 は OpenSSL ではなく CISA が付けた値で、[The Hacker News](https://thehackernews.com/2026/09/openssl-fixes-high-severity-dtls-flaw.html) も "CISA gave the flaw a CVSS score of 8.2" と書いています。一方、[Red Hat の CVE-2026-84782 のページ](https://access.redhat.com/security/cve/cve-2026-84782)は独自に CVSS 7.4（Important）と評価しています。Red Hat は、影響は主に非ブロッキング I/O で UDP 上の DTLS を使うアプリケーションに限られ、TCP 上の通常の TLS 接続は影響を受けないとしています。ただし、これは CVE-2026-84782 についての話で、同じリリースの他の CVE まで無関係というわけではありません。

CVE-2026-84783 は Moderate で、OpenSSL 4.0 のみが対象です。X.509 拡張キャッシュの use-after-free で、同じ信頼済み CA 証明書に対する最初のチェーン構築を複数の接続が同時に行うと、クラッシュ（DoS）し得ます。対象はマルチスレッドの TLS クライアントと、クライアント証明書を要求するマルチスレッドの TLS サーバーです。

残りの Low には QUIC 関連が5件あります。たとえば CVE-2026-42772 は、QUIC のフラグメント再組み立てが O(n^2) になって CPU を消費し得る、というものです。

## 3. KDE Plasma 6.8 — 30周年の節目に X11 セッションが外れる

3本目は Linux デスクトップです。[KDE のリリーススケジュール](https://community.kde.org/Schedules/Plasma_6)によれば、Plasma 6.8 の第2ベータ（6.7.91）が9月24日に出て、6.8.0 の正式版は10月14日の予定です。この日は KDE の30周年にあたります（KDE は1996年10月14日、Matthias Ettrich の投稿から始まったとされます）。

[KDE の公式ブログ](https://blogs.kde.org/2025/11/26/going-all-in-on-a-wayland-future/)で、Plasma チームは2025年11月26日に Plasma 6.8 の Wayland 専用化を表明しています。X11 セッションは2027年初めまでサポートされ、スケジュール上は2027年1月の 6.7.7 が 6.7 系の最後です。なくなるのは X11 の「セッション」で、ごく一部の例外を除き、X11 アプリは XWayland 経由で引き続き動きます。X11 が必要な人向けに、同じブログは古い Plasma を載せた長期サポートのディストリビューション（例として AlmaLinux 9）を選択肢に挙げています。

具体的に何が変わるかは、KDE 開発者 David Edmundson の[個人ブログ](https://blog.davidedmundson.co.uk/blog/596/)（2026年6月2日）が詳しいです。6.8 ではログイン画面に X11 セッションが出なくなり、Plasma Shell や System Settings などにある X11 固有のコードが取り除かれます。同じ記事によると、KDE 内部のメトリクスでは Plasma 6.6 ユーザーの 95% 超がすでに Wayland を使っています。彼は XWayland のサポートを "second-to-none"（他に引けを取らない）とも書いていますが、これは KDE 公式の表明ではなく開発者個人の発言です。

機能面では、KDE の週刊ブログ [This Week in Plasma](https://blogs.kde.org/2026/09/12/this-week-in-plasma-6.8-beta-release/) によると、KWin が `commit_timing` プロトコルに対応し、リモートデスクトップ接続の遅延もさらに減りました。同じ連載の過去回では、NVIDIA GPU でのトリプルバッファのデフォルト有効化、HDR の HLG 転送関数への対応、ポインターを止めると自動クリックする dwell clicker の内蔵も紹介されています。

X11 の仕組みに直接頼る自動化やリモート操作のツールを使っているなら、6.8 を待たずに Wayland セッションで動くか試しておくのがよいでしょう。

## 4. WSL コンテナ GA — Windows と Linux のつなぎ目にコンテナ実行環境が入る

4本目は WSL です。[Windows Developer Blog の GA 発表](https://blogs.windows.com/windowsdeveloper/2026/09/29/wsl-containers-now-generally-available/)によると、9月29日、WSL 3.0.1 で WSL コンテナ（WSLc）が一般提供になりました。CLI は `wslc.exe` で、エイリアスとして `container.exe` も使えます。導入は `wsl --update` です。プレビュー以降に、コンテナの再起動、ファイルのコピー、環境状態の確認、ネットワークの接続・切断、ヘルスチェックが加わりました。

では Docker Desktop の出番はなくなるのか。慎重に見るべきです。GA 時点で Compose は未対応で、Microsoft は次の優先課題として、既存の `compose.yaml` を変更なしで動かす `wsl compose up` を挙げています。[Xenospectrum](https://xenospectrum.com/en/wsl-containers-ga-architecture-docker-boundaries/) も、こうした制約から、現時点では既存の Docker 環境をそのまま置き換えられるものではないと指摘しています。基本的なビルドや実行は wslc で行えますが、複数サービスの構成はこれからです。

内部構造は [Microsoft のアーキテクチャ解説](https://devblogs.microsoft.com/commandline/wslc-architecture-deep-dive/)に詳しく書かれています。`wslservice.exe` は VM を保持せず、呼び出したユーザーの権限で動く子プロセス `wslcsession.exe` を起動し、セッションの操作はそこが担います。ストレージはセッションごとの VHD で、`wslc.exe` 利用時は `%AppData%\Local\wslc\sessions` に置かれます。

ネットワークには consommé（コンソメ）という新しい方式が入りました。VM のトラフィックをイーサネットフレームとして virtio キューへ送り、Windows 側のプロセスが読み取って DNS・ルーティング・ポートマッピングを処理します。通常の Windows プロセスの通信として扱われるので、VPN やファイアウォールと相性がよいのが狙いです。なお、Windows ファイルへのアクセスが最大約2倍速くなったのは consommé の効果ではありません。Microsoft の説明では、virtiofs の採用によって従来の Plan 9 方式より速くなったものです。

管理面では、Intune で WSL コンテナの有効・無効の切り替えや、承認済みレジストリへのイメージ取得の制限ができます。Defender for Endpoint の WSL 向け既存プラグインも、コンテナに対応しました。

この発表は Slashdot でも話題になり、drnb 氏は "The 'Year of the Linux Desktop' is finally arriving. Admittedly Linux on the Windows Desktop wasn't quite what we were expecting." と書いています（「Linux デスクトップの年がついに来た。ただ、Windows デスクトップの上の Linux とは予想していなかった」）。

## 5. GitLab CVE-2026-89078 / 93577 — CI 設定の正規表現が突かれる CVSS 9.9

最後は今日いちばん重い話、GitLab の CVSS 9.9 の脆弱性2件です。CVE-2026-89078 は正規表現のパース処理の double free（CWE-415）、CVE-2026-93577 は正規表現コンパイラの整数オーバーフロー（CWE-190）です。[Intruder の CVEmon](https://cvemon.intruder.io/cves/CVE-2026-89078)によると、トリガーは CI/CD 設定に入れた細工した正規表現で、認証済みユーザーであることが攻撃の前提です。CVSS の評価上は、影響が脆弱な部品の外にまで及ぶ（スコープ変更あり）とされています。

一般論として、サーバー上で任意のコードが実行されれば CI/CD 変数などの秘密情報にも手が届きえます。具体的な攻撃手順や必要なロールは一次情報で確認できないため、ここでは踏み込みません。

影響を受けるのは 19.2.0〜19.2.6、19.3.0〜19.3.2、19.4.0 で、修正版はそれぞれ 19.2.7、19.3.3、19.4.1 です。パッチは9月23日に[GitLab のパッチリリース](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-1-released/)として公開され、CVE の公開は翌24日です。GitLab.com は対応済みと報じられています。セルフマネージドの環境では、公式のアップグレード手順に従って更新してください。

悪用については、分かっていることが限られます。本稿の確認時点で、[Strix の CVE ページ](https://www.strix.ai/cve/CVE-2026-89078)は実環境での悪用の兆候はないとしており、CISA の KEV（悪用が確認された脆弱性のカタログ）にも載っていません。ただし GitLab では最近、別の脆弱性でパッチ公開の直後に悪用が試みられた例があります。8月の CVE-2026-19478（CVSS 9.4、認証不要）は、公開の約2日後に watchTowr のハニーポットで悪用の試みが観測されたと[報じられています](https://tech-insider.org/gitlab-cve-2026-19478-cvss-9-4-exploit-2026/)。悪用の報告を待たずに更新する、というのが今回の教訓でしょう。

## まとめ

Spectre BTR では、解放された JIT 領域の分岐予測の記憶が新しいコードに引き継がれました。OpenSSL では中断した送信を再開する位置が戻っておらず、GitLab では利用者が書く設定とサーバー内部の処理の間が突かれました。一方、KDE は XWayland という橋を残して X11 から Wayland へ移り、WSL は Windows と Linux のつなぎ目にコンテナの受け口を標準で用意しました。ここからは筆者の考察ですが、危険になるか進化になるかは、つなぎ目を意識して手当てしているかどうかの差だと思います。

実務でやることは3つです。カーネルと OpenSSL、GitLab のバージョンを確認し、更新後の再起動まで済ませること。DTLS を使うアプリケーションがないか棚卸しすること。そして X11 頼みのツールを Wayland で試しておくことです。

## 参考リンク

- [VUSec: Branch Target Reuse](https://www.vusec.net/projects/btr/)
- [The Register: Spectre の新種が JIT エンジンを狙う](https://www.theregister.com/security/2026/09/30/spectre-bug-is-back-this-time-to-haunt-jit-engines/5299937)
- [OpenSSL セキュリティアドバイザリ（2026-09-29）](https://openssl-library.org/news/secadv/20260929.txt)
- [KDE 公式ブログ: Wayland 一本化](https://blogs.kde.org/2025/11/26/going-all-in-on-a-wayland-future/)
- [WSL コンテナ GA 発表（Windows Developer Blog）](https://blogs.windows.com/windowsdeveloper/2026/09/29/wsl-containers-now-generally-available/)
- [GitLab 19.4.1 パッチリリース](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-1-released/)
