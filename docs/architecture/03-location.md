# 住所・位置情報

## 目的

求人と滞在Listingで共通の住所・位置情報を管理し、Google Maps上に地点を表示する。

テーブル間の関連とカラム構成は [`../er/01-listing.md`](../er/01-listing.md) を参照する。

## データモデル

求人と滞在で同じ位置情報仕様を使用する。住所・位置情報はListing本体や種別固有テーブルに保持せず、`listing_locations` に分離する。

`listings` と `listing_locations` は1対0..1とし、`listing_locations.listing_id` の一意制約で1つのListingに複数の位置情報が作成されることを防ぐ。

| カラム | 型 | 必須 | 初期値 | 定義 | 制約・更新条件 |
| --- | --- | :---: | --- | --- | --- |
| `id` | bigint | ○ | 自動採番 | Listing位置情報の識別子 | 作成後変更不可 |
| `listing_id` | bigint | ○ | なし | 対応するListing | 一意、Listing削除時に連動削除 |
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

位置情報を持たない下書きListingは、`listing_location` を作成せずに保存する。`listing_location` を作成する場合は、`latitude`、`longitude` を必須とする。

滞在Listingの公開時は`listing_location`を必須とし、`prefecture`、`city`、`address_line1`、`latitude`、`longitude`が設定されていなければならない。`postal_code`、`address_line2`、`google_place_id`は任意とする。完全な住所を保持する条件と一般ユーザーへの開示範囲は分けて扱う。

位置情報による範囲検索を導入する場合のデータ型と空間インデックスは、その機能の設計時に決定する。

## 地点の登録

入力画面ではGoogle Placesによる地点選択を優先し、該当地点がない場合は構造化住所の手入力を許可してサーバー側でGeocodingする。

Google Mapsに登録済みの施設・店舗は、Google Placesから取得したPlace ID、構造化住所、緯度、経度を保存する。

Google Mapsに施設として登録されていない住所は、Geocodingで住所から緯度・経度を取得して保存する。この場合、`google_place_id` は取得できた場合のみ保存する。

住所、Place ID、緯度、経度は同じ地点を表す値として一括更新する。

Geocodingに失敗した下書きは、`listing_location`を作成せず住所入力の作業値を画面へ返して再入力を促す。公開は位置情報の必須条件を満たすまで許可しない。公開済みListingの住所変更でGeocodingに失敗した場合は更新全体を拒否し、更新前の住所と座標を保持する。

構造化住所を住所表示の正本とし、表示時に各カラムを組み立てる。Googleから返される整形済み住所はDBに保存しない。複数のListingが同じ地点を使用する場合も、`listing_location` レコードは共有しない。

## 地図表示

Google Mapsの埋め込みURLはDBに保存せず、表示時に生成する。

表示対象は次の優先順位で決定する。

1. `google_place_id` が存在する場合は、Maps Embed APIの `place` モードへPlace IDを指定する
2. Place IDが存在しない場合は、緯度・経度を指定して地点を表示する

Place IDを指定するときは、Maps Embed APIの `q` に `place_id:{google_place_id}` を設定する。

APIキーはサーバーの環境変数で管理し、利用するWebサイトをHTTPリファラー制限に設定する。

住所と地図上の正確な地点は公開ページへ表示する。初期仕様では座標のぼかしや予約成立後のみの開示は行わない。Maps API障害時は保存済みの構造化住所を表示し、地図部分だけを利用不可表示にする。

## Place IDの更新

Place IDは永続的な識別子として扱わない。Google Maps側で無効になった場合は、保存済みの住所または緯度・経度で地図を表示し、地点を再検索してPlace IDを更新する。

## 運用上の確認事項

Places API、Geocoding API、Maps Embed APIの具体的なライブラリ、利用上限、APIキーの環境別設定は実装・インフラ設定時に決める。Place IDは地図表示が失敗したとき、または住所編集時に再確認し、通常の閲覧ごとには照会しない。

## 公式ドキュメント

- [Maps Embed API](https://developers.google.com/maps/documentation/embed/embedding-map)
- [Place IDs](https://developers.google.com/maps/documentation/places/web-service/place-id)
