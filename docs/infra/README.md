# Community Hub デモ環境構築ガイド

## この文書の目的

このディレクトリは、AWSやTerraformに慣れていない開発者が、Community Hubのデモ環境を段階的に構築できるようにするための入門書兼作業手順書である。

AWSリソースはTerraformで再現可能にし、EC2上のアプリケーションはDocker Composeで管理する。デモ環境では費用を抑えるため、Rails、Next.js、PostgreSQLを1台のEC2で動かす。現在採用している詳細構成は[単一EC2での低コストデプロイ構成](single-ec2-deployment.md)を参照する。

現在リポジトリに実装されているローカル環境とAWSサーバー環境は、[インフラアーキテクチャ](architecture.md)のMermaid図を参照する。

## 最終的に作るもの

```text
利用者
  │ HTTPS
  ▼
Route 53
  │
  ▼
Elastic IP
  │
  ▼
EC2（Public Subnet）
├── Nginx
├── Next.js
├── Rails
├── Solid Queue
├── PostgreSQL
│     └── EBSへデータを永続化
└── Certbot

外部サービス
├── S3: Terraform Stateと必要に応じたDBバックアップ
├── SSM Parameter Store: 秘密値
└── CloudWatch: ログと監視
```

これは可用性より費用と学習効果を優先したデモ構成である。本格運用ではPostgreSQLをRDSへ移し、アプリケーションを複数台に分ける。

## Terraformと手作業の境界

| 対象 | 管理方法 | 理由 |
|---|---|---|
| VPC、Subnet、Route Table | Terraform | 同じネットワークを再現するため |
| Security Group | Terraform | 公開ポートをコードレビュー可能にするため |
| EC2、EBS、Elastic IP | Terraform | サーバーと永続領域を再作成するため |
| IAM、S3、SSM、CloudWatch | Terraform | 権限と周辺サービスを再現するため |
| シークレットの実際の値 | 手動またはCI | Terraform Stateへ秘密値を残さないため |
| EC2上でのDockerイメージbuild | デプロイスクリプトまたはCI | ECRを使わず、アプリのリリースとインフラ変更を分離するため |
| `docker compose up`とDB migration | デプロイスクリプトまたはCI | Terraformの責務にしないため |
| 初回管理者やデモデータ | Railsのtaskまたはseed | アプリケーションデータとして管理するため |

## 読む順番

1. [01-foundations.md](handbook/01-foundations.md): AWS、Terraform、Dockerの役割を理解する
2. [single-ec2-deployment.md](single-ec2-deployment.md): 現在採用している低コスト構成を確認する
3. [overview.md](overview.md): 構成全体と設計判断を確認する
4. [02-roadmap.md](handbook/02-roadmap.md): 全工程と現在地を把握する
5. [03-prerequisites.md](handbook/03-prerequisites.md): AWSアカウントとローカル環境を準備する
6. [04-terraform-bootstrap.md](handbook/04-terraform-bootstrap.md): Terraform Stateの保存先を作る
7. [05-development-infrastructure.md](handbook/05-development-infrastructure.md): ネットワーク、EC2、EBSなどを作る
8. [06-deployment.md](handbook/06-deployment.md): コンテナをEC2へデプロイする
9. [07-operations.md](handbook/07-operations.md): バックアップ、監視、更新、破棄を行う

## 最初に行うこと

まだAWSリソースを作らない。最初の作業は次の3点である。

1. `handbook/01-foundations.md`と`overview.md`を読む。
2. `handbook/03-prerequisites.md`のAWSアカウント保護と料金通知を完了する。
3. `handbook/02-roadmap.md`のPhase 0のチェックをすべて完了する。

料金通知と多要素認証を設定する前に、EC2などの有料リソースを作らない。

## 文書のステータス

このガイドは構築方針と実施順序を定義している。Terraformコードと本番用Docker Composeは今後この手順に沿って追加する。コードが追加された段階で、各章のコマンドを実際のファイル名に合わせて更新する。

## 完了条件

- HTTPSで一般ユーザー画面、Tenant画面、Admin画面を表示できる
- EC2を再起動してもPostgreSQLのデータが残る
- PostgreSQLの5432番ポートがインターネットへ公開されていない
- SSHの22番ポートを開けず、Session ManagerでEC2へ接続できる
- S3へDBバックアップを保存し、復元手順を確認できる
- Terraformでデモ環境を作成・破棄できる
- 破棄後に意図しない課金対象が残っていない
