# 認証トークン保存方式の見直し

## 背景

現在の frontend では、ログイン成功時に `accessToken` と `refreshToken` を `localStorage` に保存している。

`localStorage` は JavaScript から読み取れるため、XSS が発生した場合にトークンが漏えいするリスクがある。特に `refreshToken` は長めの有効期限を持つ前提になりやすく、漏えい時の影響が大きい。

## 後で解決したい課題

- `refreshToken` を `localStorage` に保存しない。
- `accessToken` も可能であれば永続ストレージに保存しない。
- ページリロード後の認証復元方法を、XSS 耐性のある方式に変更する。

## 方針案

### 案1: Rails が HttpOnly Cookie に refresh token を保存する

- `refreshToken` は `HttpOnly`, `Secure`, `SameSite=Lax` または `SameSite=Strict` の Cookie に保存する。
- frontend の JavaScript から `refreshToken` を読めないようにする。
- `accessToken` はメモリ上に保持し、必要に応じて refresh endpoint で再発行する。

### 案2: Next.js を BFF として使う

- ブラウザは Next.js の Route Handler / Server Action にだけリクエストする。
- Next.js サーバー側が Rails API に認証付きでリクエストする。
- ブラウザに Rails 用トークンを直接持たせない。

## 影響範囲

- `frontend/src/lib/auth.ts`
- `frontend/src/components/AuthForm.tsx`
- `frontend/src/app/auth/login/page.tsx`
- `frontend/src/app/auth/sign-up/page.tsx`
- `backend/app/controllers/api/v1/auth/sessions_controller.rb`
- `backend/app/controllers/api/v1/auth/registrations_controller.rb`
- `backend/app/controllers/api/v1/auth/refresh_tokens_controller.rb`
- `backend/config/initializers/devise.rb`

## 検証観点

- ログイン後、`localStorage` に `refreshToken` が保存されないこと。
- refresh token が `HttpOnly` Cookie として保存され、JavaScript から読み取れないこと。
- ページリロード後に認証状態を復元できること。
- ログアウト時に Cookie とサーバー側 refresh token が無効化されること。
- CSRF 対策と `SameSite` 設定が期待どおりに機能すること。

