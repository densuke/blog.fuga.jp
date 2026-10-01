---
title: "「確かめた」のに破られる? rsync 3.5.0・Cisco SD-WAN・Ubuntu 26.10・Zimbra・PixelLeak、確認と実行のすき間（2026/10/2 Linux・OSSトレンド）"
date: 2026-10-02T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "rsync", "Debian", "Cisco", "SD-WAN", "Ubuntu", "Linux カーネル", "Zimbra", "AI エージェント", "GitHub"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「確かめた」と「実際に動く」のあいだには、小さなすき間があります。パスを確認した直後の一瞬、URL に混ぜた1文字、カーネルが完成する前の数日、修正版が出てから適用するまでの空白、AI が「できた」と判断してから人が確かめるまでの時間。今日の5本は、このすき間を軸に並べました。

なお、「すき間」という整理は書き手の考察で、出典の評価ではありません。

{{< youtube "ULgLpuvO_c4" >}}

## 1. rsync 3.5.0 — 33件のセキュリティ問題を一括修正、Debian は stable を 3.5.0 へ

最初はバックアップの定番、rsync です。[公式の NEWS](https://download.samba.org/pub/rsync/NEWS)によると、2026年8月13日にリリースされた 3.5.0 では、33件のセキュリティ問題がまとめて修正されました。9月28日には Debian が [DSA-6527-1](https://lists.debian.org/debian-security-announce/2026/msg00440.html) を出し、stable（trixie）の rsync を 3.5.0+ds1-0+deb13u1 へ更新しています。

Debian のメンテナー Samuel Henrique 氏は、[Lobsters のスレッド](https://lobste.rs/s/sqyhgt/major_rsync_upgrade_debian_because_33)で "In order to fix 33 CVEs, I have decided to bump the package to 3.5.0 rather than backporting all patches individually." と説明しています。個別にバックポートせず、版ごと上げる判断です。

「33件が全部の rsync に当てはまるのか」という点は、慎重に読む必要があります。NEWS は、多くの問題で影響範囲が「3.5.0 より前の全バージョン」より狭いと書いています。CVE ごとに、デーモンとして動かしているか、`use chroot = no` か、といった条件が違います。

最も深刻度が高いのは CVE-2026-53791 で、[NVD の API](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-53791) では CVSS 3.1 が 9.1（Critical）です。[GitHub のアドバイザリ](https://github.com/RsyncProject/rsync/security/advisories/GHSA-h2q9-5fr8-w635)と NEWS によれば、これは `proxy protocol = true` を有効にしたデーモンの問題です。信頼済みプロキシを経由せず直接つないだクライアントが、偽の PROXY ヘッダで接続元を詐称し、IP によるアクセス制御を回避できました。認証は不要です。3.5.0 では、転送アドレスを設定済みの信頼できるプロキシからのものだけ採用する作りになりました。

今回のテーマに最も近いのが、シンボリックリンクと TOCTOU（確認した時点と使う時点のずれ）です。たとえば CVE-2026-53783 は rrsync の問題です。NEWS によると、rrsync は引数を `realpath()` で検証したあと同じ名前で rsync を起動していたため、その間にリンクへ差し替えられる余地がありました。NVD では CVSS 3.1 で 8.1（High）です。

リンクの扱いで要になるのが `secure_relative_open()` の見直しです。[該当コミット](https://github.com/RsyncProject/rsync/commit/4fa7156ccdb2ad34b034d18fe2fd6cd79adef8a1)では、Linux 5.6 以降で `openat2(RESOLVE_BENEATH)` を使います。起点の外へ出るパスをカーネルに拒否させる方式です。古いカーネルでは、1要素ずつ `O_NOFOLLOW` で確かめる従来の方式に戻ります。ただしこのコミットの直接の目的は、先行する修正で壊れた `-K`（`--copy-dirlinks`）の正当なディレクトリリンクを通しつつ、範囲外は拒否するという回帰への対処です。

まずは `rsync --version` と、デーモンの設定を確かめてみてください。

## 2. Cisco Catalyst SD-WAN Manager — 認証回避 CVE-2026-76504、URL の1文字のエンコードで突破

2本目は Cisco の話です。[Cisco のアドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-sdwan-webauth-xr8beuuU)は、9月30日に公開されました。CVE-2026-76504 は Catalyst SD-WAN Manager の認証回避で、Cisco の評価は CVSS 3.1 で 9.8（Critical）、分類は CWE-177 です。[NVD](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-76504) でも同じ値を確認できます。アドバイザリには、9月中に Cisco PSIRT が悪用を把握したと書かれています。

手口は、`/j_security_check` を含むリクエストの URI にエンコードした文字を使うものです。Cisco は例として j を `%6a` にする方法を挙げています。[Rapid7 の解説](https://www.rapid7.com/blog/post/etr-critical-cisco-catalyst-sd-wan-manager-api-authentication-bypass-exploited-in-the-wild-cve-2026-76504/)は、Cisco の記述として `POST /%6a_security_check HTTP/1.1` という形を紹介し、エンコードした文字が1つあれば通る、とも書いています。

悪用が確認されているため、CISA は同じ9月30日に KEV（既知の悪用された脆弱性カタログ）へ追加しました。米連邦文民機関の対応期限は10月3日です。[Help Net Security](https://www.helpnetsecurity.com/2026/10/01/new-cisco-sd-wan-zero-day-exploited-in-the-wild-cve-2026-76504/)は、Cisco が悪用を明らかにしたのは今年5回目だと報じています。

対策は修正版への更新で、Cisco のアドバイザリによれば **回避策はありません** 。修正版は 20.9.10.1、20.12.8.2、20.15.6.1、20.18.4.1、26.1.2.1、26.2.1 です。

侵害の確認には、Cisco と [Field Effect](https://fieldeffect.com/blog/exploitation-cisco-catalyst-sd-wan-manager) が、`/var/log/nms/vmanage-server.log` などで `viptela-reserved-` で始まるユーザー名の記録と、エンコードされた `j_security_check` のリクエストを探すよう挙げています。通常の運用でも出うる記録なので、平常時と照らし合わせてください。

同じ種類の問題として知られる例には、2021年の Apache 2.4.49 の [CVE-2021-41773](https://blog.qualys.com/vulnerabilities-threat-research/2021/10/27/apache-http-server-path-traversal-remote-code-execution-cve-2021-41773-cve-2021-42013) があります。URL エンコードの扱いのずれを突いた点が似ています。これは書き手の整理で、Cisco がそう述べているわけではありません。

## 3. Ubuntu 26.10 — カーネルフリーズ後に Linux 7.3 へ切り替え、RC 段階で出荷の見込み

3本目は少し明るい話です。Ubuntu 26.10 のカーネルは、5月の時点では 7.2 を目標にしていました。Canonical カーネルチームの Kleber Souza 氏は9月1日、[Ubuntu Discourse](https://discourse.ubuntu.com/t/announcing-7-2-kernel-for-ubuntu-26-10-stonking-stingray/83393)で "Ubuntu 26.10 will now target the Linux 7.3 kernel instead of 7.2." と目標の変更を告げています。7.3-rc1 の段階での表明です。理由は、最新のアップストリームの機能、特に最新ハードウェア対応との整合を保つためとされています。10月1日にカーネルフリーズを迎え、最終リリースは10月15日の予定です。

[OMG! Ubuntu](https://www.omgubuntu.co.uk/2026/09/ubuntu-2610-kernel-version)によれば、Ubuntu の方針は、各リリースの開発期間中に開発されているアップストリームカーネルを載せることです。当初は8月30日頃と見込まれていた 7.2 が予定より早く出た一方、7.3 は10月15日の時点で安定版になっていない可能性が高く、同記事は RC 段階のまま出荷される見込みだとしています。

Linux 7.3 の安定版について、OMG! Ubuntu は10月末までに出る見込みとしています。[techaiwire の記事](https://techaiwire.com/articles/ubuntu-26-10-linux-7-3-prerelease-kernel/)は、順調なら10月18日、rc8 が入れば10月25日と報じていますが、これはスケジュールからの推定です。

7.3 の中身も、いくつか見ておきましょう。

- **Btrfs**: [Btrfs の pull request](https://lkml.iu.edu/2608.2/06723.html)によれば、ダイレクト I/O をバッファ I/O にフォールバックさせず、iomap のバウンスバッファで処理することで、性能が理論最大の約50%から約95%に上がります。また free space cache v1 がデフォルトで無効になります（v2 は 5.15 から mkfs の既定）。
- **メモリ管理**: [linuxcompatible の解説](https://www.linuxcompatible.org/story/linux-kernel-73-whats-new-in-the-upcoming-kernel-release/)によると、メモリ管理で1,250件のパッチ（前サイクルは920件）が入りました。[KSM のパッチ](https://ratatoskr.run/linux-mm/2026/06/17106628/t)は、約2万の VMA が1つの anon_vma を共有する条件で、ロック保持時間の最悪値が 705ms から 1.67ms になる計測です。

## 4. Zimbra CVE-2026-73570 — SNMP 通知の処理を突く無認証コマンドインジェクション

4本目は Zimbra Collaboration Suite です。CVE-2026-73570 は、[NVD](https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-73570) で CVSS 3.1 が 8.9（High）、CWE-78（OS コマンドインジェクション）です。10.1.20 より前で、オプションの zimbra-snmp が導入され、SNMP 通知が有効な場合に、認証なしで悪用できます。[Microsoft Security Blog（9月30日）](https://www.microsoft.com/en-us/security/blog/2026/09/30/unauthenticated-command-injection-on-internet-facing-mail-servers-tracking-cve-2026-73570/)によれば、入口は、シェルのメタ文字を含む細工した SMTP リクエストが SNMP 通知の処理に届くことです。

ここで動画の訂正をします。動画では「APT28・APT29 の関与が示された」と紹介しましたが、Microsoft の報告本文では、特定の攻撃グループ名は確認できませんでした。本文にあるのは "threat actors" という呼び方だけです。[CSA のリサーチノート](https://labs.cloudsecurityalliance.org/research/csa-research-note-zimbra-cve-2026-73570-snmp-nation-state-20/)も、特定の攻撃者が公に帰属されていないと書いています。

時系列は次のとおりです。

- 7月20日: Zimbra 10.1.20 が出て、修正が入った。
- 7月28日〜8月7日: Microsoft が、2種類のスキャンツールによる探査を観測した。
- 8月13日: CVE が公開された。
- 8月21日: CISA が KEV に追加した（NVD によれば期限は8月24日）。

つまり、修正版が出てから CVE の公開までの間にも、探査は始まっていました。この「修正版が出てから当てるまでの空白」が、今回のすき間です。

Microsoft が観測した攻撃チェーンも、細部まで確認しておきましょう。攻撃者は侵入後、JSP の Web シェルを公開ディレクトリへ置きました。次に正規の sudo 許可ヘルパーを悪用し、ログの zmmailboxd.out を PAM 設定へのシンボリックリンクに差し替えて、zimbra アカウントに NOPASSWD: ALL を与えています。Zimbra 既存の SSH 鍵でクラスターの他ノードへ入り、rsync で Web シェルなどを移しています。狙いは個人のパスワードでなく、認証系のシークレットで、zimbraAuthTokenKey を取得して任意アカウントのセッショントークンを作れる状態にしています。

AzCopy を Azure Blob の SAS URL 付きで実行した痕跡もありますが、転送の完了までは確認されていません。

被害の規模は、CSA によれば8月22日時点で274台以上が侵害され、8,200台超が未パッチです。これは CSA の数字で、Microsoft のものではありません。

対策の基本は、修正を含む 10.1.20 以降への更新です。Microsoft はあわせて、zimbra-snmp を外すか SNMP 通知を無効にし、SNMP と SMTP のアクセスを信頼できるホストに限ることを推奨しています。全ドメインの zimbraPreAuthKey のローテーションも挙げられています。

## 5. PixelLeak — AI エージェントが公開リポジトリに社内スクリーンショット13,000枚超

最後は AI エージェントの話です。Glow Labs が9月29日に公表した [PixelLeak の調査](https://www.glow.io/blogs/how-ai-agents-exposed-developer-screenshots-from-leading-tech-companies)によれば、AI コーディングエージェントが、コードレビューの画面などのスクリーンショットを GitHub の公開リポジトリに置き、13,000枚超の社内画像が公開状態になりました。900超のリポジトリが関わっています。影響を受けた組織は、Glow Labs と [Help Net Security](https://www.helpnetsecurity.com/2026/09/30/ai-coding-agents-github-screenshot-leak/) では300超、[The Register](https://www.theregister.com/ai-and-ml/2026/09/29/ai-models-keep-posting-screenshots-showing-sensitive-data-from-inside-tech-companies/5299640) は343社と報じています。CVE は、3つの出典のどれにも書かれていませんでした。

The Register によれば、きっかけは画像を PR に添付する手段の不足です。CLI から PR に画像を添付する API が、GitHub には無いと説明しています。Glow Labs は、Claude Code（Opus 5）でマインスイーパー風の UI を作る再現実験をしています。エージェントは "so I created a new public repo" と判断し、`sweeper-demo/pr-assets` という公開リポジトリにスクリーンショットを置きました。

広がり方も急でした。Glow Labs は、7月初旬から複数の開発者に使われるエージェントが画面を公開し始め、1週間で12超のエージェントがこの方法をスキルとして取り込んだと説明しています。ツールの gitshot は、既定の Releases 保存先の `_gitshot` タグに画像を置き、知っていれば誰でも取得できます。gitshot 自身の注意書きは、機密を既定の保存先に上げないよう警告しています。影響を受けた組織の約3分の1で gitshot が使われ、100超の公開アカウントが漏洩に関わったと Glow Labs は報告しています。この2つの数字は、単位が組織とアカウントで別のものです。

写っていたのは、顧客の請求データ、財務コンソール、未発表の製品機能、資金移動の画面などです。約93%のケースでは、画像は従業員が自分の個人名義で作ったリポジトリに置かれていました。

The Register に載った Omer Singer 氏（Glow Security の共同創業者兼 CTO）の発言は、"The biggest risk factor that we're seeing is in legitimate AI being used by developers, but then doing things that should not be done." です。最大のリスク要因は、開発者が使う正規の AI が、やってはいけないことをしてしまう点にある、という趣旨です。

Glow Labs が示す対策には、次のようなものがあります。

- 自社の組織の外にも目を向ける（個人アカウントを含む）。
- ファイルだけでなく、releases と gists も調べる。
- 無制限の自動承認をしない。
- gitshot などのツールを確認し、git 関連のツールを最新にする。

ここからは Glow Labs の推奨ではなく、一般的な確認のしかたです。GitHub CLI に紐づくアカウントとスコープは `gh auth status` で見られます。「AI が使えるようにしている」ことと、「AI が何をするかを確かめている」ことは、別の話です。

## まとめ

今日の5本を「すき間」で並べると、rsync はパスを確認した直後、Cisco は同じ住所の別の書き方、Ubuntu は RC のまま出荷される見込み、Zimbra は修正版が出てから当てるまでの空白、PixelLeak は AI が「できた」と判断した後でした。どれも、確認した「つもり」の段階と実際の動作が食い違うところで起きています。

個人的には、確認を「してある」ことより、「いつ、何に対して、誰がしているか」のほうが大事だと感じました。手元の rsync と Cisco SD-WAN Manager、Zimbra のバージョンと設定、そして AI エージェントに持たせているトークンの範囲を、一度確かめてみてはいかがでしょうか。

## 参考リンク

- [rsync NEWS](https://download.samba.org/pub/rsync/NEWS)
- [Debian DSA-6527-1](https://lists.debian.org/debian-security-announce/2026/msg00440.html)
- [Cisco アドバイザリ cisco-sa-sdwan-webauth-xr8beuuU](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-sdwan-webauth-xr8beuuU)
- [Rapid7: Cisco Catalyst SD-WAN Manager の認証回避](https://www.rapid7.com/blog/post/etr-critical-cisco-catalyst-sd-wan-manager-api-authentication-bypass-exploited-in-the-wild-cve-2026-76504/)
- [Ubuntu Discourse: 26.10 のカーネル](https://discourse.ubuntu.com/t/announcing-7-2-kernel-for-ubuntu-26-10-stonking-stingray/83393)
- [Microsoft Security Blog: Zimbra CVE-2026-73570](https://www.microsoft.com/en-us/security/blog/2026/09/30/unauthenticated-command-injection-on-internet-facing-mail-servers-tracking-cve-2026-73570/)
- [Glow Labs: PixelLeak](https://www.glow.io/blogs/how-ai-agents-exposed-developer-screenshots-from-leading-tech-companies)
