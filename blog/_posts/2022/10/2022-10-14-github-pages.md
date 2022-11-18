---
layout: post
title:  Github Pagesにアップする方法(イマドキの)
date:   2022-10-14 13:38:18 +0900
categories: github pages jekyll
---

最近は本当にGithub Pagesへのコンテンツ登録方法が楽ちんになってしまって本当助かります。
Actions使っての登録がすっごく楽。

# 早速コード

このサイトでの登録方法はこんな感じになってます。
なお、事前に対応リポジトリの設定でGithub Pagesの有効化をしておきましょう。

![Pages設定](/assets/images/gh-pages.png)


※ jekyllがカーリーブレス({..})を変に処理してしまうので、空白を入れています。

```yaml
name: Jekyllのフォーマット→公開
on:
  - push
  - workflow_dispatch
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: setup ruby
        uses: ruby/setup-ruby@359bebbc29cbe6c87da6bc9ea3bc930432750108
        with:
          ruby-version: '3.1'
      - name: install dependencies
        run: cd blog; bundle install
      - name: build contents
        run: cd blog; jekyll build
      - name: fetch contents
        uses: actions/upload-pages-artifact@v1
        with:
          path: blog/_site
  deploy:
    needs: build
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${ { steps.deployment.outputs.page_url } }
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v1
```

## 第1段階: 公開データをアーカイブして準備

ひとつは作ったJekyllのページコンテンツのデータを登録する作業です。
このデータを次の段階で登録させます。

```yaml
      - name: fetch contents
        uses: actions/upload-pages-artifact@v1
        with:
          path: blog/_site
```

## 第2段階: デプロイする

`upload-pages-artifact@v1` を使うと、指定したパス以下を回収してアーカイブしておいてくれます。

そのあとデプロイという事にします。

```yaml
  deploy:
    needs: build # 依存関係定義
    # permissions重要、actionsにてリポジトリへの書き込み権を与える
    permissions:
      pages: write
      id-token: write
    # environmentにてページの場所(URL)を準備、事前にGH Pagesを有効にすれば設定されてる模様
    environment:
      name: github-pages
      url: ${ { steps.deployment.outputs.page_url } }
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v1 # このactionでさっき改修したモノを展開してくれます
```

古はgh-pagesなどのブランチをつくってそこに配置して云々ありましたが、これだけでスッキリしてます。
気持ちいいくらいスッキリです。
