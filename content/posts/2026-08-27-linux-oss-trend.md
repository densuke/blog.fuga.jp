---
title: "開いただけでAIが汚れる — Ollamaの0.0.0.0、Giteaの匿名登録。穴の深さより「既定のまま」が効いた日（2026/8/27 Linux・OSSトレンド）"
date: 2026-08-27T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Gitea", "OpenSSL", "Calix", "NVIDIA NemoClaw", "Ollama", "Kubernetes", "UPnP", "CISA KEV"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

今日の5本を並べて気づくのは、どれも「攻撃がどれだけ深く潜り込めたか」ではなく「既定の設定がどこまで開いていたか」で被害の輪郭が決まっていたということです。Gitea は匿名ユーザー登録が既定で有効なままだったから、攻撃者は登録からエクスプロイトまでを完全自動化できました。NVIDIA の AI エージェントフレームワーク NemoClaw は Ollama を `0.0.0.0` にバインドする既定構成のせいで、Ollama 自身が持っていた防御が丸ごと無効化されました。Calix のホームルーターは UPnP の制御エンドポイントが既定で WAN 側にバインドされたまま出荷され、Kubernetes は既定値そのものを段階的に書き換えることでクラスターの前提を変えようとしています。

穴の「深さ」や「巧妙さ」よりも、既定値がどちらを向いていたかのほうが、結果として攻撃面を大きく左右した一日でした。

{{< youtube "NO4gaOmYHnw" >}}

## 1. Gitea CVE-2026-60004 — CISA KEV 追加の翌日に野生での悪用、FCEB 期限は 2026年8月28日

Gitea の diffpatch エンドポイントに存在するコードインジェクション脆弱性 [CVE-2026-60004（GHSA-rcr6-4jqh-j84m、CVSS 9.8 Critical）](https://github.com/go-gitea/gitea/security/advisories/GHSA-rcr6-4jqh-j84m)が、CISA の KEV（既知悪用脆弱性カタログ）に2026年8月25日に追加されました。翌8月26日には、暗号採掘ペイロードを投下する自動化エクスプロイトが実環境で観測されたと[Help Net Security が報じています](https://www.helpnetsecurity.com/2026/08/26/gitea-cve-2026-60004-exploited-in-the-wild/)。FCEB（米連邦民間行政機関）に課されたパッチ適用期限は **2026年8月28日** です。

脆弱性の核心は、Gitea の diffpatch API が受け取ったパッチを「共有ベアテンポラリクローン」に適用する処理にあります。bare リポジトリでは `hooks/` ディレクトリが Git の実行フックとして直接有効になっており、同一パッチを2回送ることで発生する「add/add コリジョン」のフォールバック処理を悪用すると、パッチ内のファイルパスを `hooks/post-index-change` に仕込むだけで実行可能ファイルを hooks ディレクトリに書き込めます。次の Git 操作でこのフックが Gitea サービスアカウント権限のまま起動し、任意のシェルコマンドが実行される仕組みです。

そしてここでも効いているのが「既定のまま」です。Gitea は **既定で匿名ユーザー登録が有効** になっており、攻撃者はアカウント登録→リポジトリ作成→diffpatch API 呼び出しという3ステップを人手を介さず完全自動化できます。公開 PoC が Gitea インスタンスを大量にスキャンする土台になり得る、と指摘されています。

[GHSA の確定値](https://github.com/go-gitea/gitea/security/advisories/GHSA-rcr6-4jqh-j84m)によれば、影響を受けるのは Gitea 1.17 〜 1.27.0 の全バージョン、修正は 1.27.1（[2026年7月27日リリース](https://github.com/go-gitea/gitea/releases/tag/v1.27.1)）です。攻撃事例としては、エクスプロイト成功からごく短時間でダミーコミット・シェルローダーの取得・暗号採掘バイナリの実行までが完了したと[報じられています](https://thehackernews.com/2026/08/critical-gitea-rce-actively-exploited.html)。ただし、秒数など細部の裏取りはできていないため本稿では触れません。侵害後は GHSA が列挙する範囲で、OAuth トークンなど連携用の認証情報が露出しうるとされています。なお、インターネットに公開された Gitea インスタンスの規模については、複数の調査で数万件規模という試算もあります。ただ、本稿では出典を特定できないため断定は避けます。

対応の優先順位は明快で、まずは 1.27.1 以降への即時アップグレードです。それが即座に難しい場合は `app.ini` の `[service]` セクションで `DISABLE_REGISTRATION = true` を設定し、匿名登録という「既定で開いていた入口」をまず閉じることが有効です。侵害の疑いがある場合は、露出した可能性のある認証情報のローテーションも一般的なインシデント対応として検討すべきでしょう。

## 2. OpenSSL 4.0.2 — 7ブランチ同時パッチで 9 CVE、目玉は QUIC の double-free

2026年8月25日リリースの [OpenSSL 4.0.2](https://github.com/openssl/openssl/releases/tag/openssl-4.0.2) は、4.0・3.6・3.5・3.4・3.0・1.1.1・1.0.2 という7ブランチに同時パッチを当てる異例の対応で9件の CVE を修正しました。サポートを終了していたはずの 1.0.2 と 1.1.1 にまでパッチが提供されたのは、DTLS の過剰バッファリング問題（CVE-2026-54874）が広い範囲のブランチに共通して存在していたためと見られます。ただし、この一括リリースの判断根拠について OpenSSL 公式アドバイザリ自体に明確な説明は書かれていません。

目玉は QUIC サーバーの double-free、[CVE-2026-18798（CWE-415、CVSS 3.1: 7.5 HIGH）](https://nvd.nist.gov/vuln/detail/CVE-2026-18798)です。QUIC サーバーが INITIAL パケットを受信した際、チャネル作成に失敗すると QRX（QUIC Record Layer RX）オブジェクトが二重に解放されるヒープ破損バグで、DCID が8バイト未満の INITIAL パケット1本で再現しうるとされています。RCE の可能性は NVD 上「極めて低い」と評価されており、通常は QUIC サーバープロセスの異常終了に留まります。影響ブランチは QUIC 実装を持つ 4.0・3.6・3.5 に限られ、3.4 以前は対象外です。

同じくメモリ枯渇系として、[CVE-2026-63075（CWE-770、CVSS 7.5 HIGH）](https://nvd.nist.gov/vuln/detail/CVE-2026-63075)があります。ACK のみのパケットのメタデータを接続の生存期間中ずっと保持し続けてしまう設計上の欠陥で、こちらは 4.0・3.6・3.5 に加えて 3.4 も影響を受けます。double-free の CVE-2026-18798 が 3.4 以前は対象外なのに対し、こちらは 3.4 も含む点で影響ブランチが異なり、QUIC 系の CVE も一律に同じブランチ範囲へ集中しているわけではありません。

非 QUIC 系では、CMS の AES-WRAP-PAD 鍵展開でヒープ境界外書き込みが起きる CVE-2026-63072（Medium）などが並びます。興味深いのは、[OpenSSL 公式アドバイザリ](https://openssl-library.org/news/secadv/20260825.txt)の深刻度表記が「Moderate」であるのに対し、NVD の CVSS スコアは 7.5（High）になっている点です。RCE に至らない欠陥は最大 Moderate に据え置くという OpenSSL 独自の基準と、CVSS のスコアリング方式の違いが表れています。

QUIC サーバーとして動作しているプロセス（nginx・HAProxy・Caddy などで HTTP/3 や QUIC を有効にしている環境）が主な対象で、CVE-2026-54874（DTLS）は 1.0.2 を含む全ブランチが対象のため、組み込み機器を含めた影響範囲が最も広くなります。即時アップグレードが難しい場合の一時的な回避策として、QUIC を無効化する（nginx であれば `quic` ディレクティブをコメントアウトする）という一般的な運用対応も選択肢になります。

## 3. Calix GS7 XGS の UPnP 露出 — WAN 側に無認証公開、ベンダーは無応答のまま

Calix GS7 XGS（GS5239XG）住宅向けルーターの UPnP WANIPConnection サービスが、WAN 側 TCP 5000番ポートに認証なしで公開されている[CVE-2026-75501（NVD 確定値: CVSS 7.5 HIGH）](https://nvd.nist.gov/vuln/detail/CVE-2026-75501)が、[CERT/CC アドバイザリ VU#756733](https://kb.cert.org/vuls/id/756733)として2026年8月21日に公開されました。NVD への CVSS スコア登録は8月25日で、両者の日付は区別しておく必要があります。

原因は、Calix が EXOS ファームウェアで採用する MiniUPnPd 2.3.7 が、UPnP 制御エンドポイントを LAN 側だけでなく **WAN 側にもバインドしてしまっている** ことです。認証なしで `AddPortMapping`（外部ポートを内部 LAN デバイスへ転送）、`DeletePortMapping`、`GetGenericPortMappingEntry`、`GetExternalIPAddress` の4種の SOAP アクションが実行でき、リース期間を `0` に指定すれば恒久的なポートフォワードルールを作成できます。[発見者 Brian Khan Quintana の検証](https://drkq.github.io/security-research/calix-vu756733/)では、このルールは再起動後も残存することが確認されています。

開示の経緯は正確に押さえておく必要があります。発見者 Quintana は **2026年6月7日、ベンダー・展開 ISP・CERT/CC へ同時に** 初回開示を送付しており、沈黙が続いたのはその後です。7月29日の再送にも応答はなく、CERT/CC は「ベンダーから声明を受け取っていない」として8月21日にアドバイザリを公開しました。ベンダーが意図的に放置しているかどうかまでは、確認できる事実の範囲を超えます。

なお発見者自身のブログでは CVSS 9.1 という値が示されていますが、[NVD の CNA 値は 7.5](https://nvd.nist.gov/vuln/detail/CVE-2026-75501) です。いずれも CVSS 3.1・スコープは Unchanged で評価しており、差はスコープの取り方ではなく機密性影響（Confidentiality）の評価の違いによるものです。研究者ブログは `C:H/I:H/A:N` を採って 9.1、NVD の CNA 値は `C:N/I:H/A:N` で 7.5 としています。本稿は一次情報である NVD の 7.5 HIGH を採用します。

影響を受けると確認・報告されているのは Cox Communications、Brightspeed、ALLO Communications、CityFibre、Conexon といった ISP で、いずれも大手です。加入者規模については各種試算がありますが、本稿では確度の高い一次情報で確認できていないため数字には触れません。現時点でベンダーからのパッチ提供見通しは示されておらず、利用者側でできる対応は UPnP の無効化、ISP 経由でのロック解除依頼、既存のポートフォワード設定の確認・削除といった防御的な運用に限られます。

## 4. NVIDIA NemoClaw — DNS リバインドで Ollama のチャットテンプレートを永続汚染

NVIDIA の AI エージェントフレームワーク NemoClaw が Ollama を `0.0.0.0:11434` で無認証公開してしまう構成ミスを突く DNS リバインド攻撃、[CVE-2026-65105（NVD 確定値: CVSS 8.1 HIGH）](https://nvd.nist.gov/vuln/detail/CVE-2026-65105)が、[Cyera のリサーチレポート](https://www.cyera.com/research/nemoclaw-one-website-visit-to-hijack-your-ai-agent)として研究者 Elad Luz・Ofek Itach の名で公開されました。悪意ある Web ページへのアクセス一回で、ローカル推論モデルのチャットテンプレートに隠し指示を注入できます。しかも、その汚染はセッションをまたいで永続します。macOS/Linux 向けは v0.0.35 で修正済みですが、Windows/WSL 環境については Cyera のレポートの時点で修正が明記されていません。

根本原因はここでも「既定のバインド先」です。Ollama 自体は DNS リバインド対策として Host ヘッダー検証を実装していますが、この検証は **ループバック（127.0.0.1）以外にバインドした場合には無効化される** 仕様になっています。NemoClaw がコンテナ間通信のために Ollama を `0.0.0.0` で起動する既定構成を取ったことで、この防御層が外れ、原典の表現に沿えば「残る防御は CORS ミドルウェアだけ」という状態になります。

攻撃の流れは、悪意あるドメインの DNS を後から `127.0.0.1` に向け直して「同一オリジン」として扱わせ、`GET /api/show` でチャットテンプレートを取得し、`system` ブロック末尾に隠し指示を追記した上で `POST /api/create` で汚染済みテンプレートを再登録する、というものです。チャットテンプレートは、クライアントから受け取ったメッセージを推論エンジンに渡す直前に展開される Go テキストテンプレートです。AI エージェント側が独自のシステムプロンプトを送っても、このテンプレート層でその外側から指示が注入されるため、クライアント側から汚染を検知することはできません。モデルの重み自体は変わらないため、汚染は会話を重ねても解消されません。

Cequence Security の CISO である Randolph Barr は [SiliconANGLE の取材](https://siliconangle.com/2026/08/25/nvidia-nemoclaw-flaw-let-attackers-poison-the-model-behind-a-developers-ai-agent/)に対し、「問題はモデル本体ではなく、その周辺の配管にある」と述べています。AI ツールチェーンが複雑化するほど、モデルそのものより周辺構成のミスが攻撃面になりやすいという指摘です。

NVD が確定したスコアは CVSS:3.1 で、Attack Vector は「Adjacent」（隣接ネットワーク）です。同一 LAN からの直接アクセスを主な経路として評価しているためと考えられます。ただし DNS リバインドを組み合わせれば、インターネット上の任意の Web ページからでも攻撃が成立しえます。その点で、実質的な攻撃面はスコアが示す「隣接」よりも広いとみる余地があります。この点はあくまで本稿の解釈であり、NVD 自身の評価としてではないことをお断りしておきます。影響バージョンは NemoClaw 0〜0.0.25（Linux）とされています。この脆弱性が汚染するのは Ollama を操作する AI エージェントが持つ権限の範囲であり、権限が広いエージェントほど影響も大きくなる、という関係にあります。

対応としては、macOS/Linux では NemoClaw を v0.0.35 以降に更新すること。Windows/WSL 環境では、Cyera のレポートが macOS/Linux のみ修正と明記していることを踏まえ、NemoClaw 経由の Ollama 利用を一時停止するか、`OLLAMA_HOST=127.0.0.1:11434` の明示指定とファイアウォールでのポート遮断を組み合わせることが挙げられます。

## 5. Kubernetes v1.37 — cgroup v1 の kubelet 起動拒否が続き、containerd 2.x が事実上の前提に

2026年8月26日リリースの [Kubernetes v1.37](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.37.md) は、いくつもの既定値の変化がクラスター運用に影響するリリースです。

まず cgroup v1 ノードの扱い。`failCgroupV1` の既定値が `true` になったのは v1.35 からで、v1.37 は「初めて起動を拒否する」わけではなく、その既定値をそのまま維持しています。とはいえ、[KEP-5573](https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/5573-remove-cgroup-v1/README.md)には「cgroup v1 コードの削除は 1.38 より早くは行わない」と明記されており、完全削除のタイムラインは未確定ながら窓は着実に閉じつつあります。自ノードの cgroup バージョンは `stat -fc %T /sys/fs/cgroup/` で確認でき、`tmpfs` が返れば v1、明示的な `failCgroupV1: false` の設定なしには kubelet が起動しません。

static Pod の扱いも変わりました。static Pod は kubelet が `/etc/kubernetes/manifests/` から直接読み込むため、本来 `configMapRef` や `secretRef` を通じた API リソース参照はサポート対象外でしたが、長年バグとして動作してきました。v1.37 ではこの動作が禁止され、該当のフィーチャーゲートは無効化できない形で固定化されています。自作のコントロールプレーンや独自 static Pod を運用している環境は、`/etc/kubernetes/manifests/` 配下を事前にスキャンしておく必要があります。

kube-proxy の ipvs モードについては、[KEP-5495](https://kubernetes.dev/resources/keps/5495)に沿って廃止に向けたカウントダウンが進んでいます。v1.35 で廃止が宣言され、v1.37 では実行時の廃止警告ログが出力されるようになりました。デフォルト無効化は v1.40、完全削除は v1.43 が見込まれています。推奨される移行先は v1.33 で GA になった nftables モードです。

そして [containerd の公式サポートマトリックス](https://containerd.io/releases/)によれば、Kubernetes 1.36 以降で containerd 1.x はすでに非対応となっており、v1.37 でも containerd 2.x が事実上の前提条件です。まだ containerd 1.x を使っている本番クラスターは、v1.37 へ上げる前にこの移行を済ませておく必要があります。

新機能としては、Alpha 機能として `DRADeviceCompatibilityGroups` フィーチャーゲート（既定 OFF）が追加された **DRA Device Compatibility Groups** があります。DRA ドライバがカウンターセットごとに互換グループを宣言できるようになり、デバイス準備フェーズではなくスケジュール時点で非互換な組み合わせを弾けるようになる仕組みです。GPU を複数の推論ワークロードへ細かく分割して割り当てるような設計が、よりスケジューラ側で正確に制御できるようになります。

アップグレード手順としては、containerd 2.x への移行、cgroup v1 ノードの v2 移行、static Pod マニフェストのスキャン、ipvs 廃止警告の確認、という順で事前準備を済ませてから v1.37 へ上げるのが安全でしょう。

## まとめ

Gitea の匿名登録、NemoClaw の `0.0.0.0` バインド、Calix の UPnP WAN 公開、そして Kubernetes の既定値の積み重なり——今日並んだ5本は、攻撃の巧妙さよりも「初期状態がどちらを向いていたか」が結果を左右していました。侵入経路の奇抜さより、既定のまま放置された設定のほうが、結局のところ攻撃面の広さを決めています。

手元の環境でも、Git ホスティングの匿名登録設定、ローカルで動かしている推論サーバーのバインドアドレス、ルーターの UPnP 有効化状態くらいは、一度見直してみる価値がありそうです。

## 参考リンク

- [Gitea GHSA-rcr6-4jqh-j84m](https://github.com/go-gitea/gitea/security/advisories/GHSA-rcr6-4jqh-j84m)
- [OpenSSL 公式セキュリティアドバイザリ（2026-08-25）](https://openssl-library.org/news/secadv/20260825.txt)
- [CERT/CC VU#756733（Calix）](https://kb.cert.org/vuls/id/756733)
- [Cyera リサーチレポート（NemoClaw）](https://www.cyera.com/research/nemoclaw-one-website-visit-to-hijack-your-ai-agent)
- [Kubernetes v1.37 公式 CHANGELOG](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.37.md)
