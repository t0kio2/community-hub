# tenant_locations 作成マイグレーション

## 目的と背景

`docs/er/01-listing.md` と `docs/architecture/03-location.md` に定義された、テナント所有の再利用可能な拠点を保存する `tenant_locations` テーブルを作成する。

## 変更範囲

- `backend/db/migrate/20260812011526_create_tenant_locations.rb`
- この変更では `tenants` と `listings` の参照カラム追加、モデル、画面、住所データ移行は扱わない。

## データモデル

- `tenant_id` は必須の外部キーとし、テナント削除時は拠点も削除する。
- 管理用名称、拠点種別、構造化住所、Google Place ID、緯度・経度を保持する。
- 拠点種別の初期値は `other`、緯度・経度は必須とする。
- テナント内で管理用名称が重複しないよう、`tenant_id, name` に一意インデックスを作成する。

## 実装・検証手順

1. ER定義どおりにテーブル、外部キー、インデックスをマイグレーションへ記述する。
2. `tenants.address`を参照するフォーム、表示、Strong Parameters、テストデータを削除済みカラムに合わせて修正する。
3. 求人・宿泊詳細が現在保持する住所カラムは、Listingの拠点選択を実装するまで維持する。
4. Docker Composeのtest環境でテストデータベースを準備し、全Backendテストを実行する。

## 後続対応

`TenantLocation`モデルの関連・同一テナント制約と、代表拠点およびListingの拠点選択画面を実装する。
