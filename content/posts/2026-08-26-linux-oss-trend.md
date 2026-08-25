---
title: "見過ごされた一手が、いちばん遠くまで届く — CVSS満点の7か月と、フラグ1つが眠らせていた7倍のレイテンシ（2026/8/26 Linux・OSSトレンド）"
date: 2026-08-26T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Oracle WebLogic", "CISA KEV", "Linuxカーネル", "Wi-Fi", "ath11k", "ReactOS", "IMA", "TPM", "Firefox", "JPEG XL", "Rust"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

修正はもう出ている。フラグを1つ立てるだけでいい。ログに1行足せば証明できる。——どれも「それだけのこと」に見えます。だからこそ後回しにされ、気づかれないまま何年も残ってしまう。今日お届けする5本は、その「見過ごされた小さな一手」が、いちばん遠いところまで影響を届けていた話です。

7か月前にパッチが出ていた CVSS 10.0 の脆弱性に、連邦機関が3日でパッチを当てるよう命じられた件。カーネルに機能フラグを1つ宣言していなかっただけで、Wi-Fi のレイテンシが7倍悪化していた件。ユーザー空間から書き込まれた測定ポリシーが、測定されないまま素通りしていた Linux の IMA。そして、Mozilla が「Rust で書き直してくれたら採用する」と言い張った結果、Chrome と Firefox が同じ Rust のクレートを共有することになった話。

{{< youtube "Vmyakp6XQlE" >}}

## 1. パッチは7か月前に出ていた — CVSS 10.0 の Oracle WebLogic 脆弱性に、CISA が最短の3日期限

2026年8月24日、CISA（米サイバーセキュリティ・インフラセキュリティ庁）が KEV（Known Exploited Vulnerabilities、悪用が確認された脆弱性のカタログ）に CVE-2026-21962 を追加しました。連邦機関に課されたパッチ適用の期限は2026年8月27日。KEV 制度が認めるなかで最も短い3日間です。

対象は Oracle HTTP Server と WebLogic Server Proxy Plug-in。[NVD が確定させた CVSSv3.1 スコアは 10.0 CRITICAL](https://nvd.nist.gov/vuln/detail/CVE-2026-21962)、ベクトルは `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N` です。ネットワーク越しに、特別な条件も認証もユーザー操作もなしに到達できる。しかも `S:C`（Scope: Changed）が付いています。フロントに立つ Oracle HTTP Server を抜けると、その先のバックエンド WebLogic まで影響が波及するという意味です。NVD の記述では「重要データへの無許可の作成・削除・変更アクセス、または全データへの完全アクセス」が可能とされています。

影響を受けるサポート対象バージョンは 12.2.1.4.0、14.1.1.0.0、14.1.2.0.0 です。CWE 分類は CWE-284（不適切なアクセス制御）で、[CISA の KEV エントリ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog?field_cve=CVE-2026-21962)でもこの分類が付けられています。

### 修正済みの脆弱性が、なぜ8月に緊急扱いになるのか

ここが今回いちばん引っかかるところです。この脆弱性のパッチは、[2026年1月20日の Oracle Critical Patch Update](https://www.oracle.com/security-alerts/cpujan2026.html) ですでに提供されていました。つまり **直せる状態が7か月続いていた** のです。

にもかかわらず時系列はこうなります。1月20日にパッチ公開。その2日後の1月22日に PoC（概念実証コード）が GitHub へ公開され、[CloudSEK のハニーポット](https://www.cloudsek.com/blog/honey-for-hackers-a-study-of-attacks-targeting-the-recent-cve-2026-21962-and-other-critical-weblogic-vulnerabilities-on-a-high-interactive-oracle-honeypot)には同じ日のうちに最初の攻撃が記録されます。1月27日には複数国からのスキャンが始まり、その後 [Imperva は21カ国のサイトを狙った14万件超の攻撃試行を観測](https://www.imperva.com/blog/imperva-customers-protected-against-cve-2026-21962-in-oracle-http-and-weblogic/)したと報告しています。7月には SOCRadar が、中国に関連するとみられる脅威アクターによる政府インフラへの攻撃でこの脆弱性が使われたと報告したと[報じられています](https://www.securityweek.com/cisa-warns-of-exploited-oracle-weblogic-vulnerability/)。そして8月24日、KEV 追加と3日期限。

攻撃の手口自体は派手なものではありません。プロキシ層のアクセス制御不備（CWE-284）を突くもので、パス正規化の差異を利用した細工済みパスを投げることで、本来バックエンドの WebLogic だけが受けるべきリクエストを外から直接届かせます。使われたツールも `libredtail-http` や Nmap Scripting Engine といった既製品で、高ボリュームの自動スキャンが主体でした。[The Register は「CISA が最速3日のパッチ期限を CVSS 10.0 の欠陥に設定」と見出しを打ち](https://www.theregister.com/security/2026/08/25/cisa-slaps-its-tightest-three-day-patching-deadline-on-perfect-10-oracle-flaw/5292107)、1月の開示から8月の KEV 追加までに7か月の空白があったこと自体を問題視しています。

### 今日できること

パッチ適用が最優先ですが、Oracle のコミュニティフォーラムには、パッチ適用後に Apache の起動でつまずいた事例も投稿されています。

```
Cannot load wls-plugin-12214/lib/mod_wl_24.so into server:
undefined symbol: ons_ssl_context_destroy
```

更新されたプラグインライブラリと既存の SSL ライブラリのバイナリ互換性の問題で、「直しにいったら壊れた」状態になりうるということです。適用前に検証環境で試す価値はあります。

すぐにパッチを当てられない場合の暫定措置としては、OHS と WebLogic 管理コンソールへのインターネットからの直接アクセスをファイアウォールで遮断すること、そして WAF で `/_proxy/` や `/wl_proxy/` 宛のパストラバーサル的なリクエストを検知・ブロックすることが挙げられています。Imperva は自社の CWAF と WAF Gateway について、追加設定なしで保護済み（out-of-the-box）だと報告しています。

7か月あっても当たらないパッチがある。この事実のほうが、CVSS 10.0 という数字よりも重い教訓かもしれません。

## 2. フラグを1つ立てていなかっただけ — ath11k のレイテンシが155msから22msへ

Qualcomm の Wi-Fi 6（802.11ax）チップ向け Linux ドライバ `ath11k` に、AQL（Airtime Queue Limits）とエアタイム公平性を追加する9本のパッチシリーズが、2026年8月24日に linux-wireless メーリングリストへ投稿されました。投稿者は Julius Bairaktaris で、[v3 のカバーレター](https://marc.info/?l=linux-wireless&m=178758146703148&w=2)には IPQ8074 アクセスポイントでの実測値が添えられています。

| 条件 | スループット | レイテンシ |
|------|------------|----------|
| パッチ前 | 94.6 Mbit/s | 155 ms |
| パッチ適用・AQL 制限あり | 74.3 Mbit/s | 22 ms |
| パッチ6を除いた比較ベースライン | 33.7 Mbit/s | 21 ms |

同じ負荷でレイテンシが155msから22msへ、およそ7分の1になります。あるいは同程度のレイテンシを保ったままスループットが 33.7 から 74.3 Mbit/s へ、2.2倍に増える。ラップトップで動画会議をしながら大きなファイルを落とすような場面で、体感が変わる水準の差です。

### 原因は「宣言していなかった」こと

なぜこれほど悪かったのか。Linux の Wi-Fi スタックである mac80211 は、ドライバが `NL80211_EXT_FEATURE_AQL` と `NL80211_EXT_FEATURE_AIRTIME_FAIRNESS` という2つの拡張機能フラグを宣言した場合にだけ、キュー深さの制御とフロー公平性の制御を有効にします。ath11k はこれらを宣言していませんでした。つまり mac80211 側にバッファブロート対策の仕組みはあったのに、ドライバが「使います」と手を挙げていなかったために一切適用されていなかった、ということです。

その結果、ネットワークが飽和するとフロー分離も AQM（Active Queue Management）も効かないままハードウェアの TX リングにデータが積み上がり、1つのフローが帯域を独占しながらレイテンシが跳ね上がっていました。バッファブロートという言葉が広く知られるようになってから10数年、教科書どおりの症状がドライバの宣言漏れで再現していたわけです。

そして、その核心にあたる[パッチ 2/9](https://marc.info/?l=linux-wireless&m=178758144903126&w=2)（`wifi: ath11k: enable airtime queue limits`）の差分は、実際に1行だけです。

```c
wiphy_ext_feature_set(ar->hw->wiphy, NL80211_EXT_FEATURE_AQL);
```

ただし「1行で7倍」と丸めるのは正確ではありません。この1行が効くようにするための前処理（SKB の解放経路の変更）、送信待ちパケット数とエアタイム実績の mac80211 への報告、ドライバ側 TXQ スケジューラの実装、TX 完了コールバックからのスケジューラ駆動——9本合わせて150行あまりの変更があって初めて成立します。特に、レビューで指摘を受けて追加されたパッチ6（TX 完了駆動のスケジューリング）が、レイテンシを保ったままスループットを 2.2 倍にする部分を担っています。

レビューを担当したのは fq_codel や CAKE で知られる Toke Høiland-Jørgensen で、負荷時のレイテンシを実際に測ったか、そしてキューが詰まる恐れはないかという2点が指摘されました。投稿者はこれを受けてパッチ6を追加しています。なお [Phoronix は「9本のパッチは150行あまりの追加で、Claude Opus 5 の支援を受けた」と報じています](https://www.phoronix.com/news/ath11k-7x-Lower-Latency)が、v3 のカバーレター本文に AI への言及はありません。

### 恩恵が届く範囲

対象になるのは `ath11k` を使う機種、つまり WCN6855 / WCN6750 などを積んだ Qualcomm 製 Wi-Fi 6 チップ搭載機です。ThinkPad の一部モデルや AMD 版のビジネスラップトップ、IPQ8074 / IPQ6018 ベースの Wi-Fi 6 ルーターなどが該当します。自分のマシンが該当するかは `lspci -k | grep -A3 -i network` あたりで確認できます。

ただし、これはまだメーリングリストへの投稿段階（v3）です。`ath-next` へのマージを経て将来のカーネルに入る見込みですが、現時点で試すにはパッチを手で当てるか、先行適用しているディストリビューションを使う必要があります。

## 3. 10年近く越しの Job Objects — ReactOS がプロセスグループ管理をマージ

オープンソースの Windows 互換 OS「ReactOS」が、NT カーネルのプロセスグループ管理機構「Job Objects」の基本サポートをメインラインにマージしました。[PR #7500](https://github.com/reactos/reactos/pull/7500) がマージされたのは2026年8月22日です。

Job Objects は複数のプロセスを1つのまとまりとして扱うためのカーネルオブジェクトで、[Microsoft の公式ドキュメント](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects)にあるとおり、ジョブに割り当てたプロセスが生成する子プロセスも自動的に同じジョブへ属します。まとめて終了させる、リソース制限をかける、といった操作が一括でできるため、Windows のサービス管理や、ブラウザのプロセス隔離の基盤として使われている機構です。

今回のマージで実装されたのは `NtCreateJobObject` / `NtOpenJobObject` / `NtAssignProcessToJobObject` / `NtIsProcessInJob` / `NtTerminateJobObject` / `NtQueryInformationJobObject` / `NtSetInformationJobObject` といった一連のシステムコールで、変更規模は8ファイル・追加2,245行・削除582行。中心は `ntoskrnl/ps/job.c` です。効果は数字にも出ていて、Wine の kernel32 テストスイートで60件あった job 関連の失敗がゼロになりました。

| 状態 | job 関連テストの失敗件数 |
|---|---|
| マージ前 | 60 件 |
| マージ後 | 0 件 |

対象仕様は Windows 8 より前のもので、Windows 8 で導入されたネストしたジョブや、ジョブセット、UI 制限クラスの一部はまだ実装されていません。

面白いのは、この機能がどれだけ長く懸案だったかです。最初の試みまで遡れば10年近く。途中で WIP の PR が引き継がれては Wine テストで結果が出ずに止まり、2024年6月に Gleb Surikov が PR #7500 として新たに設計をやり直しました。共通ロックで保護したイテレータの導入、プロセス割り当てのアトミックなトランザクション化、完了ポートのライフタイム管理といった同期まわりの作り直しを経て、複数の開発者によるレビューを通ってようやくマージされています。

とはいえ、これで ReactOS 上でモダンなブラウザがそのまま動くわけではありません。Job Objects 以外にも必要な NT 6.x API は山ほどあります。[Phoronix が伝えるとおりマージ自体は完了しました](https://www.phoronix.com/news/ReactOS-Job-Objects)が、これは「入口に立てた」段階の一歩です。それでも、Windows のアプリケーションを Windows なしで動かそうというプロジェクトにとって、避けて通れない礎石が1つ据わったことになります。

## 4. 測定される前のポリシーを測る — Linux 7.3 の IMA 改善

Linux 7.3 のマージウィンドウで、IMA（Integrity Measurement Architecture）に2つの実務的な変更が入りました。どちらも v7.2 には含まれておらず、[Linux v7.2 のリリース（2026年8月16日）直後に開いたマージウィンドウ](https://www.paul-moore.com/blog/d/2026/08/linux_v73_merge_window.html)以降にマージされたものです。

IMA は、カーネルがファイルやバッファのハッシュを計測し、その記録を TPM の PCR（Platform Configuration Register）へ積み上げていく仕組みです。外部の検証者は、この測定ログと TPM が署名した PCR の値（Quote）を突き合わせることで、「そのマシンで何が実行されたか」を遠隔から検証できます。クラウドや機密計算の文脈で使われるリモートアテステーションの土台です。

### 受理される前のポリシーを測る

1つめは、[ポリシーの生の書き込みをパース前に測定する変更](https://github.com/torvalds/linux/commit/f1e10b10874051e4d99911dae0dd7b75a9f8ae66)です。

署名付きポリシーが必須でない構成では、ユーザー空間から securityfs のポリシーファイルへ直接ルールを書き込めます。

```bash
echo -e "measure func=BPRM_CHECK mask=MAY_EXEC\n" \
     > /sys/kernel/security/ima/policy
```

このルートで入ってきたルールは、ユーザー空間とカーネルの信頼境界をまたいでいます。従来 `func=POLICY_CHECK` はファイル経由で読み込まれた部分的なポリシーを測定していましたが、securityfs へ書き込まれた生のバッファはその対象外でした。7.3 の変更では、 **そのポリシーが受理されるかどうかに関わらず、書き込まれたバッファをパース前に測定する** ようになりました。コミットメッセージはこれを「measure & load」パラダイムに沿ったものと説明しており、ポリシー処理のバグの露見と、IMA を壊しにいく試みの検出の両方を狙っています。測定は `measure func=POLICY_CHECK` が有効なとき（`ima_policy=tcb` など）に記録され、テンプレートは `ima-buf` に強制されます。

記録された値は次のように確認できます。

```bash
grep "ima_policy_written" \
  /sys/kernel/security/integrity/ima/ascii_runtime_measurements | \
  tail -1 | cut -d' ' -f 6 | xxd -r -p | sha256sum
```

「何を測ったか」だけでなく「どのルールで測ることにしたか」まで証拠に含める、という方向の一歩です。

### TPM が間に合わない環境への対応

2つめは `IMA_INIT_LATE_SYNC` [オプションの追加](https://github.com/torvalds/linux/commit/1ebe7997b53b7ff956a089593723d8cb6faffdd6)です。

IMA が `boot_aggregate` を TPM の PCR 値付きで記録するには、TPM ドライバが built-in で、しかも IMA の初期化より先にプローブされている必要があります。ところがコミットメッセージによれば、FF-A プロトコル上で CRB インターフェースを使う TPM では、前提となる `tpm_crb_ffa` デバイスのプローブが済んでいないと `-EPROBE_DEFER` が返ります。IMA の初期化は `late_initcall` で走り、遅延プローブの処理も同じレベルなので、順序次第で TPM のプローブが IMA 初期化より後になってしまう。同様の状況は SPI バスに接続された TPM でも[報告されています](https://lore.kernel.org/all/aYXEepLhUouN5f99@earth.li/)。

こうなると dmesg に次のメッセージが出て、IMA はハッシュの計測こそ続けるものの PCR への書き込みを行いません。ハードウェアには TPM が載っているのに、測定ログがソフトウェアから改ざん可能な状態になってしまいます。

```
ima: No TPM chip found, activating TPM-bypass!
```

新オプションは、IMA の初期化を `late_initcall_sync` まで遅らせることでこの順序問題を解消します。ただしトレードオフもあります。コミットメッセージには、このオプションを有効にした場合、initcall 中に `request_module()` などのユーザーモードヘルパー経由で initramfs 上のファイルへアクセスするモジュールを built-in にしてはならない、と明記されています。そうしないと IMA がそれらのファイルの測定を取りこぼす可能性があるためです。

手元の状況は次のコマンドで確認できます。

```bash
# TPM バイパスモードが発動していないか
dmesg | grep -i "tpm-bypass"

# IMA の測定ログ
cat /sys/kernel/security/ima/ascii_runtime_measurements | head -20

# 適用中の IMA ポリシー
cat /sys/kernel/security/ima/policy
```

Linux 7.3 の最終リリースは2026年10月中旬から下旬の見込みです。

## 5. 「Rust で書き直してくれたら採用する」 — Firefox 157 が JPEG-XL をデフォルト有効化

Mozilla が2026年8月24日、[Firefox で JPEG-XL のデコードをデフォルト有効にする Intent to Ship を公開](https://hacks.mozilla.org/2026/08/intent-to-ship-jpeg-xl/)しました。対象は Windows・macOS・Linux・Android の全プラットフォームで、[dev-platform メーリングリストの Intent to Ship 原文](https://www.mail-archive.com/dev-platform@mozilla.org/msg01866.html)では対象バージョンが Firefox 157、制御用の設定が `image.jxl.enabled`、追跡バグが Bug 2065096 であることが確認できます。

JPEG XL は ISO/IEC 18181 として2022年に標準化された静止画フォーマットで、PNG を超えるロスレス圧縮、ダウンロードの15%時点で内容が判別できるプログレッシブレンダリング、既存 JPEG の無損失再圧縮（`cjxl --lossless_jpeg=1` でファイルサイズが20〜25%減り、品質は落ちない）、16ビット色深度と広色域のネイティブ対応といった特性を持ちます。

### 拒否したのは Mozilla、条件を飲んだのは Google

今回の発表で語り継がれそうなのは、そこに至る経緯のほうです。

C++ の参照実装 libjxl は、約10万行のマルチスレッド C++ コードです。Mozilla はこれを Firefox に組み込むことについて、 **その規模のコードが追加する攻撃面（attack surface）を懸念していた** と公式ブログで述べています。そして Google Research に対して、Rust で書き直せば採用すると条件を提示しました。Google がそれに応じて開発したのが `jxl-rs`（[リポジトリ](https://github.com/libjxl/jxl-rs)）です。

`jxl-rs` は大部分が safe Rust で書かれており、SIMD 演算など性能上どうしても必要な箇所にだけ unsafe を使い、そこには Unsafe Rust の専門家による著者以外のレビューを必須とする方針が敷かれています。性能面では C++ 参照実装と同等かそれ以上で、プログレッシブレンダリングの対応は強化され、メモリ消費はむしろ減っているとされています。

結果として、Chromium もこの `jxl-rs` を統合しました。Chrome と Firefox という競合するブラウザが同じ Rust クレートを画像デコーダとして共有する、なかなか珍しい状態です。

### 一度捨てられたフォーマットの帰り道

JPEG XL の道のりは平坦ではありませんでした。2022年、Google は「エコシステム全体の関心不足」「既存フォーマットに対する十分な優位性がない」ことを理由に、Chrome の実験的な JXL サポートを削除します。ところが Chromium のバグトラッカーには Intel、Adobe、Cloudinary、Facebook、The Guardian、Shopify といった企業から反発が集まり、[500件を超えるコメントが殺到しました](https://www.theregister.com/software/2026/01/14/google-rekindles-relationship-with-jilted-jpeg-xl/4816480)。Intel の Roland Wooster も、ウェブ向けの圧縮性能と16ビット色深度、そして写真家が使うカラーガモットへの対応を挙げて JPEG XL を擁護するコメントを寄せています。

その後、2023年に Apple が WebKit へ実装（Safari 17.0 に搭載）、2025年に Microsoft が Windows 11 へ対応を追加、そして2026年に Chromium が `jxl-rs` の統合を完了。Firefox 157 の対応で、主要ブラウザが揃って JXL をデフォルトで扱う体制が整うことになります。

もっとも、万能というわけでもありません。dev-platform のメーリングリスト上の議論では、ロスレス用途の JXL がロスレス WebP に比べて大幅に遅い割にファイルサイズの削減幅は小さい、という指摘も出ており、主用途はロッシー圧縮と想定されています。

### いま試すには

Firefox 157 を待たずに試すこともできます。現行の Firefox（152〜156）では、設定を1つオンにすれば使えます。

```
# 方法1: Firefox Labs
about:preferences →「Firefox Labs」セクション →「JPEG XL」を有効化

# 方法2: about:config
about:config → image.jxl.enabled を true にして再起動
```

Web 側から段階的に配信するなら、`<picture>` でのフォールバックが素直です。

```html
<picture>
  <source srcset="image.jxl" type="image/jxl">
  <source srcset="image.avif" type="image/avif">
  <img src="image.jpg" alt="...">
</picture>
```

## まとめ

今日の5本に共通していたのは、「やろうと思えばできたはずの小さな一手」が、実際にはずいぶん長く放置されていたという構図でした。

Oracle の脆弱性は7か月前にパッチが出ていました。ath11k は mac80211 に対して機能フラグを宣言するだけでよかった。ReactOS の Job Objects は、最初の試みから数えれば10年近く懸案のままでした。IMA は、書き込まれたポリシーをパース前に測るだけで「証拠の選び方」まで記録できた。JPEG XL は、書き直しを引き受ける人がいれば主要ブラウザに載る道が残っていました。

そして、それらが動き出したきっかけも小さなものです。CISA が期限を切ったこと。レビュアーがキューの詰まりを疑ったこと。ひとりの開発者が設計をやり直したこと。Mozilla が条件を下ろさなかったこと。

手元のシステムにも、たぶん同じような「あとでやる」が眠っています。まずは `dmesg | grep -i tpm-bypass` と、Oracle HTTP Server の在庫確認あたりから始めてみてはいかがでしょうか。

## 参考リンク

- [CVE-2026-21962 - NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-21962)
- [CISA KEV 追加アラート（2026-08-24）](https://www.cisa.gov/news-events/alerts/2026/08/24/cisa-adds-one-known-exploited-vulnerability-catalog)
- [ath11k AQL パッチシリーズ v3 カバーレター（linux-wireless）](https://marc.info/?l=linux-wireless&m=178758146703148&w=2)
- [ReactOS PR #7500 - Basic support for jobs in the kernel](https://github.com/reactos/reactos/pull/7500)
- [ima: measure userspace policy writes before parsing（カーネルコミット）](https://github.com/torvalds/linux/commit/f1e10b10874051e4d99911dae0dd7b75a9f8ae66)
- [security: ima: introduce IMA_INIT_LATE_SYNC option（カーネルコミット）](https://github.com/torvalds/linux/commit/1ebe7997b53b7ff956a089593723d8cb6faffdd6)
- [Intent to Ship: JPEG-XL（Mozilla Hacks）](https://hacks.mozilla.org/2026/08/intent-to-ship-jpeg-xl/)
