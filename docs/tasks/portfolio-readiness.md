# ポートフォリオ公開までの実装ロードマップ

## 目的

Community Hubを、採用担当者が短時間で価値を理解でき、安全に操作できるポートフォリオとして公開する。

新機能の数ではなく、次の4点を優先する。

1. 代表的なユースケースが最初から最後まで動く
2. インターネットへ安全に公開できる
3. テストとCIで品質を確認できる
4. READMEとデモから設計上の強みが伝わる

## 現在の主な強み

- Admin、Tenant、一般ユーザーの複数ロールがある
- RailsのMVC、JSON API、Next.jsを組み合わせている
- Tenant境界、Policy、Service、JWT認証を実装している
- 宿泊施設、Room Type、Room／Bed、料金プラン、日別料金、販売制御を扱っている
- Model、Controller、Policy、ServiceのBackendテストがある
- Docker ComposeとTerraformによるインフラ構築を進めている
- ER図、アーキテクチャ、運用方針の文書がある

## Phase 1: 見せる機能を完成させる（必須）

### 1. 代表ユースケースを決める

ポートフォリオで説明する主導線を次に固定する。

```text
AdminがTenant Accountを作成
  → Tenantが施設、部屋、料金プラン、販売設定を登録
  → 一般ユーザーが公開施設を閲覧
  → 会員登録・ログインしてお気に入りへ追加
```

- [ ] 各ロールで主導線を最初から最後まで操作できる
- [ ] 空データ、入力エラー、権限不足で画面が破綻しない
- [ ] 他TenantのデータをURLの直接入力やパラメータ変更で操作できない
- [ ] デモに不要な未完成リンクや操作ボタンを非表示または明示する
- [ ] 予約機能を公開範囲に含めるか決定する

予約機能は必須としない。含める場合は、予約作成だけでなく在庫判定、料金確定、承認・取消まで一貫して動くことを公開条件とする。

### 2. 再現可能なデモデータを用意する

- [ ] Admin、Tenant、一般ユーザーの試用アカウントをseedで作成できる
- [ ] 施設、画像、部屋、料金プラン、販売カレンダーのサンプルを用意する
- [ ] seedを複数回実行しても重複や失敗が起きない
- [ ] 個人情報や実在人物の認証情報を含めない
- [ ] 定期的にデモ環境を初期状態へ戻せる

## Phase 2: 公開環境を完成させる（必須）

### 1. AWS BackendのProduction用コンテナ構成

- [ ] Railsを`RAILS_ENV=production`で起動する
- [ ] サーバー用ComposeへNginx、Rails、PostgreSQLを含める
- [ ] 必要な場合はSolid Queue Workerを独立サービスとして起動する
- [ ] production環境ではソースコードをbind mountしない
- [ ] RailsとPostgreSQLをホストへ直接公開せず、Nginxだけを公開する
- [ ] 各サービスへhealth checkと再起動設定を追加する
- [ ] migration失敗時にアプリを不整合な状態で公開しない手順を決める

### 2. Next.jsのVercelデプロイ

- [ ] Vercelで`user-frontend`をRoot Directoryとして設定する
- [ ] Next.jsのproduction buildがVercelで成功する
- [ ] ProductionとPreviewのデプロイ先を分ける
- [ ] `NEXT_PUBLIC_API_ORIGIN`に公開Rails APIのHTTPS Originを設定する
- [ ] Vercelへ登録する環境変数をProduction、Preview、Developmentで分ける
- [ ] `NEXT_PUBLIC_*`には公開してよい値だけを設定する
- [ ] GitHub連携によるPreview deploymentとproduction deploymentの運用を決める

### 3. HTTPS、ドメイン、CORS

- [ ] Vercel FrontendとRails APIに独自ドメインまたはデモ用サブドメインを用意する
- [ ] FrontendとAPIのOriginを確定する
- [ ] NginxでHTTPからHTTPSへリダイレクトする
- [ ] Let's EncryptなどでTLS証明書を取得し、自動更新する
- [ ] RailsのCORSでVercelのProduction Originだけを許可する
- [ ] Preview deploymentをRails APIへ接続させる場合の許可方法を決める
- [ ] Cookieを使用する場合は許可Originの完全一致、`credentials`、Cookie属性を組み合わせてテストする
- [ ] Security GroupのInboundを80、443と必要最小限の管理経路に限定する
- [ ] PostgreSQLの5432番がインターネットから接続できないことを確認する
- [ ] SSHを残す場合は管理者IPだけに限定し、可能ならSession Managerへ移行する

### 4. データ永続化と復旧

- [ ] PostgreSQLデータをEC2の一時領域やコンテナの書き込みレイヤーへ保存しない
- [ ] EC2再起動後もDBデータが残ることを確認する
- [ ] `pg_dump`をEC2外へ定期保存する
- [ ] バックアップから一時DBへ復元する手順を実行確認する
- [ ] デプロイ前のcommit SHAとDBバックアップを記録する

### 5. シークレット管理

- [ ] `.env`、Rails master key、DBパスワード、APIキーをGitへ含めない
- [ ] 公開環境の秘密値を権限制限した環境ファイルまたはSSM Parameter Storeで管理する
- [ ] Vercelの環境変数へRailsやDBの秘密値を登録しない
- [ ] EC2へ固定AWSアクセスキーを配置しない
- [ ] ログ、CI出力、エラーページへ秘密値を出さない

## Phase 3: 公開前のセキュリティ対応（必須）

### 1. 認証トークン

詳細は[認証トークン保存方式の見直し](auth-token-storage.md)を参照する。

- [ ] Refresh Tokenを`localStorage`へ保存しない
- [ ] HttpOnly、Secure、SameSiteを設定したCookieなどへ移行する
- [ ] VercelとRails APIのドメイン構成に合わせてCookieのDomain、SameSite、Secureを決定する
- [ ] FrontendからCookieを送るリクエストへ`credentials`を設定する
- [ ] ログアウト時にCookieとサーバー側Tokenを無効化する
- [ ] Token refresh、期限切れ、再利用、失効をテストする
- [ ] Cookie認証の採用に合わせてCSRF対策を確認する

### 2. 認可と入力境界

- [ ] Admin、Tenant、一般ユーザーの認可をControllerまたはPolicyテストで確認する
- [ ] Tenant IDをリクエストパラメータから自由に指定できないことを確認する
- [ ] 他Tenantに属するLocation、Listing、Room Type、Roomを関連付けられないことを確認する
- [ ] 画像アップロードのContent-Type、容量、拡張子を制限する
- [ ] productionで詳細な例外情報をブラウザへ表示しない
- [ ] `Brakeman`と`bundler-audit`の重大な警告を解消する

## Phase 4: 品質を自動的に証明する（必須）

### 1. GitHub Actions

Pull Requestと主要ブランチへのpushで次を実行する。

- [ ] Rails全テスト
- [ ] RuboCop
- [ ] Brakeman
- [ ] bundler-audit
- [ ] Next.js ESLint
- [ ] TypeScript型チェック
- [ ] Next.js production build
- [ ] Terraform `fmt -check`と`validate`
- [ ] CIが失敗している状態で公開版へマージしない運用を決める

### 2. FrontendとE2Eテスト

- [ ] Frontendのテスト基盤を追加する
- [ ] ログインとログアウトをテストする
- [ ] 施設一覧の取得とエラー表示をテストする
- [ ] お気に入りの追加と削除をテストする
- [ ] 代表ユースケースをPlaywrightなどのE2Eテストで最低1本保護する

DOM構造や文言の完全一致ではなく、ユーザーが主要操作を完了できることをテストする。

## Phase 5: READMEとデモ導線を整える（必須）

### README冒頭

- [ ] 一文でサービスの目的を説明する
- [ ] 解決する課題と想定ユーザーを説明する
- [ ] 主要画面のスクリーンショットまたは短いGIFを掲載する
- [ ] デモURLと試用アカウントを掲載する
- [ ] Admin、Tenant、一般ユーザーで試せる操作を記載する

### 技術説明

- [ ] 使用技術と採用理由を記載する
- [ ] [インフラアーキテクチャ](../infra/architecture.md)へリンクする
- [ ] ER図へリンクする
- [ ] Tenant境界、認証、在庫・料金設計など、工夫した点を3件程度説明する
- [ ] テスト件数ではなく、何を保証しているか説明する
- [ ] CIのステータスバッジを掲載する
- [ ] デモ構成が高可用な本番構成ではないことを明記する

### セットアップ情報

- [ ] 初回起動手順をREADMEだけで再現できる
- [ ] `.env.example`に必要な変数と用途を記載する
- [ ] Docker Composeを使ったテスト手順へリンクする
- [ ] 現在のREADMEにある構築時のトラブルシューティングを適切な文書へ移す

## Phase 6: 運用と信頼性を示す（推奨）

- [ ] RailsとNginxのログをAWS側で確認できる
- [ ] Next.jsのbuild・runtimeログをVercelで確認できる
- [ ] `/up`などのhealth endpointを外形監視する
- [ ] EC2のCPU、メモリ、ディスク使用率を監視する
- [ ] 監視異常とAWS料金の通知先を設定する
- [ ] デプロイ、ロールバック、バックアップ、復元手順を文書化する
- [ ] 依存パッケージの更新方法を決める
- [ ] デモを停止・破棄した際に課金リソースが残らないことを確認する

## 公開後に追加してよい項目（任意）

- [ ] 宿泊予約、承認、取消、在庫割り当てを一貫して実装する
- [ ] Solid Queueを使う実用的な非同期処理を追加する
- [ ] Active Storageの画像をS3へ保存する
- [ ] OpenAPIなどでJSON APIの契約を公開する
- [ ] アクセシビリティとモバイル表示を点検する
- [ ] パフォーマンス計測を行い、N+1や遅いQueryを改善する

これらはPhase 1から5を完了するまで優先しない。未完成な機能を増やすより、既存の主導線を安全かつ説明可能な状態にする。

## 推奨実装順序

```text
代表ユースケースの確定
  → デモデータ
  → AWS BackendのProduction用Docker構成
  → Next.jsのVercelデプロイ
  → HTTPS・CORS・永続化・シークレット管理
  → 認証TokenとTenant境界の安全性確認
  → Backend／Frontend／E2Eテスト
  → GitHub Actions
  → README・スクリーンショット
  → 公開前の通し確認
```

## 公開判定チェック

次をすべて満たした時点を「ポートフォリオとして公開可能」とする。

- [ ] READMEを読んでサービスの目的、対象ユーザー、主要機能が分かる
- [ ] デモURLをHTTPSで開ける
- [ ] 記載された試用アカウントで代表ユースケースを完了できる
- [ ] 他Tenantのデータへアクセスできない
- [ ] 秘密値と個人情報がRepositoryや画面へ露出していない
- [ ] CIですべての必須チェックが成功する
- [ ] EC2再起動後もアプリとDBが復旧する
- [ ] DBバックアップから復元できる
- [ ] デモ環境の制約と未実装項目を説明できる
- [ ] 各主要な設計判断について「なぜそうしたか」を自分の言葉で説明できる
