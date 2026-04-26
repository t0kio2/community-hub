```
project-root/
  docker-compose.yml
  api/        # Rails API
  db/         # DB関連（初期化SQLなど置き場）
  web/        # Next.js（後で）

```

Rails: APIモード（Rails 8系）
DB: PostgreSQL
web: Next.js

docker環境で開発を行う

## 開発環境のセットアップ（Docker）

- 前提: Docker / Docker Compose がインストール済み
- ルートにある `.env` を使用（例）

```
USERNAME=app
PASSWORD=app
DATABASE=app_development
```

### 起動手順

1. 初回ビルド＆起動（Rails API プロジェクトは初回起動時に自動生成されます）

```
docker compose up --build
```

2. ブラウザで http://localhost:3001 にアクセス

メモ:
- API コンテナは `api/Dockerfile` と `api/docker/entrypoint.sh` を使用します。
- 初回起動時に `api/` 配下へ Rails API 雛形を生成し、`DATABASE_URL`（PostgreSQL）で `db:prepare` を実行します。
- 以降の起動は `docker compose up` のみでOKです。
- Gemはコンテナの `bundle` ボリュームに永続化されます。

## 実施した対応（セットアップと修正）

- `api/Dockerfile` を開発向けに整備
  - ベース: `ruby:3.3-slim`
  - 追加パッケージ: `build-essential`, `libpq-dev`, `libyaml-dev`, `pkg-config`, `postgresql-client` など
  - 目的: `psych` ネイティブ拡張のビルド失敗（`yaml.h not found`）の解消
- `api/docker/entrypoint.sh` を追加
  - 初回起動時に Rails API を自動生成（`rails new --api`）
  - `--skip-docker --skip-ci --skip-git` で Docker/Kamal 等の上書きを回避
  - 起動前に `bundle install` と `rails db:prepare` を実行
- `docker-compose.yml` を調整
  - `bundle` ボリューム追加（Gem を永続化）
  - `RAILS_LOG_TO_STDOUT` 追加

## 再ビルド・再起動手順（エラー解消後）

1. コンテナ停止
```
docker compose down
```

2. API イメージをキャッシュ無効で再ビルド
```
docker compose build --no-cache api
```

3. 起動
```
docker compose up
```

4. 動作確認
- http://localhost:3001 にアクセス

## トラブルシューティング

- `psych` のビルドエラー（yaml.h not found）
  - 原因: `libyaml-dev`/`pkg-config` 不足
  - 対応: 上記 Dockerfile のパッケージ追加済み。再ビルド手順を実行

- 依然として bundler 周りでこける場合（Gem キャッシュ破損等）
```
docker compose down
docker volume rm community-hub_bundle
docker compose build --no-cache api
docker compose up
```

## テスト

Rails API のテストは Docker Compose 経由で実行する。

詳細は [docs/testing.md](docs/testing.md) を参照。

例:

```
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test api bin/rails test
```

## Codex Skills

チームで共有する Codex の作業ルールは `skills/` 配下に置く。

詳細は [docs/codex-skills.md](docs/codex-skills.md) を参照。
