# Tenant ホーム画面設計

## 目的

tenant ログイン後の `/tenant` に、組織情報が分かるホーム画面を表示し、組織情報を編集できるようにする。

## 対象

- `api/app/views/tenant/home/index.html.erb`
- `api/app/controllers/tenant/organizations_controller.rb`
- `api/app/views/tenant/organizations/edit.html.erb`
- `api/config/routes.rb`
- `api/test/controllers/tenant/home_controller_test.rb`
- `api/test/controllers/tenant/organizations_controller_test.rb`

## 実装方針

- 既存の `Tenant::BaseController` が公開している `current_tenant_user` と `current_tenant_organization` を使う。
- 画面には以下を表示する。
  - tenant 組織名、かな、ステータス、住所
  - ログイン中アカウント、ロール
- 未実装機能や今後の実装予定を説明する表示は削除する。
- owner はホーム画面から組織情報編集画面へ遷移できる。
- staff は組織情報を更新できない。
- 編集対象は `name`, `kana`, `address` に限定し、`status` は tenant 側から変更しない。
- HTML 内の `<style>` はファイル下部に配置する。

## 検証

- tenant account でサインインしたとき、ホーム画面に組織名、ロール、編集リンクが表示されることを controller test で確認する。
- ホーム画面に不要な今後の実装予定表示が出ないことを controller test で確認する。
- owner が組織情報を更新できることを controller test で確認する。
- staff が編集画面や更新処理にアクセスできないことを controller test で確認する。
- tenant user に紐づく組織がない場合のメッセージは既存挙動を維持する。
