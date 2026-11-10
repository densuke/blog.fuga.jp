---
title: "Chrome の CVE-2026-125350 は野外での悪用を Google が把握、Linux 7.5 向けの ChaCha AVX-512 は v2 の測定で約2倍、Linux 7.3 は2026年の LTS にまだ指定されていない、Broadcom の VM API は v1alpha1 で CNCF Sandbox へ、KEV に追加の4件は期限が11月12日（2026/11/11 Linux・OSSトレンド）"
date: 2026-11-11T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Chrome", "Linux カーネル", "Linux 7.3", "LTS", "AMD", "Kubernetes", "CNCF", "OpenSSH", "IBM"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

2026年11月11日の動画のテーマは、「今すぐ塞ぐべき穴と、何年もかけて育てる仕組み。技術ごとに違う『時計の速さ』を見分ける回」でした。取り上げた5本は次のとおりです。Chrome には、野外での悪用を Google が把握している8本目のゼロデイが出ました。Linux 7.5 に向けて、ChaCha の AVX-512 版と AMD の AIE4 の準備が進んでいます。Linux 7.3 は、2026年の LTS にするかどうかがまだ決まっていません。Broadcom は、VM 向けの API を CNCF の Sandbox に寄贈しました。CISA の KEV には4件が追加され、期限は11月12日です。

5本に「時計の速さ」の共通点を見るのは書き手の考察で、各社や各プロジェクトの主張ではありません。動画の内容に誤りや裏付けの取れないものがあった場合は、各節の末尾に訂正を載せました。

確認は2026年11月11日の朝（日本時間）に行いました。版の番号、NVD の状態、レビューの状況のように時点で変わるものには、本文で確認した時刻を添えています。

{{< youtube "90peygF1j6c" >}}

## 1. Chrome CVE-2026-125350 — 野外での悪用を Google が把握

[Chrome Releases ブログ](https://chromereleases.googleblog.com/2026/11/stable-channel-update-for-desktop_018223192.html)は、Stable チャンネルを、Windows と Mac が 157.0.8103.50 と .51、Linux が 157.0.8103.50 に更新したと書いています。ブログの日付は11月9日（月、米国の表記）で、配布は数日から数週間かけて進むとあります。更新には9件のセキュリティ修正が含まれます。

CVE-2026-125350 は、XML の Use-After-Free です。ブログは重大度を High とし、報告者は匿名（報告日は11月6日）です。ブログには、"Google is aware that an exploit for CVE-2026-125350 exists in the wild."（Google は、CVE-2026-125350 のエクスプロイトが野外に存在することを把握している）とあります。攻撃者や標的についての記載は、ブログにありません。バグの詳細は、多くのユーザーが更新するまで制限されることがある、とも書かれています。

[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-125350)の説明は、157.0.8103.50 より前の Chrome で、リモートの攻撃者が、細工した HTML ページ経由で、サンドボックスの内側で任意のコードを実行できた、というものです。サンドボックスの内側と限定している点に注意してください。NVD の状態は、11月11日 7:49（日本時間）の取得時点で Analyzed です。NVD 自身の採点はなく、CISA-ADP（Secondary）の CVSS v3.1 が 8.8（High）です。Chrome 側の CNA は CVSS を付けていません。

CISA は、この CVE を11月10日に [KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-125350) に追加し、期限を11月24日（火）としています。KEV の製品名は Chromium です。Edge や Brave など、Chromium を基にする製品は、各社の更新を確認してください。各社の告知は、確認できていません。

「今年8本目」は、[BleepingComputer](https://www.bleepingcomputer.com/news/security/google-patches-eighth-chrome-zero-day-exploited-in-attacks-this-year/)の数え方です。Google のブログは番号を付けていません。KEV の追加日で数えても、2026年の Chrome 系は8件です（2月17日、3月13日に2件、4月1日、6月9日、9月4日、9月9日、11月10日）。[9月7日の記事](https://blog.fuga.jp/posts/2026-09-07-linux-oss-trend/)は CVE-2026-85046 を「今年6本目」と書いており、日付順の数え方は同じです。

同じ更新には、XML の Use-After-Free がもう1件（CVE-2026-125346）あります。悪用の記載があるのは CVE-2026-125350 だけです。

動画の訂正はありません。

## 2. Linux 7.5 向けの ChaCha AVX-512 と AMD AIE4

ChaCha は、WireGuard や IPsec で使われるストリーム暗号です。Linux の x86 向け実装は、2018年のコミット [cee7a36ecb5b](https://github.com/torvalds/linux/commit/cee7a36ecb5bafef8c87fb2c10641e6125044154) で AVX-512VL 版が入りました。コミットメッセージは、"It uses ymm registers only to avoid the massive core throttling on Skylake-X platforms."（Skylake-X でコアが大きく絞られるのを避けるため、ymm レジスタだけを使う）と書いています。書いたのは、今回の投稿者でもある Martin Willi 氏です。

Martin Willi 氏は、7月22日（水）に、16ブロックをまとめて処理する AVX-512 版を[投稿](https://lore.kernel.org/linux-crypto/20260722153247.630519-1-martin@strongswan.org/)しました（v1）。512バイトを超える入力でだけ新しい経路を使い、`X86_FEATURE_PREFER_YMM` が立つ CPU では従来の ymm 版を使い続けます。v1 の説明は、クロックが下がる問題は、より新しい世代の AVX-512 では無くなっているとしています。Eric Biggers 氏は、同日の返信で、既存の実装とマクロで共通化するよう提案しました。8月6日（木）には kernel test robot が、v1 のビルドエラーを報告しています。

測定値は版によって違います。v1 では、Zen 5 の tcrypt で 4.2 GB/s が 7.5 GB/s、約1.8倍と書かれていました。11月2日（月）の[v2（3本）](https://ratatoskr.run/linux-crypto/2026/11/17843762/t)は、ChaCha の KUnit で測り直しています。Zen 5 の Strix Halo で、1024バイトが 4786 MB/s から 9401 MB/s（+96.4%）、768バイトが +99.1% です。1420バイトでは、16ブロックの呼び出しのあとに8ブロックの呼び出しが続くため、伸びは半分程度（Strix Halo で +49.7%）と書かれています。ここで見ているのは暗号処理の速度で、VPN 全体の伸びではありません。lore は bot 判定で本文を取得できなかったため、v2 以降は Ratatoskr のミラーで読みました。

状況は、11月3日（火）に変わりました。Eric Biggers 氏が v2 の3本に "Applied to" と返信し、メンテナの libcrypto-next ツリーに適用しています。Torvalds 氏のメインラインにはまだ入っていません。なお、ツリーのコミット自体は取得できておらず、確認できたのは返信のメールまでです。10月12日（月）に Martin Willi 氏が触れた9本のシリーズは、手元にあるがまだ投稿していないものです。v2 の説明も、より大きなシリーズにはまだ作業が要ると書いています。

AMD の AIE4 は、amdxdna ドライバの話です。Lizhi Hou 氏（AMD）が、19本のシリーズに10月21日（水）に "Applied patches to drm-misc-next" と返信しました。drm-misc-next の[pull request](https://ratatoskr.run/dri-devel/2026/11/17870751/t)は "for v7.5" で、11月5日のものが3回目です。電源モードの設定、サスペンドとレジューム、コマンドの投入が含まれます。搭載製品については、[Phoronix](https://www.phoronix.com/news/Linux-7.5-RK3568-AMD-AIE4) が、おそらく（"presumably"）Zen 6 世代のクライアント向けの次世代 NPU だろうと書いています。これは Phoronix の推測で、AMD の発表を確認できたわけではありません。

動画の訂正です。

- 動画では、ChaCha の新しい実装は9本のシリーズでレビュー中で、まだ取り込みが決まったわけではない、と紹介しました。9本は Martin Willi 氏が10月12日に「用意したが未投稿」と書いたものです。投稿されたのは11月2日の v2（3本）で、11月3日に Eric Biggers 氏が libcrypto-next に適用しました。メインラインにはこれからです（[v2 のスレッド](https://ratatoskr.run/linux-crypto/2026/11/17843762/t)）。
- 動画では、4.2 GB/s から 7.5 GB/s になる、と紹介しました。これは v1 の tcrypt の値です。v2 は ChaCha の KUnit で測り直し、Zen 5 の Strix Halo で、1024バイトが 4786 MB/s から 9401 MB/s でした。

## 3. Linux 7.3 — 2026年の LTS はまだ指定されていない

[kernel.org の releases.json](https://www.kernel.org/releases.json)（11月11日 7:49、日本時間）では、longterm は 6.18、6.12、6.6、6.1、5.15、5.10 の6本です。7.x は stable だけで、最新の修正版は 7.3.4（11月10日）、mainline は 7.4-rc2 です。2026年の LTS は、この時点で指定されていません。確定は、kernel.org の一覧に Longterm と表示されることで分かります。

7.3 が選ばれるという見込みは、裏付けとなる発言も報道の本文も確認できていません。

[kernel.org の releases ページ](https://www.kernel.org/releases.html)の表では、LTS はほぼ毎年1本です。5.10（2020年12月13日）、5.15（2021年10月31日）、6.1（2022年12月11日）、6.6（2023年10月29日）、6.12（2024年11月17日）、6.18（2025年11月30日）で、12月の版が LTS になった例もあります。サポートの終了予定は、6.12 と 6.18 がどちらも2028年12月です。[FOSS Force](https://fossforce.com/2026/03/greg-kroah-hartman-stretches-support-periods-for-key-linux-lts-kernels/) によると、延長は2月末にメーリングリストで告げられ、3月2日に報じられました。FOSS Force は、この動きが今後のカーネルにも及ぶ可能性が高いと見ています。

7.3 は10月18日（米国時間）に公開されました。[v7.3 のタグ](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tag/?h=v7.3)は UTC で10月18日 23:14:58、日本時間では10月19日 8:14 です（[10月19日の記事](https://blog.fuga.jp/posts/2026-10-19-linux-oss-trend/)と同じです）。[Linuxiac](https://linuxiac.com/linux-kernel-7-3-is-out-with-new-failfs-scheduler-changes-and-more/) は、マージではないコミット18,765件、開発者3,021人、初めて貢献した人807人と伝えています。

主な変更は、[kernelnewbies](https://kernelnewbies.org/Linux_7.3) によると次のとおりです。

- FailFS は、ファイルシステムに届く操作をすべて EOPNOTSUPP で失敗させる仕組みです。ルートを FailFS にすると、絶対パス、絶対シンボリックリンク、カレントディレクトリ基準の解決が失敗します。事前に開いた記述子を起点にした操作は動きます
- sched_ext は、cgroup ごとに独自の BPF スケジューラを持てるようになりました
- Btrfs は、SSD 以外のディスクでのログ書き込み（fsync など）で、遅延が減り、スループットが5倍になるとあります
- ksmbd は、オプトインで Apple の Time Machine に対応します

動画の訂正はありません。

## 4. Broadcom の VM API が CNCF Sandbox へ

VM API は、Kubernetes の API で、ハイパーバイザーを問わず VM の一生を管理するものです。[リポジトリの README](https://github.com/vm-api/vm-api) は、"provider-neutral Kubernetes API for managing virtual machines across infrastructure platforms" と説明しています。共通の部分とプロバイダーを分ける構造で、申請書は Cluster API の分け方を VM に当てはめたものだと書いています。

経緯は、CNCF の[申請 Issue #517](https://github.com/cncf/sandbox/issues/517)で追えます。

- 9月2日（UTC、日本時間は3日）: KubeVM の名前で申請（現在の題名は vm-api）
- 9月22日（火）: TOC が、条件つきで投票に進める、と決めました。条件は、プロジェクトを VMware のリポジトリから出すことと、少なくとも2つのプロバイダーで差し替えられることを示すことです。同日に投票が始まりました
- 9月28日（月）: 投票が可決しました。賛成8、反対0、未投票3で、賛成は72.73%です
- 10月28日（水、UTC。日本時間は29日）: 貢献契約が署名され、オンボーディングの Issue が作られました
- 10月30日（金）: `vm-api/vm-api` のリポジトリが作られました（日本時間 15:07）
- 11月9日（月）: Broadcom の発表を、[Cloud Native Now](https://cloudnativenow.com/features/broadcom-contributes-api-for-virtual-machines-to-cncf/) が伝えました

メンテナが1社に偏っている点は、申請者自身が申請書で、現状は単一ベンダーだと書いています。投票のあとの10月11日には、KubeSwift と VirtRigaud の作者が、申請書の自分たちの紹介が不正確だ、と Issue で異議を述べました。TOC は10月13日に、Sandbox では複数の組織の貢献者は求めないこと、投票と承認の立場は変わらないことを答えています。

API の版は、[API 定義](https://github.com/vm-api/vm-api/blob/main/api/v1alpha1/groupversion_info.go)で `vm-api.io/v1alpha1` です。README は、API の進化とプロバイダーの互換性は、活発に開発している領域だと書いています。[ロードマップ](https://github.com/vm-api/vm-api/blob/main/ROADMAP.md)では、VirtualMachineTemplate と VirtualMachineSet は、計画中で、まだ実装されていない型です。README には、使い捨ての kind クラスタで VM の作成と読み取りを確かめるスモークテストがあります。

KubeVirt については、申請書が、競合ではなく対象のプロバイダーで、ロードマップの最初だと書いています。リポジトリに KubeVirt のプロバイダーの実装は見当たらず、計画の段階です。

1クラスタで25,000台という数字は、Broadcom が申請書で、プロバイダー第1号の VM Operator について書いたものです。VM API の v1alpha1 の値ではなく、第三者の検証も確認できていません。同じ点を指摘するコメントも Issue にあります。

動画では、次の3点に訂正があります。

- 動画では、TOC の投票は10月28日に通過した、と紹介しました。正しくは9月28日です。10月28日は貢献契約の署名の日です（[Issue #517](https://github.com/cncf/sandbox/issues/517)）。
- 動画では、リポジトリは11月4日に作られた、と紹介しました。正しくは10月30日です。11月4日は、申請者がオンボーディングの Issue に作成済みと報告した日です（[Issue #544](https://github.com/cncf/sandbox/issues/544)）。
- 動画では、KubeSwift と VirtRigaud のコミュニティから機能が重なるという声が出て、それでも審査は続けられた、と紹介しました。一次では、これらの作者の指摘は、投票後の10月11日の、申請書の紹介が不正確だという異議です。TOC は10月13日に、投票と承認は変わらないと答えました（[Issue #517](https://github.com/cncf/sandbox/issues/517)）。

## 5. CISA KEV に4件が追加 — 期限は11月12日

[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/11/09/cisa-adds-four-known-exploited-vulnerabilities-catalog)は、4件を、悪用の証拠に基づいて KEV に追加したと書いています。KEV の JSON（catalogVersion 2026.11.10）では、4件とも追加は11月9日（月）、期限は11月12日（木）です。期限は、BOD 26-04 が連邦文民行政機関（FCEB）に課すものですが、CISA はすべての組織に、KEV の脆弱性の修正を優先するよう呼びかけています。3日の期限は、[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) の forensic triage の区分の標準です。書き手が KEV の JSON から数えると、6月10日以降の162件のうち126件が3日でした。

4件の CVSS v3.1 の採点は、いずれも NVD 自身のものではありません。

| CVE | 製品 | 採点（v3.1） | 修正 |
|---|---|---|---|
| CVE-2026-102895 | GPUStack | 9.8（GitHub） | 2.2.0 |
| CVE-2026-116779 | FreeSWITCH | 9.8（GitHub） | 1.11.3 |
| CVE-2026-123218 | IBM Aspera Faspex | 9.8（IBM） | 5.0.19 PL1 |
| CVE-2026-123158 | OpenSSH | 8.1（MITRE） | 10.6p2、各ディストリビューションの更新 |

GPUStack は、[GitHub の勧告 GHSA-gj9m-f8ph-pmhr](https://github.com/gpustack/gpustack/security/advisories/GHSA-gj9m-f8ph-pmhr)によると、2.2.0 より前が対象です。既定の設定（`force_auth_localhost` が False）では、ループバックと見なされた接続が管理者として扱われ、外部からの接続がループバックと見なされる場合があります。暫定策は、`force_auth_localhost=true` にすることと、入口で利用者が付けた `X-GPUStack-Real-IP` ヘッダーを取り除くことです。勧告は、v2.1.1 に対する野外での悪用を観測したとも書いています。

FreeSWITCH は、[勧告 GHSA-mg63-h38w-8p9p](https://github.com/signalwire/freeswitch/security/advisories/GHSA-mg63-h38w-8p9p)によると、1.11.2 以前が対象で、1.11.3 で修正されました。SIP の MESSAGE を送れる相手が、サーバーの管理用コマンドを実行できる問題です。MESSAGE の認証が有効な構成では、そのプロファイルのアカウントが1つ要ります。認証は、1.10.7 以降で既定で有効です。使わないプロファイルでは、`enable-chat=false` にします。

IBM Aspera Faspex は、[IBM の勧告](https://www.ibm.com/support/pages/node/7295921)によると、5.0.0 から 5.0.19 が対象で、認可されたユーザーが細工したメッセージで、完全な管理者権限を得られます。IBM は、5.0.19 PL1 への更新を強く勧めており、回避策はありません。Faspex は、2023年2月に CVE-2022-47986 でも KEV に追加されており、今回が2度目です（KEV の JSON の時点）。

OpenSSH の CVE-2026-123158 は、[11月6日の記事](https://blog.fuga.jp/posts/2026-11-06-linux-oss-trend/)で扱いました。KEV の表記は "OpenBSD OpenSSH on Linux"、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-123158) の説明は、musl libc を使い、PAM なしの Linux の sshd です。Alpine はその一例です。NVD の状態は、11月6日の記事では Received でしたが、11月11日 7:49（日本時間）の時点では Analyzed です。採点は MITRE の v3.1 が 8.1（High）のみで、NVD 自身の採点はありません。

[Alpine の勧告](https://alpinelinux.org/posts/2026-11-05-openssh-password-authentication-bypass/)が挙げる対象は、3.16 から 3.24 と edge です。更新は `apk upgrade -U -a` で、そのあとに sshd を再起動します。パッケージを更新しても、動作中の sshd は再起動されないためです。修正版は、edge が 10.6_p2-r0、3.24 が 10.3_p1-r2、3.23 が 10.2_p1-r1 で、古い版は勧告の一覧にあります。

ここで条件を取り違えやすい点があります。鍵認証だけで運用している、という理由では、対象外になりません。sshd で `PasswordAuthentication no` にしているときに、対象外になります。鍵でログインしていても、sshd のパスワード認証が有効なら、対象です。Alpine の勧告も、`PasswordAuthentication no` の場合を対象外としています。暫定策は、この設定にして sshd を再起動することで、先に鍵でのログインが通ることを確かめます。Alpine の勧告は、Docker などのコンテナの利用者のうち、コンテナの中で sshd を動かしていない場合も対象外としています。

動画の訂正です。

- 動画では、FreeSWITCH について、メッセージを届けられる相手なら誰でも、という流れで紹介しました。MESSAGE の認証が有効な構成では、そのプロファイルのアカウントが1つ要ります。認証は 1.10.7 以降で既定で有効です（[GHSA-mg63-h38w-8p9p](https://github.com/signalwire/freeswitch/security/advisories/GHSA-mg63-h38w-8p9p)）。
- 動画では、OpenSSH は鍵認証だけにしているサーバーなら対象外、と紹介しました。正しくは、sshd で `PasswordAuthentication no` にしているときです。鍵で入っていても、パスワード認証が有効なら対象です（[Alpine の勧告](https://alpinelinux.org/posts/2026-11-05-openssh-password-authentication-bypass/)）。
- 動画では、期限がたった3日だ、と紹介しました。3日は BOD 26-04 の forensic triage の区分の標準で、今回だけの短さではありません（[BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)）。

## まとめ

Chrome は、CVE-2026-125350 の修正版（Windows と Mac が 157.0.8103.50 と .51、Linux が 157.0.8103.50）が出ており、KEV の期限は11月24日です。ChaCha の AVX-512 は、v2 の3本が libcrypto-next に適用された段階で、メインラインにはまだ入っていません。Linux 7.3 は、2026年の LTS にまだ指定されていません。VM API は、v1alpha1 のアルファ版です。KEV の4件の期限は11月12日です。

手元で確かめておくものは次のとおりです。

- Chrome と Chromium 系: Chrome の版が 157.0.8103.50 以降か確かめる。Edge など Chromium を基にする製品は、各社の更新を確認する
- KEV の4件: GPUStack は 2.2.0 以上、FreeSWITCH は 1.11.3 以上、Aspera Faspex は 5.0.19 PL1、OpenSSH は各ディストリビューションの修正版かを確かめる。期限は11月12日
- Alpine の sshd: sshd のパスワード認証の設定を確かめる。更新したら sshd を再起動する。鍵認証だけという理由では、対象外にならない
- Linux 7.3: LTS に指定されるまでは、kernel.org の longterm の一覧を確かめながら、検証用の環境で試す
- VM API: v1alpha1 のアルファ版で、本番の前提にはしない。KubeVirt のプロバイダーは計画の段階

## 参考リンク

- [Chrome Releases ブログ](https://chromereleases.googleblog.com/2026/11/stable-channel-update-for-desktop_018223192.html)
- [NVD: CVE-2026-125350](https://nvd.nist.gov/vuln/detail/CVE-2026-125350)
- [CISA のアラート（KEV 4件）](https://www.cisa.gov/news-events/alerts/2026/11/09/cisa-adds-four-known-exploited-vulnerabilities-catalog)
- [ChaCha の v2 のスレッド](https://ratatoskr.run/linux-crypto/2026/11/17843762/t)
- [kernel.org の releases.json](https://www.kernel.org/releases.json)
- [cncf/sandbox Issue #517](https://github.com/cncf/sandbox/issues/517)
- [Alpine の勧告](https://alpinelinux.org/posts/2026-11-05-openssh-password-authentication-bypass/)
- [BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk)

（2026/11/11 Linux・OSSトレンド）
