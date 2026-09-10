---
title: "守ってくれていた仕組みに、期限が来た日 — OpenSSL 3.0のEOL、CERNの2,200台、消せるようになったGIL（2026/9/11 Linux・OSSトレンド）"
date: 2026-09-11T00:00:00+09:00
draft: false
tags: ["セキュリティ", "OpenSSL", "EOL", "CERN", "Debian", "KDE", "KWallet", "Rust", "Python", "free-threading", "オープンソース"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

守ってくれていた仕組みには、たいてい期限があります。

暗号ライブラリのサポート期間、ディストリビューションが面倒を見てくれる範囲、インタプリタが黙って肩代わりしてくれていた排他制御。どれも「あるのが当たり前」として使っているうちは意識しません。意識するのは、それが終わると告げられたときです。

今日の5本は、まさにその瞬間を切り取ったものが並びました。サポートが切れた暗号ライブラリ、コンパイラフラグひとつで居場所を失った旧世代ハードウェア、25年分の負債を片付けにかかったパスワード管理基盤、10年待って安定化にたどり着いた型、そして「GILが守ってくれていた」ことに今さら気づくPythonのマルチスレッド。

期限が来たとき、選べるのは2つです。動き続けるか、踏み出すか。どちらを選ぶにせよ、まず期限が来ていることに気づかないと選択肢にすらなりません。

{{< youtube "IsWeg93isl8" >}}

## 1. OpenSSL 3.0 LTS がサポート終了 — 上流のパッチが、もう来ない

まずは今日いちばん静かで、いちばん広い範囲に効く話からです。

 **2026年9月7日** をもって、OpenSSL 3.0 LTS のサポート期間が終了しました。[OpenSSL 公式のリリース戦略](https://openssl-library.org/policies/releasestrat)には、LTS について「Every two years we designate a release as a Long Term Support (LTS) release that will be supported for at least 5 years.」と書かれています。つまり2年ごとにLTSを指定し、最低5年は面倒を見る。そして同じページには「During the final year of support, we do not commit to anything other than security fixes.」ともあります。最後の1年はセキュリティ修正しか約束しない、という運用です。

3.0 は2021年9月にリリースされたLTSでしたから、この5年をきっちり使い切って期限に到達したことになります。同じページのバージョン一覧では、3.0 のサポート終了が2026年9月7日、次期LTSである 3.5 が2030年4月8日まで、最新メジャーの 4.0 が2027年5月14日までと明記されています。移行先として素直なのは 3.5 LTS です。

3.0 系の最後のリリースは [3.0.22](https://github.com/openssl/openssl/releases/tag/openssl-3.0.22) （2026年8月25日）でした。ここで5件のCVEが修正されています。[OpenSSL 3.0 シリーズの公式脆弱性一覧](https://openssl-library.org/news/vulnerabilities-3.0/)によれば、CMSの鍵アンラップ処理におけるヒープバッファオーバーフロー（CVE-2026-63072、Moderate）と、細工された `protectionAlg` によるCMPサーバーの無効ポインタ逆参照（CVE-2026-63076、Moderate）の2件がModerate、残る3件——DTLSレコードバッファリングでの過剰なメモリ消費（CVE-2026-54874）、CMPのExtraCertsキャッシュの無制限な増大（CVE-2026-63074）、空の暗号文使用時のAEAD認証タグ偽造（CVE-2026-75803）——がLowという評価です。

問題は、この 3.0.22 が「最後」だという点です。EOL当日に何かが壊れるわけではありません。恒久化するのは **これから見つかるCVEに、上流のパッチが存在しない** という状態のほうです。脆弱性の存在はNVDで公開され、PoCはGitHubに上がる。しかし 3.0 を使い続けている側に修正版は来ない。この非対称が固定される、というのがEOLの実体です。

そして厄介なのは、多くの人が自分が当事者だと気づいていないことです。[Ubuntu 22.04 の openssl パッケージ](https://packages.ubuntu.com/jammy/openssl)は 3.0.2 系、[Debian 12 bookworm の openssl](https://packages.debian.org/bookworm/openssl)は 3.0.20 系。どちらも現役で動いているサーバーが山ほどあるはずです。ディストリビューション自体のサポートは続くので、外から見れば「サポート内のOS」です。ところが中身の暗号ライブラリのほうは、上流のサポートが先に切れている。ディストリビューションのベンダーが独自にバックポートする体制はありますが、上流の修正がない状態でどこまで追随できるかは、契約や体制次第としか言えません。

手元の確認はワンライナーで済みます。

```bash
openssl version -a
```

出力が `OpenSSL 3.0.x` なら、この話の当事者です。移行するなら、エンジンAPIからプロバイダAPIへの書き換え、デフォルト無効化された弱い楕円曲線グループの互換性確認、FIPS環境ならFIPSプロバイダの再確認——このあたりが実作業として待っています。「バージョンを上げるだけ」で済まないからこそ、期限が来る前に着手する価値がありました。今からでも、期限が来ていることを知っているのと知らないのとでは大違いです。

## 2. CERN が加速器制御の2,200台をDebian 13へ — 引き金はコンパイラフラグひとつ

期限を突きつけられて「踏み出す」ほうを選んだ組織の話です。

CERNが、加速器制御に使っている産業用コンピューター2,200台超をRHEL系からDebian 13「Trixie」へ移行する——[Phoronix が2026年9月2日に報じた](https://www.phoronix.com/news/CERN-Goes-Debian-Leaving-RHEL)内容によれば、「all 2,200+ of their industrial computers and embedded systems running Debian 13」が対象です。発表の場は [MiniDebConf Winterthur 2026](https://ch2026.mini.debconf.org/talks/6-controlling-cerns-accelerators-with-debian/)、2026年8月30日の「Controlling CERN's Accelerators with Debian」というトークで、登壇したのは Federico Vaga と Nikos Tsipinakis の両氏です。

直接の引き金として名前が挙がっているのが `-march=x86-64-v2` です。Phoronix の記事では、CERNのエンジニアがこのコンパイラフラグのデフォルト採用を旧ハードウェアに対する「forced obsolescence」（強制的な陳腐化）と表現した、と伝えられています。x86-64-v2 はSSE4.2やPOPCNTといった命令セット拡張を要求するので、古い64bit CPUではそもそもバイナリが動きません。研究所の制御系には、放射線耐性部品を積んだカスタム基板のように「置き換えたくても置き換えられない」機材が普通に居座っています。

規模とコストの数字は [Linuxiac の記事](https://linuxiac.com/debian-13-is-taking-over-2200-control-systems-across-cern/)が詳しく、2,200台超のコンピューターが約17,000台のデバイスを制御し、施設はおよそ43平方キロメートルに広がっているとされています。RHELを続けるためにハードウェアを設計し直す場合の試算は「roughly CHF 5.4 million」、再設計が必要なボードは11枚、しかも成功率は「an optimistic success rate of only around 20%」——楽観的に見て2割。この数字を突きつけられれば、OSを乗り換えるほうが合理的だという判断にも頷けます。

Debian 13 が選ばれた理由は、マイクロアーキテクチャの下限を切り上げていないこと、そしてリアルタイム性の要求をメインラインのカーネルで満たせるようになったことです。同じ Linuxiac の記事によれば、移行作業はOSコンポーネントの配布方法、フロントエンド計算機のブートのしかた、デバイスドライバの統合方式にまで及んでいて、単なるパッケージの入れ替えではありません。加速器が動いている期間は更新をかけられないので、シャットダウン期間に合わせた段階投入になります。

ひとつ補足しておくと、これは「CERNがRHELを全捨てした」話ではありません。Phoronix も、移行のフォーカスは産業用の加速器制御コンピューターであり、データセンターと実験計算環境はRHEL/AlmaLinuxのままだと明記しています。長寿命ハードウェアと心中する覚悟がある領域だけが、切り替えの対象になっている。

同じ構図——10年15年と同じ機材を使い続ける組み込み・産業制御の現場——は、どの業界にもあると思います。RHEL 10 ではさらに上のマイクロアーキテクチャが要求されると言われていますから、似た判断を迫られる組織はこれから増えるのではないでしょうか。もっともこれは私の見立てで、CERN以外の事例が積み上がっているわけではありません。

## 3. KDE Frameworks 6.30.0 — KWalletの大掃除と、KIOの地味に効く改善

ここで少し肩の力を抜いて、デスクトップの話です。

[KDE Frameworks 6.30.0](https://kde.org/announcements/frameworks/6/6.30.0/) が2026年9月9日にリリースされました。今回の目玉は、KDEのパスワード管理基盤であるKWallet周辺の整理です。公式アナウンスの変更一覧を眺めると、削除・非推奨化の項目が並んでいるのが分かります。「Ksecretd: Drop KWalletSessionStore」「Drop unused handleSession from ksecretd」「Drop pseudo access control for wallet」といった削除に加えて、`Wallet::requestChangePassword()` 、 `Wallet::lockWallet()` 、 `Wallet::sync()` の3つが非推奨（deprecate）になっています。

個人的にいちばん効きそうだと思ったのが「Drop Close When Idle handling from kwalletd」です。一定時間アイドルだとウォレットを自動的に閉じる挙動が落とされました。長いファイルコピーの最中に突然パスワードを求められる、という嫌な体験に心当たりのある方は、恩恵を受ける側だと思います。

もうひとつが認証まわりの修正で、「Ksecretd: Make sure collection is reported as unlocked after PAM unlock」と「Fix logic errors in internalOpen」が入りました。ログイン時のPAM認証でウォレットが開いているはずなのに、コレクションが「ロック済み」と報告され続けるケースがあった、というものです。あわせて「Fix memory leaks in kwalletd」も入っています。25年近く動き続けてきたコンポーネントの、地に足のついた大掃除という印象です。

KIO側も静かに改善されています。「Properties: show how much room a folder takes up, not only its data」——フォルダのプロパティで、データサイズだけでなく実際にディスクを占有している量を表示するようになりました。スパースファイルや圧縮ファイルシステムで「表示と実態が合わない」と首をかしげたことがあるなら、これが答えです。HTTP周りでは「Http: Keep a large request body out of memory」と「Http: Report how far an upload has got, not what the answer weighs」の2件。大きなリクエストボディをメモリの外に出す変更と、アップロードの進捗を「サーバーの返事の重さ」ではなく「どこまで送れたか」で報告する変更です。プログレスバーが妙な動きをする理由が後者だったと分かると、なんだか腑に落ちます。

派手さはありませんが、こういう「25年分の前提を点検して落とす」作業を誰かがやってくれているから、上のレイヤーが安心して積み上がる。EOLの話の直後に読むと、少し違って見える種類のリリースです。

## 4. Rust の never 型（`!`）が安定化 — 10年かけて、慎重に

型システムの話に移ります。こちらは「期限」ではなく「ようやく届いた」ほうのニュースです。

Rust の never 型、つまり `!` が安定化されました。[PR #155499](https://github.com/rust-lang/rust/pull/155499)（タイトルは "stabilize never type"）が WaffleLapkin 氏によって2026年8月24日にマージされています。`!` は「決して値を持たない型」で、パニックする関数や到達不能なコードを型として表現するために使われます。コンパイラの内部では長らく使われていたのに、stable のコードからは `#![feature(never_type)]` なしには触れませんでした。[トラッキングissue #35121](https://github.com/rust-lang/rust/issues/35121) が立ったのが2016年ですから、実に10年越しです。

このPRがやったことは3つあります。never型の安定化そのもの、`Infallible` を `!` のエイリアスにすること、そして never type fallback を全エディションで `!` に統一すること。3つ目が一番荒っぽい変更です。

そして、ここは正直に書いておく必要があります。PR本文では、この変更は **破壊的変更** として扱われています。crater 実験の結果は「3277 regressed and 0 fixed (9024 total)」——9,024クレート中3,277件で回帰が検出された、という数字です。もちろんこの中には無関係な失敗も混ざるので、そのまま実害の件数と読むべきではありません。それでも「`Infallible` を使っていたコードが一律に得をする」という話ではないことは、はっきりしています。得をするコードもあれば、型推論のフォールバック挙動に寄りかかっていて手直しが要るコードもある。

なぜ10年もかかったのかも、この数字を見れば察しがつきます。型が確定しない文脈で `!` が `()` に暗黙フォールバックする、というかつての挙動に依存したコードが、エコシステムに実在していたからです。だからRustプロジェクトは、まず2024エディション限定でフォールバックを変え、様子を見てから全エディションへ広げる、という段取りを踏みました。安定化を急ぐより互換性を守るほうを優先する——地味ですが、こういう判断の積み重ねが「Rustのコードは壊れにくい」という評判を作っているのだと思います。

nightly で `#![feature(never_type)]` を書いていた人は、フラグを消すだけで済みます。フォールバックに依存していたコードは、型注釈を明示するか、ロジックを見直すことになります。`void` や `never` といった独自のuninhabited型クレートを使っていたコードは、そろそろ標準の `!` に寄せてよい時期でしょう。

作者本人が安定化のブログ記事に付けたタイトルは「[I feel… empty. Just like the never type.](https://blog.ihatereality.space/0C-never-type/)」。10年の重さと軽口が同居していて、いいタイトルだと思いました。

## 5. Python の free-threading — GILが黙って守ってくれていたものが、なくなる

最後は、今日いちばん「気づきにくい期限」の話です。

[PEP 779](https://peps.python.org/pep-0779/) が Final になり、Python 3.14 で free-threaded ビルド（GILなしビルド）が実験段階から **公式サポート** へ昇格しました。ただし今のところデフォルトではなく、選択制です。PEPには段階IIへ進むための基準が書かれていて、シングルスレッド性能の低下は15%までを許容ライン、メモリ使用量の増加は幾何平均で20%以内、という目安が示されています。実測はそこに収まってきており、だからこそ次の段階へ進めた、という流れです。

さて、GILがなくなると何が起きるか。GILは「一度に1スレッドしかPythonバイトコードを実行させない」ためのロックですが、副作用として `dict` や `list` への操作をだいたいスレッドセーフに見せてくれていました。誰も明示的に守っていなかったのに、壊れなかった。free-threading では、この暗黙の保護が消えます。

しかも厄介なことに、消えたことにすぐ気づけません。組み込み型には内部のロックが入りましたが、それはあくまで個々の操作の話であって、`counter[key] = counter.get(key, 0) + 1` のような読んで足して書き戻す複合操作は、依然としてアトミックではありません。GILがあった時代に「たまたま動いていた」コードは、free-threading では「たまたま動くこともある」コードに変わります。これがいちばん質の悪い壊れ方です。

では、どうテストするか。[Python Free-Threading Guide のテスト手引き](https://py-free-threading.github.io/testing/)には、実践的な手段がいくつか挙げられています。ひとつは `sys.setswitchinterval` を極端に小さい値にしてスレッド切り替えを起こしやすくする方法。ガイドでは「You can call `sys.setswitchinterval` before running multithreaded tests to force Python to release the GIL more often」と説明されています。もうひとつが、既存のテストを複数スレッドで同時実行するpytestプラグイン——Quansight Labs の `pytest-run-parallel` 、`pytest-freethreaded` 、unittest向けの `unittest-ft` あたりです。

ここで見落としてはいけない注意書きがあります。同じガイドに「pytest maintainers have explicitly ruled out making `pytest` thread-safe」とあるとおり、pytest 自体はスレッドセーフ化しない方針を明言しています。`pytest.warns` 、 `tmp_path` 、 `capsys` 、 `monkeypatch` などは並列実行の対象外です。「とりあえずテストを並列で回してみる」だけでは足元が崩れる、ということです。

もっと根本的なアプローチもあります。Bernát Gábor 氏の [blanket](https://bernat.tech/posts/blanket-deterministic-threading/) は、`Lock` 、 `RLock` 、 `Barrier` 、 `Event` 、 `Condition` 、 `Semaphore` 、 `BoundedSemaphore` の7つのプリミティブをラップし、テストコード自身がスケジューラとして振る舞う仕組みを提供します。`relay()` でロック取得の順序を、`cycle()` でバリア解放の順序を指定でき、「スレッドBが先にロックを取り、次にAが取る」といった実行順序を宣言的に書けます。しかも本物の `threading` を再実装するのではなく内部で呼び出しているので、テスト時と本番で挙動が乖離しません。レース条件を「運よく再現できたら勝ち」ではなく、狙って再現する方向へ持っていく道具です。

C拡張の側にも影響があります。GILを前提にした拡張モジュールをインポートすると、GILが自動的に再有効化されます。警告が出るので気づけますが、その時点で free-threading の恩恵は消えています。明示的にサポートを表明するには `Py_GIL_DISABLED` を宣言する必要があります。

「ライブラリが対応済み」と「スレッドセーフであることが検証済み」は別物です。ホイールがビルドできることと、競合状態がないことのあいだには、まだかなりの距離があります。

## まとめ

今日の5本を並べ直すと、どれも「これまで誰かが黙って引き受けてくれていた保証が、期限を迎える」話でした。

OpenSSL 3.0 では上流のパッチが、CERNではコンパイラのデフォルトが要求するハードウェアの下限が、KWalletでは25年動き続けた前提が、Rustではフォールバック挙動という暗黙の約束が、Pythonでは GIL という見えない排他制御が。それぞれ形は違いますが、構造はよく似ています。

期限が来たときに選べるのは、動き続けるか、踏み出すかの2つです。CERNは2割の成功率と5.4百万CHFという試算を前に、踏み出すほうを選びました。Rustは10年かけて、壊さずに踏み出す道を探しました。どちらも簡単な選択ではありません。

けれど、いちばん危ないのは3つ目の状態——期限が来たことに気づかないまま動き続けることです。`openssl version -a` を叩くのに10秒もかかりません。今日はそこから始めてもいい日だと思います。

## 参考リンク

- [OpenSSL Release Strategy（LTSポリシーとEOL日付）](https://openssl-library.org/policies/releasestrat)
- [OpenSSL 3.0 シリーズ脆弱性一覧](https://openssl-library.org/news/vulnerabilities-3.0/)
- [Phoronix: CERN Goes Debian, Leaving RHEL](https://www.phoronix.com/news/CERN-Goes-Debian-Leaving-RHEL)
- [MiniDebConf Winterthur 2026: Controlling CERN's Accelerators with Debian](https://ch2026.mini.debconf.org/talks/6-controlling-cerns-accelerators-with-debian/)
- [KDE Frameworks 6.30.0 リリースアナウンス](https://kde.org/announcements/frameworks/6/6.30.0/)
- [rust-lang/rust PR #155499: stabilize never type](https://github.com/rust-lang/rust/pull/155499)
- [PEP 779 – Criteria for supported status for free-threaded Python](https://peps.python.org/pep-0779/)
- [Python Free-Threading Guide: Testing](https://py-free-threading.github.io/testing/)
