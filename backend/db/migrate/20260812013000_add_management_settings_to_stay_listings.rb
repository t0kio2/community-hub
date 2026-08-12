class AddManagementSettingsToStayListings < ActiveRecord::Migration[8.1]
  def change
    add_column :stay_listings, :booking_confirmation_mode, :string, null: false, default: "approval_required"
    add_column :stay_listings, :approval_deadline_hours, :integer, null: false, default: 24
    add_column :stay_listings, :booking_open_days_before, :integer, null: false, default: 365
    add_column :stay_listings, :booking_close_hours_before, :integer, null: false, default: 0
    add_column :stay_listings, :stay_available_starts_on, :date
    add_column :stay_listings, :stay_available_ends_on, :date
    add_column :stay_listings, :time_zone, :string, null: false, default: "Asia/Tokyo"
  end
end
