# Listing 設計

## 目的

tenant が求人と宿泊情報を掲載し、user が検索・お気に入り・応募・予約できるための DB 設計を定義する。

求人と宿泊情報は公開状態、タイトル、本文、画像、作成者などの共通属性を持つため、共通テーブル `listings` を中心に置く。求人固有属性は `job_listings`、宿泊固有属性は `stay_listings` に分離する。

## 対象

- `backend/docs/DB/ER.md`
- 将来の migration
- 将来の model
- 将来の controller/API
- 将来の model/controller test

## データモデル方針

- `listings` は tenant 配下の掲載情報の共通ルートとする。
- `listings.listing_type` は `job` または `stay` とし、対応する詳細テーブルを 1 件だけ持つ。
- `listings.status` は `draft`, `published`, `closed`, `archived` とする。
- `created_by_tenant_member_id` と `updated_by_tenant_member_id` は操作した tenant member を保存する。
- `listing_images` は求人・宿泊の両方で共有し、`position` で表示順を管理する。
- `job_listings.work_area` は一覧や検索で使う勤務エリア、`work_address` は詳細画面で使う勤務先住所とする。
- `favorites` は user と listing の中間テーブルとし、同じ user が同じ listing を重複登録できないようにする。
- `job_applications` は求人への応募を管理する。求人 listing のみを対象にする。
- `stay_reservations` は宿泊予約を管理する。宿泊 listing のみを対象にする。

## 主な制約

- `listings.tenant_id` は必須。
- `listings.title`, `listing_type`, `status` は必須。
- `job_listings.listing_id` と `stay_listings.listing_id` は unique にし、1 listing に同種詳細を複数作らない。
- `favorites` は `user_id, listing_id` の unique index を持つ。
- `job_applications` は運用開始時点では `user_id, listing_id` を unique にし、同一求人への重複応募を防ぐ。
- `stay_reservations` は同一期間の二重予約防止が必要になるため、初期実装ではトランザクションとロックで検証し、PostgreSQL の exclusion constraint は予約要件が固まってから検討する。
- 詳細テーブルと listing_type の整合性は model validation で担保する。DB の check constraint は Rails 実装後に必要性を判断する。

## API/画面への影響

- tenant 側は listing の一覧、作成、編集、公開、終了、アーカイブを扱う。
- tenant 側の作成画面は `listing_type` に応じて求人フォームまたは宿泊フォームを表示する。
- user 側は公開済み listing の一覧、詳細、お気に入り、求人応募、宿泊予約を扱う。
- user 側の一覧検索では `listings.status = published` を基本条件にする。

## Tenant 掲載管理画面

- `/tenant/listings` に tenant 自身の掲載一覧を表示する。
- `/tenant/listings/new` で求人または宿泊の掲載を作成する。
- `/tenant/listings/:id` で掲載詳細を表示する。
- `/tenant/listings/:id/edit` で共通項目と種別別詳細を編集する。
- tenant は自 tenant の listing のみ参照・更新できる。
- `listing_type` は作成時に選択し、編集時は変更しない。
- `published` に更新されたとき `published_at` が未設定なら現在時刻を入れる。
- `closed` に更新されたとき `closed_at` が未設定なら現在時刻を入れる。

## User 掲載閲覧 API/Web

- user 側は frontend から API を呼び出して公開済み listing を表示する。
- API は `/api/v1/listings` と `/api/v1/listings/:id` を追加する。
- 一覧 API は `status = published` の listing だけを返す。
- 詳細 API も `status = published` の listing だけを返し、draft/closed/archived は返さない。
- API レスポンスには listing 共通項目、tenant の表示名、種別別詳細、画像一覧を含める。
- 初期実装では公開 listing 閲覧をログイン不要にする。お気に入り、応募、予約を追加する段階で JWT 認証 API を追加する。
- frontend 側は `/app/listings` で一覧、`/app/listings/$listingId` で詳細を表示する。
- 一覧ではタイトル、種別、tenant 名、勤務エリアまたは宿泊住所、価格/給与の概要を表示する。
- 詳細では listing 共通項目と求人/宿泊の詳細項目を表示する。
- API エラー時は画面上に取得失敗状態を表示する。

## 実装手順

1. `listings`, `job_listings`, `stay_listings`, `listing_images`, `favorites`, `job_applications`, `stay_reservations` の migration を追加する。
2. 各 model と association、enum 相当の validation を追加する。
3. tenant 向け CRUD と公開状態変更を実装する。
4. user 向け公開 listing 一覧・詳細 API を実装する。
5. frontend 側で公開 listing 一覧・詳細画面を実装する。
6. お気に入り、求人応募、宿泊予約を順に実装する。
7. 予約の同時作成と重複期間判定を追加する。

## テスト方針

- model test で必須項目、enum 値、association、unique 制約を確認する。
- tenant controller/API test で tenant が自 tenant の listing だけ作成・更新できることを確認する。
- user controller/API test で draft/closed/archived が公開一覧に出ないことを確認する。
- user controller/API test で公開 listing の一覧と詳細に種別別詳細が含まれることを確認する。
- frontend 側は一覧・詳細のローディング、成功、失敗表示をテストまたは手動確認する。
- favorites は重複登録できないことを確認する。
- job_applications は求人 listing のみ応募でき、同一 user が重複応募できないことを確認する。
- stay_reservations は宿泊 listing のみ予約でき、チェックアウト日がチェックイン日より後であることを確認する。
- 予約重複制御を実装する段階で、同一宿泊 listing の期間重複を拒否するテストを追加する。

## 検証コマンド

設計文書のみの変更では Rails test は不要。実装時は以下を使う。

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails db:prepare
```

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test test/models/listing_test.rb
```

```sh
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgres://app:app@db:5432/app_test backend bin/rails test
```

## 保留事項

- 報酬、宿泊料金、予約決済を将来扱う場合は金額カラムの通貨単位と税区分を別途定義する。
- 画像アップロード先は Active Storage、外部 URL、オブジェクトストレージ直指定のどれにするかを実装時に決める。
- 検索要件が固まったら `published_at`, `listing_type`, `tenant_id` 以外の検索用 index を追加する。
