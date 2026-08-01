# Listing管理プロトタイプ

DBやRails APIを使用せず、滞在Listingの設計をブラウザ操作で確認するためのプロトタイプです。

## 起動

リポジトリルートで静的HTTPサーバーを起動します。

```sh
python3 -m http.server 4173 --directory prototype
```

ブラウザで <http://localhost:4173> を開いてください。編集内容はブラウザの`localStorage`だけに保存されます。

## 停止

HTTPサーバーを起動したターミナルで`Ctrl+C`を押します。

起動したターミナルが分からない場合は、次のコマンドで4173番ポートを使用しているプロセスを停止できます。

```sh
lsof -ti :4173 | xargs kill
```

## テスト

```sh
cd prototype
npm test
```

## データを戻す

画面右上の「リセット」で`data/stay-listing.json`の初期状態へ戻せます。「JSONを書き出す」で現在の編集内容をダウンロードできます。
