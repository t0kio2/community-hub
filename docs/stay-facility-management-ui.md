# 宿泊施設別管理UI

## 目的と背景

宿泊施設一覧から施設を選択した後、テナント全体の管理画面ではなく、選択した施設に集中した運営画面へ切り替える。施設名、一覧へ戻る導線、予約・販売・客室・施設設定のメニューを常に確認できるようにする。

今回はUIのみを実装し、予約、在庫、料金などのモデル、ルート、コントローラは追加しない。

## 対象ファイル

- `backend/app/views/layouts/tenant.html.erb`
- `backend/app/views/tenant/stays/show.html.erb`
- `backend/app/views/tenant/stays/index.html.erb`
- `backend/app/assets/stylesheets/tenant.css`
- `backend/app/assets/stylesheets/tenant/stay_dashboard.css`
- `backend/test/controllers/tenant/stays_controller_test.rb`

## UI設計

- `Tenant::StaysController#show`を宿泊施設別の運営ダッシュボードとする
- サイドバー上部はCommunity Hubの固定表示から施設名と「宿泊施設管理」へ切り替える
- サイドバーの先頭に「宿泊施設一覧へ戻る」を表示する
- 運営ダッシュボード、予約業務、予約一覧、販売管理、客室管理、施設設定を表示する
- 未実装の画面はリンクにせず「準備中」と表示する
- メイン領域には今日の状況、要対応、施設情報への導線を表示する
- 実データがない集計値は架空の数値を表示せず`--`とする

## データ・APIへの影響

なし。既存の`@listing`、`@stay_listing`、`tenant_location`だけを表示に利用する。

## 実装手順

1. テナントレイアウトへ施設管理用のbrandとnavigationの差し込み領域を追加する
2. 宿泊施設詳細画面から施設管理用サイドバーを指定する
3. 詳細画面を運営ダッシュボードへ変更する
4. 一覧画面の導線を「管理画面」へ変更する
5. 既存デザインシステムに合わせたCSSを追加する
6. コントローラテストで施設名、戻る導線、メニュー、ダッシュボードを確認する

## CSS構成

`tenant/stay_dashboard.css`は`tenant.css`の後に、宿泊施設別ダッシュボードだけで読み込むページCSSとする。次の順序でセクションを分ける。

1. 宿泊管理共通レイアウト
2. 共通コンポーネント
3. 状態・集計カード
4. 施設別運営ダッシュボード
5. レスポンシブ調整

色、角丸、文字サイズ、表面色は`tenant.css`の`--tenant-*`トークンを参照する。ダッシュボードだけで使う薄い背景色などは`.stay-dashboard`内のローカルトークンとして定義し、同じ値を各セレクタへ重複記述しない。

ページ固有クラスは`.stay-dashboard`をBlockとするBEM形式で命名する。施設管理画面全体で再利用する`.stay-facility-navigation-*`と`.stay-status-*`には`dashboard`を付けない。

`tenant/stay_management`配下の旧UIモックはルートとコントローラがなく、現在の画面から利用されていない。そのモック専用セレクタはページCSSから除外し、実際に`stays/show`で使うスタイルだけを管理する。旧モック自体の削除は別作業とする。

## 検証方針

- 宿泊施設一覧では従来のテナント全体ナビゲーションが表示される
- 宿泊施設詳細では施設名と施設別ナビゲーションが表示される
- 一覧へ戻るリンクが正しいURLを持つ
- 未実装メニューがリンクになっていない
- 別テナントの宿泊施設を取得できない既存制約が維持される

## 今後の対応

- 公開用`facility_code`の導入
- `Tenant::Stays::*Controller`とネストしたルートの追加
- 各メニューを実装後、準備中表示を実リンクへ置き換える
- 予約・在庫・料金の実データをダッシュボード集計へ接続する
