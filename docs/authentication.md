ユーザ、テナント、アドミンの 3 者が存在する。

- ユーザ: トークン認証 (JWT)
- テナント、アドミン: セッション認証(DB にセッションを保存)

# 方針

- 各主体は accounts テーブルで認証する。
- 各主体を別 Devise スコープにする
  - UserAccount
  - TenantAccount
  - AdminAccount
- ユーザー向け frontend は token を localStorage に保存しない。
- ブラウザには HttpOnly Cookie を持たせ、JavaScript から認証 token を読めない状態にする。
- 認証が必要な Rails API 呼び出しは Next.js の BFF を経由する。
- Next.js BFF は Cookie から認証情報を取り出し、Rails API へ `Authorization: Bearer <token>` を付けて送信する。
- Rails API は引き続き Bearer token 認証を受け付ける。

# Frontend / BFF 認証方針

ユーザー画面は以下の構成にする。

```text
Browser
  HttpOnly Cookie
  ↓ same-origin request
Next.js BFF
  Authorization: Bearer <access_token>
  ↓
Rails API
```

## Cookie

- Cookie は Next.js 側で発行・削除する。
- Cookie には `HttpOnly` を付け、ブラウザ JavaScript から読めないようにする。
- 本番環境では `Secure` を付け、HTTPS のみで送信する。
- `SameSite` は原則 `Lax` または `Strict` とし、CSRF リスクを下げる。
- access token は短命にする。
- refresh token を Cookie に持たせる場合は rotation と revoke を前提にする。

初期実装では以下の Cookie を使う。

- `communityHubAccessToken`: Rails API へ Bearer token として送る短命 token。
- `communityHubRefreshToken`: access token 更新とログアウト時の revoke に使う token。
- `communityHubAccount`: 画面表示用の最小 account 情報。認可判断には使わない。
- `communityHubDeviceId`: refresh token を端末単位で管理するための ID。

## ログイン

ログイン処理は Next.js の Server Action または Route Handler で受ける。

```text
Login form
  ↓
Next.js BFF
  ↓ POST /api/v1/auth/sign_in
Rails API
  ↓ access token / refresh token
Next.js BFF
  Set-Cookie
  redirect /dashboard
```

ブラウザには token を JSON レスポンスとして返さない。

## 認証が必要な API 通信

Client Component から認証が必要なデータを取得する場合は、Rails API を直接叩かず Next.js の Route Handler を叩く。

```text
Client Component
  ↓ fetch("/api/user/favorites")
Next.js Route Handler
  Cookie から token を取得
  ↓ GET /api/v1/user/favorites
Rails API
```

Next.js Route Handler は Rails API のレスポンスを必要な形で browser に返す。

Next.js 側の初期 BFF endpoint は以下とする。

- `POST /api/v1/auth/sign_in`: Rails のログイン API に転送し、token を Cookie に保存する。
- `POST /api/v1/auth`: Rails の登録 API に転送し、token を Cookie に保存する。
- `GET /api/v1/auth/session`: Cookie の有無から frontend のログイン状態を返す。
- `DELETE /api/v1/auth/session`: refresh token を Rails に revoke させ、Cookie を削除する。

## ページ表示時の認証確認

認証が必要な page は、可能な限り Server Component 側で Cookie を確認する。

- Cookie がない場合は `/auth/login` へ redirect する。
- Cookie がある場合は Next.js BFF 経由で必要な初期データを取得する。
- Client Component だけで認証判定する実装は、移行期間の暫定対応に留める。

## ログアウト

ログアウト時は以下を行う。

- Next.js 側の Cookie を削除する。
- refresh token を使っている場合は Rails API 側で revoke する。
- 完了後 `/auth/login` へ redirect する。

# Devise / Warden 設定

```
# セッション保存可否
config.warden do |manager|
  manager.scope_defaults :user_account, store: false # APIはセッション無効
  manager.scope_defaults :tenant_account, store: true
  manager.scope_defaults :admin_account, store: true
end

# ナビゲーショナル形式
config.navigational_formats = [:html]（MVCはリダイレクト、APIはJSONで401）

# UserのみJWT有効化
config.jwt.secret, dispatch_requests(POST /api/v1/auth/sign_in), revocation_requests(DELETE /api/v1/auth/sign_out), expiration_time
```
