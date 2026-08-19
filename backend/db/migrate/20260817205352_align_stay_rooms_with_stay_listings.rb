class AlignStayRoomsWithStayListings < ActiveRecord::Migration[8.1]
  def change
    add_reference :stay_rooms,
                  :stay_listing,
                  null: false,
                  foreign_key: true,
                  index: false

    change_column_null :stay_rooms, :stay_room_type_id, true

    # 古いインデックス削除
    remove_index :stay_rooms,
                [:stay_room_type_id, :name],
                name: "index_stay_rooms_on_stay_room_type_id_and_name"
                
    # 新しい複合ユニークインデックス追加
    add_index :stay_rooms,
              [:stay_listing_id, :name],
              unique: true,
              name: "index_stay_rooms_on_stay_listing_id_and_name"

    add_index :stay_rooms,
          [:stay_room_type_id, :active],
          name: "index_stay_rooms_on_stay_room_type_id_and_active"
          

  end
end
