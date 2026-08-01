# 宿泊予約定義

## 目的

宿泊予約の受付、承認、物理在庫の割り当て、宿泊者、料金とキャンセル条件の固定、および状態遷移を定義する。

予約テーブル構造は [`../er/02-stay-reservation.md`](../er/02-stay-reservation.md)、宿泊施設、Room Type、物理在庫、Rate Planの定義は [`02-listing-stay.md`](./02-listing-stay.md) を正本とする。

## TODO

- [ ] 予約内容の変更ルールを決める
- [ ] 清掃料金、サービス料、宿泊税、入湯税を料金明細へ追加する方法を決める
- [ ] 予約完了と無断不泊への状態遷移を決める
- [ ] 宿泊者情報を変更できる正確な期限を決める

## 宿泊期間と物理在庫の割り当て

宿泊期間はチェックイン日を含みチェックアウト日を含まない半開区間`[check_in_date, check_out_date)`として扱う。8月1日チェックイン・8月3日チェックアウトは8月1日泊と8月2日泊の在庫を使用する。

期間の重複は次の条件で判定する。

```text
既存の開始日 < 新しい終了日
かつ
既存の終了日 > 新しい開始日
```

予約の全宿泊期間は施設の宿泊可能期間に収まり、予約操作日時は施設の予約受付期間内でなければならない。宿泊可能期間と予約受付期間の定義は [`02-listing-stay.md`](./02-listing-stay.md) を参照する。日時の計算には予約作成時点の施設タイムゾーンを使用する。

予約受付時に、選択されたRoom Typeに属する空きRoomまたはBedをシステムが自動で割り当てる。Room Type単位の数量だけを確保した未割り当て状態は作らない。

割り当て対象は予約期間全体で次を満たさなければならない。

- `active = true`
- 予約されたRoom Typeに所属する
- 有効期限内の`requested`または`confirmed`予約と期間が重複しない
- RoomまたはBedの施設停止期間と重複しない

貸切・個室はRoom、相部屋はBedを`quantity`件割り当てる。連泊では同じ物理在庫を使用し、宿泊途中で分割しない。

各宿泊日の予約可能数は、物理在庫とRoom Typeの日別販売上限の両方から算出する。有効期限内の`requested`と`confirmed`へ割り当てられたRoomまたはBedの件数を`used_count`とする。

```text
physical_available
= max(activeかつ停止されていない物理在庫数 - used_count, 0)

日別販売制御なし:
available = physical_available

日別販売制御あり:
sales_remaining = max(sales_limit - used_count, 0)
available = min(physical_available, sales_remaining)
```

連泊予約では、すべての宿泊日について`available >= quantity`を満たし、かつ期間全体で同じ物理在庫を確保できなければならない。どのRate Planを選択しても、同じRoom Typeの日別販売上限と共通物理在庫を消費する。

予約受付時はRoom Typeを先にロックし、対象日の販売制御、使用数、物理空き数を再計算する。その後に候補となる物理在庫をロックし、割り当てと予約状態の保存を同一トランザクションで行う。日別販売制御レコードが存在しない日もRoom Typeをロックし、同時予約による上限超過を防ぐ。必要数を確保できなければ予約または予約申請を成立させない。

テナントは確定後も同じRoom Typeに属する空きRoomまたはBedへ割り当てを変更できる。変更先のロック、利用可能性の確認、割り当ての更新を同一トランザクションで行い、失敗時は元の割り当てを維持する。別のRoom Typeへの変更は予約内容の変更として扱う。

## 宿泊人数と定員

`guest_count`は必須かつ1以上とする。初期仕様では年齢区分を持たず、宿泊する全員を1人として数える。料金計算には使用しない。

| `room_kind` | 予約条件 |
| --- | --- |
| `entire_place / private_room` | `guest_count <= capacity × quantity` |
| `shared_room` | `guest_count = quantity` |

貸切・個室は定員未満の人数で複数Roomを予約できる。相部屋は1人につき1 Bedを確保する。予約時に検証したRoom Typeの定員、宿泊人数、数量を`price_snapshot`へ複製し、Room Typeの定員変更を既存予約へ遡及させない。

## 予約者と宿泊者

`stay_reservations.user_id`は予約操作を行った予約者を表す。実際の宿泊者は予約者と同一とは限らないため、`stay_reservation_guests`へ予約時点の情報を保存する。

予約時に代表宿泊者1名の氏名、メールアドレス、電話番号を必須とする。予約者本人でなくてもよい。ユーザー情報を入力初期値にできるが、保存後は同期せず予約時点の連絡先を維持する。

同行者は氏名だけを持つ任意情報とし、予約時に全員分を求めない。予約後もチェックインまで追加、変更、削除でき、未登録でも予約の成立、承認、在庫確保に影響しない。

代表宿泊者は常に1名とし、削除は許可しない。代表宿泊者を含む登録済み宿泊者数は`guest_count`以下とするが、一致は必須としない。初期仕様では年齢区分、性別、住所、本人確認書類を保持しない。

## 予約確定方式と承認期限

施設の`booking_confirmation_mode`に従って予約を作成する。

| 設定 | 作成時の処理 |
| --- | --- |
| `instant` | 在庫を割り当て、`confirmed`で作成する |
| `approval_required` | 在庫を仮確保し、`requested`で作成する |

即時確定では割り当てと予約作成を同一トランザクションで行い、`requested`を経由しない。

予約作成時に施設の`time_zone`と、`check_in_date`、`check_in_time`から`check_in_at`を算出して予約へ固定する。承認制の`approval_expires_at`は、申請日時に施設の承認期限時間を加えた日時と`check_in_at`の早い方とする。

```text
approval_expires_at
= min(申請日時 + approval_deadline_hours, チェックイン開始日時)
```

算出値は予約へ保存し、施設の時刻やタイムゾーンの変更を遡及させない。`check_in_at`以降は申請を受け付けない。キャンセル期限の計算にも現在の施設設定ではなく予約の`check_in_at`を使用する。

有効期限内の`requested`は在庫を消費する。テナントの承認で割り当てを維持したまま`confirmed`へ遷移する。拒否、利用者取消、承認期限切れでは在庫を解放する。期限を過ぎた申請は承認できず、期限切れ処理前でも在庫確保中とは扱わない。

## 予約ステータス

| 値 | 状態 |
| --- | --- |
| `requested` | テナント承認待ち、承認期限まで在庫を仮確保 |
| `confirmed` | 予約確定、在庫を確保済み |
| `rejected` | テナントによる予約拒否 |
| `canceled` | キャンセル |
| `expired` | 承認期限切れ |
| `completed` | 宿泊完了 |

在庫を消費するのは有効期限内の`requested`と`confirmed`だけとする。割り当てレコードは状態遷移後も履歴参照のため保持する。

## 予約時料金のスナップショット

予約または予約申請の作成時に、利用者へ提示した料金と計算根拠を固定する。承認制でも申請時に固定し、承認時には再計算しない。

予約は`currency`、`accommodation_subtotal_amount`、`additional_fee_total_amount`、`discount_total_amount`、`total_amount`と、変更不可の`price_snapshot`を持つ。初期仕様では追加料金と割引を扱わず、両方の合計を0とする。

```text
accommodation_subtotal_amount = 各宿泊日の unit_amount × quantity の合計
total_amount = accommodation_subtotal_amount
             + additional_fee_total_amount
             - discount_total_amount
```

`price_snapshot`はスキーマバージョン、通貨、料金単位、Room Type、Rate Plan、施設・Room TypeのAmenities、数量、宿泊人数、日別料金明細、各合計を保持する。名称、販売形態、定員、食事条件も複製し、元レコードの変更や無効化後も予約時の内容を再現できるようにする。

```json
{
  "version": 1,
  "currency": "JPY",
  "pricing_unit": "room",
  "room_type": {
    "id": 10,
    "name": "スタンダードツイン",
    "room_kind": "private_room",
    "capacity": 2,
    "amenities": [
      { "code": "private_bathroom", "name": "専用バスルーム" }
    ]
  },
  "facility_amenities": [
    { "code": "wifi", "name": "無料Wi-Fi" }
  ],
  "rate_plan": {
    "id": 20,
    "name": "朝食付き・キャンセル可",
    "meal_type": "breakfast"
  },
  "quantity": 2,
  "guest_count": 3,
  "nights": [
    {
      "stay_date": "2026-08-10",
      "unit_amount": 15000,
      "quantity": 2,
      "subtotal_amount": 30000
    },
    {
      "stay_date": "2026-08-11",
      "unit_amount": 18000,
      "quantity": 2,
      "subtotal_amount": 36000
    }
  ],
  "accommodation_subtotal_amount": 66000,
  "additional_fee_total_amount": 0,
  "discount_total_amount": 0,
  "total_amount": 66000
}
```

`pricing_unit`は貸切・個室で`room`、相部屋で`bed`とする。各宿泊日は、対象日の`stay_room_type_rate_daily_prices`が存在すればその上書き料金を使用し、存在しなければ`stay_room_type_rates.price_per_night_amount`を使用する。解決した単価を宿泊日ごとの明細へ保存する。

元のRoom Type別料金、Room Type、Rate Planが変更されても既存予約の料金とスナップショットは更新しない。同じRoom Type内の物理在庫割り当て変更でも料金は変えない。日程、数量、Room Type、Rate Planの変更時の再見積もりは予約変更ルールで定義する。

## キャンセルポリシーのスナップショット

予約作成時にRate Planのキャンセル種別と固定テンプレートの条件を`cancellation_policy_snapshot`へ複製する。現在のRate Planやシステム標準料率ではなく、スナップショットだけで判定する。

`standard`は、キャンセル日時が「チェックイン開始日時－しきい値」以降となるルールを対象とし、複数該当する場合は最も小さいしきい値の料率を適用する。どのルールにも該当しない早期キャンセルは無料とする。

```json
{
  "type": "standard",
  "basis": "accommodation_subtotal",
  "rules": [
    { "hours_before_check_in": 168, "penalty_rate": 20 },
    { "hours_before_check_in": 48, "penalty_rate": 50 },
    { "hours_before_check_in": 24, "penalty_rate": 80 },
    { "hours_before_check_in": 0, "penalty_rate": 100 }
  ],
  "no_show_penalty_rate": 100
}
```

`non_refundable`は`type`、`basis`、`penalty_rate = 100`、`no_show_penalty_rate = 100`を保持する。

キャンセル料は利用者による`confirmed`予約のキャンセルだけに適用する。`requested`中の利用者取消とテナント都合の取消は無料とする。`non_refundable`は確定後100%、無断不泊は種別によらず100%とする。

```text
キャンセル料
= floor(accommodation_subtotal_amount × penalty_rate / 100)
```

## テスト条件

- 宿泊期間を半開区間として在庫の重複を判定すること。
- 宿泊可能期間と予約受付期間の両方を満たす場合だけ予約を受け付けること。
- 同時予約で同じ物理在庫を重複割り当てせず、必要数不足時は処理全体をロールバックすること。
- 日別販売制御の有無、上限0、上限残数、物理空き数の各条件で予約可能数を正しく算出すること。
- 連泊の全宿泊日で販売上限と物理在庫を満たす場合だけ予約できること。
- 異なるRate Planの同時予約でもRoom Type共通の販売上限を超えないこと。
- 貸切・個室に`quantity`件のRoom、相部屋に`quantity`件のBedを割り当てること。
- 同じRoom Type内の割り当て変更に成功し、失敗時は元の割り当てを維持すること。
- `guest_count`とRoom Typeの定員・販売形態の条件を検証すること。
- 代表宿泊者が常に1名で、登録済み宿泊者数が`guest_count`を超えないこと。
- 即時確定と承認制で、設定に応じた初期状態と在庫割り当てになること。
- 承認期限の境界、期限切れ、拒否、取消で在庫が正しく解放されること。
- 予約時に日別料金、合計、表示条件およびキャンセル条件を各スナップショットへ保存すること。
- 予約時に施設とRoom Typeの有効なAmenitiesのコードと表示名を料金スナップショットへ保存すること。
- 日別上書き料金がある宿泊日と基本料金へフォールバックする宿泊日を含む予約で、日別明細と合計が正しいこと。
- Rate Plan、料金、定員、標準料率の変更を既存予約へ遡及させないこと。
- 予約時の施設タイムゾーンで`check_in_at`を固定し、施設の時刻・タイムゾーン変更を遡及させないこと。
- キャンセル種別、状態、主体、時刻に応じた料率を適用し、1円未満を切り捨てること。
