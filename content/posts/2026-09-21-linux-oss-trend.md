---
title: "使っていない機能と、残ったままの権限 — 切り離す判断が守りと速さを決めた5本（2026/9/21 Linux・OSSトレンド）"
date: 2026-09-21T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Linuxカーネル", "権限昇格", "kbuild", "KaOS", "systemd", "Fujitsu", "Arm", "サプライチェーン攻撃"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

セキュリティの話をしていると、たいてい「何を足すか」の議論になります。監視を足す、EDR を入れる、多要素認証を増やす。ただ、今日の5本を並べてみると、効いているのはむしろ逆の判断でした。使っていない機能を外す、要らなくなった権限を消す、毎回やっていた処理をやめる。 **切り離す** ほうの判断です。

カーネルの脆弱性は、使ってもいないプロトコルモジュールが読み込まれているせいで届きます。ビルドが遅いのは、毎回やり直す必要のない処理をやり直しているからです。そして最後の1本は、退職した人のアクセス権が3日だけ残っていた、という話です。

{{< youtube "Ave24LYrhGI" >}}

## 1. Linux カーネルの LPE 4本が同時公開 — そして今日が KEV の是正期限

最初は、今日いちばん手を動かす必要がある話です。

セキュリティ研究者の Asim Manizada 氏が、Linux カーネルのネットワーク層にあるローカル権限昇格（LPE）の脆弱性4件について、技術解説と動作する PoC を2026年9月18日にまとめて公開しました。[本人の技術記事](https://heyitsas.im/posts/lpe-quartet/) には DirtyAH6（CVE-2026-80844）・TUNderflow（CVE-2026-81000）・PPPoEject（CVE-2026-68121）・DiagSpill（CVE-2026-74469）という4つの通称が並んでいます。記事自身が "AI-assisted vulnerability hunting experiment" と述べているとおり、自作の AI 支援ハーネスで探索した成果です。

中身はそれぞれ違う種類のバグです。[NVD の CVE-2026-80844](https://nvd.nist.gov/vuln/detail/CVE-2026-80844) の説明文は "AH6 rearranges routing-header addresses before computing or verifying the ICV. ipv6_rearrange_rthdr() assumes that segments_left is not larger than the number of addresses described" と書いていて、IPv6 の認証ヘッダ処理が、ルーティングヘッダの `segments_left` を信じすぎていた、という構図です。[PPPoEject](https://nvd.nist.gov/vuln/detail/CVE-2026-68121) は `pppoe_sendmsg()` がヘッダへのポインタを保持したまま `dev_hard_header()` を呼び、その中でソケットバッファが再確保されることで古いポインタが無効になる、典型的な Use-After-Free です。

なかでも性格が違うのが [DiagSpill](https://nvd.nist.gov/vuln/detail/CVE-2026-74469) です。SCTP の `transport_count` が16ビットで、"Adding the 65,536th transport wraps the count to zero" とあるとおり、65,536個目のピアでカウンタが0に巻き戻ります。そのカウンタを信じて確保した診断用バッファに、実際のピア一覧を全部書き込んでしまう。CVSS は NVD に登録された CNA 評価で **8.8（High）** 、ベクタは `AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` です。他の2件（TUNderflow・PPPoEject）が `AV:L` の 7.8 なのに対して、これだけ攻撃元区分が Network になっています。なお DirtyAH6 は本稿執筆時点で NVD のステータスが Received のままで、CVSS はまだ付いていません。

修正済みのバージョンは 5.10.270 / 5.15.221 / 6.1.188 / 6.6.157 / 6.12.109 / 6.18.50 / 7.2.4 です。すぐに上げられない場合の緩和策が、今日のテーマそのものでした。本人の記事は "disabling unprivileged user namespaces removes the ordinary-user path to the first three (but doesn't protect against appropriately-CAP'd containers/other processes) – DiagSpill remains reachable" と書いています。非特権ユーザーネームスペースを無効化すれば、最初の3件については一般ユーザーからの経路は塞がる。ただし相応の権限を持つコンテナやプロセスには効かないし、DiagSpill は依然として届く。DiagSpill を止めたければ、使っていない SCTP モジュールを読み込ませない、という判断になります。

紛らわしいのでもう1点。同じ週に CISA が KEV カタログへ Linux カーネルの CVE を追加していますが、これは **この4件ではありません** 。[KEV カタログの JSON](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json) を引くと、CVE-2025-39682 / CVE-2026-53266 / CVE-2025-39964 の3件が2026年9月18日に追加され、連邦機関の是正期限が **2026年9月21日** 、つまり今日に設定されています。LPE 4件のほうは KEV に載っておらず、[The Hacker News の報道](https://thehackernews.com/2026/09/public-exploits-released-for-four-linux.html) も "no reports of the four being used in real-world attacks" と、実環境での悪用は確認されていないと書いています。「同じ週にカーネルの脆弱性が一斉に動いた」のは事実ですが、PoC が出た4件と、悪用実績があって KEV に載った3件は別の話です。ここを混ぜると、対応の優先順位を間違えます。

## 2. kbuild が最大36%速くなる — LLM に「どこを掘るか」だけ聞いた話

2本目は、切り離す対象が「毎回やり直していた処理」になります。

Arm のエンジニア Lorenzo Stoakes 氏が、カーネルのビルドシステム kbuild を高速化するパッチシリーズを投稿しました。[Phoronix の報道](https://www.phoronix.com/news/Linux-Kbuild-Faster-v3) によれば、第3リビジョンは "a set of 20 patches" で、[Linux 7.4](https://www.phoronix.com/news/Linux-Kbuild-Faster-v3) へのマージを目指しています。初期リビジョンは23本だったので、資料によって本数が違って見えることがありますが、v3 は20本です。

面白いのは、遅さの原因が「並列化されていなかったから」ではなく「並列化が終わったあとの一本道が長かったから」だった点です。`make -j$(nproc)` でコンパイル自体は並列に走っても、シンボルテーブル生成・モジュール記述ファイルのコンパイル・依存解析といった後半の工程はシングルスレッドのままでした。パッチは kallsyms の圧縮処理、アセンブラに渡すファイルの形式、`depcheck` という新しい依存チェック、objtool の並列化あたりを個別に潰していきます。[初期リビジョンを報じた記事](https://www.phoronix.com/news/AI-To-Faster-Linux-Kernel-Comp) では、全モジュール有効のフルビルドが約 **36%** 、インクリメンタルビルドが最大 **70%** 、noop ビルド（何も変更せずに `make` を叩いた場合）が最大 **90%** 速くなると報告されています。何も変えていないのに `make` を叩くと待たされる、あの時間がほぼ消えるという話です。

そして、このシリーズが話題になっている理由はもう一つあります。ボトルネックの探索に LLM が使われたことです。Stoakes 氏自身がカバーレターで "it generated a lot of code, much of it hideous" と書いていて、生成されたコードの多くはひどかった、と率直に述べています。そのうえで大幅に監査・書き直したうえで投稿し、各コミットには `Assisted-by` タグを付けました。なお [Phoronix](https://www.phoronix.com/news/Linux-Kbuild-Faster-v3) は使用した LLM を名指ししておらず、モデル名は公表されていません。

AI に書かせるのではなく、AI に「どこを掘るか」だけ教えてもらって、掘るのは人間がやる。使いどころとしては、かなり誠実な部類だと思います。品質の裏付けも取られていて、生成物は従来の実装とバイト単位で一致することが検証済みだと[報告されています](https://www.phoronix.com/news/Linux-Kbuild-Faster-v3)。速くなっても出力は変わらない、というのがこの手のパッチでいちばん重要なところでしょう。

## 3. KaOS 2026.09 — systemd を切り離すのに、KDE Plasma も手放した

3本目は、いちばん大きなものを切り離した話です。

[KaOS の公式リリースノート](https://kaosx.us/news/2026/kaos09/) によれば、2026年9月12日にリリースされた KaOS 2026.09 で、起動まわりが dinit ＋ turnstile ＋ seatd の構成になりました。デスクトップ環境も、長らく主力だった KDE Plasma から Wayland コンポジタの niri（26.04）＋ Noctalia（5.1.0）へ移行しています。同じリリースノートには "Plasma 6.7 series will be the last Plasma version available in KaOS. Once Plasma moves to 6.8, it will be removed" とあり、Plasma 6.8 が出た時点でリポジトリから消す方針まで明言されました。直近2か月で "around 70 % of this distribution was rebuild" という規模の作り直しが入っています。

なぜ Qt / KDE 中心のディストリビューションが Plasma を手放すのか。経緯は [公式ブログ「Systemd and the future of KaOS」](https://kaosx.us/news/2026/systemd_kaos/)（2026年2月19日）に書かれています。直接の契機は "with the announcement of systemd 254 in July of 2023 (last version to fully support the split `/usr` setup)" 、つまり split /usr 構成のフルサポートが systemd 254 で打ち切られたことでした。KaOS はこの構成を長く維持してきたので、存続に直結します。そして同記事にはこうあります。"If just following the mandates that systemd puts out (and used by most/all mainstream distributions), there is no need for a distribution that always had used its own ideas and path." 主流が従う要求をそのままなぞるだけなら、独自の考え方でやってきたディストリビューションが存在する意味はない、という言い方です。

ただ、systemd を完全に消せたわけではありません。[dinit 版の初回安定リリースノート](https://kaosx.us/news/2026/kaosdinit06/) は udev と tmpfiles は引き続き使っており、elogind も polkit 連携のために残っていると述べています。既知の制限も正直に並んでいて、リリースノートには "Installing on RAID is currently not possible" 、BIOS 環境では XFS を選ぶと GRUB が失敗する、"Polkit is not fully ported to Turnstile/seatd yet, so some privilege escalations options will not work." と書かれています。収録は Linux 7.1.13、GCC 15.3、Glibc 2.43、Mesa 26.2.2 など。ログイン画面は SDDM から greetd ＋ tuigreet へ、ブートローダーは Limine が既定になりました。

一部メディアは「12年続いた Plasma との別れ」という見出しを付けていますが、この「12年」という数字は KaOS 自身の発表文には見当たりませんでした。数え方の根拠が確認できないので、ここでは触れないでおきます。それよりも実務的に効くのは、切り離しのコストが RAID 非対応や Polkit 未完了という形で、ちゃんと表に出ている点だと思います。依存を外すというのは、こういう請求書が来ることでもあります。

## 4. Fujitsu MONAKA — HBM も512ビットも手放した144コア

4本目は、ハードウェアが何を捨てたかの話です。

富士通が144コアの Armv9.3-A サーバー CPU「FUJITSU-MONAKA」を正式発表しました（発表は2026年9月14日）。[ServeTheHome の Hot Chips 2026 レポート](https://www.servethehome.com/fujitsus-arm-based-monaka-data-center-cpu-at-hot-chips-2026/) によれば、コアダイは TSMC の2nm 世代で作られますが、"N2P is used for less than 30% of the total silicon area" 、つまり総シリコン面積の30%未満にすぎません。残りはキャッシュを丸ごと収めた5nm の SRAM ダイと IO ダイで、これらをハイブリッドボンディングで3D積層しています。最先端プロセスを使う場所を、必要なところだけに絞ったわけです。

演算ユニットの設計も引き算です。スーパーコンピュータ「富岳」向けの A64FX が512ビットの SVE を1コアあたり1基載せていたのに対し、MONAKA は256ビットの SVE2 を2基にしました。幅を半分にして本数を倍にした形です。メモリも HBM をやめて12チャネルの DDR5（8,800 MT/s）に戻し、I/O は PCIe Gen6。NUMA 構成は144コア1ノード・36コア4ノード・18コア8ノードの3通りから選べます。SKU は350W の空冷版（ベース2.1GHz）と500W の液冷版（ベース2.9GHz）で、最大3.8GHz。Arm CCA に準拠した機密コンピューティングもハードウェアで実装されています。

AI 向けには行列演算の命令が追加されていますが、ここは注意が必要です。「他社 CPU の2倍の AI 推論スループット」という数字が各所で報じられているものの、[Converge Digest](https://convergedigest.com/fujitsu-monaka-2nm-cpu-sovereign-ai-server/) は明確に "The comparison is a Fujitsu performance claim rather than an independently published benchmark" と書いています。富士通自身の主張であって、第三者が検証したベンチマークではありません。同様に「サーバー冷却電力を最大80%削減」も発表内容の紹介であって、独立検証の数字ではない点は押さえておきたいところです。

販売時期も分けて読む必要があります。単体チップとしての MONAKA は2026年11月に世界で販売が始まる一方、[Fujitsu MONAKA Server のほうは初期の販売対象が日本と欧州](https://itwire.com/business-it-news/enterprise-solutions/fujitsu-launches-made-in-japan-next-generation-cpu-fujitsu-monaka-and-fujitsu-monaka-server-for-sovereign-ai-infrastructure) で、他地域はその後とされています。「11月に世界でサーバーが買える」ではありません。次世代の MONAKA-X については、[ServeTheHome](https://www.servethehome.com/fujitsus-arm-based-monaka-data-center-cpu-at-hot-chips-2026/) が1.4nm プロセスへの移行と NVLink Fusion 対応に触れています。Arm SME2 の採用や、RIKEN と進める FugakuNEXT で NVIDIA GPU と結ぶ構成については、報道ベースの情報にとどまります。

## 5. CrowdSec の非公開リポジトリ170本 — 残っていたのは3日分のアクセス権

最後は、切り離し損ねた話です。

2026年5月に起きた TanStack の npm サプライチェーン攻撃（CVE-2026-45321）の波及が、4か月たった9月になって表に出ました。攻撃そのものの手口は [TanStack 公式のポストモーテム](https://tanstack.com/blog/npm-supply-chain-compromise-postmortem) が詳しく、`bundle-size.yml` が `pull_request_target` でフォークの PR コードを実行していたところにペイロードを仕込まれ、GitHub Actions のキャッシュを汚染され、最終的に Runner.Worker プロセスのメモリから OIDC トークンを抜かれてリリースパイプラインを迂回されています。2026年5月11日 19:20〜19:26 UTC の6分間に、[GitHub Security Advisory GHSA-g7cv-rxg3-hmpx](https://github.com/advisories/GHSA-g7cv-rxg3-hmpx) にあるとおり42パッケージ・84バージョンの悪意あるリリースが公開されました。[NVD の CVSS](https://nvd.nist.gov/vuln/detail/CVE-2026-45321) は9.6（Critical）で、[CISA の KEV カタログ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json) にも2026年5月27日付で登録済みです。

問題は、この攻撃が正規の署名を通過した点です。[Enclave の分析](https://enclave.ai/blog/tanstack-mistral-npm-worm-slsa-architectural-failure) は "The Sigstore attestations on the compromised versions are real. They correctly attest that the packages were built and published by release.yml" と書いています。証明書は本物で、証明している内容も正しい。ただし証明しているのは「このビルド工程がこの成果物を作った」ことであって、「その工程に流し込まれたコードが正しかった」ことではありません。同記事はこれを "the first documented case of a malicious npm package shipping with valid SLSA Build Level 3 provenance" と評しています。これは第三者ブログの評価であって、公的機関がそう認定しているわけではない点は添えておきます。

そして CrowdSec です。[同社のインシデント分析](https://www.crowdsec.net/blog/tanstack-supply-chain-attack-analysis) によれば、汚染パッケージを踏んだ端末から GitHub の OAuth トークンが盗まれ、"May 22nd, 2026 – 05:52:29 until 06:01:33 UTC" のおよそ9分間に、非公開リポジトリ約170本の中身がダウンロードされました。その端末の持ち主について、同記事は "an employee who had just left the company, but that was still part of the GitHub organization for legitimate reasons" と書いています。退職した直後で、正当な理由があって GitHub Organization に残されたままだった、ということです。正式に剥奪されたのは "May 25th, 2026 – afternoon" でした。盗用と剥奪のあいだに、3日。

攻撃者は同年8月17日に、盗んだ AWS トークンの権限を試してもいます。ただ、こちらは分析記事が "This AWS role was restricted to publishing on a single SNS topic; it didn't go any further." と書いているとおり、単一の SNS トピックへの発行しかできず、そこで止まりました。同じ「残っていた権限」でも、絞ってあったほうは被害に育っていません。対比としてこれ以上ない組み合わせだと思います。

発覚は9月、サイバー犯罪フォーラムにソースコードが投稿されたことによります。4か月間、誰も気づいていませんでした。[CrowdSec の声明](https://www.crowdsec.net/blog/crowdsec-statement-source-code-exposure) は "CrowdSec's infrastructure or databases have not been accessed or compromised." 、そして "No code was altered, whether in the open-source software, our private source code, or the build pipelines." と述べていて、読まれはしたが書き換えられてはいない、という整理です。流出範囲としては約170リポジトリのほか、利用者のメールアドレス83件と、2020年当時の投資家候補51件の連絡先が[報じられています](https://thehackernews.com/2026/09/crowdsec-says-tanstack-npm-attack-led.html)。

## まとめ

今日の5本は、足すより外すほうの判断でつながっていました。

DiagSpill は、使っていない SCTP が読み込まれていること自体が攻撃面でした。kbuild のパッチは、毎回やり直す必要のない処理をやめただけで noop ビルドが9割速くなります。KaOS は systemd を外すために KDE Plasma まで手放して、その代償を RAID 非対応や Polkit 未完了という形で引き受けました。MONAKA は最先端プロセスを使う面積を3割未満に絞り、HBM と512ビット SVE を捨てています。

そして CrowdSec の件は、外し損ねた3日が170本のリポジトリになった話でした。同じインシデントの中で、権限を絞ってあった AWS トークンのほうは何も起こらずに終わっています。付けっぱなしにしないことと、付けるときに絞っておくこと。効いたのはその2つだけです。

退職手続きのチェックリストに GitHub Organization の項目があるか、という程度の話に見えますが、被害の規模はそこで決まっていました。手元で今日できることがあるとすれば、動かしていないモジュールと、使っていないアカウントを1つずつ数えることかもしれません。

## 参考リンク

- 研究者 Asim Manizada 氏による LPE 4件の技術解説: https://heyitsas.im/posts/lpe-quartet/
- CISA Known Exploited Vulnerabilities カタログ: https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json
- KaOS 2026.09 リリースノート: https://kaosx.us/news/2026/kaos09/
- ServeTheHome「Fujitsu MONAKA at Hot Chips 2026」: https://www.servethehome.com/fujitsus-arm-based-monaka-data-center-cpu-at-hot-chips-2026/
- CrowdSec「TanStack supply chain attack analysis」: https://www.crowdsec.net/blog/tanstack-supply-chain-attack-analysis
- TanStack 公式ポストモーテム: https://tanstack.com/blog/npm-supply-chain-compromise-postmortem
