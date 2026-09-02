---
title: "初期設定のままの便利さが、いちばん先に牙を剥く（2026/9/3 Linux・OSSトレンド）"
date: 2026-09-03T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Ruby on Rails", "Active Storage", "Langflow", "systemd", "Fedora", "GNOME", "Wayland", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

今日の5本を並べていて、一本の線が見えました。「初期設定のまま」です。

インストールして、動いた。設定ファイルには触っていない。それで困っていない——だから触らない。この判断自体は、たいていの場合まったく正しいものです。デフォルトは開発者が考え抜いた「最も無難な選択」であり、素人が下手にいじるより安全なことのほうが多い。

ただ今日の1本目と5本目は、その前提が崩れる話です。デフォルトのまま動く便利な機能が、そのまま外部からの入口になっていた。しかも両方とも、認証すら要らない。そして間の3本は、逆に「デフォルトを入れ替える側」の話です。systemd が PID 1 の作り方を変え、Fedora が30年もののコンソールを差し替え、GNOME がウィンドウの描き方に新しい標準を持ち込む。

壊される既定と、書き換えられる既定。今日はその両方が同じ日に並びました。

{{< youtube "dqBTpv4esHs" >}}

## 1. CVE-2026-66066 — Rails の画像アップロードから、アプリの秘密が読み出される

重い話から始めます。Ruby on Rails の Active Storage に、認証不要でサーバー上の任意ファイルを読み出せる脆弱性が見つかり、実際に悪用が始まりました。

[NVD の登録内容](https://nvd.nist.gov/vuln/detail/CVE-2026-66066)を見ると、公開は2026年7月30日、CVSS は v4.0 で **9.5（Critical）** 、分類は CWE-1188（安全でないデフォルト設定によるリソース初期化）です。ベクトルは `CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H` 。ネットワーク越し・低複雑度・権限不要・ユーザー操作不要が揃い、影響範囲は自システムを越えて後続システムにまで High が付いています。

何が起きているのか。NVD の記述はこうです。「Active Storage が、信頼できないコンテンツに対して安全でないとマークされた libvips の操作を無効化しておらず、細工されたアップロードによってそうした操作を呼び出せる」。

libvips は画像処理ライブラリで、Rails は Active Storage のバリアント（サムネイル等）生成にこれを使います。libvips 側は「この操作はファジング未実施で、信頼できない入力に使うべきではない」と印を付けている機能群を持っているのですが、Rails はそれを無効化しないまま、外部ユーザーがアップロードした画像を通していました。錠前屋が「試作品だから使うな」と札を付けた鍵が、そのまま玄関に付いていたようなものです。

結果として攻撃者は、Rails プロセスが読めるファイル——環境変数や `config/credentials.yml.enc` のようなアプリケーションシークレット——を「画像データ」として読み出せます。NVD が続けて指摘しているとおり、 `secret_key_base` が漏れた時点でセッションの偽造が可能になり、そこからリモートコード実行へ到達しうる。ファイル読み取りの脆弱性が、実質的に乗っ取りになる経路です。

**ここは正確に押さえてください。** 「Rails を使っていれば全滅」ではありません。[GitHub Security Advisory GHSA-xr9x-r78c-5hrm](https://github.com/advisories/GHSA-xr9x-r78c-5hrm) が示す条件は2つで、 **(1) Active Storage の画像処理に libvips を使う構成であること、(2) 信頼できないユーザーからの画像アップロードを受け付けていること** 。両方に当てはまる場合に影響を受けます。逆に言えば、画像処理を MiniMagick 等に切り替えている構成は、この条件から外れます。

修正版は同アドバイザリに明記されています。`activestorage` の 7.2.3.2 / 8.0.5.1 / 8.1.3.1 で、それぞれ未満のバージョンが脆弱です。発見・報告のクレジットには Ethiack のチームや GMO Flatt Security の RyotaK（Ry0taK）らが並んでいます。

悪用状況について。[SecurityWeek](https://www.securityweek.com/critical-ruby-on-rails-vulnerability-in-attackers-crosshairs/) は VulnCheck の観測として、パッチ公開からおよそ1か月後に悪用が始まり、8月初旬時点でインターネットに露出した脆弱な Rails インスタンスが約7,000件確認されたと報じています。これは一次情報ではなくセキュリティ企業の観測値ですが、規模感の目安にはなるでしょう。

Rails チームは[公式フォーラムの投稿](https://discuss.rubyonrails.org/t/cve-2026-66066-attack-details-and-tools-to-perform-a-forensic-investigation/91441)で、`rails/rails-forensics-CVE-2026-66066` リポジトリにフォレンジック用のツールを公開したことを案内しています。「自分は脆弱な期間があったか」を判定する `kr2s-was-i-vulnerable` と、Active Storage 内を細工ファイルで検索する `kr2s-was-i-exploited` の2つです。同投稿は多層防御として Landlock によるサンドボックス化にも触れています。

まずやることは修正版へのアップグレード。そのうえで、画像アップロードを受け付けているなら「読まれた形跡がないか」を確認する。公式がツールまで用意して調査を促しているという事実自体が、状況の切迫度を示しています。

## 2. systemd 262-rc1 — PID 1 を1本の静的バイナリにまとめる

セキュリティから離れて、基盤の話へ。2026年9月1日、[systemd 262-rc1 が公開されました](https://www.phoronix.com/news/systemd-262-rc1)。リリース候補版ですが、含まれている変更が面白い方向を向いています。

いちばん目を引くのが、静的リンクされた PID 1 です。Phoronix の記述はこうです。「systemd は、非常に小さなコンテナ向けに、単一の静的リンクされた PID 1 / executor バイナリとしてビルドできるようになった」。

これは地味に大きな話です。従来の systemd は多数の共有ライブラリに依存する動的リンクバイナリで、PID 1 として起動するには相応のルートファイルシステムが必要でした。コンテナを極限まで小さくしようとすると、systemd は「重い」選択肢になる。だから多くの人が distroless イメージや `tini` のような最小 init に流れたわけです。単一の静的バイナリで PID 1 が務まるなら、その天秤の傾きが少し変わります。

2つ目が `LUOSession=` の追加。「サービスユニットに `LUOSession=` オプションが追加され、systemd が Live Update Orchestrator セッションを作成できるようになった」とあります。Live Update Orchestrator は、システムを止めずに更新を進めるためのオーケストレーション層で、個々のサービスがそのセッションのライフサイクルに紐づけられるようになる、という位置づけです。パッチ適用のたびに停止時間を計画する運用にとっては、将来的に効いてくる方向でしょう。

3つ目は機密コンピューティング周りです。ここは正確に書きます。 **systemd 全体が Intel TDX に対応した、という話ではありません。** Phoronix が伝えているのは「`systemd-vmspawn` の `--coco=` オプションが、従来の AMD SEV-SNP に加えて Intel TDX をサポートするようになった」という、仮想マシン起動ツールのオプション追加です。クラウドの機密 VM を手元から立てる人には嬉しい変更ですが、範囲は限定的です。

rc1 なので、本番投入はまだ先の話。とはいえ systemd の変更はディストリビューションを通じて遅かれ早かれ全員のところに降ってきます。「コンテナの中の init をどうするか」を検討している人は、安定版が出る頃にもう一度見に来る価値があります。

## 3. Fedora 45 — 30年もののコンソールが、ついに置き換わる

Fedora 45 が Beta 段階に入りました。[Beta Freeze の適用は2026年8月25日と報じられています](https://www.linuxcompatible.org/story/fedora-45-hits-major-cutoff-day-bodhi-enablement-beta-freeze-and-string-freeze-take-effect/)。中身で目を引くのは、地味ですが影響範囲の広い変更です。

[Fedora 45 の公式 ChangeSet](https://fedoraproject.org/wiki/Releases/45/ChangeSet) に「Use kmscon as default VT console」という System-Wide Change が載っています。担当は Jocelyn Falempe、コード実装は100%完了とされ、目的は「Fedora においてカーネルコンソール fbcon をユーザースペースコンソール kmscon で置き換え、より高機能で安全なコンソールを提供する」こと。

fbcon は1990年代後半から Linux カーネルに居座っているフレームバッファベースの仮想端末で、「X も Wayland も起動していない状態で文字を出す唯一の手段」として長く働いてきました。ただ GPU が DRM/KMS へ全面移行した今、fbcon は fbdev エミュレーションという互換レイヤーの上で動くレガシーになっています。

[変更提案ページ](https://fedoraproject.org/wiki/Changes/UseKmsconVTConsole)によると、切り替えの実装は驚くほど素朴で、`/usr/lib/systemd/system/autovt@.service` のシンボリックリンクを `kmsconvt@.service` に向け直すだけ。得られるものとして挙げられているのは、xkbcommon によるキーボード対応（複数レイアウトと切り替えに対応）、Pango によるフォント描画（全角文字の幅の扱いが改善）、スクロールバック、Unicode 対応の改善、そしてカーネル常駐でなくユーザースペースプログラムであることによる安全性です。最後の点は要するに、コンソールがクラッシュしてもカーネルパニックにはならない、ということですね。

非互換もはっきり書かれています。「コンソールから `startx` のようなグラフィカルアプリケーションを起動することはできなくなるが、`kmscon-launch-gui startx` というスクリプトを使えば回避できる」。VT から直接 X を上げる古典的なワークフローの人は、ここで一度つまずくはずです。追跡は FESCo issue #3513 で行われています。

そしてもう一点、 **報道が先行して広まった誤りを訂正しておきます。** 「Fedora 45 で Shadow Stack がデフォルト有効化される」という話がありましたが、これは Fedora 45 ではありません。[Shadow Stack の変更提案ページ](https://fedoraproject.org/wiki/Changes/ShadowStack)は提案本文こそ「Fedora Linux 45」を対象と書いているものの、ページのカテゴリタグは `ChangeAcceptedF46` になっています。実際、上記の Fedora 45 ChangeSet に Shadow Stack の項目は載っていません。[Phoronix](https://www.phoronix.com/news/Fedora-46-Shadow-Stack-Plans)も、FESCo がこれを「来春の Fedora 46 で期待される早期機能のひとつ」として承認したと伝えており、延期理由として NVIDIA ドライバと PyPI の Python wheel との互換性確保に時間が必要だった点を挙げています。

ROP 攻撃をハードウェアで抑え込む機構が1サイクル遅れるのは残念ですが、バイナリ配布物との互換性が壊れれば「動かないから無効化する」が横行して意味がなくなります。待つのが正解でしょう。

## 4. GNOME 51 "A Coruña" — Wayland にブラーの標準規格がやってきた

デスクトップの話です。GNOME 51 が RC 段階に入りました。[GNOME のリリースカレンダー](https://release.gnome.org/calendar/)では 51.rc が2026年8月29日、51.0 が9月12日に置かれ、リリースイベントは9月16日です。コードネーム「A Coruña」は GUADEC 2026 の開催地であるスペイン・ガリシア州の都市に由来します。

技術的にいちばん面白いのは、Mutter への `ext-background-effect-v1` 実装です。[Mutter の Merge Request !5071](https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/5071)（タイトル「wayland: Add ext-background-effect-v1 blur support」、作者 Kristof Imeri）は2026年5月18日に作成され、2026年7月3日にマージされています。

背景ブラー——ターミナルやパネルの後ろが「すりガラス」になるあれ——は、これまで各コンポジターが独自プロトコルで実装してきました。KDE の KWin には独自のブラープロトコルがあり、GNOME にはなく、アプリ側は環境ごとに書き分けるか諦めるかの二択だった。それが Wayland の標準プロトコルとして定義され、GNOME もそれに乗った、というのが今回の変更です。設計は opt-in で、アプリが明示的にブラー領域を指定しない限り何も起きません。

ここで、よく見かける記述をひとつ訂正しておきます。「ブラー対応は Mutter 51 Alpha に入った」という説明を見かけますが、[Mutter のタグ一覧](https://gitlab.gnome.org/GNOME/mutter/-/tags)を確認すると `51.alpha` は2026年6月29日、`51.beta` は8月2日、`51.rc` は9月2日です。MR のマージが7月3日ですから、Alpha には間に合っておらず、この機能が最初に載ったリリースは Beta ということになります。細かい話ですが、「どのプレリリースで試せるか」を調べる人には意味がある差です。

ブラー以外にも、GNOME Shell の認証まわりに Web ベースのログインフローが追加され、Settings のユーザーパネルに指紋の登録・管理を行う UI が新設され、GNOME Maps がオフラインマップのダウンロードに対応する、といった変更が[9to5Linux](https://9to5linux.com/gnome-51-a-coruna-desktop-environment-scheduled-for-september-16th-2026)などで報じられています。指紋認証の設定がディストリ固有の画面や CLI から GNOME 本体に移るのは、地味ながら「初期設定でどこまでできるか」を押し上げる変更です。

Fedora 45 や Ubuntu 26.10 に載ってくる想定なので、秋のアップグレードで手元に届く人は多いはずです。

## 5. CVE-2026-0768 — AI ワークフロー基盤から、OpenAI と AWS の鍵が抜かれる

最後は今日いちばん実務に刺さる話です。AI ワークフロー構築ツール Langflow の脆弱性が、8か月の沈黙を経て突然悪用され始めました。

[NVD の登録内容](https://nvd.nist.gov/vuln/detail/CVE-2026-0768)によると、CVSS は v3.0 で **9.8（Critical）** 、ベクトルは `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` 、分類は CWE-94（コード生成の不適切な制御）。説明文は「validate エンドポイントに渡される code パラメータの処理に欠陥がある。ユーザー供給の文字列を適切に検証せずに Python コードとして実行してしまう」「攻撃者はこの脆弱性を利用して root のコンテキストでコードを実行できる」。認証は不要です。

カスタムコンポーネント編集機能のコード検証 API が、検証と称して受け取った文字列をそのまま実行していた——扉のない電子レンジのようなものです。入れたら動く。誰でも入れられる。

発見と開示の経緯は、[Zero Day Initiative の ZDI-26-034](https://www.zerodayinitiative.com/advisories/ZDI-26-034/) に残っています。Trend Research の Peter Girnus、William Gamazo Sanchez、Alfredo Oliveira の3名が発見し、ベンダーへの初報は2025年7月18日。9月11日と10月10日にステータス照会を行い、12月10日に公開予告を通知、2026年1月9日にアドバイザリ公開。通知から公開まで、およそ半年が経っています。

そして悪用が始まったのは、公開からさらに8か月後の8月末でした。[BleepingComputer](https://www.bleepingcomputer.com/news/security/critical-langflow-flaw-exploited-to-steal-openai-and-aws-keys/) は VulnCheck の観測として、英国のハニーポットで週末に少なくとも50件、翌日には累計360件の攻撃試行が記録されたと報じています。攻撃者は RCE 成功後に環境変数を漁り、`LANGFLOW_SUPERUSER` 系のキー、`OPENAI_API` 系の認証情報、`AWS_ACCESS` / `AWS_SECRET` 系のトークンを収集する。さらに `/root/.cache/langflow/secret_key`、`.ssh` ディレクトリ、`.bash_history` にも手を伸ばします。同記事は、活発に悪用されているにもかかわらず公開された PoC は確認されていない、とも書いています。

対処にあたって、 **バージョン情報の出どころには注意が必要です。** 一次情報である ZDI のアドバイザリには修正版バージョンの記載がなく、緩和策として挙げられているのは「製品へのアクセスを制限すること」だけです。[GitHub Security Advisory](https://github.com/advisories/GHSA-x5pr-rvjj-j6qm) にも影響バージョン範囲・修正バージョンの登録がありません。「1.4.2 以前が影響、1.11.6 で修正」という具体的な数字は BleepingComputer の記述によるもので、一次情報では裏が取れていない、というのが現状です。

ただし [Langflow の v1.11.6 リリース](https://github.com/langflow-ai/langflow/releases/tag/v1.11.6)（2026年9月1日公開）には「fix: backport security and correctness fixes to 1.11.6」という変更が含まれており、セキュリティ修正がバックポートされていること自体は確認できます。結論として、最新版へ上げつつ、ZDI が言うとおりインターネットへの直接公開をやめる——この2つを両方やるのが妥当な線でしょう。

ついでに書いておくと、同じ validate エンドポイントは2025年にも [CVE-2025-3248（GHSA-rvqx-wpfh-mfx7）](https://github.com/advisories/GHSA-rvqx-wpfh-mfx7) として修正されています。こちらは 1.3.0 未満が影響、1.3.0 で修正。同じ場所が二度燃えているわけです。

そして最も重要な後始末は、アップグレードではありません。 **漏れた可能性のある鍵を全部無効化して再発行することです。** OpenAI の API キーも、AWS のアクセスキーも、SSH の秘密鍵も。パッチを当てても、すでに持ち出された鍵は攻撃者の手元で有効なままです。

## まとめ

今日の5本を並べ直すと、「デフォルト」という言葉が二通りの意味で出てきました。

1本目と5本目は、デフォルトが破られた話です。Rails は画像処理ライブラリの危険な機能を初期状態で無効化していなかった。Langflow は認証なしでコードを実行する API を初期状態で外に向けていた。どちらも、利用者は何も設定を間違えていません。ただインストールして、動かしていただけです。CWE-1188——「安全でないデフォルト設定によるリソース初期化」という分類名が、そのまま今日のテーマになりました。

2本目から4本目は、デフォルトが書き換わる話です。systemd はコンテナ内の PID 1 のあり方を、Fedora は30年ものの仮想コンソールを、GNOME はウィンドウ描画の作法を、それぞれ既定から入れ替えにいく。こちらは変化そのものが目的で、しばらくは非互換の報告が続くはずです。

破られる既定と、書き換えられる既定。前者に必要なのは棚卸しで、後者に必要なのは追随です。どちらも「今動いているから触らない」では対応できません。

そこで今日の問いです。 **あなたが最後にデプロイしたアプリケーションで、明示的に設定した項目はいくつありますか。そして、設定しなかった項目のうち、外部からアクセスできるものはどれですか。** 前者は思い出せても、後者は即答しにくいはずです。私も自分のスタックを、この観点でもう一度見てみます。

## 参考リンク

- [NVD — CVE-2026-66066（Rails Active Storage）](https://nvd.nist.gov/vuln/detail/CVE-2026-66066)
- [GitHub Security Advisory — GHSA-xr9x-r78c-5hrm（影響条件・修正バージョン）](https://github.com/advisories/GHSA-xr9x-r78c-5hrm)
- [Ruby on Rails 公式フォーラム — 攻撃詳細とフォレンジックツール](https://discuss.rubyonrails.org/t/cve-2026-66066-attack-details-and-tools-to-perform-a-forensic-investigation/91441)
- [Phoronix — systemd 262-rc1](https://www.phoronix.com/news/systemd-262-rc1)
- [Fedora Project — Fedora 45 ChangeSet](https://fedoraproject.org/wiki/Releases/45/ChangeSet)
- [Fedora Project — Changes/UseKmsconVTConsole](https://fedoraproject.org/wiki/Changes/UseKmsconVTConsole)
- [Fedora Project — Changes/ShadowStack（ChangeAcceptedF46）](https://fedoraproject.org/wiki/Changes/ShadowStack)
- [GNOME — リリースカレンダー](https://release.gnome.org/calendar/)
- [GNOME Mutter — MR !5071（ext-background-effect-v1 実装）](https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/5071)
- [NVD — CVE-2026-0768（Langflow）](https://nvd.nist.gov/vuln/detail/CVE-2026-0768)
- [Zero Day Initiative — ZDI-26-034（開示タイムライン）](https://www.zerodayinitiative.com/advisories/ZDI-26-034/)
- [Langflow — v1.11.6 リリースノート](https://github.com/langflow-ai/langflow/releases/tag/v1.11.6)
