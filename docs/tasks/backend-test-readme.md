# Backendテスト実行手順のREADME整備

## 目的

BackendのRailsテストを、ホストRubyではなくDocker Composeの`backend`サービスで実行する手順を`backend/README.md`に記載する。

## 変更範囲

- `backend/README.md`
- アプリケーション、データモデル、APIへの変更は行わない。

## 記載内容

- Docker Composeサービスの起動
- test環境と`app_test`データベースを明示したテストDBの準備
- 全テスト、ファイル単位、行指定のテスト実行

## 検証

README内のコマンドが、リポジトリのComposeサービス名とRepository Instructionsに一致することを確認する。ドキュメント変更のみのため、テストは実行しない。
