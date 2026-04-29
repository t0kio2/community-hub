# ユーザープロフィール設計

## 背景

現在の `profiles` は `accounts` に紐づく共通プロフィールとして作られている。しかし `accounts` は認証情報であり、user / tenant / admin の全主体が共有するため、`profiles` の用途が広すぎる。

ユーザー向け機能では、プロフィールはサービス利用者である `users` の属性として扱う方が自然である。

## 方針

- `profiles` は user 専用プロフィールとして扱う。
- `profiles.account_id` を廃止し、`profiles.user_id` に変更する。
- `Account has_one :profile` は削除する。
- `User has_one :profile` を追加する。
- `Profile belongs_to :user` に変更する。

## データ移行

既存の `profiles.account_id` に対応する `users.account_id` が存在する場合は、その `users.id` を `profiles.user_id` に移行する。

対応する `users` が存在しない profile は、user 用 profile として成立しないため削除する。

## 影響範囲

- `backend/db/migrate`
- `backend/app/models/account.rb`
- `backend/app/models/user.rb`
- `backend/app/models/profile.rb`
- `backend/test/fixtures/profiles.yml`
- `backend/test/models/profile_test.rb`
- `backend/test/models/user_test.rb`
- `backend/test/models/account_test.rb`

## 検証

- `Profile` は `user` が必須であること。
- `User` から `profile` を参照できること。
- `Account` から `profile` を直接参照しないこと。
- `profiles.user_id` に unique index と foreign key があること。

