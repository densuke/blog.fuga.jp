---
title: "パスワード使い回しで FortiGate 86,644台が侵害（FortiBleed）、OpenSSH 10.6 のポスト量子署名と LZ77 無効化、Raspberry Pi Desktop の PC・Mac 版更新、Linux カーネルの AutoFDO・Propeller と PGO、Pwn2Own Ireland 2026（2026/10/9 Linux・OSSトレンド）"
date: 2026-10-09T00:00:00+09:00
draft: false
tags: ["セキュリティ", "Fortinet", "FortiGate", "OpenSSH", "ポスト量子暗号", "Raspberry Pi", "Debian", "Linux カーネル", "Clang", "Pwn2Own", "AI"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

最新の防御機器が、新しい脆弱性ではなくパスワードの使い回しで破られました。最先端の AI ツールも、引数インジェクションという古典的な入力処理のミスで攻略されています。今日の5本は「昔ながらの宿題が勝負を分けている」という見立てで並べました。

共通点の指摘は書き手の考察です。動画で一次情報と食い違った発言や裏付けの取れなかった発言は、各節末の「動画の訂正」にまとめました。

{{< youtube "BKPJpAeRPDg" >}}

## 1. FortiBleed — FBI と米シークレットサービスの共同勧告、FortiGate 86,644台

10月6日、FBI と米シークレットサービス（USSS）が共同で、[JCSA-20261006-01 の勧告](https://www.ic3.gov/CSA/2026/261006.pdf)を出しました。表題は "FortiBleed Operations Continue Targeting Exposed Systems Leading to Reports of Lockouts" です。勧告は、調査会社 SOCRadar の検証として、194カ国で86,644台超の侵害されたデバイスを挙げています。

名前から Heartbleed のような新しい脆弱性を想像しがちですが、勧告の説明は違います。FortiBleed は、使い回されたり漏れたりした認証情報と、古い SHA-256 のパスワード保存を突く、世界規模の認証情報侵害キャンペーンだとしています。[Security Boulevard の解説](https://securityboulevard.com/2026/10/fortibleed-safebreach-coverage-for-joint-cybersecurity-advisory-jcsa-20261006-01/)によれば、勧告は CVE 番号を挙げていません。

手口の流れは次のとおりです。

- 入口: インターネットに公開された FortiGate と SSL VPN のゲートウェイに、クレデンシャルスタッフィング（漏れたログイン情報の組をそのまま試す手口）とパスワードスプレー（よくあるパスワードを多数のアカウントに薄く試す手口）を仕掛けました。材料は、過去の Fortinet 関連の漏洩データと、情報窃取マルウェアのログだったとされています。
- 侵入後: 機器から FortiOS のユーザーデータベースとセッショントークンを抜き、パスワードのハッシュを GPU のクラスタでオフライン解析しました。
- 居座り: 機器に無かったアカウントを新しく作り、場合によっては既存のアカウントを削除して、組織を機器から締め出しました。勧告は、通常のパッチ適用やパスワードリセットを超える対応が必要になりうると述べています。

入口は売られてもいます。勧告によると、初期アクセスブローカーが FortiBleed の攻撃連鎖で得たアクセスを、ランサムウェアの提携者に渡しています。[The Register](https://www.theregister.com/security/2026/10/07/fortibleed-still-a-bleeding-nuisance-as-fbi-confirms-ongoing-attacks/5301585) は、SOCRadar が7月の時点で、FortiBleed に由来する確認済みのランサムウェア攻撃を少なくとも12件把握していたと伝えています。

勧告は、米国の重要インフラ16分野すべてに当てはまるとしています。CISA は[6月18日付けのアラート](https://www.cisa.gov/news-events/alerts/2026/06/18/cisa-urges-hardening-fortinet-devices-after-reports-credential-exposure)で防御強化を呼びかけていましたが、勧告によれば、攻撃者は漏洩済みの認証情報で公開中の Fortinet のファイアウォールをスキャンし続けています。

今日やることは、勧告に沿って整理できます。

1. FortiOS の更新と PBKDF2 への移行: [Fortinet の KB](https://community.fortinet.com/fortigate-3/technical-tip-enforcing-pbkdf2-as-hash-function-for-administrator-accounts-in-fortios-v7-2-11-and-later-220652) によれば、7.2.11・7.4.8・7.6.1 以降で、管理者の認証情報の保存が SHA256 から PBKDF2 に変わります。ただし、その管理者が一度ログインに成功するまで、パスワードは SHA256 のままです。更新しただけでは終わりません。
2. 管理者アカウントの棚卸し: 勧告は、ファイアウォールと VPN のユーザーや設定に不正な変更がないかを見直し、見覚えのないアカウントの追加に特に注意するよう求めています。
3. フィッシング耐性のある MFA: 勧告は、すべてのリモートアクセスと管理者アカウントに必須とし、外部ゲートウェイと管理画面で強制するよう求めています。FIDO2 はその代表例ですが、勧告の文言は "phishing-resistant" までです。
4. 外部からの管理の制限: 勧告は、trusted hosts（良い）、local-in ポリシー（より良い）、インターネットからの管理を無くす（最良）の順で絞るよう勧めています。

地味な手口ほど、昔どこかで漏れたパスワードが1つ残っているだけで通ってしまいます。管理画面と VPN のパスワードの使い回しを、今日一度洗い出しておくのがいちばん効きそうです。

動画の訂正です。

- 動画では「攻撃者はGPUを約45枚束ねたクラスタで、毎秒およそ26億回のペースで解析したとされています」と紹介しましたが、勧告は「GPU の分散クラスタ」とするだけで、枚数も毎秒の回数も書いていません。勧告が引く分析でも枚数は36枚と約45枚で揺れ、毎秒の回数はどの資料にも見当たらず、確認できませんでした。
- 動画では「工場出荷時の状態に戻して、ファームウェアを書き込み直すところからです。設定も一から作り直しになります」と紹介しましたが、勧告にこの復旧手順の記述は確認できませんでした。勧告が述べているのは、通常のパッチ適用とパスワードリセットを超える対応が必要になりうる、という点までです。
- 動画では「実際に、MSPが管理する複数の顧客のFortiGateが、連鎖的に侵害されたケースも確認されています」と紹介しましたが、勧告や取得できた報道に該当する記述が無く、確認できませんでした。
- 動画では「FIDO2のようなハードウェアトークンが推奨されています」と紹介しましたが、勧告が推奨しているのはフィッシング耐性のある MFA で、FIDO2 やハードウェアトークンの語は確認できませんでした。
- 動画では「VPNの内側や踏み台サーバー経由からだけ触れるように絞ることが推奨されています」と紹介しましたが、勧告の推奨は上の4のとおりで、VPN の内側や踏み台サーバーという記述は確認できませんでした。

## 2. OpenSSH 10.6 — ポスト量子署名の有効化と、LZ77 辞書コーダの無効化

[OpenSSH 10.6](https://www.openssh.org/txt/release-10.6) は2026年10月6日にリリースされました。柱は、ポスト量子の署名と圧縮の見直しの2本です。

署名について、リリースノートは "All: enable hybrid post-quantum ssh-mldsa44-ed25519 signature algorithm." と書いています。ML-DSA と Ed25519 を組み合わせたハイブリッドで、片方が破られても、もう片方が残る設計です。ML-DSA は、NIST が [FIPS 204](https://csrc.nist.gov/pubs/fips/204/final) として標準化した、格子（Module-Lattice）ベースの署名方式です。

鍵交換は一足先でした。[OpenSSH のポスト量子のページ](https://www.openssh.org/pq.html)によると、mlkem768x25519-sha256 は2025年4月の10.0 から既定です。「今盗んで、量子コンピューターが実用化したら解読する」攻撃への備えが、鍵交換、署名の順に揃ってきた形です。

実験版の鍵には注意が要ります。[10.4 のリリースノート](https://www.openssh.org/txt/release-10.4)に、ML-DSA 44 と Ed25519 の複合署名の実験的サポートと、`ssh-keygen -t mldsa44-ed25519` での鍵生成が出てきます。10.6 のノートは、実験版が使っていた "@openssh.com" の接尾辞を使わなくなったとし、"Keys generated with the previous experimental support must be regenerated and/or removed." と書いています。10.4 で試した人や CI で鍵を自動生成した人は、手元とサーバーの鍵を見直しておくと安心です。

警告の設定もあります。10.6 では WarnWeakCrypto が sshd_config にも追加されました。ノートには "This option was previously available for the client only." とあり、既定で有効で、クライアントがポスト量子安全でない鍵交換を使うとログに残ります。クライアント側（ssh_config）には、pq.html によれば10.1 の時点でこの警告があります。ssh-keygen の鍵 KDF の既定ラウンド数も、24から32に上がりました。

圧縮の話のきっかけは、論文 ["Crossing the Streams"](https://arxiv.org/abs/2609.07709) です。アブストラクトによると、1本の SSH 接続の中で多重化される全チャンネルが、同じ圧縮コンテキストを共有しています。圧縮が有効なとき、攻撃者はチャンネルに部分的に選んだ平文を注入し、暗号文の長さをネットワーク上で観測することで、中身を推測できます。

10.6 のノートは、この漏えいを抑えるため "disable LZ77 dictionary coder" としています。同時に "This change will reduce the effectiveness of the Compression option." と、圧縮の効果が下がることも認め、可能ならアプリケーション層の圧縮を使うよう勧めています。自分の `Compression` の設定と、細い回線での体感を確かめておくのが現実的です。

もう1つ、気になる断り書きがありました。OpenSSH チームは "a large number of security bug reports, many of which are findings from AI models or made with AI assistance" を受け取っているそうです。そのため当面は、次の計画リリースまで修正をためず、より頻繁にリリースするとしています。また、コマンドラインで指定した宛先のユーザー名にバックスラッシュやドル記号が含まれると、拒否されるようになりました（設定ファイルの User は対象外）。

量子という先端の備えと、圧縮という昔からの便利機能の見直しが同じ版に並んでいるのは、書き手としても面白く感じました。

動画の訂正です。

- 動画では「通信の圧縮機能を止めたことです」と紹介しましたが、リリースノートが無効にしたのは LZ77 辞書コーダで、圧縮機能そのものを止めたとは書かれていません。ノートが述べているのは、Compression オプションの効果が下がる、という点です。
- 動画では「実質的には無圧縮になります」と紹介しましたが、リリースノートには "This change will reduce the effectiveness of the Compression option." とあるだけで、無圧縮になるとの記述は確認できませんでした。

## 3. Raspberry Pi Desktop — PC・Intel Mac 向けの更新と Raspberry Pi Connect

Raspberry Pi の PC・Intel Mac 向けデスクトップが、Debian 13 "Trixie" ベースに更新されました。[公式の発表](https://www.raspberrypi.com/news/raspberry-pi-desktop-now-available-for-pc-and-mac/)は "finally got the latest version of the Desktop running on top of a Debian Trixie image" と書いています。[OS のダウンロードページ](https://www.raspberrypi.com/software/operating-systems/)によると、PC・Mac 版のカーネルは Linux 6.12、イメージの日付は10月5日、サイズは2,616MB で、SHA256 のハッシュ値も載っています。

直前の PC 向け更新は、[The Register が2022年に報じた](https://www.theregister.com/2022/07/11/raspberry_pi_desktop_update/) Debian 11 ベースの32ビット版でした。間が空いた理由を、公式の発表は "we simply didn't have time to release any newer versions." と説明しています。同じ発表で、Raspberry Pi は本体の販売で収益を得ており、ソフトウェアには課金してこなかったとも述べています。

今回から64ビット（amd64）専用です。発表によれば、Debian 自身が PC 向けの32ビットのサポートをやめたためです。過去15年ほどに作られた PC の大半と、Intel ベースの Mac の大半で動くとされています。一方、Apple Silicon は Debian の対応がまだ実験段階で、対象外です。

試し方は2通りあります。.iso を USB メモリに書き込んで起動する方法と、デスクトップのショートカットなどから標準のインストーラー Calamares を実行して、ストレージに入れる方法です。

注目は Raspberry Pi Connect です。発表によると、Connect のクライアントが入り、画面共有やリモートターミナルが使えます。[Connect のページ](https://www.raspberrypi.com/connect/)には "No ports to open, no network configuration required." とあり、個人向けは "free forever" で "Unlimited devices" です。組織向けは1台あたり月0.50ドルです。ポートを開けずに済むぶん、アカウントの守りは大事になります。1本目の話の直後だけに、パスワードの使い回しは避けたいところです。

土台の Debian 13 では、time_t が64ビットになりました。[Raspberry Pi OS Trixie の発表](https://www.raspberrypi.com/news/trixie-the-new-version-of-raspberry-pi-os/)は、カレンダーが "sometime around the year 292,277,026,596" までオーバーフローしないと書いています。約2922億年先です。同じ発表は設定アプリを Control Centre に集約したと書いており、PC・Mac 版の発表によれば、PC・Mac 版にも Control Centre と新しいドックが入っています。

新しいものを買わなくても、手元の古い PC に一仕事させられるのは、素朴にうれしい話です。

動画の訂正です。

- 動画では「PCとIntel Mac向けに約8年ぶりの大型更新を迎えました」と紹介しましたが（トピック紹介の「8年ぶり復活」と画面の「約8年ぶり更新」も同様です）、直前の PC 向け更新は2022年の Debian 11 ベース版で、約8年も空いてはいませんでした。公式の発表にも年数の記述はありません。
- 動画では「Raspberry Pi財団の本業はPi本体の販売なので、PC版に割ける人手は限られていました」と紹介しましたが、[財団のブログ](https://www.raspberrypi.org/blog/what-would-an-ipo-mean-for-the-raspberry-pi-foundation/)によれば、Pi 本体の設計・製造・流通を担うのは Raspberry Pi Ltd で、教育目的の慈善団体である財団ではありません。公式の発表も主語は "we"（Raspberry Pi）で、エンジニアリングチームの仕事が多く、新版を出す時間が取れなかったという説明でした。
- 動画では「Simon Longさんも、今後も継続してリリースしていくと明言しています」と紹介しましたが、発表のコメント欄で Simon Long 氏が書いたのは "We can't make any promises, but the intention is to continue to support and release it." で、約束はできないが継続する意向がある、という趣旨でした。

## 4. Linux カーネルの AutoFDO・Propeller と PGO — Google の LPC 2026 での発表

10月5日、プラハで開かれた Linux Plumbers Conference 2026 で、Google のエンジニアが ["Advancing PGO, AutoFDO, and Propeller in the Linux Kernel"](https://lpc.events/event/20/contributions/2396/) を発表しました。

3つとも、プログラムが実際にどう動いたかの記録を使って、コンパイラの最適化を助ける技術です。

- AutoFDO: [カーネルのドキュメント](https://docs.kernel.org/dev-tools/autofdo.html)によれば、ハードウェアのサンプリングを perf で変換してプロファイルを作ります。x86_64 は LBR、arm64 は SPE か ETM を使います。
- Propeller: [ドキュメント](https://docs.kernel.org/dev-tools/propeller.html)によると、プロファイルの情報をリンクの直前に使い、とくにブロックの配置を最適化します。

この2つは Linux 6.13 でメインラインに入っています。[Kbuild の 6.13 向け pull request](https://lkml.rescloud.iu.edu/2411.3/06598.html) に Clang の AutoFDO と Propeller のサポート追加が並び、[KernelNewbies](https://kernelnewbies.org/Linux_6.13) は6.13 の公開日を2025年1月19日としています。AutoFDO は LLVM 17 以降、Propeller は LLVM 19 以降の Clang が必要で、設定名も `CONFIG_AUTOFDO_CLANG` と `CONFIG_PROPELLER_CLANG` です。このサポートは、Clang でビルドするカーネルが対象です。

発表の概要によれば、新しい点の1つはカーネルモジュールです。既存の仕組みはどれもモジュールに対応しておらず、モジュールは Google のサーバーでカーネルのサイクルの4〜5%を使っている、と概要は述べています。PGO については、ツリー外では使えるが、本流には統合されていないと説明しています。

PGO の経緯も確かめました。2021年、Linux 5.14 向けの [Clang 機能アップデートの pull request](https://lkml.iu.edu/hypermail/linux/kernel/2106.3/04330.html) に PGO が含まれていました。Linus Torvalds 氏の返信は、サンプルデータではなく Clang の計装を使っていること、そのためカーネルが大きく遅くなること、perf のプロファイルから変換できる仕組みがあるのに使われていないことを指摘するものでした。その後、PGO の部分はこの pull request から外されました。

効果の数字は、[パッチのカバーレター](https://patchew.org/linux/20241102175115.1769468-1-xur@google.com)で確認できます。

- Neper というネットワークのベンチマークで、AutoFDO の最適化により、スループットが6.1%向上、レイテンシが10.6%短縮しました。カーネル 6.9.x の AutoFDO 最適化イメージを、標準のビルドと比べた実験です。
- AutoFDO と Propeller を合わせた効果は、マイクロベンチマークで最大10%、大規模な warehouse-scale のベンチマークで最大5%です（[LWN の転載](https://lwn.net/Articles/992751/)でも確認できます）。いずれもベンチマーク上の最大値です。

自分の環境に当てはめるなら、Clang でカーネルをビルドしているか、CPU が必要な計測機能を持つかの確認が先です。AutoFDO のドキュメントは、AMD では Zen3 の BRS か Zen4 の amd_lbr_v2 を挙げています。

一度は本流に入らなかったものを、別の道で本流に入れ、その先でまた挑戦する。派手さはなくても、こうした積み重ねがカーネルを速くしていくのだと思います。

動画の訂正です。

- 動画では「すでに入ったAutoFDOとPropellerのパッチでは」と紹介し、画面にも「参考: AutoFDO+Propellerの実測」と出しましたが、ネットワークのベンチマークでの6.1%向上と10.6%短縮は、カバーレターでは AutoFDO の最適化の結果として書かれており、Propeller には触れていません。

## 5. Pwn2Own Ireland 2026 — AI 関連の標的、Galaxy S26、プリンターやスマート家電

Zero Day Initiative（ZDI）のハッキングコンテスト Pwn2Own Ireland 2026 は、10月8日の Day 3 で最終エントリーを終えました（[Day 3 の結果](https://www.thezdi.com/blog/2026/10/8/pwn2own-ireland-2026-day-three-results-amp-master-of-pwn)）。同じブログによれば、Master of Pwn は Ikotas Labs に決まりました。[Day 2 のブログ](https://www.zerodayinitiative.com/blog/2026/10/7/pwn2own-ireland-2026-day-two-results)は、1日目に32件のユニークなゼロデイに38万8,500ドルを支払ったと書いています。

目を引くのは AI 関連の標的です。[ZDI の7月の告知](https://www.zerodayinitiative.com/blog/2026/7/21/pwn2own-ireland-2026-new-targets-and-categories)によれば、AI インフラの標的は Berlin 大会で導入され、Ireland 大会に再登場しました。[ルール](https://www.zerodayinitiative.com/Pwn2OwnIreland2026Rules.html)の AI Infrastructure には Chroma、Postgres pgvector、Oracle Autonomous AI Database、LiteLLM、Dynamo が並び、OpenAI Codex は別の AI Coding Agents のカテゴリです。結果は次のとおりです（出典は [Day 1](https://www.thezdi.com/blog/2026/10/6/pwn2own-ireland-2026-day-one-results) から Day 3 の各ブログ）。

- LiteLLM: Day 1 に、不適切な入力検証のバグとコードインジェクションを使った成功がありました。
- OpenAI Codex: Day 1 に、たった1件の引数インジェクションのバグで攻略され、賞金は4万ドルでした。引数インジェクションは、外から渡した文字列が、内部で呼ぶコマンドの引数として解釈されてしまう脆弱性です。
- Oracle Autonomous AI Database: Day 1 に5件のバグを連鎖させた成功があり、Day 2 と Day 3 にも別のチームが成功しています。
- NVIDIA Dynamo: Day 2 に、境界外（Out of Bounds）のバグで4万ドルの成功がありました。
- Chroma: 失敗が2件ある一方、衝突（既知のバグとの重複）を含む成功が2件出ました。

Samsung Galaxy S26 は、日ごとに数えるのが確実です。成功は Day 1 に3件、Day 2 に3件、Day 3 に1件の計7件でした。Day 1 の3件は、いずれも既知のバグとの衝突を含んでいます。

ほかにも、次の結果が出ています。

- Lexmark CX532adwe プリンター: Day 1 に2件、Day 2 に3件、Day 3 に1件の、計6件の成功がありました。
- Sonos Era 300: 書き込みの境界外とフォーマット文字列のバグの組み合わせで、5万ドルでした。
- Philips Hue Bridge Pro: 7件のゼロデイを連鎖させた成功で、4万ドルでした。

ルールによれば、見つかった脆弱性は影響を受けるベンダーに開示されます。参加には、原則として ZDI から累計1万5千ドル以上の報奨金を受け取っている必要があります。

利用者の側でできるのは、ベンダーの案内を追い、パッチが出たらすぐ当てることです。自分で立てて動かしている AI ツールは、更新が手動になりがちです。AI ツールに渡す入力のチェックと、サンドボックスでの隔離も根本的な守りになります。最新の AI エージェントでも、穴の種類は昔からある入力処理のミスでした。

動画の訂正です。

- 動画では「スマートフォンでは、Samsung Galaxy S26が、大会を通じて計6回も攻略されました」と紹介し、画面にも「Galaxy S26: 計 6回 攻略」と出しましたが、ZDI の結果ブログでは、成功は Day 1 に3件、Day 2 に3件、Day 3 に1件の計7件でした。6回は Day 1 と Day 2 だけの数です。
- 動画では「今回の目玉は、新しく設けられたAIインフラのカテゴリです」と紹介し、画面にも「新設: AIインフラ部門」と出しましたが、ZDI の告知では、AI インフラの標的は Berlin 大会で導入済みで、Ireland に再登場したものでした。また、動画で「LLMのプロキシや、コーディングエージェント、ベクターデータベースといった」とまとめたうち、OpenAI Codex などのコーディングエージェントは、AI インフラではなく AI Coding Agents のカテゴリです。

## まとめ

使い回しのパスワードと古いハッシュで破られた FortiGate、量子対策と同時に圧縮を見直した OpenSSH、手元の古い PC に戻ってきた Raspberry Pi Desktop、一度は本流に入らなかった最適化に再挑戦する Google、引数インジェクションで攻略された AI ツール。最新の看板の裏では、基本の手入れが勝負を分けていました。

今日できることは3つです。FortiGate を使っているなら、管理者アカウントの棚卸しと MFA の見直し。OpenSSH を使っているなら、`Compression` の設定と、10.4 の実験版で作った鍵の確認。自分で立てている AI ツールがあるなら、更新状況の確認です。皆さんの現場では、どれがいちばん手つかずですか。

## 参考リンク

- [FBI・USSS 共同勧告 JCSA-20261006-01（IC3）](https://www.ic3.gov/CSA/2026/261006.pdf)
- [OpenSSH 10.6 リリースノート](https://www.openssh.org/txt/release-10.6)
- [Raspberry Pi Desktop の PC・Mac 版の発表](https://www.raspberrypi.com/news/raspberry-pi-desktop-now-available-for-pc-and-mac/)
- [LPC 2026: Advancing PGO, AutoFDO, and Propeller in the Linux Kernel](https://lpc.events/event/20/contributions/2396/)
- [ZDI: Pwn2Own Ireland 2026 Day 3 の結果](https://www.thezdi.com/blog/2026/10/8/pwn2own-ireland-2026-day-three-results-amp-master-of-pwn)
