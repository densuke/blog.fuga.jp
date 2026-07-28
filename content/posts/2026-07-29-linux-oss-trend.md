---
title: "裏口・順序・置き場所——「処理をどこでやるか」が明暗を分けた一日（2026/7/29 Linux動向）"
date: 2026-07-29T00:00:00+09:00
draft: false
tags: ["セキュリティ", "TeamCity", "CI/CD", "CachyOS", "Linux Kernel", "fwupd", "CISA KEV", "AMD"]
categories: ["Linux・OSSトレンド"]
---

今日並んだ5本を眺めていて感じたのは、「処理をどこで、どの順番でやるか」という一点が、速さも穴も決めているということです。TeamCity の脆弱性は正面のログイン画面ではなく裏口にあたるビルドエージェント向けの通信経路が狙われ、fwupd は権限チェックより先にメタデータを読んでしまう順序ミスが火種になりました。CachyOS はスケジューラが CPU の処理順を変えるだけで体感速度を底上げし、KNOD は処理そのものを CPU から GPU へ移そうとしています。そして CISA KEV に追加された脆弱性は、本来「内部専用」だったはずの機能が外部から到達できる場所に置かれていたことが引き金でした。場所と順序、この地味な設計判断がすべてを分けています。

{{< youtube "-D69-IuF6As" >}}

## 1. JetBrains TeamCity On-Premises に認証不要 RCE CVE-2026-63077（CVSS 9.8）— CI/CD の中枢が裏口から乗っ取られる

JetBrains は2026年7月、CI/CD（継続的インテグレーション・継続的デリバリー、コードのビルドとデプロイを自動化する仕組み）ツール TeamCity On-Premises に、認証不要でリモートコード実行が可能な脆弱性 CVE-2026-63077 を公表しました。[JetBrains 公式ブログ](https://blog.jetbrains.com/teamcity/2026/07/cve-2026-63077/)によれば、CVSS スコアは **9.8** （Critical）、影響を受けるのは「All versions of TeamCity On-Premises are affected」とされる全バージョンです。修正版は **2025.11.7** および **2026.1.3** で、TeamCity Cloud は対象外。JetBrains は「TeamCity Cloud customers are not required to take any action」と明言しており、Cloud 環境での悪用の証拠も確認されていません。研究者 Antoni Tremblay が 2026年7月10日に非公開で報告し、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-63077)では7月27日に公開情報として登録されています。

今回の脆弱性が興味深いのは、狙われた場所です。標的になったのは Web のログイン画面という「正面」ではなく、ビルドエージェントがサーバーへ定期的に問い合わせを行う **Agent Polling Protocol** （内部専用の通信経路）という裏口でした。ここで受け取ったデータの処理に安全でないデシリアライズ（受け取ったバイト列をプログラム内のオブジェクトへ復元する処理を、中身の検証なしに行ってしまうこと。CWE-502、分類は NVD による）が存在し、HTTP(S) でサーバーに到達できさえすれば、未認証の攻撃者が認証チェックを完全にバイパスして任意の OS コマンドを実行できてしまいます。CVSS ベクトルは `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` で、ネットワーク越し・低い攻撃複雑度・権限もユーザー操作も不要という、攻めやすさを示す値が並びます。

ただし、ここは冷静に書いておく必要があります。攻撃の具体的な手順やペイロードの中身について、JetBrains 公式ブログは詳細を公開していません。推測で攻撃コードの流れを描写するのは避けるべきなので、この記事でも「安全でないデシリアライズが存在する」という事実以上には踏み込みません。また、公開時点で本脆弱性を悪用したスキャンや攻撃の観測情報は確認できていません。「既に悪用されている」わけではなく、あくまで悪用が可能な状態が見つかった、という段階です。

TeamCity には過去にも深刻な認証バイパスの前例があります。2024年3月に Rapid7 が開示した [CVE-2024-27198](https://www.rapid7.com/blog/post/2024/03/04/etr-cve-2024-27198-and-cve-2024-27199-jetbrains-teamcity-multiple-authentication-bypass-vulnerabilities-fixed/) は、細工した URL で認証チェックを回避できる脆弱性（CWE-288、代替パス・チャネルによる認証バイパス）で、CVSS 9.8 という値まで今回と一致していました。ただし CWE 分類が 288 と 502 で異なる別系統の脆弱性であり、同一コンポーネントの再発なのか、独立して見つかった同種の欠陥なのかは一次・二次情報のいずれからも確認できていません。断定はできませんが、狙われる通信経路が Web のルーティング処理からビルドエージェント向けの内部プロトコルへと変わった点は、攻撃者が「正面」から「裏口」へ視線を移していることの表れかもしれません。なお CVE-2024-27198 については、公開後にインターネット公開インスタンスへの大規模な悪用が観測され、不正な管理者アカウントの大量作成やランサムウェア配布に使われたと[Trend Micro が報じています](https://www.trendmicro.com/en_us/research/24/c/teamcity-vulnerability-exploits-lead-to-jasmin-ransomware.html)。

対応はシンプルです。TeamCity On-Premises を 2025.11.7 または 2026.1.3 へ更新することが最優先で、すぐに更新できない場合は[セキュリティパッチプラグイン](https://www.helpnetsecurity.com/2026/07/28/teamcity-rce-cve-2026-63077-fixed/)を適用します（2017.1 以降が対象。2017.1〜2018.1 系はプラグイン適用後にサーバー再起動が必要です）。JetBrains 公式ブログによれば、2024.03 以降のバージョンでは TeamCity がこのプラグインの存在を自動で検知してダウンロードし、管理者に通知する仕組みも用意されているとのことで、更新作業そのもののハードルは下げられています。CI/CD サーバーはソースコード・ビルド成果物・デプロイ認証情報という機密資産の集積地なので、そこでのリモートコード実行はサプライチェーン汚染に直結しかねません。インターネットに公開している場合はもちろん、社内ネットワーク越しでも到達可能な範囲であれば標的になり得るため、VPN 経由に限定するなどネットワーク到達性そのものを絞る対策も有効です。

## 2. CachyOS が AMD Ryzen AI 9 HX 470 ベンチマークで Windows 11 を上回る

Phoronix が2026年7月28日に公開した[比較レビュー](https://www.phoronix.com/review/amd-hx470-windows-linux)によれば、AMD Ryzen AI 9 HX 470（コードネーム "Gorgon Point"）搭載のミニ PC「BOSGAME VTA-439」で、CachyOS・Ubuntu 26.04 LTS・Fedora Workstation 44・Windows 11 Pro を比較したところ、CachyOS が総合首位に立ちました。テスト機は 12コア/24スレッドの Ryzen AI 9 HX 470、統合 GPU に Radeon 890M（RDNA 3.5）、メモリは DDR5-5600 32GB、ストレージは 1TB NVMe SSD という構成で、すべての OS が「out-of-the-box」（初期設定のまま）でテストされています。

CachyOS を差別化しているのは複数のチューニングの積み重ねです。ひとつは **BORE スケジューラ** （Burst-Oriented Response Enhancer）で、[開発元のリポジトリ](https://github.com/firelzrd/bore-scheduler)によれば、Linux 標準の EEVDF スケジューラを拡張し、各タスクの「バースト性」（スリープしてから短く CPU を使ってまたスリープする、という挙動の蓄積度合い）をスコア化してタイムスライスに反映する仕組みです。バースト性が低いインタラクティブなタスク（ゲーム入力や GUI 操作など）を、CPU 占有型のバックグラウンド処理より優先させる、「公平性より体感の流れのよさ」を狙った設計と言えます。もうひとつは **AutoFDO + Propeller** という二段階のプロファイル最適化で、[CachyOS のカーネルリポジトリ](https://github.com/CachyOS/linux-cachyos)にあるとおり、実行プロファイルをコンパイラへフィードバックして頻繁に通るコードパスを優先的に最適化し、リンク後にも関数配置を再最適化して命令キャッシュの効率を高めます。

このほかにも、LLVM/Clang による全モジュール横断の最適化である **LTO** （リンク時最適化）が効いています。さらに、AVX2 対応 CPU 向けの x86-64-v3、AVX-512 対応の x86-64-v4 といった命令セットに合わせて主要パッケージを個別にビルドし直す **最適化パッケージリポジトリ** も用意されています。Ryzen AI 9 HX 470 は Zen 5 コアを持つため、汎用バイナリよりも SIMD 命令（ひとつの命令で複数のデータをまとめて処理する拡張命令）を効率よく使えるというわけです。加えて、BPF ベースでスケジューラをカーネルに動的ロードできる **sched-ext（SCX）** フレームワークもあり、再起動なしにゲーミング時・省電力時で異なるスケジューリングポリシーを切り替えられる運用も想定されています。

注目したいのは、Ubuntu 26.04 LTS や Fedora 44 も汎用カーネルのまま Windows 11 を上回る場面があったと報告されている点です。CachyOS との差は Phoronix の表現どおり「わずかな優位」程度であり、圧勝という描写は正確ではありません。むしろ「チューニング済みディストロを基準にすると、他の汎用ディストロのポテンシャルの高さが見えてくる」という読み方のほうが実態に近いでしょう。なお今回のベンチマークでは AMD の XDNA 2 NPU はまだ活用されておらず、Linux 側の AI 推論ワークロード対応が整えばさらに差が広がる可能性があります。「同じハードウェアでも OS を変えれば速度が変わる」というのは、買い替えずソフトウェアだけで速くなるという、いかにも Linux らしい話です。

## 3. fwupd 2.1.7 — 未署名メタデータが認可をバイパスする信頼境界の欠陥を修正・UEFI 更新を強化

2026年7月27日にリリースされた fwupd 2.1.7 は、ファームウェア更新ツールとして地味ながら重大な修正を含んでいます。[GHSA-9f42-c37j-25jh](https://github.com/fwupd/fwupd/security/advisories/GHSA-9f42-c37j-25jh)によれば、fwupd が D-Bus 経由でインストールを処理する際、「信頼されたメタデータの要求」よりも先に未署名のメタ情報フィールドを読んでしまう設計上の問題があり、深刻度は **Low** と評価されています。発見者は GE HealthCare のシニアディレクター Daniel Birtwhistle で、医療機器メーカーが自社のセキュリティ審査の中で見つけたという点が fwupd のユースケースの広がりを物語っています。

問題の根は、たった一箇所の「処理の順序」にありました。LVFS（Linux Vendor Firmware Service）の信頼モデルは、ベンダーが GPG 署名した CAB アーカイブ（metainfo.xml とファームウェアバイナリを含む）を fwupd が検証してからインストールするという設計ですが、CAB アーカイブ内のメタ情報ファイルが、実際のインストール権限チェックよりも先に展開・参照されてしまっていました。この順序ミスひとつから、性質の異なる4つの問題が同時に生じています。①未署名メタデータを細工することで、ダウングレード操作が polkit（権限確認の仕組み）の確認プロンプトなしに「信頼済み」扱いへ変換されてしまう、②認可されていないアーカイブが、正規の root 権限アップデートによるブロックより先にデバイスの実行時状態を変更できる、③署名付きペイロード自体は正規でも、未署名の GUID/プロトコルメタデータの書き換えによって更新先が「兄弟デバイス」（同一ハブに接続された別デバイス）にリダイレクトされる、④非特権ユーザーが最低バージョン制約（`version_lowest`）をスキップでき、ダウングレード保護の FORCE フラグが形骸化する、という4点です。

GHSA が影響ありと明記しているのは **fwupd 2.1.6 および main ブランチ（6fe7d2ce 時点）** で、D-Bus 経由でファームウェア更新を受け付ける経路が対象です。それ以前のバージョン全般への影響や、特定ディストロでの同梱状況までは、GHSA でも確認できていません。悪用には「細工した CAB アーカイブをターゲットシステムの fwupd に送り込む」という前提条件が必要であることも、深刻度が Low とされている理由のひとつです。

2.1.7 ではセキュリティ強化も進んでいます。[公式リリースノート](https://github.com/fwupd/fwupd/releases/tag/2.1.7)によれば、UEFI 更新フローと systemd-pcrlock を連携させ、更新前後の PCR（Platform Configuration Register、TPM が保持する測定値）拡張を自動記録する **systemd-pcrlock プラグイン** が追加され、「ファームウェアを更新するたびに TPM の測定値が変わって LUKS が解除できなくなる」という問題への対処が図られています。加えて、TCG Opal 対応ドライブの暗号化状態を可視化する **TCG ディスク暗号化セキュリティ属性** も追加されました。フラッシュメモリのライトプロテクト状態を確認する **MTD ロックセキュリティ属性** や、EFI セクション内の GUID オフセットを検証して範囲外読み取りを防ぐ機能も入っています。対応は主要ディストリビューションのリポジトリから 2.1.7 へアップデートすることで完了し、`fwupdmgr --version` で確認できます。

## 4. KNOD — カーネルが AMD GPU へネットワークパケット処理を直接オフロードする RFC パッチ投稿

Linux カーネル開発者が、新しいネットワークオフロード機構の RFC（Request for Comments、正式なマージ前段階の議論用パッチ）を投稿しました。[Phoronix の表記](https://www.phoronix.com/news/KNOD-Network-Offload-AMD-GPUs)では "in-kernel network offload device"、通称 **KNOD** と呼ばれています。ここで扱われているのは、処理を CPU から GPU へ丸ごと移すという、これまでとは違う「置き場所」の選択です。XDP（eXpress Data Path、カーネル内でパケットを高速処理する仕組み）プログラムや IPsec の SA（Security Association、暗号通信のための鍵・パラメータ情報）を、そのまま AMD GPU（GCN/RDNA2 世代）にオフロードします。ユーザー空間の ROCm（Radeon Open Compute Platform）ランタイムを必要とせず、カーネル自身が GPU のコマンドキューを直接管理し、JIT（実行直前に機械語へ変換する）コンパイルまで行うのが特徴です。

具体的な流れはこうです。NIC がパケットを受信すると XDP フックが発火し、通常であれば CPU がプログラムを実行しますが、KNOD が有効な場合はパケットバッファのポインタを AMD GPU の VMEM（Video Memory）空間にマッピングし、事前に JIT コンパイルされた GPU 側のコードをコマンドキューへディスパッチします。GPU はパケットバッファを直接読み書きし、XDP_PASS や XDP_DROP といったアクションコードを返し、CPU はキュー管理と例外処理だけを担当する形です。IPsec SA のオフロードも設計に含まれていて、GCN/RDNA2 世代の GPU は専用の暗号化命令を持たないため、SIMD の並列性を活かしたソフトウェア実装で処理を補う想定です。

この設計のポイントは、ROCm という重量級のユーザー空間スタックが不要なことです。AMDKFD（カーネル側で AMD GPU を扱うドライバインターフェース）経由の低レベルなコマンドキューインターフェースだけを利用するため、コンテナ環境やミニマル構成のサーバーでも GPU オフロードの恩恵を受けられます。ただし現時点で押さえておくべきなのは、これがまだ **RFC 段階のパッチ投稿** であり、マージ済み・採用決定ではないという点です。目標としているのは **Linux 7.3** でのマージですが、あくまで目標であって確約ではありません。対応ハードウェアは AMD GCN 世代・RDNA2 世代（Navi 21/22/23、Radeon RX 6000 シリーズを含む）で、RDNA3 世代（RX 7000 シリーズ）は将来対応、統合 GPU の Radeon 890M（RDNA 3.5）も対象に含める予定とされています。

用途として Phoronix が挙げているのは **L4 ロードバランシングと IPsec 暗号処理** の2つです。速報自体は "Some extremely cool patches were posted to the Linux kernel mailing list" と好意的な調子でしたが、SmartNIC（DPU）との機能的な重複をどう整理するか、AMD GPU 固有の実装をメインラインのレビューにどう通すかは、これからの論点になりそうです（ここは筆者の見立てで、開発者が実際にそう述べているわけではありません）。

ネットワーク集約型のワークロードを抱えるサーバー環境にとっては、CPU コアの節約と消費電力削減につながる興味深い方向性です。データセンター向けの AMD Instinct シリーズが今後さらに普及していくことを踏まえると、AI アクセラレータとネットワークオフロードを同一 GPU 上でまかなうアーキテクチャへの布石とも読めます。とはいえ、実際にマージされるかどうかはこれからのレビュー次第で、まだ提案の一歩目である、という位置づけは見誤らないようにしたいところです。

## 5. CISA KEV 7/27 更新 — Arista VeloCloud Orchestrator（CVSS 10.0）と Fortinet FortiOS を追加、修正期限3日

2026年7月27日、CISA は既知悪用脆弱性カタログ（KEV）に2件を追加しました。[CISA のアラート](https://www.cisa.gov/news-events/alerts/2026/07/27/cisa-adds-two-known-exploited-vulnerabilities-catalog)によれば、対象は CVE-2026-16812（Arista VeloCloud Orchestrator On-Prem）と CVE-2025-68686（Fortinet FortiOS）で、いずれも実際の攻撃での悪用が確認されています。連邦機関には Binding Operational Directive 22-01 に基づく期限内のパッチ適用が義務付けられており、CVE-2026-16812 の修正期限はわずか **3日** （7月30日）という異例の短さです。通常の KEV 期限が2〜3週間であることを考えると、今回の緊急度がいかに高いかが分かります。

CVE-2026-16812 は CWE-78（OS コマンドインジェクション）に分類され、[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-16812)によれば CVSS 4.0・3.1 ともにスコアは **10.0（CRITICAL）** で、すべての評価軸が最悪値という異例の事態です。VeloCloud Orchestrator（VCO）のオンプレミス版には、本来「内部使用のみ」を想定した特権機能が存在します。ところが、これらのエンドポイントが外部から到達可能な状態でデプロイされており、特殊文字を含む細工した HTTP リクエストを送るだけで、バックエンドがそれを OS コマンドとして解釈・実行してしまいます。[Arista のセキュリティアドバイザリ](https://www.arista.com/en/support/advisories-notices/security-advisory/24364-security-advisory-0144)によれば、Arista 自身が「VCO はデフォルトで公開されており、露出を防ぐ設定は存在しない」と明言しています。影響バージョンは 5.2.x（5.2.0〜5.2.3.13）・6.1.x（6.1.0〜6.1.3.3）・6.4.x（6.4.0〜6.4.2.3）・7.0.x（7.0.0）で、それぞれ 5.2.3.14・6.1.3.4・6.4.2.4・7.0.0.1 以上への更新が必要です。攻撃 IP としては `8.19.75.217`・`206.72.242.124`・`206.72.242.162` が Arista の調査で特定されています。VCO は配下の多数の VeloCloud Edge デバイスの設定・証明書・認証情報を一元管理しているため、オーケストレーター自体が乗っ取られれば、配下ネットワーク全体の掌握につながりかねない構造です。

対する CVE-2025-68686 は CWE-200（機密情報の不正露出）で、CVSS 3.1 スコアは **5.3〜5.9** （Fortinet CNA 公表値は 5.3、NVD CNA 暫定値は 5.9）と幅があります。攻撃複雑度は High で、[Fortinet PSIRT のアドバイザリ](https://fortiguard.fortinet.com/psirt/FG-IR-25-934)によれば、これは 2024〜2025年に FortiOS SSL-VPN で悪用されたシンボリックリンク植え付けによる永続化手法へのパッチを、細工した HTTP リクエストでバイパスできてしまうという「パッチのパッチ破り」の問題です。悪用には **別の脆弱性による事前のファイルシステムレベルの侵害** が前提条件となりますが、既に侵害されたデバイスにおける検出回避・再侵害のチェーンとして実際の攻撃で使われていることが確認されています。影響は FortiOS 7.6（7.6.0〜7.6.1）・7.4（7.4.0〜7.4.6）・7.2 全バージョン・7.0 全バージョン・6.4 全バージョンと広範囲に及びます。修正版はそれぞれ 7.6.2・7.4.7 以上で、7.2/7.0/6.4 系については修正済みの系列への移行が案内されています。

対応手順としては、CVE-2026-16812 は各ブランチの修正版へ即時アップグレードし、パッチ適用までは VCO の Web インターフェースへのアクセスを管理ネットワークのみに制限、既知の攻撃 IP をブロックリストに追加することが求められます。加えて、Web アクセスログで予期しないコマンド実行や設定ファイルへのアクセスがないかを精査し、侵害痕跡の有無を確認することも欠かせません。CVE-2025-68686 は FortiOS を修正版へアップグレードし、SSL-VPN を使用していないなら無効化、過去に侵害を受けた可能性があるデバイスはシンボリックリンクの精査が必要です。Fortinet Management & Protection（FMWP）が提供する仮想パッチ（db update 26.033）を適用すれば、アップグレードまでの間の即時緩和にもなります。CVSS 10.0・悪用済み・デフォルト露出という3条件が重なった VCO と、パッチ済みのはずが再び破られた FortiOS。「内部専用のつもりの機能がどこに置かれているか」「一度直したはずの穴が本当に塞がっているか」という、場所と順序の両方が試された一件でした。

## まとめ

今日の5本を貫いていたのは、結局「処理をどこで、どの順番でやるか」という一点でした。TeamCity は正面のログイン画面ではなく裏口のビルドエージェント通信が狙われ、fwupd は権限チェックより先にメタデータを読んでしまう順序ミスが4つの問題を同時に生みました。CachyOS はスケジューラが処理の順番を組み替えるだけで体感速度を押し上げ、KNOD は処理そのものを CPU から GPU へと置き場所ごと移そうとしています。そして CISA KEV に追加された VeloCloud Orchestrator は、内部専用のつもりだった機能が外部から到達可能な場所に置かれていたことが命取りになりました。速さも穴も、結局は「どこで」「どの順番で」という地味な設計判断の積み重ねから生まれています。皆さんが普段扱っているシステムでは、その「場所」と「順序」を最後に見直したのはいつでしょうか。

## 参考リンク

- JetBrains 公式ブログ CVE-2026-63077 の技術説明 https://blog.jetbrains.com/teamcity/2026/07/cve-2026-63077/
- NVD CVE-2026-63077 https://nvd.nist.gov/vuln/detail/CVE-2026-63077
- Rapid7 ブログ CVE-2024-27198/27199 の経緯 https://www.rapid7.com/blog/post/2024/03/04/etr-cve-2024-27198-and-cve-2024-27199-jetbrains-teamcity-multiple-authentication-bypass-vulnerabilities-fixed/
- Trend Micro CVE-2024-27198 悪用後のランサムウェア配布事例 https://www.trendmicro.com/en_us/research/24/c/teamcity-vulnerability-exploits-lead-to-jasmin-ransomware.html
- Help Net Security TeamCity RCE 修正オプション解説 https://www.helpnetsecurity.com/2026/07/28/teamcity-rce-cve-2026-63077-fixed/
- Phoronix レビュー本文（CachyOS ベンチマーク） https://www.phoronix.com/review/amd-hx470-windows-linux
- CachyOS カーネル公式リポジトリ https://github.com/CachyOS/linux-cachyos
- BORE スケジューラ公式リポジトリ https://github.com/firelzrd/bore-scheduler
- GHSA-9f42-c37j-25jh（fwupd 脆弱性詳細） https://github.com/fwupd/fwupd/security/advisories/GHSA-9f42-c37j-25jh
- fwupd 2.1.7 公式リリースノート https://github.com/fwupd/fwupd/releases/tag/2.1.7
- Phoronix KNOD AMD GPU ネットワークオフロード パッチ投稿ニュース https://www.phoronix.com/news/KNOD-Network-Offload-AMD-GPUs
- CVE-2026-16812 NVD https://nvd.nist.gov/vuln/detail/CVE-2026-16812
- CVE-2025-68686 NVD https://nvd.nist.gov/vuln/detail/CVE-2025-68686
- Arista Security Advisory 0144 https://www.arista.com/en/support/advisories-notices/security-advisory/24364-security-advisory-0144
- Fortinet PSIRT FG-IR-25-934 https://fortiguard.fortinet.com/psirt/FG-IR-25-934
- CISA KEV 追加アラート（2026-07-27） https://www.cisa.gov/news-events/alerts/2026/07/27/cisa-adds-two-known-exploited-vulnerabilities-catalog
