class CreateStayRoomsAndInventory < ActiveRecord::Migration[8.1]
  def change
    create_table :stay_room_types do |t|
      t.references :stay_listing, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.text :description
      t.string :room_kind, null: false
      t.integer :capacity
      t.string :status, null: false, default: "draft"

      t.timestamps

      t.index [ :stay_listing_id, :name ], unique: true
      t.index [ :stay_listing_id, :status ]
    end

    create_table :stay_rooms do |t|
      t.references :stay_room_type, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.text :notes

      t.timestamps

      t.index [ :stay_room_type_id, :name ], unique: true
    end

    create_table :stay_beds do |t|
      t.references :stay_room, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.text :notes

      t.timestamps

      t.index [ :stay_room_id, :name ], unique: true
    end

    create_table :stay_room_blocks do |t|
      t.references :stay_room, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :reason, null: false
      t.text :notes

      t.timestamps

      t.index [ :stay_room_id, :starts_on, :ends_on ]
    end

    create_table :stay_bed_blocks do |t|
      t.references :stay_bed, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :reason, null: false
      t.text :notes

      t.timestamps

      t.index [ :stay_bed_id, :starts_on, :ends_on ]
    end

    create_table :stay_room_type_daily_sales_controls do |t|
      t.references :stay_room_type, null: false, foreign_key: true
      t.date :stay_date, null: false
      t.integer :sales_limit, null: false

      t.timestamps

      t.index [ :stay_room_type_id, :stay_date ],
              unique: true,
              name: "idx_stay_room_type_daily_sales_unique"
    end
  end
end
