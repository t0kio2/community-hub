# テーブル設計

# 認証/アカウント関連

#### accounts テーブル

```
id
email
encrypted_password
account_type ['user' | 'tenant_user' | 'admin']
status
last_login_at
email_verified_at
created_at
updated_at
```

## 共通

#### profiles テーブル

```
id
account_id [FK]
name
kana
birth_date
phone
avatar_url
created_at
updated_at
```

## ユーザ

### users テーブル

```
account_id [FK]
status
created_at
updated_at
```

## テナント

#### tenants テーブル

```
id
name
kana
address
status
created_at
updated_at
```

#### tenant_users テーブル

```
id
tenant_id [FK]
account_id [FK]
role
status
created_at
updated_at
```

## 運営

#### admins テーブル

```
id
account_id [FK]
role
status
created_at
updated_at
```

## 認可テーブル

ユーザは JWT によるトークン認証です。

#### user_refresh_tokens テーブル

```
id
account_id [FK]
token_digest [NOT NULL, UNIQUE]
device_id
device_name
user_agent
last_used_ip
expired_at
revoked_at
last_used_at
created_at
updated_at
```

- token_digest は SHA-256 でハッシュ化する。bcrypt はインデックス不可で遅いので使わない。
- リフレッシュトークンは HttpOnly/Secure/SameSite=strict クッキーに保存
- アクセストークン: 5-15 分, リフレッシュは 30-90 日
- ログアウト時、現在のアクセストークンの JTI を jwt_denlylists に登録し、該当レコードの revoked_at で無効化
- device_id/name:
  - ログイン時: X-Device-Id/X-Device-Name があれば保存（同一端末=常に 1 件に維持）。
  - リフレッシュ時: 必須ではなく未使用（保存済みのトークン検証とローテーションのみ）。
  - ログアウト時: X-Device-Id があれば、その端末のリフレッシュを失効。
  - 監査/管理: セッション一覧、端末表示、異常検知（例: 同アカウントの多数端末）に利用。

#### jwt_denylists テーブル(devise-jwt により作成される)

```
id
jti (JWTを一意に識別するID)
exp
created_at
updated_at
```

## セッション管理テーブル

テナント・管理者ユーザのセッションを DB で管理する。

#### sessions テーブル

```
id
session_id
data
created_at
updated_at
```

# Tenant - 求人/宿泊情報

TODO

#### job_listings テーブル

```
id
tenant_id [FK]

```

#### stay_listings テーブル

```
id
tenant_id [FK]

```
