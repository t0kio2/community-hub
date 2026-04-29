class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by_tenant_member, foreign_key: { to_table: :tenant_members }
      t.references :updated_by_tenant_member, foreign_key: { to_table: :tenant_members }
      t.string :listing_type, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :listings, [:listing_type, :status]
    add_index :listings, [:status, :published_at]
  end
end
