# Tenant ERBレイアウト設計

## 目的

`backend/app/views/layouts/tenant.html.erb`を、Tenantプロトタイプの緑・ライムを基調としたワークスペースUIへ更新する。Adminレイアウトで採用した画面構造と`content_for`の受け渡し方を揃え、AdminとTenantで操作感を統一する。

## 対象

- Tenant専用の固定サイドバー
- プロトタイプに沿ったブランド、緑系配色、カード状のメニュー区分
- 現在存在するRailsルートへのナビゲーション
- ログイン中のTenant Account、TenantMember、Tenant情報
- ページタイトル、戻るリンク、フラッシュ、ページCSS、本文を表示するメイン領域
- 未ログインのTenantセッション画面
- Propshaftによる本実装用CSS配信

各ページ本文の再設計、Controller、Policy、ルート、求人・予約・応募者・メンバー機能の追加は対象外とする。プロトタイプファイルは変更しない。

## レイアウト構成

Adminレイアウトと同様に、画面全体をサイドバーとメイン領域の2カラムにする。

```text
tenant-shell
├── tenant-sidebar
│   ├── brand
│   ├── navigation
│   └── account / logout
└── tenant-main
    ├── topbar
    └── content
```

トップバーは子Viewから次の領域を受け取る。

- `title`: ブラウザタイトル
- `page_title`: 画面上の主要タイトル
- `back_link`: 詳細・編集画面の戻る導線
- `stylesheets`: ページ固有CSS

`page_title`が未指定の場合は`title`を表示し、どちらもない場合は「テナントホーム」とする。`back_link`が未指定の場合はTenantワークスペースであることと組織名を表示する。

## ナビゲーション

プロトタイプの区分表現を保ちながら、現在実在するルートだけを表示する。

- ホーム: `tenant_root_path`
- 求人管理
  - 求人一覧: `tenant_jobs_path`
  - 求人を作成: `new_tenant_job_path`
- 宿泊管理
  - 宿泊施設一覧: `tenant_stays_path`
  - 宿泊施設を登録: `new_tenant_stay_path`
- 組織設定
  - 組織情報: `edit_tenant_organization_path`。ownerにだけ表示する

予約、応募者、メンバーなど、ルートが存在しない項目は表示しない。実装時に該当区分へ追加する。

## ログインユーザー領域

サイドバー下部に次を表示する。

- Tenant名
- TenantMemberのロールと状態
- Tenant Accountのメールアドレス
- ログアウト

遷移先となるメンバー画面が存在しないため、ユーザー領域自体はリンクにしない。未ログイン時はログイン導線だけを表示し、TenantMemberを参照しない。

## CSS構成

本実装用スタイルは`backend/app/assets/stylesheets/tenant.css`へ置き、レイアウト内に`style`要素を置かない。クラス名は`.tenant-shell`、`.tenant-sidebar`、`.tenant-topbar`などTenant領域固有にする。

色、フォントサイズ、角丸、コンテンツ幅は`.tenant-shell`のCSSカスタムプロパティとして定義する。配色はプロトタイプに合わせ、濃緑のサイドバー、ライムのアクセント、緑の主要操作、暖色の注意表示を使用する。

Tenant画面の主要操作には`--tenant-color-primary`を使用し、旧画面の青いアクションカラーを残さない。ホバー色などページ固有の状態も緑系で統一する。塗りつぶし型の主要操作は白文字を明示し、共通リンク色に上書きされない詳細度でコントラストを維持する。

AdminとTenantの共通CSS抽出はこの変更では行わない。両方の実装が揃った後、`docs/stylesheets-architecture.md`の基準に従って実際に共通する基礎・部品だけを`common`へ移す。

## 組織情報編集

`tenant/organizations/edit.html.erb`はTenantレイアウトの`page_title`と`back_link`を使用し、本文内に画面タイトルや戻るリンクを重複させない。組織の状態と編集対象を確認できるカード内に、組織名、組織名かな、住所のフォームを配置する。

ページ固有スタイルは`app/assets/stylesheets/tenant/organizations.css`へ分離し、View内に`style`要素を置かない。主要な更新操作はTenantの緑、キャンセルは共通の白いボタン、エラーはTenantの危険色トークンで表示する。Controller、Policy、パラメータ、更新処理は変更しない。

組織情報編集の本文は独自の最大幅を持たせず、Tenantレイアウトのコンテンツ幅を使用する。これにより、掲載管理などの他画面とカードの左右位置と横幅を揃える。入力欄はカード内で全幅とし、狭い画面では共通レイアウトに従って縮小する。

## 掲載管理

求人・宿泊施設の一覧、詳細、作成、編集は共通して`app/assets/stylesheets/tenant/listings.css`を読み込む。フォームPartialは`app/views/tenant/shared/_listing_form.html.erb`で共有し、各専用コントローラのURLを明示的に渡す。

- 一覧: 本文上部には求人作成・宿泊作成の操作だけを置き、カード内のテーブルに種別、状態、更新日、詳細・編集導線を表示する
- 詳細: トップバーに一覧へ戻る導線を置き、掲載名・種別・状態の概要、共通情報、求人または宿泊の詳細をカードとして表示する
- 作成・編集: トップバーに一覧または詳細へ戻る導線を置き、共通項目と種別固有項目を同じフォームカード表現で表示する

Listing、JobListing、StayListingのパラメータ構造と保存処理は変更しない。表示上の種別と状態は日本語化し、DB値は変更しない。

## 検証方針

- ログイン済みホームにTenant専用CSS、サイドバー、タイトル、組織名、メール、ロール、ログアウトを表示できること
- 掲載画面で掲載ナビゲーションが選択状態になること
- ownerには組織情報リンクを表示し、staffには表示しないこと
- 未ログインのログイン画面でTenantMember参照による例外が発生しないこと
- レイアウトにインライン`style`が存在しないこと
- 組織情報編集画面がページ固有CSSとトップバーの戻るリンクを使用し、インライン`style`を持たないこと
- 掲載一覧・詳細・作成・編集が共通の掲載CSSを使用し、インライン`style`を持たないこと
- 既存のTenant Controllerテストが成功すること
