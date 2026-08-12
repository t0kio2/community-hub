class CreateStayAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :stay_amenities do |t|
      t.references :tenant, null: true, foreign_key: true
      t.string :scope, null: false
      t.string :category, null: false, default: "other"
      t.string :code, null: false
      t.string :name, null: false, limit: 100
      t.integer :position, null: false
      t.boolean :active, null: false, default: true

      t.timestamps

      t.index [ :active, :scope, :category ]
      t.index :code,
              unique: true,
              where: "tenant_id IS NULL",
              name: "idx_common_stay_amenities_code"
      t.index [ :tenant_id, :code ],
              unique: true,
              where: "tenant_id IS NOT NULL",
              name: "idx_tenant_stay_amenities_code"
    end

    create_table :stay_listing_amenities do |t|
      t.references :stay_listing, null: false, foreign_key: true
      t.references :stay_amenity, null: false, foreign_key: true

      t.timestamps

      t.index [ :stay_listing_id, :stay_amenity_id ],
              unique: true,
              name: "idx_stay_listing_amenities_unique"
    end

    create_table :stay_room_type_amenities do |t|
      t.references :stay_room_type, null: false, foreign_key: true
      t.references :stay_amenity, null: false, foreign_key: true

      t.timestamps

      t.index [ :stay_room_type_id, :stay_amenity_id ],
              unique: true,
              name: "idx_stay_room_type_amenities_unique"
    end
  end
end
