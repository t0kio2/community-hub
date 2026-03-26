class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :role, null: false, default: 'user'
      t.string :status, null: false, default: 'active'

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
