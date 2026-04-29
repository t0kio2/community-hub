class CreateStayListings < ActiveRecord::Migration[8.1]
  def change
    create_table :stay_listings do |t|
      t.references :listing, null: false, foreign_key: true, index: { unique: true }
      t.string :stay_type
      t.string :address
      t.integer :capacity
      t.integer :price_per_night
      t.time :check_in_time
      t.time :check_out_time
      t.date :available_from
      t.date :available_until
      t.text :amenities
      t.text :house_rules

      t.timestamps
    end
  end
end
