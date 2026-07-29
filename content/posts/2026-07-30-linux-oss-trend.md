---
title: "製品が届く前に、ドライバはもうカーネルにいた — 準備を先に済ませたOSSたち（2026/7/30 Linux動向）"
date: 2026-07-30T00:00:00+09:00
draft: false
tags: ["gccrs", "Rust", "Linux Kernel", "Arch Linux", "Zig", "FreeBSD", "Wayland", "hwmon"]
categories: ["Linux・OSSトレンド"]
---

ふつう物事の順番は「まず出す、あとで整える」ですよね。でも今週のOSS界隈は逆で、出す前にコンパイラやドライバといった足場をせっせと組んでいた側の話が目立ちました。GCCにRustフロントエンドを作る地道な作業から、発売前にLinuxカーネルへドライバを送り込んでしまったファンコントローラーまで、5本まとめてお届けします。

{{< youtube "5rQt_Po7HVM" >}}

## 1. gccrs — GCCのRustフロントエンドがLinuxカーネル対応で前進

「rustcが動かないアーキテクチャでもRustを書きたい」。GCCに独立したRustフロントエンドを作るgccrsプロジェクトの動機はここにあります。[LWNの記事](https://noise.getoto.net/2026/07/28/progress-toward-compiling-linux-with-gccrs/)によれば、2026年前半はRust for Linuxのカーネルクレート対応に開発リソースを集中投下してきたそうです。

1月から5月にかけて名前解決の仕組みを刷新（名前解決2.0）、2月にはcfg-strippingを2パス化、3月には`compiler_builtins`と`builder_error`が0%から100%に到達、6月にはメタデータのexport/importをASTベースへ全面改修しつつGeneric Associated Types（GAT）を完全サポート。地味な積み重ねですが、[gccrs 6月月次レポート](https://raw.githubusercontent.com/Rust-GCC/Reporting/refs/heads/main/2026/2026-06-monthly-report.org)によるとRust-for-Linuxの進捗指標は1月の12%から6月末に40%まで上がっています。半年で3倍以上というのは、地道な作業の割になかなかの伸びだと素直に思いました。

ただ、この40%という数字にはちょっと注意が要ります。「コンパイルを試みられる」段階を示す自己申告指標であって、「カーネルの4割がGCCでビルドできる」わけではありません。同じ月次レポートでも後期名前解決が28%、型チェックが12%とまだボトルネックが残っていて、コンパイルが通ることとバイナリが正しく動くことは別問題です（gccrs がどういう立ち位置のプロジェクトなのかは[Rust for Linux公式のgccrs説明ページ](https://rust-for-linux.com/gccrs)にまとまっています）。派手な見出しになりがちな数字ほど、こういう注釈をちゃんと添えたいところです。開発チームは9月のRustConf 2026（モントリオール）での発表を目標に逆算しながら進めているとのこと——あくまで目標であって、発表が確定した話ではありません。

## 2. Shelly 3.0.0 — Arch LinuxのGUIパッケージマネージャがZigで書き直し

Arch Linux向けGUIパッケージマネージャ「Shelly」が、[9to5Linuxが伝えたところによると](https://9to5linux.com/shelly-3-0-gui-package-manager-for-arch-linux-released-as-a-major-update)バージョン3.0.0で大幅刷新されたそうです。従来のC#/.NETランタイム依存を捨て、システムプログラミング言語Zigでフルスクラッチ再実装したとのこと。正直、「ZigでGTK4のGUIアプリをまるごと書き直す」と聞いた瞬間は半信半疑でした。C#/.NETのランタイムオーバーヘッドが課題だったのは分かるにしても、乗り換え先がZigというのはなかなか思い切った選択です。

技術面では、Arch Linuxのパッケージ管理ライブラリlibalpmやGTK4、libarchive、GPGをネイティブバインディングで直接呼び出す設計に変わったとのこと。新機能としてAUR検索の並列実行、Flatpakリポジトリのバックエンド対応、グリッド表示とリスト表示を切り替えられる新UIが加わっています。起動速度と実行ファイルサイズが大幅に改善されたと報じられていますが、具体的な倍率やサイズの数字までは出てきませんでした。

というのも、この話題は9to5Linuxの報道1本だけが根拠で、今回GitHubリリースのような一次資料は確認できていません。技術的にはワクワクする話なんですが、裏取りの層が薄い分、鵜呑みにしすぎず「へー、そうなんだ」くらいの温度で聞いておくのがちょうどいいと思います。

## 3. FreeBSD Q2-2026ステータスレポート — NTSYNCとROCm移植が進行中

FreeBSDプロジェクトが公開した2026年第2四半期のステータスレポートには41件のエントリが並びますが、目玉は2つです。[レポート本文](https://www.freebsd.org/status/report-2026-04-2026-06/)によると、Konstantin Belousov氏がWindowsの同期プリミティブを扱うNTSYNCドライバを、Linuxのコードを一切流用せずスクラッチで実装しました。[Linux公式のNTSYNCドキュメント](https://docs.kernel.org/userspace-api/ntsync.html)で定義されているLinux 7.0-rc3のインターフェースに互換性を持たせており、`/dev/ntsync`経由でセマフォ・ミューテックス・イベントの3種を扱えます。ネイティブのFreeBSD ABIと、Linuxバイナリをそのまま動かすための`linux_ntsync` shimの両方に対応しているのが芸が細かいところです。

ちなみにLinux側では、NTSYNCを使ったWineやProtonでDirt 3が110fpsから860fpsへ、Resident Evil 2が26fpsから77fpsへ改善したという報告があります。数字だけ見ると派手ですが、これはあくまでLinux側のNTSYNCで観測された数値であって、FreeBSD実装のベンチマークではありません。FreeBSD版が同じだけ効くかどうかはまだ分からない、というのは正直に書いておきます。

もうひとつの注目はAMD ROCmの移植です。FoundationインターンのSourojeet Adhikari氏が[ROCmの公式Issue](https://github.com/ROCm/ROCm/issues/1913)のもとで作業中で、当面の目標は「ROCmでベクター加算を動かすこと」。地味な目標に聞こえますが、ROCmのスタックはかなり巨大なので、完成までにはまだ時間がかかりそうです。ほかにFramework Laptop対応の更新やIntel Panther LakeのI2C/SMBusサポート、Realtek RTL8159の10GbE動作確認なども含まれていて、この四半期のFreeBSDは地味に忙しかったようです。

## 4. Wayfire 0.11 — 分数スケーリング精度向上と実験的HDR対応

wlrootsベースのWaylandコンポジター「Wayfire」が0.11をリリースしました。……と、ここで正直に告白すると、リリース日を確定させるのにけっこう手間取りました。日付の記載が7月27日と7月28日で分かれていて、肝心の[公式ブログ](https://wayfire.org/2026/07/24/Wayfire-0-11.html)は2026年7月24日付。3つの日付が並んでしまって「どれが本当なんだ」とちょっと混乱しました。無理に一つに決めるくらいなら、「7月下旬」とぼかしておくほうが誠実だと判断しています。

中身は日付争いとは裏腹に地に足のついた改善ぞろいです。内部のジオメトリ処理を整数から浮動小数点へ切り替えたことで、125%・150%・175%といった分数スケーリング時の丸め誤差が解消され、XWaylandアプリのHiDPI対応も自動で効くようになりました。もうひとつの目玉がHDR出力への初対応です。ただしデフォルトでは無効の実験的機能で、完全なカラーマネージドHDRパスにはVulkanレンダラーが必要だと公式ブログに書かれています。まだ「使える」と無条件には言えない段階ですね。

per-outputのICCプロファイルやper-surfaceのカラーマネジメントも実装され、新しいWaylandプロトコルも6種類追加されました。[GitHubのリリースページ](https://github.com/WayfireWM/wayfire/releases/tag/v0.11.0)には、wf-shellのGTK4移植や再起動不要でプラグインを切り替えられる`wayfire-plugin`コマンドの追加も記載されています。開発チームはこれを「1.0前の最後の計画版」と位置づけているようです。2023年にRaspberry Pi OSに採用され、2024年末にはLabwcへ乗り換えられてしまった経緯もあるプロジェクトなので、この地道な仕上げっぷりには勝手に肩入れしたくなります。

## 5. ARCTIC Fan Controller — 発売前にLinuxカーネルへドライバを寄贈済み

締めはいちばん気に入っている話です。冷却製品メーカーのARCTICが、10チャンネルUSBファンコントローラー「ACFAN00351A」（$9）を発売するにあたり、自社社員Aureo Serrano de Souza氏がhwmonドライバを書き上げ、[Linuxメインラインへのマージコミット](https://github.com/torvalds/linux/commit/fc2ce3ee106f2d53eb344f5c4963c897bbb21634)を経てLinux 7.2に取り込んでから製品を出荷しました。ファンコントローラーのベンダーがここまでやるのは珍しいと思います（「業界初」とまでは言い切れませんが、少なくとも見た記憶がありません）。

ドライバはUSB Custom HID（VID 0x3904 / PID 0xF001）を採用し、`drivers/hwmon/arctic_fan_controller.c`は約300行、変更ファイルは6件・451行追加でGPL-2.0-or-laterで公開されています。sysfsは`fan[1-10]_input`（読み取り専用・約1Hz更新）と`pwm[1-10]`（0〜255・読み書き可）を提供する標準的なhwmonインターフェースです。デバイス側からINレポートが約1秒ごとに自動送信される一方、PWM変更にはOUTレポートとACK応答（タイムアウト1000ms）が使われます。ただし`GET_REPORT`には対応していないため、起動直後の現在PWM値は読み出せず、書き込みが一度発生するまで初期状態は不明という、地味だけど覚えておきたい制約もあります。

[パッチ投稿](https://lore.kernel.org/r/20260508064405.38676-1-aureo.serrano@arctic.de)が2026年5月8日、hwmonメンテナのGuenter Roeck氏によるレビューを経て6月中旬にマージ、そして7月28日に製品発売という3ヶ月スプリントでした。標準hwmonインターフェースなのでlm-sensorsやfancontrolがそのまま使えます。Phoronixのコメント欄やHacker News、Redditでも肯定的な受け止めが多かったようです。到達時期はLinux 7.2以降で、ローリングリリース系のディストリビューションは早く、Ubuntu LTSのような安定系カーネルは反映まで数ヶ月かかることが多いでしょう。$9の製品にここまでやる律儀さ、素直に好きです。

## まとめ

コンパイラを先に用意する、ドライバを先に用意する。今週の5本は、使う人の手に届く前に自分で足場を整えておく側の話でした。地味な下準備は目立ちませんが、あとで慌てないためのいちばん確実な手だと思います。皆さんは、こういう「先回りの準備」を評価する派ですか、それとも出てから判断する派ですか？

## 参考リンク

- LWN記事ミラー（gccrs進捗詳報） https://noise.getoto.net/2026/07/28/progress-toward-compiling-linux-with-gccrs/
- Shelly 3.0.0リリース発表（9to5Linux） https://9to5linux.com/shelly-3-0-gui-package-manager-for-arch-linux-released-as-a-major-update
- FreeBSD Q2 2026ステータスレポート https://www.freebsd.org/status/report-2026-04-2026-06/
- Wayfire 0.11開発者公式ブログ https://wayfire.org/2026/07/24/Wayfire-0-11.html
- Linuxメインラインへのhwmonマージコミット https://github.com/torvalds/linux/commit/fc2ce3ee106f2d53eb344f5c4963c897bbb21634
