# Admin Tenant Account 管理設計

## 背景

admin の tenant account 一覧では、各 tenant account に対して編集と削除を行う。

Rails の RESTful route では削除は `DELETE /admin/tenant_accounts/:id` で受ける。一方、HTML form は `GET` と `POST` しか直接送信できないため、Rails では `POST` に hidden field `_method=delete` を含め、`Rack::MethodOverride` で `DELETE` として扱う。

このプロジェクトは `config.api_only = true` のため、通常の Rails full-stack app と違い `Rack::MethodOverride` が middleware stack に入っていない。そのため、削除フォーム送信時に `_method=delete` が解釈されず、`POST /admin/tenant_accounts/:id` として route 解決されて `No route matches [POST]` になる。

## 対応方針

1. `api/config/application.rb` に `Rack::MethodOverride` を追加する
2. tenant account 一覧の削除フォームを Rails helper の `form_with method: :delete` に寄せる
3. integration test で `_method=delete` 付き POST が destroy route として処理されることを確認する

## テスト方針

`Admin::TenantAccountsControllerTest` に以下を追加する。

- admin としてログインする
- tenant account を作成する
- `post admin_tenant_account_path(account), params: { _method: "delete" }` を送る
- `TenantAccount.count` が減る
- `admin_tenant_accounts_path` に redirect する

これにより、HTML フォームからの method override が壊れていないことを確認する。
