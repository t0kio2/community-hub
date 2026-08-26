現状は「宿泊施設の基本構成」はかなり揃っていますが、完成とはまだ言えません。

  揃っている機能：

  - Stay Listingの新規作成・編集
  - Room Type
  - Room
  - Bed
  - Rate Plan
  - Room Type別基本料金
  - キャンセル条件の表示

  その次の実装候補は、認識どおり次の機能です。

  1. 部屋・ベッドのブロック
      - stay_room_blocks
      - stay_bed_blocks
      - 故障、清掃、メンテナンスなどで販売対象外にする期間

  2. 販売カレンダー
      - stay_room_type_daily_sales_controls
      - 日ごとの販売数や販売停止
      - stay_room_type_rate_daily_prices
      - 基本料金を日付別に上書きする特別料金

  この2種類は意味が異なります。

  - Block：特定の物理的な部屋・ベッドを利用不可にする
  - Daily sales control：Room Type単位で、その日に販売する在庫数を制御する
  - Daily price：Rate Plan × Room Type × 日付単位で価格を上書きする

  そのほか、まだ見当たらないものとしては以下があります。

  - 設備・アメニティ設定
  - Room Type画像
  - 公開設定・公開前チェック
  - Stay Listingの削除機能（必要なら）
  - 予約管理機能

  実装順としては、

  StayListingの保存修正 → Block → 販売カレンダー（日別在庫・日別料金）→ 公開設定

  がよさそうです。特に日別在庫と特別料金は同じ「販売カレンダー」画面にまとめると運用しやすいです。
