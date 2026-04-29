#設計

# 認証/アカウント関連

#### accounts

```
id
email
encrypted_password
account_type ['user' | 'tenant' | 'admin']
status
last_login_at
email_verified_at
created_at
updated_at
```

## 共通

#### profiles

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

### users

```
account_id [FK]
status
created_at
updated_at
```

## テナント

#### tenants

```
id
name
kana
address
status
created_at
updated_at
```

#### tenant_members

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

#### admins

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

#### user_refresh_tokens

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

#### jwt_denylists(devise-jwt により作成される)

```
id
jti (JWTを一意に識別するID)
exp
created_at
updated_at
```

## セッション管理テーブル

テナント・管理者ユーザのセッションを DB で管理する。

#### sessions

```
id
session_id
data
created_at
updated_at
```

# Tenant - 求人/宿泊情報

求人と宿泊情報は `listings` を共通ルートにする。
求人固有項目は `job_listings`、宿泊固有項目は `stay_listings` に分離する。
詳細方針は `docs/listing-design.md` を参照する。

#### listings

```
id
tenant_id [FK, NOT NULL]
created_by_tenant_member_id [FK]
updated_by_tenant_member_id [FK]
listing_type [NOT NULL] # job / stay
title [NOT NULL]
description
status [NOT NULL] # draft / published / closed / archived
published_at
closed_at
created_at
updated_at
```

- tenant_id に index
- listing_type, status に index
- status, published_at に index
- created_by_tenant_member_id は tenant_members.id を参照
- updated_by_tenant_member_id は tenant_members.id を参照
- status:
  - draft: 下書き
  - published: 公開中
  - closed: 募集/予約受付終了
  - archived: 非表示アーカイブ

#### job_listings

```
id
listing_id [FK, NOT NULL, UNIQUE]
employment_type # full_time / part_time / contract / temporary / other
job_category
work_location # onsite / remote / hybrid / other
address
salary_type # hourly / daily / monthly / yearly / other
salary_min
salary_max
working_hours
work_days
required_skills
welcome_skills
benefits
application_limit
created_at
updated_at
```

- listing_id は listings.id を参照
- 対象 listing の listing_type は job
- application_limit は応募上限数

#### stay_listings

```
id
listing_id [FK, NOT NULL, UNIQUE]
stay_type # private_room / shared_room / entire_place / other
address
capacity
price_per_night
check_in_time
check_out_time
available_from
available_until
amenities
house_rules
created_at
updated_at
```

- listing_id は listings.id を参照
- 対象 listing の listing_type は stay
- capacity は宿泊可能人数
- available_from, available_until は予約可能期間

#### listing_images

```
id
listing_id [FK, NOT NULL]
image_url [NOT NULL]
position [NOT NULL]
alt_text
created_at
updated_at
```

- listing_id, position に unique index
- position は 1 から始まる表示順

#### favorites

```
id
user_id [FK, NOT NULL]
listing_id [FK, NOT NULL]
created_at
updated_at
```

- user_id, listing_id に unique index

#### job_applications

```
id
user_id [FK, NOT NULL]
listing_id [FK, NOT NULL]
status [NOT NULL] # submitted / reviewing / accepted / rejected / withdrawn
message
applied_at
created_at
updated_at
```

- listing_id は job の listings.id を参照
- user_id, listing_id に unique index

#### stay_reservations

```
id
user_id [FK, NOT NULL]
listing_id [FK, NOT NULL]
status [NOT NULL] # requested / confirmed / rejected / canceled / completed
check_in_date [NOT NULL]
check_out_date [NOT NULL]
guest_count
message
created_at
updated_at
```

- listing_id は stay の listings.id を参照
- listing_id, check_in_date, check_out_date に index
- check_out_date は check_in_date より後の日付
