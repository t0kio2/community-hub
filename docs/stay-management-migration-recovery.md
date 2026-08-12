# 宿泊管理マイグレーション復元

## 背景と目的

`backend/db/schema.rb`には宿泊管理用テーブルと`stay_listings`の管理用カラムが存在するが、対応するマイグレーションファイルがない。このままでは`db:migrate`による空DBの再構築結果が`db:schema:load`と一致しないため、現在のschemaを再現する新しいマイグレーションを追加する。

## 復元範囲

- `stay_listings`への予約受付・宿泊可能期間設定の追加
- Room Type、物理Room、Bed、停止期間、日別販売上限
- Rate Plan、Room Type別基本料金、日別料金
- 共通・テナント固有Amenitiesと施設・Room Typeの中間テーブル
- 外部キー、複合一意インデックス、部分一意インデックス

既存の`20260429043036_create_stay_listings.rb`は変更しない。すでに適用済みの環境にも変更履歴を伝えられるよう、すべて新しい日時のマイグレーションとして追加する。

## 実装順序

1. `stay_listings`へ管理設定カラムを追加する。
2. `stay_room_types`を起点に物理在庫と販売制御テーブルを作成する。
3. 料金プラン、Room Type別料金、日別料金テーブルを作成する。
4. Amenitiesマスターと関連テーブルを作成する。
5. 既存の`schema.rb`を削除してから空DBへ全マイグレーションを適用し、schemaを再生成する。

## 検証方針

- 各マイグレーションファイルをRuby構文検査する。
- データが不要であることを確認し、既存schemaを削除してから開発・テストDBを再作成して`db:migrate`する。
- `db:migrate`後の`schema.rb`と期待するテーブル、カラム、外部キー、インデックスを比較する。

## 留意事項

Railsは新規DBの準備時に現在のschemaを先にロードする場合がある。復元マイグレーションは通常の可逆な`change`として保ち、既存schemaを削除した状態で空DBから適用する。再生成されたschemaのカラム順はRailsのダンプ仕様に従うため、マイグレーション内の定義順とは一致しない場合がある。

全履歴の検証で、既存の`CreateTenantUsers`と`RenameTenantUsersToTenantMembers`がどちらも`tenant_members`を対象にしている不整合が判明した。履歴上の意図どおり、前者で`tenant_users`を作成し、後者で`tenant_members`へ変更する。

ERに記載されている`latest_check_in_time`、Room Type画像、施設直下の未分類Roomなど、現行schemaに存在しない構造は今回の復元対象外とし、設計確定後に別マイグレーションで対応する。
