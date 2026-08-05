---
title: "署名は本物、中身はワーム——信頼の土台を逆手に取られた一週間"
date: 2026-08-06T00:00:00+09:00
draft: false
tags: ["npm", "サプライチェーン攻撃", "Langflow", "セキュリティ", "Python", "Linuxカーネル"]
categories: ["Linux・OSSトレンド"]
---

## はじめに

「署名がついているから安全」「デフォルト設定だから大丈夫」——そう思って毎日コードを書いている人ほど刺さるニュースが、今週は立て続けに2本も出ました。npmの供給チェーンを揺るがしたワーム「Shai-Hulud」は、業界が信頼の証として整備してきた署名の仕組みそのものを逆手に取った事件です。余談ですが、うちの支店でも先週、サーバーのメモリ逼迫が原因でAPI疎通確認が誤検知し、深夜のバッチ処理が一晩スルーされるという地味な事故がありました（幸い本当はAPIもVMも無事でした、お騒がせしてすみません）。信頼の仕組みが自分の首を絞める話、今日はちょっと他人事じゃない気分で書いています。

{{< youtube "Ffsjsy7a2CI" >}}

## 1. npm供給チェーン壊滅——keyvワーム「Shai-Hulud」が週1.27億DLパッケージ経由で444本を汚染

2026年8月4日、攻撃者がキー・バリューストレージライブラリ`keyv`のメンテナーGitHubアカウントを奪取し、[SLSAプロヴェナンス署名](https://securitylabs.datadoghq.com/articles/npm-worm-compromises-popular-npm-packages/)が付いた悪意あるバージョン`keyv@6.0.0`をnpmレジストリへ公開しました。自己増殖ワーム「Shai-Hulud」は約4時間で444パッケージ・2,234バージョンに伝播し（[SafeDep](https://safedep.io/keyv-npm-supply-chain-compromise/)集計。[Aikido](https://www.aikido.dev/blog/keyv-and-friends-compromised-in-npm-supply-chain-attack)は少なくとも868パッケージ・1,381バージョンと報告）、月間合算インストール数20億回超の生態系に侵入しています。

正直、ここが一番ゾッとしたところなのですが、攻撃者はリポジトリのメインブランチを直接改ざんして正規のGitHub Actions CIパイプラインを経由させたため、SLSAプロヴェナンス署名は **すべて正当な手続きで発行されていました** 。「署名あり＝安全」という前提そのものが崩れた事例です。しかも盗んだトークンが失効すると破壊的アクションが自動起動する「Dead-man's switch」が仕込まれており、対応する側は **先にトークンを失効させると爆発する** という嫌がらせのような順序制約を強いられます。さらに`.vscode/tasks.json`や`.claude/settings.json`にフックを埋め込む二次感染経路まであり、`npm install`を直接叩いていない開発者のマシンにも被害が及ぶ設計でした。

特にESLint関連の`flat-cache`（月5.8億DL）・`file-entry-cache`（月5.7億DL）が感染したため、「ESLintを使っているだけ」で巻き込まれた人が続出したのも今回の特徴です。2026-08-04 09:30 UTC以降に`npm install`を実行した環境は影響の可能性があるため、対応の優先順位は **Dead-man's switchの除去が最優先** 、その後に影響バージョンの特定・資格情報の全ローテーション、という順番を守る必要があります（[Wiz](https://www.wiz.io/blog/keyv-and-cacheable-npm-supply-chain-attack)のタイムライン記事に詳細があります）。

## 2. Langflow CVE-2026-9198（CVSS 9.8）がCISA KEV入り——「デフォルトのまま」が7,000台の攻撃面に

2026年8月4〜5日、CISAはAIエージェント構築ツール「Langflow」（バージョン1.0.0〜1.10.0）の[認証バイパス→コード実行の脆弱性CVE-2026-9198（CVSS 9.8 CRITICAL）](https://nvd.nist.gov/vuln/detail/CVE-2026-9198)を既知悪用脆弱性（KEV）カタログに追加しました。手口は2段階で、`auto_login`エンドポイントが`LANGFLOW_AUTO_LOGIN=true`（デフォルト値）のとき無条件でSUPERUSER権限のJWTを発行し、そのトークンを使って`validate/code`エンドポイントにPythonコードを投げると`exec()`でそのまま実行されてしまいます。

これもまた「デフォルト設定を疑わなかった」パターンです。背景にはIBMによるDataStax（Langflowの親会社）買収と、2026年4月のマネージドホスティング終了があり、乗り換え先としてセルフホストへ移った多くのユーザーがデフォルト設定のまま公開してしまったことで、[約7,000インスタンス](https://www.cisa.gov/news-events/alerts/2026/08/04/cisa-adds-three-known-exploited-vulnerabilities-catalog)規模の攻撃面が一気に形成されました。実は2026年6月にもCVE-2026-5027（CVSS 8.8）で同規模の悪用があったばかりで、「またLangflowか」という声が上がっているのも無理はありません。修正版は1.10.1で、緊急回避策としては`LANGFLOW_AUTO_LOGIN=false`への切り替えと`validate/code`エンドポイントの外部アクセス遮断が案内されています。連邦機関の対応期限は2026年8月7日と、目前に迫っています。

## 3. Simon WillisonのLLM CLI 0.32——推論トレースとサーバーサイドツールでエージェント寄りに

強め2本の合間に、実務者向けの小ネタを挟みます。2026年8月4日、Simon Willisonが[LLM 0.32](https://simonwillison.net/2026/Aug/4/new-release-of-llm/)を公開しました。マルチプロバイダーLLMを統一インターフェースで呼べるCLI/Pythonライブラリで、今回は推論モデルの思考過程を`stderr`にストリーム出力する機能（`-R`/`--hide-reasoning`で非表示切り替え可）や、OpenAIの`/v1/responses`エンドポイント対応、WebSearch・CodeInterpreterといったサーバーサイドツールの利用が一気に入りました。

個人的に地味に嬉しいのは、`stdout`が汚染されないのでパイプ処理と併用しやすい点です。ツール呼び出しを一時停止・再開できる`PauseChain`例外や、Gitのオブジェクトストアに着想を得た重複排除ロギングなど、Human-in-the-Loopなエージェント実装を意識した機能が並びます。ちなみにデフォルトモデルはGPT-4o miniからGPT-5.6 Lunaに変更されており、必須環境もPython 3.10以上・sqlite-utils 4.0以上に引き上げられているので、古い環境で使っている人はアップグレード前に確認しておくと安心です（[公式changelog](https://llm.datasette.io/en/stable/changelog.html)に全機能一覧があります）。

## 4. Python 3.14.7リリース——libexpat・tarfile・pipの3点セットで穴を塞ぐ

2026年8月5日、[Python 3.14.7](https://www.python.org/downloads/release/python-3147/)が公開されました。86名のコントリビューターによる約499件の修正を含む第7メンテナンスリリースで、バンドルするlibexpatを2.8.2に更新（[CVE-2026-45186](https://nvd.nist.gov/vuln/detail/CVE-2026-45186)を含む13件修正）、tarfileの`data_filter`がシンボリックリンク経由でフィルタを迂回できてしまう問題（[CVE-2025-4330](https://nvd.nist.gov/vuln/detail/CVE-2025-4330)関連、複数の修正コミットで多層的に対応）を封じ、pipも26.2.1（CVE-2026-3219・CVE-2026-13346修正）に引き上げています。

面白いのはCVE-2026-45186の評価がNISTでCVSS 7.5 HIGH、MITREでは2.9 LOWと大きく食い違っている点で、外部XMLを扱う本番システムはHIGH側を基準に対応するのが無難そうです。tarfileの方は「`filter='data'`を指定していれば安全」と思い込んでいたユーザーが一番危ないというオチで、CI/CDパイプラインでサードパーティのtarアーカイブを展開している人は一度点検しておいた方がよさそうです。`python3 -c "import pyexpat; print(pyexpat.EXPAT_VERSION)"`で`2.8.2`以上になっているか確認できます。

## 5. Linuxカーネル7.1.6 + LTS3系列一斉リリース——741コミット、151件超のメモリ安全性パッチ

締めは今週いちばんの物量です。2026年8月3日、Greg Kroah-Hartmanが[Linux 7.1.6](https://www.kernel.org/)（741コミット・403名参加、うち87%が`Fixes:`タグ付き）とLTS3系列（6.18.42・6.12.101・6.6.148）を同時リリースしました。中身はUse-after-free・バッファオーバーフロー・NULLポインタ参照を中心とした約151件のメモリ安全性パッチが主体で、実質的に「修正専用」のアップデートです。

個人的に唸ったのはKVM/SVMのASID衝突修正で、CPUホットプラグ後に異なる仮想マシンのvCPUが同一Address Space IDを共有してしまい、古いTLBエントリがゲスト間でリークしうるバグでした。クラウド環境だと「隣の部屋の会話が壁越しに聞こえる」ような話なので、地味ながら効いてくる修正だと思います。CIFSのタイムスタンプ競合修正（Red HatのFrank Sorenson氏によるもの）や、OpenVPNのハードニングも含まれています。あわせて、2026年3月に発表されていた[LTS EOL延長](https://fossforce.com/2026/03/greg-kroah-hartman-stretches-support-periods-for-key-linux-lts-kernels/)（6.12系は2028年12月まで）も本リリースで実効化されており、組み込み・産業機器を長く使うユーザーには嬉しいニュースです。

## まとめ

署名も、デフォルト設定も、「そうなっているはずだから」で思考停止すると足元をすくわれる——今週はそれを地でいく一週間でした。うちの支店の誤検知騒動も含めて、仕組みを信頼しつつ定期的に疑う姿勢、皆さんはどのくらい保てていますか。

## 参考リンク

- npm Shai-Hulud（Datadog Security Labs）: https://securitylabs.datadoghq.com/articles/npm-worm-compromises-popular-npm-packages/
- Langflow CVE-2026-9198（NVD）: https://nvd.nist.gov/vuln/detail/CVE-2026-9198
- LLM 0.32リリースノート（Simon Willison）: https://simonwillison.net/2026/Aug/4/new-release-of-llm/
- Python 3.14.7公式リリース: https://www.python.org/downloads/release/python-3147/
- Linux 7.1.6（kernel.org）: https://www.kernel.org/
