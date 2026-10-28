---
title: "Node2Shell が KEV 入り（連邦機関の期限は11月10日）、Steam Frame のデバイスツリーが Linux 7.4 のマージウィンドウで mainline 入り、Fedora 45 は二度目の NO-GO、KDE Plasma 6.8.2、Tailscale SSH の Tailworm は 1.104.4 で修正（2026/10/29 Linux・OSSトレンド）"
date: 2026-10-29T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "CISA KEV", "Node.js", "Linux カーネル", "Linux 7.4", "Fedora", "KDE", "Tailscale"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

小さな部品の振る舞いが、遠くの誰かの予定と安全を動かす。今回の5本は、そう読めます。Node.js に同梱された Brotli の穴は、修正版の公開から6日後に CISA の KEV へ載りました。Steam Frame のデバイスツリーは、7.4 のマージウィンドウで mainline に入りました。Fedora 45 は、証明書パッケージに残った1本のルート証明書などのために、リリース候補を作り直しています。KDE Plasma 6.8.2 は、描画の順番や GPU の組み合わせといった細部を直す版です。Tailscale SSH は、ソケット転送のパスの扱いが論点でした。

5本に共通点を見るのは、あくまで書き手の考察です。動画で一次情報と食い違った発言は、各節末の「動画の訂正」にまとめました。

この記事の確認時点は、2026年10月29日の朝（日本時間）です。NVD の状態、ブラウザや Fedora の予定、各社の修正状況など、あとから変わりうる情報には、その旨を添えました。

{{< youtube "yr4BaLATkBQ" >}}

## 1. Node2Shell — CISA の KEV に追加、連邦機関の期限は11月10日

Node2Shell（CVE-2026-111497）は、[10月26日の記事](https://blog.fuga.jp/posts/2026-10-26-linux-oss-trend/)の第5節で第一報を書きました。原因、修正版、経路、サポート終了の系列の扱いは、そちらを見てください。ここでは、その後に変わった点に絞ります。修正版は、[Node.js のセキュリティリリース](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)（10月21日）の 22.23.4、24.22.1、26.12.1 です。

### 何が変わったか

- KEV: [CISA の KEV のデータ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)では、`dateAdded` が 2026-10-27（日付のみで時刻はなし）、`dueDate` が 2026-11-10 です。10月26日の記事で確認した時点の KEV（catalogVersion 2026.10.23）には載っていませんでした。CISA は、[アラート](https://www.cisa.gov/news-events/alerts/2026/10/27/cisa-adds-two-known-exploited-vulnerabilities-catalog)で "based on evidence of active exploitation"（悪用の証拠にもとづいて）追加したと書いています。KEV の名前は "Google Brotli Unchecked Return Value Vulnerability" で、Node2Shell ではありません。ランサムウェア攻撃での利用を示す欄（knownRansomwareCampaignUse）は "Unknown" です
- 期限の対象: 11月10日は、連邦民間行政機関（FCEB）が対応する期限です。CISA のアラートは、BOD 26-04 が適用されるのは FCEB の機関だけだとしつつ、すべての組織に KEV の脆弱性の修正を優先するよう勧めています（"CISA encourages all organizations to adopt risk-based vulnerability management and prioritize remediation of KEV Catalog vulnerabilities"）
- 観測: ELLIO は、[自社ブログ](https://ellio.tech/en/blog/node2shell-cve-2026-111497-rce-on-stock-nodejs-builds/)の10月26日の追記で、"ELLIO sensors have recorded CVE-2026-111497 exploit traffic in the wild" と書いています。KEV 追加の前日です。Previdian の[ページ](https://previdian.com/CVE-2026-111497)は、センサーが攻撃の試みを1件、攻撃元の IP を1つ、国は US と記録し、初めて観測したのは2026年10月27日（"First observed Oct 27, 2026"）だと書きます。同じページは、これが "does not mean the attempt succeeded"（成功を意味しない）とも書いています
- NVD の状態: 10月26日の記事の時点では "Awaiting Analysis" でしたが、2026年10月29日の確認時点では "Analyzed" です。NVD 自身（Primary）の CVSS v3.1 は 9.8（Critical）で、Google（CNA、Secondary）の CVSS v4.0 は 9.2（Critical）です。NVD の記録にある CISA の SSVC 評価は、悪用が "active" になっていました。10月26日の記事では "none" と書いた項目です

### 採点の差

Red Hat は、[自社の CVE ページ](https://access.redhat.com/security/cve/cve-2026-111497)で、CVSS v3.1 の 8.1 と評価し、格付けは Important（Critical ではない）としています。NVD の CVSS v3.1 は 9.8 で、同じ版でも値が違います。Red Hat は、自社の採点は自社製品への影響を表したものだと説明しています。

理由として Red Hat が挙げるのは3つです。CNA が書いた攻撃の前提条件（CVSS v4.0 の AT:P）、細工した不正な入力が必要なこと、RHEL の防御機構（ASLR・NX・FORTIFY・SELinux）です。攻撃の複雑さを High と見たわけです。

### 誰が報告し、いつ入った穴か

Node.js のブログによれば、報告者は OpenAI Codex Security の Khai Tran 氏と Sylvie Mayer 氏で、修正は mcollina 氏と aduh95 氏です。Node2Shell の名前は、[Imperva](https://www.imperva.com/blog/node2shell-from-brotli-data-to-remote-code-execution/) のレッドチームが付けました。Imperva は、公式の Node.js 24.22.0 の Linux arm64 のイメージで、自分たちの環境ではコード実行を実証し、毎回は成功しなかったと書いています。

[Miggo](https://www.miggo.io/post/node2shell-cve-2026-111497-nodejs-vulnerability) の調査では、バグが入ったのは2018年2月26日で、上流の修正が公開されたのは2026年2月27日です。Miggo は、修正版の出荷は上流の修正の公開からさらに8か月近くあとだったとも書いています。混入から2026年10月の修正版まで、8年以上残っていたことになります。

### VMware SDDC Manager

Broadcom の[VMSA-2026-0008](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/39445)は、Issue date が 2026-10-27 で、KEV 追加と同じ日です。対象製品は VMware Cloud Foundation の SDDC Manager で、2026年10月29日の確認時点でも、Response Matrix の修正版の欄は全行 "Patch pending" でした。Broadcom の格付けで Critical になるのは SDDC Manager 9.1.1 系だけで、9.0.x、9.1.0、5.2.x は Critical ではありません。VMSA に悪用の記載はなく、KEV は Brotli 全般の登録です。SDDC Manager が実際に攻撃された、という意味ではありません。

### 確かめること

- `node -p process.version` で、動かしている Node.js のバージョンを確かめ、上の修正版に上げます。コンテナは、Imperva の助言に沿って、イメージの中の Node.js のバージョンを確かめ、ベースイメージから作り直します
- すぐ上げられない場合、Red Hat は、[RHSB-2026-015](https://access.redhat.com/security/vulnerabilities/RHSB-2026-015)で、信頼できないクライアントからのリクエストとレスポンスの Content-Encoding: br を、リバースプロキシやロードバランサーで除くか拒否するよう助言しています。Miggo は、入口で圧縮リクエストを止めても、fetch で受け取るレスポンス経由の経路は防げないと書いています。部分的な緩和です
- VMware の環境は、Broadcom の VMSA と KB の更新を確認します

動画の訂正です。

- 動画では、「8バイトしかない内部のリングバッファを越えて」書き込むと紹介しました。Node.js のブログは "an eight-byte internal buffer"（8バイトの内部バッファ）と書いています。ELLIO の解説でも、8バイトなのは内部バッファで、リングバッファは別のものです（[Node.js のブログ](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)、[ELLIO](https://ellio.tech/en/blog/node2shell-cve-2026-111497-rce-on-stock-nodejs-builds/)）。軽微な訂正です。

## 2. Steam Frame — デバイスツリーが 7.4 のマージウィンドウで mainline へ

先に、効果の範囲を書きます。書き手の見方としては、普通に買って遊ぶ人への変化は小さいです。[Valve の投稿](https://store.steampowered.com/news/group/45479024/view/675134162359812783)（10月9日）は、予約の人は12月までか2027年に注文のメールが届くと書いています。Phoronix は、SteamOS 向けの downstream のカーネルのほうが、今も完成度が高いと書いています（二次の情報です）。

### mainline に入った経緯

Linus Torvalds 氏は、`soc-dt-7.4` のプルリクエストを、UTC の10月22日 17:48（日本時間 10月23日 2:48）にマージしました。[マージのコミット](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=7b9a0e857b427cdda5a08b662dbea7321e6bb470)の本文に "Valve Steam Frame VR headset using Snapdragon 8 Gen 3" とあります。2026年10月29日の確認時点で、mainline の最新のタグは v7.3（UTC 10月18日 23:14）で、v7.4-rc1 はまだありません。つまり、7.4 のマージウィンドウの途中で、7.4 は未リリースです。

デバイスツリーの[コミット](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=f905cb6e600a299cdefc8763878f9739c78b77b3)の Author は、linaro.org のアドレスを使う Neil Armstrong 氏で、Reviewed-by は Konrad Dybcio 氏です。Qualcomm のツリーには、Bjorn Andersson 氏が9月25日にコミットしました。変更は3ファイルで、追加1292行、削除3行です。

### 何に対応したか

コミット本文は、初期対応の範囲を次のように挙げています。システムの予約メモリ、レギュレーター、gpio keys、PMIC の機能、PMIC の ADC チャンネル、UFS ストレージ、USB ガジェット、WCN7850 の Wi-Fi 7 と Bluetooth、I2C と基本的な周辺機器、SD カードのスロットです。さらに、ブートローダーが Linux を EL2 で起動するため、EL1 と DSP に関係するノードを外し、予約メモリの配置を定義した、とあります。

ハードの仕様は、[Valve のストアページ](https://store.steampowered.com/hardware/steamframe)に、4 nm の Snapdragon 8 Gen 3、16GB の LPDDR5X、256GB か 1TB の UFS、microSD のスロット、Wi-Fi 7 と Bluetooth 5.4 とあります。米国での価格は、Valve の[9月14日の投稿](https://store.steampowered.com/news/group/45479024/view/692020124159311887)で、256GB が1,059ドル、1TB が1,299ドルです。

GPU、画面、音声、視線の扱いが「これから」かどうかを述べた一次の文書は、確認できませんでした。確認できたのは、`.dts` で `&gpu` が有効、`&dispcc`（ディスプレイクロックの制御）が無効になっている点までです。

### 発売からの日数と、周辺の動き

Valve は、9月14日に "Steam Frame launches today!" と書き、予約の受付を始めました。予約順の抽選は9月17日、購入案内のメールは9月18日から順次です。9月14日から mainline のマージ（UTC 10月22日）まで、38日です。

Collabora は、[ブログ](https://www.collabora.com/news-and-blog/news-and-events/building-an-arch-linux-aarch64-port-for-holo-core.html)（7月17日）で、Valve と共同で作っている Arch Linux の aarch64 版 Holo Core のプレビューを公開しました。ブログは、Arch Linux のリポジトリの全パッケージを再ビルドしたわけではないとも書いています。

ドングルの ID は、rtw89 に `28de:2432` を足した[コミット](https://github.com/torvalds/linux/commit/5f65ebf9aaf00c7443252136066138435ec03958)で追加され、v7.0-rc1 に入りました。コミットの本文は、この ID を Steam Frame のドングルとは書いていません。後続のコミットが、同じ ID を "valve board" と呼んでいます。この ID 専用の変更は、7.2、7.3、7.4 のマージウィンドウに分かれて入りました。

動画の訂正はありません。

## 3. Fedora 45 — 二度目の NO-GO、残った1本のルート証明書

1回目の NO-GO は、[10月19日の記事](https://blog.fuga.jp/posts/2026-10-19-linux-oss-trend/)の第3節で扱いました。eMudhra の件の経緯は、[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)の第4節にあります。ここでは、eMudhra の件が Fedora のリリースにどう効いたかを書きます。

### 10月22日の判定会議

10月22日の判定会議は、UTC の17:00:54 に始まり、19:18:43 に NO-GO で合意しました（日本時間では10月23日の2:00 に始まり、4:18 に合意）。[devel-announce の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03863.html)は、残ったブロッカーのため RC-1.2 を NO-GO と宣言し、次の目標を 2026-11-03 としています。

[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-22/f45-final-go-no-go-meeting.2026-10-22-17.00.html)が NO-GO の個別の理由として挙げたのは、2つです。1つは ca-certificates で、議事録は、侵害された証明書が1本、RC-1.2 に入った ca-certificates-2026.2.92_v9.0.319-1.fc45 から外れていなかったと書き、ブロッカーは "not sufficiently addressed"（十分に対処されていない）としました。もう1つは Stratis で、バグ 2543511（"Stratis encrypted pool fails to boot — /dev/stratis/fedorapool/root does not exist"）が AcceptedBlocker になりました。

### 残ったルート証明書

Red Hat Bugzilla の [2556376](https://bugzilla.redhat.com/show_bug.cgi?id=2556376) によれば、残っていたのは、コード署名用のルート証明書 emSign Root CS CA - G3 です。侵害された2件のコード署名用の中間証明書を直接発行した証明書です。Fedora が外したルートは、全体で3本（AAA Certificate Services、emSign ECC Root CA - G3、emSign Root CS CA - G3）で、最初の更新（-1）で前の2本、次の更新（-2）で最後の1本を外しました。

-2（2026.2.92_v9.0.319-2）は、[F45](https://bodhi.fedoraproject.org/updates/FEDORA-2026-e57d2527d5)、[F44](https://bodhi.fedoraproject.org/updates/FEDORA-2026-0609e13c0d)、[F43](https://bodhi.fedoraproject.org/updates/FEDORA-2026-3ee4dad1c6) とも stable に出ています（Bodhi の記録で、F43 が UTC の10月22日 16:40、F44 が10月23日 1:21、F45 が10月23日 4:38）。-1 には最後の1本が残るので、対策済みと言えるのは -2 以降です。新しい候補は、[RC-1.3](https://www.mail-archive.com/test-announce@lists.fedoraproject.org/msg03324.html) と、その代替の RC-1.4 が、10月28日に出ました。

LUKS の上の LVM がアップグレード後に自動で有効にならないバグ（[2555274](https://bugzilla.redhat.com/show_bug.cgi?id=2555274)）も、ブロッカーに認定されました。ただ、会議の時点で修正の確認（VERIFIED）は済んでおり、10月23日に lvm2-2.03.43-2.fc45 が stable に入って閉じています。

### ブラウザの対応と、次の会議

Mozilla は、[Bugzilla #2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449) の Comment 18 で、UTC の10月20日 13:06 に、emSign ECC Root CA - G3 への信頼の緊急削除を決めたと書きました。10月22日の記事で書いた中間 CA の失効に続く、2段目の対応です。Chrome は、Google の[ブログ](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)で、同じルートの削除を、米国太平洋時間の10月27日の朝に出す見込みだと書きました。2026年10月29日の確認時点で、実施を確かめられる一次は見つかりませんでした。

次の判定会議は、10月29日（UTC）に予定されています。10月22日の告知と [fedocal](https://calendar.fedoraproject.org/meeting/11450/) は 17:00 UTC（日本時間 10月30日 2:00）、10月28日の[リマインダー](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03865.html)は 18:00 UTC（同 3:00）と書き、時刻が食い違います。確認時点では未開催で、結果は書けません。

### 確かめること

Fedora 43 と 44 の利用者は、ca-certificates を更新し、`rpm -q ca-certificates` で -2 以降が入っていることを確かめます。Fedora 以外では、証明書ストアの更新を確認します。Cloudflare の[ブログ](https://blog.cloudflare.com/emudhra-certificate-compromise/)は、Mozilla の Dennis Jackson 氏が、修正済みの主要なパッケージの一覧を集めていると書き、早めの更新を勧めています。Scott Helme 氏のブログは、ブラウザ以外のクライアント（curl、Python、Node、Go、Java、git など）が、ディスク上の CA の一覧を信頼し、既定では失効を確認しない、と書いています。

動画の訂正です。

- 動画では、Cloudflare が、eMudhra の中間 CA 証明書8本について、秘密鍵が割り出せる状態だと10月19日に「見つけた」と紹介しました。最初に報告したのは外部の研究者で、UTC の10月17日 18:05 に、Apple、Chrome、Microsoft、Mozilla、eMudhra へ報告しています（Mozilla の Bugzilla の記録では、Chrome から転送された報告を受けたのが 20:06 UTC で、10月22日の記事はこの時刻を書きました）。Cloudflare は、自社のブログで、10月19日の約17:00 UTC（日本時間 10月20日 2:00）に侵害を知った（became aware）と書いています（[Cloudflare のブログ](https://blog.cloudflare.com/emudhra-certificate-compromise/)、[Bugzilla #2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)）。
- 動画では、Cloudflare がこの問題を CVE-2026-111943 として追跡していると紹介し、画面にも出しました。CVE-2026-111943 は、Go プロジェクトが採番した、Go の標準ライブラリ crypto/x509 の CVE で、信頼できなくなった中間証明書の拒否リストを加えた対応です。Cloudflare のブログに、この CVE の番号は出てきません（[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)、[Go の issue](https://github.com/golang/go/issues/82345)）。
- 動画では、ca-certificates に影響を受けるルート証明書が「2本」含まれ、リリース候補の「RC-2」でも残っていたと紹介し、画面にも「ルート証明書2本が残存」と出しました。リリース候補（公式の名前は RC-1.2）の ca-certificates に残っていたのは、1本（emSign Root CS CA - G3）です（[議事録](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-22/f45-final-go-no-go-meeting.2026-10-22-17.00.html)、[Bugzilla 2556376](https://bugzilla.redhat.com/show_bug.cgi?id=2556376)）。

## 4. KDE Plasma 6.8.2 — マルチ GPU、commit timing、X11 セッション

Plasma 6.8 は、[10月14日の記事](https://blog.fuga.jp/posts/2026-10-14-linux-oss-trend/)の第3節で扱いました。[6.8.0 の告知](https://kde.org/announcements/plasma/6/6.8.0/)の日付は10月14日（水）で、記事で「リリース予定」と書いた日のとおりに出ています。6.8.1 は10月20日、[6.8.2](https://kde.org/announcements/plasma/6/6.8.2/) は10月27日（火）です。

[changelog](https://kde.org/announcements/changelogs/plasma/6/6.8.1-6.8.2/) には、136件のコミットが載っています（Commit のリンクを数えた値です）。changelog にセキュリティや CVE を示す項目はありませんでした。ただし、KDE の告知が「セキュリティ修正なし」と明言しているわけではなく、確認の範囲の話です。

### KWin のマルチ GPU

GPU の間で画面のデータをコピーする仕組み（multigpuswapchain）は、6.8 で入ったのではありません。6.7.0 のソースに、Vulkan の対応を含めて、すでにありました。6.8.2 は、その不具合を直した版です。

- EGL でのコピーの同期: コミットのメッセージによれば、同期ファイルを EGL のコンテキストに取り込んでいませんでした（[#527591](https://bugs.kde.org/527591)）
- バッファの種類のチェック: NVIDIA の回避策は、システムメモリ上の dmabuf へコピーするときだけ使うべきでした。Intel や AMD から NVIDIA への Vulkan のコピーで、EGL が使われていた不具合も、これで直ります（[#527591](https://bugs.kde.org/527591)、[#527604](https://bugs.kde.org/527604)）

報告されていたのは、AMD の内蔵 GPU が描画し、NVIDIA の GPU が外部ディスプレイにつながる構成（#527591）と、Intel と NVIDIA のハイブリッドで2画面をつなぐ構成（#527604）です。eGPU の報告は、確認できませんでした。

### 黒い画面と、カラーパイプライン

画面が黒くなる問題と、カラーパイプラインを使わない構成での無効化は、別の修正です。

- 黒い画面: [#527544](https://bugs.kde.org/527544) は、NVIDIA を描画 GPU にして、画面が Intel につながる構成で、壁紙が黒くなり、ウィンドウが再描画されなくなる報告です。コミットのメッセージによれば、dmabuf のフィードバックを内蔵 GPU に設定すると描画が止まる NVIDIA ドライバーの不具合があり、先に行うチェックでそれを避けます
- カラーパイプライン: [#527628](https://bugs.kde.org/527628) は、6.8.1 にしてゲームの性能が落ちた報告です。コミットは、カラーパイプラインに対応していない構成で post-blend offloading を無効にします。メッセージは、役に立たず、性能の問題を起こしうると書いています。別のコミットは、レガシーなモードでは許可しない修正で、[#527421](https://bugs.kde.org/527421)（マウスを動かすとちらつく）を直します

### ポインターの制約と commit timing

Wayland のポインター制約（pointerconstraints_v1）では、状態が古い値で上書きされる問題が直りました。報告（[#527675](https://bugs.kde.org/527675)）は、Blender のスライダー操作でカーソルが飛ぶというものです。

commit timing は、[コミット](https://invent.kde.org/plasma/kwin/-/commit/c74b9d2a83f43ad39914bc88a5d85542c71364b8)（10月24日）で、既定で無効になりました。環境変数 `KWIN_WAYLAND_SUPPORT_COMMIT_TIMING_V1` で有効に戻せる作りです。メッセージによれば、frame pacing を助けるはずが、今は問題ばかりを起こしていて、VRR の問題（KWin 側のバグの疑い）と、NVIDIA の Vulkan ドライバーで mpv が固まる問題がありました。関連のバグ（#525514 と #527500）は、「関連」の扱いで、修正済みとはされていません。

### そのほかの修正

タイル表示の壁紙で GIF が動かなくなっていた問題（[#516541](https://bugs.kde.org/516541)）、単色の壁紙のときアクセントカラーが決まらない問題（[#513851](https://bugs.kde.org/513851)）、KRDP でポータルのセッションが始まらず映像が出ない問題（[#527555](https://bugs.kde.org/527555)）、小数の拡大率で Oxygen のウィンドウ装飾のボタンが不ぞろいになる問題（[#527549](https://bugs.kde.org/527549)）が直りました。デスクトップのアイコンが消える問題の修正もありますが、changelog の記述は短く、マルチモニターに限った話とは確認できませんでした。

### 届く時期と、X11

2026年10月29日の確認時点で、Arch の extra は 6.8.2-1、openSUSE Tumbleweed の oss は 6.8.1 です。Fedora は、F43 と F44 の stable が 6.7.5 で、F45 の testing が 6.8.1、rawhide（F46）の stable が 6.8.2 でした。Fedora の安定版に 6.8 が届く時期や、その理由は、一次で確認できていません。

Plasma 6.8 には X11 セッションがありません。6.8.0 の告知は、Plasma で X11 セッションを開始するサポートを終了すると書き、KDE の David Edmundson 氏の[記事](https://planet.kde.org/david-edmundson-2026-06-02-ex-11-prepping-for-plasmas-last-x11-supported-release/)は、6.7 が X11 セッションを含む最後のリリースだと書いています。6.8.2 のソースの login-sessions にも、X11 のセッション定義がありません。10月14日の記事と同じ結論です。

動画の訂正です。

- 動画では、「X11のセッションを使っている人は、Waylandの修正は対象外ですが、壁紙などほかの修正は受けられます」と紹介し、画面にも「X11ではWayland修正は対象外」と出しました。Plasma 6.8 には X11 セッションがなく、6.8.2 を入れた人が使えるのは Wayland セッションだけです。X11 セッションを使い続けている人は 6.7 以前の Plasma を使っており、6.8.2 の更新の対象ではありません（[6.8.0 の告知](https://kde.org/announcements/plasma/6/6.8.0/)、[Edmundson 氏の記事](https://planet.kde.org/david-edmundson-2026-06-02-ex-11-prepping-for-plasmas-last-x11-supported-release/)）。
- 動画では、「6.8で、KWinが主導してGPUの間で画面のデータをコピーする仕組みが入った」と紹介しました。この仕組みは、Plasma 6.7.0 のソースにすでにあり、6.8.2 は 6.8 系で出たその不具合を直した版です（[kwin のソース](https://invent.kde.org/plasma/kwin/-/blob/v6.7.0/src/multigpuswapchain.cpp)）。
- 動画では、commit timing を既定で無効にした理由を、「特定の構成で、ティアリングや描画の順番の乱れを起こしていた」と紹介しました。コミットのメッセージが書く理由は、frame pacing の助けになるはずが問題ばかり起こしていること、VRR の問題（KWin 側のバグの疑い）、NVIDIA の Vulkan ドライバーで mpv が固まることです。ティアリングや描画順の乱れとは書かれていません（[コミット](https://invent.kde.org/plasma/kwin/-/commit/c74b9d2a83f43ad39914bc88a5d85542c71364b8)）。

## 5. Tailworm — Tailscale SSH の速報4本と、1.104.4

先に、影響を受ける条件を書きます。TS-2026-014 の[速報](https://tailscale.com/security-bulletins)は、Tailscale SSH を有効にしていて、ポリシーでローカルまたはリモートの転送も許可している利用者が対象だと書いています。Tailscale SSH は、[KB](https://tailscale.com/kb/1193/tailscale-ssh)によれば、接続される側のホストで有効にします。悪用には、攻撃者が tailnet の許可済みのデバイスをすでに持っている必要がある、と Tailscale のブログは書いています。

### 経緯

研究者は、Cyberdione Labs の Erica Windisch 氏で、[tailworm.com](https://tailworm.com/) に公開しました。Tailscale の[ブログ](https://tailscale.com/blog/tailscale-ssh-findings-fixes)は、10月24日（土）の午前に報告を受け、研究者は2時間後に公開した、と書いています。午前がどの時間帯の午前かは、書かれていません。同じブログは、10月23日（金）に、Tailscale SSH への懸念がソーシャルメディアで出回り始めた、とも書きます。

速報の TS-2026-014 から 017 は、10月26日の公開です。修正版の 1.104.4 は、changelog では10月28日で、速報のほうが先です。1.104.3 は社内専用でした。

### 件数

研究者の報告は、tailworm.com の番号付きで11件です。Tailscale のブログは、総数を書いていません。確認した findings のうち、個別の開示に値するものを、4本の速報として公表した、と書いています。

速報とは別に、ブログは、Serve と Funnel の5件のうち3件がバグで、1.104.4 で直ったと書きます。残る2件は設計どおりの動作で、Funnel の属性チェックの回避にはローカル管理者の権限が要ること、`TS_SERVE_ALLOW_ALL_INTERFACES` は tailnet の外へ公開するための任意の設定であることが理由です。未リリースの Conn25 にも脆弱性があった、とも書いています。11件と4本の速報の対応表は、研究者にも Tailscale にもありません。

### 4本の速報

- TS-2026-014: SSH の Unix ソケット転送が、root だけが届くソケットへの接続を許していました。速報によれば、tailscaled は転送先のパスを文字列として検査しながら、操作は root で行っていました。パスの許可リストは、初回の検査のあとにカーネルがパスを解決し直すため、レースで回避できました。changelog は、例として Docker のソケットと tailscaled のローカル API を挙げています。ソケットを差し替える経路は、tailworm.com の主張です
- TS-2026-015: SSH のセッション処理でのメモリ枯渇が、サービス拒否につながります
- TS-2026-016: ローカルで Serve の設定を書ける操作者が、特権ソケットへ届きます
- TS-2026-017: HTTP/2 の共有の状態のため、Tailscale-App-Capabilities のヘッダーが別のリクエストに付きます。影響を受けるのは、このヘッダーを見てピアを認可するアプリです

2026年10月29日の確認時点で、速報に CVE の欄はなく、NVD のキーワード検索（Tailscale、公開日が10月20日から29日）も0件でした。CVE.org は引いていないので、割り当てがないと断定はしません。Tailscale のブログと速報に、悪用の報告は書かれていません。

### 「ワーム」をめぐる言い分

研究者は、tailworm.com の Wormability の節で、ラボでの自動的な広がりを報告しています。Tailscale のブログは、"They don't describe self-replicating malware spreading automatically between machines" と書き、"lateral movement limited to connections allowed by a tailnet policy file"（tailnet のポリシーが許した接続の範囲での横移動）と表現するほうが適切だとしています。

### 対策

- Tailscale は、changelog で、1.104.4 以上に上げるよう案内しています。014 から 017 のすべての対応を含み、Unix ソケットの転送を root ではなく、認証されたユーザーの権限で行います。各ノードのバージョンを確かめます
- 上げられない間は、速報 TS-2026-014 によれば、`TS_SSH_DISABLE_FORWARDING=1` で、Tailscale SSH 全体を止めずに転送だけを止められます。設定する場所は、速報の記述に従ってください。ブログは、機微なシステムには SSH の check mode（アクセスを許す前に追加の認証を求める）の検討も勧めています
- headscale は、2026年10月29日の確認時点で、最新の v0.29.6（10月24日）に Tailworm への対応は入っていません。関連の issue（[#3601](https://github.com/juanfont/headscale/issues/3601)、[#3602](https://github.com/juanfont/headscale/issues/3602)）は open で、保守者のコメントはありません。TS-2026-014 の修正は tailscaled のノード側にあり、クライアントの更新で直るという説明は、#3601 の投稿者のもので、headscale の公式の見解ではありません

2026年7月にも、TS-2026-009 の速報が出ています。ログイン名の先頭のダッシュの扱いで root のアクセスを許す問題で、修正は 1.98.9 の changelog（7月14日）に載っています。

動画の訂正です。

- 動画では、「11件の問題を報告して、Tailscaleはそのうち4件を脆弱性と認めました」と紹介し、画面にも「報告11件のうち脆弱性と認定4件」と出しました。11件は研究者（tailworm.com）の数え方で、Tailscale のブログは総数を書いていません。Tailscale が書いているのは、確認した findings のうち個別に開示するものを4本の速報にした、という点で、「4件を認めた」とは書いていません。「残り」の全体像も補います。速報とは別に、Tailscale のブログは、Serve と Funnel の5件のうち3件がバグで 1.104.4 で修正したこと、設計どおりなのは2件であること、未リリースの Conn25 にも脆弱性があったことを書いています。動画の「設計どおり」「まだリリースされていない次世代の機能に関するもの」は、残りの一部にあたり、Serve のバグ3件が抜けていました（[Tailscale のブログ](https://tailscale.com/blog/tailscale-ssh-findings-fixes)、[tailworm.com](https://tailworm.com/)）。

## まとめ

Node2Shell は、KEV に載り、連邦機関の期限は11月10日です。NVD の状態は Analyzed になり、採点者ごとに CVSS v3.1 の値が分かれています（NVD が 9.8、Red Hat が 8.1）。まず、動かしている Node.js のバージョンを確かめ、修正版へ上げます。Steam Frame のデバイスツリーは、7.4 のマージウィンドウで mainline に入りましたが、7.4-rc1 は確認時点で未リリースです。Fedora 45 は、残った emSign Root CS CA - G3 を外した ca-certificates の -2 が出て、RC-1.3 と RC-1.4 が出ています。10月29日（UTC）の判定会議の結果は、確認時点で出ていません。Plasma 6.8.2 は、6.7 から入っていたマルチ GPU の仕組みの不具合などを直した版で、6.8 に X11 セッションはありません。Tailscale は、1.104.4 以上へ上げます。

5本に共通する「小さな部品の振る舞いが、遠くの予定と安全を動かす」という見方は、書き手の考察です。展開の戻り値、デバイスツリーのノード、証明書パッケージの1本、描画のタイミング、ソケットのパスの検査は、どれも小さな部品ですが、動く範囲は広がりました。

まず確かめることを挙げます。

- Node.js を使っているなら、`node -p process.version` でバージョンを確かめ、22.23.4、24.22.1、26.12.1 以降へ上げる。コンテナはイメージの中を確かめて作り直す
- VMware Cloud Foundation の SDDC Manager を使っているなら、Broadcom の VMSA-2026-0008 と KB の更新を確かめる
- Fedora 43 と 44 を使っているなら、`rpm -q ca-certificates` で -2 以降が入っているかを確かめる。Fedora 以外でも、証明書ストアの更新を確認する
- KDE Plasma を使っているなら、使っているディストリビューションのパッケージの版を確かめる。X11 セッションを使い続けるなら、6.7 以前にとどまる
- Tailscale SSH を使っているなら、各ノードを 1.104.4 以上に上げる。headscale は、プロジェクト側の対応を確認する

## 参考リンク

- [CISA: KEV のデータ（JSON）](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)
- [Node.js: 10月のセキュリティリリース](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)
- [Red Hat: CVE-2026-111497](https://access.redhat.com/security/cve/cve-2026-111497)
- [Broadcom: VMSA-2026-0008](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/39445)
- [Steam Frame のデバイスツリーのコミット](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=f905cb6e600a299cdefc8763878f9739c78b77b3)
- [Valve: Steam Frame のストアページ](https://store.steampowered.com/hardware/steamframe)
- [Fedora 45 Final の NO-GO の告知](https://www.mail-archive.com/devel-announce@lists.fedoraproject.org/msg03863.html)
- [Fedora 45 の判定会議の議事録（10月22日）](https://meetbot.fedoraproject.org/meeting_matrix_fedoraproject-org/2026-10-22/f45-final-go-no-go-meeting.2026-10-22-17.00.html)
- [Cloudflare: eMudhra の証明書の侵害](https://blog.cloudflare.com/emudhra-certificate-compromise/)
- [KDE Plasma 6.8.2 の告知](https://kde.org/announcements/plasma/6/6.8.2/)
- [KDE Plasma 6.8.2 の changelog](https://kde.org/announcements/changelogs/plasma/6/6.8.1-6.8.2/)
- [Tailscale: Tailscale SSH の調査結果と修正（ブログ）](https://tailscale.com/blog/tailscale-ssh-findings-fixes)
- [Tailscale: セキュリティ速報](https://tailscale.com/security-bulletins)
- [tailworm.com（研究者の公開）](https://tailworm.com/)

（2026/10/29 Linux・OSSトレンド）
