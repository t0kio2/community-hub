# アカウント削除設計

## 目的

ログイン中の user account が、自分のアカウントを削除できるようにする。削除後は認証情報を破棄し、ログイン画面へ戻す。

## API

- `DELETE /api/v1/user/account`
- 認証は既存の user JWT を使う。
- 成功時は `204 No Content` を返す。
- 未ログイン時は既存の認証処理により `401 Unauthorized` を返す。

## データ削除

削除対象は `current_user_account` とする。関連レコードは既存の `dependent: :destroy` を利用する。

- `Account has_one :user, dependent: :destroy`
- `Account has_many :user_refresh_tokens, dependent: :destroy`
- `User has_one :user_profile, dependent: :destroy`
- `User has_many :favorites, dependent: :destroy`

`users` が存在しない古い user account でも、account 自体は削除できる。

## Frontend

プロフィール画面に危険操作としてアカウント削除を追加する。プロフィール取得に失敗した場合でも、ログイン状態が残っていれば削除操作は表示する。

削除ボタン押下時は確認ダイアログを表示し、確定した場合のみ削除 API を呼び出す。

削除成功後はプロフィール画面上で削除完了トーストを表示し、短い表示時間を置いてから `/auth/login` に遷移する。API エラー時は画面内にエラーを表示する。

## 検証

- backend controller test で未ログイン時の `401` を確認する。
- backend controller test で account 削除時に user/profile/refresh token が削除されることを確認する。
- backend controller test で user が無い account も削除できることを確認する。
- frontend は lint/build で型と構文を確認する。
