# テスト実行方法

Rails API のテスト実行方法をまとめる。

テストは Docker 環境で実行する。
development DB ではなく、test DB の `app_test` を使う。

実行方法は、ホスト側から Docker にコマンドを渡す方法と、api コンテナ内に入って実行する方法の 2 通り。

## ホスト側から実行する

プロジェクトルートで実行する。

初回、または DB schema を更新した後:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails db:prepare
```

全テスト:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test
```

特定のファイル:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test test/models/tenant_member_test.rb
```

特定のテストを行番号で指定:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test test/models/tenant_member_test.rb:12
```

## api コンテナ内で実行する

まず api コンテナに入る。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bash
```

すでに api コンテナ内にいる場合は、先に環境変数を test 用にする。

```sh
export RAILS_ENV=test
export DATABASE_URL=postgres://app:app@db:5432/app_test
```

接続先を確認する場合:

```sh
bin/rails runner 'puts Rails.env; puts ActiveRecord::Base.connection_db_config.database'
```

`test` と `app_test` が表示されれば OK。

初回、または DB schema を更新した後:

```sh
bin/rails db:prepare
```

全テスト:

```sh
bin/rails test
```

特定のファイル:

```sh
bin/rails test test/models/tenant_member_test.rb
```

特定のテストを行番号で指定:

```sh
bin/rails test test/models/tenant_member_test.rb:12
```

テストケース名を表示する:

```sh
bin/rails test -v
```

特定ファイルでテストケース名を表示する:

```sh
bin/rails test test/models/tenant_member_test.rb -v
```

## 補足

`bin/rails test` はデフォルトではテストケース名を表示せず、`.` で進捗を表示する。

`app_test` がまだない場合は、`bin/rails db:prepare` で作成される。

`DATABASE_URL` が development DB を向いたまま `bin/rails test` を実行すると、`app_development` を purge しようとすることがある。テスト前に `DATABASE_URL` が `app_test` を向いていることを確認する。

Docker 実行時に Docker API へ接続できない場合は、Docker Desktop が起動しているか確認する。
