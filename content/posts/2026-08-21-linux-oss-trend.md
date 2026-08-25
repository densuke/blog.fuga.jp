---
title: "9年物の時限爆弾から pnpm の大改造まで — 今日は「作り直し」が5つ重なった日（2026/8/21 Linux・OSSトレンド）"
date: 2026-08-21T00:00:00+09:00
draft: false
tags: ["セキュリティ", "Windows", "CVE", "CISA KEV", "Go", "ポスト量子暗号", "Linux カーネル", "Fedora", "pnpm", "Rust"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

古い設計をそのまま延命させるか、思い切って捨てて作り直すか。今日並べた5本は、その決断が重なった一日の記録です。9年前のコミットに眠っていた欠陥がようやく塞がれ、9年前に決めた API 設計そのものが段階的に廃止されようとしている一方で、あるパッケージマネージャは実装言語を丸ごと Rust に置き換えるという荒療治に踏み切りました。

面白いのは、その「作り直し」の粒度がまるで揃っていないことです。関数ひとつの所有権管理を直せば済むものもあれば、カーネルの API をひとつ丸ごと畳もうとしているものもあり、言語ごと乗り換えたものもある。直さず作り直す、という選択が、セキュリティと開発者ツールの両方で同時に起きた日です。

{{< youtube "zrUTGuySAS4" >}}

## 1. VPN の鍵交換サービスに Double Free — CVE-2026-33824、連邦機関の修正期限は本日

まずはいちばん重い話から。Windows の IKE（Internet Key Exchange）サービス拡張に存在する二重解放（Double Free）の脆弱性、CVE-2026-33824 が [CISA の既知悪用済み脆弱性（KEV）カタログ](https://www.cisa.gov/news-events/alerts/2026/08/18/cisa-adds-four-known-exploited-vulnerabilities-catalog)へ 2026年8月18日付で追加されました。連邦行政機関への修正期限は BOD 26-04 の適用によりまさに本日、2026年8月21日に設定されています。

[NVD のエントリ](https://nvd.nist.gov/vuln/detail/CVE-2026-33824)に載っている評価は、次のような並びです。

| 項目 | 値 |
|---|---|
| CVSS v3.1 基本スコア | **9.8（Critical）** |
| 攻撃元区分（Attack Vector） | ネットワーク |
| 攻撃条件の複雑さ（Attack Complexity） | 低 |
| 必要な権限（Privileges Required） | なし |
| ユーザー関与（User Interaction） | 不要 |
| スコープ | 変更なし |
| 機密性 / 完全性 / 可用性への影響 | 高 / 高 / 高 |
| 脆弱性タイプ | CWE-415（Double Free） |

上から下まで、条件がいちばん緩い側に振り切っています。ネットワークから届きさえすれば、認証もユーザーの操作も要らずにコードが動く、という構成です。

脆弱なのは IKE and AuthIP IPsec Keying Modules サービス（IKEEXT）、VPN や IPsec ポリシーが有効な Windows で既定稼働している基盤サービスです。原因は IKEv2 のフラグメント再組み立て処理にあります。`IkeHandleSecurityRealmVendorId()` がヒープ確保したポインタを構造体のオフセット `0x208` に格納したあと、`IkeReinjectReassembledPacket()` によるシャローコピーで同じポインタがオフセット `0xC8` にもエイリアス（同一アドレスへの別参照）として残ってしまう。さらに `IkeQueueRecvRequest()` がその構造体をヒープ上の作業アイテムへもう一度浅くコピーするため、同じアドレスを指す参照が複数の場所にばらまかれた状態になります。そのままクリーンアップ処理に入ると、`IkeDestroyPacketContext()` と `IkeFreeMMSA()` が独立に同じ領域を解放してしまい、Double Free が完成します。

コピーそのものは高速化のための素直な実装です。ただ「このポインタを最後に解放するのは誰か」という取り決めだけが、コピーの回数ぶん曖昧になっていきました。

攻撃者からすれば、必要なのはパケット2本だけです。まず Microsoft Security Realm Vendor ID を含む `IKE_SA_INIT` メッセージを送り、続いて不正な `IKE_AUTH` メッセージを内包した暗号化フラグメント（SKF）ペイロードを2個以上含む断片化パケットを送る。これが UDP 500（IKE）または UDP 4500（NAT-T IKE）に到達すれば、認証なしで SYSTEM 権限でのコード実行が成立します。

対象は広く、NVD が挙げているのは Windows 10（1607・1809・21H2・22H2）、Windows 11（22H3・23H2・24H2・25H2・26H1）、そして Windows Server 2016 以降のサーバー系すべて。要するに、現在サポート中の Windows はひととおり含まれると考えたほうが早い範囲です。

ワーム化のしやすさについては、[ZDI の技術解析ブログ](https://www.zerodayinitiative.com/blog/2026/4/22/cve-2026-33824-remote-code-execution-in-windows-ikev2)にも評価が載っていますが、この記事では NVD の SSVC（Stakeholder-Specific Vulnerability Categorization）の確定値だけを根拠にします。`automatable: yes`（攻撃の自動化が可能）、`technicalImpact: total`（技術的影響は完全）という評価と、ネットワーク越し・未認証・ユーザー操作不要という CVSS 9.8 の構成そのものが、拡散のしやすさを物語っています。構造としては、2017年に WannaCry を引き起こした MS17-010（EternalBlue）と似た輪郭を持ちます。認証不要のネットワーク越し RCE という点は共通していて、狙われる窓口が SMB のポート 445 ではなく IKE の UDP 500/4500 である、という違いです。VPN の待ち受けはインターネットに向けて開けておくのが前提の機能なので、公開面という意味ではむしろ広いかもしれません。実際、GitHub 上には公開 PoC が複数確認されています。

そして、これが机上の心配で済んでいないことを示す観測もあります。[Palo Alto Networks Unit 42 の調査](https://unit42.paloaltonetworks.com/autonomous-ai-cyber-attack-campaign/)では、中国系とされる脅威アクター「knaithe」（別名 KnYuan、珠海拠点）の存在が報告されています。このアクターは DeepSeek の Hermes Agent を中核に据えた自律型攻撃基盤を構築し、FOFA サーチエンジンによる列挙とカスタム Python スキャナーを組み合わせて 460 拠点以上を標的選定していたとのことです。同レポートには CVE-2026-33824 も名指しで登場し、3件の IKE VPN エンドポイントを標的としたリバースシェルの接続試行が確認された、と分類されています。侵入に至ったという記述ではありませんが、少なくともこの CVE は、いま実地で試されている番号です。修正期限が本日という事実と並べると、締切の重みが少し違って見えてきます。

標的スキャンからエクスプロイトの生成・検証までを AI が半自律で担うという、2026年らしい攻撃キャンペーンの姿がここに現れています。人手で1件ずつ調べていた偵察が自動化されると、「うちみたいな小さいところは後回しだろう」という前提が効かなくなる、というのがこの手の話のいちばん怖いところです。

対応の最優先は 2026年4月14日に配信された累積セキュリティ更新プログラム（4月の月例更新）の適用です。すぐに当てられない場合の暫定策としては、次のあたりが挙げられます。

```bash
# VPN や IPsec ポリシーを使っていない環境なら、IKEEXT 自体を止めてしまう
sc stop IKEEXT
sc config IKEEXT start= disabled
```

あわせて、境界ファイアウォールで UDP 500/4500 のインバウンドをブロックする、IPsec が届く ACL / NSG を洗い直す、といった手当ても有効です。ただしこれらはあくまで一時しのぎで、恒久的な対策はパッチ適用にあります。VPN を止められない環境では、結局そこに戻ってきます。

## 2. Go 1.27 リリース — ポスト量子署名がついに標準ライブラリへ

続いては、少し前向きな話です。2026年8月19日、[Go 1.27 が正式リリース](https://go.dev/blog/go1.27)されました。柱は3つあります。

ひとつめは、FIPS 204 準拠のポスト量子署名アルゴリズムを実装する新パッケージ [`crypto/mldsa`](https://pkg.go.dev/crypto/mldsa) の追加です。ML-DSA（Module-Lattice-Based Digital Signature Algorithm）は NIST が 2024年に標準化した格子暗号ベースの署名方式で、量子コンピュータ上の Shor アルゴリズムに耐性を持ちます。強度に応じて3つの変種が用意されています。

| 変種 | 公開鍵サイズ | 署名サイズ | 用途 |
|---|---|---|---|
| MLDSA44 | 1312 バイト | 2420 バイト | 一般用途（推奨） |
| MLDSA65 | 1952 バイト | 3309 バイト | 高強度 |
| MLDSA87 | 2592 バイト | 4627 バイト | 最高強度 |

これらは `crypto/x509` と `crypto/tls` に統合され、TLS 1.3 のハンドシェイクで利用可能になりました。Go 1.26 で先に ML-KEM（鍵交換、FIPS 203）が入っていたので、今回の ML-DSA（署名）が加わったことで「鍵交換 ＋ 署名」の両方がポスト量子対応になったことになります。背景にあるのは、今日の TLS 通信を録音しておいて将来の量子コンピュータで復号する「Harvest Now, Decrypt Later」への懸念です。壊れるのは10年後かもしれませんが、盗まれるのは今日である、という理屈で動いている話です。

利用にあたっては注意点があります。既存の TLS 設定を変えなければ従来の ECDSA/RSA が使われ続けるオプトイン方式で、切り替えるには `crypto/tls` で ML-DSA の `SignatureScheme` 値（MLDSA44/65/87）を明示する必要があります。鍵交換用の `Config.CurvePreferences` は署名の設定経路ではないので、間違えないようにしたいところです。

サイズにも目を配っておきたいところです。MLDSA44 の公開鍵はおよそ 1312 バイトで、RSA-2048 の公開鍵（294 バイト）の約4.5倍。署名は 2420 バイトで、RSA 署名の約10倍にあたります。サーバー同士の通信ならほぼ誤差ですが、細い回線の先にいるモバイルや IoT デバイスでは、ハンドシェイク1回あたりの往復量として効いてくる可能性があります。

ふたつめは「ジェネリックメソッド（Generic Methods）」の解禁です。Go 1.18 でのジェネリクス導入から4年越しの機能追加で、これまで型パラメータを持てるのはパッケージレベルの関数か型そのものだけでした。その結果、型ごとに同じようなメソッドを並べるボイラープレートが定番になっていました。

```go
// Go 1.26 まで：整数型ごとに個別のメソッドが必要だった
func (r *Rand) Int32N(n int32) int32
func (r *Rand) Int64N(n int64) int64
func (r *Rand) IntN(n int) int

// Go 1.27：ジェネリックメソッドで一本にまとまる
func (r *Rand) N[Int intType](n Int) Int
```

実際に `math/rand/v2` の `(*Rand).N` がこの形で書き換わっています。ただし制限もあって、インターフェースのメソッド宣言には型パラメータを付けられないため、ジェネリックメソッドでインターフェースを実装することはできません。同時に関数型推論の汎用化も入り、複合リテラル・型変換・チャネル送信でジェネリック関数の型引数を省略できるようになりました。

先送りされてきた理由は型推論エンジンの複雑化とインターフェースとの整合性で、Go チームは3年ほどかけて型推論と型チェッカーを強化し、今回ようやく解禁に踏み切りました。既存コードへの破壊的影響はほぼありませんが、`reflect.Value.Pointer()` でクロージャのポインタ比較をしていたコードは、コンパイラが複数インスタンスを同一コードへマージするようになった影響で挙動が変わる可能性があります。

みっつめは新 JSON エンジン [`encoding/json/v2`](https://pkg.go.dev/encoding/json/v2) と `encoding/json/jsontext` のバンドルです。構成は2層で、上位の `encoding/json/v2` は `Marshal` / `Unmarshal` に可変長の `Options` 引数を足して挙動を細かく制御できるようにしたもの。下位の `encoding/json/jsontext` は、ステートマシンで妥当性を保証しながら低レベルのトークンや値のストリームを扱う層です。既存の `encoding/json` は API 互換を保ったまま内部実装だけを v2 エンジンへ差し替えており、アンマーシャル速度が大きく向上しています。

注意したいのはデフォルト挙動の厳格化で、不正な UTF-8 を含む文字列やオブジェクト内の重複キーはエラーになります。これまで黙って通っていた JSON が急に弾かれる可能性がある、ということです。`GOEXPERIMENT=nojsonv2` で旧エンジンに戻すか、v2 の `Options` で v1 相当のセマンティクスを明示すれば回避できます。

地味なところでは、メモリアロケータの改善も入りました。80 バイト未満の小さなオブジェクトにサイズ特化のアロケーションを導入し、アロケーションコストを最大30%削減しています。全体では約1%と控えめですが、小さなオブジェクトを大量に作るワークロードでは効いてくるかもしれません。なお macOS の最低要件が macOS 13 Ventura に引き上げられているので、古い macOS 環境でのビルドには注意してください。

## 3. カーネルの暗号ソケットが静かに閉じていく — Fedora 45 の AF_ALG 段階制限

ここからは少しペースを落として、地味だけれど構造的な話をお届けします。Linux カーネルの暗号ユーザー空間 API「AF_ALG」が、CVE-2026-31431（通称 Copy Fail、CVSS 7.8 HIGH）という深刻なローカル権限昇格の温床となったことを受け、Fedora 45 が AF_ALG を既知の正規ユーザーだけに限定する「Phase 1」の Change を正式承認しました。

AF_ALG は、ユーザー空間プロセスがカーネル内部の暗号アルゴリズムエンジン（`algif_aead`、`algif_skcipher`、`algif_hash` など）を直接呼び出せるようにするソケット型 API です。ソケットを開いてアルゴリズム名をバインドすると、あとは普通のソケットのように読み書きするだけで暗号処理ができる、という設計になっています。導入当初の目的は、ハードウェア暗号アクセラレータの恩恵をユーザー空間へゼロコピーで橋渡しすることにありました。

Copy Fail の根本原因は、2017年のコミット（`72548b093ee3`）にさかのぼります。AEAD 復号処理で出力スキャッターリストをページキャッシュのページへ直接チェーンする最適化が、そのまま攻撃の足がかりに転用されてしまいました。攻撃の流れは次のとおりです。

1. `socket(AF_ALG, SOCK_SEQPACKET, 0)` で AF_ALG ソケットを開き、`authencesn(hmac(sha256),cbc(aes))` をバインドする
2. `splice()` で `/usr/bin/su` のページキャッシュのページをパイプへ流し込む
3. `sendmsg()` と `recvmsg()` の組み合わせで AEAD 復号の出力先をそのページキャッシュへ向け、AAD の4〜7バイト目から供給した4バイトの値を任意の位置に書き込む
4. SUID バイナリのメモリ内イメージが書き換わる（ディスクには一切書き込まれない）
5. 改ざんされた `/usr/bin/su` を実行して root シェルを取得する

不気味なのは、この一連の流れが `socket` / `setsockopt` / `splice` / `sendmsg` / `recvmsg` という標準的なシステムコールだけで完結する点です。実装は 732 バイトの Python スクリプトに収まっており、しかも既定のカーネル設定で有効なアルゴリズムしか使いません。つまり `CONFIG` を触っていない大半のディストリビューションが、そのままの状態で対象になります。さらにディスクには書き込まれないため、ファイル内容のチェックサム検証では捉えにくいという厄介さもあります。

CISA は 2026年5月1日にこれを KEV カタログへ登録し、連邦機関への修正期限を5月15日に設定しました。影響範囲はカーネル 4.14（2017年）以降のうち、パッチ未適用のバージョンです。5.10.254・5.15.204・6.1.170・6.6.137・6.12.85・6.18.22 以上の安定版はすでに修正済みで対象外なので、まずは自分の環境がこの線を越えているかどうかを確認するのが早道です。ディストリビューション側では Ubuntu 20.04〜24.04、Amazon Linux 2023、RHEL 10.1、SUSE Linux Enterprise 16、Debian 11/12/13 などで影響が確認されています。

上流の対応も着実に進んでいます。Linux 7.2 では AF_ALG の公式非推奨化が宣言され、ゼロコピーサポートとオフ CPU ハードウェアオフロード機能が削除されました。[Phoronix の報道](https://www.phoronix.com/news/Linux-AF-ALG-Deprecation)によれば、カーネル開発者の Eric Biggers 氏は、AF_ALG が巨大な攻撃面を露出させており、現代の脆弱性発見ツールに耐えられていない、と述べています。機能として不要になったから消すのではなく、割に合わないから消す、という判断です。

続く [Linux 7.3 では、新しい sysctl `af_alg_restrict` が導入](https://www.phoronix.com/news/AF-ALG-Restrict-Sysctl-Linux)され、締め方を3段階から選べるようになりました。

| 値 | 挙動 |
|---|---|
| 0 | 無制限（従来どおり） |
| 1 | 非特権プロセスにはアルゴリズムのホワイトリストを適用 |
| 2 | 完全に無効化 |

そして今回の Fedora 45 の Change は、[「Disable in Kernel Crypto Userspace API (Phase 1)」（バグ #2517963）](https://bugzilla.redhat.com/show_bug.cgi?id=2517963)として承認されたもので、`CRYPTO_USER_API` を iwd や libkcapi、cryptosetup といった少数の正規パッケージだけに限定するというものです。「Phase 1」と名付けられていることから、将来的な完全無効化（Phase 2）を見据えた段階的な廃止ロードマップであることがうかがえます。

ここで気になるのは巻き添えの範囲ですが、dm-crypt/LUKS・kTLS・IPsec・OpenSSL・GnuTLS・SSH といった主要な暗号実装の多くは AF_ALG に依存しておらず、影響は限定的とみられます。ディスク暗号化も HTTPS も SSH も、AF_ALG を経由せずに暗号処理を行っているためです。つまり大多数のユーザーにとって、AF_ALG の廃止は体感する機会がほぼない変更だと言えそうです。攻撃面だけが大きく、使っている人は少ない。畳むという判断が通りやすい条件がそろっています。

即時の緩和策としては、`algif_aead` がモジュールになっている環境なら、次のように無効化する方法があります。

```bash
# モジュールとしてビルドされている場合
echo 'install algif_aead /bin/false' | sudo tee /etc/modprobe.d/disable-algif.conf
sudo rmmod algif_aead

# カーネル組み込みの場合（RHEL / CloudLinux 等）は起動引数で初期化を止める
sudo grubby --update-kernel=ALL --args="initcall_blacklist=algif_aead_init"
```

とはいえ恒久対策は、修正済みカーネル（7.0 以降、または 6.19.12 / 6.18.22 以上）へのアップデートです。Arch Linux や Debian、Ubuntu でも同様の制限措置が検討・実施されつつあり、Fedora の Change はその先頭を走っている格好になります。

## 4. 安定版カーネル 7 系統が一斉リリース — Thunderbolt と BPF の修正が目玉

2026年8月19日、Linux 安定版メンテナの Greg Kroah-Hartman（GKH）氏が [7.1.9・6.18.45・6.12.104・6.6.152・6.1.183・5.15.216・5.10.265 の7系統を一斉に公開](https://www.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.1.9)しました。各リリースに「重要な修正が含まれる」と告知されており、7本合計の ChangeLog 容量は約 3.7 MB にのぼります。7.1 系は今後 LTS ブランチとして 2028年12月まで継続サポートされる見込みです。

技術的なハイライトはふたつあります。ひとつは Thunderbolt の境界値チェック修正で、こちらは2件入りました。

1件目は帯域幅グループ予約配列の off-by-one です（コミット `0a8c9ed4f166`）。Thunderbolt コントローラは USB4/Thunderbolt 4 のトンネリング帯域を `group_reserved[]` という配列で管理していますが、有効なグループ ID が 1〜MAX_GROUPS であるのに対して配列は `MAX_GROUPS` 個ぶんしか確保されていませんでした。ID が MAX_GROUPS のとき、配列の末尾を1要素ぶん超えて書き込んでしまいます。修正では配列サイズを `MAX_GROUPS + 1` に広げました。1から数えるか0から数えるかという、古典的な取り違えです。

2件目は DROM（Device ROM）のポート番号に対する境界検証の追加です（コミット `f32c3a9a77cf`）。Thunderbolt デバイスが持つ DROM の `dual_link_port_nr` フィールド（6ビット値）が、そのまま `sw->ports[]` 配列のインデックスとして使われていました。悪意あるデバイスが最大ポート数を超える値を書き込んでいれば、範囲外アクセスが起きます。修正では `dual_link_port_nr >= max_port_number` のときに当該エントリを拒否するチェックが加わりました。要するに、挿しただけでカーネルを落とせる可能性のあった欠陥です。公共の充電ステーションや共有ドックを使う環境では、意味のある修正だと言えます。

もうひとつは BPF sockmap の Use-After-Free 修正です（コミット `1cec526cf0a2`）。`tcp_bpf_send_verdict()` は `psock->sk_redir` にキャッシュしたリダイレクト先ソケットの参照を使いますが、ソースソケットのロックを解放したあと、別スレッドがそのキャッシュをクリアして `sock_put()` で最終参照を落としてしまうと、最初のスレッドは解放済みのポインタを使い続けることになります。修正ではロック保持中に `sock_hold()` で一時参照を取得し、送信完了後に `sock_put()` で解放する実装へ変更されました。eBPF の socket redirect を活用するサービスメッシュ的な構成では、クラッシュにつながりうる不具合だったため、該当する eBPF 依存の観測・通信基盤を動かしている環境では優先的な適用をおすすめします。ChangeLog は修正内容を示すのみで緩和策の有無には触れていないため、確実な対処としては更新の適用をおすすめします。

BPF まわりでは fsverity 関連も2件直りました。ダイジェスト取得時にバッファが小さいと切り捨てたうえで成功を返していた問題（不完全なダイジェストのまま整合性検証が通ってしまう、という嫌な穴です）は `-EOVERFLOW` を返すよう改められ、`arg->digest_size` への並行アクセスが競合しうる問題は検証済みの `hash_alg->digest_size` を使うよう変更されました。このほか SCTP でも、ASCONF（Address Configuration Change）チャンクのライフサイクル管理に関する Use-After-Free が4件修正されています。マルチホーミングで IP アドレスを動的に追加・削除する際のレース条件が中心です。

適用対象は幅広く、次のような分布になります。

| バージョン | 主な利用先 |
|---|---|
| 7.1.9 | Fedora 43 以降・Arch Linux・openSUSE Tumbleweed などのローリングリリース系 |
| 6.18.45 | Fedora 42、Ubuntu 26.04 開発版 |
| 6.12.104 | Debian 14 候補、Ubuntu 25.04 |
| 6.6.152 / 6.1.183 | RHEL 互換系（AlmaLinux 9 等）・組み込み Linux・NAS アプライアンス |
| 5.15.216 / 5.10.265 | Android の Generic Kernel Image・産業用 IoT 機器 |

アップデートまでのつなぎとしては、Thunderbolt については信頼できないデバイスを接続しないこと、BIOS/UEFI の Thunderbolt セキュリティレベルを "User Authorization" に設定しておくことが有効です。それと、[5.10 と 5.15 は 2026年12月に EOL を迎える予定](https://www.kernel.org/releases.html)なので、そろそろ次のブランチへの移行計画を立てておく時期です。Android の Generic Kernel Image や産業用機器のように更新サイクルの長い領域ほど、この期限は早めに意識しておいたほうがよさそうです。

## 5. pnpm v12 RC — Rust への完全書き直しで warm install が約29倍に

最後は、開発者ツール側の大きな作り直しです。JavaScript エコシステムの主要パッケージマネージャ pnpm が、バージョン 12 でインストールエンジンを TypeScript/Node.js 実装から Rust（コードネーム「pacquet」）へ書き直しました。2026年8月12日に RC4、8月18日に RC7 が公開されており、RC フェーズが着実に進行しています。

[pnpm 公式ベンチマークページ](https://pnpm.io/benchmarks)によれば、数字は次のように動きました。

| シナリオ | pnpm v11 | pnpm v12（Rust） | 改善 |
|---|---|---|---|
| warm install（キャッシュ・node_modules ともにある状態） | 517ms | 18ms | **約29倍** |
| クリーンインストール | 8秒 | 2秒 | 約4倍 |

「30倍」という表現を見出しで見かけることもありますが、公式ベンチマークの確定値としては約29倍が実測に近い数字です。

warm install がこれほど劇的に縮むのは、この処理が実質「既存の `node_modules` のツリーを再検証するだけ」だからです。やることが少ないぶん、固定費の割合が大きい。従来は Node.js 上の TypeScript で動いていたため、コマンドを叩くたびに Node.js ランタイムの起動コスト（100ms 超）を払っていました。v12 はプラットフォーム別のネイティブバイナリ（Linux x64/ARM64・macOS x64/ARM64・Windows x64）として配布されるため、この起動オーバーヘッドがまるごと消えます。517ms のうちかなりの部分が「起動して、それから仕事を始める」ための時間だった、というわけです。

つまり、CI 環境で `pnpm install --frozen-lockfile` を毎回実行しているプロジェクトほど、この差はビルド時間の短縮に直結します。数百ミリ秒の話ではありますが、1日に何十回も走るジョブの先頭に必ず付いてくる固定費だと考えると、印象が変わってくるはずです。

今回の書き直しは、[pnpm 公式ブログ](https://pnpm.io/blog/whats-different-in-pnpm-12)の説明によれば、pnpm CLI を TypeScript から Rust へ移植したもので、挙動・フラグ・既定値・エラーコード・ファイル形式・ディレクトリ配置が既存の pnpm と一致するよう設計されています。Rust 側のインストールエンジンは「fetch（パッケージの取得）」と「link（ファイルシステムへのハードリンク展開）」の両フェーズを担当します。CLI・lockfile フォーマット（`pnpm-lock.yaml`）・`node_modules` のレイアウトは v11 との互換性が保たれており、既存プロジェクトの多くは設定変更なしで移行できる見込みです。循環依存の多い構成では、ピア依存の解決が2〜3倍速く、メモリ使用量も約25%減るという報告もあります。

ここまで来るのに時間はかかっています。pacquet は当初 `pnpm/pacquet` という独立したリポジトリで開発され、ロードマップは3段階で設計されました。`--frozen-lockfile` でのヘッドレスインストール、完全な依存関係解決、そして `run` や `publish` といった非インストール系コマンドの移植です。v11.2 でオプトインのバックエンドとして試験導入が始まり、2026年7月21日には pacquet リポジトリが本体の `pnpm/pnpm` へ統合されてアーカイブ化されました。

破壊的な変更は最小限に抑えられています。`sudo` 経由での `pnpm setup` / `pnpm self-update` が `ERR_PNPM_SUDO_NOT_SUPPORTED` でエラーになる、v11→v12 の git tarball 移行コードが削除される、スコープなし認証設定が拒否されレジストリへの紐付けが必須になる、という3点が主なところです。加えて `--resolution-only` フラグは `pnpm peers check` に統合されました。`.npmrc` にレジストリ指定なしの認証情報を書いているチームは、ここだけ事前に直しておく必要があります。

試すのは簡単で、いま入っている pnpm から次のコマンドを叩くだけです。

```bash
# 現在インストール済みの pnpm から v12 RC へ切り替える
pnpm self-update next-12

# または npm から直接入れる
npm install -g pnpm@next-12
```

TypeScript compiler の Go 移植や Yarn の Rust 書き直しといった動きと並べると、JavaScript ツールチェーンが「JavaScript 自身から離れる」トレンドの中でも、pnpm v12 は象徴的な一歩だと言えそうです。Node.js のために作られたパッケージマネージャが、Node.js を使わずに動くようになった。ただし RC フェーズである以上、本番環境への適用は正式リリースまで待つのが無難で、CI での試験的導入から始めるのがよさそうです。

## まとめ

今日並べた5本を振り返ると、「作り直す」という決断の重さの違いが見えてきます。Windows の IKE 拡張は、9年越しの設計ミスが二重解放という形で表面化し、パッチという小さな作り直しで塞がれました。Fedora の AF_ALG 制限は、ひとつの API をまるごと段階的に畳んでいく、もっと大きな作り直しです。そして pnpm は、実装言語そのものを置き換えるという、いちばん思い切った作り直しに踏み切りました。Go 1.27 の ML-DSA も、量子コンピュータという未来の脅威に備えて暗号の土台を差し替えていく作業の一部です。

古いコードを直しながら使い続けるか、根本から作り直すか。その判断の分かれ目は、たいてい「攻撃面がどれだけ広がっているか」と「作り直すコストに見合うだけの恩恵があるか」のふたつで決まります。IKE の二重解放は直すしかなく、AF_ALG は使っている人が少ないから畳めて、pnpm の Rust 化は速度という明確な恩恵がありました。それぞれの理由をたどってみると、なるほど今日はこの5本が並ぶ日だったのだと納得できます。

今日のところは、CVE-2026-33824 の修正期限が本日であるという1点だけ持ち帰ってください。残りは週末にでも。

## 参考リンク

- CVE-2026-33824 NVD 詳細: https://nvd.nist.gov/vuln/detail/CVE-2026-33824
- Microsoft MSRC 公式アドバイザリ: https://msrc.microsoft.com/update-guide/vulnerability/CVE-2026-33824
- CISA KEV 登録アラート 2026-08-18: https://www.cisa.gov/news-events/alerts/2026/08/18/cisa-adds-four-known-exploited-vulnerabilities-catalog
- Palo Alto Networks Unit 42 調査（自律型 AI 攻撃キャンペーン）: https://unit42.paloaltonetworks.com/autonomous-ai-cyber-attack-campaign/
- ZDI 技術解析ブログ（CVE-2026-33824）: https://www.zerodayinitiative.com/blog/2026/4/22/cve-2026-33824-remote-code-execution-in-windows-ikev2
- Go チーム公式リリースブログ: https://go.dev/blog/go1.27
- Go 1.27 公式リリースノート: https://go.dev/doc/go1.27
- crypto/mldsa パッケージドキュメント: https://pkg.go.dev/crypto/mldsa
- encoding/json/v2 パッケージドキュメント: https://pkg.go.dev/encoding/json/v2
- NIST FIPS 204 最終標準: https://csrc.nist.gov/pubs/fips/204/final
- CVE-2026-31431 NVD 詳細: https://nvd.nist.gov/vuln/detail/CVE-2026-31431
- CERT-EU Advisory 2026-005: https://cert.europa.eu/publications/security-advisories/2026-005/
- Fedora 45 ChangeSet（Phase 1 Change）: https://fedoraproject.org/wiki/Releases/45/ChangeSet
- Red Hat Bugzilla #2517963（Fedora 45 Change の追跡バグ）: https://bugzilla.redhat.com/show_bug.cgi?id=2517963
- Phoronix: Linux 7.2 AF_ALG 非推奨化: https://www.phoronix.com/news/Linux-AF-ALG-Deprecation
- Phoronix: Linux 7.3 af_alg_restrict sysctl: https://www.phoronix.com/news/AF-ALG-Restrict-Sysctl-Linux
- kernel.org 公式トップページ: https://www.kernel.org/
- 7.1.9 ChangeLog: https://www.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.1.9
- 6.18.45 ChangeLog: https://www.kernel.org/pub/linux/kernel/v6.x/ChangeLog-6.18.45
- カーネルリリーススケジュール・LTS EOL 日程: https://www.kernel.org/releases.html
- pnpm 公式ブログ（v12 変更点）: https://pnpm.io/blog/whats-different-in-pnpm-12
- pnpm 公式ベンチマークページ: https://pnpm.io/benchmarks
- GitHub 公式リリース（RC0 リリースノート）: https://github.com/pnpm/pnpm/releases/tag/v12.0.0-rc.0
- pnpm v12 Discussion: https://github.com/orgs/pnpm/discussions/11292
- pacquet リポジトリ: https://github.com/pnpm/pacquet
