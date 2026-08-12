class CreateStayRates < ActiveRecord::Migration[8.1]
  def change
    create_table :stay_rate_plans do |t|
      t.references :stay_listing, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.text :description
      t.string :meal_type, null: false, default: "room_only"
      t.string :cancellation_policy_type, null: false, default: "standard"
      t.string :status, null: false, default: "draft"

      t.timestamps

      t.index [ :stay_listing_id, :name ], unique: true
      t.index [ :stay_listing_id, :status ]
    end

    create_table :stay_room_type_rates do |t|
      t.references :stay_room_type, null: false, foreign_key: true
      t.references :stay_rate_plan, null: false, foreign_key: true
      t.integer :price_per_night_amount, null: false
      t.string :currency, null: false, default: "JPY"
      t.boolean :active, null: false, default: true

      t.timestamps

      t.index [ :stay_room_type_id, :stay_rate_plan_id ],
              unique: true,
              name: "idx_stay_room_type_rates_unique"
    end

    create_table :stay_room_type_rate_daily_prices do |t|
      t.references :stay_room_type_rate, null: false, foreign_key: true
      t.date :stay_date, null: false
      t.integer :price_amount, null: false

      t.timestamps

      t.index [ :stay_room_type_rate_id, :stay_date ],
              unique: true,
              name: "idx_stay_daily_prices_unique"
    end
  end
end
