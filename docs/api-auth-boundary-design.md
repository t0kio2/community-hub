# API 認証境界設計

## 目的

API を公開用とユーザー用に分け、認証要否とアクセス制御の責務を明確にする。

## 方針

- 公開用 API は `/api/v1/public/*` に配置する。
- ユーザー用 API は `/api/v1/user/*` に配置する。
- 認証操作は既存どおり `/api/v1/auth/*` に配置する。
- 公開用 API は認証不要とし、第三者から直接リクエストされても問題ない情報だけ返す。
- ユーザー用 API は JWT 認証を必須にする。
- ユーザー所有リソースは必ず `current_user` 起点で取得・作成・削除する。

## Controller 階層

```text
Api::V1::Public::BaseController
Api::V1::User::BaseController
```

### Api::V1::Public::BaseController

- `ActionController::API` を継承する。
- 認証は行わない。
- 公開してよいレスポンスだけを返す controller の基底にする。

対象例:

- 公開 listing 一覧
- 公開 listing 詳細
- 公開マスターデータ

### Api::V1::User::BaseController

- `ActionController::API` を継承する。
- `authenticate_user_account!` を必須にする。
- `current_user` を提供する。

対象例:

- 自分の profile
- 自分の favorites
- 自分の応募
- 自分の通知

## URL 設計

```text
GET    /api/v1/public/listings
GET    /api/v1/public/listings/:id

GET    /api/v1/user/favorites
POST   /api/v1/user/favorites
DELETE /api/v1/user/favorites/:id
```

## 公開用 API の注意点

公開用 API では以下を返さない。

- 下書き、停止、アーカイブ済みの listing
- tenant の内部管理情報
- tenant_member 情報
- favorite 済みかどうかなどユーザー依存情報
- 管理用の更新者、作成者情報

## 検証方針

- 公開 listing API は未ログインでもアクセスできること。
- 公開 listing API は published のみ返すこと。
- ユーザー用 API は未ログインで 401 になること。
- favorite は `current_user` に紐づくものだけ取得・削除できること。

