class CreateTenantUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_members do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :role
      t.string :status

      t.timestamps
    end
  end
end
