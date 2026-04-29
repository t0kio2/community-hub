# API

#### 詳細

手順（API モード＋ devise-jwt）

- 前提（済でなければ追加）

  - Gemfile: devise, devise-jwt,（必要なら）rack-cors
  - bundle install と rails g devise:install
  - config/initializers/devise.rb
  - `config.navigational_formats = []`
  - JWT 設定:
    - `config.jwt do |jwt|`
    - `jwt.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY')`
    - `jwt.dispatch_requests = [['POST','/accounts/sign_in']]`
    - `jwt.revocation_requests = [['DELETE','/accounts/sign_out']]`
    - `jwt.expiration_time = 15.minutes.to_i`（例）
    - `end`

- Account モデル作成
  - rails g devise Account
  - 生成されたマイグレーションに下記を追加
  - `account_type:string`
  - `status:string`（または `integer` で enum 運用）
  - `last_login_at:datetime`
  - `email_verified_at:datetime`（Devise の confirmable を使うなら代わりに`confirmed_at`等を採用）
- rails db:migrate
- app/models/account.rb 修正

  - `devise :database_authenticatable, :registerable, :recoverable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist`
  - 必要に応じて `enum :account_type, ...` / `enum :status, ...`
  - `has_one :profile, dependent: :destroy`

- JWT デナイリスト（devise-jwt）
  - rails g model JwtDenylist jti:string:uniq exp:datetime
  - app/models/jwt_denylist.rb
  - `include Devise::JWT::RevocationStrategies::Denylist`
  - `self.table_name = 'jwt_denylists'`
- rails db:migrate
- ルーティング - config/routes.rb - `devise_for :accounts, defaults: { format: :json }` - コントローラをカスタムする場合は `controllers: { sessions: 'accounts/sessions', registrations: 'accounts/registrations' }`

- CORS（フロントと別オリジンの場合）

  - config/initializers/cors.rb を作成
  - 例）`origins 'http://localhost:3000'`
  - `resource '*', headers: :any, expose: ['Authorization'], methods: [:get, :post, :delete, :put, :patch, :options], credentials: true`

- リフレッシュトークン（ER 準拠） - rails g model UserRefreshToken account:references token_digest:string:uniq device_id:string device_name:string user_agent:text last_used_ip:string expired_at:datetime revoked_at:datetime
  last_used_at:datetime - rails db:migrate - 運用指針 - サインイン時: アクセストークン（JWT）を `Authorization` で返し、同時に `user_refresh_tokens` にレコードを作成して、ハッシュ化したリフレッシュトークンを HttpOnly/Secure/SameSite=strict クッキーに保存 - リフレッシュ時: クッキーのトークンを検証 → ローテーション（古いレコードを失効、再発行） - サインアウト時: 現在の JWT の JTI を `jwt_denylists` に登録、該当デバイスの `user_refresh_tokens.revoked_at` を更新
- 実装ポイント

  - `UserRefreshToken` に検証・ローテーション用のサービス/クラスを作成
  - `Accounts::SessionsController` を継承して、ログイン/ログアウト時に上記処理をフック
  - クッキー属性: `httponly: true, secure: true(本番), same_site: 'Strict', path: '/api' など`

- 関連テーブル
  - profiles: rails g model Profile account:references name:string kana:string birth_date:date phone:string avatar_url:string
  - tenants, tenant_members, admins: ER 通りに生成し、関連付けをモデルへ追加
  - `Account has_one :profile`
  - `Profile belongs_to :account`
  - `Tenant has_many :tenant_members`, `has_many :profiles, through: :tenant_members` など

動作確認フロー

- サインアップ（必要に応じて）: POST /accounts（カスタム実装 or Devise Registrations）
- サインイン: POST /accounts/sign_in に { email, password } → レスポンスヘッダ Authorization: Bearer <JWT> を取得
- 認証付き API: Authorization ヘッダに付与してアクセス
- サインアウト: DELETE /accounts/sign_out
- リフレッシュ: 用意した POST /auth/refresh 等でクッキーから更新

# Web

```

```
