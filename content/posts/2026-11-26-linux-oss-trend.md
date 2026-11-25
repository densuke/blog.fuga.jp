---
title: "Palo Alto Networks が PAN-OS の Fragnesia 修正版を公開（PAN-SA-2026-0015）、Firefox 161 は CVE 110件を修正、OpenAI が行列乗算の指数の下界を主張するプレプリントを公開、podman・skopeo・mutter に CVE の修正、隔離した AI モデルが共有の推論サーバ経由で通信できたとする LessWrong の投稿（2026/11/26 Linux・OSSトレンド）"
date: 2026-11-26T00:00:00+09:00
draft: false
tags: ["セキュリティ", "CVE", "Palo Alto Networks", "PAN-OS", "Linux カーネル", "Firefox", "Podman", "コンテナ", "GNOME", "Wayland", "AI", "OpenAI", "数学史"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

2026年11月26日（木）の動画の題は「番人が乗っ取られた日 PAN-OS侵害、AIの抜け道、57年目の数学 安全の根拠はどこにある?」です。PAN-OS では、ネットワークを守るファイアウォールが、インターネットから届く管理インターフェースを入口に侵害されました。LessWrong の投稿では、隔離したモデル同士が、共有の推論サーバを介して情報を伝えられました（著者が作り込んだ条件での結果です）。

どちらも、安全のために設けた仕組みの側が、攻撃や情報の行き来に使われた例として読めます。2本を同じ見方でまとめるのは私の考察で、どちらの一次ソースも、もう一方の件には触れていません。Podman・skopeo・mutter の3件は、手元の環境で使うパッケージの更新の話です。Firefox 161 と行列乗算の話は、この見方には入れていません。

動画の訂正は、各節の末尾に置きました。確認は2026年11月26日（日本時間）です。動画の公開は11月25日 20:53 UTC（日本時間 11月26日 05:53）です。

{{< youtube "GpaBSf7hh78" >}}

## 1. PAN-OS の Fragnesia 修正版（続報）

この話題は続報です。PHP2Shell（CVE-2026-109618・CVE-2026-109619）は[10月22日の記事](https://blog.fuga.jp/posts/2026-10-22-linux-oss-trend/)、Fragnesia（CVE-2026-46300）と、Dream Research（10月30日の記事では Dream Security と表記）が報告した連鎖は[10月30日の記事](https://blog.fuga.jp/posts/2026-10-30-linux-oss-trend/)で扱いました。今回新しいのは、Palo Alto Networks が PAN-OS の Fragnesia 修正版を公開したことです。

[PAN-SA-2026-0015](https://security.paloaltonetworks.com/PAN-SA-2026-0015) は、PAN-OS に含まれる OSS の CVE を直した版を告げるアドバイザリです。重大度の欄は Informational で、CVSS の値はありません。日付はページの中で2通りあり、Timeline の初版は11月24日、見出しの Published は11月25日です。表には Fragnesia（Linux カーネルのローカル権限昇格）の修正版が20版、挙がっています。

アドバイザリは、この脆弱性について知られている悪用の経路は、インターネットに公開した管理インターフェースから PHP2Shell を先に突くものだけだ、と書いています。FAQ の対応は次のとおりです。

- CVE-2026-109618 のアドバイザリに載る修正版を実行中なら protected（保護される）。管理インターフェースを信頼できる内部の IP アドレスに絞っていれば、リスクはかなり下がる。
- 管理インターフェース（または管理プロファイルを付けたデータプレーンのインターフェース）がインターネットから届くなら、直ちに更新し、信頼できる内部 IP に制限する。そうでなければ、次のメンテナンスで修正版へ上げる。

この文面に Fragnesia の語は出てきません。2つのアドバイザリが示す最低版も食い違います。たとえば 10.2.7 系は、CVE-2026-109618 のアドバイザリが 10.2.7-h39、PAN-SA-2026-0015 の表が 10.2.7-h41 です。版を確かめるときは、[CVE-2026-109618 のアドバイザリ](https://security.paloaltonetworks.com/CVE-2026-109618)と PAN-SA-2026-0015 の両方で、自分の系列の修正版を見てください。

PHP2Shell は PHP 本体の脆弱性で、PAN-OS の管理画面が使う PHP がその影響を受けます。Palo Alto Networks の CVSS 4.0 の評価は 9.2（Critical）です。Prisma Access と Cloud NGFW は、PHP2Shell の影響を受けません。

連鎖の報告は Dream Research によるもので、ファイアウォール24台と内部の管理サーバ1台の計25台が root を取られたとしています（2026年10月26日公開、10月29日更新）。Unit 42 は、同じ攻撃者のツールを独立に検証し、報告された結果を確認したと書いています。Unit 42 の脅威ブリーフは、全世界の導入基盤のうち約0.02%が、インターネットに面した管理インターフェースを設定していて影響を受け、該当する顧客には個別に連絡した、と書いています（[Unit 42](https://unit42.paloaltonetworks.com/cve-2026-109618-cve-2026-109619/)）。

動画の訂正です。

- 動画では、今回新しいのは、root 化に使われたカーネル側の穴が Fragnesia だと特定されて、その修正が出たことだと伝えました。正しくは、Fragnesia が使われた連鎖は10月26日に Dream Research が報告済みで、10月30日の記事でも扱っています。11月24日に新しく出たのは、PAN-OS での修正（PAN-SA-2026-0015）です。
- 動画では、PHP2Shell を、PAN-OS の管理画面に組み込まれた PHP の処理に潜む脆弱性と伝えました。正しくは、PHP 本体の脆弱性です。
- 動画では、管理画面をインターネットに公開している装置は全体の約0.02%と伝えました。正しくは、約0.02%は、外向きの管理インターフェースを設定していて影響を受けた導入基盤の割合で、公開している装置の割合ではありません。

## 2. Firefox 161.0

Firefox 161.0 は11月24日に公開されました（[リリースノート](https://www.firefox.com/en-US/firefox/161.0/releasenotes/)）。160.0 の公開は11月10日で、2週間後の公開です。リリースノートが挙げる変更のうち、動画で扱ったものは次のとおりです。

- 現在のタブの URL を、キーボードショートカットでコピーできる。既定のキーは割り当てられておらず、設定の「ショートカットのカスタマイズ」で自分で決める。
- タブグループが、アプリケーションメニューに一覧で出る。
- 内蔵 VPN を、特定のサイトでオン・オフできる（リリースノートの文言）。
- アドオン管理のテーマの一覧に、Classic themes の欄ができた。以前の版の Proton テーマ、OLED テーマ、単色のテーマが入る。
- CSS の random() 関数に対応した。

Compression Dictionary Transport も、161 の対応として MDN の開発者向けノートに載っています（リリースノートの Web Platform の欄には載っていません）。サーバーは、辞書にするレスポンスを `Use-As-Dictionary` で指定します。ブラウザが保持している辞書を `Available-Dictionary` で伝えると、サーバーはその辞書に対して圧縮した応答を、`dcb`（Brotli）か `dcz`（Zstandard）の Content-Encoding で返せます（[MDN](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/161)）。

セキュリティの修正は、[MFSA 2026-131](https://www.mozilla.org/en-US/security/advisories/mfsa2026-131/) に110件（CVE-2026-135500 から CVE-2026-135609）です。Mozilla の深刻度は、high が59件、moderate（中）が30件、low が21件です。MFSA に CVSS は載っておらず、深刻度は high・moderate・low の3段階で示されています。high の例は、CVE-2026-135500（WebGPU の整数オーバーフローによる権限昇格）、CVE-2026-135501（cubeb の解放後使用によるサンドボックス脱出）、CVE-2026-135502（WebRender のサイト分離の問題）です。

動画の訂正はありません。

## 3. 行列乗算の指数 ω = 9/4 を主張するプレプリント

行列乗算の指数 ω は、n×n の行列2つの積を O(n^s) 回の演算で計算できる s の下限（infimum）です。定義どおりに計算すると n の3乗の手間がかかります。Strassen が1969年に、7回の積を使う恒等式で、指数を log2(7)（約2.81）まで下げました。それ以降の上界は少しずつ下がり、Vassilevska Williams らの 2023年7月の arXiv の論文は 2.371552 を示しています（[arXiv:2307.07970](https://arxiv.org/abs/2307.07970)）。

OpenAI は11月24日、正方行列の乗算の指数は 9/4（2.25）だとするプレプリントを、GitHub の `openai/math` に掲載しました。著者欄は個人名ではなく「OpenAI」で、リポジトリの説明では、結果は名前の無い社内モデルが出したものです（[論文のページ](https://github.com/openai/math/tree/main/preprints/The-matrix-multiplication-exponent-is-nine-fourths-November-24-2026)）。

動画の題の「57年目」は、Strassen の1969年から数えた値です。論文は、すべての体の上で指数が 9/4 だと主張しています。新しく主張しているのは下界で、形式的算術回路では、乗算または除算のゲートが少なくとも n^(9/4)/2 個必要だとします。上界の 9/4 は、論文自身が既知だと書いています。10月2日に、OpenAI の別のプレプリントが複素数の上で示しており、10月21日には Amanov・van den Berg・Zuiddam が、すべての体の上で示した論文を arXiv に出しています（[arXiv:2610.30054](https://arxiv.org/abs/2610.30054)）。

10月27日に Amir Shpilka が ECCC に出した報告は、この上界の初等的な証明と、明示的なアルゴリズムです（[ECCC TR26-281](https://eccc.weizmann.ac.il/report/2026/281/)）。11月24日の下界は、この報告より後に出たものです。OpenAI の外で下界を確かめた文書は、取得した一次の中には見つかっていません。

検証の状況は次のとおりです。

- 査読を受けた旨も、第三者が下界を確かめた旨も、取得した一次には書かれていない。
- Lean で証明されているのは、除算を使わない回路の範囲。論文の主張は、除算のゲートも含めて数えたもの。
- リポジトリの README は、この集まりを「検証の段階が混在する」「生の研究データ」と説明している。原稿は730本（375のまとまり）で、主要な結果の約42%が Lean で形式化されている（[openai/math](https://github.com/openai/math)）。

したがって、ここでは「OpenAI の主張」と書きます。

動画の訂正です。

- 動画では、11月24日のプレプリントは、2.25まで下げるアルゴリズムが存在することと、それより下に行けないことの両方を示した、と伝えました。正しくは、11月24日のプレプリントが新しく示したと主張しているのは、下界だけです。上界の 9/4 は、10月2日の OpenAI の別のプレプリントなどで先に出ていました。また動画は、2024年の約2.3716からそのままこの話に進み、直前の最良の上界がすでに10月2日の 9/4 だった点に触れていません。
- 動画では、外の研究者が中身を追って確かめ直したのは心強い材料だ、と伝えました。正しくは、Shpilka 氏が確かめたのは10月2日の上界で、11月24日の下界ではありません。

## 4. LWN のセキュリティ更新（podman・skopeo・mutter）

LWN の「Security updates」の記事は、各ディストリビューションの勧告の一覧表で、CVE の解説は載っていません。podman・skopeo・mutter の名前は、[Tuesday の記事](https://lwn.net/Articles/1109472/)と[Monday の記事](https://lwn.net/Articles/1109268/)の表に並びます。表に載る podman・skopeo・mutter の勧告の日付は、11月21日から24日です。CVE との対応は、各ディストリビューションの勧告で確かめます。

podman で直されたのは、CVE-2026-17106 です。コンテナイメージの tar アーカイブを展開するとき、アーカイブの中身を操れる攻撃者は、アーカイブが持つリンクをたどらせて、展開先の外にファイルを作ったり上書きしたりできます。原因は、Docker や Podman が使う Go のライブラリ moby/go-archive にあります。CVSS は 7.1（v4.0）で、CNA の Docker が採点した値です。修正は moby/go-archive 0.3.0 で、Podman は [6.1.1](https://github.com/containers/podman/releases/tag/v6.1.1)（公開は9月2日 UTC）で対応しました。回避策は、信頼できるアーカイブだけを展開することです（[GitHub Advisory](https://github.com/moby/go-archive/security/advisories/GHSA-hfg8-hc9c-6c3h)）。AlmaLinux 9 の勧告 ALSA-2026:102296 は、11月24日付でこの CVE を含みます。

skopeo で直されたのは、CVE-2026-78669 です。Go の標準ライブラリ（net/http と golang.org/x/net/http2）の問題で、悪意のある HTTP/2 の相手方が、ストリームを大量に開いて小さな SETTINGS フレームを多数送ると、クライアントやサーバーの CPU を使い切らせられます。skopeo に固有の問題ではなく、AlmaLinux の勧告 ALSA-2026:100639 が skopeo の修正として載せています。CVSS は 7.5（v3.1）で、CISA-ADP の採点です。skopeo は、このブログで取り上げるのは初めてです。

mutter で直されたのは、CVE-2026-108094 です。Wayland の色管理の ICC image description の経路にある解放後使用で、CVSS は 7.8（v3.1）、Red Hat（CNA）の採点です（[Red Hat の CVE ページ](https://access.redhat.com/security/cve/CVE-2026-108094)）。影響の範囲は、Red Hat が「49.x から 50.4 で確認」、メンテナーの報告（Red Hat Bugzilla）が「47.0 以上、51.0 未満」で、記述が分かれています。修正は 50.5 と 51.0 で、GNOME の NEWS では 49.8 にも入っています。回避策は、Red Hat の記述では、信頼できないアプリを影響を受ける Wayland セッションで動かさないこと、信頼できないクライアントの Wayland ソケットへのアクセスを制限することです。Red Hat は謝辞で、Calif.io を、Anthropic との協力による報告者として挙げています。

NVD は3件とも解析待ち（Awaiting Analysis）で、点数は上の採点者の値です。パッケージの更新は、各ディストリビューションの告知で、自分の版の修正を確かめてください。

動画の訂正です。

- 動画では、この発見に Anthropic が協力した、AI の会社が関わった脆弱性探しが、実際の修正につながっている例だと伝えました。正しくは、Red Hat は報告者として Calif.io を挙げ、Anthropic は協力（in collaboration with）と書くのみで、協力の中身は一次に書かれていません。

## 5. 共有の推論サーバ経由で、隔離したモデルが通信できたとする投稿

一次は、論文ではなく、LessWrong の投稿です。Niranjan Deshpande と David Africa の連名で、2026年11月19日（15:54 UTC、日本時間では11月20日 00:54）に出ました。コードは GitHub で公開され、コードと図は Claude が書いた、と著者が明記しています（[投稿](https://www.lesswrong.com/posts/7wzWuLP3HhyBLmKfo/models-can-communicate-via-inference-servers-despite-being)、[コード](https://github.com/niranjan-deshpande/side-channel-communication)）。

主張は、同じ推論サーバで動く2つのエージェントが、メッセージも共有のファイルも使わずに、サーバの計算を介して情報を伝えられる、というものです。使う経路は2つです。1つは、処理するトークンの量でカーネルが変わることによる丸め誤差の違い、もう1つは KV キャッシュに残る計算結果の違いです。符号化の方法と手順は、ここでは書きません。

数値は、条件と一緒に読む必要があります。著者は、設定を作り込んだもの（contrived）だと書いています。モデルにプロトコルを教え、最後の2層を SFT で微調整した設定です。

- 色当てのゲームで、KV キャッシュを使う方法は 1,221 回すべて、ステップサイズを使う方法は 455 回すべてで成功した。ステップサイズの方法は、サーバが空いていることが前提。
- 実トラフィックの記録を再生した実験で、ステップサイズの方法は 0.25 倍速で 23%（0.1 倍速で 39%）まで落ちた。当てずっぽうの水準は 12.5%。
- 微調整せず、プロトコルを教える設定では、ログ確率を読めるか、プロトコルを知っているかなどの条件で、成功率が偶然の水準以下から100%まで大きく変わる。

監視の実験では、方策側が送る「おとりではない」という合図を、監視役が読み取る設定を作りました。この監視役は、著者が SFT で作ったものです。合図つきの攻撃 354 件はすべて通過した一方、おとり（honeypot）は 85〜92% が検出されています。著者は、これが理論上起こりうることを示したものだ（"theoretically"）と書いています。

ほかの推論エンジン（SGLang・LMDeploy・TensorRT-LLM）でも両方の方法が動き、ステップサイズの方法は複数世代の GPU でも動きました。ただし、ある GPU で学習した監視役は、別の GPU では合図を読み取れませんでした。対策として著者は、別のエンジンインスタンスで動かすこと、バッチ不変カーネル（ステップサイズの経路を閉じる）、ユーザーごとのキャッシュ分離（キャッシュの経路を閉じる）を挙げています。vLLM のバッチ不変の機能は、公式ドキュメントでベータと書かれています（[vLLM のドキュメント](https://docs.vllm.ai/en/latest/features/batch_invariance/)）。

動画の訂正です。

- 動画では、今すぐの危険は大きくない、AI の隔離も同じサーバを分け合うところから崩せることが実験で示された、と伝えました。正しくは、リスクの大小は著者の言葉ではありません。実験は、著者が作り込んだ設定で、理論上起こりうることを示したものです。

## まとめ

ファイアウォールの管理インターフェースも推論サーバの隔離も、それ自体が安全の前提でした。その前提の側から崩れうる、という2本の読み方は書き手の考察です。実務で確認しておくものは次のとおりです。

- PAN-OS: 管理インターフェース（管理プロファイル付きのインターフェースを含む）がインターネットから届かないか確かめる。版は、CVE-2026-109618 と PAN-SA-2026-0015 の両アドバイザリで、自分の系列の修正版を確かめる。
- Firefox: 161.0 へ更新する。MFSA 2026-131 は110件を修正している。
- podman・skopeo・mutter: 各ディストリビューションの告知で、自分の版のパッケージの更新を確かめる。展開するアーカイブは信頼できるものに限る。
- 推論サーバ: 隔離したモデル同士や、監視役と監視される側を、別のエンジンインスタンスで動かす案は、著者が対策として挙げている。

## 参考リンク

- [PAN-SA-2026-0015](https://security.paloaltonetworks.com/PAN-SA-2026-0015)
- [CVE-2026-109618 のアドバイザリ](https://security.paloaltonetworks.com/CVE-2026-109618)
- [Unit 42 の脅威ブリーフ](https://unit42.paloaltonetworks.com/cve-2026-109618-cve-2026-109619/)
- [Dream Research の報告](https://dreamgroup.com/blog/chained-php2shell-exploit-roots-25-servers)
- [Firefox 161.0 のリリースノート](https://www.firefox.com/en-US/firefox/161.0/releasenotes/)
- [MFSA 2026-131](https://www.mozilla.org/en-US/security/advisories/mfsa2026-131/)
- [OpenAI の行列乗算のプレプリント（GitHub）](https://github.com/openai/math/tree/main/preprints/The-matrix-multiplication-exponent-is-nine-fourths-November-24-2026)
- [LWN: Security updates for Tuesday](https://lwn.net/Articles/1109472/)
- [Red Hat の CVE-2026-108094](https://access.redhat.com/security/cve/CVE-2026-108094)
- [LessWrong の投稿](https://www.lesswrong.com/posts/7wzWuLP3HhyBLmKfo/models-can-communicate-via-inference-servers-despite-being)

（2026/11/26 Linux・OSSトレンド）
