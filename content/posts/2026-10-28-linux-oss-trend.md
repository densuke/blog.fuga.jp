---
title: "BlackX は失効リストの更新漏れから Secure Boot を越えた、Kali Linux 2026.3、memblock の二分探索で KHO 環境の起動処理を短縮、Linux 7.2.13 と 6.18.59、PHP の CVE-2026-115560 は緩和策で守る（2026/10/28 Linux・OSSトレンド）"
date: 2026-10-28T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Secure Boot", "UEFI", "Kali Linux", "KDE", "Linux カーネル", "Linux 7.4", "KVM", "PHP"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

パッチを当てたあとに、まだ打つべき一手が残っていないか。今回の5本は、その確認の話として読めます。UEFI ブートキットの BlackX は、2022年1月に修正された穴を、失効リスト（DBX）が更新されていないままの環境で突きました。Kali Linux 2026.3 は、カーネルとデスクトップを更新しつつ、ビルドスクリプトの刷新は途中です。memblock の高速化は、前提が変わった環境で、線形探索の遅さが表に出た例です。安定版カーネルの更新は、修正ごとに入った版が違い、再起動まで済ませて初めて効きます。PHP の CVE-2026-115560 は、緩和策の1行が入っているかどうかが分かれ目です。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言や、出典を確認できなかった発言は、各節末の「動画の訂正」にまとめました。

この記事の確認時点は、日本時間の10月28日の午前です。NVD や CVE.org への登録状況、Microsoft の手順書、カーネルの取り込み状況、PHP の次のリリースなど、あとから変わりうる情報には、その旨を添えて、最新の情報を確認できる一次ソースへのリンクを付けました。

{{< youtube "Kw7EsgK95DQ" >}}

## 1. BlackX — 2022年1月に修正された穴で Secure Boot を越えた UEFI ブートキット

Kaspersky は、[Securelist の分析](https://securelist.com/uefi-bootkit-blackx/121539/)で、BlackX と名付けた UEFI ブートキットを報告しました。公開は UTC の10月22日 6:00（日本時間 15:00）です。[Microsoft の Windows IT Pro ブログ](https://techcommunity.microsoft.com/blog/windows-itpro-blog/revoking-vulnerable-windows-boot-managers/4121735)の説明では、ブートキットは、起動の流れのできるだけ早い段階で読み込まれるように作られた悪意のあるプログラムです。Secure Boot は、Windows より前に動くコードを検証済みのものに限る仕組みです。

### 何が起きたか

- Securelist によれば、Kaspersky は2026年の初めに、タジキスタン、ウズベキスタン、トルクメニスタンの外交機関を狙う攻撃を確認しました
- Kaspersky は、この攻撃を APT41 によるものと、中程度の確度（medium confidence）で結論しています。根拠として挙げているのは、ESET の記事にある PDB パスの識別子 "xdd"、DLL サイドローディングと暗号化ファイルの組み合わせ、OLLVM の難読化の3点です。確度は中程度にとどまり、断定ではありません
- APT41 を国家支援のグループとする見方は、Securelist の記述ではありません。[MITRE ATT&CK](https://attack.mitre.org/groups/G0096/) が、研究者の評価として、金銭目的の活動もする、中国の国家支援のスパイ活動グループと書いています
- Securelist は、諜報に使われたペイロードを2つ確認した、と書いています。狙いが金銭ではなく諜報だという見方の根拠は、この点です
- Securelist は、BlackX が使うエクスプロイトの実装が、BlackLotus で使われたものと "remarkably similar"（著しく似ている）と書きます。BlackLotus のソースコードはネット上に公開されたことがなく、攻撃者がリバースエンジニアリングしたか、ソースを購入したかのどちらかだろう、という書き方で、断定はしていません

### 突破に使われた穴と、失効リスト

使われたのは Baton Drop（CVE-2022-21894）です。[MSRC](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-21894) の公開は2022年1月11日で、Securelist は、標的の端末にはパッチが全部当たっていた、と書いています。[ESET の BlackLotus の記事](https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/)は、脆弱性は2022年1月の更新で修正されたが、署名が有効な古いバイナリが UEFI の失効リストに載っていない限り、悪用はできてしまう、という趣旨を書いています。

Microsoft の文書によれば、DBX は、信頼しない UEFI モジュールの読み込みを止めるための一覧です。古いブートローダーに使われた Windows Production PCA 2011 の証明書をここへ入れると、その証明書で署名されたブートマネージャーが信頼されなくなります。

Securelist は、この失効はパッチを入れただけでは自動で進まず、利用者が手動で起動する必要があると書いています。Securelist の説明では、レジストリのフラグを設定し、Secure-Boot-Update という名前のスケジュールタスクが作られます。

ここで注意したい点があります。Securelist は、これを「Baton Drop のパッチ」の話として書いています。一方、Microsoft の文書では、PCA 2011 を DBX に入れる失効の手順は、CVE-2023-24932（BlackLotus）の緩和策として案内されています。その手順書が [KB5025885](https://support.microsoft.com/en-us/topic/how-to-manage-the-windows-boot-manager-revocations-for-secure-boot-changes-associated-with-cve-2023-24932-41a975df-beb2-40c1-99a3-b3ff139f832d) です。

Microsoft の KB は、既存のスケジュールタスク `\Microsoft\Windows\PI\Secure-Boot-Update` を起動する手順を書いており、Securelist の「タスクを作る」とは言い方が違います。KB は、先に DB の更新とブートマネージャーの更新を済ませ、DBX の更新はあとに回すよう順序を示しています。

Securelist は、Microsoft の計画にある強制適用の段階（Enforcement Phase）は、Securelist の公開時点では実施されていないと書いています。10月28日の確認時点でも、KB は "The date for this phase will be announced at a later date." と書き、日付を告知していません。

### 証明書の期限と失効は別

Microsoft の[証明書の期限に関する文書](https://support.microsoft.com/en-us/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e)は、Microsoft Windows Production PCA 2011 の期限を2026年10月19日と書いています。証明書そのものの期限は、UTC の10月19日 18:51 で、日本時間では10月20日の3:51 にあたります。UEFI CA 2011（6月27日）や KEK CA 2011（6月24日）とは別の証明書です。

Securelist は、期限が切れても、証明書が失効リストに載っていなければ、脆弱なバイナリの読み込みは止まらないと書いています。期限切れと失効は別の処理です。

### 侵入後の動き

Securelist によれば、攻撃者は、被害者のネットワークに侵入し、管理者権限を得たあとに BlackX を設置しました。

- 目的は、攻撃者専用の Machine Owner Key（MOK）を入れ、任意の EFI ファイルを読み込めるようにして、Secure Boot を操作することです。MOK は、shim が信頼する鍵の一覧で、UEFI の db とは別のものです。[mokutil のマニュアル](https://github.com/lcp/mokutil/blob/master/man/mokutil.1)は、利用者が自分で信頼する証明書を管理するための仕組みだと説明しています
- Windows のカーネルに、悪意のあるドライバを入れます
- ドライバは、セキュリティ製品に関わるプロセス、スレッド、レジストリのコールバックを無効にし、ETW のプロバイダーを改ざんして、製品が出力を読めないようにします
- ブートキットのファイルを開こうとするカーネルの要求には、calc.exe のハンドルを返します
- Kaspersky や Avast の製品が入っているときだけ動く妨害処理もありました。Securelist は、動的解析では Kaspersky の製品には妨害が効かなかった、と書いています

Securelist は、Rust 製のペイロードが `www[.]archivetj[.]com` の C2 サーバーと通信する、と書いています（リンクにならないよう、無害化した表記にしています）。最新の侵害指標は、Securelist の記事で確認してください。

### 深刻度

Baton Drop の CVSS v3.1 は、Microsoft が付けた 4.4（Medium）です。ベクターは `CVSS:3.1/AV:L/AC:L/PR:H/UI:N/S:U/C:N/I:H/A:N` で、NVD の上では secure@microsoft.com の Secondary という扱いです。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2022-21894) 自身（Primary）の採点は、CVSS v2.0 の 4.9（Medium）です。Microsoft 自身の深刻度の表示は "Important" で、CVSS の Medium とは別の尺度です。

ベクターの AV:L はローカルからの攻撃、PR:H は高い権限が必要という意味です。ただ、Securelist によれば、今回の攻撃者は、被害者のネットワークに侵入して管理者権限を得てから使いました。スコアが低めでも、後回しにしてよい理由にはなりません。NVD の CPE には、Windows 8.1、10、11、Windows Server 2012 から 2022 までの各版が載っています。

### 誰に影響があるか、確かめること

直接の標的は、中央アジアの外交機関です。ただ、突かれたのは DBX の更新が済んでいないという状態で、Windows の Secure Boot の運用一般に関わる話です。Windows の Secure Boot を使う環境では、DBX の状態を確かめます。確かめ方は、Microsoft の KB が示している次のコマンドです（PowerShell。"make sure it returns True" と書かれています）。

```powershell
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI dbx).bytes) -match 'Microsoft Windows Production PCA 2011'
```

True なら、PCA 2011 は DBX に載っています。False なら、KB5025885 の手順で、DB の更新、ブートマネージャーの更新、DBX の更新の順に進めます。KB は、DBX を更新すると、PCA 2011 で署名されたブートマネージャーからは起動できなくなる、と警告しています。回復用メディアや USB、PXE の起動イメージが対象です。代表機で先に試し、回復用メディアを作ってから進めてください。BitLocker を使っているなら、回復キーを手元に確保しておくよう、Microsoft のブログも書いています。

Linux の読者は、shim が持つ MOK を確かめます。`mokutil --list-enrolled` で、登録済みの証明書を一覧できます（mokutil のマニュアルでは、信頼済みのデータベース MokListRT の一覧）。身に覚えのない鍵がないかを見ます。

失効リストに載っていない署名済みの古いバイナリが足場になる点は、別件ですが、[7月16日の記事](https://blog.fuga.jp/posts/2026-07-16-npm-supply-chain-shim-secure-boot-revocation/)でも扱いました。別の脆弱性、別のバイナリです。

最新の情報は、Microsoft の KB5025885、Securelist の記事、MSRC のページで確認してください。

動画の訂正です。

- 動画では、CVE-2022-21894 の話の流れで、パッチを当てても失効は自動では進まず、Microsoft の修正は PCA 2011 の証明書を DBX へ追加して初めて完全に機能する、と紹介しました。これは Securelist の「Baton Drop のパッチ」という書き方に沿ったものですが、Microsoft の文書では、PCA 2011 を DBX に入れる失効の手順は、CVE-2023-24932 の緩和策として案内されています。2022年1月の修正だけでは足りない点は、ESET も、影響を受けるバイナリが失効リストに載っていないと指摘しています（[KB5025885](https://support.microsoft.com/en-us/topic/how-to-manage-the-windows-boot-manager-revocations-for-secure-boot-changes-associated-with-cve-2023-24932-41a975df-beb2-40c1-99a3-b3ff139f832d)、[ESET](https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/)）。
- 動画では、攻撃者を「中国系の国家支援グループAPT41だと、カスペルスキーは中程度の確度で見ています」と紹介しました。中程度の確度で APT41 と結論したのは Kaspersky ですが、「国家支援」の評価は Securelist の記述ではなく、MITRE ATT&CK の評価です（[Securelist](https://securelist.com/uefi-bootkit-blackx/121539/)、[MITRE ATT&CK](https://attack.mitre.org/groups/G0096/)）。
- 動画では、MOK を「Secure Boot の許可リストに登録する」と紹介しました。MOK は shim が持つ一覧で、UEFI の db とは別です。Securelist の書き方は、MOK を入れて任意の EFI ファイルを読み込めるようにし、Secure Boot を操作する、というものです（[Securelist](https://securelist.com/uefi-bootkit-blackx/121539/)、[mokutil のマニュアル](https://github.com/lcp/mokutil/blob/master/man/mokutil.1)）。
- 動画では、侵害が確認されたのは「今年の前半」と紹介しました。Securelist の原文は "early 2026"（2026年の初め）で、前半より狭い範囲です（[Securelist](https://securelist.com/uefi-bootkit-blackx/121539/)）。
- 動画では、Baton Drop を「名前のとおり2022年に見つかったもの」と紹介しました。CVE 番号の2022は採番の年で、発見の年を示す一次は確認できませんでした。確認できたのは、MSRC の公開が2022年1月11日だという点です（[MSRC](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-21894)）。

## 2. Kali Linux 2026.3 — カーネル 7.1.5、Plasma 6.7、新ツール6本、ビルドスクリプトのコンテナ対応

[Kali のリリースブログ](https://www.kali.org/blog/kali-linux-2026-3-release/)の日付は、2026年10月26日（月）です。126件のパッケージ更新を含み、Kali のカーネルは 6.19 から 7.1.5 に上がりました。前の版の 2026.2 は、6月29日の公開で、カーネルは 6.19 でした。2026.2 は[7月1日の記事](https://blog.fuga.jp/posts/2026-07-01-npm-v12-git-rust-linux72-strncpy/)で扱っています。

### カーネルと土台

Kali の文書は、Kali が Debian Testing を土台にしていると書いています。Debian の experimental と unstable からは、必要なパッケージだけを選んで取り込む構成です（[Debian との関係](https://www.kali.org/docs/policy/kali-linux-relationship-with-debian/)、[ブランチの文書](https://www.kali.org/docs/general-use/kali-branches/)）。

NVIDIA のドライバを使う物理マシンでは、更新の前に確認しておくと安心です。ただし、2026.3 のブログに NVIDIA の注意書きはなく、7.1.5 で NVIDIA のドライバが動かなくなると書いた一次も見つかりませんでした。確認を勧める根拠は、2026.2 のブログと Kali の文書です。2026.2 のブログは、Debian に 7.0 のカーネルが入ったときに、NVIDIA の DKMS ドライバとの非互換の報告があり、利用者を壊さないよう 6.19 で出した、と書いています。Kali の[文書](https://www.kali.org/docs/troubleshooting/graphics-issues-on-bare-metal-installation/)も、カーネルの更新が頻繁なとき、新しい版のヘッダーが入っていないと、NVIDIA を含む DKMS のモジュールが壊れうる、と書いています。

### デスクトップ

標準のデスクトップは、2019.4 で既定になった Xfce です。2026年の時点の既定を明言した一次は見つかりませんでしたが、変更した記録も見当たりません。KDE を選ぶ人向けには、Plasma 6.7 に更新されました。Plasma 6.7 自体は、[KDE の告知](https://kde.org/announcements/plasma/6/6.7.0/)で6月16日の公開です。

Kali のブログは、画面ごとの仮想デスクトップを、特に興味深い追加の1つに挙げています。ターミナル、ブラウザ、Burp、ドキュメントを、画面ごとに分けておく使い方を例示しています。Wayland については、対応するプロトコルとポータルが増えた、と書きます。性能と消費電力の最適化は、特に内蔵の Intel GPU と、複数のフルスクリーンのウィンドウを使う場面が対象です。

### 新ツール6本

ブログは、ネットワークのリポジトリに入った新ツールを6本挙げています。各ツールの説明は、Kali のブログと上流のリポジトリによります。

- [dalfox](https://www.kali.org/tools/dalfox/) は、XSS のスキャナーです。README は、反射型、保存型、DOM ベースの XSS のスキャンを挙げています。README によれば、dalfox v3 は Rust での全面的な書き直しです。Kali に入っているのは v3.2.2 です
- [katana](https://www.kali.org/tools/katana/) は、ProjectDiscovery のクローラー（Go 製）です。標準モードとヘッドレスモードがあり、README はヘッドレスを実験的（experimental）としています。JavaScript ファイルの解析やクロールもできます。Kali の版は 1.7.0 です
- [qsreplace](https://www.kali.org/tools/qsreplace/) は、標準入力の URL のクエリ文字列の値を、指定した値に置き換えます（Go 製）
- [rustscan](https://www.kali.org/tools/rustscan/) は、高速なポートスキャナーです。README は、結果を Nmap に自動で渡せる、と書いています（Rust 製）
- [sdrangel](https://www.kali.org/tools/sdrangel/) は、ソフトウェア無線のフロントエンドです。Kali のページは、RTL-SDR、BladeRF、HackRF などに対応すると書きます（C++ 製）
- [snaffler-ng](https://www.kali.org/tools/snaffler-ng/) は、SMB の共有を巡回し、認証情報や機密データを見つけるツールです。Impacket を使った Snaffler の移植で、Python 製です

言語は、各リポジトリの主言語です。6本の内訳は、Rust が2本、Go が2本、C++ と Python が1本ずつです。

### ビルドスクリプトと NetHunter

ブログによれば、刷新したビルドスクリプトには build-in-container.sh が付属し、Docker か Podman の有無を検出して、ビルド用のコンテナを作り、その中でビルドを走らせます。ただし、全部のスクリプトの刷新は間に合っておらず、ブログは "We are aiming to have them ready for Kali 2026.4." と書いています。2026.4 での完了は、見込みの段階です。

NetHunter では、TicWatch Pro 3 のシリーズで、ウォードライビングがサポートされました。ブログによれば、Qazy Anwar 氏との協力で libnexmonkali が更新され、Kali の chroot の aircrack-ng スイートや kismet などで、腕時計の内蔵 Wi-Fi のモニターモードが使えます。

### 更新と、確かめること

既存の環境は、ブログの手順で更新します。ブログは、`sudo apt update && sudo apt -y full-upgrade` のあと、`/var/run/reboot-required` があるときだけ再起動する、と書いています。更新前に、ブログの冒頭の手順（`kali.sources` の設定など）を読んでください。更新後は、`grep VERSION /etc/os-release` で `VERSION_ID="2026.3"` になっているかを確かめます。NVIDIA を使う物理マシンは、更新の前に、上の2つの文書を確認します。

最新の情報は、Kali のリリースブログとツールのページで確認してください。

動画の訂正です。

- 動画では、「KaliはDebianの開発版であるUnstableを追いかける、ローリングリリース」と紹介し、画面にも「Debian Unstable を追うローリングリリース」と出しました。Kali の文書は、Debian Testing を土台とし、Unstable と Experimental からは必要なパッケージを選んで取り込む、と書いています（[Debian との関係](https://www.kali.org/docs/policy/kali-linux-relationship-with-debian/)、[ブランチの文書](https://www.kali.org/docs/general-use/kali-branches/)）。
- 動画では、新ツールの言語を「Rust製 2本 / Go製 1本」と画面に出しました。発言のほう（dalfox と rustscan が Rust 製、katana が Go 製）は正しいのですが、6本のうち Go 製は katana と qsreplace の2本です。qsreplace の言語は、[リポジトリ](https://github.com/tomnomnom/qsreplace)で確認できます（[katana](https://github.com/projectdiscovery/katana)も Go 製です）。

## 3. memblock の二分探索 — KHO 環境で約268秒が約50ミリ秒に、7.4 のマージウィンドウで mainline へ

memblock は、カーネルが起動の早い段階で、通常のメモリ割り当て役が動き出す前に物理メモリを管理する仕組みです。[カーネルの文書](https://docs.kernel.org/core-api/boot-time-mm.html)は、通常のカーネルのアロケーターが動いていない起動の初期に、領域を管理する方法だと書いています。この memblock に、二分探索を取り入れるパッチが、Linux 7.4 のマージウィンドウ中に mainline に入りました。

### 先に、効果の範囲

効果が大きいのは、領域の数が非常に多くなる環境です。コミット本文は、KHO のページ保存のように、互いに離れた folio を数十万個登録する、メモリの断片化が激しい場合を挙げています。領域の少ない普通のパソコンでは、差は小さいと考えられます。これは書き手の推論で、一次に「普通のパソコンの恩恵は小さい」と書いた文はありません。

### 何が遅かったか

[採用されたコミット](https://github.com/torvalds/linux/commit/7933ad3f669670ca5f5f13de2b5cb0f92b91abf5)の本文は、次のように書いています。"Under heavy memory fragmentation, such as KHO page preservation registering hundreds of thousands of disjoint folios, scanning from index 0 on every insertion and isolation results in O(N^2) complexity, causing boot-time memory retrieval to take several minutes (~268s for 393k pages)." 追加や分離のたびに、先頭から順に探していたため、全体では N の2乗になっていた、という説明です。

修正後は、"cutting KHO memory retrieval time from ~268s to ~50ms." とあります。約268秒は、4分28秒です。これは、パッチの作者（Google のアドレスを使う Tarun Sahu 氏）が自分で測った値で、第三者の再現ではありません。393k pages は、39万3000ページ分で、領域の数（リージョン）ではありません。268秒と50ミリ秒から計算すると約5,000倍ですが、コミット本文に倍率の記述はありません。

### 何を変えたか

memblock_add_range() と memblock_isolate_range() の2つの関数で、探し始める位置を二分探索で決めるように変えました。mainline の現在のコードでは、`__memblock_search()` がその役目を担います。mainline に入ったコミットは、`mm/memblock.c` の追加28行、削除15行で、コミット本文は、候補を探す処理の計算量が O(N) から O(log N) になった、と書いています。

投稿は、9月3日（UTC の15:59、日本時間では9月4日の0:59）の初版から始まり、[MARC の初版の投稿](https://marc.info/?l=linux-mm&m=178845101661902&w=2)で読めます。改訂版は、9月18日、9月26日、10月8日に出ました。初版は追加36行、削除2行で、本文には最悪 O(N log N)、順番どおりの追加なら O(N) という文言がありました。現在のコミットは、書き直されたあとの版です。

### 検証と議論

Oracle の Dongli Zhang 氏は、[初版への返信](https://marc.info/?l=linux-mm&m=178846172374316&w=2)で、自分の環境のブートログを貼りました。1ノード、32CPU で、THP は never（4K ページ）です。`mem auto-init` の行から `SLUB: HWalign` の行までの時刻の差を計算すると、パッチ前は 38.587378 から 0.231623 を引いた約38.4秒、パッチ後は 0.512019 から 0.247746 を引いた約0.26秒です。本人が「38秒が0.26秒になった」と書いたわけではなく、ログの時刻からの計算です。

ARM のアドレスを持つ Dev Jain 氏は、初版に、通常の場合は線形探索のほうがキャッシュと CPU に優しいのではないか、と[質問](https://marc.info/?l=linux-mm&m=178845212863540&w=2)しました。Sahu 氏は、[回答](https://marc.info/?l=linux-mm&m=178853588235672&w=2)で、小さいリスト（100未満）でも、最悪のサイクル数は二分探索のほうが少ない（3から4対100）と書いています。同時に、命令数は二分探索のほうが多く、キャッシュミスも起きうると認め、memblock は起動時の初期化コードなので、マイクロ秒からナノ秒の差は問題にならない、と述べています。この主張は、パッチ作者のものです。

コミットの Reviewed-by は、Pratyush Yadav 氏のみです。Mike Rapoport 氏の Signed-off-by は "Mike Rapoport (Microsoft)" で、10月24日（UTC の11:21、日本時間 20:21）に、[Linus 宛てのプルリクエスト](https://marc.info/?l=linux-mm&m=179284071612195&w=2)を送りました。

### mainline の状況

Linus Torvalds 氏が `Merge tag 'memblock-v7.4-rc1'` を[コミット](https://github.com/torvalds/linux/commit/394023fbe34fccec5d4db2576169d21e14c8d3d4)したのは、UTC の10月26日 3:27（日本時間 10月26日(月) 12:27）です。つまり、動画の公開より前に、パッチは mainline に入っていました。ただし、10月28日の確認時点で、7.4-rc1 はまだ出ていません（`v7.4-rc1` のタグはなく、master の Makefile は 7.3 のままでした）。

7.4 の正式版の時期を告知した一次は見つかりませんでした。過去の周期（7.2-rc1 から 7.2 まで、7.3-rc1 から 7.3 までが、いずれも約7週間）から書き手が計算すると、年末ごろになるという目安です。これは確定した予定ではありません。

### KHO とは

KHO は Kexec HandOver の略です。[カーネルの文書](https://docs.kernel.org/core-api/kho/index.html)は、"Kexec HandOver (KHO) is a mechanism that allows Linux to preserve memory regions, which could contain serialized system states, across kexec." と説明しています。[最初のコミット](https://github.com/torvalds/linux/commit/3dc92c311498c4d307cfdd0c6c3ac9355b50f683)の作者は、Amazon のアドレスを使う Alexander Graf 氏で、Mike Rapoport 氏（Microsoft）、Pratyush Yadav 氏（当時は Amazon のアドレス）、Changyuan Lyu 氏（Google のアドレス）が co-developed として加わっています。

[Live Update Orchestrator の文書](https://docs.kernel.org/core-api/liveupdate.html)は、Live Update を、kexec ベースの再起動で、選んだ資源の状態を保ち、指定した機器を動かしたままにする仕組みと説明しています。KHO は、その土台としてメモリの状態を渡します。

最新の情報は、torvalds/linux の履歴と、kernel.org のリリース情報で確認してください。

動画の訂正です。

- 動画では、10月24日のプルリクエストのあと、「正式に入るのは、年末に予定されているLinux 7.4のリリース以降になります」と紹介し、画面にも「正式採用: Linux 7.4 (年末予定)」と出しました。パッチは、放送の約41時間前の UTC の10月26日 3:27（日本時間 12:27）に、7.4 のマージウィンドウで mainline にマージ済みでした。7.4-rc1 と正式版は、まだ出ていません（[Linus のマージコミット](https://github.com/torvalds/linux/commit/394023fbe34fccec5d4db2576169d21e14c8d3d4)）。
- 動画では、KHO を「GoogleとMicrosoftが一緒に開発しています」と紹介し、画面にも「開発: Google と Microsoft」と出しました。最初のコミットの作者は Amazon のアドレスを使う Alexander Graf 氏で、Rapoport 氏（Microsoft）、Yadav 氏（当時は Amazon のアドレス）、Lyu 氏（Google のアドレス）が co-developed として加わっています（[最初のコミット](https://github.com/torvalds/linux/commit/3dc92c311498c4d307cfdd0c6c3ac9355b50f683)）。
- 動画では、KHO を「マシンを再起動せずに新しいカーネルへ引き継ぐ、ライブアップデートの仕組み」と紹介しました。カーネルの文書は、KHO を kexec をまたいでメモリ領域を保つ仕組みと書き、Live Update も kexec ベースの再起動の一種と説明しています。「ライブアップデート」は Live Update Orchestrator の名前で、KHO はその土台です（[KHO の文書](https://docs.kernel.org/core-api/kho/index.html)、[Live Update Orchestrator の文書](https://docs.kernel.org/core-api/liveupdate.html)）。
- 動画では、変更を「追加36行・削除2行」と紹介し、画面にも出しました。36行と2行は、9月3日の初版の値です。mainline に入ったコミットは、`mm/memblock.c` の追加28行、削除15行です（[コミット](https://github.com/torvalds/linux/commit/7933ad3f669670ca5f5f13de2b5cb0f92b91abf5)）。
- 動画では、「最悪でもN log Nに収まり、順番どおりに追加されるケースならNで済む」と紹介し、画面にも出しました。この文言は、初版から9月26日の版までのものです。mainline に入ったコミットの本文は、候補を探す処理の計算量が O(N) から O(log N) になる、と書いています（[コミット](https://github.com/torvalds/linux/commit/7933ad3f669670ca5f5f13de2b5cb0f92b91abf5)）。

## 4. Linux 7.2.13 と 6.18.59 — CIFS・ksmbd・KVM の修正と、版ごとの入り方の違い

Linux の安定版 7.2.13 と、長期サポート版（LTS）の 6.18.59 の公開は、kernel.org の releases.json で UTC の10月26日です。タグの時刻は、7.2.13 が UTC の15:01、6.18.59 が 15:09 で、日本時間では10月27日(火)の0時台にあたります。Greg Kroah-Hartman 氏の告知メールの Date は、[7.2.13](https://lwn.net/Articles/1102974/) と [6.18.59](https://lwn.net/Articles/1102975/) で、5秒しか違いません。告知は、7.2 の利用者に "All users of the 7.2 kernel series must upgrade." と求め、6.18 の利用者にも同じ文言です。更新を勧める、というより、更新が必須という言い方です。

### 修正ごとの入り方

ChangeLog（[7.2.13](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.13)、[6.18.59](https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.18.59)）で確かめると、修正ごとに入った版が違います。

| 修正 | 7.2.13 | 6.18.59 |
|---|---|---|
| CIFS の ACL のヒープオーバーフロー | あり | あり |
| SMB1 の拡張属性の範囲外書き込み | あり | なし |
| 切り詰めと並行書き込みのデータ破損（2件） | あり | あり |
| NTFS の `ntfs` ドライバの修正（9件） | あり | なし（`ntfs3` の別の修正のみ） |
| ksmbd の初期化前メモリ（3件） | あり | あり |
| KVM の SS ビット | あり | あり |
| UDP のエフェメラルポート | なし（7.2.11 で入っていた） | あり |

### CIFS と SMB

CIFS の修正（`smb: client: fix heap overflow in cifs_do_set_acl()`）は、ACL のサイズを xattr 形式で検査したあと、CIFS の送信形式に変換するときに、バッファを越えて書く問題です。コミット本文には、xattr 形式の検査は 4 + count × 8 バイト、変換後の CIFS 形式は 6 + count × 10 バイトで、"An ACL that passes the xattr-based check in cifs_set_acl() can overflow the heap when posix_acl_to_cifs() writes the larger CIFS format." とあります。悪意のある SMB サーバーが引き金になる、という記述は、コミット本文には見当たりません。

SMB1 の問題は、7.2.13 だけに入っています。コミット本文によれば、権限のないユーザーが、SMB1 のマウントに setxattr(2) で大きな値を書くと、リクエストのバッファを越えて書き込みます。

切り詰めと並行書き込みの修正は、2件あります。コミット本文は、並行する書き込みが、フラッシュのあとでローカルの切り詰めの前に新しいページを汚し、そのページが黙って捨てられる、と説明します。続く修正は、すでに進行中の直接 I/O や非同期 I/O が、切り詰めのあとに完了し、新しい EOF の先に古いデータを復活させる、という問題です。

### NTFS と ksmbd

7.2.13 には、新しい `ntfs` ドライバの修正が9件あります。7.2-rc1 の [NTFS の更新](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=dbad5db3a0bbf843adef9732ad44b817273e0a64)には、不正なメタデータの扱いの強化と、Windows のネイティブなシンボリックリンクの追加が入りました。ただし、その強化の過程で見つかったバグが今回まとめて直った、と説明した一次は見つかりません。6.18.59 に入っているのは、別のドライバ `ntfs3` の修正です。

ksmbd の修正は、複合リクエストのときに、本来見せない応答の一部が最大31バイト漏れる問題です。応答のバッファに、前の内容が残る場合があります。FS_OBJECT_ID_INFORMATION など3件で、両方の版に入っています。

### KVM と UDP

KVM の修正（`KVM: x86/mmu: Cope with the SS bit being set in #NPF exit codes`）は、KVM のゲストの Windows 11 で Hyper-V を動かしているときに、シャドウ化した NPT のネストしたページフォルトのエラーコードに SS ビットが立つ問題です。AMD のマニュアルは、SS がいつ立つかを明確に書いていません。コミット本文は、予期しない SS ビットが permission_fault() で範囲外アクセスを起こし、警告や UBSAN の報告として現れると書いています。ゲストが落ちる、という記述は本文にありません。

UDP の修正（`ipv4: udp: Create exceptions before socket matching`）は、[upstream のコミット](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4c3499f79f8c7e8561266bcc220a18538cec0458)の本文によれば、経路上にいない攻撃者が FNHE キャッシュのサイドチャネルで、接続済み UDP ソケットが使うエフェメラルポートを突き止められる問題への対策です。待ち受けのポートではなく、接続済みソケットの送信元側のポートです。さらに、この修正が今回新しく入ったのは 6.18.59 だけで、7.2 系には 7.2.11 で入っています。

### 6.18 の期間と、下流のカーネル

kernel.org の[リリースの表](https://www.kernel.org/category/releases.html)は、6.18 の予定のサポート終了を Dec, 2028 と書いています。Wayback Machine の保存では、2026年2月21日の時点で Dec, 2027、2月26日の時点で Dec, 2028 でした。延長は2026年2月に反映されています。同じ表は、この終了日は固定ではなく、業界の支援があれば延長されうる、と注記しています。

XanMod は、GitLab のタグで 6.18.59 が UTC の10月26日 16:51、7.2.13 が 16:56 のコミット作成です。Liquorix は、7.2-22 のタグが UTC の10月26日 20:36 です。いずれも同じ日に追随しました。

### 誰が確かめるか

CIFS や SMB のクライアントとして使うマシン、ksmbd を動かすサーバー、AMD の KVM ホストで Windows 11 のゲストと Hyper-V を使う環境は、優先して確かめます。更新後は、再起動して、`uname -r` で動いているカーネルが新しい版になっているかを確かめます。更新のコマンドは、使っているディストリビューションの公式の手順に従ってください。

最新の情報は、ChangeLog、kernel.org のリリースの表、ディストリビューションのアドバイザリで確認してください。

動画の訂正です。

- 動画では、「UDPの処理で、外部の攻撃者が待ち受けのポートを探り当てようとする手口への耐性が上がっています」と紹介し、画面にも「UDP: 待ち受けポートの推測に耐性」と出しました。コミット本文は、接続済み UDP ソケットが使うエフェメラルポートを推測する手口への対策と書いています。また、この修正が入ったのは 6.18.59 で、7.2 系では 7.2.11 で入っていて、7.2.13 の新規の修正ではありません（[ChangeLog-6.18.59](https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.18.59)、[upstream のコミット](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=4c3499f79f8c7e8561266bcc220a18538cec0458)）。
- 動画では、CIFS の ACL の問題を、「悪意のあるSMBサーバーや、細工したマウントポイントを経由して引き起こせるとされています」と紹介し、画面にも「悪意ある SMB サーバー経由で発生しうる」と出しました。この記述の出典は確認できませんでした。コミット本文が書く条件は、xattr 形式の検査を通った ACL が、CIFS 形式への変換で溢れる、というもので、クライアントが送信バッファに書く側の問題です（[ChangeLog-7.2.13](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.13)）。
- 動画では、2本が「8分も空けずに続けて出ています」と紹介しました。タグの時刻の差は8分13秒で、8分をわずかに超えます。tar.xz の更新時刻の差は9分53秒、告知メールの差は5秒です（[7.2.13 のタグ](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tag/?h=v7.2.13)、[6.18.59 のタグ](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tag/?h=v6.18.59)、[告知メール](https://lwn.net/Articles/1102974/)）。
- 動画では、KVM の修正を「Windows 11を動かして、Hyper-Vの機能を使うと、ゲストが落ちる原因になっていたとされています」と紹介し、画面にも出しました。この「ゲストが落ちる」という記述は、出典を確認できませんでした。ChangeLog のコミット本文にあるのは、permission_fault() での範囲外アクセスと、警告や UBSAN の報告で、ゲストが落ちるとは書かれていません（[ChangeLog-7.2.13](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.13)）。

## 5. PHP の CVE-2026-115560 — 条件がそろわない限り成り立たない穴と、緩和策の1行

CVE-2026-115560 は、[10月27日の記事](https://blog.fuga.jp/posts/2026-10-27-linux-oss-trend/)の第5節で、php.net の告知を紹介した件の続報です。PHP2Shell は、[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)と10月27日の記事で扱いました。PHP2Shell の中身は、ここでは繰り返しません。

### php.net の見方

[php.net の告知](https://www.php.net/archive/2026.php)（"Informational advisory: Session upload progress"）の公開は、UTC の10月23日 10:12（日本時間 19:12）です。告知の日付を書いているだけで、この問題が見つかった日は、一次のどこにも書かれていません。

告知は、"The issue can only occur under an unusual combination of configuration and application code." と書いています。成り立つ条件は、次の3つです。

- アプリケーションが、設定で `session.serialize_handler` を `php_binary` か `php_serialize` にしている
- 実行時に `ini_set()` で `php` に切り替えてから、`session_start()` を呼んでいる
- セッションのアップロード進捗（`session.upload_progress.enabled`）が有効なままになっている

告知は、"Applications that never change the serialize handler at runtime can keep the feature enabled." とも書きます。実行時にハンドラーを切り替えないアプリでは、機能を有効のままにしてよい、という意味です。

PHP チームの見方は、告知の原文で読めます。緩和策は "to fully protect from an unlikely RCE vector" のためで、"Since this setup is unlikely in practice, we are handling it in the regular release cycle and will publish a full advisory for CVE-2026-115560 with the next release." とあります。この構成は実際には起こりにくいので、通常のリリースの周期で扱い、完全な勧告は次のリリースで出す、という意味です。仕組みの詳細は、告知にも Amazon Linux のページにも書かれていません。この記事も、攻撃の手順は書きません。

### 深刻度と、登録の状況

Amazon Linux の[セキュリティ情報](https://explore.alas.aws.amazon.com/CVE-2026-115560.html)は、公開が2026年10月23日で、Amazon Linux の評価として、CVSS v3.1 の 8.1、Severity は Important としています。ベクターは `CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H` です。AC:H は、攻撃の複雑さが高いという意味です。php.net の言う「特殊な組み合わせ」と整合しますが、ALAS がその理由を書いているわけではありません。ページに「暫定」の語はありません。ただ、NVD の採点がまだないので、あくまで Amazon Linux の評価です。NVD が採点すれば、別の値が付く可能性もあります。

NVD は、10月28日の 9:19（日本時間）の確認で、構造化 API の結果が0件でした。MITRE の CVE レコードの API も、レコードなしと返しました。10月27日の記事の「NVD には未登録」は、その後も変わっていません。CVE 番号そのものは、php.net の告知と Amazon Linux のページで使われています。NVD や CVE.org への登録状況は今後変わる見込みなので、最新の状況は [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-115560) と [CVE.org](https://www.cve.org/CVERecord?id=CVE-2026-115560) で確かめてください。

### 影響のバージョン

php.net の告知は、影響を受ける版を書いていません。[Cloudflare](https://blog.cloudflare.com/php-vulnerabilities-waf-protection/) は、"It affects fully patched PHP releases, including 8.5.12, and will be fixed in PHP's next regular release." と書いています。10月28日の確認時点で、php.net の[アクティブなリリース](https://www.php.net/releases/active.php)の最新は、8.2.35、8.3.36、8.4.27、8.5.12（いずれも10月21日）のままで、次の通常のバグ修正リリースは、まだ出ていません。

Amazon Linux は、自社のパッケージの状態を載せています。Amazon Linux 2023 では、php8.1 が "No Fix Planned"、php8.2 から 8.5 が "Pending Fix" です。php.net が影響範囲を示さない以上、8.1 以下や特定の系統を、この記事で除外はしません。主要な CMS については、php.net は何も書いていません。

### 緩和策と、設定の場所

php.net は、次の通常のバグ修正リリースまで、`session.upload_progress.enabled=0` に設定するよう勧めています。この設定は、10月21日の PHP2Shell の GHSA でも緩和策に挙がっていました。php.net は、"If you applied it then, keep it in place and no further action is needed." と書いています。その緩和策を適用して、ワーカーを再起動していたなら、CVE-2026-115560 については、追加の作業は要らない、という意味です。修正版への更新だけでは、この設定は入りません。

PHP2Shell そのものは、緩和策だけでは足りません。GHSA は、この設定が他の経路を防がないと書いており、PHP2Shell の対策は修正版への更新です。10月22日と10月27日の記事で紹介した、php.net の「更新だけが安全な選択」という書き方とは、対象の CVE が違うので矛盾しません。

設定の場所は、php.net の10月21日の告知が、リクエストの解析より前に効く場所を挙げています。php.ini、FPM のプール、サーバーの設定です。`ini_set()` や FPM の `.user.ini` には頼らない、とあります。[マニュアル](https://www.php.net/manual/en/session.configuration.php)によれば、この設定の既定値は 1 で、変更できる範囲は INI_PERDIR です。[PHP-FPM のマニュアル](https://www.php.net/manual/en/install.fpm.configuration.php)は、php_admin_value と php_admin_flag で決めた設定は `ini_set()` で上書きできない、と書いています。php_admin_value を勧めたのは php.net ではなく、書き手の補足です。

セッションのアップロード進捗は、PHP 5.4 の UPGRADING に載った機能で、マニュアルは、アップロードの間、クライアントが指定したファイル名とフィールド名がセッションのストアに書かれ、それらは検証されない、と注意しています。進捗バーを使わないアプリでは、このオプションの無効化を検討するよう書いています。

### 2015年の報告

[bugs.php.net の Bug #71101](https://bugs.php.net/bug.php?id=71101)は、2015年12月12日（UTC）の投稿です。現在の件名は "serialize_handler must not be switched for existing sessions" で、2021年9月24日に付いたものです。種別は Documentation Problem、状態は Analyzed です。2015年の元の件名は "PHP Session Data Injection Vulnerability" で、投稿の本文は、upload_progress が有効で、スクリプトで別の serialize_handler を設定すると、任意のセッションデータを注入できる、と書いています。同じ組み合わせを指した報告が、2015年にあったことになります。ただし、php.net の告知は、このバグと CVE-2026-115560 との関係を書いていません。この記事も、関係があるとは断定しません。

### 誰が確かめるか

まず、アプリのコードに、`ini_set()` で `session.serialize_handler` を切り替えている箇所がないかを探します。アップロードの進捗を使っていなければ、`session.upload_progress.enabled=0` を、php.ini か FPM の設定に入れ、全ワーカーを再起動します。コンテナで動かしていて、設定をイメージに含めている場合は、イメージを作り直します。PHP2Shell の修正版（8.2.35、8.3.36、8.4.27、8.5.12 以降）への更新も、並行して続けます。

最新の情報は、php.net の告知、NVD、ALAS、php.net のリリース一覧で確認してください。

動画の訂正です。

- 動画では、影響の範囲を「PHP 8.2から8.5の系統が対象と見られています」と紹介し、画面にも出しました。php.net は影響を受ける版を書いておらず、8.2 から 8.5 に限る根拠は一次にありません。Cloudflare は 8.5.12 を含む修正済みの版にも影響すると書き、Bug #71101 の欄は "PHP Version: Irrelevant" で、Amazon Linux は php8.1 も一覧に載せています（[php.net](https://www.php.net/archive/2026.php)、[Cloudflare](https://blog.cloudflare.com/php-vulnerabilities-waf-protection/)、[ALAS](https://explore.alas.aws.amazon.com/CVE-2026-115560.html)、[Bug #71101](https://bugs.php.net/bug.php?id=71101)）。
- 動画では、「10年以上前に似た指摘があったのに、今になって攻撃の手順が示されたってことか」という問いに、「はい」と答えました。「10年以上前」は、2015年12月12日から2026年10月23日まで約10年10か月で、そのとおりです。ただし、再現の手順は2015年の報告に既に載っていて、今回 php.net が示したのは、成り立つ条件と緩和策です。仕組みの詳細を含む完全な勧告は、次のリリースで出すと書いています（[Bug #71101](https://bugs.php.net/bug.php?id=71101)、[php.net](https://www.php.net/archive/2026.php)）。
- 動画では、「緊急パッチの直後に見つかった」「その2日後に見つかったのが、今回のCVE-2026-115560」と紹介しました。10月23日は php.net が告知した日で、見つかった日は一次のどこにも書かれていません。同じ組み合わせを指した報告は2015年の Bug #71101 にありますが、php.net は、この CVE との関係を書いていません（[php.net](https://www.php.net/archive/2026.php)、[Bug #71101](https://bugs.php.net/bug.php?id=71101)）。

## まとめ

BlackX の件は、DBX の更新が済んでいるかを、PowerShell のコマンドで確かめます。更新するなら、Microsoft の KB5025885 の順序に従い、回復用メディアを用意し、代表機で試してからです。Linux の読者は、`mokutil --list-enrolled` で、身に覚えのない鍵がないかを見ます。Kali 2026.3 は、ブログの手順で更新し、`VERSION_ID="2026.3"` を確かめます。memblock の高速化は、KHO を使う環境の話で、7.4 のマージウィンドウで mainline に入りましたが、7.4-rc1 は確認時点で未リリースです。7.2.13 と 6.18.59 は、修正ごとに入った版が違うので、自分の版にある修正を表で確かめ、再起動して `uname -r` を見ます。PHP の CVE-2026-115560 は、`session.upload_progress.enabled=0` を設定し、全ワーカーを再起動します。NVD や CVE.org には、確認時点で登録がありません。

5本に共通する「修正のあとの仕上げが済んでいるか」という見方は、書き手の考察です。失効リストの更新、緩和策の1行、カーネルの再起動は、どれも修正の効き目を実際の環境で出すための一手です。memblock は、前提が変わった環境で、速さを測り直す価値を示しました。

まず確かめることを挙げます。

- Windows の Secure Boot を使う環境では、DBX に PCA 2011 が載っているかを確かめる。更新する前に、回復用メディアと BitLocker の回復キーを確保し、代表機で試す
- Linux の Secure Boot の環境では、`mokutil --list-enrolled` で、登録済みの鍵を確かめる
- Kali を使っているなら、更新後に `grep VERSION /etc/os-release` で 2026.3 を確かめる。NVIDIA を使う物理マシンは、更新前に Kali の文書を読む
- 安定版カーネルを使っているなら、自分の版（7.2.13 か 6.18.59 か）に入っている修正を確かめ、再起動して `uname -r` で新しいカーネルで動いているかを確かめる
- PHP を使っているなら、`session.upload_progress.enabled=0` が入っているかを確かめる。PHP2Shell の修正版への更新も続ける。設定をイメージに含めたコンテナは、イメージを作り直す

## 参考リンク

- [Securelist: BlackX の分析](https://securelist.com/uefi-bootkit-blackx/121539/)
- [Microsoft: KB5025885（CVE-2023-24932 の失効手順）](https://support.microsoft.com/en-us/topic/how-to-manage-the-windows-boot-manager-revocations-for-secure-boot-changes-associated-with-cve-2023-24932-41a975df-beb2-40c1-99a3-b3ff139f832d)
- [Microsoft: Secure Boot 証明書の期限](https://support.microsoft.com/en-us/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e)
- [MSRC: CVE-2022-21894](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2022-21894)
- [Kali Linux 2026.3 のリリースブログ](https://www.kali.org/blog/kali-linux-2026-3-release/)
- [memblock の二分探索のコミット](https://github.com/torvalds/linux/commit/7933ad3f669670ca5f5f13de2b5cb0f92b91abf5)
- [memblock-v7.4-rc1 のマージコミット](https://github.com/torvalds/linux/commit/394023fbe34fccec5d4db2576169d21e14c8d3d4)
- [Linux 7.2.13 の ChangeLog](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.2.13)
- [Linux 6.18.59 の ChangeLog](https://cdn.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.18.59)
- [php.net のセキュリティ告知](https://www.php.net/archive/2026.php)
- [Amazon Linux: CVE-2026-115560](https://explore.alas.aws.amazon.com/CVE-2026-115560.html)
- [bugs.php.net: Bug #71101](https://bugs.php.net/bug.php?id=71101)

（2026/10/28 Linux・OSSトレンド）
