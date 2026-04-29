class CreateListingImages < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_images do |t|
      t.references :listing, null: false, foreign_key: true
      t.string :image_url, null: false
      t.integer :position, null: false
      t.string :alt_text

      t.timestamps
    end

    add_index :listing_images, [:listing_id, :position], unique: true
  end
end
