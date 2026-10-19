---
title: "Linux 7.3 は「すぐ使えます」と言う SSD を信じない、GNOME 51.1 の DnD 修正、Fedora 45 の NO-GO、BeyondTrust と PAN-OS の KEV 期限（2026/10/19 Linux・OSSトレンド）"
date: 2026-10-19T00:00:00+09:00
draft: false
tags: ["Linux カーネル", "Linux 7.3", "GNOME", "Fedora", "セキュリティ", "脆弱性", "BeyondTrust", "Palo Alto Networks", "PAN-OS", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

SSD の「すぐ使えます」、Fedora の「出せる候補があります」、BeyondTrust が受け取った「このメッセージは正しい送り主から来ました」、PAN-OS の管理画面の「ログイン済みです」。今回の5本は、どれも相手の自己申告をそのまま通した場所で何が起きるか、あるいは通さずに確かめる仕組みがあるか、という話です。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "kD0jm2xHoGQ" >}}

## 1. Linux 7.3 — 「すぐ使えます」と申告する Samsung の SSD を、カーネルが信じない

Linux 7.3 は10月18日（米国時間）に正式リリースされました。Linus Torvalds による [v7.3 のタグ](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tag/?h=v7.3)の日時は 2026-10-18 23:14:58（UTC）で、日本時間では10月19日 08:14 です。以下の2つの修正は、7.3 の開発サイクルでマージされたものです。

### Samsung 990 PRO と 990 EVO Plus の Immediate Readiness

PCIe 4.0 には、リセット直後でも設定要求にすぐ応答できることを示す Immediate Readiness のビットがあります（[Phoronix](https://www.phoronix.com/news/Linux-7.3-Samsung-990-Immediate)）。ところが Samsung 990 PRO と 990 EVO Plus の一部のファームウェアは、この機能を宣言しているのに実際には対応していませんでした。[コミット](https://github.com/torvalds/linux/commit/0f8b5d90d179b9639be1dbeff59d6d971e6b0527)のメッセージによれば、一部のファームウェアでは、リセット後に最大7ミリ秒ほど、ほぼ0の値が返ってきます。

カーネルは申告を信じて待ち時間を省き、すぐに設定を書き戻すので、その内容が失われます。Phoronix によれば、この影響で、これらのドライブを VFIO パススルーで使う構成が壊れていました。

対処は、該当する2モデルのデバイス ID を quirks に登録し、「すぐ使えます」の申告を無視するというものです。コミットの題は "PCI: Ignore Immediate Readiness on Samsung 990 PRO and 990 EVO Plus NVMe" で、変更は drivers/pci/quirks.c への12行の追加です。このコミットは、Linus が取り込んだ PCI の[修正プル](https://github.com/torvalds/linux/commit/4766082b791b515953d87f7a24c2ea857e6c10b0)に含まれています。

### まれな起動ハングを直す NBCON の修正

もう1つは、2024年9月に入ったコードに由来する、SMP システムの起動ハングです。NBCON の印字用カーネルスレッドは early_initcall() で起動の早い段階から動き出し、[コミット](https://github.com/torvalds/linux/commit/5f339c46f153184570f16c8e789c9709b14cbe8b)のメッセージによれば、割り込みを非同期に有効化・無効化することで、一部のハードウェアでの SMP の初期化に干渉している可能性があります。

修正の題は "printk: Postpone kthread startup" で、スレッドの起動を、すべての arch initcall が終わったあとまで後ろにずらします。署名には John Ogness 氏の名前があり、報告者と動作確認は Derek Barbosa 氏（Red Hat）です。[Phoronix](https://www.phoronix.com/news/Linux-7.3-KThreads-NBCON)は、この修正が近いうちに現在サポート中の他のカーネル系列へバックポートされる見込みだと伝えています。

### 7.4 に向けたパッチの「2290万パーセント」

[Phoronix の記事](https://www.phoronix.com/news/Linux-7.4-Refill-Sheaves-Barn)によれば、7.4 のマージウィンドウに先立って slab/for-next に登録されたパッチで、barn_get の性能変化が +22904539.81%、barn_put が +21422544.07% と報告されています。これは barn_get と barn_put のマイクロベンチマークの値で、同じ記事は、will-it-scale の mmap1 という単一のテストでは全体で24%の向上だったとも書いています。変更は新規コード81行です。2290万パーセントという数字だけを見て、実際の性能が同じ倍率で上がると受け取ることはできません。

なお Ubuntu 26.10 は10月15日に正式リリース済みです。こちらは[10月15日の記事](https://blog.fuga.jp/posts/2026-10-15-linux-oss-trend/)で扱いました。

動画の訂正です。

- 動画では、旧カーネルの人には「起動オプションで省電力まわりを止める回避策が知られています」と紹介しましたが、そのような回避策は、コミットにも Phoronix の記事にも見当たりません。この問題はリセット直後の待ち時間の話で、省電力の設定とは別の仕組みです。
- 動画では、2290万パーセントの数字について「実用に近いテストでは、全体で24%の向上」と紹介しましたが、24% は will-it-scale の mmap1 という単一のテストでの値です。実用に近いテストと説明できる根拠は、Phoronix の記事にありません。
- 動画では「今月下旬に出る Ubuntu 26.10」と紹介しましたが、Ubuntu 26.10 は10月15日にリリース済みです。

## 2. GNOME 51.1 — Wayland と Xwayland のドラッグ&ドロップ、GNOME Web の CVE-2026-94291

GNOME 51.1 は[リリースチームの告知](https://discourse.gnome.org/t/gnome-51-1-is-released/39501)によれば10月18日（UTC）に公開された、GNOME 51 の安定版バグ修正リリースです。GNOME 51 は9月16日のリリースだったので、約4.5週での最初の修正版になります。[gnome-build-meta の一覧](https://download.gnome.org/sources/gnome-build-meta/51/gnome-build-meta-51.1.news)で新しい版が出たモジュールは、数えると28件です。この数は告知本文にはなく、一覧から数えた値です。

### Mutter 51.1 の修正

Mutter 51.1 の [NEWS](https://gitlab.gnome.org/GNOME/mutter/-/tags/51.1) の先頭は "Fix drag&drop between Wayland and Xwayland clients" です。原因は、[マージリクエスト](https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/5362)のコミットメッセージによれば、ATOM_DND_PROXY が enum から削除されたのに、対応する名前の配列の項目が残っていたことでした。差分は、meta-xwayland-dnd.c の atom 名の配列から "XdndProxy" の1行を消すものです。

同じ NEWS には、次の項目もあります。

- 設定後のウィンドウのモニターを更新する
- パネルの回転をリセットするとき、論理的な通常の向きを使う
- モニターの変更後に workspaces-only-on-primary を正しく適用する
- 同じ serial での選択（セレクション）の変更を許可する。コミットメッセージによれば、GTK3 のアプリが clear_targets() の直後に add_targets() を呼ぶ場合などの、コピー＆ペーストの修正です

### GNOME Web（Epiphany）の CVE-2026-94291

GNOME 51.1 の一覧には、Epiphany（GNOME Web）51.0 から 51.1 への更新も入っています。Epiphany の NEWS は CVE-2026-94291 を、"Epiphany allows insecure iframe through view-source / ephy-reader scheme" と記しています。Epiphany 側の 51.1 は、GNOME 51.1 より早い9月24日付です。

[Epiphany の issue](https://gitlab.gnome.org/GNOME/epiphany/-/work_items/2952)の報告は、HTTP のページから、本来は禁じられるはずの複数のソースを iframe に埋め込めるというものです。[修正コミット](https://gitlab.gnome.org/GNOME/epiphany/-/commit/25e1828903cb2419e18c437723b0f87fb5d31780)のメッセージには、ephy-reader と view-source の URI スキームがローカルファイルの流出（exfiltrate）に使われうると書かれています。修正は、これらのスキームを display isolated として登録し、Web コンテンツから埋め込めないようにするものです。

この CVE は、NVD にも cve.org にも、2026年10月19日の時点で記録がありません。そのため、深刻度の点数は書きません。説明は Epiphany 側の issue とコミットに依拠しています。

### libsoup と Debian の状況

libsoup は 3.7.3 から 3.8.0 になり、Digest 認証での nonce の検証（CVE-2026-3099）、multipart の境界外読み取りの修正（CVE-2026-66337）、サーバー側のリクエストスマグリング対策などが入りました。CVE-2026-3099 は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-3099)によれば、1つの有効な認証ヘッダーを捕まえて何度も再送できる問題です。

Debian では、[Security Tracker](https://security-tracker.debian.org/tracker/CVE-2026-94291)を2026年10月19日 06:50（日本時間）に見ると、trixie が no-dsa（Minor issue）、bookworm が postponed（Limited support）で、修正版が出ているのは forky と sid の 51.1-1 だけでした。

動画の訂正です。

- 動画では、ドラッグ&ドロップの不具合の原因を「順番を示す番号の扱いや、掴んだ状態の処理に食い違いがあって」と紹介しましたが、Mutter 51.1 の修正は、Xwayland のドラッグ&ドロップで使う atom 名の配列の不整合を直したものです。serial の変更は、コピー＆ペーストに関する別の修正です。
- 動画では、修正を「掴んでいる状態を早めに手放すようにして、X11側の処理が止まらないようにしました」と紹介しましたが、51.0 から 51.1 の間に、掴んだ状態を早く解放するような変更は見当たりません。

## 3. Fedora 45 の NO-GO — 「適切な RC が無かった」

Fedora 45 の Final は、2026年10月15日（米国時間）に NO-GO と告知されました。[devel-announce の告知](https://www.mail-archive.com/devel@lists.fedoraproject.org/msg215769.html)は、Fedora の運用担当者によるもので、理由を次のように書いています。

> Because no suitable release candidate (rc) was available, we do not have an F45 Final RC. As a result, F45 Final is NO-GO by default.

告知が述べる理由は、適切な RC が無かったことまでです。なぜ RC が作れなかったかは書かれていません。

次の目標は、同じ告知によれば10月27日（火）です。予備日の11月3日（火）は、[スケジュール表](https://fedorapeople.org/groups/schedule/f-45/f-45-key-tasks.html)の Final Target date #3 と、[Phoronix](https://www.phoronix.com/news/Fedora-45-First-No-Go)の説明によるものです。次の Go/No-Go 会議は、10月22日の 17:00 UTC（日本時間では10月23日（金）の 02:00）に開かれる予定です。10月27日は目標で、決まるのはその会議です。

候補は、その後に出ました。[test-announce](https://www.mail-archive.com/test-announce@lists.fedoraproject.org/msg03313.html)に、Fedora 45 Candidate RC-1.1 が10月17日（米国時間）に公開されたとあります。同じ日に、自動通知で 20261017.n.0 のナイトリーがテスト対象に指名されていますが、これは定例の通知で、RC ではありません。

### 並行して抱えている課題

NO-GO の原因だと断定する材料はありませんが、並行して扱われている変更と課題を挙げます。

- kmscon: fbcon を kmscon に置き換える[変更](https://fedoraproject.org/wiki/Changes/UseKmsconVTConsole)です。fbcon はカーネルに残り、kmscon が起動に失敗した場合は getty/fbcon にフォールバックします。仕組みは[10月8日の記事](https://blog.fuga.jp/posts/2026-10-08-linux-oss-trend/)にまとめました。kmscon の2件のバグ（[2524952](https://bugzilla.redhat.com/show_bug.cgi?id=2524952) は Beta ブロッカー、[2525932](https://bugzilla.redhat.com/show_bug.cgi?id=2525932) はフリーズ例外でブロッカーではない）は、どちらも9月10日に修正が stable に反映されています
- Python 3.15: [Change ページ](https://www.fedoraproject.org/wiki/Changes/Python3.15)に、再ビルドの対象は2025年10月時点で既知の約3900パッケージとあります。Fedora 45 での実数ではありません
- ツールチェーン: [GNU Toolchain の更新](https://fedoraproject.org/wiki/Changes/GNUToolchainF45)で gcc 16.2、binutils 2.47、glibc 2.44、gdb 17.2 になります。[LLVM 23](https://fedoraproject.org/wiki/Changes/LLVM-23) への更新は別の変更です。[RPM 6.1](https://fedoraproject.org/wiki/Changes/RPM-6.1) への更新もあります
- 署名検証: パッケージの署名検証を既定で強制するのは、RPM 6.1 の変更ではなく、別の変更の「[Enforcing signature checking by default](https://fedoraproject.org/wiki/Changes/Enforcing_signature_checking_by_default)」です
- ISO のサイズ: [20261017.n.0 のテスト結果](https://fedoraproject.org/wiki/Test_Results:Fedora_45_Branched_20261017.n.0_Summary)で、aarch64 の Everything boot は1,426,169,856バイトで、上限の1,300,000,000バイトを超えています。Server boot aarch64 など、ほかにも上限を超えたメディアがあります
- 遠隔インストール: Anaconda WebUI による[遠隔インストール](https://fedoraproject.org/wiki/Changes/Web_Based_Remote_Installation_Support_For_Atomic_Desktops)は、Atomic Desktops 向けの tech preview です

動画の訂正です。

- 動画では「RPM 6.1 による署名検証の強制」と紹介しましたが、署名検証の既定での強制は、RPM 6.1 の変更ではなく、別の変更「Enforcing signature checking by default」です。
- 動画では、新しいインストーラーについて「遠隔からのインストールなど、新しい機能も入っています」と紹介しましたが、遠隔インストールは Atomic Desktops 向けの tech preview です。

## 4. BeyondTrust Remote Support CVE-2026-102764 — 送り主を確かめない設計と、KEV の期限

BeyondTrust Remote Support（旧 Bomgar）の CVE-2026-102764 は、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-102764)の説明によれば、コンポーネントが受け取ったメッセージの送り主（オリジン）を十分に検証していなかった問題です。条件がそろえば、攻撃者が機器上でファイル操作を行えます。CWE は CWE-290 です。

深刻度の評価は2つあります。ベンダー側（CNA）が付けた CVSS v4.0 が9.3（Critical）、NVD 自身の評価が CVSS v3.1 の9.8（Critical）です。NVD API で確認すると、状態は Analyzed で、最終更新は10月17日（UTC）でした。

### 攻撃者と悪用の経緯

[Google Threat Intelligence Group（GTIG）の分析](https://cloud.google.com/blog/topics/threat-intelligence/armory-castle-exploits-beyondtrust)は、ARMORY CASTLE を、中国系と疑われるスパイ活動の攻撃者（以前の UNC5221）とし、この脆弱性を2026年8月下旬からゼロデイとして悪用したと書いています。BeyondTrust が脆弱性を開示したのは10月15日です。

[CISA の KEV カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-102764)には10月16日に追加され、連邦機関の対応期限は10月19日（月）です。KEV の説明は、リモートの攻撃者が機器上でファイル操作を行えるというものです。

### 侵入後の手口

GTIG が示した手口の要点です。

- 最初の POST リクエストの約11分後に、SAWFLY というウェブシェルがウェブルートに作られました
- /bin/sh を /usr/bin/dbus-authd にコピーし、所有者を root にして SUID を付けました
- sudoers のテンプレートに、サイトのサービスアカウントがパスワードなしで root になれる行を追記し、再起動や設定のリセットのあとも権限昇格が残るようにしました
- bt-secrets を使い、機器の認証情報の保管庫をダンプしようとしました。GTIG は、これを試みとして書いています。bt-secrets は、パスワード、API キー、エンドポイントの認証情報を管理するための機器標準のツールです
- BARECLAW という SOCKS5 プロキシのトンネラーを置き、haproxy.conf を書き換えてインターネットから直接使えるようにしました
- 削除コマンドには、ログファイルが13個並びます。この数は GTIG が明記したものではなく、示されたコマンドから数えた値です。一方で Mandiant は、LUKS で暗号化されたパーティションにあるログから、悪用の証拠を確認しています

### 影響範囲と対応

GTIG によれば、影響を受けるのは 26.2.3 までのサポート対象の Remote Support で、SaaS は BeyondTrust が10月9日にすべてのテナントへパッチを適用しています。自社で運用している場合は、パッチを当てる必要があります。

GTIG は、認証情報の作り直しは依存関係の順に行うこと、そして、機器をパッチするか再構築してからにすることを求めています。先に作り直すと、機器をまだ握っている攻撃者に新しい認証情報が渡るためです。機器上のログは消せるので、外部に転送したログも確認するよう勧めています。

なお、[8月20日の記事](https://blog.fuga.jp/posts/2026-08-20-linux-oss-trend/)で扱った BeyondTrust の CVE-2026-1731 は、今回とは別の脆弱性です。

動画の訂正です。

- 動画では、NVD での正式な点数は「まだ審査中」と紹介しましたが、NVD は10月17日（UTC）に更新済みで、状態は Analyzed、NVD の評価は CVSS v3.1 の9.8です。9.3 は CNA の CVSS v4.0 の値です。

## 5. Palo Alto PAN-OS CVE-2026-0322 — 管理画面のコードインジェクション

PAN-OS の管理画面（Management Interface）に、認証済みの攻撃者がネットワーク経由で root 権限の任意コードを実行できる、CWE-94 のコードインジェクションが見つかりました。[Palo Alto Networks のアドバイザリ](https://security.paloaltonetworks.com/CVE-2026-0322)は、特別な設定がなくても影響を受けるとしています。

深刻度は、Palo Alto の CVSS v4.0 で8.6（High）、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-0322)の CVSS v3.1 では7.2です。点数は High でも、アドバイザリの Urgency は HIGHEST、Exploit Maturity は ATTACKED で、できるだけ早く対処することを勧めています。悪用については "Very limited exploitation has been observed" と書かれています。発見は Palo Alto 社内からの報告です。

### 日付の並び

アドバイザリの初回公開は10月14日（水）で、CISA の KEV にも同じ10月14日に追加されました。[KEV の対応期限](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-0322)は10月17日（土）です。KEV の要求内容は、ベンダーの指示に従った緩和策の適用と、フォレンジック・トリアージの要件への準拠です。KEV に、この期限にした理由は書かれていません。

### 影響範囲と対処

影響を受けるのは、PA-Series と VM-Series のファイアウォール、Panorama の PAN-OS です。Cloud NGFW と Prisma Access は影響を受けません。

修正版は系統ごとに異なります。各系統の修正版の例は、12.2 が 12.2.4、12.1 が 12.1.10-h2、11.2 が 11.2.16、11.1 が 11.1.16-h3、10.2 が 10.2.18-h12 です。マイナー版ごとの修正版は、アドバイザリの表で確かめてください。

回避策は、アドバイザリに "No known workarounds exist for this issue." とあります。管理画面へのアクセスを信頼できる内部 IP アドレスだけに限る、または、管理画面に入れる唯一のシステムとして専用端末（ジャンプボックス）を置くことは、攻撃のリスクを下げるための対策です。リスクが最も高いのは、管理画面をインターネットの外部 IP アドレスに開いている場合だと書かれています。

Threat Prevention のサブスクリプションがあれば、Threat ID 510046 と 510047 で限定的な防御（limited coverage）が得られます。ただし、この Threat ID には SSL 復号が必要で、アドバイザリは、既知の攻撃パターンは検知できても、亜種は検知できない可能性があると注意しています。

悪用に関わったとされる IP アドレスは、アドバイザリの FAQ に3件載っています。ここでは転記しません。

PAN-OS の管理画面は、2024年にも[CVE-2024-0012](https://nvd.nist.gov/vuln/detail/CVE-2024-0012)の認証バイパスが問題になりました。こちらは認証なしで管理者権限を得られるもので、今回の認証済みの攻撃とは性質が異なります。また、Qilin が悪用した別の PAN-OS の認証バイパスは、[7月22日の記事](https://blog.fuga.jp/posts/2026-07-22-linux-oss-trend/)で扱いました。

動画の訂正です。

- 動画では「管理の操作は専用の端末からだけ許可して、その端末を多要素認証で守る方法も挙げられています」と紹介しましたが、アドバイザリが挙げているのは、管理画面にアクセスできるシステムを専用端末（ジャンプボックス）だけに限ることまでで、多要素認証の記載はありません。

## まとめ

SSD は Immediate Readiness を、BeyondTrust は送り主を、PAN-OS の管理画面はログイン済みの利用者を、それぞれ申告のまま通していました。Fedora は確かめる候補が無いので出しませんでした。この共通点は書き手の考察です。

確かめることを挙げます。

- VFIO で Samsung 990 PRO や 990 EVO Plus を使っているなら、修正の入ったカーネルで構成を試す
- GNOME 51 を使っているなら 51.1 へ更新し、Debian の stable を使っているなら、Security Tracker で GNOME Web の状況を確かめる
- Fedora 45 を待っているなら、10月22日の Go/No-Go 会議の結果を確認する。10月27日は目標で、確定ではない
- BeyondTrust Remote Support を自社運用しているなら、26.2.3 以前かを確かめてパッチを当て、そのあとで認証情報を依存の順に作り直す。外部に転送したログも確認する
- PAN-OS を使っているなら、版を確認して修正版へ更新し、管理画面がどこから見えているかを点検する

## 参考リンク

- [git.kernel.org: Linux のタグ一覧](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/refs/tags)
- [Linux コミット: Samsung 990 PRO / 990 EVO Plus の Immediate Readiness](https://github.com/torvalds/linux/commit/0f8b5d90d179b9639be1dbeff59d6d971e6b0527)
- [Linux コミット: printk の kthread 起動を遅らせる](https://github.com/torvalds/linux/commit/5f339c46f153184570f16c8e789c9709b14cbe8b)
- [GNOME 51.1 のリリース告知](https://discourse.gnome.org/t/gnome-51-1-is-released/39501)
- [Epiphany の issue 2952（CVE-2026-94291）](https://gitlab.gnome.org/GNOME/epiphany/-/work_items/2952)
- [Fedora 45 Final NO-GO の告知](https://www.mail-archive.com/devel@lists.fedoraproject.org/msg215769.html)
- [Fedora 45 のスケジュール表](https://fedorapeople.org/groups/schedule/f-45/f-45-key-tasks.html)
- [GTIG: ARMORY CASTLE による BeyondTrust の悪用](https://cloud.google.com/blog/topics/threat-intelligence/armory-castle-exploits-beyondtrust)
- [NVD: CVE-2026-102764（BeyondTrust）](https://nvd.nist.gov/vuln/detail/CVE-2026-102764)
- [Palo Alto Networks: CVE-2026-0322 のアドバイザリ](https://security.paloaltonetworks.com/CVE-2026-0322)
- [NVD: CVE-2026-0322（PAN-OS）](https://nvd.nist.gov/vuln/detail/CVE-2026-0322)

（2026/10/19 Linux・OSSトレンド）
