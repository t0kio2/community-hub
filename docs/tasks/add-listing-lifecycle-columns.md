# Listingライフサイクルカラム追加計画

## 目的と背景

`docs/er/01-listing.md`で定義済みの`last_published_at / closed_reason / archived_at`が`listings`テーブルに存在しない。後続の状態遷移実装に先立ち、nullableなカラムを追加してERとスキーマを揃える。

## 対象

- `backend/db/migrate`: 3カラムを追加するマイグレーション
- `backend/db/schema.rb`: マイグレーション適用結果
- `backend/test/models/listing_test.rb`: カラム構成の確認

## データモデル変更

- `last_published_at`: datetime、NULL可
- `closed_reason`: string、NULL可
- `archived_at`: datetime、NULL可

既存レコードはすべてNULLとし、既存の`published_at / closed_at`からの推測による補完は行わない。

## 実装・検証手順

1. `change`形式のマイグレーションで3カラムを追加する。
2. Listingモデルテストにカラムの存在と型、NULL許可を確認するテストを追加する。
3. Docker Composeのtest環境でマイグレーション、rollback、再適用を確認する。
4. Listingモデルテストと全テストを実行する。

## 後続作業

状態遷移、日時・理由の自動設定、理由の許可値検証、Controllerからの直接更新廃止は本変更に含めず、後続実装とする。
