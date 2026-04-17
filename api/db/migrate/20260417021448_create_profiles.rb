class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.string :kana
      t.date :birth_date
      t.string :phone
      t.string :avatar_url

      t.timestamps
    end
  end
end
