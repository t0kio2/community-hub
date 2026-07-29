# 滞在Listing定義

## 目的

滞在Listing固有のカラム、宿泊料金、滞在可能期間、公開条件を定義する。

Listing共通の状態遷移、権限、画像、削除・保持は [`02-listing.md`](./02-listing.md)、住所・位置情報は [`03-location.md`](./03-location.md)、テーブル間の関連は [`../er/01-listing.md`](../er/01-listing.md) を参照する。

## TODO

- [ ] 滞在Listingの公開必須項目を決める
- [ ] 通貨を日本円に固定するか決める
- [ ] 料金を整数の円単位で保持するか決める
- [ ] 料金を税込・税抜のどちらとして扱うか決める
- [ ] 料金が一室単位か、一人単位か決める
- [ ] `available_from` と `available_until` を両方必須とするか決める
- [ ] 過去の日付を指定できるか決める
- [ ] 予約期間全体が滞在可能期間内に収まることを必須とするか決める
- [ ] 予約期間の重複をどの機能で制御するか決める
- [ ] `amenities` の入力形式と検索方法を決める

## stay_listings

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・単位 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 宿泊詳細の識別子 | 作成後変更不可 |
| `listing_id` | bigint | ○ | なし | 対応する宿泊Listing | 一意、`listing_type = stay` |
| `stay_type` | string | × | NULL | 宿泊施設・部屋の種別 | `private_room / shared_room / entire_place / other` |
| `capacity` | integer | × | NULL | 宿泊可能人数 | 1以上、上限: 要定義 |
| `price_per_night` | integer | × | NULL | 1泊あたりの料金 | 0以上、課金単位・通貨・税込区分: 要定義 |
| `check_in_time` | time | × | NULL | チェックイン時刻 | タイムゾーン・時間幅: 要定義 |
| `check_out_time` | time | × | NULL | チェックアウト時刻 | タイムゾーン・時間幅: 要定義 |
| `available_from` | date | × | NULL | 予約可能期間の開始日 | `available_until`以前 |
| `available_until` | date | × | NULL | 予約可能期間の終了日 | `available_from`以後 |
| `amenities` | text | × | NULL | 設備・アメニティ | テキスト / JSON / 別テーブル: 要定義 |
| `house_rules` | text | × | NULL | 宿泊時のルール | 入力形式・最大文字数: 要定義 |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

## 宿泊料金

| 項目 | 定義 |
| --- | --- |
| 通貨 | 要定義 |
| 料金単位 | 要定義: 1室1泊 / 1名1泊 |
| 税込・税抜 | 要定義 |
| 追加人数料金 | 要定義 |
| 清掃料金・手数料 | 要定義 |

## 公開条件

共通の公開条件に加えて必要な滞在固有条件は要定義とする。

## テスト条件

- 下書きでは滞在固有の公開必須項目が未入力でも保存できること。
- 宿泊種別、定員、料金、時刻、滞在可能期間の許可値と境界値を検証すること。
- 滞在固有の公開条件を満たす場合と満たさない場合を検証すること。
