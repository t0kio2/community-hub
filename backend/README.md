# Backend

## テスト

BackendのRailsコマンドは、ホストのRubyではなくDocker Composeの`backend`サービスで実行します。

## Google Maps Embed API

拠点管理画面の地図プレビューにはMaps Embed APIを使用します。APIキーはリポジトリへコミットせず、リポジトリルートの`.env`へ設定します。

```sh
GOOGLE_MAPS_EMBED_API_KEY=your_api_key
```

設定後は`backend`コンテナを再作成して環境変数を反映します。

```sh
docker compose up -d --force-recreate backend
```

APIキーはMaps Embed API専用にし、Google Cloud Consoleで次の制限を設定してください。

- APIの制限：Maps Embed APIのみ
- アプリケーションの制限：開発環境と本番環境のHTTPリファラー

本番環境では、デプロイ先のSecretまたは環境変数に同じ変数名で設定します。Maps Embed APIのキーはブラウザへ送信されるため、API制限とHTTPリファラー制限が必須です。

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
