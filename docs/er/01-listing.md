# Listing共通 ER 図

求人と宿泊情報の共通ルートである `listings` と、位置情報、画像、お気に入りのテーブル構造を定義する。

- 求人固有ER: [`01-listing-job.md`](./01-listing-job.md)
- 滞在固有ER: [`01-listing-stay.md`](./01-listing-stay.md)
- Listing共通仕様: [`../architecture/02-listing.md`](../architecture/02-listing.md)

## 全体関連図

種別固有テーブルは関連だけを示し、カラムと制約は領域別ERに記載する。

```mermaid
erDiagram
    tenants ||--o{ listings : "掲載を持つ"
    tenant_members o|--o{ listings : "作成する"
    tenant_members o|--o{ listings : "更新する"
    listings ||--o| job_listings : "求人詳細を持つ"
    job_categories o|--o{ job_listings : "職種を分類する"
    listings ||--o| stay_listings : "宿泊詳細を持つ"
    stay_listings ||--o{ stay_room_types : "部屋タイプを持つ"
    tenants o|--o{ stay_amenities : "固有設備を持つ"
    stay_listings ||--o{ stay_listing_amenities : "施設設備を設定する"
    stay_amenities ||--o{ stay_listing_amenities : "施設へ設定される"
    stay_room_types ||--o{ stay_room_type_amenities : "部屋設備を設定する"
    stay_amenities ||--o{ stay_room_type_amenities : "部屋タイプへ設定される"
    stay_room_types ||--o{ stay_rooms : "物理客室を持つ"
    stay_rooms ||--o{ stay_beds : "相部屋のベッドを持つ"
    stay_room_types ||--o{ stay_room_type_daily_sales_controls : "日別販売上限を持つ"
    stay_listings ||--o{ stay_rate_plans : "料金プランを持つ"
    stay_room_types ||--o{ stay_room_type_rates : "プラン別料金を持つ"
    stay_rate_plans ||--o{ stay_room_type_rates : "部屋タイプへ適用する"
    stay_room_type_rates ||--o{ stay_room_type_rate_daily_prices : "日別料金を持つ"
    listings ||--o| listing_locations : "位置情報を持つ"
    listings ||--o{ listing_images : "画像を持つ"
    users ||--o{ favorites : "お気に入り登録する"
    listings ||--o{ favorites : "お気に入り登録される"
```

## listings

```mermaid
erDiagram
    tenants {
        bigint id PK
    }

    tenant_members {
        bigint id PK
    }

    listings {
        bigint id PK
        bigint tenant_id FK
        bigint created_by_tenant_member_id FK
        bigint updated_by_tenant_member_id FK
        string listing_type
        string title
        text description
        string status
        datetime published_at
        datetime last_published_at
        datetime closed_at
        string closed_reason
        datetime archived_at
        datetime created_at
        datetime updated_at
    }

    tenants ||--o{ listings : "掲載を持つ"
    tenant_members o|--o{ listings : "作成する"
    tenant_members o|--o{ listings : "更新する"
```

| カラム | 型 | NULL | 初期値 | 制約・定義 |
| --- | --- | :---: | --- | --- |
| `id` | bigint | × | 自動採番 | 主キー |
| `tenant_id` | bigint | × | なし | `tenants.id`への外部キー、作成後変更不可 |
| `created_by_tenant_member_id` | bigint | ○ | 操作中のメンバー | `tenant_members.id`への外部キー、メンバー削除時はNULL |
| `updated_by_tenant_member_id` | bigint | ○ | 操作中のメンバー | `tenant_members.id`への外部キー、メンバー削除時はNULL |
| `listing_type` | string | × | なし | `job / stay`、作成後変更不可 |
| `title` | string | × | なし | 最大120文字 |
| `description` | text | ○ | NULL | プレーンテキスト、最大10,000文字、公開時必須 |
| `status` | string | × | `draft` | `draft / published / closed / archived` |
| `published_at` | datetime | ○ | NULL | 初回公開日時 |
| `last_published_at` | datetime | ○ | NULL | 最新公開日時 |
| `closed_at` | datetime | ○ | NULL | 現在の受付終了日時 |
| `closed_reason` | string | ○ | NULL | 受付終了理由 |
| `archived_at` | datetime | ○ | NULL | 現在のアーカイブ日時 |
| `created_at` | datetime | × | 自動設定 | 作成日時 |
| `updated_at` | datetime | × | 自動設定 | 更新日時 |

`listing_type` に対応する種別固有詳細を1件だけ持つ。`job` は `job_listings`、`stay` は `stay_listings` を参照する。

状態遷移と日時カラムの更新条件は [`../architecture/02-listing.md`](../architecture/02-listing.md) を参照する。

## listing_locations

```mermaid
erDiagram
    listings {
        bigint id PK
    }

    listing_locations {
        bigint id PK
        bigint listing_id FK, UK
        string postal_code
        string prefecture
        string city
        string address_line1
        string address_line2
        string google_place_id
        decimal latitude
        decimal longitude
        datetime created_at
        datetime updated_at
    }

    listings ||--o| listing_locations : "位置情報を持つ"
```

| カラム | 型 | NULL | 初期値 | 制約・定義 |
| --- | --- | :---: | --- | --- |
| `id` | bigint | × | 自動採番 | 主キー |
| `listing_id` | bigint | × | なし | `listings.id`への外部キー、一意 |
| `postal_code` | string | ○ | NULL | 郵便番号 |
| `prefecture` | string | ○ | NULL | 都道府県 |
| `city` | string | ○ | NULL | 市区町村 |
| `address_line1` | string | ○ | NULL | 町名・番地 |
| `address_line2` | string | ○ | NULL | 建物名・部屋番号 |
| `google_place_id` | string | ○ | NULL | Google Place ID |
| `latitude` | decimal | × | なし | 緯度 |
| `longitude` | decimal | × | なし | 経度 |
| `created_at` | datetime | × | 自動設定 | 作成日時 |
| `updated_at` | datetime | × | 自動設定 | 更新日時 |

Listing削除時は対応する位置情報を連動削除する。住所・位置情報の業務仕様は [`../architecture/03-location.md`](../architecture/03-location.md) を参照する。

## listing_images

```mermaid
erDiagram
    listings {
        bigint id PK
    }

    listing_images {
        bigint id PK
        bigint listing_id FK
        integer position
        string alt_text
        datetime created_at
        datetime updated_at
    }

    listings ||--o{ listing_images : "画像を持つ"
```

| カラム | 型 | NULL | 初期値 | 制約・定義 |
| --- | --- | :---: | --- | --- |
| `id` | bigint | × | 自動採番 | 主キー |
| `listing_id` | bigint | × | なし | `listings.id`への外部キー |
| `position` | integer | × | なし | 1以上、Listing内で一意 |
| `alt_text` | string | ○ | NULL | 最大200文字 |
| `created_at` | datetime | × | 自動設定 | 作成日時 |
| `updated_at` | datetime | × | 自動設定 | 更新日時 |

画像本体はActive Storageの`has_one_attached :image`で保持する。Active Storage標準テーブルはフレームワーク管理のため、この業務ER図には展開しない。

## favorites

```mermaid
erDiagram
    users {
        bigint id PK
    }

    listings {
        bigint id PK
    }

    favorites {
        bigint id PK
        bigint user_id FK
        bigint listing_id FK
        datetime created_at
        datetime updated_at
    }

    users ||--o{ favorites : "お気に入り登録する"
    listings ||--o{ favorites : "お気に入り登録される"
```

| カラム | 型 | NULL | 初期値 | 制約・定義 |
| --- | --- | :---: | --- | --- |
| `id` | bigint | × | 自動採番 | 主キー |
| `user_id` | bigint | × | なし | `users.id`への外部キー、`listing_id`との組み合わせで一意 |
| `listing_id` | bigint | × | なし | `listings.id`への外部キー、`user_id`との組み合わせで一意 |
| `created_at` | datetime | × | 自動設定 | 作成日時 |
| `updated_at` | datetime | × | 自動設定 | 更新日時 |

## インデックス

| テーブル | カラム | 種別 |
| --- | --- | --- |
| `listings` | `tenant_id` | index |
| `listings` | `listing_type, status` | composite index |
| `listings` | `status, published_at` | composite index |
| `listings` | `created_by_tenant_member_id` | index |
| `listings` | `updated_by_tenant_member_id` | index |
| `listing_locations` | `listing_id` | unique index |
| `listing_images` | `listing_id, position` | unique index |
| `favorites` | `user_id, listing_id` | unique index |
