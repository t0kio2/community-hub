# Backend環境変数テンプレート

## 目的

Docker ComposeとBackendの起動に必要な環境変数名を、秘密値を含めず`.env.example`で共有する。
Rails自身が`.env`を直接読み込むのではなく、Docker Composeの`backend.env_file`がコンテナへ渡し、Railsが`ENV`から参照する経路も明記する。

## 対象

- PostgreSQL接続設定
- Devise JWT署名鍵
- Google Maps Embed APIキー

## 検証

アプリケーションが参照する環境変数名とテンプレートが一致することを確認する。設定例のみの変更のためテストは実行しない。
