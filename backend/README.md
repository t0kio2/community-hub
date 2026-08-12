# Backend

## テスト

BackendのRailsコマンドは、ホストのRubyではなくDocker Composeの`backend`サービスで実行します。

### コンテナの起動

リポジトリルートで次を実行します。

```sh
docker compose up -d db backend
```

### テストデータベースの準備

初回実行時やマイグレーション追加後は、test環境のデータベースを準備します。

```sh
docker compose exec \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://app:app@db:5432/app_test \
  backend bin/rails db:prepare
```

### 全テストの実行

```sh
docker compose exec \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://app:app@db:5432/app_test \
  backend bin/rails test
```

### テストファイルを指定して実行

パスは`backend`ディレクトリを基準に指定します。

```sh
docker compose exec \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://app:app@db:5432/app_test \
  backend bin/rails test test/models/listing_test.rb
```

特定のテストだけを実行する場合は、対象テストの行番号を付けます。

```sh
docker compose exec \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://app:app@db:5432/app_test \
  backend bin/rails test test/models/listing_test.rb:10
```
