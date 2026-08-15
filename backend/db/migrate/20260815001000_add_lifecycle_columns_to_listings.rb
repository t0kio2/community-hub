class AddLifecycleColumnsToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :last_published_at, :datetime
    add_column :listings, :closed_reason, :string
    add_column :listings, :archived_at, :datetime
  end
end
