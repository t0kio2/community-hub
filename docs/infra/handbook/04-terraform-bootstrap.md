# Terraform bootstrap

## bootstrapが必要な理由

通常のTerraform StateはS3へ保存する。しかし、そのS3 Bucket自身を作る前にはS3 backendを利用できない。この最初の土台だけをbootstrapとして分離する。

bootstrapで管理する候補は次のとおり。

- Terraform State用S3 Bucket
- Stateの排他制御設定
- 必要ならRoute 53 Hosted Zone
- GitHub Actions用OIDC ProviderとTerraform実行Role

デモ環境を`terraform destroy`しても、State用Bucketを同時に削除しない。

## 予定するディレクトリ

Terraform実装時にはリポジトリルートへ次を追加する。

```text
infrastructure/
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── environments/
│   └── development/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
└── modules/
```

値を含む`terraform.tfvars`と`.terraform/`はGit管理しない。値の見本だけを`terraform.tfvars.example`へ置く。

## 実装時の手順

現時点ではTerraformコードがまだないため、以下はコード追加後に実行する作業順序である。

```sh
cd infrastructure/bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

`apply`前に、planへ意図しないIAM権限や公開設定がないことを確認する。

作成後、`environments/development/backend.tf`へS3 backendを設定する。

```hcl
terraform {
  backend "s3" {
    bucket       = "実際のState用Bucket名"
    key          = "community-hub/development/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

Bucket名は世界全体で一意である必要がある。実際の名前をこの文書やソースへ固定せず、bootstrapのoutputから確認する。

## 検証項目

- S3のPublic Access Blockがすべて有効
- Bucket Versioningが有効
- サーバーサイド暗号化が有効
- Stateを閲覧できるIAM Principalが限定されている
- `terraform init`でS3 backendを初期化できる
- 連続した`terraform plan`で不要な差分が出ない

## bootstrapを削除するとき

先にデモ環境を破棄し、Stateが不要であることを確認する。State用Bucketの削除は通常の`development`環境破棄へ含めず、最後に明示的に行う。
