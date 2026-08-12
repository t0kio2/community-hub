class CreateTenantLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_locations do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :location_type, null: false, default: "other"
      t.string :postal_code
      t.string :prefecture
      t.string :city
      t.string :address_line1
      t.string :address_line2
      t.string :google_place_id
      t.decimal :latitude, null: false
      t.decimal :longitude, null: false

      t.timestamps
    end

    add_index :tenant_locations, [:tenant_id, :name], unique: true
  end
end
