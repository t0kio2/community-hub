# 掲載検索画面設計

## 目的

ユーザーがログイン後に公開中の掲載を探すための画面を追加する。

## 方針

- 画面 URL は `/listings` とする。
- access token がない場合は `/auth/login` へ戻す。
- 初期版は frontend 内の表示設計とし、API 接続は後続で行う。
- 後で API レスポンスに置き換えやすいように、listing 表示用の型と状態を page 内で分離する。
- 検索、掲載種別、働き方・滞在タイプの絞り込みを用意する。

## 影響範囲

- `frontend/src/app/dashboard/page.tsx`
- `frontend/src/app/listings/page.tsx`
- `frontend/src/app/globals.css`

## 後続作業

- `GET /api/v1/listings` を backend に追加する。
- frontend の仮データを API 取得に置き換える。
- 詳細画面 `/listings/[id]` を追加する。
- お気に入り追加 API と連携する。

## 検証

- dashboard の「掲載を探す」から `/listings` に遷移できること。
- 未ログイン状態で `/listings` を開くと `/auth/login` に戻ること。
- 検索・種別・カテゴリ絞り込みで表示件数が変わること。

