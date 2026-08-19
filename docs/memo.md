一通りの画面は揃っていますが、「実装完了」とするにはまだ不足があります。現状はUIと基本CRUDの骨格が完成した段階です。

  主な未完了事項：

  1. Room Typeの施設整合性検証

  backend/app/models/stay_room.rbには、選択したstay_room_typeが同じstay_listingに属する検証がありません。

  フォーム表示は絞り込まれていますが、リクエストを直接送れば別施設のRoom Type IDを指定できます。

  2. Roomの基本バリデーション

  現在、DB制約だけに依存しています。

  - nameの必須
  - 同一施設内での名称重複
  - activeの必須

  少なくとも以下が必要です。

  validates :name,
            presence: true,
            uniqueness: { scope: :stay_listing_id }

  3. 削除失敗時の処理

  RoomにBedがある場合はrestrict_with_errorで削除できませんが、Controllerは結果を確認せず「削除しました」と表示します。

  @room.destroy
  redirect_to ..., notice: "客室を削除しました"

  Room Typeも割当て済みRoomが存在すると、外部キーエラーになる可能性があります。削除可否とエラー表示の設計が必要です。

  4. 不要なshowルート

  Room TypeとRoomのルートにshowがありますが、ControllerとViewにshowはありません。

  resources :room_types, only: %i[index show new create edit update destroy]
  resources :rooms, only: %i[index show new create edit update destroy]

  使わないならshowを削除すべきです。現在アクセスするとActionNotFoundになります。

  5. Room Typeの業務ルール

  ER設計にある次の条件は未実装です。

  - shared_roomのcapacityは1
  - 公開時に必要な情報の検証
  - 予約割当てがあるRoomのRoom Type変更制限
  - 販売可否のRoom／Bed親子判定

  予約機能がまだなら後回しでも構いませんが、少なくともshared_roomの定員ルールは現段階で検討が必要です。

  6. テスト不足

  現在確認できているのは主に以下です。

  - Room Typeの登録・一覧・編集表示
  - Bedの登録
  - Bedの施設境界
  - 一覧での割当て状況

  不足している重要なケース：

  - Roomの登録・更新
  - 別施設Room Typeの割当て拒否
  - Bedの更新・削除
  - BedありRoomの削除拒否
  - RoomありRoom Typeの削除拒否
  - 入力エラー時の再表示

  結論として、UIはほぼ完成していますが、データ整合性・削除制御・ルート整理・重要テストが残っています。特に「別施設のRoom Typeを割り当てられる問題」と「削除失敗
  を成功表示する問題」は、完了前に修正すべきです。
