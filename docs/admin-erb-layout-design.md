# Admin ERB レイアウト設計

## 目的

`backend/app/views/layouts/admin.html.erb`を、紫を基調としたAdminプロトタイプ固有の管理画面UIへ更新する。既存のAdmin Controller、Policy、ルート、各画面のERBは変更せず、レイアウトと共通スタイルだけを対象とする。

## 対象

- 濃紺と紫を基調としたAdmin専用の固定サイドバー
- 運営管理画面であることを示すブランド・コンテキスト表示
- 実在するAdminルートへのナビゲーション
- 現在のAdmin Accountのメール、ロール、状態
- ページタイトル、フラッシュ、本文を表示するメイン領域
- 既存の一覧・詳細・フォームを整える共通スタイル
- Propshaftによる本実装用CSSアセット配信

データ取得、Controller、認可、Turbo、Stimulus、各ページ固有のマークアップは変更しない。

## CSS構成

レイアウトERBへCSSを埋め込まない。`app/assets/stylesheets/admin.css`にはAdmin全体のトークン、シェル、ナビゲーション、共通部品を置き、`app/assets/stylesheets/admin/tenants.css`にはテナント一覧・詳細だけのスタイルを置く。Adminレイアウトから共通CSS、ページCSSの順で読み込む。

共通CSSは次の順序で整理する。

1. Adminデザイントークン
2. アプリケーションシェル
3. サイドナビゲーションとアカウント領域
4. トップバーとコンテンツ領域
5. 既存ERB向けの共通カード・テーブル・フォーム
6. レスポンシブ調整

フォントサイズは`.admin-shell`に用途別のタイポグラフィトークンとして定義し、ページCSSから数値を直接指定しない。`caption`、`small`、`body`、`subheading`、`heading`、`page-title`の6段階を基本とする。ロゴなど固有の視覚表現だけは個別値を許容する。

汎用要素のスタイルは可能な限り`.admin-shell`または`.admin-content`配下へ限定し、テナント画面や認証画面への漏出を防ぐ。状態や責務が分かるAdmin固有クラスを使用し、圧縮された一行CSSは使用しない。

現在のRailsはAPI-only構成でアセットパイプラインを持たないため、`propshaft`を追加して`stylesheet_link_tag`から配信する。プロトタイプのCSSは変更しない。

## 実装方針

サイドバーはAdminプロトタイプの`admin-shell`を基準とし、テナント画面とは配色とナビゲーション表現を分離する。ナビゲーションには現在存在する`admin_root_path`、`admin_tenant_accounts_path`、`new_admin_tenant_account_path`だけを表示し、現在のパスから選択状態を付与する。

ログイン管理者はER図どおり`current_admin_account.email`と`current_admin.role`、`current_admin.status`を表示する。ログアウトは既存DeviseルートへのPOSTフォームを維持する。

### テナント一覧

`admin/tenants/index.html.erb`はAdminプロトタイプのテナント一覧を本実装用ERBへ移植する。Controllerから渡される、Listing・TenantMember・Accountを事前読み込み済みの`@tenants`だけを利用する。

一覧には組織名、所在地、ownerアカウント、Listing件数、状態、登録日、詳細導線を表示する。ownerが存在しない場合と一覧が空の場合も表示を崩さない。検索・状態フィルターはUIとして配置するが、実際の絞り込みはController実装後に有効化する。

一覧・詳細とも、表示データの本文は原則12〜13px、補助情報は10〜11px、カード見出しは14〜17pxを基準とする。8〜9pxは英字ラベルなど限定的な装飾用途に留め、メールアドレス、所在地、状態、日付など判断に必要な情報には使用しない。

各画面の主要セクションは、レイアウトが描画する`h1#admin-page-title`を`aria-labelledby`で参照する。見出しを伴わない操作領域には`header`を使わず、アクション配置用の`div`を使う。

### テナント詳細

`admin/tenants/show.html.erb`は、テナント一覧から遷移して組織の全体像を確認する参照画面とする。一覧へ戻る導線は`content_for :back_link`でAdminレイアウトへ渡し、通常画面のパンくずと同じトップバー上段へ表示する。本文上部には組織名・フリガナ・状態・登録日をまとめた概要を配置する。

Adminレイアウトは`back_link`が渡された場合だけパンくずを戻るリンクへ置き換え、未指定の画面では従来の`ADMIN / COMMUNITY HUB`を表示する。これにより、画面固有の戻り先と共通レイアウト上の配置を分離する。

本文は組織情報、TenantMember一覧、Listingサマリーと最近の掲載で構成する。メンバーにはメールアドレス・ロール・状態を、掲載には宿泊／求人の種別・公開状態・更新日を表示し、関連データが空の場合も空状態を表示する。更新・利用停止などの操作は対応するController処理が未実装のため、このUIには含めない。

現状の`show`アクションが設定する`@tenant`だけで描画可能とし、Controller変更は必須としない。将来クエリ数が問題になる場合は、`tenant_members: :account`と`listings`の事前読み込みをController側で追加する。

### テナントアカウント作成

`admin/tenant_accounts/new.html.erb`は、Admin共通レイアウトの画面タイトルと戻るリンク領域を使用する。本文内にページタイトルや導入バナーを重複させず、アカウント情報と組織情報を同じ階層のカードとして配置する。

各カードは`fieldset`と非表示の`legend`でフォーム項目のまとまりを保ち、視覚上の見出しは通常のカードヘッダーとして表示する。英字ラベルと日本語見出しの二重表示は行わない。

ページ固有スタイルは`app/assets/stylesheets/admin/tenant_accounts.css`へ分離し、View内に`style`要素を置かない。色、フォントサイズ、角丸はAdminのデザイントークンを参照する。既存のパラメータ構造、エラー表示、初期ロールowner、パスワード表示切り替え、送信処理は維持する。

## 検証方針

UI実装では、ERB構文と差分を確認し、既存の`yield`、フラッシュ、CSRF、ログアウトフォームが残っていることを確認する。詳細画面はControllerテストで、組織情報、ownerを含むメンバー、対象テナントの掲載、空状態が描画されることを確認する。
