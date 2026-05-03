# Admin テナント別掲載閲覧設計

## 目的

admin 画面で、テナントごとに作成された掲載を確認できるようにする。

## 方針

- admin のテナントアカウント一覧から、各テナントの掲載一覧へ遷移できるようにする。
- URL は既存の `admin/tenant_accounts` に合わせ、`GET /admin/tenant_accounts/:id` を使う。
- 対象テナントは `TenantAccount -> tenant_member -> tenant` で取得する。
- 掲載は `tenant.listings` を `updated_at DESC, id DESC` で表示する。
- 初期実装は閲覧のみとし、admin から掲載編集・削除は行わない。

## 影響範囲

- `backend/config/routes.rb`
- `backend/app/controllers/admin/tenant_accounts_controller.rb`
- `backend/app/views/admin/tenant_accounts/index.html.erb`
- `backend/app/views/admin/tenant_accounts/show.html.erb`
- `backend/test/controllers/admin/tenant_accounts_controller_test.rb`

## 表示項目

- 掲載 ID
- タイトル
- 種別
- ステータス
- 公開日時
- 更新日時

テナント組織が未作成のアカウントでは、掲載一覧の代わりに組織情報がない旨を表示する。

## 検証方針

- admin ログイン済みでテナント別掲載画面を開けること。
- 対象テナントの掲載が表示され、別テナントの掲載が表示されないこと。
- テナント一覧に掲載一覧へのリンクが表示されること。
- 組織未作成のテナントアカウントでも画面が 500 にならないこと。
