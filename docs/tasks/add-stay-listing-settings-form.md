# 宿泊・予約設定フォーム実装計画

## 目的と背景

宿泊施設の登録・編集画面では、`stay_listings`に定義済みの宿泊時刻、予約受付、宿泊可能期間、ハウスルールを入力できない。既存の共通Listingフォームに宿泊専用フォームを追加する。

## 対象

- `backend/app/views/tenant/shared/_listing_form.html.erb`
- `backend/app/assets/stylesheets/tenant/listings.css`
- `backend/test/controllers/tenant/stays_controller_test.rb`

## 画面変更

- 宿泊施設の場合だけ`listing[stay_listing]`配下に次の入力欄を表示する。
  - 予約確定方式、承認期限
  - チェックイン開始・最終時刻、チェックアウト時刻、タイムゾーン
  - 宿泊可能期間の開始・終了
  - 予約受付開始日数・終了時間
  - ハウスルール
- 時刻・宿泊可能期間の入力は横幅を抑えつつ、入力欄全体をネイティブピッカーの操作領域にする。
- textarea以外の入力、選択、固定値表示を共通の高さとbox sizingにし、ブラウザによる入力種別ごとの高さの差をなくす。
- ピッカーアイコンはCSS図形ではなくSVGを中央配置する。
- 初期仕様のタイムゾーンは選択式にせず、日本時間`Asia/Tokyo`を固定値として送信する。
- 求人フォームには表示しない。
- 新規画面ではDB初期値を表示し、編集画面では保存済みの値を表示する。

## 実装手順とテスト

1. 宿泊専用の`fields_for`と入力欄を追加する。
2. 補足文の表示スタイルを追加する。
3. 新規・編集画面の入力名、型、選択値、既存値をControllerテストで確認する。
4. Docker Compose経由で対象テストと全テストを実行する。

## 対象外・後続作業

- `StayListing`モデルの変更
- `Tenant::StaysController`のStrong Parametersと属性反映
- 条件付き表示のJavaScript

フォーム値を保存するには、後続作業で`listing[stay_listing]`を許可し、`@stay_listing`へ代入する必要がある。
