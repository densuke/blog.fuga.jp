---
title: "「入れた瞬間」に何が起きる? Flatpakの権限処理とMCPの認証抜け、手渡しの一瞬を守れるか（2026/9/30 Linux・OSSトレンド）"
date: 2026-09-30T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Flatpak", "MCP", "OAuth", "Python", "simdjson", "C++", "Godot", "動画編集", "NVIDIA", "Wayland"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

インストール、認証、画面の切り替え。どれも一瞬で終わる操作ですが、その一瞬に誰へ何を手渡しているのかを取り違えると、そこが弱点になります。今日はその「手渡しの一瞬」を軸に、Flatpak と MCP の Python SDK という危ない話2本で、simdjson・GoZen・NVIDIA の前向きな話3本を挟みました。

{{< youtube "Rt5lVKYtiZ8" >}}

## 1. Flatpak 1.18.4 — インストール時に任意ファイルを削除・上書きされる穴など、6件のCVEを修正

最初は Flatpak です。[リリースノート](https://github.com/flatpak/flatpak/releases/tag/1.18.4)によると、2026年9月28日に公開された 1.18.4 には、CVE-2026-97023・97024・97025・97026・97027・97029 の6件のセキュリティ修正が入っています。97028 は欠番です。

動画タイトルでは「入れた瞬間にroot権限」と言いましたが、正確には少し違います。リリースノートの表現は "Prevent privileged deletion/overwrite of arbitrary files when a malicious app is installed" です。つまり **悪意あるアプリをインストールさせると、root 権限で動く処理に任意のファイルを削除・上書きさせられる** という穴で、攻撃者が root シェルを取ったりコードを実行したりするものではありません。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-97023) には、システム全体へのインストールでは削除・上書きが root として実行される、と書かれています。CVSS v3.1 では 97023・97024 がそろって **7.1（High）** です。

修正の中身は、パス名を文字列として扱うのをやめ、ファイルディスクリプタを基準にした操作（fd-relative operations）へ切り替えるものです。[97024 のアドバイザリ](https://github.com/flatpak/flatpak/security/advisories/GHSA-8xgq-v545-vgvf)によれば、修正コミットは `01cd7c4b`・`cc3ab6ab` です。97024 で狙われうるのは `passwd`・`group`・`machine-id` という名前のファイルで、これらは空にされます。`resolv.conf` という名前のファイルは `/run/host/monitor/resolv.conf` へのシンボリックリンクに差し替えられる可能性があります。ただしアドバイザリは "It is not believed to be possible to replace these files with attacker-chosen content." と注記しており、好きな内容を書き込めるわけではありません。

残る4件は深刻度が低〜中です。97025・97026 は CVSS v4 で **2.4（Low）** 、97027 は CVSS スコアが付いておらず、Low 評価のみです。97029 だけは CVSS v4 で **5.1（Medium）** で、アドバイザリには "when running under GNOME Shell, the Flatpak app can terminate the shell, causing the desktop session to end" という例が書かれています。あくまで GNOME Shell での一例です。あわせて、バンドルされている `xdg-dbus-proxy` も 0.1.9 へ更新され、CVE-2026-94422 が修正されました。

前提として、この穴を突くにはまず悪意あるアプリをインストールまたはアップグレードさせる必要があります。リリースノートのワークアラウンドも "Avoid installing Flatpak apps from untrusted publishers, especially system-wide." で、信頼できない配布元からのインストールを避けるのが対策です。この件は [NixOS の nixpkgs でも issue #568123](https://github.com/NixOS/nixpkgs/issues/568123) として追跡されています。対象は 1.18.4 未満を使っている環境なので、まずは `flatpak --version` で手元を確かめておきましょう。

## 2. simdjson 5.0 — C++26のスタティックリフレクションが正式機能に、数値ファイルで最大25%高速化

2本目は明るい話です。[simdjson 5.0 のリリースノート](https://github.com/simdjson/simdjson/releases/tag/v5.0.0)（2026年9月28日公開）には "Static reflection is no longer guarded and is an officially supported feature." とあり、C++26 のスタティックリフレクションが正式にサポートされる機能になりました。GCC 16 なら `g++ -std=c++26 -freflection` でリフレクションを有効にして、構造体と JSON の受け渡しをコンパイラに任せられます。グルーコードを手で書かずに済むのが、いちばん大きな変化です。

`rename`・`rename_all`・`alias`・`skip` といったアノテーションも追加され、フィールド名と JSON のキー名がずれていても対応できます。読みたいキーを指定する key selector 機能については、リリースノートが "simdjson builds a perfect hash function for your set of keys. At run time, recognizing a key takes a hash computed from a couple of bytes and one comparison." と説明しています。ハッシュ計算1回と比較1回でキーを特定できる、という意味で、「コストがゼロ」というわけではありません。使い方は、公式ドキュメントの [basics.md](https://raw.githubusercontent.com/simdjson/simdjson/master/doc/basics.md) にある `Car c = doc.get<Car>();` のように、テンプレート引数で型を渡す形です。

性能面では、数値中心のファイル（canada・marine_ik・mesh・numbers）が8〜25%速くなりました。エスケープされた Unicode 文字を多く含む twitterescaped というファイルは、1.59 GB/s から 2.85 GB/s へ約1.8倍（リリースノートの表現では "almost twice as fast"）です。リリースノートによると、"among other changes"、つまりほかの変更と並んで、連続する `\uXXXX` シーケンスをまとめて処理するようにしたことが効いています。シリアライズ側でも、古い数値変換アルゴリズムの Grisu2 を Dragonbox に置き換え、canada で 0.31 から 0.52 GB/s へ改善しました。計測は GCC 16.1（`-O3`）でビルドし、Intel Xeon Gold 6548N（Emerald Rapids）で行ったもので、[開発者 Daniel Lemire 氏のブログ](https://lemire.me/blog/2026/09/28/simdjson-5-0-is-out/)にも同じ条件と数値が載っています。

ほかにも、`[2^64, 10^20)` の範囲の正の整数を `BIGINT_NUMBER` として報告するようになった変更や、RFC 7464 対応、NaN/Infinity の扱い、C++20 ranges 対応、Windows でのメモリマップファイル対応が入っています。simdjson は Node.js・ClickHouse・Apache Doris などで使われているプロジェクトで、Lemire 氏はケベック大学（TELUQ）の教授です。元になった論文 "Parsing Gigabytes of JSON per Second" は学術誌 The VLDB Journal（2019年）に掲載されています。

## 3. GoZen 0.14 — Godot製の動画エディタがアルファからベータへ

3本目は少し肩の力を抜いて、動画編集ツールの話です。Godot エンジンと FFmpeg を組み合わせた動画編集ソフト「GoZen」が、2026年9月27日に v0.14 を公開し、アルファからベータへ進みました。[Codeberg のリポジトリ](https://codeberg.org/gozen/gozen)で公開されたリリースノートによると、変更規模は "264 changed files with 8 360 additions and 10 158 deletions!" で、削除行数が追加行数を上回っています。ベータ期間については "The main focus for the upcoming beta releases will be bug fixing and adding quality of life features." とあり、今後はバグ修正と使い勝手の改善が中心になるようです。

新機能としては、Glow・Scroll・Shear・Shake・Glitch の5つのエフェクトが加わり、Angle パラメータのコントロールや、プロジェクトファイルにモジュールのバージョン情報を保存する「モジュールバージョニング」も入りました。配布は Linux 向け AppImage・Windows・macOS の3系統で、本体のライセンスは GPLv3 です。動画の再生は [gde_gozen](https://codeberg.org/gozen/gde_gozen) という GDExtension が受け持っていて、README には "provides video playback for all kinds of video formats... thanks to using the power of FFmpeg" とあります。Godot が標準で再生できる動画形式は Theora だけなので、この GDExtension のおかげで mp4 なども扱えるようになる、という位置づけです。

価格は、[itch.io の配布ページ](https://voylin.itch.io/gozen/devlog/1679004/version-014-beta)を見ると定価16ドルが25%オフで12ドル、というセール表示でした。v1.0 に到達したら Steam 版も出す予定とのことですが、時期は書かれていません。開発の拠点は GitHub から Codeberg へ移ったようで、GitHub 側のリポジトリは1年以上更新が止まっています。ゲームエンジンの上に動画編集ツールを作るという発想がそもそも面白くて、ベータでどこまで安定するのか個人的にも気になっています。

## 4. NVIDIA Display Config Server — ディスプレイを「所有して貸し出す」設計

4本目は XDC 2026（X.Org Developers Conference）からの話題です。9月28〜30日に[トロントで開催された XDC 2026](https://www.khronos.org/events/xdc-2026) で、NVIDIA のエンジニア Austin Shafer 氏が「Next Generation Display Walls on Linux」というセッションを行いました。[pbxscience の記事](https://pbxscience.com/nvidia-unveils-display-config-server-to-bring-wayland-era-linux-to-professional-display-walls/)によると、コードは NVIDIA の GitHub でオープンソースとして公開される予定ですが、記事の時点ではまだ公開されていません。

テーマはディスプレイウォール、つまり複数のディスプレイを組み合わせて1つの大画面のように扱う用途です。設計の核は、サーバーがディスプレイを "own"（所有）し、それを Vulkan クライアントへ "lease"（リース）として貸し出すモデルです。各アプリが表示設定のロジックを個別に持たずに済むのが狙いです。記事は "seamless handoff between clients"、つまりクライアント間で表示をシームレスに切り替えられる点も挙げています。ちなみに Vulkan には、ウィンドウシステムを介さずに物理ディスプレイを直接扱う [VK_KHR_display](https://github.com/KhronosGroup/Vulkan-Docs/blob/main/appendices/VK_KHR_display.adoc) という拡張があり、仕様には "Displays are independent of any windowing system in use on the system." と書かれています。

記事によれば、要求の厳しいディスプレイウォールは今も多くが Windows 上で動いていて、Linux で使われる場合は X.Org Server と NVIDIA Mosaic の上に構築されていることが多いそうです。Display Config Server は、Mosaic が担ってきた用途を Wayland 時代に移すための設計、と見るのがよさそうです。AI 以外の分野での NVIDIA の Linux への取り組みとしても注目です。

## 5. MCP Python SDK — フォールバック経路で認証サーバーの確認が抜けていた

最後はセキュリティの話に戻ります。MCP（Model Context Protocol）の Python SDK に見つかった脆弱性 [GHSA-qx49-fqc8-xw99](https://github.com/modelcontextprotocol/python-sdk/security/advisories/GHSA-qx49-fqc8-xw99) です。CVE 番号は割り当てられておらず、GHSA 番号だけで管理されています。発見したのはセキュリティ企業の Cycode で、[同社のブログ](https://cycode.com/blog/mcp-python-sdk-oauth-account-takeover/)は攻撃チェーンをエンドツーエンドで実演したとしています。

影響範囲は2系統で、中身も違います。1.9.1〜1.29.1 は、どの経路でも認証サーバーの `issuer` を検証しておらず、資格情報の紐付けもありませんでした。2.0.0〜2.1.1 は、サーバーが保護リソースのメタデータを公開していない場合（レガシーのフォールバック経路）と、403 insufficient_scope を返した場合に限って同じ穴がありました。修正版は 1.x 系が 1.30.0、2.x 系が 2.2.0 です。深刻度は High で、非対話型のプロバイダー（`ClientCredentialsOAuthProvider`・`PrivateKeyJWTOAuthProvider`）は CVSS **7.5** です。対話型の `OAuthClientProvider` はユーザー操作（UI:R）が要る分、 **6.5** になります。CWE は CWE-345 と CWE-522 です。非推奨の 1.x 系 `RFC7523OAuthClientProvider` も対象で、こちらは `issuer` を指定するオプション自体がなく、アドバイザリは上の2クラスへの移行を勧めています。

2.x 系の核心は、[v2.2.0 のリリースノート](https://github.com/modelcontextprotocol/python-sdk/releases/tag/v2.2.0)にある "checks the authorization server's `issuer` on the legacy path too" という一文です。裏を返せば、これまではレガシー（フォールバック）経路だけ `issuer` のチェックが素通りしていました。Cycode の言葉を借りれば "The check doesn't fail. It never runs."、チェックは失敗するのではなく、そもそも実行されていませんでした。動画の章タイトルの「404ひとつで」も、Cycode が説明する攻撃の起点に対応しています。攻撃者のサーバーがまず404を返し、クライアントがフォールバックして偽のログイン設定を検証なしで受け入れてしまう、という流れです。Cycode によると、これでクライアントのシークレット、認可コード、PKCE の proof key（code_verifier）までまとめて奪われ得ます。なお、本稿執筆時点で実際の悪用報告は見当たりません。

対処はアップグレードだけでは終わらない点に注意が必要です。非対話型の2クラスについて、アドバイザリは "upgrading changes nothing until you also pass `issuer=` (for example `issuer="https://auth.example.com"`)" と明記しています。発行者を明示的に指定して初めて対策になり、将来の 3.0 ではこの `issuer=` が必須になる予定です。また、アップグレード後に保存済みの OAuth クライアント登録を一度クリアするよう求められています。逆に対象外なのは、stdio トランスポートを使うクライアント、SDK で作った MCP サーバー側の実装、独自にトークンやヘッダーを付けるクライアントです。HTTP 経由で OAuth クライアント機能を使っているなら、バージョンと `issuer=` の指定の両方を確認しておきましょう。

## まとめ

今日の5本は、「一瞬の受け渡し」に注目すると輪郭がはっきりします。Flatpak ではアプリを受け取って設置する処理で、root 権限で動く部分に任意のファイルを削除・上書きさせられました。MCP の Python SDK では、認証サーバーを確かめるはずのチェックが、フォールバック経路だけ抜けていました。どちらも普段通る経路ではなく、例外的にしか通らない経路で確認が抜けていた、というのが個人的には一番の共通点だと思います。例外経路の確認漏れは見つけにくいものです。まずは手元の Flatpak と MCP 関連ライブラリのバージョンを確認するところから始めてみてはいかがでしょうか。

## 参考リンク

- [Flatpak 1.18.4 リリースノート](https://github.com/flatpak/flatpak/releases/tag/1.18.4)
- [simdjson 5.0.0 リリースノート](https://github.com/simdjson/simdjson/releases/tag/v5.0.0)
- [GoZen（Codeberg）](https://codeberg.org/gozen/gozen)
- [NVIDIA Display Config Server（pbxscience）](https://pbxscience.com/nvidia-unveils-display-config-server-to-bring-wayland-era-linux-to-professional-display-walls/)
- [MCP Python SDK Security Advisory GHSA-qx49-fqc8-xw99](https://github.com/modelcontextprotocol/python-sdk/security/advisories/GHSA-qx49-fqc8-xw99)
