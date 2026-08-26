# 宿泊管理UI

## 目的

プロトタイプで検証した宿泊施設運営の画面構成を、Railsのテナントデザインへ移植する。求人掲載と宿泊施設運営を別の業務導線として扱い、宿泊施設の最小登録後に客室・在庫・料金を段階設定する。

求人と宿泊施設は`Tenant::JobsController`と`Tenant::StaysController`へ分割済みで、サイドメニューから`tenant_jobs_path`と`tenant_stays_path`へ直接遷移する。ナビゲーションのアクティブ判定は`controller_path`だけで行う。旧`Tenant::ListingsController`と`/tenant/listings`ルートは削除し、共通フォームだけを`tenant/shared/_listing_form`として共有する。

ログイン中テナントは`Tenant::BaseController#set_current_tenant`で`@tenant`へ設定し、全テナント管理画面で共通利用する。取得処理はリダイレクトしない。テナントを必須とするJobs、Stays、Locations、Organizationsだけが`require_current_tenant!`をbefore actionとして実行し、未設定ならHomeへ戻す。Homeは必須チェックを行わず、組織未設定状態を表示できるためリダイレクトループにならない。

## 情報設計

```text
宿泊施設を登録
  施設名・説明・拠点を下書き保存
    ↓
施設ダッシュボード
  ├─ 施設・予約受付設定
  ├─ Room Type
  ├─ 物理Room／Bed
  ├─ 料金プラン
  ├─ 販売管理
  └─ 予約管理
```

初回登録では定員、基本料金、設備、予約期間を入力しない。定員はRoom Type、料金はRate PlanとRoom Typeの組み合わせ、設備は施設またはRoom Type、予約条件は施設設定で管理する。

## 画面

| ビュー | 想定URL | 役割 |
| --- | --- | --- |
| `tenant/stays/index` | `/tenant/stays` | 宿泊施設の選択 |
| `tenant/stays/new` | `/tenant/stays/new` | 施設名・説明・拠点の最小登録 |
| `tenant/stay_management/dashboard` | `/tenant/stays/:listing_id` | 設定状況と販売構成の確認 |
| `tenant/stay_management/room_types` | `/tenant/stays/:listing_id/room_types` | 販売分類の管理 |
| `tenant/stay_management/inventory` | `/tenant/stays/:listing_id/inventory` | 物理Room／Bedの管理 |
| `tenant/stay_management/rate_plans` | `/tenant/stays/:listing_id/rate_plans` | 販売条件と基本料金の管理 |

## コントローラー契約

UI内の仮データを接続時に次の変数へ置き換える。

- `@stay_listings`: テナント所有の宿泊Listing一覧
- `@stay_listing`: 現在操作中の`StayListing`
- `@room_types`: 施設のRoom Type一覧
- `@selected_room_type`: 編集対象のRoom Type
- `@rooms`: 施設の物理Room一覧。各RoomはBed一覧を持つ
- `@selected_room`: 編集対象の物理Room
- `@rate_plans`: 施設のRate Plan一覧
- `@selected_rate_plan`: 編集対象のRate Plan
- `@room_type_rates`: Room TypeとRate Planの組み合わせ料金

施設登録フォームでは`listing[tenant_location_id]`を送信する。接続時にStrong Parametersへ追加し、選択された拠点がログイン中テナントに属することをモデルで検証する。登録成功後は掲載詳細ではなく、その施設のダッシュボードへ遷移する。

すべての取得処理は、ログイン中メンバーのテナント所有Listingを起点にスコープする。他テナントのIDは404として扱う。

### 料金プランCRUD

料金プランの登録・編集フォームでは、プラン名、説明、食事条件、キャンセル条件、状態と、施設に属する全Room Typeの基本料金を一括編集する。Room Type別料金はnested attributesとして料金プラン本体と同じトランザクションで保存する。

- 販売を有効にしたRoom Typeだけ、1以上の整数の基本料金を必須にする。
- 未選択の新規Room Type別料金は保存しない。
- 保存済みのRoom Type別料金を販売停止にした場合、価格を保持して`active = false`にする。
- Room Typeと料金プランが同じ`StayListing`に属することをモデルでも検証する。
- `show`では販売条件とRoom Type別基本料金を読み取り専用で表示する。
- 物理削除は`draft`または`inactive`で、Room Type別料金を持たない料金プランだけに許可する。
- 登録・更新の検証失敗時は入力値を保持して`422 Unprocessable Entity`でフォームを再表示する。
- 別施設の料金プランIDは、現在施設から検索して404にする。

### 客室・ベッドのブロック管理

施設都合で物理在庫を一時停止する操作は、割当て客室管理から行う。客室一覧の各行からRoom Block、相部屋のベッド一覧の各行からBed Blockの管理画面へ遷移する。客室管理画面上部には、施設内のRoom BlockとBed Blockを期間順にまとめて確認する「ブロック一覧」への導線を置く。

- Room BlockとBed Blockは、それぞれ対象を固定した一覧・登録・編集画面を持つ。
- 入力項目は停止する最初の宿泊日、利用を再開する宿泊日、理由、管理メモとする。
- 期間は`starts_on...ends_on`の半開区間で、`ends_on`は`starts_on`より後を必須とする。
- 理由は`maintenance / cleaning / operator_block / other`の4種に限定する。
- Bed Blockは`shared_room`へ割り当てられたRoomのBedだけに作成できる。
- 取得対象は現在のStay Listingを起点に検索し、別施設・別テナントのIDは404とする。
- Block同士の期間重複は既存仕様どおり許可する。
- 予約済み期間との重複判定は、予約モデルと在庫割当ての実装時に追加する。
- 削除操作は履歴状態を持たない現行スキーマでは「ブロックを解除」と表現する。

## 実装手順

1. 想定URLのルートとコントローラーを追加する。
2. ビュー内の仮データをインスタンス変数へ置き換える。
3. `href="#"`と`action="#"`を実際のルートヘルパーへ置き換える。
4. Policy、Strong Parameters、成功・失敗時のレスポンスを実装する。
5. コントローラー接続後に画面テストと操作テストを追加する。

Jobs/Staysの詳細取得はそれぞれ`@tenant.listings.where(listing_type: ...)`を起点とし、別種別または別テナントのIDを404にする。Listingと`JobListing`／`StayListing`は同一トランザクションで保存する。専用フォームは`tenant_job_path`／`tenant_stay_path`へ送信し、旧Listingsルートへ依存しない。

## 検証

UI段階ではERB内にインラインstyleを置かず、Ruby構文を含むテンプレートが解析可能であることと、既存Backendテストへ影響しないことを確認する。
