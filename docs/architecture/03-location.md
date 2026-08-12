# 住所・位置情報

## 目的

テナントが登録した拠点を求人と滞在Listingで再利用し、Google Maps上に地点を表示する。

テーブル間の関連とカラム構成は [`../er/01-listing.md`](../er/01-listing.md) を参照する。

## データモデル

住所・位置情報はListing本体や種別固有テーブルへ直接保持せず、テナント所有の`tenant_locations`で管理する。`tenant_locations.tenant_id`は必須とし、所有者のない共通拠点は作成しない。

テナントは複数の拠点を持つことができ、`tenants.primary_tenant_location_id`で代表拠点を任意に指定する。`tenants`には住所文字列を保持しない。Listingは`listings.tenant_location_id`で登録済み拠点を任意に参照し、同じ拠点を複数の求人・滞在Listingから再利用できる。

`tenants.primary_tenant_location_id`と`listings.tenant_location_id`が参照する拠点は、それぞれ自身と同じテナントに属していなければならない。この同一テナント制約はアプリケーションのバリデーションで保証する。

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・更新条件 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | 拠点の識別子 | 作成後変更不可 |
| `tenant_id` | bigint | ○ | なし | 拠点を所有するテナント | 作成後変更不可、テナント削除時に連動削除 |
| `name` | string | ○ | なし | 本社、○○ホテルなどの管理用名称 | 最大100文字、テナント内で一意 |
| `location_type` | string | ○ | `other` | 拠点種別 | `headquarters / office / facility / other` |
| `postal_code` | string | × | NULL | 郵便番号 | 最大16文字。日本の郵便番号は`NNN-NNNN`へ正規化 |
| `prefecture` | string | × | NULL | 都道府県 | 最大50文字 |
| `city` | string | × | NULL | 市区町村 | 最大100文字 |
| `address_line1` | string | × | NULL | 町名・番地 | 最大255文字 |
| `address_line2` | string | × | NULL | 建物名・部屋番号 | 最大255文字 |
| `google_place_id` | string | × | NULL | Google Maps上の地点を識別するPlace ID | 最大文字数を固定しない |
| `latitude` | decimal | ○ | なし | 地点の緯度 | `-90`以上`90`以下 |
| `longitude` | decimal | ○ | なし | 地点の経度 | `-180`以上`180`以下 |
| `created_at` | datetime | ○ | 自動設定 | 作成日時 | アプリケーションから変更しない |
| `updated_at` | datetime | ○ | 自動設定 | 更新日時 | 保存時に自動更新 |

住所入力の途中ではフォーム上の作業値として扱い、Geocodingに成功して緯度・経度を取得できた時点で`tenant_locations`を保存する。

滞在Listingの公開時は`tenant_location`を必須とし、参照先に`prefecture`、`city`、`address_line1`、`latitude`、`longitude`が設定されていなければならない。`postal_code`、`address_line2`、`google_place_id`は任意とする。完全な住所を保持する条件と一般ユーザーへの開示範囲は分けて扱う。

求人Listingでは`onsite`と`hybrid`の公開時に`tenant_location`を必須とし、`remote`では任意とする。

## 拠点の登録と選択

テナントの拠点管理画面では、Google Placesによる地点選択を優先し、該当地点がない場合は構造化住所の手入力を許可してサーバー側でGeocodingする。

Google Mapsに登録済みの施設・店舗は、Google Placesから取得したPlace ID、構造化住所、緯度、経度を保存する。Google Mapsに施設として登録されていない住所は、Geocodingで住所から緯度・経度を取得して保存し、`google_place_id`は取得できた場合のみ保存する。

住所、Place ID、緯度、経度は同じ地点を表す値として一括更新する。Geocodingに失敗した場合は拠点を保存せず、入力値を画面へ返して再入力を促す。既存拠点の変更で失敗した場合は更新全体を拒否し、更新前の住所と座標を保持する。

Listing作成・編集画面では、現在のテナントが所有する`tenant_locations`から拠点を選択する。選択肢に必要な拠点がなければ拠点管理画面で新規登録する。Listingごとに住所を複製しない。

代表拠点はテナント作成時に必須とせず、拠点登録後に`tenants.primary_tenant_location_id`へ設定する。代表拠点を削除する場合は、先に別の代表拠点へ変更するか代表拠点の設定を解除する。Listingから参照中の拠点は削除せず、参照を変更または解除してから削除する。

## 住所変更の影響

Listingは拠点を参照するため、`tenant_locations`の住所変更はその拠点を使用するすべてのListingへ即時反映される。掲載時点の住所履歴は初期仕様では保持しない。

予約や応募などの取引成立時点の住所を後から再現する必要がある場合は、各取引に構造化住所のスナップショットを保存する。`tenant_locations`を履歴保存のために複製しない。

## 地図表示

Google Mapsの埋め込みURLはDBに保存せず、表示時に生成する。

表示対象は次の優先順位で決定する。

1. `google_place_id`が存在する場合は、Maps Embed APIの`place`モードへPlace IDを指定する
2. Place IDが存在しない場合は、緯度・経度を指定して地点を表示する

Place IDを指定するときは、Maps Embed APIの`q`に`place_id:{google_place_id}`を設定する。

APIキーはサーバーの環境変数で管理し、利用するWebサイトをHTTPリファラー制限に設定する。

住所と地図上の正確な地点は公開ページへ表示する。初期仕様では座標のぼかしや予約成立後のみの開示は行わない。Maps API障害時は保存済みの構造化住所を表示し、地図部分だけを利用不可表示にする。

## Place IDの更新

Place IDは永続的な識別子として扱わない。Google Maps側で無効になった場合は、保存済みの住所または緯度・経度で地図を表示し、地点を再検索してPlace IDを更新する。

## 運用上の確認事項

Places API、Geocoding API、Maps Embed APIの具体的なライブラリ、利用上限、APIキーの環境別設定は実装・インフラ設定時に決める。Place IDは地図表示が失敗したとき、または拠点編集時に再確認し、通常の閲覧ごとには照会しない。

## 公式ドキュメント

- [Maps Embed API](https://developers.google.com/maps/documentation/embed/embedding-map)
- [Place IDs](https://developers.google.com/maps/documentation/places/web-service/place-id)
