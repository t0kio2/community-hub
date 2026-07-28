# 宿泊予約関連 ER 図

一般ユーザーによる宿泊Listingの予約を `stay_reservations` で管理する。

Listing本体と宿泊詳細については [`01-listing.md`](./01-listing.md) を参照する。

## 全体関連図

```mermaid
erDiagram
    users ||--o{ stay_reservations : "宿泊を予約する"
    listings ||--o{ stay_reservations : "予約を受ける"
    listings ||--o| stay_listings : "宿泊詳細を持つ"
```

## 宿泊予約

```mermaid
erDiagram
    users {
        bigint id PK
    }

    listings {
        bigint id PK
        string listing_type
        string status
    }

    stay_reservations {
        bigint id PK
        bigint user_id FK
        bigint listing_id FK
        string status
        date check_in_date
        date check_out_date
        integer guest_count
        text message
        datetime created_at
        datetime updated_at
    }

    users ||--o{ stay_reservations : "宿泊を予約する"
    listings ||--o{ stay_reservations : "予約を受ける"
```

`user_id`、`listing_id`、`status`、`check_in_date`、`check_out_date` は必須とする。予約先は `listing_type = stay` のListingに限定する。

`check_out_date` は `check_in_date` より後の日付とする。同じ宿泊Listingに対する予約期間の重複を許可しない。

## 予約ステータス

| 値 | 状態 |
| --- | --- |
| `requested` | 予約リクエスト済み |
| `confirmed` | 予約確定 |
| `rejected` | 予約拒否 |
| `canceled` | キャンセル |
| `completed` | 宿泊完了 |

## 主な制約・インデックス

| カラム | 制約・インデックス |
| --- | --- |
| `user_id` | NOT NULL、usersへの外部キー |
| `listing_id` | NOT NULL、listingsへの外部キー |
| `status` | NOT NULL |
| `check_in_date` | NOT NULL |
| `check_out_date` | NOT NULL、`check_in_date`より後 |
| `listing_id, check_in_date, check_out_date` | composite index |
