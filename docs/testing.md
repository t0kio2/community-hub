# テスト実行ガイド

## 方針

このプロジェクトの Rails API は Rails 8.1 系で、`api/.ruby-version` は `ruby-3.3.10` を指定している。

macOS の標準 Ruby は古いことがあるため、基本的には Docker Compose 経由でテストを実行する。

ローカルで直接 `bin/rails test` を実行する場合は、少なくとも以下が必要。

- Ruby 3.3 系
- `api/Gemfile.lock` の `BUNDLED WITH` に合う Bundler
- PostgreSQL に接続できること

通常開発では Docker Compose 経由を推奨する。

## 初回準備

プロジェクトルートで実行する。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails db:prepare
```

このコマンドで test DB の作成、schema load、seed などが実行される。

`.env` の標準値は以下。

```text
USERNAME=app
PASSWORD=app
DATABASE=app_development
```

test 実行時は `DATABASE_URL=postgres://app:app@db:5432/app_test` を指定して、development DB と分ける。

## Rails テストを全部実行する

プロジェクトルートで実行する。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test
```

## 特定のテストだけ実行する

例: tenant 関連の model/controller test だけ実行する。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test test/models/tenant_test.rb test/models/tenant_user_test.rb test/controllers/admin/tenant_accounts_controller_test.rb
```

例: 1 ファイルだけ実行する。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test test/controllers/admin/tenant_accounts_controller_test.rb
```

例: 行番号指定で 1 テストだけ実行する。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test test/controllers/admin/tenant_accounts_controller_test.rb:13
```

## 今回追加した tenant 作成フローの確認

対象:

- `api/test/models/tenant_test.rb`
- `api/test/models/tenant_user_test.rb`
- `api/test/controllers/admin/tenant_accounts_controller_test.rb`

確認していること:

- `Tenant` は `name` と `status` が必須
- `TenantUser` は `role` と `status` が必須
- `TenantUser.role` は `owner` / `staff` のみ有効
- admin が tenant account を作成すると、以下が同一 transaction で作られる
  - `TenantAccount`
  - `Tenant`
  - `TenantUser`
- admin 作成時の `TenantUser.role` は `owner`
- 組織情報が不正な場合、`TenantAccount` だけが残らず rollback される

実行コマンド:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test test/models/tenant_test.rb test/models/tenant_user_test.rb test/controllers/admin/tenant_accounts_controller_test.rb
```

期待結果の例:

```text
9 runs, 38 assertions, 0 failures, 0 errors, 0 skips
```

## よくあるエラー

### `/usr/bin/ruby` で実行して Bundler エラーになる

例:

```text
Could not find 'bundler' (...) required by Gemfile.lock
```

または:

```text
`windows` is not a valid platform
```

原因:

- macOS 標準 Ruby 2.6 など、プロジェクトの Ruby バージョンと合っていない
- Rails 8.1 / Bundler 4 系に対してローカル Ruby が古い

対応:

- Docker Compose 経由で実行する
- ローカル実行したい場合は Ruby 3.3 系を入れる

### `database "app_test" does not exist`

原因:

- test DB がまだ作成されていない

対応:

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails db:prepare
```

### Docker API に接続できない

例:

```text
permission denied while trying to connect to the docker API
```

原因:

- Docker Desktop が起動していない
- Docker socket へのアクセス権がない

対応:

- Docker Desktop を起動する
- `docker ps` が実行できるか確認する

## テスト追加時のメモ

### Devise login が必要な controller / integration test

`api/test/test_helper.rb` で以下を include している。

```ruby
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
```

そのため、integration test では以下のようにログインできる。

```ruby
admin_account = AdminAccount.create!(
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password"
)

sign_in admin_account
```

### fixture の注意

`accounts.email` は unique index があるため、fixture や test 内で同じ email を使い回さない。

`tenant_members.account_id` も unique index があるため、1 account に複数の `tenant_user` を作らない。

### transaction を伴う作成フローのテスト

複数レコードを同時に作る処理は、成功ケースだけでなく rollback も確認する。

例:

- 成功時に関連レコードがすべて増える
- 失敗時に一部のレコードだけ残らない
