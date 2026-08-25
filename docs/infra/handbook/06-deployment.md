# アプリケーションのデプロイ

## Terraformと分離する

デプロイではDockerイメージを作成し、ECRへ保存し、EC2で起動する。Terraformの`remote-exec`から`docker compose up`やRails migrationを実行しない。

```text
開発端末またはGitHub Actions
  ├── test
  ├── docker build
  └── ECR push
           │
           ▼
EC2
  ├── SSMから環境変数を取得
  ├── ECR pull
  ├── Rails migration
  └── docker compose up
```

## production用コンテナ構成

開発用`docker-compose.yml`とは別に、production用Composeを用意する。

```text
reverse-proxy
├── /       → user-frontend
├── /api    → backend
├── /tenant → backend
└── /admin  → backend

内部ネットワーク
├── user-frontend
├── backend
├── worker
└── db
```

production用では次を守る。

- ソースコードをbind mountしない
- PostgreSQLの`ports`を設定しない
- RailsとNext.jsの開発サーバーを使用しない
- イメージタグを`latest`だけにせず、Git commit SHAでも識別する
- PostgreSQLのデータを`/data/postgres`へ保存する
- コンテナを`restart: unless-stopped`などで再起動可能にする
- ヘルスチェックを定義する

## productionイメージの準備

現在の`backend/Dockerfile`と`user-frontend/Dockerfile`は開発用途を含む。デプロイ実装時にはmulti-stage buildを使ったproduction用Dockerfileを追加する。

確認事項:

- Railsが`RAILS_ENV=production`で起動する
- Rails assetsが必要な場合はbuild時にprecompileされる
- Next.jsがproduction buildとproduction serverで動く
- コンテナ内へ秘密値をCOPYしない
- 対象EC2と同じCPU architectureのイメージを作る

## シークレットを登録する

Terraformで作成したSSM Parameterへ、実際の値をTerraform外から登録する。パラメータ名の例:

```text
/community-hub/development/postgres-password
/community-hub/development/rails-master-key
/community-hub/development/secret-key-base
/community-hub/development/devise-jwt-secret-key
/community-hub/development/google-maps-embed-api-key
```

値をシェル履歴、ログ、GitHub Actionsの出力へ表示しない。EC2上では、取得した値から権限を制限した環境ファイルを生成するか、デプロイ処理からComposeへ渡す。

## 初回デプロイの順序

1. RailsとNext.jsのテストを実行する。
2. productionイメージをbuildする。
3. Git commit SHA付きタグでECRへpushする。
4. Session ManagerまたはデプロイスクリプトからEC2へ接続する。
5. SSM Parameterを取得する。
6. production用Composeと設定ファイルを配置する。
7. PostgreSQLだけを起動し、health checkを待つ。
8. RailsのDBを準備し、migrationを実行する。
9. backend、worker、user-frontendを起動する。
10. reverse-proxyを起動する。
11. ヘルスチェックと主要画面を確認する。

Railsコマンドはproduction用Composeを介して実行する。具体的なComposeファイル名は実装時に確定し、この章へ追記する。

## DB構成の注意

現在のRails production設定は`primary`、`cache`、`queue`、`cable`の複数論理DBを使用する。初回起動時に必要なDBを作成できるよう、PostgreSQL初期化またはデプロイ用taskを用意する。

`DATABASE_URL`と`APP_DATABASE_PASSWORD`のどちらを正本にするかを実装時に統一する。接続先ホストはComposeサービス名`db`とし、PostgreSQLを外部公開しない。

## 更新デプロイ

1. 新しいイメージをECRへpushする。
2. DBバックアップを取得する。
3. 新しいイメージをpullする。
4. migrationを実行する。
5. コンテナを再作成する。
6. health checkを確認する。
7. 異常時は直前のイメージタグへ戻す。

DB migrationが後方互換でない場合、イメージだけ戻しても復旧できない。カラム削除やrenameは複数回のリリースへ分ける。

## 初回デプロイの完了条件

- HTTPSまたは一時的なHTTP health checkが成功する
- TenantとAdminへログインできる
- 一般ユーザー画面からRails APIへ接続できる
- 画像をS3へ保存して再表示できる
- workerがジョブを処理する
- EC2再起動後にコンテナが起動し、DBデータが残る
