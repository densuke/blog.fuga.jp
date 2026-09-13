---
title: "その更新、誰が届けていますか — CVSS満点の緊急ホットフィックスから、113パッケージを手放した夜まで（2026/9/14 Linux・OSSトレンド）"
date: 2026-09-14T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Cisco", "KEV", "Debian", "Ubuntu", "Intel", "NPU", "Void Linux", "AI", "Linuxカーネル", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

わたしたちは毎日、当たり前のように更新を受け取っています。`apt upgrade` を叩けばパッケージが降ってくるし、ベンダーのサイトにはホットフィックスが並んでいる。

けれど、その更新を「作って、検証して、配る」のは誰かの手です。ベンダーのセキュリティチームであり、ディストリビューションのリリースチームであり、ハードウェアベンダーのドライバー担当であり、そして無償で何十ものパッケージを抱えている一人のメンテナーでもあります。

今日並んだ5本は、偶然にもその「手」を上から下までたどるような並びになりました。CVSS満点で回避策のない緊急ホットフィックス、107件のセキュリティ更新をまとめて届けたディストリビューション、新しいハードウェアに追いつくためのカーネル更新、ようやく公式サポートの枠に入ったAIアクセラレーター、そして——たった13分のやりとりの末に113パッケージを手放したメンテナー。

届く側から見れば同じ「更新」でも、届ける側から見れば全部ちがう話です。

{{< youtube "uGHwcVuWQ7s" >}}

## 1. Cisco Secure Firewall Management Center の認証バイパス — CVSS 10.0、回避策なし

今日いちばん急ぐ話からいきます。

Cisco Secure Firewall Management Center（FMC）のWeb UIに、認証バイパスの脆弱性 CVE-2026-20079 が見つかりました。[Cisco 公式のセキュリティアドバイザリ](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-onprem-fmc-authbypass-5JPp45V2)によれば CVSS 基本値は 10.0、ベクターは `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` です。[NVD のエントリ](https://nvd.nist.gov/vuln/detail/CVE-2026-20079)でも同じ値になっています。ネットワーク越しに、複雑な条件なしに、認証もユーザー操作も要らずに、機密性・完全性・可用性のすべてを完全に奪える。満点というのはそういう意味です。

そしてアドバイザリには、こう書かれています。

> There are no workarounds that address this vulnerability.

回避策はありません。設定で塞ぐことも、機能を止めて凌ぐこともできない。ホットフィックスを当てるか、修正版に上げるか、その二択です。影響を受けるのは FMC ソフトウェアの 7.0 / 7.2 / 7.4 / 7.6 / 7.7 / 10.0 系統と、クラウド管理版の Cisco Security Cloud Control（SCC）Firewall Management。バージョンごとに個別のホットフィックスが用意されています。

技術的な中身は [VulnCheck の解説](https://vulncheck.com/blog/cisco-fmc-auth-bypass-cve-2026-20079)が詳しく、FMC が起動時に内部用として生成するプロセスセッションが、Web UI への最初のログインで上書きされないまま残ってしまう点が根本原因だと説明されています。VulnCheck は、攻撃が成立しやすいのは起動直後、あるいは Web UI に直接ログインする運用がほとんどない機器だと解説しています。裏を返せば、日常的にダッシュボードを触っている環境では攻撃機会がそこまで広くない、ということでもあります。修正そのものは Apache 設定と Perl の認証ハンドラー `SF/Auth.pm` にヘッダー検証を足す、25行ほどの小さな変更だとも書かれています。

問題は、すでに使われていることです。Cisco 自身がアドバイザリで「In August 2026, the Cisco PSIRT became aware of active exploitation of this vulnerability.」と述べており、8月の時点で悪用が確認されています。[Cisco Talos の分析](https://blog.talosintelligence.com/fmc-ongoing-exploitation/)は3つの攻撃クラスターを挙げ、そのうち UAT-11823 について「overlaps in tooling with the Sandworm APT actor」と高い確度で評価し、UAT-11988 はランサムウェアオペレーター（Qilin のアフィリエイトと戦術が一致）だと分析しています。国家系とランサムウェアが同じ穴を同時に掘っている、という状況です。Talos の分析結果であって Cisco のアドバイザリに書かれた帰属ではない点は、いちおう区別しておきます。

CISA は9月9日にこの CVE を [Known Exploited Vulnerabilities カタログ](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)へ追加しました。カタログのエントリには `dueDate` として 2026-09-12 が設定されています。ただしこれは [BOD 26-04](https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk) に基づく連邦行政機関（FCEB）向けの義務であって、民間企業に法的な期限があるわけではありません。[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/09/09/cisa-adds-four-known-exploited-vulnerabilities-catalog)も「BOD 26-04 applies only to FCEB agencies」と明記したうえで、他の組織にも対応を強く推奨する、という書き方をしています。

そしていちばん厄介なのがここです。Cisco はアドバイザリで、ホットフィックスは今後の攻撃を防ぐが、すでに侵害されている場合の対処にはならないと注意しています。当てて終わり、ではない。当てたうえで、当てる前に何かされていなかったかを確認する必要があります。FMC はファイアウォール群を束ねる管理基盤ですから、ここを取られるということは配下のポリシー全体を取られるということです。

## 2. Debian 13.7 "Trixie" — 107件のセキュリティ更新を、まとめて配る

急ぐ話の次は、地味だけれど確実な話です。

[Debian プロジェクトの公式アナウンス](https://www.debian.org/News/2026/20260912)によれば、安定版の第7ポイントリリース Debian 13.7 "Trixie" が2026年9月12日に公開されました。アナウンスのページには Security Updates の表と Miscellaneous Bugfixes の表が並んでおり、それぞれ107件と106件の項目が載っています。セキュリティ側は DSA-6381 から DSA-6486 までのアドバイザリに対応するもので、インストーラーのカーネルは 6.12.107+deb13 に更新されました。

面白いのは、アナウンス自身が期待値を下げにきていることです。

> Those who frequently install updates from security.debian.org won't have to update many packages, and most such updates are included in the point release.

security.debian.org から普段どおり更新を受け取っている人は、そんなに多くのパッケージを更新することにはならない——つまり、ポイントリリースとは「すでに配り終えたものを、ひとつの箱にまとめ直す作業」なのだ、というわけです。新規インストール時に何百件もの更新を追いかけなくて済むように、配り手の側で整理してくれている。これは派手ではありませんが、更新を届ける仕事のかなり本質的な部分だと思います。

中身としては glibc・QEMU・curl といった基盤コンポーネントに修正が集中しています。glibc はあらゆるプロセスがリンクしているので、更新後に長時間動き続けているプロセス（Webサーバー、データベース、コンテナランタイムなど）を再起動しないと、古いライブラリを抱えたまま走り続けることになります。ポイントリリースを当てたら再起動、はセットで考えたほうがいい部分です。

既存の Debian 13 ユーザーがやることは `sudo apt update && sudo apt upgrade` だけです。それだけで済むように、上流が整えてくれている。

## 3. Ubuntu 24.04.5 LTS — 新しいハードウェアに追いつくための更新

同じ週、Ubuntu 側でもポイントリリースが出ました。

[Ubuntu Community Hub の公式アナウンス](https://discourse.ubuntu.com/t/ubuntu-24-04-5-lts-released/87608)によると、Ubuntu 24.04 LTS（Noble Numbat）の第5ポイントリリースが2026年9月10日に公開されました。Kubuntu・Ubuntu Budgie・Ubuntu MATE・Lubuntu・Ubuntu Kylin・Ubuntu Studio・Xubuntu・Edubuntu・Ubuntu Cinnamon・Ubuntu Unity の各フレーバーも同時に 24.04.5 になっています。

このリリースの主眼は HWE（Hardware Enablement）スタックの更新です。[Phoronix](https://www.phoronix.com/news/Ubuntu-24.04.5-LTS)は「The Ubuntu 24.04.5 LTS HWE stack provides the Linux 7.0 kernel and Mesa 26.0 graphics drivers」と報じています。ただし Mesa のバージョンについては [Linuxiac](https://linuxiac.com/ubuntu-24-04-5-lts-released-with-updated-hwe-stack/) が 26.2 と書いており、媒体間で表記が割れています。公式アナウンスや[リリースノート](https://documentation.ubuntu.com/release-notes/24.04/)には具体的なバージョン番号の記載を確認できなかったので、ここでは「HWE スタックのカーネルとグラフィックスドライバーが新しくなった」という事実にとどめておきます。数字が要る方は手元の `apt policy` で確かめるのが確実です。

HWE の仕組みは知っておくと便利です。LTS のデスクトップインストールは既定で HWE スタックを追いかける設定になっているので、再インストールなしで通常のアップデート経由で新しいカーネルを受け取れます。一方サーバーインストールは既定が GA（General Availability）カーネル、つまりリリース時の 6.8 のままで、HWE は任意選択です。[Ubuntu 公式の HWE ドキュメント](https://ubuntu.com/kernel/docs/reference/hwe-kernels/)にあるとおり、サーバーで明示的に有効化したい場合は `linux-generic-hwe-24.04` を入れることになります。安定性を優先する環境で勝手にカーネルが上がらない、というのは設計としてまっとうです。

なおこの回は配る側にとっても平坦ではなかったようで、公式アナウンスのスレッドには、amd64 デスクトップインストーラーで拡張インストールを選ぶとクラッシュする問題（LP #2167127）が公開後に見つかり、デスクトップ ISO をいったん取り下げた旨が追記されています。届けるという作業には、出したあとに引っ込める判断まで含まれる、ということですね。

Ubuntu 24.04 LTS のサポート期間は、[Ubuntu 公式のカーネルライフサイクル](https://ubuntu.com/kernel/lifecycle)のとおり標準保守が2029年4月まで、ESM を契約すれば2034年3月まで延びます。

## 4. Intel NPU Driver 1.38 — 「動く」と「サポート対象」は別の話

ハードウェアに追いつく話をもうひとつ。ただしこちらは、技術というより線引きの話です。

[Intel の Linux NPU ドライバー v1.38.0 リリースノート](https://github.com/intel/linux-npu-driver/releases/tag/v1.38.0)（2026年9月11日付）に載っている変更は、実質一行です。

> Added support for Ubuntu 26.04 LTS

Phoronix も[この点を取り上げて](https://www.phoronix.com/news/Intel-Linux-NPU-Driver-1.38)「there is just one listed change」と書いています。コードが一行という意味ではなく、変更項目が一件だけ、ということです。

技術的に見れば、Ubuntu 26.04 の上でこのドライバーが動くこと自体は以前から可能だったはずです。それでもバージョンを切ってリリースノートに一行書くのは、「動く」と「公式にサポート対象である」がエンタープライズの世界では完全に別物だからです。サポート対象でなければ、業務環境で使う稟議は通らない。この一行は、そのための一行です。

中身も確認しておくと、対応プロセッサーは Meteor Lake・Arrow Lake・Lunar Lake・Panther Lake・Wildcat Lake の5世代。コンポーネントは Level Zero v1.32.0、OpenVINO 2026.3.1、コンパイラは npu_ud_2026_38_rc1 で、検証に使われたカーネルは 7.0.0-31-generic です。Ubuntu 24.04.5 の HWE スタックが載せてきた Linux 7.0 と同じ世代で検証されているわけで、ディストリビューション側の更新とハードウェアベンダー側の更新が噛み合っているのが見て取れます。

なお [Intel のドライバー構成ドキュメント](https://github.com/intel/linux-npu-driver/blob/main/docs/overview.md)にあるとおり、NPU へのアクセスはカーネルの `intel_vpu` モジュールが提供するデバイスノードの上に Level Zero のユーザースペースドライバーが乗り、その上で OpenVINO Runtime がグラフ推論をオフロードする構成です。つまり今のところ、NPU を使うには OpenVINO なり Level Zero なりのスタックに乗る必要があります。GPU のように汎用のアクセラレーターとして好き勝手に叩ける状態ではない、というのは押さえておいたほうがよいでしょう。

## 5. Void Linux の AI ポリシー紛争 — 13分で、113パッケージが手を離れた

最後は、更新を届ける「手」そのものがいなくなった話です。

発端は Go のバージョンアップ PR でした。Void Linux のメンテナー thypon 氏（本名は一次ソースで確認できなかったので GitHub ハンドルで書きます）が、[void-packages の PR #62351](https://github.com/void-linux/void-packages/pull/62351)（`go: update to 1.27.1.`）のコメント欄に、2026年9月11日23時29分（UTC）、詳細な調査レポートを投稿します。Go 1.26.5 と 1.27.1 を比較して、ビルドが壊れる7パッケージ（anubis / fs-repo-migrations / goreleaser / kubo / minio / opentofu / sops）を特定し、`x/net/http2.TrailerPrefix` が Go 1.27 で削除されたために gRPC 系が一斉にエラーになる、という分析まで含んだ力の入った内容でした。

翌9月12日の00時19分、別のメンテナー classabbyamp 氏が短く尋ねます。「what was used to generate this comparison?」

1分後、thypon 氏が答えます。「My usual setup, GLM-5.3-flash + opencode.」

ここで問題になったのは、AI を使ったこと自体よりも、開示が事後だったことです。classabbyamp 氏は [Void Linux の CONTRIBUTING.md](https://github.com/void-linux/.github/blob/master/CONTRIBUTING.md#ai-usage) の AI Usage セクションを引いて、こう返しました。

> All contributions are expected to be made by humans. AI tools may be used for research and learning, but all content in contributions must originate from and be understood by the contributor. **This includes** code, documentation, issues, security reports, **pull request descriptions, and comments** in all Void Linux community spaces.

thypon 氏は「The generated wall of text is well understood, and vouched by me and my tools.」と反論します。生成されたものではあるが、自分（と自分のツール）が理解し保証している、と。classabbyamp 氏の返しは「the policy's pretty clear that the text itself shouldn't be generated, whether you vouch/understand it or not」——ポリシーはテキストそのものを生成するなと言っており、理解しているかどうかは関係ない。

00時42分、thypon 氏は 👍 の絵文字とリンクだけを残しました。リンク先は [PR #62482「Disown maintained packages」](https://github.com/void-linux/void-packages/pull/62482)。自分がメンテナンスしていた113パッケージのテンプレートから `maintainer` 行を一括削除する、113ファイル・113行追加・113行削除という完全対称の PR です。

最初の問いかけから、ここまで23分。ポリシーを引用されてからは、13分でした。

対象には alacritty、kubernetes、moby や etcd といったコンテナ基盤、terraform、virt-manager、hugo、thermald などが含まれます。そしてこの PR は、2026年9月13日にマージされています。つまりこれらは、現時点で実際にメンテナー不在のパッケージになりました。Void のパッケージ管理は GitHub の PR ベースなので有志が名乗りを上げれば引き継げますが、kubernetes や libguestfs のように専門知識が要るものは、引き取り手が現れるまで更新が止まります。

どちらが正しいか、という話をするつもりはありません。Void のポリシーは読めば明快で、一貫して運用されています。thypon 氏の側にも、自分が検証したものを機械的に排除されたという言い分はあるでしょう。ただ事実として残ったのは、ポリシーの適用が正しく行われた結果、113パッケージの更新を届ける手がなくなった、ということです。

メンテナーの時間と気力は、OSS で最も補充しにくい資源です。ポリシーを決めるときのコストは条文の中には書かれていなくて、こういう形で後から請求書が来ます。

## まとめ

今日の5本を「届ける手」という軸で並べ直すと、こうなります。

Cisco は、回避策のない満点脆弱性に対してホットフィックスを出しました。ただし、当てたあとに何が残っているかは受け取る側の仕事として残ります。Debian は107件のセキュリティ更新を一箱にまとめて、新規インストールの手間を減らしました。Ubuntu は新しいハードウェアに追いつくためのカーネルを配り、その過程でインストーラーの不具合を見つけて ISO を引っ込めました。Intel は、すでに動いていたものに「公式サポート」という一行を足しました。そして Void Linux では、113パッケージ分の手が離れました。

更新は空から降ってくるわけではありません。誰かが作って、検証して、配っています。そしてその誰かは、たいていの場合こちらが思っているより少人数です。

あなたの環境で動いているパッケージ、その更新は今、誰が届けてくれていますか。

## 参考リンク

- [Cisco Security Advisory: cisco-sa-onprem-fmc-authbypass-5JPp45V2](https://sec.cloudapps.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-onprem-fmc-authbypass-5JPp45V2)
- [Cisco Talos: Ongoing exploitation of Cisco Secure FMC](https://blog.talosintelligence.com/fmc-ongoing-exploitation/)
- [CISA Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [Debian 13.7 リリースアナウンス](https://www.debian.org/News/2026/20260912)
- [Ubuntu 24.04.5 LTS released（Ubuntu Discourse）](https://discourse.ubuntu.com/t/ubuntu-24-04-5-lts-released/87608)
- [Intel linux-npu-driver v1.38.0 リリースノート](https://github.com/intel/linux-npu-driver/releases/tag/v1.38.0)
- [void-packages PR #62482「Disown maintained packages」](https://github.com/void-linux/void-packages/pull/62482)
- [Void Linux CONTRIBUTING.md（AI Usage）](https://github.com/void-linux/.github/blob/master/CONTRIBUTING.md#ai-usage)
