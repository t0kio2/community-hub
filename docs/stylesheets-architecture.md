# 管理画面CSS構成方針

## 目的

Admin画面とTenant画面で一貫したUIを保ちながら、それぞれ固有の配色・レイアウト・ページ要件を分離する。現時点ではAdmin画面の実装を優先し、共通CSSへの抽出はTenant画面を本実装するときに改めて判断する。

## 現在の構成

```text
backend/app/assets/stylesheets/
├── admin.css
└── admin/
    └── tenants.css
```

- `admin.css`: Adminのデザイントークン、シェル、サイドバー、トップバー、共通部品
- `admin/tenants.css`: Adminにおけるテナント一覧・詳細固有のスタイル

現段階では既存ファイルの移動や共通化を行わない。

## Tenant画面実装時の検討方針

Tenant画面の本実装時に、AdminとTenantの両方で実際に使うスタイルを確認してから`common`へ抽出する。想定する構成は次のとおり。

```text
backend/app/assets/stylesheets/
├── common/
│   ├── foundation.css
│   └── components.css
├── admin/
│   ├── layout.css
│   └── tenants.css
└── tenant/
    ├── layout.css
    ├── listings.css
    └── organization.css
```

### `common/foundation.css`

- フォントファミリーと基本タイポグラフィ
- フォントサイズ、余白、角丸などの共通トークン
- `box-sizing`などの基本設定

### `common/components.css`

- ボタン
- テーブル
- ステータスバッジ
- カード
- フォーム
- フラッシュメッセージと空状態

### 各領域の`layout.css`

- AdminまたはTenant固有のカラートークン
- サイドバー、トップバー、ログインアカウント領域
- 領域固有のページ幅やレスポンシブレイアウト

### ページCSS

- 一覧や詳細など、その画面でしか使わないレイアウト
- ページ固有の状態表現
- ページ固有のレスポンシブ調整

## 共通化の判断基準

`common`には、AdminとTenantの両方で実際に使用するものだけを置く。

- 将来使いそうという理由だけで共通化しない
- 特定領域や特定画面だけのクラスを置かない
- 色やフォントサイズは可能な限りCSSカスタムプロパティを参照する
- AdminとTenantで見た目や振る舞いが異なる部品は、無理に同一クラスへ統合しない
- 共通化によって条件分岐や上書きが増える場合は、領域固有CSSへ残す

## クラス命名

共通化した部品には`.admin-*`や`.tenant-*`を使わない。既存の`.button`や`.status-badge`のように役割が明確な名前を優先する。短い名前では衝突や責務が分かりにくい場合は、`.ui-card`や`.ui-table`のような接頭辞を検討する。

領域固有のレイアウトとページ要素には、引き続き`.admin-*`、`.tenant-*`、`.tenant-detail__*`など、所属が分かる名前を使用する。

## 読み込み順序

共通化後は、基礎、共通部品、領域レイアウト、ページCSSの順で読み込む。

```erb
<%= stylesheet_link_tag "common/foundation", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "common/components", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "admin/layout", "data-turbo-track": "reload" %>
<%= yield :stylesheets if content_for?(:stylesheets) %>
```

Tenantレイアウトでは`admin/layout`を`tenant/layout`へ置き換える。ページCSSは各Viewから`content_for :stylesheets`で渡す。

## 移行時の確認事項

Tenant画面を実装するときは、次の順序で共通化の範囲を決める。

1. AdminとTenantで必要なトークンと部品を比較する
2. 両方で同じ責務・見た目を持つものだけを`common`へ移す
3. AdminとTenantそれぞれの`layout.css`を作成する
4. 各レイアウトの読み込み順を更新する
5. AdminとTenant双方の描画テストと主要画面を確認する

CSSファイルの移動だけを先行させず、Tenant側の具体的なUIが見えた段階で共通化する。
