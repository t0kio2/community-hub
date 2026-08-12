# tenant_locations 作成マイグレーション

## 目的と背景

`docs/er/01-listing.md` と `docs/architecture/03-location.md` に定義された、テナント所有の再利用可能な拠点を保存する `tenant_locations` テーブルを作成する。

## 変更範囲

- `backend/db/migrate/20260812011526_create_tenant_locations.rb`
- `Tenant`、`TenantLocation`、`Listing`の関連と同一テナント制約
- テナントowner向けの拠点一覧・登録・編集・削除画面
- Maps Embed APIで緯度・経度のプレビューを表示する。Google Places／Geocoding連携とListingフォームの拠点選択は扱わない。

## データモデル

- `tenant_id` は必須の外部キーとし、テナント削除時は拠点も削除する。
- 管理用名称、拠点種別、構造化住所、Google Place ID、緯度・経度を保持する。
- 拠点種別の初期値は `other`、緯度・経度は必須とする。
- テナント内で管理用名称が重複しないよう、`tenant_id, name` に一意インデックスを作成する。

## 実装・検証手順

1. ER定義どおりにテーブル、外部キー、インデックスをマイグレーションへ記述する。
2. `tenants.address`を参照するフォーム、表示、Strong Parameters、テストデータを削除済みカラムに合わせて修正する。
3. 求人・宿泊詳細が現在保持する住所カラムは、Listingの拠点選択を実装するまで維持する。
4. ownerだけが自テナントの拠点を管理できるCRUD画面を実装する。
5. 拠点登録・更新と代表拠点設定を同一トランザクションで処理する。
6. APIキーは`GOOGLE_MAPS_EMBED_API_KEY`環境変数で管理し、未設定時は設定案内を表示する。
7. 入力した緯度・経度からMaps Embed APIの地図プレビューを更新できるようにする。
8. DBから取得した`decimal`が指数表記にならないよう、Mapsへ渡す座標を固定小数表記へ正規化する。
9. 組織情報編集画面に登録済み拠点の一覧と編集導線を表示し、未登録時は登録導線を表示する。
10. モデルおよびコントローラーテストを追加し、Docker Composeのtest環境で全Backendテストを実行する。

## 後続対応

緯度・経度は利用者が別途調査して入力する。将来Google Places／Geocodingを導入する場合は直接入力の扱いを再検討する。Listingフォームの拠点選択は別途実装する。
