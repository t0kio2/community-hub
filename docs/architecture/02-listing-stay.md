# 滞在Listing定義

## 目的

滞在Listing固有のカラム、宿泊料金、滞在可能期間、公開条件を定義する。

Listing共通の状態遷移、権限、画像、削除・保持は [`02-listing.md`](./02-listing.md)、住所・位置情報は [`03-location.md`](./03-location.md)、テーブル間の関連は [`../er/01-listing.md`](../er/01-listing.md) を参照する。

## TODO

- [ ] 滞在Listingの公開必須項目を決める
- [ ] Room Typeの公開必須項目と公開状態の持ち方を決める
- [ ] 予約確定時に物理Room・Bedを割り当てるか、後から割り当てるか決める
- [ ] 日付ごとの販売停止と在庫調整の持ち方を決める
- [ ] 清掃料金、サービス料、宿泊税、入湯税の料金明細を予約仕様で決める
- [ ] `available_from` と `available_until` を両方必須とするか決める
- [ ] 過去の日付を指定できるか決める
- [ ] 予約期間全体が滞在可能期間内に収まることを必須とするか決める
- [ ] 予約期間の重複をどの機能で制御するか決める
- [ ] Room Typeの`amenities`の入力形式と検索方法を決める

## 宿泊施設・部屋・在庫の単位

1つの `listing` は、テナントが運営する1つの宿泊施設を表す。施設は1つ以上のRoom Typeを持ち、一般ユーザーは予約時に物理的な部屋ではなくRoom Typeを選択する。

Room Typeはシステム共通の部屋マスターではなく、テナントが自ら所有する宿泊施設ごとに作成する販売上の部屋分類とする。同じ「ツインルーム」という名称でも、施設が異なる場合は別のRoom Typeとして扱う。Room Typeの所有テナントは `stay_room_type -> stay_listing -> listing -> tenant` の関連から特定し、テナントは自ら所有する施設にのみRoom Typeを作成・更新できる。

物理的な宿泊空間はRoomとして登録し、必ず同じ施設に属する1つのRoom Typeへ紐づける。一般ユーザーにはRoomを選択させず、施設側またはシステムが予約へ割り当てる。

```text
Tenant
└─ Listing（宿泊施設）
   └─ StayListing（施設共通の宿泊情報）
      └─ StayRoomType（販売上の部屋分類）
         └─ StayRoom（物理的な部屋）
            └─ StayBed（相部屋内の物理的なベッド）
```

| `room_kind` | 販売形態 | 予約・在庫の単位 |
| --- | --- | --- |
| `entire_place` | 一棟または独立した空間を貸し切る | Room |
| `private_room` | 施設内の個室を貸し切る | Room |
| `shared_room` | 他の宿泊者と共有する相部屋 | Bed |

1つのRoom TypeでRoom単位とBed単位の販売を混在させない。同じ物理空間をRoom単位とBed単位の両方で販売すると在庫が競合するため、初期仕様では同一期間に両方の販売方法を併用しない。

物理在庫を登録するため、Room Typeに手入力の `inventory_count` は持たない。`entire_place` と `private_room` の基本在庫は有効なRoomの件数、`shared_room` の基本在庫は有効なBedの件数から算出する。一棟貸しは、その一棟を表すRoomを1件登録する。

## stay_listings

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・単位 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 宿泊詳細の識別子 | 作成後変更不可 |
| `listing_id` | bigint | ○ | なし | 対応する宿泊Listing | 一意、`listing_type = stay` |
| `check_in_time` | time | × | NULL | チェックイン時刻 | タイムゾーン・時間幅: 要定義 |
| `check_out_time` | time | × | NULL | チェックアウト時刻 | タイムゾーン・時間幅: 要定義 |
| `available_from` | date | × | NULL | 予約可能期間の開始日 | `available_until`以前 |
| `available_until` | date | × | NULL | 予約可能期間の終了日 | `available_from`以後 |
| `house_rules` | text | × | NULL | 宿泊時のルール | 入力形式・最大文字数: 要定義 |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

## stay_room_types

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・単位 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | Room Typeの識別子 | 作成後変更不可 |
| `stay_listing_id` | bigint | ○ | なし | 所属する宿泊施設 | 所有テナントはListingから特定する |
| `name` | string | ○ | なし | テナントが設定する利用者向け名称 | 施設内の一意性・最大文字数: 要定義 |
| `description` | text | × | NULL | Room Typeの説明 | 入力形式・最大文字数: 要定義 |
| `room_kind` | string | ○ | なし | 販売形態と在庫単位を決める分類 | `entire_place / private_room / shared_room` |
| `capacity` | integer | × | NULL | Room単位で宿泊できる最大人数 | 公開時は必須、1以上、上限: 要定義。`shared_room`での扱い: 要定義 |
| `price_per_night_amount` | integer | × | NULL | テナントが入力する1在庫単位・1泊の利用者向け料金 | 公開時は必須、1以上、初期仕様では整数の円単位 |
| `currency` | string | ○ | `JPY` | ISO 4217通貨コード | 初期仕様では`JPY`のみ |
| `amenities` | text | × | NULL | Room Typeごとの設備・アメニティ | テキスト / JSON / 別テーブル: 要定義 |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

## stay_rooms

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・単位 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 物理Roomの識別子 | 作成後変更不可 |
| `stay_room_type_id` | bigint | ○ | なし | 所属するRoom Type | 同じ宿泊施設内のRoom Typeにのみ紐づける |
| `name` | string | ○ | なし | 施設内の管理名 | 例: `101号室`。施設内で一意 |
| `active` | boolean | ○ | `true` | 通常在庫として利用できるか | `false`のRoomは新規予約へ割り当てない |
| `notes` | text | × | NULL | テナント内部の管理メモ | 一般ユーザーへ表示しない |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

## stay_beds

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・単位 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 物理Bedの識別子 | 作成後変更不可 |
| `stay_room_id` | bigint | ○ | なし | Bedが設置されている物理Room | `room_kind = shared_room`のRoomにのみ作成可能 |
| `name` | string | ○ | なし | Room内の管理名 | 例: `A-1`、Room内で一意 |
| `active` | boolean | ○ | `true` | 通常在庫として利用できるか | `false`のBedは新規予約へ割り当てない |
| `notes` | text | × | NULL | テナント内部の管理メモ | 一般ユーザーへ表示しない |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

## 宿泊料金

| 項目 | 定義 |
| --- | --- |
| 通貨 | 初期仕様は`JPY` |
| 金額の保持単位 | 日本円の整数 |
| 料金単位 | `entire_place / private_room`は1 Room・1泊、`shared_room`は1 Bed・1泊 |
| 消費税 | テナントが利用者向け料金へ反映し、システムは自動加算しない |
| 追加人数料金 | 要定義 |
| 清掃料金・手数料 | 要定義 |

Room Typeの `price_per_night_amount` と `currency` を組み合わせて料金を表す。初期仕様では `currency = JPY` のみを許可し、画面に通貨選択を表示しない。

テナントは、一般ユーザーへ表示する消費税を考慮した1泊料金を `price_per_night_amount` に入力する。システムは入力額へ消費税を自動加算せず、税込・税抜を切り替えるカラムも持たない。

清掃料金、サービス料、宿泊税、入湯税などの追加料金は `price_per_night_amount` に混在させず、予約時の料金明細として管理する。予約確定前に、宿泊料金、追加料金、税および最終支払額を一般ユーザーへ表示する。

将来複数通貨へ対応する場合は、ISO 4217の通貨コードから選択可能にし、金額を通貨ごとの最小通貨単位で保持する。予約が存在するListingの通貨は変更できない。

### 設計判断の経緯

一般消費者へインターネット上で価格を事前表示する場合、原則として消費税を含む総額表示が求められる。詳細は[国税庁「事業者が消費者に対して価格を表示する場合の取扱い」](https://www.nta.go.jp/law/tsutatsu/kihon/shohi/18/01.htm)および[国税庁「総額表示の義務付け」](https://www.nta.go.jp/taxes/shiraberu/taxanswer/shohi/6902_qa.htm)を参照する。

システムが税抜料金へ消費税を自動加算するには、宿泊契約の販売主体、決済代金の受領主体、領収書・インボイスの発行主体、テナントの課税区分、適用税率、端数処理を確定する必要がある。これらが未確定の段階で一律に税率を適用すると、実際の取引条件と一致しない可能性がある。

このため初期仕様では、テナントが利用者向け料金を決定して入力し、システムはその金額をListingへ表示する。販売・決済・請求の主体と税務要件が確定し、システムによる税計算が必要になった場合は、Listingではなく予約料金計算の仕様として追加する。

## 公開条件

共通の公開条件に加えて必要な滞在固有条件は要定義とする。予約を受け付けるには、一般ユーザーが選択可能なRoom Typeと、その販売形態に対応する有効な物理在庫が少なくとも1件存在しなければならない。

## テスト条件

- 下書きでは滞在固有の公開必須項目が未入力でも保存できること。
- 自テナントが所有する宿泊施設にのみRoom Type、Room、Bedを作成・更新できること。
- Room TypeとRoom、RoomとBedが同じ宿泊施設および許可された販売形態の範囲で紐づくこと。
- Room Typeの販売形態、定員、料金、時刻、滞在可能期間の許可値と境界値を検証すること。
- 貸切部屋はRoom、相部屋はBedを在庫として数え、無効な物理在庫を除外すること。
- 滞在固有の公開条件を満たす場合と満たさない場合を検証すること。
