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

レイアウトERBへCSSを埋め込まず、`app/assets/stylesheets/admin.css`へ分離する。CSSは次の順序で整理する。

1. Adminデザイントークン
2. アプリケーションシェル
3. サイドナビゲーションとアカウント領域
4. トップバーとコンテンツ領域
5. 既存ERB向けの共通カード・テーブル・フォーム
6. レスポンシブ調整

汎用要素のスタイルは可能な限り`.admin-shell`または`.admin-content`配下へ限定し、テナント画面や認証画面への漏出を防ぐ。状態や責務が分かるAdmin固有クラスを使用し、圧縮された一行CSSは使用しない。

現在のRailsはAPI-only構成でアセットパイプラインを持たないため、`propshaft`を追加して`stylesheet_link_tag`から配信する。プロトタイプのCSSは変更しない。

## 実装方針

サイドバーはAdminプロトタイプの`admin-shell`を基準とし、テナント画面とは配色とナビゲーション表現を分離する。ナビゲーションには現在存在する`admin_root_path`、`admin_tenant_accounts_path`、`new_admin_tenant_account_path`だけを表示し、現在のパスから選択状態を付与する。

ログイン管理者はER図どおり`current_admin_account.email`と`current_admin.role`、`current_admin.status`を表示する。ログアウトは既存DeviseルートへのPOSTフォームを維持する。

## 検証方針

今回はUI実装のみとし、自動テストは追加しない。ERB構文と差分を確認し、既存の`yield`、フラッシュ、CSRF、ログアウトフォームが残っていることを確認する。
