# 求人Listing定義

## 目的

求人Listing固有のカラム、職種カテゴリー、給与、勤務条件、公開条件を定義する。

Listing共通の状態遷移、権限、画像、削除・保持は [`02-listing.md`](./02-listing.md)、住所・位置情報は [`03-location.md`](./03-location.md)、テーブル間の関連は [`../er/01-listing.md`](../er/01-listing.md) を参照する。

## job_listings

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・単位 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 求人詳細の識別子 | 作成後変更不可 |
| `listing_id` | bigint | ○ | なし | 対応する求人Listing | 一意、`listing_type = job` |
| `recruitment_type` | string | × | NULL | 募集形態 | `ongoing / spot` |
| `employment_type` | string | × | NULL | 契約上の雇用形態 | `regular_employee / contract_employee / part_time / temporary_staff / other` |
| `work_mode` | string | ○ | `onsite` | 勤務形態 | `onsite / remote / hybrid` |
| `job_category_id` | bigint | × | NULL | 職種カテゴリーマスター | 公開時は有効なカテゴリーを必須とする |
| `salary_unit` | string | × | NULL | 給与の算定単位 | `hourly / daily / monthly / annual / per_shift` |
| `salary_min_amount` | integer | × | NULL | 最低額または固定額 | 公開時は必須、1以上、整数の円単位 |
| `salary_max_amount` | integer | × | NULL | 上限額 | NULLまたは`salary_min_amount`以上 |
| `currency` | string | ○ | `JPY` | ISO 4217通貨コード | 初期仕様では`JPY`のみ |
| `transportation_fee` | integer | ○ | `0` | 給与とは別に支給する交通費 | 0以上、整数の円単位 |
| `salary_notes` | text | × | NULL | 給与条件、手当、試用期間中の差異 | 最大文字数: 要定義 |
| `work_starts_at` | datetime | × | NULL | 単発勤務の開始日時 | `spot` の公開時は必須、`work_ends_at`より前 |
| `work_ends_at` | datetime | × | NULL | 単発勤務の終了日時 | `spot` の公開時は必須、`work_starts_at`より後 |
| `application_deadline` | datetime | × | NULL | 応募締切日時 | `spot` の公開時は必須、`work_starts_at`以前 |
| `break_minutes` | integer | ○ | `0` | 単発勤務の休憩時間 | `spot` で使用、0以上かつ勤務時間未満 |
| `work_days` | string | × | NULL | 継続求人の勤務日・勤務頻度の表示文 | `ongoing`の公開時は必須、最大255文字 |
| `working_hours` | string | × | NULL | 継続求人の勤務時間の表示文 | `ongoing`の公開時は必須、最大255文字 |
| `required_qualifications` | text | × | NULL | 求人側が求める必須資格・経験 | 任意、最大2,000文字 |
| `preferred_qualifications` | text | × | NULL | 求人側が歓迎する資格・経験 | 任意、最大2,000文字 |
| `benefits` | text | × | NULL | 福利厚生 | 任意、最大2,000文字 |
| `positions_available` | integer | × | NULL | 募集人数 | 1以上、`spot`の公開時は必須 |
| `dress_code` | text | × | NULL | 単発勤務の服装・身だしなみ | `spot`で使用、最大2,000文字 |
| `items_to_bring` | text | × | NULL | 単発勤務の持ち物 | `spot`で使用、最大2,000文字 |
| `selection_process` | text | × | NULL | 継続求人の選考方法 | `ongoing`で使用、最大2,000文字 |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

## 職種カテゴリーマスター

職種カテゴリーは自由入力やコード内の固定値ではなく、`job_categories` で管理する。1つの求人は1つの主要カテゴリーに所属する。

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・更新条件 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 職種カテゴリーの識別子 | 作成後変更不可 |
| `code` | string | ○ | なし | システム内部で使用する識別子 | 一意、作成後変更不可 |
| `name` | string | ○ | なし | 画面に表示するカテゴリー名 | 最大文字数: 要定義 |
| `description` | text | × | NULL | 運営向けの説明 | 最大文字数: 要定義 |
| `position` | integer | ○ | なし | 選択肢の表示順 | 0以上、同順位はID昇順で表示する |
| `active` | boolean | ○ | true | 新規選択と公開に使用できるか | 無効化しても既存関連を保持する |
| `created_by_admin_id` | bigint | × | 操作中の管理者 | 作成した管理者 | 管理者削除時はNULL |
| `updated_by_admin_id` | bigint | × | 操作中の管理者 | 最後に更新した管理者 | 更新操作ごとに設定、管理者削除時はNULL |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

カテゴリーは物理削除せず、使用停止時は `active = false` とする。無効なカテゴリーは新しい求人へ設定できず、無効なカテゴリーを設定した下書き・終了済み求人は公開または再公開できない。

カテゴリーの無効化を理由に公開中Listingを自動で `closed` へ遷移させない。既存の関連と表示は維持し、次回の再公開までに有効なカテゴリーへ変更する。

### 初期データ

初期カテゴリーはseedで投入する。seedは環境構築時の初期登録にのみ使用し、運用開始後のカテゴリーの正本はDBとする。

seedは `code` をキーに未登録カテゴリーだけを作成する冪等な処理とする。既存カテゴリーの `name`、`position`、`active` を上書きせず、seedから削除されたカテゴリーも自動で無効化または削除しない。運用中の変更は運営管理画面から行う。

| `code` | `name` | `position` |
| --- | --- | ---: |
| `food_service` | 飲食 | 10 |
| `retail` | 販売 | 20 |
| `accommodation` | 宿泊・観光 | 30 |
| `logistics` | 物流・配送 | 40 |
| `light_work` | 軽作業 | 50 |
| `office` | オフィスワーク | 60 |
| `event` | イベント | 70 |
| `care` | 介護・福祉 | 80 |
| `medical` | 医療 | 90 |
| `construction` | 建設・土木 | 100 |
| `agriculture` | 農業 | 110 |
| `other` | その他 | 999 |

| 操作 | super_admin | operator |
| --- | :---: | :---: |
| 一覧・詳細の閲覧 | ○ | ○ |
| 作成 | ○ | × |
| 名前・説明の更新 | ○ | × |
| 表示順の変更 | ○ | × |
| 有効化・無効化 | ○ | × |

認可は職種カテゴリーマスター専用のPolicyに定義する。

## 募集形態と雇用形態

`recruitment_type` は募集期間の性質、`employment_type` は契約上の雇用区分を表し、別々に管理する。

| `recruitment_type` | 定義 | 日時カラム |
| --- | --- | --- |
| `ongoing` | 継続的な求人募集 | `work_starts_at` と `work_ends_at` は使用しない |
| `spot` | 特定の勤務日時に対する単発募集 | `work_starts_at`、`work_ends_at`、`application_deadline` が必須 |

単発募集を `employment_type` の値として表現しない。例えば、単発のアルバイトは `recruitment_type = spot`、`employment_type = part_time` として表現する。

`recruitment_type` と `employment_type` は下書きでは未設定を許可し、公開時は必須とする。業務委託や雇用関係を伴わないインターンを扱う場合は、`employment_type` に混在させず、契約形態を表す別の設計を追加する。

## 勤務形態

`work_mode` は求人公開時に必須とする。`onsite` と `hybrid` は勤務場所を表示するため `listing_location` を必須とし、`remote` は任意とする。住所の有無から勤務形態を推測しない。

## 募集条件と募集人数

`required_qualifications` と `preferred_qualifications` は応募者自身のプロフィールではなく、求人側が求める条件を表示する。未経験・資格不要の求人を公開できるよう、どちらも任意とする。

`positions_available` は応募件数の上限ではなく募集人数を表す。`spot` は公開時に1以上を必須とし、`ongoing` は人数を明示しない場合にNULLを許容する。`0`は許可しない。

`accepted` の求人応募数が `positions_available` に達した場合は、新規応募を停止してListingを `closed` へ遷移し、`closed_reason = capacity_reached` を設定する。応募ステータスの定義は [`../er/n-job-application.md`](../er/n-job-application.md) を参照する。

## 勤務日・勤務時間

`spot` は応募対象となる1回の勤務を表すため、`work_starts_at`、`work_ends_at`、`break_minutes` を構造化して保持する。公開時は開始日時と終了日時を必須とし、休憩時間は勤務時間未満でなければならない。

`ongoing` の勤務日と勤務時間は募集要項の表示にのみ使用するため、`work_days` と `working_hours` に表示文を保持する。公開時は両方を必須とする。

| カラム | 入力例 |
| --- | --- |
| `work_days` | 月曜日〜金曜日のうち週3日以上 |
| `working_hours` | 9:00〜18:00の間で実働6〜8時間 |

曜日・時間帯による検索、シフト作成、勤務可能判定は行わない。これらが必要になった場合に、勤務時間を別テーブルへ構造化する。

`spot` は `dress_code` と `items_to_bring`、`ongoing` は `selection_process` を任意の表示項目として使用する。募集形態を変更した場合は、変更前の募集形態でのみ使用するカラムをNULLへ戻す。

## 給与

給与額は日本円の整数で保持し、控除前の総支給額として扱う。給与に税込・税抜の区分は持たせない。

| `salary_unit` | 表示 | 利用可能な募集形態 |
| --- | --- | --- |
| `hourly` | 時給 | `ongoing / spot` |
| `daily` | 日給 | `ongoing / spot` |
| `monthly` | 月給 | `ongoing` |
| `annual` | 年収 | `ongoing` |
| `per_shift` | 1勤務あたり | `spot` |

金額は次の規則で表示する。

| `salary_min_amount` | `salary_max_amount` | 表示 |
| ---: | ---: | --- |
| 1,200 | 1,200 | 1,200円 |
| 1,200 | 1,500 | 1,200〜1,500円 |
| 1,200 | NULL | 1,200円以上 |

公開時は `salary_unit`、`salary_min_amount`、`currency` を必須とする。固定額は `salary_max_amount` に `salary_min_amount` と同じ値を設定する。

`per_shift` は `work_starts_at` から `work_ends_at` までの1回の勤務に対する報酬を表す。初期仕様では1つの単発Listingを1勤務枠とし、同日に複数の勤務枠を募集する場合はListingを分ける。1つのListingで複数シフトを扱う必要が生じた場合は、`job_shifts` の導入を別途設計する。

`transportation_fee` は給与とは別に支給する固定額とし、支給しない場合は `0` とする。

## 公開条件

共通の公開条件に加え、次の条件を満たす必要がある。

| 条件 | ongoing | spot |
| --- | :---: | :---: |
| `recruitment_type` | ○ | ○ |
| `employment_type` | ○ | ○ |
| 有効な`job_category` | ○ | ○ |
| `work_mode` | ○ | ○ |
| `onsite / hybrid`の場合に`listing_location`が存在する | ○ | ○ |
| `salary_unit`、`salary_min_amount`、`currency` | ○ | ○ |
| `work_days`、`working_hours` | ○ | - |
| `work_starts_at`、`work_ends_at`、`application_deadline` | - | ○ |
| `positions_available` | 任意 | ○ |

## テスト条件

- 下書きでは求人固有の公開必須項目が未入力でも保存できること。
- 単発・継続求人の許可値、必須項目、使用禁止項目を検証すること。
- 給与額、勤務日時、休憩時間、募集人数の境界値と大小関係を検証すること。
- 勤務形態に応じた位置情報の必須性を検証すること。
- 無効な職種カテゴリーで公開・再公開できないこと。
- 採用数が募集人数へ到達した場合に新規応募を停止すること。
