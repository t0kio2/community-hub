# アカウント関連 ER 図

アカウント、プロフィール、テナントメンバー、管理者、認証トークン、セッションのテーブル構造と関連を図示する。

## 全体関連図

テーブル間の関連だけを俯瞰する。詳細なカラムは後続の領域別 ER 図に記載する。

```mermaid
erDiagram
    accounts ||--o| users : "ユーザーとして利用"
    users ||--|| user_profiles : "プロフィールを持つ"
    accounts ||--o{ tenant_members : "テナントに所属"
    tenants ||--o{ tenant_members : "メンバーを持つ"
    accounts ||--o| admins : "運営者として利用"
    accounts ||--o{ user_refresh_tokens : "トークンを持つ"
```

## 認証基盤

`accounts` は一般ユーザー、テナントメンバー、運営管理者で共通利用する認証情報を管理する。

```mermaid
erDiagram
    accounts {
        bigint id PK
        string email
        string encrypted_password
        string account_type
        string status
        datetime last_login_at
        datetime email_verified_at
        datetime created_at
        datetime updated_at
    }
```

`account_type` は `user`、`tenant`、`admin` のいずれかを取る。

## 一般ユーザー

一般ユーザーとしての状態は `users`、個人プロフィールは `user_profiles` で管理する。

```mermaid
erDiagram
    accounts {
        bigint id PK
    }

    users {
        bigint account_id FK
        string status
        datetime created_at
        datetime updated_at
    }

    user_profiles {
        bigint id PK
        bigint user_id FK, UK
        string name
        string kana
        date birth_date
        string phone
        string avatar_url
        datetime created_at
        datetime updated_at
    }

    accounts ||--o| users : "ユーザーとして利用"
    users ||--|| user_profiles : "プロフィールを持つ"
```

`user_profiles.user_id` は一意であり、ユーザーとプロフィールは 1 対 1 で紐づく。

## テナント

テナントの組織情報は `tenants`、アカウントの所属・権限・在籍状態は `tenant_members` で管理する。

```mermaid
erDiagram
    accounts {
        bigint id PK
    }

    tenants {
        bigint id PK
        bigint primary_tenant_location_id FK
        string name
        string kana
        string status
        datetime created_at
        datetime updated_at
    }

    tenant_locations {
        bigint id PK
        bigint tenant_id FK
    }

    tenant_members {
        bigint id PK
        bigint tenant_id FK
        bigint account_id FK
        string role
        string status
        datetime created_at
        datetime updated_at
    }

    accounts ||--o{ tenant_members : "テナントに所属"
    tenants ||--o{ tenant_members : "メンバーを持つ"
    tenants o|--o| tenant_locations : "代表拠点を指定する"
```

`tenants`は住所文字列を直接保持しない。住所・位置情報は`tenant_locations`で管理し、`primary_tenant_location_id`には同じテナントが所有する代表拠点を任意に設定する。拠点の詳細は[`01-listing.md`](./01-listing.md)を参照する。

## 運営管理者

運営管理者としての権限と状態は `admins` で管理する。

```mermaid
erDiagram
    accounts {
        bigint id PK
    }

    admins {
        bigint id PK
        bigint account_id FK
        string role
        string status
        datetime created_at
        datetime updated_at
    }

    accounts ||--o| admins : "運営者として利用"
```

## ユーザー認証トークン

一般ユーザーの JWT リフレッシュトークンを、アカウントおよび端末単位で管理する。

```mermaid
erDiagram
    accounts {
        bigint id PK
    }

    user_refresh_tokens {
        bigint id PK
        bigint account_id FK
        string token_digest UK
        string device_id
        string device_name
        string user_agent
        string last_used_ip
        datetime expired_at
        datetime revoked_at
        datetime last_used_at
        datetime created_at
        datetime updated_at
    }

    accounts ||--o{ user_refresh_tokens : "トークンを持つ"
```

`token_digest` は SHA-256 でハッシュ化し、一意制約を設ける。

## JWT 拒否リスト

ログアウト済みアクセストークンの JTI を管理する。ほかのテーブルへの外部キーを持たない。

```mermaid
erDiagram
    jwt_denylists {
        bigint id PK
        string jti
        datetime exp
        datetime created_at
        datetime updated_at
    }
```

## テナント・管理者セッション

テナントおよび運営管理者のサーバーセッションを管理する。ほかのテーブルへの外部キーを持たない。

```mermaid
erDiagram
    sessions {
        bigint id PK
        string session_id
        text data
        datetime created_at
        datetime updated_at
    }
```
