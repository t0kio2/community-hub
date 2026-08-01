# Listing管理プロトタイプ設計

## 目的

Listing設計をDB実装前に画面操作で検証する。初期対象は滞在Listingとし、施設設定から公開可否までの操作が、現在のアーキテクチャ・ER定義で無理なく成立するか確認する。

## 配置と実行方式

`prototype/`へ、ビルド不要のHTML・CSS・JavaScript・JSONを配置する。Rails、Next.js、DB、外部APIには接続しない。初期状態をJSONから読み込み、編集結果はブラウザの`localStorage`だけへ保存する。

```text
prototype/
├── index.html
├── styles.css
├── app.js
├── domain.js
├── data/stay-listing.json
├── tests/domain.test.mjs
└── README.md
```

## 検証する操作

- 施設基本情報、予約確定方式、住所、宿泊可能期間を編集する。
- Room Typeを追加・選択し、物理Roomと相部屋のBedを追加・有効化する。
- Rate Planを追加し、選択中Room Typeとの組み合わせに基本料金を設定する。
- 指定日の料金上書きと販売上限を設定する。
- 施設とRoom TypeのAmenityを選択する。
- 公開必須条件を一覧表示し、条件を満たす場合だけ疑似公開する。
- JSONの書き出し、初期データへのリセットを行う。

## データ構造

JSONはUIで1施設を編集しやすい集約形式とする。ただし、Room Type、Room、Bed、Rate Plan、料金関連はER上の境界が分かるID参照を維持する。日別料金と販売上限は日付をキーにせず、将来テーブルへ変換しやすいレコード配列で保持する。

画像は実ファイルを保存せず、初期データ上のメタデータ件数だけを扱う。Google MapsとGeocodingは呼び出さず、構造化住所と緯度・経度を直接編集する。

## 検証方針

公開条件、物理在庫数、販売可能数、日別料金の決定を副作用のない関数へ分離し、Node.js標準テストランナーで検証する。UIは静的HTTPサーバーで表示し、ブラウザ操作で確認する。

静的HTTPサーバーは起動したターミナルの`Ctrl+C`で停止する。起動したターミナルが分からない場合は、4173番ポートを使用するプロセスを特定して終了する手順をREADMEに記載する。

## 対象外

- 求人Listing
- 実際の予約、決済、キャンセル料計算
- 複数日の予約に対するRoom・Bed割り当て
- Google Maps、画像アップロード、認証、権限
- Rails APIとDBへの保存

これらは現在の滞在Listing操作が成立すると確認した後に追加する。プロトタイプで扱う業務内容は、正式な業務定義である[`operations/stay-tenant-operations.md`](./operations/stay-tenant-operations.md)に従う。

## 宿泊業務プロトタイプへの拡張順序

| 段階 | 追加する業務 | 検証したいこと |
| --- | --- | --- |
| 1 | 業務ダッシュボード、販売カレンダー | テナントが今日すべき作業と販売状況を把握できるか |
| 2 | 予約一覧、申請承認・拒否、予約詳細 | 承認期限と在庫仮確保を誤解なく操作できるか |
| 3 | Room・Bed割り当て変更、停止期間登録 | 予約と施設停止の競合を扱えるか |
| 4 | キャンセル確認、料金スナップショット表示 | 現在の料金と予約時料金を区別できるか |
| 5 | 当日到着・出発画面 | チェックイン・完了・無断不泊の不足仕様を発見できるか |

## 拡張時のディレクトリ方針

新しいルートディレクトリは作らず、既存の`prototype/`内を機能別に分割する。

```text
prototype/
├── index.html
├── styles/
│   ├── base.css
│   └── components.css
├── src/
│   ├── app.js
│   ├── core/
│   │   ├── store.js
│   │   └── navigation.js
│   └── features/
│       ├── dashboard/
│       ├── listings/
│       ├── inventory/
│       ├── rates/
│       └── reservations/
├── data/
│   ├── stay-listing.json
│   └── stay-reservations.json
└── tests/
```

Listing設定と予約・在庫業務は同じ状態を使用するため、別プロトタイプへ分けず、JSONと`localStorage`の状態を共有する。
