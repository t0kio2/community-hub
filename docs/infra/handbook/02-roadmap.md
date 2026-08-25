# 構築ロードマップ

## 全体像

一度にすべて作らず、各Phaseの確認が終わってから次へ進む。

```text
Phase 0 安全設定
  ↓
Phase 1 ローカル準備
  ↓
Phase 2 Terraform bootstrap
  ↓
Phase 3 AWS基盤
  ↓
Phase 4 EC2初期化
  ↓
Phase 5 アプリ配備
  ↓
Phase 6 DNS・HTTPS
  ↓
Phase 7 バックアップ・監視
  ↓
Phase 8 CI/CD
```

## Phase 0: AWSアカウントを安全にする

- [ ] Root userへMFAを設定した
- [ ] 日常作業用の管理者Identityを作成した
- [ ] AWS Budgetsで料金通知を設定した
- [ ] 使用リージョンを東京`ap-northeast-1`に決めた
- [ ] ドメインを使用するか決めた

到達条件: 誤課金とアカウント侵害を検知できる。

## Phase 1: ローカル環境を準備する

- [ ] AWS CLIをインストールした
- [ ] Terraformをインストールした
- [ ] AWS CLIで対象アカウントを確認できた
- [ ] Terraformのバージョンを確認できた
- [ ] Gitへ秘密値を含めないルールを確認した

到達条件: ローカル端末からAWS APIを安全に操作できる。

## Phase 2: Terraform bootstrapを作る

- [ ] State用S3 Bucketを作成した
- [ ] 暗号化、バージョニング、Public Access Blockを有効にした
- [ ] Terraform backendをS3へ切り替えた
- [ ] Stateを読み書きできることを確認した

到達条件: 以後のインフラをリモートStateで管理できる。

## Phase 3: AWS基盤を作る

- [ ] VPCとPublic Subnetを作成した
- [ ] Internet GatewayとRoute Tableを作成した
- [ ] 80/443だけを許可するSecurity Groupを作成した
- [ ] EC2用IAM RoleとInstance Profileを作成した
- [ ] EC2、EBS、Elastic IPを作成した
- [ ] 必要なS3、SSM、CloudWatchを作成した

到達条件: Session ManagerでEC2へ接続できる。

## Phase 4: EC2を初期化する

- [ ] Docker EngineとCompose Pluginを使用できる
- [ ] EBSが想定したパスへマウントされる
- [ ] 再起動後もEBSが自動マウントされる
- [ ] PostgreSQL用ディレクトリの所有者と権限が正しい
- [ ] CloudWatchへOSまたはコンテナログを送れる

到達条件: EC2再起動後もコンテナと永続領域を利用できる。

## Phase 5: アプリを配備する

- [ ] RailsとNext.jsのproductionイメージをbuildできる
- [ ] EC2上で対象commitのproductionイメージをbuildできる
- [ ] SSMから秘密値を取得できる
- [ ] production用Composeを起動できる
- [ ] DB migrationとseedを実行できる

到達条件: EC2のIPアドレス経由でアプリのヘルスチェックに成功する。

## Phase 6: DNSとHTTPSを設定する

- [ ] Route 53のRecordがElastic IPを指している
- [ ] リバースプロキシがTLS証明書を取得した
- [ ] HTTPからHTTPSへリダイレクトされる
- [ ] Railsのhost、CORS、cookie設定が公開URLに対応している

到達条件: 公開URLから各画面をHTTPSで利用できる。

## Phase 7: 運用を確認する

- [ ] `pg_dump`をS3へ保存できる
- [ ] バックアップから別DBへ復元できる
- [ ] EBS Snapshotの保持方針を設定した
- [ ] CPU、メモリ、ディスク、HTTP異常の通知を確認した
- [ ] EC2再起動試験を行った
- [ ] `terraform destroy`後の残存課金を確認する手順がある

到達条件: 壊れたときに復元でき、不要時に安全に破棄できる。

## Phase 8: CI/CDを追加する

手動デプロイが成功してから自動化する。

- [ ] GitHub ActionsとAWSをOIDCで接続した
- [ ] Pull Requestでtest、Terraform fmt、validate、planを実行する
- [ ] 承認後だけデモ環境へdeployする
- [ ] migration失敗時にコンテナを切り替えない
- [ ] 直前のDockerイメージへ戻す手順を確認した

到達条件: 固定アクセスキーなしで、再現可能なデプロイができる。
