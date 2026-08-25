# 単一EC2での低コストデプロイ構成

## 目的

Community Hubを、AWSのマネージドサービスを最小限にして低コストで公開する。
可用性よりも費用と構成の単純さを優先し、Rails、Next.js、PostgreSQL、Nginxを1台のEC2上でDocker Composeにより運用する。

この構成ではRDS、ECR、ALB、NAT Gatewayを使用しない。

## 全体構成

```text
利用者
  │ HTTP 80 / HTTPS 443
  ▼
Elastic IP
  │
  ▼
EC2（Public Subnet）
├── Nginxコンテナ
│     ├── TLS終端
│     ├── HTTPからHTTPSへのリダイレクト
│     └── Rails／Next.jsへのリバースプロキシ
├── Railsコンテナ
├── Solid Queue Workerコンテナ
├── Next.jsコンテナ
├── PostgreSQLコンテナ
│     └── EBS上へデータを永続化
└── Certbotコンテナ
      └── Let's Encrypt証明書を取得・更新
```

RailsとPostgreSQLは同じEC2で動かすが、同じコンテナには入れない。サービスごとにコンテナを分離し、Docker Composeの内部ネットワークで通信する。

## 採用しないAWSサービス

| サービス | 採用しない理由 | 代替手段 |
|---|---|---|
| RDS | 常時料金を抑える | EC2上のPostgreSQLコンテナ |
| ECR | イメージ保存料金と構成要素を減らす | EC2上でソースからDockerイメージをbuild |
| ALB | 小規模構成では固定費が大きい | EC2上のNginx |
| NAT Gateway | 時間料金と通信料金を避ける | EC2をPublic Subnetへ配置 |
| ACM | 証明書をEC2上のNginxへ直接配置できない | Let's EncryptとCertbot |

## Terraformが管理する範囲

TerraformではAWSインフラとEC2初期設定を管理する。

- VPC
- Public Subnet
- Internet Gateway
- Route TableとSubnetの関連付け
- Security Group
- EC2
- Elastic IP
- EBSとEC2へのアタッチ
- 必要最小限のIAM Role
- `user_data`によるDocker EngineとDocker Composeの導入
- 必要に応じてDNS Record

Terraformから`docker compose up`、Rails migration、アプリケーション更新は実行しない。これらはデプロイスクリプトまたは将来のCI/CDで管理する。

## Security Group

外部公開するInboundは次に限定する。

| ポート | 用途 | 接続元 |
|---|---|---|
| 22 | SSH | 管理者の固定IPのみ。Session Manager採用後は閉じる |
| 80 | HTTP、Let's Encrypt HTTP-01認証 | `0.0.0.0/0` |
| 443 | HTTPS | `0.0.0.0/0` |

Railsの3000番、Next.jsの3001番、PostgreSQLの5432番はEC2の外へ公開しない。

## Docker Composeの責務

production用Composeでは、少なくとも次のサービスを定義する。

```text
nginx
├── backend:3000
└── user-frontend:3001

backend ── db:5432
worker  ── db:5432
```

運用上の原則は次のとおりとする。

- Nginxだけがホストの80番と443番を公開する
- Rails、Next.js、PostgreSQLにはホスト向けの`ports`を設定しない
- PostgreSQLデータをコンテナの書き込みレイヤーへ保存しない
- DBデータはEBSの`/data/postgres`などへbind mountする
- 各サービスに`restart: unless-stopped`とhealth checkを設定する
- productionではソースコードをコンテナへbind mountしない
- シークレットをDockerfileやDockerイメージへ含めない

## ECRを使わないデプロイ

アプリケーションのソースをGitからEC2へ取得し、EC2上でDockerイメージをbuildする。

初回デプロイの流れ:

1. EC2へDocker EngineとDocker Composeを導入する。
2. `/opt/community-hub`へリポジトリをcloneする。
3. 権限を制限したproduction用環境変数ファイルを配置する。
4. PostgreSQLコンテナを起動してhealth checkを待つ。
5. Railsのproductionイメージをbuildする。
6. `db:prepare`または`db:migrate`を実行する。
7. Rails、Worker、Next.jsを起動する。
8. NginxをHTTPで起動する。
9. CertbotでTLS証明書を取得する。
10. NginxをHTTPS設定へ切り替えて疎通確認する。

更新時は、対象commitをcheckoutして再buildする。

```sh
cd /opt/community-hub
git fetch --prune
git checkout <commit-sha>
docker compose -f docker-compose.production.yml build
docker compose -f docker-compose.production.yml run --rm backend bin/rails db:migrate
docker compose -f docker-compose.production.yml up -d
```

問題が発生した場合に戻せるよう、デプロイ前のcommit SHAを記録する。DB migrationに後方互換性がない場合、ソースを戻すだけでは復旧できないため、破壊的なmigrationは複数回のリリースへ分ける。

## PostgreSQLの永続化

PostgreSQLはRailsと別コンテナで動かし、データはEBSへ保存する。

```text
EC2
└── /data/postgres  ← EBS
      ↕ bind mount
    PostgreSQLコンテナ:/var/lib/postgresql/data
```

EC2やコンテナの再作成だけでDBデータが失われないことを確認する。ただし、単一EC2・単一EBS構成には自動フェイルオーバーがないため、定期的に`pg_dump`を取得し、EC2外へ退避する。

## TLS証明書

TLS証明書には無料のLet's Encryptを使用する。

事前条件:

- DNSのAレコードがElastic IPを指している
- Security Groupで80番と443番が開いている
- Nginxが80番で`/.well-known/acme-challenge/`を配信できる

NginxとCertbotで次のディレクトリを共有する。

```text
certbot/www   # HTTP-01認証ファイル
certbot/conf  # 証明書と秘密鍵
```

証明書取得後、Nginxは次のファイルを読み込む。

```text
/etc/letsencrypt/live/<domain>/fullchain.pem
/etc/letsencrypt/live/<domain>/privkey.pem
```

Certbotの`renew`をcronなどで1日2回実行し、更新成功後にNginxをreloadする。`certbot/conf`には秘密鍵が含まれるためGitへcommitしない。

## シークレット管理

次の値をGit、Dockerfile、Terraformコードへ記録しない。

- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- PostgreSQLパスワード
- 外部APIキー

初期構成ではEC2上の権限を制限した環境ファイルへ保存できる。ファイルは所有者だけが読める`0600`とし、将来必要になった場合はSSM Parameter Storeへ移行する。

## バックアップ

最低限、次のバックアップを用意する。

- PostgreSQLの定期的な`pg_dump`
- Terraform State用S3のバージョニング
- 必要に応じたEBS Snapshot

バックアップはEC2や同じEBSだけへ保存せず、障害時にも取得できる場所へ退避する。作成だけでなく、一時DBへのrestore試験を定期的に行う。

## 主な費用

この構成でもAWS費用が完全に0円になるとは限らない。主な課金対象は次のとおり。

- EC2の稼働時間
- EBSの容量とSnapshot
- Elastic IPを含むPublic IPv4
- インターネットへのデータ転送
- DNSとドメインをAWSで管理する場合のRoute 53およびドメイン料金

長期間公開しない場合は、DBバックアップの取得後に`terraform destroy`する。EC2を停止しただけではEBSやPublic IPv4などの料金が残る可能性がある。

## 構築完了条件

- Nginxの80番からHTTPSへリダイレクトされる
- 公開URLへHTTPSでアクセスできる
- RailsとNext.jsの主要画面が表示される
- PostgreSQLの5432番がインターネットへ公開されていない
- EC2再起動後にコンテナが復帰する
- EC2再起動後もDBデータが残る
- Certbotの更新テストが成功する
- `pg_dump`から一時DBへ復元できる
- `terraform destroy`後に意図しない課金リソースが残っていない

## 今後の実装順序

1. TerraformでSecurity Groupの80番と443番を許可する。
2. `user_data`でDocker EngineとDocker Composeを導入する。
3. production用DockerfileとComposeを作成する。
4. PostgreSQLのEBS永続化を設定する。
5. EC2上でRailsとPostgreSQLの起動を確認する。
6. Next.jsとWorkerを起動する。
7. Nginxを追加する。
8. DNSをElastic IPへ向ける。
9. CertbotでTLS証明書を取得し、自動更新を設定する。
10. バックアップと復元手順を実装する。

