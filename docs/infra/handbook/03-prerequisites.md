# 事前準備

## 1. AWSアカウントの保護

AWS Root userは日常作業に使わず、MFAを設定する。日常作業にはIAM Identity Centerなどで作成した管理者Identityを使用する。

AWS Budgetsでは、小さい金額から段階的な通知を設定する。設定額は実装時点の見積もりに合わせ、メール通知が実際に届くことを確認する。

## 2. 使用する名前を決める

例として次を使用する。実装時にはTerraformのvariablesへ移す。

| 項目 | 例 |
|---|---|
| Project | `community-hub` |
| Environment | `demo` |
| AWS Region | `ap-northeast-1` |
| リソース接頭辞 | `community-hub-demo` |
| 公開ホスト | `demo.example.com` |

すべてのリソースへ`Project`、`Environment`、`ManagedBy=Terraform`タグを付ける。

## 3. CLIを準備する

必要なツールは次のとおり。

- Git
- Docker EngineまたはDocker Desktop
- AWS CLI v2
- Terraform

バージョン確認:

```sh
aws --version
terraform version
docker version
docker compose version
```

Terraformの要求バージョンは、Terraformコードを追加するときに`required_version`で固定する。

## 4. AWS認証を設定する

長期アクセスキーより、IAM Identity CenterのSSOを優先する。

```sh
aws configure sso --profile community-hub-demo
aws sso login --profile community-hub-demo
aws sts get-caller-identity --profile community-hub-demo
```

最後の出力にあるAccountとArnが、操作対象のAWSアカウントであることを確認する。

作業シェルではProfileを明示する。

```sh
export AWS_PROFILE=community-hub-demo
export AWS_REGION=ap-northeast-1
aws sts get-caller-identity
```

アクセスキー、Secret Access Key、SSOキャッシュをリポジトリへ保存しない。

## 5. ドメインを準備する

HTTPS公開には、操作可能なドメインまたはサブドメインを用意する。Route 53以外でドメインを取得している場合も、サブドメインだけRoute 53へ委任できる。

ドメインをまだ用意しない場合は、先にIPアドレスとHTTPで動作確認し、HTTPSの工程でドメインを追加する。ただしログイン情報をHTTPで送信しない。

## 6. リポジトリの秘密値を確認する

`.env.example`は変数名の見本であり、実際の値はcommitしない。本番で最低限必要になる値を洗い出す。

- DBユーザー名、DB名、DBパスワード
- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- `DEVISE_JWT_SECRET_KEY`
- `GOOGLE_MAPS_EMBED_API_KEY`
- S3 Bucket名とRegion
- 公開URL

`NEXT_PUBLIC_*`はブラウザへ公開される。秘密値を設定してはいけない。

## 事前準備の確認

```sh
aws sts get-caller-identity
terraform version
docker compose version
git status --short
```

次へ進む条件:

- AWS Account IDを目視確認した
- MFAと料金通知を設定した
- CLIからAWSへ認証できた
- `.env`や秘密鍵がGitの追跡対象になっていない

