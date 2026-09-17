---
title: "気づいてから直すまでの速さが、被害の大きさを分ける — 満点10.0に猶予3日、2.5か月後の公表、そして100%の置き換え（2026/9/18 Linux・OSSトレンド）"
date: 2026-09-18T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Cisco", "KEV", "Acronis", "デジタル庁", "Ubuntu", "Rust", "coreutils", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

脆弱性そのものの深刻さは、たいてい数字で語られます。CVSS がいくつ、影響台数が何台、といった具合です。ただ、実際に被害の大きさを決めているのは、その数字よりも「気づいてから直すまでにどれだけ時間がかかったか」のほうだったりします。

今日の5本は、その時間の長さがそれぞれ違う形で表に出た話でした。満点の脆弱性に対して3日しか猶予が与えられなかった話。パッチ以外に手がなく、パーミッション1つで root まで通ってしまう話。異常に気づいてから公表まで2.5か月かかった話。そして、性能や安全性のために基盤そのものを入れ替えるという、もっと長い時間軸の話が2本です。

{{< youtube "Pv9gc257xrk" >}}

## 1. Cisco ISE CVE-2026-76460 — CVSS 10.0、悪用済み、猶予は3日

最初は、今日いちばん急ぐ話です。

Cisco Identity Services Engine（ISE）は、企業や官公庁のネットワークで 802.1X / RADIUS / TACACS+ の認証ポリシーを一元管理する、いわば入口の番人にあたる製品です。そこに認証を回避できる脆弱性が見つかりました。[Cisco の公式アドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-ISE-ABP-VNSW7Tn5) は原因を "This vulnerability is due to insufficient authentication control on an API endpoint."、つまり API エンドポイントにおける認証制御の不足だと説明しています。分類は CWE-648（Incorrect Use of Privileged APIs）、特権 API の不正な使用です。

スコアは [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-76460) の確定値で CVSS v3.1 の **10.0（Critical）** 、ベクタは `AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` です。すべての項目が最悪値で、なかでも `S:C`（Scope: Changed）が効いています。壊れるのが ISE 1台の話にとどまらず、その先にあるネットワーク全体の認証判断に波及するという意味だからです。

そして Cisco は "The Cisco PSIRT is aware of active exploitation of this vulnerability." と明記しています。すでに実際に使われている、ということです。CISA は [KEV カタログ](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json) へ 2026年9月16日に登録し、連邦機関の対応期限を **9月19日** に設定しました。掲載から3日。この期限は米国の連邦文民行政機関に課される義務なので、日本の一般企業のパッチ期限そのものではありませんが、通常の KEV が2〜3週間の猶予を与えるのに対して3日というのは、明らかに異例の短さです。

修正版はアドバイザリに一覧があります。

- ISE 3.1 → 3.1 Patch 12
- ISE 3.2 → 3.2 Patch 11
- ISE 3.3 → 3.3 Patch 12
- ISE 3.4 → 3.4 Patch 7
- ISE 3.5 → 3.5 Patch 4

ISE 3.0 については "Cisco ISE Software Release 3.0 has reached End of Software Maintenance." とあり、修正は提供されません。サポート対象のリリースへ移行するしかない、という案内です。また、この脆弱性は ISE 本体だけでなく ISE Passive Identity Connector（ISE-PIC）にも影響し、しかも "regardless of device configuration"、設定内容によらず影響を受けます。

回避策は "There are no workarounds that address this vulnerability." と明記されていて、存在しません。当座の緩和としてアドバイザリが挙げているのはインフラ ACL（iACL）で、管理・制御プレーン宛の必要なトラフィックだけを通すように絞る、という一般的な手当てです。根本的な解決はパッチだけになります。

なお発見の経緯は "This vulnerability was found during the resolution of a Cisco Technical Assistance Center (TAC) support case." とあるだけで、それ以上は書かれていません。サポートケースの調査中に見つかったという事実のみで、その前に何があったのかは公開されていません。

## 2. Acronis Backup の cPanel / Plesk プラグイン CVE-2026-87886 — 既定パーミッションから root へ

同じ日に KEV へ載ったもう1件は、地味ですが刺さる場所が悪い脆弱性です。

Acronis Backup のホスティングパネル向けプラグインに、ローカル権限昇格の脆弱性が見つかりました。[Acronis の公式アドバイザリ SEC-10986](https://security-advisory.acronis.com/advisories/SEC-10986) は分類を CWE-276（Incorrect Default Permissions）、つまり既定のファイルパーミッションが不適切であることによるものとしています。バックアップ処理が使うファイルに広すぎる権限が付いており、低権限のローカルユーザーがそれを書き換えると、root で動くバックアップサービスが書き換えられた内容を実行してしまう、という筋道です。

深刻度は CVSS 7.8（High）、ベクタは `CVSS:3.0/AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H` です。ここで1つ注意点があります。この値の出所は **Acronis 自身のアドバイザリ** で、NVD ではありません。執筆時点で NVD の API に CVE-2026-87886 を問い合わせても該当レコードが返ってこず、まだ収載されていない状態でした。報道各社が伝えている 7.8 も、元をたどれば Acronis の発表です。

影響を受けるのは Linux 向けのプラグイン3種で、修正ビルドは次のとおりです。cPanel & WHM 向けが 1.9.3.1021、Plesk 向けが 1.8.11.638、そして DirectAdmin 向けが 1.2.3.238。DirectAdmin 版も同じアドバイザリに載っているので、cPanel と Plesk だけを見て安心しないほうがいいところです。Windows 向けは対象に含まれていません。

悪用については、Acronis が "Exploitation of this vulnerability has been detected in the wild in limited, targeted attacks against Acronis Backup plugin for cPanel & WHM deployments." と公式に認めています。限定的で標的を絞った攻撃、という表現です。[BleepingComputer の報道](https://www.bleepingcomputer.com/news/security/acronis-warns-of-actively-exploited-flaw-in-its-cpanel-backup-plugin/) によれば、この判断の根拠は「被害を受けた可能性のある顧客からの1件の報告」だとされています。技術的な詳細が公開されていないのも、管理者がパッチを当てる時間を確保するためだと報じられています。どちらも Acronis のアドバイザリ本文には書かれておらず、報道経由の情報です。発見者や報告日も公表されていません。

CISA 側の期限は Cisco ISE と同じく [9月16日登録・9月19日期限](https://www.cisa.gov/news-events/alerts/2026/09/16/cisa-adds-two-known-exploited-vulnerabilities-catalog) で、根拠となる指令は BOD 26-04「Prioritizing Security Updates Based on Risk」です。

共有ホスティングのように1台へ多数のテナントが同居する環境では、ローカル権限昇格は「同居人の1人が全員の管理者になれる」ことを意味します。CVSS 7.8 は満点ではありませんが、置かれている場所を考えると軽い数字ではありません。

## 3. デジタル庁の GSS で約24.6万件 — 既知の脆弱性と、2.5か月の沈黙

ここで少し目線を日本に移します。

デジタル庁が、政府共通の業務環境である **ガバメントソリューションサービス（GSS）** への不正アクセスについて公表しました。[9月11日付の公表資料](https://www.digital.go.jp/news/2026-0911-01) によれば、第三者がネットワーク接続機器（VPN）の脆弱性を利用してシステムに侵入し、保存されていたファイルが閲覧された可能性があります。

漏えいした可能性のある件数は約24.6万件。内訳は公務員等が約18.9万件、事業者・個人が約5.7万件で、情報の種類は氏名が約23.6万件、メールアドレスが約23.1万件、電話番号が約9.4万件、住所が約0.1万件です。そして資料には「マイナンバー、金融機関口座情報、年金番号などは含まれていないことを確認」と明記されています。対象は政府の内側で働く人たちの連絡先情報であって、一般国民の個人情報ではありません。

技術的に気になるのは、使われた脆弱性の性質です。[デジタル庁の Q&A](https://www.digital.go.jp/press/5fc99139-a4e2-4b7b-8b0c-d475e926143f) には「本事案の脆弱性については、攻撃が確認される前に、公表されていたものです」とあり、さらに当初の評価は「中（CVSS Medium レベル）」で、「修正プログラムの適用前に当該脆弱性が悪用される事態となった」と説明されています。つまりゼロデイではありません。公開されていて、深刻度も最上位ではなく、パッチも出ていた。それを当てる前に踏まれた、という構図です。

冒頭の話にそのまま戻ってきます。トピック1の Cisco ISE は「回避策がなく、パッチを当てる以外に手がない」という製品側の問題でした。こちらは「手はあったが、当たるまでの時間のほうが長かった」という運用側の問題です。深刻度が Medium だったことも、おそらく優先順位の判断に効いています。

時系列は、6月25日に異常を検知、7月9日に原因を特定して通信を遮断、そして9月11日に公表。検知から公表まで約2.5か月です。Q&A はその理由を「初期段階では不正アクセスの有無や影響範囲が不明確であり、侵入経路の分析、漏えいした可能性のある情報の特定、対象者の確認に相当な時間を要した」と説明しています。技術的には理解できる説明ですが、対象者にとっては、その2.5か月のあいだ自分の連絡先が攻撃者の手元にあることを知らないまま過ごしたことになります。実際、公表資料は「デジタル庁や関係機関を装った不審なメール、電話、SMS 等に御注意いただき」と注意を呼びかけています。

なお、悪用された VPN 機器の製品名・メーカー名・CVE 番号は公表されていません。過去の類似事案から製品を推測する報道もありますが、一次資料にその記載はないので、ここでは触れないでおきます。

## 4. Ubuntu 26.10 の amd64v3 デイリー ISO — 「古い CPU 向けの妥協」をやめる選択

ここからは攻撃の話を離れます。

Canonical が Ubuntu 26.10「Stonking Stingray」向けに、x86-64-v3 に最適化したデイリー ISO の提供を始めました。[Ubuntu のデイリービルド配布ページ](https://cdimage.ubuntu.com/ubuntu/stonking/daily-live/current/) には `stonking-desktop-amd64v3.iso` が通常の amd64 イメージと並んで置かれており、zsync 用のメタファイルも揃っています。[Phoronix の報道](https://www.phoronix.com/news/Ubuntu-26.10-amd64v3-Daily) によれば、9月上旬からデイリー ISO に amd64v3 版が同梱されるようになったとのことです。

x86-64 マイクロアーキテクチャ・レベルは、2020年に AMD・Intel に加えて Red Hat・SUSE といった Linux ディストリビューターも交えて策定された、CPU 命令セットの段階仕様です。v1 から v4 まであり、 **x86-64-v3** は AVX / AVX2 による 256bit の SIMD 演算、FMA（積和融合）、BMI1 / BMI2（ビット操作）などを備えていることを前提にします。[Red Hat の技術解説](https://developers.redhat.com/articles/2024/01/02/exploring-x86-64-v3-red-hat-enterprise-linux-10) によれば、これらを最初に実装したのは Intel の Haswell 世代（2013年）で、AMD は Excavator 世代（2015年）から対応しています。過去10年ほどのあいだに作られたマシンなら、だいたい対象に入ります。

自分の環境が対応しているかどうかは、一行で確認できます。

```bash
/lib64/ld-linux-x86-64.so.2 --help | grep x86-64
# "x86-64-v3 (supported)" と出れば対応済み
```

実は、この仕組み自体は新しくありません。[Canonical Foundations チームのアナウンス](https://discourse.ubuntu.com/t/introducing-architecture-variants-amd64v3-now-available-in-ubuntu-25-10/71312) のとおり、アーキテクチャ・バリアントは Ubuntu 25.10 の時点で導入済みでした。ただし当時は、通常どおりインストールしたあとに APT の設定を足して切り替える、というオプトインの手順が必要でした。26.10 の新しさは、その手順を丸ごと省いて、インストールの時点から v3 最適化パッケージ一式が入った状態にできるところにあります。

性能については、[Phoronix が廉価ノート（CHUWI UniBook、Intel Core 3 304、8GB RAM）で実機比較](https://www.phoronix.com/review/ubuntu-2610-amd64v3-lowend) を行っています。FIO のストレージテストやグラフィックス、Stockfish、OpenSSL、cryptsetup といった項目で amd64v3 版が最速となり、記事は全体として "healthy performance gains found in a number of areas" とまとめています。具体的な向上率は本文中に数値として書かれておらずグラフ側にあるため、ここでは「はっきり差が出る領域がある」という程度に留めておきます。1万円台の差もない廉価ノートで差が見えるということ自体が、この話の要点です。

注意点もあります。AVX2 を持たない古い CPU では、この ISO はそもそも起動しません。また、デイリービルドは毎日中身が変わる開発版なので、本番環境向けではありません。合わなければ通常の amd64 ISO で入れ直せばいい、という関係です。起動後に動的に切り替えられるものではない点は誤解しやすいところでしょう。安定版のリリースは10月15日が予定されています。

## 5. Ubuntu 26.10 の Rust coreutils 100% — 5年越しの置き換えが終わる

最後は、今日いちばん静かで、いちばん深いところに触る話です。

Ubuntu 26.10 で、`cp`・`mv`・`rm` が Rust 実装の uutils coreutils に置き換わります。[Canonical Foundations チームの公式アップデート](https://discourse.ubuntu.com/t/foundations-team-updates-2026-08-27/86783) には "the 100% `rust-coreutils` enablement" という表現が登場していて、この3つが残っていた最後の空白でした。[2026年4月の公式ポスト](https://discourse.ubuntu.com/t/an-update-on-rust-coreutils/80773) にも "cp, mv, and rm continue to be provided by GNU coreutils in 26.04" とあり、26.04 LTS の時点ではまだ GNU 版のままだったことが分かります。

なぜこの3つだけ残っていたのか。理由ははっきりしています。セキュリティ監査です。同じ公式ポストによれば、Zellic による2ラウンドの監査で **113件（73件＋40件）** の問題が指摘され、[oss-security への一括開示](https://www.openwall.com/lists/oss-security/2026/05/02/2) のとおり、そのうち 44件に CVE が採番されました。メモリ安全のために Rust へ移す、という話のはずが、その Rust 実装の側で問題が見つかったわけです。

指摘の中身がまた示唆的で、[uutils 0.9.0 のリリースノート](https://github.com/uutils/coreutils/releases/tag/0.9.0) は監査結果を "concentrated in TOCTOU races and filesystem edge cases that Rust's type system does not prevent" と表現しています。TOCTOU（Time-of-Check to Time-of-Use）は、ファイルの状態を確認した瞬間と実際に操作する瞬間のあいだに、別のプロセスが対象を差し替えてくる競合です。確認したときは普通のファイルだったのに、書きに行った瞬間にはシンボリックリンクにすり替わっている、といった類のものです。

これは Rust の型システムが防げる種類のバグではありません。言語がメモリ安全でも、ファイルシステムという外の世界との間には時間の隙間があって、そこは自分で塞ぐしかない。2026年5月30日に出た 0.9.0 は、まさにそこを塞いだリリースでした。TOCTOU 耐性を持たせた `uucore::safe_copy` モジュールの新設、`cp` / `mv` / `chmod` の再帰処理での TOCTOU 修正、そして "`chroot` now resolves all ids before chrooting" のように、chroot する前に UID/GID をすべて解決しておくといった細かい直しが並んでいます。

ユーザー側の影響は、基本的にはありません。日常的な `cp` や `mv` の使い方は変わらないはずです。[uutils の公式サイト](https://uutils.org/coreutils/) は "This project aims to be a drop-in replacement for the GNU utils. Differences with GNU are treated as bugs." と明言していて、GNU との差異はすべてバグ扱いという方針だからです。それでも困る場合は、`coreutils-from-gnu` パッケージで GNU 版に戻せます。パッケージ自体は [Ubuntu 26.10 のアーカイブ](https://packages.ubuntu.com/stonking/coreutils-from-gnu) に実在します。

気にしておくといいのはライセンスのほうかもしれません。uutils は MIT ライセンスで、GNU coreutils の GPLv3 から許可型への移行にあたります。ディストリビューションの土台にあるツール群の性格が変わるという意味では、性能や安全性より長く効いてくる変化です。実際、[LWN の記事](https://lwn.net/Articles/1069593/) のコメント欄では、常連ユーザーの wtarreau 氏が、何百万ものスクリプトが挙動を前提にしてきたコアツールの置き換えに対して6か月の露出期間では短すぎる、という趣旨の懸念を書いています。

Canonical はこの流れを一度きりで終わらせるつもりはないようで、[ntpd-rs についての公式ポスト](https://discourse.ubuntu.com/t/ntpd-rs-its-about-time/79154) では 27.04 までに NTP / NTS / PTP を統合したバイナリを既定で入れる計画と、Trifecta Tech Foundation の開発を資金面で支えていることを述べています。金額については年間 €40,000 という数字が [It's FOSS](https://itsfoss.com/news/ubuntu-rustification-coreutils-migration/) で報じられていますが、公式ポスト側には記載がありません。

なお Ubuntu 26.10 は非 LTS で、サポートは9か月です。本番サーバーで 26.04 LTS を使っているなら `cp`・`mv`・`rm` は GNU 版のままなので、今すぐ何かする必要はありません。

## まとめ

今日の5本を並べると、「直すまでの時間」がそれぞれ違う長さで出てきました。

Cisco ISE は満点の10.0で、悪用済みで、回避策がなく、猶予は3日でした。ここでは時間を短くする以外の選択肢がありません。Acronis のプラグインは、既定のパーミッションという設置時の判断が、ホスティング事業者の1台の中で root まで通る経路になっていました。デジタル庁の件は、脆弱性が公開済みで、深刻度は Medium で、パッチも出ていた。手はあったのに、当たるより先に踏まれた。そして検知から公表まで2.5か月かかりました。

一方で、amd64v3 の ISO も Rust coreutils も、何年もかけて土台を差し替えていく話です。とくに後者は、メモリ安全のための置き換えが監査で113件の指摘を受けて、TOCTOU という「言語では防げない隙間」を1つずつ塞いでから、ようやく既定に昇格しました。急いで直すのとは逆の、時間をかけて確からしさを積む種類の速さです。

自分の手元で言えば、たぶん確認すべきなのは「このパッチ、いつ出たんだっけ」ではなく「出てから今日まで、何日空いているか」のほうなのだと思います。CVSS が Medium のものほど、その日数は長くなりがちです。

## 参考リンク

- Cisco 公式アドバイザリ cisco-sa-ISE-ABP-VNSW7Tn5: https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-ISE-ABP-VNSW7Tn5
- Acronis 公式アドバイザリ SEC-10986: https://security-advisory.acronis.com/advisories/SEC-10986
- デジタル庁「ガバメントソリューションサービスへの不正アクセスについて」: https://www.digital.go.jp/news/2026-0911-01
- Canonical Foundations チーム「An update on rust-coreutils」: https://discourse.ubuntu.com/t/an-update-on-rust-coreutils/80773
- uutils coreutils 0.9.0 リリースノート: https://github.com/uutils/coreutils/releases/tag/0.9.0
