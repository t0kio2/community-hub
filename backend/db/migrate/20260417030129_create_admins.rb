class CreateAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :admins do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :role
      t.string :status

      t.timestamps
    end
  end
end
