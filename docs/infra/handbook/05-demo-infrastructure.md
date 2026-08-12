# デモ用AWS基盤の構築

## この章の範囲

TerraformでAWS側の土台を作り、Session ManagerからEC2へ接続できる状態にする。アプリケーションのデプロイは次章で行う。

## 作成順序

### 1. Network

- 1つのVPC
- 1つのPublic Subnet
- Internet Gateway
- Public Subnet用Route Table
- EC2用Security Group

Security GroupのInboundは80と443だけを許可する。22、3000、3001、5432は許可しない。Outboundは、OS更新、ECR、S3、SSM、外部APIへの通信要件を確認して定義する。

### 2. IAM

EC2 Instance Roleへ必要最小限の権限を付与する。

- Systems Managerで接続する権限
- ECRからイメージをpullする権限
- 指定したS3 Bucketへアクセスする権限
- 指定したSSM Parameterを読む権限
- CloudWatch Logsへ書き込む権限

管理者権限や全S3 Bucketへの権限をEC2へ付けない。

### 3. Storage

- PostgreSQL用EBS
- Active Storage用S3 Bucket
- DBバックアップ用S3 Bucketまたはprefix
- ECR Repository

PostgreSQL用EBSには削除保護方針を明示する。デモ環境と一緒に削除する場合も、誤削除に備えたSnapshotまたは`pg_dump`の扱いを決める。

### 4. Compute

- Amazon LinuxまたはUbuntuのEC2
- Instance Profile
- PostgreSQL用EBSのattachment
- Elastic IP
- `user_data`による最低限の初期化

ARM64インスタンスを使う場合、RailsとNext.jsのDockerイメージを`linux/arm64`でbuildできる必要がある。ローカルMacのCPUアーキテクチャだけを前提にせず、ECRへpushするイメージのplatformを明示する。

### 5. ParametersとMonitoring

SSM Parameter Storeにはパラメータの名前とアクセス権をTerraformで作る。SecureStringの実際の値はTerraform外から登録し、Stateへ保存しない。

CloudWatchには最低限、次を用意する。

- コンテナログのLog Group
- EC2 CPUアラーム
- ディスク使用率アラーム
- StatusCheckFailedアラーム

メモリとディスク使用率にはCloudWatch Agentなどの追加設定が必要である。

## EBS初期化

新しいEBSは、ファイルシステム作成後にマウントする。デバイス名はOS上で変わる可能性があるため、実デバイスを確認し、UUIDで`/etc/fstab`へ登録する。

想定するマウント先:

```text
/data
├── postgres
└── caddy
```

ファイルシステム作成は新規ボリュームに一度だけ行う。既存データがあるボリュームへ`mkfs`を実行するとデータを失うため、`user_data`では未初期化か確認してから処理する。

## Terraform実装後の実行手順

```sh
cd infra/environments/demo
terraform init
terraform fmt -check -recursive ../..
terraform validate
terraform plan -out=demo.tfplan
terraform apply demo.tfplan
```

planファイルには環境情報が含まれる可能性があるためGitへcommitしない。

## 構築後の確認

1. Terraform outputからInstance IDとElastic IPを確認する。
2. EC2のPublic IPへ22番ポートが公開されていないことを確認する。
3. AWS Systems ManagerのSession Managerで接続する。
4. `docker version`と`docker compose version`を確認する。
5. `findmnt /data`などでEBSのマウントを確認する。
6. EC2を再起動し、EBSが再度マウントされることを確認する。

アプリのデプロイ前に、ここまでを完了させる。

