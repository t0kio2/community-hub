# インフラ構築の基礎知識

## まず理解する4つの層

Community Hubのデモ環境は、次の4層に分けて考える。

### 1. AWS

サーバー、ネットワーク、ディスク、DNSなどを提供する場所である。

- EC2: Linuxサーバー
- EBS: EC2へ接続する永続ディスク
- VPC: AWS内のネットワーク
- Security Group: 通信を許可するファイアウォール
- S3: 画像やバックアップの置き場
- Route 53: ドメインとIPアドレスの対応付け
- Systems Manager: SSHを公開せずEC2へ接続する仕組み

### 2. Terraform

AWSリソースの設計図をコードで記述する道具である。

```text
Terraformコード
   │ terraform plan
   ▼
変更内容を確認
   │ terraform apply
   ▼
AWSリソースを作成・変更
```

TerraformはRailsのデプロイツールではない。VPCやEC2を作るところまでを担当し、アプリの更新は別のデプロイ処理が担当する。

### 3. Docker Compose

EC2上で動かす複数コンテナをまとめて管理する。

- reverse-proxy
- user-frontend
- backend
- worker
- db

開発用のルート直下`docker-compose.yml`を、そのまま本番で使用しない。開発用設定にはソースコードのbind mount、開発サーバー、公開されたPostgreSQLポートなどが含まれるため、本番用Composeを別途用意する。

### 4. アプリケーション

RailsとNext.js自身の設定である。DB migration、seed、アセット保存先、秘密値などはこの層で扱う。

## EC2とEBSの関係

EC2のコンテナ内だけにPostgreSQLデータを保存すると、コンテナの作り直しでデータを失う。PostgreSQLの保存先にはEBS上のディレクトリを割り当てる。

```text
PostgreSQLコンテナ
  /var/lib/postgresql/data
            │ bind mount
            ▼
EC2
  /data/postgres
            │
            ▼
EBS volume
```

EBSはバックアップそのものではない。誤削除や論理的なデータ破損に備え、EBS Snapshotと`pg_dump`を併用する。

## ネットワークの基本

インターネットへ公開するのはHTTPの80番とHTTPSの443番だけにする。

| ポート | 用途 | インターネット公開 |
|---|---|---|
| 80 | HTTPSへのリダイレクトと証明書取得 | 許可 |
| 443 | Webアクセス | 許可 |
| 22 | SSH | 不許可 |
| 3000 | Next.js内部通信 | 不許可 |
| 3001 | Rails内部通信 | 不許可 |
| 5432 | PostgreSQL | 不許可 |

コンテナ同士はDockerの内部ネットワークで通信する。Railsの`DATABASE_URL`では、DBホストに`localhost`ではなくComposeのサービス名`db`を指定する。

## Stateとは何か

Terraformは、作成したAWSリソースとコードの対応をStateに保存する。Stateを失うと安全な変更や削除が難しくなる。

- StateはGitへcommitしない
- S3へ保存する
- S3の暗号化、バージョニング、Public Access Blockを有効にする
- Stateには機密情報が含まれる可能性があるため閲覧権限を絞る

## 環境変数と秘密値

次の値をGitやDockerイメージへ含めない。

- PostgreSQLパスワード
- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- `DEVISE_JWT_SECRET_KEY`
- Google Maps API key

デモ環境ではSSM Parameter Storeへ保存し、EC2のIAM Roleを使って取得する。固定のAWSアクセスキーをEC2へ置かない。

## デモ構成の制約

単一EC2へアプリとDBを同居させるため、次の制約がある。

- EC2障害中はアプリとDBの両方が停止する
- デプロイ時に短時間停止する可能性がある
- CPUとメモリをアプリとDBで共有する
- Auto Scalingできない

これらはデモ環境として許容する。本格運用へ移る場合は、最初にPostgreSQLをRDSへ移す。
