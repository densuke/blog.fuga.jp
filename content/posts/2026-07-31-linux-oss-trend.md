---
title: "9.5より5.3が先に狙われた — スコアと線引きを問う一日（2026/7/31 Linux動向）"
date: 2026-07-31T00:00:00+09:00
draft: false
tags: ["Rails", "Active Storage", "libvips", "GCC", "COSMIC", "Rust", "Debian", "LLM", "Cisco", "セキュリティ"]
categories: ["Linux・OSSトレンド"]
---

CVSS 9.5の脆弱性はまだ悪用が確認されていないのに、CVSS 5.3のほうは公開日にはもう野良で悪用されていました。数字の大きさと実際に襲われる順番は一致しない、というのが今日いちばん刺さった話です。もうひとつの糸は「AIコード貢献にどこで線を引くか」。GCCは人間の後編集分まで含めて法的に有意な貢献を一律拒否すると決め、Debianは完全禁止から中立まで5つの提案を投票にかけている最中です。線の引き方そのものが割れている、そんな一日を5本立てでお届けします。

{{< youtube "JS0aP7OV9bM" >}}

## 1. Rails Active Storage 未認証RCE — CVE-2026-66066、CVSS 9.5

Rails 7.0〜8.1系のActive Storageに、未認証の攻撃者が細工した画像をアップロードするだけで任意ファイル読み取りとリモートコード実行（RCE）に到達できる脆弱性が見つかりました。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-66066)によれば、CVSS v4.0スコアは **9.5（Critical）** でGitHub（CNA）評価として確定しており、ベクターは`AV:N/AC:L/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H`です。引き金になったのは、Active Storageが画像変換ライブラリlibvipsにバリアント生成（アップロード画像からサムネイルなどの派生画像を作る処理）を行わせる際、非信頼ファイルをそのまま渡していたことでした（CWE-1188、安全でない初期設定のまま使ってしまう不備）。libvipsは8.13から`VIPS_BLOCK_UNTRUSTED`という危険なローダーを一括ブロックする仕組みを提供していましたが、Rails側がそれを使う実装をしていなかったのが直接の原因であり、libvips自体の脆弱性ではありません。

影響バージョンは[GitHub Advisory](https://github.com/advisories/GHSA-xr9x-r78c-5hrm)の表のとおりで、7.0.0〜7.2.3.1（修正7.2.3.2）、8.0.0.beta1〜8.0.5.0（修正8.0.5.1）、8.1.0.beta1〜8.1.3.0（修正8.1.3.1）。6.x系はvipsを手動設定していた場合のみ影響し、公式パッチはありません（EOL）。「7〜8割のRailsアプリが影響を受けるとみられる」という見積もりも聞かれますが、こちらはあくまで推定の域を出ない数字です。

現時点で野良悪用の報告はありません。Ethiackの技術解析"KindaRails2Shell"は詳細手順が2026年8月28日まで非公開で、第三者PoCリポジトリも技術詳細は伏せられたままです。[Rails公式フォーラムのアドバイザリ](https://discuss.rubyonrails.org/t/cve-2026-66066-possible-arbitrary-file-read-and-remote-code-execution-in-active-storage-variant-processing/91432)は、パッチ適用だけでは不十分だと強調しています。攻撃が成立すると`secret_key_base`が漏れ、Cookie偽造からRCEへ昇格しうるためです。この鍵に加えて`master.key`やクラウドストレージのキーなど、プロセスが読めるシークレットはすべて漏洩済みとして扱いローテーションせよ、というのがアドバイザリの立場です。8月28日の詳細解禁より前に、パッチ適用と鍵の入れ替えを終えられるかが焦点になっています。

## 2. GCCがAI生成コードの「法的に有意な」貢献を一律拒絶

GCC（GNU Compiler Collection）のステアリング委員会が、AI・LLMツールに由来する「法的に有意な」コード貢献を一律拒否する方針を決めたと[Phoronixの報道](https://www.phoronix.com/news/GCC-Declining-AI-Contributions)が伝えています。これを裏付ける一次情報は現時点でその記事のみで、GCC公式サイトの声明ページは確認できていません。

注目したいのは、AI生成コードをそのまま貼り付けた投稿だけでなく、 **人間が後から編集・改変したもの** も対象になる点です。「AIが書いたけど人間がチェックしたからOK」という一般的な認識を正面から否定する内容で、他のオープンソースプロジェクトが追随するかを占う試金石にもなりそうです。GCCへのコード貢献には歴史的に著作権割り当てやDCO（Developer Certificate of Origin、そのコードの出所を開発者自身が保証する宣誓）が求められており、「法的に有意な」とはこの著作権処理が必要になる規模・独自性を持つ変更を指すとされます。目安としては「数十行を超えるオリジナル実装」あたりが挙げられますが、これはGCCが公式に示した基準というわけではありません。

一方でテストケースについては例外として、LLM支援による貢献が引き続き許容されます。定型的で創作的表現の域に達しにくく、著作権問題が生じにくいという判断のようです。ステアリング委員会はこの方針を固定的なものとは位置付けておらず、 **2027年初頭** に再評価する予定だとされています。GCCはほぼすべてのLinux/Unix系プラットフォームで使われる基礎的なコンパイラだけに、コントリビューターコミュニティへの影響は広範に及びそうです。同じくAIコントリビューションの線引きを議論しているDebian（トピック4）と合わせて、2026年はオープンソースのAI規範が定まる転換点になりつつあります。

## 3. COSMIC Epoch 1.5 — 新機能より堅牢化に振ったリリース

System76が独自開発するRust/Wayland製デスクトップ環境COSMICが、Epoch 1.5.0をリリースしました。[Phoronixの報道](https://www.phoronix.com/news/COSMIC-Epoch-1.5-Released)によれば、今回は新機能追加よりも安定性・パフォーマンス改善に重点が置かれています。主眼となったのは次の3点です。ひとつめはGPUリセット時のシステム安定性向上。GPUドライバがリセット・リカバリを行う際にコンポジター（ウィンドウの合成・表示を担う中核プロセス、cosmic-comp）ごとクラッシュしていた問題への対応で、Nvidia GPU環境や省電力設定の積極的なラップトップで恩恵が大きい修正とされています。

ふたつめはChromium系アプリで発生していた、1.0未満の分数スケーリング（HiDPIディスプレイでの縮小表示）まわりのバグ修正です。ウィンドウ座標の計算が狂ってクリック位置がずれる、あるいはレンダリングがぼやけるといった不具合が報告されていました。みっつめはCOSMICパネル（タスクバー）のFrosted Glassエフェクト（すりガラス風の半透明ぼかし処理）を使うと、パネルのCPU使用率が高騰していた問題への対策です。

なお、これらの修正の内部実装（fractional-scaleプロトコルのネゴシエーション部分の具体的なバグ内容や、ぼかし処理の差分更新による最適化の詳細、アイドル時CPU使用率の低下幅など）まで踏み込んだ解説も見かけますが、PhoronixやSystem76の公式発表として確認できる情報ではないため、ここでは主眼となった3点にとどめておきます。COSMICは「Epoch」という呼称を年1〜2回の安定性マイルストーンに使っていますが、これもSystem76独自の呼び方として紹介されているもので、公式に定義された用語というわけではありません。Wayland移行を進めるSystem76ユーザーにとっては、日常的な信頼性向上に直結する内容と言えそうです。

## 4. Debianの一般決議（GR）— LLM利用を巡る5提案が審議継続中

Debianプロジェクトが2026年7月22日に「LLM usage in Debian」の一般決議（General Resolution、vote_002）を発動しました。[Debian公式投票ページ](https://www.debian.org/vote/2026/vote_002)によれば、完全禁止から中立まで5つの競合提案が、Condorcet方式（候補同士を総当たりで比較する優先順位付き投票）にかけられることになりました。ただし **2026年7月31日時点ではまだ審議継続中で、可決も禁止決定もされていません** 。Project SecretaryのKurt Roeckxが7月24日に公式討議開始をアナウンスし、討議期間は最低2週間とされています。

5提案の内訳は、Proposal A（完全禁止、提案者Matthias Geiger、賛同者8名）、Proposal B（6条件付き許可、提案者Lucas Nussbaum元DPL、賛同者9名）、Proposal C（実際的な限り排除、提案者Ian Jackson、賛同者9名）、Proposal D（責任フレームワーク付き受容、提案者Pierre-Elliott Bécue、賛同者7名）、Proposal E（中立的立場、提案者Marc Haber、賛同者7名）です。賛同者数が多いからといって優勢というわけではなく、Condorcet方式の投票結果とは直接関係しないとされています。

対象はパッケージング・文書・翻訳・公式Web・バグレポートとプロジェクト全域に及び、著作権リスクとレビュアー疲弊が主な争点です。「アップストリームコードの約10%は既にAI補助で書かれている」という推定もあり（出典は特定されていません）、その上流側を除外したままDebian固有の作業だけ禁じるのは構造的に矛盾している、という指摘が[Lobste.rsのスレッド](https://lobste.rs/s/ygobr3/general_resolution_llm_usage_debian)などで出ています。[Hacker Newsのスレッド](https://news.ycombinator.com/item?id=49050859)（158ポイント・141コメント）でも「強制可能性への懐疑」と「非英語話者のアクセシビリティ問題」が主要論点になっており、メジャーディストリビューションとして初めてLLMポリシーを正式投票で問う事例として注目が集まっています。

## 5. Cisco Secure FMCにハードコード資格情報 — CVE-2026-20316、CISA KEV追加

Cisco Secure Firewall Management Center（FMC）のウェブUIに、低権限アカウントの静的パスワードが埋め込まれていた脆弱性が2026年7月29日に公開されました。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-20316)によれば、CVSS v3.1スコアは **5.3（MEDIUM）** ・CWE-259（ハードコードされたパスワードの使用）で、ベクターは`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N`です。一方でCisco PSIRT（製品セキュリティ対応チーム）は独自のSecurity Impact Rating（SIR）として **HIGH** を付与しており、CVSSスコアとSIRは別物である点に注意が必要です。他のFMC脆弱性と組み合わせれば（チェーンすれば）権限昇格も可能とされています。

Railsとは逆に、こちらは公開日の時点で **既に野良悪用が確認されていました** 。[CISA](https://www.cisa.gov/news-events/alerts/2026/07/29/cisa-adds-one-known-exploited-vulnerability-catalog)はKEV（Known Exploited Vulnerabilities＝悪用が確認済みの脆弱性）カタログへ2026年7月29日付でこれを追加し、連邦機関に **2026年8月1日** までの対応を義務付けています。回避策（ワークアラウンド）は存在せず、ホットフィックス適用のみが対策です。Cloud-Delivered FMC（cdFMC）は対象外で、影響はオンプレミス運用のFMCに限られます。

影響バージョンは7.0.0〜7.0.9、7.2.0〜7.2.11、7.3.0〜7.3.1.2、7.4.0〜7.4.7、7.6.0〜7.6.5、7.7.0〜7.7.12、10.0.0〜10.0.1で、それぞれに専用ホットフィックスが用意されています。侵害痕跡（IoC）の確認には`grep "license.tmp" /var/log/messages`が使えます。発見者はHorizon3.aiのJimi Sebree氏で、攻撃の具体的な手法やPoCの技術詳細は非公開のままです。Heise Onlineなど欧州メディアは「バックドア」という見出しで報じていますが、これはメディア側の表現であり、Cisco自身がそう説明しているわけではありません。CVSSの数字だけを見て後回しにすると危ない、というわかりやすい反例だと思います。

## まとめ

9.5のRailsはまだ悪用が確認されず、5.3のCiscoは公開日にはもう狙われていました。スコアの大小と実際に襲われる順番が逆転する現実を、今日の2件はそのまま見せてくれた気がします。もうひとつの糸だったAIコード貢献の線引きも、GCCは一律拒否と踏み込み、Debianは5つの提案を並べて審議中と、答えの出し方そのものが割れています。数字も線引きも、鵜呑みにせず自分の頭で考えるための材料にしたいところです。皆さんの環境では、この2本の糸をどこで引きますか？

## 参考リンク

- NVD — CVE-2026-66066（CVSS v4.0 9.5・確定値） https://nvd.nist.gov/vuln/detail/CVE-2026-66066
- GitHub Advisory GHSA-xr9x-r78c-5hrm https://github.com/advisories/GHSA-xr9x-r78c-5hrm
- Rails公式フォーラム — CVE-2026-66066アドバイザリ https://discuss.rubyonrails.org/t/cve-2026-66066-possible-arbitrary-file-read-and-remote-code-execution-in-active-storage-variant-processing/91432
- Phoronix — GCC AI生成コード拒絶ポリシー報道 https://www.phoronix.com/news/GCC-Declining-AI-Contributions
- Phoronix — COSMIC Epoch 1.5リリース報道 https://www.phoronix.com/news/COSMIC-Epoch-1.5-Released
- Debian公式投票ページ — vote_002（5提案全文・賛同者一覧） https://www.debian.org/vote/2026/vote_002
- Hacker News — Debian GRスレッド（158pt・141コメント） https://news.ycombinator.com/item?id=49050859
- NVD — CVE-2026-20316（CVSS v3.1 5.3・確定値） https://nvd.nist.gov/vuln/detail/CVE-2026-20316
- CISA KEV追加アラート（2026-07-29追加・2026-08-01対応期限） https://www.cisa.gov/news-events/alerts/2026/07/29/cisa-adds-one-known-exploited-vulnerability-catalog
