---
title: "DNA証拠が45分で偽造可能に 信頼の代償を問う一週間（2026/8/4 Linux動向）"
date: 2026-08-04T00:00:00+09:00
draft: false
tags: ["Linux カーネル", "AI", "DeepSeek", "KDE Linux", "Box64", "DNA鑑定", "CVE", "セキュリティ", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

今日の糸は2本あります。ひとつは「AIが審査・生成の速度を変える」こと。Linux カーネルは AI 生成パッチの大量流入で史上最多コミットの rc6 となり、DeepSeek は AI モデル自体を MIT ライセンスで無償公開して価格破壊を起こしました。もうひとつは「確認・信頼の裏付けが追いついているか」という問い。KDE や Box64 は使う前の確認の手間を UX で軽減する方向に進む一方、法科学の DNA 鑑定ソフトウェアは30年間ファイルの改ざん検知手段がなく、AI を使えば **45分** で証拠偽造ができてしまうという、確認の欠如が最も深刻な形で露呈した週でもありました。審査・価格・体験・証拠――AI が物事を塗り替える速さに、確認の手間がついていけるかを問う一週間です。

{{< youtube "a84D9Ng9mwI" >}}

## 1. Linux 7.2-rc6 リリース — AI パッチ流入で数年来最大の RC6 に

Linus Torvalds は Linux 7.2-rc6（2026年8月2日公開）を「コミット数で見れば、ここ数年で最大の rc6 だろう」と評しました。[Phoronix](https://www.phoronix.com/news/Linux-7.2-rc6-Released) によれば、AI/LLM コーディングエージェントを使って生成されたとみられるパッチの投稿増加と、7.2 サイクル前半で意図的に延期されていたネットワークサブシステム修正の合流が重なり、RC6 としては異例の規模となりました。内訳はドライバーが6割弱、ネットワークが2割、残りが2割という構成です。注意したいのは、AI 生成パッチが大量に投稿されメンテナーの審査負荷を著しく増大させたのが事実であり、最終的にマージされたのはあくまで審査を通過した分だけという点です。「AI パッチがそのままマージされた」わけではありません。

技術面では、AMD Zen 5 CPU が誤って Zen 6 として識別されてしまうバグが修正されました。これによりパフォーマンスカウンターや P-state 管理といった CPU 固有の最適化パスが正しく適用されるようになります。データベース運用者にとって朗報なのが MGLRU（Multi-Generation LRU）のページ回収改良で、MongoDB のようなワークロードでスループットが最大 **30%** 向上し、HDD 環境では最大 **100%** の向上も報告されています。通常環境で30%、HDD 環境で100%と、条件によって効き方が大きく変わる点は押さえておきたいところです。ほかにも AMDGPU に HDMI 2.1 FRL(Fixed Rate Link) サポートが統合され、4K 144Hz や 8K 30Hz といった高帯域の映像出力が Linux 上でも扱いやすくなりました。

Torvalds はメーリングリスト上で今回の異例な規模に言及しており、rc6 の積み残しが大きいぶん、rc7 の追加を経て安定版のリリースが若干後ろ倒しになる可能性があります。AI がコード生成の裾野を広げるほど、それを審査する人間側の負荷がどう変化していくのか、カーネル開発の現場から目が離せません。

## 2. DeepSeek-V4-Flash-0731 を MIT ライセンスで完全オープンソース化

中国の AI 研究機関 DeepSeek は2026年7月31日、総パラメーター **284B** （推論時アクティブ **13B** 、DSpark 投機的デコーダー込みで **304B** ）の Mixture-of-Experts モデル「DeepSeek-V4-Flash-0731」を [Hugging Face](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-0731) 上で MIT ライセンス公開しました。重要な点として、この0731版はアーキテクチャを変えずポストトレーニングのみで性能を引き上げています。「新アーキテクチャを採用した」わけではなく、エンジンは同じままドライバーの訓練だけで大幅に成績を伸ばしたような成果です。実際、[Artificial Analysis](https://artificialanalysis.ai/models/deepseek-v4-flash) の独立ベンチマークでは101モデル中3位を獲得しました。

コンテキストウィンドウは最大100万トークン、出力は最大38.4万トークンに対応し、[DeepSeek 公式 API ドキュメント](https://api-docs.deepseek.com/news/news260424/) によれば API 料金は入力 **$0.14/M** ・出力 **$0.28/M** トークンという低価格設定です。キャッシュヒット時の入力料金は **$0.0028/M** と通常比で約98%割引になり、反復的なエージェントタスクのコストを大きく下げます。Hacker News では「30日間・3,467API呼び出し・3.23億トークンでわずか$4.55」という実例が740ポイントを集めるほど話題になりました。

MIT ライセンスは商用利用・再配布・改変を無制限に許可するため、企業がオンプレミス展開する際の法的障壁が実質的にゼロになります。ただしモデルサイズは約167GB あり、ローカル実行には256GB 以上の RAM が実用ラインです。なお、旧モデル名の `deepseek-chat` ・`deepseek-reasoner` は **2026年7月24日15:59 UTC** 以降廃止予定のため、既存コードを利用している開発者は `deepseek-v4-flash` への切り替えが実務上必要になります。強力な AI を月額サブスクのコーヒー代より安く動かせる時代が、価格破壊というかたちで現実になってきました。

## 3. KDE Linux「Package Compatibility Helper」— Java・DOS アプリ起動時の確認を UX で肩代わり

KDE コミュニティが開発するイメージベース Linux ディストリビューション「KDE Linux」の2026年7月月次進捗レポート（[KDE 公式ブログ](https://blogs.kde.org/2026/08/03/this-month-in-kde-linux-july-2026/) 、8月3日公開）で、「Package Compatibility Helper」という機能が紹介されました。開発者 Hadi Chokr（GitHub: silverhadch）による実装で、Java ランタイムや DOSBox が未導入の環境でそれらを必要とするアプリを起動しようとした際、Flathub から必要なランタイムの自動インストールを提案します。あくまでまだアルファ版段階の機能である点は押さえておきたいところです。

Java アプリでは、JRE(Java Runtime Environment) が存在しない場合に初回起動時のダイアログで JRE をダウンロードするかどうかを尋ね、承認すればそのまま取得してアプリを起動します。従来は「何も起きない」か「謎のエラー」で詰まっていたフローが、ワンクリックの解決に変わりました。DOS 時代のレガシーバイナリについても、DOSBox の導入を提案します。DOSBox Staging を既定に選んだ理由について実装者は、設定ファイルをいじらなくても大半の DOS アプリがそのまま動くからで、既定の挙動としてはそれが望ましい、と説明しています。

KDE Linux は読み取り専用の `/usr` を持つイメージベースの不変(immutable) OS で、アプリケーションは Flatpak 経由で提供されます。システム層とアプリ層が明確に分離されているため、ランタイムをシステムに組み込まず Flatpak として隔離・取得する設計が自然に採用されました。KDE 公式ブログでも、Flatpak を使う他のイメージベース OS にとっても有用だろうという見立てで十分に汎用的な書き方がされていると説明されており、Fedora Atomic 系など他のディストリビューションへの波及も見込めます。「ファイルを開こうとしたら必要なソフトを自動で提案してくれる」という、Windows では当たり前だった体験に Linux デスクトップが着実に近づいている一例です。

## 4. Box64 v0.4.4 リリース — Python 製 GUI コンフィギュレーターと DynaCache のデフォルト有効化

ARM64・RISC-V・LoongArch 向けユーザー空間 x86_64 エミュレーター Box64 の v0.4.4 が2026年8月2日にリリースされました。[Box64 公式リリースノート](https://github.com/ptitSeb/box64/releases/tag/v0.4.4) によれば、目玉は Python 製のプロファイル管理 GUI「box64-configurator」の新搭載です。これまでテキストエディタで直接編集する必要があった `.box64rc` 形式の設定ファイルを、説明テキスト付きの一覧から視覚的に編集できるようになりました。Wine の「winetricks」に相当するツールが Box64 にも登場したとイメージするとわかりやすいでしょう。

動的再コンパイルキャッシュ「DynaCache」もこのバージョンでデフォルト有効化されました。これは Box64 の動的再コンパイラが x86_64 命令をネイティブコードに変換した結果をディスクにキャッシュし、次回起動時の再変換をスキップして起動時間を短縮する仕組みです。DynaCache 自体は **v0.3.8** で実験的機能として導入されていたもので、今回新規実装されたわけではありません。v0.4.4 でキャッシュ検証ロジックの改善などバグ修正が積み重なり、本番投入できる水準に達したと判断されデフォルト有効化に至りました。キャッシュ容量の上限はデフォルトで **2048MiB(2GB)** 、超過時は古いファイルから自動削除されます。

DRM 保護ゲームの互換性も向上し、Death Stranding 2 や Call of Duty 4 向けの RCFILE プロファイルが追加されました。LoongArch64 向けには AVX がデフォルト有効化されるなど今回最多の改善が入り、中国製 CPU 環境での x86_64 アプリ実行基盤としての重要性が高まっています。Raspberry Pi のような非 x86 ハードウェアで、2回目以降のゲーム起動が体感できるレベルで速くなる変化です。

## 5. Thermo Fisher 法科学 DNA 解析ソフトに改ざん検知回避の欠陥 — AI で45分の証拠偽造が実証

犯罪捜査で米国200以上の犯罪科学研究所が使用する Thermo Fisher Scientific 製 Applied Biosystems の DNA 解析ソフトウェアに、CVE-2026-17583 が発覚しました。核心は、装置が出力する `.fsa` ・`.hid` ファイルに1995年以来30年間、電子署名などの改ざん検知手段が一切付与されていなかったことです。[The Hacker News](https://thehackernews.com/2026/08/thermo-fisher-patches-flaw-that-could.html) の報道によれば、CVSS v4.0 スコア **8.2(High)** は Thermo Fisher 自身が CNA(CVE Numbering Authority) として付与した暫定値です。2026年8月3日時点で [NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-17583) はこの CVE を RESERVED 状態のまま未エンリッチとしており、独立評価は未公表という点は正確に押さえておく必要があります。

Forensic Bioinformatics のシステムエンジニア Nathan Adams は、Anthropic 社の Claude を活用して攻撃コードを生成し、2015年以降手を加えていないように見せかけた改ざんファイルを **約45分** で作成しました。解析ソフトはこれを正常と判定し、警告は一切発しませんでした。セキュリティの専門家による実証実験であり、「誰でも簡単に」というほど単純化すべき話ではありませんが、AI がハードルを大幅に下げた事実は変わりません。

パッチは3500/3500xL・3730/3730xL・SeqStudio Genetic Analyzer・SeqStudio Flex・GeneMapper ID-X の5製品ラインに提供され、いずれも電子署名の追加によるファイル完全性検証が実装されました。一方で3130 Series・ABI PRISM 3100/3100-Avant・ABI PRISM 310 の3製品ラインはサポート終了(EOL) のため修正は提供されません。最も重い事実は、1995年以降に生成されたすべての `.fsa` ・`.hid` ファイルについて、過去の改ざんを事後的に検知する方法が現時点で見つかっていないという点です。Thermo Fisher は「これまで悪用されたインスタンスは確認していない」と述べていますが、そもそも検知手段自体が存在しなかったことを踏まえると、この声明が保証できる範囲は限られています。

## まとめ

審査・価格・体験・証拠――今週はどの糸をたどっても「AI が物事を塗り替える速さ」に行き着きました。Linux カーネルの審査負荷は AI 生成パッチの流入で増し、DeepSeek は AI モデルそのものの価格破壊を MIT ライセンスで起こしました。KDE や Box64 は、使う前の確認をユーザーの手から UX の中へ移そうとしています。ですがその一方で、DNA 鑑定という最も確認の厳密さが求められる領域では、30年間検知手段が存在せず、AI がその欠如を **45分** という具体的な数字で可視化してしまいました。速さを追いかけるのと同じ熱量を、確認の仕組みにも向けられているでしょうか。皆さんが日常で信頼している「デジタルの証拠」は、本当に改ざんされていないと言い切れるものでしょうか。

## 参考リンク

- Linux 7.2-rc6 の公式 git タグ https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tag/?h=v7.2-rc6
- Phoronix — Linux 7.2-rc6 リリース解説 https://www.phoronix.com/news/Linux-7.2-rc6-Released
- DeepSeek-V4-Flash-0731 公式モデルカード https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash-0731
- DeepSeek 公式 API ドキュメント https://api-docs.deepseek.com/news/news260424/
- Artificial Analysis 独立ベンチマーク・コスト分析 https://artificialanalysis.ai/models/deepseek-v4-flash
- KDE 公式ブログ（July 2026 月次レポート） https://blogs.kde.org/2026/08/03/this-month-in-kde-linux-july-2026/
- Package Compatibility Helper 公式リポジトリ https://invent.kde.org/kde-linux/package-compatibility-helper
- Box64 v0.4.4 公式リリースノート https://github.com/ptitSeb/box64/releases/tag/v0.4.4
- 公式 USAGE ドキュメント（DynaCache 設定変数の説明） https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md
- Thermo Fisher Scientific 公式セキュリティ速報 https://documents.thermofisher.com/TFS-Assets/CORP/Product-Guides/fsa_hid_bulletin.pdf
- NVD — CVE-2026-17583 詳細（RESERVED 状態） https://nvd.nist.gov/vuln/detail/CVE-2026-17583
- The Hacker News（2026年8月3日報道） https://thehackernews.com/2026/08/thermo-fisher-patches-flaw-that-could.html
