# テスト実行方法

Rails backend のテスト実行方法をまとめる。

テストは Docker 環境で実行する。
development DB ではなく、test DB の `app_test` を使う。

全テスト:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test -v
```

特定のファイル:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test -v test/models/tenant_member_test.rb
```

特定のテストを行番号で指定:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test -v test/models/tenant_member_test.rb:12
```

## UIテストの粒度

ControllerテストのHTML検証は、主要なフォーム、入力名、導線、重要な表示値など、画面とサーバー間の契約に限定する。CSSクラスの細かな階層、SVG内部構造、全入力属性、ブラウザ依存の日時文字列形式は固定しない。

- 必須、許可値、数値範囲、日時の前後関係はModelテストで検証する。
- Controllerテストでは主要項目が送信可能であることと、保存済みの代表値が再表示されることを検証する。
- ピッカーの開閉、クリック領域、配置などのブラウザ操作は、必要な場合にSystem Testで検証する。
- 同じ仕様を複数レイヤーで重複して検証しない。
