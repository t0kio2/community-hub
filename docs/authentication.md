ユーザ、テナント、アドミンの 3 者が存在する。

- ユーザ: トークン認証 (JWT)
- テナント、アドミン: セッション認証(DB にセッションを保存)

# 方針

- 各主体は accounts テーブルで認証する。
- 各主体を別 Devise スコープにする
  - UserAccount
  - TenantAccount
  - AdminAccount
- MVP では Next.js BFF を置かず、ユーザー向け frontend から Rails API を直接呼び出す。
- access token / refresh token / account / device id はブラウザの `localStorage` に保存する。
- 認証が必要な Rails API 呼び出しは frontend が `Authorization: Bearer <access_token>` を付けて送信する。
- Rails API は frontend origin からの CORS preflight と `Authorization` レスポンスヘッダ公開を許可する。

# Frontend / API 直接呼び出し認証方針

ユーザー画面は以下の構成にする。

```text
Browser
  localStorage
  Authorization: Bearer <access_token>
  ↓
Rails API
```

## frontend 設定

- Rails API の origin は `NEXT_PUBLIC_API_ORIGIN` で指定する。
- ローカル開発の既定値は `http://localhost:3001` とする。
- Docker Compose の frontend には `NEXT_PUBLIC_API_ORIGIN=http://localhost:3001` を渡し、ブラウザから公開ポートへ直接アクセスさせる。

## localStorage

- `communityHubAccessToken`: Rails API へ Bearer token として送る短命 token。
- `communityHubRefreshToken`: access token 更新とログアウト時の revoke に使う token。
- `communityHubAccount`: 画面表示用の最小 account 情報。認可判断には使わない。
- `communityHubDeviceId`: refresh token を端末単位で管理するための ID。

MVP の簡素化として token を JavaScript から読める場所に置くため、XSS 対策の重要度は上がる。将来、権限や個人情報の範囲が広がる段階で HttpOnly Cookie + BFF への再移行を再検討する。

## CORS

Rails API は `FRONTEND_ORIGINS` で許可 origin を受け取る。未指定時は以下を許可する。

- `http://localhost:3000`
- `http://127.0.0.1:3000`

API レスポンスでは `Access-Control-Allow-Headers` に `Authorization`, `Content-Type`, `X-Device-Id`, `X-Device-Name` を含める。ログインとリフレッシュで返る access token を読むため、`Access-Control-Expose-Headers` に `Authorization` を含める。

## ログイン

ログイン処理は frontend から Rails API を直接呼び出す。

```text
Login form
  ↓ POST /api/v1/auth/sign_in
Rails API
  ↓ Authorization header / refresh token
frontend
  localStorage に保存
  redirect /dashboard
```

`X-Device-Id` と `X-Device-Name` を付けて refresh token を端末単位で管理する。

## 認証が必要な API 通信

Client Component から認証が必要なデータを取得する場合は、frontend の API helper を使う。

```text
Client Component
  ↓ GET /api/v1/user/favorites
  Authorization: Bearer <access_token>
Rails API
```

401 が返った場合、refresh token で `/api/v1/auth/refresh` を呼び出して token をローテーションし、成功したら元のリクエストを 1 回だけ再試行する。

## ページ表示時の認証確認

認証が必要な page は、Client Component で保存済み token を確認する。access token がないが refresh token がある場合は session 確認時に refresh を試みる。

## ログアウト

ログアウト時は以下を行う。

- refresh token を Rails API 側で revoke する。
- frontend の `localStorage` から token / account / device id を削除する。
- 完了後 `/auth/login` へ redirect する。

# 実装計画

- `frontend/src/lib/auth.ts` に API origin 解決、token 保存、refresh、認証付き fetch helper を集約する。
- `frontend/src/lib/listings.ts` は `/api/v1/public/listings` の same-origin fetch ではなく Rails API origin へ直接 fetch する。
- Next.js Route Handler と `serverAuth` は削除する。
- `frontend/next.config.ts` の `/api/:path*` rewrite は削除する。
- Rails は Rack middleware で API CORS ヘッダを付け、API の `OPTIONS` preflight を返す。
- `docker-compose.yml` の frontend に `NEXT_PUBLIC_API_ORIGIN` を追加する。

# 検証計画

- frontend lint で TypeScript / Next.js の静的検証を行う。
- Rails controller test で CORS preflight と `Authorization` expose header を確認する。
- 既存の公開 listing API test を通し、CORS 追加が公開APIのレスポンスを壊していないことを確認する。

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
