ユーザ、テナント、アドミンの 3 者が存在する。

- ユーザ: トークン認証 (JWT)
- テナント、アドミン: セッション認証(DB にセッションを保存)

# 方針

- 各主体は accounts テーブルで認証する。
- 各主体を別 Devise スコープにする
  - UserAccount
  - TenantAccount
  - AdminAccount

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
