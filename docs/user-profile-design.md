# ユーザープロフィール設計

## 背景

以前の `profiles` は `accounts` に紐づく共通プロフィールとして作られていた。しかし `accounts` は認証情報であり、user / tenant / admin の全主体が共有するため、`profiles` の用途が広すぎる。

ユーザー向け機能では、プロフィールはサービス利用者である `users` の属性として扱う方が自然である。

フロントでは dashboard に「プロフィール」導線だけがあり、応募や問い合わせに使うユーザー情報を登録・確認する画面がまだない。ユーザーが掲載へアクションする前に、最低限の連絡先と本人情報を整えられる状態を作る。

## 方針

- `user_profiles` は user 専用プロフィールとして扱う。
- `profiles` テーブルは `user_profiles` に変更する。
- `profiles.account_id` を廃止し、`user_profiles.user_id` に変更する。
- `Account has_one :profile` は削除する。
- `User has_one :user_profile` を追加する。
- `UserProfile belongs_to :user` に変更する。
- フロントのプロフィール画面 URL は `/profile` とする。
- dashboard の「プロフィール」カードは `/profile` へ遷移する。
- 未ログイン状態で `/profile` を開いた場合は `/auth/login` へ戻す。
- API レスポンス型、フォーム値、変換処理は `frontend/src/lib/profile.ts` に分離する。
- 初期版は現在の `user_profiles` テーブルに存在する項目だけを扱い、職歴・自己紹介・希望条件などは後続で追加する。

## データ移行

既存の `profiles.account_id` に対応する `users.account_id` が存在する場合は、その `users.id` を `profiles.user_id` に移行したうえで、テーブル名を `user_profiles` に変更する。

対応する `users` が存在しない profile は、user 用 profile として成立しないため削除する。

## フロント画面

### `/profile`

ログインユーザー自身のプロフィールを表示・編集する画面。

- ヘッダーは dashboard / listings と同じ `appHeader` を使う。
- ナビゲーションに `マイページ`、`掲載を探す`、`プロフィール` を表示する。
- ページ上部にプロフィール完成状態を表示する。
- 編集フォームは 1 画面で完結させ、保存後も `/profile` に留める。
- 保存成功時はフォーム上部に成功メッセージを表示する。
- 保存失敗時は API エラーまたは汎用エラーを表示する。
- 未作成の場合は空フォームを表示し、保存時に profile を作成する。

### フォーム項目

| 表示名 | フィールド | 入力種別 | 必須 | 備考 |
| --- | --- | --- | --- | --- |
| 氏名 | `name` | text | 必須 | `UserProfile` の必須項目 |
| フリガナ | `kana` | text | 任意 | 空文字は `null` として送る |
| 生年月日 | `birth_date` | date | 任意 | `YYYY-MM-DD` |
| 電話番号 | `phone` | tel | 任意 | 初期版では厳密な形式チェックはしない |
| アバター URL | `avatar_url` | url | 任意 | 画像アップロードは後続 |

### 表示状態

- 認証確認中: `読み込み中`
- profile 取得中: `プロフィールを読み込み中`
- 未作成: 空フォームと「プロフィールを保存」ボタン
- 取得成功: 取得値をフォームに反映
- 取得失敗: 再読み込み導線つきのエラー表示
- 保存中: 保存ボタンを disabled にして二重送信を防ぐ
- 保存成功: 最新の保存値をフォームに維持し、完了メッセージを表示
- 保存失敗: 入力値は破棄せず、エラーメッセージを表示

## API 連携

Next.js 側は既存の `frontend/src/app/api/v1/user/[...path]/route.ts` を使い、cookie の access token / refresh token 管理を隠蔽する。

現在の user API proxy は `GET` / `POST` / `DELETE` のみを export しているため、保存 API を通す実装時に `PUT` も追加する。

### 取得

`GET /api/v1/user/profile`

レスポンス例:

```json
{
  "profile": {
    "id": 1,
    "name": "山田 太郎",
    "kana": "ヤマダ タロウ",
    "birth_date": "1995-04-12",
    "phone": "09012345678",
    "avatar_url": "https://example.com/avatar.png"
  }
}
```

profile 未作成の場合は `200 OK` で `{"profile": null}` を返す。フロントが未作成状態と通信エラーを区別できるようにするため、未作成を `404` にはしない。

### 保存

`PUT /api/v1/user/profile`

リクエスト例:

```json
{
  "profile": {
    "name": "山田 太郎",
    "kana": "ヤマダ タロウ",
    "birth_date": "1995-04-12",
    "phone": "09012345678",
    "avatar_url": "https://example.com/avatar.png"
  }
}
```

profile が存在しない場合は作成し、存在する場合は更新する。レスポンスは取得 API と同じ形にする。

### エラー

- `401`: 未認証。フロントは `/auth/login` へ戻す。
- `422`: バリデーションエラー。`errors: string[]` を表示する。
- `500`: 汎用エラーとして「プロフィールを保存できませんでした」を表示する。

## フロント実装方針

### ファイル構成

- `frontend/src/app/profile/page.tsx`
- `frontend/src/lib/profile.ts`
- `frontend/src/app/dashboard/page.tsx`
- `frontend/src/app/globals.css`

### `frontend/src/lib/profile.ts`

責務:

- API レスポンス型を定義する。
- フォーム値型を定義する。
- `fetchUserProfile()` を提供する。
- `saveUserProfile(values)` を提供する。
- API の `null` とフォームの空文字を相互変換する。
- `name` のクライアント側必須チェックを提供する。

想定型:

```ts
export type UserProfile = {
  id: number;
  name: string;
  kana: string | null;
  birth_date: string | null;
  phone: string | null;
  avatar_url: string | null;
};

export type ProfileFormValues = {
  name: string;
  kana: string;
  birthDate: string;
  phone: string;
  avatarUrl: string;
};
```

### `frontend/src/app/profile/page.tsx`

責務:

- `useAuthSnapshot()` で認証状態を確認する。
- 未認証時に `/auth/login` へ遷移する。
- 認証済みになった後で `fetchUserProfile()` を呼ぶ。
- `ProfileFormValues` を `useState` で管理する。
- 保存時に `saveUserProfile()` を呼ぶ。
- loading / error / success / saving 状態を表示する。

## UI 方針

- 既存の `appShell`、`appHeader`、`dashboardSection`、`field`、`primaryButton`、`secondaryButton` を再利用する。
- dashboard / listings と同じ静かな業務系 UI に寄せ、装飾より入力しやすさを優先する。
- フォーム幅は最大 720px 程度に抑え、モバイルでは 1 カラムにする。
- 必須項目はラベル横に「必須」を表示する。
- アバターは初期版では URL 入力だけにし、プレビューは URL がある場合のみ表示する。
- ヘッダーやボタン内の文字がモバイルで折り返してもレイアウトが崩れないようにする。

## 影響範囲

- `backend/db/migrate`
- `backend/app/models/account.rb`
- `backend/app/models/user.rb`
- `backend/app/models/user_profile.rb`
- `backend/config/routes.rb`
- `backend/app/controllers/api/v1/user/profiles_controller.rb`
- `backend/test/fixtures/user_profiles.yml`
- `backend/test/models/user_profile_test.rb`
- `backend/test/models/user_test.rb`
- `backend/test/models/account_test.rb`
- `backend/test/controllers/api/v1/user/profiles_controller_test.rb`
- `frontend/src/app/dashboard/page.tsx`
- `frontend/src/app/profile/page.tsx`
- `frontend/src/app/api/v1/user/[...path]/route.ts`
- `frontend/src/lib/profile.ts`
- `frontend/src/app/globals.css`

## 検証

- `UserProfile` は `user` が必須であること。
- `User` から `user_profile` を参照できること。
- `Account` から `profile` を直接参照しないこと。
- `user_profiles.user_id` に unique index と foreign key があること。
- dashboard の「プロフィール」から `/profile` に遷移できること。
- 未ログイン状態で `/profile` を開くと `/auth/login` に戻ること。
- profile 未作成時に空フォームが表示されること。
- profile 作成済み時に API の値がフォームへ反映されること。
- 氏名が空の場合に保存せず、フォーム上でエラーを表示すること。
- 保存成功時に成功メッセージが表示され、入力値が維持されること。
- 保存失敗時に入力値を維持したままエラーを表示すること。
- `npm run lint` が成功すること。

## 後続作業

- アバター画像アップロードを Active Storage などで扱う。
- 掲載への応募・問い合わせ時にプロフィール情報を再利用する。
- 職歴、自己紹介、希望条件、緊急連絡先などの項目を追加する。
- プロフィール完成度を dashboard に表示する。
