# 掲載検索画面設計

## 目的

ユーザーがログイン後に公開中の掲載を探すための画面を追加する。

## 方針

- 画面 URL は `/listings` とする。
- access token がない場合は `/auth/login` へ戻す。
- 掲載一覧は `GET /api/v1/public/listings` から取得して表示する。
- API レスポンス型、表示用の型、変換処理は `frontend/src/lib/listings.ts` に分離する。
- 画面確認や将来のテストで再利用できる仮データは `frontend/src/lib/listingFixtures.ts` に退避する。
- 検索、掲載種別、働き方・滞在タイプの絞り込みを用意する。
- API 取得中、取得失敗、取得成功後 0 件の状態を明示して表示する。

## 影響範囲

- `frontend/src/app/dashboard/page.tsx`
- `frontend/src/app/listings/page.tsx`
- `frontend/src/app/globals.css`
- `frontend/src/lib/listings.ts`
- `frontend/src/lib/listingFixtures.ts`

## API 連携

- 取得先は Next.js rewrite 経由の `/api/v1/public/listings` とする。
- API の `listing_type` は表示側で `job` / `stay` に変換する。
- 仕事掲載は `detail.work_area` と給与情報を、滞在掲載は `detail.address` と `price_per_night` を優先して表示する。
- API から取得できない補助情報は画面が壊れないように既定ラベルへフォールバックする。

## 後続作業

- 詳細画面 `/listings/[id]` を追加する。
- お気に入り追加 API と連携する。

## 検証

- dashboard の「掲載を探す」から `/listings` に遷移できること。
- 未ログイン状態で `/listings` を開くと `/auth/login` に戻ること。
- 検索・種別・カテゴリ絞り込みで表示件数が変わること。
- API 取得成功時に実データが表示されること。
- API 取得失敗時に再読み込み導線つきのエラー表示になること。
- `npm run lint` が成功すること。
