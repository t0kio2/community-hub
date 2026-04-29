class ChangeProfilesToUserProfiles < ActiveRecord::Migration[8.1]
  def up
    add_reference :profiles, :user, foreign_key: true, index: { unique: true }

    execute <<~SQL.squish
      UPDATE profiles
      SET user_id = users.id
      FROM users
      WHERE profiles.account_id = users.account_id
    SQL

    execute <<~SQL.squish
      DELETE FROM profiles
      WHERE user_id IS NULL
    SQL

    change_column_null :profiles, :user_id, false
    remove_reference :profiles, :account, foreign_key: true, index: { unique: true }
  end

  def down
    add_reference :profiles, :account, foreign_key: true, index: { unique: true }

    execute <<~SQL.squish
      UPDATE profiles
      SET account_id = users.account_id
      FROM users
      WHERE profiles.user_id = users.id
    SQL

    change_column_null :profiles, :account_id, false
    remove_reference :profiles, :user, foreign_key: true, index: { unique: true }
  end
end

