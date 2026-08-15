# stay_listingsのER整合化計画

## 目的と背景

`stay_listings`には旧仕様の施設住所・定員・料金・設備カラムが残り、ERで定義した`latest_check_in_time`が存在しない。ERを正本としてスキーマとモデルを揃え、宿泊・予約設定画面を追加できる状態にする。

## 対象

- `backend/db/migrate`: ERとの差分を解消するマイグレーション
- `backend/app/models/stay_listing.rb`: 新しい宿泊・予約設定の整合性検証
- `backend/app/controllers/api/v1/public/listings_controller.rb`: 削除カラムへの参照解消
- `backend/test/fixtures/stay_listings.yml`
- `backend/test/models/stay_listing_test.rb`
- 関連する公開Listing APIテスト

## データモデル変更

- `latest_check_in_time`をnullableな`time`として追加する。
- `available_from / available_until`の既存値は、対応する`stay_available_starts_on / stay_available_ends_on`が未設定の場合に移行する。
- Room Type、所在地、Amenities、料金へ責務が移った旧カラム`stay_type / address / capacity / price_per_night / available_from / available_until / amenities`を削除する。
- rollback時は旧カラムを復元し、新しい宿泊可能期間から旧期間へ値を戻す。

## 実装手順

1. `up / down`形式のマイグレーションを追加し、期間データを保全してスキーマを変更する。
2. `StayListing`の旧カラム用検証を削除し、予約確定方式、期限、時刻、宿泊可能期間、タイムゾーンをERの制約に合わせて検証する。
3. fixtureと公開APIの出力を新スキーマへ合わせる。
4. モデルテストと公開APIテストを更新する。

## 検証・テスト計画

- マイグレーション後に`latest_check_in_time`が存在し、旧カラムが存在しないことを確認する。
- 宿泊可能期間、予約受付期間、チェックイン時刻、許可値・境界値をモデルテストで確認する。
- 公開Listing APIが削除カラムを参照せず、新しい宿泊設定を返せることを確認する。
- Docker Composeのtest環境でDBを準備し、対象テストを実行する。

## トレードオフと後続作業

- `address / capacity / price_per_night / amenities`は新しい関連モデルへ一意に変換できないため自動移行しない。これらは旧プロトタイプ項目であり、現在のERに従って削除する。
- 入力フォームと管理画面への宿泊・予約設定追加は別作業とする。
