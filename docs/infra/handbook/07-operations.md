# 運用、バックアップ、障害対応

## 日常確認

- 公開URLのhealth check
- EC2のCPU、メモリ、ディスク使用率
- PostgreSQLコンテナの状態
- Rails、Next.js、workerのエラーログ
- EBS Snapshotと`pg_dump`の最終成功時刻
- AWS Budgetsの実績
- ECR、S3、CloudWatch Logsの使用量

## PostgreSQLバックアップ

異なる障害へ備えるため、2種類を使う。

### EBS Snapshot

ディスク全体を復元しやすい。一方、実行時のDB整合性と復元手順を確認する必要がある。Snapshotの世代数と保持期間を決める。

### pg_dump

PostgreSQLの論理バックアップである。production用ComposeのDBサービスを対象に取得し、暗号化されたS3へ送る。

バックアップは、作成できたことではなく復元できたことで成功と判断する。定期的に一時DBへrestoreし、主要テーブルの件数とRails起動を確認する。

## 復元手順で記録するもの

- 使用したDockerイメージタグ
- PostgreSQLのmajor version
- バックアップ作成日時
- S3 object keyまたはSnapshot ID
- 復元先DB名
- 実行したコマンド
- 検証した画面とデータ

本番DBへ直接restoreせず、最初に別DBまたは検証環境へ復元する。

## ディスク容量不足

確認対象:

- PostgreSQLデータ
- Docker imageとbuild cache
- コンテナログ
- Railsログ
- 一時的なバックアップファイル

不用意にPostgreSQLデータディレクトリを削除しない。EBS拡張時は、AWS上のvolume拡張後にOSのpartitionとfilesystemも拡張する。

## コンテナ障害

1. `docker compose ps`で状態を確認する。
2. 対象サービスのログを確認する。
3. ディスク容量とメモリ不足を確認する。
4. 環境変数とECRイメージタグを確認する。
5. 必要なら直前の正常なイメージへ戻す。

ログへシークレットや個人情報を出力しない。

## EC2障害

単一EC2構成では自動failoverしない。

1. EC2 Status CheckとCloudWatch Alarmを確認する。
2. 再起動で復旧するか確認する。
3. EBSが正しく接続・マウントされているか確認する。
4. 復旧不能ならTerraformで新しいEC2を作成する。
5. EBSまたはバックアップからDBを復元する。
6. Elastic IPを新しいEC2へ関連付ける。
7. health checkを行う。

この手順を実際に演習し、手動復旧に必要な時間を記録する。

## デモ環境を停止・破棄する

EC2を停止しても、EBS、Elastic IP、Snapshot、S3、ECR、CloudWatch Logsなどの費用が残る。長期間使わない場合はTerraformで破棄する。

破棄前:

- 必要なDBバックアップを取得する
- S3上の画像を残すか決める
- Terraform planの対象環境とAccount IDを確認する
- State用S3 Bucketが破棄対象に含まれないことを確認する

```sh
aws sts get-caller-identity
cd infra/environments/demo
terraform plan -destroy
terraform destroy
```

`terraform destroy`は実装後、planの全削除対象を目視確認してから行う。

破棄後:

- EC2とEBS
- Elastic IP
- Snapshot
- NAT GatewayやLoad Balancer
- S3 object
- ECR image
- CloudWatch Logs
- Route 53 record

をAWS Cost Explorerと各サービス画面で確認する。常設するState用S3、Hosted Zone、ドメインなどは残る。

## 定期的なセキュリティ更新

- EC2 OSのセキュリティ更新
- Docker Engineの更新
- PostgreSQLイメージのpatch更新
- Ruby、Rails、Node.js、Next.jsの更新
- Docker base imageの再build
- IAM権限の棚卸し
- 不要なSSM Sessionと古いECR imageの確認

PostgreSQLのmajor versionは、イメージタグを書き換えるだけで更新しない。バックアップと公式のupgrade手順を準備し、検証環境で確認する。

