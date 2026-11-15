---
title: "Cursor の偽 Claude Code 拡張は最大5,000人が受け取った可能性、Check Point の PHP2Shell 連鎖は ESXi のワイパーまで、カーネルメンテナの Stoakes 氏は担当外のレビューを縮小、Trezor Safe 5 の3台にインプラント、Rust 標準ライブラリの報告は公開時点で2件が未解決（2026/11/16 Linux・OSSトレンド）"
date: 2026-11-16T00:00:00+09:00
draft: false
tags: ["セキュリティ", "サプライチェーン", "Cursor", "Claude Code", "Check Point", "PHP", "ESXi", "Linux カーネル", "AI", "Trezor", "Rust"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

公式の配信元、本物の製品、安全な言語。こうしたラベルを信じる前に、最後に確かめているのは誰の目なのか。2026年11月16日（月）の動画は、この問いを軸に5本を並べました。

Cursor では、公式のマーケットプレイスのキャッシュに、改ざんされた Claude Code の拡張機能が置かれました。Check Point のゲートウェイには、PHP の脆弱性から入り、root を取り、ESXi のデータ破壊まで進んだ事例が報告されています。Linux カーネルでは、メモリ管理のメンテナが、AI 生成のパッチの流入を理由の一部に挙げて、担当外のレビューを縮小しました。Trezor Safe 5 では、再販業者経由の3台に、画面を盗み見る追加の基板が見つかっています。Rust の標準ライブラリでは、Microsoft の研究チームが、安全な Rust のコードだけで未定義動作を起こせる件を含む、サウンドネスのバグを報告しました。

この5本に共通点を見るのは書き手の考察で、取り上げた各社や報告者がそう述べているわけではありません。動画の訂正は、各節の末尾に置きました。内容は2026年11月16日の朝（日本時間）に確認したものです。時点で変わる値には時刻を添えます。Check Point・CISA の KEV・NVD は6:51〜7:15、Rust の Issue と PR は6:53、カーネルの件は6:50〜7:00の確認です。Cursor と Trezor の公式ブログは、同じ日の朝に全文を確認しました。

{{< youtube "sRp4p6diRJM" >}}

## 1. Cursor の侵害と、偽の Claude Code 拡張

Cursor は、10月29日に、Anthropic の Claude Code 拡張機能の改ざん版が、Cursor のマーケットプレイスを配信するキャッシュに置かれたと[通知](https://cursor.com/blog/claude-code-extension-security-notice)しました。Cursor は、Anthropic はこのコピーを公開しておらず、Anthropic の製品の脆弱性でもない、と書いています。

改ざん版が公開されていたのは、米国太平洋夏時間の10月29日 2:27〜13:35です。日本時間では、10月29日（木）18:27〜10月30日（金）5:35にあたります。版は 2.1.312 と 2.1.313で、通知は Windows と macOS 向けとしています。Cursor の[詳報](https://cursor.com/blog/security-incident-update)（11月13日付）は、公開されていた時間を約11時間と書き、10月29日に拡張機能の特定のキャッシュ版を要求した利用者のうち、最大5,000人が不正なビルドを受け取った可能性がある、としています。5,000人は Cursor が示した上限で、実際に受け取った人数ではありません。

詳報が示す経緯は、次の順です。以下は Cursor の記述で、段階の数え方は Cursor のものではありません。

- 出発点は Fireworks です。Cursor が Fireworks に発行したアクセスキーが、Fireworks 側で露出し、攻撃者はそのキーで、Cursor が共有に使っていた読み取り専用のストレージから、データをコピーしました。露出の原因は書かれていません。Fireworks が侵害された、とは書かれていません
- コピーされたのは、主に2025年の、Privacy Mode を使っていないセッションの限られたトレース（コーディングエージェントの記録）です。その一部に、マスクされていない認証情報が含まれていました。Privacy Mode を使っていない利用者のうち、トレースが露出したのは0.05%未満、API の認証情報が露出した顧客は0.01%未満です
- その認証情報を起点に、攻撃者は Cursor が使う一部の SaaS ツールに到達しました
- 10月29日には、Cursor の内部システムから露出したデータにあった認証情報を使い、改ざん版を配信キャッシュに直接置きました。この認証情報が SaaS ツールから得たものかは、詳報に書かれていません

詳報は、影響を受けなかったものも挙げています。Cursor を動かす本番のシステム、Cursor のアプリ本体と公式の更新（署名鍵の露出もなし）、上流の Open VSX、Privacy Mode を使っている人のプロンプトとコードです。最後の攻撃者の活動は11月1日で、ブロックされた、と書かれています。Cursor は、インシデントは封じ込められたと考えている、としています。

通知によると、改ざん版は、端末と利用者の情報を集め、攻撃者の SSH 鍵の追記と SSH の有効化、リバース SSH トンネルを開く試みを行い、そのトンネルを永続化しようとしました。管理者権限で Cursor を起動していたような特殊な場合を除き、コードの誤りのため、この段階は失敗する、とも書かれています。ただし通知の後段は、SSH の有効化には管理者権限が要り、多くの macOS と Windows の端末では失敗してトンネルは使えないとしたうえで、拡張は攻撃者の SSH 鍵を追記し、永続化の仕組みを置き、端末の情報を攻撃者へ送った、と書いています。失敗していても、対処の手順は実行するよう求めています。拡張機能を削除するだけでは足りない場合がある、とも書かれています。手順は Cursor の通知にあり、この記事では書きません。

動画の訂正です。

- 動画のパネルは、「鍵の追加・SSH 有効化は多くが不発」と紹介しました。Cursor の通知で、多くの端末で失敗するとされたのは、SSH の有効化とトンネルです。攻撃者の鍵の追記、永続化の設置、端末情報の送信は行われた、と書かれています（[Cursor の通知](https://cursor.com/blog/claude-code-extension-security-notice)）。管理者権限で起動した場合を除いて失敗する、という発言自体は、通知の文言のとおりです。

## 2. Check Point の PHP2Shell と ESXi のワイパー

Check Point Research（CPR）は、11月12日付の[記事](https://research.checkpoint.com/2026/php2shell-exploitation-on-check-point-gateway/)で、Check Point のセキュリティゲートウェイへの攻撃を報告しました。攻撃は2つの波に分かれます。第1波は10月30日で、イスラエルの組織を狙い、一部には破壊を伴う活動がありました。第2波は11月2日で、第1波で狙われたイスラエルの組織の一部と、世界各地の組織を狙っています。CPR は第2波について、破壊の証拠はなく、イスラエルに焦点を当てた様子もない、と書きます。どちらの波も、特定の業種を狙った様子はなく、機会を狙った初期侵入の試みに見える、というのが CPR の見方です。

CPR が調査した1件の侵入の流れは、次のとおりです。以下は CPR が時系列で書いた内容を、書き手が要約したものです。

- 入口は、Mobile Access ポータルへの PHP2Shell（CVE-2026-109618 と CVE-2026-109619 に関連する活動）です
- 続けて、CVE-2026-123039 で、ポータルのサービスアカウントから root へ昇格しました
- Web シェルとバックドア（TSGA）を置き、内部の探索を行い、SSH で VMware ESXi のホストへ移り、ワイパー（destroy_v6）を実行しました

ESXi まで到達したのは、CPR が調査したこの侵入の話で、すべての被害組織が ESXi まで到達されたとは書かれていません。破壊が確認されたのは、第1波の一部の組織です。動作の詳細や、侵入の痕跡の値は、この記事では書きません。CPR と Check Point の案内を見てください。

脆弱性は3件です。

- CVE-2026-109618 と CVE-2026-109619 は PHP の脆弱性で、CISA の KEV の説明は、どちらも認証なしの遠隔コード実行です。KEV の名称は、前者が PHP Memory Corruption Vulnerability、後者が PHP Stale Internal Request-State Vulnerability です。後者は、解放済みのリクエストメモリを指す、古い（stale）内部状態が残る問題です。NVD の採点は、[CVE-2026-109618](https://nvd.nist.gov/vuln/detail/CVE-2026-109618) が CVSS v3.1 で 9.8、[CVE-2026-109619](https://nvd.nist.gov/vuln/detail/CVE-2026-109619) が CVSS v3.1 で 8.1 です。PHP（CNA）は、どちらも CVSS v4.0 で 9.2 としています。KEV には10月26日に追加され、期限は10月29日でした。PHP2Shell の第一報は、[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)で扱っています
- CVE-2026-123039 は、Check Point の Gaia OS の DynamicCLI の脆弱性で、ローカルのソケットが誰でも書き込める状態で作られ、接続元を認証しない、という内容です。[NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-123039) では、Check Point（CNA）が CVSS v3.1 で 7.8 と採点しています。NVD 自身の分析は、確認時点で進行中です。KEV には11月13日（米国の日付）に追加され、連邦機関の期限は11月16日（月）です。悪用には、機器上でコードを実行できるローカルの権限が要ります。Check Point の[ナレッジ記事（sk1000362）](https://support.checkpoint.com/results/sk/sk1000362)は、この脆弱性への実際の悪用を、"a couple of dozen customers" に対して観測した、と書いています

sk1000362 によると、影響を受けるのは R82.20、R82.10、R82、R81.20、R81.10、R81 で、Spark Firewalls と Smart-1 Cloud は影響を受けません。修正は Jumbo Hotfix Accumulator で、R82.20 は Take 14 以降、R82.10 は Take 52 以降、R82 は Take 132 以降、R81.20 は Take 174 以降です。R81.10 と R81 には、修正のテイクが載っていません。Check Point の[サポートライフサイクルの表](https://www.checkpoint.com/support-services/support-life-cycle-policy/)では、サポートの終了は R81.10 が2026年3月、R81 が2024年10月です。書き手の考察ですが、この2つの版を使っているなら、sk の対象外であることを前提に、移行の計画を持っておく必要があります。暫定策として、dynamic_server プロセスを止める方法が sk に載っています。止めると Dynamic CLI の一部のコマンドが失敗する、との注記があります。手順は sk を見てください。この Jumbo Hotfix が、PHP2Shell の2件の修正も含むかは、sk に記載がなく、確認できていません。

帰属は、CPR も確定していません。TSGA と TSProxy は、PhiliKit というマルウェアフレームワークの改変版で、コードや設定を共有する、と CPR は書きます。PhiliKit は、Ivanti の VPN 機器を狙う攻撃で、2026年2月に報告されたものです。ESET は PhiliKit を中国系の活動に関連づけていましたが、CPR は、今回の作戦の実態を高い確度では評価できない、としています。イスラエルへの集中やデータ破壊という動きは、既知の中国系グループとは完全には合致しないように見える（"do not appear to fully align"）と書き、偽旗、単なる初期アクセスの仲介、目くらましの可能性も挙げます。動機も、証拠からは確定できない、というのが CPR の評価です。

攻撃は、CPR によると、セキュリティの修正が出てから約1週間後に始まっています。どの修正を指すかは、CPR の文面では分かりません。PHP の修正は10月21日、CVE-2026-123039 の sk の作成は11月8日で、攻撃の開始（10月30日）より後です。PHP2Shell の悪用の試みは、Amazon が、10月17日付のものを1件確認しています（[AWS のブログ](https://aws.amazon.com/blogs/security/amazon-threat-intelligence-identifies-php2shell-exploitation-prior-to-public-disclosure-in-madpot/)、10月21日付）。成功しえたかは、不明とされています。10月27日の記事と同じ書き方です。10月30日の記事は、同じ PHP2Shell を PAN-OS 側で扱っています。両者の関係は、一次の資料に書かれていません。

動画の訂正です。

- 動画では、「その4日前には悪用の試みが始まっていました」と紹介し、パネルにも「悪用の試みは4日前から」と出しました。Amazon が確認したのは、10月17日付の悪用の試み1件で、成功しえたかは示されていません（[AWS のブログ](https://aws.amazon.com/blogs/security/amazon-threat-intelligence-identifies-php2shell-exploitation-prior-to-public-disclosure-in-madpot/)）。

## 3. カーネルメンテナの Stoakes 氏が、担当外のレビューを縮小

The Register は、11月13日 15:28（UTC。日本時間では11月14日（土）0:28）の[記事](https://www.theregister.com/ai-and-ml/2026/11/13/another-linux-kernel-developer-steps-back-from-some-duties-due-to-overload/5309628)で、Arm のプリンシパルソフトウェアエンジニアの Lorenzo Stoakes 氏が、メーリングリストへの投稿で、担当外のレビューを縮小すると書いたと伝えました。LKML の投稿本文は、確認時点で取得できず（アクセス拒否）、以下の発言は、The Register が引用した範囲です。投稿の日付も確認できておらず、The Register の書き方は「今週の前半（earlier this week）」です。

The Register の引用によれば、Stoakes 氏は、メモリマッピング、その排他制御、madvise、逆マッピングの4つのメンテナ職を持っています。減らすのは、自分が担当する領域以外のレビューです。"I am retaining my maintainerships and have no plans on giving those up" と、メンテナ職は続けると書いています。縮小の理由は、"Given the current throughput in the kernel resulting from AI-generated series, I unfortunately lack the bandwidth to generally be able to offer review except in those areas I maintain." と引用されています。目的は "I just want my inbox to be less horrendous." だとされます。

The Register は、続けて Stoakes 氏の次の発言を引用しています。"And yeah, AI is part of the reason; in general, it's gone from 'once a week' to 'daily' to 'half of what I see in review'." AI は理由の一部で、週に1回から毎日、そしてレビューで目にするものの半分へ増えたのは、レビュー対象全体（in general）です。AI 生成のパッチだけの増え方ではありません。メモリ管理には "the AI wave is hitting [memory management] across the board, really" とも述べています。見出しは "Another"（また）で始まりますが、1人目が誰かは、記事の本文に書かれていません。

Torvalds 氏は、Linux 7.4-rc2 の[告知](https://lkml.iu.edu/2611.1/01530.html)（米国東部時間の11月8日 19:47。日本時間では11月9日 9:47）で、BPF 側では、修正が新しい報告より速く入り始めたと、BPF の担当者が主張していると書き、本当なら素晴らしい、と続けました。ほかの多くの領域はまだそこまで来ていないと見て、"we _may_ be starting to see the tide starting to turn"（潮目が変わり始めたかもしれない）と、留保付きです。rc2 の変更の多くは "various AI fixes" によるもの、とも書いています。The Register は、Open Source Summit（10月）で Greg Kroah-Hartman 氏が、"All of the maintainers are burnt out, and we have been for ten years." と話したことも伝えています。

The Register が11月9日に Torvalds 氏の告知を伝えた[記事](https://www.theregister.com/security/2026/11/09/linus-torvalds-sees-signs-ai-prompted-patch-flood-has-peaked/5308345)は、4月に Anthropic が Mythos のバグ発見モデルを出したことに触れています。これは The Register の見立てで、Stoakes 氏の説明ではありません。Stoakes 氏の件の記事に、Mythos の語はありません。

動画の訂正です。

- 動画では、Stoakes 氏が「AIが作ったパッチの増え方」として、週に1回から毎日、レビュー対象の半分に増えたと話したと紹介しました。Stoakes 氏は、AI は理由の一部だと述べたうえで、レビュー対象全体（in general）が、週に1回から毎日、レビューで目にするものの半分へ増えたと語っています（The Register への発言。[The Register](https://www.theregister.com/ai-and-ml/2026/11/13/another-linux-kernel-developer-steps-back-from-some-duties-due-to-overload/5309628)）。
- 動画では、背景に「Anthropicが2026年4月に出したMythos」の広がりがあると紹介しました。Mythos は、4月に発表されたプレビューで、一般には公開されていません。また、これを背景とするのは The Register の見立てで、Stoakes 氏の説明ではありません（[The Register](https://www.theregister.com/security/2026/11/09/linus-torvalds-sees-signs-ai-prompted-patch-flood-has-peaked/5308345)）。

## 4. Trezor Safe 5 のハードウェアインプラント

Trezor は、11月12日付の[ブログ](https://trezor.io/blog/news/our-cryptobilis-investigation-what-we-found-and-what-weve-changed)で、CryptoBilis から買った Trezor Safe 5 の3台にインプラントが入っていたと確認しました。実機を解析したのは、10月に報告された1台で、残る2台は所有者が送った写真で特定しました。3台とも、2026年8月20日〜9月23日に、CryptoBilis の Tokopedia と Shopee の店舗、または CryptoBilis から直接、買われたものです。

最初の報告を Trezor が受けたのは10月28日で、[最初の警告](https://trezor.io/blog/news/implant-reported-in-a-trezor-sold-by-cryptobilis)は10月30日に公開されました。CryptoBilis は、10月まで東南アジアの公式の再販業者でした。Trezor は10月9日に、CryptoBilis を再販網から外しています。動画は「インドネシアの再販業者」と紹介しましたが、Trezor の一次の表記は東南アジアで、インドネシアは BleepingComputer の表現です。

Trezor の説明では、インプラントは、本体のメインボードと画面の間に挟まれた追加の回路基板です。画面に表示される内容を、入力した内容も含めてコピーするだけで、ファームウェアや Secure Element には手を加えません。リカバリーワードが画面に出ると、それを認識して保存し、パスフレーズも、画面に出る場合は同様に取ります。暗号化したうえで、モバイル通信で攻撃者のサーバへ送り、つながらなければ保存して再試行します。Trezor は、攻撃者を助ける、あるいは影響を受けた顧客を危険にさらす技術的な詳細は公開しない、としています。

対策と対応は次のとおりです。

- ファームウェア 2.13.1（11月11日公開）は、見つかったインプラントが、この版を動かす端末で何も取得できなくなる保護を含みます。ただし、更新前に取得されたウォレットのバックアップは、更新では守れません。CryptoBilis で買った人は、新しいシードの新しいウォレットへ資金を移すべきだ、と Trezor は書いています
- 2026年3月以降に CryptoBilis で Trezor を買った人は、新しい端末の対象です
- Trezor は、再販網を約80%減らしました。外した業者は、信頼でき、直接の脅威もなかったが、今後すべての再販業者に課す厳しい手順には合わなかった、と説明しています
- Trezor は、ほかの再販業者の端末や、Safe 5 以外の機種では、見つけていません。資金を失ったという報告もありません。ここまでが、11月12日の記事の時点です。Trezor は、これまでに48人の購入者から連絡があり、端末をラボで、または内部の写真で確認している、と書いています。48は購入者の数で、台数ではありません
- Trezor は、このインプラントは Ledger の端末で見つかったものと同じ仕組みで、Safe 5 の画面に合わせたものだと書いています

利用者が自分で確かめる方法について、Trezor は、重さで確かめることはできず、自分で端末を検査する確かな方法もない、と書いています（10月30日の記事）。疑わしい端末は、Trezor から次の指示があるまで、設定も使用もしないよう案内しています。次に買う場合は、trezor.io から直接買うよう案内しています。リカバリーフレーズは誰にも教えない、Trezor がそれを尋ねることはない、とも書かれています。改ざんがいつ、どこで行われたかは、Trezor は示していません。確認した2本の記事に、その後の追記は見当たりませんでした。

動画の訂正はありません。

## 5. Rust 標準ライブラリのサウンドネスのバグ（FORGE Lab の報告）

Microsoft の FORGE Lab の Yechan Bae 氏は、11月9日付の[記事](https://forge-blog.github.io/posts/rust-std-memory-safety/)で、Rust の標準ライブラリ（std と core）の unsafe なコードにあるサウンドネスのバグを報告しました。サウンドネスは、安全な Rust のコードから使う限り、未定義動作を起こさない、という約束です。記事は、安全な Rust だけで書いたコードから未定義動作を起こせる件も含む、としています。未定義動作の定義は、[Rust のリファレンス](https://doc.rust-lang.org/reference/behavior-considered-undefined.html)にあります。

一部のバグは、AI を使う脆弱性スキャナ Hyenas（研究用のバージョン）の助けで見つかりました。記事は、研究者が、元のコードを調べ、バグを再現し、セキュリティ上の影響を評価し、Rust のメンテナと協力して報告と修正を進めた、と書いています。FORGE は、バグを3つの型に分けています。パニックしないことへの過信、利用者が書いた実装が正しいことへの過信、基盤のシステム（OS や C ライブラリ）への過信です。以下の件は、再現のコードを含まない範囲で書きます。

- アロケータが巻き戻る（パニックする）と、BTreeMap の挿入などで安全性が崩れる件があります。FORGE は、1つずつ直すのではなく、Allocator の安定化で、実装側がトレイトのメソッドと drop から巻き戻らないことを要件に加える形を取った、と書いています。この安定化は [PR #156882](https://github.com/rust-lang/rust/pull/156882) で、Rust 1.100.0 に入りました。Rust 公式ブログの告知の日付は11月12日です（GitHub のリリースの公開は、日本時間で11月13日 3:19）。11月12日の記事は、公開前の確認で「予定」と書いており、その後に公開されたことになります。BTreeMap の挿入の件の Issue 自体は、確認時点でも未解決です
- str の置換で、nightly の機能で作った独自のパターンが、事実と違う値を返すと、不正な UTF-8 の文字列ができる件は、型で UTF-8 を保証する形に直されました（[PR #156556](https://github.com/rust-lang/rust/pull/156556)、2026年5月にマージ）
- スライスの `join` には、過去の修正の取り残しがありました。FORGE は、2020年に CVE-2020-36323 として報告した問題の修正が、この経路を覆っていなかったと書いています。2026年4月に、同じ関数への追加の修正が入りました（[PR #155708](https://github.com/rust-lang/rust/pull/155708)）
- Unix で、子スレッドが process::exit を呼ぶと、メインスレッドのシグナル用の予備スタックが片付けられてしまう件があります。終了処理が終わるまでの短い間に、メインスレッドがスタックを使い切ると、Rust のメッセージではなく、単なるセグメンテーション違反で落ちます。約11年前から標準ライブラリにあった問題で、修正は [PR #161037](https://github.com/rust-lang/rust/pull/161037) で入り、マイルストーンは Rust 1.99.0 です。FORGE は、この件について、調べた条件のもとで、信頼できる悪用の経路は見つからず、実用的な悪用は考えにくいと評価しています。この評価は、ほかの件には自動では当てはまらない、とも書いています
- exec と環境変数の件は、失敗した2つの exec が競合すると、解放済みの配列を指すポインタが、あとで読まれうるという内容です。11月16日 6:53 の時点で、[修正の PR #157144](https://github.com/rust-lang/rust/pull/157144) は、オープンのままです

FORGE の記事は、公開時点で、FORGE が報告した問題のうち2件が未解決だと書いています。どの2件かは、記事に番号が書かれていません。記事には、ほかの人が報告した件も含まれます。スレッドローカルのデストラクタの二重解放は、別の人の報告で、修正案の [PR #165125](https://github.com/rust-lang/rust/pull/165125) は、確認時点でオープンです。Pattern まわりの件も、FORGE 以外の報告です。公開時点では未解決でしたが、11月10日に、そのうち2件がクローズされ、1件が未解決のまま残っています。FORGE は、標準ライブラリのサウンドネスのバグが、そのまま、それを使うプログラムの脆弱性になるとは限らず、記事の件は、いずれも引き金に特殊な条件が要る、と書いています。

書き手の考察ですが、10月27日の記事で扱った Wasmtime の件のように、安全を保つための検査や約束が、条件によっては効かなくなる事例は、言語や実行基盤を変えて繰り返し報告されています。今回の件では、その約束を確かめる作業を、FORGE の研究者が、AI のスキャナも使いながら続けていたことが、報告から読み取れます。

動画の訂正です。

- 動画では、str::join に「2020年に CVE-2020-36323 として直した問題」の取り残しがあったと紹介しました。CVE-2020-36323 は、2020年12月に報告された問題で、修正は Rust 1.52.0（2021年）です（[RustSec](https://rustsec.org/advisories/CVE-2020-36323)）。FORGE の記事も、2020年は「報告した」年として書いています。関数は、一次の資料では `join`（スライスの join）の表記です。

## まとめ

Cursor の改ざん版は、最大5,000人が受け取った可能性があり、影響しなかったものは、Cursor が個別に挙げています。Check Point の件は、CPR が調査した1件の侵入の流れで、ESXi の破壊が確認されたのは、第1波の一部の組織です。Stoakes 氏の件は、LKML の投稿本文を取得できておらず、The Register の引用に基づきます。Trezor は、確認できた台数が3台で、48人の確認が続いています。Rust は、公開時点で FORGE が報告した2件が未解決で、確認時点の状態は件ごとに違います。

手元で確かめておくものは次のとおりです。

- Cursor: 10月29日の前後に、Claude Code 拡張の 2.1.312 または 2.1.313 を入れた覚えがある場合は、Cursor の通知にある確認と対処の手順を実行する。拡張機能の削除だけでは足りない場合がある
- Check Point: sk1000362 で、自分の版と製品が対象かを確かめ、Jumbo Hotfix Accumulator の適用状況（R82.20 は Take 14 以降など）を見る。R81.10 と R81 は修正のテイクが載っていない。Mobile Access ポータルを外部に公開しているかを確かめる。PHP2Shell の2件への対応は、sk に記載がなく、別に確かめる
- Trezor: CryptoBilis で買った場合は、Trezor の案内のとおり、新しいシードの新しいウォレットへ資金を移す。端末はファームウェア 2.13.1 に更新する。購入経路は、Trezor の案内を確かめる
- Rust: 標準ライブラリのバグは、版ごとに修正が入る（signal stack は 1.99.0、Allocator の約束は 1.100.0）。exec と環境変数、スレッドローカルの二重解放の修正の PR は、確認時点でオープンなので、追跡する

## 参考リンク

- [Cursor: Claude Code 拡張機能のセキュリティ通知（10月29日）](https://cursor.com/blog/claude-code-extension-security-notice)
- [Cursor: セキュリティインシデントの更新（11月13日）](https://cursor.com/blog/security-incident-update)
- [Check Point Research: PHP2Shell の Check Point ゲートウェイへの悪用](https://research.checkpoint.com/2026/php2shell-exploitation-on-check-point-gateway/)
- [Check Point sk1000362（CVE-2026-123039）](https://support.checkpoint.com/results/sk/sk1000362)
- [NVD の CVE-2026-123039](https://nvd.nist.gov/vuln/detail/CVE-2026-123039)
- [The Register: Stoakes 氏の業務縮小（11月13日）](https://www.theregister.com/ai-and-ml/2026/11/13/another-linux-kernel-developer-steps-back-from-some-duties-due-to-overload/5309628)
- [Torvalds 氏の Linux 7.4-rc2 の告知](https://lkml.iu.edu/2611.1/01530.html)
- [Trezor: CryptoBilis の調査（11月12日）](https://trezor.io/blog/news/our-cryptobilis-investigation-what-we-found-and-what-weve-changed)
- [Trezor: 最初の警告（10月30日）](https://trezor.io/blog/news/implant-reported-in-a-trezor-sold-by-cryptobilis)
- [FORGE Lab: Rust 標準ライブラリのメモリ安全性のバグ](https://forge-blog.github.io/posts/rust-std-memory-safety/)
- [Rust の PR #156882（Allocator の安定化）](https://github.com/rust-lang/rust/pull/156882)

（2026/11/16 Linux・OSSトレンド）
