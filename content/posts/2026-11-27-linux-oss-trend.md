---
title: "Drupal が CVE-2026-132165 の修正版を公開し CISA KEV にも追加、Pop!_OS 26.04 LTS が公開、Mesa の RadeonSI は radeon カーネルドライバーを既定で無効化、Linux 7.4 は AutoFDO の Profi を無効化、CISA KEV に11月25日付で10件を追加（2026/11/27 Linux・OSSトレンド）"
date: 2026-11-27T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Drupal", "Pop!_OS", "COSMIC", "Mesa", "AMD", "Linux カーネル", "LLVM", "AutoFDO", "Mitel", "Xen Orchestra"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

想定外の状態になったとき、仕組みは閉じる側と開く側のどちらに振れるのか。2026年11月27日（金）の動画は、この問いで5本を並べた回でした。題は「失敗した瞬間に扉が開く! Drupalの裏口、空っぽの値で管理者、Linux 7.4の決断 あなたのシステムはどちらへ倒れる?」です。

この問いがよく当てはまるのは、Drupal と Xen Orchestra の2件です。Drupal では、攻撃者がインストーラーを使って再インストールを試みることができました。CISA は KEV でこの件を CWE-636（not failing securely）に分類しています。Xen Orchestra では、Vates の説明によれば、空のオブジェクトとして読まれた値で最初のトークンが返り、その持ち主として認証が通りました。Linux 7.4 の Profi 無効化は、動機が実行性能の低下とビルド時間の両方にあるため、一部だけ当てはまります。Pop!_OS と Mesa の2本は、この問いの外にあります。Drupal と Xen Orchestra を同じ問いでまとめるのは私の考察で、一次ソースがそう書いているわけではありません。

動画の訂正は、各節の末尾に置きました。確認は2026年11月27日（日本時間）です。動画の公開は11月26日 20:42 UTC（日本時間 11月27日 05:42）です。

{{< youtube "usAM0gSoPfI" >}}

## 1. Drupal core の CVE-2026-132165（SA-CORE-2026-017）

Drupal は、[SA-CORE-2026-017](https://www.drupal.org/sa-core-2026-017) を2026年11月18日付で公開しました。CVE は CVE-2026-132165 で、リスクは Drupal 独自の書き方で「Highly critical 20/25」です（`AC:Complex/A:None/CI:All/II:All/E:Exploit/TD:Uncommon`）。アドバイザリは、攻撃者がインストーラーを使って Drupal の再インストールを試みられる、と説明しています。攻撃の具体は、ここでは書きません。

- 修正版は 10.6.22、11.3.22、11.4.13。影響を受けるのは、10.6.22 より前、11.0.0 以上 11.3.22 未満、11.4.0 以上 11.4.13 未満。
- 11.2.x 以下と 10.5.x 以下は EOL で、セキュリティの対応を受けられない。Drupal 8 と 9 も EOL。
- 発見のクレジットは「Anthropic's OSS Scanner」。

この件は、[PSA-2026-11-16](https://www.drupal.org/psa-2026-11-16) で事前に予告されていました。11月18日の 17:00 から 21:00 UTC（日本時間 11月19日 02:00 から 06:00）の間に、サポート中の全ブランチの修正版を出す、という内容です。予告時点のリスクは「Critical 18/25」で、匿名のユーザーに悪用されうるものが少なくとも1つあるとも書いていました。

悪用については、SA-CORE-2026-017 に追記があります。早ければ 2026年11月19日 19:00 UTC（日本時間 11月20日 04:00）に実際のサイトで悪用されたという報告を、Drupal の Security Team が受けた、という記述です。報告した主体は、ページには書かれていません。

[CISA の KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)には、CVE-2026-132165 が11月24日に追加されました。連邦機関向けの対応期限は11月27日です。

さらに、[SA-CORE-2026-019](https://www.drupal.org/sa-core-2026-019)（CVE-2026-136716）が11月25日付で出ています。リスクは「Highly critical 21/25」で、種別は Access bypass です。アドバイザリは、SA-CORE-2026-017 でインストーラーの複数の脆弱性を直したあとも、通常と異なる、または不完全なインストール状態のサイトは脆弱なままだ、と書いています。修正版は 10.6.23、11.3.23、11.4.14 です。既存の本番サイトを直すには、更新のあとに update.php を実行して update hook を動かします。

すぐに更新できない場合、SA-CORE-2026-017 は、インストーラーを保護する手順に従うよう案内しています。Drupal のドキュメント[「Securing the installer」](https://www.drupal.org/docs/administering-a-drupal-site/security-in-drupal/securing-the-installer-installphp)は、方法を3つ挙げ、Web サーバーの設定で遮断する方法に recommended と付けています。あわせて、Web サーバーが `settings.php` を書き換えたり権限を変えたりできなければ、悪用の経路の一部（すべてではない）は防げる、とも書いています。

動画の訂正です。

- 動画では、修正版の公開の翌日には、実際のサイトへの攻撃が確認されている、と伝えました。正しくは、SA-CORE-2026-017 は、早ければ 2026年11月19日 19:00 UTC（日本時間 11月20日 04:00）に悪用されたという報告を Security Team が受けた、と書くにとどまります。報告した主体は書かれておらず、Drupal 自身が確認したとは読めません。

## 2. Pop!_OS 26.04 LTS

System76 は11月24日（火）に、[Pop!_OS 26.04 LTS を公開](https://system76.com/blog/post/pop_os-26-04-lts-has-landed)しました。COSMIC は Rust で作られた、Wayland ネイティブのデスクトップ環境です（[System76 の COSMIC のページ](https://system76.com/cosmic)）。

System76 のブログが挙げる追加と変更は、次のとおりです。

- Constellations: 壁紙、アクセントカラー、アイコン、フォントを1回の操作でまとめて切り替えられる。書き出して、バックアップや共有に使える。
- 描画タブレットへの対応。ペンの傾きの検知などが使える。
- 自動更新を、初期設定、または設定の画面から有効にできる。
- COSMIC Viewer、COSMIC System Monitor、作り直した COSMIC Store。
- リモートデスクトップへの対応。

ベースの Ubuntu と各部品の版は、System76 のブログには書かれていません。[OMG! Ubuntu](https://www.omgubuntu.co.uk/2026/11/pop_os-26-04-lts-released) は、最新の Ubuntu LTS をベースにしたと報じています。[GamingOnLinux](https://www.gamingonlinux.com/2026/11/pop-os-26-04-lts-is-out-now-with-new-theme-bundles-remote-desktop-drawing-tablet-support-and-more/) は、COSMIC Epoch 1.12、Linux カーネル 7.2.15、Mesa 26.2.3 と書いています。

24.04 LTS からの更新については、System76 は「24.04 から 26.04 へのアップグレードは12月に有効になる」と書いています。同じ段落で、COSMIC はローリングリリースのデスクトップで、24.04 のユーザーは多くの機能をすでに体験している、26.04 の全体を体験するには新規インストールを、とも書いています。

動画の訂正はありません。

## 3. Mesa の RadeonSI が radeon カーネルドライバーを既定で無効化

Mesa の RadeonSI（AMD の GPU 向けドライバー）に、radeon カーネルモジュールの対応を既定で無効にする変更が入りました。Pierre-Eric Pelloux-Prayer 氏の[マージリクエスト !46489](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/46489)で、2026年11月23日 18:04 UTC（日本時間 11月24日 03:04）に main にマージされています。main の版は 27.0.0-devel です。[Mesa のリリースカレンダー](https://docs.mesa3d.org/release-calendar.html)の予定では、27.0.0-rc1 は2027年1月13日です。27.0 に入るのは予定の段階です。

変更の中身は、[コミット](https://gitlab.freedesktop.org/mesa/mesa/-/commit/a6017e961b015391a2836b175787ed6b8b6cf9f6)で確かめられます。radeon カーネルモジュールの上では、RadeonSI は警告を出して動きません。環境変数 `AMD_DEBUG=use_radeon` を付けたときだけ、従来どおり radeon を使えます。警告文は、radeon の対応は無効化されており、将来のリリースで削除される、と書いています。コミットメッセージに書かれた理由は「将来削除される予定なので、ユーザーに警告する」だけです。

対象は、GFX6 と GFX7（GCN 1 と 2。Southern Islands と Sea Islands。GCN 1.0・1.1 とも呼ばれます）の GPU です。[Timur Kristóf 氏のブログ](https://timur.hu/blog/2026/love-song-for-linux-gamers-with-old-gpus-eoy2025)には、Radeon HD 7850・7870 などが GFX6、Radeon R9 290・290X などが GFX7 の例として挙がっています。

[Mesa の RADV の文書](https://docs.mesa3d.org/drivers/radv.html)によると、カーネル側の既定は次のとおりです。

- GFX6-7 の単体 GPU は、Linux 6.19 から amdgpu が既定。
- GFX7 の APU は、Linux 7.1 から amdgpu が既定。
- 古い radeon カーネルドライバーでは、RADV（Vulkan のドライバー）は動かない。

古いカーネルで amdgpu に切り替える kernel command line の方法も、この文書に書かれています。自分の環境で使用中のカーネルドライバーが amdgpu か radeon かは、[lspci(8)](https://man7.org/linux/man-pages/man8/lspci.8.html) の出力で確かめられます。

動画の訂正はありません。

## 4. Linux 7.4 が AutoFDO の Profi を無効化

Linux 7.4 の開発ツリーに、AutoFDO のビルドで LLVM の Profi を無効にするコミット[3df238d7a9](https://github.com/torvalds/linux/commit/3df238d7a9f5ac7d78115958fd7a36139f61ca34)が入りました。作者は Douglas Anderson 氏、コミッターは Nathan Chancellor 氏です。Kbuild の fixes（タグ `kbuild-fixes-7.4-2`）として、11月24日に Linus のツリーへマージされています（[マージコミット](https://github.com/torvalds/linux/commit/4ca7b0f616)）。7.4-rc4 は11月22日に出ているので、マージウィンドウではなく、rc の期間中の修正です。

Profi は profile inference の略で、LLVM の flow-based profile inference algorithm です。AutoFDO のプロファイルはサンプリングで集めるため、欠けや誤差があります。LLVM のソースによれば、Profi は、不完全で不正確かもしれないブロックの実行回数から、流れの保存則を満たすように、現実的な回数を組み立て直します（[SampleProfileInference.cpp](https://github.com/llvm/llvm-project/blob/main/llvm/lib/Transforms/Utils/SampleProfileInference.cpp)）。Clang 21 からは、`-fprofile-sample-use` を指定すると、Clang のドライバーが自動で Profi を有効にします（[LLVM のコミット](https://github.com/llvm/llvm-project/commit/2fc4a4a9d3a87a9e11c48ef25522aa17c2a71003)）。

コミットメッセージが挙げる理由は2つです。

- カーネルの AutoFDO は FS-AFDO（flow-sensitive discriminators）を使い、Profi には FS-AFDO との既知の問題がある。LLVM 元来のプロファイル伝播のアルゴリズムに比べて、実行性能が下がる。
- Profi の最小費用最大流のソルバーは、プロファイルが少しずれたとき、または GCOV と併用したとき、特定のカーネルの制御フローグラフで、30分以上かかる、またはハングする。

修正は、Clang 21 以上のとき `-fno-sample-profile-use-profi` を渡すものです。Rust 側とリンカー（ThinLTO）側にも同じ趣旨の指定が入りました。コミットメッセージによれば、Rust 側の LLVM バックエンドは Profi が元から無効で、Clang のドライバーだけが有効にします。Rust とリンカーの指定は、将来 rustc や LLVM の既定が変わっても、C・Rust・ThinLTO の指定を揃えておくための明示です。コミットには `Cc: stable` が付いていて、stable への取り込みが依頼されています。取り込み済みかどうかは、確認できていません。

同じ 7.4 の Kbuild では、Lorenzo Stoakes 氏のビルド高速化のシリーズの最初の部分が、kbuild-7.4-1 として入りました。カバーレターは、このシリーズで allmodconfig のビルドが最大36%、差分のビルドが最大約70%速くなる、と書いています。36%は、allmodconfig のフルビルドを512スレッドの EPYC 9754 で測った値です。シリーズの残りは、7.4 にはまだ入っていません。

動画の訂正です。

- 動画では、全部入りの設定で、フルビルドは最大36%、差分のビルドは最大70%の短縮が目標だと伝えました。正しくは、36%と約70%は目標ではなく、Stoakes 氏がシリーズ全体について測った最大値です（36%は allmodconfig のフルビルドを512スレッドの EPYC で測った値）。7.4 に入ったのは、そのシリーズの最初の部分で、残りは未マージです。

## 5. CISA が KEV に10件を追加（Mitel・Danfoss・Juniper・Xen Orchestra）

CISA は、米国時間11月25日（日本時間 11月26日早朝）に、KEV カタログへ10件を追加しました（[CISA の告知](https://www.cisa.gov/news-events/alerts/2026/11/25/cisa-adds-10-known-exploited-vulnerabilities-catalog)）。告知は、実際に悪用されている証拠に基づく追加だと書いています。内訳は、Mitel 5件、Danfoss 3件、Juniper 1件、Vates 1件です。対応期限は、米国の連邦文民行政機関向けに、8件が11月28日（土）、2件（CVE-2026-133311 と CVE-2025-41450）が12月9日（水）です。

CVSS の値は採点者によって異なるため、以下では採点者を添えます。

### Mitel MiCollab（5件）

[MISA-2026-0012](https://www.mitel.com/support/security-advisories/mitel-product-security-advisory-misa-2026-0012) は、MiCollab の Audio, Web and Video Conferencing（AWV）コンポーネントの脆弱性です。CVE は CVE-2026-133275、133303、133311、133323、133324 です。最も重いのは CVE-2026-133323 で、認証なしの攻撃者が、ブラインドのコマンドインジェクションでシステム上の任意のコマンドを実行できます。Mitel の評価で CVSS 3.1 の 10.0 です（NVD の採点は 9.8）。Mitel は、これらを組み合わせると影響が大きく増える、と注意しています。対象は MiCollab 10.3（10.3.0.18）以前で、10.3（10.3.0.18）向けにパッチが提供されています。

### Danfoss AK-SM 800A（3件）

3件は CVE-2023-25914、CVE-2023-25915、CVE-2025-41450 です。このうち CVE-2023-25914 は、2023年8月21日に公開されています。DIVD の記述では、認証済みの攻撃者が、XML インターフェース経由でサーバーのシステムファイルを読み取れます。3.3 未満が影響を受け、修正は 3.3 です（[DIVD](https://csirt.divd.nl/cves/CVE-2023-25914/)）。CVSS の値は、DIVD のページと CVE レコードで食い違うため、ここでは書きません。CVE-2025-41450 は、日時に基づくパスワード生成の問題で認証を回避できる可能性がある、と CISA の ICS アドバイザリが書いています（[ICSA-25-140-03](https://www.cisa.gov/news-events/ics-advisories/icsa-25-140-03)）。R4.2 未満が影響を受け、修正は R4.2 です。Danfoss の評価で CVSS 3.1 の 8.2 です（NVD は 7.5）。

### Juniper Session Smart Conductor（1件）

CVE-2026-103406 は、AutomatedProvisioner の OS コマンドインジェクションです。リモートの攻撃者が root としてコマンドを実行できます。Juniper の評価で CVSS 3.1 の 9.8 です。修正版は 7.0.5、7.1.7、7.2.3 と、それぞれ以降のリリースで、回避策はありません（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-103406)。識別子は JSA112183）。

### Vates Xen Orchestra（1件）

CVE-2026-133469 について、Vates は [VSA-2026-062](https://docs.vates.tech/security-advisories/advisories/2026/vates-sa-2026-062/) を11月10日に公開しています。Vates の説明では、REST のクッキーの解釈で空のオブジェクトが作られ、トークンの検索が絞り込みなしの扱いになり、最初のトークンが返ります。そのトークンの持ち主として認証される、という仕組みです。影響（Impact）の欄は、攻撃者が認証を回避し、Admin 権限の操作ができる、と書いています。Vates は、この脆弱性が攻撃者に悪用されていることも明記しています。認証なしのアクセスを検知するログは残らない、とも書いています。GitHub の評価で CVSS 3.1 の 9.8 です。修正は、stable の 6.9.2 と latest の 6.10.1 です。

別の件として、[VSA-2026-063](https://docs.vates.tech/security-advisories/advisories/2026/vates-sa-2026-063/) は、VM の取り込み機能の問題を扱っています。11月10日時点では修正が含まれておらず、確認した時点でも対応中です。緩和策は、VM の取り込みを Admin に限ることです。

動画の訂正はありません。

## まとめ

閉じる側と開く側、という見方は書き手の考察です。確認しておきたいことを挙げます。

- Drupal: 10.6.22・11.3.22・11.4.13 以降へ更新する。あわせて SA-CORE-2026-019 の 10.6.23・11.3.23・11.4.14 と、update.php の実行を確認する。EOL の版は修正の対象外。更新できない間は、Drupal のドキュメントに沿って、インストーラーへのアクセスを Web サーバーの設定で遮断する。
- CISA KEV の10件: 自分の環境の製品が入っていないか確かめる。Mitel は MISA-2026-0012 のパッチ、Danfoss は 3.3 と R4.2、Juniper は 7.0.5・7.1.7・7.2.3、Xen Orchestra は 6.9.2・6.10.1 を、それぞれ確認する。
- Xen Orchestra: VSA-2026-063 は対応中なので、Vates の緩和策に沿って VM の取り込みを Admin に限る。
- Pop!_OS: 24.04 LTS からのアップグレードは12月に有効になる、と System76 は書いている。
- Mesa と古い AMD GPU: `lspci -k` で、使用中のカーネルドライバーが amdgpu か radeon かを確かめる。
- AutoFDO のカーネルを自分でビルドする場合: Clang 21 以上なら、使っているカーネルのソースにコミット 3df238d7a9 が入っているかを確かめる。

## 参考リンク

- [Drupal SA-CORE-2026-017](https://www.drupal.org/sa-core-2026-017)
- [Drupal PSA-2026-11-16](https://www.drupal.org/psa-2026-11-16)
- [Drupal SA-CORE-2026-019](https://www.drupal.org/sa-core-2026-019)
- [System76: Pop!_OS 26.04 LTS Has Landed](https://system76.com/blog/post/pop_os-26-04-lts-has-landed)
- [Mesa のマージリクエスト !46489](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/46489)
- [Mesa の RADV の文書](https://docs.mesa3d.org/drivers/radv.html)
- [Linux カーネルのコミット 3df238d7a9](https://github.com/torvalds/linux/commit/3df238d7a9f5ac7d78115958fd7a36139f61ca34)
- [CISA の告知（KEV に10件を追加）](https://www.cisa.gov/news-events/alerts/2026/11/25/cisa-adds-10-known-exploited-vulnerabilities-catalog)
- [Mitel MISA-2026-0012](https://www.mitel.com/support/security-advisories/mitel-product-security-advisory-misa-2026-0012)
- [Vates VSA-2026-062](https://docs.vates.tech/security-advisories/advisories/2026/vates-sa-2026-062/)

（2026/11/27 Linux・OSSトレンド）
