class AlignStayListingsWithEr < ActiveRecord::Migration[8.1]
  def up
    add_column :stay_listings, :latest_check_in_time, :time

    execute <<~SQL.squish
      UPDATE stay_listings
      SET stay_available_starts_on = COALESCE(stay_available_starts_on, available_from),
          stay_available_ends_on = COALESCE(stay_available_ends_on, available_until)
    SQL

    remove_column :stay_listings, :stay_type, :string
    remove_column :stay_listings, :address, :string
    remove_column :stay_listings, :capacity, :integer
    remove_column :stay_listings, :price_per_night, :integer
    remove_column :stay_listings, :available_from, :date
    remove_column :stay_listings, :available_until, :date
    remove_column :stay_listings, :amenities, :text
  end

  def down
    add_column :stay_listings, :stay_type, :string
    add_column :stay_listings, :address, :string
    add_column :stay_listings, :capacity, :integer
    add_column :stay_listings, :price_per_night, :integer
    add_column :stay_listings, :available_from, :date
    add_column :stay_listings, :available_until, :date
    add_column :stay_listings, :amenities, :text

    execute <<~SQL.squish
      UPDATE stay_listings
      SET available_from = stay_available_starts_on,
          available_until = stay_available_ends_on
    SQL

    remove_column :stay_listings, :latest_check_in_time, :time
  end
end
