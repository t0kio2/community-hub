# ログイン後画面設計

## 目的

ユーザーがログインまたは新規登録した後に、認証済み状態で最初に見る画面を用意する。

## 方針

- ログイン後の遷移先は `/dashboard` とする。
- 画面は frontend のみで完結する初期版とし、API 連携が必要な listing 表示は後続で追加する。
- 保存済みの access token がない場合はログイン画面へ戻す。
- ログインレスポンスの account 情報を保存し、dashboard でメールアドレスを表示する。
- ログアウト時は保存済みの認証情報を削除して `/auth/login` へ遷移する。

## 影響範囲

- `frontend/src/lib/auth.ts`
- `frontend/src/components/AuthForm.tsx`
- `frontend/src/app/dashboard/page.tsx`
- `frontend/src/app/globals.css`

## 検証

- ログイン成功後に `/dashboard` へ遷移すること。
- 新規登録成功後に `/dashboard` へ遷移すること。
- access token がない状態で `/dashboard` を開くと `/auth/login` へ戻ること。
- ログアウトで localStorage の認証情報が削除されること。

