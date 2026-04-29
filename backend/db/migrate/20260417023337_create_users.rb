class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :status

      t.timestamps
    end
  end
end
