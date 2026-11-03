---
title: "GitLab CVE-2026-97229 は KEV の期限日に1000台超、Fedora 45 は11月3日の出荷予定、Linux 7.2 系は 7.2.15 で終了、Langflow は 1.13.0 で修正済み、LXD の証明書チェーンの穴（2026/11/03 Linux・OSSトレンド）"
date: 2026-11-03T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "GitLab", "Fedora", "Linux カーネル", "Langflow", "LXD", "AI"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

版番号が上がっても、その番号が指す中身が自分の環境に入っているとは限りません。今回の5本は、どれも「見えている部分」と「見えていない部分」のずれの話として読めます。Alpine Linux の GitLab は、版を上げても、修正が入っていない Ruby のまま動いていました。Fedora 45 は判定会議を通りましたが、確認時点では出荷前です。Linux 7.2 系は 7.2.15 で更新が止まり、そこに入った skb_zerocopy の修正は、番号の新しい 7.3.1 のコミットの件名には見当たりません。Langflow は修正版が先に出ていて、あとから CVE が公開されました。LXD は、証明書の鎖のうち、先頭の1枚しか鍵の所有を証明していませんでした。

この共通点は、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

この記事の確認は、2026年11月3日 6:30〜7:50（日本時間）に行いました。KEV は 6:30、Fedora の出荷状況は 7:23（11:36 に再確認）、Langflow の最新版は 7:34、kernel.org の releases.json は 7:48 の状態です。あとから変わりうる情報には、確認の時刻を添えました。

{{< youtube "NNKOjJ2OPSc" >}}

## 1. GitLab CVE-2026-97229 — Alpine Linux の作り直し、KEV の期限日の観測

この CVE の修正版（19.4.2・19.3.5・19.2.8）と影響範囲は、[10月13日の記事](https://blog.fuga.jp/posts/2026-10-13-linux-oss-trend/)の第1節にあります。ここでは繰り返さず、その後に分かった点を書きます。

### NVD の登録

10月13日の記事は、NVD への登録を確認できないと書きました。確認時点（11月3日 6:30 JST）の [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-97229) は、CVE-2026-97229 を分析済み（Analyzed）としています。CVSS v3.1 の 10.0（Critical）は、GitLab（CNA）の採点（Secondary）で、NVD 自身の採点はありません。弱点の種類は CWE-190（整数オーバーフロー）です。

### 条件の書き方は、出どころで違う

- GitLab のパッチノートは、[細工した正規表現を CI/CD の設定に書くことで、認証されていないユーザーが GitLab サーバー上で任意のコードを実行できるおそれがある](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-2-released/)と書いています
- セキュリティベンダーの Rapid7 は[技術分析](https://www.rapid7.com/blog/post/etr-cve-2026-97229-critical-unauthenticated-remote-code-execution-in-gitlab/)で、攻撃を再現してみると、公開プロジェクトのブランチに CI/CD の設定ファイルを置ける手段が要る、と書いています。新規ユーザーが自分で登録してプロジェクトを作れるインスタンスでは、この制約が外れる、と続きます

自己登録を許している GitLab かどうかは、自分の環境で確かめる点です。

### Alpine Linux の件

[Alpine Linux の告知](https://alpinelinux.org/posts/GitLab-security-incident-CVE-2026-97229.html)（10月28日の投稿、10月30日に追記）が書く経緯です。

- 10月20日と21日: 新規登録のアカウントが、細工した CI の設定を Alpine の GitLab に送りました。当時は 19.3.4 で、10月12日の修正が入っていませんでした。GitLab のワーカーが8回クラッシュし、うち4回は、攻撃が途中まで進んで次の段階で失敗しました。Alpine は、修正入りと書く 19.3.5 ではなく、誤って 19.3.4 に上げた、と書いています
- 10月22日: 19.3.6（10月21日公開）に上げましたが、脆弱性は直りませんでした。修正は GitLab 自身のコードではなく、Ruby へのパッチで、GitLab は公式のパッケージにだけそれを適用します。Alpine のイメージは標準の Ruby だったので、パッチが入っていませんでした
- 10月27日: GitLab を開発者とビルドサーバー以外に閉じ、再構築を始めました。このとき公開したイメージの Ruby は 3.3.13 です
- 10月28日: 再構築が完了し、全パスワードを入れ替え、GitLab の秘密鍵も替えました
- 10月29日: 19.3.7 で再開しました

Alpine の留保も、そのまま残します。攻撃が成功した証拠は見つかっていないが、排除もできないので、侵害されたものとして作り直した、と書いています。攻撃者が Alpine の GitLab のコンテナイメージをダウンロードしていたことから、Alpine のビルドに合わせて攻撃を調整していたことがうかがえる（"suggests"）、とも書いています。パッケージとリリースの署名鍵は GitLab のサーバーに置いておらず、改ざんの形跡もない、というのが Alpine の説明です。改ざんの検証は、10月27日まで範囲を広げている途中、と書かれています。

### 自前のビルドは、Ruby も確かめる

GitLab は、[19.5.1 のパッチノート](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-5-1-released/)で、公式のパッケージ以外（自前のビルドや独自のコンテナイメージ）では、GitLab の更新だけでは足りず、Ruby も 3.3.13・3.4.12・4.0.9 以降へ上げる必要がある、と書いています。[ruby-lang.org の告知](https://www.ruby-lang.org/en/news/2026/10/23/regexp-fixes-for-gitlab-cves/)も同じ版を挙げます。数字は系列ごとの下限です。3.3 系なら 3.3.13 以降、3.4 系なら 3.4.12 以降、4.0 系なら 4.0.9 以降になります。

### KEV の期限と、Shadowserver の観測

CISA の悪用確認済みカタログである [KEV](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json) への追加は10月29日（木）、期限は11月1日（日）です。根拠は BOD 26-04 で、[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/10/29/cisa-adds-one-known-exploited-vulnerability-catalog)によれば、この指令が適用されるのは連邦民間行政機関（FCEB）だけです。

[BleepingComputer](https://www.bleepingcomputer.com/news/security/over-1-000-gitlab-servers-vulnerable-to-code-execution-attacks/) によれば、Shadowserver は11月1日（日曜。KEV の期限日）に、CVE-2026-97229 に脆弱なインスタンスを1000超、CVE-2026-110264 に脆弱なものを11300超（毎日観測している約3万9000のうち）と発信しました。11月3日の数字ではありません。

### CVE-2026-110264

同じ正規表現エンジン（Onigmo）の別の欠陥です。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-110264) の CVSS v3.1 は 10.0 で、採点は GitLab（CNA）です。NVD 自身の分析はありません。10月21日公開の 19.5.1・19.4.3・19.3.6・19.2.9 などで直り、影響は 7.0 以降の古い系列にまで及びます。確認時点（6:30）の KEV には載っていません。

### 回避策

GitLab のパッチノートに、回避策の記載は見当たりません。Rapid7 は、露出を下げる措置として、公開プロジェクトへの匿名アクセスの制限と、信頼できない利用者による公開プロジェクトの作成・書き込みの禁止を挙げています。ただし、これは確かめられた攻撃経路への対策で、欠陥のある正規表現コンパイラそのものは直らない、と Rapid7 は書いています。GitLab.com は、パッチ済みの版で動いています。Dedicated は、パッチノートの公開前に、内部のリリースでパッチ済みです。

動画の訂正です。

- 動画では、自前ビルドの確認として、Ruby が 3.3.13 以上か、同等の修正が入っているかを見るよう紹介し、画面にも「Ruby 3.3.13 以上か同等の修正か」と出しました。修正を含む Ruby は、系列ごとに 3.3.13・3.4.12・4.0.9 以降です。「3.3.13 以上」と読むと、修正を含まない 3.4.0〜3.4.11 や 4.0.0〜4.0.8 まで入ってしまいます（[GitLab のパッチノート](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-5-1-released/)、[ruby-lang.org](https://www.ruby-lang.org/en/news/2026/10/23/regexp-fixes-for-gitlab-cves/)）。
- 動画では、Shadowserver の観測を放送の日（11月3日）の時点の数字として紹介し、期限から2日過ぎてもそれだけ残っている、と話しました。画面にも同じ趣旨を出しています。Shadowserver の発信は11月1日（日曜）で、KEV の期限日そのものです。期限から2日は経っていません（[BleepingComputer](https://www.bleepingcomputer.com/news/security/over-1-000-gitlab-servers-vulnerable-to-code-execution-attacks/)、KEV の期限は11月1日）。

## 2. Fedora 45 — 出荷は11月3日（火）の予定

確認時点（11月3日 7:23 JST。11:36 JST に再確認しても同じ）で、Fedora の [releases.json](https://fedoraproject.org/releases.json) に Fedora 45 の正式版は載っておらず、Fedora Magazine にも正式版の告知は出ていません。GO の[告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)（10月29日、UTC）は、"will be shipped live on Tuesday, 3 November 2026" と書き、時刻は書いていません。動画の公開は日本時間の11月3日 5:54（UTC の11月2日 20:54）で、確認時点より前なので、動画の時点でも出荷前でした。この記事を読む時点で状況が変わっていないかは、releases.json か Fedora Magazine で確かめてください。

GO は、UTC の10月29日の会議で、RC-1.4 に対して出ました（[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-29/f45-final-go-no-go-meeting.2026-10-29-18.02.html)。GO の決定は 19:22 UTC、日本時間では10月30日 4:22）。2回の NO-GO の経緯、DRM Panic、RPM の署名、Podman、oo7 は、[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)と[10月30日の記事](https://blog.fuga.jp/posts/2026-10-30-linux-oss-trend/)にあります。ここでは、それらに無い点を書きます。

### ptrace の既定

Fedora 45 は、ptrace の既定を絞ります。[Change のページ](https://fedoraproject.org/wiki/Changes/Restrict_ptrace_by_default)は、確認方法として、`kernel.yama.ptrace_scope = 1` になっていることを挙げています。依存の向きに注意が要ります。strace・gdb・lldb などのデバッグツールのほうが、`yama-ptrace-enable` を弱い依存（Recommends）として持ち、それが入ると、制限が外れて `ptrace_scope = 0` になります。gdb-headless と gdb-minimal は対象外です。ptrace の制限は、9月16日の記事の[第4節](https://blog.fuga.jp/posts/2026-09-16-linux-oss-trend/)でも扱いました。

### ツールチェーンの版

[Fedora のパッケージ検索](https://packages.fedoraproject.org/pkgs/golang/golang/)（packages.fedoraproject.org）の、確認時点の Fedora 45 のリポジトリの Stable では、Python が 3.15.0、Go が 1.27.3、GCC が 16.2.1、Podman が 6.1.3、OpenSSL が 4.0.3 です。出荷メディアに入る版ではなく、確認時点のリポジトリの状態です。デスクトップは、gnome-shell が 51.1、KDE の plasma-workspace が 6.8.2 です。

### そのほか

- カーネル: 確認時点で、Fedora 45 のカーネルは 7.2 系で、Stable が 7.2.14、Testing が 7.2.15 です。7.2 系は11月1日に更新が終わりました（第3節）。Fedora の更新予定は、一次では確かめていません
- kmscon: [Change のページ](https://fedoraproject.org/wiki/Changes/UseKmsconVTConsole)は、Unicode と全角（double-width）文字の扱いが改善する、と書いています。[Fedora Magazine の記事](https://fedoramagazine.org/modernizing-the-console-with-kmscon/)は、setfont と loadkeys が kmscon では効かない、と書いています
- Asahi Remix: [Fedora Magazine の告知](https://fedoramagazine.org/announcing-fedora_asahi_remix_45_beta/)（9月15日）によれば、Fedora Asahi Remix 45 Beta は、Apple の M3・M3 Pro・M3 Max を初期サポートします。Asahi Linux 本体の M3 対応は、[9月8日の記事](https://blog.fuga.jp/posts/2026-09-08-linux-oss-trend/)の第4節にあります
- Fedora 43 のサポート終了: 12月上旬までです。具体的な日付は、二次の情報しか確認できていないので書きません

動画の訂正です。

- 動画では、Fedora 45 が放送の日に正式にリリースされた、と紹介し、黒板にも実際の日を11月3日と出しました。放送時点（日本時間の11月3日 5:54）では、出荷前でした。告知の予定は11月3日（火）で、確認時点（7:23）でも releases.json に正式版はありません（[告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)、[releases.json](https://fedoraproject.org/releases.json)）。
- 動画では、RC-1.4 が11月2日に GO になった、と紹介し、黒板にも「11月2日」と出しました。GO は UTC の10月29日の会議です（[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-29/f45-final-go-no-go-meeting.2026-10-29-18.02.html)）。
- 動画では、eMudhra について、インドの IT 法に基づいて認定されたルート CA だが、手続き面の懸念から扱いが問題になった、と紹介しました。問題になったのは、eMudhra の中間 CA 証明書8件の秘密鍵が漏えいしたことです。Mozilla の Bugzilla は、8件の鍵がいずれも256未満の整数だったと書いています（[Bugzilla 2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)）。経緯は[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)にあります。
- 動画では、1回目の10月15日は、リリース候補のメディアが会議の時点で用意できていなかった、と紹介し、黒板にも「候補メディア未整備」と出しました。10月15日は告知の日付で、告知は、適切なリリース候補が無かったので、既定で NO-GO（"NO-GO by default"）と書いています。会議で判定したとは書いていません。判定会議が開かれたのは、10月22日と10月29日です（[告知](https://www.mail-archive.com/devel@lists.fedoraproject.org/msg215769.html)）。

## 3. Linux 7.2.15 — 7.2 系はこれで最後

7.2.15 は、11月1日（UTC の 12:44、日本時間では 21:44）に公開されました。[Greg Kroah-Hartman 氏のアナウンス](https://lwn.net/Articles/1104629/)（LWN の転載。lore の原文は取得できていません）は、これが最後の 7.2.y（"the LAST 7.2.y kernel release"）で、7.3.y へ移るよう書いています。通常より少し早く終わった、とも書いており、これは Greg 氏の言葉です。7.2 は8月16日（UTC）に出ていて、11月1日までは77日です（書き手の算術）。

Greg 氏は、7.2 を続けると、8本のブランチを同時に保守することになり、最良の条件でも負担が重い（"a taxing task under the best of times"）と書いています。仮定形の文です。LWN の転載の範囲に内訳はありません。7.3.y と 7.2.y に、後述の長期サポート版6本を足すと8本になります（書き手の算術）。

### 移行先

確認時点（11月3日 7:48 JST）の [releases.json](https://www.kernel.org/releases.json) で、最新の安定版は 7.3.1（10月30日）です。7.2.16 はありません。長期サポート版は6本で、6.18・6.12・6.6・6.1・5.15・5.10です。[kernel.org の表](https://www.kernel.org/category/releases.html)の予定終了は、6.18 と 6.12 が2028年12月、6.6 と 6.1 が2027年12月、5.15 と 5.10 が2026年12月です。6.18 は最新の長期サポート版です。

7.3 系へ移れば、今回の修正が入る、とは言えません。7.3.1 のコミットの件名に、skb_zerocopy・ksmbd・smbdirect の修正はありません。skb_zerocopy の upstream の修正は v7.4-rc1 に入っていて、v7.3 には入っていません。この修正が 7.3 系のどの版に入るかは、確認時点で確かめられていません。ksmbd と smbdirect の修正が v7.3 に入っているかも、確かめていません。

### 差分の数え方

v7.2.14 から v7.2.15 までで、[13コミット](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.15)（版番号を上げる1本を含む）、15ファイル、追加498行・削除109行です。版番号の1本を除くと、パッチは12本です。

### skb_zerocopy

[コミット](https://github.com/gregkh/linux/commit/d7d6ff98d5d1)（作者は Zizhen Liu 氏）の説明は、skb_zerocopy() が、元の skb の持つページキャッシュ由来の領域であることを示す目印を、コピー先に引き継がないことを問題にしています。ESP の入力処理は、その目印を見て、その場での復号を避けるかを決めます。目印が落ちると、nfnetlink_queue か openvswitch の upcall のために作った skb がその場で復号され、権限のないユーザーが root 所有の読み取り専用ファイルのページキャッシュに書き込めるおそれがある、と説明しています。

[10月27日の記事](https://blog.fuga.jp/posts/2026-10-27-linux-oss-trend/)の第2節で扱った skb_zerocopy の問題と、同じ関数・同じフラグ（`SKBFL_SHARED_FRAG`）の修正で、同記事がリンクしたパッチ（v2）がそのまま取り込まれました。ただし、コミットには、ZDI の番号も Reported-by もありません。ZDI-CAN-33367 や特定の CVE と結びつけることは、ここではしません。CVE は、確認時点（11月3日 7:47 JST）で、NVD のキーワード検索では見つかりませんでした。カーネルの CNA 側は確認できていません。

### ksmbd の2件

- [c13279523ed5](https://github.com/gregkh/linux/commit/c13279523ed5): 失敗した接続が待ち行列に残り続け、認証されていない相手が、ksmbd の SMB-Direct の接続の受け付けを止められました。Stefan Metzmacher 氏の関連する3本のうち、この件を述べるのは1本です
- [aaf8a64a3fbf](https://github.com/gregkh/linux/commit/aaf8a64a3fbf)（Namjae Jeon 氏）: ネゴシエーションが終わる前に次の PDU を読むため、先に届いた短い SMB1 の要求を、SMB2 の処理で扱って、バッファの外を読むおそれがありました

どちらも、10月27日の記事の ZDI-CAN-33774・33549 と同一視しません。コミットがそれらを参照していないためです。

### Assisted-by

12パッチのうち4パッチに、Assisted-by の行があります。Bluetooth の1本（Radek Podgorny 氏）は `Assisted-by: Claude:claude-opus-5`、smbdirect の3本（Metzmacher 氏）は `Assisted-by: Claude:claude-opus-5-5` です。タグの要求の削除が v7.4-rc1 に入った経緯は、[11月2日の記事](https://blog.fuga.jp/posts/2026-11-02-linux-oss-trend/)の第3節にあります。

動画の訂正です。

- 動画では、15ファイル、追加498行、削除109行の差分に、8本のパッチが入っている、と紹介し、黒板にも「8パッチ」と出しました。ファイル数と行数は合っています。コミットは13本で、版番号を上げる1本を除くと12パッチです（[ChangeLog](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.15)）。
- 動画では、skb_zerocopy の影響する処理として、AF_XDP や TLS offload などを挙げ、黒板にも出しました。コミットが挙げる経路は、ESP の入力処理と、nfnetlink_queue・openvswitch の upcall です（[コミット](https://github.com/gregkh/linux/commit/d7d6ff98d5d1)）。
- 動画では、ksmbd の修正を、SMB2 のメッセージを SMB1 と取り違えるバグ、と紹介し、黒板にも「SMB2をSMB1と誤認」と出しました。向きが逆です。先に届いた SMB1 の要求を、SMB2 の処理で扱います（[コミット](https://github.com/gregkh/linux/commit/aaf8a64a3fbf)）。
- 動画では、長期サポート版を 6.18、6.12、6.6、6.1 と紹介し、黒板にも出しました。確認時点の releases.json の長期サポート版は、5.15 と 5.10 を加えた6本です。この2本の予定終了は、2026年12月です（[releases.json](https://www.kernel.org/releases.json)）。

## 4. Langflow — 修正版は出ている、自動ログインの初期値が焦点

修正版の Langflow 1.13.0 は公開済みです。[PyPI](https://pypi.org/project/langflow/1.13.0/) も GitHub も、UTC の10月22日 21:20（日本時間では10月23日 6:20）で、IBM の開示より前に出ていました。確認時点（11月3日 7:34 JST）の PyPI の最新版も 1.13.0 です。

### IBM の開示

[IBM のアドバイザリ](https://www.ibm.com/support/pages/node/7294467)（10月28日付）は、Langflow の4件を載せ、1.0.0〜1.12.8 を 1.13.0 へ上げるよう強く勧めています。回避策の欄は "None" です。IBM が CNA として登録した Langflow の CVE は、UTC の10月29日公開の33件でした（NVD で数えました）。アドバイザリのページに33件が載っているわけではありません。

### CVE-2026-93680

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-93680) の CVSS v3.1 は 9.8（Critical）で、採点は IBM（CNA、Secondary）です。NVD 自身の採点は見当たりませんでした。説明文は「不適切な認証」で、自動ログインの語はありません。

自動ログインの中身は、[Langflow のドキュメント](https://docs.langflow.org/api-keys-and-authentication)に書かれています。来た相手を、設定したスーパーユーザーとして、自動でサインインさせる機能です。1.13.0 で、[公式のパッケージと Docker イメージの初期値が false になりました](https://github.com/langflow-ai/langflow/pull/14993)。開発ブランチは true のままです。IBM は、この CVE を、自動ログインの対策の不完全な修正（"an incomplete remediation of an auto-login security control"）と要約しています。

### CVE-2026-110186

NVD の記録は、コード生成の不適切な制御（CWE-94）で、CVSS v3.1 は 9.8、採点は IBM（CNA、Secondary）です。93680 との連鎖は、[Ostorlab](https://blog.ostorlab.co/langflow-auto-login-auth-bypass-cve-2026-93680.html) が、認証なしのリクエストからスーパーユーザーのセッションを得て、サーバー側のコード実行に至る、と分析しているものです。IBM のアドバイザリや NVD に、連鎖の記載はありません。

### 過去の悪用と、Metasploit

- CVE-2026-33017: 3月の脆弱性です。NVD の CVSS v3.1 は 9.8（NVD 自身の採点）です。[Sysdig](https://www.sysdig.com/blog/cve-2026-33017-how-attackers-compromised-langflow-ai-pipelines-in-20-hours) によれば、アドバイザリの公開から20時間以内に、最初の攻撃を観測しました。Sysdig 自身のハニーポットでの観測です
- CVE-2026-0768: [9月3日の記事](https://blog.fuga.jp/posts/2026-09-03-linux-oss-trend/)で扱いました
- Metasploit: CVE-2026-93680 の補助モジュールが、UTC の10月8日に Metasploit Framework に取り込まれました。CVE の登録より前です。[The Hacker News](https://thehackernews.com/2026/11/critical-langflow-flaws-could-let.html) によれば、機能は、認証なしでセッションを取り、サーバーのツールを一覧するもので、コードは実行しません

### 確かめること

IBM は回避策を「無し」としています。Langflow のドキュメントには、一般的な勧めとして、`LANGFLOW_AUTO_LOGIN=False` にすること、既定以外の `LANGFLOW_SECRET_KEY` を使うこと、ポートを直接インターネットに出さないことが書かれています。既定の URL は `http://localhost:7860` です。ただし、IBM は 93680 を自動ログインの対策の不完全な修正と要約しており、旧版でこの設定が穴を塞ぐとは、一次に書かれていません。IBM が勧めているのは 1.13.0 への更新です。まず Langflow の版を確かめてください。

動画の訂正です。

- 動画では、CVE-2026-110186 の原因を、部品のコードを検証する API が、入力を十分に隔離せず exec 関数に渡すこと、と紹介しました。CVE の記録、IBM、GitHub のアドバイザリの説明は、コード生成の不適切な制御までで、検証用の API や exec 関数への受け渡しは書かれていません（[CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-110186)）。

## 5. LXD・MicroCloud CVE-2026-112816 — 証明書チェーンの先頭1枚しか証明されていない

LXD は、コンテナと仮想マシンの管理ツールです。[Canonical のアドバイザリ](https://discourse.ubuntu.com/t/security-advisory-critical-vulnerability-found-in-canonical-lxd-and-microcloud/90557)によれば、LXD の HTTPS の API が、相互 TLS の認証で、クライアントが送った証明書をすべて信頼ストアと照合していました。ところが、鍵の所有を証明するのは、先頭の1枚（リーフ証明書）だけです。そのため、API に届く攻撃者は、信頼済みの公開証明書をチェーンの中間に置くだけで、別の ID として認証できました。

コードの水準の説明は、Incus の[修正コミット](https://github.com/lxc/incus/commit/8381e54c3631c627d7ecdec03945bca14d0bd542)にあります。チェーン全体をループして、どれか1枚でも信頼済みなら通していました。Incus は、すべての照合で先頭の証明書だけを見る形に直しました。LXD は、Canonical のアドバイザリによれば 6.10.1・5.21.9・5.0.11・4.0.15 で修正されます。LXD 側の修正の中身は、公開リポジトリで差分を確かめられなかったので、断定しません。

### 記録

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-112816) の CVSS v4.0 は 10.0（Critical）で、採点は Canonical（CNA、Secondary）です。NVD の分析は保留（Deferred）です。[CVE の記録](https://www.cve.org/CVERecord?id=CVE-2026-112816)の ADP（CISA）は、2026年10月30日付で、SSVC を Exploitation が none、Automatable が yes、Technical Impact が total としています。KEV には、確認時点（11月3日 6:30 JST）で載っていません。

報告者は、CVE の記録では Stéphane Graber 氏です。肩書は、Incus の最初の保守者の一人で、[The Register](https://www.theregister.com/2023/08/04/incus_lxd_fork/) によれば LXD の元リードエンジニアです。Incus を作ったのは、Aleksa Sarai 氏です（[linuxcontainers.org の告知](https://linuxcontainers.org/incus/announcement/)）。「初期のリリースからこの状態だった」というのは、[Incus のアドバイザリ](https://github.com/lxc/incus/security/advisories/GHSA-xg75-xf37-cph9)の記述で、Incus の話です。

### 時系列

- Canonical の投稿は UTC の10月28日、アドバイザリの表の日付は10月29日です
- snap の stable チャンネルに載った時刻は、版ごとに違います（snap ストアの公開 API）。LXD の 6/stable は UTC の10月29日 1:10、5.21・5.0・4.0 は UTC の11月1日 5:10（日本時間 14:10）、MicroCloud の 2 と 3 は UTC の10月29日 21:28 です。アドバイザリが進行的なロールアウトと書いているので、全員に届いた時刻ではありません
- Incus 7.6.0 は UTC の10月30日、CVE の記録は UTC の10月30日（日本時間 10月31日）です

### 影響を受ける条件

- LXD: `core.https_address` を設定せず、ローカルのソケットだけで使っているなら、ネットワークからは届きません（[LXD のドキュメント](https://documentation.ubuntu.com/lxd/latest/howto/server_expose/)）
- Ubuntu: アーカイブの lxd は、影響なしか、パッケージが無い、と [ubuntu.com の CVE ページ](https://ubuntu.com/security/CVE-2026-112816)は書いています。snap 版は対象です
- MicroCloud: Canonical は、参加するクラスターメンバーの公開証明書が傍受されうると書いています

### 更新と暫定策

Canonical の更新手順は、`sudo snap refresh lxd` と `sudo snap refresh microcloud` です。修正版はチャンネルごとに違い、6/stable は 6.10.1、5.21/stable は 5.21.9、5.0/stable は 5.0.11、4.0/stable は 4.0.15、MicroCloud の 3/stable は 3.4.1、2/stable は 2.1.5 です。更新後に `snap list` で版を確かめるのは、書き手の助言です。

Canonical のアドバイザリに暫定策はありません。Incus のアドバイザリは、HTTPS のリスナーへのネットワークアクセスを信頼できるホストに限ること、設定で避ける方法は無いことを書いています。LXD の HTTPS の既定のポートは 8443 です（ソースコードの定数）。

### 実証コードの状況

確認時点で、GitHub に、検証用・検出用・更新用をうたう関連のリポジトリが現れています。[The Hacker News](https://thehackernews.com/2026/11/critical-lxd-and-microcloud-flaw-cvss.html) は11月1日時点で、動作する攻撃コードは公開されていないと書きました。第三者による検証は確認できませんでした。

動画の訂正です。

- 動画では、Graber 氏を、LXD の元リード開発者で、2023年に Incus というフォークを立ち上げた人、と紹介しました。Incus を作ったのは Aleksa Sarai 氏で、Graber 氏は Incus の最初の保守者の一人です（[linuxcontainers.org の告知](https://linuxcontainers.org/incus/announcement/)）。

## まとめ

GitLab は、公式のパッケージ以外では、版を上げても Ruby に修正が入らなければ直りません。Fedora 45 は、GO が出ても、確認時点では出荷前です。Linux 7.2 系は 7.2.15 で終わり、7.3 系へ移っても、今回の修正が入るかは確かめられていません。Langflow は、修正版が先に出ていて、自動ログインの初期値が焦点です。LXD は、鎖の先頭の1枚しか鍵の所有を証明していませんでした。

5本を並べて見ると、表示されている番号や状態と、中身のあいだに、それぞれ別のずれがあります。これは書き手の考察です。自分の環境でどの部分を見ていないかを、確かめる手がかりにしてください。

まず確かめることを挙げます。

- GitLab: 自分の版が影響範囲かを確かめ、修正版へ上げる。公式のパッケージ以外なら、Ruby の版も、系列ごとの下限（3.3.13・3.4.12・4.0.9）以上かを確かめる。自己登録を許しているかも見る
- Fedora: 出荷の状況を releases.json か Fedora Magazine で確かめる。更新の前に、RPM の署名、Podman 6、ptrace の制限を見る
- Linux 7.2 系: 7.2 系のカーネルを使っているなら、7.3 系か長期サポート版への移行先を決める。7.2 系には、今後の修正は出ない
- Langflow: 版を確かめ、1.13.0 に上げる。`LANGFLOW_AUTO_LOGIN` の値と、ポートの公開範囲も見る
- LXD: `core.https_address` を設定しているかを確かめる。設定していれば、`snap list` で、自分のチャンネルの修正版（6.10.1・5.21.9・5.0.11・4.0.15、MicroCloud は 3.4.1・2.1.5）になっているかを確かめ、HTTPS への到達範囲を絞る

## 参考リンク

- [GitLab: 19.4.2 のパッチリリース](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-4-2-released/)
- [GitLab: 19.5.1 のパッチリリース](https://docs.gitlab.com/releases/patches/patch-release-gitlab-19-5-1-released/)
- [Alpine Linux: GitLab のセキュリティインシデント](https://alpinelinux.org/posts/GitLab-security-incident-CVE-2026-97229.html)
- [Ruby: GitLab の CVE のための正規表現の修正](https://www.ruby-lang.org/en/news/2026/10/23/regexp-fixes-for-gitlab-cves/)
- [Rapid7: CVE-2026-97229 の技術分析](https://www.rapid7.com/blog/post/etr-cve-2026-97229-critical-unauthenticated-remote-code-execution-in-gitlab/)
- [Fedora 45 Final の GO の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03870.html)
- [Fedora Change: ptrace の制限](https://fedoraproject.org/wiki/Changes/Restrict_ptrace_by_default)
- [Greg Kroah-Hartman 氏のアナウンス（LWN の転載）](https://lwn.net/Articles/1104629/)
- [Linux 7.2.15 の ChangeLog](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.15)
- [kernel.org の releases.json](https://www.kernel.org/releases.json)
- [IBM: Langflow のアドバイザリ](https://www.ibm.com/support/pages/node/7294467)
- [Langflow: 認証と API キー](https://docs.langflow.org/api-keys-and-authentication)
- [Canonical: LXD・MicroCloud のセキュリティアドバイザリ](https://discourse.ubuntu.com/t/security-advisory-critical-vulnerability-found-in-canonical-lxd-and-microcloud/90557)
- [Incus の修正コミット](https://github.com/lxc/incus/commit/8381e54c3631c627d7ecdec03945bca14d0bd542)

（2026/11/03 Linux・OSSトレンド）
