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
