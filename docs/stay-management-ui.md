# 宿泊管理UI

## 目的

プロトタイプで検証した宿泊施設運営の画面構成を、Railsのテナントデザインへ移植する。求人掲載と宿泊施設運営を別の業務導線として扱い、宿泊施設の最小登録後に客室・在庫・料金を段階設定する。現段階ではUIのみとし、モデル、コントローラー、ルート、保存処理は実装しない。

宿泊施設一覧ルートが未接続の間、サイドメニューの「宿泊施設」はリンクにせず「準備中」と表示する。`href="#"`の仮リンクは使用しない。`/tenant/stays`実装時に一覧ルートへの通常リンクへ置き換える。

移行期間中に`tenant/listings/:id`で宿泊Listingを表示・編集する場合も、`@listing.listing_type`を基準に宿泊運営の画面として扱う。求人管理をアクティブにせず、見出しは「宿泊施設詳細／編集」、一覧ルート接続前の戻り先はテナントホームとする。

`Tenant::JobsController`と`Tenant::StaysController`への分割後は、サイドメニューから`tenant_jobs_path`と`tenant_stays_path`へ直接遷移する。ナビゲーションのアクティブ判定は`controller_path`だけで行い、`listing_type`パラメータや`@listing`から画面領域を推測しない。既存の`Tenant::ListingsController`は移行中の互換ルートとし、サイドメニューの判定対象に含めない。

ログイン中テナントは`Tenant::BaseController#set_current_tenant`で`@tenant`へ設定し、全テナント管理画面で共通利用する。取得処理はリダイレクトしない。テナントを必須とするJobs、Stays、Listings、Locations、Organizationsだけが`require_current_tenant!`をbefore actionとして実行し、未設定ならHomeへ戻す。Homeは必須チェックを行わず、組織未設定状態を表示できるためリダイレクトループにならない。`current_tenant_organization`や各コントローラ固有の`set_tenant`／`set_organization`は持たない。

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
| `tenant/stay_management/index` | `/tenant/stays` | 宿泊施設の選択 |
| `tenant/listings/new`（stay時） | `/tenant/stays/new`へ移行予定 | 施設名・説明・拠点の最小登録 |
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

## 実装手順

1. 想定URLのルートとコントローラーを追加する。
2. ビュー内の仮データをインスタンス変数へ置き換える。
3. `href="#"`と`action="#"`を実際のルートヘルパーへ置き換える。
4. Policy、Strong Parameters、成功・失敗時のレスポンスを実装する。
5. コントローラー接続後に画面テストと操作テストを追加する。

Jobs/Staysの詳細取得はそれぞれ`@tenant.listings.where(listing_type: ...)`を起点とし、別種別または別テナントのIDを404にする。Listingと`JobListing`／`StayListing`は同一トランザクションで保存する。専用フォームは`tenant_job_path`／`tenant_stay_path`へ送信し、旧Listingsルートへ依存しない。

## 検証

UI段階ではERB内にインラインstyleを置かず、Ruby構文を含むテンプレートが解析可能であることと、既存Backendテストへ影響しないことを確認する。
