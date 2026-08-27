# インフラ構成案

## 目的

- AWSのネットワーク、IAM、コンピュート、DB、ストレージを扱えることを示す
- EC2上のLinux、Docker、HTTPS、デプロイ、監視を自分で構築できることを示す
- Terraformによって同じ環境を再現できるようにする
- 非公開時はデモ環境を削除し、維持費を抑える
- デモ環境と実運用を想定した構成の差を説明できるようにする

## アプリケーション構成

現在のアプリケーションは次の要素で構成される。

- Rails: JSON API、Admin画面、Tenant画面
- Next.js: 一般ユーザー向け画面
- PostgreSQL: 業務データとRailsのSolid系データ
- Solid Queue: バックグラウンドジョブ
- Active Storage: Listing画像などのファイル管理

## デモ環境の基本構成 - パブリックVPC構成

初期のデモ環境では、AWSとサーバー構築の両方を示しつつ、常時費用を抑えられる構成を採用する。

```text
Internet
   │
Route 53
   │
Public IPv4 / Elastic IP
   │
EC2（Public Subnet）
├── HTTPSリバースプロキシ
├── Next.js
├── Rails Web
├── Solid Queue Worker
└── PostgreSQL
   │  └── EBS（DBデータ永続化）
   │
   ├── S3（Active Storage）
   └── CloudWatch（ログ・監視）
```

### EC2

- 東京リージョンを使用する
- 初期候補はARM64の`t4g.medium`とする
- Rails、Next.js、Solid Queue、リバースプロキシをDockerコンテナとして動かす
- デプロイ方式はDocker Composeとし、EC2上でソースからイメージをbuildする
- SSHポートは公開せず、Systems Manager Session Managerで接続する
- EC2 Instance Profileを使用し、固定アクセスキーを配置しない

### ネットワーク

- EC2はPublic Subnetへ配置する
- EC2へのInboundはHTTP／HTTPSに限定する
- PostgreSQLはDocker内部ネットワークだけで接続し、5432番ポートを公開しない
- 初期デモ環境ではNAT Gatewayを使用しない
- ALBは常時料金が発生するため、初期デモ環境には置かない

### PostgreSQL

- デモ環境ではEC2上のPostgreSQLコンテナを使用する
- PostgreSQLデータは専用EBSへ永続化し、コンテナ内へ保存しない
- Railsの`primary`、`cache`、`queue`、`cable`は、同じPostgreSQL内の論理DBとして管理する
- EBS SnapshotとS3へ保存する`pg_dump`を併用する
- デモデータはRailsのseedから再作成できるようにする
- 本格運用ではRDS PostgreSQLへの移行を第一候補とする

### ファイルとコンテナイメージ

- Listing画像などはS3へ保存する
- S3 Bucketは非公開とし、IAM Role経由でRailsからアクセスする
- ECRは使用せず、EC2上でGitから取得したソースをDockerイメージへbuildする
- デプロイ前後のGit commit SHAを記録し、更新とロールバックの基準にする

### HTTPSとDNS

- DNSはRoute 53で管理する
- ALBを使わず、EC2上のNginxでTLSを終端する
- TLS証明書はLet's EncryptからCertbotで取得し、自動更新する
- デモ環境を再作成したときは、Terraformが新しいPublic IPv4をRoute 53へ反映する
- Elastic IPを常設するか、環境と一緒に削除するかは、公開頻度と料金を見て決定する

## Terraformの構成

Terraformは、常設する基盤と作成・破棄するデモ環境を分離する。

```text
infrastructure/
├── bootstrap/
│   ├── Terraform State用S3
│   └── Route 53 Hosted Zone
├── environments/
│   └── development/
│       ├── network
│       ├── compute
│       ├── compute
│       ├── storage
│       └── monitoring
└── modules/
    ├── network/
    ├── compute/
    ├── compute/
    └── storage/
```

### 常設するリソース

- ドメイン
- Route 53 Hosted Zone
- Terraform State用S3 Bucket
- 必要に応じてデータ退避用S3 Bucket

Terraform State用S3 Bucketはデモ環境の`terraform destroy`対象に含めない。暗号化、バージョニング、Public Access Blockを有効にする。

### 作成・破棄するリソース

- VPC、Subnet、Route Table
- Security Group
- EC2、EBS
- Public IPv4またはElastic IP
- デモ環境固有のS3 Bucket
- CloudWatch Log Group、Alarm
- IAM Role、Policy
- Route 53のデモ用Record

## デモ環境のライフサイクル

### 構築

```text
terraform apply
      ↓
ネットワーク、EC2、EBSなどを作成
      ↓
EC2上でDockerイメージをbuildして起動
      ↓
Rails db:prepare / db:migrate
      ↓
デモ用seedを投入
      ↓
ヘルスチェックと画面確認
```

将来的には次のようなコマンドへまとめる。

```sh
make development-up
```

### 破棄

```text
terraform plan -destroyで対象確認
      ↓
必要な場合だけDBスナップショットを作成
      ↓
terraform destroy
      ↓
残存するEBS、Elastic IP、Snapshot、Logを確認
```

将来的には次のようなコマンドへまとめる。

```sh
make development-down
```

## CI/CD

GitHub Actionsの手動実行から次の処理を行える構成を目標とする。

- Terraform fmt、validate、plan
- Railsテスト
- Next.jsテストとビルド
- EC2上でのDockerイメージのビルドとデプロイ
- デモ環境の構築
- DB migration
- ヘルスチェック
- デモ環境の破棄

本番適用に相当するジョブにはGitHub Environmentの承認を設定する。AWS認証には固定アクセスキーではなく、GitHub ActionsのOIDCを使用する。

## シークレット管理

- DBパスワードや`RAILS_MASTER_KEY`をGitへ保存しない
- Terraformコードへシークレット値を直接記述しない
- SSM Parameter StoreまたはSecrets Managerの採用を実装時に決定する
- Terraform Stateを機密情報として扱い、アクセス権を限定する
- Next.jsの`NEXT_PUBLIC_*`には公開してよい値だけを設定する

## 監視と運用

- Rails、Next.js、WorkerのログをCloudWatch Logsへ送る
- EC2、PostgreSQLコンテナ、EBSのCPU、メモリ、ストレージを監視する
- HTTPヘルスチェックを用意する
- デプロイ失敗時のロールバック方法を文書化する
- `pg_dump`とEBS Snapshotから定期的にリストア確認を行う
- AWS Budgetsで月額予算の通知を設定する

## 費用方針

EC2を停止しても、EBS、Elastic IP、ALB、NAT Gatewayなどは残存状況に応じて課金される。そのため、長期間公開しない場合はEC2の停止だけでなく、デモ環境を`terraform destroy`する。

Terraformで削除しても、常設するRoute 53、State用S3、スナップショット、ログ、ドメインには少額の費用が残る。実装前と公開前にAWS Pricing Calculatorで見積もり、AWS Budgetsを設定する。

## 本番想定との差

ポートフォリオ用デモ環境では費用を優先し、Single-AZ、単一EC2、ALBなしで構築する。本格運用する場合は次を再検討する。

- EC2の複数台構成またはECS Fargateへの移行
- ALBとACMの導入
- RDS Multi-AZ
- Private Subnet上のアプリケーションサーバー
- NAT GatewayまたはVPC Endpoint
- Auto Scaling
- WAF、CloudFront
- 障害時の自動復旧
- Blue／Green Deployment

READMEや構成図では、デモ環境を本番相当と表現せず、費用上省略した構成と本番で追加する要素を明示する。

## 実装前の未決事項

- Public IPv4を毎回再取得するか、Elastic IPを常設するか
- PostgreSQL用EBSを環境と同時に削除するか、Snapshotを残すか
- S3をDBバックアップやActive Storageに使用するか
- Next.jsとRailsのドメイン構成
- SSM Parameter StoreとSecrets Managerのどちらを採用するか
- デモ環境の起動時間と許容月額

これらはTerraform実装前に決定し、本書を更新する。

## 検証方針

- 空のAWSアカウント相当から`terraform apply`だけで再現できること
- 同じ構成へ繰り返し`terraform apply`して不要な差分が出ないこと
- `terraform destroy`後に意図しない課金対象が残っていないこと
- Admin、Tenant、ユーザー画面とAPIがHTTPSで利用できること
- Rails migrationとseedを自動実行できること
- PostgreSQLの5432番ポートへインターネットから接続できないこと
- EC2へSSHポートを開けずにSession Managerで接続できること
- バックアップからデータを復元できること
