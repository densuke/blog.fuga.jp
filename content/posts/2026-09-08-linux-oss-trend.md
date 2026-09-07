---
title: "「対応済み」の射程 — 緊急ホットフィックス、重すぎたrc2、既定になった耐量子署名（2026/9/8 Linux・OSSトレンド）"
date: 2026-09-08T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Magento", "Adobe Commerce", "Linuxカーネル", "BPF", "sched_ext", "Rustls", "ポスト量子暗号", "Asahi Linux", "Patch Tuesday", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「対応済みです」という報告ほど、範囲が曖昧なまま流通する言葉もありません。

パッチを当てたから対応済み。動作確認が取れたから対応済み。標準規格が出たから対応済み。どれも嘘ではないのですが、それぞれが指している範囲はまったく違います。今日並んだ5本は、偶然にもその「範囲の差」がそのまま被害の大きさや価値の大きさになっている話ばかりでした。

穴は塞がったが店は掃除されていない話。「対応した」の主体が一人ではなかった話。標準が出てから実装の既定になるまでの2年。動くけれど眠らないノートPC。そして、パッチの数は少ないのに最高スコアが2本立っている月例更新。

「どこまでを対応済みと呼んでいるのか」を意識しながら読むと、今日の5本はきれいにひとつの線でつながります。

{{< youtube "VSh_hxTbxic" >}}

## 1. StyleSmuggler — CVE-2026-75650、CVSS 10.0。パッチは穴を塞ぐが、店は掃除しない

まずは重い話から。EC プラットフォーム Magento / Adobe Commerce を狙った未認証リモートコード実行のゼロデイです。

セキュリティ企業 Sansec が公開した[一次アドバイザリ](https://sansec.io/research/stylesmuggler-0day)によると、この脆弱性には **CVE-2026-75650** が採番され、CVSS は上限値の **10.0** 。影響範囲は「2.4.4 から 2.4.9 まで、すべてのバージョンが該当する（Every version from 2.4.4 up to and including 2.4.9 is affected）」と明記されており、Magento Open Source と Adobe Commerce の双方、B2B 版 1.3.3〜1.5.3 も含まれます。

重要なのは時系列です。Sansec のタイムラインを追うと、最初の悪用確認は **9月4日 22:20 UTC** 。アドバイザリの公開はその翌日で、Adobe が緊急ホットフィックス [APSB26-146](https://helpx.adobe.com/security/products/magento/apsb26-146.html) を出したのは **9月7日 20:20 UTC** でした。つまり **攻撃が始まってからパッチが存在するまでに、まる3日間の空白があった** ことになります。Adobe は月例のブレティンを待たず、priority 1 のホットフィックス（`VULN-39341-composer-patches.zip`）を前倒しで投げた形です。

攻撃の仕組みは二段構えです。第一段階では、GraphQL エンドポイントに対する `POST /graphql?styles[...]=` のようなリクエストで、`styles` プロパティ経由で Magento のテンプレートシステムに PHP コードを注入します。認証は不要です。第二段階は実行で、汚染されたコードは Magento が「Payment Transaction Failed Reminder」（支払い失敗リマインダー）メールをレンダリングする時点で走ります。メールが実際に届くかどうかは関係ありません。攻撃者は注文をわざと失敗させるだけで引き金を引けるわけです。

展開されるバックドアは Rust 製で、x86-64 版のサイズは **2,270,031 バイト** 。プロセス名を `[kworker/u:8:0]` というカーネルスレッド風の名前に偽装し、`ps` の出力に紛れ込みます。C2 通信は主系が `99.84.67.186:443` の TLS 上 WebSocket、副系が `185.157.160.251:123` で、こちらは NTP のトラフィックに見せかけて UDP 123 番を通ります。時刻同期を塞いでいるファイアウォールは、そう多くありません。

そして攻撃者は素早く適応しました。9月6日には実装名が `fc-cache`（フォントキャッシュ）に、9月7日には `chronyd`（時刻同期デーモン）に変わっています。いずれも Linux サーバーに実在するプロセス名で、`ps aux` を眺めただけでは違和感がありません。

さて、ここが今日のテーマです。Sansec は復旧手順として、ホットフィックスの適用に加えて **暗号化キーと関連する認証情報すべてのローテーション** 、そして media ディレクトリ配下の不審な PHP ファイルとプロセスの走査を挙げています。パッチは穴を塞ぎますが、3日間の空白のあいだに入られた店を掃除してはくれません。「パッチ適用済み＝対応済み」と読み替えた瞬間に、この差分がまるごと抜け落ちます。

なお、よく引き合いに出される「約11万ストア」という数字については注意が必要です。これは StoreLeads が数えた **Magento の稼働ストア数** であって、侵害された店舗数ではありません。[The Hacker News の報道](https://thehackernews.com/2026/09/unpatched-magento-and-adobe-commerce.html)も「Sansec は何店舗が侵害されたかを述べていない」と明記しています。母数を被害数として語ると、話がまるごと別物になってしまいます。

## 2. Linux 7.3-rc2 — 1,984コミット、BPF検証器に86コミット

セキュリティの重さから、少し温度を下げます。9月6日、Linux 7.3 の開発候補第2版がリリースされました。

[Phoronix の報道](https://www.phoronix.com/news/Linux-7.3-rc2-Released)によると、Linus Torvalds は「忙しい rc2 という感じはしなかったが、実際には明らかに忙しかった」という趣旨のコメントを添え、この rc を「full fat」と表現しています。規模の裏付けは数字のほうにあって、[LinuxCompatible のまとめ](https://www.linuxcompatible.org/story/linux-kernel-73-rc2-shipped-with-commits-bpf-hardening-and-scheduler-regressions-patched)では **694名から1,984コミット** 。rc2 としては相当に重い部類です。原因について Linus は、マージウィンドウ中に取り込み損ねた EDAC のプルを挙げつつ「それも大した量ではない」と流し、「まあ AI のせいにしておけばいい、責任を押し付けるのが簡単な相手だから」と冗談で締めています。

中身で最も厚かったのは BPF でした。前掲の LinuxCompatible によれば、BPF は今回 **86コミット** で最多パッチ数を記録し、そのすべてがメンテナ Alexei Starovoitov のもとで取り込まれています。

ここは説明の仕方に注意が要る箇所です。「Google の研究者が86個のバグを見つけて全部塞いだ」という筋書きで語られがちなのですが、原典に照らすと構図が違います。 **86 はコミット数であってバグの件数ではありません** し、研究者 Nicholas Carlini が果たした役割は「検証器のエッジケースを提起した」側です。具体的には「ポインタ比較における非NULL推論の誤り」と「ゼロスピル周辺の精度追跡」が挙げられており、修正を積み上げたのは BPF メンテナ陣、という分業になります。ここも「誰がどこまで対応したのか」の範囲の話ですね。

BPF プログラムはカーネル空間で JIT コンパイルされて動くので、検証器の穴はそのまま権限昇格やカーネルクラッシュに直結します。番人の目をまとめて点検した、という意味で地味に効くリリースです。

スケジューラ側では、7.3 のマージウィンドウで入った CFS の単一実行キュー変換が引き起こしたリグレッションを、7コミットで修正しています。タイムスタンプ処理の不具合、帯域幅計算の問題、そして新アーキテクチャの下で壊れていたスロットリングロジック——コンテナホストで cgroup の CPU 制限を使っている環境には直撃しうる箇所です。

もうひとつ、sched_ext のサブスケジューラ対応が **機能完成（feature complete）** に到達しました。[Phoronix の解説](https://www.phoronix.com/news/Linux-7.3-sched-ext)によれば、親となる BPF スケジューラが cgroup サブツリーをネストしたサブスケジューラへ委譲でき、「サブスケジューラはそれらの CPU 上の自分のタスクについて、すべてのスケジューリング決定を所有する」。委譲される権能はエンキュー・プリエンプション・CPU 周波数制御などで、親はこれらを **付与も取り消しもできる** 。データベース専用スケジューラとレイテンシ優先サービス用スケジューラを、同じホストに cgroup 単位で同居させる、という構成が現実味を帯びてきました。

グラフィックス側では、NVIDIA Blackwell（GB20x）向けの Nouveau ディスプレイ修正が入っています。[Phoronix の記事](https://www.phoronix.com/news/Nouveau-Blackwell-Display-Fixes)によると、HDMI ベンダーインフォフレームの修正、HDMI GCP AVMute のレジスタオフセット修正、vblank 割り込みの修正、GSP（GPU System Processor）連携の改善が含まれます。開発者 Mohamed Ahmed は、これらが HDMI 2.1 の立ち上げ作業の一部であり、いま直ちに致命的ではないものの「FRL、DSC、VRR といった高度な機能を正しく動かすには必要」だと説明しています。完成ではなく、地固め。ここも範囲の申告が誠実です。

## 3. Rustls 0.23.44 — 耐量子署名が「既定」になるまでの2年

一番静かな話にいきましょう。Rust 製 TLS ライブラリ Rustls が、9月7日に 0.23.44 をリリースしました。

[公式リリースノート](https://github.com/rustls/rustls/releases/tag/v%2F0.23.44)の一行目がこれです。「ポスト量子安全な ML-DSA 証明書のサポートが、aws-lc-rs クリプトプロバイダでデフォルト有効になりました（Support for post-quantum secure ML-DSA certificates is now enabled by default in the aws-lc-rs crypto provider）」。

ML-DSA は格子暗号ベースのデジタル署名アルゴリズムで、旧称を CRYSTALS-Dilithium といいます。NIST が [FIPS 204](https://csrc.nist.gov/pubs/fips/204/final) として正式発行したのが2024年8月13日ですから、標準の確定からライブラリの既定値になるまで、およそ2年かかった計算です。暗号の世界の時間感覚としては、これはかなり速いほうだと思います。

ただし、リリースノートは適用範囲もはっきり書いています。「ML-DSA 証明書はパブリックな web PKI ではサポートされていないが、プライベートな証明書階層では使用できる（ML-DSA certificates are not supported in the public web PKI, but they can be used with private certificate hierarchies）」。つまり Let's Encrypt から ML-DSA の証明書が降ってくるわけではなく、いま恩恵を受けるのは社内 PKI やサービス間 mTLS を自前の CA で回している組織です。「対応済み」の範囲を、リリースノート自身が先に線引きしている——ここが好ましい。

同じリリースには、地味ですが実務的に効く変更も入っています。組み込みの `KeyLogFile` 実装が、作成するファイルを **所有者のみ読み取り可能** に制限するようになりました（PR #3210）。SSLKEYLOGFILE は TLS セッション鍵の平文が並ぶファイルですから、パーミッションが緩いまま置かれていた環境にはありがたい修正です。加えて ECH（Encrypted Client Hello）が拒否された場合に、サーバー証明書を正しい名前に対して検証するよう修正されています（PR #3236）。ML-DSA の既定化は PR #3249 です。

急ぐ理由は「harvest now, decrypt later」——いま暗号文を収穫しておいて、量子計算機が実用化されてから復号する、という攻撃モデルです。ここで年号を取り違えやすいので補足しておくと、NIST の移行指針（[NIST IR 8547](https://csrc.nist.gov/pubs/ir/8547/ipd)）が示しているのは、112ビット相当の古典的公開鍵暗号を **2030年までに非推奨（deprecated）** 、 **2035年までに使用禁止（disallowed）** とする道筋です。2030年は「完了」の期限ではなく「非推奨化」の期限。5年ぶんの差があります。

なお Rustls は鍵交換側では既に `X25519MLKEM768` を aws-lc-rs で既定にしており、今回で署名側も既定に加わりました。TLS の二本柱が両方とも耐量子側に片足を置いた、という位置づけになります。

## 4. Asahi Linux が M3 に正式対応 — 動くけれど、眠らない

Apple Silicon の話です。Asahi Linux が9月6日、M3 系チップの公式サポートを発表しました。

[公式ブログ](https://asahilinux.org/2026/09/m2-episode-1/)によると、対象は **M3 / M3 Pro / M3 Max を搭載した MacBook と iMac** 。Mac Studio（M3 Ultra）は「まだサポートされていない」と明記されています。動作するものの列挙が具体的で、ウェブカメラ、内蔵マイク、USB（ハードウェア上限である USB 3 の 10 Gb/s まで）、AV1 を含むハードウェアビデオデコード、WiFi、Bluetooth——「M1 と M2 系のマシンでサポートされていたものは、ほとんどすべてそのまま動く」という表現です。

そして動かないものも、同じくらいはっきり書かれています。3D 加速については「いま現在、高性能あるいは電力効率の良い 3D 加速を期待しないでほしい（Do not expect performant or power-efficient 3D acceleration right now）」。スリープは「ファームウェアが提供するフレームバッファの制約により、現時点では動作しない」。HDMI ポートを備えた MacBook では、その HDMI 出力が無効化されたままです。

スリープと HDMI が同時に止まっている理由は共通していて、Apple の DCP（Display Coprocessor）のサポートが未完だからです。DCP はディスプレイ出力・スリープ制御・電力管理にまたがるコプロセッサで、プロトコルは公開されていません。ここが埋まれば両方が一度に解決する、という構造になっています。

導入は現状 Expert モード限定で、`curl -L https://alx.sh/ | EXPERT=1 sh` という形になります。[Phoronix の解説](https://www.phoronix.com/news/Asahi-Linux-Official-M3)や [Linuxiac の記事](https://linuxiac.com/asahi-linux-officially-adds-support-for-apple-m3-macs/)でも、この制限つきの提供という点は共通して触れられています。

わたしがこの発表を好ましく思ったのは、「対応しました」の範囲を、できることとできないことの両方で定義しているところです。3D 加速がない以上、ゲームや GPU 演算の用途には向きません。スリープしないノートPCはモバイルでの取り回しに響きます。一方で、コードを書いてテストを回してサーバーアプリケーションを動かす、という CPU とメモリが主役のワークロードには、もう十分に実用的です。使う側が判断を下せるだけの情報が、最初から揃っている。リリースノートとしてはこれが理想形だと思います。

ちなみに記事のタイトルは「M2: Episode 1 (or, Asahi Linux on M3)」。M2 世代の技術解説シリーズの第1回でありながら中身は M3 の話、という Asahi チーム流の捻りです。

## 5. Microsoft Patch Tuesday 2026年9月 — 9件、全部Critical、Windows本体はゼロ

最後は月例更新です。そして今月は、数の少なさが逆に目を引きます。

[Trinetri の集計](https://trinetriops.com/resources/patch-tuesday/september-2026)によれば、2026年9月の Patch Tuesday で Microsoft が修正した脆弱性は **9件** 。しかもその9件が **すべて Critical** で、Important 以下はゼロです。対象は Azure AI Language、Azure Cosmos DB、Copilot Studio、Entra ID、Azure Active Directory B2C、Microsoft Discovery Studio、Microsoft Fabric、Power Automate——見てのとおり、ほぼクラウドサービスに寄っています。 **Windows OS 本体の脆弱性は今回ゼロ件** でした。公開前に開示されていたものも、既に悪用されていたものもありません。

最高スコアは CVSS 10.0 が2本。ひとつが **CVE-2026-70352** で、これは Azure AI Language の権限昇格です。分類は CWE-306（重要な機能に対する認証の欠落）で、未認証の攻撃者がネットワーク越しに権限を昇格できる、というもの。もうひとつが CVE-2026-83711、Azure Active Directory B2C の権限昇格です。件数は少ないのに上限スコアが2本並ぶという、密度の高い月になりました。

なお、この日の総エントリ数は181件と数えられていますが、内訳は Azure Linux（旧 Mariner）のパッケージ更新が149件、Chromium ベース Edge の再公開が23件で、Microsoft 製品の新規脆弱性が残る9件、という構成です。「181件のパッチ」と「9件の新規脆弱性」は同じ月を指していますが、指している範囲が違います。ここも読み違えやすい数字です。

Linux サーバーを見ている立場からすると、今月の Microsoft 側は緊急対応の必要が薄い月です。むしろ実務直結度が高かったのは、トピック1で見た Adobe のほうでした。Magento / Adobe Commerce は多くの場合 LAMP / LEMP スタック、つまり Linux の上で動いています。Patch Tuesday は Windows のイベントだと思って眺めていると、自分の担当領域に落ちてくる火の粉を見落とすことがある、という月です。

そして [Adobe のセキュリティブレティン一覧](https://helpx.adobe.com/security/products/magento.html)を見ればわかるとおり、今月の Adobe Commerce 向け対応は定例日の9月8日を待たず、前日の9月7日に緊急ホットフィックスとして出ました。定例スケジュールという枠組みは、平時には予測可能性という価値を生みますが、実際に攻撃が走っている状況では待ち時間そのものになります。今回はその枠を外して前倒しした、という判断が見て取れます。

## まとめ

5本を並べ直すと、こうなります。

Adobe は3日遅れでパッチを出した。パッチは穴を塞いだ。けれど、その3日間に入られた店の掃除まではしてくれない。BPF の86コミットは、一人の研究者が86個のバグを潰した話ではなく、提起した人と積み上げた人がいる話だった。Rustls の ML-DSA は既定になったが、その既定が効くのはプライベート PKI の中だけで、そのことをリリースノート自身が先に書いていた。Asahi Linux の M3 対応は、動くものと動かないものを同じ密度で並べていた。そして Patch Tuesday の「181件」と「9件」は、どちらも正しい数え方だった。

どれも「対応済み」と言えます。言えますが、範囲がそれぞれ違う。

厄介なのは、範囲を狭く申告した側のほうが誠実だ、ということです。Asahi Linux も Rustls も、できないことを先に書いたぶん、読み手が自分で判断できます。逆に、範囲を書かずに「対応済み」とだけ流れてきた報告は、受け取った側が範囲を勝手に補完してしまう。今日いちばん怖かったのは、まさにそこでした。

自分のところに届いている「対応済み」の報告を、ひとつ思い浮かべてみてください。それは、どこからどこまでを指しているでしょうか。適用は済んだ。では、その前に入られていないことは、誰がどうやって確かめたのでしょう。

## 参考リンク

- [Sansec — StyleSmuggler: Magento and Adobe Commerce 0-day RCE (CVE-2026-75650)](https://sansec.io/research/stylesmuggler-0day)
- [Adobe Security Bulletin APSB26-146](https://helpx.adobe.com/security/products/magento/apsb26-146.html)
- [Phoronix — Linux 7.3-rc2 Released](https://www.phoronix.com/news/Linux-7.3-rc2-Released)
- [Phoronix — sched_ext サブスケジューラの機能完成](https://www.phoronix.com/news/Linux-7.3-sched-ext)
- [Rustls 0.23.44 リリースノート](https://github.com/rustls/rustls/releases/tag/v%2F0.23.44)
- [NIST FIPS 204（ML-DSA）](https://csrc.nist.gov/pubs/fips/204/final)
- [Asahi Linux — M2: Episode 1 (or, Asahi Linux on M3)](https://asahilinux.org/2026/09/m2-episode-1/)
- [Trinetri — Microsoft Patch Tuesday September 2026](https://trinetriops.com/resources/patch-tuesday/september-2026)
